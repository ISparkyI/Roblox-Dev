-- CaveEntrance — підказки E: «ENTER CAVE» (Niche*/GolemCave/PromptAnchor/CavePrompt) і «EXIT CAVE»
-- (Workspace/Caves/Cave_<N>/CaveExit/PromptAnchor/ExitPrompt). Печера кожної зайнятої ніші стоїть під нею (CaveService).
--   вхід телепортує в печеру ТІЄЇ ніші, до чийого кола підійшов гравець (Cave_<NicheIndex>), і запам'ятовує, звідки зайшов;
--   вихід повертає в коло входу ніші, якій належить ця печера, обличчям від печерного входу.
-- Атрибути гравця (InCave, CaveOwner, CaveFrom, CaveIndex) ставляться лише ПІСЛЯ вдалого телепорту.
-- Кулдаун входу й виходу — окремий (1 с кожен), щоб одразу після входу можна було вийти.
-- Заходити і виходити можуть ВСІ гравці. Права на дії в печері (купівля стендів, підбір големів) — CaveAccess:
--   гість (не власник печери) має CaveAccess.canInteract = false.
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local RS = game:GetService("ReplicatedStorage")
local CaveAccess = require(RS:WaitForChild("Shared"):WaitForChild("CaveAccess"))

local COOLDOWN = 1.0
local lastEnter: { [Player]: number } = {}
local lastExit: { [Player]: number } = {}

local function ancestorUnder(inst: Instance, parent: Instance?): Instance?
	local cur: Instance? = inst
	while cur and cur.Parent do
		if cur.Parent == parent then return cur end
		cur = cur.Parent
	end
	return nil
end

local function ownNiche(player: Player): Instance?
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return nil end
	for _, n in niches:GetChildren() do
		if n:GetAttribute("OwnerUserId") == player.UserId then return n end
	end
	return nil
end

-- точка біля кола входу ніші, обличчям від печерного входу (у бік ніші)
local function entranceCFrame(niche: Instance?): CFrame?
	local gc = niche and niche:FindFirstChild("GolemCave")
	local center = gc and gc:FindFirstChild("RingCenter", true)
	if not (center and center:IsA("BasePart")) then return nil end
	local pos = center.Position + Vector3.new(0, 3, 0)
	local away = center.Position - (gc :: Model):GetPivot().Position
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.1 then return CFrame.new(pos) end
	return CFrame.lookAt(pos, pos + away.Unit)
end

-- true — гравця перенесено
local function teleport(player: Player, cf: CFrame): boolean
	local char = player.Character
	if not (char and char.PrimaryPart) then return false end
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end) -- StreamingEnabled: дочекатись підвантаження
	if player.Character ~= char or not char.PrimaryPart then return false end
	char:PivotTo(cf)
	char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
	return true
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CavePrompt" and prompt.Name ~= "ExitPrompt" then return end
	local now = os.clock()
	local last = prompt.Name == "CavePrompt" and lastEnter or lastExit
	if last[player] and now - last[player] < COOLDOWN then return end
	last[player] = now

	if prompt.Name == "CavePrompt" then
		local niche = ancestorUnder(prompt, workspace:FindFirstChild("Niches"))
		local idx = niche and niche:GetAttribute("NicheIndex")
		local caves = workspace:FindFirstChild("Caves")
		local cave = caves and idx and caves:FindFirstChild("Cave_" .. idx)
		if not cave then return end -- ніша вільна: печери немає
		local ownerId = (cave:GetAttribute("OwnerUserId") :: number?) or 0
		if not CaveAccess.canEnter(player, ownerId) then return end
		local spawn = cave:FindFirstChild("GolemCaveSpawn", true)
		if not spawn or not spawn:IsA("BasePart") then return end
		if teleport(player, spawn.CFrame + Vector3.new(0, 3, 0)) then
			player:SetAttribute("InCave", true)
			player:SetAttribute("CaveOwner", ownerId)                   -- чия печера (власник цієї ніші)
			player:SetAttribute("CaveFrom", niche and niche.Name or "") -- звідки зайшли
			player:SetAttribute("CaveIndex", idx)                       -- у якій печері (Cave_<N>)
		end
	else
		if not CaveAccess.canExit(player) then return end
		local cave = ancestorUnder(prompt, workspace:FindFirstChild("Caves"))
		local idx = cave and cave:GetAttribute("NicheIndex")
		local niches = workspace:FindFirstChild("Niches")
		local niche = niches and idx and niches:FindFirstChild("Niche" .. idx)
		niche = niche or ownNiche(player)
		local cf = entranceCFrame(niche)
		if cf and teleport(player, cf) then
			player:SetAttribute("InCave", nil)
			player:SetAttribute("CaveOwner", nil)
			player:SetAttribute("CaveFrom", nil)
			player:SetAttribute("CaveIndex", nil)
		end
	end
end)

Players.PlayerRemoving:Connect(function(p) lastEnter[p] = nil; lastExit[p] = nil end)
