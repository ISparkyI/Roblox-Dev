--!strict
-- RebirthService — ребітхи (GDD - Currencies and Rebirths). Вікно — StarterPlayerScripts/RebirthWindow (кнопка Rebirth у HUD).
-- Де: ServerScriptService/RebirthService (ModuleScript), запускає NicheBoot. RemoteFunction Remotes/RebirthAction: ("Rebirth") → { ok, err? }.
-- Перевірки: Money ≥ ціни наступного ребітху (MultiConfig.rebirthPrice), Rebirths < ліміту мапи (MultiConfig.rebirthLimit(Stage)).
-- Ребітх: Money = 0 (скидаються ВСІ гроші, решта лишається), Rebirths + 1 → MultiService перераховує множник (2^Rebirths).
-- Збереження: Money і Rebirths — атрибути DataService; одразу SaveNow.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local RebirthService = {}
local last: { [Player]: number } = {}

local function onInvoke(p: Player, action: any): any
	if action ~= "Rebirth" then return { ok = false } end
	if not DataService.IsLoaded(p) then return { ok = false, err = "loading" } end
	local t = os.clock()
	if last[p] and t - last[p] < 1 then return { ok = false, err = "wait" } end
	last[p] = t
	local n = tonumber(p:GetAttribute("Rebirths")) or 0
	local stage = tonumber(p:GetAttribute("Stage")) or 1
	if n >= Cfg.rebirthLimit(stage) then return { ok = false, err = "limit" } end
	local price = Cfg.rebirthPrice(n + 1)
	local money = tonumber(p:GetAttribute("Money")) or 0
	if money < price then return { ok = false, err = "money" } end
	p:SetAttribute("Money", 0)
	p:SetAttribute("Rebirths", n + 1)
	task.spawn(function() pcall(DataService.SaveNow, p) end)
	return { ok = true, rebirths = n + 1 }
end

function RebirthService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("RebirthAction") or Instance.new("RemoteFunction")
	rf.Name = "RebirthAction"; rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onInvoke
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end

return RebirthService
