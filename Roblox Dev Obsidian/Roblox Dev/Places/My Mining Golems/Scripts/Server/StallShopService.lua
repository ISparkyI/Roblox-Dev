--!nonstrict
-- StallShopService — лавки Diamonds Shop і Events Shop у кінці зали (Workspace/Cave/Shops). 29.10.2026. GDD - Diamonds Shop.
-- Де: ServerScriptService/StallShopService (ModuleScript). Запуск: NicheBoot. Конфіг — Shared/StallShopConfig.
-- Стан — ReplicatedStorage/StallShops (Folder), атрибути: DiaLots (JSON [{id, kind = "skip"|"pass", key, min?, pass?, rarity, price,
--   stock, max}]), DiaNextAt (час наступного оновлення), EventNextAt. Запас — спільний на сервер.
-- Купівля: Remotes/StallShopAction (RemoteFunction) ("BuyDia", lotId) → { ok, err?, gain? }: запас > 0, діамантів вистачає,
--   геймпаса ще немає → −Diamonds, видача (скіп: Money += IncomeService.Rate × хвилини; геймпас: Pass_<ключ> = true), −1 запас,
--   SaveNow; голем-продавець радіє монеті (атрибут BuySeq моделі лавки, SellClient).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("StallShopConfig"))
local MonCfg = require(RS.Shared:WaitForChild("MonetizationConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local Service = {}
local state: Folder
local lots = {}
local period = -1
local rng = Random.new()

local function pickWeighted(list, wf)
	local total = 0
	for _, e in list do total += wf(e) end
	local r = rng:NextNumber() * total
	for _, e in list do
		r -= wf(e)
		if r <= 0 then return e end
	end
	return list[#list]
end

local function publish()
	state:SetAttribute("DiaLots", HttpService:JSONEncode(lots))
end

local function restock()
	lots = {}
	local n = pickWeighted(Cfg.KINDS, function(e) return e[2] end)[1]
	local pool = table.clone(Cfg.SKIPS)
	local chosen = {}
	for _ = 1, math.min(n, #pool) do
		local s = pickWeighted(pool, function(e) return e.w end)
		table.remove(pool, table.find(pool, s))
		table.insert(chosen, s)
	end
	table.sort(chosen, function(a, b) return a.min < b.min end)
	for i, s in chosen do
		local q = rng:NextInteger(s.qty[1], s.qty[2])
		table.insert(lots, { id = i, kind = "skip", key = s.key, min = s.min, rarity = s.rarity, price = s.price, stock = q, max = q })
	end
	if rng:NextNumber() < Cfg.RARE.chance then
		local r = pickWeighted(Cfg.RARE.list, function(e) return e.w end)
		table.insert(lots, { id = #lots + 1, kind = "pass", key = r.pass, pass = r.pass, rarity = "Pass", price = r.price, stock = 1, max = 1 })
	end
	publish()
end

local function tick()
	local now = os.time()
	local p = Cfg.periodOf(now, Cfg.DIA_RESTOCK)
	if p ~= period then
		period = p
		restock()
	end
	state:SetAttribute("DiaNextAt", Cfg.nextAt(now, Cfg.DIA_RESTOCK))
	state:SetAttribute("EventNextAt", Cfg.nextAt(now, Cfg.EVENT_RESTOCK))
end

local busy: { [Player]: boolean } = {}
local function onAction(p: Player, action: any, id: any): any
	if action ~= "BuyDia" or type(id) ~= "number" then return { ok = false } end
	if busy[p] or not DataService.IsLoaded(p) then return { ok = false } end
	local lot = nil
	for _, l in lots do if l.id == id then lot = l end end
	if not lot then return { ok = false, err = "gone" } end
	if lot.stock <= 0 then return { ok = false, err = "soldout" } end
	if lot.kind == "pass" and p:GetAttribute("Pass_" .. lot.pass) == true then return { ok = false, err = "owned" } end
	local dia = tonumber(p:GetAttribute("Diamonds")) or 0
	if dia < lot.price then return { ok = false, err = "diamonds" } end
	busy[p] = true
	p:SetAttribute("Diamonds", dia - lot.price)
	lot.stock -= 1
	local gain = 0
	if lot.kind == "skip" then
		local okI, Inc = pcall(require, script.Parent:FindFirstChild("IncomeService"))
		local rate = (okI and Inc and Inc.Rate) and Inc.Rate(p) or 100
		gain = math.floor(rate * lot.min)
		p:SetAttribute("Money", (tonumber(p:GetAttribute("Money")) or 0) + gain)
		p:SetAttribute("SkipGain", gain); p:SetAttribute("SkipT", os.clock())
	else
		p:SetAttribute("Pass_" .. lot.pass, true)
		p:SetAttribute("PassOff_" .. lot.pass, nil)
	end
	publish()
	local shop = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Shops") and workspace.Cave.Shops:FindFirstChild("DiamondShop")
	if shop then shop:SetAttribute("BuySeq", (tonumber(shop:GetAttribute("BuySeq")) or 0) + 1) end
	task.spawn(function() pcall(DataService.SaveNow, p) end)
	busy[p] = nil
	return { ok = true, gain = gain, kind = lot.kind }
end

function Service.Start()
	state = RS:FindFirstChild("StallShops") or Instance.new("Folder")
	state.Name = "StallShops"; state.Parent = RS
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("StallShopAction") or Instance.new("RemoteFunction")
	rf.Name = "StallShopAction"; rf.Parent = remotes
	rf.OnServerInvoke = onAction
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
	tick()
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(tick)
		end
	end)
end

return Service
