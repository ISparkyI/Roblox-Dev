-- HubConfig — числа центральної зали (Workspace/Cave/Hub): Marketplace, лідерборди, магазини, мутаційні установки, груповий голем.
-- Де: ReplicatedStorage/Shared/HubConfig (ModuleScript, сервер і клієнт). 28.10.2026.
local Config = {}

-- ===== Marketplace (телепорт у центрі зали) =====
-- Стаєш у коло (Hub/Marketplace/Ring/RingCenter, радіус MARKET_RING_R) — банер з відліком MARKET_COUNTDOWN с, потім телепорт
-- (Remotes/MarketplaceTP → сервер перевіряє, що гравець у колі, і робить TeleportAsync). 0 — місця ще немає: тост «coming soon».
Config.MARKETPLACE_PLACE_ID = 113531698511321 -- плейс Marketplace (створено 03.11.2026, Publish As; 60 гравців, вхід лише телепортом з досвіду)
Config.MARKET_COUNTDOWN = 3
Config.MARKET_RING_R = 8.6
-- Один файл плейсу на обидва місця (03.11.2026): головне — MAIN_PLACE_ID (печера, ніші); будь-який інший PlaceId цього файлу —
--   сервер Marketplace (режим маркету: NicheBoot запускає лише потрібні сервіси + MarketServerService, печеру прибирає).
--   Публікація: Publish → головне, потім File → Publish to Roblox As… → плейс Marketplace (той самий файл).
--   У Studio режим маркету вмикає атрибут Workspace.MarketTest = true (для тестів; сам телепорт у Studio не працює).
-- Сервери маркету — резервовані (TeleportService:ReserveServer), облік у MemoryStore SortedMap MARKET_MAP: ключ = PrivateServerId,
--   значення { code, n } (n — гравців). Гравець йде на найповніший сервер з n < MARKET_MAX × MARKET_FILL (45 з 60); такого немає —
--   новий сервер. Сервер маркету оновлює свій n кожні MARKET_BEAT с (TTL MARKET_TTL); спорожнів — запис прибирає, Roblox його закриває.
Config.MAIN_PLACE_ID = 121679937506068
Config.MARKET_MAX = 60
Config.MARKET_FILL = 0.75
Config.MARKET_MAP = "MarketServers"
Config.MARKET_BEAT = 15
Config.MARKET_TTL = 60
Config.MARKET_BACK_R = 8 -- коло Floor/«Back To Cave» (діаметр 16) — телепорт назад у печеру
function Config.isMarket(): boolean
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("MarketTest") == true then return true end
	if game:GetService("ReplicatedStorage"):GetAttribute("MarketMode") == true then return true end -- ставить MarketServerService (надійно для клієнта)
	if game:GetService("RunService"):IsClient() and workspace:FindFirstChild("Marketplace") and not workspace:FindFirstChild("Cave") then return true end
	return game.PlaceId ~= Config.MAIN_PLACE_ID and game.PlaceId ~= 0
end

-- ===== лідерборди (чотири кути центральної зали, GDD - Leaderboards) =====
-- Сервер (StatsService): атрибути гравця stat → OrderedDataStore "LB_<key>" раз на LB_PERIOD с, топ LB_TOP → атрибут Data (JSON) на
-- Workspace/Cave/Hub/Leaderboards/<key>. Клієнт (LeaderboardClient) малює екран. Над таблом — статуя гравця #1.
-- pos — центр низу табла (XZ), табло дивиться на центр зали HUB_CENTER.
Config.HUB_CENTER = Vector3.new(0, 1.35, 300)
Config.LB_PERIOD = 60
Config.LB_TOP = 100
-- Бонуси за місце в лідерборді (діють, поки гравець на цьому місці; оновлення — разом із таблом):
--   tier "big":   #1 +50%, #2 +25%, #3 +10%, #4–100 +5%;   tier "small": #1 +25%, #2 +15%, #3 +10%, #4–100 +5%.
--   perk: "money" — множник Money (джерело Leader у TOTAL MULTI), "luck" — Roll Luck (RollService), "boss" — дроп з босів (на майбутнє).
--   Бонуси з різних табел додаються: атрибути гравця LB_Money / LB_Luck / LB_Boss (відсотки), LB_Ranks (JSON {key = місце}).
Config.PERK_TIERS = { big = { 50, 25, 10, 5 }, small = { 25, 15, 10, 5 } }
Config.PERK_NAMES = { money = "Money", luck = "Roll Luck", boss = "Boss Drops" }
function Config.perkPct(tier: string, rank: number?): number
	local t = Config.PERK_TIERS[tier]
	if not t or not rank or rank < 1 or rank > Config.LB_TOP then return 0 end
	return t[math.min(rank, 4)]
end
-- 8 табел, по 2 в кожному куті зали. Моделі стоять у Workspace/Cave/Hub/Leaderboards (пара — «куточком», спинами до
-- скелі, екрани розведені на ±42° від діагоналі на центр зали); pos / look нижче — початкова розстановка, скрипти їх не читають.
-- Пари: гроші (Money + Income), роли (Rolls + Best Roll), Robux (Donators + Gifters), час і боси (Playtime + Bosses).
Config.BOARDS = {
	{ key = "Money", stat = "Stat_TotalMoney", title = "TOP MONEY", sub = "Money earned all-time", fmt = "money", accent = "7ef05a", accent2 = "2fc21c", tile = "green",
		perk = "money", tier = "big", pos = Vector3.new(-32, 0, 250), look = Vector3.new(1, 0, 0) },
	{ key = "Income", stat = "Stat_BestIncome", title = "TOP INCOME", sub = "Best income per minute", fmt = "income", accent = "b6ff5c", accent2 = "5fbf1c", tile = "green",
		perk = "money", tier = "small", pos = Vector3.new(-45, 0, 260), look = Vector3.new(0, 0, 1) },
	{ key = "Rolls", stat = "Stat_Rolls", title = "TOP ROLLS", sub = "Golem rolls all-time", fmt = "count", accent = "5cc8ff", accent2 = "1f7fe0", tile = "blue",
		perk = "luck", tier = "big", pos = Vector3.new(32, 0, 250), look = Vector3.new(-1, 0, 0) },
	{ key = "BestRoll", stat = "Stat_BestRoll", title = "TOP BEST ROLL", sub = "Rarest golem ever rolled", fmt = "odds", accent = "c99bff", accent2 = "7a3fe0", tile = "purple",
		perk = "luck", tier = "small", pos = Vector3.new(45, 0, 260), look = Vector3.new(0, 0, 1) },
	{ key = "Donators", stat = "Stat_RobuxSpent", title = "TOP DONATORS", sub = "Robux spent in game", fmt = "robux", accent = "ff7ac8", accent2 = "d6247e", tile = "pink",
		perk = "money", tier = "big", pos = Vector3.new(-32, 0, 350), look = Vector3.new(1, 0, 0) },
	{ key = "Gifters", stat = "Stat_RobuxGifted", title = "TOP GIFTERS", sub = "Robux gifted to players", fmt = "robux", accent = "ff9a5c", accent2 = "e0531f", tile = "orange",
		perk = "money", tier = "big", pos = Vector3.new(-45, 0, 340), look = Vector3.new(0, 0, -1) },
	{ key = "Playtime", stat = "Stat_Playtime", title = "TOP PLAYTIME", sub = "Time played all-time", fmt = "time", accent = "ffd23a", accent2 = "ff9a1f", tile = "yellow",
		perk = "luck", tier = "big", pos = Vector3.new(32, 0, 350), look = Vector3.new(-1, 0, 0) },
	{ key = "Bosses", stat = "Stat_BossKills", title = "TOP BOSS SLAYERS", sub = "Bosses defeated", fmt = "count", accent = "ff5c6e", accent2 = "c21c3a", tile = "red",
		perk = "boss", tier = "big", pos = Vector3.new(45, 0, 340), look = Vector3.new(0, 0, -1) },
}

-- табла маркету (03.11.2026): моделі Workspace/Marketplace/Floor/<model>, екран — частина Screen (атрибут Face — бік до центру).
--   Ліворуч — топ покупців, праворуч — топ продавців (големи, куплені / продані на маркеті: Stat_MarketBought / Stat_MarketSold —
--   рахує торгівля, коли вона буде: StatsService.Add(p, "MarketBought" / "MarketSold", 1)). Без бонусів за місце й статуй.
--   По центру (TICKETS_BOARD) — екран покупки пакетів тікетів (MonetizationConfig.TicketProducts, як у магазині).
Config.MARKET_BOARDS = {
	{ key = "MarketBuys", model = "LeaderBoard 1", stat = "Stat_MarketBought", title = "TOP BUYERS", sub = "Golems bought on the Marketplace", fmt = "count",
		accent = "5cc8ff", accent2 = "1f7fe0", tile = "blue" },
	{ key = "MarketSales", model = "LeaderBoard 2", stat = "Stat_MarketSold", title = "TOP SELLERS", sub = "Golems sold on the Marketplace", fmt = "count",
		accent = "ffd23a", accent2 = "ff9a1f", tile = "yellow" },
}
Config.TICKETS_BOARD = "Tickets Shop"
-- четверте табло маркету — останні угоди на ЦЬОМУ сервері (Floor/«Selling Info», частина Screen; атрибут Trades — JSON, нові зверху).
--   Записує MarketServerService.LogTrade (викличе торгівля після успішної угоди), малює LeaderboardClient.
Config.TRADES_BOARD = "Selling Info" -- ім'я моделі (порівнюється без пробілів по краях)
Config.TRADES_MAX = 100
-- продаж големів на маркеті (MarketLotService / MarketUI, 03.11.2026): слоти лотів — 3, VIP +2, покупка +3 за Robux
--   (MonetizationConfig.Products.MarketSlots, один раз → Pass_MarketSlots). Комісія з продавця — MARKET_FEE.
Config.MARKET_LOTS_BASE = 3
Config.MARKET_LOTS_VIP = 2
Config.MARKET_LOTS_BUY = 3
Config.MARKET_FEE = 0 -- 03.11.2026: комісії немає (рішення користувача)
-- мінімальна ціна лота за валютою (04.11.2026, рішення користувача): гроші $10K, діаманти 100, тікети 2
Config.MARKET_MIN_PRICE = { money = 10000, diamonds = 100, tickets = 2 }
-- големи, яких не можна продати на маркеті: груповий Mushroom Golem (GroupGolemService дає майнера).
--   Інші ексклюзиви (кейс, тижневі — у т.ч. Mushroom-носій) продавати можна.
Config.MARKET_BLOCKED = { ["mushroom:miner"] = true }
function Config.marketBlocked(kind: any, cls: any): boolean
	return Config.MARKET_BLOCKED[tostring(kind) .. ":" .. tostring(cls or "miner")] == true
end
function Config.marketSlots(p: Player): number
	local n = Config.MARKET_LOTS_BASE
	if p:GetAttribute("Pass_VIP") == true then n += Config.MARKET_LOTS_VIP end
	if p:GetAttribute("Pass_MarketSlots") == true then n += Config.MARKET_LOTS_BUY end
	return n
end
Config.MARKET_LOTS = Config.MARKET_LOTS_BASE + Config.MARKET_LOTS_VIP + Config.MARKET_LOTS_BUY -- максимум (8)
function Config.tradesBoard(): Model?
	local m = workspace:FindFirstChild("Marketplace")
	local fl = m and m:FindFirstChild("Floor")
	if not fl then return nil end
	for _, c in fl:GetChildren() do
		if c:IsA("Model") and string.match(c.Name, "^%s*(.-)%s*$") == Config.TRADES_BOARD then return c end
	end
	return nil
end

return Config
