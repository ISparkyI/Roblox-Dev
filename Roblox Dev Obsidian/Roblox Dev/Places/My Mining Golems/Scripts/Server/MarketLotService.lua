--!nonstrict
-- MarketLotService — лоти продажу големів на маркеті і історія угод (03.11.2026). Де: ServerScriptService/MarketLotService (ModuleScript).
-- Запуск: MarketServerService.Start (лише в режимі маркету). Клієнт — StarterPlayerScripts/MarketUI (вікна Sell Golems / History)
--   і MarketLotsClient (големи-лоти ходять за продавцем).
-- Лот — голем інвентаря (InvGolems), виставлений на продаж: він ЛИШАЄТЬСЯ в InvGolems, але для інвентаря «не існує»
--   (InventoryService.exists дивиться на MktLots — немає в хотбарі, руці, сітці). Лоти живуть лише поки гравець на сервері
--   (вийшов — големи просто в інвентарі, нічого не втрачається).
-- Атрибути гравця: MktLots — JSON [{ id, p, c, t }] (id голема, ціна, валюта money|diamonds|tickets, час);
--   MktHistory — JSON { b = { … }, s = { … } } (куплені / продані, останні HISTORY_MAX; секція DataService "MarketHistory").
-- Remotes/MarketAction (RemoteFunction): ("List", { id, price, cur }) → { ok, err }; ("Unlist", { ids }) → { ok }.
--   Відмови err: "full" (ліміт HubConfig.marketSlots: 3, VIP +2, куплені +3), "golem" (немає / на плоті / вже виставлений), "price", "cur".
--   ("Buy", { seller = userId, id, p, c }) → { ok, err } — купівля чужого лота (03.11.2026): p / c — ціна й валюта, які бачив покупець
--     (змінились — "changed"). Атомарно (блокування продавця й покупця): −ціна покупцю, +ціна × (1 − MARKET_FEE) продавцю,
--     голем (той самий UID, новий id) з InvGolems продавця → InvGolems покупця (GolemRegistry.Move), лот знімається,
--     MarketServerService.LogTrade (RECENT TRADES, топи, History), SaveNow обом. Відмови: gone, busy, changed, money|diamonds|tickets, full.
-- Збереження лотів (03.11.2026): секція DataService "MarketLots" = { lots = [{ id, u (UID), p, c, t }] }. На маркеті — з атрибута MktLots;
--   у печері (M.StartMain) — старий список БЕЗ тих, чиїх големів уже немає (видалив, мутація, стенд печери) або які стоять на плоті
--   (PlotPlaced) — поставив вдома на плот — лот знімається. У печері виставлені големи доступні як звичайні.
--   При вході на маркет лоти відновлюються (перевірка: голем з тим самим id і UID є, не на плоті; не більше marketSlots).
-- MarketLotService.AddHistory(p, "b"|"s", entry) — запис у історію (викликає MarketServerService.LogTrade).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("HubConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local M = {}
local HISTORY_MAX = 100
local CURS = { money = true, diamonds = true, tickets = true }
local MAX_PRICE = 1e15

local function decode(p: Player, a: string, def: any): any
	local s = p:GetAttribute(a)
	if type(s) ~= "string" or s == "" then return def end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return (ok and type(v) == "table") and v or def
end
local function lots(p: Player): { any } return decode(p, "MktLots", {}) end
local function setLots(p: Player, t: { any }) p:SetAttribute("MktLots", HttpService:JSONEncode(t)) end

local function golemOf(p: Player, id: number): any
	for _, g in decode(p, "InvGolems", {}) do if type(g) == "table" and g.id == id then return g end end
	return nil
end
local function isPlaced(p: Player, id: number): boolean return table.find(decode(p, "PlotPlaced", {}), id) ~= nil end

-- прибрати лоти, чиїх големів уже немає в інвентарі
local function prune(p: Player)
	local t, keep = lots(p), {}
	for _, l in t do if type(l) == "table" and golemOf(p, l.id) then table.insert(keep, l) end end
	if #keep ~= #t then setLots(p, keep) end
end

local CUR_ATTR = { money = "Money", diamonds = "Diamonds", tickets = "Tickets" }
local busy: { [Player]: boolean } = {}
local function encodeAttr(p: Player, a: string, v: any) p:SetAttribute(a, HttpService:JSONEncode(v)) end
local function doBuy(buyer: Player, seller: Player, id: number, seenP: any, seenC: any): any
	local lot = M.GetLot(seller, id)
	if not lot then return { ok = false, err = "gone" } end
	if tonumber(seenP) ~= lot.p or seenC ~= lot.c then return { ok = false, err = "changed" } end
	local g = golemOf(seller, id)
	if not g or isPlaced(seller, id) then M.RemoveLot(seller, id); return { ok = false, err = "gone" } end
	local attr = CUR_ATTR[lot.c]
	local bal = tonumber(buyer:GetAttribute(attr)) or 0
	if bal < lot.p then return { ok = false, err = lot.c } end
	local okI, Items = pcall(require, RS.Shared:FindFirstChild("ItemConfig"))
	if okI and Items and Items.invGolemCount and Items.invGolemCount(decode(buyer, "InvGolems", {}), decode(buyer, "PlotPlaced", {})) >= Items.maxGolems(buyer) then
		return { ok = false, err = "full" }
	end
	-- новий id у покупця (більший за всі його големи, у т.ч. в секціях печери — CaveStandService.MaxId)
	local newId = 0
	local okC, Cave = pcall(require, script.Parent:FindFirstChild("CaveStandService"))
	if okC and Cave and Cave.MaxId then local okM, m = pcall(Cave.MaxId, buyer); if okM and type(m) == "number" then newId = m end end
	for _, x in decode(buyer, "InvGolems", {}) do if type(x) == "table" and type(x.id) == "number" then newId = math.max(newId, x.id) end end
	newId += 1
	-- перенесення
	local sl, keep = decode(seller, "InvGolems", {}), {}
	for _, x in sl do if not (type(x) == "table" and x.id == id) then table.insert(keep, x) end end
	local rec = table.clone(g)
	rec.id = newId
	local bl = decode(buyer, "InvGolems", {})
	table.insert(bl, rec)
	M.RemoveLot(seller, id)
	encodeAttr(seller, "InvGolems", keep)
	encodeAttr(buyer, "InvGolems", bl)
	buyer:SetAttribute(attr, bal - lot.p)
	local gain = math.floor(lot.p * (1 - (Cfg.MARKET_FEE or 0.1)))
	seller:SetAttribute(attr, (tonumber(seller:GetAttribute(attr)) or 0) + gain)
	local okR, Reg = pcall(require, script.Parent:FindFirstChild("GolemRegistry"))
	if okR and Reg and Reg.Move then pcall(Reg.Move, seller.UserId, buyer.UserId, rec, "market") end
	local okInv, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
	if okInv and Inv and Inv.Refresh then pcall(Inv.Refresh, seller) end
	local okS, MS = pcall(require, script.Parent:FindFirstChild("MarketServerService"))
	if okS and MS and MS.LogTrade then pcall(MS.LogTrade, seller, buyer, { kind = g.kind, cls = g.cls, mut = g.mut }, lot.p, lot.c) end
	task.spawn(function() pcall(DataService.SaveNow, seller); pcall(DataService.SaveNow, buyer) end)
	return { ok = true, gain = gain }
end

M._doBuy = doBuy -- для тестів з командного рядка / Play
local function onAction(p: Player, action: any, arg: any): any
	if action == "Buy" and type(arg) == "table" then
		local seller = Players:GetPlayerByUserId(tonumber(arg.seller) or 0)
		local id = tonumber(arg.id)
		if not seller or seller == p or not id or not DataService.IsLoaded(p) or not DataService.IsLoaded(seller) then return { ok = false, err = "gone" } end
		if busy[seller] or busy[p] then return { ok = false, err = "busy" } end
		busy[seller] = true; busy[p] = true
		local ok, res = pcall(doBuy, p, seller, id, arg.p, arg.c)
		busy[seller] = nil; busy[p] = nil
		if not ok then warn("MarketLotService.Buy: ", res); return { ok = false } end
		return res
	end
	if type(arg) ~= "table" or not DataService.IsLoaded(p) then return { ok = false } end
	if action == "List" then
		local id, price, cur = tonumber(arg.id), tonumber(arg.price), arg.cur
		if not CURS[cur] then return { ok = false, err = "cur" } end
		if not price or price ~= price or price < 1 or price > MAX_PRICE then return { ok = false, err = "price" } end
		if price < ((Cfg.MARKET_MIN_PRICE or {})[cur] or 1) then return { ok = false, err = "min" } end -- 04.11.2026: мінімальна ціна
		price = math.floor(price)
		local t = lots(p)
		if #t >= Cfg.marketSlots(p) then return { ok = false, err = "full" } end
		if not id or not golemOf(p, id) or isPlaced(p, id) then return { ok = false, err = "golem" } end
		local gg = golemOf(p, id)
		if Cfg.marketBlocked(gg.kind, gg.cls) then return { ok = false, err = "blocked" } end -- груповий голем не продається
		for _, l in t do if l.id == id then return { ok = false, err = "golem" } end end
		table.insert(t, { id = id, u = gg.uid, p = price, c = cur, t = os.time() })
		setLots(p, t)
		return { ok = true }
	elseif action == "Unlist" and type(arg.ids) == "table" then
		local t, keep = lots(p), {}
		for _, l in t do if not table.find(arg.ids, l.id) then table.insert(keep, l) end end
		setLots(p, keep)
		return { ok = true }
	end
	return { ok = false }
end

function M.AddHistory(p: Player, kind: string, e: any)
	if not (p and p.Parent) or (kind ~= "b" and kind ~= "s") then return end
	local h = decode(p, "MktHistory", { b = {}, s = {} })
	h.b = h.b or {}; h.s = h.s or {}
	table.insert(h[kind], 1, e)
	while #h[kind] > HISTORY_MAX do table.remove(h[kind]) end
	p:SetAttribute("MktHistory", HttpService:JSONEncode(h))
end

-- лот продано / знято (для торгівлі): прибрати з MktLots
function M.RemoveLot(p: Player, id: number)
	local t, keep = lots(p), {}
	for _, l in t do if l.id ~= id then table.insert(keep, l) end end
	setLots(p, keep)
end
function M.GetLot(p: Player, id: number): any
	for _, l in lots(p) do if l.id == id then return l end end
	return nil
end

-- збережені лоти, які досі дійсні (голем з тим самим id + UID є в InvGolems, не на плоті)
local function validLots(p: Player, list: any): { any }
	local out = {}
	if type(list) ~= "table" then return out end
	local seen = {}
	for _, l in list do
		if type(l) == "table" and type(l.id) == "number" and not seen[l.id] and CURS[l.c] and tonumber(l.p) then
			local g = golemOf(p, l.id)
			if g and (l.u == nil or l.u == g.uid) and not isPlaced(p, l.id) and not Cfg.marketBlocked(g.kind, g.cls) then
				seen[l.id] = true
				table.insert(out, { id = l.id, u = g.uid, p = math.floor(l.p), c = l.c, t = l.t })
			end
		end
	end
	return out
end

M._validLots = validLots -- для тестів
local function onPlayer(p: Player)
	setLots(p, {})
	if not DataService.WaitLoaded(p) then return end
	-- відновити лоти: спершу дочекатись InvGolems (InventoryService) і PlotPlaced (MarketServerService.markPlaced)
	local t0 = os.clock()
	while p.Parent and (p:GetAttribute("InvReady") ~= true or p:GetAttribute("PlotPlaced") == nil) and os.clock() - t0 < 10 do task.wait(0.2) end
	if not p.Parent then return end
	local ls = DataService.GetSection(p, "MarketLots")
	local restored = validLots(p, type(ls) == "table" and ls.lots or nil)
	while #restored > Cfg.marketSlots(p) do table.remove(restored) end
	setLots(p, restored)
	p:SetAttribute("MktLotsReady", true)
	local sec = DataService.GetSection(p, "MarketHistory")
	local h = { b = {}, s = {} }
	if type(sec) == "table" then
		if type(sec.b) == "table" then h.b = sec.b end
		if type(sec.s) == "table" then h.s = sec.s end
	end
	if p.Parent then p:SetAttribute("MktHistory", HttpService:JSONEncode(h)) end
	p:GetAttributeChangedSignal("InvGolems"):Connect(function() task.defer(prune, p) end)
	p:GetAttributeChangedSignal("PlotPlaced"):Connect(function()
		local t, keep = lots(p), {}
		for _, l in t do if not isPlaced(p, l.id) then table.insert(keep, l) end end
		if #keep ~= #t then setLots(p, keep) end
	end)
end

-- секція MarketLots: на маркеті — поточні лоти (MktLots), у печері — старі без недійсних
local function registerLots(market: boolean)
	DataService.RegisterSection("MarketLots", function(p: Player, old: any)
		if p:GetAttribute("InvReady") ~= true then return old end
		if market then
			if p:GetAttribute("MktLotsReady") ~= true then return old end -- ще не відновили — не затирати
			return { lots = lots(p) }
		end
		return { lots = validLots(p, type(old) == "table" and old.lots or nil) }
	end)
end
-- головний плейс (NicheBoot): лише збереження секції — поставив голема на плот / видалив — лот зникає
function M.StartMain()
	registerLots(false)
end

function M.Start()
	registerLots(true)
	-- історія зберігається лише з маркету (в печері секція не зареєстрована й лишається недоторканою)
	DataService.RegisterSection("MarketHistory", function(p: Player, old: any)
		local s = p:GetAttribute("MktHistory")
		if type(s) ~= "string" then return old end
		local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
		return (ok and type(v) == "table") and v or old
	end)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("MarketAction") or Instance.new("RemoteFunction")
	rf.Name = "MarketAction"; rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onAction
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return M
