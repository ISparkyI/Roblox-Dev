--!strict
-- PlotConfig — плоти (зони фарму, GDD 5): руда, големи на плоті, картки прокачки. Спільний для сервера (PlotService) і клієнта.
-- Де: ReplicatedStorage/Shared/PlotConfig. Ціни — для мапи 1 (пропозиція), округлення вниз.
local Catalog = require(script.Parent:WaitForChild("GolemCatalog"))
local Config = {}

Config.MAX_PLOTS = 6     -- плоти купуються по черзі 1→6 (1 ближній лівий, 2 ближній правий, 3 середній лівий ...)
Config.MAX_POINTS = 10   -- максимум руди на плоті одночасно (картка Ore Limit, старт 1); місце руди — випадкове

-- руда мапи 1: HP і шанс спавну «1 до N» (шанси працюють як ваги: кожен спавн дає одну з трьох руд)
Config.ORES = {
	{ key = "Coal", hp = 5, odds = 3 },
	{ key = "Copper", hp = 15, odds = 9 },
	{ key = "Iron", hp = 30, odds = 20 },
}
function Config.rollOre(r: Random): any
	local total = 0
	for _, o in Config.ORES do total += 1 / o.odds end
	local x = r:NextNumber() * total
	for _, o in Config.ORES do
		x -= 1 / o.odds
		if x <= 0 then return o end
	end
	return Config.ORES[1]
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
	return math.max(1, math.floor(n * Config.dropOf(dropLvl)))
end
function Config.oreChance(key: string): number -- частка у відсотках (для UI / GDD)
	local total, mine = 0, 0
	for _, o in Config.ORES do total += 1 / o.odds; if o.key == key then mine = 1 / o.odds end end
	return mine / total * 100
end

-- ===== картки прокачки (діють на ВСІ плоти; рівень 1 = старт) =====
Config.SPAWN_START, Config.SPAWN_STEP, Config.SPAWN_MIN = 5, 0.25, 0.25
function Config.spawnOf(l: number): number return math.max(Config.SPAWN_MIN, Config.SPAWN_START - (l - 1) * Config.SPAWN_STEP) end
function Config.slotsOf(l: number): number return math.clamp(l, 1, 5) end
function Config.carryOf(l: number): number return math.min(3, 1 + (l - 1) * 0.25) end
function Config.plotsOf(l: number): number return math.clamp(l, 1, Config.MAX_PLOTS) end
function Config.pointsOf(l: number): number return math.clamp(l, 1, Config.MAX_POINTS) end
function Config.dropOf(l: number): number return math.min(10, 1 + (l - 1) * 0.5) end
function Config.crateOf(l: number): number return math.clamp(l, 1, 100) * 10 end -- місткість ящика плоту: 10 → 1000
Config.CRATE_VISUAL = 16 -- руда в ящику — один щільний шар 4 × 4 шматки; він піднімається від дна до краю з заповненням

Config.CARDS = {
	Plots = { name = "Plots", max = 6, price = function(l: number) return math.floor(150 * 5 ^ (l - 1)) end },        -- 150 … 93,750
	Points = { name = "Ore Limit", max = 10, price = function(l: number) return math.floor(300 * 2.2 ^ (l - 1)) end },  -- 1 → 10 руди на плоті: 300 … 164,629
	Spawn = { name = "Ore Spawn", max = 20, price = function(l: number) return math.floor(150 * 1.5 ^ (l - 1)) end },   -- 5 с → 0,25 с: 150 … 221,683
	Slots = { name = "Golem Slots", max = 5, price = function(l: number) return math.floor(400 * 5 ^ (l - 1)) end },    -- 1 → 5 майнерів: 400 … 50,000
	Carry = { name = "Carrier Speed", max = 9, price = function(l: number) return math.floor(250 * 2 ^ (l - 1)) end },  -- ×1 → ×3: 250 … 32,000
	Crate = { name = "Crate Capacity", max = 100, price = function(l: number) return math.floor(100 * 1.06 ^ (l - 1)) end },      -- 10 → 1000 руди в ящику, +10: 100 … 30,197
	Drop = { name = "Ore Drop", max = 19, price = function(l: number) return math.floor(300 * 1.6 ^ (l - 1)) end },      -- ×1 → ×10 шматків з руди: 300 … 885,443
	-- Auto Sell: руда з ящика продається сама (рівень 1 = Off, 2 = On). Відкривається на другій карті (Stage >= minStage).
	-- Механіка й ціна — разом із другою картою; ЦІНА — ЗАГЛУШКА, її задасть користувач.
	AutoSell = { name = "Auto Sell", max = 2, minStage = 2, price = function(l: number) return 100000 end },
}
Config.CARD_ORDER = { "Plots", "Points", "Spawn", "Slots", "Carry", "Crate", "Drop", "AutoSell" }
-- чи відкрита картка для гравця на етапі stage
function Config.cardOpen(key: string, stage: number?): boolean
	local c = Config.CARDS[key]
	return c ~= nil and (c.minStage == nil or (stage or 1) >= c.minStage)
end
function Config.defaultLevels(): { [string]: number }
	local t = {}
	for k in Config.CARDS do t[k] = 1 end
	return t
end

-- ===== големи на плоті — характеристики з каталогу (Shared/GolemCatalog, GDD Golem Stats) з урахуванням мутації =====
-- майнер: dmg — шкода за удар, int — інтервал удару (с), mspd — рух (стад/с), anim — AnimSpeed (= Швидкість);
-- носій: cap — руди за ходку, spd — рух (стад/с, ще × картка Carrier Speed)
function Config.stats(kind: string, mut: number?): any
	local m = Catalog.stats(kind, "miner", mut)
	local c = Catalog.stats(kind, "carrier", mut)
	return { dmg = m.dmg, int = m.interval, mspd = m.move, anim = m.speed, cap = c.cap, spd = c.move }
end
function Config.minerPower(kind: string, mut: number?): number return Catalog.power(kind, "miner", mut) end
function Config.carrierPower(kind: string, mut: number?): number return Catalog.power(kind, "carrier", mut) end

Config.MINER_SPEED = 8     -- стадів/с при Швидкості x1 (справжня — stats(kind).mspd)
Config.REACH = 4.4         -- відстань від центру руди до голема для руди радіусом REACH_R (лезо кірки влучає в руду)
Config.REACH_R = 2.8       -- радіус початкової моделі руди; для більшої руди голем стає далі: REACH + (радіус − REACH_R) × 0.8
Config.ORE_GAP = 1.5       -- мінімальний проміжок між сусідніми рудами
Config.MINE_CLIP = 1.4     -- тривалість кліпу Mine в аніматорі (с при AnimSpeed 1)
Config.MINE_HIT = 0.62     -- момент удару в кліпі
Config.PICK_TIME = 0.35    -- носій підбирає стак
Config.DROP_TIME = 0.55    -- носій висипає ящичок
Config.STACK_RADIUS = 3.2  -- шматки однієї руди ближче за це зливаються в один стак (як предмети в Minecraft)
Config.STACK_MAX = 99
Config.STACK_LIFE = 30     -- с: стак, який ніхто не підібрав (носій чи гравець), зникає (відлік від останнього шматка)
Config.STACK_BLINK = 5     -- с до зникнення: стак блимає
Config.PICKUP_R = 8.5      -- стади: гравець-власник підходить до стака — руда сама йде в інвентар (було 4,5)
Config.HALF = 20           -- големи й шматки руди тримаються в межах ±HALF стадів від центру плоту

Config.AUTO_EQUIP_PASS = 0 -- геймпас Auto Equip Best (id ще немає)

return Config
