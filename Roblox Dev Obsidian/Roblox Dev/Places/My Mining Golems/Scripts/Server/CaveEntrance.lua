-- CaveEntrance — підказки E: «ENTER CAVE» (Niche*/GolemCave/PromptAnchor/CavePrompt) і «EXIT CAVE»
-- (Workspace/Caves/Cave_<N>/CaveExit/PromptAnchor/ExitPrompt). Печері кожного власника — своя копія (CaveService).
--   вхід телепортує в печеру ТІЄЇ ніші, до чийого кола підійшов гравець (Cave_<NicheIndex>), і запам'ятовує, звідки зайшов;
--   вихід повертає в коло входу ніші, якій належить ця печера.
-- Заходити і виходити можуть ВСІ гравці. Права на дії в печері (купівля стендів, підбір големів) — CaveAccess:
--   гість (не власник печери) має CaveAccess.canInteract = false.
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local RS = game:GetService("ReplicatedStorage")
local CaveAccess = require(RS:WaitForChild("Shared"):WaitForChild("CaveAccess"))

local COOLDOWN = 1.0
local last: { [Player]: number } = {}

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

local function entranceCFrame(niche: Instance?): CFrame?
	local gc = niche and niche:FindFirstChild("GolemCave")
	local center = gc and gc:FindFirstChild("RingCenter", true)
	if center and center:IsA("BasePart") then return CFrame.new(center.Position + Vector3.new(0, 3, 0)) end
	return nil
end

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if not (char and char.PrimaryPart) then return end
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end)   -- StreamingEnabled: дочекатись підвантаження
	if player.Character == char and char.PrimaryPart then char:PivotTo(cf) end
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CavePrompt" and prompt.Name ~= "ExitPrompt" then return end
	local now = os.clock()
	if last[player] and now - last[player] < COOLDOWN then return end
	last[player] = now

	if prompt.Name == "CavePrompt" then
		if prompt:GetAttribute("ComingSoon") then return end
		local niche = ancestorUnder(prompt, workspace:FindFirstChild("Niches"))
		local idx = niche and niche:GetAttribute("NicheIndex")
		local caves = workspace:FindFirstChild("Caves")
		local cave = caves and idx and caves:FindFirstChild("Cave_" .. idx)
		if not cave then return end                                       -- ніша вільна: печери ще немає
		local ownerId = (cave:GetAttribute("OwnerUserId") :: number?) or 0
		if not CaveAccess.canEnter(player, ownerId) then return end
		local spawn = cave:FindFirstChild("GolemCaveSpawn", true)
		if not spawn or not spawn:IsA("BasePart") then return end
		player:SetAttribute("InCave", true)
		player:SetAttribute("CaveOwner", ownerId)                         -- чия печера (власник цієї ніші)
		player:SetAttribute("CaveFrom", niche and niche.Name or "")       -- звідки зайшли
		teleport(player, spawn.CFrame + Vector3.new(0, 3, 0))
	else
		if not CaveAccess.canExit(player) then return end
		local cave = ancestorUnder(prompt, workspace:FindFirstChild("Caves"))
		local idx = cave and cave:GetAttribute("NicheIndex")
		local niches = workspace:FindFirstChild("Niches")
		local niche = niches and idx and niches:FindFirstChild("Niche" .. idx)
		niche = niche or ownNiche(player)
		local cf = entranceCFrame(niche)
		player:SetAttribute("InCave", nil)
		player:SetAttribute("CaveOwner", nil)
		player:SetAttribute("CaveFrom", nil)
		if cf then teleport(player, cf) end
	end
end)

Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
