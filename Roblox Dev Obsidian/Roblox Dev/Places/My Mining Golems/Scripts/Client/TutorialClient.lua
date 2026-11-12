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
local U = 0.78 -- стадів на одиницю креслення (довжина ≈ 4,5 стада, ширина ≈ 2,1); 10.11.2026: більша рука (було 0,62)
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
local VP = 300 -- 10.11.2026: більша 2D-рука (було 190)
local vp = new("ViewportFrame", { Size = UDim2.fromOffset(VP, VP), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 195, 180),
	LightColor = Color3.fromRGB(255, 245, 225), LightDirection = Vector3.new(-0.4, -1, -0.6), Visible = false, ZIndex = 50 }, root)
local vpCam = new("Camera", { FieldOfView = 34 }, vp)
vp.CurrentCamera = vpCam
local vpScale = new("UIScale", {}, vp) -- 05.11.2026: рука, підпис і SKIP масштабуються під висоту екрана (телефон)
local h2, h2Parts, h2Offs = buildHand(vp, true)
-- 10.11.2026: чорна обводка 2D-руки (Highlight у ViewportFrame не працює): 8 чорних силуетів тієї ж руки, зсунутих на OUTLINE пікселів
--   у 8 напрямках, під рукою; позиція, видимість і масштаб — як у vp
local OUTLINE = 4
local outl = {}
for i = 1, 8 do
	local a = (i - 1) * math.pi / 4
	local ov = new("ViewportFrame", { Size = vp.Size, BackgroundTransparency = 1, Ambient = Color3.new(0, 0, 0), LightColor = Color3.new(0, 0, 0),
		ImageColor3 = INK, Visible = false, ZIndex = 49 }, root)
	local oc = new("Camera", { FieldOfView = 34 }, ov)
	ov.CurrentCamera = oc
	local os_ = new("UIScale", {}, ov)
	local _, oParts, oOffs = buildHand(ov, true)
	for _, prt in oParts do prt.Color = Color3.new(0, 0, 0) end
	outl[i] = { vp = ov, cam = oc, scale = os_, parts = oParts, offs = oOffs, d = Vector2.new(math.cos(a), math.sin(a)) * OUTLINE }
end
local function syncOutline()
	local k = vpScale.Scale
	for _, o in outl do
		o.vp.Visible = vp.Visible
		o.scale.Scale = k
		o.vp.Position = vp.Position + UDim2.fromOffset(o.d.X, o.d.Y)
	end
end
vp:GetPropertyChangedSignal("Position"):Connect(syncOutline)
vp:GetPropertyChangedSignal("Visible"):Connect(syncOutline)
vpScale:GetPropertyChangedSignal("Scale"):Connect(syncOutline)
-- 10.11.2026: рука на екрані пряма (не 3/4), тильною стороною (шви) до камери; кінчик пальця — у центрі кадру.
--   "up" — палець угору (рука під кнопкою), "down" — палець униз (рука над кнопкою, якщо знизу не влазить)
local ROT_UP = CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.zAxis, -Vector3.yAxis)
local ROT_DOWN = CFrame.Angles(0, 0, math.pi) * ROT_UP
local ROT_LEFT = CFrame.Angles(0, 0, math.pi / 2) * ROT_UP -- палець ліворуч (рука праворуч від кнопки)
-- 10.11.2026: дзеркальна рука (палець праворуч, рука ліворуч від кнопки): віддзеркалення по осі X екрана
--   (позиція −x, поворот M·R·M) — деталі симетричні (кулі, еліпсоїди, циліндри), тильна сторона так само до камери
local function mirrorX(cf: CFrame): CFrame
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end
local h2Dir = ""
local function setDir2(d: string)
	if h2Dir == d then return end
	h2Dir = d
	local rot = d == "down" and ROT_DOWN or ((d == "left" or d == "right") and ROT_LEFT or ROT_UP)
	local mir = d == "right"
	for i, prt in h2Parts do local cf = rot * h2Offs[i]; prt.CFrame = if mir then mirrorX(cf) else cf end
	for _, o in outl do for i, prt in o.parts do local cf = rot * o.offs[i]; prt.CFrame = if mir then mirrorX(cf) else cf end end
end
setDir2("up")
vpCam.CFrame = CFrame.lookAt(Vector3.new(0, 0, 16), Vector3.zero)
for _, o in outl do o.cam.CFrame = vpCam.CFrame end
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
	-- 10.11.2026: навчання «бос» — пропуск через BossTutorialService (Remotes/BossAction "TutSkip")
	if player:GetAttribute("TutStep") == nil and player:GetAttribute("BossTut") ~= nil then
		local ba = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("BossAction")
		if ba then ba:FireServer("TutSkip") end
		dim.Visible = false
		return
	end
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
		return buy and { world = buy.Position, tag = "", mode = "hold", obj = stand, btn = bbButton(stand) }
	elseif step == 3 then
		-- 10.11.2026: картки ролей — на екрані (RollStationClient, ScreenGui RollRolePanel), з'являються біля важеля.
		--   Панель видно — рука тицяє в картку Carrier; ні — ведемо до важеля (стрілки до нього).
		local pg = playerGui:FindFirstChild("RollRolePanel")
		if pg and pg.Enabled and pg:GetAttribute("Shown") == true then
			local cardC = pg:FindFirstChild("Card_Carrier", true)
			local b = cardC and cardC:FindFirstChild("Hit", true)
			if b then return { gui = b, tag = "Carrier" } end
		end
		return knob and { world = knob.Position, tag = "Carrier", mode = "look", area = knob.Position, obj = lever.RollLever }
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
		-- 10.11.2026: картку прокрутили за край табло — рука на стрілку прокрутки в її бік, а не «повз табло»
		local sf = b and b:FindFirstAncestorWhichIsA("ScrollingFrame")
		if g and b and sf then
			local cx = b.AbsolutePosition.X + b.AbsoluteSize.X / 2
			local x0 = sf.AbsolutePosition.X
			local x1 = x0 + sf.AbsoluteWindowSize.X
			local arrowTxt = if cx < x0 + 20 then "‹" elseif cx > x1 - 20 then "›" else nil
			if arrowTxt then
				local al = findText(g, function(t) return t == arrowTxt end)
				local ab = al and (if al.Parent and al.Parent:IsA("GuiButton") then al.Parent :: GuiObject else cardButton(al))
				if ab then b = ab end
			end
		end
		if g and b then
			local p, n = surfacePoint(g, b)
			if p then return { world = p, normal = n, tag = "Upgrade", mode = "tap", area = scr and scr.Position, obj = scr, btn = b } end
		end
		return scr and { world = scr.Position, tag = "Upgrade", mode = "tap", area = scr.Position, obj = scr }
	end
	return nil
end

-- ===== анімація =====
-- ===== навчання «бос» (10.11.2026, BossTutorialService; атрибут BossTut) =====
-- "roll": картки ролей на екрані й вибрано не Warrior — рука на картці Warrior; далеко від важеля — провідник до важеля;
--   вибрано Warrior — рука на важелі (ROLL). "buy": рука на кнопці Buy підставки з воїном.
--   "join": вікно реєстрації відкрите — рука на JOIN FIGHT; інакше — на кнопці JOIN біля NEXT BOSS (MainHUD/Btn_BossJoin, лише під час реєстрації).
local function visibleChain(g: Instance?): boolean
	while g and g:IsA("GuiObject") do
		if not g.Visible then return false end
		g = g.Parent
	end
	return g ~= nil and (not g:IsA("LayerCollector") or (g :: any).Enabled)
end
local function bossTarget(st: string): any
	local niche = myNiche()
	local rs = niche and niche:FindFirstChild("RollSystem")
	local lever = rs and rs:FindFirstChild("RollLeverModel")
	local knob = lever and lever:FindFirstChild("RollLever") and lever.RollLever:FindFirstChild("Knob")
	if st == "roll" then
		local warrior = player:GetAttribute("RollRole") == "Warrior"
		local pg = playerGui:FindFirstChild("RollRolePanel")
		if not warrior and pg and pg.Enabled and pg:GetAttribute("Shown") == true then
			local cw = pg:FindFirstChild("Card_Warrior", true)
			local b = cw and cw:FindFirstChild("Hit", true)
			if b then return { gui = b, tag = "", showTag = true } end
		end
		if not warrior then
			return knob and { world = knob.Position, tag = "", mode = "look", area = knob.Position, obj = lever.RollLever }
		end
		return knob and { world = knob.Position, tag = "Roll", mode = "hold", obj = lever.RollLever, btn = bbButton(lever) }
	elseif st == "buy" then
		local stands = rs and rs:FindFirstChild("Stands")
		local first = nil
		for i = 1, 10 do
			local stand = stands and stands:FindFirstChild("Stand" .. i)
			local buy = stand and stand:FindFirstChild("RollBuyAnchor")
			if buy then
				first = first or { world = buy.Position, tag = "", mode = "hold", obj = stand, btn = bbButton(stand) }
				local b = bbButton(stand)
				if b then return { world = buy.Position, tag = "", mode = "hold", obj = stand, btn = b } end
			end
		end
		return first
	elseif st == "join" then
		local lw = playerGui:FindFirstChild("BossLobbyWindow")
		local jl = lw and findText(lw, function(t) return t == "JOIN FIGHT" end)
		if jl and visibleChain(jl) then
			local b = jl:FindFirstAncestorWhichIsA("GuiButton") or cardButton(jl) or jl.Parent
			return { gui = b, tag = "Join" }
		end
		local hud = playerGui:FindFirstChild("MainHUD")
		local jb = hud and hud:FindFirstChild("Btn_BossJoin", true)
		if jb and jb:IsA("GuiObject") and visibleChain(jb) then return { gui = jb, tag = "Join", side = "left" } end -- на кнопці й так написано JOIN
		return nil
	elseif st == "claim" then
		-- 10.11.2026: бос переможений — рука на CLAIM у вікні VICTORY! (BossArenaClient, Btn_BossClaim) → додому
		local cb = playerGui:FindFirstChild("Btn_BossClaim", true)
		if cb and cb:IsA("GuiObject") and visibleChain(cb) then return { gui = cb, tag = "Claim" } end
		return nil
	elseif st == "dodge" or st == "back" then
		-- 10.11.2026: урок ухилення — рука на точці подалі від боса (TB_Safe); ухилився — назад до боса (TB_Back)
		local v = player:GetAttribute(st == "dodge" and "TB_Safe" or "TB_Back")
		if typeof(v) == "Vector3" then
			return { world = v + Vector3.new(0, 0.3, 0), area = v, mode = "look", tag = "" } -- підказка — банер по центру (нижче)
		end
		return nil
	end
	if st == "shop" then
		-- 10.11.2026: після навчання з босом — стрілки на підлозі до Boss Shop (магазин за Fossil Teeth); близько — рука над ним
		local v = player:GetAttribute("BossShopPos")
		if typeof(v) == "Vector3" then
			local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
			local sh = hub and hub:FindFirstChild("Shops") and hub.Shops:FindFirstChild("EventShop")
			return { world = v + Vector3.new(0, 1, 0), area = v, mode = "look", obj = sh, tag = "" }
		end
		return nil
	end
	return nil -- "fight": воїни б'ють самі, рука не потрібна
end

-- ===== навчання Cave (10.11.2026, MapService / CaveStandService; атрибут CaveTut) =====
-- Перший MAP 2 без голема в печері. Поза печерою — до входу (ENTER CAVE); у печері: стенд не куплений — на BUY першого стенда;
--   куплений — на кнопку стенда (OPEN / PLACE); вікно стенда відкрите — на вкладку або голема з атрибутом TutPick
--   (його обирає CaveStandUI: найсильніший голем вільного класу). Підписів біля руки немає — на кнопках і так написано.
local function myCave(): Model?
	local f = workspace:FindFirstChild("Caves")
	if not f then return nil end
	for _, c in f:GetChildren() do if c:GetAttribute("OwnerUserId") == player.UserId then return c end end
	return nil
end
local function caveTarget(): any
	if guiOpen("CaveStandWindow") then
		local w = playerGui:FindFirstChild("CaveStandWindow")
		for _, d in w:GetDescendants() do
			if d:IsA("GuiObject") and d:GetAttribute("TutPick") == true and visibleChain(d) then return { gui = d, tag = "" } end
		end
		return nil
	end
	if player:GetAttribute("InCave") ~= true then
		local niche = myNiche()
		local gc = niche and niche:FindFirstChild("GolemCave")
		local pa = gc and gc:FindFirstChild("PromptAnchor", true)
		if pa and pa:IsA("BasePart") then
			return { world = pa.Position, area = pa.Position, mode = "hold", tag = "", btn = bbButton(pa) }
		end
		return nil
	end
	local cave = myCave()
	local stands = cave and cave:FindFirstChild("Stands")
	if not stands then return nil end
	local want = 1
	local okJ, bought = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("CaveStands") or "[]")
	if okJ and type(bought) == "table" and #bought > 0 then
		want = math.huge
		for _, i in bought do if type(i) == "number" and i < want then want = i end end
	end
	for _, s in stands:GetChildren() do
		if s:GetAttribute("SlotIndex") == want then
			local sb = s:FindFirstChild("StandButton")
			if sb and sb:IsA("BasePart") then
				return { world = sb.Position, area = sb.Position, mode = "hold", tag = "", obj = s, btn = bbButton(sb) }
			end
		end
	end
	return nil
end

-- 10.11.2026: стрілки на підлозі — по шляху PathfindingService (в обхід стін), а не навпростець.
--   10.11.2026 v2: повний шлях до цілі рахується ОДИН раз; далі лише:
--   • пройдені точки відкидаються (масив коротшає — менше роботи щокадру);
--   • гравець відійшов від шляху (> OFF_R) — рахується лише короткий шматок від гравця до точки попереду на старому шляху
--     і «пришивається» до решти шляху (решта точок не перераховується); зовсім далеко (> FAR_OFF) — шлях заново;
--   • проєкція гравця на шлях шукається лише серед перших SCAN відрізків. Немає шляху — стрілки навпростець.
local PFS = game:GetService("PathfindingService")
local AGENT = { AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 }
local OFF_R, FAR_OFF, SCAN = 5, 40, 24
local pathPts: { Vector3 }? = nil
local pathGoal: Vector3? = nil
local pathBusy = false
local fixAt = 0
local function computePath(from: Vector3, goal: Vector3, done: ({ Vector3 }?) -> ())
	pathBusy = true
	task.spawn(function()
		local path = PFS:CreatePath(AGENT)
		local ok = pcall(function() path:ComputeAsync(from, goal) end)
		local pts: { Vector3 }? = nil
		if ok and (path.Status == Enum.PathStatus.Success or path.Status == Enum.PathStatus.ClosestNoPath) then
			local l = {}
			for _, w in path:GetWaypoints() do table.insert(l, w.Position) end
			if #l >= 2 then pts = l end
		end
		pathBusy = false
		done(pts)
	end)
end
-- найближча до origin точка шляху (у площині) серед перших SCAN відрізків: відстань, номер відрізка, частка t
local function project(pts: { Vector3 }, origin: Vector3): (number, number, number)
	local best, bi, bt = math.huge, 1, 0
	for i = 1, math.min(#pts - 1, SCAN) do
		local a, b = pts[i], pts[i + 1]
		local abx, abz = b.X - a.X, b.Z - a.Z
		local l2 = abx * abx + abz * abz
		local tt = l2 > 0 and math.clamp(((origin.X - a.X) * abx + (origin.Z - a.Z) * abz) / l2, 0, 1) or 0
		local dx, dz = origin.X - (a.X + abx * tt), origin.Z - (a.Z + abz * tt)
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < best then best, bi, bt = dist, i, tt end
	end
	return best, bi, bt
end
local function refreshPath(from: Vector3, goal: Vector3)
	-- нова ціль — повний шлях один раз
	if not pathGoal or ((pathGoal :: Vector3) - goal).Magnitude >= 1 then
		if pathBusy then return end
		pathGoal = goal; pathPts = nil; fixAt = os.clock()
		computePath(from, goal, function(pts) if pathGoal == goal then pathPts = pts end end)
		return
	end
	local pts = pathPts
	if not pts then
		-- шляху немає (не знайшовся) — спробувати ще раз, але не частіше ніж раз на 2 с
		if not pathBusy and os.clock() - fixAt > 2 then
			fixAt = os.clock()
			computePath(from, goal, function(np) if pathGoal == goal then pathPts = np end end)
		end
		return
	end
	local dist, i = project(pts, from)
	-- пройдене відкидаємо (лишаємо поточний відрізок)
	if i > 1 and not pathBusy then
		local n = table.create(#pts - i + 1)
		for k = i, #pts do n[#n + 1] = pts[k] end
		pathPts = n; pts = n; i = 1
	end
	if dist > OFF_R and not pathBusy and os.clock() - fixAt > 0.4 then
		fixAt = os.clock()
		if dist > FAR_OFF then
			computePath(from, goal, function(np) if pathGoal == goal and np then pathPts = np end end)
		else
			-- короткий шматок до точки на 2 вузли попереду; решта шляху без змін
			local j = math.min(#pts, i + 2)
			computePath(from, pts[j], function(np)
				if pathGoal ~= goal or not np or pathPts ~= pts then return end
				local merged = np
				for k = j + 1, #pts do merged[#merged + 1] = pts[k] end
				pathPts = merged
			end)
		end
	end
end
-- точка шляху на відстані d (по площині) від проєкції origin на шлях; повертає позицію й напрям відрізка
local function alongPath(origin: Vector3, d: number): (Vector3?, Vector3?)
	local pts = pathPts
	if not pts then return nil, nil end
	local best, bi, bt = project(pts, origin)
	if best > 12 then return nil, nil end -- далеко від шляху — поки шматок не дорахувався, стрілки навпростець
	local i, tt, rem = bi, bt, d
	while i < #pts do
		local a, b = pts[i], pts[i + 1]
		local seg = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = seg.Magnitude
		local left = len * (1 - tt)
		if len > 0.01 and rem <= left then
			return a + (b - a) * (tt + rem / len), seg.Unit
		end
		rem -= left; i += 1; tt = 0
	end
	return nil, nil -- далі кінця шляху
end

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
local boomF: Folder? = nil
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
				boomF = new("Folder", { Name = "TutBoom" }, workspace) -- 10.11.2026: шматки вибуху окремо (fxFolder лишається для навчання «бос»)
				local center = cf.Position
				likeM:Destroy(); likeM = nil
				UISounds.play("purchase", 0.1)
				-- спалах
				local fl = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Shape = Enum.PartType.Ball,
					Material = Enum.Material.Neon, Color = GOLD, Transparency = 0.2, Size = Vector3.one * 1.5, CFrame = CFrame.new(center) }, boomF)
				TweenService:Create(fl, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * 9, Transparency = 1 }):Play()
				-- іскри
				local at = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(center) }, boomF)
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
						Size = Vector3.one * r * 2, CFrame = CFrame.new(center) }, boomF)
					local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.1, math.random() - 0.5).Unit
					TweenService:Create(bit, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ CFrame = CFrame.new(center + dir * (5 + math.random() * 4)), Size = Vector3.one * 0.05, Transparency = 1 }):Play()
				end
			end
		end
		local fade = math.clamp((age - 1.65) / 0.5, 0, 1)
		tagText.TextTransparency = fade
		-- 10.11.2026: рука й UI не знищуються — потрібні для навчання «бос» (BossTutorialService)
		if age > 2.6 then
			waveT = nil
			if boomF then boomF:Destroy(); boomF = nil end
			ui.Enabled = false; tagBB.Enabled = false; tagBB.Adornee = hParts[1]; tagText.TextTransparency = 0
		end
		return
	end
	-- 10.11.2026: навчання «бос» (BossTutorialService, атрибут BossTut) — після основного; HUD не ховаємо (потрібна кнопка JOIN)
	local bossSt = player:GetAttribute("TutStep") == nil and player:GetAttribute("BossTut") or nil
	local caveOn = player:GetAttribute("TutStep") == nil and not bossSt and player:GetAttribute("CaveTut") ~= nil -- 10.11.2026: навчання Cave
	if not bossSt and not caveOn then enforceHidden() end
	local step = tonumber(player:GetAttribute("TutStep")) or 1
	if step ~= lastStep then lastStep = step end
	local tg = if bossSt then bossTarget(bossSt) elseif caveOn then caveTarget() else target(step)
	if not tg then setHandVisible(false); vp.Visible = false; tag2.Visible = false; hideChevrons(); setTargetObj(nil); ringOn(nil); return end
	-- 10.11.2026: кнопка «у світі» (BillboardGui CustomPrompts: ROLL, FREE / ціна Buy, COLLECT…) видна на екрані — 2D-рука на неї,
	--   як на кнопку HUD; підпис кроку (Buy, Roll…) — над кнопкою. Далеко / кнопки ще немає — 3D-рука на об'єкті, як раніше.
	-- 10.11.2026: гравець далеко від цілі (далі FAR) — кнопку у світі не підміняємо 2D-рукою: лише стрілки на підлозі (нижче)
	local nearT = true
	if not tg.gui and hrp then
		local ar = (tg.area or tg.world) :: Vector3?
		if ar then nearT = Vector3.new(ar.X - hrp.Position.X, 0, ar.Z - hrp.Position.Z).Magnitude <= FAR end
	end
	if not tg.gui and tg.btn and nearT then
		local b = tg.btn :: GuiObject
		local bb = b.Parent and b:FindFirstAncestorWhichIsA("BillboardGui")
		local cam = workspace.CurrentCamera
		local ad = bb and (bb.Adornee or bb.Parent)
		if bb and bb.Enabled and cam and ad and b.AbsoluteSize.X > 4 and (ad:IsA("BasePart") or ad:IsA("Attachment")) then
			local wp = (if ad:IsA("Attachment") then (ad :: Attachment).WorldPosition else (ad :: BasePart).Position)
				+ bb.StudsOffsetWorldSpace + cam.CFrame:VectorToWorldSpace(bb.StudsOffset)
			local v, onScreen = cam:WorldToViewportPoint(wp)
			if onScreen and v.Z > 0 then
				local off = (b.AbsolutePosition - bb.AbsolutePosition) + b.AbsoluteSize / 2 - bb.AbsoluteSize / 2
				local scr = Vector2.new(v.X, v.Y) + off
				local vs = cam.ViewportSize
				if scr.X > 0 and scr.Y > 0 and scr.X < vs.X and scr.Y < vs.Y then
					-- 10.11.2026: підпис лише якщо на кнопці немає такого ж слова (ROLL — без «Roll»; FREE / ціна — з «Buy»)
					local dup = false
					local tl = string.lower(tg.tag or "")
					for _, d in b:GetDescendants() do
						if d:IsA("TextLabel") and tl ~= "" and string.find(string.lower(d.Text), tl, 1, true) then dup = true; break end
					end
					tg = { gui = b, screen = scr, tag = tg.tag, showTag = not dup, tagAbove = true, obj = tg.obj }
				end
			end
		elseif cam and tg.world and b:FindFirstAncestorWhichIsA("SurfaceGui") then
			-- 10.11.2026: кнопка на табло (SurfaceGui, картки прокачки) — 2D-рука згори вниз на кнопку, без підпису
			local v, onScreen = cam:WorldToViewportPoint(tg.world :: Vector3)
			if onScreen and v.Z > 0 then
				tg = { gui = b, screen = Vector2.new(v.X, v.Y), half = Vector2.new(0, 10), forceDown = true, showTag = false, obj = tg.obj, btn = b }
			end
		end
	end
	ringOn(tg.btn or tg.gui)
	ringTick(t)
	setTag(tg.tag or "")
	setTargetObj(tg.obj)
	targetHL.FillTransparency = 0.86 + 0.06 * math.sin(t * 4)
	if tg.gui then
		-- 2D-рука над кнопкою
		setHandVisible(false); hideChevrons()
		local gui = tg.gui :: GuiObject
		local c = (tg.screen :: Vector2?) or (gui.AbsolutePosition + gui.AbsoluteSize / 2 - root.AbsolutePosition)
		local k = uiS()
		vpScale.Scale = k; tagScale.Scale = k
		-- 10.11.2026: рука збоку від кнопки, а не на ній: під кнопкою пальцем угору; знизу не влазить — над кнопкою пальцем униз
		local half0 = (tg.half :: Vector2?) or gui.AbsoluteSize / 2
		-- спершу праворуч від кнопки (палець ліворуч); не влазить — під кнопкою (палець угору); і там ні — над нею (палець униз)
		-- 10.11.2026: side = "left" — рука ліворуч від кнопки, дзеркальна, палець праворуч (JOIN біля NEXT BOSS: праворуч — таймер і BOSS)
		local leftSide = tg.side == "left" and not tg.forceDown
		local right = not leftSide and not tg.forceDown and c.X + half0.X + VP * 0.5 * k < root.AbsoluteSize.X - 4
		local down = tg.forceDown == true or (not right and not leftSide and c.Y + half0.Y + VP * 0.5 * k > root.AbsoluteSize.Y - 4)
		setDir2(leftSide and "right" or (right and "left" or (down and "down" or "up")))
		local edge = if leftSide then Vector2.new(c.X - half0.X - 2, c.Y)
			elseif right then Vector2.new(c.X + half0.X + 2, c.Y)
			else Vector2.new(c.X + half0.X * 0.2, if down then c.Y - half0.Y - 2 else c.Y + half0.Y + 2)
		local amp = tapAmp("tap", t)
		local poke = (if leftSide then Vector2.new(-1, 0) elseif right then Vector2.new(1, 0) else Vector2.new(0, if down then -1 else 1)) * (14 * (1 - amp) + 2) * k
		local bob = Vector2.new(0, math.sin(t * 2.2) * 2)
		vp.Position = UDim2.fromOffset(edge.X - TIP2.X * k + poke.X + bob.X, edge.Y - TIP2.Y * k + poke.Y + bob.Y)
		vp.Visible = true
		syncOutline() -- 10.11.2026: обводка в тому ж кадрі (сигнал зміни властивості приходить із затримкою — обводка відставала)
		-- підпис: праворуч від кнопки (над кнопкою часто її заголовок); праворуч не влазить — над кнопкою;
		-- і там не влазить — під рукою. Завжди в межах екрана.
		local sw, sh = root.AbsoluteSize.X, root.AbsoluteSize.Y
		local tw, th = 260 * k, 40 * k
		local half = gui.AbsoluteSize / 2
		local tx, ty
		local w = math.min(tw, (tag2.TextBounds.X + 8) * 1) -- фактична ширина тексту (TextBounds уже з масштабом)
		if tg.tagAbove or right or leftSide then
			tx, ty = c.X, if down then c.Y + half.Y + th + 6 else c.Y - half.Y - 6 -- над кнопкою у світі (Buy над FREE); рука зверху — підпис під кнопкою
		elseif c.X + half.X + 14 * k + w <= sw - 8 then
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
		-- провідник: рука перед гравцем, палець — у бік цілі; стрілки на підлозі (10.11.2026: по шляху в обхід стін)
		refreshPath(hrp.Position, area)
		local dir = flatD.Unit
		do local _, d0 = alongPath(hrp.Position, 3); if d0 then dir = d0 end end
		local pos = hrp.Position + dir * 8.5 + Vector3.new(0, 2.2 + math.sin(t * 2.2) * 0.2, 0) -- 08.11.2026: рука далі перед гравцем (було 5)
		goal = CFrame.lookAt(pos, pos + dir + Vector3.new(0, -0.15, 0))
		tagBB.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
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
			local cdir = dir
			if pathPts then
				local pp, pd = alongPath(hrp.Position, d)
				if pp and pd then base = Vector3.new(pp.X, y, pp.Z); cdir = pd else a = 0 end -- за кінцем шляху — не показуємо
			end
			local hit = workspace:Raycast(base + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rp)
			if hit then base = Vector3.new(base.X, hit.Position.Y + 0.06, base.Z) end
			local cf = CFrame.lookAt(base, base + cdir)
			c.L.CFrame = cf * CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 0, 0.55)
			c.R.CFrame = cf * CFrame.Angles(0, math.rad(-40), 0) * CFrame.new(0, 0, 0.55)
			c.L.Transparency = 1 - 0.65 * a; c.R.Transparency = 1 - 0.65 * a
		end
		-- 10.11.2026: далеко — руки немає, ведуть лише стрілки на підлозі
		setHandVisible(false)
		return
	else
		hideChevrons()
		local appr: Vector3
		local camFlat = Vector3.zAxis
		-- 10.11.2026: «показати» об'єкт (руда, плот) — палець над верхом моделі, а не всередині неї
		if tg.mode == "look" and tg.obj and tg.obj:IsA("Model") then
			local bcf, bsz = (tg.obj :: Model):GetBoundingBox()
			local top = bcf.Position.Y + bsz.Y / 2 + 0.2
			if tp.Y < top then tp = Vector3.new(tp.X, top, tp.Z) end
		end
		if tg.normal then
			appr = ((tg.normal :: Vector3) + Vector3.new(0, 0.55, 0)).Unit
		else
			-- 10.11.2026: рука згори над ціллю, трохи нахилена до камери, тильна сторона (шви) — до камери:
			--   з камери за спиною гравця рукавичку видно «до нас», палець — униз на ціль (було: рука від гравця, видно манжету)
			local cam = workspace.CurrentCamera
			local toC = cam and Vector3.new(cam.CFrame.Position.X - tp.X, 0, cam.CFrame.Position.Z - tp.Z) or Vector3.zero
			camFlat = toC.Magnitude > 0.1 and toC.Unit or Vector3.zAxis
			appr = (Vector3.new(0, 1, 0) + camFlat * 0.3).Unit
		end
		local amp = tapAmp(tg.mode or "tap", t)
		local dist = 0.35 + (1 - amp) * 1.1 + math.sin(t * 2) * 0.08
		local tip = tp + appr * dist
		goal = if tg.normal then CFrame.lookAt(tip, tp) else CFrame.lookAt(tip, tp, camFlat)
		tagBB.StudsOffsetWorldSpace = Vector3.new(0, 6, 0) -- підпис над рукою (рука вертикальна, ~4,5 стада)
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
		setHandVisible(false); ui.Enabled = false -- 10.11.2026: не знищуємо (навчання «бос»)
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

-- 10.11.2026: навчання «бос» — та сама рука й рамки, без ховання HUD; SKIP — лише до арени ("roll" / "buy" / "join")
local bossOn = false
local function bossSkip()
	local st = player:GetAttribute("BossTut")
	local can = bossOn and (st == "roll" or st == "buy" or st == "join")
	if skipRoot then skipRoot.Visible = can end
	if bossOn and not can then dim.Visible = false end
	warnRow.Visible = not bossOn -- «не отримаєш 100 діамантів» — лише в основному навчанні
end
local function bossSync()
	-- 10.11.2026: той самий режим (рука без ховання HUD, без SKIP) — і для навчання Cave (CaveTut)
	local on = player:GetAttribute("TutStep") == nil and (player:GetAttribute("BossTut") ~= nil or player:GetAttribute("CaveTut") ~= nil)
	if on == bossOn then
		if bossOn then bossSkip() end -- 10.11.2026: поза навчанням «бос» SKIP не чіпаємо (інакше ховався SKIP основного навчання)
		return
	end
	bossOn = on
	if on then
		running = true; ui.Enabled = true
		bossSkip()
	else
		warnRow.Visible = true
		running = false
		vp.Visible = false; tag2.Visible = false; hideChevrons(); setTargetObj(nil); ringOn(nil); setHandVisible(false)
		if not waveT then ui.Enabled = false end
	end
end
player:GetAttributeChangedSignal("BossTut"):Connect(bossSync)
player:GetAttributeChangedSignal("CaveTut"):Connect(bossSync)
bossSync()
-- 10.11.2026: навчання Cave скінчилось (перший голем на стенді) — тост і звук
do
	local caveWas = player:GetAttribute("CaveTut")
	player:GetAttributeChangedSignal("CaveTut"):Connect(function()
		local now = player:GetAttribute("CaveTut")
		if caveWas ~= nil and now == nil and player:GetAttribute("CaveTutDone") == true then
			UISounds.play("claim", 0.1)
			local uiev = RS:FindFirstChild("UIEvents")
			local toast = uiev and uiev:FindFirstChild("Toast")
			if toast then toast:Fire("Golems saved! Now you can go to Map 2", "green", nil) end
		end
		caveWas = now
	end)
end

-- 10.11.2026: урок ухилення (BossTut "dodge") — «сповільнення часу»: удар боса повільний (сервер), екран трохи блякне й темнішає
local Lighting = game:GetService("Lighting")
local slowCC: ColorCorrectionEffect? = nil
-- банер-підказка по центру екрана: "dodge" — відійди від боса; "back" — повертайся до боса
local banner = new("TextLabel", { Name = "DodgeHint", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34),
	Size = UDim2.fromOffset(760, 64), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true, Text = "", TextColor3 = GOLD,
	Visible = false, ZIndex = 60 }, root)
new("UITextSizeConstraint", { MaxTextSize = 46 }, banner)
stroke(banner, INK, 5)
local bannerScale = new("UIScale", {}, banner)
RunService.RenderStepped:Connect(function()
	if banner.Visible then bannerScale.Scale = uiS() * (1 + 0.05 * math.sin(os.clock() * 6)) end
end)
local function bannerSync()
	local st = player:GetAttribute("BossTut")
	if st == "dodge" then
		banner.Text = "MOVE AWAY FROM THE BOSS!"; banner.TextColor3 = GOLD; banner.Visible = true
	elseif st == "back" then
		banner.Text = "GO BACK AND FIGHT!"; banner.TextColor3 = Color3.fromHex("8dff5a"); banner.Visible = true
	else
		banner.Visible = false
	end
end
player:GetAttributeChangedSignal("BossTut"):Connect(bannerSync)
local function slowMo()
	local on = player:GetAttribute("BossTut") == "dodge"
	if on and not slowCC then
		local c = new("ColorCorrectionEffect", { Name = "TutSlowMo", Saturation = 0, Contrast = 0, Brightness = 0 }, Lighting)
		slowCC = c
		TweenService:Create(c, TweenInfo.new(0.4), { Saturation = -0.35, Contrast = 0.15, Brightness = -0.05 }):Play()
	elseif not on and slowCC then
		local c = slowCC :: ColorCorrectionEffect
		slowCC = nil
		local tw = TweenService:Create(c, TweenInfo.new(0.5), { Saturation = 0, Contrast = 0, Brightness = 0 })
		tw.Completed:Connect(function() c:Destroy() end)
		tw:Play()
	end
end
player:GetAttributeChangedSignal("BossTut"):Connect(slowMo)

-- 10.11.2026: крок "shop" — щойно відкрилось вікно BOSS SHOP (StallShopWindow), стрілки до магазину вже не потрібні
task.spawn(function()
	while true do
		task.wait(0.3)
		if player:GetAttribute("BossTut") == "shop" then
			local w = playerGui:FindFirstChild("StallShopWindow")
			local tl = w and findText(w, function(t) return t == "BOSS SHOP" end)
			if tl and visibleChain(tl) then
				hideChevrons(); setHandVisible(false)
				local ba = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("BossAction")
				if ba then ba:FireServer("TutShopSeen") end
				task.wait(1)
			end
		end
	end
end)
