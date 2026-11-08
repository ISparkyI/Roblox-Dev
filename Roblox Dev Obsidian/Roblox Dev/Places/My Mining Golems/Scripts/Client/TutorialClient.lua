--!nonstrict
-- TutorialClient — інтерактивне навчання (05.11.2026, GDD/Plan - Tutorial). Де: StarterPlayer/StarterPlayerScripts/TutorialClient.
-- Сервер — TutorialService (кроки TutStep 1..10, TutorialDone, нагорода). Тут:
--   • рука-провідник: кістки передпліччя й кисті, вказівний палець, жовта обвідка (Highlight крізь стіни), легке сяйво;
--     анімації: гойдання, «тик» пальцем, «затиск» (E), переліт, «провідник» (гравець далі FAR стад — рука летить перед ним
--     і показує напрям + стрілки на підлозі), помах на прощання;
--   • 05.11.2026 v2: рука — мультяшна біла рукавичка (об'ємна), чорна обвідка + золоте сяйво, іскри біля пальця;
--     підпис біля руки — нейтральний для всіх платформ (Roll, Buy…, без клавіш); об'єкт, з яким працює рука, — золота обвідка й легке сяйво;
--     фінал — «лайк» (великий палець угору): вискакує, росте, вибухає іскрами й шматочками і зникає;
--     наприкінці 3 покупки на табло плоту (Ore Spawn → Ore Limit → Plots), потім «You're ready!»;
--   • 2D-рука (та сама модель у ViewportFrame) — для кнопок у вікнах (PLACE GOLEMS, EQUIP BEST, Select All, Sell);
--   • мінімум UI: поки йде навчання, сховані HIDE_GUIS (HUD-кнопки, лічильники, підказки); у кінці — повертаються;
--   • кнопка SKIP унизу → підтвердження (без нагороди 100 діамантів) → Remotes/TutorialAction ("Skip").
-- Підписи біля руки — 1–2 слова, окремі TextLabel (автопереклад Roblox).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local StyleA = require(Shared:WaitForChild("StyleA"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local REWARD = 100
local FAR = 24 -- далі — режим «провідник»
local HIDE_GUIS = { "MainHUD", "BoostsHUD", "OfflineHint", "TeleportHUD" }
local DIA_ICON = "rbxassetid://126442692946356"
local BONE = Color3.fromHex("f2ead8")
local GOLD = Color3.fromHex("ffd23a")
local INK = Color3.fromHex("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function stroke(o, color, th, tr)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, o)
end

-- ===== модель руки (05.11.2026 v2): мультяшна біла рукавичка — об'ємна, з чорними швами й розтрубом манжети =====
--   кінчик вказівного пальця в (0,0,0), рука тягнеться в +Z (до манжети); тильна сторона — вгору (+Y)
local U = 0.62 -- стадів на одиницю креслення (довжина ≈ 3,7 стада, ширина ≈ 1,7)
local GLOVE = Color3.fromHex("fbfbf8")
local SEAM = Color3.fromHex("2a2c31")
local function handParts(): { any }
	local P = {}
	local function bone(a, b, r, col) table.insert(P, { kind = "bone", a = a, b = b, r = r, col = col }) end
	local function ball(a, r, col) table.insert(P, { kind = "ball", a = a, r = r, col = col }) end
	local function ell(a, size, col) table.insert(P, { kind = "ell", a = a, size = size, col = col }) end
	-- вказівний палець: товстий, з круглим кінчиком
	ball(Vector3.new(0, 0, 0.42), 0.42)
	bone(Vector3.new(0, 0, 0.42), Vector3.new(0, 0.02, 2.7), 0.42)
	-- долоня — сплюснутий еліпсоїд
	ell(Vector3.new(-0.55, -0.05, 3.55), Vector3.new(2.5, 1.45, 2.4))
	-- зігнуті пальці під вказівним (три «кулачки»)
	for i, x in { -0.55, -1.1, -1.6 } do ball(Vector3.new(x + 0.05, -0.35, 2.55 + i * 0.12), 0.47) end
	-- великий палець збоку
	bone(Vector3.new(0.55, -0.15, 3.7), Vector3.new(0.95, -0.3, 2.55), 0.36)
	ball(Vector3.new(0.95, -0.3, 2.55), 0.36)
	-- зап'ясток і манжета-розтруб
	bone(Vector3.new(-0.5, 0, 4.4), Vector3.new(-0.5, 0, 5.05), 0.85)
	bone(Vector3.new(-0.5, 0, 5.0), Vector3.new(-0.5, 0, 5.55), 1.12)
	bone(Vector3.new(-0.5, 0, 5.5), Vector3.new(-0.5, 0, 5.75), 1.22)
	-- шви на тильній стороні
	for _, x in { -1.15, -0.55, 0.05 } do bone(Vector3.new(x, 0.69, 2.95), Vector3.new(x, 0.62, 4.05), 0.07, SEAM) end
	-- шов манжети
	bone(Vector3.new(-0.5, 0, 5.02), Vector3.new(-0.5, 0, 5.1), 1.15, SEAM)
	return P
end
local function buildHand(parent: Instance, forViewport: boolean?, grow: number?): (Model, { BasePart }, { CFrame })
	local m = Instance.new("Model")
	m.Name = "TutorialHand"
	local parts, offs = {}, {}
	for _, e in handParts() do
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic; p.Color = e.col or GLOVE
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		local off
		if e.kind == "ball" then
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.one * (e.r * 2 * U)
			off = CFrame.new(e.a * U)
		elseif e.kind == "ell" then
			p.Size = e.size * U
			new("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, p)
			off = CFrame.new(e.a * U)
		else
			local a, b = e.a * U, (e.b :: Vector3) * U
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new((b - a).Magnitude, e.r * 2 * U, e.r * 2 * U)
			off = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
		end
		if grow then p.Size *= grow end
		p.CFrame = off
		p.Parent = m
		table.insert(parts, p); table.insert(offs, off)
	end
	m.Parent = parent
	return m, parts, offs
end

-- ===== 3D-рука =====
local fxFolder = new("Folder", { Name = "TutorialFx" }, workspace)
local hand, hParts, hOffs = buildHand(fxFolder)
-- виділення: чорна мультяшна обвідка (видно крізь стіни) + золоте сяйво, що пульсує; світло й іскри біля пальця
local hl = new("Highlight", { Adornee = hand, OutlineColor = INK, OutlineTransparency = 0, FillColor = GOLD, FillTransparency = 0.9,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, hand)
-- товща обвідка: копія рукавички трохи більша (×1,14), майже прозора, зі своєю чорною обвідкою — лінія виходить ширшою
local shell, sParts, sOffs = buildHand(fxFolder, false, 1.14)
for _, sp in sParts do sp.Transparency = 0.97 end
local shellHL = new("Highlight", { Adornee = shell, OutlineColor = INK, OutlineTransparency = 0, FillTransparency = 1,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, shell)
for i, sp in sParts do table.insert(hParts, sp); table.insert(hOffs, sOffs[i]) end
new("PointLight", { Color = Color3.fromHex("ffe7a3"), Range = 8, Brightness = 0.7, Shadows = false }, hParts[3])
local sparks = new("ParticleEmitter", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(GOLD), LightEmission = 1,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }), Lifetime = NumberRange.new(0.4, 0.7),
	Rate = 5, Speed = NumberRange.new(1, 2.5), SpreadAngle = Vector2.new(180, 180), Transparency = NumberSequence.new(0.2) }, hParts[1])
local tagBB = new("BillboardGui", { Size = UDim2.fromOffset(220, 46), StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0), AlwaysOnTop = true,
	LightInfluence = 0, MaxDistance = 400, Adornee = hParts[1] }, fxFolder)
local tagText = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true, Text = "",
	TextColor3 = WHITE }, tagBB)
new("UITextSizeConstraint", { MaxTextSize = 30 }, tagText)
stroke(tagText, INK, 3.5)
local handCF = CFrame.new(0, -500, 0)
local handShown = true -- 06.11.2026: стартове setHandVisible(false) нижче має спрацювати (було false — рука з обвідкою висіла за картою, видно крізь стіни)
local function setHandVisible(on: boolean)
	if handShown == on then return end
	handShown = on
	for _, p in hParts do p.LocalTransparencyModifier = on and 0 or 1 end
	hl.Enabled = on
	shellHL.Enabled = on
	sparks.Enabled = on
	tagBB.Enabled = on
end
setHandVisible(false)

-- стрілки на підлозі (режим «провідник»)
local chev = {}
for i = 1, 6 do
	local c = new("Model", { Name = "Chevron" }, fxFolder)
	for s = -1, 1, 2 do
		new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon,
			Color = GOLD, Transparency = 1, Size = Vector3.new(0.35, 0.1, 1.6), Name = s < 0 and "L" or "R" }, c)
	end
	chev[i] = c
end
-- підсвітка об'єкта, з яким зараз працює рука: золота обвідка + легке золоте сяйво (пульсує)
local targetHL = new("Highlight", { Name = "TargetHighlight", OutlineColor = GOLD, OutlineTransparency = 0.1, FillColor = GOLD, FillTransparency = 0.88,
	DepthMode = Enum.HighlightDepthMode.Occluded, Enabled = false }, fxFolder)
local function setTargetObj(obj: Instance?)
	if obj and (obj:IsA("Model") or obj:IsA("BasePart")) then
		if targetHL.Adornee ~= obj then targetHL.Adornee = obj end
		targetHL.Enabled = true
	else
		targetHL.Enabled = false
	end
end
local function hideChevrons() for _, c in chev do for _, p in c:GetChildren() do p.Transparency = 1 end end end

-- ===== 2D-рука (ViewportFrame) =====
local ui = new("ScreenGui", { Name = "TutorialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local root = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, ui)
local VP = 190
local vp = new("ViewportFrame", { Size = UDim2.fromOffset(VP, VP), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 195, 180),
	LightColor = Color3.fromRGB(255, 245, 225), LightDirection = Vector3.new(-0.4, -1, -0.6), Visible = false, ZIndex = 50 }, root)
local vpCam = new("Camera", { FieldOfView = 30 }, vp)
vp.CurrentCamera = vpCam
local vpScale = new("UIScale", {}, vp) -- 05.11.2026: рука, підпис і SKIP масштабуються під висоту екрана (телефон)
local h2, h2Parts, h2Offs = buildHand(vp, true)
local DIR2 = Vector3.new(-0.62, 0.72, -0.3).Unit -- палець на екрані вгору-ліворуч, рука — вниз-праворуч
do
	local rot = CFrame.lookAt(Vector3.zero, DIR2)
	for i, prt in h2Parts do prt.CFrame = rot * h2Offs[i] end
end
vpCam.CFrame = CFrame.lookAt(Vector3.new(0, 0, 16) - DIR2 * 2.2, -DIR2 * 2.2)
-- де на кадрі кінчик пальця (пікселі від лівого верхнього кута)
local function tipPixel(): Vector2
	local v = vpCam.CFrame:PointToObjectSpace(Vector3.zero)
	local t = math.tan(math.rad(vpCam.FieldOfView / 2))
	local x, y = v.X / (-v.Z * t), v.Y / (-v.Z * t)
	return Vector2.new((0.5 + x / 2) * VP, (0.5 - y / 2) * VP)
end
local TIP2 = tipPixel()
local tag2 = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(260, 40), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true, Text = "",
	TextColor3 = WHITE, Visible = false, ZIndex = 51 }, root)
local tagScale = new("UIScale", {}, tag2)
-- масштаб туторіал-UI: висота екрана / 720 (як MainHUD), не менше 0,55
local function uiS(): number return math.clamp(root.AbsoluteSize.Y / 720, 0.55, 1) end
new("UITextSizeConstraint", { MaxTextSize = 28 }, tag2)
stroke(tag2, INK, 3.5)

-- ===== кнопка SKIP і підтвердження =====
local skipBtn = StyleA.new(root, { size = Vector2.new(150, 46), position = Vector2.new(0, 0), color = "gray", text = "SKIP", textSize = 24,
	clickable = true, zIndex = 40 })
local skipRoot = skipBtn.root or skipBtn.group
if skipRoot then
	-- окрема рамка з UIScale (UIScale самої кнопки може використовувати StyleA для анімації натискання)
	local skHold = new("Frame", { Name = "SkipHolder", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.fromOffset(150, 46),
		BackgroundTransparency = 1 }, root)
	local sk = new("UIScale", {}, skHold)
	skipRoot.AnchorPoint = Vector2.new(0, 0); skipRoot.Position = UDim2.fromOffset(0, 0); skipRoot.Parent = skHold
	local function fitSkip() local k = uiS(); sk.Scale = k; skHold.Position = UDim2.new(0.5, 0, 1, -math.floor(22 * k)) end
	fitSkip(); root:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSkip)
end
local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, Visible = false, Active = true, ZIndex = 70 }, root)
local CW, CH = 460, 250
local conf = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(CW, CH),
	BackgroundColor3 = Color3.fromHex("4a4f57"), ZIndex = 71 }, dim)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("5d636b"), Color3.fromHex("3c4047")) }, conf)
new("UIStroke", { Color = INK, Thickness = 5 }, conf)
local confScale = new("UIScale", {}, conf)
local function confText(y, h, size, text, color, order)
	local t = new("TextLabel", { Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(CW, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color, ZIndex = 72 }, conf)
	stroke(t, INK, 4)
	return t
end
confText(18, 54, 40, "SKIP TUTORIAL?", WHITE)
local warnRow = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(CW / 2, 80),
	Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 72 }, conf)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, warnRow)
local function warnPart(text, color, order, localize)
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = XBOLD, TextSize = 22, Text = text, TextColor3 = color, AutoLocalize = localize,
		Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = order, ZIndex = 72 }, warnRow)
	stroke(t, INK, 3)
end
warnPart("You won't get", Color3.fromHex("e9edf1"), 1, true)
warnPart(tostring(REWARD), Color3.fromHex("8fe0ff"), 2, false)
new("ImageLabel", { BackgroundTransparency = 1, Image = DIA_ICON, Size = UDim2.fromOffset(30, 30), LayoutOrder = 3, ZIndex = 72 }, warnRow)
warnPart("for finishing it", Color3.fromHex("e9edf1"), 4, true)
local bCont = StyleA.new(conf, { size = Vector2.new(190, 66), position = Vector2.new(30, CH - 92), color = "green", text = "CONTINUE", textSize = 26, clickable = true, zIndex = 73 })
local bSkip = StyleA.new(conf, { size = Vector2.new(190, 66), position = Vector2.new(CW - 220, CH - 92), color = "red", text = "SKIP", textSize = 28, clickable = true, zIndex = 73 })

-- ===== стан =====
local running = false
local hiddenByUs: { [ScreenGui]: boolean } = {}
local function restoreGuis()
	for g in hiddenByUs do if g.Parent then g.Enabled = true end end
	table.clear(hiddenByUs)
end
local function enforceHidden()
	for _, n in HIDE_GUIS do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false; hiddenByUs[g] = true end
	end
end

StyleA.bind(skipBtn, { debounce = 0.3, onClick = function()
	dim.Visible = true
	confScale.Scale = 0.7
	TweenService:Create(confScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end })
StyleA.bind(bCont, { debounce = 0.2, onClick = function() dim.Visible = false end })
StyleA.bind(bSkip, { debounce = 0.5, onClick = function()
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("TutorialAction")
	if rf then pcall(rf.InvokeServer, rf, "Skip") end
	dim.Visible = false
end })

-- ===== цілі =====
local function myNiche(): Model?
	local f = workspace:FindFirstChild("Niches")
	if not f then return nil end
	for _, m in f:GetChildren() do if m:GetAttribute("OwnerUserId") == player.UserId then return m end end
	return nil
end
local function findText(rootInst: Instance?, pred): GuiObject?
	if not rootInst then return nil end
	for _, d in rootInst:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and pred(d.Text) then return d end
	end
	return nil
end
local function cardButton(lbl: Instance?): GuiObject?
	-- картка (екран ролу / табло): піднятись до картки й знайти її кнопку «стиль A»
	local x = lbl and lbl.Parent
	for _ = 1, 3 do
		if not x then break end
		for _, d in x:GetDescendants() do if d:IsA("ImageButton") and d.Name == "StyleAButton" then return d end end
		x = x.Parent
	end
	return nil
end
-- точка в світі для елемента SurfaceGui (Front / Back)
local function surfacePoint(gui: SurfaceGui, el: GuiObject): (Vector3?, Vector3?)
	local part = gui.Adornee
	if not (part and part:IsA("BasePart")) then return nil end
	local abs = gui.AbsoluteSize
	if abs.X <= 0 then return nil end
	local c = el.AbsolutePosition + el.AbsoluteSize / 2
	local u, v = c.X / abs.X, c.Y / abs.Y
	local s = part.Size
	local lp, n
	if gui.Face == Enum.NormalId.Back then
		lp = Vector3.new((u - 0.5) * s.X, (0.5 - v) * s.Y, s.Z / 2); n = Vector3.new(0, 0, 1)
	else
		lp = Vector3.new((0.5 - u) * s.X, (0.5 - v) * s.Y, -s.Z / 2); n = Vector3.new(0, 0, -1)
	end
	return part.CFrame:PointToWorldSpace(lp), part.CFrame:VectorToWorldSpace(n)
end
local function guiOpen(name: string): boolean
	local g = playerGui:FindFirstChild(name)
	local mr = g and g:FindFirstChild("ModalRoot")
	return g ~= nil and g.Enabled and mr ~= nil and mr.Visible
end

-- ===== обводка кнопки, з якою взаємодіє рука (05.11.2026) =====
-- Кнопка на екрані, на SurfaceGui (картки) чи на BillboardGui (підказки Roll / Buy, COLLECT): золота рамка з чорним
-- контуром навколо неї (дочірня рамка самої кнопки — працює в усіх видах GUI) + «хвиля», що розходиться й гасне (пульсація).
-- кнопка BillboardGui, прив'язаного до obj (підказки CustomPrompts, COLLECT ящика); кеш 0,4 с — пошук по PlayerGui не щокадру
local bbCache = { obj = nil :: any, t = 0, btn = nil :: GuiObject? }
local function bbButton(obj: Instance?): GuiObject?
	if not obj then return nil end
	if bbCache.obj == obj and os.clock() - bbCache.t < 0.4 and (bbCache.btn == nil or bbCache.btn.Parent) then return bbCache.btn end
	local best, ba = nil, 0
	local function scan(r: Instance)
		for _, bb in r:GetDescendants() do
			if bb:IsA("BillboardGui") and bb.Enabled then
				local a = bb.Adornee or bb.Parent
				if a and (a == obj or a:IsDescendantOf(obj)) then
					for _, d in bb:GetDescendants() do
						if d:IsA("GuiButton") and d.Visible then
							local s = d.AbsoluteSize.X * d.AbsoluteSize.Y
							if s > ba then best, ba = d, s end
						end
					end
				end
			end
		end
	end
	scan(playerGui); scan(obj)
	bbCache.obj, bbCache.t, bbCache.btn = obj, os.clock(), best
	return best
end
local ring: Frame? = nil
local ringFor: GuiObject? = nil
local ringGold: UIStroke? = nil
local wave: Frame? = nil
local waveStroke: UIStroke? = nil
local waveScale: UIScale? = nil
local function ringOn(btn: GuiObject?)
	if btn == ringFor and ring and ring.Parent then return end
	if ring then ring:Destroy() end
	if wave then wave:Destroy() end
	ring, wave, ringFor = nil, nil, btn
	if not btn then return end
	local cr = btn:FindFirstChildOfClass("UICorner")
	-- бейдж клавіші (E / R — дитина кнопки, TextLabel з 1–2 літер) лишається ПОВЕРХ рамки: рамка на шар нижче за нього
	local zr = 60
	for _, ch in btn:GetChildren() do
		if ch:IsA("TextLabel") and #ch.Text <= 2 and ch.BackgroundTransparency < 1 then zr = math.min(zr, ch.ZIndex - 1) end
	end
	local rad = cr and cr.CornerRadius or UDim.new(0, 3) -- кнопки StyleA без заокруглень — рамка майже прямокутна, впритул
	local function frameAround(pad: number): Frame
		local f = new("Frame", { Name = "TutRing", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, pad, 1, pad), BackgroundTransparency = 1, Active = false, ZIndex = zr }, btn)
		new("UICorner", { CornerRadius = rad }, f)
		return f
	end
	-- золота рамка впритул до краю кнопки (обводка Border малюється назовні), чорний контур — одразу за нею
	ring = frameAround(6)
	new("UIStroke", { Color = INK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ring)
	local inner = frameAround(0)
	inner.Parent = ring
	inner.Size = UDim2.new(1, -6, 1, -6)
	ringGold = new("UIStroke", { Color = GOLD, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inner)
	-- хвиля пульсації
	wave = frameAround(6)
	waveStroke = new("UIStroke", { Color = GOLD, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, wave)
	waveScale = new("UIScale", {}, wave)
end
local function ringTick(t: number)
	if not (ring and ring.Parent) then return end
	local p = (t % 1.1) / 1.1
	if ringGold then ringGold.Transparency = 0.3 * (0.5 + 0.5 * math.sin(t * 6)) end
	if waveScale then waveScale.Scale = 1 + 0.22 * p end
	if waveStroke then waveStroke.Transparency = p; waveStroke.Thickness = 4 * (1 - p) + 1 end
end

-- ціль кроку: { world = Vector3, normal = Vector3?, area = Vector3 (куди йти), tag = "…", mode = "tap" | "hold" | "look" } або { gui = GuiObject, tag = "…" }
local function target(step: number): any
	local niche = myNiche()
	if not niche then return nil end
	local rs = niche:FindFirstChild("RollSystem")
	local lever = rs and rs:FindFirstChild("RollLeverModel")
	local knob = lever and lever:FindFirstChild("RollLever") and lever.RollLever:FindFirstChild("Knob")
	local stand = rs and rs:FindFirstChild("Stands") and rs.Stands:FindFirstChild("Stand1")
	local buy = stand and stand:FindFirstChild("RollBuyAnchor")
	local plot = niche:FindFirstChild("Plots") and niche.Plots:FindFirstChild("Plot1")
	if step == 1 or step == 4 then
		-- кнопка ROLL — BillboardGui CustomPrompt на RollLeverModel.PromptAnchor (не всередині RollLever): шукаємо по всій моделі важеля
		return knob and { world = knob.Position, tag = "Roll", mode = "hold", obj = lever.RollLever, btn = bbButton(lever) }
	elseif step == 2 or step == 5 then
		return buy and { world = buy.Position, tag = "Buy", mode = "hold", obj = stand, btn = bbButton(stand) }
	elseif step == 3 then
		-- 07.11.2026: картки ролей лежать на підлозі перед важелем (RollSystem/RoleCards, RollStationClient) — рука тицяє в картку Carrier згори
		local cards = rs and rs:FindFirstChild("RoleCards")
		local card
		for _, c in (cards and cards:GetChildren() or {}) do if c:GetAttribute("Role") == "Carrier" then card = c end end
		if card and card:IsA("BasePart") then
			local g = playerGui:FindFirstChild("RollCard_" .. niche.Name .. "_Carrier")
			local b = g and g:FindFirstChildWhichIsA("TextButton", true)
			return { world = card.Position + card.CFrame.UpVector * 0.15, normal = card.CFrame.UpVector, tag = "Carrier", mode = "tap", area = card.Position, obj = card, btn = b } -- 08.11.2026: картка на рампі (нахилена)
		end
		return nil
	elseif step == 6 then
		if guiOpen("PlotPlaceWindow") then
			local lbl = findText(playerGui:FindFirstChild("PlotPlaceWindow"), function(t) return t == "EQUIP BEST" end)
			return lbl and { gui = lbl.Parent, tag = "Equip Best" }
		end
		local ppb = playerGui:FindFirstChild("PlacePlotButton")
		local rt = ppb and ppb:FindFirstChild("Root")
		if rt and rt.Visible then
			local b = rt:FindFirstChild("StyleAButton", true)
			return b and { gui = b, tag = "Place golems" }
		end
		local base = plot and plot:FindFirstChild("Base")
		return base and { world = base.Position + Vector3.new(0, 1, 0), tag = "Your plot", mode = "look", area = base.Position, obj = base }
	elseif step == 7 then
		if guiOpen("PlotPlaceWindow") then
			local w = playerGui.PlotPlaceWindow
			local x = w.ModalRoot:FindFirstChild("Pop") and w.ModalRoot.Pop:FindFirstChild("StyleAButton")
			return x and { gui = x, tag = "Close", showTag = true } -- хрестик без напису — підпис потрібен
		end
		local ores = plot and plot:FindFirstChild("Ores")
		for _, o in (ores and ores:GetChildren() or {}) do
			if o:GetAttribute("Tut") and not o:GetAttribute("Broken") then
				return { world = o:GetPivot().Position + Vector3.new(0, 1.5, 0), tag = "Mining!", mode = "look", obj = o }
			end
		end
		local crate = plot and plot:FindFirstChild("Crate")
		return crate and { world = crate:GetPivot().Position + Vector3.new(0, 3, 0), tag = "Ore goes here", mode = "look", obj = crate }
	elseif step == 8 then
		local crate = plot and plot:FindFirstChild("Crate")
		return crate and { world = crate:GetPivot().Position + Vector3.new(0, 4.5, 0), tag = "Collect", mode = "tap", obj = crate, btn = bbButton(crate) }
	elseif step == 9 then
		if guiOpen("SellWindow") then
			local w = playerGui.SellWindow
			local sell = findText(w, function(t) return string.sub(t, 1, 4) == "Sell" and string.find(t, "%$") ~= nil end)
			if sell then return { gui = sell.Parent, tag = "Sell" } end
			local all = findText(w, function(t) return t == "Select All" end)
			return all and { gui = all.Parent, tag = "Select All" }
		end
		local ring = niche:FindFirstChild("Sell") and niche.Sell:FindFirstChild("Ring")
		local rc = ring and ring:FindFirstChild("RingCenter", true)
		return rc and { world = rc.Position + Vector3.new(0, 1, 0), tag = "Sell", mode = "look", area = rc.Position, obj = ring }
	elseif step == 10 then
		local panel = niche:FindFirstChild("Upgrade panels") and niche["Upgrade panels"]:FindFirstChild("Plot_Upgrade_panel")
		local scr = panel and panel:FindFirstChild("screen")
		local g = playerGui:FindFirstChild("PlotUpgrades_" .. niche.Name)
		-- 3 покупки по черзі (TutBuys — скільки вже купив на цьому кроці)
		local want = ({ "Ore Spawn", "Ore Limit", "Plots" })[(tonumber(player:GetAttribute("TutBuys")) or 0) + 1] or "Ore Spawn"
		local lbl = findText(g, function(t) return t == want end)
		local b = cardButton(lbl)
		if g and b then
			local p, n = surfacePoint(g, b)
			if p then return { world = p, normal = n, tag = "Upgrade", mode = "tap", area = scr and scr.Position, obj = scr, btn = b } end
		end
		return scr and { world = scr.Position, tag = "Upgrade", mode = "tap", area = scr.Position, obj = scr }
	end
	return nil
end

-- ===== анімація =====
local function tapAmp(mode: string, t: number): number
	if mode == "hold" then
		local ph = t % 2.2
		if ph < 0.25 then return ph / 0.25 elseif ph < 1.35 then return 1 elseif ph < 1.6 then return 1 - (ph - 1.35) / 0.25 end
		return 0
	elseif mode == "tap" then
		local ph = t % 1.6
		if ph < 0.6 then return math.abs(math.sin(ph / 0.3 * math.pi)) end
		return 0
	end
	return 0.25 + 0.25 * math.sin(t * 2.4) -- look: м'яке «показування»
end
local function floorY(): number
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hrp and hum then return hrp.Position.Y - hum.HipHeight - hrp.Size.Y / 2 + 0.08 end
	return 0
end

local lastStep = -1
local waveT: number? = nil
-- «лайк» для фіналу: кулак з великим пальцем угору (будується в stopTut)
local likeM: Model? = nil
local likeParts, likeOffs, likeSizes = {}, {}, {}
local likeBoom = false
local LIKE_YAW, LIKE_ROLL = 70, 5 -- поворот «лайка» (градуси): 70 — майже профіль (як емодзі 👍: пальці вправо, манжета вліво), 5 — великий палець майже вертикально
local function buildLike(): Model
	local P = {}
	local function bone(a, b, r, col) table.insert(P, { kind = "bone", a = a, b = b, r = r, col = col }) end
	local function ball(a, r, col) table.insert(P, { kind = "ball", a = a, r = r, col = col }) end
	local function ell(a, size) table.insert(P, { kind = "ell", a = a, size = size }) end
	-- кулак (центр у 0), пальці зігнуті вперед (−Z, до камери), великий палець угору, манжета позаду (+Z)
	ell(Vector3.new(0, 0, 0.2), Vector3.new(2.3, 2.3, 2.3))
	for i, y in { 0.75, 0.2, -0.35, -0.85 } do ball(Vector3.new(-0.15 + i * 0.03, y, -0.95), 0.5 - i * 0.03) end
	bone(Vector3.new(0.55, 0.55, -0.35), Vector3.new(0.55, 2.0, -0.4), 0.45)
	ball(Vector3.new(0.55, 2.0, -0.4), 0.45)
	bone(Vector3.new(0, -0.1, 1.2), Vector3.new(0, -0.1, 1.75), 0.95)
	bone(Vector3.new(0, -0.1, 1.7), Vector3.new(0, -0.1, 2.2), 1.15)
	bone(Vector3.new(0, -0.1, 1.72), Vector3.new(0, -0.1, 1.8), 1.18, Color3.fromHex("2a2c31"))
	local m = Instance.new("Model")
	m.Name = "TutorialLike"
	for _, e in P do
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic; p.Color = e.col or Color3.fromHex("fbfbf8")
		local off
		if e.kind == "ball" then
			p.Shape = Enum.PartType.Ball; p.Size = Vector3.one * (e.r * 2 * U); off = CFrame.new(e.a * U)
		elseif e.kind == "ell" then
			p.Size = e.size * U; new("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, p); off = CFrame.new(e.a * U)
		else
			local a, b = e.a * U, (e.b :: Vector3) * U
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new((b - a).Magnitude, e.r * 2 * U, e.r * 2 * U)
			off = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
		end
		p.CFrame = CFrame.new(0, -500, 0)
		p.Parent = m
		table.insert(likeParts, p); table.insert(likeOffs, off); table.insert(likeSizes, p.Size)
	end
	new("Highlight", { Adornee = m, OutlineColor = INK, OutlineTransparency = 0, FillColor = GOLD, FillTransparency = 0.92,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, m)
	m.Parent = fxFolder
	return m
end
local stepTagShown = ""
local function setTag(text: string)
	if stepTagShown ~= text then
		stepTagShown = text
		tagText.Text = text; tag2.Text = text
	end
end

RunService.RenderStepped:Connect(function(dt)
	if not running and not waveT then return end
	local t = os.clock()
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	if waveT then
		-- фінал (05.11.2026 v3): «лайк» — кулак з великим пальцем угору біля гравця, лицем до камери: вискакує,
		--   гойдається, росте й тремтить, потім вибухає (іскри, шматочки рукавички, спалах) і зникає
		local age = t - waveT
		local cam = workspace.CurrentCamera
		if hrp and cam and likeM then
			local side = cam.CFrame.RightVector
			local base = hrp.Position + side * 3.2 + Vector3.new(0, 3.4, 0)
			local s
			if age < 0.35 then
				local k = age / 0.35; local c1 = 1.9; s = 1 + (c1 + 1) * (k - 1) ^ 3 + c1 * (k - 1) ^ 2 -- Back out
			elseif age < 1.2 then
				s = 1
			elseif age < 1.65 then
				local k = (age - 1.2) / 0.45; s = 1 + 0.7 * k * k
			else
				s = 1.7
			end
			s = math.max(0.05, s)
			local wob = age < 1.2 and math.sin(age * 7) * 0.12 or (age < 1.65 and (math.random() - 0.5) * 0.25 * ((age - 1.2) / 0.45) or 0)
			local cf = CFrame.lookAt(base + Vector3.new(0, math.sin(age * 3) * 0.15, 0), cam.CFrame.Position)
				* CFrame.Angles(0, 0, math.rad(LIKE_ROLL) + wob) * CFrame.Angles(0, math.rad(LIKE_YAW), 0) -- боком до камери (профіль кулака, великий палець угору)
			if age < 1.65 then
				local cfs = {}
				for i, o in likeOffs do
					likeParts[i].Size = likeSizes[i] * s
					cfs[i] = cf * CFrame.new(o.Position * s) * (o - o.Position)
				end
				workspace:BulkMoveTo(likeParts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
			elseif not likeBoom then
				likeBoom = true
				local center = cf.Position
				likeM:Destroy(); likeM = nil
				UISounds.play("purchase", 0.1)
				-- спалах
				local fl = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Shape = Enum.PartType.Ball,
					Material = Enum.Material.Neon, Color = GOLD, Transparency = 0.2, Size = Vector3.one * 1.5, CFrame = CFrame.new(center) }, fxFolder)
				TweenService:Create(fl, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * 9, Transparency = 1 }):Play()
				-- іскри
				local at = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(center) }, fxFolder)
				for _, col in { GOLD, WHITE } do
					local pe = new("ParticleEmitter", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(col), LightEmission = 1,
						Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) }), Lifetime = NumberRange.new(0.5, 1),
						Speed = NumberRange.new(10, 22), SpreadAngle = Vector2.new(180, 180), Drag = 3, Enabled = false }, at)
					pe:Emit(40)
				end
				-- шматочки рукавички
				for _ = 1, 14 do
					local r = 0.25 + math.random() * 0.35
					local bit = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Shape = Enum.PartType.Ball,
						Material = Enum.Material.SmoothPlastic, Color = math.random() < 0.15 and Color3.fromHex("2a2c31") or Color3.fromHex("fbfbf8"),
						Size = Vector3.one * r * 2, CFrame = CFrame.new(center) }, fxFolder)
					local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.1, math.random() - 0.5).Unit
					TweenService:Create(bit, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ CFrame = CFrame.new(center + dir * (5 + math.random() * 4)), Size = Vector3.one * 0.05, Transparency = 1 }):Play()
				end
			end
		end
		local fade = math.clamp((age - 1.65) / 0.5, 0, 1)
		tagText.TextTransparency = fade
		if age > 2.6 then waveT = nil; fxFolder:Destroy(); ui:Destroy() end
		return
	end
	enforceHidden()
	local step = tonumber(player:GetAttribute("TutStep")) or 1
	if step ~= lastStep then lastStep = step end
	local tg = target(step)
	if not tg then setHandVisible(false); vp.Visible = false; tag2.Visible = false; hideChevrons(); setTargetObj(nil); ringOn(nil); return end
	ringOn(tg.btn or tg.gui)
	ringTick(t)
	setTag(tg.tag or "")
	setTargetObj(tg.obj)
	targetHL.FillTransparency = 0.86 + 0.06 * math.sin(t * 4)
	if tg.gui then
		-- 2D-рука над кнопкою
		setHandVisible(false); hideChevrons()
		local gui = tg.gui :: GuiObject
		local c = gui.AbsolutePosition + gui.AbsoluteSize / 2 - root.AbsolutePosition
		local amp = tapAmp("tap", t)
		local poke = Vector2.new(0.62, 0.72).Unit * (14 * (1 - amp) + 2)
		local bob = Vector2.new(0, math.sin(t * 2.2) * 2)
		local k = uiS()
		vpScale.Scale = k; tagScale.Scale = k
		poke *= k
		vp.Position = UDim2.fromOffset(c.X - TIP2.X * k + poke.X + bob.X, c.Y - TIP2.Y * k + poke.Y + bob.Y)
		vp.Visible = true
		-- підпис: праворуч від кнопки (над кнопкою часто її заголовок); праворуч не влазить — над кнопкою;
		-- і там не влазить — під рукою. Завжди в межах екрана.
		local sw, sh = root.AbsoluteSize.X, root.AbsoluteSize.Y
		local tw, th = 260 * k, 40 * k
		local half = gui.AbsoluteSize / 2
		local tx, ty
		local w = math.min(tw, (tag2.TextBounds.X + 8) * 1) -- фактична ширина тексту (TextBounds уже з масштабом)
		if c.X + half.X + 14 * k + w <= sw - 8 then
			tx, ty = c.X + half.X + 14 * k + w / 2, c.Y + th / 2
		else
			ty = c.Y - half.Y - 6
			if ty - th < 8 then ty = math.min(sh - 8, c.Y + VP * 0.62 * k + th) end
			tx = c.X
		end
		tx = math.clamp(tx, 8 + tw / 2, sw - 8 - tw / 2)
		tag2.Position = UDim2.fromOffset(tx, ty)
		-- 05.11.2026: кнопки у вікнах і так підписані (Select All, Sell, Equip Best…) — текст біля 2D-руки не дублюємо;
		--   лише для кнопок без напису (showTag, наприклад хрестик)
		tag2.Visible = tg.showTag == true
		return
	end
	vp.Visible = false; tag2.Visible = false
	if not hrp then return end
	local tp = tg.world :: Vector3
	local area = (tg.area or tp) :: Vector3
	local flatD = Vector3.new(area.X - hrp.Position.X, 0, area.Z - hrp.Position.Z)
	local goal
	if flatD.Magnitude > FAR then
		-- провідник: рука перед гравцем, палець — у бік цілі; стрілки на підлозі
		local dir = flatD.Unit
		local pos = hrp.Position + dir * 8.5 + Vector3.new(0, 2.2 + math.sin(t * 2.2) * 0.2, 0) -- 08.11.2026: рука далі перед гравцем (було 5)
		goal = CFrame.lookAt(pos, pos + dir + Vector3.new(0, -0.15, 0))
		local y = floorY()
		local shift = (t * 5) % 3.5
		-- 08.11.2026: стрілки лягають на верх того, що під ними (сходинки, плити) — не ховаються в текстурі
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { player.Character, fxFolder }
		rp.RespectCanCollide = true
		for i, c in chev do
			local d = 3 + (i - 1) * 3.5 + shift
			local a = math.clamp(1 - math.abs(d - 12) / 12, 0, 1)
			local base = Vector3.new(hrp.Position.X, y, hrp.Position.Z) + dir * d
			local hit = workspace:Raycast(base + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rp)
			if hit then base = Vector3.new(base.X, hit.Position.Y + 0.06, base.Z) end
			local cf = CFrame.lookAt(base, base + dir)
			c.L.CFrame = cf * CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 0, 0.55)
			c.R.CFrame = cf * CFrame.Angles(0, math.rad(-40), 0) * CFrame.new(0, 0, 0.55)
			c.L.Transparency = 1 - 0.65 * a; c.R.Transparency = 1 - 0.65 * a
		end
	else
		hideChevrons()
		local appr: Vector3
		if tg.normal then
			appr = ((tg.normal :: Vector3) + Vector3.new(0, 0.55, 0)).Unit
		else
			local toP = Vector3.new(hrp.Position.X - tp.X, 0, hrp.Position.Z - tp.Z)
			local h = toP.Magnitude > 0.1 and toP.Unit or Vector3.zAxis
			appr = (h * 0.55 + Vector3.new(0, 1, 0)).Unit
		end
		local amp = tapAmp(tg.mode or "tap", t)
		local dist = 0.35 + (1 - amp) * 1.1 + math.sin(t * 2) * 0.08
		local tip = tp + appr * dist
		goal = CFrame.lookAt(tip, tp)
	end
	if not handShown then handCF = goal end
	setHandVisible(true)
	hl.FillTransparency = 0.9 + 0.04 * math.sin(t * 4)
	handCF = handCF:Lerp(goal, 1 - math.exp(-dt * 9))
	local cfs = {}
	for i, o in hOffs do cfs[i] = handCF * o end
	workspace:BulkMoveTo(hParts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end)

local function startTut()
	if running then return end
	running = true
	ui.Enabled = true
end
local function stopTut(reward: boolean)
	if not running then return end
	running = false
	restoreGuis()
	vp.Visible = false; tag2.Visible = false; hideChevrons(); setTargetObj(nil); ringOn(nil)
	if skipRoot then skipRoot.Visible = false end
	if reward then
		setHandVisible(false)
		likeM = buildLike()
		tagBB.Adornee = likeParts[1]; tagBB.Enabled = true; tagText.TextTransparency = 0
		setTag("You're ready!")
		waveT = os.clock()
		UISounds.play("claim", 0.1)
		local uiev = RS:FindFirstChild("UIEvents")
		local toast = uiev and uiev:FindFirstChild("Toast")
		if toast then toast:Fire("+" .. REWARD .. " Diamonds!", "blue", nil) end
	else
		fxFolder:Destroy(); ui:Destroy()
	end
end

local function sync()
	if player:GetAttribute("TutorialDone") == true then
		stopTut(player:GetAttribute("TutReward") ~= nil)
	elseif player:GetAttribute("TutStep") ~= nil then
		startTut()
	end
end
player:GetAttributeChangedSignal("TutStep"):Connect(sync)
player:GetAttributeChangedSignal("TutorialDone"):Connect(sync)
sync()
