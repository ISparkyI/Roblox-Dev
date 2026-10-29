--!nonstrict
-- BossPortalClient — портал на арену боса в кінці зали (Workspace/Cave/Hub/BossPortal). 29.10.2026, v2 (арка).
-- Кам'яна арка (Arch: стовпи з каменів, дуга, замковий камінь) з порталом усередині (Core: Plane + PlaneTop, Spiral).
-- Без анімацій відкриття/закриття (рішення користувача): спіраль крутиться, світло «дихає», промені з порталу
-- центр — червоно-біле світіння; коли бос з'явився (Workspace.BossAt … BossOpenUntil,
-- BossPortalService) — усе яскравіше й швидше. Табличка BOSS FIGHT: таймер до боса / BOSS IS HERE!, COMING SOON.
-- Коло перед аркою — тост «Boss Arena — coming soon» (арени ще немає). Кнопка Boss у HUD (UIEvents/HUDButton "Boss") —
-- телепорт до входу (Remotes/BossPortalAction "TP").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local hub = workspace:WaitForChild("Cave"):WaitForChild("Hub")
local portal = hub:WaitForChild("BossPortal", 60)
if not portal then return end
local core = portal:WaitForChild("Core")
local light = core:WaitForChild("Glow"):FindFirstChildOfClass("PointLight")
local embers = core:WaitForChild("Embers"):FindFirstChildOfClass("ParticleEmitter")
local ringCenter = portal:WaitForChild("Ring"):WaitForChild("RingCenter")
local sign = portal:WaitForChild("SignAnchor"):WaitForChild("BossSign")
local timerLbl = sign:WaitForChild("Timer")
local titleLbl = sign:WaitForChild("Title")

local spiralCenter = core:WaitForChild("SpiralCenter")
local center = spiralCenter.Position
local HW = spiralCenter:GetAttribute("HalfW") or 7.4 -- півширина / піввисота отвору порталу (спіраль витягнута по ньому)
local HH = spiralCenter:GetAttribute("HalfH") or 14.6

-- спіраль: кожен рукав — кілька довгих гладких кривих (Beam з кривизною Безьє), без коротких відрізків;
-- витягнута по формі отвору, крутиться; ближче до верху й низу — прозоріша
local spiralFolder = Instance.new("Folder")
spiralFolder.Name = "BossPortalSpiral"
spiralFolder.Parent = workspace
local spRoot = Instance.new("Part")
spRoot.Name = "SpiralRoot"; spRoot.Anchored = true; spRoot.CanCollide = false; spRoot.CanQuery = false; spRoot.CanTouch = false
spRoot.Transparency = 1; spRoot.Size = Vector3.new(0.2, 0.2, 0.2)
spRoot.CFrame = CFrame.new()
spRoot.Parent = spiralFolder
local ARMS, TURNS, STEP = 3, 1.3, math.pi / 4
local LAYERS = { 1, 0.86, 0.72, 0.59, 0.47, 0.35, 0.24, 0.13 } -- багато тонких кроків — драбинки не видно -- ширина шарів (частка) — від країв до центру смуги
local LAYER_A = 0.14 -- непрозорість одного шару (накладаються) -- рукави, витки, кут однієї кривої
local NSEG = math.ceil(TURNS * 2 * math.pi / STEP)
local TH_MAX = NSEG * STEP
local arms = {}
for a = 1, ARMS do
	local pts, segs = {}, {}
	for k = 0, NSEG do
		local at = Instance.new("Attachment"); at.Parent = spRoot
		pts[k] = at
	end
	for k = 1, NSEG do
		local function mk(wk: number)
			local bm = Instance.new("Beam")
			bm.Attachment0 = pts[k - 1]; bm.Attachment1 = pts[k]
			bm.FaceCamera = false; bm.Segments = 20; bm.LightEmission = 1; bm.LightInfluence = 0
			bm.Width0 = wk; bm.Width1 = wk
			bm.Parent = spRoot
			return bm
		end
		local r0, r1 = (k - 1) / NSEG, k / NSEG
		-- 5 шарів на одній кривій: ширші — прозоріші, вузькі — яскравіші → поперек смуги плавно 0 → 100 → 0
		local layers = {}
		for li, f in LAYERS do
			local bm = mk(1)
			local hot = (li - 1) / (#LAYERS - 1) -- 0 зовнішній … 1 серцевина
			local c0 = Color3.fromHex("c0101a"):Lerp(Color3.fromHex("ffd8b8"), hot * (1 - r0 * 0.6))
			local c1 = Color3.fromHex("c0101a"):Lerp(Color3.fromHex("ffd8b8"), hot * (1 - r1 * 0.6))
			bm.Color = ColorSequence.new(c0, c1)
			layers[li] = { beam = bm, f = f }
		end
		segs[k] = { layers = layers, r0 = r0, r1 = r1 }
	end
	arms[a] = { pts = pts, segs = segs, off = (a - 1) * 2 * math.pi / ARMS }
end
local centerDiscs = {}
for i, d in {} do -- диски центру прибрано (29.10.2026): центр — там, де сходяться рукави
	local p = Instance.new("Part")
	p.Name = "CenterGlow"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Shape = Enum.PartType.Cylinder; p.Material = Enum.Material.Neon
	p.Color = Color3.fromHex(d[2]); p.Transparency = d[3]
	local dia = d[1] * HW * 2
	p.Size = Vector3.new(0.05, dia, dia)
	p.CFrame = CFrame.new(center + Vector3.new(0, 0, 0.1 + i * 0.05)) * CFrame.Angles(0, math.pi / 2, 0)
	p.Parent = spiralFolder
	centerDiscs[i] = { part = p, tr = d[3], dia = dia }
end
local function centerStep(t: number, power: number)
	local pulse = 0.5 + 0.5 * math.sin(t * 2.4)
	for i, d in centerDiscs do
		local k = 1 + 0.08 * pulse * (5 - i) / 4 + (power - 0.6) * 0.3
		d.part.Size = Vector3.new(0.05, d.dia * k, d.dia * k)
		d.part.Transparency = math.clamp(d.tr + 0.1 * (1 - pulse), 0, 1)
	end
end
local function radius(th: number): number return 0.04 + 0.96 * th / TH_MAX end
local function point(th: number, off: number): (number, number)
	local r = radius(th)
	return math.cos(th + off) * r * HW, math.sin(th + off) * r * HH
end
local function spiralStep(t: number, speed: number, power: number)
	local rot = -t * speed
	for _, arm in arms do
		local off = arm.off + rot
		local ys = {}
		for k = 0, NSEG do
			local th = k * STEP
			local x, y = point(th, off)
			local x1, y1 = point(th - 0.001, off)
			local x2, y2 = point(th + 0.001, off)
			local tan = Vector3.new(x2 - x1, y2 - y1, 0).Unit
			local p = center + Vector3.new(x, y, 0)
			arm.pts[k].WorldCFrame = CFrame.fromMatrix(p, tan, Vector3.new(0, 0, 1):Cross(tan))
			ys[k] = math.abs(y) / HH
		end
		for k = 1, NSEG do
			local sg = arm.segs[k]
			-- кривизна Безьє: дуга STEP → контрольні точки на дотичних
			local th0, th1 = (k - 1) * STEP, k * STEP
			-- кубічна крива Ерміта: контрольні точки = швидкість × крок / 3 (стики без зламів)
			local function speedAt(th: number): number
				local e = 0.001
				local x1, y1 = point(th - e, off); local x2, y2 = point(th + e, off)
				return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) / (2 * e)
			end
			local cs0, cs1 = speedAt(th0) * STEP / 3, speedAt(th1) * STEP / 3
			local w0, w1 = (0.5 + sg.r0 * 4.2) * HW / 11.5, (0.5 + sg.r1 * 4.2) * HW / 11.5
			local xm, ym = point((th0 + th1) / 2, off)
			local function vis(yy: number, r: number)
				-- зовнішній кінець плавно тане; ближче до центру — яскравіше (рукави сходяться в центрі)
				local outer = math.clamp((1 - r) / 0.3, 0, 1)
				outer = outer * outer * (3 - 2 * outer)
				local inner = 1 + 0.8 * math.clamp(1 - r / 0.25, 0, 1)
				return math.min(1.6, math.clamp(1 - yy ^ 1.4, 0, 1) ^ 1.5 * outer * inner * (0.75 + 0.25 * power))
			end
			local v0, vm, v1 = vis(ys[k - 1], sg.r0), vis(math.abs(ym) / HH, (sg.r0 + sg.r1) / 2), vis(ys[k], sg.r1)
			for _, L in sg.layers do
				local bm = L.beam
				bm.CurveSize0 = cs0; bm.CurveSize1 = cs1
				bm.Width0 = w0 * L.f; bm.Width1 = w1 * L.f
				bm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - LAYER_A * v0), NumberSequenceKeypoint.new(0.5, 1 - LAYER_A * vm), NumberSequenceKeypoint.new(1, 1 - LAYER_A * v1) })
			end
		end
	end
end

local function fmt(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%02d:%02d", sec // 60, sec % 60)
end

local power = 0.6 -- 0.6 звичайно, 1 — бос з'явився (плавно)
local lastT = os.clock()
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local dt = math.min(0.1, t - lastT); lastT = t
	local now = workspace:GetServerTimeNow()
	local at = workspace:GetAttribute("BossAt")
	local openUntil = workspace:GetAttribute("BossOpenUntil")
	local isOpen = type(openUntil) == "number" and now < openUntil
	power += ((isOpen and 1 or 0.6) - power) * math.min(1, dt * 1.5)

	spiralStep(t, 0.9 + (power - 0.6) * 4, power)
	local pulse = 0.5 + 0.5 * math.sin(t * 1.8)
	if light then light.Brightness = 1.6 + pulse * 0.8 + (power - 0.6) * 3; light.Range = 20 + (power - 0.6) * 15 end
	if embers then embers.Rate = 8 + (power - 0.6) * 100 end

	centerStep(t, power)

	if isOpen then
		timerLbl.Text = "BOSS IS HERE!"
		timerLbl.TextColor3 = Color3.fromHex("ff6a5a")
	else
		timerLbl.Text = type(at) == "number" and fmt(at - now) or "--:--"
		timerLbl.TextColor3 = Color3.new(1, 1, 1)
	end
	local soon = (not isOpen) and type(at) == "number" and at - now < 10
	titleLbl.Rotation = soon and math.sin(t * 30) * 2 or 0
end)

-- коло: арени ще немає
local uiEvents = RS:WaitForChild("UIEvents", 30)
local toast = uiEvents and uiEvents:WaitForChild("Toast", 30)
local inside = false
task.spawn(function()
	while true do
		task.wait(0.2)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local now = false
		if hrp then
			local d = (hrp.Position - ringCenter.Position) * Vector3.new(1, 0, 1)
			now = d.Magnitude < 13.8 and math.abs(hrp.Position.Y - ringCenter.Position.Y) < 8
		end
		if now and not inside and toast then
			toast:Fire("BOSS ARENA — COMING SOON!", Color3.fromHex("ff5a4a"))
		end
		inside = now
	end
end)

-- кнопка Boss у HUD: телепорт до входу
local hudEvent = uiEvents and uiEvents:WaitForChild("HUDButton", 30)
local remotes = RS:WaitForChild("Remotes", 30)
local action = remotes and remotes:WaitForChild("BossPortalAction", 30)
if hudEvent and action then
	hudEvent.Event:Connect(function(key)
		if key == "Boss" then action:FireServer("TP") end
	end)
end
