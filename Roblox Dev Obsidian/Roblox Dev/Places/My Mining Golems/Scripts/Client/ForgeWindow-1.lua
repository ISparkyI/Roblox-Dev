-- ForgeWindow — модальне вікно кузні «Forge» по центру екрана (замість тимчасової темної панелі з ForgeClient).
-- Де: StarterPlayer/StarterPlayerScripts/ForgeWindow (LocalScript). Інтерфейс будується кодом (ScreenGui ForgeWindow).
-- Макет і числа: ui/forge_window (SPEC.md, gen_forge_window.py). Полотно 1120 × 740 одиниць дизайну, на екран
-- його масштабує один UIScale (ПК ≈ 0,93 при 1280 × 720, телефон ≈ 0,5). Стиль — GDD «2D іконки → Картки покращень»:
--   усе квадратне (без UICorner; обводки рамок — LineJoinMode Miter, гострі кути), блиск — прямокутна біла смужка зверху
--   (не окремий овал), у кнопках, чипах і плитках — напівпрозорий studs-шум (studNoise). Круглий лише значок-галочка.
-- Коли видно: гравець стоїть у колі своєї кузні (ніша в Workspace/Niches з атрибутом OwnerUserId = свій UserId,
--   далі Forge/Ring/RingCenter; відстань — XZ у просторі RingCenter, радіус Cfg.RING_R). Вийшов з кола — вікно закривається.
--   Хрестик закриває вікно до наступного входу в коло.
-- Дані (опитування кожні 0,15 с, кузню шукаємо щоразу заново — переживає перебудову ніші й стрімінг):
--   кузня: State (Asleep / Waking / Working / Dozing), StateTime, Wake_<руда>, Pal_<руда>, Bars_<руда>, CapLvl, SpdLvl;
--   гравець: Ore_<руда>. Числа — Shared/ForgeConfig, формат — Shared/NumberFormat.
-- Remotes/ForgeAction: "Give" і "Wake" (голем спить), "Put" і "Take" (працює), "TestOre" (кнопка TEST +10, лише в Studio).
--   Сервер (ForgeService) сам перевіряє коло, стан і кількість руди.
-- Іконки: ICONS нижче — PNG 512 з ui/forge_window/icons (forge_ore_*.png, forge_bar_*.png) після Asset Manager.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local Action = RS:WaitForChild("Remotes"):WaitForChild("ForgeAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ORE = Cfg.ORES

-- ===== іконки (вписати ID після завантаження PNG через Asset Manager) =====
local ICONS = {
	ore_Coal = "rbxassetid://122509413885861",   -- forge_ore_coal.png
	ore_Copper = "rbxassetid://108009889585390", -- forge_ore_copper.png
	ore_Iron = "rbxassetid://120329833545037",   -- forge_ore_iron.png
	bar_Coal = "rbxassetid://101473380326305",   -- forge_bar_coal.png
	bar_Copper = "rbxassetid://106483042191242", -- forge_bar_copper.png
	bar_Iron = "rbxassetid://101014974673426",   -- forge_bar_iron.png
}

-- ===== константи макета (одиниці дизайну) =====
local CANVAS_W, CANVAS_H = 1120, 740 -- ModalRoot
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1040, 650
local CX0, CW = 42, 956 -- ліва межа й ширина вмісту у вікні
local ROW1_Y, ROW1_H = 68, 50
local ROWS_Y, ROW_H, ROW_GAP = 192, 96, 10
local REFRESH = 0.15
local EXIT_PAD = 0.5 -- запас на виході з кола, щоб вікно не блимало на межі (сервер приймає дії до RING_R + 2.5)

local MSG_ASLEEP = "The golem is asleep. Bring ore to wake him up."
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

-- теми чипів: світлий / основний / темний (0 / 0.55 / 1)
local THEME = {
	green = { { 0, "a6e862" }, { 0.55, "6cc934" }, { 1, "3f9d18" } },
	blue = { { 0, "6fc6ff" }, { 0.55, "2f8ee6" }, { 1, "1a5cb0" } },
	orange = { { 0, "ffb15c" }, { 0.55, "f07a1e" }, { 1, "b8500c" } },
	red = { { 0, "ff6f66" }, { 0.55, "e2322f" }, { 1, "a8161b" } },
	purple = { { 0, "c08af7" }, { 0.55, "8a3fe6" }, { 1, "561aa8" } },
	amber = { { 0, "ffe27a" }, { 0.55, "ffb21e" }, { 1, "e07a06" } },
}
-- кнопки (GDD): лаймова — можна, тьмяна — не можна, сіра — службова
local BTN_LIME = { { 0, "eaff9a" }, { 0.5, "c3f04a" }, { 1, "8ccc22" } }
local BTN_DIM = { { 0, "d9e2b0" }, { 0.5, "aab884" }, { 1, "7d8a5c" } }
local BTN_GRAY = { { 0, "f4f5f6" }, { 0.5, "d6d8db" }, { 1, "a9adb2" } }
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
-- плитка руди: верх → низ
local TILE = {
	Coal = { { 0, "5a5f67" }, { 1, "23262b" } },
	Copper = { { 0, "c9643a" }, { 1, "6e2a12" } },
	Iron = { { 0, "c7a27a" }, { 1, "6b5038" } },
}

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
-- без заокруглень; ширина — 100 % батька мінус 2 × inset (тягнеться разом із чипом / заливкою шкали). alpha — «білий N%»
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
-- studs-шум усередині кнопки / чипа / плитки: сітка пупочок як у stud() (квадрат 62 % клітинки з «L»-тінню), але біла
-- пупочка + чорна тінь (лягає на будь-який градієнт) і без заокруглення; усе в CanvasGroup з GroupTransparency alpha
-- (≈ 0,86 — лише легкий «шум», кнопка не ідеально чиста). cell — приблизна клітинка: підганяється так, щоб у висоту h
-- влазило ціле число рядів; по ширині w сітка по центру, зайве обрізає CanvasGroup. Розмір групи — 100 % батька, тож
-- для чипів змінної ширини w — найбільша ширина. z — ZIndex у батька: над фоном-градієнтом, під блиском і текстом.
-- Active = false: кліки проходять у кнопку. Вертикальне згасання (UIGradient на групі): унизу studs видно на 100 %,
-- догори плавно до 0 % (поверх GroupTransparency); колір не змінює (білий).
local function studNoise(parent, w, h, cell, alpha, z)
	local rows = math.max(1, math.floor(h / cell + 0.5))
	local c = h / rows
	local cols = math.ceil(w / c - 0.001)
	local ox = (w - cols * c) / 2
	local s = c * 0.62
	local o = (c - s) / 2
	local d = math.max(1, s * 0.12)
	local g = new("CanvasGroup", { Name = "StudNoise", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		GroupTransparency = alpha or 0.86, Active = false, ClipsDescendants = true, ZIndex = z or 1 }, parent)
	for cx = 0, cols - 1 do
		for cy = 0, rows - 1 do
			local x, y = ox + cx * c, cy * c
			frame(g, x + o - d / 2, y + o + d / 2, s, s, BLACK, { ZIndex = 1 })
			frame(g, x + o + d / 2, y + o - d / 2, s, s, WHITE, { ZIndex = 2 })
		end
	end
	new("UIGradient", { Name = "Fade", Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, g)
	return g
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

-- ===== ефекти кнопок: темна «губа» знизу (3D) і відблиск, що час від часу пробігає по кнопці =====
-- колір губи — найтемніша (остання) зупинка градієнта кнопки, затемнена на 25 %
local function darken(c: Color3, k: number): Color3 return Color3.new(c.R * (1 - k), c.G * (1 - k), c.B * (1 - k)) end
local function lipColor(keys) return darken(C(keys[#keys][2]), 0.25) end
-- відблиск: дві похилі світлі лінії (широка й тонка) у UIGradient; у спокої зсунуті за лівий край (невидимі)
local SHINE_REST, SHINE_END = Vector2.new(-1.3, 0), Vector2.new(1.3, 0)
local SHINE_SEQ = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.40, 1), NumberSequenceKeypoint.new(0.44, 0.45),
	NumberSequenceKeypoint.new(0.49, 1), NumberSequenceKeypoint.new(0.53, 1), NumberSequenceKeypoint.new(0.555, 0.65), NumberSequenceKeypoint.new(0.58, 1),
	NumberSequenceKeypoint.new(1, 1) })
local SHINE_INFO = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local shineRng = Random.new()
local shiners = {} -- кнопки з відблиском (один спільний цикл нижче)

-- ===== кнопка (квадратна: тінь + тіло з градієнтом + studs-шум + губа + прямокутний блиск + відблиск + текст + UIScale) =====
-- opt: stroke, shadowDy, gloss = { h, alpha } (смужка зверху, відступ = stroke), noise (клітинка studs-шуму), textSize, textStroke,
--   text, keys, z (тінь — z, кнопка — z + 1), alwaysShine (відблиск завжди, навіть не лаймова — хрестик).
--   Усередині кнопки (знизу догори): шум ZIndex 1, губа 2, блиск 3, відблиск 4, текст / хрестик 5+
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local btn = new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x + w / 2, y + h / 2),
		Size = UDim2.fromOffset(w, h), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = opt.z + 1 }, parent)
	stroke(btn, INK, opt.stroke)
	studNoise(btn, w, h, opt.noise, 0.86, 1)
	-- губа: смуга висотою lipH уздовж нижнього краю всередині обводки
	local st = opt.stroke
	local lipH = math.max(5, math.floor(h * 0.09 + 0.5))
	local lip = frame(btn, st, h - st - lipH, w - 2 * st, lipH, lipColor(opt.keys), { Name = "Lip", Active = false, ZIndex = 2 })
	local g = opt.gloss
	gloss(btn, st, g[1], g[2], { ZIndex = 3 })
	-- відблиск: білий прямокутник на всю внутрішню частину, видимість задає UIGradient (Offset рухаємо твіном)
	local shine = new("Frame", { Name = "Shine", Position = UDim2.fromOffset(st, st), Size = UDim2.new(1, -2 * st, 1, -2 * st), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0, BorderSizePixel = 0, Active = false, ZIndex = 4 }, btn)
	local shineGrad = new("UIGradient", { Rotation = 25, Color = ColorSequence.new(WHITE), Transparency = SHINE_SEQ, Offset = SHINE_REST }, shine)
	local text = opt.textSize and label(btn, 0, 0, w, h, opt.textSize, opt.text or "", WHITE, opt.textStroke, { ZIndex = 5 }) or nil
	local b = { btn = btn, shadow = sh, grad = vgrad(btn, opt.keys), keys = opt.keys, text = text, scale = new("UIScale", {}, btn),
		basePos = btn.Position, enabled = true, hover = false, shaking = false, lastFire = 0, onClick = nil, action = nil,
		lip = lip, shineGrad = shineGrad, shineTw = TweenService:Create(shineGrad, SHINE_INFO, { Offset = SHINE_END }),
		alwaysShine = opt.alwaysShine == true, nextShine = os.clock() + shineRng:NextNumber(0.5, 3) }
	-- після проходу — одразу назад за лівий край
	b.shineTw.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then shineGrad.Offset = SHINE_REST end
	end)
	table.insert(shiners, b)
	btn.MouseEnter:Connect(function()
		b.hover = true
		if b.enabled then tween(b.scale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.04 }) end
	end)
	btn.MouseLeave:Connect(function()
		b.hover = false
		tween(b.scale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
	end)
	btn.Activated:Connect(function()
		if b.enabled then
			b.scale.Scale = 0.92
			tween(b.scale, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
			if b.onClick and os.clock() - b.lastFire > 0.2 then
				b.lastFire = os.clock()
				b.onClick(b)
			end
		elseif not b.shaking then
			-- тьмяна кнопка: хитається замість дії
			b.shaking = true
			task.spawn(function()
				for _, dx in { -10, 10, -7, 7, -3, 0 } do btn.Position = b.basePos + UDim2.fromOffset(dx, 0); task.wait(0.03) end
				btn.Position = b.basePos
				b.shaking = false
			end)
		end
	end)
	return b
end
local function setKeys(o, keys)
	if o.keys ~= keys then
		o.keys = keys; o.grad.Color = cseq(keys)
		if o.lip then o.lip.BackgroundColor3 = lipColor(keys) end -- губа кнопки йде за станом (лайм / тьмяна / сіра)
	end
end
-- кнопку видно на екрані: усі предки-GuiObject Visible, ScreenGui / SurfaceGui увімкнено, ненульовий розмір
local function onScreen(btn: GuiObject): boolean
	if btn.AbsoluteSize.X == 0 then return false end
	local o: Instance? = btn
	while o do
		if o:IsA("LayerCollector") then return o.Enabled end
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return false
end
-- спільний цикл відблисків: у кожної кнопки свій розклад (перший раз через 0,5–3 с, далі кожні 3,5–6 с);
-- пропускаємо невидимі й тьмяні / сірі кнопки (хрестик — завжди); знищені кнопки викидаємо з реєстру
task.spawn(function()
	while true do
		task.wait(0.2)
		local now = os.clock()
		for i = #shiners, 1, -1 do
			local b = shiners[i]
			if not b.btn.Parent then
				table.remove(shiners, i)
			elseif now >= b.nextShine then
				b.nextShine = now + shineRng:NextNumber(3.5, 6)
				if (b.alwaysShine or b.keys == BTN_LIME) and onScreen(b.btn) then
					b.shineTw:Cancel()
					b.shineGrad.Offset = SHINE_REST
					b.shineTw:Play()
				end
			end
		end
	end
end)
-- текст, дія й стан кнопки дії (лаймова / тьмяна)
local function setButton(b, text: string, action: string?, enabled: boolean)
	if b.text and b.text.Text ~= text then b.text.Text = text end
	b.action = action
	if b.enabled ~= enabled then
		b.enabled = enabled
		setKeys(b, enabled and BTN_LIME or BTN_DIM)
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

-- ===== чип стану (квадратний; ширина = текст + 44) =====
-- усередині body: studs-шум ZIndex 1 (сітка на найширший чип CHIP_MAX_W, зайве обрізається), блиск 2, текст 3
local CHIP_MAX_W = 480
local function makeChip(parent)
	local c = frame(parent, CX0, ROW1_Y, 100, ROW1_H, nil, { BackgroundTransparency = 1, ZIndex = 6, Visible = false })
	new("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.7,
		BorderSizePixel = 0, ZIndex = 1 }, c)
	local body = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2 }, c)
	stroke(body, INK, 4)
	studNoise(body, CHIP_MAX_W, ROW1_H, 24, 0.86, 1)
	gloss(body, 4, math.floor(ROW1_H * 0.38 + 0.5), 0.3, { ZIndex = 2 })
	local text = label(body, 0, 0, 0, 0, 26, "", WHITE, 3, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })
	return { frame = c, grad = vgrad(body, THEME.blue), keys = THEME.blue, text = text }
end

-- ===== плитка 80 × 80 з іконкою (квадратна; шум ZIndex 1, блиск 2, іконка 3, галочка 4) =====
local function makeTile(parent, x, y, oreKey, iconId)
	local t = frame(parent, x, y, 80, 80, WHITE, { ZIndex = 1 })
	vgrad(t, TILE[oreKey] or TILE.Coal); stroke(t, INK, 3)
	studNoise(t, 80, 80, 22, 0.86, 1)
	gloss(t, 3, 30, 0.25, { ZIndex = 2 })
	new("ImageLabel", { Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, Image = iconId or "",
		ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, t)
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
frame(pop, WIN_X, WIN_Y + 14, WIN_W, WIN_H, BLACK, { Name = "WindowShadow", BackgroundTransparency = 0.65, ZIndex = 1 })
local window = frame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, WHITE, { Name = "Window", ZIndex = 2 })
vgrad(window, RIM); stroke(window, INK, 5)
local rimLine = frame(window, 6, 6, WIN_W - 12, WIN_H - 12, nil, { Name = "RimLine", BackgroundTransparency = 1, ZIndex = 1 })
stroke(rimLine, C("6a7078"), 1.5, 0.1)
local PAN_W, PAN_H = WIN_W - 36, WIN_H - 36 -- 1004 × 614
local panel = frame(window, 18, 18, PAN_W, PAN_H, C("a9aeb5"), { Name = "Panel", ZIndex = 2, ClipsDescendants = true })
stroke(panel, INK, 4)
-- studs панелі: клітинка 40, сітка 25 × 15 по центру (перша клітинка з (2, 7)); будуються один раз
local studsFrame = frame(panel, 0, 0, PAN_W, PAN_H, nil, { Name = "Studs", BackgroundTransparency = 1, ZIndex = 1 })
do
	local CELL = 40
	local nx, ny = math.floor(PAN_W / CELL), math.floor(PAN_H / CELL)
	local ox, oy = (PAN_W - nx * CELL) / 2, (PAN_H - ny * CELL) / 2
	for cx = 0, nx - 1 do
		for cy = 0, ny - 1 do
			stud(studsFrame, ox + cx * CELL, oy + cy * CELL, CELL, C("b3b8bf"), C("868b92"), C("c8ccd1"), 1)
		end
	end
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
local row2Label = textAt(content, CX0, 153, 150, 28, "Ore given", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1 })
local row2Bar = makeBar(content, 212, 128, 618, 50, 28, 1)
local testBtn = makeButton(content, 848, 133, 150, 40, { stroke = 3, shadowDy = 5, gloss = { 15, 0.3 }, noise = 20,
	textSize = 20, textStroke = 2.5, text = "TEST +10", keys = BTN_GRAY, z = 2 })
testBtn.onClick = function() Action:FireServer("TestOre") end
local isDev = RunService:IsStudio()
testBtn.btn.Visible = isDev
testBtn.shadow.Visible = isDev

-- рядки руди (Coal, Copper, Iron)
local rows = {}
for i = 1, math.min(3, #ORE) do
	local o = ORE[i]
	local y = ROWS_Y + (i - 1) * (ROW_H + ROW_GAP)
	local row = frame(content, CX0, y, CW, ROW_H, WHITE, { Name = "OreRow_" .. o.key, ZIndex = 1 })
	stroke(row, INK, 3)
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.4) }) }, row)
	-- «Працює»: фон рядка заповнюється зеленим, поки голем переплавляє саме цю руду (SmeltStart … SmeltStart + SmeltDur)
	local prog = frame(row, 0, 0, 0, ROW_H, WHITE, { Name = "Progress", ZIndex = 0, Visible = false, BackgroundTransparency = 0.35 })
	vgrad(prog, { { 0, "b6f07a" }, { 0.55, "6cc934" }, { 1, "3f9d18" } })
	local tile = makeTile(row, 8, 8, o.key, ICONS["ore_" .. o.key])
	local check = makeCheck(tile)
	textAt(row, 106, 32, 320, 38, o.key, WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
	local sub = textAt(row, 106, 70, 600, 22, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 2 })
	-- «Спить»: шкала віддано / треба
	local bar = makeBar(row, 440, 22, CW - 440 - 16, 52, 30, 2)
	-- «Працює»: кількість злитків + плитка злитка
	local barsText = textAt(row, 852 - 420, 48, 420, 44, "", LIME_TXT, 4, { TextXAlignment = Enum.TextXAlignment.Right, RichText = true, ZIndex = 2 })
	local ingot = makeTile(row, CW - 8 - 80, 8, o.key, ICONS["bar_" .. o.key])
	rows[i] = { ore = o, sub = sub, bar = bar, check = check, barsText = barsText, ingot = ingot, prog = prog }
end

-- затемнення «Прокидається / Засинає» (накриває рядок 2 і рядки руди; ловить кліки)
local overlay = frame(content, 34, 120, 972, 388, C("0d0f12"), { Name = "Overlay", BackgroundTransparency = 0.28, Active = true, Visible = false, ZIndex = 5 })
local overWord = textAt(overlay, 0, 160, 900, 72, "", C("ffd34d"), 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
local overDots = textAt(overlay, 0, 160, 140, 72, "", C("ffd34d"), 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
local overBar = makeBar(overlay, 280 - 34, 342 - 120, 480, 36, nil, 1)
local over = { word = nil, keys = FILL.amber, t0 = nil, dur = 4.2 }

-- кнопки дії
local btnLeft = makeButton(content, 104, 520, 400, 82, { stroke = 5, shadowDy = 8, gloss = { 31, 0.3 }, noise = 28,
	textSize = 40, textStroke = 4, text = "", keys = BTN_LIME, z = 6 })
local btnRight = makeButton(content, 536, 520, 400, 82, { stroke = 5, shadowDy = 8, gloss = { 31, 0.3 }, noise = 28,
	textSize = 40, textStroke = 4, text = "", keys = BTN_LIME, z = 6 })
local function fireAction(b) if b.action then Action:FireServer(b.action) end end
btnLeft.onClick = fireAction
btnRight.onClick = fireAction

-- заголовок «Forge» поза вікном: тінь-копія +7 і градієнтний текст (лівий край x 72, центр великих літер y 52)
textAt(pop, 72, 52 + 7, 420, 112, "Forge", INK, 10, { Name = "TitleShadow", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, 72, 52, 420, 112, "Forge", WHITE, 9, { Name = "Title", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
vgrad(title, TITLE_G)

-- червона квадратна кнопка X над заголовком (тінь 5, кнопка 6; хрестик з двох повернутих прямокутних смужок,
-- два шари: з контуром і без; ZIndex 5–6 — над studs-шумом, губою, блиском і відблиском; відблиск — завжди)
local closeBtn = makeButton(pop, 1024, 24, 92, 92, { stroke = 5, shadowDy = 8, gloss = { 35, 0.3 }, noise = 23, keys = THEME.red, z = 5,
	alwaysShine = true })
closeBtn.btn.Name = "Close"
for layer = 1, 2 do
	for _, rot in { 45, -45 } do
		local s = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(46, 46), Size = UDim2.fromOffset(60, 18), Rotation = rot,
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = layer + 4 }, closeBtn.btn)
		if layer == 1 then stroke(s, INK, 5) end
	end
end

-- =====================================================================
-- ===== масштаб під екран =====
-- =====================================================================
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	-- верхня смуга Roblox (кнопки меню й чату): вікно ставимо нижче неї, щоб не перекривати ці кнопки на телефоні
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	vh -= top
	modalRoot.Position = UDim2.new(0.5, 0, 0.5, top / 2)
	local phone = vh < 500 or (UIS.TouchEnabled and not UIS.MouseEnabled)
	local mx, my = phone and 24 or 48, phone and 12 or 32
	local s = math.min((vw - mx) / CANVAS_W, (vh - my) / CANVAS_H)
	-- саме вікно (без заголовка й полів) не більше 92 % ширини / висоти вільної частини екрана
	s = math.min(s, 0.92 * vw / WIN_W, 0.92 * vh / WIN_H)
	-- на великих екранах не більше за дизайн-розмір (інакше вікно затуляє майже весь екран)
	fitScale.Scale = math.clamp(s, 0.1, 1)
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
-- ===== дані =====
-- =====================================================================
local function num(v, default) return tonumber(v) or default end
local function inv(key: string): number return num(player:GetAttribute(key), 0) end

-- чипи зліва направо (проміжок 14); повертає праву межу останнього
local function setChips(list)
	local x = CX0
	for i, chip in chips do
		local spec = list[i]
		chip.frame.Visible = spec ~= nil
		if spec then
			local w = math.floor(textWidth(spec[1], 26, HEAVY) + 44 + 0.5)
			chip.text.Text = spec[1]
			if chip.keys ~= spec[2] then chip.keys = spec[2]; chip.grad.Color = cseq(spec[2]) end
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
		local x0 = 520 - 34 - (ww + dw) / 2
		overWord.Text = word
		overWord.Position = UDim2.fromOffset(x0, 160 - 43.2)
		overWord.Size = UDim2.fromOffset(ww + 8, 86.4)
		overDots.Position = UDim2.fromOffset(x0 + ww, 160 - 43.2)
	end
end

-- оновити все вікно за станом кузні f; instant — без анімації шкал (одразу після відкриття)
local function refresh(f: Model, instant: boolean)
	local st = f:GetAttribute("State")
	if st ~= "Waking" and st ~= "Working" and st ~= "Dozing" then st = "Asleep" end

	if st == "Asleep" or st == "Waking" then
		-- ===== голем спить / прокидається: віддаємо руду для пробудження =====
		local right = setChips({ st == "Waking" and { "WAKING UP", THEME.amber } or { "ASLEEP", THEME.blue } })
		setMessage(st == "Waking" and MSG_WAKING or MSG_ASLEEP, 26, right)
		local given, need, canGive, allFull = 0, 0, false, true
		for i, r in rows do
			local key = r.ore.key
			local req = num(Cfg.WAKE_REQ[i], 0)
			local g = num(f:GetAttribute("Wake_" .. key), 0)
			local have = inv("Ore_" .. key)
			local full = g >= req
			given += math.min(g, req); need += req
			if not full then allFull = false end
			if have > 0 and not full then canGive = true end
			r.sub.Text = "You have " .. NF.full(have)
			r.bar.track.Visible = true
			setBar(r.bar, req > 0 and g / req or 1, full and FILL.lime or FILL.cyan, NF.full(g) .. " / " .. NF.full(req), instant)
			r.check.Visible = full
			r.barsText.Visible = false
			r.ingot.Visible = false
		end
		row2Label.Text = "Ore given"
		setBar(row2Bar, need > 0 and given / need or 0, given >= need and FILL.lime or FILL.cyan, NF.full(given) .. " / " .. NF.full(need), instant)
		setButton(btnLeft, "Give Ore", "Give", st == "Asleep" and canGive)
		setButton(btnRight, "Wake Up", "Wake", st == "Asleep" and allFull)
		setOverlay(st == "Waking" and "WAKING UP" or nil, FILL.amber, f)
	else
		-- ===== голем працює / засинає: піддон руди і злитки =====
		local right
		if st == "Working" then
			local spd = Cfg.spdOf(num(f:GetAttribute("SpdLvl"), 1))
			right = setChips({ { "WORKING", THEME.green }, { "1 ore every " .. fmtNum(spd) .. "s", THEME.blue },
				{ "Bar = ×" .. fmtNum(Cfg.BAR_MULT) .. " ore price", THEME.orange } })
			setMessage(nil, 26, right)
		else
			right = setChips({ { "FALLING ASLEEP", THEME.purple } })
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
			if have > 0 and r.ore.price <= room then canPut = true end
			r.sub.Text = "You have " .. NF.full(have) .. " · On pallet " .. NF.full(pal)
			r.bar.track.Visible = false
			r.check.Visible = false
			r.barsText.Visible = true
			r.barsText.Text = '<font weight="800" size="22" color="#e9edf1">bars</font>  ×' .. NF.full(bars)
			r.barsText.TextColor3 = bars > 0 and LIME_TXT or GRAY_TXT
			r.ingot.Visible = true
		end
		row2Label.Text = "Ore pallet"
		setBar(row2Bar, cap > 0 and value / cap or 0, FILL.orange, NF.money(value) .. " / " .. NF.money(cap), instant)
		setButton(btnLeft, "Put Ore", "Put", st == "Working" and canPut)
		setButton(btnRight, "Take Bars (" .. NF.full(totalBars) .. ")", "Take", st == "Working" and totalBars > 0)
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
	local want = f ~= nil and inside and not dismissed
	if want and f then
		if not isOpen then
			refresh(f, true)
			open()
		else
			refresh(f, false)
		end
	elseif isOpen then
		close()
	end
end

-- перші заміри ширини тексту заздалегідь (щоб перше відкриття не чекало)
task.spawn(function()
	for _, s in { "ASLEEP", "WAKING UP", "WORKING", "FALLING ASLEEP" } do textWidth(s, 26, HEAVY) end
	for _, s in { "WAKING UP", "FALLING ASLEEP", "..." } do textWidth(s, 72, HEAVY) end
end)

while true do
	local ok, err = pcall(step)
	if not ok then warn("ForgeWindow: " .. tostring(err)) end
	task.wait(REFRESH)
end
