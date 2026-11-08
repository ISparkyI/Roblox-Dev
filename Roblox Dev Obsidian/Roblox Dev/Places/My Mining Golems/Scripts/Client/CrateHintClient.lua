--!nonstrict
-- CrateHintClient — проміжна підказка «Collect» (08.11.2026). Де: StarterPlayer/StarterPlayerScripts/CrateHintClient (LocalScript).
-- Лише ОДИН раз за всю гру (атрибут гравця CrateHintDone, зберігає DataService; ставить AnalyticsFunnels на Remotes/HintAction "Done").
-- Коли: навчання пройдене (TutorialDone, TutStep = nil) і ящик (Crate) на одному з відкритих плотів своєї ніші заповнився
--   (атрибути плоту CrateCount ≥ CrateCap).
-- Що показуємо (без слів): золоті стрілки на підлозі під гравцем у бік цього ящика, над ящиком — знак оклику, що пульсує,
--   сам ящик — золота обвідка, що блимає; біля ящика кнопка COLLECT теж блимає золотою рамкою (PlotClient, атрибут CrateHintOn).
-- Кінець: зібрав руду з цього ящика (атрибут плоту CollectT) → HintAction "Done" ("Crate"). Нагороди немає.
-- Funnels (AnalyticsFunnels): Hint_Crate — 1 Hint shown · 2 Collected.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local okH, Hub = pcall(require, RS:WaitForChild("Shared"):WaitForChild("HubConfig"))
if okH and Hub and Hub.isMarket and Hub.isMarket() then return end -- на маркеті плотів немає
if player:GetAttribute("CrateHintDone") == true then return end

local GOLD = Color3.fromHex("ffd23a")
local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local NEAR = 10 -- ближче до ящика — стрілки під гравцем ховаються

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function hintRemote(): RemoteEvent?
	local r = RS:FindFirstChild("Remotes")
	return r and r:FindFirstChild("HintAction") :: RemoteEvent?
end

local function myPlots(): { Instance }
	local f = workspace:FindFirstChild("Niches")
	if not f then return {} end
	for _, m in f:GetChildren() do
		if m:GetAttribute("OwnerUserId") == player.UserId then
			local p = m:FindFirstChild("Plots")
			return p and p:GetChildren() or {}
		end
	end
	return {}
end
local function fullPlot(): Instance?
	if player:GetAttribute("CrateHintDone") == true or player:GetAttribute("TutorialDone") ~= true or player:GetAttribute("TutStep") ~= nil then return nil end
	if player:GetAttribute("InBossArena") == true then return nil end
	for _, pl in myPlots() do
		local n = tonumber(pl:GetAttribute("CrateCount")) or 0
		local cap = tonumber(pl:GetAttribute("CrateCap")) or 0
		if pl:GetAttribute("Unlocked") == true and cap > 0 and n >= cap and pl:FindFirstChild("Crate") then return pl end
	end
	return nil
end

-- ===== візуал =====
local fx = new("Folder", { Name = "CrateHintFX" }, workspace)
local chev = {}
for i = 1, 6 do
	local c = new("Model", { Name = "Chevron" }, fx)
	for s = -1, 1, 2 do
		new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon,
			Color = GOLD, Transparency = 1, Size = Vector3.new(0.35, 0.1, 1.6), Name = s < 0 and "L" or "R" }, c)
	end
	chev[i] = c
end
local function hideChev() for _, c in chev do c.L.Transparency = 1; c.R.Transparency = 1 end end
local hl = new("Highlight", { Name = "CrateHintHL", OutlineColor = GOLD, FillColor = GOLD, FillTransparency = 0.85, OutlineTransparency = 0,
	DepthMode = Enum.HighlightDepthMode.Occluded, Enabled = false }, fx)
local anchor = new("Part", { Name = "HintMark", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1,
	Size = Vector3.one * 0.2 }, fx)
local bb = new("BillboardGui", { Name = "CrateHintMark", Adornee = anchor, Size = UDim2.fromScale(3, 4.5), AlwaysOnTop = false, LightInfluence = 0,
	MaxDistance = 400, ResetOnSpawn = false, Enabled = false }, player:WaitForChild("PlayerGui"))
local markRoot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bb)
local markScale = new("UIScale", {}, markRoot)
local mark = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "!", TextScaled = true, FontFace = HEAVY,
	TextColor3 = Color3.new(1, 1, 1), AutoLocalize = false }, markRoot)
new("UIStroke", { Color = INK, Thickness = 6, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }, mark)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("fff3b0")), ColorSequenceKeypoint.new(0.55, GOLD),
	ColorSequenceKeypoint.new(1, Color3.fromHex("ff9a1f")) }) }, mark)

local function setShown(on: boolean)
	bb.Enabled = on
	hl.Enabled = on
	player:SetAttribute("CrateHintOn", on or nil) -- PlotClient: кнопка COLLECT блимає
	if not on then hideChev() end
end
setShown(false)

local target: Instance? = nil -- плот з повним ящиком
local doneSent = false
local collectConn: RBXScriptConnection? = nil
local function finish(collected: boolean)
	if doneSent then return end
	doneSent = true
	target = nil
	setShown(false)
	if collectConn then collectConn:Disconnect() end
	local h = hintRemote()
	if h and collected then h:FireServer("Done", "Crate") end
	task.delay(0.5, function() fx:Destroy(); bb:Destroy() end)
end

local function floorY(hrp: BasePart): number
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return hrp.Position.Y - (hum and hum.HipHeight or 2) - hrp.Size.Y / 2 + 0.08
end

-- умова — раз на 0,5 с; анімація — щокадру
task.spawn(function()
	while not doneSent do
		if player:GetAttribute("CrateHintDone") == true then finish(false); break end
		if not target then
			local pl = fullPlot()
			if pl then
				target = pl
				local h = hintRemote()
				if h then h:FireServer("Step", "Crate", 1) end
				-- зібрав з цього ящика (сервер ставить CollectT при Collect)
				collectConn = pl:GetAttributeChangedSignal("CollectT"):Connect(function() finish(true) end)
			end
		end
		task.wait(0.5)
	end
end)

RunService.RenderStepped:Connect(function()
	if doneSent or not target then return end
	local crate = target.Parent and target:FindFirstChild("Crate")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (crate and hrp) or player:GetAttribute("InBossArena") == true then setShown(false); return end
	setShown(true)
	local t = os.clock()
	if hl.Adornee ~= crate then hl.Adornee = crate end
	hl.OutlineTransparency = 0.1 + 0.6 * (0.5 + 0.5 * math.sin(t * 5))
	local cf, size = crate:GetBoundingBox()
	local top = cf.Position + Vector3.new(0, size.Y / 2, 0)
	anchor.CFrame = CFrame.new(top + Vector3.new(0, 4.5 + math.sin(t * 2.4) * 0.3, 0))
	markScale.Scale = 1 + 0.18 * math.sin(t * 5)
	-- стрілки під гравцем у бік ящика
	local d = Vector3.new(cf.Position.X - hrp.Position.X, 0, cf.Position.Z - hrp.Position.Z)
	if d.Magnitude < NEAR then hideChev(); return end
	local dir = d.Unit
	local y = floorY(hrp)
	local shift = (t * 5) % 3.5
	local maxD = d.Magnitude - 3
	-- стрілки лягають на верх того, що під ними (сходинки, плити) — не ховаються в текстурі
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { player.Character, fx }
	rp.RespectCanCollide = true
	for i, c in chev do
		local dd = 3 + (i - 1) * 3.5 + shift
		local a = math.clamp(1 - math.abs(dd - 12) / 12, 0, 1)
		if dd > maxD then a = 0 end
		local base = Vector3.new(hrp.Position.X, y, hrp.Position.Z) + dir * dd
		local hit = workspace:Raycast(base + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rp)
		if hit then base = Vector3.new(base.X, hit.Position.Y + 0.06, base.Z) end
		local ccf = CFrame.lookAt(base, base + dir)
		c.L.CFrame = ccf * CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 0, 0.55)
		c.R.CFrame = ccf * CFrame.Angles(0, math.rad(-40), 0) * CFrame.new(0, 0, 0.55)
		c.L.Transparency = 1 - 0.65 * a; c.R.Transparency = 1 - 0.65 * a
	end
end)
