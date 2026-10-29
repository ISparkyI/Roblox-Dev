--!nonstrict
-- SettingsWindow — вікно SETTINGS (кнопка-шестерня ліворуч угорі HUD) і застосування налаштувань на клієнті.
-- Де: StarterPlayer/StarterPlayerScripts/SettingsWindow (LocalScript). Сервер — ServerScriptService/SettingsService
--   (RemoteEvent Remotes/SettingsAction (ключ, значення) → атрибут гравця Set_<ключ>, зберігає DataService, префікс Set_).
-- Стиль і каркас вікна — як InfoWindows (980 × 528 зі studs, заголовок з іконкою −8°, червона X, Esc / клік поза вікном,
--   Shared/WindowManager "Settings", одне вікно на екрані). Рядки — темні картки з назвою й підписом; не влазить — прокрутка.
-- Налаштування:
--   MUSIC, SOUND EFFECTS — повзунки 0–100 % (SoundGroup MusicGroup / SfxGroup у SoundService, лише локально);
--   MUTATION AURAS — ефекти мутацій (MutationAuraClient читає Set_AurasLocal / Set_Auras);
--   HIDE OTHER PLAYERS — чужі персонажі невидимі лише в мене (LocalTransparencyModifier, без табличок і імен);
--   LOW GRAPHICS — без тіней і пост-ефектів Lighting (Bloom, SunRays, DepthOfField, Blur);
--   NAMETAG — випадаючий список тегів (MonetizationConfig.TAGS; спочатку NONE; VIP — геймпас VIP), SettingsService малює тег над головою.
--   AUTO EQUIP BEST — з геймпасом Pass_AutoEquip перемикач ON / OFF (Set_AutoEquip); без нього — GAMEPASS, клік відкриває SHOP.
-- Значення одразу застосовуються локально, сервер підтверджує атрибутом.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ICON = { -- іконки кнопок HUD (MainHUD, 2D/Main HUD)
	settings = "rbxassetid://111541402429276",
}

-- ===== розміри (як усі вікна) =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528

-- ===== кольори й шрифти =====
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local MUTED = C("9aa3ad")
local GOOD = C("7ef05a")
local BAD = C("ff5a5a")
local BADGE_RED = C("ff3b4f")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local SLOT_BG = { { 0, "22262c" }, { 1, "15181c" } }
local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right

-- ===== помічники (як у IndexUI / InventoryUI) =====
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function frame(parent, x, y, w, h, color, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or WHITE, BorderSizePixel = 0 }, parent)
	if props then for k, v in props do f[k] = v end end
	return f
end
local function corner(o, r) new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
local function stroke(o, color, th, tr, contextual)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0,
		LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function vgrad(o, keys) return new("UIGradient", { Color = cseq(keys), Rotation = 90 }, o) end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	return t
end
local function textAt(parent, x, cy, w, size, text, color, sw, props)
	return label(parent, x, cy - size * 0.6, w, size * 1.2, size, text, color, sw, props)
end
local function stud(parent, x, y, cell, fill, shade, edge, edgeTh)
	local s = cell * 0.62
	local o = (cell - s) / 2
	local d = s * 0.12
	local r = s * 0.16
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade, { ZIndex = 1 }); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill, { ZIndex = 2 }); corner(st, r)
	if edge then stroke(st, edge, edgeTh or 2) end
end
local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end
local function isPress(inp: InputObject): boolean
	return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end
local function cardBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.4) }) }, f)
	stroke(f, INK, 3)
	return f
end
-- темне поле (як слот інвентаря)
local function slotBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	vgrad(f, SLOT_BG); stroke(f, INK, 4)
	return f
end
-- вікно зі studs (як Forge / Inventory / Index). Повертає (window, вміст)
local function windowFrame(parent, x, y, w, h, z, shadowDy)
	frame(parent, x, y + shadowDy, w, h, BLACK, { Name = "WindowShadow", BackgroundTransparency = 0.65, ZIndex = z })
	local win = frame(parent, x, y, w, h, WHITE, { Name = "Window", ZIndex = z + 1 })
	vgrad(win, RIM); stroke(win, INK, 5)
	local rl = frame(win, 6, 6, w - 12, h - 12, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	stroke(rl, C("6a7078"), 1.5, 0.1)
	local pw, ph = w - 36, h - 36
	local panel = frame(win, 18, 18, pw, ph, C("a9aeb5"), { Name = "Panel", ZIndex = 2, ClipsDescendants = true })
	stroke(panel, INK, 4)
	local studs = frame(panel, 0, 0, pw, ph, nil, { Name = "Studs", BackgroundTransparency = 1, ZIndex = 1 })
	local CELL = 40
	local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
	local ox, oy = (pw - nx * CELL) / 2, (ph - ny * CELL) / 2
	for cx = 0, nx - 1 do
		for cy = 0, ny - 1 do stud(studs, ox + cx * CELL, oy + cy * CELL, CELL, C("b3b8bf"), C("868b92"), C("c8ccd1"), 1) end
	end
	local shade = frame(panel, 0, 0, pw, ph, WHITE, { Name = "Shade", ZIndex = 2 })
	new("UIGradient", { Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE), ColorSequenceKeypoint.new(1, WHITE) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1), NumberSequenceKeypoint.new(1, 0.82) }) }, shade)
	local content = frame(win, 0, 0, w, h, nil, { Name = "Content", BackgroundTransparency = 1, ZIndex = 3 })
	return win, content
end

-- звук відмови (сіра / недоступна дія)
local function denySound()
	if StyleA.deny then StyleA.deny() else UISounds.play("deny", 0.08) end
end
-- кнопка-група «стиль A» (як у IndexUI): тінь, основа, напис в одному Frame — масштабуються й хитаються разом
local function shakeGroup(grp: GuiObject)
	denySound()
	if grp:GetAttribute("Shaking") then return end
	grp:SetAttribute("Shaking", true)
	local p0 = grp.Position
	task.spawn(function()
		for _, dx in { -10, 10, -7, 7, -3, 0 } do grp.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		grp.Position = p0
		grp:SetAttribute("Shaking", nil)
	end)
end
local function makeGroupButton(parent, x, y, w, h, opt)
	local grp = new("Frame", { Name = opt.name or "Group", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x + w / 2, y + h / 2), Size = UDim2.fromOffset(w, h), ZIndex = opt.z or 1 }, parent)
	local gs = new("UIScale", {}, grp)
	frame(grp, 0, opt.shadowDy, w, h, BLACK, { Name = "Shadow", BackgroundTransparency = 0.7, ZIndex = 1 })
	local b = StyleA.new(grp, { size = Vector2.new(w, h), position = Vector2.new(0, 0), color = opt.color, clickable = true,
		shine = opt.shine, zIndex = 2, icon = opt.icon, iconPad = opt.iconPad, text = opt.text, textSize = opt.textSize })
	b.root.Name = "Button"
	b.scale = gs
	b.group = grp
	b.onClick = nil
	StyleA.bind(b, { debounce = 0.15, hoverAlways = true, tap = opt.tap, canClick = function() return true end, onClick = function()
		if b.enabled == false then shakeGroup(grp) elseif b.onClick then b.onClick(b) end
	end })
	return b
end
local function makeBadge(parent, z, sz)
	local f = frame(parent, 0, 0, sz, sz, INK, { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Visible = false })
	corner(f, UDim.new(0.5, 0))
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = BADGE_RED, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -4, 1, -4), ZIndex = z }, f)
	corner(fill, UDim.new(0.5, 0))
	local t = label(fill, 0, 0, sz, sz, math.floor(sz * 0.6 + 0.5), "", WHITE, 1.4, { Size = UDim2.fromScale(1, 1), ZIndex = z + 1 })
	return { f = f, t = t, sz = sz }
end
local function setBadge(b, n: number)
	if not b then return end
	b.f.Visible = n > 0
	if n <= 0 then return end
	local s = n > 9 and "9+" or tostring(n)
	b.t.Text = s
	b.f.Size = UDim2.fromOffset(math.max(b.sz, math.floor(b.sz * 0.46 + #s * b.sz * 0.35)), b.sz)
end

local Action = nil
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 60)
	Action = r and r:WaitForChild("BackendAction", 60)
end)
local function invoke(action: string, arg: any): any
	local t0 = os.clock()
	while not Action and os.clock() - t0 < 5 do task.wait(0.1) end
	if not Action then return nil end
	local ok, res = pcall(Action.InvokeServer, Action, action, arg)
	if ok then return res end
	return nil
end

local uiEvents = RS:WaitForChild("UIEvents", 30)
local hudEvent = uiEvents and uiEvents:WaitForChild("HUDButton", 30)

-- =====================================================================
-- ===== вікно: рамка, заголовок з іконкою, X, відкриття / закриття =====
-- =====================================================================
-- spec: key (WindowManager / HUDButton), gui, title, icon, palette (4 кольори переливу)
local function makeWindow(spec)
	local W = { isOpen = false }
	local gui = new("ScreenGui", { Name = spec.gui, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10, Enabled = true }, playerGui)
	local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
		Active = true, Visible = false, ZIndex = 1 }, gui)
	local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
	local fitScale = new("UIScale", {}, modalRoot)
	local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
	local popScale = new("UIScale", {}, pop)
	local _, content = windowFrame(pop, WX, WY, WW, WH, 1, 14)
	W.gui, W.content, W.modalRoot = gui, content, modalRoot

	-- заголовок: іконка кнопки HUD (≈ 2 × висоти літер, нахил −8°) + текст з переливом і відблиском; обводка й тіні — чорні
	local TITLE_ICON = 132
	local TI_CX, TI_CY = WX + 26 + TITLE_ICON / 2, WY - 6
	new("ImageLabel", { Name = "TitleIconShadow", BackgroundTransparency = 1, Image = spec.icon, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TI_CX, TI_CY + 7), Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON), Rotation = -8, ZIndex = 3 }, pop)
	new("ImageLabel", { Name = "TitleIcon", BackgroundTransparency = 1, Image = spec.icon, ScaleType = Enum.ScaleType.Fit, Rotation = -8,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TI_CX, TI_CY), Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON), ZIndex = 4 }, pop)
	local TITLE_X = WX + 26 + TITLE_ICON + 2
	textAt(pop, TITLE_X, WY - 8 + 7, 600, 96, spec.title, INK, 9, { TextXAlignment = LEFT, ZIndex = 3 })
	local title = textAt(pop, TITLE_X, WY - 8, 600, 96, spec.title, WHITE, 8, { TextXAlignment = LEFT, ZIndex = 4 })
	local titleGrad = new("UIGradient", { Rotation = 0 }, title)
	local titleShine = textAt(pop, TITLE_X, WY - 8, 600, 96, spec.title, WHITE, 0, { TextXAlignment = LEFT, ZIndex = 5 })
	local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
			NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
			NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
	do
		local P = {}
		for _, h in spec.palette do table.insert(P, C(h)) end
		local function sample(u)
			local x = (u % 1) * #P
			local i = math.floor(x)
			local t = x - i
			t = t * t * (3 - 2 * t)
			return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
		end
		RunService.Heartbeat:Connect(function()
			if not modalRoot.Visible then return end
			local phase = -(os.clock() / 4)
			local ks = {}
			for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end
			titleGrad.Color = ColorSequence.new(ks)
		end)
		local tw = TweenService:Create(titleShineGrad, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
		tw.Completed:Connect(function() titleShineGrad.Offset = Vector2.new(-1.3, 0) end)
		task.spawn(function() while true do task.wait(3 + math.random() * 3); if modalRoot.Visible then tw:Play() end end end)
	end
	local closeBtn = makeGroupButton(pop, WX + WW - 70, WY - 34, 84, 84, { name = "Close", shadowDy = 8, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

	local function fit()
		WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WX, winY = WY, winW = WW, winH = WH })
	end
	local camConn
	local function bindCamera()
		if camConn then camConn:Disconnect(); camConn = nil end
		local cam = workspace.CurrentCamera
		if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
		fit()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
	pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fit) end)
	bindCamera()

	local animToken = 0
	local hotbarOrder = nil
	local escName = spec.key .. "Esc"
	local function escKey(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
		task.defer(function() if W.isOpen then W.close() end end)
		return Enum.ContextActionResult.Sink
	end
	function W.open()
		if W.isOpen then return end
		W.isOpen = true
		WindowManager.opened(spec.key) -- одне вікно на екрані: інші закриваються
		animToken += 1
		local my = animToken
		-- хотбар лишається видно над затемненням (як у INVENTORY / INDEX)
		local hb = playerGui:FindFirstChild("Hotbar")
		if hb and hb:IsA("ScreenGui") then
			hotbarOrder = hb.DisplayOrder < 11 and hb.DisplayOrder or 5
			hb.DisplayOrder = 11
			task.delay(0.2, function() if W.isOpen and animToken == my then hb.DisplayOrder = 11 end end)
		end
		fit()
		if W.onOpen then W.onOpen() end
		backdrop.Visible = true; modalRoot.Visible = true
		backdrop.BackgroundTransparency = 1
		popScale.Scale = 0.85
		tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
		tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
			if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
		end)
		CAS:BindActionAtPriority(escName, escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
	end
	function W.close()
		if not W.isOpen then return end
		W.isOpen = false
		pcall(function() CAS:UnbindAction(escName) end)
		if W.onClose then W.onClose() end
		animToken += 1
		local my = animToken
		tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
		tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
			if animToken ~= my then return end
			backdrop.Visible = false; modalRoot.Visible = false
			local hb = playerGui:FindFirstChild("Hotbar")
			-- інше вікно (Inventory / Index…), що вже відкрилось, саме тримає хотбар нагорі — порядок не чіпаємо
			local other = false
			for _, n in { "InventoryWindow", "IndexWindow", "FeedbackWindow", "CodesWindow", "UpdatesWindow", "SettingsWindow", "QuestsWindow", "RebirthWindow", "ShopWindow" } do
				local g = playerGui:FindFirstChild(n)
				local mr = g and g:FindFirstChild("ModalRoot")
				if g ~= gui and mr and mr.Visible then other = true end
			end
			if hb and hotbarOrder and not other then hb.DisplayOrder = hotbarOrder end
			hotbarOrder = nil
		end)
	end
	closeBtn.onClick = function() W.close() end
	WindowManager.register(spec.key, function() return W.isOpen end, function() W.close() end)
	local function inside(o: GuiObject, p: Vector2, top: number?): boolean
		local a, s = o.AbsolutePosition, o.AbsoluteSize
		return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y - (top or 0) and p.Y <= a.Y + s.Y
	end
	backdrop.InputBegan:Connect(function(inp)
		if not isPress(inp) then return end
		-- закриває лише клік ПОЗА вікном (заголовок і X над рамкою — теж вікно); без GetGuiInset: inp.Position і AbsolutePosition в одному просторі
		local p = Vector2.new(inp.Position.X, inp.Position.Y)
		if inside(content, p, content.AbsoluteSize.Y * 0.18) then return end
		W.close()
	end)
	if hudEvent then
		hudEvent.Event:Connect(function(key) if key == spec.key then if W.isOpen then W.close() else W.open() end end end)
	end
	return W
end
-- =====================================================================
-- ===== налаштування: значення, застосування =====
-- =====================================================================
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local DEF = { Music = 100, Sfx = 100, HidePlayers = false, Auras = true, LowGfx = false, AutoEquip = true, AutoRoll = true, AutoBuy = true, FastRoll = true, AutoCollect = true, RollMuts = 0, RollRars = 0, RollMinDmg = 0, Tag = "" }
local pending = {} -- локальні значення, ще не підтверджені сервером
local function val(k: string): any
	if pending[k] ~= nil then return pending[k] end
	local v = player:GetAttribute("Set_" .. k)
	if v == nil then return DEF[k] end
	return v
end

-- звук: дві групи (локально) — музика й решта звуків
local function group(name: string): SoundGroup
	local g = SoundService:FindFirstChild(name)
	if not (g and g:IsA("SoundGroup")) then
		g = Instance.new("SoundGroup"); g.Name = name; g.Volume = 1; g.Parent = SoundService
	end
	return g :: SoundGroup
end
local musicG, sfxG = group("MusicGroup"), group("SfxGroup")
local function tagSound(s: Instance)
	if not s:IsA("Sound") then return end
	if s.Name == "BackgroundMusic" then s.SoundGroup = musicG elseif s.SoundGroup == nil then s.SoundGroup = sfxG end
end
for _, root in { SoundService, RS, workspace } do
	for _, d in root:GetDescendants() do tagSound(d) end
	root.DescendantAdded:Connect(tagSound)
end
local function applySound()
	musicG.Volume = math.clamp(val("Music") / 100, 0, 1)
	sfxG.Volume = math.clamp(val("Sfx") / 100, 0, 1)
end

-- сховати інших гравців (лише в мене на екрані)
local hideConns: { [Player]: { RBXScriptConnection } } = {}
local function hideChar(ch: Model?, on: boolean)
	if not ch then return end
	for _, d in ch:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = on and 1 or 0
		elseif d:IsA("BillboardGui") then d.Enabled = not on end
	end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = on and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer end
end
local function watchPlayer(p: Player)
	if p == player then return end
	local list = {}
	local function onChar(ch: Model)
		hideChar(ch, val("HidePlayers"))
		table.insert(list, ch.DescendantAdded:Connect(function(d)
			if not val("HidePlayers") then return end
			if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 1 elseif d:IsA("BillboardGui") then d.Enabled = false end
		end))
	end
	if p.Character then onChar(p.Character) end
	table.insert(list, p.CharacterAdded:Connect(onChar))
	hideConns[p] = list
end
for _, p in Players:GetPlayers() do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(p)
	for _, c in hideConns[p] or {} do c:Disconnect() end
	hideConns[p] = nil
end)
local function applyHide()
	local on = val("HidePlayers")
	for _, p in Players:GetPlayers() do if p ~= player then hideChar(p.Character, on) end end
end

-- низька графіка: без тіней і пост-ефектів (Bloom, SunRays, DepthOfField, Blur)
local gfxSaved = nil
local function applyGfx()
	local low = val("LowGfx")
	if low and not gfxSaved then
		gfxSaved = { shadows = Lighting.GlobalShadows, fx = {} }
		Lighting.GlobalShadows = false
		for _, e in Lighting:GetChildren() do
			if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("BlurEffect") then
				gfxSaved.fx[e] = e.Enabled; e.Enabled = false
			end
		end
	elseif not low and gfxSaved then
		Lighting.GlobalShadows = gfxSaved.shadows
		for e, en in gfxSaved.fx do if e.Parent then e.Enabled = en end end
		gfxSaved = nil
	end
end
-- ауры мутацій вмикає / вимикає MutationAuraClient за атрибутом гравця (локальна копія — для миттєвого відгуку)
local function applyAuras() player:SetAttribute("Set_AurasLocal", val("Auras")) end

local function applyAll() applySound(); applyHide(); applyGfx(); applyAuras() end
applyAll()
for k in DEF do
	player:GetAttributeChangedSignal("Set_" .. k):Connect(function()
		if pending[k] ~= nil and pending[k] == player:GetAttribute("Set_" .. k) then pending[k] = nil end
		applyAll()
	end)
end

local SetRemote = nil
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 60)
	SetRemote = r and r:WaitForChild("SettingsAction", 60)
end)
local function send(k: string, v: any)
	pending[k] = v
	applyAll()
	if SetRemote then SetRemote:FireServer(k, v) end
end

-- =====================================================================
-- ===== вікно SETTINGS =====
-- =====================================================================
local win = makeWindow({ key = "Settings", gui = "SettingsWindow", title = "SETTINGS", icon = ICON.settings, palette = { "ffffff", "c9d6e3", "8d9bab", "c9d6e3" } })
local LX, LY, LW, LH = 36, 66, 908, 436
local list = new("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(LX, LY), Size = UDim2.fromOffset(LW, LH), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C("2a2e35"), ScrollBarImageTransparency = 0.1, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 4 }, win.content)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 18) }, list)
local CW = LW - 26
local ROW_H = 60
local refreshers = {}

local function row(order: number, title: string, sub: string): Frame
	local r = new("Frame", { Name = "Row_" .. title, Size = UDim2.fromOffset(CW, ROW_H), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 4 }, list)
	cardBg(r, 0, 0, CW, ROW_H, 4)
	textAt(r, 20, 21, 460, 26, title, WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 5 })
	textAt(r, 20, 44, 520, 15, sub, SUB_TXT, 1.4, { TextXAlignment = LEFT, FontFace = BOLD, ZIndex = 5 })
	return r
end

-- перемикач ON / OFF (кнопка «стиль A»)
local TG_W, TG_H = 150, 44
local function toggleRow(order: number, key: string, title: string, sub: string)
	local r = row(order, title, sub)
	local b = makeGroupButton(r, CW - TG_W - 16, (ROW_H - TG_H) / 2 - 2, TG_W, TG_H, { name = "Toggle", shadowDy = 5, color = "green", text = "ON", textSize = 24, z = 5 })
	local function refresh()
		local on = val(key)
		b:setColor(on and "green" or "red")
		b:setText(on and "ON" or "OFF")
	end
	b.onClick = function() send(key, not val(key)); refresh() end
	refresh()
	refreshers[key] = refresh
end

-- повзунок 0–100 % (затиск і перетягування; клік по смузі — одразу туди)
local function sliderRow(order: number, key: string, title: string, sub: string)
	local r = row(order, title, sub)
	local TW, TH = 300, 22
	local tx = CW - 16 - 110 - TW
	local ty = (ROW_H - TH) / 2
	local track = frame(r, tx, ty, TW, TH, WHITE, { Name = "Track", ZIndex = 5, Active = true })
	vgrad(track, SLOT_BG); stroke(track, INK, 3)
	local fill = frame(track, 0, 0, TW, TH, WHITE, { Name = "Fill", ZIndex = 6 })
	vgrad(fill, { { 0, "a6ff7a" }, { 0.5, "6fe04a" }, { 1, "3fae2a" } })
	local KW, KH = 26, 38
	local knob = frame(r, tx, ty + TH / 2 - KH / 2, KW, KH, WHITE, { Name = "Knob", ZIndex = 7, Active = true })
	vgrad(knob, { { 0, "ffffff" }, { 1, "c9ced5" } }); stroke(knob, INK, 3)
	frame(knob, KW / 2 - 1.5, 9, 3, KH - 18, C("8d939b"), { ZIndex = 8 })
	local valLbl = textAt(r, CW - 16 - 84, ROW_H / 2, 84, 26, "100%", WHITE, 2.6, { ZIndex = 5 })
	local function show(v: number)
		local k = v / 100
		fill.Size = UDim2.fromOffset(math.max(0, TW * k), TH)
		fill.Visible = v > 0
		knob.Position = UDim2.fromOffset(tx + TW * k - KW / 2, ty + TH / 2 - KH / 2)
		valLbl.Text = string.format("%d%%", v)
	end
	local dragging = false
	local cur = val(key)
	local function fromX(px: number): number
		local a, s = track.AbsolutePosition.X, track.AbsoluteSize.X
		if s <= 0 then return cur end
		return math.clamp(math.floor((px - a) / s * 100 + 0.5), 0, 100)
	end
	local function setLocal(v: number)
		if v == cur then return end
		cur = v
		pending[key] = v
		show(v); applySound()
	end
	local function begin(inp: InputObject)
		if not isPress(inp) then return end
		dragging = true
		setLocal(fromX(inp.Position.X))
	end
	track.InputBegan:Connect(begin)
	knob.InputBegan:Connect(begin)
	UIS.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			setLocal(fromX(inp.Position.X))
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if dragging and isPress(inp) then
			dragging = false
			UISounds.play("tap", 0.05)
			send(key, cur)
		end
	end)
	refreshers[key] = function() if not dragging then cur = val(key); show(cur) end end
	show(cur)
end

-- геймпас-перемикач (поки замкнений: геймпаса ще немає)
local function lockedRow(order: number, title: string, sub: string)
	local r = row(order, title, sub)
	local b = makeGroupButton(r, CW - TG_W - 16, (ROW_H - TG_H) / 2 - 2, TG_W, TG_H, { name = "Locked", shadowDy = 5, color = "gray", text = "GAMEPASS", textSize = 18, z = 5 })
	b.enabled = false
end

sliderRow(1, "Music", "MUSIC", "Background music volume")
sliderRow(2, "Sfx", "SOUND EFFECTS", "Buttons, mining, workshop and other sounds")
toggleRow(3, "Auras", "MUTATION AURAS", "Glow and particles around mutated golems")
toggleRow(4, "HidePlayers", "HIDE OTHER PLAYERS", "Other players become invisible (only for you)")
toggleRow(5, "LowGfx", "LOW GRAPHICS", "No shadows and post effects for better FPS")
-- кнопка перемикача без геймпаса (v2, 28.10.2026): зелена з ціною геймпаса (іконка Robux + число, як у SHOP);
-- клік — одразу вікно покупки Roblox (PromptGamePassPurchase; видає MonetizationService). id = 0 (ще не створено в Creator Hub) — кнопка хитається.
local MonCfgP = require(Shared:WaitForChild("MonetizationConfig"))
local function passPrice(b, key: string)
	local def = MonCfgP.Passes[key]
	local row = new("Frame", { Name = "PriceRow", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -1),
		Size = UDim2.fromOffset(0, TG_H), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 8, Visible = false }, b.group)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder }, row)
	new("ImageLabel", { Name = "Robux", BackgroundTransparency = 1, Image = "rbxassetid://139687766069559", ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(22, 22), LayoutOrder = 1, ZIndex = 8 }, row)
	local t = new("TextLabel", { Name = "Price", BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 22, TextColor3 = WHITE,
		Text = tostring(def and def.robux or 0), Size = UDim2.fromOffset(0, TG_H), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, ZIndex = 9 }, row)
	new("UIStroke", { Color = INK, Thickness = 2.4 }, t)
	local P = {}
	function P.show(on: boolean)
		row.Visible = on
		if on then b:setColor("green"); b:setText("") end
	end
	function P.buy()
		-- лише вікно оплати Roblox (у SHOP не перекидаємо); id = 0 — геймпас ще не створено в Creator Hub: кнопка хитається
		if def and (def.id or 0) > 0 then
			pcall(function() game:GetService("MarketplaceService"):PromptGamePassPurchase(player, def.id) end)
		else
			shakeGroup(b.group)
			if RunService:IsStudio() then warn("SettingsWindow: геймпас " .. key .. " ще без id (MonetizationConfig.Passes) — вікно оплати відкриється, коли його створять") end
		end
	end
	return P
end

-- AUTO EQUIP BEST: з геймпасом (Pass_AutoEquip) — ON / OFF; без нього — сіра GAMEPASS, клік відкриває SHOP
do
	local r = row(6, "AUTO EQUIP BEST", "Best golems go to your plots automatically")
	local b = makeGroupButton(r, CW - TG_W - 16, (ROW_H - TG_H) / 2 - 2, TG_W, TG_H, { name = "Toggle", shadowDy = 5, color = "green", text = "", textSize = 24, z = 5 })
	local pp = passPrice(b, "AutoEquip")
	local function refresh()
		if player:GetAttribute("Pass_AutoEquip") ~= true then pp.show(true); return end
		pp.show(false)
		local on = val("AutoEquip")
		b:setColor(on and "green" or "red"); b:setText(on and "ON" or "OFF")
	end
	b.onClick = function()
		if player:GetAttribute("Pass_AutoEquip") ~= true then pp.buy(); return end
		send("AutoEquip", not val("AutoEquip")); refresh()
	end
	refresh()
	refreshers.AutoEquip = refresh
	player:GetAttributeChangedSignal("Pass_AutoEquip"):Connect(refresh)
end
-- AUTO COLLECT / FAST ROLL: з геймпасом — ON / OFF (Set_AutoCollect / Set_FastRoll); без нього — ціна, клік відкриває покупку
local function passToggle(order: number, key: string, title: string, sub: string)
	local r = row(order, title, sub)
	local b = makeGroupButton(r, CW - TG_W - 16, (ROW_H - TG_H) / 2 - 2, TG_W, TG_H, { name = "Toggle", shadowDy = 5, color = "green", text = "", textSize = 24, z = 5 })
	local pp = passPrice(b, key)
	local function refresh()
		if player:GetAttribute("Pass_" .. key) ~= true then pp.show(true); return end
		pp.show(false)
		local on = val(key)
		b:setColor(on and "green" or "red"); b:setText(on and "ON" or "OFF")
	end
	b.onClick = function()
		if player:GetAttribute("Pass_" .. key) ~= true then pp.buy(); return end
		send(key, not val(key)); refresh()
	end
	refresh()
	refreshers[key] = refresh
	player:GetAttributeChangedSignal("Pass_" .. key):Connect(refresh)
end
passToggle(7, "AutoCollect", "AUTO COLLECT", "Crates empty into your inventory by themselves")
passToggle(8, "FastRoll", "FAST ROLL", "Faster lever and rolls")
-- AUTO ROLL: з геймпасом (Pass_AutoRoll) — ON / OFF (Set_AutoRoll); без нього — сіра GAMEPASS, клік відкриває SHOP
do
	local r = row(9, "AUTO ROLL", "The roll lever pulls itself")
	local b = makeGroupButton(r, CW - TG_W - 16, (ROW_H - TG_H) / 2 - 2, TG_W, TG_H, { name = "Toggle", shadowDy = 5, color = "green", text = "", textSize = 24, z = 5 })
	local pp = passPrice(b, "AutoRoll")
	local function refresh()
		if player:GetAttribute("Pass_AutoRoll") ~= true then pp.show(true); return end
		pp.show(false)
		local on = val("AutoRoll")
		b:setColor(on and "green" or "red"); b:setText(on and "ON" or "OFF")
	end
	b.onClick = function()
		if player:GetAttribute("Pass_AutoRoll") ~= true then pp.buy(); return end
		send("AutoRoll", not val("AutoRoll")); refresh()
	end
	refresh()
	refreshers.AutoRoll = refresh
	player:GetAttributeChangedSignal("Pass_AutoRoll"):Connect(refresh)
end

-- ===== AUTO ROLL FILTER (v2, 28.10.2026): які результати ролу «потрібні» =====
-- Під фільтр = мутація вибрана І шкода голема (носій — місткість) >= MIN DAMAGE. Auto Roll на такому результаті зупиняється;
-- з геймпасом Auto Buy — купує його сам і крутить далі. Мутацій не вибрано — підходить будь-яка; і мутацій немає, і MIN DAMAGE = 0 — фільтр вимкнено.
-- Значення: Set_RollMuts (біти 1 << мутація), Set_RollMinDmg, Set_AutoBuy (SettingsService; читає RollService).
do
	local Catalog = require(Shared:WaitForChild("GolemCatalog"))
	local MutationText = require(Shared:WaitForChild("MutationText"))
	local NF = require(Shared:WaitForChild("NumberFormat"))
	-- заголовок розділу
	local hdr = new("Frame", { Name = "Hdr_AutoRoll", Size = UDim2.fromOffset(CW, 40), BackgroundTransparency = 1, LayoutOrder = 13, ZIndex = 4 }, list)
	textAt(hdr, 0, 24, CW, 26, "~ AUTO ROLL FILTER ~", WHITE, 2.8, { ZIndex = 5 })

	-- AUTO BUY: геймпас Pass_AutoBuy — ON / OFF; без нього — GAMEPASS → SHOP
	local r = row(14, "AUTO BUY", "Golems from your filter are bought automatically")
	local b = makeGroupButton(r, CW - TG_W - 16, (ROW_H - TG_H) / 2 - 2, TG_W, TG_H, { name = "Toggle", shadowDy = 5, color = "green", text = "", textSize = 24, z = 5 })
	local pp = passPrice(b, "AutoBuy")
	local function refreshBuy()
		if player:GetAttribute("Pass_AutoBuy") ~= true then pp.show(true); return end
		pp.show(false)
		local on = val("AutoBuy")
		b:setColor(on and "green" or "red"); b:setText(on and "ON" or "OFF")
	end
	b.onClick = function()
		if player:GetAttribute("Pass_AutoBuy") ~= true then pp.buy(); return end
		send("AutoBuy", not val("AutoBuy")); refreshBuy()
	end
	refreshBuy()
	refreshers.AutoBuy = refreshBuy
	player:GetAttributeChangedSignal("Pass_AutoBuy"):Connect(refreshBuy)

	-- MUTATIONS: 8 перемикачів (мутація кольором самої мутації), зелений — вибрана
	local MH = 116
	local mr = new("Frame", { Name = "Row_MUTATIONS", Size = UDim2.fromOffset(CW, MH), BackgroundTransparency = 1, LayoutOrder = 15, ZIndex = 4 }, list)
	cardBg(mr, 0, 0, CW, MH, 4)
	textAt(mr, 20, 21, 460, 26, "MUTATIONS", WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 5 })
	textAt(mr, 20, 44, CW - 40, 15, "Auto Roll stops on these (Auto Buy buys them). None selected — any mutation", SUB_TXT, 1.4, { TextXAlignment = LEFT, FontFace = BOLD, ZIndex = 5 })
	local n = #Catalog.MUTATIONS
	local GAPX = 10
	local chipW = math.floor((CW - 40 - (n - 1) * GAPX) / n)
	local chips = {}
	local function mask(): number return math.floor(tonumber(val("RollMuts")) or 0) end
	local function refreshChips()
		local mk = mask()
		for i, c in chips do c:setColor(bit32.band(mk, bit32.lshift(1, i - 1)) ~= 0 and "green" or "gray") end
	end
	for i, mu in Catalog.MUTATIONS do
		local c = makeGroupButton(mr, 20 + (i - 1) * (chipW + GAPX), 62, chipW, 38, { name = "Mut" .. (i - 1), shadowDy = 4, color = "gray", text = "", textSize = 16, z = 5 })
		local l = textAt(c.group, 0, 19, chipW, 17, string.upper(mu.key), WHITE, 2, { ZIndex = 9 })
		if i > 1 then MutationText.apply(l, i - 1) end
		c.onClick = function()
			send("RollMuts", bit32.bxor(mask(), bit32.lshift(1, i - 1))); refreshChips()
		end
		chips[i] = c
	end
	refreshChips()
	refreshers.RollMuts = refreshChips

	-- MIN DAMAGE: поле вводу (1500, 1.5K, 2M …); 0 — будь-яка
	-- RARITY: 8 перемикачів (без Exclusive — у ролі не випадає), назва кольором рідкості; нічого не вибрано — будь-яка
	local rr = new("Frame", { Name = "Row_RARITY", Size = UDim2.fromOffset(CW, MH), BackgroundTransparency = 1, LayoutOrder = 16, ZIndex = 4 }, list)
	cardBg(rr, 0, 0, CW, MH, 4)
	textAt(rr, 20, 21, 460, 26, "RARITY", WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 5 })
	textAt(rr, 20, 44, CW - 40, 15, "Only these rarities. None selected — any rarity", SUB_TXT, 1.4, { TextXAlignment = LEFT, FontFace = BOLD, ZIndex = 5 })
	local RARS = {}
	for _, r in Catalog.RARITIES do if r ~= "Exclusive" then table.insert(RARS, r) end end
	local rw = math.floor((CW - 40 - (#RARS - 1) * GAPX) / #RARS)
	local rchips = {}
	local function rmask(): number return math.floor(tonumber(val("RollRars")) or 0) end
	local function refreshRars()
		local mk = rmask()
		for i, c in rchips do c:setColor(bit32.band(mk, bit32.lshift(1, i - 1)) ~= 0 and "green" or "gray") end
	end
	for i, r in RARS do
		local c = makeGroupButton(rr, 20 + (i - 1) * (rw + GAPX), 62, rw, 38, { name = "Rar" .. i, shadowDy = 4, color = "gray", text = "", textSize = 16, z = 5 })
		textAt(c.group, 0, 19, rw, 16, string.upper(r), Catalog.rarityColor(r), 2, { ZIndex = 9 })
		c.onClick = function()
			send("RollRars", bit32.bxor(rmask(), bit32.lshift(1, i - 1))); refreshRars()
		end
		rchips[i] = c
	end
	refreshRars()
	refreshers.RollRars = refreshRars
	player:GetAttributeChangedSignal("Set_RollRars"):Connect(refreshRars)

	local dr = row(17, "MIN DAMAGE", "At least this damage (carriers: capacity). Nothing selected and 0 — filter off")
	local BW, BH = 220, 42
	local box = frame(dr, CW - BW - 16, (ROW_H - BH) / 2, BW, BH, WHITE, { Name = "Box", ZIndex = 5 })
	vgrad(box, SLOT_BG); stroke(box, INK, 3)
	local tb = new("TextBox", { Name = "Input", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), FontFace = XBOLD, TextSize = 22,
		TextColor3 = WHITE, PlaceholderText = "ANY", PlaceholderColor3 = MUTED, ClearTextOnFocus = false, Text = "", ZIndex = 6 }, box)
	local function show()
		local v = tonumber(val("RollMinDmg")) or 0
		tb.Text = v > 0 and NF.compact(v) or ""
	end
	local MULT = { k = 1e3, m = 1e6, b = 1e9, t = 1e12 }
	tb.FocusLost:Connect(function()
		local txt = string.lower((tb.Text:gsub("[%s,_$]", "")))
		local num, suf = string.match(txt, "^([%d%.]+)(%a?)$")
		local v = tonumber(num or "")
		if txt == "" then v = 0 elseif v and suf ~= "" then v = MULT[suf] and v * MULT[suf] or nil end
		if v then send("RollMinDmg", math.max(0, math.floor(v))) else UISounds.play("deny", 0.08) end
		show()
	end)
	show()
	refreshers.RollMinDmg = show
	player:GetAttributeChangedSignal("Set_RollMinDmg"):Connect(show)
	player:GetAttributeChangedSignal("Set_RollMuts"):Connect(refreshChips)
end

-- NAMETAG: кнопка з поточним тегом, клік — випадаючий список (NONE + теги; чужі — сірі з назвою геймпаса, клік відкриває SHOP)
do
	local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
	local r = row(20, "NAMETAG", "Tag above your head, everyone sees it")
	local DW = 200
	local b = makeGroupButton(r, CW - DW - 16, (ROW_H - TG_H) / 2 - 2, DW, TG_H, { name = "Dropdown", shadowDy = 5, color = "gray", text = "NONE  ▼", textSize = 18, z = 5 })
	local function cur(): string
		local k = val("Tag")
		if type(k) ~= "string" or k == "" or not MonCfg.ownsTag(player, k) then return "" end
		return k
	end
	local function refresh()
		local k = cur()
		b:setText((k == "" and "NONE" or k) .. "  ▼")
		b:setColor(k == "" and "gray" or "yellow")
	end
	local layer
	local function closeDrop() if layer then layer:Destroy(); layer = nil end end
	b.onClick = function()
		if layer then closeDrop(); return end
		local content = win.content
		local k = content.AbsoluteSize.X / math.max(1, content.Size.X.Offset)
		layer = frame(content, 0, 0, content.Size.X.Offset, content.Size.Y.Offset, nil, { Name = "TagDrop", BackgroundTransparency = 1, Active = true, ZIndex = 40 })
		local opts = { { key = "", text = "NONE" } }
		for _, t in MonCfg.TAGS do table.insert(opts, { key = t.key, text = t.text, t = t }) end
		local OH = 44
		local PH = #opts * (OH + 6) + 6
		local bx = (b.group.AbsolutePosition.X - content.AbsolutePosition.X) / k
		local by = (b.group.AbsolutePosition.Y - content.AbsolutePosition.Y) / k + TG_H + 8
		if by + PH > content.Size.Y.Offset - 24 then by -= TG_H + 16 + PH end -- унизу не влазить — відкриваємо вгору
		local panel = slotBg(layer, bx, by, DW, PH, 41)
		-- клік поза списком — закрити (клік по пункту обробляє сама кнопка)
		layer.InputBegan:Connect(function(inp)
			if not isPress(inp) then return end
			local a, sz = panel.AbsolutePosition, panel.AbsoluteSize
			local px, py = inp.Position.X, inp.Position.Y
			if px < a.X or px > a.X + sz.X or py < a.Y or py > a.Y + sz.Y then task.defer(closeDrop) end
		end)
		panel.Active = true
		for i, o in opts do
			local own = o.key == "" or MonCfg.ownsTag(player, o.key)
			local ob = makeGroupButton(panel, 6, 6 + (i - 1) * (OH + 6), DW - 12, OH, { name = "Opt_" .. (o.key == "" and "None" or o.key), shadowDy = 4,
				color = own and (cur() == o.key and "yellow" or "green") or "gray", text = own and o.text or (o.text .. " · PASS"), textSize = 18, z = 42 })
			ob.onClick = function()
				closeDrop()
				if not own then
					if hudEvent then task.defer(function() hudEvent:Fire("Shop") end) end
					return
				end
				send("Tag", o.key); refresh()
			end
		end
	end
	refresh()
	refreshers.Tag = refresh
	player.AttributeChanged:Connect(function(a) if string.sub(a, 1, 5) == "Pass_" then refresh() end end)
	local oldClose = win.onClose
	win.onClose = function() closeDrop(); if oldClose then oldClose() end end
end

local function refreshAll() for _, f in refreshers do f() end end
win.onOpen = refreshAll
for k in DEF do player:GetAttributeChangedSignal("Set_" .. k):Connect(function() if win.isOpen then local f = refreshers[k]; if f then f() end end end) end
