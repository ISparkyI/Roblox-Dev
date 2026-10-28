--!nonstrict
-- ShopWindow — вікно SHOP (кнопка Shop ліворуч у HUD). Де: StarterPlayer/StarterPlayerScripts/ShopWindow (LocalScript).
-- Каркас вікна — як InfoWindows / QuestsWindow (980 × 528 зі studs, заголовок з іконкою Shop −8°, перелив червоний, червона X,
--   Esc / клік поза вікном, WindowManager "Shop"). Праворуч від заголовка — перемикач ROBUX / TICKETS і баланс тікетів
--   (за тікети ціна × 1,25, вгору до цілого — MonetizationConfig.ticketPrice).
-- Розділи (прокрутка), заголовки «~ НАЗВА ~»:
--   MONEY MULTIPLIER — драбина x2 Money: «x8 → x16», ціна наступного ступеня (Developer Product MonetizationConfig.MoneyTierProducts;
--     за тікети — Remotes/ShopAction "BuyTier"); куплено все — MAX.
--   GAMEPASSES — MonetizationConfig.Passes: VIP на всю ширину, решта 2 у ряд (Robux — PromptGamePassPurchase, id = 0 — ще не
--     створено; тікети — ShopAction "BuyTickets"); куплено — OWNED.
--   BUNDLES — продовгуваті картки: Starter Pack і Mega Pack (заготовки, SOON), Potion Pack (Developer Product, багаторазовий;
--     за тікети — ShopAction "BuyProduct").
--   TICKETS — 9 пакетів тікетів (MonetizationConfig.TicketProducts, багаторазові, лише Robux), вигода +12,5 … +25 %.
--   COMING SOON — заготовки майбутніх геймпасів (Fast Roll, Auto Roll, x2 Mutation Luck, +1 Roll Stand, Extra Storage,
--     Fast Mutations), сірі, SOON. Ціни заготовок — пропозиція.
-- Картка: колір товару, візерунок «квадратик + L» як на кнопках стилю A (дрібніший, прозорість 15 %), іконка зліва (−8°, тінь),
--   назва з переливом, опис, кнопка з ціною (іконка Robux / тікета + число). На фоні падають іконки товару (40 % прозорі),
--   обрізані краєм картки. Наведення — Shared/CardHover без нахилу (×1,05); картка під мишкою — над сусідами; проміжки між
--   картками більші за приріст від збільшення.
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
	shop = "rbxassetid://91791061262477", robux = "rbxassetid://139687766069559", ticket = "rbxassetid://85299808396483",
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
		WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WX, winY = WY, winW = WW, winH = WH, leftExtra = spec.leftExtra })
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
		if W.keepInside and W.keepInside(p) then return end -- закладки збоку — теж вікно
		W.close()
	end)
	if hudEvent then
		hudEvent.Event:Connect(function(key) if key == spec.key then if W.isOpen then W.close() else W.open() end end end)
	end
	return W
end
-- =====================================================================
-- ===== SHOP =====
-- =====================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local NF = require(Shared:WaitForChild("NumberFormat"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local MultiCfg = require(Shared:WaitForChild("MultiConfig"))
local CardHover = require(Shared:WaitForChild("CardHover"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
-- описи товарів списком «- пункт» (що саме купуємо)
-- опис карток (v6, 28.10.2026): список рядків без «- », ключові слова — кольором (RichText, колір = що саме дає товар);
-- рядок-таблиця { text, icon = "Pot_*" } — маленьке 3D-зілля перед текстом. MINIS[key] — ряд 3D-зіль з підписом під кожним.
local function fc(hex: string, t: string): string return '<font color="#' .. hex .. '">' .. t .. "</font>" end
local GOLD, GREEN, PURPLE, BLUE, ORANGE, PINK, LIME = "ffd23a", "7ef05a", "c99bff", "6fd2ff", "ff9a4a", "ff7fc4", "b8ff5a"
-- колір виділення контрастує з кольором картки (зелене на зеленій картці не читається)
local DESC = {
	VIP = { fc(LIME, "x1.5 Money") .. " from every sale", fc(ORANGE, "VIP") .. " nametag above your head", "Stacks with " .. fc(BLUE, "all other boosts") },
	Lucky = { fc(GOLD, "x2 Roll Luck") .. " forever", "Rare golems " .. fc(GOLD, "2x") .. " more often" },
	MutLucky = { fc("ffb3f0", "x2 Mutation Luck") .. " forever", "Mutations " .. fc("ffb3f0", "2x") .. " more often" },
	AutoEquip = { "Auto-equips " .. fc(GOLD, "best golems"), "Toggle it in Settings" },
	FastForge = { "Forge smelts " .. fc(LIME, "2x faster") },
	AutoCollect = { "Crates go to " .. fc(LIME, "inventory"), "No more COLLECT" },
	RollStand1 = { fc(GREEN, "+1 roll stand") .. " per stage", "2 stages, up to " .. fc(GREEN, "7 stands") },
	MoneyTier = { "More " .. fc(GOLD, "Money") .. " from every sale", fc(GOLD, "Permanent") .. ", stacks with VIP" },
	StarterPack = { fc(GOLD, "+$50K") .. " Money", { text = fc(GOLD, "3") .. " Luck Potions", icon = "Pot_Luck" }, "Stone Golem" },
	PotionPack = {},
	ExtraStorage = { fc(LIME, "+50") .. " golem inventory slots", "Buy as many as you want" },
	Mega = { fc(GOLD, "+1,000") .. " Tickets", fc(GREEN, "10") .. " of each potion", fc(BLUE, "Diamond") .. " Ironclad Golem" },
	FastRoll = { "Roll results appear " .. fc(GOLD, "instantly"), "No waiting between rolls" },
	AutoRoll = { "The lever " .. fc(LIME, "rolls by itself"), "Stops on golems from your filter" },
	AutoBuy = { fc(GOLD, "Buys golems") .. " from your filter", "Mutation, rarity, min damage" },
}
local MINIS = {
	PotionPack = { { "Pot_Luck", "x5", GREEN, "+25% Luck" }, { "Pot_Speed", "x5", BLUE, "2x Mining" }, { "Pot_Money", "x5", GOLD, "x2 Money" },
		{ "Pot_Strength", "x5", "ff6f7f", "+50% Damage" } },
}
local TextService = game:GetService("TextService")
-- іконки нових розділів (Asset Manager; nil — тимчасова іконка)
local SKIP_ICON_ID, LUCK10_ICON_ID, LUCK99_ICON_ID = "76478987044650", "124578338510174", "120776574619004"   -- shop_timeskip / shop_luckroll10 / shop_luckroll99.png
local win = makeWindow({ key = "Shop", gui = "ShopWindow", title = "SHOP", leftExtra = 110, -- закладки зліва (WindowFit тримає їх на екрані)
	 icon = ICON.shop, palette = { "ffd0d6", "ff5a6e", "c21a32", "ff5a6e" } })
local content = win.content

local currency = "robux" -- "robux" | "tickets"
local function owned(key: string): boolean return player:GetAttribute("Pass_" .. key) == true end
local function tickets(): number return tonumber(player:GetAttribute("Tickets")) or 0 end

-- перемикач валюти праворуч від заголовка: ROBUX / TICKETS (вибрана кольорова, інша сіра)
local SW_X, SW_W, SW_H = 520, 170, 48
local swRobux = makeGroupButton(content, SW_X, 18, SW_W, SW_H, { name = "CurRobux", shadowDy = 5, color = "green", z = 6, shine = false })
local swTickets = makeGroupButton(content, SW_X + SW_W + 12, 18, SW_W, SW_H, { name = "CurTickets", shadowDy = 5, color = "gray", z = 6, shine = false })
local function swContent(b, icon: string, text: string)
	local pad = 7
	local s = SW_H - 2 * pad - 6
	new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = icon, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(12, pad),
		Size = UDim2.fromOffset(s, s), ZIndex = 4 }, b.group)
	textAt(b.group, 12 + s + 8, SW_H / 2 - 2, SW_W - s - 28, 22, text, WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
end
swContent(swRobux, ICON.robux, "ROBUX")
swContent(swTickets, ICON.ticket, "TICKETS")
local balance = textAt(content, SW_X, 82, SW_W * 2 + 12, 15, "", SUB_TXT, 1.8, { ZIndex = 6, FontFace = XBOLD })

-- список (прокрутка): розділи «~ Назва ~» з картками
local LX, LY, LW, LH = 30, 96, 920, 410
local list = new("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(LX, LY), Size = UDim2.fromOffset(LW, LH), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C("2a2e35"), ScrollBarImageTransparency = 0.1, CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 4 }, content)
local PADX, PADY = 26, 18 -- запас під збільшення картки при наведенні (×1,05)
local CW = LW - 2 * PADX - 14
local GX, GY = 28, 24 -- проміжки між картками (більші за приріст від збільшення — сусіда не накриває)
local PATTERN_TILE = 24 -- візерунок «квадратик + L» як на кнопках: 2 × 2 клітинки по 12

-- опис розбиваємо на рядки ОДИН раз (за шириною в спокої): при збільшенні картки (UIScale) текст не переноситься наново й не скаче
local function prewrap(text: string, size: number, width: number): string
	local params = Instance.new("GetTextBoundsParams")
	params.Font = XBOLD
	params.Size = size
	params.Width = 100000
	local function tw(t: string): number
		params.Text = t
		local ok, v = pcall(TextService.GetTextBoundsAsync, TextService, params)
		return ok and v.X or #t * size * 0.6
	end
	local out = {}
	for para in (text .. "\n"):gmatch("(.-)\n") do
		local line = ""
		for word in para:gmatch("%S+") do
			local cand = line == "" and word or (line .. " " .. word)
			if line ~= "" and tw(cand) > width then table.insert(out, line); line = word else line = cand end
		end
		table.insert(out, line)
	end
	return table.concat(out, "\n")
end

-- опис: кожен рядок — окрема мітка (RichText, без переносу; не влазить — шрифт менший), тож при збільшенні картки нічого не скаче.
-- align: "left" | "center". Повертає y під останнім рядком.
local function plainOf(t: string): string return (t:gsub("<[^>]+>", "")) end
local function fitSize(text: string, size: number, width: number): number
	local params = Instance.new("GetTextBoundsParams")
	params.Font = XBOLD; params.Width = 100000
	params.Text = plainOf(text)
	while size > 11 do
		params.Size = size
		local ok, v = pcall(TextService.GetTextBoundsAsync, TextService, params)
		if not ok or v.X <= width then break end
		size -= 1
	end
	return size
end
local function descLines(card: GuiObject, x: number, y: number, w: number, size: number, lines: any, align: string, z: number): number
	if type(lines) == "string" then
		local t = {}
		for ln in (lines .. "\n"):gmatch("(.-)\n") do table.insert(t, ln) end
		lines = t
	end
	local lh = math.floor(size * 1.3 + 0.5)
	for _, ln in lines do
		local text = type(ln) == "table" and ln.text or ln
		local ic = type(ln) == "table" and ln.icon or nil
		local isz = ic and math.floor(size * 1.5) or 0
		local avail = w - (ic and isz + 4 or 0)
		local sz = fitSize(text, size, avail - 6)
		local lx = x + (ic and isz + 4 or 0)
		local lbl = label(card, lx, y, avail, lh, sz, text, WHITE, size >= 18 and 2 or 1.6, { RichText = true, TextWrapped = false,
			TextXAlignment = align == "center" and Enum.TextXAlignment.Center or LEFT, TextYAlignment = Enum.TextYAlignment.Center, FontFace = XBOLD, ZIndex = z })
		if ic then
			if align == "center" then
				-- іконка перед текстом по центру: зсуваємо пару «іконка + текст» разом
				local params = Instance.new("GetTextBoundsParams"); params.Font = XBOLD; params.Size = sz; params.Width = 100000; params.Text = plainOf(text)
				local ok, v = pcall(TextService.GetTextBoundsAsync, TextService, params)
				local tw0 = ok and v.X or avail
				local total = isz + 4 + tw0
				local sx = x + (w - total) / 2
				lbl.Position = UDim2.fromOffset(sx + isz + 4, y); lbl.TextXAlignment = LEFT
				lx = sx
			else lx = x end
			local im = new("ImageLabel", { Name = "LineIcon", BackgroundTransparency = 1, Position = UDim2.fromOffset(lx, y + (lh - isz) / 2), Size = UDim2.fromOffset(isz, isz), ZIndex = z }, card)
			ItemViewport.set(im, ic, 1.25)
		end
		y += lh
	end
	return y
end
-- ряд 3D-зіль з підписом (x5) — більше картинок, менше тексту
local function miniRow(card: GuiObject, x: number, y: number, minis: any, z: number): number
	-- колонка на зілля: 3D-іконка, під нею кількість (колір зілля) і на що воно впливає
	local S, CWD = 40, 104
	for i, mn in minis do
		local cx = x + (i - 1) * CWD
		local im = new("ImageLabel", { Name = "Mini", BackgroundTransparency = 1, Position = UDim2.fromOffset(cx + (CWD - S) / 2, y), Size = UDim2.fromOffset(S, S), ZIndex = z }, card)
		ItemViewport.set(im, mn[1], 1.2)
		local t = textAt(card, cx, y + S + 9, CWD, 18, mn[2], C(mn[3]), 2.4, { ZIndex = z + 1 })
		t.TextColor3 = C(mn[3])
		if mn[4] then textAt(card, cx, y + S + 29, CWD, 15, mn[4], WHITE, 1.8, { ZIndex = z + 1, FontFace = XBOLD }) end
	end
	return y + S + 40
end

-- іконки товару падають на фоні картки (згори вниз, 40 % прозорі)
local function startRain(clip: Frame, icon: string, w: number, h: number, every: number)
	task.spawn(function()
		while clip.Parent do
			if win.isOpen then
				local s = math.random(22, 42)
				local img = new("ImageLabel", { BackgroundTransparency = 1, Image = icon, ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(s, s), Rotation = math.random(-25, 25),
					Position = UDim2.fromOffset(math.random(10, math.max(11, math.floor(w) - 10)), -s), ZIndex = 2 }, clip)
				local tw = TweenService:Create(img, TweenInfo.new(3 + math.random() * 3, Enum.EasingStyle.Linear), {
					Position = UDim2.fromOffset(img.Position.X.Offset + math.random(-30, 30), h + s), Rotation = img.Rotation + math.random(-60, 60) })
				tw.Completed:Connect(function() img:Destroy() end)
				tw:Play()
			end
			task.wait(every * (0.6 + math.random() * 0.8))
		end
	end)
end

-- ===== товари =====
-- item: key, name, desc, icon, tone (hex), tile (колір візерунка StyleA), robux, kind = "pass" | "tier" | "soon",
--   noTickets (лише Robux), extra (функція — додатковий вміст картки)
local PASS_TILE = { VIP = "yellow", Lucky = "green", MutLucky = "blue", AutoEquip = "blue", FastForge = "orange", AutoCollect = "purple", RollStand1 = "gray", FastRoll = "blue", AutoRoll = "red", AutoBuy = "green" }
local passItems = {}
for key, def in MonCfg.Passes do
	if not def.hidden then -- етапи (RollStand2) показує картка першого етапу
		table.insert(passItems, { key = key, kind = "pass", name = def.name, desc = def.desc, icon = def.icon, tone = def.tone, tile = PASS_TILE[key] or "gray",
			robux = def.robux, id = def.id, order = def.order or 99, featured = def.featured, stages = def.stages, noTilt = key == "VIP" })
	end
end
table.sort(passItems, function(a, b) return a.order < b.order end)

-- заготовки (SOON): ціни — пропозиція, з'являться разом із системами
local BUNDLES = {
	{ key = "StarterPack", kind = "product", once = true, golem = "stone", mut = 4, name = "Starter Pack", desc = "+$50K Money, 3 Luck Potions and a Diamond Stone Golem. Once per player!",
		icon = "rbxassetid://97975821667403", tone = "7ef05a", tile = "green", robux = MonCfg.Products.StarterPack.robux, id = MonCfg.Products.StarterPack.id },
	{ key = "PotionPack", kind = "product", vp = "Icon:PotionPack", name = "Potion Pack", desc = "5 of each potion: Luck, Speed, Money, Strength. Buy as many as you want!",
		icon = "rbxassetid://104193388781391", tone = "5cc8ff", tile = "blue", robux = MonCfg.Products.PotionPack.robux, id = MonCfg.Products.PotionPack.id },
	{ key = "ExtraStorage", kind = "product", name = "Extra Storage", desc = "+50 golem slots in your inventory. Buy as many as you want!",
		icon = "rbxassetid://107241982376806", tone = "ff8a3a", tile = "orange", robux = MonCfg.Products.ExtraStorage.robux, id = MonCfg.Products.ExtraStorage.id },
	{ key = "Mega", kind = "soon", name = "Mega Pack", desc = "+1,000 Tickets, 10 potions of each kind and a Diamond Ironclad Golem.", icon = "rbxassetid://85164603125451",
		tone = "c08cff", tile = "purple", robux = 399 },
}
-- пакети тікетів (MonetizationConfig.TicketProducts): лише за Robux, багаторазові; вигода — tickets / robux − 1
local PRODUCTS = {}
for i, t in MonCfg.TicketProducts do
	local bonus = math.floor(MonCfg.ticketBonus(t) * 1000 + 0.5) / 10
	table.insert(PRODUCTS, { key = "T" .. i, kind = "tickets", noTickets = true, name = NF.full(t.tickets) .. " Tickets",
		desc = NF.full(t.tickets) .. " Tickets\n" .. (bonus > 0 and ("+" .. tostring(bonus) .. "% bonus" .. (i == #MonCfg.TicketProducts and "\nBEST VALUE" or "")) or "1 Robux = 1 Ticket"),
		icon = "rbxassetid://85299808396483", tone = i % 3 == 1 and "ffd23a" or (i % 3 == 2 and "ff8a3a" or "ff6fb8"),
		tile = i % 3 == 1 and "yellow" or (i % 3 == 2 and "orange" or "red"), robux = t.robux, id = t.id })
end
local FUTURE = {}

-- ціна товару в поточній валюті (nil — без ціни)
-- поточний етап геймпаса з етапами (перший не куплений; nil — куплено все)
local function stageKey(item): string?
	if not item.stages then return item.key end
	for _, k in item.stages do if not owned(k) then return k end end
	return nil
end
local function priceOf(item): (string?, number?)
	if item.kind == "mutTier" then
		local t = MonCfg.MUT_SPEED_TIERS[(tonumber(player:GetAttribute("MutSpeedTier")) or 0) + 1]
		if not t then return nil, nil end
		return ICON.robux, t.robux
	end
	if item.kind == "pass" and item.stages then
		local k = stageKey(item)
		local def = k and MonCfg.Passes[k]
		if not def then return nil, nil end
		if currency == "tickets" then return ICON.ticket, MonCfg.ticketPrice(def.robux) end
		return ICON.robux, def.robux
	end
	if item.kind == "tier" then
		local t = MultiCfg.DONATE_TIERS[(tonumber(player:GetAttribute("DonateTier")) or 0) + 1]
		if not t then return nil, nil end
		if currency == "tickets" then return ICON.ticket, MonCfg.ticketPrice(t.price) end
		return ICON.robux, t.price
	end
	if currency == "tickets" and not item.noTickets then return ICON.ticket, MonCfg.ticketPrice(item.robux) end
	return ICON.robux, item.robux
end
-- стан кнопки: "buy" | "owned" | "soon" | "max"
local function stateOf(item): string
	if item.kind == "soon" then return "soon" end
	if item.kind == "pass" and not stageKey(item) then return "owned" end
	if item.kind == "pass" and not item.stages and owned(item.key) then return "owned" end
	if item.kind == "product" and item.once and owned(item.key) then return "owned" end
	if item.kind == "mutTier" and not MonCfg.MUT_SPEED_TIERS[(tonumber(player:GetAttribute("MutSpeedTier")) or 0) + 1] then return "max" end
	if item.kind == "tier" and not MultiCfg.DONATE_TIERS[(tonumber(player:GetAttribute("DonateTier")) or 0) + 1] then return "max" end
	return "buy"
end

local cards = {}
local function shopCall(action: string, arg: any): any
	local r = RS:FindFirstChild("Remotes")
	local rf = r and r:FindFirstChild("ShopAction")
	if not rf then return nil end
	local ok, res = pcall(rf.InvokeServer, rf, action, arg)
	return ok and res or nil
end

-- куплені геймпаси, які мають перемикач у SETTINGS: замість OWNED — синя кнопка SETTINGS, клік відкриває налаштування
local SETTINGS_PASSES = { AutoRoll = true, AutoBuy = true, AutoEquip = true }
local function onBuy(c)
	local item = c.item
	local st = stateOf(item)
	if st == "owned" and item.kind == "pass" and SETTINGS_PASSES[item.key] and hudEvent then
		hudEvent:Fire("Settings")
		return
	end
	if st ~= "buy" then
		shakeGroup(c.btn.group)
		if st == "soon" then balance.Text = item.name .. " is coming soon!" end
		return
	end
	local _, price = priceOf(item)
	if currency == "tickets" and not item.noTickets then
		if tickets() < (price or math.huge) then shakeGroup(c.btn.group); return end
		c.btn.enabled = false
		local res = shopCall(item.kind == "tier" and "BuyTier" or (item.kind == "product" and "BuyProduct" or "BuyTickets"), item.kind == "pass" and stageKey(item) or item.key)
		if res and res.ok then UISounds.play("purchase", 0.1) else denySound() end
		c.btn.enabled = true
		return
	end
	if item.kind == "mutTier" then
		local t = MonCfg.MUT_SPEED_TIERS[(tonumber(player:GetAttribute("MutSpeedTier")) or 0) + 1]
		if t and t.id ~= 0 then pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, t.id)
		else shakeGroup(c.btn.group); balance.Text = "Fast Mutations are coming soon!" end
		return
	end
	if item.kind == "pass" and item.stages then item.id = (MonCfg.Passes[stageKey(item) or ""] or {}).id end
	if item.kind == "tier" then
		local nxt = (tonumber(player:GetAttribute("DonateTier")) or 0) + 1
		local pid = MonCfg.MoneyTierProducts[nxt]
		if pid and pid ~= 0 then pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, pid) else shakeGroup(c.btn.group) end
		return
	end
	if (item.id or 0) == 0 then
		shakeGroup(c.btn.group)
		balance.Text = item.kind == "tickets" and "Ticket packs are coming soon!" or "Robux purchase is coming soon. Use Tickets!"
		return
	end
	if item.kind == "product" or item.kind == "tickets" then
		pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, item.id)
	else
		pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, item.id)
	end
end

-- картка: layout "wide" (на всю ширину) | "half" (2 у ряд) | "compact" (3 у ряд)
local function makeCard(item, x: number, y: number, w: number, h: number, layout: string)
	local desc = DESC[item.key] or item.desc
	local P = CardHover.PAD or 12
	local holder = new("Frame", { Name = "Card_" .. item.key, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(w + 2 * P, h + 8 + 2 * P), Position = UDim2.fromOffset(x + w / 2, y + (h + 8) / 2), ZIndex = 1 }, list)
	holder:SetAttribute("NoTilt", true)
	frame(holder, P, P + 8, w, h, BLACK, { Name = "Shadow", BackgroundTransparency = 0.6, ZIndex = 1 })
	local card = frame(holder, P, P, w, h, WHITE, { Name = "Card", ZIndex = 2, ClipsDescendants = true })
	local tone = C(item.tone)
	local soon = item.kind == "soon"
	if soon then tone = tone:Lerp(C("8d939b"), 0.55) end
	vgrad(card, { { 0, tone:Lerp(WHITE, 0.08):ToHex() }, { 0.55, tone:Lerp(BLACK, 0.3):ToHex() }, { 1, tone:Lerp(BLACK, 0.55):ToHex() } })
	stroke(card, INK, 4)
	local A = StyleA.ASSETS
	new("ImageLabel", { Name = "Pattern", BackgroundTransparency = 1, Image = A["stylea_tile_" .. item.tile] or A["stylea_tile_" .. item.tile .. "_half"] or A.stylea_tile_gray,
		ImageTransparency = 0.15, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(PATTERN_TILE, PATTERN_TILE),
		Size = UDim2.fromOffset(w, h), ZIndex = 1 }, card)
	local shade = frame(card, 0, 0, w, h, BLACK, { Name = "Shade", ZIndex = 1 })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 0.6) }) }, shade)
	local clip = frame(card, 0, 0, w, h, nil, { Name = "Rain", BackgroundTransparency = 1, ZIndex = 2, ClipsDescendants = true })
	if not soon then startRain(clip, item.icon, w, h, layout == "wide" and 0.5 or 0.75) end
	-- іконка, назва, опис
	local compact = layout == "compact"
	local square = layout == "square" -- квадратна картка (геймпаси, 3 у ряд): назва зверху, іконка по центру, опис під нею, кнопка внизу
	local isz = layout == "wide" and 132 or (compact and 76 or (square and 92 or 112))
	local icx, icy = (compact and 14 or 22) + isz / 2, compact and 44 + isz / 2 or h / 2
	if square then icx, icy = w / 2, 44 + isz / 2 end
	local function iconImg(name, dy, color, tr, z)
		return new("ImageLabel", { Name = name, BackgroundTransparency = 1, Image = item.icon, ImageColor3 = color or WHITE, ImageTransparency = tr or 0,
			ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(icx, icy + dy), Size = UDim2.fromOffset(isz, isz),
			Rotation = -8, ZIndex = z }, card)
	end
	local iconShadow = iconImg("IconShadow", 6, INK, 0.35, 4)
	local icon = iconImg("Icon", 0, nil, 0, 5)
	if soon then icon.ImageColor3 = C("b9bec5") end
	if item.noTilt then icon.Rotation = 0; iconShadow.Rotation = 0 end
	if item.vp then -- 3D-модель замість картинки (зілля — Prefabs/IconModels)
		icon.Rotation = 0; iconShadow.Visible = false
		ItemViewport.set(icon, item.vp, 1.12)
	end
	if item.golem then -- 3D-модель голема (як у інвентарі)
		local k = ItemViewport.golemKey(item.golem, "miner")
		if k then
			icon.Rotation = 0; iconShadow.Visible = false
			icon.Size = UDim2.fromOffset(isz * 0.72, isz * 0.72) -- модель у ItemViewport більша за мітку (SCALE)
			icon.Position = UDim2.fromOffset(icx, icy + 8)
			ItemViewport.set(icon, k)
		end
		-- мутація голема — назва над ним кольором мутації (анімований градієнт Shared/MutationText)
		if item.mut and item.mut > 0 then
			local mu = Catalog.MUTATIONS[item.mut + 1]
			local ml = textAt(card, icx - 80, icy - isz * 0.36 - 6, 160, 22, string.upper(mu and mu.key or ""), WHITE, 2.4, { ZIndex = 7 })
			require(Shared:WaitForChild("MutationText")).apply(ml, item.mut)
		end
	end
	local title, tx, tw
	if square then
		title = textAt(card, 10, 28, w - 20, 26, item.name, WHITE, 2.8, { ZIndex = 6 })
		tx = 14; tw = w - 28
		descLines(card, tx, 44 + isz + 6, tw, 15, desc, "center", 6)
	elseif compact then
		title = textAt(card, 10, 24, w - 20, 22, item.name, WHITE, 2.6, { ZIndex = 6 })
		tx = 14 + isz + 10; tw = w - tx - 12
		descLines(card, tx, 46, tw, 14, desc, "left", 6)
	else
		tx = 22 + isz + 18; tw = w - tx - 18
		title = textAt(card, tx, layout == "wide" and 32 or 30, tw, layout == "wide" and 36 or 28, item.name, WHITE, layout == "wide" and 3.4 or 2.8, { TextXAlignment = LEFT, ZIndex = 6 })
		local dy = layout == "wide" and 54 or 48
		local dw = layout == "wide" and (tw - 250) or tw
		if MINIS[item.key] then dy = miniRow(card, tx + 4, dy + 2, MINIS[item.key], 6) + 2 end
		descLines(card, tx, dy, dw, layout == "wide" and 21 or 16, desc, "left", 6)
	end
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ffffff" }, { 1, soon and "c9ced5" or item.tone } }) }, title)
	if item.extra then item.extra(card, w, h, tx, tw) end
	-- кнопка з ціною (праворуч унизу; у compact — на всю ширину внизу)
	local full = compact or square -- кнопка на всю ширину внизу
	-- розмір кнопки ×1,5 (v10, 28.10.2026): була 220×58 / повна ширина×48 / 180×50
	local bw, bh = layout == "wide" and 330 or (full and w - 28 or 270), layout == "wide" and 87 or (full and 72 or 75)
	local bx, by = full and 14 or w - bw - 16, h - bh - (full and 16 or 18)
	local btn = makeGroupButton(card, bx, by, bw, bh, { name = "Buy", shadowDy = 5, color = "green", z = 7 })
	local row = new("Frame", { Name = "PriceRow", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(bw / 2, bh / 2 - 3),
		Size = UDim2.fromOffset(0, bh), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 8 }, btn.group)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local s = math.floor(bh * 0.5)
	local bIcon = new("ImageLabel", { Name = "CurIcon", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(s, s), LayoutOrder = 1, ZIndex = 8 }, row)
	local bText = new("TextLabel", { Name = "Price", BackgroundTransparency = 1, FontFace = HEAVY, TextSize = layout == "wide" and 42 or 36, TextColor3 = WHITE, Text = "",
		Size = UDim2.fromOffset(0, bh), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, ZIndex = 9 }, row)
	stroke(bText, INK, 3.4, 0, true)
	local c = { item = item, holder = holder, card = card, btn = btn, bIcon = bIcon, bText = bText, title = title }
	CardHover.attach(holder, card, function() return win.isOpen end)
	-- картка під мишкою — над сусідами (збільшена не ховається під іншою)
	card.MouseEnter:Connect(function() holder.ZIndex = 5 end)
	card.MouseLeave:Connect(function() holder.ZIndex = 1 end)
	btn.onClick = function() onBuy(c) end
	table.insert(cards, c)
	return c
end

local function refreshCard(c)
	local item, b = c.item, c.btn
	local st = stateOf(item)
	if c.refreshExtra then c.refreshExtra() end
	if item.stages then
		local n = 0
		for _, k in item.stages do if owned(k) then n += 1 end end
		c.title.Text = item.name .. " (" .. math.min(n + (st == "owned" and 0 or 1), #item.stages) .. "/" .. #item.stages .. ")"
	end
	if st == "owned" and item.kind == "pass" and SETTINGS_PASSES[item.key] then
		b:setColor("blue"); b.enabled = true
		c.bIcon.Visible = false
		c.bText.Text = "SETTINGS"
		return
	end
	if st == "owned" or st == "max" or st == "soon" then
		b:setColor("gray"); b.enabled = st == "soon"
		c.bIcon.Visible = false
		c.bText.Text = st == "owned" and "OWNED" or (st == "max" and "MAX" or "SOON")
		return
	end
	local icon, price = priceOf(item)
	local tix = currency == "tickets" and not item.noTickets
	local can = not tix or tickets() >= (price or math.huge)
	b:setColor(tix and (can and "yellow" or "gray") or "green")
	b.enabled = true
	c.bIcon.Visible = true
	c.bIcon.Image = icon or ICON.robux
	c.bText.Text = NF.full(price or 0)
end

-- ===== побудова розділів =====
local y = PADY
local SECTION_Y = {} -- y заголовка розділу (відкриття магазину одразу на розділі: «+» біля грошей, лічильники діамантів / тікетів)
local function header(text: string)
	SECTION_Y[text] = y
	local t = textAt(list, PADX, y + 22, CW, 36, "~ " .. text .. " ~", WHITE, 3.6, { ZIndex = 3 })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ffffff" }, { 1, "dfe4ea" } }) }, t)
	y += 54
end
local function grid(items, cols: number, h: number, layout: string)
	local w = (CW - (cols - 1) * GX) / cols
	for i, item in items do
		local col = (i - 1) % cols
		makeCard(item, PADX + col * (w + GX), y, w, h, layout)
		if col == cols - 1 or i == #items then y += h + GY + 8 end
	end
end

-- 1. Money Multiplier — драбина x2 Money (Developer Products; за тікети — ×1,25)
header("MONEY MULTIPLIER")
do
	local multLbl
	local tier = { key = "MoneyTier", kind = "tier", name = "Money Boost", desc = "Get more Money from every sale. Permanent!",
		icon = "rbxassetid://103015355952567", tone = "a6ff3a", tile = "green", robux = 0 }
	tier.extra = function(card, w, h, tx, tw)
		multLbl = textAt(card, tx, h - 52, tw - 250, 46, "", WHITE, 4, { TextXAlignment = LEFT, ZIndex = 6, RichText = true })
	end
	local c = makeCard(tier, PADX, y, CW, 170, "wide")
	c.refreshExtra = function()
		local cur = tonumber(player:GetAttribute("DonateTier")) or 0
		local now = MultiCfg.donateMult(cur)
		local nxt = MultiCfg.nextDonateMult(cur)
		multLbl.Text = nxt and (NF.mult(now) .. ' → <font color="#c9ff3a">' .. NF.mult(nxt) .. "</font>") or NF.mult(now)
	end
	y += 170 + GY + 8
end
-- 2. Gamepasses — VIP на всю ширину, решта 2 у ряд
header("GAMEPASSES")
do
	local rest = {}
	for _, it in passItems do
		if it.featured then makeCard(it, PADX, y, CW, 170, "wide"); y += 170 + GY + 8 else table.insert(rest, it) end
	end
	-- квадратні картки, 3 у ряд (висота = ширина)
	grid(rest, 3, math.floor((CW - 2 * GX) / 3) + 28, "square") -- +28: місце під більшу кнопку з ціною
end
-- 3. Bundles, 4. Products, 5. Coming Soon (заготовки)
-- MUTATION SPEED (Fast Mutations) з магазину прибрано (28.10.2026): картка з'явиться біля Mutation Machine; логіка (MUT_SPEED_TIERS,
-- MutSpeedTier, ProcessReceipt) лишається.
-- LUCKY ROLLS (v8; v9 — над BUNDLES): +1 рол з Roll Luck ×10 / ×99 на ВСІХ підставках (атрибути LuckRoll10 / LuckRoll99, RollService бере найсильніший)
header("LUCKY ROLLS")
do
	local LR = {
		{ key = "LuckRoll10", name = "x10 Lucky Roll", icon = "rbxassetid://" .. (LUCK10_ICON_ID or "116109725516204"), tone = "ffd23a", tile = "yellow" },
		{ key = "LuckRoll99", name = "x99 Lucky Roll", icon = "rbxassetid://" .. (LUCK99_ICON_ID or "90173095287975"), tone = "c99bff", tile = "purple" },
	}
	DESC.LuckRoll10 = { fc(GOLD, "x10 Roll Luck") .. " for 1 roll", "Works on " .. fc(LIME, "all stands") }
	DESC.LuckRoll99 = { fc("ffb3f0", "x99 Roll Luck") .. " for 1 roll", "Works on " .. fc(LIME, "all stands") }
	local w = (CW - GX) / 2
	for i, it in LR do
		local d = MonCfg.Products[it.key]
		it.kind = "product"; it.robux = d.robux; it.id = d.id
		local have
		it.extra = function(card, cw, ch, tx, tw)
			-- конюшина в 1,6 раза більша за звичайну іконку half-картки (у PNG широкі прозорі поля)
			for _, nm in { "Icon", "IconShadow" } do
				local im = card:FindFirstChild(nm)
				if im then im.Size = UDim2.fromOffset(im.Size.X.Offset * 1.6, im.Size.Y.Offset * 1.6) end
			end
			-- під описом (третій рядок), щоб не залазило під кнопку покупки
			have = textAt(card, tx, 98, tw, 20, "", Color3.fromHex(GOLD), 2, { TextXAlignment = LEFT, ZIndex = 7 })
		end
		local c = makeCard(it, PADX + (i - 1) * (w + GX), y, w, 212, "half")
		c.refreshExtra = function()
			local n = tonumber(player:GetAttribute(it.key)) or 0
			if have then have.Text = n > 0 and ("Owned: " .. n) or "" end
		end
	end
	y += 212 + GY + 8
end
header("BUNDLES")
grid(BUNDLES, 1, 150, "wide")
header("TICKETS")
grid(PRODUCTS, 3, 226, "compact")
-- TIME SKIPS (v8, 28.10.2026): одразу гроші = дохід за хвилину (атрибут IncomePerMin, IncomeService) × тривалість.
-- Сума на картці жива (refreshExtra). Чим довший скіп — тим більша вигода (MonetizationConfig.skipBonus). Іконка — Golden Clock.
header("TIME SKIPS")
do
	local SKIP_ICON = "rbxassetid://" .. (SKIP_ICON_ID or "103015355952567")
	local items = {}
	local function fmtMin(m: number): string
		if m < 60 then return m .. " Min" end
		local h = m / 60
		return h .. (h == 1 and " Hour" or " Hours")
	end
	for i, key in MonCfg.TIME_SKIPS do
		local d = MonCfg.Products[key]
		local bonus = math.floor(MonCfg.skipBonus(key) * 100 + 0.5)
		local it = { key = key, kind = "product", name = fmtMin(d.skipMin) .. " Skip", icon = SKIP_ICON,
			tone = i <= 3 and "7ef05a" or (i <= 6 and "ffd23a" or "ff9a3a"), tile = i <= 3 and "green" or (i <= 6 and "yellow" or "orange"),
			robux = d.robux, id = d.id }
		DESC[key] = { " ", bonus > 0 and (fc(LIME, "+" .. bonus .. "%") .. " value") or "Instant Money" }
		local amt
		it.extra = function(card, w, h, tx, tw)
			amt = textAt(card, tx, 57, tw, 20, "", C("7ef05a"), 2.2, { TextXAlignment = LEFT, ZIndex = 7 })
			-- маленькі гроші поверх годинника (правий нижній кут іконки compact: центр 52,82)
			for _, m in { { "SkipMoneyShadow", 4, INK, 0.35, 6 }, { "SkipMoney", 0, WHITE, 0, 7 } } do
				new("ImageLabel", { Name = m[1], BackgroundTransparency = 1, Image = "rbxassetid://103015355952567", ImageColor3 = m[3], ImageTransparency = m[4],
					ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(52 + 24, 82 + 24 + m[2]),
					Size = UDim2.fromOffset(44, 44), Rotation = -8, ZIndex = m[5] }, card)
			end
		end
		table.insert(items, it)
		items[#items].refresh = function()
			local r = tonumber(player:GetAttribute("IncomePerMin")) or 100
			if amt then amt.Text = "+" .. NF.money(r * d.skipMin) end
		end
	end
	local w = (CW - 2 * GX) / 3
	for i, it in items do
		local col = (i - 1) % 3
		local c = makeCard(it, PADX + col * (w + GX), y, w, 226, "compact")
		c.refreshExtra = it.refresh
		if col == 2 or i == #items then y += 226 + GY + 8 end
	end
end
-- DIAMONDS (v9, 28.10.2026): 9 пакетів діамантів за Robux (MonetizationConfig.DIAMOND_PACKS), вигода — diamondBonus
header("DIAMONDS")
do
	local items = {}
	for i, key in MonCfg.DIAMOND_PACKS do
		local d = MonCfg.Products[key]
		local bonus = math.floor(MonCfg.diamondBonus(key) * 100 + 0.5)
		DESC[key] = { NF.full(d.diamonds) .. " Diamonds", bonus > 0 and (fc(LIME, "+" .. bonus .. "%") .. " bonus") or "Instant Diamonds",
			i == #MonCfg.DIAMOND_PACKS and fc(GOLD, "BEST VALUE") or nil }
		table.insert(items, { key = key, kind = "product", noTickets = true, name = NF.full(d.diamonds) .. " Diamonds",
			icon = "rbxassetid://126442692946356", tone = i <= 3 and "6fd2ff" or (i <= 6 and "5c8dff" or "c99bff"),
			tile = i <= 3 and "blue" or (i <= 6 and "blue" or "purple"), robux = d.robux, id = d.id })
	end
	grid(items, 3, 226, "compact")
end
-- COMING SOON: порожньо — Fast Roll і Auto Roll тепер геймпаси (GAMEPASSES); нові заготовки — у FUTURE, тоді секція повернеться
if #FUTURE > 0 then
	header("COMING SOON")
	grid(FUTURE, 3, 226, "compact")
end
list.CanvasSize = UDim2.fromOffset(0, y + PADY)

local function refreshAll()
	swRobux:setColor(currency == "robux" and "green" or "gray")
	swTickets:setColor(currency == "tickets" and "yellow" or "gray")
	balance.Text = currency == "tickets" and ("You have " .. NF.full(tickets()) .. " Tickets · price ×1.25") or "Pay with Robux or switch to Tickets"
	for _, c in cards do refreshCard(c) end
end
swRobux.onClick = function() if currency ~= "robux" then currency = "robux"; refreshAll() end end
swTickets.onClick = function() if currency ~= "tickets" then currency = "tickets"; refreshAll() end end
player.AttributeChanged:Connect(function(a)
	if win.isOpen and (a == "Tickets" or a == "DonateTier" or a == "MutSpeedTier" or a == "ExtraSlots" or a == "IncomePerMin"
		or a == "LuckRoll10" or a == "LuckRoll99" or string.sub(a, 1, 5) == "Pass_") then refreshAll() end
end)
win.onOpen = function() refreshAll(); list.CanvasPosition = Vector2.zero end
-- відкрити магазин одразу на розділі (v9): «+» біля грошей (UIEvents/MoneyPlus) → TIME SKIPS,
-- лічильник діамантів (HUDButton "DiamondsPlus") → DIAMONDS, тікетів ("TicketsPlus") → TICKETS
local function openAt(section: string)
	if not win.isOpen then win.open() end
	local sy = SECTION_Y[section]
	if not sy then return end
	-- CanvasPosition — у пікселях екрана (з UIScale): переводимо з одиниць макета через AbsoluteCanvasSize / CanvasSize
	-- вікно ще «попає» (масштаб 0,85 → 1,05 → 1), тому ставимо ще й після анімації
	local function go()
		local k = list.AbsoluteCanvasSize.Y / math.max(list.CanvasSize.Y.Offset, 1)
		local maxY = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
		list.CanvasPosition = Vector2.new(0, math.clamp((sy - 6) * k, 0, maxY))
	end
	-- CanvasPosition у пікселях задається для поточного масштабу — поки триває «поп», вирівнюємо щокадру (без стрибка)
	go()
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if os.clock() - t0 > 0.4 or not win.isOpen then conn:Disconnect(); return end
		go()
	end)
end
-- ===== закладки зліва (v10): перехід на розділ. Та сама рамка, що й у вікна (RIM + чорна обводка), правий край
-- ховається під вікном (ZIndex нижче за Window) — закладка ніби виростає з рамки. Активна (розділ на екрані) висунута й світліша.
local TABS = {
	{ "MONEY MULTIPLIER", "MONEY", "rbxassetid://103015355952567" },
	{ "GAMEPASSES", "PASSES", "rbxassetid://111200556390804" },
	{ "LUCKY ROLLS", "LUCKY", "rbxassetid://" .. (LUCK10_ICON_ID or "116109725516204") },
	{ "BUNDLES", "PACKS", "rbxassetid://104193388781391" },
	{ "TICKETS", "TICKETS", ICON.ticket },
	{ "TIME SKIPS", "SKIPS", "rbxassetid://" .. (SKIP_ICON_ID or "103015355952567") },
	{ "DIAMONDS", "DIAMONDS", "rbxassetid://126442692946356" },
}
do
	local pop = content.Parent and content.Parent.Parent
	local TAB_W, TAB_H, TAB_GAP, HID = 118, 60, 8, 18 -- HID — скільки сховано під рамкою вікна
	local y0 = WY + 30
	local tabs = {}
	local active = nil
	local function setActive(i)
		if active == i then return end
		active = i
		for j, t in tabs do
			local on = j == i
			tween(t.g, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(WX + HID - TAB_W - (on and 8 or 0), t.y) })
			t.face.BackgroundColor3 = on and C("d9dde2") or C("a9aeb5")
			t.txt.TextColor3 = on and C("ffe14a") or WHITE
		end
	end
	local scrollTw
	local function scrollTo(section)
		local sy = SECTION_Y[section]
		if not sy then return end
		local k = list.AbsoluteCanvasSize.Y / math.max(list.CanvasSize.Y.Offset, 1)
		local maxY = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
		if scrollTw then scrollTw:Cancel() end
		scrollTw = tween(list, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { CanvasPosition = Vector2.new(0, math.clamp((sy - 6) * k, 0, maxY)) })
	end
	for i, t in TABS do
		if SECTION_Y[t[1]] and pop then
			local ty = y0 + (#tabs) * (TAB_H + TAB_GAP)
			local g = new("Frame", { Name = "Tab_" .. t[2], BackgroundTransparency = 1, Position = UDim2.fromOffset(WX + HID - TAB_W, ty), Size = UDim2.fromOffset(TAB_W, TAB_H), ZIndex = 1 }, pop)
			frame(g, 0, 6, TAB_W, TAB_H, BLACK, { Name = "Shadow", BackgroundTransparency = 0.65, ZIndex = 1 })
			local rim = frame(g, 0, 0, TAB_W, TAB_H, WHITE, { Name = "Rim", ZIndex = 1 })
			vgrad(rim, RIM); stroke(rim, INK, 5)
			-- поле закладки — колір панелі вікна, йде під рамку (права обводка схована); fw — видима ширина
			local face = frame(rim, 6, 6, TAB_W, TAB_H - 12, C("a9aeb5"), { Name = "Face", ZIndex = 1 })
			stroke(face, INK, 3)
			local fw = TAB_W - HID - 6
			new("ImageLabel", { Name = "IconShadow", BackgroundTransparency = 1, Image = t[3], ImageColor3 = INK, ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(fw / 2, 18), Size = UDim2.fromOffset(30, 30), Rotation = -8, ZIndex = 1 }, face)
			new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = t[3], ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(fw / 2, 15), Size = UDim2.fromOffset(30, 30), Rotation = -8, ZIndex = 1 }, face)
			local txt = textAt(face, 0, 38, fw, 13, t[2], WHITE, 2, { ZIndex = 1 })
			local hit = new("TextButton", { Name = "Hit", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, g)
			local sc = new("UIScale", {}, g)
			hit.MouseEnter:Connect(function() tween(sc, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }) end)
			hit.MouseLeave:Connect(function() tween(sc, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 }) end)
			local idx = #tabs + 1
			hit.Activated:Connect(function() UISounds.play("tap", 0.08); setActive(idx); scrollTo(t[1]) end)
			tabs[idx] = { g = g, face = face, txt = txt, y = ty, section = t[1] }
		end
	end
	-- активна закладка слідує за прокруткою (розділ, чий заголовок уже вище третини видимої частини)
	local function sync()
		local k = list.AbsoluteCanvasSize.Y / math.max(list.CanvasSize.Y.Offset, 1)
		if k <= 0 then return end
		local pos = list.CanvasPosition.Y / k + list.AbsoluteWindowSize.Y / k / 3
		local best = 1
		for i, t in tabs do if SECTION_Y[t.section] <= pos then best = i end end
		if list.CanvasPosition.Y >= list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y - 2 then best = #tabs end
		if not (scrollTw and scrollTw.PlaybackState == Enum.PlaybackState.Playing) then setActive(best) end
	end
	win.keepInside = function(p: Vector2): boolean
		for _, t in tabs do
			local a, s = t.g.AbsolutePosition, t.g.AbsoluteSize
			if p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y then return true end
		end
		return false
	end
	list:GetPropertyChangedSignal("CanvasPosition"):Connect(sync)
	task.defer(sync)
end
if hudEvent then
	hudEvent.Event:Connect(function(key)
		if key == "DiamondsPlus" then openAt("DIAMONDS") elseif key == "TicketsPlus" then openAt("TICKETS") end
	end)
end
if uiEvents then
	task.spawn(function()
		local mp = uiEvents:WaitForChild("MoneyPlus", 30)
		if mp then mp.Event:Connect(function() openAt("TIME SKIPS") end) end
	end)
	-- табло магазину в ніші (ShopBoard): відкрити на розділі (товар без id — покупка тут, можна тікетами)
	local soa = uiEvents:FindFirstChild("ShopOpenAt") or new("BindableEvent", { Name = "ShopOpenAt" }, uiEvents)
	soa.Event:Connect(function(section) if type(section) == "string" then openAt(section) end end)
end
