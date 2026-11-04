--!nonstrict
-- TeleportHUD — 3 кнопки телепорту зверху по центру екрана (в один ряд з кнопками Roblox і верхнім рядом MainHUD). 29.10.2026.
-- Де: StarterPlayer/StarterPlayerScripts/TeleportHUD (LocalScript). Сервер — StallShopService (Remotes/StallShopAction "Teleport", ціль):
--   SHOP   (синя)   — перед лавками DIAMONDS / EVENTS SHOP (Cave/Hub/Shops), обличчям до них;
--   HOME   (зелена, найбільша) — додому, на PlotSpawn своєї ніші;
--   MARKET (жовта)   — у центр кола Marketplace трохи в повітрі (одразу стартує відлік переходу).
-- Стиль — кнопки StyleA (візерунок studs), чорна тінь, текст Montserrat Heavy з обводкою #14161a.
-- Режим маркету (HubConfig.isMarket, 03.11.2026): лише HOME — телепорт назад у печеру (Remotes/MarketplaceTP "home").
-- Арена боса (атрибут гравця InBossArena, BossPortalService; 03.11.2026): SHOP і MARKET сховані, замість HOME — червона EXIT:
--   вікно підтвердження «LEAVE BOSS ARENA?» (EXIT / STAY) → Remotes/BossPortalAction "Exit" — на свій плот.
local HubCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("HubConfig"))
local MARKET = HubCfg.isMarket()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Shared = RS:WaitForChild("Shared")
local StyleA = require(Shared:WaitForChild("StyleA"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local C = Color3.fromHex
local INK = C("14161a")
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)

local ITEMS = {
	-- s — множник розміру кнопки (v3, 29.10.2026: усі ×1,15, HOME ×1,25 — головна); MARKET — жовта
	{ key = "shop", text = "SHOP", color = "blue", s = 1.15 },
	{ key = "home", text = "HOME", color = "green", s = 1.25 },
	{ key = "market", text = "MARKET", color = "yellow", s = 1.15 },
}
-- 03.11.2026 (рішення користувача): у печері SHOP / HOME / MARKET зверху прибрані; лишаються EXIT на арені боса і HOME на Marketplace
local NORMAL_ITEMS = {}
if MARKET then ITEMS = { { key = "home", text = "HOME", color = "green", s = 1.25 } } end
local ARENA_ITEMS = { { key = "exit", text = "EXIT", color = "red", s = 1.25 } }
local function itemsNow()
	if MARKET then return ITEMS end
	return player:GetAttribute("InBossArena") == true and ARENA_ITEMS or NORMAL_ITEMS
end
local W, H, GAP, CY = 176, 52, 14, 42 -- базовий розмір (× s), реальні пікселі; CY — центр ряду по вертикалі

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end

local old = pg:FindFirstChild("TeleportHUD"); if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "TeleportHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4 }, pg)
local total, maxH = 0, 0
local row = new("Frame", { Name = "Row", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, CY),
	Size = UDim2.fromOffset(0, 0) }, gui)

-- ===== вікно підтвердження виходу з арени боса =====
local confirmGui = new("ScreenGui", { Name = "BossExitConfirm", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 60, Enabled = false }, pg)
local dim = new("TextButton", { Name = "Dim", Text = "", AutoButtonColor = false, BackgroundColor3 = BLACK, BackgroundTransparency = 0.45,
	Size = UDim2.fromScale(1, 1), ZIndex = 1 }, confirmGui)
local CW, CH = 460, 250
local panel = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(CW, CH),
	BackgroundColor3 = C("1f232b"), BorderSizePixel = 0, ZIndex = 2 }, confirmGui)
new("UIStroke", { Color = INK, Thickness = 5 }, panel)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("2c313b"), C("16191f")) }, panel)
local pScale = new("UIScale", {}, panel)
local ttl = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 40, TextColor3 = C("ff5a4d"), Text = "LEAVE BOSS ARENA?",
	Position = UDim2.fromOffset(0, 22), Size = UDim2.fromOffset(CW, 48), ZIndex = 3 }, panel)
new("UIStroke", { Color = INK, Thickness = 4, LineJoinMode = Enum.LineJoinMode.Round }, ttl)
local sub = new("TextLabel", { BackgroundTransparency = 1, FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold),
	TextSize = 22, TextColor3 = WHITE, Text = "You will return to your plot.", Position = UDim2.fromOffset(0, 76), Size = UDim2.fromOffset(CW, 30), ZIndex = 3 }, panel)
new("UIStroke", { Color = INK, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round }, sub)
local function confirmBtn(x: number, text: string, color: string, onClick)
	local BW, BH = 180, 66
	local holder = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, CH - BH - 34), Size = UDim2.fromOffset(BW, BH + 5), ZIndex = 3 }, panel)
	local sh = new("Frame", { BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(BW, BH), ZIndex = 3 }, holder)
	local b = StyleA.new(holder, { size = Vector2.new(BW, BH), position = Vector2.new(0, 0), color = color, clickable = true, zIndex = 4 })
	StyleA.follow(b, sh)
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 32, TextColor3 = WHITE, Text = text, Size = UDim2.fromOffset(BW, BH - 4), ZIndex = 8 }, b.root)
	new("UIStroke", { Color = INK, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	StyleA.bind(b, { debounce = 0.4, onClick = onClick })
end
local function closeConfirm() confirmGui.Enabled = false end
confirmBtn(36, "EXIT", "red", function()
	closeConfirm()
	local rem = RS:FindFirstChild("Remotes")
	local ev = rem and rem:FindFirstChild("BossPortalAction")
	if ev then ev:FireServer("Exit"); UISounds.play("claim", 0.1) end
end)
confirmBtn(CW - 36 - 180, "STAY", "gray", closeConfirm)
dim.MouseButton1Click:Connect(closeConfirm)
local function openConfirm()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
	pScale.Scale = math.clamp(math.min(vs.X / (CW + 60), vs.Y / (CH + 120)), 0.55, 1.2)
	confirmGui.Enabled = true
	UISounds.play("tap", 0.1)
end
player:GetAttributeChangedSignal("InBossArena"):Connect(function() if player:GetAttribute("InBossArena") ~= true then closeConfirm() end end)

local busy = false
local function go(key: string)
	if key == "exit" then openConfirm(); return end
	if busy then return end
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild(MARKET and "MarketplaceTP" or "StallShopAction")
	if not rf then return end
	busy = true
	local ok, res
	if MARKET then ok, res = pcall(rf.InvokeServer, rf, "home") else ok, res = pcall(rf.InvokeServer, rf, "Teleport", key) end
	busy = false
	if ok and type(res) == "table" and res.ok then
		UISounds.play("claim", 0.1)
	elseif not (ok and type(res) == "table" and res.err == "busy") then
		toast("Can't teleport right now", "red", "deny")
	end
end

local fit -- нижче
local function buildRow()
	for _, c in row:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	local list = itemsNow()
	total, maxH = math.max(0, #list - 1) * GAP, 0
	for _, it in list do total += math.floor(W * it.s); maxH = math.max(maxH, math.floor(H * it.s)) end
	row.Size = UDim2.fromOffset(total, maxH)
local x = 0
for _, it in list do
	local W, H = math.floor(W * it.s), math.floor(H * it.s)
	local holder = new("Frame", { Name = it.text, BackgroundTransparency = 1, Position = UDim2.fromOffset(x, (maxH - H) / 2), Size = UDim2.fromOffset(W, H + 4) }, row)
	x += W + GAP
	local sh = new("Frame", { Name = "Shadow", BackgroundColor3 = BLACK, BackgroundTransparency = 0.7, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(W, H), ZIndex = 1 }, holder)
	local b = StyleA.new(holder, { size = Vector2.new(W, H), position = Vector2.new(0, 0), color = it.color, clickable = true, zIndex = 2 })
	StyleA.follow(b, sh)
	local t = new("TextLabel", { Name = "Label", BackgroundTransparency = 1, FontFace = HEAVY, TextSize = math.floor(28 * it.s), TextColor3 = WHITE, Text = it.text,
		Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(W, H - 4), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7 }, b.root)
	new("UIStroke", { Color = INK, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	StyleA.bind(b, { debounce = 0.4, onClick = function() go(it.key) end })
end
	if fit then fit() end
end
buildRow()
player:GetAttributeChangedSignal("InBossArena"):Connect(buildRow)

-- ===== адаптивність =====
-- Ряд завжди у верхньому ряду: рівно посередині між верхніми іконками зліва й справа (і кнопками Roblox) та на їхній висоті;
-- зменшується під вільне місце на будь-якій роздільній здатності (телефон, планшет, ПК).
local GuiService = game:GetService("GuiService")
local fitScale = new("UIScale", {}, row)
-- 03.11.2026: сусіди — ЛИШЕ верхній ряд MainHUD (MainHUD/TopRow), а не всі кнопки екрана: раніше відкрите вікно (SHOP,
--   інвентар тощо) зі своїми вкладками близько до верху теж вважалося сусідом, і ряд стрибав та зменшувався.
--   Ряд завжди по центру екрана; зменшується не нижче MIN_INLINE; так і не вміщається — опускається під верхній ряд (не налазить).
local MIN_INLINE = 0.6 -- менше цього не стискаємо
local function shown(o: Instance): boolean
	while o and o:IsA("GuiObject") do
		if not o.Visible then return false end
		o = o.Parent
	end
	return true
end
local function topButtons(): { { p: Vector2, s: Vector2 } }
	-- усі ScreenGui рахують AbsolutePosition в одному просторі, тому віднімаємо позицію нашого gui — виходять координати як у row.Position
	local list, origin = {}, gui.AbsolutePosition
	local hud = pg:FindFirstChild("MainHUD")
	local top = hud and hud:FindFirstChild("TopRow")
	if not top then return list end
	for _, o in top:GetDescendants() do
		if o:IsA("GuiButton") and o.AbsoluteSize.X > 8 and o.AbsoluteSize.X < 420 and o.AbsoluteSize.Y < 220 and shown(o) then
			local p = o.AbsolutePosition - origin
			if p.Y < 260 then table.insert(list, { p = p, s = o.AbsoluteSize }) end
		end
	end
	return list
end
function fit()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vw = cam.ViewportSize.X
	local cx = vw / 2
	-- верхній ряд іконок інших HUD (центр іконки у верхній смузі екрана)
	local left, right = 0, vw
	local ok, tb = pcall(function() return GuiService.TopbarInset end)
	if ok and tb then
		left = math.max(left, tb.Min.X)
		if tb.Max.X > tb.Min.X then right = math.min(right, tb.Max.X) end
	end
	local ySum, yN, bottom = 0, 0, 0
	for _, b in topButtons() do
		local my = b.p.Y + b.s.Y / 2
		if my > 0 and my < 80 and b.s.Y < 110 then
			if b.p.X + b.s.X / 2 < cx then left = math.max(left, b.p.X + b.s.X) else right = math.min(right, b.p.X) end
			ySum += my; yN += 1
			bottom = math.max(bottom, b.p.Y + b.s.Y)
		end
	end
	-- ряд завжди по центру екрана; ширина — до ближчої з двох груп (симетрично), зменшення не нижче MIN_INLINE
	local MARGIN = 12
	local half = math.min(cx - left, right - cx) - MARGIN
	local k = math.clamp(2 * half / total, MIN_INLINE, 1)
	fitScale.Scale = k
	local cy = yN > 0 and ySum / yN or CY
	if total * k > 2 * half and yN > 0 then
		-- навіть на MIN_INLINE не вміщається (вузький телефон) — під верхній ряд, без накладання
		cy = bottom + 8 + maxH * k / 2
	end
	row.Position = UDim2.new(0, cx, 0, cy)
end
local camConn
local function bindCam()
	if camConn then camConn:Disconnect() end
	local cam = workspace.CurrentCamera
	if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCam)
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fit) end)
bindCam()
task.spawn(function() -- інші HUD з'являються пізніше й можуть ховати/показувати кнопки — перевіряємо раз на секунду
	while gui.Parent do task.wait(1); fit() end
end)
