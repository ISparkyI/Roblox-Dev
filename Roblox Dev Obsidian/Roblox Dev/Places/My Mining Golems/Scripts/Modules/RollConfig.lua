--!strict
-- RollConfig — числа покращень ролу (за GDD плейсу, розділ 4.6 «Табличка покращень ролів» і 5).
-- Де: ReplicatedStorage/Shared/RollConfig. Користуються сервер (RollUpgradeService) і екран (RollUpgradeUI).
--
-- Roll Luck: рівень 1 = 5%, кожен рівень +5%, без обмеження, ніколи не скидається.
--   Ціна переходу з рівня n на n+1 (економіка v2): 500 × 1,55^(n−1), округлено (див. luckPrice).
-- Місця ролу (Roll Stands): 1 → 5, ціни 50 / 250 / 1,000 / 4,000 × множник цін мапи (як картки плоту);
--   скидаються на новому етапі.
-- Множник етапу (до етапу 1): ×1, ×5, ×40, ×440, ×6 160, ×104 720 («×5, далі +×3 з кожним етапом»).
-- Усі ціни — пропозиція GDD, округлення вниз.
--
-- Дані гравця (поки атрибути, до збереження): RollLuckLvl (1+), RollLuck (%, = 5 × рівень), RollStands (1–5), Stage, Money.

local RollConfig = {}

RollConfig.LUCK_PER_LEVEL = 5
-- 08.11.2026 (рішення користувача): «під капотом» Roll Luck діє на РІДКІСТЬ ГОЛЕМА у 5 разів сильніше, ніж показано
--   (табло, ціни й відсотки ті самі): множник голема = 1 + 5 × удача / 100 (185 % → ×10,25 замість ×2,85). На мутації — як і було.
RollConfig.GOLEM_LUCK_MULT = 5
RollConfig.STANDS_BASE = 7 -- за Money (табло Roll Upgrades); 08.11.2026: було 5 (+2: точки Point6 / Point7 — кути верхнього ряду)
RollConfig.STANDS_MAX = 9 -- + геймпаси Pass_RollStand1 / Pass_RollStand2 (+1 кожен; наступні точки за номером, до Point9)
RollConfig.STAND_BASE_PRICE = 500
RollConfig.STAND_PRICE_STEP = 3

function RollConfig.luckPercent(level: number): number
	return RollConfig.LUCK_PER_LEVEL * level
end

-- економіка v2 (29.10.2026): Roll Luck дешевша — ціна = 500 × 1,55^(рівень − 1), округлено до «гарних» чисел.
-- 100 % (рівень 20) — разом ≈ $3.76M (було ≈ $12.7T). Рівень 8 (40 %) — ≈ $18.7K (кінець мапи 1). Не скидається і не множиться за мапу.
RollConfig.LUCK_START_PRICE = 500
RollConfig.LUCK_GROWTH = 1.55
local function nice(x: number): number
	local s = if x < 100 then 5 elseif x < 1000 then 25 elseif x < 10000 then 100 elseif x < 100000 then 500 else 5000
	if x >= 1e7 then s = 10 ^ (math.floor(math.log10(x)) - 2) end -- далі — 3 значущі цифри
	return math.max(s, math.floor(x / s + 0.5) * s)
end
-- 03.11.2026 (рішення користувача): Roll Luck БЕЗ обмеження; ціни підібрані так, щоб до кінця мапи 6
--   гравець мав близько 2000 % (рівень ~400), далі качається й далі.
--   Рівні 1–35 — ×1,55 за рівень; далі ×LUCK_LATE_GROWTH. 03.11.2026 v2 (симуляція з ребітхами): ×1,0567 —
--   медіана на кінець мап: 50 % / 140 % / 410 % / 975 % / 1500 % / ~1990 % (рівень ~397). Було ×1,017 → ~6000 % на мапі 6.
--   З 2000 % Astral (1 до 10 млн) — ≈ 1 до 476,000 за рол (x2 Roll Luck — 1 до 238,000).
RollConfig.LUCK_MAX_LEVEL = math.huge -- без обмеження (код MAX у RollUpgradeUI / Service лишається на випадок межі)
RollConfig.LUCK_KNEE = 35      -- до цього рівня — ×1,55, далі — ×LUCK_LATE_GROWTH
RollConfig.LUCK_LATE_GROWTH = 1.0567
-- ціна переходу з рівня level на level + 1 (nil лише на LUCK_MAX_LEVEL, зараз недосяжний)
function RollConfig.luckPrice(level: number): number?
	local l = math.max(1, math.floor(level))
	if l >= RollConfig.LUCK_MAX_LEVEL then return nil end
	if l <= RollConfig.LUCK_KNEE then
		return nice(RollConfig.LUCK_START_PRICE * RollConfig.LUCK_GROWTH ^ (l - 1))
	end
	local knee = RollConfig.LUCK_START_PRICE * RollConfig.LUCK_GROWTH ^ (RollConfig.LUCK_KNEE - 1)
	return nice(knee * RollConfig.LUCK_LATE_GROWTH ^ (l - RollConfig.LUCK_KNEE))
end

function RollConfig.stageMult(stage: number): number
	local m, step = 1, 5
	for _ = 2, math.max(1, stage) do
		m *= step
		step += 3
	end
	return m
end

-- ціна переходу з count місць на count + 1 (nil, якщо вже максимум).
-- економіка v2 (29.10.2026): мапа 1 — 50 / 250 / 1,000 / 4,000; на інших мапах × той самий множник, що й картки плоту
-- (PlotConfig.priceMult: 1 + 2 × (множник мапи − 1) → ×1, ×2, ×3 …). Раніше — 500 × 3^k і власний множник ×5 / ×40.
RollConfig.STAND_PRICES = { 50, 250, 1000, 4000, 16000, 64000 } -- 08.11.2026: + 6-та й 7-ма підставки (×4, як і раніше)
function RollConfig.standPrice(count: number, stage: number): number?
	if count >= RollConfig.STANDS_BASE then return nil end
	local base = RollConfig.STAND_PRICES[math.clamp(math.floor(count), 1, #RollConfig.STAND_PRICES)]
	local MultiCfg = require(script.Parent:WaitForChild("MultiConfig"))
	local mult = MultiCfg.priceMult(stage) -- 03.11.2026: MultiConfig.PRICE_MULTS
	return math.floor(base * mult * MultiCfg.earlyDiscount(count, stage)) -- 04.11.2026: знижка перших рівнів (мапи 2+)
end

-- усього підставок гравця: куплені за Money (1–5) + геймпаси Pass_RollStand1 / Pass_RollStand2 (+1 кожен)
function RollConfig.totalStands(p: Instance): number
	local base = math.clamp(tonumber(p:GetAttribute("RollStands")) or 1, 1, RollConfig.STANDS_BASE)
	local extra = (p:GetAttribute("Pass_RollStand1") == true and 1 or 0) + (p:GetAttribute("Pass_RollStand2") == true and 1 or 0)
	return math.min(base + extra, RollConfig.STANDS_MAX)
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
