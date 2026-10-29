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

-- Skip Rebirth (Developer Product, MonetizationService): наступний ребітх без вимоги й без скидання Money.
-- Якщо ліміт мапи вже досягнуто — покупка не губиться: RebirthSkips + 1, застосовується, щойно ліміт зросте (нова мапа).
local function applySkips(p: Player)
	local credits = tonumber(p:GetAttribute("RebirthSkips")) or 0
	if credits <= 0 then return end
	local n = tonumber(p:GetAttribute("Rebirths")) or 0
	local stage = tonumber(p:GetAttribute("Stage")) or 1
	local free = Cfg.rebirthLimit(stage) - n
	if free <= 0 then return end
	local use = math.min(free, credits)
	p:SetAttribute("Rebirths", n + use)
	p:SetAttribute("RebirthSkips", credits - use)
end
function RebirthService.SkipRebirth(p: Player): boolean
	p:SetAttribute("RebirthSkips", (tonumber(p:GetAttribute("RebirthSkips")) or 0) + 1)
	applySkips(p)
	return true
end

function RebirthService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("RebirthAction") or Instance.new("RemoteFunction")
	rf.Name = "RebirthAction"; rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onInvoke
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
	local function onPlayer(p: Player)
		p:GetAttributeChangedSignal("Stage"):Connect(function() applySkips(p) end)
		task.spawn(function()
			for _ = 1, 60 do if DataService.IsLoaded(p) then break end task.wait(1) end
			applySkips(p)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return RebirthService
