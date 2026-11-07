--!nonstrict
-- StallShopConfig — лавки в кінці зали (Workspace/Cave/Shops): Diamonds Shop і Events Shop. 29.10.2026.
-- GDD - Diamonds Shop. Усі ціни, ваги й кількості — пропозиція (міняються тут).
-- Асортимент Diamonds Shop оновлюється кожні DIA_RESTOCK с (межі періодів — за часом сервера, однакові всюди), запас
--   кожного лоту — СПІЛЬНИЙ на весь сервер (хто перший купив — той і забрав). За оновлення: KINDS (2–4 види скіпів за вагами),
--   іноді (RARE.chance) — один рідкісний лот-геймпас (1 шт.). Скіп дає одразу Money = дохід за хвилину × хвилини.
-- Boss Shop (колишній Events Shop, 04.11.2026) — за Fossil Tooth, оновлення кожні EVENT_RESTOCK (6 год), див. BOSS_* нижче.
local Config = {}

Config.DIA_RESTOCK = 30 * 60
Config.EVENT_RESTOCK = 6 * 60 * 60 -- Boss Shop: 6 год (межі — за часом сервера, однакові на всіх серверах)

-- скіпалки часу (GDD): хвилини, рідкість, вага появи, кількість за оновлення, ціна в діамантах
-- 06.11.2026: ціни ×5 і округлені до «круглих» (було 10 / 18 / 32 / 85 / 300 / 550)
Config.SKIPS = {
	{ key = "Skip5", min = 5, rarity = "Common", w = 35, qty = { 1, 3 }, price = 50 },
	{ key = "Skip10", min = 10, rarity = "Uncommon", w = 25, qty = { 1, 3 }, price = 100 },
	{ key = "Skip20", min = 20, rarity = "Rare", w = 18, qty = { 1, 2 }, price = 150 },
	{ key = "Skip60", min = 60, rarity = "Epic", w = 12, qty = { 1, 2 }, price = 400 },
	{ key = "Skip240", min = 240, rarity = "Legendary", w = 7, qty = { 1, 1 }, price = 1500 },
	{ key = "Skip480", min = 480, rarity = "Mythic", w = 3, qty = { 1, 1 }, price = 3000 },
}
-- скільки лотів у лавці завжди (29.10.2026): скіпи + зілля (якщо випало) + геймпас (якщо випав) = LOTS
Config.LOTS = 4
-- (застаріле, не використовується) скільки видів скіпів за оновлення: { кількість, вага }
Config.KINDS = { { 2, 20 }, { 3, 40 }, { 4, 40 } }
-- рідкісний лот: шанс на оновлення, геймпас (ключ MonetizationConfig.Passes), ціна в діамантах, вага; 1 шт. на сервер
Config.RARE = {
	chance = 0.25,
	list = {
		{ pass = "FastRoll", price = 4000, w = 60 },
		{ pass = "AutoRoll", price = 8000, w = 30 },
		{ pass = "AutoBuy", price = 12000, w = 10 },
	},
}
-- кольори рідкостей карток (верх → низ)
Config.RARITY = {
	Common = { "c9ced4", "6f7680" }, Uncommon = { "8ef05a", "237a16" }, Rare = { "6fc6ff", "1a5cb0" },
	Epic = { "d59bff", "5f22b4" }, Legendary = { "ffe27a", "b07a06" }, Mythic = { "ff8a96", "a8182f" }, Pass = { "ffb15c", "b8500c" },
}

-- ЗІЛЛЯ (29.10.2026): іноді (POTION_CHANCE за оновлення) — один лот зілля, вид за вагою w, кількість qty.
-- Ціна в діамантах прив'язана до мапи ГРАВЦЯ (лише для зіль): price × MultiConfig.stageMult (мапа 1 ×1, мапа 2 ×1,5, мапа 3 ×2,
-- мапа 4 ×3 …), округлено. Ефект зілля — ItemConfig.POTIONS (Luck +25 % удачі 5 хв, Speed ×2 швидкість 5 хв, Strength +50 % шкоди
-- 5 хв, Money ×2 гроші 10 хв). Порівняння: скіп 10 хв = 100 діамантів, Money Potion (10 хв ×2) = 125.
Config.POTION_CHANCE = 0.5
-- 06.11.2026: ціни зілля ×5 (було 15 / 15 / 12 / 25)
Config.POTIONS = {
	{ key = "Luck", price = 75, w = 30, qty = { 1, 3 }, tile = "green", col = { "8ef05a", "237a16" } },
	{ key = "Speed", price = 75, w = 30, qty = { 1, 3 }, tile = "blue", col = { "6fc6ff", "1a5cb0" } },
	{ key = "Strength", price = 60, w = 25, qty = { 1, 3 }, tile = "red", col = { "ff8a96", "a8182f" } },
	{ key = "Money", price = 125, w = 15, qty = { 1, 2 }, tile = "yellow", col = { "ffe27a", "b07a06" } },
}
function Config.potion(key: string): any
	for _, p in Config.POTIONS do if p.key == key then return p end end
	return nil
end
local MultiCfg = require(script.Parent:WaitForChild("MultiConfig"))
function Config.potionPrice(base: number, stage: any): number
	return math.max(1, math.floor(base * MultiCfg.stageMult(tonumber(stage) or 1) + 0.5))
end
-- візерунок StyleA на картці лоту (як у SHOP) за рідкістю
Config.TILE = { Common = "gray", Uncommon = "green", Rare = "blue", Epic = "purple", Legendary = "yellow", Mythic = "red", Pass = "orange", Exclusive = "red", Tickets = "yellow" }
Config.RARITY.Exclusive = { "ff6b6b", "8a1020" }
Config.RARITY.Tickets = { "ffe27a", "c27a06" }

-- ===== BOSS SHOP (04.11.2026) =====
-- Валюта — Fossil Tooth (атрибут FossilTeeth, дає бос). Асортимент міняється кожні EVENT_RESTOCK (6 год) і ОДНАКОВИЙ на всіх
--   серверах (зерно = номер періоду, Config.bossLots). BOSS_LOTS = 8 лотів: 1-й — завжди ексклюзивний воїн (один з BOSS_GOLEMS за
--   вагою w; не той самий, що в попередньому періоді), решта 7 — різні лоти з BOSS_POOL за вагою w, кількість qty.
-- Запас ОСОБИСТИЙ: кожен гравець може купити до max шт. лоту за період (атрибут BossShopBuys, StallShopService).
-- Зілля тут — фіксована ціна (без множника мапи).
Config.BOSS_LOTS = 8
Config.BOSS_GOLEMS = {
	{ kind = "mushroom", price = 300, w = 40 }, -- 50% BEST
	{ kind = "honey", price = 450, w = 30 }, -- 65% BEST
	{ kind = "snow", price = 800, w = 20 }, -- 90% BEST
	{ kind = "cloud", price = 1400, w = 10 }, -- 150% BEST
}
Config.BOSS_POOL = {
	{ key = "BLuck", kind = "potion", potion = "Luck", price = 8, qty = { 1, 3 }, w = 14 },
	{ key = "BSpeed", kind = "potion", potion = "Speed", price = 8, qty = { 1, 3 }, w = 14 },
	{ key = "BStrength", kind = "potion", potion = "Strength", price = 10, qty = { 1, 3 }, w = 12 },
	{ key = "BMoney", kind = "potion", potion = "Money", price = 12, qty = { 1, 2 }, w = 12 },
	{ key = "BSkip10", kind = "skip", min = 10, rarity = "Uncommon", price = 10, qty = { 1, 3 }, w = 12 },
	{ key = "BSkip20", kind = "skip", min = 20, rarity = "Rare", price = 18, qty = { 1, 2 }, w = 10 },
	{ key = "BSkip60", kind = "skip", min = 60, rarity = "Epic", price = 45, qty = { 1, 2 }, w = 8 },
	{ key = "BSkip240", kind = "skip", min = 240, rarity = "Legendary", price = 150, qty = { 1, 1 }, w = 4 },
	{ key = "BSkip480", kind = "skip", min = 480, rarity = "Mythic", price = 280, qty = { 1, 1 }, w = 2 },
	{ key = "BTix3", kind = "tickets", tickets = 3, rarity = "Tickets", price = 60, qty = { 1, 1 }, w = 4 },
	{ key = "BTix10", kind = "tickets", tickets = 10, rarity = "Tickets", price = 180, qty = { 1, 1 }, w = 1.5 },
}
local function wpick(rng: Random, list: { any }): any
	local total = 0
	for _, e in list do total += e.w end
	local r = rng:NextNumber() * total
	for _, e in list do
		r -= e.w
		if r <= 0 then return e end
	end
	return list[#list]
end
-- зерно періоду: перемішане (сусідні періоди не дають схожих перших чисел Random)
local function seedOf(period: number, salt: number): number
	local h = (period * 2654435761 + salt * 40503) % 2147483647
	h = (h * 48271 + 11) % 2147483647
	return h
end
-- голем періоду: ланцюжок від BOSS_EPOCH, кожен наступний — за вагою, але НЕ той самий, що попередній (кеш останнього)
local BOSS_EPOCH = 83000
local gCache = { p = BOSS_EPOCH - 1, g = nil }
local function bossGolem(period: number): any
	if period < gCache.p then gCache = { p = BOSS_EPOCH - 1, g = nil } end
	local p, g = gCache.p, gCache.g
	while p < period do
		p += 1
		local list = Config.BOSS_GOLEMS
		if g and #list > 1 then
			list = {}
			for _, e in Config.BOSS_GOLEMS do if e ~= g then table.insert(list, e) end end
		end
		local rng = Random.new(seedOf(p, 1))
		rng:NextNumber()
		g = wpick(rng, list)
	end
	gCache = { p = p, g = g }
	return g
end
-- асортимент Boss Shop на період (детерміновано — однаково на сервері, клієнті й усіх серверах)
function Config.bossLots(period: number): { any }
	local g = bossGolem(period)
	local lots = { { id = 1, kind = "golem", key = "G_" .. g.kind, golem = g.kind, rarity = "Exclusive", price = g.price, max = 1 } }
	local rng = Random.new(seedOf(period, 2))
	rng:NextNumber()
	local pool = table.clone(Config.BOSS_POOL)
	local picked = {}
	for _ = 1, math.min(Config.BOSS_LOTS - 1, #pool) do
		local e = wpick(rng, pool)
		table.remove(pool, table.find(pool, e))
		table.insert(picked, e)
	end
	local ORD = { potion = 1, skip = 2, tickets = 3 }
	table.sort(picked, function(a, b)
		if ORD[a.kind] ~= ORD[b.kind] then return ORD[a.kind] < ORD[b.kind] end
		return a.price < b.price
	end)
	for _, e in picked do
		local q = rng:NextInteger(e.qty[1], e.qty[2])
		table.insert(lots, { id = #lots + 1, kind = e.kind, key = e.key, potion = e.potion, min = e.min, tickets = e.tickets,
			rarity = e.rarity or "Potion", price = e.price, max = q })
	end
	return lots
end

function Config.periodOf(t: number, len: number): number return math.floor(t / len) end
function Config.nextAt(t: number, len: number): number return (math.floor(t / len) + 1) * len end

return Config
