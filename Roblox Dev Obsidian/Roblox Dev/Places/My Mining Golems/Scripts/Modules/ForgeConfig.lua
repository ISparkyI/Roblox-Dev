--!strict
-- ForgeConfig — числа Forge (кузня з големом-ковалем). Спільний для сервера й клієнта.
-- Де: ReplicatedStorage/Shared/ForgeConfig. Усі ціни — етап 1 (пропозиція, див. GDD 7.1).

local Config = {}

-- руда кожної мапи (29.10.2026): ціни — GDD - Ores and Bars (ціна = базова × 20^(мапа−1)); по 3 руди на мапу
Config.STAGE_ORES = {
	[1] = {
		{ key = "Coal",   color = Color3.fromHex("2b2e33"), bar = Color3.fromHex("34373d"), price = 8, smelt = false }, -- вугілля НЕ плавиться (злитків немає) — лише продається
		{ key = "Copper", color = Color3.fromHex("c8643a"), bar = Color3.fromHex("d9733f"), price = 20 },
		{ key = "Iron",   color = Color3.fromHex("d08a55"), bar = Color3.fromHex("e0e4ea"), price = 50 },
	},
	[2] = {
		{ key = "Tin",    color = Color3.fromHex("a9bccb"), bar = Color3.fromHex("c9d5de"), price = 160 },
		{ key = "Silver", color = Color3.fromHex("e3e8ee"), bar = Color3.fromHex("f1f4f8"), price = 400 },
		{ key = "Gold",   color = Color3.fromHex("ffc928"), bar = Color3.fromHex("ffd84a"), price = 1000 },
	},
	-- мапи 3–7 (03.11.2026): product = "Cut" — огранований кристал (модель Prefabs/ForgeProps/Cut<Руда>), робиться в Workshop як злиток
	--   (ціна × BAR_MULT, у інвентарі той самий ключ Bars_<Руда>); без product — злиток (Bar<Руда>). Мапа 7 — прихована (наступне оновлення).
	[3] = {
		{ key = "Quartz",   color = Color3.fromHex("e9e6f2"), bar = Color3.fromHex("ffffff"), price = 3200, product = "Cut" },
		{ key = "Amethyst", color = Color3.fromHex("a96bff"), bar = Color3.fromHex("c79bff"), price = 8000, product = "Cut" },
		{ key = "Sapphire", color = Color3.fromHex("3d7bff"), bar = Color3.fromHex("6fa2ff"), price = 20000, product = "Cut" },
	},
	[4] = {
		{ key = "Obsidian", color = Color3.fromHex("7d4dd6"), bar = Color3.fromHex("9a6bf0"), price = 64000, product = "Cut" },
		{ key = "Ruby",     color = Color3.fromHex("e2304a"), bar = Color3.fromHex("ff5a6e"), price = 160000, product = "Cut" },
		{ key = "Emberite", color = Color3.fromHex("ff7a2a"), bar = Color3.fromHex("ff9a4a"), price = 400000 },
	},
	[5] = {
		{ key = "Frostite",  color = Color3.fromHex("bfeaff"), bar = Color3.fromHex("e2f6ff"), price = 1280000, product = "Cut" },
		{ key = "Platinum",  color = Color3.fromHex("9fe4ff"), bar = Color3.fromHex("d7e2ea"), price = 3200000 },
		{ key = "Celestium", color = Color3.fromHex("fff1a8"), bar = Color3.fromHex("fff7cc"), price = 8000000, product = "Cut" },
	},
	[6] = {
		{ key = "Voidstone", color = Color3.fromHex("b46bff"), bar = Color3.fromHex("d4a6ff"), price = 25600000, product = "Cut" },
		{ key = "Starmetal", color = Color3.fromHex("8a7dd6"), bar = Color3.fromHex("a9a0e6"), price = 64000000 },
		{ key = "Eclipsium", color = Color3.fromHex("6a2ab8"), bar = Color3.fromHex("ffcf4a"), price = 160000000, product = "Cut" },
	},
	[7] = {
		{ key = "Toxite",   color = Color3.fromHex("3e8a3a"), bar = Color3.fromHex("5fb85a"), price = 512000000, product = "Cut" },
		{ key = "Uranite",  color = Color3.fromHex("7dff4a"), bar = Color3.fromHex("a6ff7a"), price = 1280000000 },
		{ key = "Venomite", color = Color3.fromHex("2fbf5a"), bar = Color3.fromHex("5ae07d"), price = 3200000000, product = "Cut" },
	},
}
Config.MAX_STAGE = 6 -- (04.11.2026: відкрито мапу 6 Void Core — остання в цьому оновленні) скільки мап уже відкрито в грі (перехід далі — «coming soon»; префаби NichePrefab_Stage1..N)
Config.ORE_STAGES = #Config.STAGE_ORES -- скільки мап має руду в конфігу (7)
Config.INDEX_STAGES = 6 -- руда яких мап видно в Index (мапа 7 — наступне оновлення, ніде не показується)
-- усі руди всіх мап (інвентар, збереження, продаж старої руди)
Config.ALL_ORES = {}
for st = 1, Config.ORE_STAGES do for _, o in Config.STAGE_ORES[st] do o.stage = st; table.insert(Config.ALL_ORES, o) end end
-- продукт руди: "Bar" (злиток) або "Cut" (огранований кристал); модель і назва для UI
function Config.productOf(key: string): string
	local o = nil
	for _, x in Config.ALL_ORES do if x.key == key then o = x end end
	return (o and o.product) or "Bar"
end
function Config.productModel(key: string): string return Config.productOf(key) .. key end -- BarTin / CutQuartz
function Config.productName(key: string): string
	return Config.productOf(key) == "Cut" and ("Cut " .. key) or (key .. " Bar")
end
function Config.oresFor(stage: number?): { any }
	return Config.STAGE_ORES[math.clamp(math.floor(tonumber(stage) or 1), 1, Config.MAX_STAGE)]
end
function Config.oreDef(key: string): any
	for _, o in Config.ALL_ORES do if o.key == key then return o end end
	return nil
end
-- пробудження голема кузні (Workshop) на кожній мапі: руда мапи (по порядку) + гроші
Config.WAKE = {
	[1] = { req = { 20, 10, 5 }, money = 1000 },
	[2] = { req = { 30, 15, 8 }, money = 100000 },
	-- мапи 2–7: 30 / 15 / 8 руди мапи + гроші — WAKE_FIXED / WAKE_MONEY_BASE нижче (04.11.2026);
	-- числа money тут — лише запасні
	[3] = { req = { 30, 15, 8 }, money = 6700000 },
	[4] = { req = { 30, 15, 8 }, money = 310000000 },
	[5] = { req = { 30, 15, 8 }, money = 19000000000 },
	[6] = { req = { 30, 15, 8 }, money = 1500000000000 },
	[7] = { req = { 30, 15, 8 }, money = 117000000000000 },
}
function Config.wakeFor(stage: number?): any
	return Config.WAKE[math.clamp(math.floor(tonumber(stage) or 1), 1, Config.MAX_STAGE)]
end
-- ORES / WAKE_REQ / WAKE_MONEY — руда й пробудження ПОТОЧНОЇ мапи. На сервері — мапа 1 (сервіси беруть oresFor(етап ніші));
-- на клієнті таблиці оновлюються НА МІСЦІ при зміні атрибута Stage гравця (вікна, що тримають посилання, бачать нову руду).
Config.ORES = table.clone(Config.STAGE_ORES[1])
-- чи можна плавити руду в злитки (вугілля — ні: його кладуть лише для пробудження голема або продають)
function Config.canSmelt(o): boolean return o.smelt ~= false end
Config.BAR_MULT = 1.5          -- злиток = ціна руди × 1.5
Config.WAKE_REQ = table.clone(Config.WAKE[1].req) -- руда етапу, щоб розбудити голема (поточна мапа, див. вище)
Config.WAKE_MONEY = Config.WAKE[1].money -- і ще гроші (знімаються кнопкою Wake Up; окремий рядок Money у вікні Forge)
Config.StageChanged = Instance.new("BindableEvent") -- клієнт: руда мапи змінилась (вікна перебудовують рядки)
if game:GetService("RunService"):IsClient() then
	local lp = game:GetService("Players").LocalPlayer
	local cur = 1
	local function sync()
		local st = math.clamp(math.floor(tonumber(lp:GetAttribute("Stage")) or 1), 1, Config.MAX_STAGE)
		if st == cur then return end
		cur = st
		Config.curStage = st
		table.clear(Config.ORES); for _, o in Config.oresFor(st) do table.insert(Config.ORES, o) end
		table.clear(Config.WAKE_REQ); for _, n in Config.wakeFor(st).req do table.insert(Config.WAKE_REQ, n) end
		Config.WAKE_MONEY = Config.wakeFor(st).money
		Config.StageChanged:Fire(st)
	end
	sync()
	lp:GetAttributeChangedSignal("Stage"):Connect(sync)
end
Config.VIS_ORE = 16            -- скільки кубиків кожного типу видно на піддоні Ore
Config.VIS_BARS = 24           -- скільки злитків видно на піддоні Bars
Config.RING_R = 8.64           -- радіус кола взаємодії (стади; коло збільшено ще в 1.5 раза)
Config.WAKE_TIME = 4.2         -- тривалість анімації пробудження, с
Config.DOZE_TIME = 4.2         -- тривалість засинання, с
Config.SMELT_FLIGHT = 1.1      -- (застаріле) раніше: руда летить у піч + злиток вилітає, с
Config.WAIT_WORD = "WAITING"     -- стан «кузня працює, але голем нічого не плавить» (табличка над кузнею + чип у вікні); до слова додаються крапки
Config.BAR_DELAY = 2.7         -- через скільки секунд після переплавки злиток зараховується на піддон
                               -- (руда летить у піч → гаряча заготовка на ковадло → удар → політ на піддон)

Config.SPD_MIN = 0.25          -- найшвидший інтервал удару, с (рівень 12; було 0.75 на рівні 10)
Config.OPH_MAX = 10           -- Ore per Hit: максимум руди, яку голем переробляє за один удар

-- мапа для формул (29.10.2026): на клієнті — мапа гравця (оновлює sync нижче), на сервері сервіс передає мапу кузні.
-- Місткість піддону ($) росте як ціна руди мапи (×20 на мапу); ціни покращень — × PlotConfig-правило (1 + 2 × (множник мапи − 1)).
Config.curStage = Config.curStage or 1
local function st(stage: number?): number return math.max(1, math.floor(tonumber(stage) or Config.curStage)) end
local MultiCfg = require(script.Parent:WaitForChild("MultiConfig"))
function Config.priceMult(stage: number?): number return MultiCfg.priceMult(st(stage)) end -- 03.11.2026: MultiConfig.PRICE_MULTS
local nice = MultiCfg.round2 -- 2 значущі цифри (590M, 8.2T)
-- гроші за пробудження на мапах 2–7 = 50,000 × множник цін мапи (03.11.2026; мапа 2 ≈ $590M). Мапа 1 — $1,000 як було.
-- 04.11.2026 (рішення користувача): гроші пробудження задані вручну — мапа 1 $1K, мапа 2 $15M, мапа 3 $5B
--   (було 50,000 × множник цін: $590M / $245B — пробудження коштувало ×500 від першого покращення Workshop).
--   Мапи 4–7 (ще не відкриті) — та сама пропорція, що на мапі 3: WAKE_MONEY_BASE × множник цін мапи (≈1,020 × множник).
Config.WAKE_FIXED = { [1] = 1000, [2] = 15e6, [3] = 5e9, [4] = 2.5e12, [5] = 5e14, [6] = 1e17 }
Config.WAKE_MONEY_BASE = 5e9 / MultiCfg.priceMult(3)
for s = 1, #Config.WAKE do Config.WAKE[s].money = Config.WAKE_FIXED[s] or nice(Config.WAKE_MONEY_BASE * MultiCfg.priceMult(s)) end
-- 10.11.2026: гроші за пробудження Workshop прибрано на всіх мапах (лише руда) — гравці витрачають гроші на апгрейди
for s = 1, #Config.WAKE do Config.WAKE[s].money = 0 end
Config.WAKE_MONEY = 0
if Config.curStage and Config.curStage > 1 then Config.WAKE_MONEY = Config.wakeFor(Config.curStage).money end
-- економіка v2 (29.10.2026): місткість піддону — 10 рівнів ($300 → $20,000 на мапі 1, ×20 за мапу); було +$300 без межі
Config.CAP_LEVELS = { 300, 500, 800, 1300, 2000, 3200, 5000, 8000, 12500, 20000 }
Config.CAP_MAX = #Config.CAP_LEVELS
function Config.capOf(l: number, stage: number?): number return Config.CAP_LEVELS[math.clamp(math.floor(l), 1, Config.CAP_MAX)] * 20 ^ (st(stage) - 1) end
function Config.capMax(l: number): boolean return l >= Config.CAP_MAX end
function Config.spdOf(l: number): number return math.max(Config.SPD_MIN, 3 - (l - 1) * 0.25) end
function Config.spdMax(l: number): boolean return Config.spdOf(l) <= Config.SPD_MIN + 1e-6 end
function Config.ophOf(l: number): number return math.clamp(math.floor(l), 1, Config.OPH_MAX) end -- рівень 1 = 1 руда за удар
function Config.ophMax(l: number): boolean return l >= Config.OPH_MAX end
-- ціни переходу з рівня l на l + 1 (мапа 1; × priceMult на інших мапах), економіка v2
Config.CAP_PRICES = { 100, 200, 350, 675, 1300, 2400, 4500, 8500, 16000 }
Config.SPD_PRICES = { 75, 125, 200, 350, 575, 950, 1600, 2600, 4300, 7200, 12000 }
Config.OPH_PRICES = { 300, 525, 950, 1700, 3000, 5300, 9500, 17000, 30000 }
local function at(t: { number }, l: number): number return t[math.clamp(math.floor(l), 1, #t)] end
-- 04.11.2026: знижка перших рівнів на мапах 2+ (MultiConfig.earlyDiscount; Ore per Hit починається з рівня 1 → знижка рівня l)
local function disc(l: number, stage: number?): number return MultiCfg.earlyDiscount(l, st(stage)) end
function Config.capPrice(l: number, stage: number?): number return math.floor(at(Config.CAP_PRICES, l) * Config.priceMult(stage) * disc(l, stage)) end
function Config.spdPrice(l: number, stage: number?): number return math.floor(at(Config.SPD_PRICES, l) * Config.priceMult(stage) * disc(l, stage)) end
function Config.ophPrice(l: number, stage: number?): number return math.floor(at(Config.OPH_PRICES, l) * Config.priceMult(stage) * disc(l, stage)) end

-- Auto Workshop (29.10.2026): четверта картка табло Workshop. Куплена (AutoLvl = 2 на моделі кузні) або геймпас Pass_AutoWorkshop — кузня
--   сама бере руду мапи з інвентаря на піддон, плавить і кладе злитки в інвентар (ForgeService.autoStep). Картка відкривається
--   з мапи AUTO_MIN_STAGE і скидається на наступній мапі (секція Forge); геймпас — з мапи 1 і назавжди.
--   Ціна (03.11.2026) = AUTO_PRICE_BASE × множник цін мапи (autoPrice; мапа 3 ≈ $6.8T). Було фіксовані $5M.
--   Перемикач ON / OFF — цією ж карткою (Set_AutoWorkshop).
Config.AUTO_MIN_STAGE = 2 -- 09.11.2026: було 3 (картка Auto Workshop тепер з мапи 2)
Config.AUTO_PRICE_BASE = 1666667 -- $5M / (старий множник мапи 3 = 3): те саме співвідношення до цін карток
function Config.autoPrice(stage: number?): number return nice(Config.AUTO_PRICE_BASE * Config.priceMult(stage)) end
Config.AUTO_PRICE = Config.autoPrice(Config.AUTO_MIN_STAGE) -- запасне (старий код)
function Config.autoOwned(p: Instance?, f: Instance?): boolean
	if p and p:GetAttribute("Pass_AutoWorkshop") == true then return true end
	return f ~= nil and (tonumber(f:GetAttribute("AutoLvl")) or 1) >= 2
end

-- ТЕСТ: поки немає інвентаря, гравець отримує руду й гроші атрибутами.
Config.TEST_START = { Ore = { 25, 12, 6 }, Money = 0 } -- стартові гроші нового гравця: 0 (29.10.2026, було 10,000)
Config.TEST_SELL_BARS = false -- false: «Забрати злитки» кладе їх в інвентар (Bars_<руда>), продаються в лавці Sell; true — ТЕСТ: одразу продати

return Config
