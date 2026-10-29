--!strict
-- NicheService — ніші гравців (плоти): збірка з префабів, автоклейм, телепорт на спавн.
-- Де: ServerScriptService/NicheService (ModuleScript). Запускає ServerScriptService/NicheBoot.
--
-- Як працює:
--   * Шаблони ніш лежать у Workspace/NichePrefabs (там їх зручно редагувати).
--     На старті сервера папка переїжджає в ServerStorage, щоб шаблон не був у грі.
--   * Workspace/Niches на старті перебудовується: у кожен сокет з Workspace/NicheSockets
--     ставиться свіжа копія шаблону етапу 1 (вільна ніша = етап 1, порожня).
--   * Гравець заходить → отримує першу вільну нішу (порядок SOCKET_ORDER) → при кожній
--     появі персонажа телепортується на PlotSpawn своєї ніші (обличчям до важеля).
--   * Гравець виходить → ніша скидається: нова копія етапу 1, без власника.
--
-- API для інших серверних систем:
--   local NicheService = require(game.ServerScriptService.NicheService)
--   NicheService.GetNiche(player)   -> Model? (ніша гравця)
--   NicheService.GetOwner(niche)    -> Player?
--   NicheService.Claimed.Event:Connect(function(player, niche) ... end)
--   NicheService.Released.Event:Connect(function(player, niche) ... end)
-- Атрибути ніші: NicheIndex, Socket, Stage, OwnerUserId (0 = вільна).
-- Етап гравця поки береться з атрибута player "Stage" (за замовчуванням 1);
-- коли буде збереження даних — ставити цей атрибут до клейму.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))

local SOCKET_ORDER = { "Socket1L", "Socket1R", "Socket2L", "Socket2R", "Socket3L", "Socket3R" }

type Slot = { index: number, socket: BasePart, model: Model?, owner: Player? }

local NicheService = {}
NicheService.Claimed = Instance.new("BindableEvent")
NicheService.Released = Instance.new("BindableEvent")

local slots: { Slot } = {}
local byPlayer: { [Player]: Slot } = {}
local templates: Folder
local nichesFolder: Folder
local started = false

local function templateFor(stage: number): Model
	local t = templates:FindFirstChild("NichePrefab_Stage" .. stage) or templates:FindFirstChild("NichePrefab_Stage1")
	assert(t and t:IsA("Model"), "NicheService: немає шаблону NichePrefab_Stage1")
	return t
end

-- Вигляд ніші залежно від власника: табличка, UI на таблах.
local function applyOwner(slot: Slot)
	local m = slot.model
	if not m then return end
	local owner = slot.owner
	m:SetAttribute("OwnerUserId", owner and owner.UserId or 0)
	for _, d in m:GetDescendants() do
		if d.Name == "OwnerSign" and d:IsA("BasePart") then
			d:SetAttribute("OwnerName", owner and owner.DisplayName or "")
		end
	end
	-- інформація на таблах показується тільки в зайнятій ніші
	for _, folderName in { "Upgrade panels", "RollSystem" } do
		local f = m:FindFirstChild(folderName)
		if f then
			for _, d in f:GetDescendants() do
				if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
					d.Enabled = owner ~= nil
				end
			end
		end
	end
end

local function build(slot: Slot, stage: number)
	if slot.model then slot.model:Destroy() end
	local m = templateFor(stage):Clone()
	m.Name = "Niche" .. slot.index
	m:SetAttribute("NicheIndex", slot.index)
	m:SetAttribute("Socket", slot.socket.Name)
	m:SetAttribute("Stage", stage)
	m:PivotTo(slot.socket.CFrame)
	m.Parent = nichesFolder
	slot.model = m
	applyOwner(slot)
end

local function spawnCFrame(slot: Slot): CFrame?
	local m = slot.model
	if not m then return nil end
	local sp = m:FindFirstChild("PlotSpawn", true)
	if sp and sp:IsA("BasePart") then return sp.CFrame end
	return m:GetPivot()
end

local function teleport(player: Player)
	local slot = byPlayer[player]
	local char = player.Character
	if not slot or not char then return end
	local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	local cf = spawnCFrame(slot)
	if not hrp or not cf then return end
	local up = (hum and hum.HipHeight or 2) + hrp.Size.Y / 2 + 0.2
	char:PivotTo(cf + cf.UpVector * up)
	hrp.AssemblyLinearVelocity = Vector3.zero
end
-- кнопка HOME у HUD (TeleportHUD → StallShopService "Teleport", "home"; 29.10.2026): на PlotSpawn своєї ніші
function NicheService.TeleportHome(player: Player) teleport(player) end

local function claim(player: Player)
	if byPlayer[player] then return end
	for _, slot in slots do
		if not slot.owner then
			slot.owner = player
			byPlayer[player] = slot
			local stage = (player:GetAttribute("Stage") :: number?) or 1
			if not slot.model or slot.model:GetAttribute("Stage") ~= stage then
				build(slot, stage)
			else
				applyOwner(slot)
			end
			player:SetAttribute("NicheIndex", slot.index)
			NicheService.Claimed:Fire(player, slot.model)
			if player.Character then task.spawn(teleport, player) end
			return
		end
	end
	warn("NicheService: вільних ніш немає для " .. player.Name .. " (MaxPlayers у Game Settings має бути 6)")
end

local function release(player: Player)
	local slot = byPlayer[player]
	if not slot then return end
	DataService.Capture(player) -- знімок даних (Forge тощо), поки ніша ще жива
	byPlayer[player] = nil
	local old = slot.model
	slot.owner = nil
	NicheService.Released:Fire(player, old)
	build(slot, 1) -- скидання: свіжа порожня ніша етапу 1
end

function NicheService.GetNiche(player: Player): Model?
	local slot = byPlayer[player]
	return slot and slot.model
end

-- перебудувати нішу гравця під його поточний етап (перехід на нову мапу, MapService): старі сервіси знімають стан
-- (Released), ніша збирається з шаблону етапу, сервіси підхоплюють нову (Claimed), гравець — на спавн.
function NicheService.Rebuild(player: Player)
	local slot = byPlayer[player]
	if not slot then return end
	local stage = (player:GetAttribute("Stage") :: number?) or 1
	NicheService.Released:Fire(player, slot.model)
	build(slot, stage)
	player:SetAttribute("NicheIndex", slot.index)
	NicheService.Claimed:Fire(player, slot.model)
	if player.Character then task.spawn(teleport, player) end
end

function NicheService.GetOwner(niche: Model): Player?
	for _, slot in slots do
		if slot.model == niche then return slot.owner end
	end
	return nil
end

function NicheService.Start()
	if started then return end
	started = true
	-- шаблони: Workspace/NichePrefabs -> ServerStorage/NichePrefabs
	local wsTemplates = workspace:FindFirstChild("NichePrefabs")
	if wsTemplates then wsTemplates.Parent = ServerStorage end
	templates = ServerStorage:WaitForChild("NichePrefabs") :: Folder
	-- ніші в печері збираються заново з шаблону (шаблон — єдине джерело правди)
	local old = workspace:FindFirstChild("Niches")
	if old then old:Destroy() end
	nichesFolder = Instance.new("Folder")
	nichesFolder.Name = "Niches"
	nichesFolder.Parent = workspace
	local sockets = workspace:WaitForChild("NicheSockets")
	for i, name in SOCKET_ORDER do
		local socket = sockets:FindFirstChild(name)
		if socket and socket:IsA("BasePart") then
			local slot: Slot = { index = i, socket = socket, model = nil, owner = nil }
			table.insert(slots, slot)
			build(slot, 1)
		else
			warn("NicheService: немає сокета " .. name)
		end
	end
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(teleport, player)
		end)
		task.spawn(function()
			if DataService.WaitLoaded(player) then claim(player) end -- ніша зі збереженим етапом
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(release)
	for _, p in Players:GetPlayers() do onPlayer(p) end
end

return NicheService
