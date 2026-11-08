--!strict
-- BossConfig — бій з босом (Plan - Boss Fight System, 04.11.2026). Спільний для сервера й клієнта.
-- Де: ReplicatedStorage/Shared/BossConfig. Сервер — ServerScriptService/BossFightService, клієнт — BossLobbyWindow (вікно порталу)
--   і BossArenaClient (арена: големи, зони, HP, лідерборд, результати).
-- Цикл: бос кожні 15 хв (BossPortalService: Workspace.BossAt). За REG_TIME с до BossAt — реєстрація біля порталу (JOIN),
--   у BossAt — бій до FIGHT_TIME с або смерті боса, потім RESULTS_TIME с — вікно нагород і всі додому.
-- Арена — префаб на кожного боса: ServerStorage/BossArenas/<arena> (клонується в Workspace як «Boss Map»).

local M = {}

M.MIN_STAGE = 1          -- 08.11.2026: бос і воїни — з мапи 1 для всіх (було 2, рішення 04.11.2026)
M.REG_TIME = 60          -- реєстрація: останні 60 с перед босом
M.FIGHT_TIME = 300       -- бій: 5 хв
M.RESULTS_TIME = 13      -- вікно результатів, потім додому (06.11.2026: 9 → 13 — спершу ~5 с анімація смерті боса)
M.MAX_PLAYERS = 6        -- учасників у бою (сервер на 6 гравців)
M.BASE_SLOTS = 3         -- слотів бійців стандартно
M.EXTRA_SLOTS = 2        -- 05.11.2026: 4-й слот — за діаманти (DIA_SLOT_PRICE, атрибут BossSlotDia), 5-й — геймпас Pass_BossSlots (79 R$)
M.DIA_SLOT_PRICE = 2500  -- ціна 4-го слота в діамантах (раз і назавжди)
M.TICK = 0.1             -- крок симуляції сервера, с
M.SEND_EVERY = 0.12      -- як часто сервер шле позиції големів, с

-- големи на арені
M.FOLLOW_R = 6.5         -- радіус «хмарки» навколо гравця
M.ATTACK_RANGE = 3.2     -- від краю хітбоксу боса, стад
M.BOSS_SPEED = 9          -- 05.11.2026: бос ходить по арені (стад/с) до найближчого гравця
M.BOSS_STOP = 27          -- зупиняється на такій відстані від гравця (центр боса — гравець); 06.11.2026: бос ×6 — ближче
M.BOSS_ROAM = 120         -- далі від центру арени не відходить
M.ENGAGE_R = 30          -- гравець на стільки близько до боса — големи йдуть бити (далі — відступають за гравцем); 06.11.2026: 20 → 30
M.MIN_MOVE = 18          -- големи не відстають від гравця (стад/с)
M.MAX_MOVE = 26
-- шкода голема по босу — 1 : 1 (06.11.2026: без м'якої стелі ^0,8 — голем б'є 1K, бос втрачає 1K)
function M.golemDmg(dmg: number): number return math.max(1, dmg or 1) end
-- 06.11.2026: удар боса знімає pct × hitMult від макс. HP голема: чим більше HP, тим менший відсоток —
--   −0,12 за кожне ×10 HP (10 HP → 1,0; 1K → 0,76; 10K → 0,64; 100K → 0,52), не нижче HIT_MIN
M.HIT_STEP, M.HIT_MIN = 0.12, 0.4
function M.hitMult(maxHp: number): number
	return math.clamp(1 - M.HIT_STEP * math.log10(math.max(10, maxHp or 10) / 10), M.HIT_MIN, 1)
end
-- «кругле» HP: найближче (за відношенням) з 1 / 2 / 2,5 / 5 / 7,5 × 10^k — 10K, 20K, 25K, 50K, 75K, 100K, 250K, 500K…
local NICE = { 1, 2, 2.5, 5, 7.5, 10 }
function M.niceHp(x: number): number
	if x <= 1 then return 1 end
	local p = 10 ^ math.floor(math.log10(x))
	local best, br = p, math.huge
	for _, k in NICE do
		local v = k * p
		local r = math.max(v, x) / math.min(v, x)
		if r < br then best, br = v, r end
	end
	return best
end

M.ICON_TOOTH = "rbxassetid://123134840549658"
M.ICON_DIAMOND = "rbxassetid://126442692946356"

-- боси (перше оновлення — один)
M.BOSSES = {
	goblin = {
		name = "GOBKING",
		-- HP-бар (05.11.2026): картинка-рамка з назвою (Style/Roblox/bossbar_gobking.png, 1024 × 204); win = прозоре вікно під
		--   заповнення HP у пікселях картинки { x, y, w, h }. image = "" — запасний вигляд (назва текстом + проста смуга)
		bar = { image = "rbxassetid://98021755888673", w = 1024, h = 204, win = { 78, 88, 860, 46 } },
		arena = "Arena_GolemGoblin",
		-- 06.11.2026: HP боса = сума шкоди за секунду всіх големів усіх гравців × 135 (≈ 3 хв: големи б'ють ~75 % часу —
		--   ходять, ухиляються), далі округлення до «круглого» числа (M.niceHp)
		hpPerDps = 135,
		minHp = 1000,
		half = Vector3.new(12, 21, 9), -- половина хітбоксу (X ширина, Y висота, Z глибина); 06.11.2026: GOBKING ~42 студи (×6 до големів, було ×8)
		pause = { 4.2, 5.6 }, -- пауза між атаками (с), у другій фазі × 0,7; 06.11.2026: довше (було 3,2–4,4)
		-- атаки: форма (прямокутники на підлозі), попередження warn с, шкода pct від макс. HP голема
		attacks = {
			-- 04.11.2026 тест: при 0,25–0,35 големи гинули за ~25 с, вдвічі м'якше
			-- 05.11.2026: 4 атаки GOBKING — Ground Slam, Arm Sweep, Crystal Eruption, Rock Rain (у другій фазі більше каменів)
			-- 06.11.2026: warn +0,9 с — зона з'являється раніше, є час вивести големів (гравець відходить — големи за ним)
			{ key = "Slam", weight = 3, warn = 2.5, pct = 0.18 },
			{ key = "Sweep", weight = 3, warn = 2.5, pct = 0.15 },
			{ key = "Eruption", weight = 3, warn = 2.2, pct = 0.12 },
			{ key = "RockRain", weight = 2, warn = 2.4, pct = 0.10 },
		},
		-- 04.11.2026: атаки йдуть не випадково, а по черзі (10 атак, далі повтор з 1-ї); { ключ, бік для Sweep: 1 — права рука, −1 — ліва }
		sequence = {
			{ "Slam" }, { "Sweep", 1 }, { "Eruption" }, { "Sweep", -1 }, { "RockRain" },
			{ "Slam" }, { "Eruption" }, { "Sweep", 1 }, { "Slam" }, { "RockRain" },
		},
	},
}
M.ROTATION = { "goblin" }
function M.current(): (string, any)
	local id = M.ROTATION[1]
	return id, M.BOSSES[id]
end

-- лут: пул залежить від кількості учасників N (рішення 04.11.2026: лише Fossil Tooth і діаманти)
-- 06.11.2026: загальний пул — 10 зубів + 2 за гравця, 250 діамантів + 50 за гравця; участь і бонуси за місця беруться З пулу
--   (разом гравці отримують рівно пул, з точністю до округлення вниз)
M.LOOT = {
	teethBase = 10, teethPerPlayer = 2, diaBase = 250, diaPerPlayer = 50,
	partTeeth = 1, partDia = 10, minShare = 0.01, -- «участь»: дожив до кінця на арені й наніс ≥ 1 %
	topTeeth = { 3, 2, 1 }, topDia = { 50, 30, 20 },
	loseMult = 0.1, -- програш: без зубів, діаманти × 0,1
}

-- нагорода гравця: dmg, sum — шкода гравця / усіх; place — місце; n — учасників; win
function M.reward(dmg: number, sum: number, place: number, n: number, win: boolean): (number, number)
	local L = M.LOOT
	local share = sum > 0 and dmg / sum or 0
	if share < L.minShare then return 0, 0 end
	local T = L.teethBase + L.teethPerPlayer * n
	local D = L.diaBase + L.diaPerPlayer * n
	local tt, td = 0, 0 -- бонуси всіх призових місць (1..min(n, 3)) — віднімаються з пулу
	for i = 1, math.min(n, #L.topTeeth) do tt += L.topTeeth[i] or 0; td += L.topDia[i] or 0 end
	local teeth = L.partTeeth + math.floor(math.max(0, T - L.partTeeth * n - tt) * share)
	local dia = L.partDia + math.floor(math.max(0, D - L.partDia * n - td) * share)
	teeth += L.topTeeth[place] or 0
	dia += L.topDia[place] or 0
	if not win then return 0, math.max(1, math.ceil(dia * L.loseMult)) end
	return teeth, dia
end

-- слоти бійців гравця
-- чи відкритий слот i (1..BASE_SLOTS + EXTRA_SLOTS): 1–3 — завжди, 4 — куплений за діаманти, 5 — геймпас
function M.slotOpen(p: Instance, i: number): boolean
	if i <= M.BASE_SLOTS then return true end
	if i == M.BASE_SLOTS + 1 then return p:GetAttribute("BossSlotDia") == true end
	if i == M.BASE_SLOTS + 2 then return p:GetAttribute("Pass_BossSlots") == true end
	return false
end
function M.slots(p: Instance): number
	local n = 0
	for i = 1, M.BASE_SLOTS + M.EXTRA_SLOTS do if M.slotOpen(p, i) then n += 1 end end
	return n
end

return M
