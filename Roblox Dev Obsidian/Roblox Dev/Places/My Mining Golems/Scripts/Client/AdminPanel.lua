--!nonstrict
-- AdminPanel — адмін-панель (персонал: owner / admin / mod). Відкриття / закриття — F2 (також X, Esc, клік поза вікном).
-- Де: ServerStorage/AdminUI/AdminPanelGui/AdminPanel (LocalScript). Сервер (AdminService) клонує AdminPanelGui у PlayerGui
--   ЛИШЕ персоналу (AdminConfig + видані ролі), тож у звичайних гравців цього коду немає. Кожну дію сервер перевіряє сам.
--   Роль — атрибут гравця AdminRole: вкладки й секції, недоступні ролі, ховаються (ADMINS — лише owner; видача — admin+).
-- Стиль — як Inventory / Index / Updates: вікно 980 × 528 зі studs (полотно 1080 × 640, Shared/WindowFit), заголовок ADMIN
--   з переливом (червоний → помаранчевий), чорні обводка й тінь; кнопки «стиль A», червона X, поява 0,85 → 1,05 → 1.
--   Мінімум полів вводу: усе, що можна, — кнопками й вибором (голем — вікно з картинками всіх големів, мутація, клас;
--   кількість — кнопки −/+ або швидкі значення 100 / 1K / 10K…; тривалість бану, подій, банера — кнопками).
--   Поле вводу лишається лише для чисел, тексту (оголошення, причина, повідомлення) і пошуку.
-- Вкладки:
--   PLAYERS — гравці на всіх серверах (аватар, сервер); пошук / OPEN за ім'ям або userId (офлайн — профіль зі збереження).
--     Профіль: ресурси; дії TELEPORT (і на інший сервер) / BRING / SPECTATE / FREEZE / UNFREEZE / KICK / COPY ID / BAN HISTORY;
--     особисте повідомлення (банер лише цьому гравцю); RESOURCES — GIVE / TAKE / SET; GIVE GOLEM (вибір з картинками × N);
--     зілля; BAN (1 год … назавжди, модератор — до 1 дня) / UNBAN; големи з іконкою й UID (виділяється для копіювання) + DELETE.
--   GOLEMS — пошук голема за UID: час мінту, запис глобального індексу (власник, історія), де він зараз (сервер, гравець, місце).
--   GLOBAL — оголошення на всі сервери (колір, тривалість); видача всім (ресурс / зілля / голем; + тим, хто зайде протягом
--     15 хв / 1 год / 1 дня); Admin Abuse: ROLL LUCK (рідкість голема) / MUTATION LUCK (шанс мутації) / MONEY
--     × 2 / 3 / 5 / 10 або свій множник (Money — до x1000, удача — без межі) на 5 хв … 3 год, STOP.
--   ME — свій персонаж (лише на цьому сервері): швидкість, стрибок, політ (WASD, Space / Ctrl), noclip, мій профіль.
--   SERVERS — сервери (гравців, аптайм, версія), SHUTDOWN ALL (owner). LOGS — журнал: THIS SERVER (живий) або ALL HISTORY (усі сервери, по днях), фільтри (SUSPECT, адмін, видачі,
--     нові, видалені, дюпи). ADMINS (owner) — персонал: додати за ім'ям / з онлайн-списку (ADMIN / MODERATOR), змінити, прибрати.

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
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local MultiCfg = require(Shared:WaitForChild("MultiConfig"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local holder = script.Parent -- AdminPanelGui (ScreenGui)

-- ===== розміри =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528
local PX, PY, PW, PH = 296, 62, 650, 440 -- сторінка праворуч (у межах вікна)

-- ===== кольори й шрифти =====
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local MUTED = C("b9c0c8")
local GOOD = C("7ef05a")
local BAD = C("ff5a5a")
local GOLD = C("ffd23a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local SLOT_BG = { { 0, "22262c" }, { 1, "15181c" } }
local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right

-- ===== помічники (як у InfoWindows) =====
local U = {}
function U.new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local new = U.new
function U.frame(parent, x, y, w, h, color, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or WHITE, BorderSizePixel = 0 }, parent)
	if props then for k, v in props do f[k] = v end end
	return f
end
local frame = U.frame
function U.corner(o, r) new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
function U.stroke(o, color, th, tr, contextual)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0,
		LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local stroke = U.stroke
function U.cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
function U.vgrad(o, keys) return new("UIGradient", { Color = U.cseq(keys), Rotation = 90 }, o) end
-- текст не вилазить за свою рамку: якщо не влазить — зменшується (не більше size, не менше ~55 %).
-- Мітки з TextTruncate (журнал) лишаються обрізаними «…».
function U.fit(t: TextLabel, size: number)
	if t.TextTruncate ~= Enum.TextTruncate.None then return end
	t.TextScaled = true
	local c = t:FindFirstChildOfClass("UITextSizeConstraint") or new("UITextSizeConstraint", {}, t)
	c.MaxTextSize = math.max(1, math.floor(size + 0.5))
	c.MinTextSize = math.max(8, math.floor(size * 0.55))
end
function U.label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	U.fit(t, size)
	return t
end
local label = U.label
function U.textAt(parent, x, cy, w, size, text, color, sw, props)
	return label(parent, x, cy - size * 0.6, w, size * 1.2, size, text, color, sw, props)
end
local textAt = U.textAt
function U.stud(parent, x, y, cell, fill, shade, edge, edgeTh)
	local s = cell * 0.62
	local o = (cell - s) / 2
	local d = s * 0.12
	local r = s * 0.16
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade, { ZIndex = 1 }); U.corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill, { ZIndex = 2 }); U.corner(st, r)
	if edge then stroke(st, edge, edgeTh or 2) end
end
function U.tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end
local tween = U.tween
function U.isPress(inp: InputObject): boolean
	return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end
function U.cardBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	new("UIGradient", { Rotation = 90, Color = U.cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.4) }) }, f)
	stroke(f, INK, 3)
	return f
end
local cardBg = U.cardBg
function U.slotBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	U.vgrad(f, SLOT_BG); stroke(f, INK, 4)
	return f
end
function U.windowFrame(parent, x, y, w, h, z, shadowDy)
	frame(parent, x, y + shadowDy, w, h, BLACK, { Name = "WindowShadow", BackgroundTransparency = 0.65, ZIndex = z })
	local win = frame(parent, x, y, w, h, WHITE, { Name = "Window", ZIndex = z + 1 })
	U.vgrad(win, RIM); stroke(win, INK, 5)
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
function U.deny()
	if StyleA.deny then StyleA.deny() else UISounds.play("deny", 0.08) end
end
function U.shakeGroup(grp: GuiObject)
	U.deny()
	if grp:GetAttribute("Shaking") then return end
	grp:SetAttribute("Shaking", true)
	local p0 = grp.Position
	task.spawn(function()
		for _, dx in { -10, 10, -7, 7, -3, 0 } do grp.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		grp.Position = p0
		grp:SetAttribute("Shaking", nil)
	end)
end
-- кнопка-група «стиль A»: тінь, основа, напис в одному Frame (тінь — дитина групи)
function U.button(parent, x, y, w, h, text, color, onClick, opt)
	opt = opt or {}
	local grp = new("Frame", { Name = opt.name or (text ~= "" and text or "Button"), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x + w / 2, y + h / 2), Size = UDim2.fromOffset(w, h), ZIndex = opt.z or 4 }, parent)
	local gs = new("UIScale", {}, grp)
	frame(grp, 0, opt.shadowDy or math.max(4, math.floor(h * 0.1)), w, h, BLACK, { Name = "Shadow", BackgroundTransparency = 0.7, ZIndex = 1 })
	local b = StyleA.new(grp, { size = Vector2.new(w, h), position = Vector2.new(0, 0), color = color, clickable = true,
		shine = opt.shine == true, zIndex = 2, icon = opt.icon, iconPad = opt.iconPad, text = text, textSize = opt.textSize, half = opt.half })
	b.root.Name = "Button"
	if b.label then U.fit(b.label, b.label.TextSize) end -- напис не виходить за грань кнопки
	b.scale = gs
	b.group = grp
	b.onClick = onClick
	StyleA.bind(b, { debounce = 0.15, hoverAlways = true, canClick = function() return true end, onClick = function()
		if b.enabled == false then U.shakeGroup(grp) elseif b.onClick then b.onClick(b) end
	end })
	return b
end
local button = U.button
-- темне поле вводу (як слот інвентаря)
function U.input(parent, x, y, w, h, placeholder, opt)
	opt = opt or {}
	local bg = U.slotBg(parent, x, y, w, h, opt.z or 4)
	bg.Name = opt.name or "Input"
	local tb = new("TextBox", { Name = "Box", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0),
		FontFace = opt.mono and MONO or BOLD, TextSize = opt.textSize or 20, TextColor3 = WHITE, PlaceholderText = placeholder or "",
		PlaceholderColor3 = C("7d858f"), Text = opt.text or "", TextXAlignment = LEFT, ClearTextOnFocus = false, ClipsDescendants = true,
		TextEditable = opt.readOnly ~= true, ZIndex = (opt.z or 4) + 1 }, bg)
	return tb, bg
end
local input = U.input
-- вибір одного з кількох: вибраний — свій колір, інші — сірі
function U.choice(parent, x, y, w, h, gap, items, default, onChange, textSize)
	local st = { value = default, btns = {} }
	local function paint()
		for _, it in items do
			local b = st.btns[it.key]
			b:setColor(st.value == it.key and (it.color or "blue") or "gray")
		end
	end
	for i, it in items do
		local b = button(parent, x + (i - 1) * (w + gap), y, w, h, it.text, "gray", function()
			st.value = it.key
			paint()
			if onChange then onChange(it.key) end
		end, { textSize = textSize })
		st.btns[it.key] = b
	end
	paint()
	function st.set(k) st.value = k; paint() end
	return st
end
function U.section(parent, x, y, text)
	return label(parent, x, y, 600, 24, 18, text, GOLD, 2.4, { TextXAlignment = LEFT, ZIndex = 4 })
end
function U.scroller(parent, x, y, w, h, name)
	return new("ScrollingFrame", { Name = name or "Scroll", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C("2a2e35"), ScrollBarImageTransparency = 0.1, CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 4 }, parent)
end
-- відступи всередині прокрутки: рамки, тіні й збільшення кнопок при наведенні не обрізаються краєм (і смуга прокрутки не налазить)
local SCROLL_PAD = { l = 8, t = 6, r = 18, b = 10 }
do
	local raw = U.scroller
	U.scroller = function(...)
		local sf = raw(...)
		new("UIPadding", { PaddingLeft = UDim.new(0, SCROLL_PAD.l), PaddingTop = UDim.new(0, SCROLL_PAD.t),
			PaddingRight = UDim.new(0, SCROLL_PAD.r), PaddingBottom = UDim.new(0, SCROLL_PAD.b) }, sf)
		return sf
	end
end
function U.clear(o: Instance)
	for _, c in o:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
end
function U.num(n: any): string
	n = tonumber(n) or 0
	-- великі числа (від 1 млрд) — коротко, як у грі: 1.5B, 2Qa, 1Qi… (повний запис 1e18 нечитабельний)
	if math.abs(n) >= 1e9 then return (n < 0 and "-" or "") .. NumberFormat.short(math.abs(n)) end
	local s = tostring(math.floor(math.abs(n)))
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then out = string.sub(out, 2) end
	return (n < 0 and "-" or "") .. out
end
function U.dur(sec: number): string
	sec = math.max(0, math.floor(sec or 0))
	if sec >= 3600 then return string.format("%d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60) end
	return string.format("%d:%02d", sec // 60, sec % 60)
end
function U.golemName(kind, mut): (string, Color3)
	local def = Catalog.GOLEMS[kind]
	local mu = Catalog.MUTATIONS[(tonumber(mut) or 0) + 1]
	local nm = (def and def.name) or tostring(kind)
	if mu and mu.key ~= "Normal" then nm = mu.key .. " " .. nm end
	return nm, (mu and mu.color) or WHITE
end

-- ===== сервер =====
local Action = nil
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 60)
	Action = r and r:WaitForChild("AdminAction", 60)
end)
local function invoke(action: string, arg: any): any
	local t0 = os.clock()
	while not Action and os.clock() - t0 < 5 do task.wait(0.1) end
	if not Action then return { ok = false, error = "No connection" } end
	local ok, res = pcall(Action.InvokeServer, Action, action, arg)
	if ok and type(res) == "table" then return res end
	return { ok = false, error = ok and "No answer" or tostring(res) }
end

-- =====================================================================
-- ===== вікно =====
-- =====================================================================
local gui = new("ScreenGui", { Name = "AdminWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 30, Enabled = true }, playerGui)
holder.Destroying:Connect(function() gui:Destroy() end)
local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local _, content = U.windowFrame(pop, WX, WY, WW, WH, 1, 14)

-- заголовок ADMIN: перелив червоний → помаранчевий, відблиск; обводка й тінь — чорні
local W = { isOpen = false }
do
	local TITLE_X = WX + 34
	textAt(pop, TITLE_X, WY - 8 + 7, 600, 96, "ADMIN", INK, 9, { TextXAlignment = LEFT, ZIndex = 3 })
	local title = textAt(pop, TITLE_X, WY - 8, 600, 96, "ADMIN", WHITE, 8, { TextXAlignment = LEFT, ZIndex = 4 })
	local titleGrad = new("UIGradient", { Rotation = 0 }, title)
	local titleShine = textAt(pop, TITLE_X, WY - 8, 600, 96, "ADMIN", WHITE, 0, { TextXAlignment = LEFT, ZIndex = 5 })
	local shineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
			NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
			NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
	local P = { C("ffe1d6"), C("ff7a45"), C("e8243c"), C("ff7a45") }
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
	local tw = TweenService:Create(shineGrad, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
	tw.Completed:Connect(function() shineGrad.Offset = Vector2.new(-1.3, 0) end)
	task.spawn(function() while true do task.wait(3 + math.random() * 3); if modalRoot.Visible then tw:Play() end end end)
end
local closeBtn = button(pop, WX + WW - 70, WY - 34, 84, 84, "", "red", nil,
	{ name = "Close", shadowDy = 8, icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

-- рядок статусу (результат останньої дії)
local status = label(content, 330, 20, 560, 34, 20, "", WHITE, 2.4, { TextXAlignment = RIGHT, ZIndex = 6 })
local statusToken = 0
local function setStatus(text: string, ok: boolean?)
	statusToken += 1
	local my = statusToken
	status.Text = text
	status.TextColor3 = ok == false and BAD or (ok == true and GOOD or WHITE)
	local sc = status:FindFirstChildOfClass("UIScale") or new("UIScale", {}, status)
	sc.Scale = 0.8
	tween(sc, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	if ok ~= nil then
		pcall(UISounds.play, ok and "claim" or "deny", 0.1)
		task.delay(6, function() if statusToken == my then status.Text = "" end end)
	end
end
local function result(res: any, okText: string?)
	if res and res.ok then setStatus(res.text or okText or "Done", true) else setStatus((res and res.error) or "Error", false) end
	return res and res.ok
end

-- вікно підтвердження (у межах панелі)
local confirmLayer = frame(content, 0, 0, WW, WH, BLACK, { Name = "Confirm", BackgroundTransparency = 0.35, Visible = false, ZIndex = 40, Active = true })
local confirmCard = U.slotBg(confirmLayer, (WW - 560) / 2, (WH - 240) / 2, 560, 240, 41)
local confirmText = label(confirmCard, 20, 16, 520, 130, 26, "", WHITE, 2.6, { TextWrapped = true, ZIndex = 42 })
local confirmFn = nil
local confirmYes = button(confirmCard, 40, 160, 220, 60, "YES", "red", function()
	confirmLayer.Visible = false
	local f = confirmFn
	confirmFn = nil
	if f then task.spawn(f) end
end, { z = 42 })
button(confirmCard, 300, 160, 220, 60, "CANCEL", "gray", function()
	confirmLayer.Visible = false
	confirmFn = nil
end, { z = 42 })
local function confirm(text: string, fn, yesText: string?, yesColor: string?)
	confirmText.Text = text
	confirmYes:setText(yesText or "YES")
	confirmYes:setColor(yesColor or "red")
	confirmFn = fn
	confirmLayer.Visible = true
end

-- ===== відкриття / закриття =====
local function fit()
	WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WX, winY = WY, winW = WW, winH = WH })
end
do
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
end
local animToken = 0
local function escKey(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	task.defer(function()
		if confirmLayer.Visible then confirmLayer.Visible = false; confirmFn = nil elseif W.isOpen then W.close() end
	end)
	return Enum.ContextActionResult.Sink
end
function W.open()
	if W.isOpen then return end
	W.isOpen = true
	WindowManager.opened("Admin")
	animToken += 1
	local my = animToken
	fit()
	if W.onOpen then W.onOpen() end
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("AdminEsc", escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
end
function W.close()
	if not W.isOpen then return end
	W.isOpen = false
	confirmLayer.Visible = false
	pcall(function() CAS:UnbindAction("AdminEsc") end)
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
	end)
end
closeBtn.onClick = function() W.close() end
WindowManager.register("Admin", function() return W.isOpen end, function() W.close() end)
backdrop.InputBegan:Connect(function(inp)
	if not U.isPress(inp) then return end
	-- закриває лише клік ПОЗА вікном (заголовок і X над рамкою — теж вікно); без GetGuiInset
	local p = Vector2.new(inp.Position.X, inp.Position.Y)
	local a, s = content.AbsolutePosition, content.AbsoluteSize
	local top = s.Y * 0.18
	if p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y - top and p.Y <= a.Y + s.Y then return end
	W.close()
end)
UIS.InputBegan:Connect(function(inp, processed)
	if inp.KeyCode == Enum.KeyCode.F2 and not UIS:GetFocusedTextBox() then
		if W.isOpen then W.close() else W.open() end
	end
end)

-- =====================================================================
-- ===== вкладки =====
-- =====================================================================
local LEVEL = { mod = 1, admin = 2, owner = 3 }
local function myLevel(): number return LEVEL[player:GetAttribute("AdminRole") or ""] or 0 end
local pages = {}
local onShow = {} -- key → функція при відкритті вкладки (у Frame не можна класти свої поля)
local tabs = {}
local TABS = {
	{ key = "players", text = "PLAYERS", color = "blue", need = 1 },
	{ key = "golems", text = "GOLEMS", color = "purple", need = 1 },
	{ key = "global", text = "GLOBAL", color = "orange", need = 1 },
	{ key = "me", text = "ME", color = "green", need = 1 },
	{ key = "servers", text = "SERVERS", color = "yellow", need = 1 },
	{ key = "logs", text = "LOGS", color = "gray", need = 1 },
	{ key = "admins", text = "ADMINS", color = "red", need = 3 },
}
local TAB_X, TAB_W, TAB_H, TAB_G = 30, 222, 56, 8
local selTab = nil
local function layoutTabs()
	local i = 0
	for _, t in TABS do
		local b = tabs[t.key]
		local vis = myLevel() >= t.need
		b.group.Visible = vis
		if vis then
			b.baseY = PY + i * (TAB_H + TAB_G) + TAB_H / 2
			b.group.Position = UDim2.fromOffset(TAB_X + TAB_W / 2 + (selTab == t.key and 12 or 0), b.baseY)
			i += 1
		end
	end
end
local function selectTab(key: string)
	selTab = key
	for _, t in TABS do
		local b = tabs[t.key]
		local on = t.key == key
		b:setColor(on and (t.color == "gray" and "blue" or t.color) or "gray")
		pages[t.key].Visible = on
	end
	layoutTabs()
	if onShow[key] then task.spawn(onShow[key]) end
end
for _, t in TABS do
	local b = button(content, TAB_X, PY, TAB_W, TAB_H, t.text, "gray", function() selectTab(t.key) end, { textSize = 22 })
	tabs[t.key] = b
	pages[t.key] = frame(content, PX, PY, PW, PH, nil, { Name = "Page_" .. t.key, BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
end
-- секції, що потребують рівня admin (видача, події): ховаються в модераторів
local gated = {}
local function gate(o: GuiObject, need: number) table.insert(gated, { o = o, need = need }); o.Visible = myLevel() >= need end
player:GetAttributeChangedSignal("AdminRole"):Connect(function()
	for _, g in gated do if g.o.Parent then g.o.Visible = myLevel() >= g.need end end
	layoutTabs()
	if selTab and tabs[selTab] and not tabs[selTab].group.Visible then selectTab("players") end
end)

-- ===== дрібні елементи =====
local CW = PW - SCROLL_PAD.l - SCROLL_PAD.r -- ширина вмісту в сторінці з прокруткою (без відступів і смуги)
-- іконка голема: 3D-модель (ItemViewport), якщо є, інакше PNG з каталогу
function U.golemIcon(parent, x, y, size, kind, cls, z)
	local l = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size),
		ScaleType = Enum.ScaleType.Fit, Image = Catalog.icon(kind), ZIndex = z or 6 }, parent)
	pcall(ItemViewport.set, l, ItemViewport.golemKey(kind, cls))
	return l
end
function U.setGolemIcon(l: ImageLabel, kind, cls)
	l.Image = Catalog.icon(kind)
	pcall(ItemViewport.set, l, ItemViewport.golemKey(kind, cls))
end
-- кнопки швидкого вибору числа: заповнюють поле
function U.presets(parent, x, y, w, h, gap, values, box, textSize)
	for i, v in values do
		button(parent, x + (i - 1) * (w + gap), y, w, h, v[1], "gray", function() box.Text = tostring(v[2]) end, { textSize = textSize or 16, half = true })
	end
end
-- [-] [число] [+]
function U.stepper(parent, x, y, w, h, init, minV, maxV)
	local st = {}
	local box = input(parent, x + h + 6, y, w - 2 * (h + 6), h, "", { text = tostring(init) })
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.Position = UDim2.fromOffset(4, 0) -- у вузькому полі число по центру, без великих бокових відступів
	box.Size = UDim2.new(1, -8, 1, 0)
	box.TextSize = math.floor(h * 0.48)
	local function get() return math.clamp(math.floor(tonumber(box.Text) or init), minV, maxV) end
	button(parent, x, y, h, h, "-", "red", function() box.Text = tostring(math.max(minV, get() - 1)) end, { textSize = 26 })
	button(parent, x + w - h, y, h, h, "+", "green", function() box.Text = tostring(math.min(maxV, get() + 1)) end, { textSize = 26 })
	box.FocusLost:Connect(function() box.Text = tostring(get()) end)
	st.get = get
	st.box = box
	return st
end
local function mutColor(m): Color3
	local mu = Catalog.MUTATIONS[(tonumber(m) or 0) + 1]
	local c = (mu and mu.color) or WHITE
	local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
	return lum < 0.45 and C("e6e9ef") or c -- Secret (темний) — світлий текст з чорною обводкою
end
local function golemItem(sel) -- { kind, mut, cls } → рядок для сервера
	return sel.kind .. "@" .. tostring(sel.mut) .. ":" .. sel.cls
end

-- =====================================================================
-- ===== вибір голема (вікно з картинками) =====
-- =====================================================================
local Picker = {}
do
	local layer = frame(content, 0, 0, WW, WH, BLACK, { Name = "GolemPicker", BackgroundTransparency = 0.35, Visible = false, ZIndex = 50, Active = true })
	local card = U.slotBg(layer, 30, 24, 920, 480, 51) -- непрозора підкладка (крізь неї не видно сторінку)
	label(card, 18, 10, 560, 36, 26, "CHOOSE GOLEM", GOLD, 3, { TextXAlignment = LEFT, ZIndex = 52 })
	local grid = U.scroller(card, 14, 54, 590, 412, "Grid")
	grid.ZIndex = 52
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	new("UIGridLayout", { CellSize = UDim2.fromOffset(106, 128), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local st = { kind = "stone", mut = 0, cls = "miner", cb = nil }
	local cells = {}
	local RX = 618
	local prevBg = cardBg(card, RX, 14, 288, 110, 52)
	local prevIcon = U.golemIcon(prevBg, 94, 5, 100, "stone", "miner", 53)
	local prevName = label(card, RX, 126, 288, 28, 22, "", WHITE, 2.6, { ZIndex = 53 })
	local prevRar = label(card, RX, 152, 288, 20, 14, "", MUTED, 1.6, { ZIndex = 53 })
	local mutBtns, clsBtns = {}, {}
	local function paint()
		local def = Catalog.GOLEMS[st.kind]
		U.setGolemIcon(prevIcon, st.kind, st.cls)
		prevName.Text = U.golemName(st.kind, st.mut)
		prevName.TextColor3 = mutColor(st.mut)
		prevRar.Text = string.upper(def and def.rarity or "") .. ((def and def.exclusive) and (" · " .. string.upper(def.howShort and def.howShort.miner or tostring(def.exclusive))) or (" · 1 in " .. U.num(def and def.odds or 1)))
		prevRar.TextColor3 = Catalog.rarityColor(def and def.rarity)
		for id, c in cells do
			c.stroke.Color = id == st.kind and GOLD or INK
			c.stroke.Thickness = id == st.kind and 5 or 3
		end
		for i, b in mutBtns do b:setColor(i - 1 == st.mut and "blue" or "gray") end
		for k, b in clsBtns do b:setColor(k == st.cls and "green" or "gray") end
	end
	-- звичайні големи (ORDER), потім усі ексклюзиви (EXCLUSIVES: Mushroom, големи Exclusive Case; 02.11.2026)
	local pickIds = table.clone(Catalog.ORDER)
	for _, id in Catalog.EXCLUSIVES or {} do if Catalog.GOLEMS[id] and not table.find(pickIds, id) then table.insert(pickIds, id) end end
	for i, id in pickIds do
		local def = Catalog.GOLEMS[id]
		local rc = Catalog.rarityColor(def.rarity)
		local cell = new("ImageButton", { Name = id, BackgroundColor3 = WHITE, AutoButtonColor = false, LayoutOrder = i, ZIndex = 53 }, grid)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(rc:Lerp(BLACK, 0.35), rc:Lerp(BLACK, 0.75)) }, cell)
		local s = stroke(cell, INK, 3)
		U.golemIcon(cell, 13, 4, 80, id, "miner", 54)
		label(cell, 2, 86, 102, 22, 14, string.gsub(def.name, " Golem$", ""), WHITE, 1.8, { ZIndex = 55 })
		label(cell, 2, 106, 102, 16, 11, string.upper(def.rarity), rc:Lerp(WHITE, 0.35), 1.4, { ZIndex = 55 })
		cells[id] = { stroke = s }
		cell.Activated:Connect(function()
			StyleA.tap()
			st.kind = id
			paint()
		end)
	end
	label(card, RX, 174, 288, 20, 14, "MUTATION", MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 53 })
	for i, mu in Catalog.MUTATIONS do
		local col, row = (i - 1) % 2, (i - 1) // 2
		local b = button(card, RX + col * 146, 196 + row * 40, 142, 34, string.upper(mu.key), "gray", function()
			st.mut = i - 1
			paint()
		end, { z = 53, textSize = 16 })
		b.label.TextColor3 = mutColor(i - 1)
		mutBtns[i] = b
	end
	label(card, RX, 358, 288, 18, 14, "CLASS", MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 53 })
	for i, k in { "miner", "carrier", "warrior" } do
		clsBtns[k] = button(card, RX + (i - 1) * 97, 378, 93, 34, string.upper(k), "gray", function()
			st.cls = k
			paint()
		end, { z = 53, textSize = 14 })
	end
	-- CANCEL / SELECT — унизу праворуч
	button(card, RX, 424, 136, 44, "CANCEL", "gray", function() layer.Visible = false end, { z = 53, textSize = 18 })
	button(card, RX + 146, 424, 142, 44, "SELECT", "green", function()
		layer.Visible = false
		if st.cb then st.cb({ kind = st.kind, mut = st.mut, cls = st.cls }) end
	end, { z = 53, textSize = 18 })
	function Picker.open(init, cb)
		if init then st.kind, st.mut, st.cls = init.kind or st.kind, init.mut or st.mut, init.cls or st.cls end
		st.cb = cb
		paint()
		layer.Visible = true
	end
	function Picker.close() layer.Visible = false end
	Picker.layer = layer
end
-- ===== вибір геймпаса (вікно з іконками, як вибір голема): ALL — усі геймпаси; OWNED — уже є в гравця =====
local PassPicker = {}
-- особливі пункти вибору (v2, 28.10.2026) — не геймпаси, а продукти: драбини «до ступеня» (x2 Money, Fast Mutations;
-- ступінь — вікно LevelPicker) і Lucky Roll x10 / x99 (кількість). Сервер: what = MoneyTier | MutTier | LuckRoll10 | LuckRoll99.
local SPECIAL = {
	["@MoneyTier"] = { name = "x2 Money (levels)", icon = "rbxassetid://103015355952567", tone = "7ef05a", what = "MoneyTier", level = true },
	["@MutTier"] = { name = "Fast Mutations (levels)", icon = "rbxassetid://90173095287975", tone = "c99bff", what = "MutTier", level = true },
	["@LuckRoll10"] = { name = "x10 Lucky Roll", icon = "rbxassetid://124578338510174", tone = "ffd23a", what = "LuckRoll10" },
	["@LuckRoll99"] = { name = "x99 Lucky Roll", icon = "rbxassetid://120776574619004", tone = "c99bff", what = "LuckRoll99" },
}
local SPECIAL_ORDER = { "@MoneyTier", "@MutTier", "@LuckRoll10", "@LuckRoll99" }
local function passName(key: string): string
	if key == "*" then return "ALL GAMEPASSES" end
	if SPECIAL[key] then return SPECIAL[key].name end
	local d = MonCfg.Passes[key]
	return d and d.name or tostring(key)
end
local function passIcon(key: string): string
	if key == "*" then return "rbxassetid://91791061262477" end -- іконка Shop
	if SPECIAL[key] then return SPECIAL[key].icon end
	local d = MonCfg.Passes[key]
	return d and d.icon or ""
end
-- ступені драбини: { { lv, "x512" }, … }
local function tierLevels(what: string): { any }
	local out = {}
	local function mx(m: number): string return "x" .. (m >= 1e5 and NumberFormat.short(m) or U.num(m)) end
	if what == "MoneyTier" then
		for i = 1, MultiCfg.maxDonateTier() do table.insert(out, { i, mx(MultiCfg.donateMult(i)) }) end
	else
		for i, t in MonCfg.MUT_SPEED_TIERS do table.insert(out, { i, mx(t.mult) }) end
	end
	return out
end
local function levelText(what: string, lv: number): string
	if not lv or lv <= 0 then return "none" end
	for _, l in tierLevels(what) do if l[1] == lv then return l[2] end end
	return "?"
end
do
	local layer = frame(content, 0, 0, WW, WH, BLACK, { Name = "PassPicker", BackgroundTransparency = 0.35, Visible = false, ZIndex = 50, Active = true })
	local card = U.slotBg(layer, 170, 60, 640, 408, 51)
	label(card, 18, 10, 500, 36, 26, "CHOOSE GAMEPASS", GOLD, 3, { TextXAlignment = LEFT, ZIndex = 52 })
	local grid = U.scroller(card, 14, 54, 612, 290, "Grid")
	grid.ZIndex = 52
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	new("UIGridLayout", { CellSize = UDim2.fromOffset(136, 136), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local st = { key = "*", cb = nil, owned = {} }
	local cells = {}
	local keys = { "*" }
	local tmp = {}
	for k, d in MonCfg.Passes do table.insert(tmp, { k = k, o = d.order or 99 }) end
	table.sort(tmp, function(a, b) return a.o < b.o end)
	for _, t in tmp do table.insert(keys, t.k) end
	for _, k in SPECIAL_ORDER do table.insert(keys, k) end
	local function paint()
		for k, c in cells do
			c.stroke.Color = k == st.key and GOLD or INK
			c.stroke.Thickness = k == st.key and 5 or 3
			c.own.Visible = k ~= "*" and st.owned[k] == true
		end
	end
	for i, k in keys do
		local d = MonCfg.Passes[k] or SPECIAL[k]
		local tone = d and C(d.tone) or C("ff5a6e")
		local cell = new("ImageButton", { Name = k, BackgroundColor3 = WHITE, AutoButtonColor = false, LayoutOrder = i, ZIndex = 53 }, grid)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(tone:Lerp(BLACK, 0.3), tone:Lerp(BLACK, 0.7)) }, cell)
		local s = stroke(cell, INK, 3)
		new("ImageLabel", { BackgroundTransparency = 1, Image = passIcon(k), ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(28, 10),
			Size = UDim2.fromOffset(80, 80), ZIndex = 54 }, cell)
		label(cell, 4, 92, 128, 38, 15, k == "*" and "ALL" or passName(k), WHITE, 1.8, { TextWrapped = true, ZIndex = 55 })
		local own = label(cell, 4, 4, 124, 18, 12, "OWNED", GOOD, 1.6, { TextXAlignment = RIGHT, ZIndex = 55, Visible = false })
		cells[k] = { stroke = s, own = own }
		cell.Activated:Connect(function() StyleA.tap(); st.key = k; paint() end)
	end
	button(card, 640 - 14 - 300, 354, 140, 44, "CANCEL", "gray", function() layer.Visible = false end, { z = 53, textSize = 18 })
	button(card, 640 - 14 - 150, 354, 150, 44, "SELECT", "green", function()
		layer.Visible = false
		if st.cb then st.cb(st.key) end
	end, { z = 53, textSize = 18 })
	function PassPicker.open(init, owned, cb)
		st.key = init or st.key
		st.cb = cb
		st.owned = {}
		for _, k in owned or {} do st.owned[k] = true end
		paint()
		layer.Visible = true
	end
	PassPicker.layer = layer
end
-- ===== вибір ступеня драбини (x2 Money / Fast Mutations): «до ступеня», той самий стиль, що й вибір геймпаса =====
local LevelPicker = {}
do
	local layer = frame(content, 0, 0, WW, WH, BLACK, { Name = "LevelPicker", BackgroundTransparency = 0.35, Visible = false, ZIndex = 60, Active = true })
	local card = U.slotBg(layer, 170, 60, 640, 408, 61)
	local title = label(card, 18, 10, 604, 36, 24, "GIVE UP TO LEVEL", GOLD, 3, { TextXAlignment = LEFT, ZIndex = 62 })
	local grid = U.scroller(card, 14, 54, 612, 290, "Grid")
	grid.ZIndex = 62
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	new("UIGridLayout", { CellSize = UDim2.fromOffset(110, 74), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local st = { cb = nil, sel = 1, strokes = {} }
	local function paint()
		for lv, s in st.strokes do s.Color = lv == st.sel and GOLD or INK; s.Thickness = lv == st.sel and 5 or 3 end
	end
	button(card, 640 - 14 - 300, 354, 140, 44, "CANCEL", "gray", function() layer.Visible = false end, { z = 63, textSize = 18 })
	button(card, 640 - 14 - 150, 354, 150, 44, "SELECT", "green", function()
		layer.Visible = false
		if st.cb then st.cb(st.sel) end
	end, { z = 63, textSize = 18 })
	function LevelPicker.open(what: string, init: number?, cb)
		for _, c in grid:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		st.strokes = {}
		st.cb = cb
		st.sel = init or 1
		title.Text = (what == "MoneyTier" and "x2 MONEY" or "FAST MUTATIONS") .. " — GIVE UP TO LEVEL"
		local sp = SPECIAL["@" .. what]
		local tone = C(sp and sp.tone or "7ef05a")
		for _, l in tierLevels(what) do
			local lv = l[1]
			local cell = new("ImageButton", { Name = "L" .. lv, BackgroundColor3 = WHITE, AutoButtonColor = false, LayoutOrder = lv, ZIndex = 63 }, grid)
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(tone:Lerp(BLACK, 0.3), tone:Lerp(BLACK, 0.7)) }, cell)
			st.strokes[lv] = stroke(cell, INK, 3)
			new("ImageLabel", { BackgroundTransparency = 1, Image = sp and sp.icon or "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(6, 6),
				Size = UDim2.fromOffset(30, 30), ZIndex = 64 }, cell)
			label(cell, 38, 6, 66, 30, 13, "LV " .. lv, MUTED, 1.4, { TextXAlignment = RIGHT, ZIndex = 64 })
			local t = label(cell, 4, 38, 102, 30, 22, l[2], WHITE, 2, { ZIndex = 64 })
			U.fit(t, 22)
			cell.Activated:Connect(function() StyleA.tap(); st.sel = lv; paint() end)
		end
		paint()
		layer.Visible = true
	end
end
-- поле «вибраний геймпас»: іконка й назва, клік — вікно вибору
function U.passField(parent, x, y, w, h, sel, ownedList, onChange)
	local bg = U.slotBg(parent, x, y, w, h, 4)
	local btn = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 7 }, bg)
	local icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(8, 4),
		Size = UDim2.fromOffset(h - 8, h - 8), ZIndex = 5 }, bg)
	local nm = label(bg, h + 8, 4, w - h - 16, h * 0.5, 18, "", WHITE, 2, { TextXAlignment = LEFT, ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
	local sub = label(bg, h + 8, h * 0.5, w - h - 16, h * 0.4, 13, "", MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 6 })
	local own, n = {}, 0
	for _, k in ownedList or {} do own[k] = true; n += 1 end
	local function paint()
		icon.Image = passIcon(sel.key)
		nm.Text = passName(sel.key)
		if SPECIAL[sel.key] then
			sub.Text = (SPECIAL[sel.key].level and "choose level" or "choose amount") .. " · click to change"
			sub.TextColor3 = MUTED
		else
			sub.Text = (sel.key == "*" and (n .. " owned") or (own[sel.key] and "OWNED" or "not owned")) .. " · click to change"
			sub.TextColor3 = (sel.key ~= "*" and own[sel.key]) and GOOD or MUTED
		end
	end
	btn.Activated:Connect(function()
		StyleA.tap()
		PassPicker.open(sel.key, ownedList, function(k) sel.key = k; paint(); if onChange then onChange(k) end end)
	end)
	paint()
	return bg
end

-- поле «вибраний голем»: картка з іконкою й назвою, клік — вікно вибору
function U.golemField(parent, x, y, w, h, sel, onChange)
	local bg = U.slotBg(parent, x, y, w, h, 4)
	local btn = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 7 }, bg)
	local icon = U.golemIcon(bg, 6, 2, h - 4, sel.kind, sel.cls, 5)
	local nm = label(bg, h + 8, 4, w - h - 16, h * 0.5, 18, "", WHITE, 2, { TextXAlignment = LEFT, ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
	local sub = label(bg, h + 8, h * 0.5, w - h - 16, h * 0.4, 13, "", MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 6 })
	local function paint()
		U.setGolemIcon(icon, sel.kind, sel.cls)
		nm.Text = U.golemName(sel.kind, sel.mut)
		nm.TextColor3 = mutColor(sel.mut)
		sub.Text = string.upper(sel.cls) .. " · click to change"
	end
	btn.Activated:Connect(function()
		StyleA.tap()
		Picker.open(sel, function(r)
			sel.kind, sel.mut, sel.cls = r.kind, r.mut, r.cls
			paint()
			if onChange then onChange(sel) end
		end)
	end)
	paint()
	return bg
end

-- =====================================================================
-- ===== стеження (spectate) =====
-- =====================================================================
local Spectate = {}
do
	-- 07.11.2026 v2: SPECTATE з подробицями (гравець має бути на цьому сервері). Сервер (AdminService SpecStart / SpecStop) ставить
	--   цілі атрибут Spectated, її клієнт (StarterPlayerScripts/SpecFeedClient) шле камеру, курсор, відкриті вікна й кліки → Remotes/SpecFeed → сюди.
	--   Панелька: STOP, FOLLOW CAM (камера дивиться туди ж, куди гравець; вимикається), баланс наживо, відкриті вікна, останні кліки;
	--   на екрані — курсор гравця (кружечок) і спалах у місці кліку.
	local BW = 640
	local bar = new("Frame", { Name = "SpectateBar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(BW, 236), Visible = false, ZIndex = 20 }, gui)
	local barScale = new("UIScale", {}, bar)
	cardBg(bar, 0, 0, BW, 236, 20)
	local txt = label(bar, 14, 6, BW - 200, 34, 22, "", WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 21 })
	button(bar, BW - 176, 8, 162, 44, "STOP", "red", function() Spectate.stop() end, { z = 22, textSize = 20 })
	local bal = label(bar, 14, 44, BW - 28, 26, 18, "", GOLD, 2, { TextXAlignment = LEFT, ZIndex = 21 })
	local followBtn
	local follow = true
	followBtn = button(bar, 14, 76, 230, 40, "FOLLOW CAM: ON", "green", function()
		follow = not follow
		followBtn:setText(follow and "FOLLOW CAM: ON" or "FOLLOW CAM: OFF")
		followBtn:setColor(follow and "green" or "gray")
		if not follow then Spectate._free() end
	end, { z = 22, textSize = 16 })
	local winL = label(bar, 256, 76, BW - 270, 40, 15, "Windows: —", WHITE, 1.6, { TextXAlignment = LEFT, ZIndex = 21, TextWrapped = true })
	local clicksL = label(bar, 14, 122, BW - 28, 108, 15, "", C("cfe3ff"), 1.6, { TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, TextWrapped = true })
	-- шар курсора й кліків (повний екран)
	local ov = new("ScreenGui", { Name = "SpecOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 95, Enabled = false }, player:WaitForChild("PlayerGui"))
	local cursor = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = C("ffd23a"), BackgroundTransparency = 0.35, Visible = false }, ov)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, cursor)
	new("UIStroke", { Color = INK, Thickness = 3 }, cursor)
	local target: Player? = nil
	local camData = nil
	local lastFeed = 0
	local clicks = {}
	local conn, rconn, fconn
	local cam = workspace.CurrentCamera
	function Spectate._free()
		cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
	end
	local function flash(x, y)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 }, ov)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
		local st = new("UIStroke", { Color = C("ff5a5a"), Thickness = 5 }, f)
		TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(90, 90) }):Play()
		TweenService:Create(st, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		task.delay(0.55, function() f:Destroy() end)
	end
	local feedEv = RS:WaitForChild("Remotes"):WaitForChild("SpecFeed", 30)
	if feedEv then
		feedEv.OnClientEvent:Connect(function(uid, d)
			if not target or target.UserId ~= uid or type(d) ~= "table" then return end
			lastFeed = os.clock()
			if d.cam then camData = d.cam end
			if d.m then cursor.Position = UDim2.fromScale(d.m[1], d.m[2]); cursor.Visible = true end
			if d.win then winL.Text = "Windows: " .. (#d.win > 0 and table.concat(d.win, ", ") or "—") end
			if d.click then
				table.insert(clicks, 1, os.date("%H:%M:%S") .. "  clicked  " .. tostring(d.click.text))
				while #clicks > 4 do table.remove(clicks) end
				clicksL.Text = table.concat(clicks, "\n")
				flash(d.click.x, d.click.y)
			end
		end)
	end
	function Spectate.start(t: Player)
		local hum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
		if not hum then setStatus("Player has no character", false); return end
		local res = invoke("SpecStart", { u = t.UserId })
		if not res.ok then result(res); return end
		target = t
		camData = nil; table.clear(clicks); clicksL.Text = "Clicks will appear here"; winL.Text = "Windows: —"
		cam = workspace.CurrentCamera
		cam.CameraSubject = hum
		txt.Text = "SPECTATING @" .. t.Name
		barScale.Scale = fitScale.Scale
		bar.Visible = true
		ov.Enabled = true
		if conn then conn:Disconnect() end
		conn = t.CharacterAdded:Connect(function(ch)
			local h = ch:WaitForChild("Humanoid", 10)
			if h and bar.Visible and not follow then workspace.CurrentCamera.CameraSubject = h end
		end)
		if rconn then rconn:Disconnect() end
		local acc = 0
		rconn = RunService.RenderStepped:Connect(function(dt)
			if not target or target.Parent ~= Players then Spectate.stop(); return end
			-- баланс наживо (атрибути гравця видно всім клієнтам)
			acc += dt
			if acc > 0.2 then
				acc = 0
				local a = function(n) return tonumber(target:GetAttribute(n)) or 0 end
				bal.Text = "$" .. U.num(a("Money")) .. "   ·   Diamonds " .. U.num(a("Diamonds")) .. "   ·   Tickets " .. U.num(a("Tickets"))
					.. "   ·   Rebirths " .. U.num(a("Rebirths"))
				if os.clock() - lastFeed > 3 then cursor.Visible = false end
			end
			-- камера гравця
			cam = workspace.CurrentCamera
			if follow and camData and os.clock() - lastFeed < 3 then
				if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
				local p = Vector3.new(camData[1], camData[2], camData[3])
				local l = Vector3.new(camData[4], camData[5], camData[6])
				if l.Magnitude > 0.01 then
					cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(p, p + l.Unit), math.clamp(dt * 12, 0, 1))
				end
			elseif cam.CameraType == Enum.CameraType.Scriptable then
				Spectate._free()
			end
		end)
		W.close()
	end
	function Spectate.stop()
		if conn then conn:Disconnect(); conn = nil end
		if rconn then rconn:Disconnect(); rconn = nil end
		if target then task.spawn(invoke, "SpecStop", {}) end
		target = nil
		bar.Visible = false
		ov.Enabled = false
		cursor.Visible = false
		cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
	end
end

-- =====================================================================
-- ===== PLAYERS =====
-- =====================================================================
local openPlayer -- (userId | name)
local openGolem -- (uid) 07.11.2026: вкладка GOLEMS + повна історія голема
do
	local pg = pages.players
	local listView = frame(pg, 0, 0, PW, PH, nil, { Name = "List", BackgroundTransparency = 1, ZIndex = 4 })
	local detail = U.scroller(pg, 0, 0, PW, PH, "Detail")
	detail.Visible = false
	local search = input(listView, 0, 0, 196, 52, "Name or UserId…")
	local all = {}
	local listScroll = U.scroller(listView, 0, 64, PW, PH - 64, "Players")
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, listScroll)
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local function drawList()
		U.clear(listScroll)
		local q = string.lower(search.Text)
		local n = 0
		for i, e in all do
			if q == "" or string.find(string.lower(e.name), q, 1, true) or string.find(tostring(e.u), q, 1, true) then
				n += 1
				local row = frame(listScroll, 0, 0, CW, 62, nil, { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 4 })
				cardBg(row, 0, 0, CW, 62, 4)
				local av = new("ImageLabel", { BackgroundColor3 = C("2a2e35"), Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(48, 48), ZIndex = 5,
					Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(e.u) .. "&w=150&h=150" }, row)
				stroke(av, INK, 2)
				label(row, 66, 6, 330, 30, 22, e.name, WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
				label(row, 66, 34, 360, 22, 15, "ID " .. e.u .. "  ·  server " .. tostring(e.job) .. (e.here and "  (this)" or ""),
					e.here and GOOD or MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5 })
				button(row, CW - 128, 9, 116, 44, "OPEN", "blue", function() openPlayer(e.u) end, { z = 6 })
			end
		end
		if n == 0 then label(listScroll, 0, 0, CW, 60, 20, #all == 0 and "Loading…" or "Nobody online matches — press OPEN to look up offline", MUTED, 2, { ZIndex = 5 }) end
	end
	local function load()
		local res = invoke("Players")
		if res.ok then
			all = res.players or {}
			table.sort(all, function(a, b)
				if a.here ~= b.here then return a.here == true end
				return string.lower(a.name) < string.lower(b.name)
			end)
			drawList()
		else
			result(res)
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(drawList)
	local function openTyped()
		local t = string.gsub(search.Text, "%s", "")
		if t == "" then U.deny(); return end
		openPlayer(tonumber(t) or t)
	end
	button(listView, 204, 0, 100, 52, "OPEN", "blue", openTyped)
	button(listView, 312, 0, 116, 52, "REFRESH", "green", load)

	-- 06.11.2026: BANS — історія банів (кого, хто, коли, на скільки, причина, чи ще діє). OPEN — профіль гравця, UNBAN — зняти бан
	--   (модератор+; сервер не дає банити / кікати рівних і вищих за рангом). Дані — AdminService.BanList (DataStore AdminBans).
	local bansView = frame(pg, 0, 0, PW, PH, nil, { Name = "Bans", BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
	local bansScroll = U.scroller(bansView, 0, 64, PW, PH - 64, "BanList")
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, bansScroll)
	bansScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local bansInfo = label(bansView, 260, 0, 390, 52, 16, "", MUTED, 1.8, { TextXAlignment = LEFT, ZIndex = 5 })
	local backToBans = false
	local backToVisits = false -- 07.11.2026: профіль відкрито з VISITS — BACK веде туди
	local loadBans
	local function durText(h: number): string
		if h <= 0 then return "FOREVER" end
		if h >= 24 and h % 24 == 0 then return (h // 24) .. (h == 24 and " day" or " days") end
		return h .. " h"
	end
	local function banRow(i: number, e: any)
		local row = frame(bansScroll, 0, 0, CW, 92, nil, { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 4 })
		cardBg(row, 0, 0, CW, 92, 4)
		local av = new("ImageLabel", { BackgroundColor3 = C("2a2e35"), Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(48, 48), ZIndex = 5,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(e.u) .. "&w=150&h=150" }, row)
		stroke(av, INK, 2)
		local st, sc
		if e.un then st, sc = "UNBANNED" .. (e.unn and (" by @" .. tostring(e.unn)) or ""), GOOD
		elseif e.active then st, sc = "BANNED" .. ((tonumber(e.h) or 0) > 0 and (" until " .. os.date("%d.%m %H:%M", tonumber(e.till) or 0)) or " FOREVER"), BAD
		else st, sc = "EXPIRED", MUTED end
		local TW = CW - 66 - 250
		label(row, 66, 4, TW, 28, 21, "@" .. tostring(e.n or e.u), WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
		label(row, 66, 32, TW, 20, 14, st, sc, 1.6, { TextXAlignment = LEFT, ZIndex = 5 })
		label(row, 66, 52, CW - 80, 18, 13, durText(tonumber(e.h) or 0) .. " · by @" .. tostring(e.bn or e.by) .. " · " .. os.date("%Y-%m-%d %H:%M", tonumber(e.t) or 0)
			.. " · ID " .. tostring(e.u), MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 5 })
		label(row, 66, 70, CW - 80, 18, 13, (e.r and e.r ~= "") and ("Reason: " .. tostring(e.r)) or "No reason", MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 5,
			TextTruncate = Enum.TextTruncate.AtEnd })
		button(row, CW - 240, 10, 110, 44, "OPEN", "blue", function() backToBans = true; openPlayer(e.u) end, { z = 6 })
		if e.active then
			button(row, CW - 122, 10, 110, 44, "UNBAN", "green", function()
				confirm("UNBAN @" .. tostring(e.n or e.u) .. "?", function()
					if result(invoke("Unban", { u = e.u })) then loadBans() end
				end, "UNBAN", "green")
			end, { z = 6 })
		end
	end
	loadBans = function()
		U.clear(bansScroll)
		bansInfo.Text = "Loading…"
		local res = invoke("BanList", {})
		if not res.ok then result(res); bansInfo.Text = ""; return end
		local list = res.bans or {}
		local act = 0
		for i, e in list do
			if e.active then act += 1 end
			banRow(i, e)
		end
		bansInfo.Text = #list .. " bans · " .. act .. " active"
		if #list == 0 then label(bansScroll, 0, 0, CW, 60, 20, "No bans yet", MUTED, 2, { ZIndex = 5 }) end
	end
	button(bansView, 0, 0, 110, 52, "BACK", "gray", function()
		bansView.Visible = false
		listView.Visible = true
		load()
	end)
	button(bansView, 120, 0, 130, 52, "REFRESH", "green", function() loadBans() end)
	button(listView, 436, 0, 96, 52, "BANS", "red", function()
		listView.Visible = false
		bansView.Visible = true
		loadBans()
	end)
	-- 07.11.2026: VISITS — історія входів у гру (хто й коли заходив, найсвіжіші зверху) з пошуком за ніком / ID;
	--   OPEN — профіль (і офлайн). Дані — AdminService.Visits (OrderedDataStore AdminVisits), до 300 останніх гравців.
	local visView = frame(pg, 0, 0, PW, PH, nil, { Name = "Visits", BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
	local visScroll = U.scroller(visView, 0, 64, PW, PH - 64, "VisitList")
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, visScroll)
	visScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local visSearch = input(visView, 112, 0, 250, 52, "Search name / ID…")
	local visInfo = label(visView, 498, 0, 152, 52, 14, "", MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5, TextWrapped = true })
	local visAll = {}
	local VIS_SHOW = 120
	local function ago(t: any): string
		local d = os.time() - (tonumber(t) or 0)
		if d < 3600 then return math.max(1, d // 60) .. " min ago" end
		if d < 86400 then return (d // 3600) .. " h ago" end
		return (d // 86400) .. " d ago"
	end
	local function drawVisits()
		U.clear(visScroll)
		local q = string.lower((string.gsub(visSearch.Text, "%s", "")))
		local n, shown = 0, 0
		for i, e in visAll do
			local nm, dn = string.lower(tostring(e.n or "")), string.lower(tostring(e.d or ""))
			if q == "" or string.find(nm, q, 1, true) or string.find(dn, q, 1, true) or string.find(tostring(e.u), q, 1, true) then
				n += 1
				if shown < VIS_SHOW then
					shown += 1
					local row = frame(visScroll, 0, 0, CW, 62, nil, { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 4 })
					cardBg(row, 0, 0, CW, 62, 4)
					local av = new("ImageLabel", { BackgroundColor3 = C("2a2e35"), Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(48, 48), ZIndex = 5,
						Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(e.u) .. "&w=150&h=150" }, row)
					stroke(av, INK, 2)
					local nameT = "@" .. tostring(e.n or e.u)
					if e.d and e.n and e.d ~= e.n then nameT = tostring(e.d) .. " (@" .. tostring(e.n) .. ")" end
					label(row, 66, 6, CW - 66 - 140, 30, 21, nameT, WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd })
					local onT = e.here and "  ·  ONLINE (this server)" or (e.on and "  ·  ONLINE" or "")
					label(row, 66, 34, CW - 66 - 140, 22, 14, "joined " .. os.date("%Y-%m-%d %H:%M", tonumber(e.t) or 0) .. " (" .. ago(e.t) .. ")  ·  ID " .. tostring(e.u) .. onT,
						(e.here or e.on) and GOOD or MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd })
					button(row, CW - 128, 9, 116, 44, "OPEN", "blue", function() backToVisits = true; openPlayer(e.u) end, { z = 6 })
				end
			end
		end
		visInfo.Text = (q == "" and (#visAll .. " players") or (n .. " found of " .. #visAll)) .. (n > VIS_SHOW and (" · first " .. VIS_SHOW) or "")
		if n == 0 then
			label(visScroll, 0, 0, CW, 60, 18, #visAll == 0 and "No visits recorded yet" or "Nobody matches — type the full nick in PLAYERS and press OPEN", MUTED, 2, { ZIndex = 5 })
		end
	end
	local function loadVisits()
		U.clear(visScroll)
		visInfo.Text = "Loading…"
		local res = invoke("Visits", { n = 300 })
		if not res.ok then result(res); visInfo.Text = ""; return end
		visAll = res.visits or {}
		drawVisits()
	end
	visSearch:GetPropertyChangedSignal("Text"):Connect(drawVisits)
	button(visView, 0, 0, 104, 52, "BACK", "gray", function()
		visView.Visible = false
		listView.Visible = true
		load()
	end)
	button(visView, 370, 0, 120, 52, "REFRESH", "green", loadVisits)
	button(listView, 540, 0, 110, 52, "VISITS", "purple", function()
		listView.Visible = false
		visView.Visible = true
		loadVisits()
	end)
	search.FocusLost:Connect(function(enter) if enter then openTyped() end end)

	-- ===== профіль гравця =====
	local cur = nil
	local golemSel = { kind = "stone", mut = 0, cls = "miner" }
	local function rowLabel(parent, x, y, w, size, text, color, align)
		return label(parent, x, y, w, size + 8, size, text, color or WHITE, size >= 20 and 2.4 or 1.8, { TextXAlignment = align or LEFT, ZIndex = 5 })
	end
	local function back()
		detail.Visible = false
		cur = nil
		if backToBans then -- 06.11.2026: профіль відкрито з історії банів — назад до неї
			backToBans = false
			bansView.Visible = true
			loadBans()
			return
		end
		if backToVisits then -- 07.11.2026: назад до історії входів (без перезавантаження списку)
			backToVisits = false
			visView.Visible = true
			return
		end
		listView.Visible = true
		load()
	end
	local function draw(info: any)
		U.clear(detail)
		cur = info
		local here = Players:GetPlayerByUserId(info.u)
		local online = string.find(tostring(info.status), "^online") ~= nil
		local y = 0
		button(detail, 0, 0, 104, 48, "BACK", "gray", back)
		button(detail, CW - 128, 0, 128, 48, "REFRESH", "green", function() openPlayer(info.u) end)
		local av = new("ImageLabel", { BackgroundColor3 = C("2a2e35"), Position = UDim2.fromOffset(114, 0), Size = UDim2.fromOffset(48, 48), ZIndex = 5,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(info.u) .. "&w=150&h=150" }, detail)
		stroke(av, INK, 2)
		local HW = CW - 128 - 8 - 170 -- ширина заголовка: до кнопки REFRESH
		rowLabel(detail, 170, -2, HW, 22, (info.display and info.display ~= info.name) and (info.display .. " (@" .. tostring(info.name) .. ")") or ("@" .. tostring(info.name)))
		local st = tostring(info.status or "?")
		if info.job then st ..= " · server " .. info.job end
		if info.age then st ..= " · account " .. info.age .. " d" end
		if info.lastSeen then st ..= " · seen " .. os.date("%Y-%m-%d %H:%M", info.lastSeen) end
		rowLabel(detail, 170, 26, HW, 13, "ID " .. info.u .. " · " .. st, online and GOOD or MUTED)
		y = 60
		if info.suspect then
			rowLabel(detail, 0, y, CW, 17, "SUSPECT: owns an indexed golem registered to someone else (see LOGS)", BAD)
			y += 28
		end
		local tiles = {
			{ "MONEY", U.num(info.money) }, { "DIAMONDS", U.num(info.diamonds) }, { "TICKETS", U.num(info.tickets) },
			{ "STAGE", tostring(info.stage or 1) }, { "ROLL LUCK", tostring(info.luck or 1) }, { "GOLEMS", tostring(#(info.golems or {})) },
		}
		local tw = (CW - 5 * 8) / 6
		for i, t in tiles do
			local x = (i - 1) * (tw + 8)
			cardBg(detail, x, y, tw, 64, 4)
			rowLabel(detail, x, y + 5, tw, 13, t[1], MUTED, Enum.TextXAlignment.Center)
			rowLabel(detail, x, y + 27, tw, 22, t[2], WHITE, Enum.TextXAlignment.Center)
		end
		y += 80

		-- ДІЇ З ГРАВЦЕМ (модератор+)
		U.section(detail, 0, y, "ACTIONS"); y += 30
		local bw = (CW - 3 * 8) / 4
		local acts = {
			{ "TELEPORT", "blue", online, function() result(invoke("Teleport", { u = info.u })) end },
			{ "BRING", "purple", here ~= nil, function() result(invoke("Bring", { u = info.u })) end },
			{ "SPECTATE", "green", here ~= nil and here ~= player, function() if here then Spectate.start(here) end end },
			{ "FREEZE", "blue", online, function() result(invoke("Freeze", { u = info.u, on = true })) end },
			{ "UNFREEZE", "orange", online, function() result(invoke("Freeze", { u = info.u, on = false })) end },
			{ "KICK", "orange", online, nil },
			{ "COPY ID", "gray", true, nil },
			{ "BAN HISTORY", "gray", true, nil },
			{ "INVENTORY", "green", true, nil }, -- 07.11.2026: увесь інвентар гравця (хотбар, рука, зілля, бусти, кейси, руда, де големи)
		}
		-- RESET ALL (29.10.2026, лише owner): стерти все збереження гравця; друга кнопка — ще й зняти всі геймпаси (не повернуться при вході)
		if myLevel() >= 3 then
			table.insert(acts, { "RESET ALL DATA", "red", true, nil })
			table.insert(acts, { "RESET + PASSES", "red", true, nil })
		end
		local histHolder
		for i, a in acts do
			local col, row = (i - 1) % 4, (i - 1) // 4
			local b = button(detail, col * (bw + 8), y + row * 56, bw, 48, a[1], a[3] and a[2] or "gray", a[4], { textSize = 16 })
			if not a[3] then b.enabled = false end
			if a[1] == "RESET ALL DATA" or a[1] == "RESET + PASSES" then
				local passes = a[1] == "RESET + PASSES"
				b.onClick = function()
					confirm("RESET ALL progress of @" .. tostring(info.name) .. (passes and " AND remove all gamepasses" or "") .. "?\nMoney, golems, cave, map, rebirths, diamonds — everything. Can't be undone.",
						function() result(invoke("Wipe", { u = info.u, passes = passes })) end, "RESET", "red")
				end
			elseif a[1] == "KICK" then
				b.onClick = function()
					confirm("KICK @" .. tostring(info.name) .. "?", function() result(invoke("Kick", { u = info.u, reason = "" })) end, "KICK", "orange")
				end
			elseif a[1] == "COPY ID" then
				b.onClick = function()
					local box = new("TextBox", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Text = tostring(info.u), TextTransparency = 1 }, detail)
					box:CaptureFocus(); box.SelectionStart = 1; box.CursorPosition = #box.Text + 1
					setStatus("ID selected — press Ctrl+C", true)
					task.delay(4, function() box:Destroy() end)
				end
			elseif a[1] == "INVENTORY" then
				-- 07.11.2026 v2: відкриває справжнє вікно BACKPACK (InventoryUI) з даними цього гравця — лише перегляд, без дій
				b.onClick = function()
					setStatus("Loading inventory…")
					local res = invoke("InvRaw", { u = info.u })
					if not res.ok then result(res); return end
					local fn = shared.MMG_ViewInventory
					if type(fn) ~= "function" then setStatus("Backpack window is not ready", false); return end
					setStatus(res.live and "Inventory: live" or "Inventory: last save (not on this server)", true)
					fn(tostring(res.name or info.name), res.attrs or {})
				end
			elseif a[1] == "BAN HISTORY" then
				b.onClick = function()
					local res = invoke("BanHistory", { u = info.u })
					if not res.ok then result(res); return end
					if not histHolder then return end
					U.clear(histHolder)
					local hy = 0
					if #(res.history or {}) == 0 then rowLabel(histHolder, 0, 0, CW, 15, "No bans", MUTED); hy = 24 end
					for _, h in res.history or {} do
						local d = (h.dur or 0) < 0 and "PERMANENT" or (h.dur and U.dur(h.dur) or "?")
						rowLabel(histHolder, 0, hy, CW, 14, (h.ban and "BAN " or "UNBAN ") .. tostring(h.start) .. " · " .. d .. " · " .. tostring(h.reason or ""), h.ban and BAD or GOOD)
						hy += 22
					end
					histHolder.Size = UDim2.fromOffset(CW, hy)
					setStatus("Ban history loaded", true)
				end
			end
		end
		y += math.ceil(#acts / 4) * 56 + 4
		histHolder = frame(detail, 0, y, CW, 0, nil, { BackgroundTransparency = 1, ZIndex = 4 })
		-- усе нижче — у afterHist, який посувається під історію банів (BAN HISTORY)
		local afterHist = frame(detail, 0, 0, CW, 10, nil, { BackgroundTransparency = 1, ZIndex = 4 })
		local base = afterHist
		local by = 0

		-- ПОВІДОМЛЕННЯ
		U.section(base, 0, by, "MESSAGE TO PLAYER"); by += 30
		local dm = input(base, 0, by, CW - 150, 46, "Private message…")
		button(base, CW - 140, by, 140, 46, "SEND", "blue", function()
			if #dm.Text < 2 then setStatus("Write a message first", false); return end
			if result(invoke("DM", { u = info.u, text = dm.Text })) then dm.Text = "" end
		end, { textSize = 18 })
		by += 66

		-- РЕСУРСИ (admin+)
		local resF = frame(base, 0, by, CW, 10, nil, { BackgroundTransparency = 1, ZIndex = 4 })
		do
			local ry = 0
			U.section(resF, 0, ry, "RESOURCES"); ry += 30
			local res = U.choice(resF, 0, ry, (CW - 24) / 4, 46, 8, {
				{ key = "Money", text = "MONEY", color = "green" }, { key = "Diamonds", text = "DIAMONDS", color = "blue" },
				{ key = "Tickets", text = "TICKETS", color = "yellow" }, { key = "LuckLvl", text = "ROLL LUCK", color = "purple" },
			}, "Money", nil, 17)
			ry += 56
			local amount = input(resF, 0, ry, 190, 46, "amount")
			U.presets(resF, 198, ry, 82, 46, 6, { { "100", 100 }, { "1K", 1000 }, { "10K", 10000 }, { "1M", 1000000 }, { "1B", 1000000000 } }, amount)
			ry += 56
			local function act(mode: string)
				local n = tonumber((string.gsub(amount.Text, "[,%s]", "")))
				if not n or n < 0 or (n == 0 and mode ~= "set") then setStatus("Enter an amount", false); return end
				local function go()
					local arg = { u = info.u, what = res.value, amount = mode == "take" and -n or n, mode = mode == "set" and "set" or nil }
					if result(invoke("Give", arg)) then openPlayer(info.u, true) end
				end
				if mode == "give" then go() else
					confirm((mode == "take" and ("TAKE " .. U.num(n) .. " " .. res.value .. " from") or ("SET " .. res.value .. " = " .. U.num(n) .. " for")) .. " @" .. tostring(info.name) .. "?", go, mode == "take" and "TAKE" or "SET")
				end
			end
			local w3 = (CW - 16) / 3
			button(resF, 0, ry, w3, 50, "GIVE", "green", function() act("give") end)
			button(resF, w3 + 8, ry, w3, 50, "TAKE", "red", function() act("take") end)
			button(resF, 2 * (w3 + 8), ry, w3, 50, "SET", "orange", function() act("set") end)
			ry += 70

			-- КАРТА (05.11.2026): перевести на потрібну мапу — «скіп прогресу», ребітхи підтягуються (SetMap; гравець — на цьому сервері)
			U.section(resF, 0, ry, "MAP · SKIP PROGRESS  (now: Map " .. tostring(info.stage or 1) .. ", Rebirths " .. tostring(info.rebirths or 0) .. ")"); ry += 30
			local FC = require(Shared:WaitForChild("ForgeConfig"))
			local mitems = {}
			for m = 1, FC.MAX_STAGE do table.insert(mitems, { key = m, text = "MAP " .. m, color = "orange" }) end
			local mw = (CW - 8 * (#mitems - 1)) / #mitems
			local mapSel = U.choice(resF, 0, ry, mw, 46, 8, mitems, math.clamp(tonumber(info.stage) or 1, 1, FC.MAX_STAGE), nil, 17)
			ry += 56
			local function goMap(full: boolean)
				local m = mapSel.value
				local reb = full and MultiCfg.rebirthLimit(m) or (m > 1 and MultiCfg.rebirthLimit(m - 1) or 0)
				confirm("Move @" .. tostring(info.name) .. " to MAP " .. m .. "?\nRebirths = " .. reb .. ". Money, plots, ore and inventory golems reset like a real map change.", function()
					if result(invoke("SetMap", { u = info.u, stage = m, full = full })) then openPlayer(info.u, true) end
				end, "MOVE", "orange")
			end
			local w2 = (CW - 8) / 2
			button(resF, 0, ry, w2, 50, "GO TO MAP", "orange", function() goMap(false) end)
			button(resF, w2 + 8, ry, w2, 50, "GO + ALL MAP REBIRTHS", "purple", function() goMap(true) end)
			ry += 70

			U.section(resF, 0, ry, "GIVE GOLEM"); ry += 30
			U.golemField(resF, 0, ry, 300, 64, golemSel)
			local cnt = U.stepper(resF, 310, ry + 9, 176, 46, 1, 1, 50)
			button(resF, 496, ry + 7, CW - 496, 50, "GIVE", "green", function()
				if result(invoke("Give", { u = info.u, what = "Golem", amount = cnt.get(), item = golemItem(golemSel) })) then openPlayer(info.u, true) end
			end)
			ry += 84

			-- кейси (02.11.2026): предмет Case_<ключ> у вкладці Golems інвентаря; відкривається з хотбара (CaseService)
			U.section(resF, 0, ry, "GIVE CASE"); ry += 30
			for _, cd in Items.CASES or {} do
				local cbg = U.slotBg(resF, 0, ry, 300, 64, 4)
				local cic = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 2), Size = UDim2.fromOffset(60, 60),
					ScaleType = Enum.ScaleType.Fit, Image = "", ZIndex = 5 }, cbg)
				pcall(ItemViewport.set, cic, "Case_" .. cd.key, 1.1)
				label(cbg, 72, 4, 220, 32, 18, cd.name, cd.tone or WHITE, 2, { TextXAlignment = LEFT, ZIndex = 6 })
				label(cbg, 72, 34, 220, 24, 13, "has: " .. tostring(info.cases and info.cases[cd.key] or "?"), MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 6 })
				local ccnt = U.stepper(resF, 310, ry + 9, 176, 46, 1, 1, 1000)
				button(resF, 496, ry + 7, CW - 496, 50, "GIVE", "green", function()
					if result(invoke("Give", { u = info.u, what = "Case", amount = ccnt.get(), item = cd.key })) then openPlayer(info.u, true) end
				end)
				ry += 74
			end
			ry += 10

			-- РУДА (05.11.2026): сира (Ore_<ключ>) і оброблена (Bars_<ключ> — злитки / огранені камені) будь-якої мапи; у дужках — скільки має
			U.section(resF, 0, ry, "GIVE ORE"); ry += 30
			local paintOres
			local oMap = U.choice(resF, 0, ry, mw, 46, 8, mitems, math.clamp(tonumber(info.stage) or 1, 1, FC.MAX_STAGE), function() paintOres() end, 17)
			ry += 56
			local oKind = U.choice(resF, 0, ry, w2, 46, 8, { { key = "Ore", text = "RAW ORE", color = "orange" }, { key = "Bars", text = "REFINED", color = "purple" } },
				"Ore", function() paintOres() end, 17)
			ry += 56
			local ow = (CW - 16) / 3
			local oSel = U.choice(resF, 0, ry, ow, 46, 8, { { key = 1, text = "", color = "green" }, { key = 2, text = "", color = "green" }, { key = 3, text = "", color = "green" } }, 1, nil, 16)
			local function oreAt(i: number): any return (FC.STAGE_ORES[oMap.value] or {})[i] end
			paintOres = function()
				for i = 1, 3 do
					local b, o = oSel.btns[i], oreAt(i)
					local has = o and info.ores and info.ores[o.key]
					local txt = o and string.upper(oKind.value == "Ore" and o.key or FC.productName(o.key)) or "?"
					if has then txt ..= " (" .. U.num(oKind.value == "Ore" and has[1] or has[2]) .. ")" end
					if b and b.label then b.label.Text = txt end
				end
			end
			paintOres()
			ry += 56
			local oAmt = input(resF, 0, ry, 190, 46, "amount")
			U.presets(resF, 198, ry, 82, 46, 6, { { "10", 10 }, { "100", 100 }, { "1K", 1000 }, { "10K", 10000 }, { "100K", 100000 } }, oAmt)
			ry += 56
			local function giveOre(sign: number)
				local n = tonumber((string.gsub(oAmt.Text, "[,%s]", "")))
				local o = oreAt(oSel.value)
				if not n or n <= 0 or n ~= math.floor(n) then setStatus("Enter an amount", false); return end
				if not o then setStatus("Pick an ore", false); return end
				local function go()
					if result(invoke("Give", { u = info.u, what = oKind.value, amount = sign * n, item = o.key })) then openPlayer(info.u, true) end
				end
				if sign > 0 then go() else
					confirm("TAKE " .. U.num(n) .. " " .. (oKind.value == "Ore" and (o.key .. " Ore") or FC.productName(o.key)) .. " from @" .. tostring(info.name) .. "?", go, "TAKE")
				end
			end
			button(resF, 0, ry, w2, 50, "GIVE", "green", function() giveOre(1) end)
			button(resF, w2 + 8, ry, w2, 50, "TAKE", "red", function() giveOre(-1) end)
			ry += 70

			U.section(resF, 0, ry, "POTIONS"); ry += 30
			local pitems = {}
			for _, d in Items.POTIONS do table.insert(pitems, { key = d.key, text = string.upper(d.key), color = "purple" }) end
			local pot = U.choice(resF, 0, ry, (CW - 6 * (#pitems - 1)) / #pitems, 46, 6, pitems, pitems[1] and pitems[1].key, nil, 15)
			ry += 56 -- кількість і GIVE — окремим рядком, щоб число було добре видно
			local pn = U.stepper(resF, 0, ry, 220, 46, 1, 1, 999)
			button(resF, 230, ry, CW - 230, 46, "GIVE", "green", function()
				if result(invoke("Give", { u = info.u, what = "Potion", amount = pn.get(), item = pot.value })) then openPlayer(info.u, true) end
			end)
			ry += 66

			-- геймпаси: вибір з іконками (ALL — усі), GIVE / TAKE (Pass_<ключ>; офлайн — поштою)
			U.section(resF, 0, ry, "GAMEPASSES (" .. #(info.passes or {}) .. " / " .. (function() local k = 0 for _ in MonCfg.Passes do k += 1 end return k end)() .. ")"); ry += 30
			local passSel = { key = "*" }
			U.passField(resF, 0, ry, 300, 64, passSel, info.passes or {})
			local bw2 = (CW - 318) / 2
			local tiers = info.tiers or {}
			button(resF, 310, ry + 7, bw2, 50, "GIVE", "green", function()
				local sp = SPECIAL[passSel.key]
				if sp and sp.level then -- драбина: вибір ступеня («до ступеня»; зараз у гравця — tiers)
					LevelPicker.open(sp.what, math.max(1, tonumber(tiers[sp.what]) or 0), function(lv)
						if result(invoke("Give", { u = info.u, what = sp.what, amount = lv })) then openPlayer(info.u, true) end
					end)
				elseif sp then
					if result(invoke("Give", { u = info.u, what = sp.what, amount = 1 })) then openPlayer(info.u, true) end
				else
					if result(invoke("Give", { u = info.u, what = "Pass", amount = 1, item = passSel.key })) then openPlayer(info.u, true) end
				end
			end)
			button(resF, 318 + bw2, ry + 7, bw2, 50, "TAKE", "red", function()
				local sp = SPECIAL[passSel.key]
				if sp and sp.level then setStatus("Levels can't be taken (only raised)", false); return end
				confirm("TAKE " .. passName(passSel.key) .. " from @" .. tostring(info.name) .. "?", function()
					local arg = sp and { u = info.u, what = sp.what, amount = -1 } or { u = info.u, what = "Pass", amount = -1, item = passSel.key }
					if result(invoke("Give", arg)) then openPlayer(info.u, true) end
				end, "TAKE")
			end)
			label(resF, 0, ry + 66, CW, 18, 13, "x2 Money: " .. levelText("MoneyTier", tonumber(tiers.MoneyTier) or 0) .. " · Fast Mutations: "
				.. levelText("MutTier", tonumber(tiers.MutTier) or 0) .. " · Lucky Rolls: x10 × " .. (tiers.LuckRoll10 or 0) .. ", x99 × " .. (tiers.LuckRoll99 or 0),
				MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 5 })
			ry += 22
			ry += 84
			resF.Size = UDim2.fromOffset(CW, ry)
			gate(resF, 2)
			if resF.Visible then by += ry end
		end

		-- МОДЕРАЦІЯ
		U.section(base, 0, by, "BAN"); by += 30
		local reason = input(base, 0, by, CW, 46, "Reason (shown to the player)")
		by += 54
		local isMod = myLevel() < 2
		local durItems = { { key = 1, text = "1 HOUR", color = "orange" }, { key = 24, text = "1 DAY", color = "orange" } }
		if not isMod then
			table.insert(durItems, { key = 168, text = "7 DAYS", color = "red" })
			table.insert(durItems, { key = 720, text = "30 DAYS", color = "red" })
			table.insert(durItems, { key = 0, text = "FOREVER", color = "red" })
		end
		local dur = U.choice(base, 0, by, (CW - 4 * 6) / 5, 44, 6, durItems, 24, nil, 15)
		by += 54
		button(base, 0, by, (CW - 8) / 2, 50, "BAN", "red", function()
			local h = dur.value
			confirm("BAN @" .. tostring(info.name) .. (h > 0 and (" for " .. (h >= 24 and (h // 24 .. " day(s)") or (h .. " h"))) or " FOREVER") .. "?",
				function() result(invoke("Ban", { u = info.u, hours = h, reason = reason.Text })) end, "BAN")
		end)
		local ub = button(base, (CW - 8) / 2 + 8, by, (CW - 8) / 2, 50, "UNBAN", "blue", function()
			result(invoke("Unban", { u = info.u }))
		end)
		-- 06.11.2026: UNBAN — і модераторам (гейт прибрано)
		by += 72

		-- ГОЛЕМИ
		local gl = info.golems or {}
		U.section(base, 0, by, "GOLEMS (" .. #gl .. ")"); by += 30
		local gfilter = input(base, 0, by, CW, 44, "Filter: name, mutation, UID, plot / cave…")
		by += 54
		local listTop = by
		local holderF = frame(base, 0, listTop, CW, 10, nil, { BackgroundTransparency = 1, ZIndex = 4 })
		local function drawGolems()
			U.clear(holderF)
			local q = string.lower(gfilter.Text)
			local yy = 0
			local shown = 0
			for _, g in gl do
				local uid, kind, cls, mut, where, locked = g[1], g[2], g[3], g[4], g[5], g[6]
				local nm = U.golemName(kind, mut)
				local hay = string.lower(nm .. " " .. tostring(uid) .. " " .. tostring(cls) .. " " .. tostring(where))
				if q == "" or string.find(hay, q, 1, true) then
					shown += 1
					if shown > 60 then
						rowLabel(holderF, 0, yy, CW, 15, "…and more — use the filter", MUTED); yy += 26
						break
					end
					cardBg(holderF, 0, yy, CW, 68, 4)
					U.golemIcon(holderF, 6, yy + 4, 60, kind, cls, 5)
					rowLabel(holderF, 72, yy + 5, 300, 18, nm, mutColor(mut))
					rowLabel(holderF, 330, yy + 7, 160, 13, string.upper(tostring(cls)) .. " · " .. string.upper(tostring(where)) .. (locked == 1 and " · LOCK" or ""), MUTED, RIGHT)
					local ubx = input(holderF, 70, yy + 34, 422, 28, "", { text = uid ~= "" and uid or "(no UID yet)", mono = true, readOnly = true, textSize = 15, z = 5 })
					ubx.TextColor3 = C("cfd6de")
					-- 07.11.2026: HISTORY — звідки голем узявся й через кого переходив (вкладка GOLEMS)
					button(holderF, CW - 124, yy + 36, 112, 28, "HISTORY", "purple", function()
						if uid == "" then setStatus("Golem has no UID yet", false); return end
						openGolem(uid)
					end, { z = 6, textSize = 14 })
					local del = button(holderF, CW - 124, yy + 4, 112, 28, "DELETE", "red", function()
						if uid == "" then setStatus("Golem has no UID yet", false); return end
						confirm("DELETE " .. nm .. " from @" .. tostring(info.name) .. " forever?\n" .. uid, function()
							if result(invoke("Give", { u = info.u, what = "RemoveGolem", amount = 1, item = uid })) then openPlayer(info.u, true) end
						end, "DELETE")
					end, { z = 6, textSize = 14 })
					gate(del.group, 2)
					yy += 76
				end
			end
			if shown == 0 then rowLabel(holderF, 0, 0, CW, 18, "No golems", MUTED); yy = 30 end
			holderF.Size = UDim2.fromOffset(CW, yy)
			afterHist.Size = UDim2.fromOffset(CW, listTop + yy)
			detail.CanvasSize = UDim2.fromOffset(0, y + 6 + histHolder.Size.Y.Offset + listTop + yy + 30)
		end
		gfilter:GetPropertyChangedSignal("Text"):Connect(drawGolems)
		histHolder:GetPropertyChangedSignal("Size"):Connect(function()
			afterHist.Position = UDim2.fromOffset(0, y + histHolder.Size.Y.Offset + 6)
			detail.CanvasSize = UDim2.fromOffset(0, y + 6 + histHolder.Size.Y.Offset + afterHist.Size.Y.Offset + 30)
		end)
		afterHist.Position = UDim2.fromOffset(0, y + 6)
		drawGolems()
	end

	-- silent = оновлення після дії: рядок статусу не чіпаємо (там результат дії — успіх або помилка)
	openPlayer = function(who: any, silent: boolean?)
		selectTab("players")
		if not silent then setStatus("Loading…") end
		local arg = type(who) == "number" and { u = who } or { name = tostring(who) }
		local res = invoke("PlayerInfo", arg)
		if not res.ok then result(res); return end
		if not silent then setStatus("") end
		listView.Visible = false
		bansView.Visible = false
		visView.Visible = false
		detail.Visible = true
		local keep = (cur and cur.u == res.info.u) and detail.CanvasPosition or Vector2.zero
		draw(res.info)
		detail.CanvasPosition = keep
	end
	onShow.players = function()
		if not detail.Visible then load() end
	end
end

-- =====================================================================
-- ===== GOLEMS (пошук за UID) =====
-- =====================================================================
do
	local pg = pages.golems
	local uidBox = input(pg, 0, 0, 500, 52, "Golem UID (26 chars)", { mono = true, textSize = 17 })
	local out = U.scroller(pg, 0, 64, PW, PH - 64, "Result")
	local function find()
		local uid = string.upper((string.gsub(uidBox.Text, "%s", "")))
		if #uid ~= 26 then setStatus("UID must be 26 characters", false); return end
		setStatus("Searching all servers…")
		local res = invoke("FindUid", { uid = uid })
		U.clear(out)
		if not res.ok then result(res); return end
		setStatus("")
		local y = 0
		local function line(text, color, size, x)
			size = size or 16
			label(out, x or 14, y, CW - (x or 14) - 10, size + 8, size, text, color or WHITE, 1.8, { TextXAlignment = LEFT, ZIndex = 6, TextWrapped = true })
			y += size + 10
		end
		local top = y
		local card = cardBg(out, 0, y, CW, 10, 4)
		y += 10
		local ix = res.index
		if ix then U.golemIcon(out, CW - 110, 8, 96, ix.k, ix.c, 6) end
		line(res.uid, GOLD, 20)
		line("Minted: " .. (res.minted and os.date("%Y-%m-%d %H:%M:%S", math.floor(res.minted)) or "?"), MUTED)
		if ix then
			line(U.golemName(ix.k, ix.m) .. " · " .. string.upper(tostring(ix.c)), mutColor(ix.m), 20)
			line("Index owner: " .. tostring(ix.o) .. " · source: " .. tostring(ix.s), WHITE)
			for i = #(ix.h or {}), 1, -1 do
				local h = ix.h[i]
				line(os.date("%m-%d %H:%M", h.t or 0) .. "  " .. string.upper(tostring(h.e)) .. "  user " .. tostring(h.u) .. "  " .. tostring(h.r or ""), MUTED, 14, 28)
			end
		else
			line("Not in the global index (normal for golems below Void that were never traded)", MUTED, 14)
		end
		card.Size = UDim2.fromOffset(CW, math.max(y - top + 6, 116))
		y = math.max(y, top + 116) + 18
		local hits = res.hits or {}
		label(out, 0, y, 600, 24, 18, "FOUND ON PLAYERS (" .. #hits .. ")" .. (#hits > 1 and "  — DUPLICATE!" or ""), #hits > 1 and BAD or GOLD, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
		y += 32
		if #hits == 0 then line("Nobody online has it (it may be deleted or the owner is offline)", MUTED) end
		for _, h in hits do
			cardBg(out, 0, y, CW, 72, 4)
			U.golemIcon(out, 6, y + 4, 64, h.kind, h.cls, 5)
			label(out, 78, y + 6, 300, 28, 20, "@" .. tostring(h.name), WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
			label(out, 78, y + 38, 300, 22, 14, U.golemName(h.kind, h.mut) .. " · " .. string.upper(tostring(h.where)) .. " · server " .. tostring(h.job), mutColor(h.mut), 1.6, { TextXAlignment = LEFT, ZIndex = 5 })
			button(out, CW - 248, y + 13, 116, 46, "OPEN", "blue", function() openPlayer(h.u) end, { z = 6 })
			local del = button(out, CW - 124, y + 13, 112, 46, "DELETE", "red", function()
				confirm("DELETE " .. U.golemName(h.kind, h.mut) .. " from @" .. tostring(h.name) .. " forever?", function()
					result(invoke("Give", { u = h.u, what = "RemoveGolem", amount = 1, item = res.uid }))
				end, "DELETE")
			end, { z = 6, textSize = 17 })
			gate(del.group, 2)
			y += 80
		end
		-- 07.11.2026: ПОВНА ІСТОРІЯ — журнал усіх серверів від дня мінту (AdminService.GolemHistory)
		y += 8
		label(out, 0, y, 600, 24, 18, "FULL HISTORY", GOLD, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
		y += 32
		out.CanvasSize = UDim2.fromOffset(0, y + 40)
		local hres = invoke("GolemHistory", { uid = uid })
		if not hres.ok then line(tostring(hres.error or "History failed"), BAD)
		else
			if hres.partial then line("Older than 21 days — only the last 21 days of the log are shown", MUTED, 13) end
			local evs = hres.events or {}
			if #evs == 0 then line("No log entries yet (the log is written once a minute — try again shortly)", MUTED, 14) end
			local WHAT = { mint = "CREATED", move = "MOVED", burn = "DELETED", dupe = "DUPLICATE REMOVED", foreign = "SUSPECT: OWNER MISMATCH",
				legacy = "GOT UID (old save)", relink = "RE-INDEXED", grant = "GRANTED" }
			local function who(u, n) return n and ("@" .. n) or (u and ("user " .. tostring(u)) or "?") end
			for _, e in evs do
				local t = os.date("%Y-%m-%d %H:%M", e.t or 0)
				local col = e.e == "burn" and BAD or (e.e == "move" and C("8fd2ff") or (e.e == "mint" and GOOD or ((e.e == "dupe" or e.e == "foreign") and BAD or WHITE)))
				local txt
				if e.e == "move" then
					txt = t .. "   " .. who(e.u, e.un) .. "  →  " .. who(e.x, e.xn) .. "   (" .. tostring(e.r or "trade") .. ")"
				else
					txt = t .. "   " .. (WHAT[e.e] or string.upper(tostring(e.e))) .. "   " .. who(e.u, e.un) .. ((e.r and e.r ~= "") and ("   (" .. tostring(e.r) .. ")") or "")
				end
				cardBg(out, 0, y, CW, 34, 4)
				label(out, 12, y + 4, CW - 24, 26, 15, txt, col, 1.6, { TextXAlignment = LEFT, ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
				y += 40
			end
		end
		out.CanvasSize = UDim2.fromOffset(0, y + 10)
	end
	button(pg, 512, 0, 138, 52, "FIND", "blue", find)
	uidBox.FocusLost:Connect(function(enter) if enter then find() end end)
	openGolem = function(uid: string)
		selectTab("golems")
		uidBox.Text = uid
		task.spawn(find)
	end
end

-- =====================================================================
-- ===== GLOBAL =====
-- =====================================================================
do
	local pg = pages.global
	local sc = U.scroller(pg, 0, 0, PW, PH, "Global")
	local y = 0
	-- оголошення
	U.section(sc, 0, y, "ANNOUNCEMENT (all servers)"); y += 30
	local annText = input(sc, 0, y, CW, 48, "Message for everyone…")
	y += 56
	local annColor = U.choice(sc, 0, y, (CW - 24) / 5, 42, 6, {
		{ key = "yellow", text = "YELLOW", color = "yellow" }, { key = "green", text = "GREEN", color = "green" },
		{ key = "red", text = "RED", color = "red" }, { key = "blue", text = "BLUE", color = "blue" }, { key = "purple", text = "PURPLE", color = "purple" },
	}, "yellow", nil, 15)
	y += 50
	label(sc, 0, y, 120, 42, 15, "SHOW FOR", MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5 })
	local annSec = U.choice(sc, 110, y, 92, 42, 6, {
		{ key = 5, text = "5 SEC" }, { key = 10, text = "10 SEC" }, { key = 20, text = "20 SEC" }, { key = 40, text = "40 SEC" },
	}, 10, nil, 15)
	y += 52
	button(sc, 0, y, 240, 50, "SEND", "green", function()
		if #annText.Text < 2 then setStatus("Write a message first", false); return end
		if result(invoke("Announce", { text = annText.Text, color = annColor.value, sec = annSec.value })) then annText.Text = "" end
	end)
	y += 74

	-- видача всім (admin+)
	local gF = frame(sc, 0, y, CW, 10, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local gy = 0
	U.section(gF, 0, gy, "GIVE TO EVERYONE (all servers)"); gy += 30
	local itemsTop = gy + 56
	local potF, golF, amtF, passF, caseF
	local gPass = { key = "*" }
	local gLevel = { MoneyTier = 1, MutTier = 1 }
	local refreshPassF
	-- 10.11.2026: + CASE — кейси всім (Case_<ключ>; кількість — поле AMOUNT, до 1000)
	local gWhat = U.choice(gF, 0, gy, (CW - 36) / 7, 44, 6, {
		{ key = "Money", text = "MONEY", color = "green" }, { key = "Diamonds", text = "DIAMONDS", color = "blue" },
		{ key = "Tickets", text = "TICKETS", color = "yellow" }, { key = "Potion", text = "POTION", color = "purple" },
		{ key = "Golem", text = "GOLEM", color = "orange" }, { key = "Pass", text = "PASS", color = "red" },
		{ key = "Case", text = "CASE", color = "gray" },
	}, "Diamonds", function(k)
		potF.Visible = k == "Potion"
		caseF.Visible = k == "Case"
		golF.Visible = k == "Golem"
		amtF.Visible = k ~= "Golem" and k ~= "Pass"
		passF.Visible = k == "Pass"
	end, 15)
	gy += 56
	-- кількість (для ресурсів і зілля)
	amtF = frame(gF, 0, itemsTop, CW, 46, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local gAmount = input(amtF, 0, 0, 190, 46, "amount")
	U.presets(amtF, 198, 0, 82, 46, 6, { { "10", 10 }, { "100", 100 }, { "1K", 1000 }, { "10K", 10000 }, { "1M", 1000000 } }, gAmount)
	-- зілля
	potF = frame(gF, 0, itemsTop + 54, CW, 46, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
	local pitems = {}
	for _, d in Items.POTIONS do table.insert(pitems, { key = d.key, text = string.upper(d.key), color = "purple" }) end
	local gPot = U.choice(potF, 0, 0, (CW - 18) / 4, 44, 6, pitems, pitems[1] and pitems[1].key, nil, 16)
	-- кейс (10.11.2026)
	caseF = frame(gF, 0, itemsTop + 54, CW, 46, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
	local citems = {}
	for _, d in Items.CASES or {} do table.insert(citems, { key = d.key, text = string.upper(d.name or d.key), color = "orange" }) end
	local nC = math.max(1, #citems)
	local gCase = U.choice(caseF, 0, 0, (CW - 6 * (nC - 1)) / nC, 44, 6, citems, citems[1] and citems[1].key, nil, 15)
	-- голем
	golF = frame(gF, 0, itemsTop, CW, 64, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
	local gGolem = { kind = "stone", mut = 0, cls = "miner" }
	U.golemField(golF, 0, 0, 380, 64, gGolem)
	local gCnt = U.stepper(golF, 392, 9, 160, 46, 1, 1, 10)
	-- геймпас / драбина «до ступеня» / Lucky Roll: вибір з іконками; праворуч — ступінь (вікно вибору) або кількість
	passF = frame(gF, 0, itemsTop, CW, 64, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
	local lvlBtn, passCnt
	U.passField(passF, 0, 0, 380, 64, gPass, {}, function() refreshPassF() end)
	lvlBtn = button(passF, 392, 7, CW - 392, 50, "UP TO x2", "orange", function()
		local sp = SPECIAL[gPass.key]
		if not (sp and sp.level) then return end
		LevelPicker.open(sp.what, gLevel[sp.what], function(lv) gLevel[sp.what] = lv; refreshPassF() end)
	end, { textSize = 18 })
	local cntF = frame(passF, 392, 9, 220, 46, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	passCnt = U.stepper(cntF, 0, 0, 220, 46, 1, 1, 100)
	function refreshPassF()
		local sp = SPECIAL[gPass.key]
		lvlBtn.group.Visible = sp ~= nil and sp.level == true
		if sp and sp.level and lvlBtn.label then lvlBtn.label.Text = "UP TO " .. levelText(sp.what, gLevel[sp.what]) end
		cntF.Visible = sp ~= nil and not sp.level
	end
	refreshPassF()
	gy = itemsTop + 112
	label(gF, 0, gy, 220, 42, 15, "ALSO FOR JOINERS", MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5 })
	local gWin = U.choice(gF, 172, gy, (CW - 172 - 18) / 4, 42, 6, {
		{ key = 0, text = "NO" }, { key = 15, text = "15 MIN" }, { key = 60, text = "1 HOUR" }, { key = 1440, text = "1 DAY" },
	}, 0, nil, 15)
	gy += 50
	label(gF, 0, gy, CW, 36, 13, "Everyone online gets it now. «Also for joiners» — players who join during that time get it too (once per player).", MUTED, 1.4, { TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, TextWrapped = true })
	gy += 40
	button(gF, 0, gy, 320, 50, "GIVE EVERYONE", "green", function()
		local what = gWhat.value
		local n, item, desc
		if what == "Pass" then
			local sp = SPECIAL[gPass.key]
			if sp and sp.level then
				what = sp.what; n = gLevel[sp.what] or 1; item = ""
				desc = (sp.what == "MoneyTier" and "x2 Money" or "Fast Mutations") .. " up to " .. levelText(sp.what, n) .. " (who has less)"
			elseif sp then
				what = sp.what; n = passCnt.get(); item = ""; desc = n .. " × " .. sp.name
			else
				n = 1; item = gPass.key; desc = passName(gPass.key)
			end
		elseif what == "Golem" then
			n = gCnt.get(); item = golemItem(gGolem); desc = n .. " × " .. U.golemName(gGolem.kind, gGolem.mut)
		elseif what == "Case" then
			n = tonumber((string.gsub(gAmount.Text, "[,%s]", "")))
			if not n or n <= 0 then setStatus("Enter an amount", false); return end
			n = math.floor(n)
			if n > 1000 then setStatus("Max 1,000 cases at once", false); return end
			item = gCase.value
			local cn = item
			for _, d in Items.CASES or {} do if d.key == item then cn = d.name or d.key end end
			desc = U.num(n) .. " × " .. cn
		else
			n = tonumber((string.gsub(gAmount.Text, "[,%s]", "")))
			if not n or n <= 0 then setStatus("Enter an amount", false); return end
			item = what == "Potion" and gPot.value or ""
			desc = U.num(n) .. " " .. (what == "Potion" and (gPot.value .. " Potion") or what)
		end
		local win = gWin.value
		confirm("Give " .. desc .. " to EVERYONE" .. (win > 0 and (" + joiners for " .. (win >= 60 and (win // 60 .. " h") or (win .. " min"))) or "") .. "?", function()
			result(invoke("GrantAll", { what = what, amount = n, item = item, window = win }))
		end, "GIVE", "green")
	end)
	gy += 74

	-- Admin Abuse
	U.section(gF, 0, gy, "ADMIN ABUSE EVENTS (all servers)"); gy += 30
	local eKind = U.choice(gF, 0, gy, (CW - 16) / 3, 46, 8, {
		{ key = "luck", text = "ROLL LUCK", color = "green" }, { key = "mutluck", text = "MUTATION LUCK", color = "purple" },
		{ key = "money", text = "MONEY", color = "yellow" },
	}, "luck", nil, 18)
	gy += 56
	-- множник: готові кнопки або своє число в полі (x1.5, x25…; поле має перевагу, кнопка очищує поле)
	local MW = (CW - 170 - 4 * 6) / 4
	local eCustom
	local eMult = U.choice(gF, 0, gy, MW, 46, 6, {
		{ key = 2, text = "x2", color = "orange" }, { key = 3, text = "x3", color = "orange" },
		{ key = 5, text = "x5", color = "orange" }, { key = 10, text = "x10", color = "red" },
	}, 2, function() if eCustom then eCustom.Text = "" end end, 20)
	eCustom = input(gF, CW - 164, gy, 164, 46, "custom x")
	eCustom.TextXAlignment = Enum.TextXAlignment.Center
	eCustom:GetPropertyChangedSignal("Text"):Connect(function()
		local v = tonumber((string.gsub(eCustom.Text, "[xX%s]", "")))
		if v then eMult.set(nil) elseif eMult.value == nil and eCustom.Text == "" then eMult.set(2) end
	end)
	local function multValue(): number?
		local t = string.gsub(eCustom.Text, "[xX%s]", "")
		if t ~= "" then
			local v = tonumber(t)
			if not v or v ~= v or v <= 1 or (eKind.value == "money" and v > 1000) then return nil end
			return v
		end
		return eMult.value
	end
	gy += 56
	local eMin = U.choice(gF, 0, gy, (CW - 24) / 5, 42, 6, {
		{ key = 5, text = "5 MIN" }, { key = 15, text = "15 MIN" }, { key = 30, text = "30 MIN" }, { key = 60, text = "1 HOUR" }, { key = 180, text = "3 HOURS" },
	}, 15, nil, 15)
	gy += 52
	button(gF, 0, gy, 300, 50, "START", "green", function()
		local m = multValue()
		if not m then setStatus(eKind.value == "money" and "Money multiplier: 1.01 … 1000" or "Multiplier must be a number above 1", false); return end
		result(invoke("Event", { kind = eKind.value, mult = m, minutes = eMin.value }))
	end)
	button(gF, 310, gy, CW - 310, 50, "STOP", "red", function()
		result(invoke("Event", { kind = eKind.value, mult = 1 }))
	end)
	gy += 64
	-- активні події й черга (менші множники чекають, поки закінчиться більший): по рядку на вид
	local active = label(gF, 0, gy, CW, 84, 17, "", WHITE, 2, { TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, TextWrapped = true })
	gy += 96
	gF.Size = UDim2.fromOffset(CW, gy)
	gate(gF, 2)
	local function canvas() sc.CanvasSize = UDim2.fromOffset(0, y + (gF.Visible and gy or 0) + 10) end
	gF:GetPropertyChangedSignal("Visible"):Connect(canvas)
	canvas()
	task.spawn(function()
		while true do
			task.wait(1)
			if modalRoot.Visible and selTab == "global" then
				local now = workspace:GetServerTimeNow()
				local parts = {}
				for _, e in { { "EventLuck", "ROLL LUCK" }, { "EventMutLuck", "MUTATION LUCK" }, { "EventMoney", "MONEY" } } do
					local m = tonumber(workspace:GetAttribute(e[1])) or 1
					local u = tonumber(workspace:GetAttribute(e[1] .. "Until")) or 0
					if m > 1 and u > now then
						local function xs(v) return (v >= 1e6) and NumberFormat.short(v) or tostring(v) end
						local line = e[2] .. " x" .. xs(m) .. " (" .. U.dur(u - now) .. ")"
						local okQ, q = pcall(HttpService.JSONDecode, HttpService, workspace:GetAttribute(e[1] .. "Queue") or "[]")
						if okQ and type(q) == "table" then
							for _, it in q do line ..= "  →  x" .. xs(it.m) .. " (" .. U.dur(it.d or 0) .. ")" end
						end
						table.insert(parts, line)
					end
				end
				active.Text = #parts > 0 and table.concat(parts, "\n") or "No active events"
				active.TextColor3 = #parts > 0 and GOOD or MUTED
			end
		end
	end)
end

-- =====================================================================
-- ===== ME (свої інструменти: швидкість, стрибок, політ, крізь стіни) =====
-- =====================================================================
do
	local pg = pages.me
	local sc = U.scroller(pg, 0, 0, PW, PH, "Me")
	local y = 0
	local speed, jump, flySpeed = 16, 50, 60
	local flying, noclip = false, false
	local flyConn, noclipConn, att, lv, ao = nil, nil, nil, nil, nil
	local saved = {}
	local function hum(): Humanoid?
		return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	end
	local function applyMove()
		local h = hum()
		if not h then return end
		h.WalkSpeed = speed
		h.UseJumpPower = true
		h.JumpPower = jump
	end
	local function stopFly()
		flying = false
		if flyConn then flyConn:Disconnect(); flyConn = nil end
		for _, o in { lv, ao, att } do if o then o:Destroy() end end
		lv, ao, att = nil, nil, nil
		local h = hum()
		if h then h.PlatformStand = false end
	end
	local function startFly()
		local ch = player.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local h = hum()
		if not (hrp and h) then return false end
		flying = true
		att = new("Attachment", { Name = "AdminFlyAtt" }, hrp)
		lv = new("LinearVelocity", { Name = "AdminFly", Attachment0 = att, MaxForce = 1e7, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
			RelativeTo = Enum.ActuatorRelativeTo.World, VectorVelocity = Vector3.zero }, hrp)
		ao = new("AlignOrientation", { Name = "AdminFlyAlign", Attachment0 = att, Mode = Enum.OrientationAlignmentMode.OneAttachment,
			RigidityEnabled = true }, hrp)
		h.PlatformStand = true
		flyConn = RunService.RenderStepped:Connect(function()
			local cam = workspace.CurrentCamera
			if not (cam and lv and lv.Parent) then return end
			local d = Vector3.zero
			if not UIS:GetFocusedTextBox() then
				if UIS:IsKeyDown(Enum.KeyCode.W) then d += cam.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cam.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then d += cam.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cam.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.yAxis end
				if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then d -= Vector3.yAxis end
			end
			lv.VectorVelocity = d.Magnitude > 0.01 and d.Unit * flySpeed or Vector3.zero
			local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
			if look.Magnitude > 0.01 then ao.CFrame = CFrame.lookAt(Vector3.zero, look) end
		end)
		return true
	end
	local function setNoclip(on: boolean)
		noclip = on
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
		if on then
			noclipConn = RunService.Stepped:Connect(function()
				local ch = player.Character
				if not ch then return end
				for _, d in ch:GetDescendants() do
					if d:IsA("BasePart") and d.CanCollide then
						if saved[d] == nil then saved[d] = true end
						d.CanCollide = false
					end
				end
			end)
		else
			for part in saved do if part.Parent then part.CanCollide = true end end
			table.clear(saved)
		end
	end
	player.CharacterAdded:Connect(function(ch)
		stopFly()
		table.clear(saved)
		ch:WaitForChild("Humanoid", 10)
		task.wait(0.2)
		if speed ~= 16 or jump ~= 50 then applyMove() end
	end)

	U.section(sc, 0, y, "WALK SPEED"); y += 30
	local cs = U.choice(sc, 0, y, (CW - 24) / 5, 44, 6, {
		{ key = 16, text = "NORMAL", color = "green" }, { key = 32, text = "x2", color = "blue" }, { key = 50, text = "50", color = "blue" },
		{ key = 100, text = "100", color = "orange" }, { key = 200, text = "200", color = "red" },
	}, 16, function(v) speed = v; applyMove() end, 17)
	y += 64
	U.section(sc, 0, y, "JUMP POWER"); y += 30
	U.choice(sc, 0, y, (CW - 18) / 4, 44, 6, {
		{ key = 50, text = "NORMAL", color = "green" }, { key = 100, text = "100", color = "blue" },
		{ key = 200, text = "200", color = "orange" }, { key = 400, text = "400", color = "red" },
	}, 50, function(v) jump = v; applyMove() end, 17)
	y += 64
	U.section(sc, 0, y, "FLY  (W A S D, Space — up, Ctrl / Q — down)"); y += 30
	local flyBtn
	flyBtn = button(sc, 0, y, 200, 50, "FLY: OFF", "gray", function()
		if flying then stopFly() else
			if not startFly() then setStatus("No character", false) end
		end
		flyBtn:setText(flying and "FLY: ON" or "FLY: OFF")
		flyBtn:setColor(flying and "green" or "gray")
	end)
	U.choice(sc, 210, y + 3, (CW - 210 - 18) / 4, 44, 6, {
		{ key = 30, text = "SLOW" }, { key = 60, text = "NORMAL" }, { key = 120, text = "FAST" }, { key = 250, text = "TURBO" },
	}, 60, function(v) flySpeed = v end, 15)
	y += 70
	U.section(sc, 0, y, "NOCLIP (walk through walls)"); y += 30
	local ncBtn
	ncBtn = button(sc, 0, y, 200, 50, "NOCLIP: OFF", "gray", function()
		setNoclip(not noclip)
		ncBtn:setText(noclip and "NOCLIP: ON" or "NOCLIP: OFF")
		ncBtn:setColor(noclip and "green" or "gray")
	end, { textSize = 18 })
	y += 70
	U.section(sc, 0, y, "QUICK"); y += 30
	button(sc, 0, y, 260, 50, "MY PROFILE", "blue", function() openPlayer(player.UserId) end)
	button(sc, 270, y, CW - 270, 50, "RESET ALL", "orange", function()
		stopFly(); setNoclip(false)
		speed, jump = 16, 50
		applyMove()
		cs.set(16)
		flyBtn:setText("FLY: OFF"); flyBtn:setColor("gray")
		ncBtn:setText("NOCLIP: OFF"); ncBtn:setColor("gray")
		setStatus("Back to normal", true)
	end)
	y += 70
	label(sc, 0, y, CW, 40, 13, "These tools only affect your own character on this server and reset when you leave.", MUTED, 1.4, { TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, TextWrapped = true })
	y += 44
	sc.CanvasSize = UDim2.fromOffset(0, y)
end

-- =====================================================================
-- ===== SERVERS =====
-- =====================================================================
do
	local pg = pages.servers
	local list = U.scroller(pg, 0, 64, PW, PH - 64, "Servers")
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local summary = label(pg, 150, 0, 270, 52, 18, "", WHITE, 2.2, { TextXAlignment = LEFT, ZIndex = 5 })
	local function load()
		local res = invoke("Servers")
		if not res.ok then result(res); return end
		U.clear(list)
		local total = 0
		for i, s in res.servers or {} do
			total += s.n or 0
			local row = frame(list, 0, 0, CW, 56, nil, { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 4 })
			cardBg(row, 0, 0, CW, 56, 4)
			label(row, 16, 6, 300, 26, 20, tostring(s.job) .. (s.here and "  (this)" or ""), s.here and GOOD or WHITE, 2.2, { TextXAlignment = LEFT, ZIndex = 5 })
			label(row, 16, 32, 560, 20, 14, (s.n or 0) .. " players · up " .. U.dur(s.up or 0) .. " · version " .. tostring(s.place or "?"), MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5 })
		end
		summary.Text = #(res.servers or {}) .. " servers · " .. total .. " players"
	end
	button(pg, 0, 0, 140, 52, "REFRESH", "green", load)
	local sd = button(pg, PW - 240, 0, 240, 52, "SHUTDOWN ALL", "red", function()
		confirm("Kick EVERYONE from ALL servers (restart for an update)?", function() result(invoke("Shutdown", {})) end, "SHUTDOWN")
	end, { textSize = 19 })
	gate(sd.group, 3)
	onShow.servers = load
end

-- =====================================================================
-- ===== LOGS =====
-- =====================================================================
do
	-- THIS SERVER — живий журнал цього сервера (останні 150 подій); ALL HISTORY — увесь журнал з усіх серверів, що будь-коли
	-- працювали (DataStore GolemLog, по днях UTC): ‹ OLDER / NEWER › гортають дні. SUSPECT — запити до панелі без ролі.
	local pg = pages.logs
	local list = U.scroller(pg, 0, 162, PW, PH - 162, "Logs")
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local COLORS = { mint = GOOD, burn = BAD, dupe = BAD, foreign = BAD, suspect = BAD, admin = GOLD, grant = C("7fd0ff"), legacy = MUTED, move = WHITE }
	local GROUPS = { all = nil, admin = { admin = true }, grant = { grant = true }, mint = { mint = true, legacy = true }, burn = { burn = true },
		dupe = { dupe = true, foreign = true }, suspect = { suspect = true } }
	local filter = input(pg, 150, 0, PW - 466, 52, "Search…")
	local logs = {}
	local scope, back = "server", 0
	local draw, load
	U.choice(pg, PW - 306, 0, 150, 52, 6, {
		{ key = "server", text = "THIS SERVER", color = "blue" }, { key = "all", text = "ALL HISTORY", color = "orange" },
	}, "server", function(v) scope = v; back = 0; load() end, 14)
	local kind = U.choice(pg, 0, 62, (PW - 36) / 7, 42, 6, {
		{ key = "all", text = "ALL", color = "blue" }, { key = "admin", text = "ADMIN", color = "yellow" }, { key = "grant", text = "GIVES", color = "blue" },
		{ key = "mint", text = "NEW", color = "green" }, { key = "burn", text = "DELETED", color = "red" }, { key = "dupe", text = "DUPES", color = "red" },
		{ key = "suspect", text = "SUSPECT", color = "red" },
	}, "all", function() draw() end, 14)
	local older = button(pg, 0, 112, 140, 42, "‹ OLDER", "gray", function() if scope == "all" then back += 1; load() end end, { textSize = 15 })
	local newer = button(pg, PW - 140, 112, 140, 42, "NEWER ›", "gray", function() if scope == "all" and back > 0 then back -= 1; load() end end, { textSize = 15 })
	local dayLbl = label(pg, 150, 112, PW - 300, 42, 16, "", WHITE, 1.6, { ZIndex = 5 })
	draw = function()
		U.clear(list)
		local q = string.lower(filter.Text)
		local grp = GROUPS[kind.value]
		local n = 0
		for i, e in logs do
			if grp and not grp[e.e] then continue end
			local nm = e.k and U.golemName(e.k, e.m) or ""
			local when = scope == "all" and os.date("!%H:%M:%S", e.t or 0) or os.date("%H:%M:%S", e.t or 0)
			local text = when .. "  " .. string.upper(tostring(e.e)) .. "  user " .. tostring(e.u or "")
				.. (nm ~= "" and ("  " .. nm) or "") .. (e.g and ("  " .. e.g) or "") .. (e.r and ("  [" .. tostring(e.r) .. "]") or "")
				.. (e.x and ("  " .. tostring(e.x)) or "")
			if q == "" or string.find(string.lower(text), q, 1, true) then
				n += 1
				if n > 300 then
					label(list, 0, 0, CW, 30, 14, "Showing the first 300 — refine the search", MUTED, 1.4, { ZIndex = 5, LayoutOrder = 1e9 })
					break
				end
				local row = frame(list, 0, 0, CW, 30, nil, { BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 4 })
				local t = label(row, 6, 0, CW - 12, 30, 14, text, COLORS[e.e] or WHITE, 1.4, { TextXAlignment = LEFT, ZIndex = 5, FontFace = MONO, TextTruncate = Enum.TextTruncate.AtEnd })
				t.TextYAlignment = Enum.TextYAlignment.Center
			end
		end
		if n == 0 then label(list, 0, 0, CW, 40, 18, scope == "all" and "No events this day" or "No events (this server)", MUTED, 2, { ZIndex = 5 }) end
	end
	load = function()
		older:setColor(scope == "all" and "blue" or "gray")
		newer:setColor((scope == "all" and back > 0) and "blue" or "gray")
		dayLbl.Text = scope == "all" and "Loading…" or "LIVE · this server · last 150 events"
		local res = invoke("Logs", { scope = scope, back = back })
		if not res.ok then result(res); return end
		logs = res.logs or {}
		if scope == "all" then
			local d = tostring(res.day or "")
			dayLbl.Text = string.format("%s.%s.%s (UTC) · %d events%s", string.sub(d, 7, 8), string.sub(d, 5, 6), string.sub(d, 1, 4), #logs,
				back == 0 and " · today" or "")
		end
		draw()
	end
	filter:GetPropertyChangedSignal("Text"):Connect(function() draw() end)
	button(pg, 0, 0, 140, 52, "REFRESH", "green", function() load() end)
	onShow.logs = function() load() end
end

-- =====================================================================
-- ===== ADMINS (лише owner) =====
-- =====================================================================
do
	local pg = pages.admins
	local sc = U.scroller(pg, 0, 0, PW, PH, "Admins")
	local ROLE_COLOR = { owner = "red", admin = "orange", mod = "blue" }
	local load
	local function draw(list, online)
		U.clear(sc)
		local y = 0
		U.section(sc, 0, y, "ADD STAFF"); y += 30
		local who = input(sc, 0, y, CW, 46, "Name or UserId")
		y += 54
		local role = U.choice(sc, 0, y, 200, 44, 8, {
			{ key = "admin", text = "ADMIN", color = "orange" }, { key = "mod", text = "MODERATOR", color = "blue" },
		}, "admin", nil, 17)
		button(sc, 416, y, CW - 416, 46, "ADD", "green", function()
			local t = string.gsub(who.Text, "%s", "")
			if t == "" then setStatus("Enter a name or UserId", false); return end
			local num = tonumber(t)
			confirm("Give " .. string.upper(role.value) .. " access to " .. t .. "?", function()
				if result(invoke("SetRole", { u = num, name = not num and t or nil, role = role.value })) then who.Text = ""; load() end
			end, "ADD", "green")
		end)
		y += 56
		label(sc, 0, y, CW, 34, 13, "ADMIN — everything except shutdown and staff list. MODERATOR — view, kick, ban up to 24 h, announce, message, teleport, freeze, spectate.", MUTED, 1.4, { TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, TextWrapped = true })
		y += 44
		U.section(sc, 0, y, "STAFF (" .. #list .. ")"); y += 30
		for _, e in list do
			cardBg(sc, 0, y, CW, 64, 4)
			local av = new("ImageLabel", { BackgroundColor3 = C("2a2e35"), Position = UDim2.fromOffset(8, y + 8), Size = UDim2.fromOffset(48, 48), ZIndex = 5,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(e.u) .. "&w=150&h=150" }, sc)
			stroke(av, INK, 2)
			label(sc, 66, y + 6, 300, 28, 21, "@" .. tostring(e.name), WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
			label(sc, 66, y + 36, 330, 20, 13, "ID " .. tostring(e.u) .. (e.fixed and " · AdminConfig" or (" · added " .. (e.t and os.date("%Y-%m-%d", e.t) or "?"))), MUTED, 1.4, { TextXAlignment = LEFT, ZIndex = 5 })
			local rb = button(sc, CW - 268, y + 10, 140, 44, string.upper(e.r == "mod" and "MODERATOR" or e.r), ROLE_COLOR[e.r] or "gray", nil, { z = 6, textSize = 15, half = true })
			if not e.fixed then
				rb.onClick = function()
					local nr = e.r == "admin" and "mod" or "admin"
					confirm("Change @" .. tostring(e.name) .. " to " .. string.upper(nr == "mod" and "MODERATOR" or nr) .. "?", function()
						if result(invoke("SetRole", { u = e.u, role = nr })) then load() end
					end, "CHANGE", "orange")
				end
				button(sc, CW - 120, y + 10, 112, 44, "REMOVE", "red", function()
					confirm("Remove staff access from @" .. tostring(e.name) .. "?", function()
						if result(invoke("SetRole", { u = e.u, role = "none" })) then load() end
					end, "REMOVE")
				end, { z = 6, textSize = 17 })
			else
				rb.enabled = false
			end
			y += 72
		end
		y += 10
		U.section(sc, 0, y, "ONLINE PLAYERS"); y += 30
		local staff = {}
		for _, e in list do staff[e.u] = true end
		local n = 0
		for _, p in online do
			if not staff[p.u] then
				n += 1
				cardBg(sc, 0, y, CW, 56, 4)
				label(sc, 14, y, 300, 56, 19, p.name, WHITE, 2.2, { TextXAlignment = LEFT, ZIndex = 5 })
				button(sc, CW - 300, y + 6, 140, 44, "ADMIN", "orange", function()
					confirm("Give ADMIN access to @" .. p.name .. "?", function()
						if result(invoke("SetRole", { u = p.u, role = "admin" })) then load() end
					end, "ADD", "green")
				end, { z = 6, textSize = 16 })
				button(sc, CW - 152, y + 6, 140, 44, "MODERATOR", "blue", function()
					confirm("Give MODERATOR access to @" .. p.name .. "?", function()
						if result(invoke("SetRole", { u = p.u, role = "mod" })) then load() end
					end, "ADD", "green")
				end, { z = 6, textSize = 14 })
				y += 64
			end
		end
		if n == 0 then label(sc, 0, y, CW, 30, 15, "Everyone online is already staff", MUTED, 1.6, { TextXAlignment = LEFT, ZIndex = 5 }); y += 34 end
		sc.CanvasSize = UDim2.fromOffset(0, y + 10)
	end
	load = function()
		local res = invoke("Roles", {})
		if not res.ok then result(res); return end
		local pl = invoke("Players", {})
		draw(res.roles or {}, (pl.ok and pl.players) or {})
	end
	onShow.admins = load
end

layoutTabs()
selectTab("players")
