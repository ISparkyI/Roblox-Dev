--!nonstrict
-- MonetizationService — покупки за Robux: Developer Products (ступені x2 Money) і геймпаси (VIP і т.д.).
-- Де: ServerScriptService/MonetizationService (ModuleScript). Запуск: NicheBoot (після DataService).
--
-- Пакети тікетів (MonetizationConfig.TicketProducts) і продукти (Products: Potion Pack) — багаторазові, ProcessReceipt;
--   Potion Pack за тікети — ShopAction "BuyProduct".
-- Ступені x2 Money: кожна покупка = наступний ступінь (атрибут DonateTier). ProductId ступеня — у MonetizationConfig.MoneyTierProducts.
-- ProcessReceipt: дублікати відсікаються по PurchaseId (в профілі останні 200), перед PurchaseGranted дані зберігаються (SaveNow).
-- Геймпаси: при вході перевіряємо власність (UserOwnsGamePassAsync) → атрибут Pass_<ім'я>; при покупці в грі — теж.
-- За тікети (магазин SHOP): RemoteFunction Remotes/ShopAction ("BuyTickets", ключ) → ціна MonetizationConfig.ticketPrice(robux),
--   −Tickets, Pass_<ключ> = true, SaveNow. Уже є — відмова. ("BuyTier") — наступний ступінь x2 Money за тікети (× 1,25).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local Items = require(RS:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local MonetizationService = {}
local MAX_RECEIPTS = 200

-- видати ступінь x2 Money (для покупок і тестів); повертає новий ступінь
function MonetizationService.GrantMoneyTier(p: Player, tier: number): number
	local cur = (p:GetAttribute("DonateTier") :: number?) or 0
	if tier > cur then
		p:SetAttribute("DonateTier", math.min(tier, MultiCfg.maxDonateTier()))
	else
		warn(("MonetizationService: %s купив ступінь %d, який вже є (%d)"):format(p.Name, tier, cur))
	end
	return p:GetAttribute("DonateTier")
end

local function tierOfProduct(productId: number): number?
	for tier, id in MonCfg.MoneyTierProducts do
		if id ~= 0 and id == productId then return tier end
	end
	return nil
end

-- багаторазові продукти (MonetizationConfig.Products): Potion Pack — по potions кожного зілля
function MonetizationService.GrantProduct(p: Player, key: string): boolean
	local d = MonCfg.Products[key]
	if not d then return false end
	if key == "StarterPack" then
		p:SetAttribute("Pass_StarterPack", true)
		p:SetAttribute("Money", ((tonumber(p:GetAttribute("Money")) or 0) :: number) + d.money)
		p:SetAttribute("Pot_Luck", ((tonumber(p:GetAttribute("Pot_Luck")) or 0) :: number) + d.luckPotions)
		local okI, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
		local okC, Cave = pcall(require, script.Parent:FindFirstChild("CaveStandService"))
		if okI and okC and Inv and Cave then
			local gid = Cave.MaxId(p) + 1
			local okA, added = pcall(Inv.AddGolem, p, gid, "stone", "miner", 4, "shop:starter", true) -- Diamond (mut 4) Stone Golem
			-- як після купівлі на підставці ролу: голем одразу в хотбарі (хотбар повний — лише в інвентарі)
			if okA and added and Inv.Pin then pcall(Inv.Pin, p, "Golem_" .. gid) end
		end
	elseif key == "MarketSlots" then -- +3 слоти лотів на маркеті, один раз (03.11.2026)
		p:SetAttribute("Pass_MarketSlots", true)
	elseif key == "ExtraStorage" then
		p:SetAttribute("ExtraSlots", ((tonumber(p:GetAttribute("ExtraSlots")) or 0) :: number) + d.slots)
	elseif d.skipMin then -- тайм-скіп: дохід за хвилину × хвилини
		local okI, Inc = pcall(require, script.Parent:FindFirstChild("IncomeService"))
		local rate = (okI and Inc and Inc.Rate) and Inc.Rate(p) or 100
		local add = math.floor(rate * d.skipMin)
		p:SetAttribute("Money", ((tonumber(p:GetAttribute("Money")) or 0) :: number) + add)
		p:SetAttribute("SkipGain", add); p:SetAttribute("SkipT", os.clock()) -- клієнт показує «+$…»
	elseif d.diamonds then -- пакет діамантів
		p:SetAttribute("Diamonds", ((tonumber(p:GetAttribute("Diamonds")) or 0) :: number) + d.diamonds)
	elseif d.cases then -- Exclusive Cases (03.11.2026): клас — вибраний у магазині перед оплатою (атрибут CaseBuyCls), інакше Exclusive (випадковий)
		local cls = p:GetAttribute("CaseBuyCls")
		local ck = (cls == "miner" and "Miner") or (cls == "carrier" and "Carrier") or (cls == "warrior" and "Warrior") or "Exclusive"
		if not Items.case(ck) then ck = "Exclusive" end
		local a = "Case_" .. ck
		p:SetAttribute(a, ((tonumber(p:GetAttribute(a)) or 0) :: number) + d.cases)
		-- куплений кейс одразу в руці (новий слот хотбара; хотбар повний — лише в інвентарі), 03.11.2026
		local okI, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
		if okI and Inv and Inv.Give then pcall(Inv.Give, p, a) end
	elseif d.luckRoll then -- Lucky Roll: +1 рол з удачею ×luckRoll
		local a = "LuckRoll" .. d.luckRoll
		p:SetAttribute(a, ((tonumber(p:GetAttribute(a)) or 0) :: number) + 1)
	elseif key == "PotionPack" then
		for _, pot in Items.POTIONS do
			local k = "Pot_" .. pot.key
			p:SetAttribute(k, ((tonumber(p:GetAttribute(k)) or 0) :: number) + d.potions)
		end
	end
	return true
end
-- Developer Product за id: ступінь x2 Money, пакет тікетів або продукт; false — невідомий
-- додатковий обробник продуктів з інших сервісів (GiftService: подарунки): fn(p, productId, receiptInfo) -> true/false або nil (не мій)
MonetizationService.ExtraGrant = nil
-- налагодження покупок (29.10.2026): рядок у вивід сервера і в консоль клієнта ВЛАСНИКА гри (у Team Test сервер у хмарі — його вивід не видно)
function MonetizationService.Debug(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
	local msg = table.concat(parts, " ")
	print(msg)
	local owner = Players:GetPlayerByUserId(game.CreatorId)
	local r = RS:FindFirstChild("Remotes")
	local ev = r and r:FindFirstChild("AdminBroadcast")
	if owner and ev then ev:FireClient(owner, "debug", { text = msg }) end
end
-- видати ефект Developer Product за id гравцеві p (без ExtraGrant; GiftService — для подарунків цілі)
local baseGrant
local function grantProductId(p: Player, productId: number, info: any?): boolean
	if MonetizationService.ExtraGrant then
		local r = MonetizationService.ExtraGrant(p, productId, info)
		if r ~= nil then return r end
	end
	return baseGrant(p, productId)
end
baseGrant = function(p: Player, productId: number): boolean
	local tier = tierOfProduct(productId)
	if tier then MonetizationService.GrantMoneyTier(p, tier); return true end
	for _, t in MonCfg.TicketProducts do
		if t.id ~= 0 and t.id == productId then
			p:SetAttribute("Tickets", ((tonumber(p:GetAttribute("Tickets")) or 0) :: number) + t.tickets)
			return true
		end
	end
	for key, d in MonCfg.Products do
		if d.id ~= 0 and d.id == productId then return MonetizationService.GrantProduct(p, key) end
	end
	-- скіп дня щоденних нагород (DailyConfig.SKIP 19 R$ / SKIP7 69 R$) — наступна нагорода одразу (29.10.2026)
	do
		local okD, DC = pcall(require, RS:WaitForChild("Shared"):WaitForChild("DailyConfig"))
		if okD and DC and (productId == DC.SKIP.id or productId == DC.SKIP7.id) then
			return require(script.Parent:WaitForChild("DailyService")).Skip(p)
		end
	end
	if MonCfg.RebirthSkip and MonCfg.RebirthSkip.id ~= 0 and MonCfg.RebirthSkip.id == productId then
		return require(script.Parent:WaitForChild("RebirthService")).SkipRebirth(p)
	end
	for tier, t in MonCfg.MUT_SPEED_TIERS do
		if t.id ~= 0 and t.id == productId then
			p:SetAttribute("MutSpeedTier", math.max(tonumber(p:GetAttribute("MutSpeedTier")) or 0, tier))
			return true
		end
	end
	return false
end
MonetizationService.GrantById = function(p: Player, productId: number): boolean return baseGrant(p, productId) end

local function checkPasses(p: Player)
	-- Studio (29.10.2026): атрибут скрипта StudioIgnoreOwned = true — не давати геймпаси за власністю Roblox (власник гри /
	-- покупець тестує як звичайний гравець; в Studio без доступу до API дані з PassOff не зберігаються). У грі не діє.
	if game:GetService("RunService"):IsStudio() and script:GetAttribute("StudioIgnoreOwned") == true then return end
	for name, def in MonCfg.Passes do
		if def.id ~= 0 then
			local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(p.UserId, def.id) end)
			-- PassOff_<ключ> — геймпас знято через адмін-панель: не повертаємо (29.10.2026)
			if ok and owns and p:GetAttribute("PassOff_" .. name) ~= true then p:SetAttribute("Pass_" .. name, true) end
		end
	end
end

local shopBusy: { [Player]: boolean } = {}
-- ("BuyTickets", ключ геймпаса) — геймпас за тікети; ("BuyTier") — наступний ступінь x2 Money за тікети (ціна ступеня × 1,25)
local function onShop(p: Player, action: any, key: any): any
	-- клас кейса перед вікном оплати (SHOP → CASES, 03.11.2026); ProcessReceipt бере його з атрибута CaseBuyCls
	if action == "CaseClass" then
		if key == "miner" or key == "carrier" or key == "warrior" then p:SetAttribute("CaseBuyCls", key); return { ok = true } end
		return { ok = false }
	end
	if shopBusy[p] or not DataService.IsLoaded(p) then return { ok = false } end
	local price, grant
	if action == "BuyTickets" and type(key) == "string" then
		local def = MonCfg.Passes[key]
		if not def then return { ok = false } end
		if p:GetAttribute("Pass_" .. key) == true then return { ok = false, err = "owned" } end
		if def.requires and p:GetAttribute("Pass_" .. def.requires) ~= true then return { ok = false, err = "requires" } end
		price = MonCfg.ticketPrice(def.robux)
		grant = function() p:SetAttribute("Pass_" .. key, true); p:SetAttribute("PassOff_" .. key, nil) end
	elseif action == "BuyProduct" and type(key) == "string" then
		local d = MonCfg.Products[key]
		if not d or d.diamonds then return { ok = false } end -- діаманти — лише за Robux; кейси — і за тікети (03.11.2026, клас — CaseBuyCls)
		if d.once and p:GetAttribute("Pass_" .. key) == true then return { ok = false, err = "owned" } end
		price = MonCfg.ticketPrice(d.robux)
		grant = function() MonetizationService.GrantProduct(p, key) end
	elseif action == "BuyTier" then
		local nxt = ((tonumber(p:GetAttribute("DonateTier")) or 0) :: number) + 1
		local t = MultiCfg.DONATE_TIERS[nxt]
		if not t then return { ok = false, err = "max" } end
		price = MonCfg.ticketPrice(t.price)
		grant = function() MonetizationService.GrantMoneyTier(p, nxt) end
	else
		return { ok = false }
	end
	shopBusy[p] = true
	local tk = tonumber(p:GetAttribute("Tickets")) or 0
	if tk < price then shopBusy[p] = nil; return { ok = false, err = "tickets" } end
	p:SetAttribute("Tickets", tk - price)
	grant()
	task.spawn(function() pcall(DataService.SaveNow, p) end)
	shopBusy[p] = nil
	return { ok = true }
end

function MonetizationService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("ShopAction") or Instance.new("RemoteFunction")
	rf.Name = "ShopAction"; rf.Parent = remotes
	rf.OnServerInvoke = onShop
	Players.PlayerRemoving:Connect(function(p) shopBusy[p] = nil end)
	MarketplaceService.ProcessReceipt = function(info)
		MonetizationService.Debug("[Receipt] in", info.PlayerId, info.ProductId)
		local p = Players:GetPlayerByUserId(info.PlayerId)
		if not p or not DataService.WaitLoaded(p) then MonetizationService.Debug("[Receipt] no player / not loaded"); return Enum.ProductPurchaseDecision.NotProcessedYet end
		local data = DataService.GetData(p)
		if not data then MonetizationService.Debug("[Receipt] no data"); return Enum.ProductPurchaseDecision.NotProcessedYet end
		MonetizationService.Debug("[Receipt]", p.Name, info.ProductId, "spent", info.CurrencySpent, "purchase", info.PurchaseId)
		local id = tostring(info.PurchaseId)
		if not table.find(data.receipts, id) then
			local granted = grantProductId(p, info.ProductId, info)
			MonetizationService.Debug("[Receipt] granted", granted)
			if not granted then
				warn("MonetizationService: невідомий ProductId " .. tostring(info.ProductId))
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			table.insert(data.receipts, id)
			while #data.receipts > MAX_RECEIPTS do table.remove(data.receipts, 1) end
			-- статистика: витрачені Robux (лідерборд TOP DONATORS, StatsService); геймпаси рахує StatsService сам
			p:SetAttribute("Stat_RobuxSpent", (tonumber(p:GetAttribute("Stat_RobuxSpent")) or 0) + math.max(0, tonumber(info.CurrencySpent) or 0))
		end
		local saved = DataService.SaveNow(p)
		MonetizationService.Debug("[Receipt] saved", saved)
		if saved then return Enum.ProductPurchaseDecision.PurchaseGranted end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
		if not purchased then return end
		for name, def in MonCfg.Passes do
			if def.id ~= 0 and def.id == passId then
				p:SetAttribute("Pass_" .. name, true)
				p:SetAttribute("PassOff_" .. name, nil)
				task.spawn(DataService.SaveNow, p)
			end
		end
	end)

	local function onPlayer(p: Player)
		if DataService.WaitLoaded(p) then checkPasses(p) end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return MonetizationService
