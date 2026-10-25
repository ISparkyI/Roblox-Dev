--!strict
-- RollConfig — числа покращень ролу (за GDD плейсу, розділ 4.6 «Табличка покращень ролів» і 5).
-- Де: ReplicatedStorage/Shared/RollConfig. Користуються сервер (RollUpgradeService) і екран (RollUpgradeUI).
--
-- Roll Luck: рівень 1 = 5%, кожен рівень +5%, без обмеження, ніколи не скидається.
--   Ціна переходу з рівня n на n+1: Ціна_1 = 1 000, Ціна_(n+1) = floor(Ціна_n × max(1.25, 4 − 0.05·(n−1))).
-- Місця ролу (Roll Stands): 1 → 5, ціни 500 × 3^(k−1) за перехід k → k+1, множаться на множник етапу;
--   скидаються на новому етапі.
-- Множник етапу (до етапу 1): ×1, ×5, ×40, ×440, ×6 160, ×104 720 («×5, далі +×3 з кожним етапом»).
-- Усі ціни — пропозиція GDD, округлення вниз.
--
-- Дані гравця (поки атрибути, до збереження): RollLuckLvl (1+), RollLuck (%, = 5 × рівень), RollStands (1–5), Stage, Money.

local RollConfig = {}

RollConfig.LUCK_PER_LEVEL = 5
RollConfig.LUCK_START_PRICE = 1000
RollConfig.STANDS_MAX = 5
RollConfig.STAND_BASE_PRICE = 500
RollConfig.STAND_PRICE_STEP = 3

function RollConfig.luckPercent(level: number): number
	return RollConfig.LUCK_PER_LEVEL * level
end

-- ціна переходу з рівня level на level + 1
function RollConfig.luckPrice(level: number): number
	local p = RollConfig.LUCK_START_PRICE
	for n = 1, level - 1 do
		p = math.floor(p * math.max(1.25, 4 - 0.05 * (n - 1)))
	end
	return p
end

function RollConfig.stageMult(stage: number): number
	local m, step = 1, 5
	for _ = 2, math.max(1, stage) do
		m *= step
		step += 3
	end
	return m
end

-- ціна переходу з count місць на count + 1 (nil, якщо вже максимум)
function RollConfig.standPrice(count: number, stage: number): number?
	if count >= RollConfig.STANDS_MAX then return nil end
	return math.floor(RollConfig.STAND_BASE_PRICE * RollConfig.STAND_PRICE_STEP ^ (count - 1) * RollConfig.stageMult(stage))
end

return RollConfig
