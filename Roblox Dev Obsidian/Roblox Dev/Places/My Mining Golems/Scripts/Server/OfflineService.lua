--!strict
-- OfflineService — офлайн-дохід (04.11.2026). Де: ServerScriptService/OfflineService (ModuleScript). Запуск: NicheBoot.
-- Перший вхід у гру — нічого (атрибута LastSeen ще немає). Далі при вході: відсутність = зараз − LastSeen (не більше MAX_SEC = 24 год,
--   менше MIN_SEC — нічого), дохід = збережений IncomeRate ($/хв, IncomeService; уже з постійними множниками) × хвилини відсутності.
--   Сума кладеться в OfflinePending (+ OfflineSec — скільки був відсутній), гравець бачить вікно OfflineWindow і тисне CLAIM:
--   Remotes/OfflineAction ("Claim") → Money += OfflinePending, OfflinePending = 0. Не забрав і вийшов — сума лишається до наступного входу.
-- LastSeen оновлюється кожні TICK с, поки гравець у грі (DataService зберігає атрибут) — похибка часу виходу ≤ TICK с.
-- Плейс Marketplace (grant = false): лише оновлює LastSeen — час на маркеті не рахується як офлайн.
-- 11.11.2026: аналітика — Funnels → "OfflineEarnings": 1 Window shown (клієнт OfflineWindow → OfflineAction("Shown")) →
--   2 Claimed (CustomField01 = "Free" або "x2"). Окремо Custom events "OfflineClaimFree" / "OfflineClaimX2" (значення — сума $).
--   funnelSessionId — свій на кожне вікно (UserId-час), тож фанел рахує кожен показ.
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local RS = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))

local OfflineService = {}
OfflineService.MAX_SEC = 24 * 60 * 60
OfflineService.MIN_SEC = 60
local TICK = 15

local ready: { [Player]: boolean } = {}
local busy: { [Player]: boolean } = {}
local sess: { [Player]: string } = {} -- фанел OfflineEarnings: сесія поточного вікна
local shown: { [Player]: boolean } = {}

local function funnelStep(p: Player, step: number, name: string, kind: string?)
	if not sess[p] then sess[p] = tostring(p.UserId) .. "-" .. os.time() end
	local id = sess[p]
	pcall(function()
		if kind then
			AnalyticsService:LogFunnelStepEvent(p, "OfflineEarnings", id, step, name, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = kind })
		else
			AnalyticsService:LogFunnelStepEvent(p, "OfflineEarnings", id, step, name)
		end
	end)
end
local function claimed(p: Player, kind: string, gain: number)
	funnelStep(p, 2, "Claimed", kind)
	pcall(function() AnalyticsService:LogCustomEvent(p, kind == "x2" and "OfflineClaimX2" or "OfflineClaimFree", gain) end)
	sess[p] = nil
	shown[p] = nil
end

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
	if action == "Shown" then -- вікно WELCOME BACK показали (раз на суму до видачі)
		if ready[p] and not shown[p] and (tonumber(p:GetAttribute("OfflinePending")) or 0) > 0 then
			shown[p] = true
			funnelStep(p, 1, "Window shown")
		end
		return { ok = true }
	end
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
	claimed(p, "Free", n)
	return { ok = true, gain = n }
end

-- 10.11.2026: x2 CLAIM (Developer Product OfflineX2, MonetizationService.GrantProduct): Money += 2 × OfflinePending.
--   Атрибут OfflineX2Gain — клієнт показує тост і закриває вікно. Нічого забирати (вже забрав) — покупку все одно зараховуємо.
function OfflineService.ClaimX2(p: Player): boolean
	local n = tonumber(p:GetAttribute("OfflinePending")) or 0
	if n <= 0 then return true end
	p:SetAttribute("OfflinePending", 0)
	p:SetAttribute("OfflineSec", 0)
	p:SetAttribute("Money", (tonumber(p:GetAttribute("Money")) or 0) + n * 2)
	p:SetAttribute("OfflineX2Gain", n * 2)
	claimed(p, "x2", n * 2)
	return true
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
	Players.PlayerRemoving:Connect(function(p) ready[p] = nil; busy[p] = nil; sess[p] = nil; shown[p] = nil end)
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
