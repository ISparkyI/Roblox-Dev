--!strict
-- GolemCatalog — каталог големів: 24 големи × 3 класи (майнер, носій, воїн), рідкості, мутації, формули.
-- Де: ReplicatedStorage/Shared/GolemCatalog (спільний для сервера й клієнта). Джерело — GDD:
--   Golem Stats - Miner / Carrier / Warrior (значення Normal) і GDD - Golems («Формули мутацій», «Прогресія каталогу»).
-- Змінюєш таблицю в GDD — міняєш і тут (рядок голема = три рядки GDD з тим самим ID).
--
-- Голем у грі: { kind = ID, cls = "miner" | "carrier" | "warrior", mut = 0..7 }.
--   Швидкість — один множник на все: рух 8 × Швидкість стад/с, удар раз на 1,40 / Швидкість с, AnimSpeed = Швидкість.
--   Мутація k (Normal = 0 … Secret = 7): ціна ×1,5^k, шкода й HP ×1,35^k, місткість ×1,25^k (вниз), швидкість ×1,05^k.
-- model — ім'я моделі в ReplicatedStorage/PlotAssets (поки є тільки Stone Golem = "Golem"); nil — моделі ще немає.
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

-- мутації: odds — шанс «1 до N» при ролі (GDD - Golems, «Мутації»); кольори — пропозиція
M.MUTATIONS = {
	{ key = "Normal", odds = 1, color = Color3.fromHex("ffffff") },
	{ key = "Bronze", odds = 10, color = Color3.fromHex("e0874a") },
	{ key = "Silver", odds = 15, color = Color3.fromHex("d6dde4") },
	{ key = "Gold", odds = 40, color = Color3.fromHex("ffd23a") },
	{ key = "Diamond", odds = 150, color = Color3.fromHex("6fe8ff") },
	{ key = "Void", odds = 1250, color = Color3.fromHex("a24bff") },
	{ key = "Rainbow", odds = 5000, color = Color3.fromHex("ff6ad5") },
	{ key = "Secret", odds = 50000, color = Color3.fromHex("ff3b5c") },
}

M.ORDER = { "wooden", "stone", "clay", "gravel", "mossback", "copperhead", "flint", "rustbolt", "granite", "lantern", "ironclad", "quartzling", "tinker", "silverjaw", "geode", "amethyst", "sapphire", "obsidian", "magmaheart", "ruby", "frostforged", "platinum", "aurelian", "astral" }

-- значення Normal; odds — шанс ролу «1 до N»; map — мапа з таблиці GDD
M.GOLEMS = {
	wooden = { name = "Wooden Golem", rarity = "Common", map = 1, odds = 1, size = 1, model = nil, icon = "rbxassetid://118736528199973",
		miner = { price = 0, dmg = 1, speed = 1 },
		carrier = { price = 0, cap = 1, speed = 1 },
		warrior = { price = 50, dmg = 1, hp = 10, speed = 1 } },
	stone = { name = "Stone Golem", rarity = "Common", map = 1, odds = 10, size = 1, model = "Golem", icon = "rbxassetid://97975821667403",
		miner = { price = 150, dmg = 2, speed = 1.05 },
		carrier = { price = 100, cap = 2, speed = 1.125 },
		warrior = { price = 200, dmg = 2, hp = 20, speed = 1.1 } },
	clay = { name = "Clay Golem", rarity = "Common", map = 1, odds = 15, size = 1.05, model = nil, icon = nil,
		miner = { price = 400, dmg = 3, speed = 0.9 },
		carrier = { price = 230, cap = 3, speed = 0.95 },
		warrior = { price = 610, dmg = 3, hp = 40, speed = 0.9 } },
	gravel = { name = "Gravel Golem", rarity = "Common", map = 1, odds = 25, size = 0.95, model = nil, icon = nil,
		miner = { price = 850, dmg = 3, speed = 1.2 },
		carrier = { price = 650, cap = 2, speed = 1.25 },
		warrior = { price = 960, dmg = 3, hp = 30, speed = 1.25 } },
	mossback = { name = "Mossback Golem", rarity = "Common", map = 1, odds = 40, size = 1.05, model = nil, icon = nil,
		miner = { price = 1400, dmg = 5, speed = 1 },
		carrier = { price = 890, cap = 3, speed = 1.05 },
		warrior = { price = 1900, dmg = 5, hp = 50, speed = 1.05 } },
	copperhead = { name = "Copperhead Golem", rarity = "Uncommon", map = 1, odds = 75, size = 1.05, model = nil, icon = nil,
		miner = { price = 2100, dmg = 6, speed = 1.1 },
		carrier = { price = 1500, cap = 4, speed = 1.15 },
		warrior = { price = 2500, dmg = 6, hp = 60, speed = 1.15 } },
	flint = { name = "Flint Golem", rarity = "Uncommon", map = 1, odds = 120, size = 1, model = nil, icon = nil,
		miner = { price = 4000, dmg = 7, speed = 1.25 },
		carrier = { price = 3200, cap = 4, speed = 1.3 },
		warrior = { price = 5100, dmg = 7, hp = 70, speed = 1.3 } },
	rustbolt = { name = "Rustbolt Golem", rarity = "Uncommon", map = 1, odds = 200, size = 1.1, model = nil, icon = nil,
		miner = { price = 12000, dmg = 12, speed = 0.95 },
		carrier = { price = 6400, cap = 6, speed = 1 },
		warrior = { price = 19000, dmg = 10, hp = 140, speed = 0.95 } },
	granite = { name = "Granite Golem", rarity = "Uncommon", map = 1, odds = 300, size = 1.15, model = nil, icon = nil,
		miner = { price = 18500, dmg = 15, speed = 1.05 },
		carrier = { price = 11000, cap = 7, speed = 1.1 },
		warrior = { price = 27000, dmg = 13, hp = 180, speed = 1.05 } },
	lantern = { name = "Lantern Golem", rarity = "Uncommon", map = 1, odds = 500, size = 1.05, model = nil, icon = nil,
		miner = { price = 29500, dmg = 19, speed = 1.15 },
		carrier = { price = 22000, cap = 7, speed = 1.2 },
		warrior = { price = 35000, dmg = 18, hp = 180, speed = 1.2 } },
	ironclad = { name = "Ironclad Golem", rarity = "Rare", map = 1, odds = 900, size = 1.15, model = nil, icon = "rbxassetid://133852237833502",
		miner = { price = 36000, dmg = 25, speed = 1 },
		carrier = { price = 20000, cap = 9, speed = 1.05 },
		warrior = { price = 58000, dmg = 21, hp = 290, speed = 1 } },
	quartzling = { name = "Quartzling Golem", rarity = "Rare", map = 1, odds = 1500, size = 0.9, model = nil, icon = "rbxassetid://125678918437751",
		miner = { price = 75000, dmg = 50, speed = 1.35 },
		carrier = { price = 60000, cap = 11, speed = 1.4 },
		warrior = { price = 85000, dmg = 48, hp = 480, speed = 1.4 } },
	tinker = { name = "Tinker Golem", rarity = "Rare", map = 1, odds = 2500, size = 1, model = nil, icon = nil,
		miner = { price = 120000, dmg = 90, speed = 1.2 },
		carrier = { price = 80000, cap = 17, speed = 1.25 },
		warrior = { price = 170000, dmg = 86, hp = 860, speed = 1.25 } },
	silverjaw = { name = "Silverjaw Golem", rarity = "Rare", map = 1, odds = 4000, size = 1.15, model = nil, icon = nil,
		miner = { price = 250000, dmg = 200, speed = 1.15 },
		carrier = { price = 150000, cap = 25, speed = 1.2 },
		warrior = { price = 320000, dmg = 190, hp = 1900, speed = 1.2 } },
	geode = { name = "Geode Golem", rarity = "Epic", map = 1, odds = 8000, size = 1.2, model = nil, icon = nil,
		miner = { price = 1000000, dmg = 310, speed = 1.1 },
		carrier = { price = 570000, cap = 40, speed = 1.15 },
		warrior = { price = 1600000, dmg = 260, hp = 3600, speed = 1.1 } },
	amethyst = { name = "Amethyst Golem", rarity = "Epic", map = 1, odds = 15000, size = 1.15, model = nil, icon = nil,
		miner = { price = 3000000, dmg = 550, speed = 1.4 },
		carrier = { price = 2300000, cap = 40, speed = 1.45 },
		warrior = { price = 3600000, dmg = 530, hp = 5300, speed = 1.45 } },
	sapphire = { name = "Sapphire Golem", rarity = "Epic", map = 1, odds = 25000, size = 1.2, model = nil, icon = nil,
		miner = { price = 7500000, dmg = 920, speed = 1.25 },
		carrier = { price = 5200000, cap = 60, speed = 1.3 },
		warrior = { price = 10000000, dmg = 880, hp = 8800, speed = 1.3 } },
	obsidian = { name = "Obsidian Golem", rarity = "Legendary", map = 1, odds = 50000, size = 1.35, model = nil, icon = nil,
		miner = { price = 30000000, dmg = 1200, speed = 1.1 },
		carrier = { price = 16000000, cap = 80, speed = 1.15 },
		warrior = { price = 50000000, dmg = 1000, hp = 14000, speed = 1.1 } },
	magmaheart = { name = "Magmaheart Golem", rarity = "Legendary", map = 3, odds = 100000, size = 1.25, model = nil, icon = nil,
		miner = { price = 80000000, dmg = 2400, speed = 1.5 },
		carrier = { price = 64000000, cap = 90, speed = 1.55 },
		warrior = { price = 96000000, dmg = 2300, hp = 23000, speed = 1.55 } },
	ruby = { name = "Ruby Golem", rarity = "Legendary", map = 3, odds = 175000, size = 1.4, model = nil, icon = nil,
		miner = { price = 250000000, dmg = 3400, speed = 1.3 },
		carrier = { price = 150000000, cap = 140, speed = 1.35 },
		warrior = { price = 400000000, dmg = 2900, hp = 41000, speed = 1.3 } },
	frostforged = { name = "Frostforged Golem", rarity = "Mythic", map = 4, odds = 400000, size = 1.35, model = nil, icon = nil,
		miner = { price = 1500000000, dmg = 5200, speed = 1.45 },
		carrier = { price = 1100000000, cap = 140, speed = 1.5 },
		warrior = { price = 1900000000, dmg = 5000, hp = 50000, speed = 1.5 } },
	platinum = { name = "Platinum Golem", rarity = "Mythic", map = 4, odds = 1000000, size = 1.5, model = nil, icon = nil,
		miner = { price = 6000000000, dmg = 7500, speed = 1.3 },
		carrier = { price = 3400000000, cap = 220, speed = 1.35 },
		warrior = { price = 9200000000, dmg = 6400, hp = 90000, speed = 1.3 } },
	aurelian = { name = "Aurelian Golem", rarity = "Divine", map = 5, odds = 2500000, size = 1.45, model = nil, icon = "rbxassetid://85164603125451",
		miner = { price = 40000000000, dmg = 9000, speed = 1.7 },
		carrier = { price = 31000000000, cap = 190, speed = 1.75 },
		warrior = { price = 45000000000, dmg = 8700, hp = 87000, speed = 1.75 } },
	astral = { name = "Astral Golem", rarity = "Celestial", map = 6, odds = 10000000, size = 1.5, model = nil, icon = nil,
		miner = { price = 200000000000, dmg = 12000, speed = 2 },
		carrier = { price = 130000000000, cap = 245, speed = 2.05 },
		warrior = { price = 270000000000, dmg = 12000, hp = 120000, speed = 2.05 } },
}

M.LEGACY = { wood = "wooden", iron = "ironclad", gold = "aurelian", crystal = "quartzling" }

for i, id in M.ORDER do
	local g = (M.GOLEMS :: any)[id]
	g.id = id
	g.index = i
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

-- характеристики голема з урахуванням мутації.
-- Повертає { price, speed, move (стад/с), interval (с), dmg?, cap?, hp?, size }
function M.stats(kind: any, cls: any, mut: any): any
	local g = M.get(kind) or M.GOLEMS.wooden
	local c = M.cls(cls)
	local base = (g :: any)[c]
	local k = M.mut(mut)
	local speed = base.speed * 1.05 ^ k
	local s: any = {
		price = math.floor(base.price * 1.5 ^ k + 1e-6),
		speed = speed,
		move = M.BASE_SPEED * speed,
		interval = M.BASE_INTERVAL / speed,
		size = g.size,
	}
	if base.dmg then s.dmg = math.max(1, math.floor(base.dmg * 1.35 ^ k + 1e-6)) end
	if base.hp then s.hp = math.max(1, math.floor(base.hp * 1.35 ^ k + 1e-6)) end
	if base.cap then s.cap = math.max(1, math.floor(base.cap * 1.25 ^ k + 1e-6)) end
	return s
end

-- сила для сортування (Equip Best): майнер — шкода за секунду, носій — руди за секунду руху, воїн — шкода за секунду × HP
function M.power(kind: any, cls: any, mut: any): number
	local c = M.cls(cls)
	local s = M.stats(kind, c, mut)
	if c == "carrier" then return s.cap * s.move end
	if c == "warrior" then return s.dmg / s.interval * s.hp end
	return s.dmg / s.interval
end

-- короткий підпис статів для UI: "2 dmg · x1.05", "2 ore · x1.13", "2 dmg · 20 HP"
function M.statText(kind: any, cls: any, mut: any): string
	local c = M.cls(cls)
	local s = M.stats(kind, c, mut)
	local sp = string.format("x%.2f", s.speed):gsub("0+$", ""):gsub("%.$", "")
	if c == "carrier" then return string.format("%d ore · %s", s.cap, sp) end
	if c == "warrior" then return string.format("%d dmg · %d HP", s.dmg, s.hp) end
	return string.format("%d dmg · %s", s.dmg, sp)
end

return M
