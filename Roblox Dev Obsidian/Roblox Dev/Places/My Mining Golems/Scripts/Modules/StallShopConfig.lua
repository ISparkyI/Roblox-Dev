--!nonstrict
-- StallShopConfig — лавки в кінці зали (Workspace/Cave/Shops): Diamonds Shop і Events Shop. 29.10.2026.
-- GDD - Diamonds Shop. Усі ціни, ваги й кількості — пропозиція (міняються тут).
-- Асортимент Diamonds Shop оновлюється кожні DIA_RESTOCK с (межі періодів — за часом сервера, однакові всюди), запас
--   кожного лоту — СПІЛЬНИЙ на весь сервер (хто перший купив — той і забрав). За оновлення: KINDS (2–4 види скіпів за вагами),
--   іноді (RARE.chance) — один рідкісний лот-геймпас (1 шт.). Скіп дає одразу Money = дохід за хвилину × хвилини.
-- Events Shop — поки COMING SOON, таймер оновлення EVENT_RESTOCK.
local Config = {}

Config.DIA_RESTOCK = 30 * 60
Config.EVENT_RESTOCK = 3 * 60 * 60

-- скіпалки часу (GDD): хвилини, рідкість, вага появи, кількість за оновлення, ціна в діамантах
Config.SKIPS = {
	{ key = "Skip5", min = 5, rarity = "Common", w = 35, qty = { 1, 3 }, price = 10 },
	{ key = "Skip10", min = 10, rarity = "Uncommon", w = 25, qty = { 1, 3 }, price = 18 },
	{ key = "Skip20", min = 20, rarity = "Rare", w = 18, qty = { 1, 2 }, price = 32 },
	{ key = "Skip60", min = 60, rarity = "Epic", w = 12, qty = { 1, 2 }, price = 85 },
	{ key = "Skip240", min = 240, rarity = "Legendary", w = 7, qty = { 1, 1 }, price = 300 },
	{ key = "Skip480", min = 480, rarity = "Mythic", w = 3, qty = { 1, 1 }, price = 550 },
}
-- скільки видів скіпів за оновлення: { кількість, вага }
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

function Config.periodOf(t: number, len: number): number return math.floor(t / len) end
function Config.nextAt(t: number, len: number): number return (math.floor(t / len) + 1) * len end

return Config
