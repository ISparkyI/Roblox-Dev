--!nonstrict
-- StatsService — статистика гравця за весь час (атрибути Stat_*, зберігаються DataService за префіксом) і лідерборди в центрі зали.
-- Де: ServerScriptService/StatsService (ModuleScript). Запуск: NicheBoot. GDD - Leaderboards. 28.10.2026.
--
-- Статистика:
--   Stat_TotalMoney — усі зароблені Money (будь-яке зростання атрибута Money після завантаження даних)
--   Stat_Rolls      — роли: кожна зміна атрибута RollPullT ніші (важіль смикнули — вручну чи Auto Roll) → +1 власнику ніші
--   Stat_Playtime   — секунди в грі (старт — з profile.stats.playSeconds, далі +час сесії)
--   Stat_RobuxSpent — витрачені Robux: продукти — MonetizationService (ProcessReceipt, CurrencySpent), геймпаси — тут
--     (PromptGamePassPurchaseFinished, ціна з MonetizationConfig.Passes)
--   Stat_BestIncome — найбільший IncomePerMin (пік)
--   Stat_BestRoll   — найрідкісніший рол: «1 до N» = шанс голема × шанс мутації (RollService → StatsService.Max)
--   Stat_RobuxGifted — Robux, витрачені на подарунки іншим (GiftService)
--   Stat_BossKills  — перемоги над босами (буде з босами: StatsService.Add(p, "BossKills", 1))
--   Stat_OresMined  — шматки руди, добуті за весь час (PlotService.breakOre, 30.10.2026)
--   Stat_Mutations  — успішні мутації (MutationService.claim)
--   Stat_BestStreak — рекорд дейлі-стріку (DailyService)
--   StatsService.Add(p, key, n) — додати до Stat_<key>; StatsService.Max(p, key, v) — записати, якщо більше
-- Бонуси за місце (HubConfig.PERK_TIERS): після кожного оновлення табел — атрибути гравця LB_Money / LB_Luck / LB_Boss (%)
--   і LB_Ranks (JSON {key = місце}). Money — MultiService (джерело Leader), Luck — RollService.
-- Лідерборди (HubConfig.BOARDS): раз на LB_PERIOD с — значення онлайн-гравців → OrderedDataStore "LB_<key>",
--   топ LB_TOP → атрибут Data (JSON [{u, n, v}]) і UpdatedAt на Workspace/Cave/Hub/Leaderboards/<key>;
--   #1 — статуя (аватар гравця) на StatuePad над таблом. У Studio без доступу до API — сховище в пам'яті.
-- Маркет (HubConfig.isMarket, 03.11.2026): замість BOARDS — HubConfig.MARKET_BOARDS (Marketplace/Floor/<model>), без бонусів за місце.
--   Stat_MarketBought / Stat_MarketSold — големи, куплені / продані на маркеті (StatsService.Add — коли буде торгівля).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local HubCfg = require(Shared:WaitForChild("HubConfig"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local StatsService = {}
local STATS = { "Stat_TotalMoney", "Stat_Rolls", "Stat_Playtime", "Stat_RobuxSpent", "Stat_BestIncome", "Stat_BestRoll", "Stat_RobuxGifted", "Stat_BossKills",
	"Stat_OresMined", "Stat_Mutations", "Stat_BestStreak", "Stat_MarketBought", "Stat_MarketSold" }

local function num(p: Player, a: string): number return tonumber(p:GetAttribute(a)) or 0 end
-- 10.11.2026: топи за Robux (TOP DONATORS / TOP GIFTERS) — без ліміту часу в грі: покупець потрапляє в топ одразу
local NO_PLAYTIME_LIMIT = { Stat_RobuxSpent = true, Stat_RobuxGifted = true }
local schedulePublishOne: (string) -> () = function() end -- нижче
function StatsService.Add(p: Player, key: string, n: number)
	if not (p and p.Parent and DataService.IsLoaded(p)) or type(n) ~= "number" or n ~= n then return end
	local a = "Stat_" .. key
	p:SetAttribute(a, num(p, a) + n)
end
function StatsService.Max(p: Player, key: string, v: number)
	if not (p and p.Parent and DataService.IsLoaded(p)) or type(v) ~= "number" or v ~= v then return end
	local a = "Stat_" .. key
	if v > num(p, a) then p:SetAttribute(a, v) end
end

-- ===== гравці =====
local tracked: { [Player]: { money: number, tick: number } } = {}
local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	for _, a in STATS do if p:GetAttribute(a) == nil then p:SetAttribute(a, 0) end end
	-- час у грі — від того, що вже нараховано в профілі (якщо Stat_Playtime менший)
	local d = DataService.GetData(p)
	local ps = d and d.stats and tonumber(d.stats.playSeconds) or 0
	if ps > num(p, "Stat_Playtime") then p:SetAttribute("Stat_Playtime", ps) end
	-- 10.11.2026: Robux витрачені / подаровані — табло оновлюється одразу
	for a in NO_PLAYTIME_LIMIT do
		p:GetAttributeChangedSignal(a):Connect(function() schedulePublishOne(a) end)
	end
	local st = { money = num(p, "Money"), tick = os.clock() }
	tracked[p] = st
	local function inc() StatsService.Max(p, "BestIncome", math.floor(num(p, "IncomePerMin"))) end
	p:GetAttributeChangedSignal("IncomePerMin"):Connect(inc)
	inc()
	p:GetAttributeChangedSignal("Money"):Connect(function()
		local m = num(p, "Money")
		if m > st.money then p:SetAttribute("Stat_TotalMoney", num(p, "Stat_TotalMoney") + (m - st.money)) end
		st.money = m
	end)
end

-- роли: RollPullT ніші ставить LeverScript на кожне смикання важеля
local function hookNiche(n: Instance)
	n:GetAttributeChangedSignal("RollPullT"):Connect(function()
		local uid = n:GetAttribute("OwnerUserId")
		local p = type(uid) == "number" and uid ~= 0 and Players:GetPlayerByUserId(uid) or nil
		if p then StatsService.Add(p, "Rolls", 1) end
	end)
end

-- ===== лідерборди =====
local STUDIO = RunService:IsStudio()
local useMemory = false
local memory: { [string]: { [string]: number } } = {}
local stores = {}
local written: { [string]: { [number]: number } } = {}
local names: { [number]: string } = {}

local function store(key: string)
	if not stores[key] then stores[key] = DataStoreService:GetOrderedDataStore("LB_" .. key .. (STUDIO and "_Studio" or "")) end
	return stores[key]
end
local function fallback(err)
	if STUDIO and tostring(err):lower():find("studio") then
		if not useMemory then warn("StatsService: OrderedDataStore недоступний у Studio — лідерборди в пам'яті.") end
		useMemory = true
	end
end
local function nameOf(uid: number): string
	if names[uid] then return names[uid] end
	local p = Players:GetPlayerByUserId(uid)
	if p then names[uid] = p.Name; return p.Name end
	local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
	if ok and type(n) == "string" then names[uid] = n; return n end
	return "Player"
end
local LB_MIN_PLAYTIME = 20 * 60 -- крім NO_PLAYTIME_LIMIT (вище)
-- 06.11.2026: адміни / модератори (AdminService.IsStaffId) у лідерборди не потрапляють — ні в лобі, ні на маркеті:
--   не записуємо їхні значення, відфільтровуємо з топу (беремо із запасом) і раз за сесію сервера видаляємо їхні старі записи зі сховища.
local AdminService = nil
local function isStaff(uid: number): boolean
	if not AdminService then
		local ok, m = pcall(require, script.Parent:WaitForChild("AdminService"))
		if not ok then return false end
		AdminService = m
	end
	return AdminService.IsStaffId ~= nil and AdminService.IsStaffId(uid) == true
end
local purged: { [string]: { [number]: boolean } } = {}
local function write(b)
	written[b.key] = written[b.key] or {}
	for _, p in Players:GetPlayers() do
		if DataService.IsLoaded(p) and not isStaff(p.UserId) then
			local v = math.floor(num(p, b.stat))
			-- у топ потрапляють лише гравці з часом у грі ≥ LB_MIN_PLAYTIME (20 хв)
			if not NO_PLAYTIME_LIMIT[b.stat] and num(p, "Stat_Playtime") < LB_MIN_PLAYTIME then v = 0 end
			if v > 0 and written[b.key][p.UserId] ~= v then
				if not useMemory then
					-- 08.11.2026: бюджет запитів сервера вичерпано — пропускаємо (допишемо наступного разу), а не ставимо в чергу
					--   (попередження «DataStore request was added to queue» на LB_Bosses — останнє табло в циклі)
					local okB, budget = pcall(function() return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync) end)
					if okB and budget < 3 then continue end
					local ok, err = pcall(function() store(b.key):SetAsync(tostring(p.UserId), v) end)
					if not ok then fallback(err) end
				end
				if useMemory then memory[b.key] = memory[b.key] or {}; memory[b.key][tostring(p.UserId)] = v end
				written[b.key][p.UserId] = v
			end
		end
	end
end
local function read(b): { any }
	local list = {}
	if not useMemory then
		local ok, page = pcall(function() return store(b.key):GetSortedAsync(false, math.min(100, HubCfg.LB_TOP + 10)):GetCurrentPage() end)
		if ok then
			purged[b.key] = purged[b.key] or {}
			for _, e in page do
				local u = tonumber(e.key) or 0
				if isStaff(u) then
					if not purged[b.key][u] then
						purged[b.key][u] = true
						task.spawn(pcall, function() store(b.key):RemoveAsync(e.key) end)
					end
				elseif #list < HubCfg.LB_TOP then
					table.insert(list, { u = u, v = e.value })
				end
			end
			return list
		end
		fallback(page)
	end
	for k, v in memory[b.key] or {} do if not isStaff(tonumber(k) or 0) then table.insert(list, { u = tonumber(k) or 0, v = v }) end end
	table.sort(list, function(x, y) return x.v > y.v end)
	while #list > HubCfg.LB_TOP do table.remove(list) end
	return list
end

-- статуя гравця #1 на StatuePad (аватар, анкерований, без скриптів)
local statueOf: { [string]: number } = {}
-- зібрати аватар за суглобами до анкерування (29.10.2026): модель з CreateHumanoidModelFromUserId ще не в світі, фізика її не складала —
-- голова / аксесуари могли висіти збоку. Ставимо кожну деталь від HumanoidRootPart по Motor6D / Weld: Part1 = Part0 · C0 · C1⁻¹
local function solveRig(rig: Model)
	local root = rig:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum then pcall(function() hum:BuildRigFromAttachments() end) end
	-- суглоби: Motor6D / Weld (C0, C1) або нові AnimationConstraint / RigidConstraint (аватари з оновленими суглобами, Attachment0 / 1)
	local joints = {}
	for _, j in rig:GetDescendants() do
		if (j:IsA("Motor6D") or j:IsA("Weld")) and j.Part0 and j.Part1 then
			table.insert(joints, { Part0 = j.Part0, Part1 = j.Part1, C0 = j.C0, C1 = j.C1 })
		elseif (j:IsA("AnimationConstraint") or j:IsA("RigidConstraint")) and j.Attachment0 and j.Attachment1 then
			local a0, a1 = j.Attachment0, j.Attachment1
			if a0.Parent:IsA("BasePart") and a1.Parent:IsA("BasePart") then
				table.insert(joints, { Part0 = a0.Parent, Part1 = a1.Parent, C0 = a0.CFrame, C1 = a1.CFrame })
			end
		end
	end
	local done = { [root] = true }
	local progress = true
	while progress do
		progress = false
		for _, j in joints do
			local a, b = j.Part0, j.Part1
			if done[a] and not done[b] then
				b.CFrame = a.CFrame * j.C0 * j.C1:Inverse(); done[b] = true; progress = true
			elseif done[b] and not done[a] then
				a.CFrame = b.CFrame * j.C1 * j.C0:Inverse(); done[a] = true; progress = true
			end
		end
	end
end
local function placeStatue(model: Model, uid: number)
	if statueOf[model.Name] == uid then return end
	statueOf[model.Name] = uid
	local old = model:FindFirstChild("Statue")
	if old then old:Destroy() end
	local pad = model:FindFirstChild("StatuePad")
	if not (pad and uid > 0) then return end
	local ok, rig = pcall(function() return Players:CreateHumanoidModelFromUserId(uid) end)
	if not ok or not rig then return end
	rig.Name = "Statue"
	solveRig(rig)
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		elseif d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
	end
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.PlatformStand = true end
	pcall(function() rig:ScaleTo(1.25) end)
	local _, size = rig:GetBoundingBox()
	local top = pad.CFrame * CFrame.new(0, pad.Size.Y / 2, 0)
	rig:PivotTo(top * CFrame.new(0, size.Y / 2, 0)) -- дивиться туди ж, куди й табло (на центр зали)
	-- нижня точка моделі — на верху платформи
	local cf2, s2 = rig:GetBoundingBox()
	local dy = (top.Position.Y) - (cf2.Position.Y - s2.Y / 2)
	rig:PivotTo(rig:GetPivot() + Vector3.new(0, dy, 0))
	rig.Parent = model
end

-- бонуси за місце: збираємо за всіма таблами і ставимо атрибути онлайн-гравцям
local PERK_ATTR = { money = "LB_Money", luck = "LB_Luck", boss = "LB_Boss" }
local function applyPerks(ranks: { [string]: { [number]: number } })
	for _, p in Players:GetPlayers() do
		local sum = { money = 0, luck = 0, boss = 0 }
		local mine = {}
		for _, b in HubCfg.BOARDS do
			local r = ranks[b.key] and ranks[b.key][p.UserId]
			if r then
				mine[b.key] = r
				sum[b.perk] = (sum[b.perk] or 0) + HubCfg.perkPct(b.tier, r)
			end
		end
		for k, a in PERK_ATTR do
			local v = sum[k] or 0
			if (tonumber(p:GetAttribute(a)) or 0) ~= v then p:SetAttribute(a, v > 0 and v or nil) end
		end
		p:SetAttribute("LB_Ranks", HttpService:JSONEncode(mine))
	end
end

local function publishMarket()
	local fl = workspace:FindFirstChild("Marketplace") and workspace.Marketplace:FindFirstChild("Floor")
	for _, b in HubCfg.MARKET_BOARDS or {} do
		write(b)
		local list = read(b)
		for _, e in list do e.n = nameOf(e.u) end
		local m = fl and fl:FindFirstChild(b.model)
		if m then
			m:SetAttribute("Data", HttpService:JSONEncode(list))
			m:SetAttribute("UpdatedAt", workspace:GetServerTimeNow())
			m:SetAttribute("NextAt", workspace:GetServerTimeNow() + HubCfg.LB_PERIOD)
		end
	end
end

-- 10.11.2026: оновити одне табло одразу (після покупки за Robux), не чекаючи LB_PERIOD
local function publishOne(statName: string)
	if HubCfg.isMarket() then return end
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local folder = hub and hub:FindFirstChild("Leaderboards")
	for _, b in HubCfg.BOARDS do
		if b.stat == statName then
			write(b)
			local list = read(b)
			for _, e in list do e.n = nameOf(e.u) end
			local m = folder and folder:FindFirstChild(b.key)
			if m then
				m:SetAttribute("Data", HttpService:JSONEncode(list))
				m:SetAttribute("UpdatedAt", workspace:GetServerTimeNow())
				task.spawn(placeStatue, m, list[1] and list[1].u or 0)
			end
		end
	end
end
local pendingOne: { [string]: boolean } = {}
schedulePublishOne = function(statName: string)
	if pendingOne[statName] then return end
	pendingOne[statName] = true
	task.delay(3, function() -- кілька покупок поспіль — одне оновлення
		pendingOne[statName] = nil
		local ok, err = pcall(publishOne, statName)
		if not ok then warn("StatsService: ", err) end
	end)
end

local function publish()
	if HubCfg.isMarket() then publishMarket(); return end
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local folder = hub and hub:FindFirstChild("Leaderboards")
	local ranks = {}
	for _, b in HubCfg.BOARDS do
		write(b)
		local list = read(b)
		ranks[b.key] = {}
		for i, e in list do e.n = nameOf(e.u); ranks[b.key][e.u] = i end
		local m = folder and folder:FindFirstChild(b.key)
		if m then
			m:SetAttribute("Data", HttpService:JSONEncode(list))
			m:SetAttribute("UpdatedAt", workspace:GetServerTimeNow())
			m:SetAttribute("NextAt", workspace:GetServerTimeNow() + HubCfg.LB_PERIOD)
			task.spawn(placeStatue, m, list[1] and list[1].u or 0)
		end
	end
	applyPerks(ranks)
end

function StatsService.Start()
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) tracked[p] = nil end)
	-- роли з ніш: на сервері Marketplace ніш немає (HubConfig.isMarket) — не чекаємо, інакше NicheBoot завис би тут
	task.spawn(function()
		local niches = workspace:WaitForChild("Niches", 30)
		if not niches then return end
		for _, n in niches:GetChildren() do hookNiche(n) end
		niches.ChildAdded:Connect(hookNiche)
	end)
	-- геймпаси за Robux → Stat_RobuxSpent (ціна з конфіга)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
		if not purchased then return end
		for _, def in MonCfg.Passes do
			if def.id == passId then StatsService.Add(p, "RobuxSpent", tonumber(def.robux) or 0); break end
		end
	end)
	-- час у грі: раз на 15 с
	task.spawn(function()
		while true do
			task.wait(15)
			local t = os.clock()
			for p, st in tracked do
				if p.Parent then
					p:SetAttribute("Stat_Playtime", num(p, "Stat_Playtime") + math.floor(t - st.tick + 0.5))
					st.tick = t
				end
			end
		end
	end)
	-- лідерборди
	task.spawn(function()
		task.wait(8)
		while true do
			local ok, err = pcall(publish)
			if not ok then warn("StatsService: ", err) end
			task.wait(HubCfg.LB_PERIOD)
		end
	end)
end

return StatsService
