--!nonstrict
-- InfoWindows — вікна FEEDBACK, CODES і UPDATES (кнопки праворуч угорі HUD). Інтерфейс будується кодом (ScreenGui FeedbackWindow,
--   CodesWindow, UpdatesWindow). Де: StarterPlayer/StarterPlayerScripts/InfoWindows (LocalScript). Нотатка — 2D/Feedback Codes Updates.
-- Стиль — як Inventory / Index: вікно 980 × 528 зі studs (полотно 1080 × 640, Shared/WindowFit), великий заголовок з іконкою HUD зліва
--   (≈ 2 × висоти літер, нахил −8°, чорні обводка й тінь, перелив кольору кнопки HUD: Feedback — рожевий, Codes — жовтий, Updates — синій),
--   кнопки «стиль A», червона X, поява 0,85 → 1,05 → 1. Закриття — X, Esc, клік поза вікном (без GetGuiInset). Не влазить — прокрутка.
-- Одне вікно на екрані — Shared/WindowManager ("Feedback", "Codes", "Updates"). Хотбар лишається над затемненням.
-- Відкриття: MainHUD → ReplicatedStorage/UIEvents/HUDButton "Feedback" / "Codes" / "Updates" (повторне натискання — закрити).
-- Сервер — ServerScriptService/BackendService (RemoteFunction Remotes/BackendAction: GetUpdates, SeenUpdates, Redeem, SendFeedback).
--   UPDATES (v3): ліворуч — стовпчик вкладок-версій (кнопки «стиль A», вибрана синя й зсунута, нові зверху, гортається; закріплена —
--     мітка PIN; не переглянута — червона крапка). Праворуч — усі рядки таблиці вибраної версії: картки на всю область з прокруткою,
--     версія й дата дрібно, заголовок кольором titleColor, текст RichText ([#rrggbb]слова[/] → колір, **жирний**; <, >, & з таблиці
--     екрануються; textColor — колір усього тексту), велика картинка під текстом. За замовчуванням відкрита найновіша версія.
--     Відкрили версію — її id у UpdatesSeen (SeenUpdates): крапка зникає; червоний лічильник на кнопці HUD — кількість непереглянутих версій. Без таблиці — запасний список сервера (стан бекенду гравцю не показуємо).
--   CODES: поле (UPPERCASE), кнопка REDEEM (Enter теж), результат під полем: зелений «+50 Diamonds!» / червоний «Invalid code»,
--     «Already used», «Expired», «Code limit reached», «Codes are offline», «Inventory full». Звуки claim / deny.
--   FEEDBACK: категорії Bug / Idea / Other (перемикачі), поле на 500 символів (лічильник), SEND; «Thanks! Sent.» / «Wait 1:43» /
--     «Can't send right now». Пристрій (Touch / Gamepad / Keyboard) — з клієнта.
--     Допуск (перевіряє сервер BackendService; тут лише показ за атрибутами FeedbackBlock / FeedbackReadyAt): < 5 хв у грі —
--     сіра SEND (deny) і «You can send feedback after 5 minutes in game» + «Available in 3:12»; акаунт < 3 днів —
--     «Your account must be at least 3 days old».

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
local Loc = require(Shared:WaitForChild("Loc")) -- переклад текстів апдейт-логу: точний рядок з таблиці Updates → Source у хмарній таблиці локалізації
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ICON = { -- іконки кнопок HUD (MainHUD, 2D/Main HUD)
	feedback = "rbxassetid://84284099600077", codes = "rbxassetid://116306459544574", updates = "rbxassetid://133326399418460",
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
	StyleA.studTile(studs, ox, oy, nx * CELL, ny * CELL, CELL, C("b3b8bf")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
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
			for _, n in { "InventoryWindow", "IndexWindow", "FeedbackWindow", "CodesWindow", "UpdatesWindow" } do
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

local function fmtWait(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end
local function setStatus(lbl: TextLabel, text: string, color: Color3)
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.TextTransparency = 1
	local s = lbl:FindFirstChildOfClass("UIStroke")
	if s then s.Transparency = 1; tween(s, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0 }) end
	tween(lbl, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextTransparency = 0 })
	local sc = lbl:FindFirstChildOfClass("UIScale") or new("UIScale", {}, lbl)
	sc.Scale = 0.8
	tween(sc, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
end

-- =====================================================================
-- ===== UPDATES =====
-- =====================================================================
local upd = makeWindow({ key = "Updates", gui = "UpdatesWindow", title = "UPDATES", icon = ICON.updates, palette = { "e6f6ff", "7fd0ff", "1c7fd8", "7fd0ff" } })
-- ліворуч — стовпчик вкладок-версій (як класи в Index: кнопки «стиль A», вибрана синя й зсунута праворуч; гортається),
-- праворуч — новини вибраної версії (картки на всю ширину області, прокрутка; картинка велика, під текстом)
local VX, VY, VW, VH = 30, 62, 256, 440   -- область вкладок (у межах панелі)
local TAB_W, TAB_H, TAB_G = 222, 72, 12
local NX, NY, NW, NH = 296, 62, 650, 440  -- область новин
local verList = new("ScrollingFrame", { Name = "Versions", Position = UDim2.fromOffset(VX, VY), Size = UDim2.fromOffset(VW, VH), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C("2a2e35"), CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 4 }, upd.content)
local updList = new("ScrollingFrame", { Name = "News", Position = UDim2.fromOffset(NX, NY), Size = UDim2.fromOffset(NW, NH), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C("2a2e35"), ScrollBarImageTransparency = 0.1, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 4 }, upd.content)
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, updList)
new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 16) }, updList)
local updLoading = textAt(upd.content, 0, 280, WW, 24, "Loading…", WHITE, 2.6, { ZIndex = 5 })

local updates = {}       -- останній список з сервера
local groups = {}        -- версії: { key, version, date, pinned, list = { рядки } } — нові зверху
local selVer = nil       -- ключ вибраної версії
local seenSet = {}       -- id → true (атрибут UpdatesSeen)
local function readSeen()
	table.clear(seenSet)
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("UpdatesSeen") or "[]")
	if ok and type(list) == "table" then for _, id in list do seenSet[tostring(id)] = true end end
end

-- текст з таблиці → RichText: екрануємо &, <, >; [#rrggbb]…[/] → колір; **…** → жирний
local function richText(s: string): string
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, "%[#(%x%x%x%x%x%x)%](.-)%[/%]", '<font color="#%1">%2</font>')
	s = string.gsub(s, "%*%*(.-)%*%*", "<b>%1</b>")
	return s
end
local function hexColor(s: string, default: Color3): Color3
	local h = string.match(s or "", "^#?(%x%x%x%x%x%x)$")
	return h and C(h) or default
end
local function imageId(s: string): string
	if not s or s == "" then return "" end
	if string.find(s, "^rbxassetid://%d+$") or string.find(s, "^rbxthumb://") then return s end
	local n = string.match(s, "(%d+)")
	return n and ("rbxassetid://" .. n) or ""
end

-- версії: рядки таблиці з однаковою версією — одна вкладка. Порядок: новіша дата вище, далі більший номер версії
local function verNums(v: string): { number }
	local t = {}
	for n in string.gmatch(v, "%d+") do table.insert(t, tonumber(n)) end
	return t
end
local function newerVer(a, b): boolean
	if a.date ~= b.date then return a.date > b.date end
	local x, y = verNums(a.version), verNums(b.version)
	for i = 1, math.max(#x, #y) do
		local p, q = x[i] or 0, y[i] or 0
		if p ~= q then return p > q end
	end
	return a.first < b.first
end
-- підпис версії: у таблиці «0.3» → «v0.3» (текст на кшталт «Beta» — як є)
local function vLabel(v: string): string
	return string.match(v, "^%d") and ("v" .. v) or v
end
local function buildGroups()
	local byKey = {}
	groups = {}
	for i, u in updates do
		local key = u.version ~= "" and u.version or ("#" .. u.id)
		local g = byKey[key]
		if not g then
			g = { key = key, version = u.version ~= "" and vLabel(u.version) or "News", date = u.date or "", pinned = false, list = {}, first = i }
			byKey[key] = g
			table.insert(groups, g)
		end
		table.insert(g.list, u)
		if u.pinned then g.pinned = true end
		if (u.date or "") > g.date then g.date = u.date end
	end
	table.sort(groups, newerVer)
end
local function groupUnseen(g): boolean
	for _, u in g.list do if not seenSet[u.id] then return true end end
	return false
end

local hudBadge = nil
-- лічильник на кнопці HUD — скільки версій ще не відкривали
local function unseenCount(): number
	local n = 0
	for _, g in groups do if groupUnseen(g) then n += 1 end end
	return n
end
local function updateHudBadge() setBadge(hudBadge, unseenCount()) end

-- мітка без UIStroke (UIStroke Miter на заокругленому Frame малює чорний квадрат): темна підкладка + кольорова
-- плашка всередині, обидва шари з однаковими заокругленнями (як бейджі Index)
local function chip(parent, text: string, color: Color3, order: number)
	local ch = new("Frame", { Name = "Chip", LayoutOrder = order, BackgroundColor3 = INK, BorderSizePixel = 0, Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X, ZIndex = 5 }, parent)
	corner(ch, 7)
	new("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, ch)
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X, ZIndex = 6 }, ch)
	corner(fill, 5)
	new("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, fill)
	label(fill, 0, 0, 0, 20, 14, text, WHITE, 1.6, { AutomaticSize = Enum.AutomaticSize.X, ZIndex = 7 })
	return ch
end
-- червона крапка «не переглянуто» (два кола без UIStroke, як бейджі)
local function makeDot(parent, x, y, z)
	local f = frame(parent, x, y, 20, 20, INK, { Name = "NewDot", AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Visible = false })
	corner(f, UDim.new(0.5, 0))
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = BADGE_RED, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -5, 1, -5), ZIndex = z }, f)
	corner(fill, UDim.new(0.5, 0))
	return f
end

-- ===== вкладки версій =====
local tabs = {} -- key → { hold, b, dot, i }
local selectVersion -- нижче
local function tabY(i: number) return 4 + (i - 1) * (TAB_H + TAB_G) end
local function paintTabs(animate: boolean)
	for _, t in tabs do
		local on = t.key == selVer
		t.b:setColor(on and "blue" or "gray")
		local pos = UDim2.fromOffset(on and 14 or 4, tabY(t.i))
		if animate then tween(t.hold, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = pos }) else t.hold.Position = pos end
		t.dot.Visible = groupUnseen(t.g)
	end
end
local function buildTabs()
	for _, c in verList:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	table.clear(tabs)
	for i, g in groups do
		local hold = frame(verList, 4, tabY(i), TAB_W, TAB_H + 8, nil, { Name = "Ver_" .. i, BackgroundTransparency = 1, ZIndex = 4 })
		local b = makeGroupButton(hold, 0, 0, TAB_W, TAB_H, { shadowDy = 7, color = "gray", z = 1, shine = false })
		local tx = 16
		textAt(b.group, tx, 27, TAB_W - tx - 46, 26, g.version, WHITE, 2.8, { TextXAlignment = LEFT, ZIndex = 5 })
		textAt(b.group, tx, 52, TAB_W - tx - 12, 15, g.date, SUB_TXT, 1.8, { TextXAlignment = LEFT, FontFace = XBOLD, ZIndex = 5 })
		-- 09.11.2026: мітку PIN на вкладці версії прибрано (закріплені версії лише стоять першими)
		local dot = makeDot(b.group, TAB_W - 10, 10, 8)
		b.onClick = function() if selVer ~= g.key then selectVersion(g.key, true) end end
		tabs[g.key] = { key = g.key, g = g, hold = hold, b = b, dot = dot, i = i }
	end
	verList.CanvasSize = UDim2.fromOffset(0, tabY(#groups + 1) + 6)
end

-- ===== картки вибраної версії =====
local CARD_W = NW - 22
local function renderNews(g)
	for _, c in updList:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	if not g then return end
	for i, u in g.list do
		local img = imageId(u.image)
		local textW = CARD_W - 32
		local card = new("Frame", { Name = "Card_" .. i, LayoutOrder = i, Size = UDim2.fromOffset(CARD_W, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4 }, updList)
		new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.25) }) }, card)
		stroke(card, INK, 3)
		local col = new("Frame", { Name = "Col", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 14), Size = UDim2.fromOffset(textW, 0),
			AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 5 }, card)
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, col)
		new("UIPadding", { PaddingBottom = UDim.new(0, 16) }, col)
		-- рядок: версія · дата (09.11.2026: мітку PINNED прибрано)
		local meta = new("Frame", { Name = "Meta", LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.fromOffset(textW, 24), ZIndex = 5 }, col)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder }, meta)
		local metaTxt = (u.version ~= "" and vLabel(u.version) or "") .. ((u.version ~= "" and u.date ~= "") and "  ·  " or "") .. (u.date or "")
		if metaTxt ~= "" then
			label(meta, 0, 0, 0, 24, 16, metaTxt, MUTED, 1.6, { LayoutOrder = 3, AutomaticSize = Enum.AutomaticSize.X, FontFace = XBOLD, ZIndex = 5 })
		end
		label(col, 0, 0, textW, 0, 32, Loc.t(u.title ~= "" and u.title or "Update"), hexColor(u.titleColor, WHITE), 3,
			{ LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = LEFT, ZIndex = 5, AutoLocalize = false })
		-- 05.11.2026: текст з пунктами «1. …», «2. …» (кожен з нового рядка, ≥ 2 пунктів) — кожен пункт окремою плашкою
		--   з жовтим квадратиком-номером; інакше — один абзац, як раніше
		local items, numbered = {}, 0
		for line in string.gmatch(u.text .. "\n", "([^\n]*)\n") do
			local plain = string.gsub(string.gsub(string.gsub(line, "%[#%x+%]", ""), "%[/%]", ""), "%*%*", "")
			local num = string.match(plain, "^%s*(%d+)[%.%)]%s")
			if num then
				local body = string.gsub(line, "^%s*%[#%x+%]%*%*%d+[%.%)]%*%*%[/%]%s*", "")
				body = string.gsub(body, "^%s*%[#%x+%]%d+[%.%)]%[/%]%s*", "")
				body = string.gsub(body, "^%s*%*%*%d+[%.%)]%*%*%s*", "")
				body = string.gsub(body, "^%s*%d+[%.%)]%s*", "")
				table.insert(items, { n = num, text = body }); numbered += 1
			elseif string.match(line, "%S") then
				table.insert(items, { text = line })
			end
		end
		if numbered >= 2 then
			for k, it in items do
				local row = new("Frame", { Name = "Item_" .. k, LayoutOrder = 10 + k, Size = UDim2.fromOffset(textW, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = C("101317"), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 5 }, col)
				new("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
				stroke(row, INK, 2.5).LineJoinMode = Enum.LineJoinMode.Round -- Miter з UICorner малює квадратні кути
				new("UISizeConstraint", { MinSize = Vector2.new(0, 54) }, row)
				local tx = 16
				if it.n then
					local badge = new("Frame", { Name = "Num", BackgroundColor3 = C("ffd24a"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(36, 36), ZIndex = 6 }, row)
					new("UICorner", { CornerRadius = UDim.new(0, 8) }, badge)
					stroke(badge, INK, 2.5).LineJoinMode = Enum.LineJoinMode.Round
					label(badge, 0, 0, 36, 36, 21, it.n, WHITE, 2.4, { ZIndex = 7 })
					tx = 58
				end
				local t = label(row, tx, 0, textW - tx - 12, 0, 20, richText(Loc.t(it.text)), hexColor(u.textColor, SUB_TXT), 1.9,
					{ AutoLocalize = false, AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, RichText = true, TextXAlignment = LEFT,
						TextYAlignment = Enum.TextYAlignment.Center, FontFace = XBOLD, LineHeight = 1.1, ZIndex = 6 })
				new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }, t)
			end
		elseif u.text ~= "" then
			label(col, 0, 0, textW, 0, 21, richText(Loc.t(u.text)), hexColor(u.textColor, SUB_TXT), 1.9,
				{ AutoLocalize = false, LayoutOrder = 3, AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, RichText = true, TextXAlignment = LEFT,
					TextYAlignment = Enum.TextYAlignment.Top, FontFace = XBOLD, LineHeight = 1.15, ZIndex = 5 })
		end
		if img ~= "" then -- картинка велика: на всю ширину картки під текстом
			local box = slotBg(col, 0, 0, textW, 300, 5)
			box.LayoutOrder = 100
			new("ImageLabel", { Name = "Image", BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit,
				Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), ZIndex = 6 }, box)
		end
	end
	updList.CanvasPosition = Vector2.zero
end

-- вибір версії: показати її новини й позначити їх переглянутими (крапка й NEW знімаються, лічильник HUD зменшується)
selectVersion = function(key, animate: boolean)
	selVer = key
	local g = nil
	for _, x in groups do if x.key == key then g = x end end
	renderNews(g)
	if g then
		local ids = {}
		for _, u in g.list do if not seenSet[u.id] then table.insert(ids, u.id); seenSet[u.id] = true end end
		if #ids > 0 then task.spawn(invoke, "SeenUpdates", ids) end
	end
	paintTabs(animate)
	updateHudBadge()
	if not animate then -- вкладку вибраної версії — у видиму частину стовпчика
		local t = tabs[key]
		if t then verList.CanvasPosition = Vector2.new(0, math.max(0, tabY(t.i) - 8)) end
	end
end
local function refreshTabDots()
	if upd.isOpen then for _, t in tabs do t.dot.Visible = groupUnseen(t.g) end end
end

local function showUpdates()
	buildGroups()
	updLoading.Visible = #groups == 0
	updLoading.Text = #groups == 0 and "No news yet" or ""
	buildTabs()
	-- за замовчуванням — найновіша версія (перша вкладка); закріплена лише позначена PIN
	local keep = nil
	for _, g in groups do if g.key == selVer then keep = selVer end end
	selectVersion(keep or (groups[1] and groups[1].key), false)
end

local updToken = 0
upd.onOpen = function()
	updToken += 1
	local my = updToken
	readSeen()
	selVer = nil
	if #updates == 0 then updLoading.Visible = true; updLoading.Text = "Loading…" end
	showUpdates()
	task.spawn(function()
		local res = invoke("GetUpdates")
		if my ~= updToken then return end
		if type(res) ~= "table" or type(res.updates) ~= "table" then
			updLoading.Visible = #updates == 0
			updLoading.Text = "Can't load news right now"
			return
		end
		updates = res.updates
		readSeen()
		showUpdates()
	end)
end

-- червоний лічильник нових на кнопці Updates у HUD (MainHUD не змінюється: значок додаємо до його кнопки звідси)
task.spawn(function()
	for _ = 1, 60 do
		local hud = playerGui:FindFirstChild("MainHUD")
		if hud then
			for _, d in hud:GetDescendants() do
				if d:IsA("ImageLabel") and d.Name == "Icon" and d.Image == ICON.updates and d.Parent then
					hudBadge = makeBadge(d.Parent, 10, 22)
					hudBadge.f.Position = UDim2.new(1, -4, 0, 4)
					updateHudBadge()
					return
				end
			end
		end
		task.wait(1)
	end
end)
-- список для лічильника: при вході й раз на 2 хв (сервер тримає кеш)
task.spawn(function()
	while player:GetAttribute("UpdatesSeen") == nil do task.wait(1) end
	while true do
		if not upd.isOpen then
			local res = invoke("GetUpdates")
			if type(res) == "table" and type(res.updates) == "table" then
				updates = res.updates
				readSeen()
				buildGroups()
				updateHudBadge()
			end
		end
		task.wait(120)
	end
end)
player:GetAttributeChangedSignal("UpdatesSeen"):Connect(function() readSeen(); updateHudBadge(); refreshTabDots() end)

-- =====================================================================
-- ===== CODES =====
-- =====================================================================
local codes = makeWindow({ key = "Codes", gui = "CodesWindow", title = "CODES", icon = ICON.codes, palette = { "fff6c8", "ffd23a", "e09a10", "ffd23a" } })
local codeCard = cardBg(codes.content, 140, 92, 700, 392, 3)
textAt(codeCard, 0, 48, 700, 32, "Redeem a code", WHITE, 3.2, { ZIndex = 4 })
textAt(codeCard, 0, 88, 700, 17, "Find codes in Updates and on our socials!", SUB_TXT, 1.9, { FontFace = XBOLD, ZIndex = 4 })
local codeSlot = slotBg(codeCard, 70, 120, 560, 80, 4)
local codeBox = new("TextBox", { Name = "CodeInput", BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0),
	FontFace = HEAVY, TextSize = 38, Text = "", PlaceholderText = "ENTER CODE", PlaceholderColor3 = C("5d636b"), TextColor3 = WHITE,
	ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Center, ClipsDescendants = true, ZIndex = 5 }, codeSlot)
stroke(codeBox, INK, 3, 0, true)
local redeemBtn = makeGroupButton(codeCard, 200, 222, 300, 84, { name = "Redeem", shadowDy = 8, color = "green", text = "REDEEM", textSize = 34, z = 5, tap = false })
local codeResult = textAt(codeCard, 0, 350, 700, 28, "", GOOD, 3, { ZIndex = 5 })

local CODE_ERR = {
	invalid = "Invalid code", used = "Already used", expired = "Expired", limit = "Code limit reached", offline = "Codes are offline",
	full = "Inventory full", busy = "Try again in a moment", error = "Something went wrong · try again",
}
local redeeming = false
local editing = false
codeBox:GetPropertyChangedSignal("Text"):Connect(function()
	if editing then return end
	local t = string.upper(codeBox.Text)
	t = string.gsub(t, "[\r\n\t]", "")
	if #t > 24 then t = string.sub(t, 1, 24) end
	if t ~= codeBox.Text then
		editing = true
		codeBox.Text = t
		codeBox.CursorPosition = #t + 1
		editing = false
	end
end)
local function doRedeem()
	if redeeming then return end
	local code = string.gsub(codeBox.Text, "^%s*(.-)%s*$", "%1")
	if code == "" then shakeGroup(redeemBtn.group); setStatus(codeResult, "Enter a code first", BAD); return end
	StyleA.tap()
	redeeming = true
	redeemBtn:setText("...")
	local res = invoke("Redeem", code)
	redeeming = false
	redeemBtn:setText("REDEEM")
	if type(res) == "table" and res.ok then
		UISounds.play("claim")
		setStatus(codeResult, res.text or "Redeemed!", GOOD)
		codeBox.Text = ""
	else
		local e = type(res) == "table" and res.error or "error"
		local msg = CODE_ERR[e] or CODE_ERR.error
		if e == "wait" then msg = "Too many tries · wait " .. fmtWait(res.wait or 2) end
		denySound()
		setStatus(codeResult, msg, BAD)
	end
end
redeemBtn.onClick = function() task.spawn(doRedeem) end
codeBox.FocusLost:Connect(function(enter) if enter and codes.isOpen then task.spawn(doRedeem) end end)
codes.onOpen = function() codeResult.Text = "" end
codes.onClose = function() codeBox:ReleaseFocus() end

-- =====================================================================
-- ===== FEEDBACK =====
-- =====================================================================
local fb = makeWindow({ key = "Feedback", gui = "FeedbackWindow", title = "FEEDBACK", icon = ICON.feedback, palette = { "ffe6f6", "ff9ad9", "e0479e", "ff9ad9" } })
local FB_MIN, FB_MAX = 10, 500
local CATS = { { "Bug", "red" }, { "Idea", "yellow" }, { "Other", "blue" } }
local category = "Bug"
local catBtns = {}
textAt(fb.content, 40, 86, 222, 20, "Category", WHITE, 2.2, { TextXAlignment = LEFT, ZIndex = 5 })
local function paintCats()
	for _, c in CATS do catBtns[c[1]]:setColor(category == c[1] and c[2] or "gray") end
end
for i, c in CATS do
	local b = makeGroupButton(fb.content, 40, 104 + (i - 1) * 86, 222, 72, { name = "Cat_" .. c[1], shadowDy = 7, color = "gray", text = c[1], textSize = 28, z = 5, shine = false })
	b.onClick = function() category = c[1]; paintCats() end
	catBtns[c[1]] = b
end
paintCats()
label(fb.content, 40, 372, 222, 100, 15, "Your message goes straight to the developers. Thank you for helping!", SUB_TXT, 1.6,
	{ TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, FontFace = XBOLD, ZIndex = 5 })
local fbSlot = slotBg(fb.content, 290, 72, 650, 318, 4)
local fbScroll = new("ScrollingFrame", { Name = "TextScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 4),
	Size = UDim2.new(1, -8, 1, -8), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6,
	ScrollBarImageColor3 = C("5d636b"), ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 5 }, fbSlot)
local fbBox = new("TextBox", { Name = "FeedbackInput", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -30, 0, 290),
	AutomaticSize = Enum.AutomaticSize.Y, FontFace = BOLD, TextSize = 21, Text = "", PlaceholderText = "Tell us about a bug or share an idea…",
	PlaceholderColor3 = C("6a7078"), TextColor3 = WHITE, ClearTextOnFocus = false, MultiLine = true, TextWrapped = true,
	TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 6 }, fbScroll)
new("UIPadding", { PaddingBottom = UDim.new(0, 12) }, fbScroll)
local fbCount = textAt(fb.content, 290, 408, 650, 17, "0 / " .. FB_MAX, MUTED, 1.8, { TextXAlignment = RIGHT, FontFace = XBOLD, ZIndex = 5 })
local fbStatus = label(fb.content, 290, 428, 400, 66, 22, "", GOOD, 2.4, { TextWrapped = true, TextXAlignment = LEFT, ZIndex = 5 })
local sendBtn = makeGroupButton(fb.content, 720, 428, 220, 70, { name = "Send", shadowDy = 7, color = "green", text = "SEND", textSize = 30, z = 5, tap = false })
-- допуск до відгуку (сервер авторитетний — BackendService; тут лише показ): атрибути FeedbackBlock / FeedbackReadyAt
local fbGate = label(fb.content, 290, 424, 420, 78, 17, "", C("ffd23a"), 2, { Name = "Gate", TextWrapped = true, TextXAlignment = LEFT, Visible = false, ZIndex = 5 })
local function gateState(): (string?, number)
	if player:GetAttribute("FeedbackBlock") == "account" then return "account", 0 end
	local readyAt = player:GetAttribute("FeedbackReadyAt")
	if type(readyAt) ~= "number" then return nil, 0 end -- сервер ще не надіслав — перевірить сам при надсиланні
	local left = readyAt - workspace:GetServerTimeNow()
	if left > 0 then return "session", left end
	return nil, 0
end
local function gateText(st: string?, left: number): string
	if st == "account" then return "Your account must be at least " .. tostring(player:GetAttribute("FeedbackMinAccountDays") or 3) .. " days old" end
	local mins = math.max(1, math.ceil(((player:GetAttribute("FeedbackMinSession") :: number?) or 300) / 60))
	return "You can send feedback after " .. mins .. (mins == 1 and " minute" or " minutes") .. " in game\nAvailable in " .. fmtWait(left)
end

local fbEditing = false
local function fbLen(): number return utf8.len(fbBox.Text) or #fbBox.Text end
fbBox:GetPropertyChangedSignal("Text"):Connect(function()
	if fbEditing then return end
	local t = fbBox.Text
	local n = utf8.len(t) or #t
	if n > FB_MAX then
		local cut = utf8.offset(t, FB_MAX + 1)
		fbEditing = true
		fbBox.Text = string.sub(t, 1, (cut or #t + 1) - 1)
		fbEditing = false
		n = FB_MAX
	end
	fbCount.Text = n .. " / " .. FB_MAX
	fbCount.TextColor3 = (n >= FB_MAX and BAD) or (n > 0 and n < FB_MIN and C("ffd23a")) or MUTED
end)

local cooldownUntil = 0
local sending = false
local function refreshSend()
	-- сіра під час надсилання й очікування; натискання тоді хитає кнопку й показує «Wait m:ss»
	sendBtn:setColor((cooldownUntil - os.clock() <= 0 and not sending and gateState() == nil) and "green" or "gray")
end
local function startCooldown(sec: number)
	cooldownUntil = os.clock() + sec
	refreshSend()
	task.spawn(function()
		while os.clock() < cooldownUntil do
			if fbStatus:GetAttribute("Wait") then fbStatus.Text = "Wait " .. fmtWait(cooldownUntil - os.clock()) end
			task.wait(0.25)
		end
		if fbStatus:GetAttribute("Wait") then fbStatus:SetAttribute("Wait", nil); fbStatus.Text = "" end
		refreshSend()
	end)
end
local function deviceName(): string
	local last = UIS:GetLastInputType()
	if string.find(last.Name, "Gamepad") then return "Gamepad" end
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then return "Touch" end
	return "Keyboard"
end
local function doSend()
	if sending then return end
	local text = string.gsub(fbBox.Text, "^%s*(.-)%s*$", "%1")
	local n = utf8.len(text) or #text
	fbStatus:SetAttribute("Wait", nil)
	if n < FB_MIN then
		shakeGroup(sendBtn.group)
		setStatus(fbStatus, "Too short · at least " .. FB_MIN .. " characters", BAD)
		return
	end
	StyleA.tap()
	sending = true
	refreshSend()
	sendBtn:setText("...")
	local res = invoke("SendFeedback", { category = category, text = text, device = deviceName() })
	sending = false
	sendBtn:setText("SEND")
	if type(res) == "table" and res.ok then
		UISounds.play("claim")
		setStatus(fbStatus, "Thanks! Sent.", GOOD)
		fbBox.Text = ""
		startCooldown(120)
	elseif type(res) == "table" and res.error == "rate" then
		denySound()
		fbStatus:SetAttribute("Wait", true)
		setStatus(fbStatus, "Wait " .. fmtWait(res.wait or 120), BAD)
		startCooldown(res.wait or 120)
	else
		local e = type(res) == "table" and res.error or "error"
		denySound()
		setStatus(fbStatus, ((e == "session" or e == "account") and gateText(e, type(res) == "table" and res.wait or 0))
			or (e == "short" and ("Too short · at least " .. FB_MIN .. " characters")) or (e == "long" and "Too long") or "Can't send right now", BAD)
		refreshSend()
	end
end
sendBtn.onClick = function()
	if sending then return end
	if gateState() then shakeGroup(sendBtn.group); return end -- ще не можна: сіра кнопка, deny
	if os.clock() < cooldownUntil then
		shakeGroup(sendBtn.group)
		fbStatus:SetAttribute("Wait", true)
		setStatus(fbStatus, "Wait " .. fmtWait(cooldownUntil - os.clock()), BAD)
		return
	end
	task.spawn(doSend)
end
fb.onOpen = function()
	if not fbStatus:GetAttribute("Wait") and os.clock() >= cooldownUntil then fbStatus.Text = "" end
	refreshSend()
end
fb.onClose = function() fbBox:ReleaseFocus() end
-- поки вікно відкрите: допуск (таймер «Available in m:ss») і колір SEND
task.spawn(function()
	while true do
		if fb.isOpen then
			local st, left = gateState()
			fbGate.Visible = st ~= nil
			fbStatus.Visible = st == nil
			if st then
				fbGate.Text = gateText(st, left)
				fbGate.TextColor3 = st == "account" and BAD or C("ffd23a")
			end
			refreshSend()
		end
		task.wait(0.25)
	end
end)
