--!strict
-- MapService — перехід гравця на наступну мапу (GDD - Maps). 29.10.2026.
-- Де: ServerScriptService/MapService (ModuleScript). Запуск: NicheBoot (після PlotService / InventoryService).
-- Кнопка MAP N на табло Cave_Upgrade (клієнт MapBoard) → Remotes/MapAction ("Next") → тут:
--   умови: своя ніша, біля табла, прокачка плотів 100 % (усі картки, відкриті на цій мапі, на максимумі — атрибут PlotLv),
--   є префаб наступної мапи (ForgeConfig.MAX_STAGE).
--   скидання (GDD): големи інвентаря (крім Exclusive; стенди печери й машини мутацій лишаються) — InventoryService.ResetForNewMap;
--   Money, RollStands, руда й злитки (Ore_*, Bars_*), секція Forge — DataService.ResetStageScope (+ подія StageReset:
--   PlotService скидає картки й ящики, RollService — підставки); Stage + 1 → ніша перебудовується з NichePrefab_Stage<N>
--   (NicheService.Rebuild), кузня (Workshop) засинає — будиться рудою нової мапи (ForgeConfig.WAKE). Зілля лишаються.
-- Відповідь клієнту: Remotes/MapAction:FireClient(p, "Done", stage) | ("Deny", причина).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PlotCfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local Forge = require(RS.Shared:WaitForChild("ForgeConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local NicheService = require(script.Parent:WaitForChild("NicheService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local MapService = {}
local BOARD_REACH = 70 -- стадів від екрана табла
local busy: { [Player]: boolean } = {}
local ev: RemoteEvent

local function progress(p: Player): number
	local lv = {}
	local raw = p:GetAttribute("PlotLv")
	if type(raw) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(t) == "table" then lv = t end
	end
	local stage = tonumber(p:GetAttribute("Stage")) or 1
	local sum, n = 0, 0
	for _, key in PlotCfg.CARD_ORDER do
		local def = PlotCfg.CARDS[key]
		if def and PlotCfg.cardOpen(key, stage) and def.max > 1 and not def.optional then -- Auto Sell (optional) не обов'язковий
			local l = math.clamp(math.floor(tonumber(lv[key]) or 1), 1, def.max)
			sum += (l - 1) / (def.max - 1); n += 1
		end
	end
	return n > 0 and sum / n or 0
end

local function nearBoard(p: Player, niche: Model): boolean
	local ups = niche:FindFirstChild("Upgrade panels")
	local board = ups and ups:FindFirstChild("Cave_Upgrade")
	local screen = board and board:FindFirstChild("screen")
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (screen and screen:IsA("BasePart") and hrp) then return false end
	return (hrp.Position - screen.Position).Magnitude <= BOARD_REACH
end

-- перейти на наступну мапу (force — адмін / тест: без умов прокачки й відстані)
function MapService.Advance(p: Player, force: boolean?): (boolean, string?)
	if busy[p] then return false, "busy" end
	if not DataService.IsLoaded(p) then return false, "loading" end
	local niche = NicheService.GetNiche(p)
	if not niche then return false, "niche" end
	local stage = tonumber(p:GetAttribute("Stage")) or 1
	if stage >= Forge.MAX_STAGE then return false, "soon" end
	if not force then
		if progress(p) < 1 - 1e-6 then return false, "plots" end
		if not nearBoard(p, niche) then return false, "far" end
	end
	busy[p] = true
	local ok, err = pcall(function()
		InventoryService.ResetForNewMap(p)
		p:SetAttribute("Stage", stage + 1)
		DataService.ResetStageScope(p)
		NicheService.Rebuild(p)
	end)
	busy[p] = nil
	if not ok then warn("MapService: " .. tostring(err)); return false, "error" end
	task.spawn(function() pcall(DataService.SaveNow, p) end)
	return true
end

function MapService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local e = remotes:FindFirstChild("MapAction") :: RemoteEvent?
	if not e then
		local n = Instance.new("RemoteEvent"); n.Name = "MapAction"; n.Parent = remotes
		e = n
	end
	ev = e :: RemoteEvent
	ev.OnServerEvent:Connect(function(p: Player, action: any)
		if action ~= "Next" then return end
		local ok, why = MapService.Advance(p)
		if ok then ev:FireClient(p, "Done", p:GetAttribute("Stage")) else ev:FireClient(p, "Deny", why) end
	end)
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
	-- для адмін-панелі / тестів у Studio: ServerScriptService.MapService.Advance:Invoke(player, force)
	local bf = script:FindFirstChild("Advance") or Instance.new("BindableFunction")
	bf.Name = "Advance"; bf.Parent = script
	;(bf :: BindableFunction).OnInvoke = function(p: Player, force: boolean?) return MapService.Advance(p, force) end
end

return MapService
