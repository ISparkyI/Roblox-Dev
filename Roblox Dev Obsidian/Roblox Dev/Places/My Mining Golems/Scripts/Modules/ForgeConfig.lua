--!strict
-- ForgeConfig — числа Forge (кузня з големом-ковалем). Спільний для сервера й клієнта.
-- Де: ReplicatedStorage/Shared/ForgeConfig. Усі ціни — етап 1 (пропозиція, див. GDD 7.1).

local Config = {}

-- руда кожної мапи (29.10.2026): ціни — GDD - Ores and Bars (ціна = базова × 20^(мапа−1)); по 3 руди на мапу
Config.STAGE_ORES = {
	[1] = {
		{ key = "Coal",   color = Color3.fromHex("2b2e33"), bar = Color3.fromHex("34373d"), price = 8, smelt = false }, -- вугілля НЕ плавиться (злитків немає) — лише продається
		{ key = "Copper", color = Color3.fromHex("c8643a"), bar = Color3.fromHex("d9733f"), price = 20 },
		{ key = "Iron",   color = Color3.fromHex("d08a55"), bar = Color3.fromHex("e0e4ea"), price = 50 },
	},
	[2] = {
		{ key = "Tin",    color = Color3.fromHex("a9bccb"), bar = Color3.fromHex("c9d5de"), price = 160 },
		{ key = "Silver", color = Color3.fromHex("e3e8ee"), bar = Color3.fromHex("f1f4f8"), price = 400 },
		{ key = "Gold",   color = Color3.fromHex("ffc928"), bar = Color3.fromHex("ffd84a"), price = 1000 },
	},
}
Config.MAX_STAGE = 2 -- скільки мап уже є в грі (префаби NichePrefab_Stage1..N)
-- усі руди всіх мап (інвентар, збереження, продаж старої руди)
Config.ALL_ORES = {}
for st = 1, Config.MAX_STAGE do for _, o in Config.STAGE_ORES[st] do o.stage = st; table.insert(Config.ALL_ORES, o) end end
function Config.oresFor(stage: number?): { any }
	return Config.STAGE_ORES[math.clamp(math.floor(tonumber(stage) or 1), 1, Config.MAX_STAGE)]
end
function Config.oreDef(key: string): any
	for _, o in Config.ALL_ORES do if o.key == key then return o end end
	return nil
end
-- пробудження голема кузні (Workshop) на кожній мапі: руда мапи (по порядку) + гроші
Config.WAKE = {
	[1] = { req = { 20, 10, 5 }, money = 1000 },
	[2] = { req = { 30, 15, 8 }, money = 100000 },
}
function Config.wakeFor(stage: number?): any
	return Config.WAKE[math.clamp(math.floor(tonumber(stage) or 1), 1, Config.MAX_STAGE)]
end
-- ORES / WAKE_REQ / WAKE_MONEY — руда й пробудження ПОТОЧНОЇ мапи. На сервері — мапа 1 (сервіси беруть oresFor(етап ніші));
-- на клієнті таблиці оновлюються НА МІСЦІ при зміні атрибута Stage гравця (вікна, що тримають посилання, бачать нову руду).
Config.ORES = table.clone(Config.STAGE_ORES[1])
-- чи можна плавити руду в злитки (вугілля — ні: його кладуть лише для пробудження голема або продають)
function Config.canSmelt(o): boolean return o.smelt ~= false end
Config.BAR_MULT = 1.5          -- злиток = ціна руди × 1.5
Config.WAKE_REQ = table.clone(Config.WAKE[1].req) -- руда етапу, щоб розбудити голема (поточна мапа, див. вище)
Config.WAKE_MONEY = Config.WAKE[1].money -- і ще гроші (знімаються кнопкою Wake Up; окремий рядок Money у вікні Forge)
Config.StageChanged = Instance.new("BindableEvent") -- клієнт: руда мапи змінилась (вікна перебудовують рядки)
if game:GetService("RunService"):IsClient() then
	local lp = game:GetService("Players").LocalPlayer
	local cur = 1
	local function sync()
		local st = math.clamp(math.floor(tonumber(lp:GetAttribute("Stage")) or 1), 1, Config.MAX_STAGE)
		if st == cur then return end
		cur = st
		Config.curStage = st
		table.clear(Config.ORES); for _, o in Config.oresFor(st) do table.insert(Config.ORES, o) end
		table.clear(Config.WAKE_REQ); for _, n in Config.wakeFor(st).req do table.insert(Config.WAKE_REQ, n) end
		Config.WAKE_MONEY = Config.wakeFor(st).money
		Config.StageChanged:Fire(st)
	end
	sync()
	lp:GetAttributeChangedSignal("Stage"):Connect(sync)
end
Config.VIS_ORE = 16            -- скільки кубиків кожного типу видно на піддоні Ore
Config.VIS_BARS = 24           -- скільки злитків видно на піддоні Bars
Config.RING_R = 8.64           -- радіус кола взаємодії (стади; коло збільшено ще в 1.5 раза)
Config.WAKE_TIME = 4.2         -- тривалість анімації пробудження, с
Config.DOZE_TIME = 4.2         -- тривалість засинання, с
Config.SMELT_FLIGHT = 1.1      -- (застаріле) раніше: руда летить у піч + злиток вилітає, с
Config.WAIT_WORD = "WAITING"     -- стан «кузня працює, але голем нічого не плавить» (табличка над кузнею + чип у вікні); до слова додаються крапки
Config.BAR_DELAY = 2.7         -- через скільки секунд після переплавки злиток зараховується на піддон
                               -- (руда летить у піч → гаряча заготовка на ковадло → удар → політ на піддон)

Config.SPD_MIN = 0.25          -- найшвидший інтервал удару, с (рівень 12; було 0.75 на рівні 10)
Config.OPH_MAX = 10           -- Ore per Hit: максимум руди, яку голем переробляє за один удар

-- мапа для формул (29.10.2026): на клієнті — мапа гравця (оновлює sync нижче), на сервері сервіс передає мапу кузні.
-- Місткість піддону ($) росте як ціна руди мапи (×20 на мапу); ціни покращень — × PlotConfig-правило (1 + 2 × (множник мапи − 1)).
Config.curStage = Config.curStage or 1
local function st(stage: number?): number return math.max(1, math.floor(tonumber(stage) or Config.curStage)) end
local MultiCfg = require(script.Parent:WaitForChild("MultiConfig"))
function Config.priceMult(stage: number?): number return 1 + 2 * (MultiCfg.stageMult(st(stage)) - 1) end
-- економіка v2 (29.10.2026): місткість піддону — 10 рівнів ($300 → $20,000 на мапі 1, ×20 за мапу); було +$300 без межі
Config.CAP_LEVELS = { 300, 500, 800, 1300, 2000, 3200, 5000, 8000, 12500, 20000 }
Config.CAP_MAX = #Config.CAP_LEVELS
function Config.capOf(l: number, stage: number?): number return Config.CAP_LEVELS[math.clamp(math.floor(l), 1, Config.CAP_MAX)] * 20 ^ (st(stage) - 1) end
function Config.capMax(l: number): boolean return l >= Config.CAP_MAX end
function Config.spdOf(l: number): number return math.max(Config.SPD_MIN, 3 - (l - 1) * 0.25) end
function Config.spdMax(l: number): boolean return Config.spdOf(l) <= Config.SPD_MIN + 1e-6 end
function Config.ophOf(l: number): number return math.clamp(math.floor(l), 1, Config.OPH_MAX) end -- рівень 1 = 1 руда за удар
function Config.ophMax(l: number): boolean return l >= Config.OPH_MAX end
-- ціни переходу з рівня l на l + 1 (мапа 1; × priceMult на інших мапах), економіка v2
Config.CAP_PRICES = { 100, 200, 350, 675, 1300, 2400, 4500, 8500, 16000 }
Config.SPD_PRICES = { 75, 125, 200, 350, 575, 950, 1600, 2600, 4300, 7200, 12000 }
Config.OPH_PRICES = { 300, 525, 950, 1700, 3000, 5300, 9500, 17000, 30000 }
local function at(t: { number }, l: number): number return t[math.clamp(math.floor(l), 1, #t)] end
function Config.capPrice(l: number, stage: number?): number return math.floor(at(Config.CAP_PRICES, l) * Config.priceMult(stage)) end
function Config.spdPrice(l: number, stage: number?): number return math.floor(at(Config.SPD_PRICES, l) * Config.priceMult(stage)) end
function Config.ophPrice(l: number, stage: number?): number return math.floor(at(Config.OPH_PRICES, l) * Config.priceMult(stage)) end

-- Auto Workshop (29.10.2026): четверта картка табло Workshop. Куплена (AutoLvl = 2 на моделі кузні) або геймпас Pass_AutoWorkshop — кузня
--   сама бере руду мапи з інвентаря на піддон, плавить і кладе злитки в інвентар (ForgeService.autoStep). Картка відкривається
--   з мапи AUTO_MIN_STAGE і скидається на наступній мапі (секція Forge); геймпас — з мапи 1 і назавжди. Ціна — фіксована
--   (рішення користувача). Перемикач ON / OFF — цією ж карткою (Set_AutoWorkshop).
Config.AUTO_MIN_STAGE = 3
Config.AUTO_PRICE = 5000000
function Config.autoOwned(p: Instance?, f: Instance?): boolean
	if p and p:GetAttribute("Pass_AutoWorkshop") == true then return true end
	return f ~= nil and (tonumber(f:GetAttribute("AutoLvl")) or 1) >= 2
end

-- ТЕСТ: поки немає інвентаря, гравець отримує руду й гроші атрибутами.
Config.TEST_START = { Ore = { 25, 12, 6 }, Money = 0 } -- стартові гроші нового гравця: 0 (29.10.2026, було 10,000)
Config.TEST_SELL_BARS = false -- false: «Забрати злитки» кладе їх в інвентар (Bars_<руда>), продаються в лавці Sell; true — ТЕСТ: одразу продати

return Config
