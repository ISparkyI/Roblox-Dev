--!strict
-- GolemGiftService — сервер подарунків големів у лобі (05.11.2026, GDD/Plan - Golem Gifting). Правила — Shared/GolemGiftConfig.
-- Де: ServerScriptService/GolemGiftService (ModuleScript). Запуск: NicheBoot (лобі, після MarketLotService.StartMain).
-- Remotes/GolemGift (RemoteFunction):
--   ("Gift", { to = UserId, id = id голема, uid = UID }) → { ok, pending?, err?, msg? } — 06.11.2026: голем НЕ передається одразу,
--     а створюється пропозиція: отримувачу — Remotes/GolemGiftOffer (RemoteEvent) { oid, from, fromName, kind, cls, mut };
--     у нього вікно GIFT FOR YOU! (ACCEPT / DECLINE). Один гравець — одна пропозиція (як дарувальник і як отримувач).
--   ("Respond", { oid, accept }) — відповідь отримувача: ACCEPT → передача (усе перевіряється ще раз), DECLINE — дарувальнику тост.
--   Без відповіді Cfg.ACCEPT_TIME с — скасовано (дарувальнику тост, у отримувача вікно закривається: GolemGiftOffer { close = oid }).
-- Хто може дарувати отримувачу — його налаштування Set_GiftMode ("all" | "friends" | "none"); дружба — Player:IsFriendsWith (кеш).
-- Передача (як купівля лота на маркеті, MarketLotService): голем з тим самим UID і новим id (більшим за всі id отримувача,
--   разом зі стендами печери — CaveStandService.MaxId) з InvGolems дарувальника → InvGolems отримувача; GolemRegistry.Move
--   (журнал + глобальний індекс), InventoryService.Refresh (рука, хотбар, замки дарувальника), GiftCD = зараз + COOLDOWN,
--   SaveNow обом, тости обом (Remotes/AdminBroadcast "toast"). Поки йде передача — обидва гравці «зайняті» (busy).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local Cfg = require(Shared:WaitForChild("GolemGiftConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local M = {}
local busy: { [Player]: boolean } = {}
local offers: { [number]: any } = {} -- [oid] = { from, to, id, uid, friend }
local byFrom: { [Player]: number } = {}
local byTo: { [Player]: number } = {}
local seq = 0
local offerEv: RemoteEvent? = nil

local function notify(p: Player, text: string, color: string)
	local r = RS:FindFirstChild("Remotes")
	local ev = r and r:FindFirstChild("AdminBroadcast")
	if ev and ev:IsA("RemoteEvent") then pcall(ev.FireClient, ev, p, "toast", { text = text, color = color }) end
end

local function rootOf(p: Player): BasePart?
	local ch = p.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	return (r and r:IsA("BasePart")) and r or nil
end

-- дружба (кеш на хвилину: IsFriendsWith — мережевий запит)
local friendCache: { [string]: { v: boolean, t: number } } = {}
local function isFriend(a: Player, b: Player): boolean
	local k = math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
	local c = friendCache[k]
	if c and os.clock() - c.t < 60 then return c.v end
	local ok, v = pcall(a.IsFriendsWith, a, b.UserId)
	local res = ok and v == true
	friendCache[k] = { v = res, t = os.clock() }
	return res
end

-- передача голема (після ACCEPT); checkFar = false — відстань уже не важлива (отримувач міг відійти, поки думав)
local function doGift(from: Player, to: Player, id: number, uid: any, friend: boolean, checkFar: boolean?): any
	local T = Cfg.TEXT
	if from:GetAttribute("InvReady") ~= true or to:GetAttribute("InvReady") ~= true then return { ok = false, err = "busy", msg = T.errBusy } end
	if checkFar then
		local a, b = rootOf(from), rootOf(to)
		if not (a and b) or (a.Position - b.Position).Magnitude > Cfg.REACH then return { ok = false, err = "far", msg = T.errFar } end
	end
	local g = Cfg.golemOf(from, id)
	if not g or (uid ~= nil and g.uid ~= uid) then return { ok = false, err = "gone", msg = T.errGone } end
	local err, msg = Cfg.check(from, to, g, friend)
	if err then return { ok = false, err = err, msg = msg } end
	-- новий id у отримувача
	local newId = 0
	local okC, Cave = pcall(require, script.Parent:FindFirstChild("CaveStandService"))
	if okC and Cave and Cave.MaxId then local okM, m = pcall(Cave.MaxId, to); if okM and type(m) == "number" then newId = m end end
	for _, x in Cfg.decode(to, "InvGolems") do if type(x) == "table" and type(x.id) == "number" then newId = math.max(newId, x.id) end end
	newId += 1
	-- перенесення
	local keep = {}
	for _, x in Cfg.decode(from, "InvGolems") do if not (type(x) == "table" and x.id == id) then table.insert(keep, x) end end
	local rec = table.clone(g)
	rec.id = newId
	rec.ix = 1 -- передані големи живуть у глобальному індексі (GolemRegistry.Move)
	local list = Cfg.decode(to, "InvGolems")
	table.insert(list, rec)
	from:SetAttribute("InvGolems", HttpService:JSONEncode(keep))
	to:SetAttribute("InvGolems", HttpService:JSONEncode(list))
	from:SetAttribute("GiftCD", workspace:GetServerTimeNow() + Cfg.COOLDOWN)
	local okR, Reg = pcall(require, script.Parent:FindFirstChild("GolemRegistry"))
	if okR and Reg and Reg.Move then pcall(Reg.Move, from.UserId, to.UserId, rec, "gift") end
	local okI, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
	if okI and Inv and Inv.Refresh then pcall(Inv.Refresh, from) end
	task.spawn(function() pcall(DataService.SaveNow, from); pcall(DataService.SaveNow, to) end)
	local name = Cfg.nameOf(g)
	notify(from, string.format(T.sent, name, to.DisplayName), "green")
	notify(to, string.format(T.got, from.DisplayName, name), "green")
	print("[Gift golem]", from.UserId, "->", to.UserId, g.uid, g.kind, g.cls, g.mut)
	return { ok = true }
end

local function dropOffer(oid: number)
	local o = offers[oid]
	if not o then return nil end
	offers[oid] = nil
	if byFrom[o.from] == oid then byFrom[o.from] = nil end
	if byTo[o.to] == oid then byTo[o.to] = nil end
	return o
end

-- 1) дарувальник: створити пропозицію
local function offer(p: Player, to: Player, id: number, uid: any): any
	local T = Cfg.TEXT
	if byFrom[p] then return { ok = false, err = "pending", msg = T.errPending } end
	if byTo[to] then return { ok = false, err = "targetBusy", msg = T.errTargetBusy } end
	if p:GetAttribute("InvReady") ~= true or to:GetAttribute("InvReady") ~= true then return { ok = false, err = "busy", msg = T.errBusy } end
	local a, b = rootOf(p), rootOf(to)
	if not (a and b) or (a.Position - b.Position).Magnitude > Cfg.REACH then return { ok = false, err = "far", msg = T.errFar } end
	local g = Cfg.golemOf(p, id)
	if not g or (uid ~= nil and g.uid ~= uid) then return { ok = false, err = "gone", msg = T.errGone } end
	local friend = to:GetAttribute("Set_GiftMode") == "friends" and isFriend(p, to) or false
	local err, msg = Cfg.check(p, to, g, friend)
	if err then return { ok = false, err = err, msg = msg } end
	seq += 1
	local oid = seq
	offers[oid] = { from = p, to = to, id = id, uid = g.uid, friend = friend }
	byFrom[p], byTo[to] = oid, oid
	if offerEv then offerEv:FireClient(to, { oid = oid, from = p.UserId, fromName = p.DisplayName, kind = g.kind, cls = g.cls, mut = g.mut, time = Cfg.ACCEPT_TIME }) end
	task.delay(Cfg.ACCEPT_TIME + 1, function()
		local o = dropOffer(oid)
		if not o then return end
		if o.from.Parent then notify(o.from, string.format(T.expired, o.to.DisplayName), "red") end
		if offerEv and o.to.Parent then offerEv:FireClient(o.to, { close = oid }) end
	end)
	return { ok = true, pending = true, msg = string.format(T.waiting, to.DisplayName) }
end

-- 2) отримувач: ACCEPT / DECLINE
local function respond(p: Player, oid: number, accept: boolean): any
	local T = Cfg.TEXT
	local o = offers[oid]
	if not o or o.to ~= p then return { ok = false, err = "gone", msg = T.errGone } end
	dropOffer(oid)
	local from = o.from
	if not from.Parent then return { ok = false, err = "gone", msg = T.errGone } end
	if not accept then
		notify(from, string.format(T.declined, p.DisplayName), "red")
		return { ok = true }
	end
	if busy[from] or busy[p] then return { ok = false, err = "busy", msg = T.errBusy } end
	busy[from], busy[p] = true, true
	local ok, res = pcall(doGift, from, p, o.id, o.uid, o.friend, false)
	busy[from], busy[p] = nil, nil
	if not ok then warn("GolemGiftService:", res); res = { ok = false, err = "busy", msg = T.errBusy } end
	if not res.ok then
		notify(from, res.msg or T.errBusy, "red")
		notify(p, res.msg or T.errBusy, "red")
	end
	return res
end

local function onInvoke(p: Player, action: any, arg: any): any
	if type(arg) ~= "table" then return { ok = false, err = "bad" } end
	if action == "Respond" then
		local oid = tonumber(arg.oid)
		if not oid then return { ok = false, err = "bad" } end
		return respond(p, oid, arg.accept == true)
	end
	if action ~= "Gift" then return { ok = false, err = "bad" } end
	local to = Players:GetPlayerByUserId(tonumber(arg.to) or 0)
	-- 06.11.2026: IsPaidItemTradingAllowed == false (PolicyNoTrade) у дарувальника чи отримувача — без подарунків големів
	if p:GetAttribute("PolicyNoTrade") == true or (to and to:GetAttribute("PolicyNoTrade") == true) then return { ok = false, err = "region", msg = "Golem gifts are not available in this region" } end
	local id = tonumber(arg.id)
	if not to or to == p or not id then return { ok = false, err = "bad" } end
	if busy[p] or busy[to] then return { ok = false, err = "busy", msg = Cfg.TEXT.errBusy } end
	busy[p], busy[to] = true, true
	local ok, res = pcall(offer, p, to, id, arg.uid)
	busy[p], busy[to] = nil, nil
	if not ok then warn("GolemGiftService:", res); return { ok = false, err = "busy", msg = Cfg.TEXT.errBusy } end
	return res
end

M._doGift = doGift -- для тестів
M._offer = offer
M._respond = respond

function M.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("GolemGift") or Instance.new("RemoteFunction")
	rf.Name = "GolemGift"
	rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onInvoke
	local ev = remotes:FindFirstChild("GolemGiftOffer") or Instance.new("RemoteEvent")
	ev.Name = "GolemGiftOffer"
	ev.Parent = remotes
	offerEv = ev :: RemoteEvent
	Players.PlayerRemoving:Connect(function(p)
		busy[p] = nil
		for oid, o in offers do
			if o.from == p or o.to == p then
				dropOffer(oid)
				if o.to ~= p and offerEv and o.to.Parent then offerEv:FireClient(o.to, { close = oid }) end
			end
		end
	end)
end

return M
