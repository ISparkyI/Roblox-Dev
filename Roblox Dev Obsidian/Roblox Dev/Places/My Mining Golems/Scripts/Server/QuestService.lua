--!strict
-- QuestService — квести (GDD - Quests and Index): щоденні, тижневі ланцюжки, спеціальні. Вікно — StarterPlayerScripts/QuestsWindow.
-- Де: ServerScriptService/QuestService (ModuleScript), запускає NicheBoot. Дані — секція профілю "Quests" (DataService).
-- Лічильники (QuestService.Add(player, stat, n)) кличуть інші сервіси:
--   Mine — зламана руда на плоті (PlotService), Sell — продані руда й злитки, шт. (SellService), Roll — роли (RollService),
--   Buy — куплені після ролу големи (RollService), Smelt — забрані з кузні злитки (ForgeService), Play — хвилини в грі (тут),
--   Boss — бої з босом (ще немає боса).
-- Щоденні: 3 квести на добу (UTC), набір і цілі однозначно з (день, UserId) — легкий / середній / важкий, нагорода 5 / 10 / 15 діамантів.
-- Тижневі: 6 ланцюжків (тиждень з понеділка, UTC); рахунок за тиждень наростає, рівень i виконано, коли рахунок ≥ цілі i;
--   забирати по одному рівню, нагорода 5 / 10 / 20 / 40 / 80 діамантів. Boss — SOON (боса ще немає).
-- Спеціальні: 20 годин у грі (сумарно) → Exclusive «100% Best» — поки SOON (голема ще немає), прогрес уже рахується.
-- Клієнту — атрибут гравця QuestState (JSON, раз на ≤ 1 с при змінах). RemoteFunction Remotes/QuestAction:
--   ("Claim", { kind = "daily", i = 1..3 }) / ("Claim", { kind = "weekly", key = "Mine" }) / ("ClaimAll") → { ok, diamonds }.
-- Нагороди й цілі — пропозиція (GDD).
-- Studio: атрибут цього скрипта TestAdd = "Mine:50" додає всім гравцям (для перевірки).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local DataService = require(script.Parent:WaitForChild("DataService"))

local QuestService = {}

local DAY = 86400
local WEEK = 7 * DAY
local function dayIdx(t: number): number return t // DAY end
local function weekIdx(t: number): number return (t + 3 * DAY) // WEEK end -- 1.1.1970 — четвер; тиждень з понеділка

-- щоденні: стат, назва (%d — ціль), цілі легкий / середній / важкий
local DAILY_POOL = {
	{ stat = "Mine", text = "Break %s ores", t = { 25, 60, 120 } },
	{ stat = "Sell", text = "Sell %s ores or bars", t = { 20, 50, 100 } },
	{ stat = "Roll", text = "Roll %s times", t = { 10, 25, 50 } },
	{ stat = "Buy", text = "Buy %s rolled golems", t = { 2, 5, 10 } },
	{ stat = "Play", text = "Play for %s minutes", t = { 10, 20, 40 } },
	{ stat = "Smelt", text = "Collect %s bars from the Workshop", t = { 10, 25, 50 } },
}
local DAILY_REWARD = { 5, 10, 15 }

-- тижневі ланцюжки (порядок показу)
local WEEKLY = {
	{ key = "Mine", text = "Break %s ores", t = { 10, 50, 250, 1000, 5000 } },
	{ key = "Sell", text = "Sell %s ores or bars", t = { 5, 25, 100, 400 } },
	{ key = "Roll", text = "Roll %s times", t = { 20, 100, 400, 1500 } },
	{ key = "Play", text = "Play for %s", t = { 30, 120, 300, 600 }, time = true },
	{ key = "Boss", text = "Boss fights: %s", t = { 1, 3, 10, 25 }, soon = true },
	{ key = "Buy", text = "Buy %s rolled golems", t = { 5, 20, 60, 150 } },
}
local WEEK_REWARD = { 5, 10, 20, 40, 80 }

local SPECIAL = {
	{ key = "Best100", stat = "Play", text = "Play for 20 hours in total", target = 1200, reward = "100% Best", soon = true },
}

type Q = {
	day: number, dStats: { [string]: number }, dClaimed: { [string]: boolean },
	week: number, wStats: { [string]: number }, wLvl: { [string]: number },
	total: { [string]: number }, special: { [string]: boolean },
}
local state: { [Player]: Q } = {}
local dirty: { [Player]: boolean } = {}
local playAcc: { [Player]: number } = {}

-- набір щоденних на день: 3 різні стати, однозначно з (день, UserId)
local function dailyFor(p: Player, day: number)
	local rnd = Random.new(day * 7919 + p.UserId % 1000003)
	local idx = {}
	for i = 1, #DAILY_POOL do idx[i] = i end
	for i = #idx, 2, -1 do local j = rnd:NextInteger(1, i); idx[i], idx[j] = idx[j], idx[i] end
	local out = {}
	for tier = 1, 3 do
		local d = DAILY_POOL[idx[tier]]
		table.insert(out, { stat = d.stat, text = d.text, target = d.t[tier], reward = DAILY_REWARD[tier] })
	end
	return out
end

local function fresh(): Q
	local t = os.time()
	return { day = dayIdx(t), dStats = {}, dClaimed = {}, week = weekIdx(t), wStats = {}, wLvl = {}, total = {}, special = {} }
end

-- новий день / тиждень — скинути відповідні лічильники
local function roll(q: Q)
	local t = os.time()
	if q.day ~= dayIdx(t) then q.day = dayIdx(t); q.dStats = {}; q.dClaimed = {} end
	if q.week ~= weekIdx(t) then q.week = weekIdx(t); q.wStats = {}; q.wLvl = {} end
end

local function fmtNum(n: number): string
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if r:sub(1, 1) == "," then r = r:sub(2) end
	return r
end
local function fmtTime(min: number): string
	if min >= 60 then
		local h = min / 60
		return (h == math.floor(h) and tostring(h) or string.format("%.1f", h)) .. (h == 1 and " hour" or " hours")
	end
	return tostring(min) .. " minutes"
end

local function snapshot(p: Player, q: Q)
	local daily = {}
	for i, d in dailyFor(p, q.day) do
		local prog = q.dStats[d.stat] or 0
		table.insert(daily, { i = i, stat = d.stat, text = string.format(d.text, fmtNum(d.target)), prog = math.min(prog, d.target),
			target = d.target, reward = d.reward, claimed = q.dClaimed[tostring(i)] == true })
	end
	local weekly = {}
	for _, w in WEEKLY do
		local lvl = q.wLvl[w.key] or 0
		local max = #w.t
		local tgt = w.t[math.min(lvl + 1, max)]
		local prog = q.wStats[w.key] or 0
		table.insert(weekly, { key = w.key, lvl = lvl, max = max, prog = math.min(prog, tgt), target = tgt,
			text = string.format(w.text, w.time and fmtTime(tgt) or fmtNum(tgt)), reward = WEEK_REWARD[math.min(lvl + 1, #WEEK_REWARD)],
			done = lvl >= max, soon = w.soon == true })
	end
	local special = {}
	for _, s in SPECIAL do
		local prog = q.total[s.stat] or 0
		table.insert(special, { key = s.key, text = s.text, prog = math.min(prog, s.target), target = s.target, reward = s.reward,
			claimed = q.special[s.key] == true, soon = s.soon == true })
	end
	return { day = q.day, week = q.week, daily = daily, weekly = weekly, special = special }
end

local function publish(p: Player)
	local q = state[p]
	if not q then return end
	roll(q)
	p:SetAttribute("QuestState", HttpService:JSONEncode(snapshot(p, q)))
end

function QuestService.Add(p: Player, stat: string, n: number?)
	local q = state[p]
	if not q then return end
	local k = n or 1
	if type(k) ~= "number" or k <= 0 or k ~= k then return end
	roll(q)
	q.dStats[stat] = (q.dStats[stat] or 0) + k
	q.wStats[stat] = (q.wStats[stat] or 0) + k
	q.total[stat] = (q.total[stat] or 0) + k
	dirty[p] = true
end

local function addDiamonds(p: Player, n: number)
	p:SetAttribute("Diamonds", ((tonumber(p:GetAttribute("Diamonds")) or 0) :: number) + n)
	-- кожна отримана нагорода квесту — +1 до Stat_QuestsDone (особисте табло біля ніші, PlotStatsClient)
	p:SetAttribute("Stat_QuestsDone", ((tonumber(p:GetAttribute("Stat_QuestsDone")) or 0) :: number) + 1)
end

-- одна нагорода; повертає кількість діамантів (0 — не можна)
local function claimOne(p: Player, q: Q, kind: string, arg: any): number
	if kind == "daily" then
		local i = tonumber(arg)
		local list = dailyFor(p, q.day)
		local d = i and list[i]
		if not d or q.dClaimed[tostring(i)] then return 0 end
		if (q.dStats[d.stat] or 0) < d.target then return 0 end
		q.dClaimed[tostring(i)] = true
		addDiamonds(p, d.reward)
		return d.reward
	elseif kind == "weekly" then
		for _, w in WEEKLY do
			if w.key == arg and not w.soon then
				local lvl = q.wLvl[w.key] or 0
				if lvl >= #w.t then return 0 end
				if (q.wStats[w.key] or 0) < w.t[lvl + 1] then return 0 end
				q.wLvl[w.key] = lvl + 1
				local r = WEEK_REWARD[math.min(lvl + 1, #WEEK_REWARD)]
				addDiamonds(p, r)
				return r
			end
		end
	end
	return 0
end

local busy: { [Player]: boolean } = {}
local function onInvoke(p: Player, action: any, arg: any): any
	local q = state[p]
	if not q or busy[p] then return { ok = false } end
	busy[p] = true
	roll(q)
	local got = 0
	if action == "Claim" and type(arg) == "table" then
		got = claimOne(p, q, tostring(arg.kind), arg.kind == "daily" and arg.i or arg.key)
	elseif action == "ClaimAll" then
		for i = 1, 3 do got += claimOne(p, q, "daily", i) end
		for _, w in WEEKLY do
			for _ = 1, #w.t do
				local r = claimOne(p, q, "weekly", w.key)
				if r <= 0 then break end
				got += r
			end
		end
	end
	busy[p] = nil
	if got > 0 then publish(p); dirty[p] = nil end
	return { ok = got > 0, diamonds = got }
end

local function load(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "Quests")
	local q = fresh()
	if type(sec) == "table" then
		for _, k in { "day", "week" } do if type(sec[k]) == "number" then (q :: any)[k] = sec[k] end end
		for _, k in { "dStats", "dClaimed", "wStats", "wLvl", "total", "special" } do
			if type(sec[k]) == "table" then (q :: any)[k] = sec[k] end
		end
	end
	state[p] = q
	publish(p)
end

function QuestService.Start()
	DataService.RegisterSection("Quests", function(p, old)
		local q = state[p]
		if not q then return old end
		return { day = q.day, week = q.week, dStats = q.dStats, dClaimed = q.dClaimed, wStats = q.wStats, wLvl = q.wLvl,
			total = q.total, special = q.special }
	end)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("QuestAction") or Instance.new("RemoteFunction")
	rf.Name = "QuestAction"; rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onInvoke
	Players.PlayerAdded:Connect(function(p) task.spawn(load, p) end)
	for _, p in Players:GetPlayers() do task.spawn(load, p) end
	Players.PlayerRemoving:Connect(function(p)
		task.delay(30, function() -- секція пишеться при виході — даємо DataService зняти знімок
			if p.Parent then return end
			state[p] = nil; dirty[p] = nil; playAcc[p] = nil; busy[p] = nil
		end)
	end)
	-- тест у Studio: атрибут скрипта TestAdd = "Mine:50" — додати всім гравцям (лише Studio)
	if RunService:IsStudio() then
		script:GetAttributeChangedSignal("TestAdd"):Connect(function()
			local v = script:GetAttribute("TestAdd")
			local stat, n = string.match(tostring(v), "^(%a+):(%d+)$")
			if stat then for _, p in Players:GetPlayers() do QuestService.Add(p, stat, tonumber(n)) end end
		end)
	end
	-- хвилини в грі (хвилина — коли набралось 60 с) і публікація змін раз на секунду
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1)
			local t = os.clock()
			local dt = t - last
			last = t
			for p in state do
				if p.Parent == Players then
					playAcc[p] = (playAcc[p] or 0) + dt
					if playAcc[p] >= 60 then
						local m = math.floor(playAcc[p] / 60)
						playAcc[p] -= m * 60
						QuestService.Add(p, "Play", m)
					end
					local q = state[p]
					if q and (q.day ~= dayIdx(os.time()) or q.week ~= weekIdx(os.time())) then dirty[p] = true end
					if dirty[p] then dirty[p] = nil; publish(p) end
				end
			end
		end
	end)
end

return QuestService
