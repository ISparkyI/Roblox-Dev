--!strict
-- GroupGolemService — ексклюзивний Mushroom Golem за вступ у групу (стенд для новачків, GDD). 29.10.2026.
-- Де: ServerScriptService/GroupGolemService (ModuleScript). Запуск: NicheBoot (після MutationService).
-- Стенди — Workspace/Cave/Hub/GroupStands/GroupStand1..2 (між Mutation Machines і Marketplace, дзеркально): підставка з мохом і
--   мухоморами, на ній живий Mushroom Golem (сервер ставить модель у GolemSpot), табличка (малює GroupStandClient), кнопка E (GroupPrompt).
-- E: не в групі — клієнт відкриває вікно вступу (GroupService:PromptJoinAsync), потім просить сервер перевірити ("Check");
--   у групі і голема немає — Mushroom Golem (майнер, Normal) у інвентар, хотбар і руку; другий раз — лише якщо голема більше немає
--   ніде (інвентар, печера, мутаційні машини). Атрибут GroupGolem = true (DataService) — вже забирав.
-- Сила: GolemCatalog (dynamic = "bestMiner") — 50 % шкоди найкращого звичайного майнера гравця. Тут рахується атрибут
--   гравця BestMinerDmg (інвентар + стенди печери + мутаційні машини) — оновлюється саме.
-- Remotes/GroupGolemAction (RemoteEvent): сервер → клієнт ("Join") | ("Toast", текст, колір); клієнт → сервер ("Check").

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local CaveStandService = require(script.Parent:WaitForChild("CaveStandService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local GolemModel = require(RS.Shared:WaitForChild("GolemModel"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))

local GroupGolemService = {}
GroupGolemService.GROUP_ID = 996441586
GroupGolemService.KIND = "mushroom"
local REACH = 16

local remote: RemoteEvent
local last: { [Player]: number } = {}

local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end

-- усі големи гравця (інвентар разом із плотами, стенди печери, мутаційні машини)
local function allGolems(p: Player): { any }
	local out = {}
	for _, g in decode(p, "InvGolems", {}) do table.insert(out, g) end
	for _, g in decode(p, "CaveStandGolems", {}) do table.insert(out, g) end
	for _, mm in decode(p, "MutMachines", {}) do
		if type(mm) == "table" and type(mm.slots) == "table" then
			for _, g in mm.slots do table.insert(out, g) end
		end
	end
	return out
end
local function ownsMushroom(p: Player): boolean
	for _, g in allGolems(p) do
		if type(g) == "table" and Catalog.id(g.kind) == GroupGolemService.KIND then return true end
	end
	return false
end

local function updateBest(p: Player)
	local all = allGolems(p)
	local b = Catalog.bestMinerDmg(all)
	if p:GetAttribute("BestMinerDmg") ~= b then p:SetAttribute("BestMinerDmg", b) end
	-- найкраща місткість носія — Mushroom Golem-носій (нагорода Daily) має 75 % від неї (GolemCatalog.carrierShare)
	local c = Catalog.bestCarrierCap(all)
	if p:GetAttribute("BestCarrierCap") ~= c then p:SetAttribute("BestCarrierCap", c) end
	-- воїн (warriorShare, големи Exclusive Case, 02.11.2026)
	local wd, wh = Catalog.bestWarrior(all)
	if p:GetAttribute("BestWarriorDmg") ~= wd then p:SetAttribute("BestWarriorDmg", wd) end
	if p:GetAttribute("BestWarriorHp") ~= wh then p:SetAttribute("BestWarriorHp", wh) end
end

local function inGroup(p: Player): boolean
	local ok, r = pcall(function() return p:IsInGroupAsync(GroupGolemService.GROUP_ID) end)
	if not ok then ok, r = pcall(function() return p:IsInGroup(GroupGolemService.GROUP_ID) end) end
	return ok and r == true
end

local function toast(p: Player, text: string, color: string)
	remote:FireClient(p, "Toast", text, color)
end

local function tryClaim(p: Player)
	if p:GetAttribute("InvReady") ~= true or p:GetAttribute("CaveReady") ~= true then return end
	if not inGroup(p) then remote:FireClient(p, "Join"); return end
	p:SetAttribute("InGroup", true)
	if ownsMushroom(p) then toast(p, "You already have the Mushroom Golem!", "gray"); return end
	if Items.invGolemCount(decode(p, "InvGolems", {}), decode(p, "PlotPlaced", {})) >= Items.maxGolems(p) then
		toast(p, "Your inventory is full!", "red"); return
	end
	local id = CaveStandService.MaxId(p) + 1
	local ok = InventoryService.AddGolem(p, id, GroupGolemService.KIND, "miner", 0, "group", true)
	if not ok then return end
	InventoryService.Give(p, "Golem_" .. id)
	p:SetAttribute("GroupGolem", true)
	updateBest(p)
	toast(p, "Mushroom Golem claimed! Thanks for joining - don't forget to LIKE the game!", "green")
	remote:FireClient(p, "Claimed")
	task.spawn(function() pcall(DataService.SaveNow, p) end)
end

-- гравець біля якогось стенда (вікно відкривається лише поруч)
local function nearStand(p: Player): boolean
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local f = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub") and workspace.Cave.Hub:FindFirstChild("GroupStands")
	if not (hrp and hrp:IsA("BasePart") and f) then return false end
	for _, s in f:GetChildren() do
		local b = s:FindFirstChild("Base")
		if b and b:IsA("BasePart") and (hrp.Position - b.Position).Magnitude <= REACH + 8 then return true end
	end
	return false
end

-- живий Mushroom Golem на кожному стенді (вітрина)
local function placeShowcase(stand: Instance)
	local spot = stand:FindFirstChild("GolemSpot")
	if not (spot and spot:IsA("BasePart")) or stand:FindFirstChild("ShowGolem") then return end
	local m = GolemModel.build(GroupGolemService.KIND, "miner")
	if not m then return end
	m.Name = "ShowGolem"
	m:SetAttribute("Mut", 0)
	local k = 0.9
	m:ScaleTo(m:GetScale() * k)
	local up = GolemModel.footOffset(m)
	local base = spot.CFrame
	local pos = base.Position - Vector3.new(0, spot.Size.Y / 2, 0) + Vector3.new(0, up, 0)
	m:PivotTo(CFrame.lookAt(pos, pos + base.LookVector)) -- обличчям до кнопки (до гравців)
	m.Parent = stand
end

function GroupGolemService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("GroupGolemAction") or Instance.new("RemoteEvent")
	ev.Name = "GroupGolemAction"; ev.Parent = remotes
	remote = ev :: RemoteEvent
	remote.OnServerEvent:Connect(function(p, action)
		if action == "Check" then
			if not nearStand(p) then return end
			local t = os.clock()
			if last[p] and t - last[p] < 1 then return end
			last[p] = t
			tryClaim(p)
		end
	end)
	-- кнопка E (GroupPrompt) лише відкриває вікно на клієнті (GroupStandClient); видача — кнопка CLAIM у вікні → "Check"
	local function onPlayer(p: Player)
		task.spawn(function()
			p:SetAttribute("InGroup", inGroup(p))
		end)
		for _, a in { "InvGolems", "CaveStandGolems", "MutMachines" } do
			p:GetAttributeChangedSignal(a):Connect(function() updateBest(p) end)
		end
		updateBest(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do onPlayer(p) end
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
	task.spawn(function()
		local hub = workspace:WaitForChild("Cave"):WaitForChild("Hub")
		local f = hub:WaitForChild("GroupStands", 30)
		if not f then return end
		task.wait(1) -- PlotAssets (перенос префабів PlotService)
		for _, s in f:GetChildren() do placeShowcase(s) end
	end)
end

return GroupGolemService
