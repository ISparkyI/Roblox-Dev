-- WorkshopClient — клієнт Workshop (майстерня, заміна Forge; чернетка 28.10.2026): анімація 6-рукого голема-майстра «Брасс»,
--   печі, міха, заготовки на ковадлі, топки в грудях і диму з димаря, екран покращень. Основа — ForgeClient.
-- Де: StarterPlayer/StarterPlayerScripts/WorkshopClient (LocalScript). Моделі: Niche*/Forge (майстерня в префабі, 28.10.2026; ForgeClient вимкнено) і тестова Workspace/WorkshopDraft/Workshop.
-- Анімація 6 рук: верхні — як у коваля (молот, ліва тримає заготовку); середні — по шляхах WorkshopRig.MPATH (без перетинів):
--   права бере руду внизу й підкидає до печі на замаху, ліва після удару підхоплює злиток; у спокої — розкладені вбік;
--   нижні — огранювання: різець постукує, кристал повертається. Сон: усі руки складені, нижні на колінах, топка ледь тліє.
--   Пробудження: встає, бере молот, потім розкладає середні руки й бере різець і кристал. Засинання — у зворотному порядку.
-- Стан бере з атрибутів моделі Niche*/Forge (їх ставить ForgeService). Деталі голема анкеровані,
-- тут їм щокадру ставиться CFrame (тільки на клієнті).
-- Сцена збільшена в Rig.S разів: усі числа нижче у «веб-одиницях» множаться на S.
--
-- Цикл переплавки (на кожен SmeltSeq із сервера):
--   руда летить з піддону Ore у піч → за ~0.9 с гаряча заготовка вилітає з устя на ковадло →
--   голем б'є (іскри, заготовка сплющується) → заготовка, остигаючи, летить на піддон Bars.
-- Якщо руди в черзі немає — голем стоїть біля ковадла й роззирається.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local Rig = require(RS.Shared:WaitForChild("WorkshopRig")) -- 6 рук (WorkshopRig: ForgeRig + середні й нижні руки з ліктями)
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local CardHover = require(RS.Shared:WaitForChild("CardHover")) -- наведення: ×1.05 і нахил до 3° у бік мишки
local UISfx = require(RS.Shared:WaitForChild("UISfx")) -- звук покупки
local Action = RS:WaitForChild("Remotes"):WaitForChild("ForgeAction")
local player = Players.LocalPlayer
local SC, S = Rig.SC, Rig.S
local D = math.rad
local ORE = Cfg.ORES
local V = Vector3.new

local function lerp(a, b, t) return a + (b - a) * t end
local function smooth(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
local HOT, COLD = Color3.fromHex("ff6a2a"), Color3.fromHex("3a1a0c")
local INGOT_HOT = Color3.fromHex("ff8a3d")
local INGOT = V(0.95, 0.28, 0.5) * S          -- заготовка на ковадлі
local INGOT_FLAT = V(1.08, 0.2, 0.56) * S      -- після удару
local QUEUE_MAX = 3
-- темп анімації: повний цикл удару (Rig.CYCLE ≈ 1.9 с) не довший за інтервал сервера spdOf(SpdLvl).
-- Якщо інтервал коротший — усе в циклі (замах, удар, політ руди й заготовки) прискорюється в k разів (з запасом 5 %),
-- інакше черга ударів росла й голем відставав від реальної швидкості (зайві удари викидалися).
local function tempoOf(f: Model): number
	local dur = Cfg.spdOf(f:GetAttribute("SpdLvl") or 1)
	return math.max(1, Rig.CYCLE * 1.05 / dur)
end
-- меші руди й злитка (ReplicatedStorage/Prefabs/ForgeProps): ті самі, що лежать на піддонах
local PROPS = RS:FindFirstChild("Prefabs") and RS.Prefabs:FindFirstChild("ForgeProps")
local ORE_MESH = { "OreA", "OreB", "OreC" }

-- удар: кут руки, за якого низ молота торкається верху заготовки (+0.05), щоб молот не входив у неї
local function calibrate(origin: CFrame, ingotTop: number)
	local best = Rig.STRIKE_ARM
	for a = Rig.STRIKE_ARM, Rig.STRIKE_ARM + 25, 0.25 do
		local p = table.clone(Rig.POSE.work)
		p.armR, p.wrist, p.lean = a, -a, 6
		local J = Rig.solve(Rig.rootCF(origin, p), p)
		local face = J.wrist * (Rig.STRIKE_FACE * SC)
		best = a
		if face.Y >= ingotTop + 0.05 then break end
	end
	local ph = {}
	for i, q in Rig.PH do ph[i] = table.clone(q); ph[i].a = table.clone(q.a); ph[i].w = table.clone(q.w) end
	ph[3].a[2], ph[3].w[2] = best, -best
	ph[4].a[1], ph[4].w[1] = best, -best
	ph[4].a[2] = best + 8; ph[5].a[1] = best + 8
	return ph
end
local function strikeAt(ph, t: number)
	for i, p in ph do
		if t <= p.t1 then
			local u = p.e(math.clamp((t - p.t0) / (p.t1 - p.t0), 0, 1))
			return i, p.a[1] + (p.a[2] - p.a[1]) * u, p.w[1] + (p.w[2] - p.w[1]) * u, p.l[1] + (p.l[2] - p.l[1]) * u
		end
	end
	return 0, 78, -40, 2
end

-- ===== екран покращень на табло (стиль Roll Upgrades) =====
-- SurfaceGui у PlayerGui з Adornee на UpgradePanel/screen (так працює клік мишкою), полотно 1600 × 1000 (екран 20 × 12,5 стада).
-- Три вертикальні картки на сірій 2D-підкладці зі studs на весь екран (темної рамки більше немає): Capacity (помаранчева,
-- ящик руди), Speed (синя, молот) і Ore per Hit (фіолетова, ковадло з рудою). Влазить дві з половиною — ряд карток
-- прокручується коліщатком миші (коли мишка над таблом, зум камери вимикається), повзунком унизу, стрілками або
-- перетягуванням самих карток. Іконки — у стилі HUD (пака), без бейджів.
-- Стиль: усе квадратне (без UICorner, обводки рамок Miter), блиск картки — прямокутна смужка зверху. Кнопки купівлі —
-- «стиль A» з картинок (модуль Shared/StyleA). Заокруглення лишилися тільки на самих пупочках studs.
-- Іконки — PNG 512 px з прозорим фоном, відрендерені з веб-макета й завантажені через Asset Manager.
-- Своя кузня: кнопки працюють. Чужа / вільна: видно рівні й ціни, кнопки неактивні.
-- Екран будується, коли камера ближче 140 стадів, і прибирається далі 200 (щоб не тримати тисячі рамок для всіх кузень).
local playerGui = player:WaitForChild("PlayerGui")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local PH = 1000 -- ширина полотна рахується з пропорцій екрана (20 × 12,5 → 1600 × 1000)
local CW, CH, GAP = 500, 790, 90
-- Краї екрана закриває 3D-рамка табла (цегляні стовпи й балки ≈ 120–130 px полотна), тому все стоїть у «безпечній зоні»:
-- картки зменшені до CARD_K, зверху відступ CARD_TOP, з боків SIDE (перша й остання картки не впритик до стовпів),
-- повзунок — над нижньою балкою. У проміжних положеннях прокрутки картки заходять «за» стовпи.
local CARD_K, SIDE, CARD_TOP = 0.85, 150, 130
local VP_Y, VP_H = 0, 850                                -- вікно карток (над повзунком)
local TRACK_W, TRACK_H, TRACK_Y = 860, 40, 866          -- повзунок унизу (по центру)
local ARROW = 56
-- Auto (29.10.2026): Auto Workshop — з мапи 3 за Money (ForgeConfig.AUTO_*) або геймпас; куплено — кнопка ON / OFF
local CARD_ORDER = { { "Cap", "Capacity", 72 }, { "Spd", "Speed", 72 }, { "Oph", "Ore per Hit", 60 }, { "Auto", "Auto Workshop", 54 } }
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")

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
-- UICorner — тільки для пупочок studs; картки, кнопки, рамки — квадратні
local function corner(o, r) new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
-- обводка рамки — Miter (гострі кути); обводка тексту (contextual) — Round
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
-- пупочка studs з «L»-тінню (як у Money HUD і на таблі Roll Upgrades)
local function stud(parent, x, y, cell, fill, shade, edge)
	local s = math.floor(cell * 0.62)
	local o = (cell - s) / 2
	local d = math.max(2, math.floor(s * 0.12 + 0.5))
	local r = math.max(3, math.floor(s * 0.16))
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill); corner(st, r)
	if edge then stroke(st, edge, 2) end
end
-- темніший колір (для нижньої смуги картки)
local function darken(c, k) return Color3.new(c.R * (1 - k), c.G * (1 - k), c.B * (1 - k)) end
-- косі світлі смуги на картці (як у «Store»): біла рамка Bands на всю картку, UIGradient під кутом 65°
-- дає три статичні смуги (широка, тонка, широка) з білим ≈ 10–18 %. Кліки не перехоплює (Active = false).
local function bands(parent, w, h)
	local f = frame(parent, 0, 0, w, h, WHITE, { Name = "Bands", Active = false })
	local K = NumberSequenceKeypoint.new
	new("UIGradient", { Rotation = 65, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new({ K(0, 1), K(0.16, 1), K(0.17, 0.82),
		K(0.31, 0.82), K(0.32, 1), K(0.47, 1), K(0.48, 0.9), K(0.53, 0.9), K(0.54, 1), K(0.70, 1), K(0.71, 0.85), K(0.83, 0.85), K(0.84, 1), K(1, 1) }) }, f)
	return f
end
-- іконки v2 у стилі HUD (контур #040435, видавлена грань, гострі блики), без бейджів; 512 px, завантажені як Decal (ID картинки нижче)
local ICONS = {
	Cap = "rbxassetid://91341404610533",  -- forge_capacity (ящик, з якого виглядає руда)
	Spd = "rbxassetid://109722376919744", -- forge_speed (молот і штрихи руху)
	Oph = "rbxassetid://98215380451624",  -- forge_ore_per_hit (ковадло, три шматки руди, спалах удару)
	Auto = "rbxassetid://102635405420682", -- Auto Workshop (ковадло з зірочками, тимчасово — іконка заголовка WORKSHOP)
}
local THEMES = {
	Cap = { grad = { { 0, "ffb15c" }, { 0.55, "f07a1e" }, { 1, "b8500c" } }, rim = "ffd2a3", stud = "ffc890", studShade = "b3520f" },
	Spd = { grad = { { 0, "6fc6ff" }, { 0.55, "2f8ee6" }, { 1, "1a5cb0" } }, rim = "bfe6ff", stud = "8fd2ff", studShade = "1b62b8" },
	Oph = { grad = { { 0, "d59bff" }, { 0.55, "9a4cf0" }, { 1, "5f22b4" } }, rim = "ecd4ff", stud = "dcb4ff", studShade = "5c1fa8" },
	Auto = { grad = { { 0, "6ff0d8" }, { 0.55, "1fb89c" }, { 1, "0d7a66" } }, rim = "c8fff2", stud = "8ff5e0", studShade = "0f8a72" },
}
-- квадратна картка: квадратні тінь, обідок, косі світлі смуги Bands, темна суцільна смуга BottomStrip знизу, прямокутний
-- блиск зверху; кнопка купівлі — «стиль A» (StyleA)
local function card(parent, x, y, key, title, titleSize)
	local th = THEMES[key]
	-- тримач (CanvasGroup) — щоб картку разом з тінню можна було збільшувати й нахиляти при наведенні
	local holder, o = CardHover.holder(parent, x, y, CW, CH, 14)
	frame(holder, o.X, o.Y + 14, CW, CH, Color3.new(0, 0, 0), { BackgroundTransparency = 0.65 })
	local c = frame(holder, o.X, o.Y, CW, CH, WHITE); vgrad(c, th.grad); stroke(c, INK, 6)
	-- studs на картці (ледь помітні)
	-- шар studs — звичайний Frame (CanvasGroup у таблах на слабкій графіці не малювався); прозорість 0.68 — кожній пупочці
	local sg = new("Frame", { Name = "Studs", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(CW - 20, CH - 20), BackgroundTransparency = 1, ClipsDescendants = true }, c)
	task.defer(function() for _, d in sg:GetChildren() do if d:IsA("GuiObject") then d.BackgroundTransparency = 0.68 end end end)
	local cell = 46
	for cx = 0, math.ceil((CW - 20) / cell) - 1 do
		for cy = 0, math.ceil((CH - 20) / cell) - 1 do
			local s = cell * 0.6; local o = (cell - s) / 2
			local a = frame(sg, cx * cell + o - 2, cy * cell + o + 2, s, s, C(th.studShade)); corner(a, 5)
			local b = frame(sg, cx * cell + o, cy * cell + o, s, s, C(th.stud)); corner(b, 5)
		end
	end
	-- косі світлі смуги: над шаром studs, під блиском / іконкою / текстом
	bands(c, CW, CH)
	-- блиск: прямокутна смужка на всю ширину всередині обідка (12 від краю), зверху, біла з вертикальним градієнтом прозорості
	local gloss = frame(c, 12, 12, CW - 24, math.floor(CH * 0.36), WHITE)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 12, 12, CW - 24, CH - 24, nil, { BackgroundTransparency = 1 }); stroke(rim, C(th.rim), 6, 0.25)
	-- нижня суцільна смуга (замість старої напівпрозорої): найтемніший колір теми, затемнений на 30 %; ZIndex 2 — над обідком
	local stripH = math.max(10, math.floor(CH * 0.03))
	frame(c, 0, CH - stripH, CW, stripH, darken(C(th.grad[#th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(CW / 2, 240), Size = UDim2.fromOffset(340, 340),
		BackgroundTransparency = 1, Image = ICONS[key], ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, c)
	label(c, 0, 432, CW, 90, titleSize or 72, title, WHITE, 7)
	local value = label(c, 0, 530, CW, 70, 50, "", WHITE, 6, { RichText = true })
	-- кнопка купівлі — «стиль A» (Shared/StyleA): green — грошей вистачає, gray — не вистачає або MAX; напис — ціна / MAX.
	-- Квадратна тінь під нею лишилася.
	local bx, by, bw, bh = 70, 640, CW - 140, 100
	local saShadow = frame(c, bx, by + 8, bw, bh, Color3.new(0, 0, 0), { BackgroundTransparency = 0.7 })
	local sa = StyleA.new(c, { size = Vector2.new(bw, bh), position = Vector2.new(bx, by), color = "green", text = "", textSize = 58,
		clickable = true, zIndex = 2 })
	StyleA.follow(sa, saShadow) -- тінь кнопки масштабується й хитається разом з нею
	return { value = value, btn = sa.button, sa = sa, holder = holder, card = c }
end

local function buildPanel(f: Model, screen: BasePart, ownerId: number)
	local mine = ownerId == player.UserId
	local PW = math.floor(PH * screen.Size.X / screen.Size.Y + 0.5)
	local g = new("SurfaceGui", { Name = "ForgeUpgrades_" .. (f.Parent and f.Parent.Name or "?"), Adornee = screen,
		Face = Enum.NormalId[screen:GetAttribute("ScreenFace") or "Front"], SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = 400 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("8e939a"), { ClipsDescendants = true, Active = true })
	-- сіра підкладка зі studs на весь екран (картки прокручуються, тому studs і під ними)
	local PC = 56
	for cx = 0, math.ceil(PW / PC) - 1 do
		for cy = 0, math.ceil(PH / PC) - 1 do
			stud(root, cx * PC, cy * PC, PC, C("979ca3"), C("6c7178"), C("aeb3b9"))
		end
	end
	local shade = frame(root, 0, 0, PW, PH, WHITE, { ZIndex = 2, Active = false })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.08, 1), NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 0.8) }) }, shade)
	local pb = frame(root, 0, 0, PW, PH, nil, { BackgroundTransparency = 1, ZIndex = 9, Active = false }); stroke(pb, INK, 5)
	-- вікно карток — ScrollingFrame лише по X: коліщатко миші й свайп на телефоні прокручують його самі, і тоді камера не зумиться
	-- (подія вже оброблена GUI). Повзунок, стрілки й перетягування мишкою ставлять CanvasPosition плавно.
	-- картки малюються в повному розмірі, а зменшує їх базовий масштаб тримача (CardHover base = CARD_K).
	-- UIScale на всьому ряду не підходить: CanvasGroup-тримачі тоді малюють «хвости» (повтор низу картки).
	local step0 = (CW + GAP) * CARD_K
	local rowW = math.ceil(SIDE * 2 + #CARD_ORDER * CW * CARD_K + (#CARD_ORDER - 1) * GAP * CARD_K)
	local vp = new("ScrollingFrame", { Position = UDim2.fromOffset(0, VP_Y), Size = UDim2.fromOffset(PW, VP_H), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.fromOffset(rowW, 0), ScrollBarThickness = 0, ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollingEnabled = true, ZIndex = 4 }, root)
	local row = frame(vp, 0, 0, rowW, VP_H, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local cards = {}
	for i, d in CARD_ORDER do
		-- центр картки після зменшення; card() приймає лівий верхній кут незменшеної картки
		local cx = SIDE + CW * CARD_K / 2 + (i - 1) * step0
		local cy = CARD_TOP + (CH + 14) * CARD_K / 2
		cards[d[1]] = card(row, cx - CW / 2, cy - (CH + 14) / 2, d[1], d[2], d[3])
	end
	-- тіні по лівому й правому краю — завжди (як на всіх таблах прокачки)
	-- по самому краю екрана і на всю його висоту
	local FADE_W = 150
	local function fade(x, rot)
		local f0 = frame(root, x, 0, FADE_W, PH, C("282c32"), { ZIndex = 5, Active = false })
		new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, f0)
		return f0
	end
	local fadeL, fadeR = fade(0, 0), fade(PW - FADE_W, 180)
	-- повзунок: темна доріжка + лаймовий повзунок «стиль A»; по боках — сірі кнопки-стрілки
	local trackX = (PW - TRACK_W) / 2
	local track = new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(trackX, TRACK_Y), Size = UDim2.fromOffset(TRACK_W, TRACK_H),
		BackgroundColor3 = C("14161a"), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 6 }, root)
	track:SetAttribute("NoHoverSound", true)
	stroke(track, INK, 5)
	local thumbW = math.max(140, TRACK_W * PW / rowW)
	local thumb = StyleA.new(track, { size = Vector2.new(thumbW, TRACK_H), position = Vector2.new(0, 0), anchor = Vector2.new(0, 0), color = "green", zIndex = 7 })
	local arrows = {}
	for i, dir in { -1, 1 } do
		local ax = dir < 0 and trackX - ARROW - 18 or trackX + TRACK_W + 18
		local a = StyleA.new(root, { size = Vector2.new(ARROW, ARROW), position = Vector2.new(ax, TRACK_Y + TRACK_H / 2 - ARROW / 2), anchor = Vector2.new(0, 0), color = "gray",
			clickable = true, shine = false, zIndex = 7 })
		-- шеврон — біла «‹ / ›» з темним контуром по центру грані (нижче — губа кнопки)
		label(a.root, 0, -7, ARROW, 50, 54, dir < 0 and "‹" or "›", WHITE, 5, { ZIndex = 9 })
		arrows[i] = { sa = a, dir = dir }
	end
	-- голем спить: весь екран під затемненням з написом
	local lock = frame(root, 0, 0, PW, PH, C("0d0f12"), { BackgroundTransparency = 0.28, ZIndex = 10 })
	label(lock, 0, PH / 2 - 108, PW, 96, 84, "WAKE THE GOLEM", C("ffd34d"), 8)
	label(lock, 0, PH / 2 - 12, PW, 96, 84, "FIRST", C("ffd34d"), 8)
	local pn = { gui = g, screen = screen, ownerId = ownerId, cards = cards, lock = lock, can = {},
		row = row, thumb = thumb, thumbW = thumbW, fadeL = fadeL, fadeR = fadeR, x = 0, tx = 0, maxX = math.max(0, rowW - PW) }
	local function clampT() pn.tx = math.clamp(pn.tx, 0, pn.maxX) end
	-- прокрутка: x — поточна CanvasPosition; tx — ціль для плавного доведення (стрілки, повзунок, перетягування).
	-- Коліщатко / свайп рухають CanvasPosition самі — тоді ціль підтягується до них.
	pn.anim = false
	local function layout()
		pn.x = vp.CanvasPosition.X
		local u = pn.maxX > 0 and pn.x / pn.maxX or 0
		thumb:setPosition(Vector2.new(u * (TRACK_W - thumbW), 0))
	end
	layout()
	vp:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not pn.anim then pn.tx = vp.CanvasPosition.X end
		layout()
	end)
	local step = RunService.RenderStepped:Connect(function(dt)
		if not pn.anim then return end
		local x = vp.CanvasPosition.X
		if math.abs(pn.tx - x) < 0.5 then
			vp.CanvasPosition = Vector2.new(pn.tx, 0)
			pn.anim = false
			return
		end
		vp.CanvasPosition = Vector2.new(x + (pn.tx - x) * (1 - math.exp(-14 * dt)), 0)
	end)
	g.Destroying:Connect(function() step:Disconnect() end)
	local function go() clampT(); pn.anim = true end
	for _, a in arrows do
		StyleA.bind(a.sa, { hoverAlways = true, canClick = function() return not lock.Visible end,
			onClick = function() pn.tx = pn.x + a.dir * step0; go() end })
	end
	-- поки голем спить — не прокручується
	lock:GetPropertyChangedSignal("Visible"):Connect(function() vp.ScrollingEnabled = not lock.Visible end)
	-- перетягування: повзунок (рух повзунка → ряд) або самі картки (рух мишки → ряд у зворотний бік).
	-- Координата на полотні — променем з камери на грань (CardHover.surfaceX), тому працює й поза межами полотна.
	local drag = nil
	-- точка в координатах вьюпорта: мишка — GetMouseLocation, дотик — позиція + верхній відступ GUI
	local function pointOf(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			local inset = game:GetService("GuiService"):GetGuiInset()
			return Vector2.new(input.Position.X, input.Position.Y) + inset
		end
		return nil
	end
	local function startDrag(kind, input)
		if lock.Visible or pn.maxX <= 0 then return end
		local sx = CardHover.surfaceX(g, pointOf(input)) or 0
		drag = { kind = kind, sx = sx, st = pn.tx, input = input, moved = false }
		if kind == "track" then -- клік по доріжці поза повзунком — стрибок туди
			local rel = sx - track.AbsolutePosition.X
			local tl = pn.x / math.max(1, pn.maxX) * (TRACK_W - thumbW)
			if rel < tl or rel > tl + thumbW then pn.tx = (rel - thumbW / 2) / (TRACK_W - thumbW) * pn.maxX; go() end
			drag.st = pn.tx
		else
			drag.st = pn.x
		end
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then startDrag("track", input) end
	end)
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then startDrag("cards", input) end
	end)
	local moveConn = UIS.InputChanged:Connect(function(input)
		if not drag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= drag.input then return end
		local sx = CardHover.surfaceX(g, pointOf(input))
		if not sx then return end
		local d = sx - drag.sx
		if drag.kind == "track" then
			pn.tx = drag.st + d * pn.maxX / math.max(1, TRACK_W - thumbW); go()
		elseif input.UserInputType == Enum.UserInputType.MouseMovement and (drag.moved or math.abs(d) > 14) then
			-- мишкою тягнемо ряд самі (дотик прокручує ScrollingFrame нативно)
			drag.moved = true
			pn.tx = drag.st - d; go()
		end
	end)
	local endConn = UIS.InputEnded:Connect(function(input)
		if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then drag = nil end
	end)
	g.Destroying:Connect(function() moveConn:Disconnect(); endConn:Disconnect() end)
	-- наведення на картки (поки голем спить і картки під затемненням — не реагують)
	for _, cd in cards do CardHover.attach(cd.holder, cd.card, function() return not lock.Visible end, CARD_K) end -- картки на 5 % менші
	if mine then
		for key, cd in cards do
			-- наведення 1,04 завжди; натискання 0,92 + Back і запит, якщо можна; інакше (грошей нема / MAX / не працює) — хитання
			-- tap = false: у покупки свій звук BuySound (без нашарування з tap)
			StyleA.bind(cd.sa, { hoverAlways = true, tap = false, canClick = function() return pn.can[key] == true end,
				onClick = function() UISfx.play("BuySound"); Action:FireServer("Upgrade", key) end })
		end
	else
		-- чужа або вільна кузня: кнопки лише для перегляду
		for _, cd in cards do
			cd.btn.Active = false
			cd.btn.Selectable = false
			pcall(function() cd.btn.Interactable = false end)
		end
	end
	return pn
end
-- ===== збір кузні =====
local recs = {}
local function setup(f: Model)
	if recs[f] or not f:FindFirstChild("ForgeOrigin") then return end
	local r = { f = f, origin = f.ForgeOrigin.CFrame, parts = {}, offs = {}, joints = {}, look = {}, lids = {}, eyes = {},
		hand = {}, rest = {}, fire = {}, coals = {}, belTop = {}, ct = 0, cycle = false, hit = false,
		eyeX = 0, eyeY = 0, blinkT = 2, blinkA = 0, heat = 0, cur = {}, seq = f:GetAttribute("SmeltSeq") or 0, flash = 0,
		queue = {}, job = nil }
	r.KF = r.origin * CFrame.new(6.4 * S, 0, -8.2 * S) * CFrame.Angles(0, D(-45), 0)
	-- (майстерня) голема можна зсунути атрибутом GolemShift (Vector3 у координатах ForgeOrigin); піч/вогонь лишаються на r.origin
	r.gorigin = r.origin * CFrame.new((f:GetAttribute("GolemShift") :: Vector3?) or Vector3.zero)
	for _, p in f.Golem:GetChildren() do
		if p:IsA("BasePart") then
			if p:GetAttribute("LidOff") then table.insert(r.lids, p)
			elseif p:GetAttribute("Off") and p:GetAttribute("Joint") then
				table.insert(r.parts, p); table.insert(r.offs, p:GetAttribute("Off")); table.insert(r.joints, p:GetAttribute("Joint"))
				r.look[#r.parts] = p:GetAttribute("Look") == true
				if p:GetAttribute("HandHammer") then table.insert(r.hand, p) end
				if string.match(p.Name, "^EyeShine") or string.match(p.Name, "^Pupil") then table.insert(r.eyes, p) end
			end
		end
	end
	for _, p in f.Anvil:GetChildren() do if p:GetAttribute("RestHammer") then table.insert(r.rest, p) end end
	r.face = f.Anvil:FindFirstChild("AnvilFace")
	r.ingotLight = r.face and r.face:FindFirstChild("IngotLight")
	r.sparks = r.face and r.face:FindFirstChild("SparkPoint") and r.face.SparkPoint:FindFirstChild("Sparks")
	-- звук удару (Snd_Hit на AnvilFace): стартує так, щоб пік удару в файлі (HitOffset) збігся з Rig.HIT
	r.hitSnd = r.face and r.face:FindFirstChild("Snd_Hit")
	if r.hitSnd and r.hitSnd.SoundId ~= "" then
		task.spawn(function() pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), { r.hitSnd }) end)
	end
	local k = f.Kiln
	for _, p in k:GetChildren() do
		if p.Name == "Fire" then table.insert(r.fire, p)
		elseif p.Name == "Coal" and p:GetAttribute("Hot") then table.insert(r.coals, p) end
	end
	-- міх — модель Kiln/Bellows (деталі: BellowsBase, BellowsTop, BellowsHandle, BellowsLeather, BelPivot ...). Якщо моделі немає (стара кузня), шукаємо в Kiln.
	local bm = k:FindFirstChild("Bellows") or k
	r.belPivot = bm:FindFirstChild("BelPivot"); r.leather = bm:FindFirstChild("BellowsLeather")
	-- звук міха (Bellows/BellowsNozzle/Snd_Puff): грає на початку кожного ходу вниз (стискання)
	local nz = bm:FindFirstChild("BellowsNozzle")
	r.puff = nz and nz:FindFirstChild("Snd_Puff")
	if r.puff and r.puff.SoundId ~= "" then
		task.spawn(function() pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), { r.puff }) end)
	end
	r.belBase = bm:FindFirstChild("BellowsBase"); r.belBoard = bm:FindFirstChild("BellowsTop")
	-- рухомі деталі (верхня дошка, ручка) тримають зсув від шарніра, взятий з поточного положення моделі —
	-- можна безпечно пересувати міх у світі, анімація не кривиться
	r.belOff = {}
	if r.belPivot then
		for _, p in bm:GetChildren() do
			if p:IsA("BasePart") and p:GetAttribute("BelTop") then
				table.insert(r.belTop, p); r.belOff[p] = r.belPivot.CFrame:ToObjectSpace(p.CFrame)
			end
		end
	end
	if r.leather then
		r.leatherXZ = r.leather.Size
		-- шкіра міха — трапеція (коробка + клин): верх нахиляється разом з верхньою дошкою, тож шкіра завжди торкається обох дощок
		local wd = Instance.new("WedgePart")
		wd.Name = "BellowsLeatherWedge"; wd.Anchored = true; wd.CanCollide = false; wd.CanQuery = false; wd.CanTouch = false
		wd.Material = r.leather.Material; wd.MaterialVariant = r.leather.MaterialVariant; wd.Color = r.leather.Color
		wd.Reflectance = r.leather.Reflectance; wd.CastShadow = r.leather.CastShadow
		wd.Size = V(r.leather.Size.X, 0.01, r.leather.Size.Z)
		wd.Parent = bm
		r.leatherWedge = wd
	end
	r.fireLight = k:FindFirstChild("FireLightPart") and k.FireLightPart:FindFirstChild("FireLight")
	r.mouth = k:FindFirstChild("Mouth"); r.embers = r.mouth and r.mouth:FindFirstChild("Embers")
	-- звук печі (Kiln/FireLightPart): Snd_Ignite — запалювання, Snd_FireLoop — зациклене горіння
	local fp = k:FindFirstChild("FireLightPart")
	r.fign = fp and fp:FindFirstChild("Snd_Ignite"); r.floop = fp and fp:FindFirstChild("Snd_FireLoop")
	r.fon, r.ftoken, r.fvol, r.floopActive = false, 0, 0, false
	r.floopBase = r.floop and r.floop.Volume or 0
	local fpre = {}
	for _, s in { r.fign, r.floop } do if s and s.SoundId ~= "" then table.insert(fpre, s) end end
	if #fpre > 0 then task.spawn(function() pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), fpre) end) end
	local head = f.Golem:FindFirstChild("Head"); r.zzz = head and head:FindFirstChild("Zzz")
	r.flyFrom = f.Pallets.PalletOre:FindFirstChild("FlyFrom"); r.flyTo = f.Pallets.PalletBars:FindFirstChild("FlyTo")
	r.ring = f.Ring:FindFirstChild("RingCenter")
	-- місце заготовки на ковадлі (+0.1 над гранню) і калібрування удару під її верх
	if r.face then
		local top = r.face.Position.Y + r.face.Size.Y / 2
		r.anvilCF = CFrame.new(r.face.Position.X, top + 0.1 + INGOT.Y / 2, r.face.Position.Z) * (r.face.CFrame - r.face.Position)
		r.ph = calibrate(r.gorigin, top + 0.1 + INGOT.Y)
	else
		r.ph = Rig.PH
	end
	-- заготовка (клієнтська деталь)
	local tpl = PROPS and PROPS:FindFirstChild("Ingot")
	local ing = tpl and tpl:Clone() or Instance.new("Part")
	ing.Name = "ForgeIngot"; ing.Anchored = true; ing.CanCollide = false; ing.CanQuery = false; ing.CanTouch = false
	ing.Size = INGOT; ing.Material = Enum.Material.Neon; ing.Color = INGOT_HOT; ing.Transparency = 1
	ing.TopSurface = Enum.SurfaceType.Smooth; ing.BottomSurface = Enum.SurfaceType.Smooth
	ing.Parent = workspace
	r.ingot = ing
	-- табло покращень будується в refreshPanels, коли камера поруч
	recs[f] = r
	r.golemCount = #f.Golem:GetChildren()
	-- топка в грудях і дим з димаря (голем-майстер)
	r.fbox = f.Golem:FindFirstChild("FireboxGlow")
	r.flight = r.fbox and r.fbox:FindFirstChild("FireLight")
	local cap = f.Golem:FindFirstChild("ChimneyCap")
	if cap and not cap:FindFirstChild("Smoke") then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "Smoke"; pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.EmissionDirection = Enum.NormalId.Right
		pe.Color = ColorSequence.new(Color3.fromHex("8a8f96"), Color3.fromHex("5a5f66")); pe.LightInfluence = 1
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 * S), NumberSequenceKeypoint.new(1, 2.2 * S) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(1.8, 2.6); pe.Speed = NumberRange.new(2.5, 4); pe.SpreadAngle = Vector2.new(12, 12)
		pe.Acceleration = Vector3.new(0.4, 1.2, 0); pe.Rate = 0.5; pe.RotSpeed = NumberRange.new(-30, 30); pe.Rotation = NumberRange.new(0, 360)
		pe.Parent = cap
	end
	r.smoke = cap and cap:FindFirstChild("Smoke")
	-- декор майстерні (Workshop/Decor): шестерні на гербі, точильне коло, іскри, пара з клапана, стрілки манометрів
	local decor = f:FindFirstChild("Decor")
	if decor then
		local spins = {}
		local function addSpin(m: Model, rate: number, grinder: boolean)
			local pv = m:GetPivot()
			local parts, offs = {}, {}
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then table.insert(parts, p); table.insert(offs, pv:ToObjectSpace(p.CFrame)) end
			end
			table.insert(spins, { pv = pv, parts = parts, offs = offs, rate = rate, grinder = grinder, ang = 0, ax = m:GetAttribute("SpinAxis") })
		end
		for _, m in decor:GetDescendants() do
			if m:IsA("Model") and m:GetAttribute("Spin") ~= nil then
				addSpin(m, m:GetAttribute("Spin") :: number, m.Name == "Wheel")
			end
		end
		r.spins = spins
		r.grind = 0
		r.gsparks = decor:FindFirstChild("Sparks", true)
		r.vent = decor:FindFirstChild("Steam", true)
		r.ventT = 3
		r.needles = {}
		for _, gm in decor:GetDescendants() do
			if gm:IsA("Model") and gm:GetAttribute("Gauge") then
				local body, nd = gm:FindFirstChild("Body"), gm:FindFirstChild("Needle")
				if body and nd then table.insert(r.needles, { p = nd, c = body.CFrame, off = body.CFrame:ToObjectSpace(nd.CFrame), ph = #r.needles * 1.7 }) end
			end
		end
	end
	-- огранювання: диск різака (SpinC), кристал у руці (CrystalPart), кристали середньої руки й верстата, іскри, летючий кристал
	r.spinDisc, r.cryParts = {}, {}
	for i, p in r.parts do
		local c = p:GetAttribute("SpinC")
		if c then r.spinDisc[i] = c end
		local kind = p:GetAttribute("CrystalPart")
		if kind then r.cryParts[i] = kind end
	end
	r.cutQ = {}; r.cutSeq = f:GetAttribute("CutSeq") or 0; r.discAng, r.discSpd, r.cryAng = 0, 0, 0
	r.grindCry = {}
	for _, p in f.Golem:GetChildren() do if string.match(p.Name, "^GrindCrystal") then table.insert(r.grindCry, p) end end
	r.benchCry, r.benchLights = {}, {}
	local bench = decor and decor:FindFirstChild("CrystalBench")
	if bench then
		for _, d in bench:GetDescendants() do
			if d:IsA("BasePart") and (d.Material == Enum.Material.Glass or (d.Material == Enum.Material.Neon and not d:FindFirstAncestor("Lamp")) or d.Name == "Rock") then table.insert(r.benchCry, d) end
			if d:IsA("PointLight") and d.Parent and d.Parent.Name == "Rock" then table.insert(r.benchLights, d) end
		end
	end
	local cb = f.Golem:FindFirstChild("CrystalBody_BL")
	if cb then
		local pe = cb:FindFirstChild("CutSparks") :: ParticleEmitter?
		if not pe then
			local e = Instance.new("ParticleEmitter")
			e.Name = "CutSparks"; e.Texture = "rbxasset://textures/particles/sparkles_main.dds"; e.Rate = 0; e.LightEmission = 1
			e.Size = NumberSequence.new(0.22, 0.04); e.Lifetime = NumberRange.new(0.2, 0.45); e.Speed = NumberRange.new(4, 8)
			e.SpreadAngle = Vector2.new(60, 60); e.Acceleration = Vector3.new(0, -25, 0)
			e.Parent = cb
			pe = e
		end
		r.cutSparks = pe
	end
	local fc = Instance.new("Part")
	fc.Name = "CrystalFlyer"; fc.Anchored = true; fc.CanCollide = false; fc.CanQuery = false; fc.CanTouch = false; fc.CastShadow = false
	fc.Material = Enum.Material.Glass; fc.Transparency = 1; fc.Size = Vector3.new(0.62, 1.0, 0.62)
	fc.Parent = workspace
	r.cryFly = fc
	r.cryOnShown = nil
	local function teardown()
		if recs[f] == r then recs[f] = nil end
		if r.cryFly then r.cryFly:Destroy() end
		ing:Destroy()
		if r.leatherWedge then r.leatherWedge:Destroy() end
		if r.panel then r.panel.gui:Destroy(); r.panel = nil end
	end
	r.teardown = teardown
	f.AncestryChanged:Connect(function()
		if not f:IsDescendantOf(workspace) then teardown() end
	end)
end

-- сервер на старті перебудовує Workspace/Niches, тому кузні шукаємо періодично.
-- Стрімінг: кузня (Atomic) може піти з клієнта й повернутися новими деталями. Якщо деталі голема,
-- які ми рухаємо, вже не в моделі (або їх стало інше число) — збираємо кузню заново, інакше голем
-- лишається в серверній позі сну, хоча кузня працює.
task.spawn(function()
	while true do
		for f, r in recs do
			local g = f:FindFirstChild("Golem")
			if not g or #g:GetChildren() ~= r.golemCount or (r.parts[1] and not r.parts[1]:IsDescendantOf(f)) then r.teardown() end
		end
		local niches = workspace:FindFirstChild("Niches")
		if niches then
			for _, n in niches:GetChildren() do
				local f = n:FindFirstChild("Workshop") or n:FindFirstChild("Forge") -- у префабі майстерня зветься Forge (для ForgeService / ForgeWindow)
				if f and not recs[f] and f:FindFirstChild("Ring") and f:FindFirstChild("Pallets") and f:FindFirstChild("Kiln") then
					local ok, err = pcall(setup, f) if not ok then warn("WorkshopClient: " .. tostring(err)) end
				end
			end
		end
		-- тестова чернетка майстерні (поки не замінили Forge у префабі)
		local draft = workspace:FindFirstChild("WorkshopDraft")
		local df = draft and draft:FindFirstChild("Workshop")
		if df and not recs[df] and df:FindFirstChild("Ring") and df:FindFirstChild("Pallets") and df:FindFirstChild("Kiln") then
			local ok, err = pcall(setup, df) if not ok then warn("WorkshopClient: " .. tostring(err)) end
		end
		task.wait(1)
	end
end)

-- ===== політ руди в піч (тільки візуал) =====
local flyers = {}
-- руда кузні — руда мапи її ніші (29.10.2026): тип t (1..3) → ключ руди
local curForge: Instance? = nil
local function oreAt(t: number): any
	local n = curForge and curForge.Parent
	return Cfg.oresFor(n and n:GetAttribute("Stage") or 1)[t] or ORE[t]
end
local CHUNK = setmetatable({}, { __index = function(_, t) local o = oreAt(t) return o and ("Chunk" .. o.key) or nil end })
local function fly(from: Vector3, to: Vector3, color: Color3, size: Vector3, dur: number, t: number?)
	local tpl = PROPS and t and PROPS:FindFirstChild(CHUNK[t] or "")
	local p
	if tpl then
		p = tpl:Clone() -- кольори граней зберігаються (UsePartColor = false), розмір не чіпаємо
	else
		p = PROPS and PROPS:FindFirstChild(ORE_MESH[math.random(1, #ORE_MESH)])
		p = p and p:Clone() or Instance.new("Part")
		p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic; p.MaterialVariant = ""
	end
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.CFrame = CFrame.new(from); p.Parent = workspace
	table.insert(flyers, { p = p, a = from, b = to, t = 0, dur = dur })
end

-- ===== заготовка: устя → ковадло → (удар) → піддон Bars =====
-- job = { t = тип руди, phase = "toClaw" | "inClaw" | "toss" | "toAnvil" | "onAnvil" | "toPallet", u = 0..1, flat = після удару }
-- (майстерня) заготовка вилітає з устя прямо в праву середню клешню (r.clawCF), клешня ловить її, замахується
-- і підкидає на ковадло (реліз на ct = TOSS_AT); до ковадла чи печі клешня не тягнеться — вони поза досяжністю.
local TOSS_AT = 0.58 -- момент циклу, коли клешня відпускає заготовку (удар — Rig.HIT = 0.92)
local function jobUpdate(r, dt, clock)
	local ing, job = r.ingot, r.job
	if not job or not r.anvilCF or not r.mouth then
		ing.Transparency = 1
		if r.ingotLight then r.ingotLight.Brightness = 0 end
		return
	end
	local bar = oreAt(job.t).bar
	ing.Transparency = 0
	local k = r.k or 1
	if job.phase == "toClaw" and not r.clawCF then job.phase = "toAnvil" end
	if job.phase == "toClaw" then
		job.u = math.min(1, job.u + dt * k / 0.35)
		local u = smooth(job.u)
		local a, b = r.mouth.Position, r.clawCF.Position
		ing.Size = INGOT; ing.Color = INGOT_HOT; ing.Material = Enum.Material.Neon
		ing.CFrame = CFrame.new(a:Lerp(b, u) + V(0, math.sin(u * math.pi) * 1.4 * S, 0)) * (r.clawCF - r.clawCF.Position):Lerp(CFrame.identity, 1 - u)
		if job.u >= 1 then job.phase = "inClaw" end
	elseif job.phase == "inClaw" then
		ing.Size = INGOT; ing.Color = INGOT_HOT; ing.Material = Enum.Material.Neon
		ing.CFrame = r.clawCF
		if not r.cycle or r.ct >= TOSS_AT then job.phase = "toss"; job.u = 0; job.from = r.clawCF end
	elseif job.phase == "toss" then
		job.u = math.min(1, job.u + dt * k / 0.28)
		local u = job.u
		local a, b = job.from.Position, r.anvilCF.Position
		ing.Size = INGOT; ing.Color = INGOT_HOT; ing.Material = Enum.Material.Neon
		ing.CFrame = CFrame.new(a:Lerp(b, u) + V(0, math.sin(u * math.pi) * 1.2 * S, 0)) * (job.from - job.from.Position):Lerp(r.anvilCF - r.anvilCF.Position, smooth(u))
		if job.u >= 1 then job.phase = "onAnvil" end
	elseif job.phase == "toAnvil" then
		job.u = math.min(1, job.u + dt * k / 0.5)
		local u = smooth(job.u)
		local a, b = r.mouth.Position, r.anvilCF.Position
		ing.Size = INGOT; ing.Color = INGOT_HOT; ing.Material = Enum.Material.Neon
		ing.CFrame = CFrame.new(a:Lerp(b, u) + V(0, math.sin(u * math.pi) * 1.6 * S, 0)) * (r.anvilCF - r.anvilCF.Position) * CFrame.Angles(0, (1 - u) * 2.5, 0)
		if job.u >= 1 then job.phase = "onAnvil" end
	elseif job.phase == "onAnvil" then
		ing.Size = job.flat and INGOT_FLAT or INGOT
		ing.CFrame = r.anvilCF * CFrame.new(0, (ing.Size.Y - INGOT.Y) / 2, 0)
		ing.Color = INGOT_HOT; ing.Material = Enum.Material.Neon
	elseif job.phase == "toPallet" then
		job.u = math.min(1, job.u + dt * k / 0.6)
		local u = smooth(job.u)
		local a, b = r.anvilCF.Position, r.flyTo and r.flyTo.Position or r.anvilCF.Position
		ing.Size = INGOT_FLAT
		ing.Color = INGOT_HOT:Lerp(bar, u)
		ing.Material = u > 0.6 and Enum.Material.SmoothPlastic or Enum.Material.Neon
		ing.CFrame = CFrame.new(a:Lerp(b, u) + V(0, math.sin(u * math.pi) * 2.2 * S, 0)) * CFrame.Angles(clock * 5, 0, clock * 3)
		if job.u >= 1 then r.job = nil; ing.Transparency = 1 end
	end
	if r.ingotLight then
		local glow = job.phase == "toPallet" and (1 - job.u) or 1
		r.ingotLight.Brightness = glow * (0.7 + r.flash * 2.2)
	end
end

-- ===== поза голема =====
local P = Rig.POSE
-- ===== огранювання кристалів нижніми руками (відкривається з 3-ї карти; на 1-й і 2-й кристалів немає взагалі) =====
-- Сервер на кожен кристал змінює CutSeq (+1) і CutType (1 кварц, 2 аметист, 3 сапфір) на моделі майстерні.
-- Кристал летить з піддона руди в нижню ліву руку → права нижня підводить різак (диск крутиться, іскри) → огранений летить на піддон.
-- Пози CUT_L / CUT_R перевірено на перетини з тілом, іншими руками й ударом молота (контакт диска з кристалом лише в CUT).
local CUT_L = { bL = -20, bLz = 40, bLy = 40, bLe = 90 }
local CUT_R = { bR = 40, bRz = 60, bRy = -10, bRe = 6 }
local CUT_TIME = 3.2
local CRY_C = Vector3.new(0, -3.55, 0) -- центр кристала в нижній лівій руці (простір ліктя elBL)
local CRY_COL = { { "f1e6ff", "ffffff" }, { "9a5cd6", "c99bff" }, { "2f6fe0", "7fb2ff" } } -- кварц, аметист, сапфір: тіло, ядро
local function crystalsOpen(f: Model): boolean
	local o = f:GetAttribute("StageOverride") -- лише для тестової чернетки
	if o then return o >= 3 end
	local n: Instance? = f.Parent
	while n and n ~= workspace and n:GetAttribute("OwnerUserId") == nil do n = n.Parent end
	local id = n and n:GetAttribute("OwnerUserId") or 0
	local pl = id ~= 0 and Players:GetPlayerByUserId(id) or nil
	return pl ~= nil and (tonumber(pl:GetAttribute("Stage")) or 1) >= 3
end
local function poseFor(r, dt)
	local f = r.f
	local st = f:GetAttribute("State") or "Asleep"
	local T = workspace:GetServerTimeNow() - (f:GetAttribute("StateTime") or 0)
	local pose, lid, look = nil, 0, { 0, 0 }
	local handOn = false
	if st == "Asleep" then
		local br = math.sin(os.clock() * 1.6)
		pose = table.clone(P.sleep); pose.lean = -15 + br * 1.2; pose.headX = -20 + br * 1.5; lid = 1
		r.heat = math.max(0, r.heat - dt * 0.5)
	elseif st == "Waking" then
		r.heat = math.clamp((T - 2.0) / 1.6, 0, 1)
		if T < 0.8 then
			pose = table.clone(P.sleep); local u = smooth(T / 0.8); pose.headX = lerp(-20, 0, u); pose.headZ = lerp(9, 0, u)
			lid = T < 0.35 and 1 - T / 0.35 or (T < 0.5 and (T - 0.35) / 0.15 or math.max(0, 1 - (T - 0.5) / 0.12))
		-- встає одразу на робоче місце: підйом і зсув до ковадла йдуть разом, без кроків на місці
		elseif T < 2.7 then pose = Rig.blend(P.sleep, P.standW, smooth((T - 0.8) / 1.9)); pose.headX = 0; pose.headZ = 0
		-- стоїть, помічає молот на ковадлі (погляд униз)
		elseif T < 3.2 then
			local u = smooth((T - 2.7) / 0.5)
			pose = table.clone(P.standW); pose.headX = 5 * u; look = { 0, -0.05 * u }
		-- одне безперервне плавне рух: рука й кисть піднімаються до пози очікування (idleW), молот береться посередині руху.
		-- Закінчується рівно в idleW — тією ж позою, з якої починається Working, тому ривка вгору-вниз немає.
		else
			local u = smooth((T - 3.2) / (Cfg.WAKE_TIME - 3.2))
			local arc = math.sin(u * math.pi)
			pose = Rig.blend(P.standW, P.idleW, u)
			pose.lean += arc * 2.5 -- легкий нахил до ковадла в момент хвату
			pose.headX = 5 * (1 - u) + arc * 3; look = { 0, -0.05 * (1 - u) }
			handOn = u > 0.5
		end
	elseif st == "Dozing" then
		r.heat = math.max(0, 1 - T / 2.4)
		r.cycle = false; table.clear(r.queue)
		-- (майстерня) спершу 0.6 с складає середні руки, тримаючи верхні в робочій позі, потім опускає верхні
		if T < 0.6 then pose = table.clone(P.work); handOn = true
		elseif T < 1.2 then pose = Rig.blend(P.work, P.standW, smooth((T - 0.6) / 0.6)); handOn = T < 0.95
		-- сідає одразу з робочого місця: опускання і зсув до стінки йдуть разом, без ходьби
		elseif T < 3.6 then pose = Rig.blend(P.standW, P.sleep, smooth((T - 1.2) / 2.4)); pose.headX = 0; pose.headZ = 0
		else local u = smooth((T - 3.6) / 0.8); pose = table.clone(P.sleep); pose.headX = lerp(0, -20, u); pose.headZ = lerp(0, 9, u); lid = u end
		-- якщо заснув посеред удару: молот і корпус плавно доходять до пози (раніше перескакували за один кадр)
		for _, k in { "armR", "wrist", "lean", "armL" } do if r.cur[k] then pose[k] = lerp(r.cur[k], pose[k], math.min(1, dt * 6)) end end
	else -- Working
		handOn = true
		local busy = r.cycle or #r.queue > 0 or f:GetAttribute("Busy") == true
		for _, o in ORE do if (f:GetAttribute("Pal_" .. o.key) or 0) > 0 then busy = true end end
		r.heat = lerp(r.heat, busy and 1 or 0.45, math.min(1, dt * 1.5))
		-- новий цикл: у печі є готова руда, а попередня заготовка вже злетіла з ковадла
		if not r.cycle and r.queue[1] and os.clock() >= r.queue[1].ready and (not r.job or r.job.phase == "toPallet") then
			local q = table.remove(r.queue, 1)
			r.cycle = true; r.ct = 0; r.hit = false; r.hsnd = false
			r.next = { t = q.t, phase = "toClaw", u = 0 }
		end
		if r.next and (not r.job) then r.job = r.next; r.next = nil end
		if r.cycle then
			r.ct += dt * (r.k or 1)
			-- звук: старт за HitOffset (+Lead) до моменту удару (Rig.HIT = 0.92 с циклу), щоб пік удару лагав разом із молотом
			if not r.hsnd and r.hitSnd and r.hitSnd.SoundId ~= "" then
				local lead = (r.hitSnd:GetAttribute("HitOffset") or 0) + (r.hitSnd:GetAttribute("Lead") or 0)
				if r.ct >= math.max(0, Rig.HIT - lead * (r.k or 1)) then
					r.hsnd = true
					r.hitSnd.TimePosition = 0
					r.hitSnd:Play()
				end
			end
			if not r.hit and r.ct >= Rig.HIT then
				r.hit = true; r.flash = 1
				if r.sparks then r.sparks:Emit(22) end
				if r.job and r.job.phase ~= "toPallet" then r.job.flat = true end
			end
			if r.job and r.job.phase == "onAnvil" and r.ct >= 1.15 then r.job.phase = "toPallet"; r.job.u = 0 end
			if r.ct >= Rig.CYCLE then r.cycle = false; r.ct = 0 end
			local i, a, w, l = strikeAt(r.ph, math.min(r.ct, Rig.CYCLE))
			pose = table.clone(P.work); pose.armR = a; pose.wrist = w; pose.lean = l; pose._fast = (i == 3 or i == 4)
			look = (i == 1 or i == 2) and { -0.01, 0.03 } or { 0, -0.07 }
			local since = r.ct - Rig.HIT
			if since > 0 and since < 0.2 then lid = math.max(lid, 0.45 - since * 2) end
		else
			pose = table.clone(busy and P.work or P.idleW); pose.lean += math.sin(os.clock() * 2) * 0.6
			local g = math.floor(os.clock() / 1.1) % 4
			look = ({ { 0, 0.02 }, { -0.09, 0 }, { 0, 0.02 }, { 0.07, 0 } })[g + 1]
		end
		-- плавні переходи (крім самого удару)
		if not pose._fast then
			for _, k in { "armR", "wrist", "lean", "armL" } do if r.cur[k] then pose[k] = lerp(r.cur[k], pose[k], math.min(1, dt * 6)) end end
		end
	end
	-- ===== 6 рук: середні — по шляхах без перетинів (Rig.MPATH), нижні — огранювання =====
	do
		local MP = Rig.MPATH
		local clock = os.clock()
		local function mid(side, list, u, rev) local a, z, e = Rig.pathAt(list, u, rev); Rig.setMid(pose, side, a, z, e) end
		if st == "Asleep" then
			local br = math.sin(clock * 1.6)
			pose.bR += br * 2; pose.bL += br * 2
		elseif st == "Waking" then
			-- середні лишаються складеними (верхні руки ще низько); нижні беруть різець і кристал
			if T >= 3.2 then
				local s = smooth(math.clamp((T - 3.2) / math.max(0.1, Cfg.WAKE_TIME - 3.2), 0, 1))
				pose.bR = lerp(55, 50, s); pose.bL = lerp(55, 50, s); pose.bRe = lerp(20, 45, s); pose.bLe = lerp(20, 45, s)
				pose.bRz = lerp(-6, 8, s); pose.bLz = lerp(6, -8, s)
			end
		elseif st == "Dozing" then
			-- спершу складає середні руки, потім сідає
			if T < 0.6 then local u = T / 0.6; mid("R", MP.R.restReach, u, true); mid("L", MP.L.restReach, u, true)
			elseif T < 1.2 then
				-- середні лишаються складеними (поза P.work тут би знову їх розкинула — був ривок), плавно переходять у standW
				local s = smooth((T - 0.6) / 0.6)
				mid("R", MP.R.restReach, 0); mid("L", MP.L.restReach, 0)
				for _, k in { "mR", "mRz", "mRe", "mL", "mLz", "mLe" } do pose[k] = lerp(pose[k], P.standW[k], s) end
			end
		else -- Working
			local busy2 = r.cycle or #r.queue > 0
			if T < 0.9 then
				-- щойно прокинувся: верхні вже підняті — розкладає середні руки вбік
				local u = T / 0.9
				mid("R", MP.R.restReach, u); mid("L", MP.L.restReach, u)
			else
				-- права середня (з боку печі) ловить заготовку з устя й підкидає на ковадло: усе в межах розкладеної пози,
				-- без витягування до печі/ковадла (вони поза досяжністю). u — положення на шляху restReach (1 = розкладена).
				-- ліва середня лише «дихає». Перехід плавний: r.mrU / r.mlU доганяють ціль (без ривків між станами).
				local s = (math.sin(clock * 0.9) + 1) / 2
				local tR, tL = 1 - s * 0.12, 1 - s * 0.1
				if r.cycle then
					local ct = r.ct
					if ct < 0.3 then tR = 1
					elseif ct < 0.42 then tR = 1 - 0.1 * smooth((ct - 0.3) / 0.12) -- ловить: клешня трохи осідає
					elseif ct < 0.52 then tR = 0.9 - 0.1 * smooth((ct - 0.42) / 0.1) -- замах
					elseif ct < 0.64 then tR = 0.8 + 0.2 * smooth((ct - 0.52) / 0.12) -- кидок (реліз на TOSS_AT)
					else tR = 1 end
				end
				r.mrU = lerp(r.mrU or 1, tR, math.min(1, dt * 16)); r.mlU = lerp(r.mlU or 1, tL, math.min(1, dt * 6))
				mid("R", MP.R.restReach, r.mrU)
				-- ліва середня тримає кристал (GrindCrystal) у розкладеній позі й ледь «дихає» (без тягнення до недосяжних цілей)
				mid("L", MP.L.restReach, 1 - 0.06 * s)
			end
			-- нижні: тримають різак (і кристал, коли він є) — легке «дихання»; саме огранювання накладається нижче (r.cutW)
			local b2 = math.sin(clock * 1.3)
			pose.bR += b2 * 1.5; pose.bL += b2 * 1.5
		end
	end
	-- огранювання: плавний перехід нижніх рук у пози CUT_L / CUT_R, поки кристал летить у руку й обробляється
	do
		local c = r.cut
		local cutting = st == "Working" and c ~= nil and (c.phase == "fly" or c.phase == "cut")
		r.cutW = math.clamp((r.cutW or 0) + (cutting and dt * 2.2 or -dt * 2.2), 0, 1)
		local w = smooth(r.cutW)
		if w > 0 then
			for k, v in CUT_L do pose[k] = lerp(pose[k] or 0, v, w) end
			for k, v in CUT_R do pose[k] = lerp(pose[k] or 0, v, w) end
			if c and c.phase == "cut" then pose.bRe += math.sin(os.clock() * 7) * 5 * w end -- диск то заходить у кристал, то відходить
		end
	end
	pose._fast = nil
	for k, v in pose do r.cur[k] = v end
	return pose, lid, look, handOn, st
end

-- ===== звук вогню печі =====
-- Вогонь «відомий», коли r.heat >= 0.03 (так само, як показуються язики полум'я). Цикл:
--   прокидання голема → heat зростає → грає Snd_Ignite → після нього зациклене Snd_FireLoop (гучність йде за heat)
--   → голем засинає, heat падає до 0 → звук затихає й зупиняється → наступне прокидання починає цикл знову.
local function startFireLoop(r)
	local loop = r.floop
	if not loop or loop.SoundId == "" then return end
	r.floopActive = true
	loop.Looped = true
	loop.Volume = r.fvol
	if loop.TimeLength > 5 then loop.TimePosition = math.random() * (loop.TimeLength - 5) end -- щоб печі не грали в унісон
	loop:Play()
end

local function fireSound(r, heat: number, dt: number)
	local ign, loop = r.fign, r.floop
	if not ign and not loop then return end
	local on = heat >= 0.03
	if on and not r.fon then
		-- початок циклу: запалювання, потім горіння
		r.fon = true; r.ftoken += 1
		local tk = r.ftoken
		r.fvol = 0; r.floopActive = false
		if ign and ign.SoundId ~= "" then
			ign.TimePosition = 0; ign:Play()
			local len = ign.TimeLength > 0 and ign.TimeLength or 1.75
			task.delay(math.max(0.1, len - 0.15), function()
				if r.ftoken == tk and r.fon then startFireLoop(r) end
			end)
		else
			startFireLoop(r)
		end
	elseif not on and r.fon then
		-- вогонь погас: скасовуємо відлік до запуску циклу горіння
		r.fon = false; r.ftoken += 1; r.floopActive = false
		if ign and ign.IsPlaying then ign:Stop() end
	end
	-- гучність горіння: плавно за heat (повна при heat = 1, тихіше при heat 0.45), у нуль — після гасіння
	if loop then
		local target = (r.fon and r.floopActive) and r.floopBase * math.clamp(heat, 0, 1) ^ 0.8 or 0
		r.fvol += (target - r.fvol) * math.min(1, dt * (target > r.fvol and 3 or 6))
		if loop.IsPlaying then
			loop.Volume = r.fvol
			if target == 0 and r.fvol < 0.004 then loop:Stop() end
		end
	end
end

-- ===== кадр =====
local camera = workspace.CurrentCamera
RunService.RenderStepped:Connect(function(dt)
	local clock = os.clock()
	for f, r in recs do
		if not f.Parent then recs[f] = nil continue end
		curForge = f
		-- нова переплавка на сервері → руда летить у піч і стає в чергу
		local seq = f:GetAttribute("SmeltSeq") or 0
		r.k = tempoOf(f)
		if seq ~= r.seq then
			local n = seq - r.seq
			r.seq = seq
			local t = f:GetAttribute("SmeltType") or 1
			if r.flyFrom and r.mouth and n > 0 then
				fly(r.flyFrom.Position, r.mouth.Position, oreAt(t).color, V(0.62, 0.62, 0.62) * S, 0.5 / r.k, t)
				if #r.queue < QUEUE_MAX then table.insert(r.queue, { t = t, ready = clock + 0.9 / r.k }) end
			end
		end
		-- огранювання: нові кристали (CutSeq / CutType) → черга, лише якщо відкрито (3-я карта)
		r.cryOn = crystalsOpen(f)
		local cseq = f:GetAttribute("CutSeq") or 0
		if cseq ~= r.cutSeq then
			if cseq > r.cutSeq and r.cryOn and #r.cutQ < 4 then table.insert(r.cutQ, math.clamp(f:GetAttribute("CutType") or 1, 1, 3)) end
			r.cutSeq = cseq
		end
		do
			local stNow = f:GetAttribute("State")
			if not r.cut and r.cutQ[1] and stNow == "Working" and r.cryOn then r.cut = { t = table.remove(r.cutQ, 1), phase = "fly", u = 0 } end
			local c = r.cut
			if c then
				local kk = r.k or 1
				if c.phase ~= "out" and (stNow ~= "Working" or not r.cryOn) then c.phase = "out"; c.u = 0; c.from = nil end -- заснув — кристал відлітає на піддон
				if c.phase == "fly" then c.u += dt * kk / 0.7; if c.u >= 1 then c.phase = "cut"; c.u = 0 end
				elseif c.phase == "cut" then c.u += dt * kk / CUT_TIME; if c.u >= 1 then c.phase = "out"; c.u = 0; c.from = nil end
				elseif c.phase == "out" then c.u += dt * kk / 0.7; if c.u >= 1 then r.cut = nil end end
			end
		end
		if (camera.CFrame.Position - r.origin.Position).Magnitude > 300 then continue end
		local pose, lid, look, handOn, st = poseFor(r, dt)
		-- кліпання (коли очі відкриті)
		if lid < 1 then
			r.blinkT -= dt
			if r.blinkT <= 0 then r.blinkT = 2.6 + math.random() * 3; r.blinkA = 0.16 end
			if r.blinkA > 0 then r.blinkA -= dt; local u = 1 - r.blinkA / 0.16; lid = math.max(lid, 1 - math.abs(u * 2 - 1)) end
		end
		r.eyeX = lerp(r.eyeX, look[1], math.min(1, dt * 12)); r.eyeY = lerp(r.eyeY, look[2], math.min(1, dt * 12))
		local J = Rig.solve(Rig.rootCF(r.gorigin, pose), pose)
		r.clawCF = J.elMR and J.elMR * CFrame.new(0, -5.0, 0) or nil -- точка між пальцями правої середньої клешні
		local cutNow = r.cut ~= nil and r.cut.phase == "cut"
		r.discSpd = lerp(r.discSpd, cutNow and 32 or 0, math.min(1, dt * (cutNow and 3 or 1.5)))
		r.discAng = (r.discAng + r.discSpd * dt) % (math.pi * 2)
		if cutNow then r.cryAng = (r.cryAng + dt * 1.6) % (math.pi * 2) end
		local cfs = table.create(#r.parts)
		for i, p in r.parts do
			local j = J[r.joints[i]]
			local sc = r.spinDisc[i]
			if sc then
				cfs[i] = j * CFrame.new(sc) * CFrame.Angles(r.discAng, 0, 0) * CFrame.new(-sc) * r.offs[i]
			elseif r.cryParts[i] then
				cfs[i] = j * CFrame.new(CRY_C) * CFrame.Angles(0, r.cryAng, 0) * CFrame.new(-CRY_C) * r.offs[i]
			else
				cfs[i] = r.look[i] and j * CFrame.new(r.eyeX * SC, r.eyeY * SC, 0) * r.offs[i] or j * r.offs[i]
			end
		end
		workspace:BulkMoveTo(r.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		-- кристал у руці (лише під час огранювання), летючий кристал, іскри; кристали середньої руки й верстата — лише з 3-ї карти
		do
			local c = r.cut
			local col = c and CRY_COL[c.t] or CRY_COL[2]
			for i, kind in r.cryParts do
				local p = r.parts[i]
				p.Transparency = cutNow and (kind == "core" and 0.25 or 0.2) or 1
				if cutNow then p.Color = Color3.fromHex(kind == "core" and col[2] or col[1]) end
			end
			local handPos = (J.elBL * CFrame.new(CRY_C)).Position
			local fc = r.cryFly
			if fc then
				if c and (c.phase == "fly" or c.phase == "out") then
					local a, b
					if c.phase == "fly" then a, b = (r.flyFrom and r.flyFrom.Position or handPos), handPos
					else c.from = c.from or handPos; a, b = c.from, (r.flyTo and r.flyTo.Position or handPos) end
					local u = smooth(c.u)
					fc.Color = Color3.fromHex(col[1]); fc.Transparency = 0.15
					fc.Size = c.phase == "out" and Vector3.new(0.5, 0.75, 0.5) or Vector3.new(0.62, 1.0, 0.62)
					fc.CFrame = CFrame.new(a:Lerp(b, u) + Vector3.new(0, math.sin(u * math.pi) * 2.2 * S, 0)) * CFrame.Angles(clock * 3, clock * 4, 0)
				else
					fc.Transparency = 1
				end
			end
			if r.cutSparks then
				r.cutSparks.Rate = (cutNow and r.cutW > 0.9) and (30 + math.sin(clock * 7) * 15) or 0
				if cutNow then r.cutSparks.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHex(col[2])) end
			end
			if r.cryOnShown ~= r.cryOn then
				r.cryOnShown = r.cryOn
				for _, p in r.grindCry do p.LocalTransparencyModifier = r.cryOn and 0 or 1 end
				for _, p in r.benchCry do p.LocalTransparencyModifier = r.cryOn and 0 or 1 end
				for _, l in r.benchLights do l.Enabled = r.cryOn end
			end
		end
		local c = math.max(0.02, lid)
		for _, l in r.lids do
			local lo = l:GetAttribute("LidOff")
			local h = 0.6 * SC
			if string.sub(l.Name, 1, 3) == "Lid" then
				l.Size = V(l.Size.X, h * c, l.Size.Z); l.CFrame = J.head * lo * CFrame.new(0, -h * c / 2, 0)
			else
				l.CFrame = J.head * lo * CFrame.new(0, -h * c, -0.01); l.Transparency = lid > 0.08 and 0 or 1
			end
		end
		-- закрите око: зіниці й відблиски ховаються, щоб нічого не випирало крізь повіку
		for _, p in r.eyes do p.Transparency = lid > 0.3 and 1 or 0 end
		for _, p in r.hand do p.Transparency = handOn and 0 or 1 end
		for _, p in r.rest do p.Transparency = handOn and 1 or 0 end
		-- піч і міх
		local heat = r.heat
		-- топка в грудях: колір і світло за жаром, легке мерехтіння; дим з димаря
		if r.fbox then
			local flick = 0.88 + math.sin(clock * 11) * 0.07 + math.sin(clock * 23) * 0.05
			r.fbox.Color = Color3.fromHex("3a1a0c"):Lerp(Color3.fromHex("ff6a1a"), math.clamp(0.12 + heat * flick, 0, 1))
			if r.flight then r.flight.Brightness = 0.15 + heat * 1.6 * flick end
		end
		if r.smoke then r.smoke.Rate = heat > 0.3 and (2 + heat * 5) or 0.35 end
		local pump = (math.sin(clock * 2.4) + 1) / 2 * heat
		fireSound(r, heat, dt)
		-- пшик міха: pump = (sin(clock*2.4)+1)/2*heat. pump=1 — міх стиснуто (верх і ручка внизу), pump=0 — розкрито.
		-- Хід вниз починається, коли sin = -1 (2.4*clock = 1.5π + 2πk), триває π/2.4 ≈ 1.31 с — звук 1.2 с (0.6 с при PlaybackSpeed 0.5).
		if r.puff and r.puff.SoundId ~= "" then
			local ph = clock * 2.4 - 1.5 * math.pi
			local n = math.floor(ph / (2 * math.pi))
			if r.puffN == nil then
				r.puffN = n
			elseif n ~= r.puffN then
				r.puffN = n
				local since = (ph % (2 * math.pi)) / 2.4 -- скільки секунд минуло з початку ходу
				if heat >= 0.2 and since < 0.15 then r.puff.TimePosition = 0; r.puff:Play() end
			end
		end
		for _, p in r.fire do
			local base = p:GetAttribute("BaseSize") :: Vector3
			local ph = p:GetAttribute("Ph") :: number
			if heat < 0.03 then p.Transparency = 1 else
				p.Transparency = 0
				p.Size = base * V(heat, heat * (1 + math.sin(clock * 13 + ph) * 0.18), heat)
				p.CFrame = r.KF * (p:GetAttribute("BaseCF") :: CFrame) + V(0, math.sin(clock * 9 + ph) * 0.12 * S * heat, 0)
			end
		end
		for _, p in r.coals do p.Color = COLD:Lerp(HOT, heat) end
		if r.fireLight then r.fireLight.Brightness = heat * (1.35 + pump * 0.35 + math.sin(clock * 11) * 0.15) end
		if r.embers then r.embers.Rate = heat > 0.4 and 7 * heat or 0 end
		-- декор: шестерні крутяться повільно уві сні й швидше за роботи; коло точить лише при жарі
		if r.spins then
			r.grind = lerp(r.grind, (heat > 0.6 and r.cryOn) and 1 or 0, math.min(1, dt * 1.2)) -- точильне коло — лише з 3-ї карти
			local dparts, dcfs = {}, {}
			for _, s in r.spins do
				local speed = s.grinder and (r.grind * 9) or (s.rate * (0.25 + heat * 1.5))
				if math.abs(speed) > 0.001 then
					s.ang = (s.ang + speed * dt) % (math.pi * 2)
					local rot = s.pv * (s.ax == "X" and CFrame.Angles(s.ang, 0, 0) or CFrame.Angles(0, 0, s.ang))
					for i, p in s.parts do table.insert(dparts, p); table.insert(dcfs, rot * s.offs[i]) end
				end
			end
			for _, n in r.needles do
				local a = -math.rad(20 + heat * 150 + math.sin(clock * 7 + n.ph) * 6 * heat)
				table.insert(dparts, n.p); table.insert(dcfs, n.c * CFrame.Angles(a, 0, 0) * n.off)
			end
			if #dparts > 0 then workspace:BulkMoveTo(dparts, dcfs, Enum.BulkMoveMode.FireCFrameChanged) end
			if r.gsparks then r.gsparks.Rate = r.grind > 0.7 and (18 + math.sin(clock * 5) * 10) or 0 end
			if r.vent then
				r.ventT -= dt
				if r.ventT <= 0 then
					r.ventT = 5 + math.random() * 4
					if heat > 0.3 then r.vent:Emit(10) end
				end
			end
		end
		if r.belPivot then
			local rot = r.belPivot.CFrame * CFrame.Angles(D(-pump * 14), 0, 0)
			for _, p in r.belTop do p.CFrame = rot * r.belOff[p] end
		end
		-- шкіра міха: трапеція між дошками. Низ — на верхній грані основи, верх — по нижній грані нахиленої дошки:
		-- коробка (висота меншого краю) + клин зверху (різниця висот). Заходить у дошки на SINK, щоб не було щілин.
		if r.leather and r.leatherWedge and r.belBase and r.belBoard and r.belBoard.Parent then
			local SINK = 0.06
			local bt = r.belBase.CFrame * CFrame.new(0, r.belBase.Size.Y / 2, 0)
			local by = r.belBoard.Size.Y / 2
			local L = r.leatherXZ.Z / 2
			local pa = bt:PointToObjectSpace((r.belBoard.CFrame * CFrame.new(0, -by, -L)).Position)
			local pb = bt:PointToObjectSpace((r.belBoard.CFrame * CFrame.new(0, -by, L)).Position)
			local dz = pb.Z - pa.Z
			local slope = math.abs(dz) > 1e-4 and (pb.Y - pa.Y) / dz or 0
			local ha = math.max(0.1, pa.Y + slope * (-L - pa.Z) + 2 * SINK) -- висота біля -Z
			local hb = math.max(0.1, pa.Y + slope * (L - pa.Z) + 2 * SINK)  -- висота біля +Z
			local low, diff = math.min(ha, hb), math.abs(ha - hb)
			r.leather.Size = V(r.leatherXZ.X, low, r.leatherXZ.Z)
			r.leather.CFrame = bt * CFrame.new(0, -SINK + low / 2, 0)
			local wd = r.leatherWedge
			if diff < 0.004 then
				wd.Transparency = 1
			else
				wd.Transparency = r.leather.Transparency
				wd.Size = V(r.leatherXZ.X, diff, r.leatherXZ.Z)
				-- клин: високий край на +Z; якщо вищий -Z — розвертаємо на 180°
				wd.CFrame = bt * CFrame.new(0, -SINK + low + diff / 2, 0) * (hb >= ha and CFrame.identity or CFrame.Angles(0, math.pi, 0))
			end
		end
		r.flash = math.max(0, r.flash - dt * 3)
		jobUpdate(r, dt, clock)
		-- «Z» над головою
		if r.zzz then
			r.zzz.Enabled = st == "Asleep"
			if st == "Asleep" then
				for i = 1, 3 do
					local z = r.zzz:FindFirstChild("Z" .. i)
					local a = (clock * 0.45 + i / 3) % 1
					z.Position = UDim2.fromScale(0.05 + a * 0.45, 0.8 - a * 0.75)
					z.TextTransparency = a < 0.15 and 1 - a / 0.15 or a
					z.Size = UDim2.fromScale(0.2 + a * 0.15, 0.14 + a * 0.1)
				end
			end
		end
	end
	for i = #flyers, 1, -1 do
		local fl = flyers[i]
		fl.t += dt / fl.dur
		local u = math.min(1, fl.t)
		fl.p.CFrame = CFrame.new(fl.a:Lerp(fl.b, u) + V(0, math.sin(u * math.pi) * 3 * S, 0)) * CFrame.Angles(clock * 6, 0, clock * 4)
		if u >= 1 then fl.p:Destroy(); table.remove(flyers, i) end
	end
end)

-- вікно кузні в колі — окремий скрипт StarterPlayerScripts/ForgeWindow

-- екрани табла: будуються поблизу камери для всіх кузень (кнопки активні лише на своїй), дані — власника кузні
local function refreshPanels()
	local camPos = camera.CFrame.Position
	for f, r in recs do
		local up = f:FindFirstChild("UpgradePanel")
		local screen = up and up:FindFirstChild("screen")
		local ownerId = f.Parent and f.Parent:GetAttribute("OwnerUserId") or 0
		local dist = screen and (screen.Position - camPos).Magnitude or math.huge
		if r.panel and (dist > 200 or r.panel.ownerId ~= ownerId or r.panel.screen ~= screen) then r.panel.gui:Destroy(); r.panel = nil end
		if not r.panel and screen and dist < 140 then r.panel = buildPanel(f, screen, ownerId) end
		local pn = r.panel
		if pn then
			local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil
			local money = owner and owner:GetAttribute("Money") or 0
			local working = f:GetAttribute("State") == "Working"
			local cl, sl = f:GetAttribute("CapLvl") or 1, f:GetAttribute("SpdLvl") or 1
			local cp, sp = Cfg.capPrice(cl), Cfg.spdPrice(sl)
			local smax = Cfg.spdMax(sl)
			local cap, spd = pn.cards.Cap, pn.cards.Spd
			if Cfg.capMax(cl) then -- економіка v2: місткість має максимум
				cap.value.Text = string.format('<font color="#D4FF3E">MAX (%s)</font>', NF.money(Cfg.capOf(cl)))
				cap.sa:setText("MAX")
				cap.sa:setColor("gray")
				pn.can.Cap = false
			else
				cap.value.Text = string.format('<font color="#FFFFFF">%s</font>  <font color="#D4FF3E">›  %s</font>', NF.money(Cfg.capOf(cl)), NF.money(Cfg.capOf(cl + 1)))
				cap.sa:setText(NF.money(cp))
				cap.sa:setColor(money >= cp and "green" or "gray")
				pn.can.Cap = working and money >= cp
			end
			if smax then
				spd.value.Text = string.format('<font color="#D4FF3E">MAX (%.2fs)</font>', Cfg.spdOf(sl))
				spd.sa:setText("MAX")
				spd.sa:setColor("gray")
				pn.can.Spd = false
			else
				spd.value.Text = string.format('<font color="#FFFFFF">%.2fs</font>  <font color="#D4FF3E">›  %.2fs</font>', Cfg.spdOf(sl), Cfg.spdOf(sl + 1))
				spd.sa:setText(NF.money(sp))
				spd.sa:setColor(money >= sp and "green" or "gray")
				pn.can.Spd = working and money >= sp
			end
			-- Ore per Hit: скільки руди за один удар (1 → OPH_MAX)
			local ol = math.max(1, f:GetAttribute("OphLvl") or 1)
			local oph = pn.cards.Oph
			if Cfg.ophMax(ol) then
				oph.value.Text = string.format('<font color="#D4FF3E">MAX (%d ore)</font>', Cfg.ophOf(ol))
				oph.sa:setText("MAX")
				oph.sa:setColor("gray")
				pn.can.Oph = false
			else
				local op = Cfg.ophPrice(ol)
				oph.value.Text = string.format('<font color="#FFFFFF">%d</font>  <font color="#D4FF3E">›  %d</font>', Cfg.ophOf(ol), Cfg.ophOf(ol + 1))
				oph.sa:setText(NF.money(op))
				oph.sa:setColor(money >= op and "green" or "gray")
				pn.can.Oph = working and money >= op
			end
			-- Auto Workshop: куплено / геймпас — ON / OFF (Set_AutoWorkshop); до мапи AUTO_MIN_STAGE — замок; інакше ціна
			local au = pn.cards.Auto
			if au then
				local stage = tonumber(f.Parent and f.Parent:GetAttribute("Stage")) or 1
				if owner and Cfg.autoOwned(owner, f) then
					local on = owner:GetAttribute("Set_AutoWorkshop") ~= false
					au.value.Text = on and '<font color="#D4FF3E">Auto: ON</font>' or '<font color="#FFFFFF">Auto: OFF</font>'
					au.sa:setText(on and "ON" or "OFF")
					au.sa:setColor(on and "green" or "red")
					pn.can.Auto = working
				elseif stage < Cfg.AUTO_MIN_STAGE then
					au.value.Text = "Map " .. Cfg.AUTO_MIN_STAGE
					au.sa:setText("MAP " .. Cfg.AUTO_MIN_STAGE)
					au.sa:setColor("gray")
					pn.can.Auto = false
				else
					au.value.Text = '<font color="#FFFFFF">Off</font>  <font color="#D4FF3E">›  On</font>'
					au.sa:setText(NF.money(Cfg.AUTO_PRICE))
					au.sa:setColor(money >= Cfg.AUTO_PRICE and "green" or "gray")
					pn.can.Auto = working and money >= Cfg.AUTO_PRICE
				end
			end
			pn.lock.Visible = not working
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.15)
		refreshPanels()
	end
end)
-- ===== табличка «FORGE» над колом кузні: синій градієнт, що переливається, + білий відблиск (як заголовок вікна) =====
-- Табличка — BillboardGui Forge/Ring/SignAnchor/ForgeSign (Title, State). Анімація лише на клієнті, для всіх кузень поблизу.
do
	local SIGN_P = { Color3.fromHex("c8fbff"), Color3.fromHex("5ff2ff"), Color3.fromHex("1fa8f2"), Color3.fromHex("5ff2ff") }
	local function sample(u)
		local x = (u % 1) * #SIGN_P
		local k = math.floor(x)
		local t = x - k
		t = t * t * (3 - 2 * t) -- плавний перехід між кольорами
		return SIGN_P[k + 1]:Lerp(SIGN_P[(k + 1) % #SIGN_P + 1], t)
	end
	local SHINE_T = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) })
	-- звичайна (не «слабка») таблиця: ключі-інстанси в слабкій таблиці зникають при збиранні сміття,
	-- і тоді табличка чіплялася знову (копії відблиску накопичувались, анімація «телепортувалась»). Видаляємо вручну.
	local signs = {} -- [title] = { grad, tween, nextAt }
	local function hook(sign: Instance)
		local t = sign:FindFirstChild("Title")
		if not (t and t:IsA("TextLabel")) or signs[t] then return end
		local grad = t:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", t)
		grad.Rotation = 0
		for _, old in t.Parent:GetChildren() do if old.Name == "TitleShine" then old:Destroy() end end
		local sh = t:Clone()
		sh.Name = "TitleShine"; sh.TextColor3 = Color3.new(1, 1, 1); sh.ZIndex = t.ZIndex + 1
		for _, c in sh:GetChildren() do c:Destroy() end
		local sg = Instance.new("UIGradient"); sg.Rotation = 25; sg.Transparency = SHINE_T; sg.Offset = Vector2.new(-1.3, 0); sg.Parent = sh
		sh.Parent = t.Parent
		local tw = game:GetService("TweenService"):Create(sg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
		tw.Completed:Connect(function() sg.Offset = Vector2.new(-1.3, 0) end)
		signs[t] = { grad = grad, tween = tw, nextAt = os.clock() + 1 + math.random() * 3 }
	end
	local function scan()
		local niches = workspace:FindFirstChild("Niches")
		if not niches then return end
		for _, d in niches:GetDescendants() do
			if d.Name == "ForgeSign" and d:IsA("BillboardGui") then hook(d) end
		end
	end
	task.spawn(function() while true do scan(); task.wait(2) end end)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local phase = -(now / 4)
		local ks
		for t, s in signs do
			if not t.Parent then signs[t] = nil continue end
			if not ks then
				ks = {}
				for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end -- 19 точок (максимум 20) — без «сходинок»
				ks = ColorSequence.new(ks)
			end
			s.grad.Color = ks
			-- статус на табличці з «...» (WAITING..., WAKING UP...): крапки з'являються по одній, слово не рухається
			-- (текст той самий, MaxVisibleGraphemes ховає зайві крапки, тож розмір і центр не стрибають)
			local st = t.Parent and t.Parent:FindFirstChild("State")
			if st and st:IsA("TextLabel") then
				local txt = st.Text
				if string.sub(txt, -3) == "..." then
					local want = #txt - 3 + (math.floor(now / 0.35) % 3 + 1)
					if st.MaxVisibleGraphemes ~= want then st.MaxVisibleGraphemes = want end
				elseif st.MaxVisibleGraphemes ~= -1 then
					st.MaxVisibleGraphemes = -1
				end
			end
			if now >= s.nextAt then s.tween:Play(); s.nextAt = now + 3 + math.random() * 3 end
		end
	end)
end
