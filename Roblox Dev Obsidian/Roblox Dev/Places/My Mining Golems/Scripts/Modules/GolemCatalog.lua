--!strict
-- GolemCatalog — каталог големів: 24 големи × 3 класи (майнер, носій, воїн), рідкості, мутації, формули.
-- Де: ReplicatedStorage/Shared/GolemCatalog (спільний для сервера й клієнта). Джерело — GDD:
--   Golem Stats - Miner / Carrier / Warrior (значення Normal) і GDD - Golems («Формули мутацій», «Прогресія каталогу»).
-- Змінюєш таблицю в GDD — міняєш і тут (рядок голема = три рядки GDD з тим самим ID).
--
-- Голем у грі: { kind = ID, cls = "miner" | "carrier" | "warrior", mut = 0..7 }.
--   Швидкість — один множник на все: рух 8 × Швидкість стад/с, удар раз на 1,40 / Швидкість с, AnimSpeed = Швидкість.
--   Мутація (Normal = 0 … Secret = 7) — готовий множник сили M (MUTATIONS[].power: 1 / 1,25 / 1,5 / 2 / 3 / 5 / 10 / 25):
--   ціна, шкода, HP, місткість × M, швидкість без змін (27.10.2026; до цього — кроки ×1,35^k / ×1,25^k / ×1,05^k / ×1,5^k).
-- model — ім'я моделі в ReplicatedStorage/PlotAssets (є Stone Golem = "Golem", Wooden Golem = "WoodenGolem", Clay Golem = "ClayGolem", Gravel Golem = "GravelGolem", Mossback Golem = "MossbackGolem", Copperhead Golem = "CopperheadGolem", Flint Golem = "FlintGolem", Rustbolt Golem = "RustboltGolem", Granite Golem = "GraniteGolem", Lantern Golem = "LanternGolem", Ironclad Golem = "IroncladGolem", Quartzling Golem = "QuartzlingGolem", Tinker Golem = "TinkerGolem", Silverjaw Golem = "SilverjawGolem", Geode Golem = "GeodeGolem", Amethyst Golem = "AmethystGolem", Sapphire Golem = "SapphireGolem", Obsidian Golem = "ObsidianGolem", Magmaheart Golem = "MagmaheartGolem", Ruby Golem = "RubyGolem", Frostforged Golem = "FrostforgedGolem", Platinum Golem = "PlatinumGolem", Aurelian Golem = "AurelianGolem", Astral Golem = "AstralGolem"); nil — моделі ще немає.
-- box — ім'я ящичка носія в PlotAssets (Stone = "CarryBox", Wooden = "WoodenCarryBox"). M.model(kind) / M.box(kind) — з фолбеком
--   на "Golem" / "CarryBox"; M.applyClassItems(model, cls, strip, kind?) — предмет у руці за класом (Pickaxe / Sword).
-- pickaxe / sword — ім'я префаба предмета в PlotAssets (Stone = "StonePickaxe" / "StoneSword", Wooden = "WoodenPickaxe" / "WoodenSword");
--   півот префаба = CFrame кулака Fist_L голема в спокої (точка хвату, Attachment Grip). Моделі големів — без предметів.
-- icon — тимчасова PNG-іконка (є не в усіх; без неї — іконка Stone). Назва голема — завжди «<слово> Golem».
-- Старі тестові ID (wood, iron, gold, crystal) перетворюються на нові через LEGACY.

local M = {}

M.BASE_SPEED = 8      -- стад/с при Швидкості x1
M.BASE_INTERVAL = 1.4 -- с між ударами при Швидкості x1
M.FALLBACK_ICON = "rbxassetid://97975821667403" -- іконка Stone Golem

-- рідкості по порядку; кольори Uncommon і вище — пропозиція (поки немає в GDD)
M.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Celestial", "Exclusive" }
M.RARITY_COLOR = {
	Common = Color3.fromHex("9aa3ad"), Uncommon = Color3.fromHex("6ee05a"), Rare = Color3.fromHex("3aa6ff"),
	Epic = Color3.fromHex("c86bff"), Legendary = Color3.fromHex("ffc531"), Mythic = Color3.fromHex("ff4fd8"),
	Divine = Color3.fromHex("fff08a"), Celestial = Color3.fromHex("7ef6ff"), Exclusive = Color3.fromHex("ff5a5a"),
}

-- мутації: odds — шанс «1 до N» при ролі (GDD - Golems, «Мутації»); кольори — пропозиція.
-- 03.11.2026 (рішення користувача): мутації рідші — було 10 / 15 / 40 / 150 / 1,250 / 5,000 / 50,000 (Normal ≈ 80 %), стало
--   25 / 50 / 120 / 400 / 2,500 / 10,000 / 100,000 (Normal ≈ 93 % на старті). Рол: спершу вид голема за його odds, потім поверх — мутація
--   (RollService; удача мутацій — окрема, див. там).
-- color — суцільний колір (рамки, сяйво, текст без анімації); gradient — циклічний візерунок назви (список hex по колу:
-- Shared/MutationText плавно зсуває його вздовж тексту), speed — швидкість переливу (періодів за секунду),
-- shine — білий блиск, що біжить по тексту (Secret). Normal — без градієнта.
M.MUTATIONS = {
	-- power — множник сили M (затверджено користувачем 27.10.2026): 1 / 1,25 / 1,5 / 2 / 3 / 5 / 10 / 25 (див. M.stats)
	{ key = "Normal", power = 1, odds = 1, color = Color3.fromHex("ffffff") },
	{ key = "Bronze", power = 1.25, odds = 25, color = Color3.fromHex("e0874a"), gradient = { "e0874a", "ffc08a", "b5612c", "e0874a", "8f4a1f" }, speed = 0.25 },
	{ key = "Silver", power = 1.5, odds = 50, color = Color3.fromHex("d6dde4"), gradient = { "d6dde4", "ffffff", "9aa6b2", "e8edf2", "8b96a3" }, speed = 0.25 },
	{ key = "Gold", power = 2, odds = 120, color = Color3.fromHex("ffd23a"), gradient = { "ffd23a", "fff3a8", "e0a51c", "ffe066", "b8860b" }, speed = 0.3 },
	{ key = "Diamond", power = 3, odds = 400, color = Color3.fromHex("6fe8ff"), gradient = { "6fe8ff", "e6fdff", "3fa9ff", "b5f4ff", "2f8fe8" }, speed = 0.35 },
	{ key = "Void", power = 5, odds = 2500, color = Color3.fromHex("a24bff"), gradient = { "a24bff", "e2b8ff", "5a1fb0", "c27bff", "3d1478" }, speed = 0.3 },
	{ key = "Rainbow", power = 10, odds = 10000, color = Color3.fromHex("ff6ad5"), gradient = { "ff2a2a", "ff8a00", "ffe600", "22e04a", "00c8ff", "2a5cff", "b02aff" }, speed = 0.35 }, -- насичена веселка (як фон слота, 26.10.2026)
	-- Secret (найвища): голографічний хром — білий + блідо-ціан + блідо-рожевий, блиск, що біжить (погоджено 26.10.2026; до цього —
	-- сріблясто-сталевий b8c4d0, ще раніше — червоний ff3b5c). Фон слота Secret — обсидіан + хром (Shared/MutationSlotFX)
	-- v23 (26.10.2026): чорно-сірий перелив (чорний → графіт → світло-сірий) + білий блиск, що біжить (замість голографічного)
	-- v24 (27.10.2026): світлий перелив (білий / світло-сірий) з графітово-чорною обводкою і білим блиском — читається на темних фонах
	-- (підказка хотбара, картка інвентаря, пігулки Index, таблички над підлогою печери) і на світлих; раніше — темний текст 2a2c30 + біла обводка
	{ key = "Secret", power = 25, odds = 100000, color = Color3.fromHex("5a5f66"), gradient = { "9aa0a8", "dfe3e8", "ffffff", "b4bac2", "f0f2f5", "a3a9b1" }, speed = 0.25, shine = true,
		-- градієнт множиться і на текст, і на обводку: текст білий (перелив світло-сірих), обводка графітово-чорна лишається чорною
		stroke = "14161a" },
}

M.ORDER = { "wooden", "stone", "clay", "gravel", "mossback", "copperhead", "flint", "rustbolt", "granite", "lantern", "ironclad", "quartzling", "tinker", "silverjaw", "geode", "amethyst", "sapphire", "obsidian", "magmaheart", "ruby", "frostforged", "platinum", "aurelian", "astral" }

-- значення Normal; odds — шанс ролу «1 до N»; map — мапа з таблиці GDD
M.GOLEMS = {
	wooden = { name = "Wooden Golem", rarity = "Common", map = 1, odds = 1, size = 1, model = "WoodenGolem", box = "WoodenCarryBox", pickaxe = "WoodenPickaxe", sword = "WoodenSword", icon = "rbxassetid://118736528199973",
		miner = { price = 0, dmg = 1, speed = 1 },
		carrier = { price = 0, cap = 1, speed = 1 },
		warrior = { price = 50, dmg = 1, hp = 10, speed = 1 } },
	stone = { name = "Stone Golem", rarity = "Common", map = 1, odds = 10, size = 1, model = "Golem", box = "CarryBox", pickaxe = "StonePickaxe", sword = "StoneSword", icon = "rbxassetid://97975821667403",
		miner = { price = 150, dmg = 2, speed = 1.05 },
		carrier = { price = 100, cap = 2, speed = 1.125 },
		warrior = { price = 200, dmg = 2, hp = 20, speed = 1.1 } },
	clay = { name = "Clay Golem", rarity = "Common", map = 1, odds = 15, size = 1.05, model = "ClayGolem", box = "ClayCarryBox", pickaxe = "ClayPickaxe", sword = "ClaySword", icon = nil,
		miner = { price = 400, dmg = 3, speed = 0.9 },
		carrier = { price = 230, cap = 3, speed = 0.95 },
		warrior = { price = 610, dmg = 3, hp = 40, speed = 0.9 } },
	gravel = { name = "Gravel Golem", rarity = "Common", map = 1, odds = 25, size = 0.95, model = "GravelGolem", box = "GravelCarryBox", pickaxe = "GravelPickaxe", sword = "GravelSword", icon = nil,
		miner = { price = 850, dmg = 3, speed = 1.2 },
		carrier = { price = 650, cap = 2, speed = 1.25 },
		warrior = { price = 960, dmg = 3, hp = 30, speed = 1.25 } },
	mossback = { name = "Mossback Golem", rarity = "Common", map = 1, odds = 40, size = 1.05, model = "MossbackGolem", box = "MossbackCarryBox", pickaxe = "MossbackPickaxe", sword = "MossbackSword", icon = nil,
		miner = { price = 1400, dmg = 5, speed = 1 },
		carrier = { price = 890, cap = 3, speed = 1.05 },
		warrior = { price = 1900, dmg = 5, hp = 50, speed = 1.05 } },
	copperhead = { name = "Copperhead Golem", rarity = "Uncommon", map = 1, odds = 75, size = 1.05, model = "CopperheadGolem", box = "CopperheadCarryBox", pickaxe = "CopperheadPickaxe", sword = "CopperheadSword", icon = nil,
		miner = { price = 2100, dmg = 6, speed = 1.1 },
		carrier = { price = 1500, cap = 4, speed = 1.15 },
		warrior = { price = 2500, dmg = 6, hp = 60, speed = 1.15 } },
	flint = { name = "Flint Golem", rarity = "Uncommon", map = 1, odds = 120, size = 1, model = "FlintGolem", box = "FlintCarryBox", pickaxe = "FlintPickaxe", sword = "FlintSword", icon = nil,
		miner = { price = 4000, dmg = 7, speed = 1.25 },
		carrier = { price = 3200, cap = 4, speed = 1.3 },
		warrior = { price = 5100, dmg = 7, hp = 70, speed = 1.3 } },
	rustbolt = { name = "Rustbolt Golem", rarity = "Uncommon", map = 1, odds = 200, size = 1.1, model = "RustboltGolem", box = "RustboltCarryBox", pickaxe = "RustboltPickaxe", sword = "RustboltSword", icon = nil,
		miner = { price = 12000, dmg = 12, speed = 0.95 },
		carrier = { price = 6400, cap = 6, speed = 1 },
		warrior = { price = 19000, dmg = 10, hp = 140, speed = 0.95 } },
	granite = { name = "Granite Golem", rarity = "Uncommon", map = 1, odds = 300, size = 1.15, model = "GraniteGolem", box = "GraniteCarryBox", pickaxe = "GranitePickaxe", sword = "GraniteSword", icon = nil,
		miner = { price = 18500, dmg = 15, speed = 1.05 },
		carrier = { price = 11000, cap = 7, speed = 1.1 },
		warrior = { price = 27000, dmg = 13, hp = 180, speed = 1.05 } },
	lantern = { name = "Lantern Golem", rarity = "Uncommon", map = 1, odds = 500, size = 1.05, model = "LanternGolem", box = "LanternCarryBox", pickaxe = "LanternPickaxe", sword = "LanternSword", icon = nil,
		miner = { price = 29500, dmg = 19, speed = 1.15 },
		carrier = { price = 22000, cap = 7, speed = 1.2 },
		warrior = { price = 35000, dmg = 18, hp = 180, speed = 1.2 } },
	ironclad = { name = "Ironclad Golem", rarity = "Rare", map = 1, odds = 900, size = 1.15, model = "IroncladGolem", box = "IroncladCarryBox", pickaxe = "IroncladPickaxe", sword = "IroncladSword", icon = "rbxassetid://133852237833502",
		miner = { price = 36000, dmg = 25, speed = 1 },
		carrier = { price = 20000, cap = 9, speed = 1.05 },
		warrior = { price = 58000, dmg = 21, hp = 290, speed = 1 } },
	quartzling = { name = "Quartzling Golem", rarity = "Rare", map = 1, odds = 1500, size = 0.9, model = "QuartzlingGolem", box = "QuartzlingCarryBox", pickaxe = "QuartzlingPickaxe", sword = "QuartzlingSword", icon = "rbxassetid://125678918437751",
		miner = { price = 75000, dmg = 50, speed = 1.35 },
		carrier = { price = 60000, cap = 11, speed = 1.4 },
		warrior = { price = 85000, dmg = 48, hp = 480, speed = 1.4 } },
	tinker = { name = "Tinker Golem", rarity = "Rare", map = 1, odds = 2500, size = 1, model = "TinkerGolem", box = "TinkerCarryBox", pickaxe = "TinkerPickaxe", sword = "TinkerSword", icon = nil,
		miner = { price = 120000, dmg = 90, speed = 1.2 },
		carrier = { price = 80000, cap = 17, speed = 1.25 },
		warrior = { price = 170000, dmg = 86, hp = 860, speed = 1.25 } },
	silverjaw = { name = "Silverjaw Golem", rarity = "Rare", map = 1, odds = 4000, size = 1.15, model = "SilverjawGolem", box = "SilverjawCarryBox", pickaxe = "SilverjawPickaxe", sword = "SilverjawSword", icon = nil,
		miner = { price = 250000, dmg = 200, speed = 1.15 },
		carrier = { price = 150000, cap = 25, speed = 1.2 },
		warrior = { price = 320000, dmg = 190, hp = 1900, speed = 1.2 } },
	geode = { name = "Geode Golem", rarity = "Epic", map = 1, odds = 8000, size = 1.2, model = "GeodeGolem", box = "GeodeCarryBox", pickaxe = "GeodePickaxe", sword = "GeodeSword", icon = nil,
		miner = { price = 1000000, dmg = 310, speed = 1.1 },
		carrier = { price = 570000, cap = 40, speed = 1.15 },
		warrior = { price = 1600000, dmg = 260, hp = 3600, speed = 1.1 } },
	amethyst = { name = "Amethyst Golem", rarity = "Epic", map = 1, odds = 15000, size = 1.15, model = "AmethystGolem", box = "AmethystCarryBox", pickaxe = "AmethystPickaxe", sword = "AmethystSword", icon = nil,
		miner = { price = 3000000, dmg = 550, speed = 1.4 },
		carrier = { price = 2300000, cap = 40, speed = 1.45 },
		warrior = { price = 3600000, dmg = 530, hp = 5300, speed = 1.45 } },
	sapphire = { name = "Sapphire Golem", rarity = "Epic", map = 1, odds = 25000, size = 1.2, model = "SapphireGolem", box = "SapphireCarryBox", pickaxe = "SapphirePickaxe", sword = "SapphireSword", icon = nil,
		miner = { price = 7500000, dmg = 920, speed = 1.25 },
		carrier = { price = 5200000, cap = 60, speed = 1.3 },
		warrior = { price = 10000000, dmg = 880, hp = 8800, speed = 1.3 } },
	obsidian = { name = "Obsidian Golem", rarity = "Legendary", map = 1, odds = 50000, size = 1.35, model = "ObsidianGolem", box = "ObsidianCarryBox", pickaxe = "ObsidianPickaxe", sword = "ObsidianSword", icon = nil,
		miner = { price = 30000000, dmg = 1200, speed = 1.1 },
		carrier = { price = 16000000, cap = 80, speed = 1.15 },
		warrior = { price = 50000000, dmg = 1000, hp = 14000, speed = 1.1 } },
	magmaheart = { name = "Magmaheart Golem", rarity = "Legendary", map = 3, odds = 100000, size = 1.25, model = "MagmaheartGolem", box = "MagmaheartCarryBox", pickaxe = "MagmaheartPickaxe", sword = "MagmaheartSword", icon = nil,
		miner = { price = 80000000, dmg = 2400, speed = 1.5 },
		carrier = { price = 64000000, cap = 90, speed = 1.55 },
		warrior = { price = 96000000, dmg = 2300, hp = 23000, speed = 1.55 } },
	ruby = { name = "Ruby Golem", rarity = "Legendary", map = 3, odds = 175000, size = 1.4, model = "RubyGolem", box = "RubyCarryBox", pickaxe = "RubyPickaxe", sword = "RubySword", icon = nil,
		miner = { price = 250000000, dmg = 3400, speed = 1.3 },
		carrier = { price = 150000000, cap = 140, speed = 1.35 },
		warrior = { price = 400000000, dmg = 2900, hp = 41000, speed = 1.3 } },
	frostforged = { name = "Frostforged Golem", rarity = "Mythic", map = 4, odds = 400000, size = 1.35, model = "FrostforgedGolem", box = "FrostforgedCarryBox", pickaxe = "FrostforgedPickaxe", sword = "FrostforgedSword", icon = nil,
		miner = { price = 1500000000, dmg = 5200, speed = 1.45 },
		carrier = { price = 1100000000, cap = 140, speed = 1.5 },
		warrior = { price = 1900000000, dmg = 5000, hp = 50000, speed = 1.5 } },
	platinum = { name = "Platinum Golem", rarity = "Mythic", map = 4, odds = 1000000, size = 1.5, model = "PlatinumGolem", box = "PlatinumCarryBox", pickaxe = "PlatinumPickaxe", sword = "PlatinumSword", icon = nil,
		miner = { price = 6000000000, dmg = 7500, speed = 1.3 },
		carrier = { price = 3400000000, cap = 220, speed = 1.35 },
		warrior = { price = 9200000000, dmg = 6400, hp = 90000, speed = 1.3 } },
	aurelian = { name = "Aurelian Golem", rarity = "Divine", map = 5, odds = 2500000, size = 1.45, model = "AurelianGolem", box = "AurelianCarryBox", pickaxe = "AurelianPickaxe", sword = "AurelianSword", icon = "rbxassetid://85164603125451",
		miner = { price = 40000000000, dmg = 9000, speed = 1.7 },
		carrier = { price = 31000000000, cap = 190, speed = 1.75 },
		warrior = { price = 45000000000, dmg = 8700, hp = 87000, speed = 1.75 } },
	astral = { name = "Astral Golem", rarity = "Celestial", map = 6, odds = 10000000, size = 1.5, model = "AstralGolem", box = "AstralCarryBox", pickaxe = "AstralPickaxe", sword = "AstralSword", icon = nil,
		miner = { price = 200000000000, dmg = 12000, speed = 2 },
		carrier = { price = 130000000000, cap = 245, speed = 2.05 },
		warrior = { price = 270000000000, dmg = 12000, hp = 120000, speed = 2.05 } },
}

-- ексклюзиви (не роляться, не в ORDER): Mushroom Golem — нагорода за групу (GroupGolemService, 29.10.2026).
--   dynamic = "bestMiner": шкода майнера = share × шкода найкращого звичайного майнера власника (атрибут BestMinerDmg) × мутація,
--   але не менше за miner.dmg. Власник — аргумент p у stats / power / statText (на клієнті без p — LocalPlayer).
M.GOLEMS.mushroom = { name = "Mushroom Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.05, model = "MushroomGolem", box = "MushroomCarryBox",
	pickaxe = "MushroomPickaxe", sword = "MushroomSword", icon = nil, exclusive = "group", dynamic = "bestMiner", share = 0.5,
	-- носій (29.10.2026, нагорода Daily кожен 7-й день): місткість = carrierShare × місткість найкращого звичайного носія (атрибут BestCarrierCap)
	carrierShare = 0.75,
	-- як отримати (Index, замість шансу ролу): за класом; nil — ще не можна отримати
	how = { miner = "Join the group", carrier = "Weekly reward", warrior = "Boss Shop" }, -- 02.11.2026: Daily → Weekly; 03.11.2026: воїни-ексклюзиви — з Boss Shop
	howShort = { miner = "Group", carrier = "Weekly", warrior = "Boss Shop" }, -- на картці Index (замість «1 in N»)
	miner = { price = 0, dmg = 1, speed = 1.1 },
	carrier = { price = 0, cap = 2, speed = 1.1 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.1 } }

-- Тижневі нагороди Daily (02.11.2026, exclusive = "weekly"): цикл днів 7 / 14 / 21 / 28 — Mushroom / Honey / Snow / Cloud (DailyConfig.WEEKLY).
--   Сила — частка best для всіх класів (як у кейсі), нагорода дає один клас (how — лише для нього).
M.GOLEMS.honey = { name = "Honey Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.05, model = "HoneyGolem", box = "HoneyCarryBox",
	pickaxe = "HoneyPickaxe", sword = "HoneySword", icon = nil, exclusive = "weekly", dynamic = "bestMiner", share = 0.65,
	carrierShare = 0.65, warriorShare = 0.65,
	how = { miner = "Weekly reward", carrier = "Weekly reward", warrior = "Boss Shop" },
	howShort = { miner = "Weekly", carrier = "Weekly", warrior = "Boss Shop" },
	miner = { price = 0, dmg = 1, speed = 1.15 },
	carrier = { price = 0, cap = 2, speed = 1.15 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.15 } }
M.GOLEMS.snow = { name = "Snow Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.1, model = "SnowGolem", box = "SnowCarryBox",
	pickaxe = "SnowPickaxe", sword = "SnowSword", icon = nil, exclusive = "weekly", dynamic = "bestMiner", share = 0.9,
	carrierShare = 0.9, warriorShare = 0.9,
	how = { miner = "Weekly reward", carrier = "Weekly reward", warrior = "Boss Shop" },
	howShort = { miner = "Weekly", carrier = "Weekly", warrior = "Boss Shop" },
	miner = { price = 0, dmg = 1, speed = 1.2 },
	carrier = { price = 0, cap = 2, speed = 1.2 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.2 } }
M.GOLEMS.cloud = { name = "Cloud Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.15, model = "CloudGolem", box = "CloudCarryBox",
	pickaxe = "CloudPickaxe", sword = "CloudSword", icon = nil, exclusive = "weekly", dynamic = "bestMiner", share = 1.5,
	carrierShare = 1.5, warriorShare = 1.5,
	how = { miner = "Weekly reward", carrier = "Weekly reward", warrior = "Boss Shop" },
	howShort = { miner = "Weekly", carrier = "Weekly", warrior = "Boss Shop" },
	miner = { price = 0, dmg = 1, speed = 1.3 },
	carrier = { price = 0, cap = 2, speed = 1.3 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.3 } }

-- Exclusive Case (02.11.2026): 5 големів кейсу ексклюзивів, завжди Normal. Сила — частка best гравця для кожного класу
-- (share / carrierShare / warriorShare: майнер — BestMinerDmg, носій — BestCarrierCap, воїн — BestWarriorDmg і BestWarriorHp),
-- швидкість — власна фіксована. caseChance — шанс у кейсі (CaseService).
M.GOLEMS.coral = { name = "Coral Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.15, model = "CoralGolem", box = "CoralCarryBox",
	pickaxe = "CoralPickaxe", sword = "CoralSword", icon = nil, exclusive = "case", dynamic = "bestMiner", share = 0.65,
	carrierShare = 0.65, warriorShare = 0.65, caseChance = 0.63, -- 03.11.2026: 63 / 20 / 10 / 5 / 2 % (було 88,9 / 8 / 2 / 1 / 0,1)
	how = { miner = "Exclusive Case", carrier = "Exclusive Case", warrior = "Exclusive Case" },
	howShort = { miner = "Case", carrier = "Case", warrior = "Case" },
	miner = { price = 0, dmg = 1, speed = 1.2 },
	carrier = { price = 0, cap = 2, speed = 1.2 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.2 } }
M.GOLEMS.jade = { name = "Jade Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.2, model = "JadeGolem", box = "JadeCarryBox",
	pickaxe = "JadePickaxe", sword = "JadeSword", icon = nil, exclusive = "case", dynamic = "bestMiner", share = 1.0,
	carrierShare = 1.0, warriorShare = 1.0, caseChance = 0.20,
	how = { miner = "Exclusive Case", carrier = "Exclusive Case", warrior = "Exclusive Case" },
	howShort = { miner = "Case", carrier = "Case", warrior = "Case" },
	miner = { price = 0, dmg = 1, speed = 1.35 },
	carrier = { price = 0, cap = 2, speed = 1.35 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.35 } }
M.GOLEMS.storm = { name = "Storm Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.35, model = "StormGolem", box = "StormCarryBox",
	pickaxe = "StormPickaxe", sword = "StormSword", icon = nil, exclusive = "case", dynamic = "bestMiner", share = 1.25,
	carrierShare = 1.25, warriorShare = 1.25, caseChance = 0.10,
	how = { miner = "Exclusive Case", carrier = "Exclusive Case", warrior = "Exclusive Case" },
	howShort = { miner = "Case", carrier = "Case", warrior = "Case" },
	miner = { price = 0, dmg = 1, speed = 1.5 },
	carrier = { price = 0, cap = 2, speed = 1.5 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.5 } }
M.GOLEMS.phantom = { name = "Phantom Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.45, model = "PhantomGolem", box = "PhantomCarryBox",
	pickaxe = "PhantomPickaxe", sword = "PhantomSword", icon = nil, exclusive = "case", dynamic = "bestMiner", share = 1.6,
	carrierShare = 1.6, warriorShare = 1.6, caseChance = 0.05,
	how = { miner = "Exclusive Case", carrier = "Exclusive Case", warrior = "Exclusive Case" },
	howShort = { miner = "Case", carrier = "Case", warrior = "Case" },
	miner = { price = 0, dmg = 1, speed = 1.75 },
	carrier = { price = 0, cap = 2, speed = 1.75 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 1.75 } }
M.GOLEMS.chrono = { name = "Chrono Golem", rarity = "Exclusive", map = 1, odds = 0, size = 1.5, model = "ChronoGolem", box = "ChronoCarryBox",
	pickaxe = "ChronoPickaxe", sword = "ChronoSword", icon = nil, exclusive = "case", dynamic = "bestMiner", share = 2.0,
	carrierShare = 2.0, warriorShare = 2.0, caseChance = 0.02,
	how = { miner = "Exclusive Case", carrier = "Exclusive Case", warrior = "Exclusive Case" },
	howShort = { miner = "Case", carrier = "Case", warrior = "Case" },
	miner = { price = 0, dmg = 1, speed = 2.0 },
	carrier = { price = 0, cap = 2, speed = 2.0 },
	warrior = { price = 0, dmg = 1, hp = 10, speed = 2.0 } }

M.LEGACY = { wood = "wooden", iron = "ironclad", gold = "aurelian", crystal = "quartzling" }

for i, id in M.ORDER do
	local g = (M.GOLEMS :: any)[id]
	g.id = id
	g.index = i
end
M.GOLEMS.mushroom.id = "mushroom"
M.GOLEMS.mushroom.index = #M.ORDER + 1
-- ексклюзиви по порядку (Index: група Exclusive після Celestial, лише сторінка Normal; 30.10.2026)
M.EXCLUSIVES = { "mushroom", "honey", "snow", "cloud", "coral", "jade", "storm", "phantom", "chrono" }
for i, id in M.EXCLUSIVES do
	local g = (M.GOLEMS :: any)[id]
	g.id = id
	g.index = #M.ORDER + i
end
-- як отримати ексклюзив цього класу (текст) або "Coming soon"; short — короткий (картка Index) або "Soon"
function M.howToGet(kind: any, cls: any, short: boolean?): string
	local g = (M.GOLEMS :: any)[kind]
	local t = g and (short and g.howShort or g.how)
	return (t and t[cls]) or (short and "Soon" or "Coming soon")
end

-- нормалізований ID (з урахуванням старих) або nil
function M.id(kind: any): string?
	if type(kind) ~= "string" then return nil end
	if (M.GOLEMS :: any)[kind] then return kind end
	return M.LEGACY[kind]
end

function M.get(kind: any): any
	local id = M.id(kind)
	return id and (M.GOLEMS :: any)[id] or nil
end

function M.cls(cls: any): string
	return (cls == "carrier" or cls == "warrior") and cls or "miner"
end

function M.mut(m: any): number
	local k = math.floor(tonumber(m) or 0)
	return math.clamp(k, 0, #M.MUTATIONS - 1)
end

function M.mutation(m: any): any
	return M.MUTATIONS[M.mut(m) + 1]
end

function M.rarityColor(r: string?): Color3
	return (r and M.RARITY_COLOR[r]) or M.RARITY_COLOR.Common
end

function M.icon(kind: any): string
	local g = M.get(kind)
	return (g and g.icon) or M.FALLBACK_ICON
end

-- ім'я моделі голема в PlotAssets (немає своєї — "Golem", Stone)
function M.model(kind: any): string
	local g = M.get(kind)
	return (g and g.model) or "Golem"
end

-- ім'я ящичка носія в PlotAssets (немає свого — "CarryBox")
function M.box(kind: any): string
	local g = M.get(kind)
	return (g and g.box) or "CarryBox"
end

-- предмет у руці за класом (27.10.2026: окремі префаби): майнер — клон PlotAssets/<pickaxe> під ім'ям "Pickaxe",
-- воїн — PlotAssets/<sword> під ім'ям "Sword", носій — нічого. Предмет ставиться півотом у кулак Fist_L моделі
-- (викликати, поки модель у позі спокою, до анімації); кожна деталь отримує атрибут FistRel (CFrame відносно
-- кулака), модель предмета — Scale0 і Hand: за ними GolemAnimator водить предмет за кулаком. Старі предмети
-- видаляються. kind — ID голема (без нього — атрибут Kind моделі або GolemKind шаблону). strip — залишено для
-- сумісності (непотрібних груп тепер немає в жодному випадку).
function M.applyClassItems(model: Instance, cls: any, strip: boolean?, kind: any?)
	local c = M.cls(cls)
	for _, n in { "Pickaxe", "Sword" } do
		local old = model:FindFirstChild(n)
		if old then old:Destroy() end
	end
	local slot = if c == "miner" then "pickaxe" elseif c == "warrior" then "sword" else nil
	if not slot then return end
	local g = M.get(kind or model:GetAttribute("Kind") or model:GetAttribute("GolemKind"))
	-- голем без власної моделі показується моделлю Stone (M.model) — і предмет тоді Stone
	local key = if g and g.model then g[slot] else (M.GOLEMS :: any).stone[slot]
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("PlotAssets")
	local src = key and assets and assets:FindFirstChild(key)
	local hand = model:FindFirstChild((src and src:GetAttribute("Hand") :: string?) or "Fist_L")
	if not src or not src:IsA("Model") or not hand or not hand:IsA("BasePart") then return end
	local it = src:Clone()
	it.Name = if slot == "pickaxe" then "Pickaxe" else "Sword"
	it:SetAttribute("PrefabOf", nil)
	local k = if model:IsA("Model") then model:GetScale() else 1
	if math.abs(k - it:GetScale()) > 1e-4 then it:ScaleTo(k) end
	it:PivotTo(hand.CFrame)
	it:SetAttribute("Hand", hand.Name)
	it:SetAttribute("Scale0", k)
	for _, d in it:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = hand.Anchored; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Massless = true
			d:SetAttribute("FistRel", hand.CFrame:ToObjectSpace(d.CFrame))
		end
	end
	it.Parent = model
end

-- статична поза «несе ящичок» для моделей без аніматора (слот, фігурка): руки як у GolemAnimator.holdPose,
-- ящичок між кулаками (та сама формула, що в аніматорі). data — require(GolemData) моделі; викликати до ScaleTo.
local HOLD = { UpperArm_R = { -0.95, 0, 0.32 }, UpperArm_L = { -0.95, 0, -0.32 }, Forearm_R = { -0.55, 0, 0 }, Forearm_L = { -0.55, 0, 0 } }
function M.poseCarry(model: Model, data: any, box: Model?)
	local root = model:FindFirstChild("Root")
	if not root or not root:IsA("BasePart") or type(data) ~= "table" then return end
	local scale = model:GetScale()
	local S = 0.5 * scale
	local base = root.CFrame * CFrame.Angles(0, math.pi, 0)
	local byName = {}
	for _, b in data.bones do byName[b.name] = b end
	local cache: { [string]: CFrame } = {}
	local function boneCF(name: string): CFrame
		if cache[name] then return cache[name] end
		local b = byName[name]
		local r = HOLD[name]
		local rot = if r then CFrame.Angles(0, 0, r[3]) * CFrame.Angles(0, r[2], 0) * CFrame.Angles(r[1], 0, 0) else CFrame.identity
		local cf
		if b.parent and byName[b.parent] then
			cf = boneCF(b.parent) * CFrame.new((b.pos - byName[b.parent].pos) * S) * rot
		else
			cf = CFrame.new(b.pos * S) * rot
		end
		cache[name] = cf
		return cf
	end
	for _, blk in data.blocks do
		if HOLD[blk.bone] and byName[blk.bone] then
			local cont = if blk.group then model:FindFirstChild(blk.group) else model
			local part = cont and cont:FindFirstChild(blk.name)
			if part and part:IsA("BasePart") then
				local pos = if blk.cf then blk.cf.Position else blk.c
				local rot = if blk.cf then blk.cf.Rotation else CFrame.Angles(0, 0, blk.rz or 0)
				part.CFrame = base * boneCF(blk.bone) * CFrame.new((pos - byName[blk.bone].pos) * S) * rot
			end
		end
	end
	if box then
		local fl, fr = model:FindFirstChild("Fist_L"), model:FindFirstChild("Fist_R")
		if fl and fr and fl:IsA("BasePart") and fr:IsA("BasePart") then
			local mid = (fl.Position + fr.Position) / 2
			local ctr = (box:GetAttribute("CenterY") :: number?) or 0.575
			box:PivotTo(CFrame.new(mid) * root.CFrame.Rotation * CFrame.new(0, -(ctr + 0.75) * scale, 0))
		end
	end
end

-- множник сили мутації M (Normal 1 … Secret 25)
function M.mult(mut: any): number
	return M.mutation(mut).power or 1
end

-- число для підписів: ціле — без коми, дрібне — один знак (2.4)
function M.num(n: number): string
	if n == math.floor(n) then return string.format("%d", n) end
	return (string.format("%.1f", n):gsub("%.0$", ""))
end

-- характеристики голема з урахуванням мутації (27.10.2026: готовий множник сили M з MUTATIONS[].power).
-- Швидкість — як у Normal; шкода, HP, місткість і ціна — × M. Округлення: шкода < 10 — до 0,1 (2 × 1,2 = 2,4),
-- інакше ціле; HP — ціле; місткість — ціле, але при M > 1 не менше за базову + 1; ціна — ціле.
-- Повертає { price, speed, move (стад/с), interval (с), dmg?, cap?, hp?, size, mult }
-- динамічна шкода ексклюзиву (dynamic = "bestMiner"): власник p або (на клієнті) LocalPlayer
local RunService = game:GetService("RunService")
local function ownerOf(p: any): any
	if p then return p end
	if RunService:IsClient() then return game:GetService("Players").LocalPlayer end
	return nil
end
-- найкраща шкода звичайного майнера зі списку записів { kind, cls, mut } (ексклюзи з dynamic не рахуються)
function M.bestMinerDmg(list: { any }): number
	local best = 0
	for _, g in list do
		if type(g) == "table" and M.cls(g.cls) == "miner" then
			local d = M.get(g.kind)
			if d and not d.dynamic then
				local s = M.stats(d.id, "miner", g.mut)
				if (s.dmg or 0) > best then best = s.dmg end
			end
		end
	end
	return best
end

-- найкраща місткість звичайного носія (ексклюзи з dynamic не рахуються) — для Mushroom Golem-носія (carrierShare)
function M.bestCarrierCap(list: { any }): number
	local best = 0
	for _, g in list do
		if type(g) == "table" and M.cls(g.cls) == "carrier" then
			local d = M.get(g.kind)
			if d and not d.dynamic then
				local s = M.stats(d.id, "carrier", g.mut)
				if (s.cap or 0) > best then best = s.cap end
			end
		end
	end
	return best
end

-- найкращий звичайний воїн (за силою dmg/interval × hp; ексклюзи з dynamic не рахуються) — його шкода й HP (для warriorShare)
function M.bestWarrior(list: { any }): (number, number)
	local bp, bd, bh = 0, 0, 0
	for _, g in list do
		if type(g) == "table" and M.cls(g.cls) == "warrior" then
			local d = M.get(g.kind)
			if d and not d.dynamic then
				local s = M.stats(d.id, "warrior", g.mut)
				local pw = (s.dmg or 0) / s.interval * (s.hp or 0)
				if pw > bp then bp, bd, bh = pw, s.dmg, s.hp end
			end
		end
	end
	return bd, bh
end

function M.stats(kind: any, cls: any, mut: any, p: any?): any
	local g = M.get(kind) or M.GOLEMS.wooden
	local c = M.cls(cls)
	local base = (g :: any)[c]
	local m = M.mult(mut)
	if g.dynamic == "bestMiner" and c == "miner" then
		local o = ownerOf(p)
		local best = o and tonumber(o:GetAttribute("BestMinerDmg")) or 0
		base = table.clone(base)
		base.dmg = math.max(base.dmg, (g.share or 0.5) * best)
	end
	if g.carrierShare and c == "carrier" then
		local o = ownerOf(p)
		local best = o and tonumber(o:GetAttribute("BestCarrierCap")) or 0
		base = table.clone(base)
		base.cap = math.max(base.cap, math.floor(g.carrierShare * best + 0.5))
	end
	if g.warriorShare and c == "warrior" then
		local o = ownerOf(p)
		local bd = o and tonumber(o:GetAttribute("BestWarriorDmg")) or 0
		local bh = o and tonumber(o:GetAttribute("BestWarriorHp")) or 0
		base = table.clone(base)
		base.dmg = math.max(base.dmg, g.warriorShare * bd)
		base.hp = math.max(base.hp, math.floor(g.warriorShare * bh + 0.5))
	end
	local speed = base.speed
	local function round(x) return math.floor(x + 0.5) end
	local s: any = {
		mult = m,
		price = round(base.price * m),
		speed = speed,
		move = M.BASE_SPEED * speed,
		interval = M.BASE_INTERVAL / speed,
		size = g.size,
	}
	if base.dmg then
		local d = base.dmg * m
		s.dmg = d < 10 and math.floor(d * 10 + 0.5) / 10 or round(d)
	end
	if base.hp then s.hp = round(base.hp * m) end
	if base.cap then
		s.cap = round(base.cap * m)
		if m > 1 then s.cap = math.max(s.cap, base.cap + 1) end
	end
	return s
end

-- сила для сортування (Equip Best): майнер — шкода за секунду, носій — руди за секунду руху, воїн — шкода за секунду × HP
function M.power(kind: any, cls: any, mut: any, p: any?): number
	local c = M.cls(cls)
	local s = M.stats(kind, c, mut, p)
	if c == "carrier" then return s.cap * s.move end
	if c == "warrior" then return s.dmg / s.interval * s.hp end
	return s.dmg / s.interval
end

-- короткий підпис статів для UI: "2 dmg · Speed x1.05", "2 ore · Speed x1.13", "2 dmg · 20 HP"
function M.statText(kind: any, cls: any, mut: any, p: any?): string
	local c = M.cls(cls)
	local s = M.stats(kind, c, mut, p)
	local sp = string.format("x%.2f", math.floor(s.speed * 100 + 0.5) / 100):gsub("0+$", ""):gsub("%.$", "") -- 1.125 → x1.13
	if c == "carrier" then return M.num(s.cap) .. " ore · Speed " .. sp end
	if c == "warrior" then return M.num(s.dmg) .. " dmg · " .. M.num(s.hp) .. " HP" end
	return M.num(s.dmg) .. " dmg · Speed " .. sp -- 2.4 dmg (без %d — дрібна шкода)
end

-- частка best ексклюзиву для класу (0.65 = 65 %) або nil (звичайний голем / клас без частки). 02.11.2026
function M.bestShare(kind: any, cls: any): number?
	local g = M.get(kind)
	if not g or not g.dynamic then return nil end
	local c = M.cls(cls)
	if c == "carrier" then return g.carrierShare elseif c == "warrior" then return g.warriorShare end
	return g.share
end
-- підпис «65% BEST» над рідкістю ексклюзиву (табличка в руці, відкриття кейса, підказка хотбара) або nil
M.BEST_COLOR = Color3.fromHex("ffd23a")
-- Index (03.11.2026): за кожен запис ексклюзиву — 100 діамантів; ексклюзив відкриває лише запис свого класу (IndexService)
M.EXCLUSIVE_INDEX_REWARD = 100
function M.bestText(kind: any, cls: any): string?
	local s = M.bestShare(kind, cls)
	if not s then return nil end
	return string.format("%g", math.floor(s * 1000 + 0.5) / 10) .. "% BEST"
end

return M
