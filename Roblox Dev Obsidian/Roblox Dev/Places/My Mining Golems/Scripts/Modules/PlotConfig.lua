--!strict
-- PlotConfig — плоти (зони фарму, GDD 5): руда, големи на плоті, картки прокачки. Спільний для сервера (PlotService) і клієнта.
-- Де: ReplicatedStorage/Shared/PlotConfig. Ціни — для мапи 1 (пропозиція), округлення вниз.
local Catalog = require(script.Parent:WaitForChild("GolemCatalog"))
local Config = {}

Config.MAX_PLOTS = 6     -- плоти купуються по черзі 1→6 (1 ближній лівий, 2 ближній правий, 3 середній лівий ...)
Config.MAX_POINTS = 6    -- (28.10.2026, було 10) максимум руди на плоті одночасно (картка Ore Limit, старт 1); місце руди — випадкове

-- руда мапи 1: HP і шанс спавну «1 до N» (шанси працюють як ваги: кожен спавн дає одну з трьох руд)
-- руда кожної мапи; шанси 1 до 3 / 9 / 20. HP (03.11.2026, рішення користувача; було ×14 за мапу — непрохідно):
--   мапа 1 — 4 / 12 / 24 (1 : 3 : 6); з мапи 2 — 1 : 2 : 3 і ×5 за мапу, тож найслабша руда мапи (S) міцніша
--   за найсильнішу попередньої (L = ×1,5): 40/80/120 · 200/400/600 · 1,000/2,000/3,000 · 5,000/10,000/15,000 · 25,000/50,000/75,000.
Config.STAGE_ORES = {
	[1] = {
		{ key = "Coal", hp = 4, odds = 3 },
		{ key = "Copper", hp = 12, odds = 9 },
		{ key = "Iron", hp = 24, odds = 20 },
	},
	[2] = {
		{ key = "Tin", hp = 40, odds = 3 },
		{ key = "Silver", hp = 80, odds = 9 },
		{ key = "Gold", hp = 120, odds = 20 },
	},
	[3] = {
		{ key = "Quartz", hp = 200, odds = 3 },
		{ key = "Amethyst", hp = 400, odds = 9 },
		{ key = "Sapphire", hp = 600, odds = 20 },
	},
	[4] = {
		{ key = "Obsidian", hp = 1000, odds = 3 },
		{ key = "Ruby", hp = 2000, odds = 9 },
		{ key = "Emberite", hp = 3000, odds = 20 },
	},
	[5] = {
		{ key = "Frostite", hp = 5000, odds = 3 },
		{ key = "Platinum", hp = 10000, odds = 9 },
		{ key = "Celestium", hp = 15000, odds = 20 },
	},
	[6] = {
		{ key = "Voidstone", hp = 25000, odds = 3 },
		{ key = "Starmetal", hp = 50000, odds = 9 },
		{ key = "Eclipsium", hp = 75000, odds = 20 },
	},
	-- мапа 7 — прихована (наступне оновлення), те саме правило ×5
	[7] = {
		{ key = "Toxite", hp = 125000, odds = 3 },
		{ key = "Uranite", hp = 250000, odds = 9 },
		{ key = "Venomite", hp = 375000, odds = 20 },
	},
}
Config.ORES = Config.STAGE_ORES[1] -- руда мапи 1
-- руда в Index (03.11.2026): мапи 1–6 по порядку (o.stage — мапа); мапа 7 — наступне оновлення, у Index її немає.
-- Номер у цьому списку = n для нагороди Index (IndexService.oreReward).
Config.INDEX_STAGES = 6
Config.INDEX_ORES = {}
for st = 1, Config.INDEX_STAGES do
	for _, o in Config.STAGE_ORES[st] or {} do o.stage = st; table.insert(Config.INDEX_ORES, o) end
end
for _, o in Config.STAGE_ORES[7] or {} do o.stage = 7 end
function Config.oresFor(stage: number?): { any }
	local n = #Config.STAGE_ORES
	return Config.STAGE_ORES[math.clamp(math.floor(tonumber(stage) or 1), 1, n)]
end
function Config.rollOre(r: Random, stage: number?): any
	local list = Config.oresFor(stage)
	local total = 0
	for _, o in list do total += 1 / o.odds end
	local x = r:NextNumber() * total
	for _, o in list do
		x -= 1 / o.odds
		if x <= 0 then return o end
	end
	return list[1]
end
-- розмір жили: S — мала (стандарт), M — середня, L — велика. drop — множник кількості руди, hp — множник HP
-- (кількість — округлення вниз, HP — вгору). Модель — PlotAssets/Ores/<Руда>_<S|M|L>.
Config.SIZES = {
	{ key = "S", weight = 60, drop = 1, hp = 1 },
	{ key = "M", weight = 30, drop = 1.5, hp = 1.25 },
	{ key = "L", weight = 10, drop = 2, hp = 1.5 },
}
function Config.rollSize(r: Random): any
	local x = r:NextNumber() * 100
	for _, s in Config.SIZES do
		x -= s.weight
		if x <= 0 then return s end
	end
	return Config.SIZES[1]
end
function Config.hpOf(ore: any, size: any): number return math.ceil(ore.hp * size.hp) end
-- скільки шматків падає з руди: 1–3 (1 — найчастіше), × розмір жили (вниз), × картка Ore Drop (вниз), мінімум 1
Config.BASE_DROP = { { n = 1, weight = 60 }, { n = 2, weight = 30 }, { n = 3, weight = 10 } }
function Config.rollDrop(r: Random, size: any, dropLvl: number): number
	local x, base = r:NextNumber() * 100, 1
	for _, d in Config.BASE_DROP do
		x -= d.weight
		if x <= 0 then base = d.n; break end
	end
	local n = math.floor(base * size.drop)
	-- (29.10.2026, економіка v2) дробова частина — шансом: 1 шматок × 1,25 = 1 або 2 (25 %); кожен рівень Ore Drop дає рівно +25 % у середньому
	local x = n * Config.dropOf(dropLvl)
	local k = math.floor(x)
	if r:NextNumber() < x - k then k += 1 end
	return math.max(1, k)
end
function Config.oreChance(key: string): number -- частка у відсотках (для UI / GDD)
	local total, mine = 0, 0
	local list = Config.ORES
	for _, st in Config.STAGE_ORES do for _, o in st do if o.key == key then list = st end end end -- шанс серед руди своєї мапи
	for _, o in list do total += 1 / o.odds; if o.key == key then mine = 1 / o.odds end end
	return mine / total * 100
end

-- ===== картки прокачки (діють на ВСІ плоти; рівень 1 = старт) =====
-- ===== економіка v2 (29.10.2026, GDD - Economy): ціни мапи 1, рівні скорочено, кожна покупка відчутна =====
-- Ore Spawn: 10 рівнів, кожен ≈ на 23 % швидше (5 с → 0,75 с)
Config.SPAWN_LEVELS = { 5, 4.05, 3.3, 2.65, 2.15, 1.75, 1.4, 1.15, 0.95, 0.75 }
function Config.spawnOf(l: number): number return Config.SPAWN_LEVELS[math.clamp(math.floor(l), 1, #Config.SPAWN_LEVELS)] end
function Config.slotsOf(l: number): number return math.clamp(l, 1, 5) end
function Config.carryOf(l: number): number return math.min(3, 1 + (l - 1) * 0.25) end
function Config.plotsOf(l: number): number return math.clamp(l, 1, Config.MAX_PLOTS) end
function Config.pointsOf(l: number): number return math.clamp(l, 1, Config.MAX_POINTS) end
function Config.dropOf(l: number): number return math.min(3, 1 + (l - 1) * 0.25) end -- ×1 → ×3 (28.10.2026, було ×10)
-- Crate Capacity: 10 рівнів (було 100 рівнів по +10)
Config.CRATE_LEVELS = { 20, 40, 70, 110, 160, 230, 320, 450, 650, 1000 }
function Config.crateOf(l: number): number return Config.CRATE_LEVELS[math.clamp(math.floor(l), 1, #Config.CRATE_LEVELS)] end
Config.CRATE_VISUAL = 16 -- руда в ящику — один щільний шар 4 × 4 шматки; він піднімається від дна до краю з заповненням

-- ціни переходу з рівня l на l + 1 (мапа 1); разом 48 покупок = $114,655, мапа 1 ≈ 25–35 хв (симуляція, GDD - Economy)
local function list(t: { number }): (number) -> number
	return function(l: number) return t[math.clamp(math.floor(l), 1, #t)] end
end
Config.CARDS = {
	Plots = { name = "Plots", max = 6, price = list({ 25, 125, 600, 3000, 15000 }) },
	Points = { name = "Ore Limit", max = 6, price = list({ 30, 100, 375, 1400, 5000 }) },
	Spawn = { name = "Ore Spawn", max = 10, price = list({ 30, 65, 125, 275, 600, 1300, 2700, 5700, 12000 }) },
	Slots = { name = "Golem Slots", max = 5, price = list({ 50, 300, 1700, 10000 }) },
	Carry = { name = "Carrier Speed", max = 9, price = list({ 40, 85, 200, 400, 875, 1900, 4200, 9000 }) },
	Crate = { name = "Crate Capacity", max = 10, price = list({ 20, 40, 85, 175, 350, 700, 1400, 2900, 6000 }) },
	Drop = { name = "Ore Drop", max = 9, price = list({ 60, 125, 275, 625, 1400, 2900, 6400, 14000 }) },
	-- Auto Sell (29.10.2026): усе, що потрапляє в інвентар (руда, злитки всіх мап), одразу продається (ServerScriptService/
	--   AutoSellService); що саме — налаштування на цій картці (кнопка SETTINGS після покупки). Рівень 1 = не куплено, 2 = куплено.
	--   Відкривається на мапі 2, скидається разом з усіма картками на наступній мапі. Геймпас Auto Sell (Pass_AutoSell) — те саме з мапи 1
	--   і назавжди (картку тоді не купують). Ціна — $250K фіксована (flat: без множника мапи; рішення користувача).
	--   optional: не рахується в прогрес NEXT MAP (MapService).
	AutoSell = { name = "Auto Sell", max = 2, minStage = 2, flat = true, optional = true, pass = "AutoSell", price = function(l: number, stage: number?) return require(script.Parent:WaitForChild("MultiConfig")).round2(125000 * Config.priceMult(stage)) end }, -- 03.11.2026: × множник цін мапи (мапа 2 ≈ $1.5B; було фіксовані $250K)
}
-- ціни карток на мапі N (29.10.2026, рішення користувача): приріст множника мапи (MultiConfig.STAGE_MULTS) подвоюється —
-- ціна × (1 + 2 × (множник мапи − 1)). Мапа 1 ×1 → ×1; мапа 2 ×1,5 → ×2; мапа 3 ×2 → ×3 … Ціни ростуть удвічі швидше за заробіток
-- (баланс — через големів).
local MultiCfg = require(script.Parent:WaitForChild("MultiConfig"))
function Config.priceMult(stage: number?): number
	return MultiCfg.priceMult(stage) -- 03.11.2026: таблиця MultiConfig.PRICE_MULTS (×0,7 / ×230 / ×15,500 …)
end
function Config.cardPrice(key: string, l: number, stage: number?): number
	local c = Config.CARDS[key]
	if c and c.flat then return math.floor(c.price(l, stage)) end -- одна ціна без рівнів (Auto Sell; сама враховує мапу)
	return c and math.floor(c.price(l) * Config.priceMult(stage) * MultiCfg.earlyDiscount(l, stage)) or math.huge -- 04.11.2026: знижка перших рівнів (мапи 2+)
end
Config.CARD_ORDER = { "Plots", "Points", "Spawn", "Slots", "Carry", "Crate", "Drop", "AutoSell" }
-- чи відкрита картка для гравця на етапі stage
function Config.cardOpen(key: string, stage: number?): boolean
	local c = Config.CARDS[key]
	return c ~= nil and (c.minStage == nil or (stage or 1) >= c.minStage)
end
-- чи є в гравця Auto Sell: геймпас або куплена картка (рівень 2 у PlotLv)
function Config.autoSellOwned(p: Instance): boolean
	if p:GetAttribute("Pass_AutoSell") == true then return true end
	local raw = p:GetAttribute("PlotLv")
	if type(raw) ~= "string" then return false end
	local ok, t = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), raw)
	return ok and type(t) == "table" and (tonumber(t.AutoSell) or 1) >= 2
end
function Config.defaultLevels(): { [string]: number }
	local t = {}
	for k in Config.CARDS do t[k] = 1 end
	return t
end

-- ===== големи на плоті — характеристики з каталогу (Shared/GolemCatalog, GDD Golem Stats) з урахуванням мутації =====
-- майнер: dmg — шкода за удар, int — інтервал удару (с), mspd — рух (стад/с), anim — AnimSpeed (= Швидкість);
-- носій: cap — руди за ходку, spd — рух (стад/с, ще × картка Carrier Speed)
-- p — власник (для ексклюзів з динамічною шкодою, Mushroom Golem)
-- (05.11.2026) прихований стандарт носіїв: множники для ВСІХ носіїв на плоті (опис / Index / картки не змінюються).
--   Носій не встигав за 5 майнерами: місткість за ходку × CARRIER_CAP (вниз, мін. 1), рух × CARRIER_MOVE.
Config.CARRIER_CAP = 3
Config.CARRIER_MOVE = 1.5
function Config.stats(kind: string, mut: number?, p: any?): any
	local m = Catalog.stats(kind, "miner", mut, p)
	local c = Catalog.stats(kind, "carrier", mut, p)
	return { dmg = m.dmg, int = m.interval, mspd = m.move, anim = m.speed,
		cap = math.max(1, math.floor((c.cap or 1) * Config.CARRIER_CAP)), spd = c.move * Config.CARRIER_MOVE }
end
function Config.minerPower(kind: string, mut: number?, p: any?): number return Catalog.power(kind, "miner", mut, p) end
function Config.carrierPower(kind: string, mut: number?, p: any?): number return Catalog.power(kind, "carrier", mut, p) end

Config.MINER_SPEED = 8     -- стадів/с при Швидкості x1 (справжня — stats(kind).mspd)
Config.REACH = 4.4         -- відстань від центру руди до голема для руди радіусом REACH_R (лезо кірки влучає в руду)
Config.REACH_R = 2.8       -- радіус початкової моделі руди; для більшої руди голем стає далі: REACH + (радіус − REACH_R) × 0.8
Config.ORE_GAP = 1.5       -- мінімальний проміжок між сусідніми рудами
Config.MINE_CLIP = 1.4     -- тривалість кліпу Mine в аніматорі (с при AnimSpeed 1)
Config.MINE_HIT = 0.62     -- момент удару в кліпі
Config.PICK_TIME = 0.25    -- носій підбирає стак (05.11.2026, було 0,35)
Config.DROP_TIME = 0.4     -- носій висипає ящичок (05.11.2026, було 0,55)
Config.STACK_RADIUS = 3.2  -- шматки однієї руди ближче за це зливаються в один стак (як предмети в Minecraft)
Config.STACK_MAX = 99
Config.STACK_LIFE = 10     -- с (було 30; 28.10.2026 — 10 за рішенням користувача): стак, який ніхто не підібрав (носій чи гравець), зникає (відлік від останнього шматка)
Config.STACK_BLINK = 5     -- с до зникнення: стак блимає
Config.PICKUP_R = 8.5      -- стади: гравець-власник підходить до стака — руда сама йде в інвентар (було 4,5)
Config.HALF = 20           -- големи й шматки руди тримаються в межах ±HALF стадів від центру плоту

Config.AUTO_EQUIP_PASS = 0 -- геймпас Auto Equip Best (id ще немає)

return Config
