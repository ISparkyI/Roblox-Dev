-- HubConfig — числа центральної зали (Workspace/Cave/Hub): Marketplace, лідерборди, магазини, мутаційні установки, груповий голем.
-- Де: ReplicatedStorage/Shared/HubConfig (ModuleScript, сервер і клієнт). 28.10.2026.
local Config = {}

-- ===== Marketplace (телепорт у центрі зали) =====
-- Стаєш у коло (Hub/Marketplace/Ring/RingCenter, радіус MARKET_RING_R) — банер з відліком MARKET_COUNTDOWN с, потім телепорт
-- (Remotes/MarketplaceTP → сервер перевіряє, що гравець у колі, і робить TeleportAsync). 0 — місця ще немає: тост «coming soon».
Config.MARKETPLACE_PLACE_ID = 0
Config.MARKET_COUNTDOWN = 3
Config.MARKET_RING_R = 8.6

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

return Config
