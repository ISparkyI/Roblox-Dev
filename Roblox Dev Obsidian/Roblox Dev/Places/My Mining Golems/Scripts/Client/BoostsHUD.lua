--!strict
-- BoostsHUD — активні зілля зверху по центру екрана: круглий значок кольору зілля з іконкою і таймер (хв:с) під ним.
-- Де: StarterPlayerScripts/BoostsHUD. Дані — атрибути гравця Boost_<зілля> (кінець дії, час сервера; ставить InventoryService "Use").
-- Список зіль, іконки, кольори — Shared/ItemConfig.POTIONS. Значок з'являється, коли зілля випили, і зникає, коли дія скінчилась.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Items = require(RS:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local ItemViewport = require(RS.Shared:WaitForChild("ItemViewport")) -- 3D-зілля (Prefabs/IconModels)

local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local SIZE = 62

local gui = Instance.new("ScreenGui")
gui.Name = "BoostsHUD"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 4
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local root = Instance.new("Frame")
root.Name = "Root"; root.BackgroundTransparency = 1; root.AnchorPoint = Vector2.new(0.5, 0)
root.Position = UDim2.new(0.5, 0, 0, 12); root.Size = UDim2.fromOffset(600, SIZE + 30)
root.Parent = gui
local scale = Instance.new("UIScale"); scale.Parent = root
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal; list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, 12); list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = root
gui.Parent = player:WaitForChild("PlayerGui")

local function fit()
	local cam = workspace.CurrentCamera
	local y = cam and cam.ViewportSize.Y or 1015
	scale.Scale = math.clamp(y / 1015, 0.55, 1.3)
end
fit()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

local function circle(parent: Instance, size: number, color: Color3, z: number): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.new(0.5, 0, 0, SIZE / 2)
	f.Size = UDim2.fromOffset(size, size); f.BackgroundColor3 = color; f.BorderSizePixel = 0; f.ZIndex = z
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.5, 0); c.Parent = f
	f.Parent = parent
	return f
end

type Badge = { root: Frame, timer: TextLabel }
local badges: { [string]: Badge } = {}

local function makeBadge(i: number, d: any): Badge
	local b = Instance.new("Frame")
	b.Name = d.key; b.BackgroundTransparency = 1; b.Size = UDim2.fromOffset(SIZE + 10, SIZE + 30); b.LayoutOrder = i
	circle(b, SIZE + 6, INK, 1) -- чорний контур (окремим колом, без UIStroke)
	circle(b, SIZE, d.tone, 2)
	local inner = circle(b, SIZE - 10, Color3.fromHex("23262d"), 3)
	inner.BackgroundTransparency = 0.15
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1; icon.Image = d.icon; icon.ScaleType = Enum.ScaleType.Fit
	icon.AnchorPoint = Vector2.new(0.5, 0.5); icon.Position = UDim2.new(0.5, 0, 0, SIZE / 2)
	icon.Size = UDim2.fromOffset(SIZE - 14, SIZE - 14); icon.ZIndex = 4; icon.Parent = b
	ItemViewport.set(icon, "Pot_" .. d.key, 1.15)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.new(0.5, 0, 0, SIZE - 4)
	t.Size = UDim2.fromOffset(SIZE + 20, 26); t.FontFace = HEAVY; t.TextSize = 21; t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = ""; t.ZIndex = 5
	local st = Instance.new("UIStroke"); st.Color = INK; st.Thickness = 2.5; st.Parent = t
	t.Parent = b
	b.Parent = root
	-- поява: значок «вистрибує»
	local us = Instance.new("UIScale"); us.Scale = 0.4; us.Parent = b
	game:GetService("TweenService"):Create(us, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	return { root = b, timer = t }
end

local function fmt(sec: number): string
	sec = math.ceil(sec)
	local h = math.floor(sec / 3600)
	local m = math.floor(sec % 3600 / 60)
	local s = sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

-- Lucky Roll у запасі (LuckRoll10 / LuckRoll99): значок конюшини з «xN» замість таймера, поки є хоч один
local LUCKY = {
	{ key = "LuckRoll10", text = "x10", tone = Color3.fromHex("ffd23a"), icon = "rbxassetid://124578338510174" },   -- shop_luckroll10.png (жовта конюшина)
	{ key = "LuckRoll99", text = "x99", tone = Color3.fromHex("c99bff"), icon = "rbxassetid://120776574619004" },   -- shop_luckroll99.png (фіолетова конюшина)
}
local luckyBadges: { [string]: Badge } = {}
local function updateLucky()
	for i, l in LUCKY do
		local n = tonumber(player:GetAttribute(l.key)) or 0
		local bd = luckyBadges[l.key]
		if n > 0 then
			if not bd then
				bd = makeBadge(100 + i, { key = l.key, tone = l.tone, icon = l.icon })
				local ic = bd.root:FindFirstChildOfClass("ImageLabel")
				if ic then local vp = ic:FindFirstChild("ItemVP"); if vp then vp:Destroy() end; ic.Image = l.icon end
				luckyBadges[l.key] = bd
			end
			bd.timer.Text = l.text .. (n > 1 and (" ×" .. n) or "")
			bd.timer.TextColor3 = l.tone
		elseif bd then
			bd.root:Destroy(); luckyBadges[l.key] = nil
		end
	end
end
for _, l in LUCKY do player:GetAttributeChangedSignal(l.key):Connect(updateLucky) end
updateLucky()

local acc = 0
local function update()
	for i, d in Items.POTIONS do
		local left = Items.boostLeft(player, d.key)
		local b = badges[d.key]
		if left > 0 then
			if not b then b = makeBadge(i, d); badges[d.key] = b end
			b.timer.Text = fmt(left)
			b.timer.TextColor3 = left <= 10 and Color3.fromHex("ff8a8a") or Color3.new(1, 1, 1)
		elseif b then
			b.root:Destroy()
			badges[d.key] = nil
		end
	end
end
update()
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 then return end
	acc = 0
	update()
end)
