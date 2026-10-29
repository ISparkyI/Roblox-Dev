--!strict
-- BossPortalService — розклад боса і портал на арену (кінець зали, Workspace/Cave/Hub/BossPortal). 29.10.2026.
-- Де: ServerScriptService/BossPortalService (ModuleScript). Запуск: NicheBoot (після GroupGolemService).
-- Бос — кожні CYCLE с (15 хв) за годинником сервера (GetServerTimeNow), однаково на всіх серверах:
--   Workspace.BossAt        — коли наступний бос (с, час сервера); його показують HUD (MainHUD) і табличка BOSS FIGHT;
--   Workspace.BossOpenUntil — до коли портал відкритий після появи боса (OPEN_FOR с) — скеля розсувається (BossPortalClient).
-- Арени ще немає: коло біля порталу — тост COMING SOON (клієнт). Remotes/BossPortalAction: клієнт → сервер ("TP") —
--   кнопка Boss у HUD телепортує до входу (перед колом).
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

function BossPortalService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("BossPortalAction") :: RemoteEvent?
	if not ev then
		local e = Instance.new("RemoteEvent"); e.Name = "BossPortalAction"; e.Parent = remotes
		ev = e
	end
	(ev :: RemoteEvent).OnServerEvent:Connect(function(p: Player, action: any)
		if action ~= "TP" then return end
		local t = os.clock()
		if lastTP[p] and t - lastTP[p] < 2 then return end
		lastTP[p] = t
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local cf = entrance()
		if not (hrp and hum and hum.Health > 0 and cf) then return end
		char:PivotTo(cf)
	end)
	Players.PlayerRemoving:Connect(function(p) lastTP[p] = nil end)
	tick()
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return BossPortalService
