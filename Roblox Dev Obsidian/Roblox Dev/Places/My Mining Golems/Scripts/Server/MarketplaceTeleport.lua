-- MarketplaceTeleport — телепорт між печерою й Marketplace (окремий плейс HubConfig.MARKETPLACE_PLACE_ID, той самий файл). 03.11.2026.
-- Де: ServerScriptService/MarketplaceTeleport (Script). Клієнт — StarterPlayerScripts/MarketplaceClient (відлік 3 с, банер).
-- Remotes/MarketplaceTP (RemoteFunction): сервер перевіряє, що гравець стоїть у колі, і робить TeleportAsync.
--   Відповідь: { ok = true } | { ok = false, reason = "soon" | "far" | "busy" | "fail" }.
-- Головний плейс: коло Cave/Hub/Marketplace/RingCenter → сервер маркету. Сервери маркету — резервовані (ReserveServer), облік у
--   MemoryStore SortedMap HubConfig.MARKET_MAP ({ code, n } за PrivateServerId; n оновлює MarketServerService): беремо найповніший
--   з n < 45 (60 × 0,75), інакше резервуємо новий. MemoryStore впав — звичайний TeleportAsync (публічний сервер маркету).
-- Режим маркету (HubConfig.isMarket): коло Marketplace/Floor/«Back To Cave» (MARKET_BACK_R) → TeleportAsync у головний плейс.
--   Туди ж веде кнопка HOME (TeleportHUD, без перевірки кола: аргумент "home").
-- Поки MARKETPLACE_PLACE_ID = 0 (місця немає) — "soon", клієнт показує тост.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("HubConfig"))
local MARKET = Cfg.isMarket()

local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"; remotes.Parent = RS
local rf = remotes:FindFirstChild("MarketplaceTP") or Instance.new("RemoteFunction")
rf.Name = "MarketplaceTP"; rf.Parent = remotes

local busy: { [Player]: number } = {}
local function ringCenter(): BasePart?
	if MARKET then
		local m = workspace:FindFirstChild("Marketplace")
		local c = m and m:FindFirstChild("Back To Cave", true)
		return (c and c:IsA("BasePart")) and c or nil
	end
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local c = hub and hub:FindFirstChild("Marketplace") and hub.Marketplace:FindFirstChild("RingCenter", true)
	return (c and c:IsA("BasePart")) and c or nil
end
local function inRing(p: Player): boolean
	local center = ringCenter()
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not (center and hrp) then return false end
	local d = hrp.Position - center.Position
	return Vector2.new(d.X, d.Z).Magnitude <= (MARKET and Cfg.MARKET_BACK_R or Cfg.MARKET_RING_R) + 2.5 and math.abs(d.Y) < 10
end

-- ===== вибір сервера маркету (головний плейс) =====
-- код доступу резервованого сервера або nil (тоді — звичайний телепорт)
local function pickServer(): string?
	local okM, map = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, Cfg.MARKET_MAP)
	if not okM then return nil end
	local okR, items = pcall(function() return map:GetRangeAsync(Enum.SortDirection.Ascending, 100) end)
	if not okR then warn("MarketplaceTeleport: MemoryStore ", items); return nil end
	local limit = math.floor(Cfg.MARKET_MAX * Cfg.MARKET_FILL)
	local best, bestN = nil, -1
	for _, it in items do
		local v = it.value
		local n = type(v) == "table" and tonumber(v.n) or nil
		if n and type(v.code) == "string" and n < limit and n > bestN then best, bestN = it, n end
	end
	if best then
		-- одразу +1, щоб кілька головних серверів не переповнили один сервер маркету до його наступного серцебиття
		pcall(function()
			map:UpdateAsync(best.key, function(old)
				if type(old) ~= "table" then return nil end
				old.n = (tonumber(old.n) or 0) + 1
				return old
			end, Cfg.MARKET_TTL)
		end)
		return best.value.code
	end
	local okS, code, id = pcall(TeleportService.ReserveServer, TeleportService, Cfg.MARKETPLACE_PLACE_ID)
	if not okS then warn("MarketplaceTeleport: ReserveServer ", code); return nil end
	-- запис нового сервера; сам сервер підхопить його за PrivateServerId й далі оновлює n сам
	pcall(map.SetAsync, map, id, { code = code, n = 1 }, Cfg.MARKET_TTL * 2)
	return code
end

local function teleport(p: Player): boolean
	if MARKET then
		local ok, err = pcall(function() TeleportService:TeleportAsync(Cfg.MAIN_PLACE_ID, { p }) end)
		if not ok then warn("MarketplaceTeleport: home ", err) end
		return ok
	end
	local code = pickServer()
	local ok, err = pcall(function()
		local opts = Instance.new("TeleportOptions")
		if code then opts.ReservedServerAccessCode = code end
		TeleportService:TeleportAsync(Cfg.MARKETPLACE_PLACE_ID, { p }, opts)
	end)
	if not ok then warn("MarketplaceTeleport: ", err) end
	return ok
end

rf.OnServerInvoke = function(p: Player, arg: any)
	if busy[p] and os.clock() - busy[p] < 5 then return { ok = false, reason = "busy" } end
	if not (MARKET and arg == "home") and not inRing(p) then return { ok = false, reason = "far" } end
	if not MARKET and (Cfg.MARKETPLACE_PLACE_ID or 0) == 0 then return { ok = false, reason = "soon" } end
	busy[p] = os.clock()
	if not teleport(p) then busy[p] = nil; return { ok = false, reason = "fail" } end
	return { ok = true }
end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)

-- ===== список серверів маркету (кнопка з монітором, MarketUI; 03.11.2026) =====
-- Remotes/MarketServers (RemoteFunction, лише режим маркету):
--   ("List") → { servers = [{ key, n, max, current }] } — з MemoryStore MARKET_MAP (коди доступу клієнту НЕ віддаються);
--   ("Join", key) → { ok, err } — TeleportAsync на цей резервований сервер (повний — "full", зник — "gone").
--   У Studio MemoryStore немає — список з одного поточного сервера.
if MARKET then
	local RunService = game:GetService("RunService")
	local sf = remotes:FindFirstChild("MarketServers") or Instance.new("RemoteFunction")
	sf.Name = "MarketServers"; sf.Parent = remotes
	local lastAsk: { [Player]: number } = {}
	local function readAll(): { any }
		if RunService:IsStudio() then return {} end
		local okM, map = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, Cfg.MARKET_MAP)
		if not okM then return {} end
		local okR, items = pcall(function() return map:GetRangeAsync(Enum.SortDirection.Ascending, 100) end)
		return okR and items or {}
	end
	sf.OnServerInvoke = function(p: Player, action: any, key: any)
		local t = os.clock()
		if lastAsk[p] and t - lastAsk[p] < 1 then return { ok = false, err = "busy" } end
		lastAsk[p] = t
		local me = game.PrivateServerId
		if action == "List" then
			local list, haveMe = {}, false
			for _, it in readAll() do
				local v = it.value
				if type(v) == "table" and type(v.code) == "string" then
					local cur = it.key == me
					haveMe = haveMe or cur
					table.insert(list, { key = it.key, n = cur and #Players:GetPlayers() or (tonumber(v.n) or 0), max = Cfg.MARKET_MAX, current = cur })
				end
			end
			if not haveMe then table.insert(list, 1, { key = me ~= "" and me or "this", n = #Players:GetPlayers(), max = Cfg.MARKET_MAX, current = true }) end
			return { ok = true, servers = list }
		elseif action == "Join" and type(key) == "string" then
			if key == me or key == "this" then return { ok = false, err = "here" } end
			local code
			for _, it in readAll() do
				if it.key == key and type(it.value) == "table" then
					if (tonumber(it.value.n) or 0) >= Cfg.MARKET_MAX then return { ok = false, err = "full" } end
					code = it.value.code
				end
			end
			if type(code) ~= "string" then return { ok = false, err = "gone" } end
			local ok, err = pcall(function()
				local opts = Instance.new("TeleportOptions")
				opts.ReservedServerAccessCode = code
				TeleportService:TeleportAsync(Cfg.MARKETPLACE_PLACE_ID, { p }, opts)
			end)
			if not ok then warn("MarketplaceTeleport Join: ", err); return { ok = false, err = "fail" } end
			return { ok = true }
		end
		return { ok = false }
	end
	Players.PlayerRemoving:Connect(function(p) lastAsk[p] = nil end)
end

-- ===== 08.11.2026: скільки гравців зараз на всіх серверах маркету — для напису під табличкою MARKETPLACE (MarketplaceClient) =====
-- Головний плейс: раз на 30 с сума n з MemoryStore MARKET_MAP → атрибут Workspace.MarketPlayers. У Studio MemoryStore не читаємо — 0.
if not MARKET then
	task.spawn(function()
		local RunService = game:GetService("RunService")
		while true do
			local total = nil
			if RunService:IsStudio() then
				total = 0
			else
				local okM, map = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, Cfg.MARKET_MAP)
				if okM then
					local okR, items = pcall(function() return map:GetRangeAsync(Enum.SortDirection.Ascending, 100) end)
					if okR and type(items) == "table" then
						total = 0
						for _, it in items do
							local v = it.value
							if type(v) == "table" then total += math.max(0, math.floor(tonumber(v.n) or 0)) end
						end
					end
				end
			end
			if total then workspace:SetAttribute("MarketPlayers", total) end -- не вдалося прочитати — лишається попереднє число
			task.wait(30)
		end
	end)
end
