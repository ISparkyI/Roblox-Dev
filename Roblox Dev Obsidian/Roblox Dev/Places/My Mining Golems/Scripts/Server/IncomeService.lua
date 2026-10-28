--!strict
-- IncomeService — скільки гравець заробляє за 1 хвилину (для статистики й тайм-скіпів у SHOP).
-- Де: ServerScriptService/IncomeService (ModuleScript). Запуск: NicheBoot.
-- Як рахуємо: дохід = вартість руди, яку добувають големи на плотах (PlotService → IncomeService.Record при зламі руди:
--   шматки × ціна руди ForgeConfig), а не продажі (гравець продає пачками, це нерівно). Кошики по 1 хвилині, вікно WINDOW хв.
--   Швидкість = сума вікна / хвилин у вікні (не менше 1) × постійний множник (добуток Multi_* : друзі, ребітхи, донат, VIP, мапа;
--   БЕЗ подій і Money Potion — тимчасові бонуси не роздувають тайм-скіп). Не менше MIN_RATE.
-- Атрибути гравця: IncomePerMin (поточна, оновлюється раз на 5 с) і IncomeRate (збережене DataService значення — щоб після входу
--   тайм-скіп одразу мав нормальну суму; поки нових даних менше FRESH хвилин, береться більше з двох).
-- Тайм-скіп (MonetizationService): Money += IncomeService.Rate(p) × хвилини.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))

local IncomeService = {}
local WINDOW = 10   -- хвилин у вікні
local FRESH = 3     -- хвилин даних, після яких довіряємо поточному значенню
local MIN_RATE = 100 -- $/хв мінімум (новачок без големів)

type Track = { buckets: { [number]: number }, since: number }
local tracks: { [Player]: Track } = {}

local function minuteNow(): number return math.floor(os.time() / 60) end
local function baseMulti(p: Player): number
	local m = 1
	for _, s in MultiCfg.SOURCES do m *= tonumber(p:GetAttribute("Multi_" .. s.key)) or 1 end
	return m
end

-- руда добута на плоті: base — вартість у $ без множників
function IncomeService.Record(p: Player, base: number)
	local t = tracks[p]
	if not t or base <= 0 then return end
	local k = minuteNow()
	t.buckets[k] = (t.buckets[k] or 0) + base
end

local function compute(p: Player): number
	local t = tracks[p]
	if not t then return MIN_RATE end
	local now = minuteNow()
	local sum = 0
	for k, v in t.buckets do
		if now - k >= WINDOW then t.buckets[k] = nil else sum += v end
	end
	local mins = math.clamp((os.time() - t.since) / 60, 1, WINDOW)
	local rate = sum / mins * baseMulti(p)
	local saved = tonumber(p:GetAttribute("IncomeRate")) or 0
	if (os.time() - t.since) / 60 < FRESH then rate = math.max(rate, saved) end
	return math.max(MIN_RATE, math.floor(rate))
end

-- поточна швидкість ($/хв) — для тайм-скіпів
function IncomeService.Rate(p: Player): number return compute(p) end

function IncomeService.Start()
	local function add(p: Player) tracks[p] = { buckets = {}, since = os.time() } end
	Players.PlayerAdded:Connect(add)
	for _, p in Players:GetPlayers() do add(p) end
	Players.PlayerRemoving:Connect(function(p) tracks[p] = nil end)
	task.spawn(function()
		while true do
			task.wait(5)
			for p in tracks do
				if p.Parent then
					local r = compute(p)
					p:SetAttribute("IncomePerMin", r)
					if (os.time() - tracks[p].since) / 60 >= FRESH then p:SetAttribute("IncomeRate", r) end
				end
			end
		end
	end)
end

return IncomeService
