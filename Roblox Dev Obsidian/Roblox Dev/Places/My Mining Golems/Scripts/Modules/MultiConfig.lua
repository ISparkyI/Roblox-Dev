--!strict
-- MultiConfig — глобальні множники Money (спільний для сервера й клієнта).
-- Де: ReplicatedStorage/Shared/MultiConfig. Загальний множник = ДОБУТОК п'яти джерел (порядок у SOURCES = порядок у плашці над TOTAL MULTI).
--
--   Friends  — друзі на сервері: 1 + 0.25 за кожного друга (0 друзів = x1, 1 друг = x1.25)
--   Rebirth  — множник ребітхів (ПОКИ x1; формула з GDD 8 готова, вмикається REBIRTH_ENABLED)
--   Donate   — x2 Money за Robux: ступені x2, x3, x4, x8, x16 … (кожна покупка = наступний ступінь, список — DONATE_TIERS)
--   VIP      — геймпас VIP: x2
--   Stage    — множник етапу (STAGE_MULTS; нові етапи — додати число в кінець таблиці)
--
-- Як розширити: новий ступінь донату — рядок у кінець DONATE_TIERS (і окремий продукт у MonetizationConfig.MoneyTierProducts
-- під тим самим номером); новий етап — число в кінець STAGE_MULTS; нове джерело — рядок у SOURCES і гілка в MultiService.compute
-- (сервер записує атрибут гравця Multi_<key>, клієнт читає його сам).

local Config = {}

Config.FRIEND_BONUS = 0.25 -- +25% за кожного друга на сервері
Config.VIP_MULT = 2
Config.REBIRTH_ENABLED = false -- ПОКИ x1; коли зробимо ребітхи — true (формула: 2^Rebirths, GDD 8)

-- множник етапу: 1 → x1, 2 → x1.5, 3 → x2, 4 → x3, 5 → x4, 6 → x6, 7 → x9, 8 → x12 (далі додаємо з новими етапами)
Config.STAGE_MULTS = { 1, 1.5, 2, 3, 4, 6, 9, 12 }

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

-- Рядки плашки над TOTAL MULTI: key (атрибут гравця Multi_<key>), назва, іконка (rbxassetid або ""), відношення сторін іконки
Config.SOURCES = {
	{ key = "Friends", label = "Friends", icon = "rbxassetid://109796913398904", aspect = 1.0711 },
	{ key = "Rebirth", label = "Rebirth", icon = "rbxassetid://134045976199050", aspect = 0.9844 },
	{ key = "Donate", label = "Money Boost", icon = "rbxassetid://103015355952567", aspect = 1 },
	{ key = "VIP", label = "VIP", icon = "rbxassetid://133507616051548", aspect = 1.0711 }, -- hud_vip / hud_map: власні іконки (2D/Main HUD/Roblox/Import); aspect 1.0711 — у ту ж рамку, що Friends
	{ key = "Stage", label = "Map", icon = "rbxassetid://100812332622032", aspect = 1.0711 },
}

return Config
