-- CaveService — персональна печера кожного власника ніші.
-- Де: ServerScriptService/CaveService (Script).
--
-- Як працює:
--   * Шаблон печери лежить у Workspace/Cave_Inside (там його зручно редагувати). На старті сервера він переїжджає
--     в ServerStorage/CaveInsideTemplate, щоб у грі не було зайвої копії (так само, як NichePrefabs).
--   * Коли ніша отримує власника, для неї створюється своя печера Workspace/Caves/Cave_<NicheIndex>: копія шаблону,
--     зсунута по Z на SPACING * (індекс − 1). Атрибути печери: NicheIndex, OwnerUserId.
--   * Коли власник виходить (ніша стає вільною), його печера видаляється, а гості, що були всередині, повертаються
--     до кола входу тієї ніші, звідки зайшли.
--   * Вхід/вихід — ServerScriptService/CaveEntrance: вхід у печеру ТІЄЇ ніші, до чийого кола підійшов гравець,
--     вихід — назад у коло входу цієї ж ніші. Заходити можуть усі, а діяти (купівля стендів, підбір голема) —
--     лише власник: Shared/CaveAccess.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local SPACING = 130          -- відстань між печерами вздовж Z (печера завширшки 84)
local caves: { [number]: Model } = {}

local folder = workspace:FindFirstChild("Caves") or Instance.new("Folder")
folder.Name = "Caves"; folder.Parent = workspace

-- шаблон
local authoring = workspace:FindFirstChild("Cave_Inside")
if authoring then authoring.Name = "CaveInsideTemplate"; authoring.Parent = ServerStorage end
local template = ServerStorage:WaitForChild("CaveInsideTemplate") :: Model
local BASE = template:GetPivot()

local function nicheEntrance(niche: Instance?): CFrame?
	local gc = niche and niche:FindFirstChild("GolemCave")
	local center = gc and gc:FindFirstChild("RingCenter", true)
	if center and center:IsA("BasePart") then return CFrame.new(center.Position + Vector3.new(0, 3, 0)) end
	return nil
end

local function moveTo(player: Player, cf: CFrame)
	local char = player.Character
	if not (char and char.PrimaryPart) then return end
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end)   -- StreamingEnabled: дочекатись підвантаження місця
	if player.Character == char and char.PrimaryPart then char:PivotTo(cf) end
end

-- гості повертаються у коло входу ніші, звідки зайшли (або у власну нішу)
local function evict(ownerUserId: number)
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InCave") and p:GetAttribute("CaveOwner") == ownerUserId then
			local niches = workspace:FindFirstChild("Niches")
			local from = p:GetAttribute("CaveFrom")
			local niche = niches and type(from) == "string" and niches:FindFirstChild(from)
			if not niche and niches then
				for _, n in niches:GetChildren() do
					if n:GetAttribute("OwnerUserId") == p.UserId then niche = n end
				end
			end
			p:SetAttribute("InCave", nil); p:SetAttribute("CaveOwner", nil); p:SetAttribute("CaveFrom", nil)
			local cf = nicheEntrance(niche)
			if cf then task.spawn(moveTo, p, cf) end
		end
	end
end

local function createCave(index: number, ownerId: number)
	local c = template:Clone()
	c.Name = "Cave_" .. index
	c:SetAttribute("NicheIndex", index)
	c:SetAttribute("OwnerUserId", ownerId)
	c:PivotTo(BASE * CFrame.new(0, 0, SPACING * (index - 1)))
	c.Parent = folder
	caves[index] = c
end

local function destroyCave(index: number)
	local c = caves[index]
	if not c then return end
	local owner = c:GetAttribute("OwnerUserId") :: number
	caves[index] = nil
	evict(owner)
	c:Destroy()
end

-- підказка входу активна лише в зайнятій ніші (в неї є печера)
local function syncEntrance(niche: Instance, enabled: boolean)
	for _, d in niche:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "CavePrompt" and d.Enabled ~= enabled then d.Enabled = enabled end
	end
end

-- узгодження кожні 0,5 с: ніша з власником ⇒ є печера; вільна ніша ⇒ печери немає
task.spawn(function()
	while true do
		local niches = workspace:FindFirstChild("Niches")
		if niches then
			local seen: { [number]: boolean } = {}
			for _, n in niches:GetChildren() do
				local idx = n:GetAttribute("NicheIndex") :: number?
				local owner = (n:GetAttribute("OwnerUserId") :: number?) or 0
				if idx then
					seen[idx] = true
					local cave = caves[idx]
					if owner ~= 0 then
						if cave and cave:GetAttribute("OwnerUserId") ~= owner then destroyCave(idx); cave = nil end
						if not cave then createCave(idx, owner) end
						syncEntrance(n, true)
					else
						if cave then destroyCave(idx) end
						syncEntrance(n, false)
					end
				end
			end
			for idx in caves do
				if not seen[idx] then destroyCave(idx) end
			end
		end
		task.wait(0.5)
	end
end)

-- після смерті/респавну гравця NicheService повертає його на спавн ніші — скидаємо стан печери
local function onPlayer(p: Player)
	p.CharacterAdded:Connect(function()
		p:SetAttribute("InCave", nil); p:SetAttribute("CaveOwner", nil); p:SetAttribute("CaveFrom", nil)
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end
