--!nonstrict
-- DailyService — щоденні нагороди (DAILY REWARDS, 29.10.2026). Де: ServerScriptService/DailyService (ModuleScript). Запуск: NicheBoot.
-- Числа й генерація нагород — Shared/DailyConfig. Вікно — StarterPlayerScripts/DailyWindow (кнопка Daily під Rebirth у HUD).
-- Дані гравця (атрибути, DataService, global): DailySeed (свій ряд нагород), DailyIdx (скільки нагород уже взято;
--   наступна = DailyIdx + 1), DailyLast (день DailyConfig.dayIndex останнього безкоштовного CLAIM), DailyStreak (днів підряд).
-- CLAIM: раз на день (DailyLast < сьогодні); стрік +1, якщо вчора теж забирав, інакше 1. Скіп за Robux (Developer Products DailyConfig.SKIP /
--   SKIP7, MonetizationService → DailyService.Skip) — наступна нагорода одразу, день і стрік не змінюються.
-- Remotes/DailyAction (RemoteFunction): ("Claim") → { ok, reward?, err? }. Атрибут DailyGot = JSON останньої нагороди (тост на клієнті).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("DailyConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local DailyService = {}
local busy: { [Player]: boolean } = {}

local function num(p: Player, a: string, d: number): number return tonumber(p:GetAttribute(a)) or d end
local function add(p: Player, a: string, n: number) p:SetAttribute(a, num(p, a, 0) + n) end
-- рекорд стріку — Stat_BestStreak (особисте табло, DataService за префіксом Stat_)
local function bestStreak(p: Player)
	local s = num(p, "DailyStreak", 0)
	if s > num(p, "Stat_BestStreak", 0) then p:SetAttribute("Stat_BestStreak", s) end
end

-- видати нагороду rw гравцеві
local function grant(p: Player, rw: any): boolean
	local okM, Mon = pcall(require, script.Parent:FindFirstChild("MonetizationService"))
	if rw.kind == "skip" or rw.kind == "potionpack" or rw.kind == "luckroll" or rw.kind == "luckroll99" then
		local key = rw.kind == "skip" and rw.key or ({ potionpack = "PotionPack", luckroll = "LuckRoll10", luckroll99 = "LuckRoll99" })[rw.kind]
		return okM and Mon and Mon.GrantProduct(p, key) == true
	elseif rw.kind == "diamonds" then add(p, "Diamonds", rw.n)
	elseif rw.kind == "tickets" then add(p, "Tickets", rw.n)
	elseif rw.kind == "potion" then add(p, "Pot_" .. rw.key, rw.n)
	elseif rw.kind == "golem" then
		local okI, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
		local okC, Cave = pcall(require, script.Parent:FindFirstChild("CaveStandService"))
		if not (okI and okC and Inv and Cave) then return false end
		local gid = Cave.MaxId(p) + 1
		local okA, added = pcall(Inv.AddGolem, p, gid, rw.key, rw.cls or "carrier", 0, "daily", true)
		if not (okA and added) then return false end
		if Inv.Pin then pcall(Inv.Pin, p, "Golem_" .. gid) end
	else
		return false
	end
	return true
end

local function give(p: Player): (boolean, any)
	local n = num(p, "DailyIdx", 0) + 1
	local rw = Cfg.reward(num(p, "DailySeed", 1), n)
	if not grant(p, rw) then return false, nil end
	p:SetAttribute("DailyIdx", n)
	rw.day = n
	p:SetAttribute("DailyGot", HttpService:JSONEncode(rw))
	return true, rw
end

-- безкоштовна нагорода дня
function DailyService.Claim(p: Player): any
	if busy[p] or not DataService.IsLoaded(p) then return { ok = false, err = "busy" } end
	local today = Cfg.dayIndex(os.time())
	local last = num(p, "DailyLast", -1)
	if last >= today then return { ok = false, err = "claimed" } end
	busy[p] = true
	local ok, rw = give(p)
	if ok then
		p:SetAttribute("DailyStreak", last == today - 1 and num(p, "DailyStreak", 0) + 1 or 1)
		p:SetAttribute("DailyLast", today)
		bestStreak(p)
		task.spawn(function() pcall(DataService.SaveNow, p) end)
	end
	busy[p] = nil
	return { ok = ok, reward = rw, err = (not ok) and "fail" or nil }
end

-- скіп за Robux (викликає MonetizationService з ProcessReceipt): наступна нагорода зараз
function DailyService.Skip(p: Player): boolean
	if not DataService.IsLoaded(p) then return false end
	local ok = give(p)
	return ok
end

function DailyService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("DailyAction") or Instance.new("RemoteFunction")
	rf.Name = "DailyAction"; rf.Parent = remotes
	rf.OnServerInvoke = function(p: Player, action: any)
		if action == "Claim" then return DailyService.Claim(p) end
		return { ok = false }
	end
	local function onPlayer(p: Player)
		if not DataService.WaitLoaded(p) then return end
		if not p:GetAttribute("DailySeed") then p:SetAttribute("DailySeed", Random.new():NextInteger(1, 2000000000)) end
		if p:GetAttribute("DailyIdx") == nil then p:SetAttribute("DailyIdx", 0) end
		-- стрік розірвано (пропущено день) — показуємо 0, доки не забере сьогодні
		bestStreak(p)
		if num(p, "DailyLast", -1) < Cfg.dayIndex(os.time()) - 1 then p:SetAttribute("DailyStreak", 0) end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
	-- день для клієнта (таймер і CLAIM такий самий, як на сервері)
	task.spawn(function()
		while true do
			local t = os.time()
			RS:SetAttribute("DailyDay", Cfg.dayIndex(t))
			RS:SetAttribute("DailyNextAt", Cfg.nextReset(t))
			task.wait(5)
		end
	end)
end

return DailyService
