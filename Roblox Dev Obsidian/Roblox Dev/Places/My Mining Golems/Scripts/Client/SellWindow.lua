-- SellWindow — модальне вікно лавки «Sell» по центру екрана (інвентар руди й злитків слотами, вибір кількості, продаж).
-- Де: StarterPlayer/StarterPlayerScripts/SellWindow (LocalScript). Інтерфейс будується кодом (ScreenGui SellWindow).
-- Макет: ui/sell_window (веб-макет v4, слот «C · Сяйво»). Полотно 1286 × 740, рамка 1206 × 650 (як Forge);
-- розмір і місце на екрані — Shared/WindowFit.place (усі вікна 1 в 1). Іконки слотів — 3D (Shared/ItemViewport).
-- Стиль — як вікно Forge: квадратне вікно зі studs, кнопки «стиль A» (Shared/StyleA), заголовок КАПСОМ (зелений перелив).
--
-- Що у вікні:
--   • рядок «Selected»: шкала «вибрано N · $X / max $Y» (сума вже × TotalMulti);
--   • зліва підписи рядів «Ore» / «Bars» з вартістю ряду і кнопками «All Ore» / «All Bars» (коли вибрано все — червоні «No Ore» / «No Bars»);
--   • два ряди квадратних слотів (руда / злитки), колонка = вид руди. Слот: іконка без фону на темному з кольоровим сяйвом,
--     «×N» (скільки є), назва, лаймова плашка з кількістю вибраного, лаймова рамка, коли вибрано;
--     «+» (зелена) і «−» (червона): клік — ±1, затиснути — повтор, що пришвидшується (крок 1 → 2 → 5 → 15 → 50);
--   • ряди гортаються разом по горизонталі (коли руд більше, ніж влазить): колесо мишки, перетягування, повзунок знизу;
--   • клік по слоту — міні-меню з повзунком (поява 0,85 → 1,05 → 1): −/+, «All» (на максимумі — червона «Clear»), «Done»;
--   • кнопки внизу: Select All (синя), Clear (червона), Sell $X (зелена; нічого не вибрано — сіра й хитається).
-- Наведення на слот: ×1,025 і нахил до 1,5° у бік мишки (удвічі слабше за картки прокачки ролу), натискання — 0,96.
--   Звук наведення слота — SoundService/SlotHover (порожній SoundId = без звуку; звук підбере користувач).
-- Коли видно: власник ніші стоїть у колі своєї лавки (Niche*/Sell/Ring/RingCenter, радіус SellRig.RING_R). Вийшов — вікно закривається;
--   хрестик закриває до наступного входу. Анімації голема (SellClient) від вікна не залежать і нікого не тримають.
-- Дані: інвентар — атрибути гравця Ore_<руда>, Bars_<руда>; TotalMulti. Ціни — Shared/ForgeConfig (злиток = × BAR_MULT).
-- Продаж: Remotes/SellAction ("Sell", { [Ore_Coal] = n, [Bars_Iron] = n, ... }); сервер (SellService) перевіряє все сам.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local CAS = game:GetService("ContextActionService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local Rig = require(RS.Shared:WaitForChild("SellRig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local ItemVP = require(RS.Shared:WaitForChild("ItemViewport")) -- 3D-моделі руди й злитків у слотах замість PNG
local UISfx = require(RS.Shared:WaitForChild("UISfx"))
local UISounds = require(RS.Shared:WaitForChild("UISounds")) -- hover / tap для кнопок +/− на слотах (вони без StyleA.bind)
local Action = RS:WaitForChild("Remotes"):WaitForChild("SellAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ORE = Cfg.ORES

-- ===== іконки й кольори сяйва слотів =====
local ICONS = {
	ore_Coal = StyleA.ASSETS.forge_ore_coal_v2,
	ore_Copper = StyleA.ASSETS.forge_ore_copper_v2,
	ore_Iron = StyleA.ASSETS.forge_ore_iron_v2,
	bar_Coal = "rbxassetid://101473380326305",
	bar_Copper = "rbxassetid://106483042191242",
	bar_Iron = StyleA.ASSETS.forge_bar_iron_v2,
}
local TONE = { Coal = "6d737c", Copper = "e0743c", Iron = "d9b08a", Tin = "a9bccb", Silver = "dfe6ee", Gold = "ffc928" }
-- мапи 3–7 (03.11.2026): тон — колір руди з ForgeConfig
for _, o in require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ForgeConfig")).ALL_ORES do
	if not TONE[o.key] then TONE[o.key] = o.color:ToHex() end
end

-- ===== константи макета (одиниці дизайну) =====
-- рамка 1206 × 650 — ті самі пропорції, що в Inventory (980 × 528): на екрані вікна 1 в 1 (Shared/WindowFit.match)
local CANVAS_W, CANVAS_H = 1286, 740
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1206, 650
local CX0, CW = 42, 1122
local SL, GAP = 160, 22
local COL = SL + GAP
local ROWY = { 20, 192 }
local PADX = 14
local LBLX = CX0 + 6
local GX0, GY0 = CX0 + 142, 128
local VW, VH = CX0 + CW - GX0, 362
local SBY, SBH = GY0 + VH + 6, 20
local BTN_Y = 536
local MW, MH, MPAD = 520, 356, 30
local HP = 16 -- запас CanvasGroup слота (рамка, плашка, тінь не обрізаються)
local GLOW_N, GLOW_R, GLOW_A, GLOW_P = 30, 58, 0.85, 0.9 -- сяйво слота (R 58 — влазить у слот без обрізання): кількість кіл, радіус, непрозорість у центрі
local GLOW_T = {} -- прозорість i-го кола (i = 1 — найменше)
do
	local function op(d) return GLOW_A * math.max(0, 1 - d / GLOW_R) ^ GLOW_P end
	for i = 1, GLOW_N do
		local outer, inner = GLOW_R * i / GLOW_N, GLOW_R * (i - 1) / GLOW_N
		-- кільце між inner і outer: (1 − op(inner)) = (1 − op(outer)) · (1 − a_i)
		local a = 1 - (1 - op(inner)) / math.max(1e-6, 1 - op(outer))
		GLOW_T[i] = 1 - math.clamp(a, 0, 1)
	end
end
local REFRESH = 0.15
local EXIT_PAD = 0.5

-- ===== кольори =====
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local LIME = { { 0, "eaff9a" }, { 0.5, "c3f04a" }, { 1, "8ccc22" } }
local TRACK = { { 0, "1a1d22" }, { 1, "353b44" } }
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }

-- ===== помічники (як у ForgeWindow) =====
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
-- текст за «центром великих літер» cy: бокс 1,2 × розміру з центром у cy
local function textAt(parent, x, cy, w, size, text, color, sw, props)
	return label(parent, x, cy - size * 0.6, w, size * 1.2, size, text, color, sw, props)
end
local function gloss(parent, inset, h, alpha)
	return new("Frame", { Name = "Gloss", Position = UDim2.fromOffset(inset, inset), Size = UDim2.new(1, -2 * inset, 0, h),
		BackgroundColor3 = WHITE, BackgroundTransparency = 1 - alpha, BorderSizePixel = 0 }, parent)
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
local function isMove(inp: InputObject): boolean
	return inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch
end

-- квадратне вікно зі studs (як Forge): тінь, темний обідок, світла лінія, панель зі studs і затіненням. Повертає (window, вміст)
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

-- кнопка «стиль A» + квадратна тінь. opt: shadowDy, color, text, textSize, icon, iconPad, z, noSound.
-- b.onClick(b); b.base — колір, коли кнопка доступна; b:enable(on) — сіра й хитається, коли недоступна.
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, shine = opt.shine, zIndex = opt.z + 1 })
	b.shadow = sh
	StyleA.follow(b, sh) -- тінь масштабується й хитається разом з кнопкою
	b.base = opt.color
	b.onClick = nil
	if opt.noSound then b.root:SetAttribute("NoHoverSound", true) end
	if not opt.manual then
		StyleA.bind(b, { debounce = opt.debounce or 0.15, onClick = function() if b.onClick then b.onClick(b) end end })
	end
	function b.enable(self, on: boolean)
		self.enabled = on
		self:setColor(on and self.base or "gray")
	end
	function b.recolor(self, color: string)
		self.base = color
		if self.enabled then self:setColor(color) end
	end
	return b
end

-- шкала: доріжка + заливка (лайм) з блиском + текст по центру (RichText)
local function makeBar(parent, x, y, w, h, textSize, z)
	local track = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 1 })
	vgrad(track, TRACK); stroke(track, INK, 4)
	local fill = frame(track, 0, 0, h, h, WHITE, { Visible = false, ZIndex = 1 })
	vgrad(fill, LIME)
	gloss(fill, 0, math.floor(h * 0.36 + 0.5), 0.32)
	local text = textSize and label(track, 0, 0, w, h, textSize, "", WHITE, math.floor(textSize * 0.1 + 0.5), { ZIndex = 2, RichText = true }) or nil
	return { track = track, fill = fill, text = text, w = w, h = h, fw = -1, tw = nil }
end
local function setBar(bar, frac: number, text: string?)
	if frac ~= frac then frac = 0 end
	frac = math.clamp(frac, 0, 1)
	if text and bar.text and bar.text.Text ~= text then bar.text.Text = text end
	local fw = frac > 0 and math.max(frac, bar.h / bar.w) * bar.w or 0
	if math.abs(fw - bar.fw) < 0.01 then return end
	bar.fw = fw
	if bar.tw then bar.tw:Cancel(); bar.tw = nil end
	if fw <= 0 then bar.fill.Visible = false; bar.fill.Size = UDim2.fromOffset(bar.h, bar.h); return end
	if not bar.fill.Visible then bar.fill.Visible = true; bar.fill.Size = UDim2.fromOffset(bar.h, bar.h) end
	bar.tw = tween(bar.fill, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(fw, bar.h) })
end

-- затиснути кнопку: дія одразу; через 0,38 с — повтор, що пришвидшується (інтервал 170 → 30 мс), і крок росте
-- 1 → 2 → 5 → 15 → 50 (після 1,2 / 2,5 / 4 / 6 с). fn() → false — далі не можна (кнопка хитається / повтор зупиняється).
-- Звук tap — на КОЖЕН крок повтору (правка користувача): що швидший повтор, то частіше звук; тон ледь росте
-- з прискоренням (PlaybackSpeed до ×1,12). minGap 0,025 с — щоб копії не злипались.
local holdActive = nil
local function holdRepeat(b, fn: () -> boolean)
	local token = 0
	local function stop()
		token += 1
		if holdActive == stop then holdActive = nil end
		tween(b.scale, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = b.hover and 1.04 or 1 })
	end
	b.root.InputBegan:Connect(function(inp)
		if not isPress(inp) then return end
		if holdActive then holdActive() end
		token += 1
		local my = token
		holdActive = stop
		b.scale.Scale = 0.92
		if not fn() then StyleA.shake(b); stop(); return end
		UISounds.play("tap", 0.025) -- звук натискання; далі — на кожен крок автоповтору
		local t0 = os.clock()
		task.delay(0.38, function()
			while token == my do
				local el = os.clock() - t0
				local n = el < 1.2 and 1 or el < 2.5 and 2 or el < 4 and 5 or el < 6 and 15 or 50
				local done = 0
				for _ = 1, n do
					if not fn() then break end
					done += 1
				end
				if done > 0 then UISounds.play("tap", 0.025, 1 + math.min(0.12, el * 0.02)) end
				if done < n then stop(); return end
				task.wait(math.max(0.03, 0.17 - el * 0.07))
			end
		end)
	end)
	b.root.MouseLeave:Connect(function() b.hover = false; if holdActive == stop then stop() end end)
	-- звук наведення тут (атрибут NoHoverSound лишаємо — автоматичний UIHover не дублює)
	b.root.MouseEnter:Connect(function() b.hover = true; UISounds.play("hover", 0.05); if holdActive ~= stop then tween(b.scale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.04 }) end end)
end
UIS.InputEnded:Connect(function(inp) if isPress(inp) and holdActive then holdActive() end end)

-- =====================================================================
-- ===== дані =====
-- =====================================================================
local ITEMS = {} -- { key = "Ore_Coal", ore = o, kind = "ore" | "bar", price, name, icon, tone }
local sel: { [string]: number } = {}
-- руда поточної мапи (Cfg.ORES оновлюється при зміні Stage; тоді слоти перебудовуються — buildSlots нижче)
local function buildItems()
	table.clear(ITEMS)
	for _, o in ORE do
		table.insert(ITEMS, { key = "Ore_" .. o.key, ore = o, kind = "ore", price = o.price, name = o.key, icon = ICONS["ore_" .. o.key] or "", tone = C(TONE[o.key] or "9aa3ad") })
	end
	for _, o in ORE do
		if not Cfg.canSmelt(o) then continue end -- злитків вугілля не буває
		table.insert(ITEMS, { key = "Bars_" .. o.key, ore = o, kind = "bar", price = o.price * Cfg.BAR_MULT, name = o.key, icon = ICONS["bar_" .. o.key] or "", tone = C(TONE[o.key] or "9aa3ad") })
	end
	table.clear(sel)
	for _, it in ITEMS do sel[it.key] = 0 end
end
buildItems()

local function inv(key: string): number return math.max(0, math.floor(tonumber(player:GetAttribute(key)) or 0)) end
-- заблоковане в інвентарі (замок, InvLocks) не продається: для продажу його кількість = 0 (сервер теж відкидає)
local LOCK_ICON = "rbxassetid://122986621331664" -- inv_icon_lock
local lockedKeys: { [string]: boolean } = {}
local function readLocks()
	table.clear(lockedKeys)
	local ok, l = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), player:GetAttribute("InvLocks") or "[]")
	if ok and type(l) == "table" then for _, k in l do if type(k) == "string" then lockedKeys[k] = true end end end
end
readLocks()
local function sellable(key: string): number return lockedKeys[key] and 0 or inv(key) end
local function multi(): number return tonumber(player:GetAttribute("TotalMulti")) or 1 end
local function selCount(): number local s = 0 for _, it in ITEMS do s += sel[it.key] end return s end
local function selValue(): number local s = 0 for _, it in ITEMS do s += sel[it.key] * it.price end return s end
local function totalCount(): number local s = 0 for _, it in ITEMS do s += sellable(it.key) end return s end
local function totalValue(): number local s = 0 for _, it in ITEMS do s += sellable(it.key) * it.price end return s end

-- =====================================================================
-- ===== збірка вікна =====
-- =====================================================================
local old = playerGui:FindFirstChild("SellWindow")
if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "SellWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10 }, playerGui)
local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)

local _, content = windowFrame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, 1, 14)

-- рядок «Selected»
textAt(content, CX0, 98, 170, 28, "Selected", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1 })
local selBar = makeBar(content, 212, 73, CW - 170, 50, 26, 1)

-- звук наведення слота (порожній SoundId — тиша; звук підбере користувач)
local function slotHoverSound()
	local s = SoundService:FindFirstChild("SlotHover")
	if s and s:IsA("Sound") and s.SoundId ~= "" then s.TimePosition = 0; s:Play() end
end

-- ===== вікно перегляду слотів + смуга (гортаються разом) =====
local viewport = frame(content, GX0, GY0, VW, VH, nil, { Name = "Slots", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 2 })
local strip = frame(viewport, 0, 0, 10, VH, nil, { Name = "Strip", BackgroundTransparency = 1, ZIndex = 1 })
local ncol = #ORE
local STRIP_W = PADX * 2 + ncol * COL - GAP
strip.Size = UDim2.fromOffset(STRIP_W, VH)
local scrollX = 0
local sbTrack = frame(content, GX0, SBY, VW, SBH, WHITE, { Name = "ScrollTrack", Active = true, ZIndex = 3 })
vgrad(sbTrack, TRACK); stroke(sbTrack, INK, 3)
local sbThumb = frame(sbTrack, 0, 0, 80, SBH, WHITE, { Name = "Thumb", Active = true, ZIndex = 2 })
vgrad(sbThumb, LIME); gloss(sbThumb, 0, 7, 0.32)

local function maxScroll(): number return math.max(0, STRIP_W - VW) end
local function layoutThumb()
	local ms = maxScroll()
	local tw = math.max(60, VW * VW / STRIP_W)
	sbThumb.Size = UDim2.fromOffset(tw, SBH)
	sbThumb.Position = UDim2.fromOffset(ms > 0 and scrollX / ms * (VW - tw) or 0, 0)
end
local function setScroll(x: number)
	scrollX = math.clamp(x, 0, maxScroll())
	strip.Position = UDim2.fromOffset(-scrollX, 0)
	layoutThumb()
end
sbTrack.Visible = maxScroll() > 0
setScroll(0)
-- одиниць дизайну в одному пікселі екрана
local function unitsPerPx(): number
	local a = viewport.AbsoluteSize.X
	return a > 0 and VW / a or 1
end

-- перетягування рядів / повзунка, колесо мишки
local drag = nil -- { x, s, moved, thumb }
local dragEndAt = -1 -- коли закінчилось перетягування рядів (клік одразу після нього не відкриває меню)
local function beginDrag(inp: InputObject, thumb: boolean)
	if not isPress(inp) then return end
	drag = { x = inp.Position.X, s = scrollX, moved = false, thumb = thumb }
end
local function wheel(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseWheel and maxScroll() > 0 then setScroll(scrollX - inp.Position.Z * 90) end
end
viewport.InputBegan:Connect(function(inp) beginDrag(inp, false) end)
viewport.InputChanged:Connect(wheel)
sbThumb.InputBegan:Connect(function(inp) beginDrag(inp, true) end)
sbTrack.InputBegan:Connect(function(inp)
	if not isPress(inp) or drag then return end
	local f = (inp.Position.X - sbTrack.AbsolutePosition.X) / math.max(1, sbTrack.AbsoluteSize.X)
	setScroll(f * maxScroll())
end)
UIS.InputChanged:Connect(function(inp)
	if not drag or not isMove(inp) or maxScroll() <= 0 then return end
	local dx = (inp.Position.X - drag.x) * unitsPerPx()
	if drag.thumb then
		local tw = sbThumb.Size.X.Offset
		setScroll(drag.s + dx * maxScroll() / math.max(1, VW - tw))
	else
		if math.abs(dx) > 6 then drag.moved = true end
		if drag.moved then setScroll(drag.s - dx) end
	end
end)
UIS.InputEnded:Connect(function(inp)
	if isPress(inp) and drag then
		if drag.moved then dragEndAt = os.clock() end
		drag = nil
	end
end)

-- ===== слоти =====
local slots = {}
local mini = { open = false, slot = nil }
local openMini -- нижче
local refresh -- нижче

local function toast(s, text: string)
	s.toast.Text = text
	s.toast.Visible = true
	s.toastTok += 1
	local my = s.toastTok
	task.delay(0.7, function() if s.toastTok == my then s.toast.Visible = false end end)
end
-- ±n до вибраного; повертає false, якщо далі не можна (і показує «MAX» / «EMPTY» / «0»)
local function add(s, n: number): boolean
	local it = s.it
	if lockedKeys[it.key] and n > 0 then toast(s, "LOCKED"); return false end
	local have = sellable(it.key)
	local v = sel[it.key] + n
	if v > have or v < 0 then
		toast(s, n > 0 and (have > 0 and "MAX" or "EMPTY") or "0")
		return false
	end
	sel[it.key] = v
	refresh()
	return true
end

-- наведення слотів: масштаб і нахил плавно (експонента ~0,07 с), лише активні слоти
local hoverSet = {}
local hoverConn = nil
local function hoverStep(dt: number)
	local a = 1 - math.exp(-14 * dt)
	for s in hoverSet do
		local ts = s.down and 0.96 or (s.hover and 1.025 or 1)
		local tr = (s.hover and not s.down) and s.rel * 1.5 or 0
		s.s += (ts - s.s) * a
		s.r += (tr - s.r) * a
		if not s.hover and not s.down and math.abs(s.s - 1) < 0.0005 and math.abs(s.r) < 0.02 then
			s.s, s.r = 1, 0
			hoverSet[s] = nil
		end
		s.scale.Scale = s.s
		s.card.Rotation = s.r
	end
	if next(hoverSet) == nil and hoverConn then hoverConn:Disconnect(); hoverConn = nil end
end
local function wakeHover(s)
	hoverSet[s] = true
	if not hoverConn then hoverConn = RunService.RenderStepped:Connect(hoverStep) end
end

local function makeSlot(it, col: number, row: number)
	local x, y = PADX + (col - 1) * COL, ROWY[row]
	-- holder масштабується (UIScale), а нахиляється лише card (фон, сяйво, іконка, написи, рамка). Кнопки +/−, плашка й клік —
	-- у holder без повороту: у поверненому елементі Roblox не обрізає візерунок кнопок стилю A (studs вилазили за кнопку)
	local holder = new("Frame", { Name = "Slot_" .. it.key, BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(SL + 2 * HP, SL + 2 * HP), Position = UDim2.fromOffset(x + SL / 2, y + SL / 2), ZIndex = 1 }, strip)
	local scale = new("UIScale", {}, holder)
	local card = frame(holder, 0, 0, SL + 2 * HP, SL + 2 * HP, nil, { Name = "Card", BackgroundTransparency = 1, ZIndex = 1 })
	frame(card, HP, HP + 6, SL, SL, BLACK, { Name = "Shadow", BackgroundTransparency = 0.7, ZIndex = 1 })
	-- «C · Сяйво»: темний квадрат, тонка рамка кольору руди, м'яке кругле сяйво за іконкою
	local bg = frame(card, HP, HP, SL, SL, WHITE, { Name = "Bg", ZIndex = 2 })
	vgrad(bg, { { 0, "22262c" }, { 1, "15181c" } }); stroke(bg, INK, 4)
	local tone = frame(card, HP + 3, HP + 3, SL - 6, SL - 6, nil, { Name = "Tone", BackgroundTransparency = 1, ZIndex = 3 })
	stroke(tone, it.tone, 3, 0.67)
	-- зона іконки: квадрат ліворуч від кнопок +/− і над назвою (модель рівно в цих межах, не вилазить)
	local IX, IY, IS = 6, 20, SL - 60
	local gcx, gcy = HP + IX + IS / 2, HP + IY + IS / 2
	-- радіальне сяйво (27.10.2026): один ImageLabel з м'якою радіальною текстурою (soft_radial256), ледь помітне
	-- (ImageTransparency 0,86) — замість 30 вкладених кіл (було видно сходинки)
	local glow = new("ImageLabel", { Name = "Glow", BackgroundTransparency = 1, Image = "rbxassetid://122253463048651", ImageColor3 = it.tone, ImageTransparency = 0.86,
		Position = UDim2.fromOffset(gcx - GLOW_R, gcy - GLOW_R), Size = UDim2.fromOffset(GLOW_R * 2, GLOW_R * 2), ZIndex = 3 }, card)
	local icon = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = it.icon, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(HP + IX, HP + IY), Size = UDim2.fromOffset(IS, IS), ZIndex = 4 }, card)
	ItemVP.set(icon, it.key, 1)
	local cnt = textAt(card, HP, HP + 24, SL - 12, 30, "", WHITE, 3.5, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 })
	textAt(card, HP + 12, HP + SL - 20, SL - 66, 20, it.name, WHITE, 2.5, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5 })
	-- рамка «вибрано»: лаймова лінія + м'яке світіння
	local ring = frame(card, HP - 6, HP - 6, SL + 12, SL + 12, nil, { Name = "Ring", BackgroundTransparency = 1, Visible = false, ZIndex = 6 })
	stroke(ring, C("c8ff6a"), 4)
	local ringGlow = frame(ring, -4, -4, SL + 20, SL + 20, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	stroke(ringGlow, C("c8ff6a"), 6, 0.6)
	-- плашка з кількістю вибраного
	local pill = StyleA.new(holder, { size = Vector2.new(86, 40), position = Vector2.new(HP - 8, HP - 12), anchor = Vector2.zero, color = "green", half = true,
		rows = 3, text = "", textSize = 24, zIndex = 7 })
	pill.root.Visible = false
	-- клік по слоту (міні-меню), наведення, перетягування
	local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(HP, HP),
		Size = UDim2.fromOffset(SL, SL), ZIndex = 8 }, holder)
	hit:SetAttribute("NoHoverSound", true)
	local pb = makeButton(holder, HP + SL - 54, HP + 40, 46, 46, { shadowDy = 4, color = "green", text = "+", textSize = 28, z = 9, shine = false, noSound = true, manual = true })
	local mb = makeButton(holder, HP + SL - 54, HP + 92, 46, 46, { shadowDy = 4, color = "red", text = "−", textSize = 28, z = 9, shine = false, noSound = true, manual = true })
	local tst = textAt(holder, 0, HP + SL / 2, SL + 2 * HP, 26, "", C("ffd34d"), 3, { ZIndex = 12, Visible = false })
	-- замок: предмет заблокований в інвентарі — продати не можна
	local lockImg = new("ImageLabel", { Name = "Lock", BackgroundTransparency = 1, Image = LOCK_ICON, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(HP + 8, HP + 8), Size = UDim2.fromOffset(34, 34), ZIndex = 7, Visible = false }, card)
	local s = { root = holder, shaking = false, it = it, col = col, row = row, x = x, y = y, holder = holder, card = card, glow = glow, scale = scale, icon = icon, cnt = cnt, ring = ring, pill = pill,
		pb = pb, mb = mb, toast = tst, toastTok = 0, hover = false, down = false, rel = 0, s = 1, r = 0, lockImg = lockImg }
	holdRepeat(pb, function() return add(s, 1) end)
	holdRepeat(mb, function() return add(s, -1) end)
	local function aim(px: number)
		local c = holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2
		s.rel = math.clamp((px - c) / math.max(1, hit.AbsoluteSize.X / 2), -1, 1)
	end
	hit.MouseEnter:Connect(function(px)
		if mini.open then return end
		if not s.hover then slotHoverSound() end
		s.hover = true; aim(px); wakeHover(s)
	end)
	hit.MouseMoved:Connect(function(px) if mini.open then return end s.hover = true; aim(px); wakeHover(s) end)
	hit.MouseLeave:Connect(function() s.hover = false; s.down = false; wakeHover(s) end)
	hit.InputBegan:Connect(function(inp)
		if isPress(inp) then s.down = true; wakeHover(s); beginDrag(inp, false) end
	end)
	hit.InputEnded:Connect(function(inp) if isPress(inp) then s.down = false; wakeHover(s) end end)
	hit.InputChanged:Connect(wheel)
	hit.Activated:Connect(function()
		if (drag and drag.moved) or os.clock() - dragEndAt < 0.15 then return end
		if lockedKeys[it.key] and inv(it.key) > 0 then StyleA.shake(s); toast(s, "LOCKED"); return end
		if inv(it.key) < 1 then StyleA.shake(s); toast(s, "EMPTY"); return end
		StyleA.tap() -- звук натискання (слот — не StyleA.bind)
		openMini(s)
	end)
	return s
end

local function buildSlots()
	for _, s in slots do s.holder:Destroy() end
	table.clear(slots)
	for row, kind in { "ore", "bar" } do
		local col = 0
		for _, it in ITEMS do
			if it.kind == kind then
				col += 1
				table.insert(slots, makeSlot(it, col, row))
			end
		end
	end
end
buildSlots()

-- підписи рядів зліва: назва, вартість ряду, кнопка «All Ore» / «All Bars»
local rowInfo = {}
for r, spec in { { "Ore", "ore", "All Ore", "No Ore" }, { "Bars", "bar", "All Bars", "No Bars" } } do
	local cy = GY0 + ROWY[r] + SL / 2
	textAt(content, LBLX, cy - 46, 130, 40, spec[1], WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
	local val = textAt(content, LBLX, cy - 8, 130, 22, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 2 })
	local b = makeButton(content, LBLX - 2, cy + 16, 124, 50, { shadowDy = 4, color = "blue", text = spec[3], textSize = 21, z = 4 })
	local info = { kind = spec[2], val = val, btn = b, allText = spec[3], noneText = spec[4], full = false }
	b.onClick = function()
		for _, it in ITEMS do
			if it.kind == info.kind then sel[it.key] = info.full and 0 or sellable(it.key) end
		end
		refresh()
	end
	rowInfo[r] = info
end

-- кнопки внизу
local btnAll = makeButton(content, CX0, BTN_Y, 300, 82, { shadowDy = 8, color = "blue", text = "Select All", textSize = 38, z = 6 })
local btnClear = makeButton(content, CX0 + 316, BTN_Y, 200, 82, { shadowDy = 8, color = "red", text = "Clear", textSize = 38, z = 6 })
local btnSell = makeButton(content, CX0 + 532, BTN_Y, CW - 532, 82, { shadowDy = 8, color = "green", text = "Sell", textSize = 38, z = 6, debounce = 0.35 })
btnAll.onClick = function() for _, it in ITEMS do sel[it.key] = sellable(it.key) end; refresh() end
-- замки змінилися (інвентар) — замок на слоті, іконка пригасає, вибране заблоковане скидається
local function applyLocks()
	readLocks()
	for _, s in slots do
		local l = lockedKeys[s.it.key] == true
		if s.lockImg then s.lockImg.Visible = l and inv(s.it.key) > 0 end
		s.icon.ImageTransparency = (l and inv(s.it.key) > 0) and 0.45 or 0
		if l then sel[s.it.key] = 0 end
	end
end
applyLocks()
-- нова мапа — нова руда: слоти перебудовуються
Cfg.StageChanged.Event:Connect(function()
	buildItems(); buildSlots(); applyLocks()
	if refresh then refresh() end
end)
player:GetAttributeChangedSignal("InvLocks"):Connect(function() applyLocks(); if refresh then refresh() end end)
btnClear.onClick = function() for _, it in ITEMS do sel[it.key] = 0 end; refresh() end

-- спливне «+$X» над кнопкою Sell
local function popMoney(amount: number)
	local t = textAt(content, CX0 + 532 + (CW - 532) / 2 - 250, BTN_Y - 26, 500, 48, "+" .. NF.money(amount), C("c8ff6a"), 0, { ZIndex = 40 })
	stroke(t, C("0b3a14"), 5, 0, true)
	tween(t, 1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
	local st = t:FindFirstChildOfClass("UIStroke")
	if st then tween(st, 1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 }) end
	task.delay(1.35, function() t:Destroy() end)
end
btnSell.onClick = function()
	local payload, base = {}, 0
	for _, it in ITEMS do
		local n = math.min(sel[it.key], sellable(it.key))
		if n > 0 then payload[it.key] = n; base += n * it.price end
	end
	if base <= 0 then StyleA.shake(btnSell); return end
	Action:FireServer("Sell", payload)
	UISfx.play("SellSound")
	popMoney(math.floor(base * multi() + 0.5))
	for _, it in ITEMS do sel[it.key] = 0 end
	refresh()
end

-- заголовок «SELL» поза вікном: тінь-копія +7, зелений перелив (період 4 с) і білий відблиск, що час від часу пробігає
-- Домовленість для всіх вікон: іконка зліва від тексту (тут — гроші, як на кнопці x2 Money у HUD), висота ≈ 2 ×
-- висоти літер, нахил −8°, текст зсунуто праворуч; обводка й тінь тексту та тінь іконки (силует +9 вниз) — ЧОРНІ (INK).
local TITLE_ICON = "rbxassetid://94881597034076" -- mmg_title_cash_black (Decal 73285674841616): гроші як у HUD, чорний контур #14161a
local TITLE_IS = 170                                 -- розмір іконки ≈ 2 × висоти літер (118 · 0,7)
local TITLE_ICX, TITLE_ICY = 56 + TITLE_IS / 2, 44   -- центр іконки
local TITLE_X = TITLE_ICX + TITLE_IS / 2 + 8         -- лівий край тексту — за іконкою, не налазить
new("ImageLabel", { Name = "TitleIconShadow", BackgroundTransparency = 1, Image = TITLE_ICON, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY + 9), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 3 }, pop)
new("ImageLabel", { Name = "TitleIcon", BackgroundTransparency = 1, Image = TITLE_ICON, ScaleType = Enum.ScaleType.Fit,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 4 }, pop)
local titleShadow = textAt(pop, TITLE_X, 50 + 9, 560, 118, "SELL", INK, 11, { Name = "TitleShadow", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, TITLE_X, 50, 560, 118, "SELL", WHITE, 10, { Name = "Title", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local titleShine = textAt(pop, TITLE_X, 50, 560, 118, "SELL", WHITE, 0, { Name = "TitleShine", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
do
	local P = { C("e6ffb0"), C("8cf04a"), C("22a838"), C("8cf04a") }
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
	task.spawn(function()
		while true do
			task.wait(3 + math.random() * 3)
			if modalRoot.Visible then tw:Play() end
		end
	end)
end
-- заголовок і X — ті самі пропорції, що в Inventory (×650/528): на екрані однакові розмір і місце
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })
closeBtn.root.Name = "Close"

-- =====================================================================
-- ===== міні-меню слота (повзунок кількості) =====
-- =====================================================================
local MK = {}
do
	local dim = frame(content, 0, 0, WIN_W, WIN_H, C("0d0f12"), { Name = "MiniDim", BackgroundTransparency = 0.55, Active = true, Visible = false, ZIndex = 20 })
	MK.dim = dim
	-- стрілка до слота: повернуті квадрати шаром НИЖЧЕ вікна меню
	MK.arrowInk = frame(content, 0, 0, 41, 41, INK, { Name = "MiniArrowInk", AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, Visible = false, ZIndex = 28 })
	MK.arrowFill = frame(content, 0, 0, 31, 31, C("585e66"), { Name = "MiniArrowFill", AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, Visible = false, ZIndex = 29 })
	local root = frame(content, 0, 0, MW, MH, nil, { Name = "Mini", BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 30 })
	MK.root = root
	MK.scale = new("UIScale", {}, root)
	local _, cont = windowFrame(root, 0, 0, MW, MH, 1, 10)
	MK.icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(MPAD, MPAD - 4),
		Size = UDim2.fromOffset(64, 64), ZIndex = 3 }, cont)
	MK.title = textAt(cont, MPAD + 76, MPAD + 14, 300, 34, "", WHITE, 3.5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	MK.sub = textAt(cont, MPAD + 76, MPAD + 46, 330, 20, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 3 })
	MK.close = makeButton(cont, MW - MPAD - 56, MPAD, 56, 56, { shadowDy = 5, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 4 })
	MK.read = textAt(cont, 0, 134, MW, 48, "", WHITE, 5, { ZIndex = 3, RichText = true })
	local TW = MW - 2 * MPAD - 2 * (50 + 14)
	local TX, TY, TH = MPAD + 64, 168, 34
	local KW, KH = 44, 54
	local bar = makeBar(cont, TX, TY, TW, TH, nil, 3)
	bar.track.Active = true
	MK.bar = bar
	MK.knob = StyleA.new(cont, { size = Vector2.new(KW, KH), position = Vector2.new(TX, TY + TH / 2 - KH / 2 - 4), anchor = Vector2.zero, color = "gray",
		rows = 4, clickable = true, shine = false, zIndex = 8 })
	StyleA.bind(MK.knob, { hoverAlways = true })
	MK.minus = makeButton(cont, MPAD, TY + TH / 2 - 25, 50, 50, { shadowDy = 5, color = "red", text = "−", textSize = 30, z = 4, shine = false, manual = true, noSound = true }) -- звуки — у holdRepeat
	MK.plus = makeButton(cont, MW - MPAD - 50, TY + TH / 2 - 25, 50, 50, { shadowDy = 5, color = "green", text = "+", textSize = 30, z = 4, shine = false, manual = true, noSound = true })
	MK.cost = textAt(cont, 0, TY + TH + 22, MW, 20, "", INK, 0, { FontFace = XBOLD, ZIndex = 3 })
	local btnY = MH - 18 - 12 - 70
	MK.all = makeButton(cont, MPAD, btnY, 200, 68, { shadowDy = 6, color = "blue", text = "All", textSize = 32, z = 4 })
	MK.done = makeButton(cont, MPAD + 214, btnY, MW - 2 * MPAD - 214, 68, { shadowDy = 6, color = "green", text = "Done", textSize = 32, z = 4 })

	-- показати значення (без зміни вибраного)
	function MK.sync()
		local s = mini.slot
		if not s then return end
		local it = s.it
		local n = inv(it.key)
		local v = math.min(sel[it.key], n)
		local f = n > 0 and v / n or 0
		MK.knob:setPosition(Vector2.new(TX + f * (TW - KW), TY + TH / 2 - KH / 2 - 4))
		bar.fill.Visible = v > 0
		bar.fill.Size = UDim2.fromOffset(v > 0 and f * (TW - KW) + KW / 2 or TH, TH)
		MK.read.Text = NF.full(v) .. '<font size="28" color="#c9ced4"> / ' .. NF.full(n) .. "</font>"
		MK.sub.Text = "You have " .. NF.full(n) .. " · " .. NF.money(it.price) .. " each"
		local m = multi()
		MK.cost.Text = v > 0 and (m ~= 1 and (NF.money(v * it.price) .. " × " .. NF.mult(m):sub(2) .. " = " .. NF.money(math.floor(v * it.price * m + 0.5))) or NF.money(v * it.price))
			or "slide to choose"
		local full = n > 0 and v >= n
		MK.all:setText(full and "Clear" or "All")
		MK.all:recolor(full and "red" or "blue")
	end
	function MK.set(v: number)
		local s = mini.slot
		if not s then return end
		sel[s.it.key] = math.clamp(math.floor(v + 0.5), 0, inv(s.it.key))
		refresh()
	end
	local sliding = false
	local function fromX(x: number)
		local s = mini.slot
		local abs = bar.track.AbsoluteSize.X
		if not s or abs <= 0 then return end
		local f = math.clamp(((x - bar.track.AbsolutePosition.X) / (abs / TW) - KW / 2) / (TW - KW), 0, 1)
		MK.set(f * inv(s.it.key))
	end
	local function startSlide(inp: InputObject) if isPress(inp) then sliding = true; fromX(inp.Position.X) end end
	MK.knob.root.InputBegan:Connect(startSlide)
	bar.track.InputBegan:Connect(startSlide)
	UIS.InputChanged:Connect(function(inp) if sliding and isMove(inp) then fromX(inp.Position.X) end end)
	UIS.InputEnded:Connect(function(inp) if isPress(inp) then sliding = false end end)
	holdRepeat(MK.minus, function() local s = mini.slot return s ~= nil and add(s, -1) end)
	holdRepeat(MK.plus, function() local s = mini.slot return s ~= nil and add(s, 1) end)
	MK.all.onClick = function()
		local s = mini.slot
		if not s then return end
		local n = inv(s.it.key)
		MK.set(sel[s.it.key] >= n and 0 or n)
	end
end

local function closeMini()
	if not mini.open then return end
	mini.open = false
	mini.slot = nil
	MK.dim.Visible = false
	MK.arrowInk.Visible = false
	MK.arrowFill.Visible = false
	pcall(function() CAS:UnbindAction("SellMini") end)
	local my = {}
	mini.tok = my
	tween(MK.scale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 }).Completed:Connect(function()
		if mini.tok == my then MK.root.Visible = false end
	end)
end
-- закриваємо лише кліком ПОЗА вікном меню (InputBegan затемнення спрацьовує й під самим вікном), хрестиком або Done
MK.dim.InputBegan:Connect(function(inp)
	if not isPress(inp) then return end
	local r = MK.root
	if r and r.Visible then
		local p, a, sz = inp.Position, r.AbsolutePosition, r.AbsoluteSize
		if p.X >= a.X and p.X <= a.X + sz.X and p.Y >= a.Y and p.Y <= a.Y + sz.Y then return end
	end
	closeMini()
end)
MK.close.onClick = function() closeMini() end
MK.done.onClick = function() closeMini() end

local function miniKey(_, state, inp: InputObject)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	local s = mini.slot
	local k = inp.KeyCode
	if s and (k == Enum.KeyCode.Left or k == Enum.KeyCode.Down) then add(s, -1)
	elseif s and (k == Enum.KeyCode.Right or k == Enum.KeyCode.Up) then add(s, 1)
	elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.Escape then closeMini() end
	return Enum.ContextActionResult.Sink
end

openMini = function(s)
	if mini.open then closeMini() end
	local it = s.it
	mini.open, mini.slot = true, s
	mini.tok = {}
	s.hover, s.down = false, false
	wakeHover(s)
	-- місце: праворуч від слота, якщо влазить, інакше ліворуч, інакше по центру вікна (без стрілки)
	local sx, sy = GX0 + s.x - scrollX, GY0 + s.y
	local right = sx + SL + 30 + MW <= WIN_W - 20
	local left = sx - 30 - MW >= 20
	local side = right or left
	local x = right and sx + SL + 30 or left and sx - 30 - MW or (WIN_W - MW) / 2
	local y = side and math.clamp(sy + SL / 2 - MH / 2, 30, WIN_H - MH - 30) or (WIN_H - MH) / 2 + 20
	local ay = side and math.clamp(sy + SL / 2 - y, 40, MH - 40) or MH / 2
	local ax = right and 0 or left and MW or MW / 2
	MK.root.AnchorPoint = Vector2.new(ax / MW, ay / MH)
	MK.root.Position = UDim2.fromOffset(x + ax, y + ay)
	if side then
		local px = right and x - 5 or x + MW + 5
		MK.arrowInk.Position = UDim2.fromOffset(px, y + ay)
		MK.arrowFill.Position = UDim2.fromOffset(px, y + ay)
	end
	MK.arrowInk.Visible = side
	MK.arrowFill.Visible = side
	MK.icon.Image = it.icon
	ItemVP.set(MK.icon, it.key, 0.95) -- поруч із заголовком: у межах іконки
	local FCfg = require(game:GetService("ReplicatedStorage").Shared.ForgeConfig)
	MK.title.Text = it.kind == "bar" and (FCfg.productOf(it.name) == "Cut" and ("Cut " .. it.name) or (it.name .. " Bars")) or it.name
	MK.sync()
	MK.dim.Visible = true
	MK.root.Visible = true
	-- рамка слота блимає двічі (видно, для якого слота меню)
	s.ring.Visible = true
	task.spawn(function()
		for _ = 1, 2 do
			tween(s.ring:FindFirstChildOfClass("UIStroke"), 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Transparency = 0.6 }).Completed:Wait()
			tween(s.ring:FindFirstChildOfClass("UIStroke"), 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Transparency = 0 }).Completed:Wait()
		end
		refresh()
	end)
	-- поява: 0,85 → 1,05 → 1 (як вікна гри)
	MK.scale.Scale = 0.85
	local my = mini.tok
	tween(MK.scale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and mini.tok == my then tween(MK.scale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("SellMini", miniKey, false, Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Return, Enum.KeyCode.Escape)
end

-- =====================================================================
-- ===== оновлення =====
-- =====================================================================
refresh = function()
	local m = multi()
	for _, it in ITEMS do sel[it.key] = math.clamp(sel[it.key], 0, sellable(it.key)) end -- інвентар (чи замки) міг змінитися
	for _, s in slots do
		local it = s.it
		local n, k = inv(it.key), sel[it.key]
		s.cnt.Text = "×" .. NF.short(n)
		s.cnt.TextColor3 = n > 0 and WHITE or C("9aa3ad")
		-- порожній слот (×0): іконка напівпрозора й сіра, без сяйва — одразу видно, що цього немає
		s.icon.ImageColor3 = n > 0 and WHITE or C("8a9099")
		local lk = lockedKeys[it.key] == true and n > 0 -- заблоковане: замок, іконка пригасає, + неактивний
		s.icon.ImageTransparency = n > 0 and (lk and 0.45 or 0) or 0.55
		if s.lockImg then s.lockImg.Visible = lk end
		s.glow.Visible = n > 0 and not lk
		s.pill.root.Visible = k > 0
		if k > 0 then s.pill:setText(NF.short(k)) end
		if not (mini.open and mini.slot == s) then s.ring.Visible = k > 0 end
		s.pb:enable(k < sellable(it.key))
		s.mb:enable(k > 0)
	end
	for _, r in rowInfo do
		local v, tot, full = 0, 0, true
		for _, it in ITEMS do
			if it.kind == r.kind then
				local n = sellable(it.key)
				v += n * it.price; tot += n
				if sel[it.key] < n then full = false end
			end
		end
		r.val.Text = NF.money(math.floor(v * m + 0.5))
		r.full = tot > 0 and full
		r.btn:enable(tot > 0)
		r.btn:recolor(r.full and "red" or "blue")
		r.btn:setText(r.full and r.noneText or r.allText)
	end
	local sv, tv, sc = math.floor(selValue() * m + 0.5), math.floor(totalValue() * m + 0.5), selCount()
	setBar(selBar, tv > 0 and sv / tv or 0, sc > 0
		and (NF.full(sc) .. (sc == 1 and " item · " or " items · ") .. NF.money(sv) .. ' <font color="#d9dde2">/ max ' .. NF.money(tv) .. "</font>")
		or ("Nothing selected · max " .. NF.money(tv)))
	btnSell:setText(sv > 0 and ("Sell " .. NF.money(sv)) or "Sell")
	btnSell:enable(sv > 0)
	btnAll:enable(sc < totalCount())
	btnClear:enable(sc > 0)
	if mini.open then MK.sync() end
end

-- =====================================================================
-- ===== масштаб під екран (як ForgeWindow) =====
-- =====================================================================
local WindowFit = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowFit"))
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	local fullH = vh
	vh -= top
	modalRoot.Position = UDim2.new(0.5, 0, 0.5, top / 2)
	local phone = vh < 500 or (UIS.TouchEnabled and not UIS.MouseEnabled)
	-- адаптивний масштаб: вікно займає однакову частку екрана (Shared/WindowFit)
	-- розмір і місце — спільне правило всіх вікон (Shared/WindowFit.place)
	WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WIN_X, winY = WIN_Y, winW = WIN_W, winH = WIN_H })
end
local camConn
local function bindCamera()
	if camConn then camConn:Disconnect(); camConn = nil end
	local cam = workspace.CurrentCamera
	if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fit) end)
bindCamera()

-- =====================================================================
-- ===== відкриття / закриття =====
-- =====================================================================
local isOpen, dismissed = false, false
local animToken = 0

local function open()
	isOpen = true
	require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowManager")).opened("Sell") -- одне вікно на екрані: інші закриваються
	animToken += 1
	local my = animToken
	fit()
	for _, it in ITEMS do sel[it.key] = 0 end
	setScroll(0)
	refresh()
	backdrop.Visible = true
	modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and animToken == my then
			tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 })
		end
	end)
end

local function close()
	if not isOpen then return end
	isOpen = false
	closeMini()
	drag = nil
	if holdActive then holdActive() end
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false
		modalRoot.Visible = false
		for _, s in slots do s.hover, s.down = false, false; s.scale.Scale = 1; s.card.Rotation = 0; s.s, s.r = 1, 0 end
		for _, b in { btnAll, btnClear, btnSell, closeBtn, rowInfo[1].btn, rowInfo[2].btn } do b.hover = false; b.scale.Scale = 1 end
	end)
end
closeBtn.onClick = function()
	dismissed = true -- до виходу з кола й повторного входу
	close()
end
-- одне вікно на екрані (Shared/WindowManager): відкрилось інше вікно — Sell закривається й не відкривається знову, доки гравець не вийде з кола
require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowManager")).register("Sell", function() return isOpen end, function() dismissed = true; close() end)

-- своя лавка: ніша з OwnerUserId = UserId → Sell
local function findMySell(): Model?
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return nil end
	for _, n in niches:GetChildren() do
		if n:GetAttribute("OwnerUserId") == player.UserId then
			local s = n:FindFirstChild("Sell")
			if s then return s :: Model end
		end
	end
	return nil
end
local function ringDistance(s: Model): number
	local ring = s:FindFirstChild("Ring")
	local rc = ring and ring:FindFirstChild("RingCenter")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (rc and rc:IsA("BasePart") and hrp and hrp:IsA("BasePart")) then return math.huge end
	local d = rc.CFrame:PointToObjectSpace(hrp.Position)
	return Vector2.new(d.X, d.Z).Magnitude
end

local function step()
	local s = findMySell()
	local dist = s and ringDistance(s) or math.huge
	local inside = dist <= Rig.RING_R + ((isOpen or dismissed) and EXIT_PAD or 0)
	if not inside then dismissed = false end
	if s and inside and not dismissed then
		if not isOpen then open() else refresh() end
	elseif isOpen then
		close()
	end
end

while true do
	local ok, err = pcall(step)
	if not ok then warn("SellWindow: " .. tostring(err)) end
	task.wait(REFRESH)
end
