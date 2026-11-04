--!nonstrict
-- MarketServerService — сервер Marketplace (режим маркету, HubConfig.isMarket). 03.11.2026.
-- Де: ServerScriptService/MarketServerService (ModuleScript). Запуск: NicheBoot (лише в режимі маркету, після DataService).
-- Що робить:
--   * прибирає з Workspace печеру й усе головного плейсу (STRIP) — гравцям на маркеті воно не потрібне й не вантажиться;
--   * спавн: кожен персонаж — на випадкову точку Workspace/Marketplace/SpawnPoints (обличчям до центру);
--   * облік сервера в MemoryStore SortedMap HubConfig.MARKET_MAP: ключ game.PrivateServerId, значення { code, n } — код записав
--     головний сервер при ReserveServer (MarketplaceTeleport), тут кожні MARKET_BEAT с оновлюється n = гравців (TTL MARKET_TTL).
--     Порожній сервер (останній вийшов / BindToClose) — запис прибирається; сам сервер Roblox закриває.
--     Публічний (не резервований) сервер маркету обліку не веде.
-- Атрибут ReplicatedStorage.MarketMode = true — для клієнтів (HubConfig.isMarket теж його читає).
--   * PlotPlaced (03.11.2026): PlotService тут не працює, тому список големів на плотах беремо зі збереженої секції Plots
--     (assign: m — майнери, c — носій) — інакше в інвентарі й хотбарі з'являлись големи з плотів.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("HubConfig"))

local MarketServerService = {}

-- ===== табло останніх угод (HubConfig.TRADES_BOARD, 03.11.2026) =====
-- MarketServerService.LogTrade(seller, buyer, golem, price, currency) — викликати після УСПІШНОЇ угоди на цьому сервері:
--   seller / buyer — Player (або { UserId, Name }), golem — { kind, cls, mut }, price — число, currency — "money" | "diamonds" | "tickets".
--   Запис { s, sn, b, bn, k, c, m, p, cur, t } — на початок списку, не більше HubConfig.TRADES_MAX; атрибут Trades моделі табла (JSON).
--   Також +1 до Stat_MarketSold продавцю й Stat_MarketBought покупцю (табла TOP SELLERS / TOP BUYERS).
local trades = {}
function MarketServerService.LogTrade(seller: any, buyer: any, golem: any, price: number, currency: string)
	local g = type(golem) == "table" and golem or {}
	table.insert(trades, 1, {
		s = seller and seller.UserId or 0, sn = seller and seller.Name or "?",
		b = buyer and buyer.UserId or 0, bn = buyer and buyer.Name or "?",
		k = g.kind, c = g.cls, m = tonumber(g.mut) or 0,
		p = math.floor(tonumber(price) or 0), cur = currency or "money", t = os.time(),
	})
	while #trades > (Cfg.TRADES_MAX or 100) do table.remove(trades) end
	local board = Cfg.tradesBoard and Cfg.tradesBoard()
	if board then board:SetAttribute("Trades", game:GetService("HttpService"):JSONEncode(trades)) end
	-- історія гравців (вікно History, MarketLotService)
	local okL, Lots = pcall(require, script.Parent:FindFirstChild("MarketLotService"))
	if okL and Lots then
		local e = trades[1]
		local base = { k = e.k, c = e.c, m = e.m, p = e.p, cur = e.cur, t = e.t }
		if typeof(buyer) == "Instance" then local b = table.clone(base); b.u = e.s; b.n = e.sn; Lots.AddHistory(buyer, "b", b) end
		if typeof(seller) == "Instance" then local s = table.clone(base); s.u = e.b; s.n = e.bn; Lots.AddHistory(seller, "s", s) end
	end
	local okS, Stats = pcall(require, script.Parent:FindFirstChild("StatsService"))
	if okS and Stats and Stats.Add then
		if typeof(seller) == "Instance" then pcall(Stats.Add, seller, "MarketSold", 1) end
		if typeof(buyer) == "Instance" then pcall(Stats.Add, buyer, "MarketBought", 1) end
	end
end
local HttpService = game:GetService("HttpService")

-- големи на плотах (зі збереження) → атрибут PlotPlaced, як у печері
local function markPlaced(p: Player)
	local okD, DataService = pcall(require, script.Parent:FindFirstChild("DataService"))
	if not (okD and DataService and DataService.WaitLoaded) or not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "Plots")
	local placed = {}
	if type(sec) == "table" and type(sec.assign) == "table" then
		for _, s in sec.assign do
			if type(s) == "table" then
				if type(s.m) == "table" then for _, id in s.m do if type(id) == "number" then table.insert(placed, id) end end end
				if type(s.c) == "number" then table.insert(placed, s.c) end
			end
		end
	end
	if p.Parent then p:SetAttribute("PlotPlaced", HttpService:JSONEncode(placed)) end
end
local STRIP = { "Cave", "Cave_Inside", "NichePrefabs", "NicheSockets", "Boss Map", "Niches" }
local rng = Random.new()

local function spawnPoints(): { BasePart }
	local m = workspace:FindFirstChild("Marketplace")
	local f = m and m:FindFirstChild("SpawnPoints")
	local list = {}
	if f then for _, p in f:GetChildren() do if p:IsA("BasePart") then table.insert(list, p) end end end
	return list
end

local function place(player: Player, char: Model)
	local pts = spawnPoints()
	if #pts == 0 then return end
	local sp = pts[rng:NextInteger(1, #pts)]
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	local up = (hum and hum.HipHeight or 2) + hrp.Size.Y / 2 + 0.3
	local cf = sp.CFrame + sp.CFrame.UpVector * up
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end)
	if player.Character ~= char then return end
	char:PivotTo(cf)
	hrp.AssemblyLinearVelocity = Vector3.zero
end

-- ===== облік у MemoryStore =====
local map = nil
local function beat(remove: boolean?)
	if not map or game.PrivateServerId == "" then return end
	local id = game.PrivateServerId
	if remove then pcall(map.RemoveAsync, map, id); return end
	local n = #Players:GetPlayers()
	pcall(function()
		map:UpdateAsync(id, function(old)
			if type(old) ~= "table" or type(old.code) ~= "string" then return nil end -- запис зник — без коду відновити не можемо
			old.n = n
			return old
		end, Cfg.MARKET_TTL)
	end)
end

-- префаби големів (Workspace/PlotPrefabs → ReplicatedStorage/PlotAssets) — як PlotService.syncPrefabs у печері (03.11.2026):
-- PlotService на маркеті не працює, і без цього 3D-іконки й моделі більшості големів були порожні (інвентар, рука, RECENT TRADES)
local function syncPrefabs()
	local stage = workspace:FindFirstChild("PlotPrefabs")
	local assets = RS:FindFirstChild("PlotAssets")
	if not (stage and assets) then return end
	for _, m in stage:GetDescendants() do
		local key = m:IsA("Model") and m:GetAttribute("PrefabOf")
		if type(key) == "string" and key ~= "" then
			local c = m:Clone()
			c.Name = key
			c:SetAttribute("PrefabOf", nil)
			local old = assets:FindFirstChild(key)
			if old then old:Destroy() end
			c.Parent = assets
		end
	end
	stage:Destroy()
end

function MarketServerService.Start()
	RS:SetAttribute("MarketMode", true)
	syncPrefabs()
	require(script.Parent:WaitForChild("MarketLotService")).Start() -- лоти продажу големів і історія угод (Remotes/MarketAction)
	for _, name in STRIP do
		local o = workspace:FindFirstChild(name)
		if o then o:Destroy() end
	end
	local function onPlayer(p: Player)
		p.CharacterAdded:Connect(function(ch) task.defer(place, p, ch) end)
		if p.Character then task.defer(place, p, p.Character) end
		task.spawn(beat)
		task.spawn(markPlaced, p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do onPlayer(p) end
	Players.PlayerRemoving:Connect(function()
		task.delay(0.5, function() beat(#Players:GetPlayers() == 0) end)
	end)
	if not RunService:IsStudio() then
		local ok, m = pcall(MemoryStoreService.GetSortedMap, MemoryStoreService, Cfg.MARKET_MAP)
		if ok then map = m else warn("MarketServerService: MemoryStore ", m) end
		game:BindToClose(function() beat(true) end)
		task.spawn(function()
			while true do
				beat()
				task.wait(Cfg.MARKET_BEAT)
			end
		end)
	end
end

return MarketServerService
