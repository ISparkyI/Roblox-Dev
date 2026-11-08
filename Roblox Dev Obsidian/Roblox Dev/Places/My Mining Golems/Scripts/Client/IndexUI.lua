--!nonstrict
-- IndexUI — вікно INDEX: колекція големів і руди. Сторінка големів = клас × мутація (24 големи), усього 24 × 3 × 8 = 576 записів.
-- Де: StarterPlayer/StarterPlayerScripts/IndexUI (LocalScript). Інтерфейс будується кодом (ScreenGui IndexWindow).
-- Макет: 2D/Index (веб-макет index_mock, затверджений; v2–v4 — за відгуками). Стиль і помічники — як у InventoryUI: вікно
--   зі studs, кнопки «стиль A», темні слоти з сяйвом кольору рідкості, заголовок з синім переливом, червона X, поява 0,85 → 1,05 → 1,
--   UIScale під полотно 1080 × 640 (вікно 980 × 528 — як усі вікна; не збільшується, усе вміщається прокруткою).
--
-- Що на екрані: угорі розділи Golems / Ores / Bosses (кнопка, тінь, іконка й напис масштабуються разом — однією групою).
--   Golems: ліворуч класи Miners / Carriers / Warriors (іконки зі станції ролу) з лічильником «N / 192 found» (усі мутації класу);
--   під ними — «All Golems» (N / 576 і забрані діаманти). Над сіткою — 8 пігулок мутацій (Normal … Secret) з лічильником сторінки.
--   Сітка 6 у ряд, згрупована за рідкістю (гортається колесом, перетягуванням і повзунком; при відкритті вікна й зміні класу /
--   мутації / розділу — на початок). Невідкритий голем — чорний силует і «???».
--   Відкритий, але ще не забраний запис — слот затемнений, поверх — діамант «+N» і маленька зелена кнопка Claim (забрати нагороду).
--   Claim All (+N) — у вікні, ліворуч під вкладками класів: забирає всі незабрані нагороди з усіх класів, мутацій і руди; нічого — сіра.
--   Забрали — оверлей Claim і «+N» плавно зникають усіма шарами (заливка, текст, UIStroke), діаманти летять до лічильника HUD
--   (лічильник сам рахує вгору й «попає» — MainHUD, на будь-яке зростання Diamonds).
--   Червоні лічильники незабраних — на кнопках Golems / Ores, вкладках класів, пігулках мутацій і на кнопці Index у HUD.
--   Клік по картці — вибір (ще раз — зняти); внизу з'являється інформація: рідкість, клас, мутація, стати (лише відкриті), шанс
--   «1 in N» (Normal — не мутація, а стандарт: базовий шанс голема з каталогу; мутація — базовий × odds мутації) і нагорода. Нічого не вибрано
--   (так при кожному відкритті) — картки внизу немає, сітка займає її місце.
--   Ores: ліворуч мапа (Map 1, «N / 3 found»), сітка руди мапи (3D-моделі як в інвентарі — Shared/ItemViewport "Ore_<Key>"; шанс спавну),
--   картка внизу — HP, шанс спавну (Shared/PlotConfig), ціна руди й злитка або «Can't smelt» (Shared/ForgeConfig) і нагорода за руду:
--   n ≤ 5 → 5·n, далі 25·(n−4) (5, 10, 15, 20, 25, 50, 75, 100…), n — номер руди в PlotConfig.ORES (oreReward). «All Ores» — N / 3 і «+N earned».
-- Червоні лічильники — кружки без UIStroke (UIStroke на круглому Frame малює темний квадрат): темне коло + червоне коло, обидва UICorner 0,5.
-- Заголовок: іконка книжки (та сама, що на кнопці Index у HUD) зліва від «INDEX», ≈ 2 × висоти літер, нахил −8°; обводка й тінь
--   тексту та тінь іконки — чорні (INK; #040435 скасовано). Звуки — Shared/UISounds: hover на слотах і пігулках, tap на кліку
--   (кнопки StyleA — сам StyleA.bind), claim на Claim / Claim All. Пігулки мутацій — у горизонтальному ScrollingFrame (повзунок 4 px), лічильник
--   усередині пігулки справа. Іконки на кнопках — у «safe area» (відступ ≈ 10 % висоти кнопки з усіх боків).
--   Bosses — заглушка в тому ж стилі.
-- 30.10.2026: група Exclusive (GolemCatalog.EXCLUSIVES: Mushroom) — в кінці сторінки Normal кожного класу (після Celestial); замість шансу —
--   як отримати (Catalog.howToGet: Group / Daily / Soon). У лічильники N / 576 не входять, Claim — як за Normal.
-- 05.11.2026: голем з наступної мапи (GolemCatalog map > атрибут Stage гравця) — плашка «MAP N» поверх картки, у картці внизу
--   «Drops from MAP N»; перехід на нову мапу — плашки оновлюються самі.
-- Відкриття: кнопка Index у HUD (MainHUD → ReplicatedStorage/UIEvents/HUDButton "Index"; повторне натискання — закрити).
--   Закриття — X, Esc, клік поза вікном. Одне вікно за раз: при відкритті закривається Inventory і ховаються Forge / Sell / PlotPlace;
--   відкрили Inventory (кнопка або B) — Index закривається.
-- Дані: атрибути гравця IndexFound (JSON-список ключів "<id>:<клас>:<мутація>" і "ore:<Key>") і IndexClaimed (забрані) — ставить
--   сервер IndexService. Дії: Remotes/IndexAction ("Claim", ключ) і ("ClaimAll"); діаманти нараховує сервер. Каталог — Shared/GolemCatalog;
--   3D-модель голема (у кого вона є) — Shared/ItemViewport, інакше іконка GolemCatalog.icon.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local MutationText = require(Shared:WaitForChild("MutationText")) -- анімовані градієнти назв мутацій (пігулки, картка)
local StyleA = require(Shared:WaitForChild("StyleA"))
local ItemVP = require(Shared:WaitForChild("ItemViewport"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local Forge = require(Shared:WaitForChild("ForgeConfig"))
local PlotCfg = require(Shared:WaitForChild("PlotConfig"))
local UISounds = require(Shared:WaitForChild("UISounds")) -- hover / tap / claim (звуки SoundService)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ICON = {
	golems = (Items.ICONS and Items.ICONS.tab_golems) or "rbxassetid://125478992512505", -- вкладка Golems інвентаря
	-- копії лише для Index з ЧОРНИМ контуром (#040435 → #14161a, v8); оригінали (HUD, станція ролу) не змінювались
	ores = "rbxassetid://138440040019462", -- index_ore_icon_ink (варіант A; Decal 102083657051701)
	book = "rbxassetid://81868206271295", -- index_title_book_ink (книжка hud_index; Decal 99925081177892)
	bosses = "rbxassetid://137113714883300", -- 06.11.2026: нова іконка боса (шолом, як у HUD і вікні порталу); був череп index_boss_ink 111613717383454
	diamond = "rbxassetid://126442692946356", -- hud_diamond (MainHUD)
	miner = "rbxassetid://72243061675485",   -- index_class_*_ink — іконки класів станції ролу (Decal 85390237520635)
	carrier = "rbxassetid://133110323029733", -- Decal 81676518505400
	warrior = "rbxassetid://81730174326768", -- Decal 70557914685591
	Coal = StyleA.ASSETS.forge_ore_coal_v2, Copper = StyleA.ASSETS.forge_ore_copper_v2, Iron = StyleA.ASSETS.forge_ore_iron_v2,
}
local REWARD = { 1, 2, 3, 5, 10, 25, 100, 200 } -- діаманти за новий запис, за мутацією (GDD - Quests and Index; нараховує IndexService)
-- руда: діаманти за n-ту руду каталогу (PlotConfig.ORES): n ≤ 5 → 5·n, далі 25·(n−4) — 5, 10, 15, 20, 25, 50, 75, 100… (як у IndexService)
local ORE_REWARD_STEP, ORE_REWARD_BIG = 5, 25
local function oreReward(n: number): number return n <= 5 and ORE_REWARD_STEP * n or ORE_REWARD_BIG * (n - 4) end
local CLS = { { "miner", "Miners", "Miner" }, { "carrier", "Carriers", "Carrier" }, { "warrior", "Warriors", "Warrior" } }
local NMUT = #Catalog.MUTATIONS

-- големи Index: каталог без Exclusive
local GOLEMS = {}
for _, id in Catalog.ORDER do
	local g = Catalog.get(id)
	if g and g.rarity ~= "Exclusive" then table.insert(GOLEMS, g) end
end
local PAGE = #GOLEMS
-- 04.11.2026: лічильники враховують і ексклюзиви (лише сторінка Normal кожного класу): клас = 24 × 8 + 9, усе = × 3 класи
-- 05.11.2026: ексклюзиви Marketplace — лише у своєму класі (Catalog.exclusivesFor), тож суми класів різні
local PER_CLASS = function(c: string): number return PAGE * NMUT + #Catalog.exclusivesFor(c) end
local TOTAL = PER_CLASS("miner") + PER_CLASS("carrier") + PER_CLASS("warrior")

-- руда мап 1–6 (03.11.2026; була лише мапа 1): HP і шанс спавну — PlotConfig.INDEX_ORES, ціна й переплавка — ForgeConfig.
-- Мапа 7 — наступне оновлення, тут її немає.
-- усе про вкладки мап — в одній таблиці (ліміт 200 локальних змінних у скрипті): names, cur (вибрана мапа), tabs, hdr
local OM = { names = { "Mossy Grotto", "Rusty Mine", "Crystal Depths", "Magma Caverns", "Frozen Abyss", "Void Core" }, cur = 1, tabs = {}, hdr = nil }
local ORES = {}
for n, o in PlotCfg.INDEX_ORES or PlotCfg.ORES do
	local f = Forge.oreDef and Forge.oreDef(o.key) or nil
	table.insert(ORES, { key = o.key, hp = o.hp, odds = o.odds, price = f and f.price or 0, smelt = f ~= nil and Forge.canSmelt(f),
		tone = (Items.ORE_TONE and Items.ORE_TONE[o.key]) or (f and f.color) or Color3.new(1, 1, 1), chance = PlotCfg.oreChance(o.key),
		reward = oreReward(n), stage = o.stage or 1, ik = "ore:" .. o.key, vp = "Ore_" .. o.key, name = o.key, ore = o.key })
end
-- оброблена руда (03.11.2026, вкладка Crafted): злиток / огранований кристал кожної руди, що плавиться; ключ "bar:<Key>" (IndexService)
for n, o in PlotCfg.INDEX_ORES or PlotCfg.ORES do
	local f = Forge.oreDef and Forge.oreDef(o.key) or nil
	if f and Forge.canSmelt(f) then
		table.insert(ORES, { key = "Bars_" .. o.key, prod = Forge.productOf(o.key), price = math.floor(f.price * Forge.BAR_MULT + 1e-6), orePrice = f.price,
			tone = f.bar or f.color, reward = oreReward(n), stage = o.stage or 1, ik = "bar:" .. o.key, vp = "Bars_" .. o.key,
			name = Forge.productName(o.key), ore = o.key, chance = 0 })
	end
end

-- ===== константи макета (одиниці дизайну; вікно 980 × 528 як INVENTORY) =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528
local TX, TW, TH = 40, 222, 80            -- класи (під ними — Claim All)
local GX, GY, GW, GH = 288, 122, 636, 272 -- сітка
local S, GG, GCOLS, GP = 88, 19, 6, 6     -- картка, проміжок (рамки 4 px → видно ≈ 11 px), 6 у ряд, відступ
local HDR_H, HDR_GAP = 22, 6              -- заголовок рідкості
local CH_W, CH_H, CH_X, CH_Y = 104, 40, 290, 74 -- пігулки мутацій (горизонтальна прокрутка)
local CH_G = 16
local IY, IH = 404, 88                    -- картки внизу (інформація, колекція)
local GLOW_N = 16

-- ===== кольори =====
local C = Color3.fromHex
local INK = C("14161a")
local TITLE_INK = INK -- обводка й тінь заголовка й тінь іконки — чорні (#040435 скасовано користувачем)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local MUTED = C("9aa3ad")
local UNKNOWN = C("8b939c")
local RING = C("c8ff6a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local LIME = { { 0, "eaff9a" }, { 0.5, "c3f04a" }, { 1, "8ccc22" } }
local TRACK = { { 0, "1a1d22" }, { 1, "353b44" } }
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local SLOT_BG = { { 0, "22262c" }, { 1, "15181c" } }
local CHECK = "✓"

-- ===== помічники (як у InventoryUI) =====
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
local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right
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
-- плавне зникнення всіх шарів: заливка, картинки, текст, обводка тексту і кожен UIStroke (інакше лишається контур); потім Destroy
local function fadeOut(root: Instance, t: number, destroy: boolean?)
	local info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local function f(o)
		if o:IsA("GuiObject") then
			local p = { BackgroundTransparency = 1 }
			if o:IsA("TextLabel") or o:IsA("TextButton") then p.TextTransparency = 1; p.TextStrokeTransparency = 1 end
			if o:IsA("ImageLabel") or o:IsA("ImageButton") then p.ImageTransparency = 1 end
			TweenService:Create(o, info, p):Play()
		elseif o:IsA("UIStroke") then
			TweenService:Create(o, info, { Transparency = 1 }):Play()
		end
	end
	f(root)
	for _, d in root:GetDescendants() do f(d) end
	if destroy then task.delay(t + 0.05, function() root:Destroy() end) end
end
local function isPress(inp: InputObject): boolean
	return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end
-- зменшує шрифт мітки, поки текст не влізе
local function fitText(t: TextLabel, maxSize: number, minSize: number)
	for sz = maxSize, minSize, -1 do
		t.TextSize = sz
		if t.TextFits then return end
	end
end
-- картка-підкладка (як картка предмета в INVENTORY): напівпрозорий темний градієнт + контур
local function cardBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.4) }) }, f)
	stroke(f, INK, 3)
	return f
end

-- квадратне вікно зі studs (як Forge / Inventory). Повертає (window, вміст)
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

-- кнопка-група «стиль A»: тінь, основа, іконка й напис в одному Frame — наведення / натискання масштабують, а хитання
-- (недоступна кнопка, b.enabled = false) зсуває всю групу: тінь, іконка, напис і лічильник не відстають від кнопки.
-- Іконку й напис кладемо в b.group (ZIndex 4–5, над основою 2 і тінню 1). opt: name, shadowDy, color, z, shine, icon, iconPad.
local function shakeGroup(grp: GuiObject)
	StyleA.deny() -- звук відмови (tap цього кліку скасовується)
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
		shine = opt.shine, zIndex = 2, icon = opt.icon, iconPad = opt.iconPad })
	b.root.Name = "Button"
	b.scale = gs -- StyleA.bind масштабує групу, а не лише основу
	b.group = grp
	b.onClick = nil
	-- canClick завжди true: недоступну кнопку хитаємо самі — усю групу (StyleA.shake зсуває лише основу)
	StyleA.bind(b, { debounce = 0.15, hoverAlways = true, tap = opt.tap, canClick = function() return true end, onClick = function()
		if b.enabled == false then shakeGroup(grp) elseif b.onClick then b.onClick(b) end
	end })
	return b
end

-- сяйво (27.10.2026): один ImageLabel з м'якою радіальною текстурою (soft_radial256, Image 122253463048651 / Decal 92624674231424)
-- замість вкладених кіл (було видно «драбинку»). glowTable → { t = прозорість текстури }: ледь помітна підсвітка (~0,85–0,98).
local function glowTable(A, P, n) return { t = 1 - A * 0.16 } end
local function glowDisc(parent, cx, cy, rx, ry, n, z)
	local img = new("ImageLabel", { Name = "Glow", BackgroundTransparency = 1, Image = "rbxassetid://122253463048651", ImageTransparency = 1,
		Position = UDim2.fromOffset(cx - rx, cy - ry), Size = UDim2.fromOffset(rx * 2, ry * 2), ZIndex = z or 1 }, parent)
	return { img }
end
local function setGlow(list, color, tbl)
	for _, c in list do
		c.ImageColor3 = color
		c.ImageTransparency = tbl and tbl.t or 1
	end
end
local GLOW_ITEM = glowTable(0.85, 0.9)
local GLOW_EMPTY = glowTable(0.16, 1.4)
local GLOW_INFO = glowTable(0.7, 1.3)
local CHIP_N = 10
local GLOW_CHIP_ON = glowTable(0.53, 1.05, CHIP_N)
local GLOW_CHIP_OFF = glowTable(0.53 * 0.25, 1.05, CHIP_N)

-- наведення на слот / пігулку — той самий звук, що на кнопках і картках (ButtonHover); натискання без StyleA.bind — tap
local function slotHoverSound() UISounds.play("hover", 0.05) end
local function tapSound() UISounds.play("tap", 0.08) end -- minGap як у StyleA.tap: один клік — один tap

-- ===== числа й тексти (як у макеті) =====
local function trimNum(x: number, d: number): string
	local s = string.format("%." .. d .. "f", x)
	if d > 0 then s = (s:gsub("0+$", "")); s = (s:gsub("%.$", "")) end
	return s
end
local function fmt(n: number): string
	if n < 1000 and n ~= math.floor(n) then return Catalog.num(n) end -- дрібна шкода мутації: 2.4
	local s = string.format("%d", math.floor(n + 0.5))
	local out = (s:reverse():gsub("(%d%d%d)", "%1,")):reverse()
	if string.sub(out, 1, 1) == "," then out = string.sub(out, 2) end
	return out
end
local UNITS = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
local function short(n: number): string
	for _, u in UNITS do
		if n >= u[1] then
			local x = n / u[1]
			local s = x >= 100 and trimNum(math.floor(x + 0.5), 0) or x >= 10 and trimNum(math.floor(x * 10 + 0.5) / 10, 1)
				or trimNum(math.floor(x * 100 + 0.5) / 100, 2)
			return s .. u[2]
		end
	end
	return fmt(n)
end
local function spd(v: number): string return "x" .. trimNum(math.floor(v * 100 + 0.5) / 100, 2) end -- як GolemCatalog.statText: 1.125 → x1.13
local function money(v: number): string
	if v == 0 then return "FREE" end
	return "$" .. (v >= 1e5 and short(v) or fmt(v))
end

-- шанс «1 in N»: Normal — не мутація, а стандарт: базовий шанс голема з каталогу (Wooden 1 in 1, Stone 1 in 10, Clay 1 in 15…);
-- сторінка мутації — базовий шанс × odds мутації (Bronze: Stone 1 in 100, Gold: Stone 1 in 400). Без удачі і без «решти» ймовірності.
local function oddsN(id: string, k: number): number
	local g = Catalog.get(id)
	local u = Catalog.MUTATIONS[k + 1]
	return math.max(1, g and g.odds or 1) * ((k == 0 or not u) and 1 or math.max(1, u.odds))
end
local function oddsTxt(id: string, k: number): string
	local N = oddsN(id, k)
	if N < 10 then return "1 in " .. trimNum(math.floor(N * 100 + 0.5) / 100, 2) end
	if N < 100 then return "1 in " .. trimNum(math.floor(N * 10 + 0.5) / 10, 1) end
	if N < 10000 then return "1 in " .. fmt(N) end
	return "1 in " .. short(N)
end
local function pct(v: number): string return trimNum(math.floor(v * 10 + 0.5) / 10, 1) .. "%" end

local function font(hex: string, t: string): string return '<font color="#' .. hex .. '">' .. t .. "</font>" end
-- назви мутацій (пігулки, картка) з 26.10.2026 — Shared/MutationText (градієнт з анімацією); старі RAINBOW / rainbow / mutRich
-- (RichText по літерах) прибрано — скрипт біля ліміту 200 локальних змінних верхнього рівня.
local function L(t) return font("9aa3ad", t) end
local function statRich(id: string, cls: string, k: number): string
	local s = Catalog.stats(id, cls, k)
	-- 04.11.2026: ексклюзив — сила залежить від найкращого голема гравця, тож пишемо «65% BEST», а не стати
	local bt = Catalog.bestText and Catalog.bestText(id, cls)
	if bt then return font("ffd23a", bt) .. " · " .. L("Speed") .. " " .. spd(s.speed) end
	if cls == "carrier" then return L("Capacity") .. " " .. s.cap .. " · " .. L("Speed") .. " " .. spd(s.speed) .. " · " .. money(s.price) end
	if cls == "warrior" then
		return L("Damage") .. " " .. fmt(s.dmg) .. " · " .. L("HP") .. " " .. short(s.hp) .. " · " .. L("Speed") .. " " .. spd(s.speed) .. " · " .. money(s.price)
	end
	return L("Damage") .. " " .. fmt(s.dmg) .. " · " .. L("Speed") .. " " .. spd(s.speed) .. " · " .. money(s.price)
end

-- =====================================================================
-- ===== дані =====
-- =====================================================================
local found, claimed = {}, {}
local function keyOf(id: string, cls: string, k: number): string return id .. ":" .. cls .. ":" .. k end
local function oreKey(key: string): string return "ore:" .. key end
local ORE_BY_KEY = {}
for _, o in ORES do ORE_BY_KEY[o.key] = o; ORE_BY_KEY[o.ik] = o end
local function decodeAttr(attr: string): { any }
	local v = player:GetAttribute(attr)
	if type(v) ~= "string" or v == "" then return {} end
	local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
	return ok and type(t) == "table" and t or {}
end
local function readData()
	found, claimed = {}, {}
	for _, k in decodeAttr("IndexFound") do if type(k) == "string" then found[k] = true end end
	for _, k in decodeAttr("IndexClaimed") do if type(k) == "string" then claimed[k] = true end end
end
-- відкритий, але ще не забраний запис
local function claimable(k: string): boolean return found[k] == true and not claimed[k] end
-- нагорода за запис: голем — за мутацією (REWARD), руда — oreReward(n)
local function rewardOf(k: string): number
	if string.sub(k, 1, 4) == "ore:" or string.sub(k, 1, 4) == "bar:" then
		local o = ORE_BY_KEY[k]
		return o and o.reward or 0
	end
	local g = Catalog.get(string.match(k, "^(%w+):"))
	if g and g.rarity == "Exclusive" then return Catalog.EXCLUSIVE_INDEX_REWARD or 100 end -- ексклюзив — 100 (03.11.2026)
	return REWARD[(tonumber(string.match(k, ":(%d+)$")) or 0) + 1] or 0
end
local function pageCount(cls: string, k: number): number
	local n = 0
	for _, g in GOLEMS do if found[keyOf(g.id, cls, k)] then n += 1 end end
	if k == 0 then for _, id in Catalog.exclusivesFor(cls) do if found[keyOf(id, cls, 0)] then n += 1 end end end
	return n
end
local function classCount(cls: string): number
	local n = 0
	for k = 0, NMUT - 1 do n += pageCount(cls, k) end
	return n
end
-- скільки записів сторінки / класу можна забрати
local function pageClaim(cls: string, k: number): number
	local n = 0
	for _, g in GOLEMS do if claimable(keyOf(g.id, cls, k)) then n += 1 end end
	if k == 0 then for _, id in Catalog.exclusivesFor(cls) do if claimable(keyOf(id, cls, 0)) then n += 1 end end end
	return n
end
local function classClaim(cls: string): number
	local n = 0
	for k = 0, NMUT - 1 do n += pageClaim(cls, k) end
	return n
end
-- відкрито големів і забрано діамантів за големів
local function totals(): (number, number)
	local n, d = 0, 0
	for _, c in CLS do
		for k = 0, NMUT - 1 do
			for _, g in GOLEMS do
				local key = keyOf(g.id, c[1], k)
				if found[key] then n += 1 end
				if claimed[key] then d += REWARD[k + 1] end
			end
		end
		for _, id in Catalog.exclusivesFor(c[1]) do -- ексклюзиви: лише Normal, нагорода — Catalog.EXCLUSIVE_INDEX_REWARD
			local key = keyOf(id, c[1], 0)
			if found[key] then n += 1 end
			if claimed[key] then d += Catalog.EXCLUSIVE_INDEX_REWARD or 100 end
		end
	end
	return n, d
end
-- відкрито руди, забрано діамантів за руду, можна забрати
-- raw: true — лише руда, false — лише оброблена, nil — усе; 4-й результат — скільки всього записів
local function oreCount(raw: boolean?): (number, number, number, number)
	local n, d, c, t = 0, 0, 0, 0
	for _, o in ORES do
		if raw ~= nil and (o.prod == nil) ~= raw then continue end
		t += 1
		local k = o.ik
		if found[k] then n += 1 end
		if claimed[k] then d += o.reward end
		if claimable(k) then c += 1 end
	end
	return n, d, c, t
end
-- усі незабрані: кількість і діаманти
local function pendingAll(): (number, number)
	local n, d = 0, 0
	for k in found do if not claimed[k] then n += 1; d += rewardOf(k) end end
	return n, d
end

-- =====================================================================
-- ===== вікно INDEX =====
-- =====================================================================
local gui = new("ScreenGui", { Name = "IndexWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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

-- заголовок INDEX (синій перелив + відблиск, як INVENTORY) і X
-- іконка книжки зліва від тексту (спільна домовленість вікон): ≈ 2 × висоти літер (96 · 0,7 ≈ 67 → 132), нахил −8°, текст зсунуто
-- праворуч; тінь іконки (+7 вниз), обводка й тінь тексту — чорні (INK), як до v6
local TITLE_ICON = 132
local TI_CX, TI_CY = WX + 26 + TITLE_ICON / 2, WY - 6
new("ImageLabel", { Name = "TitleIconShadow", BackgroundTransparency = 1, Image = ICON.book, ImageColor3 = TITLE_INK, ScaleType = Enum.ScaleType.Fit,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TI_CX, TI_CY + 7), Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON), Rotation = -8, ZIndex = 3 }, pop)
new("ImageLabel", { Name = "TitleIcon", BackgroundTransparency = 1, Image = ICON.book, ScaleType = Enum.ScaleType.Fit, Rotation = -8,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TI_CX, TI_CY), Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON), ZIndex = 4 }, pop)
local TITLE_X = WX + 26 + TITLE_ICON + 2
local titleShadow = textAt(pop, TITLE_X, WY - 8 + 7, 300, 96, "INDEX", TITLE_INK, 9, { TextXAlignment = LEFT, ZIndex = 3 })
local title = textAt(pop, TITLE_X, WY - 8, 300, 96, "INDEX", WHITE, 8, { TextXAlignment = LEFT, ZIndex = 4 })
for _, t in { titleShadow, title } do t:FindFirstChildOfClass("UIStroke").Color = TITLE_INK end
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local titleShine = textAt(pop, TITLE_X, WY - 8, 300, 96, "INDEX", WHITE, 0, { TextXAlignment = LEFT, ZIndex = 5 })
local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
do
	local P = { C("e6f6ff"), C("7fd0ff"), C("1c7fd8"), C("7fd0ff") }
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

-- ===== стан =====
local section = "golems"
local cls = "miner"
local mut = 0
local sel = nil    -- вибраний голем (id); nil — нічого не вибрано, картки внизу немає
local selOre = nil -- вибрана руда (Key)
local isOpen = false
local render, renderGrid, renderInfo -- нижче

-- червоний лічильник незабраних нагород (центр у x, y; ширина росте з числом)
local BADGE_RED = C("ff3b4f")
-- кружок без UIStroke (UIStroke на круглому Frame малює темний квадрат під кругом): темне коло-обвідка + червоне коло всередині,
-- кожен шар — UICorner 0,5; квадратної тіні / рамки під кругом немає
local function makeBadge(parent, x, y, z, sz)
	sz = sz or 26
	z = z or 20
	local f = frame(parent, x, y, sz, sz, INK, { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Visible = false })
	corner(f, UDim.new(0.5, 0))
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = BADGE_RED, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -5, 1, -5), ZIndex = z }, f)
	corner(fill, UDim.new(0.5, 0))
	local t = label(fill, 0, 0, sz, sz, math.floor(sz * 0.58 + 0.5), "", WHITE, 1.6, { Size = UDim2.fromScale(1, 1), ZIndex = z + 1 })
	return { f = f, t = t, sz = sz }
end
local function setBadge(b, n: number)
	if not b then return end
	b.f.Visible = n > 0
	if n <= 0 then return end
	local s = n > 99 and "99+" or tostring(n)
	b.t.Text = s
	b.f.Size = UDim2.fromOffset(math.max(b.sz, math.floor(b.sz * 0.46 + #s * b.sz * 0.35)), b.sz)
end

-- ===== розділи вгорі: Golems / Ores / Bosses =====
local SECT = { { "golems", "Golems", ICON.golems }, { "ores", "Resources", ICON.ores }, { "bosses", "Bosses", ICON.bosses } }
local sectBtns, sectBadges = {}, {}
local SECT_X, SECT_W, SECT_H = 465, 140, 44 -- праворуч від заголовка з іконкою (не накладаються), ліворуч від X
-- іконка в «safe area»: відступ ≈ 10 % висоти кнопки з усіх боків, по центру по вертикалі, не виходить за рамку
local function safeIcon(parent, image, h, x)
	local pad = math.max(4, math.floor(h * 0.1 + 0.5))
	local s = h - 2 * pad
	new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(x or pad + 2, pad),
		Size = UDim2.fromOffset(s, s), ZIndex = 4 }, parent)
	return (x or pad + 2) + s
end
for i, spec in SECT do
	local b = makeGroupButton(content, SECT_X + (i - 1) * (SECT_W + 10), 20, SECT_W, SECT_H, { name = "Sect_" .. spec[1], shadowDy = 5, color = "gray", z = 6, shine = false })
	b.onClick = function() if section ~= spec[1] then section = spec[1]; render(true) end end
	local ix = safeIcon(b.group, spec[3], SECT_H, 6) + 6
	-- напис вписується в кнопку (Resources довший за інші): TextScaled з максимумом 22 (TextFits до першого кадру не працює)
	local st = textAt(b.group, ix, SECT_H / 2 - 1, SECT_W - ix - 10, 22, spec[2], WHITE, 2.4, { TextXAlignment = LEFT, ZIndex = 5, TextScaled = true })
	new("UITextSizeConstraint", { MaxTextSize = 22, MinTextSize = 12 }, st)
	sectBtns[spec[1]] = b
	sectBadges[spec[1]] = makeBadge(b.group, SECT_W - 6, 2, 8)
end

-- ===== вкладки ліворуч (класи големів; мапа руди): тримач рухається, група масштабується разом з тінню =====
local function tabY(i: number) return 66 + (i - 1) * (TH + 12) end
local function makeTab(name, i, icon, text)
	local hold = frame(content, TX, tabY(i), TW, TH + 8, nil, { Name = name, BackgroundTransparency = 1, ZIndex = 4 })
	local b = makeGroupButton(hold, 0, 0, TW, TH, { shadowDy = 7, color = "gray", z = 1, shine = false })
	local ix = safeIcon(b.group, icon, TH, 10) + 8
	textAt(b.group, ix, 28, TW - ix - 8, 24, text, WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 5 })
	local c = textAt(b.group, ix, 52, TW - ix - 8, 15, "", SUB_TXT, 2, { TextXAlignment = LEFT, FontFace = XBOLD, ZIndex = 5 })
	return { hold = hold, b = b, c = c, i = i, badge = makeBadge(b.group, TW - 8, 6, 8) }
end
local clsTabs = {}
for i, spec in CLS do
	local k = spec[1]
	local t = makeTab("Class_" .. k, i, ICON[k], spec[2])
	t.b.onClick = function() if cls ~= k then cls = k; render(true) end end
	clsTabs[k] = t
end
-- вкладки мап (розділ Ores, 03.11.2026): 6 низьких кнопок «Map N» + «x / 3», вибрана — синя
-- одна вкладка «All Maps» (руда всіх мап — одним списком справа, мапи відділені заголовками-плашками)
-- розділ Resources (03.11.2026): дві вкладки — Raw Ores (руда) і Crafted (злитки й ограновані кристали з Workshop); OM.raw — вибрана перша
OM.raw = true
OM.tab = makeTab("Raw", 1, ICON.ores, "Raw Ores")
OM.tab2 = makeTab("Crafted", 2, StyleA.ASSETS.forge_bar_iron_v2 or ICON.ores, "Crafted")
OM.tabs[1] = OM.tab
OM.tabs[2] = OM.tab2
for _, t in OM.tabs do t.hold.Visible = false end

-- ===== колекція ліворуч унизу: загальний прогрес і забрані діаманти =====
local coll = cardBg(content, TX, IY, TW, IH, 3)
local collTitle = textAt(coll, 12, 17, 200, 17, "All Golems", WHITE, 2, { TextXAlignment = LEFT, ZIndex = 2 })
local collBar = frame(coll, 12, 30, 198, 24, WHITE, { ZIndex = 2, ClipsDescendants = true })
vgrad(collBar, { { 0, "1a1d22" }, { 1, "2a2f36" } }); stroke(collBar, INK, 3)
local collFill = frame(collBar, 0, 0, 10, 24, WHITE, { ZIndex = 1 }); vgrad(collFill, LIME)
local collTxt = textAt(collBar, 0, 12, 198, 16, "", WHITE, 2, { ZIndex = 3 })
local collIcon = new("ImageLabel", { BackgroundTransparency = 1, Image = ICON.diamond, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(12, 61),
	Size = UDim2.fromOffset(20, 22), ZIndex = 2 }, coll)
local collD = textAt(coll, 38, 72, 176, 16, "", WHITE, 2, { TextXAlignment = LEFT, FontFace = XBOLD, RichText = true, ZIndex = 2 })

-- ===== мутації (ряд пігулок над сіткою) =====
-- горизонтальний ScrollingFrame: гортається колесом, перетягуванням (миша — нижче, дотик — сам) і тоненьким повзунком (4 px)
local CH_PAD = 6
local CH_VW = GW + 18
local CH_CW = CH_PAD * 2 + NMUT * CH_W + (NMUT - 1) * CH_G
local chipSF = new("ScrollingFrame", { Name = "Mutations", Position = UDim2.fromOffset(GX - 4, CH_Y - 5), Size = UDim2.fromOffset(CH_VW, CH_H + 13),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.fromOffset(CH_CW, 0),
	ScrollBarThickness = 4, ScrollBarImageColor3 = C("c8ff6a"), ScrollBarImageTransparency = 0.25, HorizontalScrollBarInset = Enum.ScrollBarInset.None,
	VerticalScrollBarInset = Enum.ScrollBarInset.None, ElasticBehavior = Enum.ElasticBehavior.Never, ZIndex = 4 }, content)
local chipDrag, chipDragEnd = nil, -1
local function chipMax(): number return math.max(0, CH_CW - CH_VW) end
-- CanvasPosition — у пікселях екрана (з UIScale), рахуємо в одиницях макета
local function chipK(): number return chipSF.AbsoluteSize.X > 0 and chipSF.AbsoluteSize.X / CH_VW or 1 end
local function chipPos(): number return chipSF.CanvasPosition.X / chipK() end
local function chipScrollTo(x: number, animate: boolean?)
	x = math.clamp(x, 0, chipMax())
	local v = Vector2.new(x * chipK(), 0)
	if animate then tween(chipSF, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { CanvasPosition = v })
	else chipSF.CanvasPosition = v end
end
-- колесо миші гортає ряд вбік (сам ScrollingFrame з напрямком X колесо не бере)
local function chipWheel(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseWheel then chipScrollTo(chipPos() - inp.Position.Z * 80) end
end
chipSF.InputChanged:Connect(chipWheel)
-- вибрана пігулка — у видимій частині ряду
local function chipShow(k: number, animate: boolean?)
	local x0 = CH_PAD + k * (CH_W + CH_G)
	local cp = chipPos()
	if x0 - CH_PAD < cp then chipScrollTo(x0 - CH_PAD, animate)
	elseif x0 + CH_W + CH_PAD > cp + CH_VW then chipScrollTo(x0 + CH_W + CH_PAD - CH_VW, animate) end
end
local function chipBegin(inp: InputObject)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then chipDrag = { x = inp.Position.X, c = chipPos(), moved = false } end
end
chipSF.InputBegan:Connect(chipBegin)
UIS.InputChanged:Connect(function(inp)
	if not chipDrag or inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	local dx = (inp.Position.X - chipDrag.x) / chipK()
	if math.abs(dx) > 6 then chipDrag.moved = true end
	if chipDrag.moved then chipScrollTo(chipDrag.c - dx) end
end)
UIS.InputEnded:Connect(function(inp)
	if chipDrag and inp.UserInputType == Enum.UserInputType.MouseButton1 then
		if chipDrag.moved then chipDragEnd = os.clock() end
		chipDrag = nil
	end
end)
local chips = {}
for i, u in Catalog.MUTATIONS do
	local k = i - 1
	local root = frame(chipSF, CH_PAD + k * (CH_W + CH_G), 5, CH_W, CH_H, nil, { Name = "Mut_" .. u.key, BackgroundTransparency = 1, ZIndex = 4 })
	local sc = new("UIScale", {}, root)
	frame(root, 0, 3, CH_W, CH_H, BLACK, { BackgroundTransparency = 0.7, ZIndex = 1 })
	local bg = frame(root, 0, 0, CH_W, CH_H, WHITE, { ZIndex = 2 }); vgrad(bg, SLOT_BG); stroke(bg, INK, 3)
	local inner = frame(root, 2, 2, CH_W - 4, CH_H - 4, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	stroke(inner, u.color, 2, 0.67)
	local clip = frame(root, 2, 2, CH_W - 4, CH_H - 4, nil, { BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 })
	local glow = glowDisc(clip, (CH_W - 4) / 2, (CH_H - 4) / 2, (CH_W - 4) * 0.53, (CH_H - 4) * 0.53, CHIP_N, 1)
	local nm = textAt(root, 4, 14, CH_W - 8, 15, u.key, u.color, 1.8, { ZIndex = 6 })
	fitText(nm, 15, 11)
	MutationText.apply(nm, k) -- свій градієнт кожної мутації (Normal — суцільний білий)
	local ct = textAt(root, 0, 29, CH_W, 12, "", MUTED, 1.6, { FontFace = XBOLD, ZIndex = 6 })
	local ring = frame(root, -1, -1, CH_W + 2, CH_H + 2, nil, { BackgroundTransparency = 1, ZIndex = 7, Visible = false })
	stroke(ring, RING, 4)
	local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, root)
	hit:SetAttribute("NoHoverSound", true)
	hit.MouseEnter:Connect(function()
		if isOpen then slotHoverSound() end
		tween(sc, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 })
	end)
	hit.MouseLeave:Connect(function() tween(sc, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 }) end)
	hit.InputBegan:Connect(chipBegin)
	hit.InputChanged:Connect(chipWheel)
	hit.Activated:Connect(function()
		if (chipDrag and chipDrag.moved) or os.clock() - chipDragEnd < 0.15 then return end
		tapSound()
		if mut ~= k then mut = k; render(true); chipShow(k, true) end
	end)
	-- лічильник — усередині пігулки справа (не на рамці); з ним напис зсувається ліворуч
	chips[i] = { root = root, glow = glow, nm = nm, ct = ct, ring = ring, color = u.color, badge = makeBadge(root, CH_W - 16, CH_H / 2, 12, 20) }
end

-- ===== Claim All — у вікні, ліворуч під вкладками (не виходить за екран на 4:3 / iPad): забрати всі незабрані нагороди =====
local CA_X, CA_Y, CA_W, CA_H = TX, 346, TW, 48
local claimAllBtn = makeGroupButton(content, CA_X, CA_Y, CA_W, CA_H, { name = "ClaimAll", shadowDy = 5, color = "gray", z = 6, tap = false }) -- звук — лише claim (без tap)
local caRow = frame(claimAllBtn.group, 0, 8, CA_W, 28, nil, { BackgroundTransparency = 1, ZIndex = 5 })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, caRow)
label(caRow, 0, 0, 0, 28, 22, "Claim All", WHITE, 2.4, { LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 5 })
local caIcon = new("ImageLabel", { LayoutOrder = 2, BackgroundTransparency = 1, Image = ICON.diamond, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(19, 24), ZIndex = 5 }, caRow)
local caTx = label(caRow, 0, 0, 0, 28, 22, "+0", WHITE, 2.4, { LayoutOrder = 3, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 5 })

-- ===== сітка зі смугою прокрутки (групи за рідкістю) =====
-- висота: GH — коли внизу картка вибраного запису; GH_FULL — нічого не вибрано, сітка займає місце картки
local GH_FULL = IY + IH - GY
local gh = GH_FULL
local gvp = frame(content, GX, GY, GW, gh, nil, { Name = "Grid", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 2 })
local gstrip = frame(gvp, 0, 0, GW, 10, nil, { Name = "Strip", BackgroundTransparency = 1, ZIndex = 1 })
local vsb = frame(content, GX + GW + 3, GY + GP, 10, gh - 2 * GP, WHITE, { Active = true, ZIndex = 3 })
new("UIGradient", { Color = cseq(TRACK), Rotation = 0 }, vsb); stroke(vsb, INK, 3)
local vth = frame(vsb, 0, 0, 10, 60, WHITE, { Active = true, ZIndex = 2 }); vgrad(vth, LIME)
local gscroll, gH = 0, 0
local function gmax() return math.max(0, gH - gh) end
local function setG(v: number)
	gscroll = math.clamp(v, 0, gmax())
	gstrip.Position = UDim2.fromOffset(0, -gscroll)
	local th = math.max(40, (gh - 2 * GP) * gh / math.max(gh, gH))
	vth.Size = UDim2.fromOffset(10, th)
	vth.Position = UDim2.fromOffset(0, gmax() > 0 and gscroll / gmax() * (gh - 2 * GP - th) or 0)
	vsb.Visible = gmax() > 0 and section == "golems"
end
local function setGridH(h: number)
	gh = h
	gvp.Size = UDim2.fromOffset(GW, h)
	vsb.Size = UDim2.fromOffset(10, h - 2 * GP)
	-- прокрутку чіпаємо лише коли треба обмежити; інакше — тільки бігунок (не збиває анімацію вмісту сітки)
	if gscroll > gmax() then setG(gscroll) return end
	local th = math.max(40, (gh - 2 * GP) * gh / math.max(gh, gH))
	vth.Size = UDim2.fromOffset(10, th)
	vth.Position = UDim2.fromOffset(0, gmax() > 0 and gscroll / gmax() * (gh - 2 * GP - th) or 0)
	vsb.Visible = gmax() > 0 and section == "golems"
end
local drag, dragEndAt = nil, -1
local function unitsPerPx() local a = gvp.AbsoluteSize.Y return a > 0 and gh / a or 1 end
local function beginDrag(inp, thumb) if isPress(inp) then drag = { y = inp.Position.Y, s = gscroll, moved = false, thumb = thumb } end end
local function wheel(inp) if inp.UserInputType == Enum.UserInputType.MouseWheel and gmax() > 0 then setG(gscroll - inp.Position.Z * 70) end end
local function slotIsDragging() return (drag ~= nil and drag.moved) or os.clock() - dragEndAt < 0.15 end
gvp.InputBegan:Connect(function(inp) beginDrag(inp, false) end)
gvp.InputChanged:Connect(wheel)
vth.InputBegan:Connect(function(inp) beginDrag(inp, true) end)
UIS.InputChanged:Connect(function(inp)
	if not drag or not (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) or gmax() <= 0 then return end
	local dy = (inp.Position.Y - drag.y) * unitsPerPx()
	if drag.thumb then setG(drag.s + dy * gmax() / math.max(1, gh - 2 * GP - vth.Size.Y.Offset))
	else
		if math.abs(dy) > 6 then drag.moved = true end
		if drag.moved then setG(drag.s - dy) end
	end
end)
UIS.InputEnded:Connect(function(inp)
	if isPress(inp) and drag then if drag.moved then dragEndAt = os.clock() end drag = nil end
end)

-- ===== наведення карток (×1,025, нахил до 1,5°, натискання 0,96 — як слоти інвентаря) =====
local hoverSet = {}
local hoverConn = nil
local function hoverStep(dt: number)
	local a = 1 - math.exp(-14 * dt)
	for s in hoverSet do
		local ts = s.down and 0.96 or (s.hover and 1.025 or 1)
		local tr = (s.hover and not s.down) and s.rel * 1.5 or 0
		s.sc += (ts - s.sc) * a
		s.rot += (tr - s.rot) * a
		if not s.hover and not s.down and math.abs(s.sc - 1) < 0.0005 and math.abs(s.rot) < 0.02 then
			s.sc, s.rot = 1, 0
			hoverSet[s] = nil
		end
		s.scale.Scale = s.sc
		s.card.Rotation = s.rot
	end
	if next(hoverSet) == nil and hoverConn then hoverConn:Disconnect(); hoverConn = nil end
end
local function wakeHover(s)
	if s.fxSync then s.fxSync() end -- фон мутації сторінки на наведеній / вибраній картці
	hoverSet[s] = true
	if not hoverConn then hoverConn = RunService.RenderStepped:Connect(hoverStep) end
end

-- ===== картка (слот «C · Сяйво» з інвентаря), розмір sz (за замовчуванням S; написи масштабуються разом) =====
-- makeCard(parent, x, y, name, scroll, sz) → s; s.set(d): d = { found, claim, sel, tone, name, icon, vp, odds }.
--   claim — нагорода (число), якщо запис відкритий, але ще не забраний: слот затемнений, поверх — діамант «+N» і кнопка Claim.
-- s.onClick(s) — клік по картці (не після перетягування); s.onClaim(s) — кнопка Claim. scroll = true — картка в сітці, що гортається.
local function makeCard(parent, x, y, name, scroll, sz)
	local S = sz or S
	local k = S / 95
	local P = 16
	local holder = new("Frame", { Name = name, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(S + 2 * P, S + 2 * P),
		Position = UDim2.fromOffset(x + S / 2, y + S / 2), ZIndex = 2 }, parent)
	local scale = new("UIScale", {}, holder)
	local card = frame(holder, 0, 0, S + 2 * P, S + 2 * P, nil, { Name = "Card", BackgroundTransparency = 1, ZIndex = 1 })
	frame(card, P, P + math.floor(S * 0.04 + 0.5), S, S, BLACK, { BackgroundTransparency = 0.7, ZIndex = 1 })
	local bg = frame(card, P, P, S, S, WHITE, { ZIndex = 2 })
	vgrad(bg, SLOT_BG); stroke(bg, INK, 4)
	local tone = frame(card, P + 3, P + 3, S - 6, S - 6, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local toneStroke = stroke(tone, WHITE, 3, 0.94)
	local glow = glowDisc(card, P + S / 2, P + S / 2, S * 0.5, S * 0.5, GLOW_N, 3)
	-- фон за мутацією сторінки (Shared/MutationSlotFX) — на наведеній і вибраній відкритій картці голема (не для руди);
	-- require тут, а не вгорі — скрипт біля ліміту 200 локальних верхнього рівня
	local mfx = require(Shared:WaitForChild("MutationSlotFX")).new(card, { pos = Vector2.new(P, P), size = Vector2.new(S, S), z = 3 })
	local pad = S * 0.17
	local iw = S - 2 * pad
	local icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(P + pad, P + pad * 1.05),
		Size = UDim2.fromOffset(iw, iw), ZIndex = 4 }, card)
	local T1, T2 = math.floor(12 * k + 0.5), math.floor(15 * k + 0.5) -- розміри написів
	local nm = textAt(card, P + 6 * k, P + 13 * k, S - 9 * k, T1, "", WHITE, 2, { TextXAlignment = LEFT, FontFace = XBOLD, ZIndex = 5 })
	local odds = textAt(card, P, P + S - 11 * k, S - 7 * k, T1, "", WHITE, 2, { TextXAlignment = RIGHT, FontFace = XBOLD, ZIndex = 5 })
	local ring = frame(card, P - 2, P - 2, S + 4, S + 4, nil, { BackgroundTransparency = 1, ZIndex = 7, Visible = false })
	stroke(ring, RING, 4)
	-- 05.11.2026: плашка «MAP N» поверх голема з наступних мап (GolemCatalog map > Stage гравця) — де він почне випадати
	local mapTag = frame(holder, P + S / 2 - 31 * k, P + S * 0.55, 62 * k, 21 * k, WHITE, { Name = "MapTag", ZIndex = 29, Visible = false })
	vgrad(mapTag, { { 0, "ffc25a" }, { 1, "e0751c" } }); stroke(mapTag, INK, 2.5)
	local mapTx = label(mapTag, 0, 0, 62 * k, 21 * k, math.floor(14 * k + 0.5), "", WHITE, 2, { ZIndex = 29 })
	-- «можна забрати»: затемнення слота, діамант «+N», кнопка Claim (не нахиляються разом з карткою)
	local dim = frame(card, P, P, S, S, BLACK, { Name = "Dim", BackgroundTransparency = 0.42, ZIndex = 6, Visible = false })
	local rw = frame(holder, P, P + S * 0.24, S, 26 * k, nil, { Name = "Reward", BackgroundTransparency = 1, ZIndex = 32, Visible = false })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4 * k), SortOrder = Enum.SortOrder.LayoutOrder }, rw)
	new("ImageLabel", { LayoutOrder = 1, BackgroundTransparency = 1, Image = ICON.diamond, ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(17 * k, 22 * k), ZIndex = 32 }, rw)
	local rwTxt = label(rw, 0, 0, 0, 26 * k, math.floor(20 * k + 0.5), "", WHITE, 2.4, { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 32 })
	local cb = StyleA.new(holder, { size = Vector2.new(S - 18 * k, 30 * k), position = Vector2.new(P + 9 * k, P + S - 40 * k), anchor = Vector2.new(0.5, 0.5),
		color = "green", text = "Claim", textSize = math.floor(15 * k + 0.5), clickable = true, shine = false, zIndex = 33, name = "Claim" })
	cb.root.Visible = false
	local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(P, P),
		Size = UDim2.fromOffset(S, S), ZIndex = 30 }, holder)
	hit:SetAttribute("NoHoverSound", true)
	local s = { holder = holder, card = card, scale = scale, sc = 1, rot = 0, rel = 0, hover = false, down = false, onClick = nil, onClaim = nil, y = y, S = S, P = P,
		cb = cb.root }
	StyleA.bind(cb, { debounce = 0.2, tap = false, onClick = function() if s.onClaim then s.onClaim(s) end end }) -- звук — лише claim
	function s.set(d)
		setGlow(glow, d.found and d.tone or WHITE, d.found and GLOW_ITEM or GLOW_EMPTY)
		toneStroke.Color = d.found and d.tone or WHITE
		toneStroke.Transparency = d.found and 0.67 or 0.94
		icon.Image = d.icon
		ItemVP.set(icon, d.vp) -- 3D-модель, якщо є
		icon.ImageColor3 = d.found and WHITE or BLACK -- невідкрите — чорний силует
		icon.ImageTransparency = d.found and 0 or 0.5
		if d.found then
			nm.Text = d.name; nm.FontFace = XBOLD; nm.TextColor3 = WHITE
			fitText(nm, T1, 9)
		else
			nm.Text = "???"; nm.FontFace = HEAVY; nm.TextColor3 = UNKNOWN; nm.TextSize = T2
		end
		odds.Text = d.odds
		odds.TextColor3 = d.found and d.tone or UNKNOWN
		fitText(odds, T1, 9)
		local can = d.claim ~= nil
		dim.Visible = can; rw.Visible = can; cb.root.Visible = can
		if can then rwTxt.Text = "+" .. d.claim end
		ring.Visible = d.sel == true
		mapTag.Visible = d.map ~= nil
		if d.map then mapTx.Text = "MAP " .. d.map end
		holder.ZIndex = d.sel and 5 or 2
		mfx.setMut((d.found and d.mut) or nil)
		s.sel = d.sel == true
		s.fxSync()
	end
	function s.fxSync() mfx.setOn(s.hover or s.sel) end
	-- Claim: оверлей (затемнення, «+N», кнопка) плавно зникає всіма шарами — копія поверх, оригінал ховає set()
	function s.fadeClaim()
		if not dim.Visible then return end
		for _, o in { dim, rw, cb.root } do
			local c = o:Clone()
			c.Parent = o.Parent
			fadeOut(c, 0.3, true)
		end
	end
	-- «+N» злітає вгору й повністю зникає (текст і його обводка)
	function s.toast(text: string)
		local t = textAt(holder, 0, P + S * 0.45, S + 2 * P, math.floor(24 * k + 0.5), text, C("7fd0ff"), 2.6, { ZIndex = 40 })
		tween(t, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 28 * k) })
		fadeOut(t, 0.8, true)
	end
	local function aim(px: number)
		local c = holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2
		s.rel = math.clamp((px - c) / math.max(1, hit.AbsoluteSize.X / 2), -1, 1)
	end
	hit.MouseEnter:Connect(function(px)
		if not isOpen then return end
		if not s.inside then s.inside = true; slotHoverSound() end -- звук раз на вхід (MouseMoved може прийти раніше за MouseEnter)
		s.hover = true; aim(px); wakeHover(s)
	end)
	hit.MouseMoved:Connect(function(px) if not isOpen then return end s.hover = true; aim(px); wakeHover(s) end)
	hit.MouseLeave:Connect(function() s.inside = false; s.hover = false; s.down = false; wakeHover(s) end)
	hit.InputBegan:Connect(function(inp)
		if isPress(inp) then s.down = true; wakeHover(s); if scroll then beginDrag(inp, false) end end
	end)
	hit.InputEnded:Connect(function(inp) if isPress(inp) then s.down = false; wakeHover(s) end end)
	if scroll then hit.InputChanged:Connect(wheel); cb.root.InputChanged:Connect(wheel) end
	hit.Activated:Connect(function()
		if scroll and slotIsDragging() then return end
		tapSound()
		if s.onClick then s.onClick(s) end
	end)
	return s
end

-- заголовок групи: смуга кольору, назва, «n / всього»
local HW = GW - 2 * GP - 4
local function groupHeader(parent, y, tone, text)
	local hd = frame(parent, GP, y, HW, HDR_H, WHITE, { ZIndex = 1 })
	new("UIGradient", { Rotation = 0, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, tone), ColorSequenceKeypoint.new(0.55, INK), ColorSequenceKeypoint.new(1, INK) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.67), NumberSequenceKeypoint.new(0.55, 0.4), NumberSequenceKeypoint.new(1, 0.6) }) }, hd)
	frame(hd, 0, 0, 4, HDR_H, tone, { ZIndex = 2 })
	textAt(hd, 12, HDR_H / 2, 300, 17, text, tone, 2.1, { TextXAlignment = LEFT, ZIndex = 3 })
	return textAt(hd, HW - 212, HDR_H / 2, 200, 14, "", SUB_TXT, 2, { TextXAlignment = RIGHT, FontFace = XBOLD, ZIndex = 3 })
end

-- групи за рідкістю (будуються один раз, сторінка лише перемальовує вміст)
local groups = {}
local cards = {}
do
	local y = GP
	for _, r in Catalog.RARITIES do
		local list = {}
		for _, g in GOLEMS do if g.rarity == r then table.insert(list, g) end end
		if #list == 0 then continue end
		local cnt = groupHeader(gstrip, y, Catalog.rarityColor(r), r)
		local grp = { r = r, list = list, cnt = cnt, y = y }
		table.insert(groups, grp)
		y += HDR_H + HDR_GAP
		for i, g in list do
			local c = makeCard(gstrip, GP + ((i - 1) % GCOLS) * (S + GG), y + math.floor((i - 1) / GCOLS) * (S + GG), "Card_" .. g.id, true)
			c.group = grp
			c.g = g
			cards[g.id] = c
		end
		y += math.ceil(#list / GCOLS) * (S + GG) + 2
	end
	-- ексклюзиви — остання група, лише на сторінці Normal (висота стрічки — атрибути HAll / HNoEx
	-- самої стрічки: нові локальні верхнього рівня не додаємо — скрипт біля ліміту 200)
	gstrip:SetAttribute("HNoEx", y + GP - 2)
	local exl = {}
	for _, id in Catalog.EXCLUSIVES or {} do local g = Catalog.get(id); if g then table.insert(exl, g) end end
	if #exl > 0 then
		local grp = { r = "Exclusive", list = exl, cnt = groupHeader(gstrip, y, Catalog.rarityColor("Exclusive"), "Exclusive"), y = y, excl = true, items = {} }
		table.insert(groups, grp)
		y += HDR_H + HDR_GAP
		for i, g in exl do
			local c = makeCard(gstrip, GP + ((i - 1) % GCOLS) * (S + GG), y + math.floor((i - 1) / GCOLS) * (S + GG), "Card_" .. g.id, true)
			c.group = grp
			c.g = g
			cards[g.id] = c
			table.insert(grp.items, c)
		end
		y += math.ceil(#exl / GCOLS) * (S + GG) + 2
	end
	gH = y + GP - 2
	gstrip:SetAttribute("HAll", gH)
	gstrip.Size = UDim2.fromOffset(GW, gH)
end

-- ===== руда (розділ Ores): група «Map 1» і картки =====
-- один список, що гортається: для кожної мапи — плашка «Map N · Назва» з лічильником і 3 картки руди (03.11.2026)
local oreArea = new("ScrollingFrame", { Name = "OreGrid", Position = UDim2.fromOffset(GX, CH_Y), Size = UDim2.fromOffset(GW + 14, GY + GH_FULL - CH_Y),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 6,
	ScrollBarImageColor3 = C("c8ff6a"), ScrollBarImageTransparency = 0.25, VerticalScrollBarInset = Enum.ScrollBarInset.None,
	ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false, ZIndex = 2 }, content)
-- другий список — оброблена руда (вкладка Crafted), така сама розкладка
OM.barArea = oreArea:Clone()
OM.barArea.Name = "CraftedGrid"
OM.barArea.Parent = content
local ORE_S, ORE_G = 128, 16
local oreCards = {}
OM.cnts, OM.bcnts = {}, {}
for _, raw in { true, false } do
	local area = raw and oreArea or OM.barArea
	local y = GP
	for m = 1, #OM.names do
		local hdr = groupHeader(area, y, C(raw and "7fd0ff" or "ffb15c"), "Map " .. m .. " · " .. OM.names[m])
		if raw then OM.cnts[m] = hdr else OM.bcnts[m] = hdr end
		local j = 0
		for i, o in ORES do
			if o.stage == m and (o.prod == nil) == raw then
				j += 1
				local c = makeCard(area, GP + 4 + (j - 1) * (ORE_S + ORE_G), y + HDR_H + 10, o.vp, false, ORE_S)
				c.ore = o
				oreCards[i] = c
			end
		end
		y += HDR_H + 10 + ORE_S + ORE_G
	end
	textAt(area, 0, y + 6, GW, 17, raw and "New ores appear on the next maps" or "Smelt ore in the Workshop to discover", WHITE, 2.2, { ZIndex = 2 })
	area.CanvasSize = UDim2.fromOffset(0, y + 30)
end

-- ===== картка вибраного запису внизу =====
-- у масці InfoClip (обрізає по низу вікна): виїжджає знизу / ховається вниз, верх картки йде за низом сітки (applyCardT).
-- Схована маска невидима, щоб не забирати наведення в нижнього ряду карток сітки.
local INFO_SLIDE = GH_FULL - GH
local infoClip = frame(content, 284, IY - 6, 658, IH + 10, nil, { Name = "InfoClip", BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 })
local info = cardBg(infoClip, 6, 6, 646, IH, 3)
local infoGlow = glowDisc(info, 52, 44, 41, 41, GLOW_N, 1)
local infoIcon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(76, 76), ZIndex = 3 }, info)
local infoName = textAt(info, 104, 23, 316, 26, "", WHITE, 3, { TextXAlignment = LEFT, ZIndex = 3 })
local infoSub = textAt(info, 104, 48, 316, 15, "", SUB_TXT, 1.8, { TextXAlignment = LEFT, FontFace = XBOLD, RichText = true, ZIndex = 3 })
-- назва мутації в підписі картки — окрема мітка одразу за текстом infoSub (градієнт MutationText)
local infoMut = textAt(info, 104, 48, 120, 15, "", WHITE, 1.8, { TextXAlignment = LEFT, FontFace = XBOLD, ZIndex = 3, Visible = false })
local infoStat = textAt(info, 104, 69, 322, 13, "", SUB_TXT, 1.6, { TextXAlignment = LEFT, FontFace = XBOLD, RichText = true, ZIndex = 3 })
local oddsBox = frame(info, 432, 8, 202, 72, WHITE, { ZIndex = 3 })
vgrad(oddsBox, { { 0, "1c1f24" }, { 1, "121418" } }); stroke(oddsBox, INK, 3)
stroke(frame(oddsBox, 2, 2, 198, 68, nil, { BackgroundTransparency = 1, ZIndex = 1 }), WHITE, 2, 0.94)
local oddsTitle = textAt(oddsBox, 0, 13, 202, 12, "ROLL CHANCE", MUTED, 1.5, { FontFace = XBOLD, ZIndex = 2 })
local oddsTx = textAt(oddsBox, 0, 34, 202, 26, "", WHITE, 3, { ZIndex = 2 })
local rwRow = frame(oddsBox, 0, 50, 202, 18, nil, { BackgroundTransparency = 1, ZIndex = 2 })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, rwRow)
local rwIcon = new("ImageLabel", { LayoutOrder = 1, BackgroundTransparency = 1, Image = ICON.diamond, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(14, 18), ZIndex = 2 }, rwRow)
local rwTx = label(rwRow, 0, 0, 0, 18, 13, "", SUB_TXT, 1.6, { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, FontFace = XBOLD, RichText = true, ZIndex = 2 })

-- ===== розділ Bosses (06.11.2026): картки босів у порядку BossConfig.ROTATION, решта — «???» (наступні оновлення) =====
--   Бос переможений (атрибут гравця Stat_BossKills > 0) — кольорова картинка (IconAtlas.BOSS), назва, «Defeated: N»;
--   ще ні — чорний силует, «???», «Unlocks on Map 2». Знизу картки — що падає (зуб, діаманти).
local soon = cardBg(content, 40, 92, 896, 400, 3)
soon.Visible = false
do
	local BossCfg = require(Shared:WaitForChild("BossConfig"))
	local Loc = require(Shared:WaitForChild("Loc"))
	local okA, Atlas = pcall(require, Shared:WaitForChild("IconAtlas"))
	textAt(soon, 0, 40, 896, 34, "Bosses", WHITE, 3.4, { ZIndex = 2 })
	textAt(soon, 0, 376, 896, 17, "Defeat bosses to fill the Index", SUB_TXT, 1.9, { FontFace = XBOLD, ZIndex = 2 })
	local CW, CH, GAP = 250, 282, 20
	local x0 = (896 - (3 * CW + 2 * GAP)) / 2
	local cards = {}
	for i = 1, 3 do
		local id = BossCfg.ROTATION[i]
		local def = id and BossCfg.BOSSES[id]
		local r = frame(soon, x0 + (i - 1) * (CW + GAP), 70, CW, CH, WHITE, { ZIndex = 2, ClipsDescendants = true })
		vgrad(r, SLOT_BG); stroke(r, INK, 4)
		local b = okA and Atlas.BOSS
		local aid = b and Atlas.ATLAS[b[1]]
		local img
		if def and type(aid) == "string" and aid ~= "" then
			img = new("ImageLabel", { BackgroundTransparency = 1, Image = aid, ImageRectOffset = Vector2.new(b[2], b[3]), ImageRectSize = Vector2.new(b[4], b[5]),
				ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(8, 38), Size = UDim2.fromOffset(CW - 16, 176), ZIndex = 3 }, r)
		else
			img = new("ImageLabel", { BackgroundTransparency = 1, Image = ICON.bosses, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset((CW - 140) / 2, 56),
				Size = UDim2.fromOffset(140, 140), ImageColor3 = BLACK, ImageTransparency = 0.5, ZIndex = 3 }, r)
		end
		local name = textAt(r, 12, 22, CW - 24, 24, "???", UNKNOWN, 2.6, { TextXAlignment = LEFT, ZIndex = 4 })
		local info = textAt(r, 0, 232, CW, 17, def and "Not defeated yet" or "Coming soon", SUB_TXT, 1.9, { FontFace = XBOLD, ZIndex = 4 })
		if def then -- що падає
			local row = frame(r, 0, 248, CW, 26, nil, { BackgroundTransparency = 1, ZIndex = 4 })
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
			label(row, 0, 0, 0, 26, 15, "Drops", C("ffd23a"), 1.8, { LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 4 })
			new("ImageLabel", { LayoutOrder = 2, BackgroundTransparency = 1, Image = BossCfg.ICON_TOOTH, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(24, 24), ZIndex = 4 }, row)
			new("ImageLabel", { LayoutOrder = 3, BackgroundTransparency = 1, Image = BossCfg.ICON_DIAMOND, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(22, 22), ZIndex = 4 }, row)
		end
		cards[i] = { def = def, img = img, name = name, info = info }
	end
	local function refreshBosses()
		local kills = tonumber(player:GetAttribute("Stat_BossKills")) or 0
		for _, c in cards do
			if c.def then
				local open = kills > 0 -- поки один бос: будь-яка перемога — це він
				c.img.ImageColor3 = open and WHITE or BLACK
				c.img.ImageTransparency = open and 0 or 0.35
				c.name.Text = open and c.def.name or "???"
				c.name.TextColor3 = open and C("b8ff8a") or UNKNOWN
				c.info.AutoLocalize = not open
				c.info.Text = open and Loc.f("Defeated: {1}", kills) or "Not defeated yet" -- 08.11.2026: бос з мапи 1
			end
		end
	end
	refreshBosses()
	player:GetAttributeChangedSignal("Stat_BossKills"):Connect(refreshBosses)
	soon:GetPropertyChangedSignal("Visible"):Connect(function() if soon.Visible then refreshBosses() end end)
	Loc.Ready:Connect(refreshBosses)
end

-- =====================================================================
-- ===== логіка вікна =====
-- =====================================================================
local Action = nil
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 30)
	Action = r and r:WaitForChild("IndexAction", 30)
end)

-- червоний лічильник на кнопці Index у HUD (MainHUD не змінюється: значок додаємо до його кнопки звідси)
local hudBadge = nil
local function updateHud()
	local n = pendingAll()
	setBadge(hudBadge, n)
end
task.spawn(function()
	local hud = playerGui:WaitForChild("MainHUD", 60)
	for _ = 1, 60 do
		if not hud or not hud.Parent then hud = playerGui:FindFirstChild("MainHUD") end
		if hud then
			for _, d in hud:GetDescendants() do
				if d:IsA("TextLabel") and d.Name == "Label" and d.Text == "Index" and d.Parent then
					hudBadge = makeBadge(d.Parent, 0, 0, 10)
					hudBadge.f.Position = UDim2.new(1, -8, 0, 10)
					updateHud()
					return
				end
			end
		end
		task.wait(1)
	end
end)

renderGrid = function(resetScroll: boolean)
	-- ексклюзиви — лише на Normal: інакше ховаємо групу й коротшаємо стрічку
	gH = (mut == 0 and gstrip:GetAttribute("HAll")) or gstrip:GetAttribute("HNoEx") or gH
	gstrip.Size = UDim2.fromOffset(GW, gH)
	for _, grp in groups do
		local list = grp.list
		if grp.excl then
			-- 05.11.2026: лише ексклюзиви цього класу (Marketplace — один клас): картки щільно по порядку, висота стрічки — від їх кількості
			list = {}
			for _, c in grp.items do
				local on = mut == 0 and (c.g.only == nil or c.g.only == cls)
				c.holder.Visible = on
				if on then
					table.insert(list, c.g)
					local i = #list
					c.holder.Position = UDim2.fromOffset(GP + ((i - 1) % GCOLS) * (S + GG) + S / 2, grp.y + HDR_H + HDR_GAP + math.floor((i - 1) / GCOLS) * (S + GG) + S / 2)
				end
			end
			grp.cnt.Parent.Visible = mut == 0
			if mut == 0 then gH = grp.y + HDR_H + HDR_GAP + math.ceil(#list / GCOLS) * (S + GG) + GP; gstrip.Size = UDim2.fromOffset(GW, gH) end
		end
		local n = 0
		for _, g in list do if found[keyOf(g.id, cls, mut)] then n += 1 end end
		local done = n == #list
		grp.cnt.Text = (done and (CHECK .. " ") or "") .. n .. " / " .. #list
		grp.cnt.TextColor3 = done and RING or SUB_TXT
	end
	for id, c in cards do
		local g = c.g
		local k = keyOf(id, cls, mut)
		c.set({ found = found[k] == true, claim = claimable(k) and rewardOf(k) or nil, sel = sel == id, tone = Catalog.rarityColor(g.rarity),
			name = g.name, icon = Catalog.icon(id), vp = ItemVP.golemKey(id, cls),
			odds = g.rarity == "Exclusive" and Catalog.howToGet(id, cls, true) or oddsTxt(id, mut), mut = mut,
			map = (g.rarity ~= "Exclusive" and (g.map or 1) > (tonumber(player:GetAttribute("Stage")) or 1)) and g.map or nil })
	end
	if resetScroll then gscroll = 0 end -- при відкритті й зміні класу / мутації — на початок
	setG(gscroll)
end

local function renderOres()
	-- лічильники по мапах: відкрито / всього, скільки можна забрати
	for _, raw in { true, false } do
		local mf, mt, mc = {}, {}, {}
		for _, o in ORES do
			if (o.prod == nil) == raw then
				local k = o.ik
				mt[o.stage] = (mt[o.stage] or 0) + 1
				if found[k] then mf[o.stage] = (mf[o.stage] or 0) + 1 end
				if claimable(k) then mc[o.stage] = (mc[o.stage] or 0) + 1 end
			end
		end
		local all, allT, allC = 0, 0, 0
		for m, lbl in (raw and OM.cnts or OM.bcnts) do
			local n, tot = mf[m] or 0, mt[m] or 0
			all += n; allT += tot; allC += mc[m] or 0
			local done = tot > 0 and n == tot
			lbl.Text = (done and (CHECK .. " ") or "") .. n .. " / " .. tot
			lbl.TextColor3 = done and RING or SUB_TXT
		end
		local t = raw and OM.tab or OM.tab2
		t.c.Text = all .. " / " .. allT .. " found"
		setBadge(t.badge, allC)
		local on = raw == OM.raw
		t.b:setColor(on and "blue" or "gray")
		t.hold.Position = UDim2.fromOffset(on and TX + 10 or TX, tabY(t.i))
	end
	for _, c in oreCards do
		local o = c.ore
		local k = o.ik
		c.set({ found = found[k] == true, claim = claimable(k) and o.reward or nil, sel = selOre == o.key, tone = o.tone, name = o.name,
			icon = ICON[o.ore] or ICON.ores, vp = o.vp, odds = o.prod and (o.prod == "Cut" and "GEM" or "BAR") or pct(o.chance) })
	end
end

local function infoCommon(isFound: boolean, tone: Color3)
	infoIcon.ImageColor3 = isFound and WHITE or BLACK
	infoIcon.ImageTransparency = isFound and 0 or 0.5
	setGlow(infoGlow, tone, isFound and GLOW_INFO or nil)
end
-- рядок нагороди в картці: не відкрито — «+N on first find», можна забрати — «+N ready to claim», забрано — «✓ +N claimed»
local function rewardLine(k: string, rw: number)
	rwIcon.Visible = true
	if claimed[k] then
		rwTx.Text = font("c8ff6a", CHECK) .. " +" .. rw .. " claimed"; rwTx.TextColor3 = SUB_TXT
	elseif found[k] then
		rwTx.Text = "+" .. rw .. " ready to claim"; rwTx.TextColor3 = C("c8ff6a")
	else
		rwTx.Text = "+" .. rw .. " on first find"; rwTx.TextColor3 = C("7fd0ff")
	end
end
renderInfo = function()
	if section == "ores" then
		local o = selOre and ORE_BY_KEY[selOre]
		if not o then return end
		local k = o.ik
		local isFound = found[k] == true
		infoIcon.Image = ICON[o.ore] or ICON.ores
		ItemVP.set(infoIcon, o.vp, 1.13)
		infoCommon(isFound, o.tone)
		infoName.Text = isFound and o.name or "???"
		fitText(infoName, 26, 18)
		infoSub.Text = font(o.tone:ToHex(), o.prod and (o.prod == "Cut" and "Gem" or "Bar") or "Ore") .. " · Map " .. (o.stage or 1)
		infoMut.Visible = false; MutationText.clear(infoMut)
		if o.prod then -- оброблена руда: з чого робиться і ціна; справа — «за руду» (ціна × BAR_MULT)
			infoStat.Text = isFound and (L("From") .. " " .. o.ore .. " · " .. L("Sell") .. " " .. money(o.price)) or L("Smelt ore in the Workshop to reveal")
			oddsTitle.Text = "VALUE"
			oddsTx.Text = "x" .. tostring(Forge.BAR_MULT)
			oddsTx.TextColor3 = isFound and WHITE or C("c9ced4")
			fitText(oddsTx, 26, 18)
			rewardLine(k, o.reward)
			return
		end
		if isFound then
			infoStat.Text = L("HP") .. " " .. o.hp .. " · " .. L("Ore") .. " " .. money(o.price) .. " · "
				.. (o.smelt and (L("Bar") .. " " .. money(math.floor(o.price * Forge.BAR_MULT + 1e-6))) or L("Can't smelt"))
		else
			infoStat.Text = L("Break it on your plot to reveal stats")
		end
		oddsTitle.Text = "SPAWN CHANCE"
		oddsTx.Text = pct(o.chance)
		oddsTx.TextColor3 = isFound and WHITE or C("c9ced4")
		fitText(oddsTx, 26, 18)
		rewardLine(k, o.reward)
		return
	end
	local g = sel and Catalog.get(sel)
	if not g then return end
	local k = keyOf(g.id, cls, mut)
	local isFound = found[k] == true
	local tc = Catalog.rarityColor(g.rarity)
	infoIcon.Image = Catalog.icon(g.id)
	ItemVP.set(infoIcon, ItemVP.golemKey(g.id, cls), 1.13)
	infoCommon(isFound, tc)
	infoName.Text = isFound and g.name or "???"
	fitText(infoName, 26, 18)
	local cn = "Miner"
	for _, c in CLS do if c[1] == cls then cn = c[3] end end
	infoSub.Text = font(tc:ToHex(), g.rarity) .. " " .. cn .. " · "
	infoMut.Text = Catalog.MUTATIONS[mut + 1].key
	infoMut.Visible = true
	MutationText.apply(infoMut, mut)
	local k1 = math.max(info.AbsoluteSize.X / 646, 0.01) -- TextBounds — у пікселях екрана
	infoMut.Position = UDim2.fromOffset(104 + infoSub.TextBounds.X / k1 + 4, infoMut.Position.Y.Offset)
	local ex = g.rarity == "Exclusive" -- ексклюзив: замість шансу — як отримати
	infoStat.Text = isFound and statRich(g.id, cls, mut) or L(ex and "Get it to reveal stats"
		or ((g.map or 1) > (tonumber(player:GetAttribute("Stage")) or 1) and ("Drops from MAP " .. g.map)) or "Roll it to reveal stats")
	oddsTitle.Text = ex and "HOW TO GET" or "ROLL CHANCE"
	oddsTx.Text = ex and Catalog.howToGet(g.id, cls) or oddsTxt(g.id, mut)
	oddsTx.TextColor3 = isFound and WHITE or C("c9ced4")
	fitText(oddsTx, 26, 18)
	rewardLine(k, rewardOf(k))
end

-- вибрана картка має бути видно після того, як сітка стала нижчою
local function ensureVisible(c)
	local top, bottom = c.y - GP, c.y + S + GP
	if bottom > gscroll + gh then setG(bottom - gh) elseif top < gscroll then setG(top) end
end
-- картка внизу лише коли щось вибрано; без неї сітка големів займає її місце.
-- Поява й зникнення — один tween cardT (0 — видна, 1 — схована, 0,2 с Quad Out); від нього покадрово — висота сітки,
-- бігунок, положення картки й (під час анімації) прокрутка до вибраної картки, тому без стрибків. Ховаючись, картка
-- з'їжджає з попереднім вмістом.
local cardT = new("NumberValue", { Value = 1 }, nil)
local cardTw = nil
local function applyCardT()
	local t = cardT.Value
	info.Position = UDim2.fromOffset(6, 6 + t * INFO_SLIDE)
	infoClip.Visible = t < 0.995
	setGridH(GH + t * INFO_SLIDE)
	oreArea.Size = UDim2.fromOffset(GW + 14, GY + GH + t * INFO_SLIDE - CH_Y) -- список руди — до низу вікна, коли картка схована
	OM.barArea.Size = oreArea.Size
	local c = cardTw and sel and section == "golems" and cards[sel]
	if c then ensureVisible(c) end
end
cardT.Changed:Connect(applyCardT)
local function applySelection()
	local want = false
	if section == "golems" then want = sel ~= nil elseif section == "ores" then want = selOre ~= nil end
	if want then renderInfo() end
	if cardTw then cardTw:Cancel(); cardTw = nil end
	local target = want and 0 or 1
	if not (isOpen and modalRoot.Visible) or cardT.Value == target then -- вікно ще не показане / без змін — одразу
		if cardT.Value ~= target then cardT.Value = target else applyCardT() end
		return
	end
	cardTw = tween(cardT, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Value = target })
end

-- Claim All і лічильники
local function updateClaims()
	local n, d = pendingAll()
	claimAllBtn.enabled = n > 0
	claimAllBtn:setColor(n > 0 and "green" or "gray")
	caTx.Text = "+" .. d
	local gN = 0
	for _, c in CLS do gN += classClaim(c[1]) end
	setBadge(sectBadges.golems, gN)
	local _, _, oN = oreCount()
	setBadge(sectBadges.ores, oN)
	local _ = oN -- бейджі вкладок мап — у renderOres (по кожній мапі)
	if section == "ores" then renderOres() end
	for k, t in clsTabs do setBadge(t.badge, classClaim(k)) end
	for i, ch in chips do
		local n = pageClaim(cls, i - 1)
		setBadge(ch.badge, n)
		-- є лічильник — напис і число зсуваються ліворуч, щоб не налазити на нього
		local w = n > 0 and CH_W - 34 or CH_W - 8
		ch.nm.Size = UDim2.fromOffset(w, ch.nm.Size.Y.Offset); ch.ct.Size = UDim2.fromOffset(w + (n > 0 and 4 or 8), ch.ct.Size.Y.Offset)
		ch.ct.Position = UDim2.fromOffset(0, ch.ct.Position.Y.Offset); ch.nm.Position = UDim2.fromOffset(4, ch.nm.Position.Y.Offset)
		fitText(ch.nm, 15, 11)
	end
	updateHud()
end

-- діаманти летять від кнопки до лічильника діамантів у HUD (лічильник сам рахує вгору — MainHUD)
-- шар нульового розміру: повноекранний Frame поверх вікна забирав наведення (MouseEnter) у слотів
local flyLayer = new("Frame", { Name = "Fly", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), ZIndex = 50 }, gui)
-- Координати: AbsolutePosition — у просторі екрана, а шар польоту починається з власного AbsolutePosition (з IgnoreGuiInset
-- це (0, −58) у Studio), тож усе переводимо відносно flyLayer.AbsolutePosition — інакше діаманти летять на 58 px вище.
-- Ціль — центр самої ImageLabel іконки діаманта в MainHUD (перераховується щокадру), кінцевий розмір = розміру іконки
-- (без її «попу»); на прильоті іконка ще раз «попає», діамант зникає в ній.
local function flyDiamonds(from: GuiObject?, amount: number)
	local hud = playerGui:FindFirstChild("MainHUD")
	local plate = hud and hud:FindFirstChild("Counter_Diamonds", true)
	local target = plate and plate:FindFirstChild("Icon")
	if not (from and target) then return end
	local tScale = target:FindFirstChildOfClass("UIScale")
	local function targetRect(): (Vector2, Vector2)
		local k = tScale and tScale.Scale or 1
		return target.AbsolutePosition + target.AbsoluteSize / 2 - flyLayer.AbsolutePosition, target.AbsoluteSize / math.max(0.01, k)
	end
	local a = from.AbsolutePosition + from.AbsoluteSize / 2 - flyLayer.AbsolutePosition
	local px = math.max(18, math.floor(26 * gui.AbsoluteSize.Y / 720 + 0.5))
	local s0 = Vector2.new(px * 0.78, px)
	local function arrivePop()
		if not tScale then return end
		local up = TweenService:Create(tScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.2 })
		up.Completed:Connect(function(st)
			if st == Enum.PlaybackState.Completed then tween(tScale, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 }) end
		end)
		up:Play()
	end
	for i = 1, math.clamp(math.ceil(amount / 10) + 2, 3, 8) do
		task.delay((i - 1) * 0.06, function()
			local p0 = a + Vector2.new(math.random(-20, 20), math.random(-10, 10))
			local b0 = targetRect()
			local bend = Vector2.new(math.random(-90, 90), -math.random(80, 160))
			local img = new("ImageLabel", { BackgroundTransparency = 1, Image = ICON.diamond, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(p0.X, p0.Y), Size = UDim2.fromOffset(s0.X, s0.Y), ZIndex = 50 }, flyLayer)
			local nv = new("NumberValue", { Value = 0 }, img)
			nv.Changed:Connect(function(t)
				local b, bs = targetRect()
				local mid = (p0 + b0) / 2 + bend
				local q = (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * mid + t * t * b
				local sz = s0:Lerp(bs, t)
				img.Position = UDim2.fromOffset(q.X, q.Y)
				img.Size = UDim2.fromOffset(sz.X, sz.Y)
			end)
			local tw = TweenService:Create(nv, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 1 })
			tw.Completed:Connect(function()
				arrivePop()
				img:Destroy()
			end)
			tw:Play()
		end)
	end
end

-- забрати нагороду: сервер перевіряє й нараховує Diamonds; тут — одразу показати (атрибути прийдуть слідом)
local function claimOne(k: string, card)
	if not claimable(k) then return end
	claimed[k] = true
	if Action then Action:FireServer("Claim", k) end
	UISounds.play("claim", 0.1)
	if card then card.fadeClaim(); card.toast("+" .. rewardOf(k)); flyDiamonds(card.cb, rewardOf(k)) end
	local s0 = gscroll
	render(false); setG(s0)
end
claimAllBtn.onClick = function()
	local n, d = pendingAll()
	if n == 0 then return end
	for k in found do claimed[k] = true end
	if Action then Action:FireServer("ClaimAll") end
	UISounds.play("claim", 0.1)
	local t = textAt(claimAllBtn.group, 0, -12, CA_W, 26, "+" .. d, C("7fd0ff"), 2.8, { ZIndex = 9 })
	tween(t, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 30) })
	fadeOut(t, 0.9, true) -- текст і обводка зникають повністю
	flyDiamonds(caIcon, d)
	local s0 = gscroll
	render(false); setG(s0)
end

for _, c in cards do
	c.onClick = function()
		sel = (sel ~= c.g.id) and c.g.id or nil -- ще раз по вибраній — зняти вибір
		renderGrid(false)
		applySelection()
		if sel then ensureVisible(c) end
	end
	c.onClaim = function() claimOne(keyOf(c.g.id, cls, mut), c) end
end
for _, c in oreCards do
	c.onClick = function()
		selOre = (selOre ~= c.ore.key) and c.ore.key or nil
		renderOres()
		applySelection()
	end
	c.onClaim = function() claimOne(c.ore.ik, c) end
end
for _, t in OM.tabs do
	t.b.onClick = function()
		local raw = t == OM.tab
		if OM.raw ~= raw then OM.raw = raw; selOre = nil; render(true) end
	end
end

render = function(animate: boolean?)
	local gol = section == "golems"
	local ore = section == "ores"
	for k, b in sectBtns do b:setColor(k == section and "blue" or "gray") end
	gvp.Visible = gol
	chipSF.Visible = gol
	claimAllBtn.group.Visible = gol or ore
	for _, t in clsTabs do t.hold.Visible = gol end
	oreArea.Visible = ore and OM.raw
	OM.barArea.Visible = ore and not OM.raw
	for _, t in OM.tabs do t.hold.Visible = ore end
	coll.Visible = gol or ore
	soon.Visible = not (gol or ore)
	if not gol then vsb.Visible = false end
	updateClaims()
	if ore then
		renderOres()
		local n, d, _, tot = oreCount(OM.raw)
		collTitle.Text = OM.raw and "All Ores" or "All Crafted"
		collTxt.Text = n .. " / " .. tot
		collFill.Size = UDim2.fromOffset(math.max(6, 198 * n / math.max(1, tot)), 24)
		collIcon.Image = ICON.diamond
		collD.Text = "+" .. d .. " " .. L("earned")
		applySelection()
		return
	end
	if not gol then applySelection(); return end
	for k, t in clsTabs do
		local on = k == cls
		t.b:setColor(on and "blue" or "gray")
		tween(t.hold, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(on and TX + 10 or TX, tabY(t.i)) })
		t.c.Text = classCount(k) .. " / " .. PER_CLASS(k) .. " found"
	end
	for i, ch in chips do
		local k = i - 1
		local on = k == mut
		local n = pageCount(cls, k)
		local pt = k == 0 and PAGE + #Catalog.exclusivesFor(cls) or PAGE -- Normal — разом з ексклюзивами
		ch.ring.Visible = on
		setGlow(ch.glow, ch.color, on and GLOW_CHIP_ON or GLOW_CHIP_OFF)
		ch.ct.Text = n == pt and (CHECK .. " " .. n .. "/" .. pt) or (n .. "/" .. pt)
		ch.ct.TextColor3 = n == pt and RING or (on and WHITE or MUTED)
		ch.root.ZIndex = on and 5 or 4
	end
	if sel and mut ~= 0 and cards[sel] and cards[sel].group.excl then sel = nil end -- ексклюзиви — лише на Normal
	local n, d = totals()
	collTitle.Text = "All Golems"
	collTxt.Text = n .. " / " .. TOTAL
	collFill.Size = UDim2.fromOffset(math.max(6, 198 * n / TOTAL), 24)
	collIcon.Image = ICON.diamond
	collD.Text = "+" .. d .. " " .. L("earned")
	applySelection() -- висота сітки — до перемальовування (прокрутка рахується від неї)
	renderGrid(animate == true)
	if animate then
		gstrip.Position = UDim2.fromOffset(0, -gscroll + 10)
		tween(gstrip, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(0, -gscroll) })
	end
end

-- =====================================================================
-- ===== масштаб, відкриття / закриття =====
-- =====================================================================
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

local uiEvents = RS:WaitForChild("UIEvents", 30)
local hudEvent = uiEvents and uiEvents:WaitForChild("HUDButton", 30)

local animToken = 0
local open, close
local hiddenGuis = {}
local hotbarOrder = nil
local function escKey(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	task.defer(function() if isOpen then close() end end)
	return Enum.ContextActionResult.Sink
end
open = function()
	if isOpen then return end
	isOpen = true
	animToken += 1
	local my = animToken
	-- одне вікно на екрані (Shared/WindowManager, 27.10.2026): інші вікна закриваються своєю анімацією
	require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowManager")).opened("Index")
	-- хотбар лишається видно над затемненням (як у INVENTORY)
	-- (Inventory, що закривається, за 0,12 с повертає хотбару свій порядок — тож ставимо ще раз після цього)
	local hb = playerGui:FindFirstChild("Hotbar")
	if hb and hb:IsA("ScreenGui") then
		hotbarOrder = hb.DisplayOrder < 11 and hb.DisplayOrder or 5
		hb.DisplayOrder = 11
		task.delay(0.2, function() if isOpen and animToken == my then hb.DisplayOrder = 11 end end)
	end
	readData()
	sel, selOre = nil, nil -- при відкритті нічого не вибрано (картки внизу немає)
	gscroll = 0
	chipSF.CanvasPosition = Vector2.zero
	chipShow(mut, false)
	fit()
	render(true)
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("IndexEsc", escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
end
close = function()
	if not isOpen then return end
	isOpen = false
	pcall(function() CAS:UnbindAction("IndexEsc") end)
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
		local hb = playerGui:FindFirstChild("Hotbar")
		local invRoot = playerGui:FindFirstChild("InventoryWindow") and playerGui.InventoryWindow:FindFirstChild("ModalRoot")
		if hb and hotbarOrder and not (invRoot and invRoot.Visible) then hb.DisplayOrder = hotbarOrder end
		hotbarOrder = nil
		for g in hiddenGuis do if g.Parent then g.Enabled = true end end
		table.clear(hiddenGuis)
	end)
end
closeBtn.onClick = function() close() end
-- одне вікно на екрані (Shared/WindowManager): відкрилось інше вікно — Index закривається
require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowManager")).register("Index", function() return isOpen end, function() close() end)
local function inside(o: GuiObject, p: Vector2, top: number?): boolean
	local a, s = o.AbsolutePosition, o.AbsoluteSize
	return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y - (top or 0) and p.Y <= a.Y + s.Y
end
-- 03.11.2026 (рішення користувача): Index закривається ЛИШЕ хрестиком (і Esc). Клік поза вікном більше не закриває:
-- на телефоні, коли Index відкривався зоною, гравець відпускав палець з джойстика — і вікно одразу закривалось.
OM.closeOnBackdrop = false -- у таблиці OM (ліміт 200 локальних змінних у скрипті)
backdrop.InputBegan:Connect(function(inp)
	if not OM.closeOnBackdrop or not isPress(inp) then return end
	-- закриває лише клік ПОЗА вікном (заголовок INDEX і X над рамкою — теж вікно). Без + GetGuiInset(): inp.Position
	-- і AbsolutePosition в одному просторі (з поправкою клік біля низу вікна — картка внизу — помилково закривав Index)
	local p = Vector2.new(inp.Position.X, inp.Position.Y)
	if inside(content, p, content.AbsoluteSize.Y * 0.18) or inside(claimAllBtn.group, p, 0) then return end
	close()
end)

-- кнопка Index у HUD (MainHUD → UIEvents/HUDButton "Index")
if hudEvent then
	hudEvent.Event:Connect(function(key) if key == "Index" then if isOpen then close() else open() end end end)
end
-- відкрили Inventory (кнопка HUD або B) — Index закривається
task.spawn(function()
	local inv = playerGui:WaitForChild("InventoryWindow", 60)
	local mr = inv and inv:WaitForChild("ModalRoot", 30)
	if mr then mr:GetPropertyChangedSignal("Visible"):Connect(function() if mr.Visible and isOpen then close() end end) end
end)

-- дані: зміна IndexFound / IndexClaimed → лічильник на HUD і перемалювати відкрите вікно (раз за кадр)
local pending = false
player.AttributeChanged:Connect(function(name)
	if name ~= "IndexFound" and name ~= "IndexClaimed" and name ~= "Stage" then return end -- Stage — плашки MAP N
	if pending then return end
	pending = true
	task.defer(function()
		pending = false
		readData()
		updateHud()
		if isOpen then local s0 = gscroll; render(false); setG(s0) end
	end)
end)
readData()
updateHud()
