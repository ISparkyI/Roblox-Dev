--!nonstrict
-- MultiService — рахує глобальний множник Money гравця (тільки сервер).
-- Де: ServerScriptService/MultiService (ModuleScript). Запуск: NicheBoot (після DataService).
--
-- Джерела (MultiConfig.SOURCES): Friends, Rebirth, Donate, VIP, Stage. Кожне пишеться в атрибут гравця Multi_<key>,
-- загальний множник (добуток) — у TotalMulti. Клієнт (MoneyHUD) показує їх у плашці над TOTAL MULTI.
-- Вхідні дані (атрибути гравця, зберігаються DataService): Stage, Rebirths, DonateTier, Pass_VIP. Друзів рахуємо на сервері
-- (Player:IsFriendsWith), перераховуємо при вході/виході будь-кого.
--
-- API: MultiService.Start(); MultiService.Get(player) -> TotalMulti; MultiService.Apply(player, amount) -> amount × TotalMulti (округлено).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local MultiService = {}

local friendsOf: { [Player]: { [number]: boolean } } = {} -- друзі гравця, що зараз на сервері (userId → true)
local ready: { [Player]: boolean } = {}

local function friendCount(p: Player): number
	local n = 0
	for _ in friendsOf[p] or {} do n += 1 end
	return n
end

local function compute(p: Player)
	if not ready[p] or p.Parent ~= Players then return end
	local parts = {
		Friends = Cfg.friendsMult(friendCount(p)),
		Rebirth = Cfg.rebirthMult(p:GetAttribute("Rebirths") or 0),
		Donate = Cfg.donateMult(p:GetAttribute("DonateTier") or 0),
		VIP = (p:GetAttribute("Pass_VIP") == true) and Cfg.VIP_MULT or 1,
		Stage = Cfg.stageMult(p:GetAttribute("Stage") or 1),
	}
	local total = 1
	for _, s in Cfg.SOURCES do
		local v = parts[s.key] or 1
		p:SetAttribute("Multi_" .. s.key, v)
		total *= v
	end
	p:SetAttribute("TotalMulti", total)
end

function MultiService.Get(p: Player): number
	return (p:GetAttribute("TotalMulti") :: number?) or 1
end

-- сума за продаж з урахуванням глобального множника (округлюємо до цілого)
function MultiService.Apply(p: Player, amount: number): number
	return math.floor(amount * MultiService.Get(p) + 0.5)
end

-- перевірка пари друзів (з yield): якщо a і b друзі, обидва отримують бонус
local function checkPair(a: Player, b: Player)
	local ok, res = pcall(function() return a:IsFriendsWith(b.UserId) end)
	if ok and res and a.Parent == Players and b.Parent == Players then
		friendsOf[a] = friendsOf[a] or {}; friendsOf[b] = friendsOf[b] or {}
		friendsOf[a][b.UserId] = true; friendsOf[b][a.UserId] = true
		compute(a); compute(b)
	end
end

local function setup(p: Player)
	if not DataService.WaitLoaded(p) then return end
	friendsOf[p] = friendsOf[p] or {}
	ready[p] = true
	for _, a in { "Stage", "Rebirths", "DonateTier", "Pass_VIP" } do
		p:GetAttributeChangedSignal(a):Connect(function() compute(p) end)
	end
	compute(p)
	for _, other in Players:GetPlayers() do
		if other ~= p then task.spawn(checkPair, p, other) end
	end
end

function MultiService.Start()
	Players.PlayerAdded:Connect(function(p) task.spawn(setup, p) end)
	for _, p in Players:GetPlayers() do task.spawn(setup, p) end
	Players.PlayerRemoving:Connect(function(p)
		ready[p] = nil
		friendsOf[p] = nil
		for _, other in Players:GetPlayers() do
			if other ~= p and friendsOf[other] and friendsOf[other][p.UserId] then
				friendsOf[other][p.UserId] = nil
				compute(other)
			end
		end
	end)
end

return MultiService
