--!strict
-- CaseService — відкриття кейсів з інвентаря (02.11.2026). Де: ServerScriptService/CaseService (ModuleScript), запуск — NicheBoot.
-- Кейс — стаковий предмет Case_<ключ> (ItemConfig.CASES; зберігає InventoryService, секція Inventory, поле cases).
-- Дія: Remotes/CaseAction:FireServer("Open", "Case_Exclusive").
--   Перевірки: є кейс, інвентар готовий і не повний, не частіше за COOLDOWN (анімація йде ~7 с, але клієнт ставить відкриття в чергу).
--   Рол: зважений за GolemCatalog.caseChance серед M.EXCLUSIVES з exclusive = "case" (Coral 88,9 / Jade 8 / Storm 2 / Phantom 1 / Chrono 0,1 %).
--   Клас — випадковий (Miner / Carrier / Warrior по 1/3), мутація — завжди Normal.
--   Успіх: Case_<ключ> − 1, InventoryService.AddGolem(…, "case"), клієнту — Remotes/CaseResult { ok, case, kind, cls, mut, fakes }
--   (fakes — големи для «рулетки» анімації CaseOpenClient). Відмова — { ok = false, why = "full" | "none" | "busy" }.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local CaveStandService = require(script.Parent:WaitForChild("CaveStandService"))

local CaseService = {}
local COOLDOWN = 1.5
local CLASSES = { "miner", "carrier", "warrior" }
local rnd = Random.new()
local last: { [Player]: number } = {}
local resultEv: RemoteEvent

-- големи кейсу: { id, w } у порядку EXCLUSIVES
function CaseService.pool(caseKey: string?): { any }
	local t = {}
	for _, id in Catalog.EXCLUSIVES or {} do
		local g = Catalog.GOLEMS[id]
		if g and g.exclusive == "case" and (tonumber(g.caseChance) or 0) > 0 then table.insert(t, { id = id, w = g.caseChance }) end
	end
	return t
end

function CaseService.roll(caseKey: string?): string?
	local pool = CaseService.pool(caseKey)
	local sum = 0
	for _, e in pool do sum += e.w end
	if sum <= 0 then return nil end
	local x = rnd:NextNumber() * sum
	for _, e in pool do
		x -= e.w
		if x <= 0 then return e.id end
	end
	return pool[#pool].id
end

local function invFull(p: Player): boolean
	local function dec(a: string): any
		local s = p:GetAttribute(a)
		if type(s) ~= "string" or s == "" then return {} end
		local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
		return ok and v or {}
	end
	return Items.invGolemCount(dec("InvGolems"), dec("PlotPlaced")) >= Items.maxGolems(p)
end

local function open(p: Player, key: any)
	if type(key) ~= "string" or string.sub(key, 1, 5) ~= "Case_" or not Items.case(string.sub(key, 6)) then return end
	if p:GetAttribute("InvReady") ~= true then return end
	local now = os.clock()
	if now - (last[p] or 0) < COOLDOWN then resultEv:FireClient(p, { ok = false, why = "busy" }); return end
	local n = math.floor(tonumber(p:GetAttribute(key)) or 0)
	if n <= 0 then resultEv:FireClient(p, { ok = false, why = "none" }); return end
	if invFull(p) then resultEv:FireClient(p, { ok = false, why = "full" }); return end
	local kind = CaseService.roll(string.sub(key, 6))
	if not kind then return end
	last[p] = now
	local cls = CLASSES[rnd:NextInteger(1, #CLASSES)]
	local id = CaveStandService.MaxId(p) + 1
	if not InventoryService.AddGolem(p, id, kind, cls, 0, "case") then
		resultEv:FireClient(p, { ok = false, why = "full" })
		return
	end
	p:SetAttribute(key, n - 1)
	-- «рулетка»: випадкові големи кейсу (рівноймовірно, щоб було видно всіх), сусідні не повторюються, останній ≠ результат
	local pool = CaseService.pool(string.sub(key, 6))
	local fakes, prev = {}, nil
	for i = 1, 11 do
		local pick
		for _ = 1, 10 do
			pick = pool[rnd:NextInteger(1, #pool)].id
			if pick ~= prev and not (i == 11 and pick == kind) then break end
		end
		table.insert(fakes, pick)
		prev = pick
	end
	resultEv:FireClient(p, { ok = true, case = key, kind = kind, cls = cls, mut = 0, fakes = fakes })
end

function CaseService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("CaseAction") or Instance.new("RemoteEvent")
	ev.Name = "CaseAction"; ev.Parent = remotes
	local res = remotes:FindFirstChild("CaseResult") or Instance.new("RemoteEvent")
	res.Name = "CaseResult"; res.Parent = remotes
	resultEv = res :: RemoteEvent
	;(ev :: RemoteEvent).OnServerEvent:Connect(function(p, action, arg)
		if action == "Open" then open(p, arg) end
	end)
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end

return CaseService
