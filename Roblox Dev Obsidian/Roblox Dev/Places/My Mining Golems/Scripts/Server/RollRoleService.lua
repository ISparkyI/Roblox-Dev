-- RollRoleService — вибір типу голема для ролу (картки на екрані станції ролу в ніші).
-- Клієнт (StarterPlayerScripts/RollStationClient): Remotes.RollRole:FireServer("Miner" | "Carrier").
-- Сервер пише атрибут гравця RollRole (зберігає DataService, global). Warrior заблокований до другої карти (Stage >= 2).
-- Важіль (LeverScript) передає роль у Pulled(player, role).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local remote = RS:WaitForChild("Remotes"):WaitForChild("RollRole")

local ROLES = {
	Miner = function() return true end,
	Carrier = function() return true end,
	Warrior = function(p) return (tonumber(p:GetAttribute("Stage")) or 1) >= 2 end, -- MAP 2
}
local last = {}

remote.OnServerEvent:Connect(function(p, role)
	if type(role) ~= "string" then return end
	local ok = ROLES[role]
	if not ok or not ok(p) then return end
	local t = os.clock()
	if last[p] and t - last[p] < 0.2 then return end
	last[p] = t
	p:SetAttribute("RollRole", role)
end)

Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
