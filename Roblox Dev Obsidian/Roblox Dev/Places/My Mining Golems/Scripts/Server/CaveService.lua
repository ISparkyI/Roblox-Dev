-- CaveService — персональна печера кожного власника ніші, рівно ПІД його нішею.
-- Де: ServerScriptService/CaveService (Script). Автор печери — друг користувача; прив'язку до сокетів переписано 26.10.2026.
--
-- Як працює:
--   * Шаблон печери — Workspace/Cave_Inside (тестовий префаб: правиш у Studio там, де він стоїть, під тестовою
--     нішею NichePrefabs). На старті сервера він переїжджає в ServerStorage/CaveInsideTemplate і з карти зникає
--     (як NichePrefabs / PlotPrefabs). Гравців у шаблон НЕ телепортуємо.
--   * Печера прив'язана до СОКЕТА ніші (Workspace/NicheSockets/Socket*), а не до моделі ніші етапу: ставиться за
--     CFrame сокета * CAVE_FROM_SOCKET — по центру під нішею, на фіксованій глибині (верх печери ≈ 12 стадів під
--     підлогою ніші; не перетинає карту, ніші й сусідні печери — перевірено для всіх 6 сокетів). Ніша етапу
--     (карта 1, 2…) може замінюватись — печера під нею лишається та сама: Workspace/Caves/Cave_<NicheIndex>
--     (NicheIndex = номер слота NicheService, 1:1 із сокетом). Атрибути печери: NicheIndex, Socket, OwnerUserId.
--   * Події NicheService (без опитування): Claimed → печера власника з'являється; Released → гості повертаються до
--     входу ніші, печера прибирається (шаблон 5159 інстансів — у вільних нішах печер немає).
--   * Підказка ENTER CAVE (Niche*/GolemCave/PromptAnchor/CavePrompt) увімкнена лише в зайнятій ніші; затиск 0,9 с
--     ставить код (і для EXIT CAVE у печері) — значення з Edit не єдине джерело.
--   * Вхід / вихід — ServerScriptService/CaveEntrance; права — Shared/CaveAccess.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")

local NicheService = require(SSS:WaitForChild("NicheService"))

-- де печера відносно сокета ніші (простір сокета: −Z — углиб ніші, X — уздовж ряду сокетів):
-- центр під нішею (ніша 150 × 271, центр підлоги ≈ z −135), півот на 42 стади нижче сокета, довгою віссю (160) углиб.
local CAVE_FROM_SOCKET = CFrame.new(0, -42, -135) * CFrame.Angles(0, -math.pi / 2, 0)
local HOLD = 0.9 -- затиск ENTER / EXIT CAVE, с

local folder = workspace:FindFirstChild("Caves") or Instance.new("Folder")
folder.Name = "Caves"
folder.Parent = workspace

-- шаблон: Workspace/Cave_Inside → ServerStorage/CaveInsideTemplate
local authoring = workspace:FindFirstChild("Cave_Inside")
if authoring then
	local old = ServerStorage:FindFirstChild("CaveInsideTemplate")
	if old then old:Destroy() end
	authoring.Name = "CaveInsideTemplate"
	authoring.Parent = ServerStorage
end
local template = ServerStorage:WaitForChild("CaveInsideTemplate", 10) :: Model?
if not template then
	warn("CaveService: немає шаблону печери (Workspace/Cave_Inside або ServerStorage/CaveInsideTemplate) — печери вимкнено")
	return
end

local caves: { [number]: Model } = {}

local function socketOf(niche: Instance): BasePart?
	local name = niche:GetAttribute("Socket")
	local sockets = workspace:FindFirstChild("NicheSockets")
	local s = sockets and type(name) == "string" and sockets:FindFirstChild(name)
	return (s and s:IsA("BasePart")) and s or nil
end

-- точка біля кола входу ніші, обличчям від печерного входу (у бік ніші)
local function nicheEntrance(niche: Instance?): CFrame?
	local gc = niche and niche:FindFirstChild("GolemCave")
	local center = gc and gc:FindFirstChild("RingCenter", true)
	if not (center and center:IsA("BasePart")) then return nil end
	local pos = center.Position + Vector3.new(0, 3, 0)
	local away = center.Position - (gc :: Model):GetPivot().Position
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.1 then return CFrame.new(pos) end
	return CFrame.lookAt(pos, pos + away.Unit)
end

local function moveTo(player: Player, cf: CFrame)
	local char = player.Character
	if not (char and char.PrimaryPart) then return end
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end) -- StreamingEnabled: дочекатись підвантаження
	if player.Character == char and char.PrimaryPart then
		char:PivotTo(cf)
		char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
	end
end

local function clearCaveAttrs(p: Player)
	p:SetAttribute("InCave", nil); p:SetAttribute("CaveOwner", nil); p:SetAttribute("CaveFrom", nil)
end

-- усіх, хто в печері idx, повертаємо до входу ніші, з якої зайшли (або до власної ніші)
local function evict(idx: number)
	local niches = workspace:FindFirstChild("Niches")
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InCave") and p:GetAttribute("CaveIndex") == idx then
			local from = p:GetAttribute("CaveFrom")
			local niche = niches and type(from) == "string" and niches:FindFirstChild(from) or nil
			if not niche or (niche:GetAttribute("NicheIndex") == idx) then
				niche = NicheService.GetNiche(p) -- власник ніші вже пішов: гостя — у його власну нішу
			end
			clearCaveAttrs(p); p:SetAttribute("CaveIndex", nil)
			local cf = nicheEntrance(niche)
			if cf then task.spawn(moveTo, p, cf) end
		end
	end
end

local function removeCave(idx: number)
	local c = caves[idx]
	if not c then return end
	caves[idx] = nil
	evict(idx)
	c:Destroy()
end

local function ensureCave(niche: Instance, ownerId: number)
	local idx = niche:GetAttribute("NicheIndex") :: number?
	local socket = socketOf(niche)
	if not idx or not socket then warn("CaveService: у ніші " .. niche.Name .. " немає NicheIndex / Socket"); return end
	local cur = caves[idx]
	if cur and cur.Parent and cur:GetAttribute("OwnerUserId") == ownerId then return end
	if cur then removeCave(idx) end
	local c = (template :: Model):Clone()
	c.Name = "Cave_" .. idx
	c:SetAttribute("NicheIndex", idx)
	c:SetAttribute("Socket", socket.Name)
	c:SetAttribute("OwnerUserId", ownerId)
	c:PivotTo(socket.CFrame * CAVE_FROM_SOCKET)
	for _, d in c:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "ExitPrompt" then d.HoldDuration = HOLD end
	end
	c.Parent = folder
	caves[idx] = c
end

-- ===== підказка ENTER CAVE: лише в зайнятій ніші; затиск 0,9 с =====
local function syncNiche(n: Instance)
	local on = ((n:GetAttribute("OwnerUserId") :: number?) or 0) ~= 0
	for _, d in n:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "CavePrompt" then
			d.HoldDuration = HOLD
			if d.Enabled ~= on then d.Enabled = on end
		end
	end
end
local function hookNiche(n: Instance)
	if not n:IsA("Model") or not n.Parent then return end
	syncNiche(n)
	n:GetAttributeChangedSignal("OwnerUserId"):Connect(function() syncNiche(n) end)
end
local function hookNiches(f: Instance)
	for _, n in f:GetChildren() do hookNiche(n) end
	f.ChildAdded:Connect(function(n) task.defer(hookNiche, n) end) -- ніша перебудована (етап / скидання)
end
workspace.ChildAdded:Connect(function(c)
	if c.Name == "Niches" and c:IsA("Folder") then hookNiches(c) end -- NicheService.Start створює папку заново
end)
do
	local nf = workspace:FindFirstChild("Niches")
	if nf then hookNiches(nf) end
end

-- ===== печери: події NicheService =====
NicheService.Claimed.Event:Connect(function(player: Player, niche: Model)
	if niche then ensureCave(niche, player.UserId) end
end)
NicheService.Released.Event:Connect(function(_player: Player, niche: Model)
	local idx = niche and niche:GetAttribute("NicheIndex") :: number?
	if idx then removeCave(idx) end
end)
-- ті, хто отримав нішу до підключення подій
for _, p in Players:GetPlayers() do
	local n = NicheService.GetNiche(p)
	if n then ensureCave(n, p.UserId) end
end

-- після смерті / респавну NicheService ставить гравця на спавн ніші — скидаємо стан печери
local function onPlayer(p: Player)
	p.CharacterAdded:Connect(function() clearCaveAttrs(p); p:SetAttribute("CaveIndex", nil) end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end
