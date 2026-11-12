--!nocheck
-- TrailerDirector — режисер трейлера (07.11.2026; v3 11.11.2026: підписи кадрів, кадри Cave і Marketplace, мутація з виходом голема). Лише Studio і лише коли workspace.TrailerMode = true; у живій грі не працює.
-- Сети готує ServerScriptService/TrailerServer (копії ніш Stage1..6 і арени в Workspace/TrailerSets, бос і Bacon у
--   ReplicatedStorage/TrailerAssets). Тут — камера (сплайни, easing, тряска, удари FOV), големи (Shared/GolemModel, анімує
--   їхній GolemAnimator; у режимі TrailerLive GolemAnimRunner анімує їх щокадру), події кадрів і спливаючі цифри.
-- Керування (Play у Studio):
--   F6 — увесь трейлер (спершу підготовка, потім відлік 3-2-1 на чорному екрані й старт);
--   F7 — лише підготовка (зібрати големів у всіх сетах); 1…9 — окремий кадр (8 Cave, 9 Marketplace); F8 — стоп і повернення камери.
--   Порядок у трейлері (F6): 1 2 3 4 5 8 9 6 7. Підписи (caption) — Luckiest Guy, жовто-помаранчеві, з плавною появою / зникненням.
--   _G.TrailerPeek(n, t) — поставити камеру кадру n на момент t (перевірка ракурсу).
-- Кадри: 1 Рол (ричаг → Secret-голем) · 2 Відліт над плотами з шахтарями · 3 Носильщики й гроші · 4 Шість світів ·
--   5 Машина мутацій · 6 Бій з босом (армія воїнів) · 7 Фінал (Bacon перед армією, дрон угору).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

if not RunService:IsStudio() or workspace:GetAttribute("TrailerMode") ~= true then return end

local player = Players.LocalPlayer
local Shared = RS:WaitForChild("Shared")
local GM = require(Shared:WaitForChild("GolemModel"))
local Boss = require(script:WaitForChild("TrailerBoss"))
local sets = workspace:WaitForChild("TrailerSets", 120)
local assets = RS:WaitForChild("TrailerAssets", 120)
local focusEv = assets:WaitForChild("Focus")
local PlotAssets = RS:WaitForChild("PlotAssets", 60)

local C = Color3.fromHex
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local LUCKY = Font.new("rbxasset://fonts/families/LuckiestGuy.json")
-- перед голема — −Z моделі (як у CFrame.lookAt)
local V3 = Vector3.new

local live = workspace:FindFirstChild("TrailerLive") or Instance.new("Folder")
live.Name = "TrailerLive"
live.Parent = workspace
local fx = workspace:FindFirstChild("TrailerFx") or Instance.new("Folder")
fx.Name = "TrailerFx"
fx.Parent = workspace

-- ================= утиліти =================
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local E = {
	lin = function(k) return k end,
	inout = function(k) return k < 0.5 and 2 * k * k or 1 - (-2 * k + 2) ^ 2 / 2 end,
	out = function(k) return 1 - (1 - k) ^ 2 end,
	out3 = function(k) return 1 - (1 - k) ^ 3 end,
	in2 = function(k) return k * k end,
	in3 = function(k) return k * k * k end,
	sine = function(k) return -(math.cos(math.pi * k) - 1) / 2 end,
}
local function clamp01(x) return math.clamp(x, 0, 1) end
local function seg(t, a, b) return clamp01((t - a) / (b - a)) end
local function lerp(a, b, k) return a + (b - a) * k end
-- Catmull-Rom по списку точок, u ∈ [0, 1]
local function spline(pts, u)
	local n = #pts
	if n == 1 then return pts[1] end
	local f = clamp01(u) * (n - 1)
	local i = math.min(math.floor(f) + 1, n - 1)
	local k = f - (i - 1)
	local p0, p1, p2, p3 = pts[math.max(i - 1, 1)], pts[i], pts[i + 1], pts[math.min(i + 2, n)]
	local k2, k3 = k * k, k * k * k
	return 0.5 * ((2 * p1) + (-p0 + p2) * k + (2 * p0 - 5 * p1 + 4 * p2 - p3) * k2 + (-p0 + 3 * p1 - 3 * p2 + p3) * k3)
end
local function look(pos, at, roll)
	local cf = CFrame.lookAt(pos, at)
	if roll and roll ~= 0 then cf *= CFrame.Angles(0, 0, roll) end
	return cf
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local function floorNear(pos: Vector3, within: Instance): number
	rayParams.FilterDescendantsInstances = { within }
	local r = workspace:Raycast(pos + V3(0, 1.5, 0), V3(0, -6, 0), rayParams)
	return r and r.Position.Y or pos.Y
end
local function floorAt(pos: Vector3, within: Instance?): number
	rayParams.FilterDescendantsInstances = { within or sets }
	local r = workspace:Raycast(pos + V3(0, 40, 0), V3(0, -120, 0), rayParams)
	return r and r.Position.Y or pos.Y
end

-- поставити модель стопами на точку pos (Y = підлога), обличчям до at (yaw); flip = false — без розвороту (не голем)
local function ground(m: Model, pos: Vector3, at: Vector3?, flip: boolean?)
	m:PivotTo(CFrame.new(m:GetPivot().Position))
	local bcf, sz = m:GetBoundingBox()
	local off = m:GetPivot().Position.Y - (bcf.Position.Y - sz.Y / 2)
	local cf = CFrame.new(pos)
	if at then
		local d = V3(at.X - pos.X, 0, at.Z - pos.Z)
		if d.Magnitude > 0.01 then cf = CFrame.lookAt(pos, pos + d) end
	end
	m:PivotTo(cf * CFrame.new(0, off, 0))
end

-- ================= големи =================
local function golem(kind: string, cls: string, mut: number?, scale: number?): Model?
	local ok, m = pcall(GM.build, kind, cls)
	if not ok or not m then warn("[Trailer] build", kind, m); return nil end
	if scale and math.abs(scale - 1) > 1e-3 then m:ScaleTo(m:GetScale() * scale) end
	if mut and mut > 0 then m:SetAttribute("Mut", mut) end
	m.Name = "TG_" .. kind
	return m
end
local function rootOf(m: Model): BasePart? return m:FindFirstChild("Root") :: BasePart? end
-- сховати під землю (не знімаємо з workspace: аніматор реєструється один раз)
local function hide(m: Model?)
	if not m then return end
	local p = m:GetPivot().Position
	m:PivotTo(CFrame.new(p.X, -400, p.Z))
end
local function setState(m: Model, st: string, speed: number?)
	m:SetAttribute("State", st)
	if speed then m:SetAttribute("AnimSpeed", speed) end
end
local function headTop(m: Model): Vector3
	local cf, sz = m:GetBoundingBox()
	return cf.Position + V3(0, sz.Y / 2, 0)
end
local function footOf(m: Model): number
	local ok, f = pcall(GM.footOffset, m)
	return ok and f or 0
end
-- перемістити голема (Root; аніматор ставить деталі від Root) — yaw у напрямі dir
local function moveGolem(m: Model, pos: Vector3, dir: Vector3, foot: number)
	local r = rootOf(m)
	if not r then return end
	local rel = m:GetAttribute("TRootRel")
	if not rel then
		rel = m:GetPivot():ToObjectSpace(r.CFrame)
		m:SetAttribute("TRootRel", rel)
	end
	local d = V3(dir.X, 0, dir.Z)
	if d.Magnitude < 1e-3 then d = V3(0, 0, -1) end
	local piv = CFrame.lookAt(pos, pos + d) * CFrame.new(0, foot, 0)
	r.CFrame = piv * rel
end

local function ore(names: { string }, idx: number, pos: Vector3, yaw: number, scale: number?): Model?
	local o = PlotAssets:FindFirstChild("Ores")
	local src = o and o:FindFirstChild(names[idx])
	if o and not src then
		for _, n in names do
			src = o:FindFirstChild(n) or o:FindFirstChild((n:gsub("_L$", "_M")))
			if src then break end
		end
	end
	src = src or (o and o:FindFirstChild("Coal_L"))
	if not src then return nil end
	local m = src:Clone()
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	if scale then m:ScaleTo(m:GetScale() * scale) end
	m.Parent = live
	ground(m, pos, pos + V3(math.sin(yaw), 0, math.cos(yaw)), false)
	return m
end

-- ================= Bacon =================
local function bacon(pos: Vector3, at: Vector3): any
	local src = assets:FindFirstChild("Bacon")
	if not src then return nil end
	local m = src:Clone()
	m.Parent = live
	ground(m, pos, at, false)
	local hrp = m:FindFirstChild("HumanoidRootPart")
	local b = { m = m, base = {}, root = hrp.CFrame }
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then b.base[p] = p.CFrame end end
	return b
end
local ARM = { R = { "RightUpperArm", "RightLowerArm", "RightHand" }, L = { "LeftUpperArm", "LeftLowerArm", "LeftHand" } }
local function shoulder(b, side: string): Vector3
	local att = b.m:FindFirstChild(side == "R" and "RightShoulderRigAttachment" or "LeftShoulderRigAttachment", true)
	return (b.base[att.Parent] * att.CFrame).Position
end
-- рука side ("R"/"L") спрямована у світовий напрям dir (від плеча)
local function baconArm(b, side: string, dir: Vector3)
	local pv = shoulder(b, side)
	local down = -b.root.UpVector
	local d = dir.Unit
	local axis = down:Cross(d)
	local ang = math.acos(math.clamp(down:Dot(d), -1, 1))
	local R = axis.Magnitude > 1e-4 and CFrame.fromAxisAngle(axis.Unit, ang) or CFrame.new()
	local T = CFrame.new(pv) * R * CFrame.new(-pv)
	for _, n in ARM[side] do
		local p = b.m:FindFirstChild(n)
		if p then p.CFrame = T * b.base[p] end
	end
end
local function baconRest(b, side: string)
	for _, n in ARM[side] do
		local p = b.m:FindFirstChild(n)
		if p then p.CFrame = b.base[p] end
	end
end
local function baconPlace(b, cf: CFrame)
	if not b.rel then
		b.root0 = b.root
		b.rel = {}
		for p, c in b.base do b.rel[p] = b.root:ToObjectSpace(c) end
	end
	b.root = cf
	for p, r in b.rel do
		local c = cf * r
		b.base[p] = c
		p.CFrame = c
	end
end
local function baconShock(b, on: boolean)
	local plate = b.m:FindFirstChild("ShockFace")
	local sg = plate and plate:FindFirstChildOfClass("SurfaceGui")
	if sg then sg.Enabled = on end
	local head = b.m:FindFirstChild("ClassicHead")
	local face = head and head:FindFirstChild("face")
	if face then face.Transparency = on and 1 or 0 end
end

local active = false
local quiet = false -- тиша під час прогріву за чорним екраном
local curShot = 0 -- який кадр зараз іде
local SFX_MASTER = 0.45 -- усі звуки трейлера — тихіше, фоном
local MUSIC_BOOST = 1.8 -- музика гри — голосніше
-- ================= звуки =================
-- Лише звуки, що вже є в грі: SoundService (LeverPull, ButtonHover, ClaimReward, BuySound, PurchaseSuccess, SellSound),
--   ReplicatedStorage/BossSfx (GolemHit, Punch, Footstep, …), ReplicatedStorage/MutationSfx (ZapSmall, ZapBig, Hum).
local SoundService = game:GetService("SoundService")
local function findSound(name: string): Sound?
	local s = SoundService:FindFirstChild(name)
	if not s then for _, f in { RS:FindFirstChild("BossSfx"), RS:FindFirstChild("MutationSfx"), RS:FindFirstChild("PlotAssets") } do s = s or (f and f:FindFirstChild(name)) end end
	return (s and s:IsA("Sound") and s.SoundId ~= "") and s or nil
end
local sndLast = {}
-- pos = nil — 2D; minGap — не частіше (за назвою)
local function snd(name: string, vol: number?, spd: number?, pos: Vector3?, minGap: number?, key: string?)
	if quiet then return end
	local tpl = findSound(name)
	if not tpl then return end
	local k = key or name
	local now = os.clock()
	if minGap and sndLast[k] and now - sndLast[k] < minGap then return end
	sndLast[k] = now
	local c = tpl:Clone()
	c.Volume = tpl.Volume * (vol or 1) * SFX_MASTER
	c.PlaybackSpeed = tpl.PlaybackSpeed * (spd or 1)
	c.Looped = false
	if pos then
		local a = Instance.new("Attachment")
		a.WorldPosition = pos
		a.Parent = workspace.Terrain
		c.RollOffMode = Enum.RollOffMode.InverseTapered
		c.RollOffMinDistance, c.RollOffMaxDistance = 14, 140
		c.Parent = a
		c:Play()
		task.delay((tpl.TimeLength > 0 and tpl.TimeLength or 3) / math.max(0.3, c.PlaybackSpeed) + 0.3, function() a:Destroy() end)
	else
		c.Parent = SoundService
		c:Play()
		task.delay((tpl.TimeLength > 0 and tpl.TimeLength or 3) / math.max(0.3, c.PlaybackSpeed) + 0.3, function() c:Destroy() end)
	end
	return c
end
-- удари кіркою: руда-ціль отримує HitTime від аніматора → звук + здригання (OreShake руди)
local function hitSound(target: Instance, m: Model, main: boolean?)
	target:GetAttributeChangedSignal("HitTime"):Connect(function()
		if not active then return end
		local p = target:GetAttribute("HitPoint")
		local pos = typeof(p) == "Vector3" and p or m:GetPivot().Position
		local cam = workspace.CurrentCamera
		if main and curShot ~= 2 then return end
		if main then
			-- головний шахтар біля камери: кожен удар, рівно в момент удару анімації, 2D (не залежить від відстані)
			snd("PickaxeHit", 1.8, 0.95 + math.random() * 0.1, nil, nil, "hero")
			return
		end
		if (cam.CFrame.Position - pos).Magnitude > 120 then return end
		snd("PickaxeHit", 0.5, 0.95 + math.random() * 0.15, pos, 0.12, "mine")
	end)
end
local function setTarget(m: Model, target: Instance)
	local ov = m:FindFirstChild("MineTarget") or Instance.new("ObjectValue")
	ov.Name = "MineTarget"
	ov.Value = target
	ov.Parent = m
end

-- ================= ефекти =================
local function anchorPart(pos: Vector3, life: number): BasePart
	local p = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1,
		Size = V3(0.2, 0.2, 0.2), CFrame = CFrame.new(pos) }, fx)
	task.delay(life, function() p:Destroy() end)
	return p
end
-- спливаюча цифра (висота в стадах)
local function pop(pos: Vector3, text: string, color: Color3, h: number, rise: number?, life: number?)
	life = life or 0.9
	local a = anchorPart(pos, life + 0.1)
	local w = h * math.max(2.2, #text * 0.62)
	local bb = new("BillboardGui", { Size = UDim2.fromScale(w * 0.4, h * 0.4), LightInfluence = 0, AlwaysOnTop = false,
		MaxDistance = 1000, Adornee = a, ResetOnSpawn = false }, a)
	local l = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), FontFace = HEAVY, Text = text,
		TextColor3 = color, TextScaled = true }, bb)
	local st = new("UIStroke", { Color = C("14161a"), Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round }, l)
	tween(bb, 0.22, { Size = UDim2.fromScale(w, h) }, Enum.EasingStyle.Back)
	tween(a, life, { CFrame = CFrame.new(pos + V3(0, rise or 3, 0)) }, Enum.EasingStyle.Quad)
	task.delay(life * 0.6, function()
		tween(l, life * 0.4, { TextTransparency = 1 })
		tween(st, life * 0.4, { Transparency = 1 })
	end)
	task.spawn(function()
		local t0 = os.clock()
		while a.Parent and os.clock() - t0 < life do
			st.Thickness = math.clamp(bb.AbsoluteSize.Y * 0.09, 1.5, 8)
			RunService.RenderStepped:Wait()
		end
	end)
end
local function burst(pos: Vector3, col: Color3, big: number)
	local core = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = col, Size = V3(1, 1, 1) * big,
		CFrame = CFrame.new(pos), Transparency = 0.1 }, fx)
	tween(core, 0.5, { Size = V3(1, 1, 1) * big * 7, Transparency = 1 }, Enum.EasingStyle.Quart).Completed:Connect(function() core:Destroy() end)
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2 + math.random() * 0.3
		local len = big * (6 + math.random() * 6)
		local cf0 = CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi, 0) * CFrame.Angles(0, 0, a)
		local ray = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			Material = Enum.Material.Neon, Color = col:Lerp(Color3.new(1, 1, 1), 0.5), Transparency = 0.15,
			Size = V3(0.3 * big, 0.25 * big, 0.25 * big), CFrame = cf0 }, fx)
		tween(ray, 0.55, { Size = V3(len, 0.06 * big, 0.06 * big), CFrame = cf0 * CFrame.new(len / 2, 0, 0), Transparency = 1 }, Enum.EasingStyle.Quart)
			.Completed:Connect(function() ray:Destroy() end)
	end
	Boss.ring(pos - V3(0, big * 0.4, 0), big * 4, col, 0.5, 0.2)
	Boss.ring(pos - V3(0, big * 0.4, 0), big * 6, Color3.new(1, 1, 1), 0.8, 0.5)
	Boss.sparks(pos - V3(0, 2, 0), math.floor(30 * big), col)
	Boss.flash(pos, col, 40 * big, 6)
end

-- ================= камера =================
local camCF, camFov = CFrame.new(), 70
local punch, punchT = 0, 0
local function fovPunch(k) punch = k; punchT = os.clock() end
RunService:BindToRenderStep("TrailerCam", Enum.RenderPriority.Camera.Value, function()
	if not active then return end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local pk = punch * math.exp(-(os.clock() - punchT) * 7)
	cam.CFrame = camCF
	for _, e in Lighting:GetChildren() do if e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") then if e.Enabled then e.Enabled = false end end end -- кожен кадр
	cam.FieldOfView = math.clamp(camFov - pk, 10, 110)
	-- 11.11.2026: свій персонаж у кадрі не потрібен (стояв у хабі за машиною мутацій) — ховаємо локально
	local ch = player.Character
	if ch then
		for _, d in ch:GetDescendants() do
			if d:IsA("BasePart") then d.LocalTransparencyModifier = 1
			elseif d:IsA("BillboardGui") and d.Enabled then d.Enabled = false end
		end
	end
end)

-- ================= інтерфейс / середовище =================
local hiddenGuis = {}
local function hideUi(on: boolean)
	local pg = player:WaitForChild("PlayerGui")
	if on then
		for _, g in pg:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "TrailerUI" then hiddenGuis[g] = true; g.Enabled = false end
		end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
		pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
		for _, e in Lighting:GetChildren() do if e:IsA("DepthOfFieldEffect") or e:IsA("BlurEffect") then e.Enabled = false end end
		for _, e in workspace.CurrentCamera:GetChildren() do if e:IsA("PostEffect") then e.Enabled = false end end
	else
		for g in hiddenGuis do if g.Parent then g.Enabled = true end end
		hiddenGuis = {}
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
		pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
	end
end
player:WaitForChild("PlayerGui").ChildAdded:Connect(function(g)
	if active and g:IsA("ScreenGui") and g.Name ~= "TrailerUI" then hiddenGuis[g] = true; g.Enabled = false end
end)
-- 11.11.2026: ігрові вікна, які самі вмикаються під час трейлера (напр. RollRolePanel у новачка), — ховаємо щокадру
RunService.Heartbeat:Connect(function()
	if not active then return end
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "TrailerUI" then hiddenGuis[g] = true; g.Enabled = false end
	end
end)
local ui = new("ScreenGui", { Name = "TrailerUI", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000 }, player.PlayerGui)
local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0 }, ui)
local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, ui)
local info = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(600, 120), FontFace = HEAVY, TextSize = 64, TextColor3 = Color3.new(1, 1, 1), Text = "" }, ui)
local function flashWhite(a: number, dur: number)
	white.BackgroundTransparency = 1 - a
	tween(white, dur, { BackgroundTransparency = 1 })
end
-- підписи кадрів (11.11.2026): Luckiest Guy, жовто-помаранчевий перелив, темна обводка й тінь; поява / зникнення — setCaption(text, a)
local capHold = new("Frame", { Name = "Caption", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.855),
	Size = UDim2.fromScale(0.92, 0.15), BackgroundTransparency = 1 }, ui)
local capScale = new("UIScale", {}, capHold)
local capShadow = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.075), Size = UDim2.fromScale(1, 1), FontFace = LUCKY,
	TextScaled = true, Text = "", TextColor3 = C("2b1403"), TextTransparency = 1, ZIndex = 1 }, capHold)
local capShadowStroke = new("UIStroke", { Color = C("2b1403"), Thickness = 9, Transparency = 1, LineJoinMode = Enum.LineJoinMode.Round }, capShadow)
local capText = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), FontFace = LUCKY, TextScaled = true, Text = "",
	TextColor3 = Color3.new(1, 1, 1), TextTransparency = 1, ZIndex = 2 }, capHold)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C("fff48a")), ColorSequenceKeypoint.new(0.5, C("ffd21f")),
	ColorSequenceKeypoint.new(1, C("ff9416")) }) }, capText)
local capStroke = new("UIStroke", { Color = C("4a2406"), Thickness = 7, Transparency = 1, LineJoinMode = Enum.LineJoinMode.Round }, capText)
local function setCaption(text: string, a: number)
	if capText.Text ~= text then capText.Text = text; capShadow.Text = text end
	capText.TextTransparency = 1 - a; capStroke.Transparency = 1 - a
	capShadow.TextTransparency = 1 - a * 0.6; capShadowStroke.Transparency = 1 - a * 0.6
	capScale.Scale = 0.9 + 0.1 * a
	local th = math.max(3, ui.AbsoluteSize.Y / 1080 * 7)
	capStroke.Thickness = th; capShadowStroke.Thickness = th * 1.3
end

-- ================= сети =================
local function stage(i: number): Model? return sets:FindFirstChild("Stage" .. i) end
local function plotBase(st: Model, i: number): BasePart?
	local p = st:FindFirstChild("Plots") and st.Plots:FindFirstChild("Plot" .. i)
	return p and p:FindFirstChild("Base")
end
local function leverOf(st: Model): Model? return st:FindFirstChild("RollSystem") and st.RollSystem:FindFirstChild("RollLeverModel") end

local STAGE_ORES = {
	{ "Coal_L", "Copper_L", "Iron_L" }, { "Tin_L", "Silver_L", "Gold_L" }, { "Quartz_L", "Amethyst_L", "Sapphire_L" },
	{ "Obsidian_L", "Ruby_L", "Emberite_L" }, { "Frostite_L", "Platinum_L", "Celestium_L" }, { "Voidstone_L", "Starmetal_L", "Voidstone_M" },
}
local STAGE_KINDS = {
	{ "wooden", "stone", "clay", "gravel", "mossback", "copperhead", "flint", "rustbolt", "granite", "lantern" },
	{ "ironclad", "quartzling", "tinker", "silverjaw", "lantern", "granite" },
	{ "geode", "amethyst", "sapphire", "obsidian", "magmaheart" },
	{ "magmaheart", "ruby", "obsidian", "sapphire" },
	{ "frostforged", "platinum", "ruby" },
	{ "aurelian", "astral", "platinum" },
}
local STAGE_MONEY = {
	{ "+$12", "+$48", "+$150", "+$1.2K" }, { "+$3.4K", "+$18K", "+$72K" }, { "+$250K", "+$1.1M", "+$4.8M" },
	{ "+$19M", "+$86M", "+$340M" }, { "+$1.2B", "+$7.5B", "+$26B" }, { "+$98B", "+$420B", "+$1.7T" },
}
local function pick(t) return t[math.random(1, #t)] end
local nextPop = setmetatable({}, { __mode = "k" })
local function minerPop(list, money, h)
	local now = os.clock()
	for _ = 1, 6 do
		local m = list[math.random(1, #list)]
		if (nextPop[m] or 0) <= now then
			nextPop[m] = now + 1.4 + math.random() * 0.6
			pop(headTop(m) + V3((math.random() - 0.5) * 2, 1 + math.random() * 0.6, (math.random() - 0.5) * 2), pick(money), C("5af078"), h, 3, 0.9)
			return
		end
	end
end
local function randMut(stageN: number): number
	if math.random() < 0.55 then return 0 end
	return math.clamp(math.random(1, 3) + math.floor(stageN / 2), 1, 7)
end

-- заповнити плот шахтарями навколо руд
local function fillPlot(st: Model, stageN: number, plotN: number, nOres: number, perOre: number): { Model }
	local base = plotBase(st, plotN)
	if not base then return {} end
	local c = base.Position
	local list = {}
	local rng = Random.new(stageN * 100 + plotN)
	for i = 1, nOres do
		local a = (i / nOres) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local r = nOres == 1 and 0 or rng:NextNumber(9, 14)
		local op = V3(c.X + math.cos(a) * r, 0, c.Z + math.sin(a) * r)
		op = V3(op.X, floorAt(op, st), op.Z)
		local oreM = ore(STAGE_ORES[stageN], ((i - 1) % 3) + 1, op, rng:NextNumber(0, 6.28), 1)
		if oreM then hitSound(oreM, oreM) end
		for j = 1, perOre do
			local b = (j / perOre) * math.pi * 2 + a + 0.6
			local gp = V3(op.X + math.cos(b) * 6.5, 0, op.Z + math.sin(b) * 6.5)
			gp = V3(gp.X, floorAt(gp, st), gp.Z)
			local m = golem(pick(STAGE_KINDS[stageN]), "miner", randMut(stageN))
			if m then
				m.Parent = live
				ground(m, gp, op)
				setState(m, "Mine", 0.9 + rng:NextNumber(0, 0.35))
				if oreM then setTarget(m, oreM) end
				table.insert(list, m)
			end
		end
	end
	return list
end

-- ================= кадри =================
-- v2 (07.11.2026): повільніші плавні кадри, големи обличчям у правильний бік (перед моделі — −Z, як у lookAt),
--   камера лише в перевірених коридорах (прохід між плотами, над плотами нижче балок), фінал — на арені після перемоги.
local S = {}
local prepared = false

local st1, lv1
local roll = {}
local function hideBacon(b) b.m:PivotTo(b.m:GetPivot() - V3(0, 400, 0)) end

-- ---------- 1. РОЛ (5 с): ричаг → 4 фейки на стенді (виростають і зникають, як у RollRevealClient) → Secret-Аурелиан ----------
S[1] = { name = "Roll", dur = 6.0 }
local FAKES = { "wooden", "copperhead", "ironclad", "silverjaw", "sapphire", "ruby" }
local FAKE_CYS = { 0.36, 0.32, 0.3, 0.34, 0.42, 0.55 }
local FAKE_T0, APPEAR, VANISH = 1.0, 0.13, 0.1
local FAKE_ST = {}
local RESULT_T = FAKE_T0
for i, c in FAKE_CYS do FAKE_ST[i] = RESULT_T; RESULT_T += c end
S[1].prep = function()
	st1 = stage(1)
	lv1 = leverOf(st1)
	local rl = lv1:FindFirstChild("RollLever")
	roll.parts = {}
	for _, p in rl:GetDescendants() do if p:IsA("BasePart") then roll.parts[p] = p.CFrame end end
	roll.h = rl:FindFirstChild("Hinge").Position
	roll.knob0 = rl:FindFirstChild("Knob").Position
	-- 11.11.2026: підлога променем від рівня важеля вниз (floorAt згори влучав у балку над новим місцем важеля — Bacon опинявся на даху)
	local function floorLow(pos: Vector3): number
		rayParams.FilterDescendantsInstances = { st1 }
		local r = workspace:Raycast(pos + V3(0, 2, 0), V3(0, -25, 0), rayParams)
		return r and r.Position.Y or pos.Y
	end
	roll.floor = floorLow(V3(roll.knob0.X + 0.95, roll.knob0.Y, roll.knob0.Z - 2.4))
	roll.bpos = V3(roll.knob0.X + 0.95, roll.floor, roll.knob0.Z - 2.4)
	roll.b = bacon(roll.bpos, roll.bpos + V3(0, 0, 10))
	local sp = st1.RollSystem.StandPoints:FindFirstChild("Point1")
	roll.standPos = V3(sp.Position.X, floorLow(sp.Position + V3(0, 3, 0)), sp.Position.Z)
	local stand = RS:FindFirstChild("Prefabs") and RS.Prefabs:FindFirstChild("RollStand")
	roll.standTop = roll.standPos.Y
	if stand then
		local s = stand:Clone()
		for _, d in s:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
		s:ScaleTo(s:GetScale() * 1.5)
		s.Parent = live
		ground(s, roll.standPos)
		local cf, sz = s:GetBoundingBox()
		-- центр плити стенда (півот префаба зміщений від центру)
		local d = V3(roll.standPos.X - cf.Position.X, 0, roll.standPos.Z - cf.Position.Z)
		s:PivotTo(s:GetPivot() + d)
		cf, sz = s:GetBoundingBox()
		roll.standTop = cf.Position.Y + sz.Y / 2
	end
	roll.gpos = V3(roll.standPos.X, roll.standTop, roll.standPos.Z)
	roll.gat = roll.gpos + V3(10, 0, -5)
	local function mk(kind, mut, sc)
		local g = golem(kind, "miner", mut, sc)
		if not g then return nil end
		g.Parent = live
		ground(g, roll.gpos, roll.gat)
		setState(g, "Idle", 1)
		local e = { m = g, base = g:GetScale() }
		hide(g)
		return e
	end
	roll.fakes = {}
	for i, k in FAKES do roll.fakes[i] = mk(k, (i == 5) and 3 or ((i == 6) and 5 or 0), 0.9) end
	roll.res = mk("aurelian", 7, 1.1)
end
-- поставити голема на стенд з масштабом k (0..1+)
local function standPose(e, k: number)
	if not e then return end
	local kk = math.max(0.03, k)
	local want = e.base * kk
	if math.abs(e.m:GetScale() - want) > 1e-4 then e.m:ScaleTo(want) end
	ground(e.m, roll.gpos, roll.gat)
end
local function backOut(x: number): number
	local c1, c3 = 1.9, 2.9
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end
local function knobPos(): Vector3
	local k = roll.knobPart
	if not k then
		for p in roll.parts do if p.Name == "Knob" then roll.knobPart = p; k = p end end
	end
	return k.Position
end
local function leverAngle(a: number)
	local h = roll.h
	local T = CFrame.new(h) * CFrame.Angles(0, 0, a) * CFrame.new(-h)
	for p, cf in roll.parts do p.CFrame = T * cf end
end
S[1].start = function()
	if not roll.broot0 then roll.broot0 = roll.b.root end
	baconPlace(roll.b, roll.broot0)
	leverAngle(0)
	baconShock(roll.b, false)
	baconRest(roll.b, "L")
	for _, e in roll.fakes do if e then hide(e.m) end end
	if roll.res then hide(roll.res.m) end
	roll.cur = 0
end
S[1].update = function(t)
	leverAngle(-math.rad(85) * E.inout(seg(t, 0.5, 0.95)))
	if t < RESULT_T + 0.25 then
		local to = (knobPos() - shoulder(roll.b, "R")).Unit
		local down = -roll.b.root.UpVector
		local k = E.out(seg(t, 0.05, 0.5))
		local d = down:Lerp(to, k)
		if d.Magnitude > 1e-3 then baconArm(roll.b, "R", d) end
	end
	-- фейки
	local i = 0
	for j, st in FAKE_ST do if t >= st then i = j end end
	local FAKE_CY = FAKE_CYS[i] or 1
	if t >= FAKE_T0 and t < RESULT_T and i >= 1 then
		if roll.cur ~= i then
			if roll.cur > 0 and roll.fakes[roll.cur] then hide(roll.fakes[roll.cur].m) end
			roll.cur = i
			snd("ButtonHover", 1.6, 1 + 0.07 * (i - 1))
		end
		local a = t - FAKE_ST[i]
		local k
		if a < APPEAR then k = backOut(a / APPEAR)
		elseif a < FAKE_CY - VANISH then k = 1
		else local x = (a - (FAKE_CY - VANISH)) / VANISH; k = 1 - x * x end
		standPose(roll.fakes[i], k)
	elseif t >= RESULT_T and roll.cur ~= 99 then
		if roll.cur > 0 and roll.fakes[roll.cur] then hide(roll.fakes[roll.cur].m) end
		roll.cur = 99
	end
	if roll.cur == 99 and roll.res then
		standPose(roll.res, backOut(clamp01((t - RESULT_T) / 0.25)))
	end
	local tj = t - (RESULT_T + 0.25)
	local b = roll.b
	if tj >= 0 then
		local r0 = roll.broot0
		local camP = S[1].cam(t).Position
		local toCam = V3(camP.X - r0.Position.X, 0, camP.Z - r0.Position.Z).Unit
		local yaw0 = math.atan2(-r0.LookVector.X, -r0.LookVector.Z)
		local yaw1 = math.atan2(-toCam.X, -toCam.Z)
		local dy = (yaw1 - yaw0 + math.pi) % (2 * math.pi) - math.pi
		local yaw = yaw0 + dy * E.out(clamp01(tj / 0.3))
		local hop = math.abs(math.sin(math.max(0, tj - 0.15) * 7.5)) * 1.3
		baconPlace(b, CFrame.new(r0.Position + V3(0, hop, 0)) * CFrame.Angles(0, yaw, 0))
		local up, rv, lk = b.root.UpVector, b.root.RightVector, b.root.LookVector
		local wave = math.sin(tj * 9) * 0.25
		baconArm(b, "R", up + rv * (0.45 + wave) + lk * 0.15)
		baconArm(b, "L", up - rv * (0.45 + wave) + lk * 0.15)
	end
end
S[1].events = {
	{ 0.5, function() snd("LeverPull", 2.2) end },
	{ 0.95, function()
		Boss.sparks(knobPos(), 14, C("ffd84a"))
		Boss.shake(0.25, 0.25)
	end },
	{ RESULT_T, function()
		snd("ClaimReward", 1.4)
		snd("ZapBig", 0.7, 1.2)
		burst(roll.gpos + V3(0, 4, 0), C("fff6d0"), 1.6)
		flashWhite(0.6, 0.4)
		fovPunch(8)
		Boss.shake(0.7, 0.5)
	end },
	{ RESULT_T + 0.25, function() baconShock(roll.b, true) end },
	{ RESULT_T + 0.75, function() snd("BuySound", 2) end },
}
S[1].cam = function(t)
	local b, g = roll.bpos, roll.gpos
	local k = E.sine(seg(t, 0, 6.0))
	local mid = (b + g) / 2
	local pts = { b + V3(6, 5.2, -14), b + V3(11, 5, -9), b + V3(13.5, 4.8, 1.0), b + V3(13.5, 5.2, 5.0) }
	local ats = { V3(g.X + 3, b.Y + 4.5, g.Z), V3(g.X + 2, b.Y + 4.5, g.Z - 0.5), mid + V3(0, 4.6, -0.5), mid + V3(-1, 5.0, 0.5) }
	return look(spline(pts, k), spline(ats, k)), 58
end
S[1].focus = function() return lv1 and lv1:GetPivot().Position + V3(20, 5, 0) end

-- ---------- 2. ШАХТАРІ НА ПЛОТАХ (4 с) ----------
local miners1 = {}
local hero
S[2] = { name = "Mining", dur = 4.0 }
S[2].prep = function()
	for i = 1, 6 do
		for _, m in fillPlot(st1, 1, i, 3, 2) do table.insert(miners1, m) end
	end
	local b1 = plotBase(st1, 1).Position
	local y = b1.Y + 0.4
	local hp = V3(b1.X + 14, y, b1.Z - 15)
	local op = hp + V3(-7.5, 0, 0)
	local heroOre = ore(STAGE_ORES[1], 3, op, 0.7, 1.1)
	if heroOre then hitSound(heroOre, heroOre, true) end
	hero = golem("granite", "miner", 3, 1.15)
	if hero and heroOre then setTarget(hero, heroOre) end
	if hero then
		hero.Parent = live
		ground(hero, hp, op)
		setState(hero, "Mine", 1)
		table.insert(miners1, hero)
	end
	S[2].op = op
	S[2].hp = hp
end
S[2].start = function()
	S[2].popT = 0
	if S[3] and S[3].walkStart then S[3].walkStart() end
end
S[2].update = function(t, dt)
	if S[3] and S[3].walk then S[3].walk(t) end -- 11.11.2026: носії (кадр 3) ідуть уже зараз, а не топчуться на місці
	S[2].popT -= dt
	if S[2].popT <= 0 and #miners1 > 0 then
		S[2].popT = 0.1
		if t < 1.2 and hero then minerPop({ hero }, STAGE_MONEY[1], 1.6) else minerPop(miners1, STAGE_MONEY[1], 2.4) end
	end
end
S[2].cam = function(t)
	local hp = S[2].hp
	local aisle = (plotBase(st1, 1).Position + plotBase(st1, 2).Position) / 2
	local y = aisle.Y
	local k = E.sine(seg(t, 0, 4.0))
	local pts = { hp + V3(-1, 7, -21), V3(hp.X - 2, y + 10, aisle.Z + 4), V3(aisle.X + 30, y + 20, aisle.Z), V3(aisle.X + 42, y + 26, aisle.Z) }
	local ats = { hp + V3(-2.5, 3, 0), hp + V3(-12, 2, 2), V3(aisle.X - 40, y, aisle.Z), V3(aisle.X - 70, y, aisle.Z) }
	return look(spline(pts, k), spline(ats, k)), lerp(55, 72, k)
end
S[2].focus = function() return lv1:GetPivot().Position + V3(-60, 5, 0) end

-- ---------- 3. НОСИЛЬЩИКИ (3 с) ----------
local carriers = {}
S[3] = { name = "Carriers", dur = 3.0 }
S[3].prep = function()
	local a = (plotBase(st1, 3).Position + plotBase(st1, 4).Position) / 2
	S[3].y = a.Y + 0.4
	S[3].from = V3(a.X - 10, S[3].y, a.Z)
	S[3].dir = V3(1, 0, 0)
	local kinds = { "ironclad", "granite", "copperhead", "silverjaw", "rustbolt", "lantern" }
	for i = 1, 6 do
		local m = golem(kinds[i], "carrier", (i == 2 and 4) or (i == 5 and 3) or 0)
		if m then
			local box = m:FindFirstChild("CarryBox")
			local load = box and box:FindFirstChild("Load")
			if load then for _, d in load:GetDescendants() do if d:IsA("BasePart") then d.Transparency = 0 end end end
			m.Parent = live
			local off = V3(-((i - 1) // 2) * 11 - (((i - 1) % 2) * 4), 0, ((i - 1) % 2 == 0) and -5 or 5)
			ground(m, S[3].from + off, S[3].from + off + S[3].dir)
			table.insert(carriers, { m = m, foot = footOf(m), off = off })
		end
	end
end
local CAR_V = 7
local CAR_LEAD = 4.0 -- = S[2].dur: носії починають іти з початку кадру 2; S[3].from — де вони на початку кадру 3
S[3].walkStart = function()
	for _, c in carriers do setState(c.m, "Walk", 1.2) end
end
S[3].walk = function(T) -- T — секунди від початку кадру 2
	if not S[3].from then return end
	for _, c in carriers do
		moveGolem(c.m, S[3].from + c.off + S[3].dir * ((T - CAR_LEAD) * CAR_V), S[3].dir, c.foot)
	end
end
S[3].start = S[3].walkStart
S[3].update = function(t)
	S[3].walk(CAR_LEAD + t)
	local c = carriers[math.random(1, math.max(1, #carriers))]
	if c then snd("Footstep", 0.35, 1.2 + math.random() * 0.2, c.m:GetPivot().Position, 0.16, "carstep") end
end
S[3].events = {
	{ 1.6, function() snd("SellSound", 4); for _, c in carriers do pop(headTop(c.m) + V3(0, 1.2, 0), pick({ "+$4.8K", "+$12K", "+$31K" }), C("ffd24a"), 2.2, 3, 1.1) end end },
}
S[3].cam = function(t)
	local lead = S[3].from + S[3].dir * (t * CAR_V)
	local k = E.sine(seg(t, 0, 3.0))
	-- камера їде разом із носіями й плавно опускається зверху до рівня очей
	local p = lead + V3(lerp(27, 24, k), lerp(12.5, 5.2, k), lerp(-7, 4, k))
	return look(p, lead + V3(-2, lerp(2.6, 3.6, k), 0)), lerp(62, 56, k)
end
S[3].focus = function() return S[3].from + V3(0, 5, 0) end

-- ---------- 4. СВІТИ (3 × 1,3 с) ----------
local worlds = {}
local WORLD = { 3, 5, 6 }
local SUB = 1.3
S[4] = { name = "Worlds", dur = SUB * #WORLD }
local mapBoards = {} -- 11.11.2026: табло «NEXT MAP» на кожній мапі трейлера (будує MapBoard через _G.TrailerMapBoard)
S[4].prep = function()
	for i = 1, 6 do
		local st = stage(i)
		local g = mapBoards[i]
		if st and _G.TrailerMapBoard and not (g and g.Parent) then
			local ok, res = pcall(_G.TrailerMapBoard, st, i)
			if ok then mapBoards[i] = res else warn("[Trailer] map board " .. i .. ": " .. tostring(res)) end
		end
	end
	for _, i in WORLD do
		local st = stage(i)
		if st then
			local w = { st = st, miners = {} }
			for _, pn in { 1, 2, 3, 4 } do
				for _, m in fillPlot(st, i, pn, 2, 3) do table.insert(w.miners, m) end
			end
			w.a = (plotBase(st, 1).Position + plotBase(st, 2).Position) / 2
			worlds[i] = w
		end
	end
end
S[4].start = function() S[4].last = 0 end
S[4].update = function(t, dt)
	local n = math.clamp(math.floor(t / SUB) + 1, 1, #WORLD)
	local w = worlds[WORLD[n]]
	if not w then return end
	if n ~= S[4].last then
		S[4].last = n
		-- без спалаху: світ підміняється «на льоту» (камера летить далі тим самим шляхом)
	end
	w.popT = (w.popT or 0) - dt
	if w.popT <= 0 and #w.miners > 0 then
		w.popT = 0.08
		minerPop(w.miners, STAGE_MONEY[WORLD[n]], 2.6)
	end
end
S[4].cam = function(t)
	local n = math.clamp(math.floor(t / SUB) + 1, 1, #WORLD)
	local w = worlds[WORLD[n]]
	-- один безперервний проліт уздовж проходу; ніші однакові, тож шлях задано відносно поточного світу — світи
	--   підміняються під камерою без стрибка
	local k = seg(t, 0, S[4].dur)
	local a = w.a
	local p = V3(a.X + lerp(32, -16, k), a.Y + lerp(13, 9, k) + math.sin(k * math.pi) * 2, a.Z + math.sin(k * math.pi * 1.5) * 4)
	return look(p, V3(p.X - 40, a.Y + 1, a.Z)), 70
end
S[4].focus = function() local w = worlds[WORLD[1]]; return w and w.a + V3(30, 5, 0) end

-- ---------- 5. МУТАЦІЯ (4,2 с): як у грі (MutationMachineClient) — големи на плитах обличчям до камери машини,
--   по черзі (найближчий першим) йдуть конвеєром у камеру й зникають, спалах, на виході — голем з наступною мутацією ----------
local mut = {}
S[5] = { name = "Mutation", dur = 7.3 }
local GOLEM_H, GOLEM_W, RIDE = 6.5, 4.6, 7
S[5].prep = function()
	local mm = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub") and workspace.Cave.Hub:FindFirstChild("MutationMachines")
	local mach = mm and mm:FindFirstChild("Machine1")
	if not mach then warn("[Trailer] no machine"); return end
	local core = mach:FindFirstChild("Core")
	local tc = core and core:FindFirstChild("TunnelCeil")
	mut.center = tc and tc.Position or core:GetBoundingBox().Position
	local function padTop(m)
		local pad = m:FindFirstChild("Pad")
		return pad.Position + V3(0, pad.Size.Y / 2, 0)
	end
	local function fit(g)
		local _, size = g:GetBoundingBox()
		local k = math.min(1, GOLEM_H / math.max(0.1, size.Y), GOLEM_W / math.max(0.1, math.max(size.X, size.Z)))
		if k < 0.999 then g:ScaleTo(g:GetScale() * k) end
	end
	mut.g = {}
	for i = 1, 3 do
		local p = padTop(mach:FindFirstChild("Slot" .. i))
		local g = golem("ruby", "miner", 0, 1)
		if g then
			fit(g)
			g.Parent = live
			ground(g, p, V3(mut.center.X, p.Y, mut.center.Z))
			setState(g, "Idle", 1)
			mut.g[i] = { m = g, foot = footOf(g), from = p, to = V3(mut.center.X, p.Y, mut.center.Z) }
		end
	end
	mut.slot1 = mut.g[1] and mut.g[1].from
	mut.out = padTop(mach:FindFirstChild("Output"))
	mut.res = golem("ruby", "miner", 6, 1)
	if mut.res then
		fit(mut.res)
		mut.res.Parent = live
		mut.outAt = mut.out + (mut.out - V3(mut.center.X, mut.out.Y, mut.center.Z))
		ground(mut.res, mut.out, mut.outAt)
		setState(mut.res, "Idle", 1)
		mut.resFoot = footOf(mut.res)
		hide(mut.res)
	end
end
-- черга: слот 3 (біля тунелю) першим; ідуть майже разом (11.11.2026: раніше по черзі — готовий голем не встигав вийти в кадрі)
local ORDER = { 3, 2, 1 }
local RAINBOW = { C("ff2a2a"), C("ff8a00"), C("ffe600"), C("22e04a"), C("00c8ff"), C("b02aff"), C("ff6ad5") }
local function walkT(g) return (g.to - g.from).Magnitude / RIDE end
S[5].start = function()
	local t, last = 0.4, 0
	for _, i in ORDER do
		local g = mut.g[i]
		if g then
			g.t0 = t
			g.t1 = t + math.max(0.4, walkT(g))
			last = math.max(last, g.t1)
			t += 0.35
			g.done = false
			moveGolem(g.m, g.from, g.to - g.from, g.foot)
			setState(g.m, "Idle", 1)
		end
	end
	mut.burstT = last + 0.25
	mut.resT = mut.burstT + 0.3
	mut.walkDur = math.max(0.5, (mut.out - V3(mut.center.X, mut.out.Y, mut.center.Z)).Magnitude / RIDE)
	mut.landT = mut.resT + mut.walkDur
	S[5].dur = mut.landT + 2.1 -- готовий голем стоїть у кадрі з ефектами
	mut.fired = false
	mut.resShown = false
	mut.resDone = false
	mut.sparkT = 0
	hide(mut.res)
end
S[5].update = function(t)
	for _, g in mut.g do
		if not g.done and t >= g.t0 then
			if g.m:GetAttribute("State") ~= "Walk" then setState(g.m, "Walk", 1.1) end
			local k = seg(t, g.t0, g.t1)
			local e = k * k * (3 - 2 * k)
			moveGolem(g.m, g.from:Lerp(g.to, e), g.to - g.from, g.foot)
			if k >= 1 then
				g.done = true
				hide(g.m)
				snd("ZapSmall", 1.5, 1, mut.center)
				Boss.sparks(mut.center, 10, C("c58bff"))
			end
		end
	end
	if not mut.fired and t >= mut.burstT then
		mut.fired = true
		snd("ZapBig", 1.6, 1, mut.center)
		burst(mut.center + V3(0, 1, 0), C("c58bff"), 1.2)
		Boss.shake(0.4, 0.35)
		fovPunch(5)
	end
	if mut.res and t >= mut.resT then
		local from = V3(mut.center.X, mut.out.Y, mut.center.Z)
		local k = seg(t, mut.resT, mut.landT)
		if not mut.resShown then
			mut.resShown = true
			setState(mut.res, "Walk", 1.1)
			snd("ZapSmall", 1.4, 1.25, mut.center)
		end
		if k < 1 then
			local e = k * k * (3 - 2 * k)
			local p = from:Lerp(mut.out, e)
			moveGolem(mut.res, p, mut.out - from, mut.resFoot)
			if t >= mut.sparkT then
				mut.sparkT = t + 0.1
				Boss.sparks(p + V3(0, 3, 0), 5, pick(RAINBOW))
			end
		else
			if not mut.resDone then
				mut.resDone = true
				snd("ClaimReward", 1.5)
				snd("ZapBig", 0.8, 1.3, mut.out)
				setState(mut.res, "Idle", 1)
				burst(mut.out + V3(0, 3, 0), C("ffffff"), 1.5)
				burst(mut.out + V3(0, 3, 0), C("ff6ad5"), 1.1)
				flashWhite(0.45, 0.35)
				fovPunch(7)
				Boss.shake(0.5, 0.4)
				pop(mut.out + V3(0, GOLEM_H + 2.6, 0), "RAINBOW!", C("ff6ad5"), 3.4, 2.2, 1.7)
			end
			-- розворот до камери, підстрибування, іскри веселкою
			local tl = t - mut.landT
			local camP = S[5].cam(t).Position
			local toCam = V3(camP.X - mut.out.X, 0, camP.Z - mut.out.Z).Unit
			local d = (mut.out - from).Unit:Lerp(toCam, E.out(seg(tl, 0, 0.35)))
			local hop = math.abs(math.sin(math.min(tl, 0.84) * 7.5)) * 1.2 * (1 - seg(tl, 0, 0.84))
			moveGolem(mut.res, mut.out + V3(0, hop, 0), d, mut.resFoot)
			if t >= mut.sparkT then
				mut.sparkT = t + 0.16
				Boss.sparks(mut.out + V3((math.random() - 0.5) * 5, 1.5 + math.random() * 5, (math.random() - 0.5) * 5), 5, pick(RAINBOW))
			end
		end
	end
end
S[5].cam = function(t)
	-- 1) дугою збоку машини (+X) від слотів до тунелю; 2) після спалаху — до виходу, готовий голем великим планом
	local s1, out = mut.slot1, mut.out
	local tA = (mut.burstT or 4) + 0.3
	local landT = mut.landT or (tA + 1.3)
	local k = E.sine(seg(t, 0, tA))
	local zc = lerp((s1.Z + mut.center.Z) / 2, (mut.center.Z + out.Z) / 2, k)
	local mc = V3(mut.center.X, s1.Y, (s1.Z + out.Z) / 2)
	local a = math.rad(lerp(-50, 40, k))
	local r = lerp(27, 19, k)
	local pA = mc + V3(math.cos(a) * r, lerp(11, 4.5, k), math.sin(a) * r)
	local atA = V3(mc.X, s1.Y + 2.2, zc)
	local k2 = E.inout(seg(t, tA - 0.6, landT - 0.05))
	local push = E.sine(seg(t, landT, S[5].dur))
	local pB = out + V3(lerp(12, 9.5, push), lerp(4.2, 3.8, push), lerp(10, 8, push))
	local atB = out + V3(0, 3.6, 0)
	return look(pA:Lerp(pB, k2), atA:Lerp(atB, k2)), lerp(lerp(58, 52, k), 46, k2)
end
S[5].focus = function() return mut.center and mut.center + V3(25, 3, 0) end

-- ---------- 6. БОС (7 с) ----------
local bossS = { g = {} }
local fin = {} -- (кадр 7; оголошено тут — кадр 6 ховає фінальних Bacon і армію)
S[6] = { name = "Boss", dur = 6.0 }
S[6].prep = function()
	local arena = sets:FindFirstChild("BossArena")
	if not arena then warn("[Trailer] no arena"); return end
	local mv = arena:GetAttribute("MovedBy") -- 11.11.2026: зсув арени в ServerStorage (TrailerServer копіює атрибут)
	if typeof(mv) ~= "Vector3" then mv = Vector3.zero end
	local c = V3(-709.736 + 9000 + mv.X, 0, -784.736 + mv.Z)
	bossS.c = V3(c.X, floorAt(V3(c.X, 40, c.Z), arena), c.Z)
	bossS.arena = arena
	Boss.setFloor(bossS.c.Y)
	local src = assets:FindFirstChild("Gobking")
	if src then
		local m = src:Clone()
		local hb = m:FindFirstChild("Hitbox")
		m.PrimaryPart = hb
		local p = bossS.c + V3(0, hb.Size.Y / 2, 0)
		m:PivotTo(CFrame.lookAt(p, p + V3(0, 0, 1)))
		bossS.src = m
	end
	local kinds = { "ruby", "magmaheart", "obsidian", "platinum", "frostforged", "sapphire", "amethyst", "geode", "ironclad", "silverjaw", "aurelian", "astral" }
	local N = 24
	for i = 1, N do
		local row = (i - 1) // 8
		local col = (i - 1) % 8
		local start = bossS.c + V3((col - 3.5) * 7 + (row % 2) * 3, 0, 70 + row * 8)
		local inner = i <= 16
		local ang = inner and ((i - 1) / 16) * math.pi * 2 or ((i - 17) / 8) * math.pi * 2 + math.pi / 8
		local ringR = inner and 27 or 37
		local dst = bossS.c + V3(math.sin(ang) * ringR, 0, math.cos(ang) * ringR)
		local m = golem(kinds[(i % #kinds) + 1], "warrior", (i % 4 == 0) and math.random(2, 7) or 0, 0.85)
		if m then
			start = V3(start.X, floorAt(start, arena), start.Z)
			dst = V3(dst.X, floorAt(dst, arena), dst.Z)
			m.Parent = live
			ground(m, start, bossS.c)
			local rel0 = start - bossS.c
			local a0 = math.atan2(rel0.X, rel0.Z)
			local a1 = ang
			while a1 - a0 > math.pi do a1 -= 2 * math.pi end
			while a1 - a0 < -math.pi do a1 += 2 * math.pi end
			local tgt = Instance.new("Configuration")
			tgt.Name = "BossHitTarget"
			tgt.Parent = m
			setTarget(m, tgt)
			tgt:GetAttributeChangedSignal("HitTime"):Connect(function()
				if not active or not bossS.fighting then return end
				local hp = tgt:GetAttribute("HitPoint")
				local pos = typeof(hp) == "Vector3" and hp or m:GetPivot().Position
				snd("GolemHit", 0.8, 0.9 + math.random() * 0.3, pos, 0.05, "bosshit")
				if (bossS.popGap or 0) <= os.clock() then
					bossS.popGap = os.clock() + 0.06
					pop(pos + V3(0, 3 + math.random() * 2, 0), "-" .. math.random(12, 98) .. "." .. math.random(0, 9) .. "K", C("ff4a4a"), 2.6, 3, 0.6)
				end
			end)
			table.insert(bossS.g, { m = m, foot = footOf(m), from = start, to = dst, a0 = a0, a1 = a1, r0 = rel0.Magnitude, r1 = ringR,
				y0 = start.Y, y1 = dst.Y, t0 = 0.05 + row * 0.15 + math.random() * 0.12 })
		end
	end
end
-- 11.11.2026 (v3): бій 6 с — армія вбігає, бос б'є кулаком, останній ряд (8 големів) застрибує на боса з усіх боків,
--   добиває й зістрибує, бос падає. Таймінги: JUMP0 — перший стрибок, FALL_T — смерть боса (падіння триває 2,25 с).
local RUN_T = 1.45
local JUMP0, JUMP_GAP, JUMP_LEN = 2.15, 0.09, 0.62
local FALL_T = 3.45
local OFF_LEN = 0.75
local JUMP_H = { 43, 34, 28, 38, 31, 25, 36, 29 } -- висота точки на босі для кожного стрибуна
local JUMP_R = { 3, 9, 10, 8, 10, 11, 9, 10 } -- відстань від осі боса
S[6].start = function()
	if fin.b then hideBacon(fin.b) end
	for _, g in (fin.g or {}) do hide(g.m) end
	if bossS.m then bossS.m:Destroy() end
	if bossS.src then
		bossS.m = bossS.src:Clone()
		bossS.m.Parent = live
		Boss.bind(bossS.m)
	end
	local j = 0
	for _, g in bossS.g do
		g.arrived, g.cheer, g.last, g.up, g.hit = false, false, nil, false, false
		if g.r1 > 30 then
			j += 1
			g.j = j
			g.jh, g.jr = JUMP_H[(j - 1) % #JUMP_H + 1], JUMP_R[(j - 1) % #JUMP_R + 1]
		end
		moveGolem(g.m, g.from, bossS.c - g.from, g.foot)
		setState(g.m, "Run", 1.5)
	end
	bossS.popT = 0
end
S[6].update = function(t, dt)
	for _, g in bossS.g do
		local tj = g.j and (JUMP0 + (g.j - 1) * JUMP_GAP)
		if tj and t >= tj then
			-- стрибун: дуга на боса → б'є, тримаючись на ньому → зістрибує, коли бос падає
			g.arrived = true
			local a = g.a1
			local from = V3(g.to.X, g.y1, g.to.Z)
			local hold = bossS.c + V3(math.sin(a) * g.jr, g.jh, math.cos(a) * g.jr)
			local tl = tj + JUMP_LEN
			local p
			if t < tl then
				local k = (t - tj) / JUMP_LEN
				p = from:Lerp(hold, k) + V3(0, math.sin(k * math.pi) * 11, 0)
				if not g.up then
					g.up = true
					setState(g.m, "Mine", 2.4)
					snd("Footstep", 1, 0.8, from, 0.03, "jumpoff")
				end
			elseif t < FALL_T then
				p = hold + V3(0, math.abs(math.sin((t - tl) * 14)) * 0.6, 0)
				if not g.hit then
					g.hit = true
					Boss.sparks(hold, 14, C("ffe27a"))
					burst(hold, C("fff2a8"), 1.3)
					pop(hold + V3(0, 5, 0), "-" .. math.random(120, 980) .. "K", C("ff4a4a"), 3.6, 3, 0.7)
					snd("GolemHit", 1.1, 0.75 + math.random() * 0.15, hold, 0.03, "jumphit")
					Boss.shake(0.5, 0.2)
					fovPunch(2.5)
				end
			else
				local k = clamp01((t - FALL_T) / OFF_LEN)
				local out = bossS.c + V3(math.sin(a) * (g.r1 + 7), 0, math.cos(a) * (g.r1 + 7))
				out = V3(out.X, g.y1, out.Z)
				p = hold:Lerp(out, k) + V3(0, math.sin(k * math.pi) * 9, 0)
				if k >= 1 and not g.cheer then
					g.cheer = true
					setState(g.m, "Idle", 1)
				end
			end
			moveGolem(g.m, p, bossS.c - p, g.foot)
			continue
		end
		local k = seg(t, g.t0, g.t0 + RUN_T)
		if not g.arrived then
			-- по дузі: радіус зменшується швидше, кут — плавно (оббігають боса з боків)
			local kr = E.out(k)
			local ka = E.inout(k)
			local a = lerp(g.a0, g.a1, ka)
			local r = lerp(g.r0, g.r1, kr)
			local p = bossS.c + V3(math.sin(a) * r, 0, math.cos(a) * r)
			p = V3(p.X, lerp(g.y0, g.y1, k), p.Z)
			local prev = g.last or g.from
			local dir = (k < 0.97 and (p - prev).Magnitude > 0.01) and (p - prev) or (bossS.c - p)
			g.last = p
			moveGolem(g.m, p, dir, g.foot)
			if k >= 1 then
				g.arrived = true
				setState(g.m, "Mine", 1.8 + math.random() * 0.5)
			end
		end
		if t > FALL_T + 2.3 and not g.cheer then
			g.cheer = true
			setState(g.m, "Idle", 1)
		end
	end
	bossS.fighting = t > 1.4 and t < FALL_T + 0.3
	if t < 1.7 and #bossS.g > 0 then
		local g = bossS.g[math.random(1, #bossS.g)]
		snd("Footstep", 0.6, 1.1 + math.random() * 0.3, g.m:GetPivot().Position, 0.07, "armystep")
	end
end
S[6].events = {
	{ 0.15, function() Boss.sfx("AttackScream", bossS.c + V3(0, 40, 0), { spd = 0.85, vol = 1, min = 60, max = 400 }) end },
	{ 1.15, function() Boss.attack("Slam", 0.7, 0) end },
	{ 1.85, function()
		local f = Boss.fist("FistL") or bossS.c
		Boss.impact(V3(f.X, bossS.c.Y, f.Z + 4), 1.6)
		Boss.shake(1.6, 0.6)
		fovPunch(8)
		Boss.sfx("Punch", bossS.c, { spd = 0.8, vol = 1.3, min = 60, max = 400 })
	end },
	{ FALL_T, function()
		-- останній удар: бос валиться
		Boss.die()
		Boss.shake(1.5, 0.6)
		fovPunch(9)
		flashWhite(0.35, 0.25)
		Boss.sfx("Punch", bossS.c, { spd = 0.65, vol = 1.5, min = 60, max = 400 })
		pop(bossS.c + V3(0, 50, 6), "-9.9M", C("ff4a4a"), 7, 5, 1.1)
	end },
	{ FALL_T + 2.27, function()
		local p = bossS.c + V3(0, 3, 12)
		Boss.debris(p, 26, 1.6, 55, { C("ffd24a"), C("5cc8ff"), C("ff5a8a"), C("5af078") }, true)
		Boss.sparks(p, 40, C("ffd24a"))
		burst(p + V3(0, 4, 0), C("ffd24a"), 2)
		pop(p + V3(0, 14, 0), "+$2.4T", C("ffd24a"), 7, 5, 1.6)
		snd("ClaimReward", 1.5)
		snd("PurchaseSuccess", 1.2)
	end },
}
S[6].cam = function(t)
	local c = bossS.c
	-- проліт: низько за армією → повз неї до боса → низький ракурс збоку на стрибки → облет і відліт угору на падіння
	local k = seg(t, 0, 6.0)
	local pts = { c + V3(6, 9, 102), c + V3(-8, 10, 68), c + V3(-46, 15, 56), c + V3(-64, 19, 30), c + V3(-60, 27, 58), c + V3(-38, 37, 90) }
	local ats = { c + V3(0, 12, 40), c + V3(0, 20, 0), c + V3(0, 24, 0), c + V3(0, 24, 2), c + V3(0, 14, 8), c + V3(0, 6, 12) }
	local fov = t < 3 and lerp(76, 60, E.sine(seg(t, 0, 3))) or lerp(60, 66, E.sine(seg(t, 3, 6)))
	return look(spline(pts, k), spline(ats, k)), fov
end
S[6].focus = function() return bossS.c and bossS.c + V3(0, 6, 70) end

-- ---------- 7. ФІНАЛ НА АРЕНІ (4,5 с) ----------
S[7] = { name = "Victory", dur = 4.5 }
S[7].prep = function()
	if not bossS.c then return end
	fin.c = bossS.c
	fin.b = bacon(bossS.c + V3(0, 0, 14), bossS.c + V3(0, 0, 40))
	if fin.b then fin.home = fin.b.m:GetPivot(); hideBacon(fin.b) end
	local kinds = { "astral", "aurelian", "platinum", "frostforged", "ruby", "magmaheart", "obsidian", "sapphire", "amethyst", "geode", "silverjaw", "ironclad" }
	fin.g = {}
	for i = 1, 44 do
		local row = (i - 1) // 11
		local col = (i - 1) % 11
		local p = bossS.c + V3((col - 5) * (9.5 + row * 0.8) + (row % 2) * 4.5, 0, 2 - row * 11)
		p = V3(p.X, floorAt(p, bossS.arena), p.Z)
		local m = golem(kinds[(i * 5 % #kinds) + 1], "warrior", (i % 3 == 0) and math.random(3, 7) or 0, 1.1)
		if m then
			m.Parent = live
			ground(m, p, p + V3(0, 0, 10))
			setState(m, "Idle", 1)
			table.insert(fin.g, { m = m, foot = footOf(m), p = p })
			hide(m)
		end
	end
end
S[7].start = function()
	if bossS.m then bossS.m:Destroy(); bossS.m = nil; Boss.bind(nil) end
	local c = fin.c
	fin.t0 = os.clock()
	fin.landed = false
	if fin.b then
		if not fin.r0 then fin.r0 = fin.b.root end
		baconPlace(fin.b, fin.r0 + V3(0, 14, 0))
		baconShock(fin.b, false)
		local up, rv, lk = fin.b.root.UpVector, fin.b.root.RightVector, fin.b.root.LookVector
		baconArm(fin.b, "R", up + rv * 0.25 + lk * 0.1)
		baconArm(fin.b, "L", -up - rv * 0.25)
	end
	for _, g in bossS.g do hide(g.m) end
	for _, g in fin.g do moveGolem(g.m, g.p, V3(0, 0, 1), g.foot) end
	flashWhite(0.8, 0.45)
end
S[7].update = function(t)
	local b = fin.b
	if not b then return end
	local k = clamp01(t / 0.4)
	local y = 14 * (1 - k * k)
	if k >= 1 and not fin.landed then
		fin.landed = true
		local p = fin.r0.Position - V3(0, 3, 0)
		Boss.dust(p, 14, 18, 2, 6)
		snd("Punch", 0.5, 1.3)
		snd("ClaimReward", 1.2, 0.9)
		Boss.ring(p, 7, Color3.new(1, 1, 1), 0.4, 0.3)
		Boss.shake(0.4, 0.3)
	end
	-- після приземлення — маленький відскок
	if k >= 1 then y = math.abs(math.sin(math.min(t - 0.4, 0.42) * 7.5)) * 0.8 end
	baconPlace(b, fin.r0 + V3(0, y, 0))
	local up, rv, lk = b.root.UpVector, b.root.RightVector, b.root.LookVector
	baconArm(b, "R", up + rv * 0.25 + lk * 0.1)
	baconArm(b, "L", -up - rv * 0.25)
end
S[7].cam = function(t)
	local c = fin.c
	local k = E.inout(seg(t, 0, 4.5))
	local pts = { c + V3(0.8, 5.2, 19.5), c + V3(2, 7, 27), c + V3(0, 12, 38), c + V3(0, 17, 46) }
	local ats = { c + V3(0, 5.2, 14), c + V3(0, 5, 10), c + V3(0, 6, -4), c + V3(0, 6, -12) }
	return look(spline(pts, k), spline(ats, k)), lerp(42, 62, E.out(k))
end
S[7].focus = function() return fin.c and fin.c + V3(0, 6, 40) end

-- ---------- 8. CAVE (4,6 с): стенди печери — на кожному майнер, воїн і носій трикутником (11.11.2026) ----------
local caveS = { st = {} }
S[8] = { name = "Cave", dur = 4.6 }
-- [стенд] = { майнер, воїн, носій, мутації… }
local CAVE_TRIOS = {
	{ "obsidian", "moonstone", "sapphire", 4, 0, 3 }, { "ruby", "emerald", "geode", 0, 2, 0 }, { "magmaheart", "ruby", "amethyst", 5, 0, 1 },
	{ "topaz", "sapphire", "silverjaw", 1, 0, 0 }, { "aurelian", "platinum", "frostforged", 6, 3, 0 }, { "emerald", "obsidian", "topaz", 0, 0, 2 },
}
local CAVE_ANG = { 0, 120, -120 } -- майнер до цінника, воїн і носій — задні сторони трикутника
local CAVE_ROLE = { "miner", "warrior", "carrier" }
local CAVE_T = { [1] = 0.55, [3] = 1.35, [5] = 2.15 } -- коли на стенді з'являються големи (решта стоять одразу)
S[8].prep = function()
	local cs = sets:FindFirstChild("CaveSet")
	local stands = cs and cs:FindFirstChild("Stands")
	if not stands then warn("[Trailer] no CaveSet"); return end
	for _, sm in stands:GetChildren() do
		local i = sm:GetAttribute("SlotIndex")
		local bed, board = sm:FindFirstChild("Bed"), sm:FindFirstChild("PriceBoard")
		if type(i) == "number" and CAVE_TRIOS[i] and bed and board then
			local top = bed.Position + V3(0, bed.Size.Y / 2, 0)
			local d = V3(board.Position.X - bed.Position.X, 0, board.Position.Z - bed.Position.Z).Unit
			-- стенд «куплений»: без ціни й зеленого світла
			local pg = board:FindFirstChild("PriceGui")
			local pr = pg and pg:FindFirstChild("Price")
			if pr then pr.Visible = false end
			for _, l in board:GetChildren() do if l:IsA("Light") then l.Enabled = false end end
			local e = { top = top, dir = d, g = {}, fired = false }
			local trio = CAVE_TRIOS[i]
			for r = 1, 3 do
				local outv = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(CAVE_ANG[r])):VectorToWorldSpace(d)
				local m = golem(trio[r], CAVE_ROLE[r], trio[3 + r] or 0, 0.85)
				if m then
					m.Parent = live
					local pos = top + outv * 3.7
					ground(m, pos, pos + outv)
					setState(m, "Idle", 1)
					table.insert(e.g, { m = m, pos = pos, at = pos + outv, base = m:GetScale() })
				end
			end
			caveS.st[i] = e
		end
	end
end
local function cavePlace(g, k: number)
	local want = g.base * math.max(0.03, k)
	if math.abs(g.m:GetScale() - want) > 1e-4 then g.m:ScaleTo(want) end
	ground(g.m, g.pos, g.at)
end
S[8].start = function()
	for i, e in caveS.st do
		e.fired = false
		for _, g in e.g do
			if CAVE_T[i] then hide(g.m) else cavePlace(g, 1) end
		end
	end
end
S[8].update = function(t)
	for i, e in caveS.st do
		local t0 = CAVE_T[i]
		if t0 and t >= t0 then
			if not e.fired then
				e.fired = true
				snd("BuySound", 1.7, 1 + 0.05 * i)
				burst(e.top + V3(0, 3, 0), C("8dff5a"), 1.0)
				Boss.sparks(e.top + V3(0, 2.5, 0), 14, C("ffd84a"))
				fovPunch(3)
			end
			for j, g in e.g do cavePlace(g, backOut(clamp01((t - t0 - (j - 1) * 0.09) / 0.26))) end
		end
	end
end
S[8].cam = function(t)
	local e1 = caveS.st[1]
	if not e1 then return CFrame.new(), 60 end
	-- проїзд проходом між рядами стендів: уздовж ряду 1-3-5, камера трохи попереду стенда, що «спалахує»
	local ref, d = e1.top, e1.dir
	local along = V3(caveS.st[3].top.X - ref.X, 0, caveS.st[3].top.Z - ref.Z).Unit -- від стенда 1 до стенда 3
	local k = E.sine(seg(t, 0, 4.6))
	local p = ref + d * lerp(27, 22, k) + along * lerp(-15, 22, k) + V3(0, lerp(9, 7.5, k), 0)
	local at = ref + d * 1.5 + along * lerp(1, 33, k) + V3(0, 3.2, 0)
	return look(p, at), lerp(60, 54, k)
end
S[8].focus = function() return caveS.st[1] and caveS.st[1].top + V3(0, 6, 0) end

-- ---------- 9. MARKETPLACE (4,2 с): ексклюзивні големи колом біля порталу маркету, ціни й SOLD! (11.11.2026) ----------
local mkS = { g = {} }
S[9] = { name = "Market", dur = 4.2 }
local MK_GOLEMS = { { "cyborg", "miner" }, { "spartan", "warrior" }, { "lampminer", "carrier" }, { "chrono", "miner" }, { "phantom", "warrior" },
	{ "storm", "carrier" }, { "jade", "miner" } }
local MK_TAGS = { "250K", "780K", "1.2M", "89K", "2.3M", "4.5M", "620K" }
local function coins(pos: Vector3, n: number)
	local TS = game:GetService("TweenService")
	for _ = 1, n do
		local a = math.random() * math.pi * 2
		local r = 2.5 + math.random() * 3.5
		local c = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon, Color = C("ffd23a"), Size = V3(0.22, 1.15, 1.15), CFrame = CFrame.new(pos) * CFrame.Angles(0, a, math.pi / 2) }, fx)
		local mid = pos + V3(math.cos(a) * r * 0.6, 3 + math.random() * 3, math.sin(a) * r * 0.6)
		local endp = pos + V3(math.cos(a) * r, -3.5, math.sin(a) * r)
		TS:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(mid) * CFrame.Angles(a, a * 2, math.pi / 2) }):Play()
		task.delay(0.3, function()
			TS:Create(c, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(endp) * CFrame.Angles(a * 3, 0, math.pi / 2), Transparency = 1 }):Play()
			task.delay(0.5, function() c:Destroy() end)
		end)
	end
end
S[9].prep = function()
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local mk = hub and hub:FindFirstChild("Marketplace")
	if not mk then warn("[Trailer] no Marketplace"); return end
	local cf = mk:GetBoundingBox()
	local t2 = mk:FindFirstChild("Tier2")
	local y = t2 and (t2.Position.Y + math.min(t2.Size.X, t2.Size.Y, t2.Size.Z) / 2) or cf.Position.Y
	mkS.c = V3(cf.Position.X, y, cf.Position.Z)
	mkS.g = {}
	-- лічильник «N PLAYERS» над порталом у трейлері не потрібен
	for _, root in { mk, player.PlayerGui } do
		for _, d in root:GetDescendants() do
			if d:IsA("TextLabel") and string.find(d.Text, "PLAYER", 1, true) then
				local bb = d:FindFirstAncestorWhichIsA("BillboardGui")
				if bb and (root == mk or (bb.Adornee and bb.Adornee:IsDescendantOf(mk))) then d.Visible = false end
			end
		end
	end
	local n = #MK_GOLEMS
	for i, spec in MK_GOLEMS do
		local a = (i - 1) / n * math.pi * 2
		local dir = V3(math.cos(a), 0, math.sin(a))
		local m = golem(spec[1], spec[2], 0, 0.68)
		if m then
			m.Parent = live
			local pos = mkS.c + dir * 12.6
			ground(m, pos, pos + dir)
			setState(m, "Idle", 1)
			table.insert(mkS.g, { m = m, tag = MK_TAGS[i], a = a })
		end
	end
end
S[9].start = function()
	mkS.next = 0.3
	mkS.i = 0
	for _, g in mkS.g do g.popT = nil end
end
S[9].update = function(t)
	if #mkS.g == 0 then return end
	if t >= mkS.next and t < 3.9 then
		mkS.next = t + 0.2
		mkS.i += 1
		-- продаж над големом, який зараз у кадрі й найдовше не «продавався» (щоразу інший)
		local ca = math.rad(lerp(-125, -55, E.sine(seg(t, 0, 4.2))))
		local best, bt = nil, math.huge
		for _, g in mkS.g do
			local dlt = math.abs((g.a - ca + math.pi) % (2 * math.pi) - math.pi)
			local last = (g.popT or -9) + math.random() * 0.05
			if dlt < 1.6 and last < t - 0.7 and last < bt then best, bt = g, last end
		end
		if best then
			best.popT = t
			local top = headTop(best.m)
			pop(top + V3(0, 1.6, 0), "SOLD!", C("5af078"), 2.9, 2.6, 0.9)
			pop(top + V3(0, 4.8, 0), "+$" .. best.tag, C("ffd84a"), 2.1, 3.2, 0.9)
			coins(top + V3(0, 0.5, 0), 10)
			Boss.sparks(top, 12, C("ffd84a"))
			burst(top, C("ffe27a"), 0.9)
			snd("SellSound", 1.5, 0.95 + 0.05 * (mkS.i % 5), top, 0.05, "mksold")
		end
	end
end
S[9].cam = function(t)
	local c = mkS.c
	if not c then return CFrame.new(), 60 end
	local k = E.sine(seg(t, 0, 4.2))
	local a = math.rad(lerp(-125, -55, k))
	local r = lerp(36, 29, k)
	return look(c + V3(math.cos(a) * r, lerp(13, 9.5, k), math.sin(a) * r), c + V3(0, 7, 0)), lerp(60, 54, k)
end
S[9].focus = function() return mkS.c and mkS.c + V3(0, 6, -25) end

-- підписи кадрів (11.11.2026)
S[1].caption = "ROLL RARE GOLEMS"
S[2].caption = "MINE ORE"
S[3].caption = "EARN MONEY"
S[4].caption = "UNLOCK NEW WORLDS"
S[5].caption = "MUTATE YOUR GOLEMS"
S[6].caption = "DEFEAT BOSSES"
S[7].caption = "BUILD YOUR ARMY"
S[8].caption = "SAVE YOUR BEST GOLEMS"
S[9].caption = "TRADE GOLEMS"
local ORDER_ALL = { 1, 2, 3, 4, 5, 8, 9, 6, 7 }

-- ================= рушій =================
local stopFlag = false
local function prepare()
	if prepared then return end
	prepared = true
	info.Text = "PREPARING…"
	do
		local mine
		local nf = workspace:FindFirstChild("Niches")
		for _, n in (nf and nf:GetChildren() or {}) do if n:GetAttribute("OwnerUserId") == player.UserId then mine = n end end
		local function relPath(inst, root)
			local t = {}
			local x = inst
			while x and x ~= root do table.insert(t, 1, x.Name); x = x.Parent end
			return x == root and t or nil
		end
		if mine then
			for _, g in player.PlayerGui:GetChildren() do
				-- табло «NEXT MAP» не копіюємо: для кожної мапи його будує MapBoard (_G.TrailerMapBoard, кадр 4) зі своїм номером мапи
				if (g:IsA("SurfaceGui") or g:IsA("BillboardGui")) and g.Adornee and g.Adornee:IsDescendantOf(mine)
					and not (_G.TrailerMapBoard and g.Name:sub(1, 9) == "MapBoard_") then
					local path = relPath(g.Adornee, mine)
					for _, si in { 1, 3, 5, 6 } do
						local st = stage(si)
						local x = st
						for _, nm in path or {} do x = x and x:FindFirstChild(nm) end
						if x and x:IsA("BasePart") then
							local c = g:Clone()
							c.Name = "Trailer_" .. g.Name .. "_" .. si
							for _, d in c:GetDescendants() do if d:IsA("LuaSourceContainer") then d:Destroy() end end
							c.Adornee = x
							c.Enabled = true
							c.Parent = ui.Parent
						end
					end
				end
			end
		end
	end
	for _, d in sets:GetDescendants() do if d:IsA("BillboardGui") then d.Enabled = false end end
	workspace:SetAttribute("TrailerLive", true)
	for i = 1, #S do
		local ok, err = pcall(S[i].prep)
		if not ok then warn("[Trailer] prep " .. i .. ": " .. tostring(err)) end
		task.wait()
	end
	for i = 1, #S do
		local f = S[i].focus and S[i].focus()
		if f and false then focusEv:FireServer(f); task.wait(0.6) end
	end
	info.Text = ""
end

local function setShotTime(s, t, dt)
	if s.update then s.update(t, dt) end
	local cf, fov = s.cam(t)
	camCF, camFov = cf, fov or 70
end

local function runShot(i)
	local s = S[i]
	if not s then return end
	curShot = i
	local f = s.focus and s.focus()
	if f and false then focusEv:FireServer(f) end
	if s.start then s.start() end
	local events = {}
	for _, e in s.events or {} do table.insert(events, { e[1], e[2], false }) end
	local t0 = os.clock()
	local last = t0
	setShotTime(s, 0, 0)
	while not stopFlag do
		local now = os.clock()
		local t = now - t0
		if t >= s.dur then break end
		for _, e in events do
			if not e[3] and t >= e[1] then
				e[3] = true
				task.spawn(function() local ok, er = pcall(e[2]); if not ok then warn("[Trailer] ev", er) end end)
			end
		end
		local ok, er = pcall(setShotTime, s, t, now - last)
		if not ok then warn("[Trailer] shot " .. i, er); break end
		if s.caption then
			local cin = s.capIn or 0.3
			local cout = s.capOut or (s.dur - 0.5)
			setCaption(s.caption, math.min(E.out(seg(t, cin, cin + 0.4)), 1 - E.inout(seg(t, cout, cout + 0.4))))
		end
		last = now
		RunService.RenderStepped:Wait()
	end
	if s.stop then pcall(s.stop) end
	setCaption(s.caption or "", 0)
	curShot = 0
end

local musicVol = {}
local function muteMusic(on: boolean)
	for _, d in SoundService:GetDescendants() do
		if d:IsA("Sound") and (d.Name:find("Music") or (d.Parent and d.Parent.Name:find("Music"))) then
			if on then if musicVol[d] == nil then musicVol[d] = d.Volume end; d.Volume = musicVol[d] * MUSIC_BOOST
			elseif musicVol[d] ~= nil then d.Volume = musicVol[d] end
		end
	end
	if not on then musicVol = {} end
end
local running = false
local function play(list)
	if running then return end
	running = true
	stopFlag = false
	hideUi(true)
	muteMusic(true)
	workspace:SetAttribute("TrailerLive", true)
	black.BackgroundTransparency = 0
	active = true
	prepare()
	quiet = true
	-- прогрів: камера (за чорним екраном) стоїть у ключових точках кожного кадру, щоб довантажились деталі й текстури
	for _, i in list do
		local sh = S[i]
		if sh then
			local f = sh.focus and sh.focus()
			if f and false then focusEv:FireServer(f) end
			if sh.start then pcall(sh.start) end
			for _, u in { 0, 0.35, 0.7, 0.95 } do
				local ok = pcall(setShotTime, sh, sh.dur * u, 0)
				if ok then task.wait(0.45) end
			end
		end
		if stopFlag then break end
	end
	quiet = false
	if #list > 1 then
		for n = 3, 1, -1 do info.Text = tostring(n); task.wait(1) end
	else
		task.wait(0.3)
	end
	info.Text = ""
	black.BackgroundTransparency = 1
	for _, i in list do
		if stopFlag then break end
		runShot(i)
	end
	if #list > 1 and not stopFlag then
		tween(black, 0.25, { BackgroundTransparency = 0 })
		task.wait(1.5)
	end
	running = false
end

local function stop()
	stopFlag = true
	task.wait(0.1)
	active = false
	black.BackgroundTransparency = 1
	info.Text = ""
	hideUi(false)
	muteMusic(false)
	workspace:SetAttribute("TrailerLive", false)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	workspace.CurrentCamera.FieldOfView = 70
end

UIS.InputBegan:Connect(function(io, gp)
	if gp then return end
	local kc = io.KeyCode
	if kc == Enum.KeyCode.F6 then
		task.spawn(play, ORDER_ALL)
	elseif kc == Enum.KeyCode.F7 then
		task.spawn(prepare)
	elseif kc == Enum.KeyCode.F8 then
		task.spawn(stop)
	else
		local map = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
			[Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6, [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9 }
		local n = map[kc]
		if n and not running then task.spawn(play, { n }) end
	end
end)

_G.TrailerPlay = function(list) task.spawn(play, list) end
_G.TrailerStop = function() task.spawn(stop) end
_G.TrailerPrepare = function() prepare() end
_G.TrailerPeek = function(n, t)
	prepare()
	hideUi(true)
	active = true
	local s = S[n]
	if s.start then s.start() end
	for _, e in s.events or {} do if e[1] <= t then pcall(e[2]) end end
	-- оновлення з кроком (щоб стан кадру на момент t був як у справжньому прогоні)
	local tt = 0
	while tt < t do pcall(setShotTime, s, tt, 0.1); tt += 0.1 end
	setShotTime(s, t, 0)
	if s.caption then setCaption(s.caption, 1) end
	local f = s.focus and s.focus()
	if f and false then focusEv:FireServer(f) end
	return tostring(camCF.Position)
end

-- команди для перевірки з плагіна / командного рядка (_G там інший): PlayerGui.TrailerUI.TrailerCmd:Invoke(op, ...)
local cmd = Instance.new("BindableFunction")
cmd.Name = "TrailerCmd"
cmd.OnInvoke = function(op, a, b)
	if op == "prepare" then prepare(); return "ok"
	elseif op == "peek" then return _G.TrailerPeek(a, b)
	elseif op == "play" then task.spawn(play, a); return "ok"
	elseif op == "stop" then task.spawn(stop); return "ok"
	end
end
cmd.Parent = ui
