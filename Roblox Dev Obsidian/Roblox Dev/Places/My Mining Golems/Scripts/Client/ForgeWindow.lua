-- ForgeWindow — модальне вікно кузні «Forge» по центру екрана (замість тимчасової темної панелі з ForgeClient).
-- Де: StarterPlayer/StarterPlayerScripts/ForgeWindow (LocalScript). Інтерфейс будується кодом (ScreenGui ForgeWindow).
-- Макет і числа: ui/forge_window (SPEC.md, gen_forge_window.py). Полотно 1286 × 740, рамка 1206 × 650 (пропорції Inventory);
-- розмір і місце на екрані — Shared/WindowFit.place (усі вікна 1 в 1). Рядки руди + Money гортаються (повзунок справа). Стиль — GDD «2D іконки»:
--   усе квадратне (без UICorner; обводки рамок — LineJoinMode Miter, гострі кути). Кнопки, чипи стану й плитки руди /
--   злитків — «стиль A» з картинок (модуль Shared/StyleA: 9-slice основа + тайл візерунка + іконка / напис).
--   Блиск шкал — прямокутна біла смужка зверху. Круглий лише значок-галочка.
-- Коли видно: гравець стоїть у колі своєї кузні (ніша в Workspace/Niches з атрибутом OwnerUserId = свій UserId,
--   далі Forge/Ring/RingCenter; відстань — XZ у просторі RingCenter, радіус Cfg.RING_R). Вийшов з кола — вікно закривається.
--   Хрестик закриває вікно до наступного входу в коло.
-- Дані (опитування кожні 0,15 с, кузню шукаємо щоразу заново — переживає перебудову ніші й стрімінг):
--   кузня: State (Asleep / Waking / Working / Dozing), StateTime, Wake_<руда>, Pal_<руда>, Bars_<руда>, CapLvl, SpdLvl;
--   гравець: Ore_<руда>. Числа — Shared/ForgeConfig, формат — Shared/NumberFormat.
-- Remotes/ForgeAction: "Give" і "Wake" (голем спить), "Put" (Put All Ore), "PutOre" ({ ore, n } — попап вибору кількості) і "Take" (працює),
--   "TestOre" (кнопка TEST +10 схована: isDev = false).
--   Вугілля не плавиться (ForgeConfig.canSmelt): рядок Coal — «Can't smelt». Пробудження — руда + WAKE_MONEY (рядок Money).
--   Сервер (ForgeService) сам перевіряє коло, стан і кількість руди.
-- Іконки: ICONS нижче — PNG 512 після Asset Manager: руда й залізний злиток — нові v2 (ID вписуються в StyleA.ASSETS),
--   злитки вугілля й міді — старі ID тут.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local UISounds = require(RS.Shared:WaitForChild("UISounds")) -- claim — забрати злитки (Take Bars)
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
-- 07.11.2026: динамічні написи (числа всередині) — через Shared/Loc (шаблони {1}); автопереклад таких рядків не ловить
local Loc = require(RS:WaitForChild("Shared"):WaitForChild("Loc"))
local ItemVP = require(RS.Shared:WaitForChild("ItemViewport")) -- 3D-моделі руди й злитків у плитках замість PNG
local Action = RS:WaitForChild("Remotes"):WaitForChild("ForgeAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ORE = Cfg.ORES

-- ===== іконки (вписати ID після завантаження PNG через Asset Manager) =====
local ICONS = {
	ore_Coal = StyleA.ASSETS.forge_ore_coal_v2,     -- forge_ore_coal_v2.png
	ore_Copper = StyleA.ASSETS.forge_ore_copper_v2, -- forge_ore_copper_v2.png
	ore_Iron = StyleA.ASSETS.forge_ore_iron_v2,     -- forge_ore_iron_v2.png
	bar_Coal = "rbxassetid://101473380326305",      -- forge_bar_coal.png
	bar_Copper = "rbxassetid://106483042191242",    -- forge_bar_copper.png
	bar_Iron = StyleA.ASSETS.forge_bar_iron_v2,     -- forge_bar_iron_v2.png
}

-- ===== константи макета (одиниці дизайну) =====
-- рамка 1206 × 650 — ті самі пропорції, що в Inventory (980 × 528): на екрані вікна 1 в 1 (Shared/WindowFit.match)
local CANVAS_W, CANVAS_H = 1286, 740 -- ModalRoot
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1206, 650
local CX0, CW = 42, 1122 -- ліва межа й ширина вмісту у вікні
local DX = (CW - 956) / 2 -- зсув центрованих елементів відносно старого макета (ширина 956)
local ROW1_Y, ROW1_H = 68, 50
local ROWS_Y, ROW_H, ROW_GAP = 192, 96, 10
-- «Спить»: 4-й рядок «Money» (Cfg.WAKE_MONEY) — вікно на цей час вище на 120 (кратно клітинці studs 40)
local EXTRA_H = ROW_H + ROW_GAP + 14
local MONEY_Y = ROWS_Y + 3 * (ROW_H + ROW_GAP)
local REFRESH = 0.15
local EXIT_PAD = 0.5 -- запас на виході з кола, щоб вікно не блимало на межі (сервер приймає дії до RING_R + 2.5)

local MSG_ASLEEP = "Bring ore and money to wake the golem up."
local MSG_WAKING = "All ore delivered. The golem is waking up!"
local MSG_DOZING = "The pallet is empty. The golem is falling asleep."

-- ===== кольори =====
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local LIME_TXT = C("d4ff3e")
local GRAY_TXT = C("c9ced4")
local SUB_TXT = C("e9edf1")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

-- лаймова заливка (шкала «повно», значок-галочка)
local BTN_LIME = { { 0, "eaff9a" }, { 0.5, "c3f04a" }, { 1, "8ccc22" } }
-- заливки шкал
local FILL = {
	cyan = { { 0, "9ff0ff" }, { 0.5, "3cc4f0" }, { 1, "1688c8" } },
	lime = BTN_LIME,
	orange = { { 0, "ffb15c" }, { 0.5, "f07a1e" }, { 1, "b8500c" } },
	amber = { { 0, "ffe27a" }, { 0.5, "ffb21e" }, { 1, "e07a06" } },
	purple = { { 0, "c08af7" }, { 0.5, "8a3fe6" }, { 1, "561aa8" } },
}
local TRACK = { { 0, "1a1d22" }, { 1, "353b44" } }
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local TITLE_G = { { 0, "fff2a0" }, { 0.5, "ffc531" }, { 1, "f07a1e" } }
-- ===== будівельники (як у ForgeClient / RollUpgradeUI) =====
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
-- UICorner лишився тільки для пупочок studs і круглого значка-галочки; рамки, кнопки, чипи, шкали — квадратні
local function corner(o, r) new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
-- обводка рамки — Miter (гострі кути квадрата); обводка тексту (contextual) — Round, так літери виглядають краще
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
-- текст за «центром великих літер» cy (як у макеті): бокс 1,2 × розміру з центром у cy
local function textAt(parent, x, cy, w, size, text, color, sw, props)
	return label(parent, x, cy - size * 0.6, w, size * 1.2, size, text, color, sw, props)
end
-- блиск: прямокутна біла смужка зверху на всю внутрішню ширину (відступ inset = товщина обводки з усіх боків),
-- без заокруглень; ширина — 100 % батька мінус 2 × inset (тягнеться разом із заливкою шкали). alpha — «білий N%»
local function gloss(parent, inset, h, alpha, props)
	local g = new("Frame", { Name = "Gloss", Position = UDim2.fromOffset(inset, inset), Size = UDim2.new(1, -2 * inset, 0, h),
		BackgroundColor3 = WHITE, BackgroundTransparency = 1 - alpha, BorderSizePixel = 0 }, parent)
	if props then for k, v in props do g[k] = v end end
	return g
end
-- пупочка studs з «L»-тінню (точні частки клітинки, як у SVG-макеті: 62 %, кут 16 %, зсув 12 %)
local function stud(parent, x, y, cell, fill, shade, edge, edgeTh)
	local s = cell * 0.62
	local o = (cell - s) / 2
	local d = s * 0.12
	local r = s * 0.16
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade, { ZIndex = 1 }); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill, { ZIndex = 2 }); corner(st, r)
	if edge then stroke(st, edge, edgeTh or 2) end
end
-- похилі світлі смуги «задньої панелі» картки (як у референсі «Store»): один білий Frame на всю внутрішню частину
-- (відступ inset = обводка), без заокруглень, Active = false; UIGradient Rotation 65 дає три смуги (широка, тонка, широка),
-- ≈ 10–18 % білого. k — множник непрозорості смуг (1 — як на картках, < 1 — слабше). Статичні (без анімації).
local BAND_KEYS = { { 0, 1 }, { 0.16, 1 }, { 0.17, 0.82 }, { 0.31, 0.82 }, { 0.32, 1 }, { 0.47, 1 }, { 0.48, 0.9 }, { 0.53, 0.9 },
	{ 0.54, 1 }, { 0.70, 1 }, { 0.71, 0.85 }, { 0.83, 0.85 }, { 0.84, 1 }, { 1, 1 } }
local function bands(parent, inset, w, h, k, z)
	local f = frame(parent, inset, inset, w - 2 * inset, h - 2 * inset, WHITE, { Name = "Bands", BackgroundTransparency = 0, Active = false, ZIndex = z or 1 })
	local ks = {}
	for _, p in BAND_KEYS do table.insert(ks, NumberSequenceKeypoint.new(p[1], 1 - (1 - p[2]) * (k or 1))) end
	new("UIGradient", { Rotation = 65, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new(ks) }, f)
	return f
end
local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end

-- ширина тексту (одиниці дизайну) для чипів і напису затемнення; кеш, бо GetTextBoundsAsync чекає відповіді
local widthCache = {}
local function textWidth(text: string, size: number, font: Font): number
	local key = text .. "|" .. size .. "|" .. font.Weight.Name
	local w = widthCache[key]
	if w then return w end
	local ok, res = pcall(function()
		local p = Instance.new("GetTextBoundsParams")
		p.Text = text; p.Font = font; p.Size = size; p.Width = 100000
		return TextService:GetTextBoundsAsync(p)
	end)
	w = ok and res.X or (utf8.len(text) or #text) * size * 0.62
	widthCache[key] = w
	return w
end

local function fmtNum(n: number): string -- 2.75 → "2.75", 3 → "3", 2.5 → "2.5"
	local s = string.format("%.2f", n)
	s = (string.gsub(s, "0+$", ""))
	s = (string.gsub(s, "%.$", ""))
	return s
end

-- ===== кнопка «стиль A» (Shared/StyleA) + квадратна тінь під нею =====
-- opt: shadowDy, color ("green" / "gray" / "red"), text, textSize, icon, iconPad, z (тінь — z, кнопка — z + 1).
-- Поведінка — StyleA.bind: наведення 1,04, натискання 0,92 + Back; недоступна (b.enabled = false) — хитається.
-- b.onClick(b) — дія (не частіше ніж раз на 0,2 с), b.action — що слати на сервер; b.btn — сама ImageButton.
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, zIndex = opt.z + 1 })
	b.btn = b.root
	b.shadow = sh
	StyleA.follow(b, sh) -- тінь масштабується й хитається разом з кнопкою
	b.onClick = nil
	b.action = nil
	StyleA.bind(b, { debounce = 0.2, onClick = function() if b.onClick then b.onClick(b) end end })
	return b
end
-- градієнт заливки шкали
local function setKeys(o, keys)
	if o.keys ~= keys then o.keys = keys; o.grad.Color = cseq(keys) end
end
-- текст, дія й стан кнопки дії (green — можна, gray — не можна)
local function setButton(b, text: string, action: string?, enabled: boolean)
	b:setText(text)
	b.action = action
	if b.enabled ~= enabled then
		b.enabled = enabled
		b:setColor(enabled and "green" or "gray")
		if b.hover then tween(b.scale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = enabled and 1.04 or 1 }) end
	end
end

-- ===== шкала (квадратна доріжка + квадратна заливка з прямокутним блиском + текст по центру) =====
local function makeBar(parent, x, y, w, h, textSize, z)
	local track = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 1 })
	vgrad(track, TRACK); stroke(track, INK, 4)
	local fill = frame(track, 0, 0, h, h, WHITE, { Visible = false, ZIndex = 1 })
	local grad = vgrad(fill, FILL.cyan)
	gloss(fill, 0, math.floor(h * 0.36 + 0.5), 0.32)
	local text = textSize and label(track, 0, 0, w, h, textSize, "", WHITE, math.floor(textSize * 0.1 + 0.5), { ZIndex = 2 }) or nil
	return { track = track, fill = fill, grad = grad, keys = FILL.cyan, text = text, w = w, h = h, fw = -1, tw = nil }
end
-- frac 0..1; ширина заливки = max(частка, h / w) × w, при 0 — прихована; instant — без анімації
local function setBar(bar, frac: number, keys, text: string?, instant: boolean?)
	if frac ~= frac then frac = 0 end -- NaN
	frac = math.clamp(frac, 0, 1)
	setKeys(bar, keys)
	if text and bar.text and bar.text.Text ~= text then bar.text.Text = text end
	local fw = frac > 0 and math.max(frac, bar.h / bar.w) * bar.w or 0
	if math.abs(fw - bar.fw) < 0.01 then return end
	bar.fw = fw
	if bar.tw then bar.tw:Cancel(); bar.tw = nil end
	if fw <= 0 then
		bar.fill.Visible = false
		bar.fill.Size = UDim2.fromOffset(bar.h, bar.h)
		return
	end
	if not bar.fill.Visible then bar.fill.Visible = true; bar.fill.Size = UDim2.fromOffset(bar.h, bar.h) end
	if instant then
		bar.fill.Size = UDim2.fromOffset(fw, bar.h)
	else
		bar.tw = tween(bar.fill, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(fw, bar.h) })
	end
end

-- ===== чип стану (стиль A: візерунок половинної сили, 3 ряди клітинок; висота 50, ширина = текст + 44) =====
-- контейнер frame (видимість, позиція, розмір) + тінь + сам чип body (StyleA, колір за значенням)
local function makeChip(parent)
	local c = frame(parent, CX0, ROW1_Y, 100, ROW1_H, nil, { BackgroundTransparency = 1, ZIndex = 6, Visible = false })
	new("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.7,
		BorderSizePixel = 0, ZIndex = 1 }, c)
	local body = StyleA.new(c, { size = Vector2.new(100, ROW1_H), position = Vector2.zero, anchor = Vector2.zero, color = "blue", half = true,
		rows = 3, text = "", textSize = 26, zIndex = 2 })
	return { frame = c, body = body }
end

-- ===== плитка 80 × 80 з іконкою (стиль A: колір руди, візерунок половинної сили, іконка в межах грані; галочка — ZIndex 4) =====
local ORE_TILE = { Coal = "ore_coal", Copper = "ore_copper", Iron = "ore_iron", Tin = "blue", Silver = "gray", Gold = "yellow",
	-- мапи 3–7 (03.11.2026)
	Quartz = "gray", Amethyst = "purple", Sapphire = "blue", Obsidian = "purple", Ruby = "red", Emberite = "orange",
	Frostite = "blue", Platinum = "gray", Celestium = "yellow", Voidstone = "purple", Starmetal = "purple", Eclipsium = "purple",
	Toxite = "green", Uranite = "green", Venomite = "green" }
local function makeTile(parent, x, y, oreKey, iconId, clickable, itemKey)
	-- руда без PNG (мапа 2+): тимчасова картинка, щоб у плитці був ImageLabel — далі його замінить 3D-модель (ItemViewport)
	if not iconId and itemKey and ItemVP.has(itemKey) then iconId = "rbxasset://textures/ui/GuiImagePlaceholder.png" end
	-- якір у центрі (за замовчуванням StyleA): наведення / натискання масштабують плитку від центру, а не від лівого верхнього кута
	local t = StyleA.new(parent, { size = Vector2.new(80, 80), position = Vector2.new(x, y),
		color = ORE_TILE[oreKey] or "gray", half = true, rows = 4, icon = iconId, zIndex = 2, clickable = clickable, shine = false })
	-- іконка плитки → 3D-модель (ItemViewport): шукаємо ImageLabel із цією картинкою
	if itemKey and ItemVP.has(itemKey) then
		for _, d in t.root:GetDescendants() do
			if d:IsA("ImageLabel") and d.Image == iconId then ItemVP.set(d, itemKey); break end
		end
	end
	return t
end
-- лаймова галочка на плитці: коло Ø34 ink, всередині Ø26 лаймове, центр (76, 6) плитки (єдина кругла деталь — це значок)
local function makeCheck(tile)
	local ring = frame(tile, 76 - 17, 6 - 17, 34, 34, INK, { ZIndex = 4, Visible = false }); corner(ring, UDim.new(0.5, 0))
	local dot = frame(ring, 4, 4, 26, 26, WHITE, { ZIndex = 1 }); corner(dot, UDim.new(0.5, 0)); vgrad(dot, BTN_LIME)
	-- дві смужки «✓» (біла 4, контур ink 2); другий шар без контуру, щоб контур не перетинав місце з'єднання
	local arms = { { -4.5, 2.5, 11.1, 45 }, { 2.5, 0, 17.5, -48 } }
	for layer = 1, 2 do
		for _, a in arms do
			local s = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(17 + a[1], 17 + a[2]), Size = UDim2.fromOffset(a[3], 4),
				Rotation = a[4], BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = layer + 1 }, ring)
			corner(s, 2)
			if layer == 1 then stroke(s, INK, 2) end
		end
	end
	return ring
end

-- =====================================================================
-- ===== збірка вікна =====
-- =====================================================================
-- синій плюсик у правому нижньому куті плитки руди: «сюди можна натиснути й обрати кількість». Коло Ø32 (ink 3) + синє ×26 + білий плюс (ink 1,5).
-- Сірий, коли цю руду зараз покласти не можна. Пульсує (UIScale 1 → 1,12). Дочірній елемент плитки, ZIndex 4 (як галочка).
local BADGE_BLUE = { { 0, "9fd8ff" }, { 0.55, "3aa0f0" }, { 1, "1c68c4" } }
local BADGE_GRAY = { { 0, "c9ced4" }, { 0.55, "8c929a" }, { 1, "5a6068" } }
local function makeBadge(tile)
	local ring = frame(tile, 59, 59, 32, 32, INK, { Name = "PlusBadge", ZIndex = 4 }); corner(ring, UDim.new(0.5, 0))
	local inner = frame(ring, 3, 3, 26, 26, WHITE, { ZIndex = 1 }); corner(inner, UDim.new(0.5, 0))
	local grad = vgrad(inner, BADGE_BLUE)
	for layer = 1, 2 do
		for _, a in { { 6, 11, 14, 4 }, { 11, 6, 4, 14 } } do
			local s = frame(inner, a[1], a[2], a[3], a[4], WHITE, { ZIndex = layer + 1 }); corner(s, 2)
			if layer == 1 then stroke(s, INK, 1.5) end
		end
	end
	local sc = new("UIScale", {}, ring)
	TweenService:Create(sc, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 }):Play()
	return { ring = ring, grad = grad, can = true }
end
local function setBadge(b, can: boolean)
	if b.can == can then return end
	b.can = can
	b.grad.Color = cseq(can and BADGE_BLUE or BADGE_GRAY)
end

local old = playerGui:FindFirstChild("ForgeWindow")
if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "ForgeWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10 }, playerGui)

-- темне тло на весь екран (ловить кліки, щоб не проходили в гру)
local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)

-- вікно (квадратне): тінь, темний обідок, світла лінія, панель зі studs і затіненням
local winShadow = frame(pop, WIN_X, WIN_Y + 14, WIN_W, WIN_H, BLACK, { Name = "WindowShadow", BackgroundTransparency = 0.65, ZIndex = 1 })
local window = frame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, WHITE, { Name = "Window", ZIndex = 2 })
vgrad(window, RIM); stroke(window, INK, 5)
local rimLine = frame(window, 6, 6, WIN_W - 12, WIN_H - 12, nil, { Name = "RimLine", BackgroundTransparency = 1, ZIndex = 1 })
stroke(rimLine, C("6a7078"), 1.5, 0.1)
local PAN_W, PAN_H = WIN_W - 36, WIN_H - 36 -- 1004 × 614
local panel = frame(window, 18, 18, PAN_W, PAN_H, C("a9aeb5"), { Name = "Panel", ZIndex = 2, ClipsDescendants = true })
stroke(panel, INK, 4)
-- studs панелі: клітинка 40, сітка 25 × 15 по центру (перша клітинка з (2, 7)); будуються один раз
local studsFrame = frame(panel, 0, 0, PAN_W, PAN_H + EXTRA_H, nil, { Name = "Studs", BackgroundTransparency = 1, ZIndex = 1 })
do
	local CELL = 40
	local nx, ny = math.floor(PAN_W / CELL), math.floor((PAN_H + EXTRA_H) / CELL) -- з запасом на 4-й рядок (панель обрізає)
	local ox, oy = (PAN_W - nx * CELL) / 2, (PAN_H + EXTRA_H - ny * CELL) / 2
	StyleA.studTile(studsFrame, ox, oy, nx * CELL, ny * CELL, CELL, C("b3b8bf")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
end
local shade = frame(panel, 0, 0, PAN_W, PAN_H, WHITE, { Name = "Shade", ZIndex = 2 })
new("UIGradient", { Rotation = 90,
	Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE),
		ColorSequenceKeypoint.new(1, WHITE) }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1),
		NumberSequenceKeypoint.new(1, 0.82) }) }, shade)

-- вміст вікна (координати вікна). ZIndex: рядки 1, TEST 2–3, затемнення 5, чипи й кнопки 6–7
local content = frame(window, 0, 0, WIN_W, WIN_H, nil, { Name = "Content", BackgroundTransparency = 1, ZIndex = 3 })

-- рядок 1: чипи стану + повідомлення
local chips = { makeChip(content), makeChip(content), makeChip(content) }
local message = textAt(content, CX0, 95, 600, 26, "", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Visible = false })

-- рядок 2: підпис + загальна шкала + TEST +10
local row2Label = textAt(content, CX0, 153, 150, 28, "Ore Given", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1 })
local row2Bar = makeBar(content, 212, 128, CW - 338, 50, 28, 1)
local testBtn = makeButton(content, CW - 108, 133, 150, 40, { shadowDy = 5, textSize = 20, text = "TEST +10", color = "gray", z = 2 })
testBtn.onClick = function() Action:FireServer("TestOre") end
local isDev = false -- кнопку TEST +10 прибрано на прохання користувача
testBtn.btn.Visible = isDev
testBtn.shadow.Visible = isDev

-- рядки руди (Coal, Copper, Iron)
-- Рядки (руда + Money) у вікні перегляду з вертикальним повзунком справа. Рамка вікна не росте: якщо рядків більше,
-- ніж влазить (голем спить → рядок Money), їх гортають коліщатком, повзунком або кліком по доріжці (як в SellWindow).
local RW = CW - 34                  -- ширина рядка (справа місце під повзунок)
local VIEW_Y, VIEW_H = ROWS_Y - 4, 324 -- вікно перегляду: від першого рядка до кнопок дії (y 520)
local SB_X, SB_W = CX0 + RW + 12, 22
local rowsView = frame(content, CX0 - 4, VIEW_Y, RW + 8, VIEW_H, nil, { Name = "RowsView", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 1 })
local rowsStrip = frame(rowsView, 0, 0, RW + 8, VIEW_H, nil, { Name = "Strip", BackgroundTransparency = 1, ZIndex = 1 })
local rowsH = 8 + 3 * ROW_H + 2 * ROW_GAP -- висота вмісту (3 або 4 рядки)
local scrollY = 0
local vTrack = frame(content, SB_X, VIEW_Y, SB_W, VIEW_H, WHITE, { Name = "RowsScroll", Active = true, ZIndex = 2 })
vgrad(vTrack, TRACK); stroke(vTrack, INK, 3)
local vThumb = frame(vTrack, 0, 0, SB_W, VIEW_H, WHITE, { Name = "Thumb", Active = true, ZIndex = 2 })
new("UIGradient", { Color = cseq(BTN_LIME), Rotation = 0 }, vThumb)
local function vMax(): number return math.max(0, rowsH - VIEW_H) end
local function vLayout()
	local ms = vMax()
	local th = ms > 0 and math.max(48, VIEW_H * VIEW_H / rowsH) or VIEW_H
	vThumb.Size = UDim2.fromOffset(SB_W, th)
	vThumb.Position = UDim2.fromOffset(0, ms > 0 and scrollY / ms * (VIEW_H - th) or 0)
	vThumb.BackgroundTransparency = ms > 0 and 0 or 0.55
	-- гортати нікуди (вміст ≤ висоти вікна) — повзунок не показуємо (правка користувача)
	vTrack.Visible = ms > 0
end
local function setScrollY(y: number)
	scrollY = math.clamp(y, 0, vMax())
	rowsStrip.Position = UDim2.fromOffset(0, -scrollY)
	vLayout()
end
local function vPress(inp) return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch end
local vDrag = nil
local function vWheel(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseWheel and vMax() > 0 then setScrollY(scrollY - inp.Position.Z * 60) end
end
rowsView.InputChanged:Connect(vWheel)
vTrack.InputChanged:Connect(vWheel)
vThumb.InputBegan:Connect(function(inp) if vPress(inp) then vDrag = { y = inp.Position.Y, s = scrollY, thumb = true } end end)
-- затиск мишки (або пальця) на рядках і рух вгору/вниз — гортання списку (як перетягування слотів у SellWindow)
UIS.InputBegan:Connect(function(inp)
	if not vPress(inp) or vDrag or vMax() <= 0 or not modalRoot.Visible then return end
	local p, a, s = inp.Position, rowsView.AbsolutePosition, rowsView.AbsoluteSize
	if p.X < a.X or p.X > a.X + s.X or p.Y < a.Y or p.Y > a.Y + s.Y then return end
	vDrag = { y = p.Y, s = scrollY, thumb = false }
end)
vTrack.InputBegan:Connect(function(inp)
	if not vPress(inp) or vDrag then return end
	local f = (inp.Position.Y - vTrack.AbsolutePosition.Y) / math.max(1, vTrack.AbsoluteSize.Y)
	setScrollY(f * rowsH - VIEW_H / 2)
end)
UIS.InputChanged:Connect(function(inp)
	if not vDrag or vMax() <= 0 then return end
	if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	local k = VIEW_H / math.max(1, vTrack.AbsoluteSize.Y) -- одиниць дизайну на піксель
	local dy = (inp.Position.Y - vDrag.y) * k
	if vDrag.thumb then
		setScrollY(vDrag.s + dy * vMax() / math.max(1, VIEW_H - vThumb.Size.Y.Offset))
	else
		setScrollY(vDrag.s - dy) -- тягнеш вгору — список їде вгору
	end
end)
UIS.InputEnded:Connect(function(inp) if vPress(inp) then vDrag = nil end end)
setScrollY(0)

local rows = {}
local openPicker, closePicker, onTileClick -- попап вибору кількості руди (нижче, після refresh)
-- рядки руди поточної мапи; нова мапа (Cfg.StageChanged) — рядки перебудовуються
local function buildRows()
for _, r in rows do r.row:Destroy() end
table.clear(rows)
for i = 1, math.min(3, #ORE) do
	local o = ORE[i]
	local row = frame(rowsStrip, 4, 4 + (i - 1) * (ROW_H + ROW_GAP), RW, ROW_H, WHITE, { Name = "OreRow_" .. o.key, ZIndex = 1 })
	stroke(row, INK, 3)
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.4) }) }, row)
	-- «Працює»: фон рядка заповнюється зеленим, поки голем переплавляє саме цю руду (SmeltStart … SmeltStart + SmeltDur)
	local prog = frame(row, 0, 0, 0, ROW_H, WHITE, { Name = "Progress", ZIndex = 0, Visible = false, BackgroundTransparency = 0.35 })
	vgrad(prog, { { 0, "b6f07a" }, { 0.55, "6cc934" }, { 1, "3f9d18" } })
	-- «задня панель» як у картки: слабші похилі смуги (найнепрозоріша ≈ 0,9 прозорості) над прогресом (зелене видно крізь них)
	-- і темна суцільна смужка 8 px уздовж низу всередині обводки. ZIndex у рядку: прогрес 0, смуги й смужка 1, плитки 2,
	-- тексти й шкала 3
	bands(row, 3, RW, ROW_H, 0.1 / 0.18, 1)
	-- (темну смужку знизу рядка прибрано на прохання користувача)
	-- затемнення рядка, коли відкрито попап іншого рядка (рядки в RowsView — спільне PickerDim їх не накриває)
	local rowDim = frame(row, 0, 0, RW, ROW_H, C("0d0f12"), { Name = "RowDim", BackgroundTransparency = 0.5, Visible = false, ZIndex = 9 })
	local tile = makeTile(row, 8, 8, o.key, ICONS["ore_" .. o.key], true, "Ore_" .. o.key)
	local check = makeCheck(tile.root)
	local badge = makeBadge(tile.root)
	StyleA.bind(tile, { debounce = 0.2, canClick = function() return tile.root.Active end, onClick = function() onTileClick(i) end })
	-- підказка посеред рядка («Not enough room» / «No Coal»), коли покласти нічого
	local toast = textAt(row, 330 + (RW - 956) / 2, 48, 380, 30, "", C("ffd34d"), 4, { TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8, Visible = false })
	textAt(row, 106, 32, 320, 38, o.key, WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	local sub = textAt(row, 106, 70, 600, 22, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 3 })
	-- «Спить»: шкала віддано / треба
	local bar = makeBar(row, 440, 22, RW - 440 - 16, 52, 30, 3)
	-- «Працює»: кількість злитків + плитка злитка
	local barsText = textAt(row, RW - 104 - 420, 48, 420, 44, "", LIME_TXT, 4, { TextXAlignment = Enum.TextXAlignment.Right, RichText = true, ZIndex = 3 })
	local ingot = makeTile(row, RW - 8 - 80, 8, o.key, ICONS["bar_" .. o.key], nil, "Bars_" .. o.key).root
	-- 08.11.2026: руди в інвентарі вистачає, щоб закрити цей рядок пробудження — золота рамка навколо рядка блимає (ReadyGlow)
	local glow = frame(row, 2, 2, RW - 4, ROW_H - 4, nil, { Name = "ReadyGlow", BackgroundTransparency = 1, Visible = false, ZIndex = 8 })
	local glowS = new("UIStroke", { Color = C("ffd23a"), Thickness = 6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, glow)
	rows[i] = { dim = rowDim, ore = o, row = row, tile = tile, badge = badge, toast = toast, toastTok = 0, sub = sub, bar = bar, check = check, barsText = barsText, ingot = ingot, prog = prog,
		glow = glow, glowS = glowS, ready = false }
end
end
buildRows()
Cfg.StageChanged.Event:Connect(buildRows)

-- затемнення «Прокидається / Засинає» (накриває рядок 2 і рядки руди; ловить кліки)
local overlay = frame(content, 34, 120, CW + 16, 388, C("0d0f12"), { Name = "Overlay", BackgroundTransparency = 0.28, Active = true, Visible = false, ZIndex = 5 })
local overWord = textAt(overlay, 0, 160, 900, 72, "", C("ffd34d"), 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
local overDots = textAt(overlay, 0, 160, 140, 72, "", C("ffd34d"), 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
local overBar = makeBar(overlay, 280 - 34 + DX, 342 - 120, 480, 36, nil, 1)
local over = { word = nil, keys = FILL.amber, t0 = nil, dur = 4.2 }

-- кнопки дії (стиль A: green — можна, gray — не можна)
local btnLeft = makeButton(content, 104 + DX, 520, 400, 82, { shadowDy = 8, textSize = 40, text = "", color = "green", z = 6 })
local btnRight = makeButton(content, 536 + DX, 520, 400, 82, { shadowDy = 8, textSize = 40, text = "", color = "green", z = 6 })
local function fireAction(b)
	if not b.action then return end
	if b.action == "Take" then UISounds.play("claim") end -- злитки в інвентар = нагорода
	Action:FireServer(b.action)
	-- 08.11.2026: проміжна підказка Workshop — натиснув Give Ore → підказку пройдено (AnalyticsFunnels, Funnels Hint_Workshop)
	if b.action == "Give" and player:GetAttribute("WsHintGive") == true then
		player:SetAttribute("WsHintGive", nil)
		local h = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("HintAction")
		if h then h:FireServer("Done", "Workshop") end
	end
end
btnLeft.onClick = fireAction
btnRight.onClick = fireAction
-- 08.11.2026: підсвітка, що блимає: рядки руди, яких уже вистачає (ReadyGlow). Кнопка Give Ore не блимає (прибрано на прохання).
do
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local pulse = 0.5 + 0.5 * math.sin(t * 5)
		for _, r in rows do
			if r.glow then
				r.glow.Visible = r.ready == true
				if r.ready then r.glowS.Transparency = 0.1 + 0.75 * pulse end
			end
		end
	end)
end

-- рядок «Money» (лише поки голем спить / прокидається): скільки грошей треба за пробудження (Cfg.WAKE_MONEY).
-- Гроші не віддаються частинами, як руда: сервер знімає їх кнопкою Wake Up. Шкала — баланс гравця до потрібної суми.
local moneyRow
do
	local row = frame(rowsStrip, 4, 4 + 3 * (ROW_H + ROW_GAP), RW, ROW_H, WHITE, { Name = "MoneyRow", ZIndex = 1, Visible = false })
	stroke(row, INK, 3)
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.4) }) }, row)
	bands(row, 3, RW, ROW_H, 0.1 / 0.18, 1)
	local tile = StyleA.new(row, { size = Vector2.new(80, 80), position = Vector2.new(8, 8), anchor = Vector2.zero, color = "green", half = true,
		rows = 4, text = "$", textSize = 58, zIndex = 2, shine = false })
	local check = makeCheck(tile.root)
	textAt(row, 106, 32, 320, 38, "Money", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	local sub = textAt(row, 106, 70, 600, 22, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 3 })
	local bar = makeBar(row, 440, 22, RW - 440 - 16, 52, 30, 3)
	moneyRow = { row = row, sub = sub, bar = bar, check = check }
end

-- висота вікна: tall — 4 рядки (руда + Money), інакше 3. Росте все вікно вниз, кнопки дії зсуваються, полотно перецентровується.
local curExtra = 0
local fitRef -- fit() оголошено нижче
local btnBase = {}
for _, b in { btnLeft, btnRight } do btnBase[b] = { b.btn.Position, b.shadow.Position } end
-- Рамка вікна НЕ росте (правило: не збільшувати вікно, а адаптувати вміст): tall — 4-й рядок Money з'являється в списку,
-- список стає довшим за вікно перегляду і гортається повзунком справа.
local curTall = nil
local function setTall(tall: boolean)
	if curTall == tall then return end
	curTall = tall
	moneyRow.row.Visible = tall
	local n = tall and 4 or 3
	rowsH = 8 + n * ROW_H + (n - 1) * ROW_GAP
	rowsStrip.Size = UDim2.fromOffset(RW + 8, rowsH)
	setScrollY(scrollY)
end
setTall(false)

-- заголовок «Forge» поза вікном: тінь-копія +7 і градієнтний текст (лівий край x 72, центр великих літер y 52)
-- заголовок КАПСОМ: «золото, що переливається» (кольори повільно пливуть зліва направо, період 4 с)
-- + білий відблиск, що час від часу пробігає зліва направо (як на кнопках стилю A)
-- Домовленість для всіх вікон: іконка зліва від тексту (тут — ковадло, mmg_title_anvil_v2), видима висота ≈ 2 × висоти літер,
-- нахил −8°, текст зсунуто праворуч, щоб не налазив; обводка й тінь тексту та тінь іконки — ЧОРНІ (INK),
-- як до спроби з #040435 (правка користувача); тінь — силует +9 вниз.
local TITLE_ICON = "rbxassetid://102635405420682" -- mmg_title_anvil_black (Decal 117805404448692): ковадло й 2 зірочки, чорний контур #14161a
local TITLE_IS = 222                                -- розмір картинки іконки (ковадло — ~65 % її висоти ≈ 2 × висоти літер)
local TITLE_ICX, TITLE_ICY = 56 + TITLE_IS / 2, 38  -- центр іконки
local TITLE_X = TITLE_ICX + TITLE_IS * 0.44 + 10    -- лівий край тексту — одразу за правим краєм ковадла
new("ImageLabel", { Name = "TitleIconShadow", BackgroundTransparency = 1, Image = TITLE_ICON, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY + 9), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 3 }, pop)
new("ImageLabel", { Name = "TitleIcon", BackgroundTransparency = 1, Image = TITLE_ICON, ScaleType = Enum.ScaleType.Fit,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 4 }, pop)
local titleShadow = textAt(pop, TITLE_X, 50 + 9, 560, 118, "WORKSHOP", INK, 11, { Name = "TitleShadow", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, TITLE_X, 50, 560, 118, "WORKSHOP", WHITE, 10, { Name = "Title", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local titleShine = textAt(pop, TITLE_X, 50, 560, 118, "WORKSHOP", WHITE, 0, { Name = "TitleShine", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
do
	-- періодичний градієнт: світле золото → золото → помаранчеве → золото → світле золото; один період = половина ширини напису
	local P = { C("fff6b0"), C("ffc531"), C("ff9a1a"), C("ffc531") }
	local function sample(u) -- u у [0, 1) по періоду
		local x = (u % 1) * #P
		local i = math.floor(x)
		local t = x - i
		t = t * t * (3 - 2 * t) -- плавний перехід між кольорами
		return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
	end
	RunService.Heartbeat:Connect(function()
		if not title.Visible or not modalRoot.Visible then return end
		local phase = -(os.clock() / 4)
		local ks = {}
		for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end -- 19 точок (максимум 20) — без «сходинок»
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

-- червона квадратна кнопка X над заголовком (стиль A red + іконка stylea_icon_x; тінь 5, кнопка 6). Іконка трохи більша
-- за грань (iconPad −0,05): у PNG плече X ≈ 27 % ширини, тож на кнопці плече ≈ 0,30 висоти грані, як у GDD
-- заголовок і X — ті самі пропорції, що в Inventory (×650/528): на екрані однакові розмір і місце
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })
closeBtn.btn.Name = "Close"

-- =====================================================================
-- ===== масштаб під екран =====
-- =====================================================================
local WindowFit = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowFit"))
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	-- верхня смуга Roblox (кнопки меню й чату): вікно ставимо нижче неї, щоб не перекривати ці кнопки на телефоні
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	local fullH = vh
	vh -= top
	modalRoot.Position = UDim2.new(0.5, 0, 0.5, top / 2)
	local phone = vh < 500 or (UIS.TouchEnabled and not UIS.MouseEnabled)
	-- адаптивний масштаб: вікно займає однакову частку екрана (Shared/WindowFit)
	-- рамка (без 4-го рядка Money) 1 в 1 як Inventory; високе вікно лише доростає вниз
	-- розмір і місце — спільне правило всіх вікон (Shared/WindowFit.place)
	WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H + curExtra, winX = WIN_X, winY = WIN_Y, winW = WIN_W, winH = WIN_H, extraH = curExtra })
end
fitRef = fit
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
-- ===== дані =====
-- =====================================================================
local function num(v, default) return tonumber(v) or default end
local function inv(key: string): number return num(player:GetAttribute(key), 0) end
-- заблоковані в інвентарі ключі (атрибут InvLocks): такі предмети не віддаються в кузню (сервер теж перевіряє)
local HttpService = game:GetService("HttpService")
local function isLocked(key: string): boolean
	local ok, l = pcall(HttpService.JSONDecode, HttpService, (player:GetAttribute("InvLocks") :: string?) or "[]")
	if ok and type(l) == "table" then for _, k in l do if k == key then return true end end end
	return false
end
local function avail(key: string): number return isLocked(key) and 0 or inv(key) end

-- чипи зліва направо (проміжок 14); повертає праву межу останнього
local function setChips(list)
	local x = CX0
	for i, chip in chips do
		local spec = list[i]
		chip.frame.Visible = spec ~= nil
		if spec then
			local txt = Loc.t(spec[1])
			local w = math.floor(textWidth(txt, 26, HEAVY) + 44 + 0.5)
			chip.body:setText(txt)
			chip.body:setColor(spec[2])
			chip.body:setSize(Vector2.new(w, ROW1_H))
			chip.frame.Position = UDim2.fromOffset(x, ROW1_Y)
			chip.frame.Size = UDim2.fromOffset(w, ROW1_H)
			x += w + 14
		end
	end
	return x - 14
end
local function setMessage(text: string?, size: number, chipRight: number)
	message.Visible = text ~= nil
	if not text then return end
	local x = chipRight + 20
	message.Text = text
	message.TextSize = size
	message.Position = UDim2.fromOffset(x, 95 - size * 0.6)
	message.Size = UDim2.fromOffset(CX0 + CW - x, size * 1.2)
end
-- стан «WAITING...»: кузня працює, але голем нічого не плавить (піддон руди порожній). Чип показує слово з крапками, що
-- з'являються по одній (MaxVisibleGraphemes ховає зайві крапки, тож слово не рухається). Слово — Cfg.WAIT_WORD (те саме й на табличці).
local WAIT_TEXT = Cfg.WAIT_WORD .. "..."
local waiting = false
local function waitDots(): number return math.floor(os.clock() / 0.35) % 3 + 1 end
local function setWaiting(on: boolean)
	waiting = on
	local l = chips[1].body.label
	if l then l.MaxVisibleGraphemes = on and (#WAIT_TEXT - 3 + waitDots()) or -1 end
end
local function setOverlay(word: string?, keys, f: Model)
	overlay.Visible = word ~= nil
	if not word then over.word = nil; return end
	over.keys = keys
	over.t0 = tonumber(f:GetAttribute("StateTime"))
	over.dur = (keys == FILL.purple and Cfg.DOZE_TIME or Cfg.WAKE_TIME) or 4.2
	if over.word ~= word then
		over.word = word
		-- слово + «...» по центру x 520 вікна; крапки окремим лейблом, щоб слово не стрибало
		local ww, dw = textWidth(word, 72, HEAVY), textWidth("...", 72, HEAVY)
		local x0 = WIN_W / 2 - 34 - (ww + dw) / 2
		overWord.Text = word
		overWord.Position = UDim2.fromOffset(x0, 160 - 43.2)
		overWord.Size = UDim2.fromOffset(ww + 8, 86.4)
		overDots.Position = UDim2.fromOffset(x0 + ww, 160 - 43.2)
	end
end

-- оновити все вікно за станом кузні f; instant — без анімації шкал (одразу після відкриття)
local function refresh(f: Model, instant: boolean)
	local st = f:GetAttribute("State")
	for _, r in rows do r.ready = false end -- 08.11.2026: ReadyGlow — нижче, лише поки голем спить
	if st ~= "Waking" and st ~= "Working" and st ~= "Dozing" then st = "Asleep" end

	if st == "Asleep" or st == "Waking" then
		-- ===== голем спить / прокидається: віддаємо руду для пробудження =====
		local right = setChips({ st == "Waking" and { "WAKING UP", "yellow" } or { "ASLEEP", "blue" } })
		setWaiting(false)
		setMessage(st == "Waking" and MSG_WAKING or MSG_ASLEEP, 26, right)
		local given, need, canGive, allFull = 0, 0, false, true
		for i, r in rows do
			local key = r.ore.key
			local req = num(Cfg.WAKE_REQ[i], 0)
			local g = num(f:GetAttribute("Wake_" .. key), 0)
			local have = inv("Ore_" .. key)
			local lockedOre = isLocked("Ore_" .. key)
			local full = g >= req
			given += math.min(g, req); need += req
			if not full then allFull = false end
			if have > 0 and not full and not lockedOre then canGive = true end
			r.sub.Text = "You have " .. NF.full(have) .. (lockedOre and have > 0 and " · Locked" or "")
			r.bar.track.Visible = true
			setBar(r.bar, req > 0 and g / req or 1, full and FILL.lime or FILL.cyan, NF.full(g) .. " / " .. NF.full(req), instant)
			r.check.Visible = full
			r.ready = st == "Asleep" and not full and not lockedOre and have >= req - g
			r.barsText.Visible = false
			r.ingot.Visible = false
			r.badge.ring.Visible = false
			r.tile.root.Active = false
		end
		-- гроші за пробудження (знімаються кнопкою Wake Up)
		local wm = num(Cfg.WAKE_MONEY, 0)
		local cash = inv("Money")
		local paid = wm <= 0 or cash >= wm
		setTall(wm > 0)
		if wm > 0 then
			moneyRow.sub.Text = "You have " .. NF.money(cash)
			setBar(moneyRow.bar, cash / wm, paid and FILL.lime or FILL.cyan, NF.money(math.min(cash, wm)) .. " / " .. NF.money(wm), instant)
			moneyRow.check.Visible = paid
		end
		row2Label.Text = "Ore Given"
		setBar(row2Bar, need > 0 and given / need or 0, given >= need and FILL.lime or FILL.cyan, NF.full(given) .. " / " .. NF.full(need), instant)
		setButton(btnLeft, "Give Ore", "Give", st == "Asleep" and canGive)
		setButton(btnRight, "Wake Up", "Wake", st == "Asleep" and allFull and paid)
		setOverlay(st == "Waking" and "WAKING UP" or nil, FILL.amber, f)
	else
		-- ===== голем працює / засинає: піддон руди і злитки =====
		setTall(false)
		local right
		if st == "Working" then
			local spd = Cfg.spdOf(num(f:GetAttribute("SpdLvl"), 1))
			-- голем не працює: нічого не плавиться і на піддоні руди немає (та сама умова, що й у таблички над кузнею)
			local idle = f:GetAttribute("Busy") ~= true
			if idle then
				for _, r in rows do
					if num(f:GetAttribute("Pal_" .. r.ore.key), 0) > 0 then idle = false; break end
				end
			end
			local oph = Cfg.ophOf(num(f:GetAttribute("OphLvl"), 1)) -- Ore per Hit: скільки руди за один удар
			right = setChips({ idle and { WAIT_TEXT, "gray" } or { "WORKING", "green" }, { Loc.f("{1} ORE EVERY {2}s", oph, fmtNum(spd)), "blue" },
				{ (function() -- 05.11.2026: продукт мапи — злитки, огранені кристали або обидва
					local bar, cut = false, false
					for _, r in rows do if Cfg.canSmelt(r.ore) then if Cfg.productOf(r.ore.key) == "Cut" then cut = true else bar = true end end end
					return Loc.f(((cut and bar) and "REFINED" or (cut and "CUT GEM" or "BAR")) .. " = ×{1} ORE PRICE", fmtNum(Cfg.BAR_MULT))
				end)(), "orange" } })
			setWaiting(idle)
			setMessage(nil, 26, right)
		else
			right = setChips({ { "FALLING ASLEEP", "purple" } })
			setWaiting(false)
			setMessage(MSG_DOZING, 24, right)
		end
		local cap = Cfg.capOf(num(f:GetAttribute("CapLvl"), 1))
		local value, totalBars = 0, 0
		for _, r in rows do
			local key = r.ore.key
			local pal = num(f:GetAttribute("Pal_" .. key), 0)
			value += pal * r.ore.price
			totalBars += num(f:GetAttribute("Bars_" .. key), 0)
		end
		local room = cap - value
		local canPut = false
		for _, r in rows do
			local key = r.ore.key
			local have = inv("Ore_" .. key)
			local pal = num(f:GetAttribute("Pal_" .. key), 0)
			local bars = num(f:GetAttribute("Bars_" .. key), 0)
			local smelt = Cfg.canSmelt(r.ore) -- вугілля не плавиться: рядок лише показує запас
			local lockedOre = isLocked("Ore_" .. key)
			if smelt and not lockedOre and have > 0 and r.ore.price <= room then canPut = true end
			r.sub.AutoLocalize = false
			r.sub.Text = smelt and Loc.f((lockedOre and have > 0) and "You have {1} (locked) · On pallet {2}" or "You have {1} · On pallet {2}", NF.full(have), NF.full(pal))
				or Loc.f("You have {1} · Sell it at the shop", NF.full(have))
			r.bar.track.Visible = false
			r.check.Visible = false
			r.barsText.Visible = true
			r.barsText.Text = smelt and ('<font weight="800" size="22" color="#e9edf1">' .. (Cfg.productOf(key) == "Cut" and "Cut" or "Bars") .. '</font>  ×' .. NF.full(bars)) or "Can't smelt"
			r.barsText.TextColor3 = (smelt and bars > 0) and LIME_TXT or GRAY_TXT
			r.ingot.Visible = smelt
			local canOre = smelt and not lockedOre and st == "Working" and math.min(have, math.floor(room / r.ore.price)) > 0
			r.badge.ring.Visible = smelt and st == "Working"
			r.tile.root.Active = smelt and st == "Working"
			setBadge(r.badge, canOre)
		end
		row2Label.Text = "Ore Pallet"
		setBar(row2Bar, cap > 0 and value / cap or 0, FILL.orange, NF.money(value) .. " / " .. NF.money(cap), instant)
		setButton(btnLeft, "Put All Ore", "Put", st == "Working" and canPut)
		setButton(btnRight, Loc.f("Take All ({1})", NF.full(totalBars)), "Take", st == "Working" and totalBars > 0) -- 05.11.2026: злитки й кристали
		setOverlay(st == "Dozing" and "FALLING ASLEEP" or nil, FILL.purple, f)
	end
end

-- переплавка: зелене заповнення рядка руди, яку голем переплавляє зараз. Сервер на початку кожної руди ставить
-- SmeltType (яка руда), SmeltStart (час сервера) і SmeltDur (= швидкість, spdOf(SpdLvl)); коли шкала повна —
-- сервер додає злиток і починає наступну руду, тож заповнення скидається й іде знову.
local shownForge = nil -- кузня, яку зараз показує вікно (ставить step)
RunService.Heartbeat:Connect(function()
	if not modalRoot.Visible then return end
	local f = shownForge
	local cur, frac = nil, 0
	if f and f.Parent and f:GetAttribute("State") == "Working" then
		local t0, dur = tonumber(f:GetAttribute("SmeltStart")), tonumber(f:GetAttribute("SmeltDur"))
		if t0 and dur and dur > 0 then
			frac = (workspace:GetServerTimeNow() - t0) / dur
			if frac > 0 and frac <= 1 then cur = tonumber(f:GetAttribute("SmeltType")) end
		end
	end
	for i, r in rows do
		local on = cur == i
		if r.prog.Visible ~= on then r.prog.Visible = on end
		if on then r.prog.Size = UDim2.fromOffset(math.max(44, frac * CW), ROW_H) end
	end
end)

-- =====================================================================
-- ===== попап вибору кількості руди (клік по плитці руди в рядку, коли голем працює) =====
-- =====================================================================
-- Макет: ui/forge_ore_popup. Попап — маленьке вікно 620 × 410 в стилі вікна кузні, справа від плитки зі стрілкою на неї.
-- Максимум = мін(скільки є руди, скільки ще вміщається на палеті за ціною руди). «All» лише ставить повзунок
-- на максимум; кладе руду «Put N» (Action "PutOre", { ore, n }). Сервер перевіряє ще раз. Дані оновлюються кожні 0,15 с (pickerUpdate).
local CAS = game:GetService("ContextActionService")
local POP_W, POP_H, PK_PAD = 620, 410, 32
local picker = { open = false, i = 1, v = 1, mx = 1, drag = false, value = 0, cap = 0 }
local PK = {}

local function palInfo(f: Model): (number, number)
	local cap = Cfg.capOf(num(f:GetAttribute("CapLvl"), 1))
	local value = 0
	for _, r in rows do value += num(f:GetAttribute("Pal_" .. r.ore.key), 0) * r.ore.price end
	return value, cap
end
-- скільки руди i-го рядка можна покласти зараз
local function maxPutFor(f: Model, i: number): number
	local r = rows[i]
	if not Cfg.canSmelt(r.ore) then return 0 end
	local value, cap = palInfo(f)
	return math.max(0, math.min(avail("Ore_" .. r.ore.key), math.floor((cap - value) / r.ore.price)))
end

local function showToast(i: number, text: string)
	local r = rows[i]
	r.toast.Text = text
	r.toast.Visible = true
	r.toastTok += 1
	local my = r.toastTok
	task.delay(1.4, function() if r.toastTok == my then r.toast.Visible = false end end)
end

do
	local dim = frame(content, 0, 0, WIN_W, WIN_H, C("0d0f12"), { Name = "PickerDim", BackgroundTransparency = 0.5, Active = true, Visible = false, ZIndex = 20 })
	-- закриваємо лише кліком ПОЗА вікном попапа (InputBegan затемнення спрацьовує й під самим вікном) або хрестиком
	dim.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		local r = PK.root
		if r and r.Visible then
			local p, a, s = inp.Position, r.AbsolutePosition, r.AbsoluteSize
			if p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y then return end
		end
		closePicker()
	end)
	PK.dim = dim
	-- стрілка до плитки: повернуті на 45° квадрати (ink + колір обрамлення), обидва шаром НИЖЧЕ вікна попапа (ZIndex 28 / 29 < 30), щоб не перекривати його рамку
	PK.arrowInk = frame(content, 0, 0, 41, 41, INK, { Name = "PickerArrowInk", AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, Visible = false, ZIndex = 28 })
	PK.arrowFill = frame(content, 0, 0, 31, 31, C("585e66"), { Name = "PickerArrowFill", AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, Visible = false, ZIndex = 29 })

	local root = frame(content, 0, 0, POP_W, POP_H, nil, { Name = "Picker", BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 30 })
	PK.root = root
	PK.scale = new("UIScale", {}, root)
	frame(root, 0, 10, POP_W, POP_H, BLACK, { Name = "Shadow", BackgroundTransparency = 0.65, ZIndex = 1 })
	local win = frame(root, 0, 0, POP_W, POP_H, WHITE, { Name = "Window", ZIndex = 2 })
	vgrad(win, RIM); stroke(win, INK, 5)
	local rl = frame(win, 6, 6, POP_W - 12, POP_H - 12, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	stroke(rl, C("6a7078"), 1.5, 0.1)
	local pw, ph = POP_W - 36, POP_H - 36
	local panel = frame(win, 18, 18, pw, ph, C("a9aeb5"), { Name = "Panel", ZIndex = 2, ClipsDescendants = true })
	stroke(panel, INK, 4)
	local studs = frame(panel, 0, 0, pw, ph, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	do
		local CELL = 40
		local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
		local ox, oy = (pw - nx * CELL) / 2, (ph - ny * CELL) / 2
		StyleA.studTile(studs, ox, oy, nx * CELL, ny * CELL, CELL, C("b3b8bf")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
	end
	local shade = frame(panel, 0, 0, pw, ph, WHITE, { Name = "Shade", ZIndex = 2 })
	new("UIGradient", { Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE), ColorSequenceKeypoint.new(1, WHITE) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1), NumberSequenceKeypoint.new(1, 0.82) }) }, shade)
	local cont = frame(win, 0, 0, POP_W, POP_H, nil, { BackgroundTransparency = 1, ZIndex = 3 })

	-- шапка: плитка руди, назва, «You have N · Pallet fits M», закрити
	PK.tile = StyleA.new(cont, { size = Vector2.new(64, 64), position = Vector2.new(PK_PAD, PK_PAD), anchor = Vector2.zero, color = "ore_coal", half = true, rows = 4, zIndex = 2 })
	PK.title = textAt(cont, PK_PAD + 80, PK_PAD + 17, 300, 38, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	PK.sub = textAt(cont, PK_PAD + 80, PK_PAD + 50, 420, 20, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 3 })
	PK.close = makeButton(cont, POP_W - PK_PAD - 60, PK_PAD, 60, 60, { shadowDy = 5, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 4 })
	PK.close.onClick = function() closePicker() end
	-- число
	PK.read = textAt(cont, 0, 148, POP_W, 56, "", WHITE, 5, { ZIndex = 3, RichText = true })
	-- повзунок по центру: доріжка + лаймова заливка до ручки + ручка (сіра кнопка стилю A 46 × 58) + − / +
	local TW = POP_W - 2 * PK_PAD - 2 * 68
	local TX, TY, TH = PK_PAD + 68, 188, 36
	local KW, KH = 46, 58
	local bar = makeBar(cont, TX, TY, TW, TH, nil, 3)
	setKeys(bar, FILL.lime)
	bar.fill.Visible = true
	bar.track.Active = true
	PK.bar = bar
	PK.knob = StyleA.new(cont, { size = Vector2.new(KW, KH), position = Vector2.new(TX, TY + TH / 2 - KH / 2 - 4), anchor = Vector2.zero, color = "gray", rows = 4, clickable = true, shine = false, zIndex = 8 })
	StyleA.bind(PK.knob, { hoverAlways = true })
	PK.minL = textAt(cont, TX + 2, TY + TH + 25, 60, 26, "1", INK, 0, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 3 })
	PK.maxL = textAt(cont, TX + TW - 62, TY + TH + 25, 60, 26, "", INK, 0, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 3 })
	PK.cost = textAt(cont, 0, TY + TH + 25, POP_W, 22, "", INK, 0, { FontFace = XBOLD, ZIndex = 3 })
	PK.minus = makeButton(cont, PK_PAD, TY + TH / 2 - 26, 52, 52, { shadowDy = 5, textSize = 34, text = "−", color = "gray", z = 4 })
	PK.plus = makeButton(cont, POP_W - PK_PAD - 52, TY + TH / 2 - 26, 52, 52, { shadowDy = 5, textSize = 34, text = "+", color = "gray", z = 4 })
	-- кнопки: All (повзунок на максимум) і Put N (підтвердити)
	local btnY = POP_H - 18 - 16 - 83
	PK.all = makeButton(cont, PK_PAD, btnY, 230, 76, { shadowDy = 7, textSize = 36, text = "All", color = "green", z = 4 })
	PK.put = makeButton(cont, PK_PAD + 246, btnY, POP_W - 2 * PK_PAD - 246, 76, { shadowDy = 7, textSize = 36, text = "Put 1", color = "green", z = 4 })

	function PK.set(v: number)
		v = math.clamp(math.floor(v + 0.5), 1, math.max(1, picker.mx))
		picker.v = v
		local f = picker.mx > 1 and (v - 1) / (picker.mx - 1) or 1
		PK.knob:setPosition(Vector2.new(TX + f * (TW - KW), TY + TH / 2 - KH / 2 - 4))
		bar.fill.Size = UDim2.fromOffset(f * (TW - KW) + KW / 2, TH)
		PK.read.Text = NF.full(v) .. '<font size="30" color="#c9ced4"> / ' .. NF.full(picker.mx) .. "</font>"
		PK.maxL.Text = NF.full(picker.mx)
		PK.all:setText("All")
		PK.put:setText(Loc.f("Put {1}", NF.full(v)))
		local price = rows[picker.i].ore.price
		PK.cost.AutoLocalize = false
		PK.cost.Text = Loc.f("+{1} · pallet {2} / {3}", NF.money(v * price), NF.money(picker.value + v * price), NF.money(picker.cap))
	end
	local function setFromX(x: number)
		local abs = bar.track.AbsoluteSize.X
		if abs <= 0 then return end
		local f = math.clamp(((x - bar.track.AbsolutePosition.X) / (abs / TW) - KW / 2) / (TW - KW), 0, 1)
		PK.set(1 + f * (picker.mx - 1))
	end
	local function isPress(inp: InputObject): boolean
		return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
	end
	local function beginDrag(inp: InputObject)
		if isPress(inp) then picker.drag = true; setFromX(inp.Position.X) end
	end
	PK.knob.root.InputBegan:Connect(beginDrag)
	bar.track.InputBegan:Connect(beginDrag)
	UIS.InputChanged:Connect(function(inp)
		if picker.drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then setFromX(inp.Position.X) end
	end)
	UIS.InputEnded:Connect(function(inp) if isPress(inp) then picker.drag = false end end)
	PK.minus.onClick = function() PK.set(picker.v - 1) end
	PK.plus.onClick = function() PK.set(picker.v + 1) end
	PK.all.onClick = function() PK.set(picker.mx) end
	PK.put.onClick = function()
		local r = rows[picker.i]
		Action:FireServer("PutOre", { ore = r.ore.key, n = picker.v })
		closePicker()
	end
end

-- клавіші поки попап відкритий: ← → (або ↓ ↑) — ±1, Enter — Put N, Esc — закрити (Sink, щоб персонаж і камера не рухались)
local function pickerKey(_, state, inp: InputObject)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	local k = inp.KeyCode
	if k == Enum.KeyCode.Left or k == Enum.KeyCode.Down then PK.set(picker.v - 1)
	elseif k == Enum.KeyCode.Right or k == Enum.KeyCode.Up then PK.set(picker.v + 1)
	elseif k == Enum.KeyCode.Return then PK.put.onClick(PK.put)
	elseif k == Enum.KeyCode.Escape then closePicker() end
	return Enum.ContextActionResult.Sink
end

local function pickerTexts(f: Model)
	local r = rows[picker.i]
	PK.sub.AutoLocalize = false
	PK.sub.Text = Loc.f("You have {1} · Pallet fits {2}", NF.full(inv("Ore_" .. r.ore.key)), NF.full(picker.mx))
end

closePicker = function()
	picker.drag = false
	if not picker.open then return end
	picker.open = false
	PK.dim.Visible = false
	PK.root.Visible = false
	PK.arrowInk.Visible = false
	PK.arrowFill.Visible = false
	for _, r in rows do r.row.ZIndex = 1; r.dim.Visible = false end
	rowsView.ZIndex = 1
	pcall(function() CAS:UnbindAction("ForgePicker") end)
end

openPicker = function(i: number)
	local f = shownForge
	if not f or f:GetAttribute("State") ~= "Working" then return end
	local mx = maxPutFor(f, i)
	if mx < 1 then return end
	local r = rows[i]
	picker.open, picker.i, picker.mx = true, i, mx
	picker.value, picker.cap = palInfo(f)
	local tcy = VIEW_Y + 4 + (i - 1) * (ROW_H + ROW_GAP) + 48 - scrollY
	local gx = CX0 + 8 + 80 + 40
	local top = math.clamp(tcy - 70, 84, WIN_H - POP_H - 26)
	local ay = math.clamp(tcy - top, 46, POP_H - 46)
	PK.root.AnchorPoint = Vector2.new(0, ay / POP_H)
	PK.root.Position = UDim2.fromOffset(gx, top + ay)
	PK.arrowInk.Position = UDim2.fromOffset(gx - 5, top + ay)
	PK.arrowFill.Position = UDim2.fromOffset(gx - 5, top + ay)
	PK.tile:setColor(ORE_TILE[r.ore.key] or "gray")
	PK.tile:setIcon(ICONS["ore_" .. r.ore.key])
	PK.title.Text = r.ore.key
	pickerTexts(f)
	PK.set(mx)
	-- рядок з плиткою лишається яскравим над затемненням: вікно перегляду над PickerDim, інші рядки — під власним затемненням
	rowsView.ZIndex = 21
	for j, rr in rows do rr.dim.Visible = j ~= i end
	r.row.ZIndex = 21
	PK.dim.Visible = true
	PK.root.Visible = true
	PK.arrowInk.Visible = true
	PK.arrowFill.Visible = true
	PK.scale.Scale = 0.92
	tween(PK.scale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
	CAS:BindActionAtPriority("ForgePicker", pickerKey, false, Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Return, Enum.KeyCode.Escape)
end

onTileClick = function(i: number)
	local f = shownForge
	if not f or f:GetAttribute("State") ~= "Working" then return end
	if maxPutFor(f, i) < 1 then
		StyleA.shake(rows[i].tile)
		showToast(i, isLocked("Ore_" .. rows[i].ore.key) and inv("Ore_" .. rows[i].ore.key) > 0 and "Locked in inventory" or inv("Ore_" .. rows[i].ore.key) < 1 and ("No " .. rows[i].ore.key) or "Not enough room")
	else
		openPicker(i)
	end
end

-- що 0,15 с: дані попапа за поточним станом (голем споживає палету → максимум росте); якщо класти вже нема чого — закриваємо
local function pickerUpdate(f: Model)
	if not picker.open then return end
	if f:GetAttribute("State") ~= "Working" then closePicker(); return end
	local mx = maxPutFor(f, picker.i)
	if mx < 1 then closePicker(); return end
	picker.mx = mx
	picker.value, picker.cap = palInfo(f)
	pickerTexts(f)
	PK.set(math.min(picker.v, mx))
end

-- крапки в чіпі «WAITING...» (по одній, кожні 0,35 с)
RunService.Heartbeat:Connect(function()
	if not waiting or not modalRoot.Visible then return end
	local l = chips[1].body.label
	if l then
		local w = #WAIT_TEXT - 3 + waitDots()
		if l.MaxVisibleGraphemes ~= w then l.MaxVisibleGraphemes = w end
	end
end)

-- крапки й шкала затемнення (кожен кадр, лише коли затемнення видно)
RunService.Heartbeat:Connect(function()
	if not modalRoot.Visible or not overlay.Visible then return end
	local dots = string.rep(".", math.floor(os.clock() / 0.3) % 3 + 1)
	if overDots.Text ~= dots then overDots.Text = dots end
	local frac
	if over.t0 then
		frac = (workspace:GetServerTimeNow() - over.t0) / math.max(0.1, over.dur)
	else
		frac = (os.clock() % 2) / 1.7 -- немає StateTime: цикл 2 с, як у макеті
	end
	setBar(overBar, frac, over.keys, nil, true)
end)

-- =====================================================================
-- ===== відкриття / закриття =====
-- =====================================================================
local isOpen, dismissed = false, false
local animToken = 0

local function open()
	isOpen = true
	require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowManager")).opened("Forge") -- одне вікно на екрані: інші закриваються
	animToken += 1
	local my = animToken
	fit()
	backdrop.Visible = true
	modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	local t1 = tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 })
	t1.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and animToken == my then
			tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 })
		end
	end)
end

local function close()
	if not isOpen then return end
	isOpen = false
	closePicker()
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	local t = tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
	t.Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false
		modalRoot.Visible = false
		-- скинути наведення (на телефоні MouseLeave може не прийти)
		for _, b in { btnLeft, btnRight, testBtn, closeBtn } do b.hover = false; b.scale.Scale = 1 end
	end)
end

closeBtn.onClick = function()
	dismissed = true -- до виходу з кола й повторного входу
	close()
end
-- одне вікно на екрані (Shared/WindowManager): відкрилось інше вікно — Forge закривається й не відкривається знову, доки гравець не вийде з кола
require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowManager")).register("Forge", function() return isOpen end, function() dismissed = true; close() end)

-- своя кузня: ніша з OwnerUserId = UserId → Forge (шукаємо щоразу: ніші перебудовуються, кузня може стрімитися)
local function findMyForge(): Model?
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return nil end
	for _, n in niches:GetChildren() do
		if n:GetAttribute("OwnerUserId") == player.UserId then
			local f = n:FindFirstChild("Forge")
			if f then return f end
		end
	end
	return nil
end
-- відстань від центру кола до гравця по XZ у просторі RingCenter
local function ringDistance(f: Model): number
	local ring = f:FindFirstChild("Ring")
	local rc = ring and ring:FindFirstChild("RingCenter")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (rc and rc:IsA("BasePart") and hrp and hrp:IsA("BasePart")) then return math.huge end
	local d = rc.CFrame:PointToObjectSpace(hrp.Position)
	return Vector2.new(d.X, d.Z).Magnitude
end

local function step()
	local f = findMyForge()
	shownForge = f
	local dist = f and ringDistance(f) or math.huge
	local inside = dist <= Cfg.RING_R + ((isOpen or dismissed) and EXIT_PAD or 0)
	if not inside then dismissed = false end
	local want = f ~= nil and inside and not dismissed and player:GetAttribute("TutStep") == nil -- 06.11.2026: під час навчання вікно майстерні не відкривається
	if want and f then
		if not isOpen then
			refresh(f, true)
			open()
		else
			refresh(f, false)
			pickerUpdate(f)
		end
	elseif isOpen then
		close()
	end
end

-- перші заміри ширини тексту заздалегідь (щоб перше відкриття не чекало)
task.spawn(function()
	for _, s in { "ASLEEP", "WAKING UP", "WORKING", "FALLING ASLEEP", WAIT_TEXT } do textWidth(s, 26, HEAVY) end
	for _, s in { "WAKING UP", "FALLING ASLEEP", "..." } do textWidth(s, 72, HEAVY) end
end)

while true do
	local ok, err = pcall(step)
	if not ok then warn("ForgeWindow: " .. tostring(err)) end
	task.wait(REFRESH)
end
