-- MarketplaceTeleport — телепорт з кола Marketplace (Workspace/Cave/Hub/Marketplace) на інший сервер (місце HubConfig.MARKETPLACE_PLACE_ID).
-- Де: ServerScriptService/MarketplaceTeleport (Script). Клієнт — StarterPlayerScripts/MarketplaceClient (відлік 3 с, банер).
-- Remotes/MarketplaceTP (RemoteFunction): сервер перевіряє, що гравець стоїть у колі, і робить TeleportAsync.
--   Відповідь: { ok = true } | { ok = false, reason = "soon" | "far" | "busy" | "fail" }.
-- Поки MARKETPLACE_PLACE_ID = 0 (місця немає) — "soon", клієнт показує тост.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("HubConfig"))

local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"; remotes.Parent = RS
local rf = remotes:FindFirstChild("MarketplaceTP") or Instance.new("RemoteFunction")
rf.Name = "MarketplaceTP"; rf.Parent = remotes

local busy: { [Player]: number } = {}
local function inRing(p: Player): boolean
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local center = hub and hub:FindFirstChild("Marketplace") and hub.Marketplace:FindFirstChild("RingCenter", true)
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not (center and hrp) then return false end
	local d = hrp.Position - center.Position
	return Vector2.new(d.X, d.Z).Magnitude <= Cfg.MARKET_RING_R + 2.5 and math.abs(d.Y) < 10
end

rf.OnServerInvoke = function(p: Player)
	if busy[p] and os.clock() - busy[p] < 5 then return { ok = false, reason = "busy" } end
	if not inRing(p) then return { ok = false, reason = "far" } end
	if (Cfg.MARKETPLACE_PLACE_ID or 0) == 0 then return { ok = false, reason = "soon" } end
	busy[p] = os.clock()
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Cfg.MARKETPLACE_PLACE_ID, { p })
	end)
	if not ok then warn("MarketplaceTeleport: ", err); busy[p] = nil; return { ok = false, reason = "fail" } end
	return { ok = true }
end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
