--!strict
-- IndexService — колекція Index (сервер): які записи гравець уже відкрив і за які вже забрав нагороду (діаманти).
-- Де: ServerScriptService/IndexService (ModuleScript). Запуск: NicheBoot (після DataService та InventoryService).
-- Клієнт — StarterPlayerScripts/IndexUI. Големи, рідкості, мутації — Shared/GolemCatalog; руда — Shared/PlotConfig.ORES.
--
-- Ключі записів:
--   голем — "<id>:<клас>:<мутація>" (id з GolemCatalog.ORDER, клас miner | carrier | warrior, мутація 0..7), напр. "flint:miner:0";
--     сторінка Index = клас × мутація (24 големи), усього 24 × 3 × 8 = 576 записів. Exclusive-големи в Index не потрапляють.
--   руда — "ore:<Key>" (Key з PlotConfig.ORES — Coal, Copper, Iron).
-- Відкриття: голем — коли атрибут гравця InvGolems (JSON { { id, kind, cls, mut } }, ставить InventoryService) отримує голема з новим
--   ключем; руда — коли атрибут Ore_<Key> уперше > 0. Відкриття НЕ дає діамантів саме по собі (v4).
-- Нагорода — лише кнопкою Claim (одного запису) або Claim All (усі незабрані):
--   голем — за мутацією (GDD - Quests and Index): Normal +1, Bronze +2, Silver +3, Gold +5, Diamond +10, Void +25, Rainbow +100, Secret +200;
--   руда — n ≤ 5 → 5·n, далі 25·(n−4): 5, 10, 15, 20, 25, 50, 75, 100… (n — номер руди в PlotConfig.ORES; Coal 5, Copper 10, Iron 15) — oreReward.
--   Діаманти додаються в атрибут Diamonds (той самий лічильник, що в HUD). Сервер перевіряє: запис відкритий і ще не забраний.
-- Для клієнта (атрибути гравця): IndexFound — JSON-список відкритих ключів; IndexClaimed — JSON-список забраних ключів.
-- Дії (RemoteEvent ReplicatedStorage/Remotes/IndexAction): "Claim", ключ — забрати один запис; "ClaimAll" — забрати все.
-- Збереження: секція "Index" у DataService: { found = { ключі }, claimed = { ключі } }. Не скидається при переході на мапу (GDD).
--   Стара секція (v1–v3, нагорода нараховувалась сама): відкриті големи й руди з orePaid вважаються забраними.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local PlotCfg = require(RS.Shared:WaitForChild("PlotConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local IndexService = {}
IndexService.REWARD = { 1, 2, 3, 5, 10, 25, 100, 200 } -- діаманти за голема, за мутацією 0..7
IndexService.ORE_REWARD_STEP = 5 -- руда: n ≤ 5 → 5·n
IndexService.ORE_REWARD_BIG = 25 -- далі 25·(n−4)
function IndexService.oreReward(n: number): number
	return n <= 5 and IndexService.ORE_REWARD_STEP * n or IndexService.ORE_REWARD_BIG * (n - 4)
end
local REWARD = IndexService.REWARD

type State = { found: { [string]: boolean }, claimed: { [string]: boolean }, lastAll: number }
local states: { [Player]: State } = {}

-- руда, яку знає Index (PlotConfig.ORES, по порядку): Key → діаманти
local ORE_KEYS: { [string]: number } = {}
for n, o in PlotCfg.ORES do ORE_KEYS[o.key] = IndexService.oreReward(n) end

-- ключ запису голема або nil (невідомий голем / Exclusive)
local function keyOf(kind: any, cls: any, mut: any): string?
	local g = Catalog.get(kind)
	if not g or g.rarity == "Exclusive" then return nil end
	return g.id .. ":" .. Catalog.cls(cls) .. ":" .. tostring(Catalog.mut(mut))
end
IndexService.keyOf = keyOf

-- нагорода за запис (діаманти) або nil, якщо ключ неправильний
local function rewardOf(k: any): number?
	if type(k) ~= "string" or #k > 40 then return nil end
	if string.sub(k, 1, 4) == "ore:" then return ORE_KEYS[string.sub(k, 5)] end
	local id, cls, mut = string.match(k, "^(%w+):(%a+):(%d+)$")
	if not id or keyOf(id, cls, mut) ~= k then return nil end
	return REWARD[(tonumber(mut) or 0) + 1]
end
IndexService.rewardOf = rewardOf

local function list(set: { [string]: boolean }): { string }
	local t = {}
	for k in set do table.insert(t, k) end
	table.sort(t)
	return t
end

local function publish(p: Player, st: State)
	p:SetAttribute("IndexFound", HttpService:JSONEncode(list(st.found)))
	p:SetAttribute("IndexClaimed", HttpService:JSONEncode(list(st.claimed)))
end

-- нові записи големів з поточного InvGolems (без нагороди — її забирають кнопкою Claim)
local function scan(p: Player)
	local st = states[p]
	if not st then return end
	local s = p:GetAttribute("InvGolems")
	if type(s) ~= "string" or s == "" then return end
	local ok, gl = pcall(HttpService.JSONDecode, HttpService, s)
	if not ok or type(gl) ~= "table" then return end
	local changed = false
	for _, g in gl do
		if type(g) == "table" then
			local k = keyOf(g.kind, g.cls, g.mut)
			if k and not st.found[k] then st.found[k] = true; changed = true end
		end
	end
	if changed then publish(p, st) end
end

-- руда: відкрита, коли Ore_<Key> уперше > 0
local function scanOres(p: Player)
	local st = states[p]
	if not st then return end
	local changed = false
	for key in ORE_KEYS do
		local k = "ore:" .. key
		if (tonumber(p:GetAttribute("Ore_" .. key)) or 0) > 0 and not st.found[k] then st.found[k] = true; changed = true end
	end
	if changed then publish(p, st) end
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local st: State = { found = {}, claimed = {}, lastAll = 0 }
	local sec = DataService.GetSection(p, "Index")
	if type(sec) == "table" then
		if type(sec.found) == "table" then
			for _, k in sec.found do if rewardOf(k) then st.found[k] = true end end
		end
		if type(sec.claimed) == "table" then
			for _, k in sec.claimed do if rewardOf(k) and st.found[k] then st.claimed[k] = true end end
		else
			-- стара секція (v1–v3): големи вже були оплачені автоматично, руда — якщо є в orePaid
			for k in st.found do if string.sub(k, 1, 4) ~= "ore:" then st.claimed[k] = true end end
			if type(sec.orePaid) == "table" then
				for _, k in sec.orePaid do if st.found[k] then st.claimed[k] = true end end
			end
		end
	end
	states[p] = st
	publish(p, st)
	p:GetAttributeChangedSignal("InvGolems"):Connect(function() scan(p) end)
	scan(p) -- InvGolems могли виставити ще до цього моменту (InventoryService після завантаження даних)
	p.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, 4) == "Ore_" then scanOres(p) end
	end)
	scanOres(p)
end

local function addDiamonds(p: Player, n: number)
	if n > 0 then p:SetAttribute("Diamonds", (tonumber(p:GetAttribute("Diamonds")) or 0) + n) end
end

local function onAction(p: Player, action: any, arg: any)
	local st = states[p]
	if not st then return end
	if action == "Claim" then
		local r = rewardOf(arg)
		if not r or not st.found[arg] or st.claimed[arg] then return end -- лише відкритий і ще не забраний
		st.claimed[arg] = true
		addDiamonds(p, r)
		publish(p, st)
	elseif action == "ClaimAll" then
		if os.clock() - st.lastAll < 0.5 then return end
		st.lastAll = os.clock()
		local gain = 0
		for k in st.found do
			if not st.claimed[k] then
				local r = rewardOf(k)
				if r then st.claimed[k] = true; gain += r end
			end
		end
		if gain > 0 then addDiamonds(p, gain); publish(p, st) end
	end
end

local started = false
function IndexService.Start()
	if started then return end
	started = true
	DataService.RegisterSection("Index", function(p: Player, old: any): any
		local st = states[p]
		if not st then return old end
		return { found = list(st.found), claimed = list(st.claimed) }
	end)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("IndexAction") or Instance.new("RemoteEvent")
	ev.Name = "IndexAction"; ev.Parent = remotes;
	(ev :: RemoteEvent).OnServerEvent:Connect(onAction)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	-- знімок секції DataService робить синхронно при виході — стан прибираємо пізніше
	Players.PlayerRemoving:Connect(function(p) task.delay(60, function() states[p] = nil end) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return IndexService
