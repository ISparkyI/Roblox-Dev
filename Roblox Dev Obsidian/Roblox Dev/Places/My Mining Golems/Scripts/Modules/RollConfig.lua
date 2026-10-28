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

-- ===== Рол големів (RollService — сервер, RollRevealClient — анімація; GDD - Roll) =====
-- Анімація на кожній відкритій підставці (v3, 27.10.2026 — без обертання): FAKES випадкових появ (поява APPEAR →
-- показ → зникнення VANISH), 5-та поява — справжній результат (RESULT_APPEAR + спалах). Уся анімація триває рівно TOTAL с
-- від удару важеля до кінця появи результату на ОСТАННІЙ підставці: підставка i стартує зі зсувом (i − 1) × STAGGER,
-- а тривалість циклу фейка (cycle) стискається так, щоб остання підставка закінчила рівно на TOTAL.
RollConfig.TOTAL = 2.0
RollConfig.FAKES = 4
RollConfig.APPEAR = 0.1
RollConfig.VANISH = 0.1
RollConfig.RESULT_APPEAR = 0.2
RollConfig.STAGGER = 0.04
-- тривалість одного циклу фейка (поява + показ + зникнення) при count підставках: 1 підставка — 0,45 с, 5 — 0,41 с
function RollConfig.cycle(count: number): number
	return (RollConfig.TOTAL - RollConfig.RESULT_APPEAR - RollConfig.STAGGER * math.max(0, count - 1)) / RollConfig.FAKES
end
-- скільки триває анімація ролу на count підставках (до кінця появи результату на останній) — завжди TOTAL
function RollConfig.revealTime(count: number): number
	return RollConfig.TOTAL
end

-- вибір за шансами «1 до N»: items = { { odds = N, ... } }, luck — % (множник удачі M = 1 + luck / 100).
-- Перевірка ВІД НАЙРІДШОГО (як у RNG-іграх): кожен небазовий випадає з шансом min(1, M / N), якщо рідший не випав;
-- базовий (найменше N, звичайно 1) — якщо не випав жоден. Так множник масштабується без межі: M ≥ N найрідшого → завжди він.
-- (До 28.10.2026 — кумулятивні інтервали з нормалізацією: після ~x10 множник переставав діяти, розподіл застигав на
--  Bronze ~50 % / Secret ~0,01 % навіть при x1 000 000 000.) При звичайній удачі (x1,05) шанси майже ті самі. rnd — Random (сервер).
function RollConfig.pick(items: { any }, luck: number, rnd: Random): any
	if #items == 0 then return nil end
	local list = table.clone(items)
	table.sort(list, function(a, b) return a.odds > b.odds end) -- від найрідшого
	local mult = 1 + math.max(0, luck) / 100
	for i = 1, #list - 1 do
		if rnd:NextNumber() < math.min(1, mult / math.max(1, list[i].odds)) then return list[i] end
	end
	return list[#list]
end


return RollConfig
