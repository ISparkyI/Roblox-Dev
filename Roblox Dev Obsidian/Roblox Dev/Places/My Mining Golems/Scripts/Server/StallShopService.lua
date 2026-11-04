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
	-- завжди Cfg.LOTS (4) випадкових лоти (29.10.2026): зілля й геймпас (коли випали) займають місце, решта — скіпи
	local pt = rng:NextNumber() < Cfg.POTION_CHANCE and pickWeighted(Cfg.POTIONS, function(e) return e.w end) or nil
	local rp = rng:NextNumber() < Cfg.RARE.chance and pickWeighted(Cfg.RARE.list, function(e) return e.w end) or nil
	local n = (Cfg.LOTS or 4) - (pt and 1 or 0) - (rp and 1 or 0)
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
	-- зілля (29.10.2026): іноді один лот; ціна для гравця — Cfg.potionPrice(price, мапа гравця)
	if pt then
		local q = rng:NextInteger(pt.qty[1], pt.qty[2])
		table.insert(lots, { id = #lots + 1, kind = "potion", key = "Pot_" .. pt.key, potion = pt.key, rarity = "Potion", price = pt.price, stock = q, max = q })
	end
	if rp then
		local r = rp
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
-- телепорти з HUD (кнопки SHOP / HOME / MARKET зверху по центру, TeleportHUD, 29.10.2026): Remotes/StallShopAction ("Teleport", ціль)
--   "shop" — перед лавками DIAMONDS / EVENTS SHOP (Cave/Hub/Shops) обличчям до них; "home" — на PlotSpawn своєї ніші (NicheService.TeleportHome);
--   "market" — у центр кола Marketplace, трохи в повітрі (гравець приземляється — відразу починається відлік переходу, MarketplaceClient).
local tpAt: { [Player]: number } = {}
local function floorAt(pos: Vector3, char: Model): Vector3
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char }
	local hit = workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), rp)
	return hit and hit.Position or pos
end
local function teleport(p: Player, target: any): any
	if os.clock() - (tpAt[p] or 0) < 1.5 then return { ok = false, err = "busy" } end
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum and hum.Health > 0) then return { ok = false, err = "fail" } end
	if target == "home" then
		local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
		if not (okN and NS and NS.TeleportHome) then return { ok = false, err = "fail" } end
		tpAt[p] = os.clock()
		p:SetAttribute("InBossArena", nil) -- вдома — уже не на арені боса
		NS.TeleportHome(p)
		return { ok = true }
	end
	local cave = workspace:FindFirstChild("Cave")
	local at: Vector3?, look: Vector3?
	local lift = 0 -- додаткова висота над підлогою (Marketplace — падає в коло)
	if target == "shop" then
		-- 03.11.2026: лавки тепер у Cave/Hub/Shops; ставимо ПЕРЕД обома лавками (посередині між колами DIAMONDS і EVENTS, на 12 стадів ближче
		--   до центру зали), обличчям до лавок — не в коло, щоб вікно лавки не відкривалось саме
		local shops = cave and ((cave:FindFirstChild("Hub") and cave.Hub:FindFirstChild("Shops")) or cave:FindFirstChild("Shops"))
		local a = shops and shops:FindFirstChild("DiamondShop")
		local b = shops and shops:FindFirstChild("EventShop")
		local ra = a and a:FindFirstChild("RingCenter", true)
		local rb = b and b:FindFirstChild("RingCenter", true)
		if ra and rb and ra:IsA("BasePart") and rb:IsA("BasePart") then
			local mid = (ra.Position + rb.Position) / 2
			local shopMid = (a:GetPivot().Position + b:GetPivot().Position) / 2
			local dir = Vector3.new(mid.X - shopMid.X, 0, mid.Z - shopMid.Z)
			dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
			at = mid + dir * 12; look = shopMid
		end
	elseif target == "market" then
		local mk = cave and cave:FindFirstChild("Hub") and cave.Hub:FindFirstChild("Marketplace")
		if mk then
			local rc = mk:FindFirstChild("RingCenter", true)
			local c = (rc and rc:IsA("BasePart")) and rc.Position or mk:GetPivot().Position
			at = c; look = c + Vector3.new(0, 0, 10); lift = 4
		end
	end
	if not at or not look then return { ok = false, err = "fail" } end
	tpAt[p] = os.clock()
	local g = floorAt(at, char :: Model)
	local pos = g + Vector3.new(0, hum.HipHeight + hrp.Size.Y / 2 + 0.3 + lift, 0)
	-- StreamingEnabled: спершу підвантажити місце призначення (до 2 с), потім переносити — без «пролагів» (03.11.2026)
	pcall(function() p:RequestStreamAroundAsync(pos, 2) end)
	if p.Character ~= char then return { ok = false, err = "fail" } end
	char:PivotTo(CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)))
	hrp.AssemblyLinearVelocity = Vector3.zero
	return { ok = true }
end
local function onAction(p: Player, action: any, id: any): any
	if action == "Teleport" then return teleport(p, id) end
	if action ~= "BuyDia" or type(id) ~= "number" then return { ok = false } end
	if busy[p] or not DataService.IsLoaded(p) then return { ok = false } end
	local lot = nil
	for _, l in lots do if l.id == id then lot = l end end
	if not lot then return { ok = false, err = "gone" } end
	if lot.stock <= 0 then return { ok = false, err = "soldout" } end
	if lot.kind == "pass" and p:GetAttribute("Pass_" .. lot.pass) == true then return { ok = false, err = "owned" } end
	local price = lot.kind == "potion" and Cfg.potionPrice(lot.price, p:GetAttribute("Stage")) or lot.price -- зілля дорожчають з мапою
	local dia = tonumber(p:GetAttribute("Diamonds")) or 0
	if dia < price then return { ok = false, err = "diamonds" } end
	busy[p] = true
	p:SetAttribute("Diamonds", dia - price)
	lot.stock -= 1
	local gain = 0
	if lot.kind == "skip" then
		local okI, Inc = pcall(require, script.Parent:FindFirstChild("IncomeService"))
		local rate = (okI and Inc and Inc.Rate) and Inc.Rate(p) or 100
		gain = math.floor(rate * lot.min)
		p:SetAttribute("Money", (tonumber(p:GetAttribute("Money")) or 0) + gain)
		p:SetAttribute("SkipGain", gain); p:SetAttribute("SkipT", os.clock())
	elseif lot.kind == "potion" then
		local k = "Pot_" .. lot.potion
		p:SetAttribute(k, (tonumber(p:GetAttribute(k)) or 0) + 1)
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
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil; tpAt[p] = nil end)
	tick()
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(tick)
		end
	end)
end

return Service
