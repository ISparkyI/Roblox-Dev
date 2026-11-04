--!strict
-- BossPortalService — розклад боса і портал на арену (кінець зали, Workspace/Cave/Hub/BossPortal). 29.10.2026.
-- Де: ServerScriptService/BossPortalService (ModuleScript). Запуск: NicheBoot (після GroupGolemService).
-- Бос — кожні CYCLE с (15 хв) за годинником сервера (GetServerTimeNow), однаково на всіх серверах:
--   Workspace.BossAt        — коли наступний бос (с, час сервера); його показують HUD (MainHUD) і табличка BOSS FIGHT;
--   Workspace.BossOpenUntil — до коли портал відкритий після появи боса (OPEN_FOR с) — скеля розсувається (BossPortalClient).
-- Remotes/BossPortalAction: клієнт → сервер:
--   "TP"    — кнопка Boss у HUD телепортує до входу (перед колом);
--   "Arena" — гравець у колі порталу (відлік 3 с — BossPortalClient) → на арену Workspace/«Boss Map» (ТОЙ САМИЙ сервер;
--             випадкова точка в радіусі Radius від частини ArenaSpawn), атрибут гравця InBossArena = true (03.11.2026);
--   "Exit"  — кнопка EXIT (TeleportHUD, після підтвердження) → на свій плот (NicheService.TeleportHome), InBossArena = nil.
--   Смерть / новий персонаж — InBossArena знімається (гравець з'являється вдома).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local BossPortalService = {}
BossPortalService.CYCLE = 15 * 60
BossPortalService.OPEN_FOR = 60

local lastTP: { [Player]: number } = {}

local function tick()
	local now = workspace:GetServerTimeNow()
	local k = math.floor(now / BossPortalService.CYCLE)
	local at = (k + 1) * BossPortalService.CYCLE
	local openUntil = k * BossPortalService.CYCLE + BossPortalService.OPEN_FOR
	if workspace:GetAttribute("BossAt") ~= at then workspace:SetAttribute("BossAt", at) end
	if workspace:GetAttribute("BossOpenUntil") ~= openUntil then workspace:SetAttribute("BossOpenUntil", openUntil) end
end

local function entrance(): CFrame?
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local portal = hub and hub:FindFirstChild("BossPortal")
	local ring = portal and portal:FindFirstChild("Ring")
	local c = ring and ring:FindFirstChild("RingCenter")
	if not (c and c:IsA("BasePart")) then return nil end
	local pos = c.Position + Vector3.new(0, 3.2, 17) -- перед колом, обличчям до скелі
	return CFrame.lookAt(pos, Vector3.new(c.Position.X, pos.Y, c.Position.Z))
end

local RING_R = 13.8 -- коло перед аркою (як у BossPortalClient)
local rng = Random.new()
local function inPortalRing(hrp: BasePart): boolean
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local portal = hub and hub:FindFirstChild("BossPortal")
	local ring = portal and portal:FindFirstChild("Ring")
	local c = ring and ring:FindFirstChild("RingCenter")
	if not (c and c:IsA("BasePart")) then return false end
	local d = hrp.Position - c.Position
	return Vector2.new(d.X, d.Z).Magnitude <= RING_R + 2 and math.abs(d.Y) < 10
end
local function arenaSpot(): CFrame?
	local bm = workspace:FindFirstChild("Boss Map")
	local sp = bm and bm:FindFirstChild("ArenaSpawn")
	if not (sp and sp:IsA("BasePart")) then return nil end
	local r = tonumber(sp:GetAttribute("Radius")) or 30
	local a = rng:NextNumber() * math.pi * 2
	local dist = r * math.sqrt(rng:NextNumber())
	local pos = sp.Position + Vector3.new(math.cos(a) * dist, 0, math.sin(a) * dist)
	return CFrame.lookAt(pos, Vector3.new(sp.Position.X, pos.Y, sp.Position.Z) + Vector3.new(0.01, 0, 0))
end

function BossPortalService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("BossPortalAction") :: RemoteEvent?
	if not ev then
		local e = Instance.new("RemoteEvent"); e.Name = "BossPortalAction"; e.Parent = remotes
		ev = e
	end
	(ev :: RemoteEvent).OnServerEvent:Connect(function(p: Player, action: any)
		if action ~= "TP" and action ~= "Arena" and action ~= "Exit" then return end
		local t = os.clock()
		if lastTP[p] and t - lastTP[p] < 2 then return end
		lastTP[p] = t
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and hum.Health > 0) then return end
		if action == "Arena" then
			if p:GetAttribute("InBossArena") == true or not inPortalRing(hrp :: BasePart) then return end
			local spot = arenaSpot()
			if not spot then return end
			pcall(function() p:RequestStreamAroundAsync(spot.Position) end)
			if p.Character ~= char then return end
			char:PivotTo(spot + Vector3.new(0, hum.HipHeight + (hrp :: BasePart).Size.Y / 2 + 0.5, 0))
			;(hrp :: BasePart).AssemblyLinearVelocity = Vector3.zero
			p:SetAttribute("InBossArena", true)
			return
		elseif action == "Exit" then
			if p:GetAttribute("InBossArena") ~= true then return end
			p:SetAttribute("InBossArena", nil)
			local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
			if okN and NS and NS.TeleportHome then NS.TeleportHome(p) end
			return
		end
		local cf = entrance()
		if not (hrp and hum and hum.Health > 0 and cf) then return end
		char:PivotTo(cf)
		p:SetAttribute("InBossArena", nil)
	end)
	Players.PlayerRemoving:Connect(function(p) lastTP[p] = nil end)
	-- новий персонаж (смерть на арені) — вже не на арені
	local function hookP(p: Player) p.CharacterAdded:Connect(function() p:SetAttribute("InBossArena", nil) end) end
	Players.PlayerAdded:Connect(hookP)
	for _, p in Players:GetPlayers() do hookP(p) end
	tick()
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return BossPortalService
