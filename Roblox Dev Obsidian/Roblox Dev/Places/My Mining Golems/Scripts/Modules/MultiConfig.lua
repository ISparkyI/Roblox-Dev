--!strict
-- MultiConfig — глобальні множники Money (спільний для сервера й клієнта).
-- Де: ReplicatedStorage/Shared/MultiConfig. Загальний множник = ДОБУТОК п'яти джерел (порядок у SOURCES = порядок у плашці над TOTAL MULTI).
--
--   Friends  — друзі на сервері: 1 + 0.25 за кожного друга (0 друзів = x1, 1 друг = x1.25)
--   Rebirth  — множник ребітхів: 2^Rebirths (GDD - Currencies and Rebirths); ціна й ліміт — rebirthPrice / rebirthLimit нижче
--   Donate   — x2 Money за Robux: ступені x2, x3, x4, x8, x16 … (кожна покупка = наступний ступінь, список — DONATE_TIERS)
--   VIP      — геймпас VIP: x1.5
--   Stage    — множник етапу (STAGE_MULTS; нові етапи — додати число в кінець таблиці)
--
-- Як розширити: новий ступінь донату — рядок у кінець DONATE_TIERS (і окремий продукт у MonetizationConfig.MoneyTierProducts
-- під тим самим номером); новий етап — число в кінець STAGE_MULTS; нове джерело — рядок у SOURCES і гілка в MultiService.compute
-- (сервер записує атрибут гравця Multi_<key>, клієнт читає його сам).

local Config = {}

Config.FRIEND_BONUS = 0.25 -- +25% за кожного друга на сервері
Config.VIP_MULT = 1.5
Config.REBIRTH_ENABLED = true -- множник ребітхів 2^Rebirths (вікно REBIRTH, RebirthService)
-- ребітхи: ліміт — мапа 1: 5, кожна наступна +3. Для переходу на наступну мапу треба зробити ВСІ ребітхи мапи (03.11.2026, MapService).
-- Ціна (03.11.2026, симуляція з ребітхами): j-й ребітх мапи s = REBIRTH_BASE × priceMult(s) × REBIRTH_GROWTH^(j−1), округлено до
-- цілого числа в одиницях K / M / B … (Config.round): мапа 1: 3K, 9K, 26K, 78K, 240K; мапа 2: 49M, 150M, 440M …
-- Крок ×3 > множника ×2. Було 20K × 3^(n−1) для всіх мап.
Config.REBIRTH_BASE = 4150 -- × priceMult мапи (мапа 1: 4150 × 0,7 ≈ 2.9K)
Config.REBIRTH_GROWTH = 3
Config.REBIRTH_LIMIT = 5
Config.REBIRTH_PER_STAGE = 3

-- множник етапу: 1 → x1, 2 → x1.5, 3 → x2, 4 → x3, 5 → x4, 6 → x6, 7 → x9, 8 → x12 (далі додаємо з новими етапами)
Config.STAGE_MULTS = { 1, 1.5, 2, 3, 4, 6, 9, 12 }

-- множник ЦІН на мапі: картки плотів, підставки ролу, покращення й пробудження Workshop, Auto Sell, Auto Workshop, ребітхи
-- = ціна «мапи 1» × PRICE_MULTS[мапа]. 03.11.2026 v2 — симуляція З РЕБІТХАМИ (×2 доходу кожен, усі ребітхи мапи обов'язкові
-- для переходу) і Roll Luck з коліном. Ціль: мапа 1 ≈ 30 хв, далі 1 год / 2 / 4 / 8 / 16 год (медіана симуляції: 29 / 57 / 115 /
-- 243 / 482 / 984 хв; Roll Luck ×1,0567 → ~2000 % на кінець мапи 6). Було { 0.7, 230, 15500, 720000, 43e6, 3.4e9 } — без
-- урахування ребітхів. Мапа 7 — оцінка (×300 до мапи 6).
Config.PRICE_MULTS = { 0.7, 11800, 4.9e6, 2.5e9, 8.3e11, 1.77e14, 5.3e16 }
-- знижка перших рівнів на мапах 2+ (04.11.2026, рішення користувача): на новій мапі все скидається, і перші покупки за повним
--   множником мапи були задовгими (1–2 хв на перше покращення). Множник ціни за рівнем l (l = поточний рівень / кількість):
--   1 → ×0.4, 2 → ×0.5, 3 → ×0.6, 4 → ×0.7, 5 → ×0.8, 6+ → ×0.9. Мапа 1 — без знижки. Діє на картки плотів, підставки ролу,
--   покращення Workshop (PlotConfig.cardPrice, RollConfig.standPrice, ForgeConfig.cap/spd/ophPrice). Ребітхи, Auto Sell, Auto Workshop — без неї.
Config.EARLY_DISCOUNT = { 0.4, 0.5, 0.6, 0.7, 0.8 }
Config.EARLY_DISCOUNT_REST = 0.9
function Config.earlyDiscount(level: number?, stage: number?): number
	if math.floor(tonumber(stage) or 1) <= 1 then return 1 end
	local l = math.max(1, math.floor(tonumber(level) or 1))
	return Config.EARLY_DISCOUNT[l] or Config.EARLY_DISCOUNT_REST
end
function Config.priceMult(stage: number?): number
	local s = math.max(1, math.floor(tonumber(stage) or 1))
	return Config.PRICE_MULTS[math.min(s, #Config.PRICE_MULTS)]
end

-- ступені x2 Money за Robux: { mult = множник, price = ціна в R$ }. Номер ступеня = номер рядка (атрибут гравця DonateTier = скільки куплено).
-- Ціни — за таблицею в GDD 15.2 (задає ЛИШЕ користувач; самим не міняти).
Config.DONATE_TIERS = {
	{ mult = 2, price = 1 },
	{ mult = 3, price = 3 },
	{ mult = 4, price = 9 },
	{ mult = 8, price = 27 },
	{ mult = 16, price = 56 },
	{ mult = 32, price = 99 },
	{ mult = 64, price = 149 },
	{ mult = 128, price = 249 },
	{ mult = 256, price = 399 },
	{ mult = 512, price = 589 },
	{ mult = 1024, price = 899 },
	{ mult = 2048, price = 1199 },
	{ mult = 4096, price = 1499 },
	{ mult = 8192, price = 1799 },
	{ mult = 16384, price = 1999 },
	{ mult = 32768, price = 2299 },
	{ mult = 65536, price = 2699 },
	{ mult = 131072, price = 2999 },
	{ mult = 262144, price = 3399 },
	{ mult = 524288, price = 3699 },
	{ mult = 1048576, price = 3999 },
}

function Config.maxDonateTier(): number return #Config.DONATE_TIERS end

-- множник за кількість куплених ступенів: 0 → x1, 1 → x2, 2 → x3, 3 → x4 …
function Config.donateMult(tier: number): number
	tier = math.clamp(math.floor(tier), 0, #Config.DONATE_TIERS)
	if tier == 0 then return 1 end
	return Config.DONATE_TIERS[tier].mult
end

-- наступний ступінь після куплених `tier` (nil, якщо все куплено)
function Config.nextDonateMult(tier: number): number?
	local t = Config.DONATE_TIERS[math.floor(tier) + 1]
	return t and t.mult
end
function Config.nextDonatePrice(tier: number): number?
	local t = Config.DONATE_TIERS[math.floor(tier) + 1]
	return t and t.price
end

function Config.stageMult(stage: number): number
	stage = math.max(1, math.floor(stage))
	return Config.STAGE_MULTS[math.min(stage, #Config.STAGE_MULTS)]
end

function Config.friendsMult(friends: number): number
	return 1 + Config.FRIEND_BONUS * math.max(0, friends)
end

function Config.rebirthMult(rebirths: number): number
	if not Config.REBIRTH_ENABLED then return 1 end
	return 2 ^ math.max(0, rebirths)
end

-- ціна n-го ребітху (n = 1, 2, 3 …)
-- округлення цін до ЦІЛОГО числа в одиницях показу (K / M / B / T …): 2905 → 3K, 48,9M → 49M, 7,29T → 7T (без «2.9K»)
function Config.round(x: number): number
	if x < 1000 then return math.max(1, math.floor(x + 0.5)) end
	local u = 1000 ^ math.floor(math.log10(x) / 3 + 1e-9)
	return math.floor(x / u + 0.5) * u
end
local nice = Config.round
-- 2 значущі цифри (Auto Sell, Auto Workshop, пробудження Workshop): 1,475B → 1.5B
function Config.round2(x: number): number
	if x < 100 then return math.floor(x + 0.5) end
	local p = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / p + 0.5) * p
end
-- ціни ребітхів мап 1–6 — від користувача (03.11.2026); далі (мапа 7+) — формула нижче
Config.REBIRTH_PRICES = {
	5e3, 10e3, 25e3, 100e3, 250e3, -- мапа 1
	50e6, 150e6, 450e6,             -- мапа 2
	20e9, 60e9, 200e9,              -- мапа 3
	10e12, 25e12, 100e12,           -- мапа 4
	3e15, 10e15, 25e15,             -- мапа 5
	750e15, 2e18, 10e18,            -- мапа 6
}
function Config.rebirthPrice(n: number): number
	n = math.max(1, math.floor(n))
	if Config.REBIRTH_PRICES[n] then return Config.REBIRTH_PRICES[n] end
	local s = Config.rebirthStageFor(n)
	local first = s == 1 and 1 or (Config.REBIRTH_LIMIT + Config.REBIRTH_PER_STAGE * (s - 2) + 1) -- перший ребітх цієї мапи
	return nice(Config.REBIRTH_BASE * Config.priceMult(s) * Config.REBIRTH_GROWTH ^ (n - first))
end
-- скільки ребітхів дозволено на мапі stage
function Config.rebirthLimit(stage: number): number
	return Config.REBIRTH_LIMIT + Config.REBIRTH_PER_STAGE * (math.max(1, math.floor(stage)) - 1)
end
-- з якої мапи доступний n-й ребітх
function Config.rebirthStageFor(n: number): number
	if n <= Config.REBIRTH_LIMIT then return 1 end
	return 1 + math.ceil((n - Config.REBIRTH_LIMIT) / Config.REBIRTH_PER_STAGE)
end

-- Рядки плашки над TOTAL MULTI: key (атрибут гравця Multi_<key>), назва, іконка (rbxassetid або ""), відношення сторін іконки
Config.SOURCES = {
	{ key = "Friends", label = "Friends", icon = "rbxassetid://109796913398904", aspect = 1.0711 },
	{ key = "Rebirth", label = "Rebirth", icon = "rbxassetid://134045976199050", aspect = 0.9844 },
	{ key = "Donate", label = "Money Boost", icon = "rbxassetid://103015355952567", aspect = 1 },
	{ key = "VIP", label = "VIP", icon = "rbxassetid://133507616051548", aspect = 1.0711 }, -- hud_vip / hud_map: власні іконки (2D/Main HUD/Roblox/Import); aspect 1.0711 — у ту ж рамку, що Friends
	{ key = "Stage", label = "Map", icon = "rbxassetid://100812332622032", aspect = 1.0711 },
	{ key = "Leader", label = "Leaderboards", icon = "podium", aspect = 1 }, -- "podium" — іконка з фреймів (MoneyHUD); бонус за місця в лідербордах (HubConfig.PERK_TIERS)
}

return Config
