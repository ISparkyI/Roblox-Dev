--!strict
-- OfflineService — офлайн-дохід (04.11.2026). Де: ServerScriptService/OfflineService (ModuleScript). Запуск: NicheBoot.
-- Перший вхід у гру — нічого (атрибута LastSeen ще немає). Далі при вході: відсутність = зараз − LastSeen (не більше MAX_SEC = 24 год,
--   менше MIN_SEC — нічого), дохід = збережений IncomeRate ($/хв, IncomeService; уже з постійними множниками) × хвилини відсутності.
--   Сума кладеться в OfflinePending (+ OfflineSec — скільки був відсутній), гравець бачить вікно OfflineWindow і тисне CLAIM:
--   Remotes/OfflineAction ("Claim") → Money += OfflinePending, OfflinePending = 0. Не забрав і вийшов — сума лишається до наступного входу.
-- LastSeen оновлюється кожні TICK с, поки гравець у грі (DataService зберігає атрибут) — похибка часу виходу ≤ TICK с.
-- Плейс Marketplace (grant = false): лише оновлює LastSeen — час на маркеті не рахується як офлайн.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))

local OfflineService = {}
OfflineService.MAX_SEC = 24 * 60 * 60
OfflineService.MIN_SEC = 60
local TICK = 15

local ready: { [Player]: boolean } = {}
local busy: { [Player]: boolean } = {}

local function onPlayer(p: Player, grant: boolean)
	if not DataService.WaitLoaded(p) or p.Parent ~= Players then return end
	local now = os.time()
	local last = tonumber(p:GetAttribute("LastSeen"))
	if grant and last and last > 0 then
		local sec = math.min(math.max(0, now - last), OfflineService.MAX_SEC)
		local rate = tonumber(p:GetAttribute("IncomeRate")) or 0
		if sec >= OfflineService.MIN_SEC and rate > 0 then
			local gain = math.floor(rate * sec / 60)
			if gain > 0 then
				p:SetAttribute("OfflinePending", (tonumber(p:GetAttribute("OfflinePending")) or 0) + gain)
				p:SetAttribute("OfflineSec", sec)
			end
		end
	end
	p:SetAttribute("LastSeen", now)
	ready[p] = true
end

local function onAction(p: Player, action: any): any
	if action ~= "Claim" then return { ok = false } end
	if busy[p] or not ready[p] then return { ok = false } end
	local n = tonumber(p:GetAttribute("OfflinePending")) or 0
	if n <= 0 then return { ok = false, err = "none" } end
	busy[p] = true
	p:SetAttribute("OfflinePending", 0)
	p:SetAttribute("OfflineSec", 0)
	p:SetAttribute("Money", (tonumber(p:GetAttribute("Money")) or 0) + n)
	task.spawn(function() pcall(DataService.SaveNow, p) end)
	busy[p] = nil
	return { ok = true, gain = n }
end

function OfflineService.Start(opts: any?)
	local grant = not (opts and opts.grant == false)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("OfflineAction") or Instance.new("RemoteFunction")
	rf.Name = "OfflineAction"; rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onAction
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p, grant) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p, grant) end
	Players.PlayerRemoving:Connect(function(p) ready[p] = nil; busy[p] = nil end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			local now = os.time()
			for p in ready do
				if p.Parent == Players then p:SetAttribute("LastSeen", now) end
			end
		end
	end)
end

return OfflineService
