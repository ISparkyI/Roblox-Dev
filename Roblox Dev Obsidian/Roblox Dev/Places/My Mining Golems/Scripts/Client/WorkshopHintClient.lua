--!nonstrict
-- WorkshopHintClient — проміжна підказка «Workshop» (08.11.2026). Де: StarterPlayer/StarterPlayerScripts/WorkshopHintClient (LocalScript).
-- Лише ОДИН раз за всю гру (атрибут гравця WsHintDone, зберігає DataService; ставить ForgeService на ForgeAction "HintDone").
-- Коли: навчання пройдене (TutorialDone, TutStep = nil), голем майстерні своєї ніші спить (Forge State = "Asleep") і в інвентарі
--   вже є стільки руди, щоб закрити хоча б один рядок пробудження (Ore_<руда> ≥ потрібно − уже віддано Wake_<руда>).
-- Що показуємо (без слів): золоті стрілки на підлозі під гравцем у бік кола Workshop; над колом — знак оклику, що пульсує;
--   від кола розходяться світлі кола й гаснуть («підійди сюди»).
-- Кінець: гравець став у коло (там відкривається вікно Workshop) → ForgeAction "HintDone", усе прибирається. Нагороди немає.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local okH, Hub = pcall(require, RS.Shared:WaitForChild("HubConfig"))
if okH and Hub and Hub.isMarket and Hub.isMarket() then return end -- на маркеті майстерні немає
if player:GetAttribute("WsHintDone") == true then return end

local GOLD = Color3.fromHex("ffd23a")
local CYAN = Color3.fromHex("22e4f5")
local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local RING_R = Cfg.RING_R
local NEAR = 12 -- ближче до кола — стрілки під гравцем ховаються (коло й знак уже видно)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local function myForge(): Model?
	local f = workspace:FindFirstChild("Niches")
	if not f then return nil end
	for _, m in f:GetChildren() do
		if m:GetAttribute("OwnerUserId") == player.UserId then return m:FindFirstChild("Forge") :: Model? end
	end
	return nil
end
local function ringCenter(f: Model?): BasePart?
	local r = f and f:FindFirstChild("Ring")
	local c = r and r:FindFirstChild("RingCenter")
	return (c and c:IsA("BasePart")) and c or nil
end

-- чи пора: є руда, щоб закрити хоча б один рядок пробудження
local function wanted(f: Model?): boolean
	if player:GetAttribute("WsHintDone") == true or player:GetAttribute("TutorialDone") ~= true or player:GetAttribute("TutStep") ~= nil then return false end
	if player:GetAttribute("InBossArena") == true then return false end
	if not f or f:GetAttribute("State") ~= "Asleep" then return false end
	for i, o in Cfg.ORES do
		local need = (Cfg.WAKE_REQ[i] or 0) - (tonumber(f:GetAttribute("Wake_" .. o.key)) or 0)
		if need > 0 and (tonumber(player:GetAttribute("Ore_" .. o.key)) or 0) >= need then return true end
	end
	return false
end

-- ===== візуал =====
local fx = new("Folder", { Name = "WorkshopHintFX" }, workspace)
-- стрілки на підлозі (як у навчанні): 6 «шевронів» з двох неонових смужок
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

-- кола, що розходяться від кола Workshop: SurfaceGui на прозорій пластині над підлогою
local SPAN = 1.6 -- полотно = SPAN × діаметр кола (місце для розширення)
local plate = new("Part", { Name = "HintRings", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	Transparency = 1, Size = Vector3.new(RING_R * 2 * SPAN, 0.05, RING_R * 2 * SPAN) }, fx)
local sg = new("SurfaceGui", { Face = Enum.NormalId.Top, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 20,
	LightInfluence = 0, AlwaysOnTop = false, Adornee = plate, ResetOnSpawn = false, ClipsDescendants = false }, player:WaitForChild("PlayerGui"))
sg.Name = "WorkshopHintRings"
local waves = {}
for i = 1, 3 do
	local w = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1 / SPAN, 1 / SPAN),
		BackgroundTransparency = 1 }, sg)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, w)
	local st = new("UIStroke", { Color = CYAN, Thickness = 14, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, w)
	waves[i] = { f = w, s = st }
end

-- знак оклику над колом: пульсує (більшає й меншає)
local anchor = new("Part", { Name = "HintMark", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1,
	Size = Vector3.one * 0.2 }, fx)
local bb = new("BillboardGui", { Name = "WorkshopHintMark", Adornee = anchor, Size = UDim2.fromScale(4, 6), AlwaysOnTop = false, LightInfluence = 0,
	MaxDistance = 400, ResetOnSpawn = false, Enabled = false }, player.PlayerGui)
local markRoot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bb)
local markScale = new("UIScale", {}, markRoot)
local mark = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "!", TextScaled = true, FontFace = HEAVY,
	TextColor3 = Color3.new(1, 1, 1), AutoLocalize = false }, markRoot)
new("UIStroke", { Color = INK, Thickness = 6, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }, mark)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("fff3b0")), ColorSequenceKeypoint.new(0.55, GOLD),
	ColorSequenceKeypoint.new(1, Color3.fromHex("ff9a1f")) }) }, mark)

local function setShown(on: boolean)
	bb.Enabled = on
	sg.Enabled = on
	if not on then hideChev() end
end
setShown(false)

local active = false
local doneSent = false
-- 08.11.2026: reached = true — гравець дійшов до кола: далі у вікні Workshop блимає кнопка Give Ore (ForgeWindow, атрибут гравця
--   WsHintGive, лише на клієнті); натиснув її — ForgeWindow шле Remotes/HintAction "Done" (зберігається WsHintDone, Funnels).
--   reached = false — підказка вже не потрібна (голем прокинувся іншим шляхом / уже пройдено).
-- Funnels (AnalyticsFunnels): Hint_Workshop — 1 Hint shown · 2 Reached workshop · 3 Gave ore · 4 Woke golem.
local function finish(reached: boolean?)
	if doneSent then return end
	doneSent = true
	active = false
	setShown(false)
	local h = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("HintAction")
	if reached then
		if h then h:FireServer("Step", "Workshop", 2) end
		player:SetAttribute("WsHintGive", true)
	elseif h and player:GetAttribute("WsHintDone") ~= true then
		h:FireServer("Done", "Workshop")
	end
	task.delay(0.5, function() fx:Destroy(); sg:Destroy(); bb:Destroy() end)
end

local function floorY(hrp: BasePart): number
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return hrp.Position.Y - (hum and hum.HipHeight or 2) - hrp.Size.Y / 2 + 0.08
end

-- перевірка умови — раз на 0,5 с; анімація — щокадру
task.spawn(function()
	while not doneSent do
		local f = myForge()
		if not active and wanted(f) then
			active = true
			local h = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("HintAction")
			if h then h:FireServer("Step", "Workshop", 1) end
		end
		if active and (player:GetAttribute("WsHintDone") == true) then finish() end
		if active and f and f:GetAttribute("State") ~= "Asleep" then finish() end -- розбудив іншим шляхом — підказка вже не потрібна
		task.wait(0.5)
	end
end)

RunService.RenderStepped:Connect(function()
	if not active or doneSent then return end
	local f = myForge()
	local rc = ringCenter(f)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (rc and hrp) or player:GetAttribute("InBossArena") == true then setShown(false); return end
	setShown(true)
	local t = os.clock()
	local center = rc.Position
	local groundY = center.Y - rc.Size.Y / 2
	-- коло: пластина трохи над підлогою
	plate.CFrame = CFrame.new(center.X, groundY + 0.12, center.Z)
	for i, w in waves do
		local p = ((t / 1.6) + (i - 1) / #waves) % 1
		local k = 1 + 0.45 * p
		w.f.Size = UDim2.fromScale(k / SPAN, k / SPAN)
		-- плавна поява на старті й згасання до кінця (без стрибка видимості, коли коло перезапускається)
		local a = math.clamp(p / 0.12, 0, 1) * (1 - p) ^ 1.5
		w.s.Transparency = 1 - 0.85 * a
	end
	-- знак оклику: над колом, пульсує й легко гойдається
	anchor.CFrame = CFrame.new(center.X, groundY + 6.5 + math.sin(t * 2.4) * 0.35, center.Z)
	markScale.Scale = 1 + 0.18 * math.sin(t * 5)
	-- стрілки під гравцем у бік кола
	local d = Vector3.new(center.X - hrp.Position.X, 0, center.Z - hrp.Position.Z)
	if d.Magnitude <= RING_R + 2.5 and math.abs(hrp.Position.Y - center.Y) < 10 then finish(true); return end -- став у коло — відкривається Workshop
	if d.Magnitude < NEAR then hideChev(); return end
	local dir = d.Unit
	local y = floorY(hrp)
	local shift = (t * 5) % 3.5
	-- стрілки лягають на верх того, що під ними (сходинки, плити) — не ховаються в текстурі
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { player.Character, fx }
	rp.RespectCanCollide = true
	local maxD = d.Magnitude - RING_R
	for i, c in chev do
		local dd = 3 + (i - 1) * 3.5 + shift
		local a = math.clamp(1 - math.abs(dd - 12) / 12, 0, 1)
		if dd > maxD then a = 0 end
		local base = Vector3.new(hrp.Position.X, y, hrp.Position.Z) + dir * dd
		local hit = workspace:Raycast(base + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rp)
		if hit then base = Vector3.new(base.X, hit.Position.Y + 0.06, base.Z) end
		local cf = CFrame.lookAt(base, base + dir)
		c.L.CFrame = cf * CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 0, 0.55)
		c.R.CFrame = cf * CFrame.Angles(0, math.rad(-40), 0) * CFrame.new(0, 0, 0.55)
		c.L.Transparency = 1 - 0.65 * a; c.R.Transparency = 1 - 0.65 * a
	end
end)
