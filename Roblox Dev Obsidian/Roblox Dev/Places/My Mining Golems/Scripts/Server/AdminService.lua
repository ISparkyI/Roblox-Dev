--!nonstrict
-- AdminService — сервер адмін-панелі: гравці на всіх серверах, видача / забирання, кік і бан, пошук голема за UID,
--   глобальні оголошення, видача всім, події Admin Abuse (удача, гроші), список серверів, журнал.
-- Де: ServerScriptService/AdminService (ModuleScript). Запуск: NicheBoot (ОСТАННІМ). Доступ — ServerStorage/AdminConfig.
-- Клієнт панелі — ServerStorage/AdminUI/AdminPanelGui (ScreenGui з LocalScript AdminPanel): сервер клонує його ЛИШЕ адмінам
--   у PlayerGui, тож інші гравці навіть не отримують код панелі. Банер оголошень, тости й плашки подій для всіх —
--   StarterPlayerScripts/AdminBroadcastClient.
--
-- Зв'язок:
--   RemoteFunction Remotes/AdminAction (InvokeServer(дія, аргументи)) — кожен виклик: isAdmin, ліміт 12 дій / 3 с.
--   RemoteEvent Remotes/AdminBroadcast — сервер → клієнти: ("ann", { text, color, sec }) банер; ("toast", { text, color }) тост.
--   MessagingService, тема TOPIC — команди між серверами: give, info, find, kick, ann, ggrant, event, shutdown.
--   MemoryStore: AdminPresence (SortedMap: сервер → гравці, оновлення кожні PRESENCE_SEC), AdminReplies (HashMap: відповіді
--     інших серверів на запит, 60 с), AdminGrants (SortedMap: активні видачі всім — для тих, хто зайде протягом вікна),
--     AdminState (HashMap: ключ "events" — активні події удачі / грошей; сервер перевіряє раз на STATE_SEC).
--   DataStore AdminMail (ключ M_<userId>) — видачі гравцю, що зараз офлайн: отримає при наступному вході.
-- Ідемпотентність: кожна видача має tx; профіль гравця (секція "AdminTx") пам'ятає останні TX_KEEP tx — повтор
--   (подвійне повідомлення, пошта + живе повідомлення) не дасть видачу двічі.
-- Нагороди (what): Money | Diamonds | Tickets | LuckLvl | Potion (item = ключ зілля) | Golem (item = "stone@3:carrier",
--   amount = кількість) | RemoveGolem (item = UID) | Pass (item = ключ геймпаса з MonetizationConfig.Passes або "*" — усі;
--   amount 1 — видати, −1 — забрати; атрибут Pass_<ключ>). amount < 0 для Money / Diamonds / Tickets / LuckLvl — забрати (не нижче 0).
--   LuckRoll10 / LuckRoll99 (amount = скільки Lucky Roll у запас) — як ресурси.
--   MoneyTier / MutTier (amount = ступінь драбини x2 Money — MultiConfig.DONATE_TIERS / Fast Mutations — MonetizationConfig.MUT_SPEED_TIERS):
--     «до ступеня» — DonateTier / MutSpeedTier = max(поточний, amount); хто вже має ступінь не нижче — без змін (і без тосту).
-- Події: workspace атрибути EventLuck / EventLuckUntil (Roll Luck — рідкість голема), EventMutLuck / EventMutLuckUntil
--   (Mutation Luck — шанс мутації), EventMoney / EventMoneyUntil (os.time). Читають RollService і MultiService.
--
-- Дії панелі (AdminAction): Players, PlayerInfo { u | name }, Give { u, what, amount, item, mode = "set"? }, Kick { u, reason },
--   Ban { u, hours (0 — назавжди), reason }, Unban { u }, BanHistory { u }, FindUid { uid }, Announce { text, color, sec },
--   DM { u, text, color } (банер лише цьому гравцю), Teleport { u } (до гравця; інший сервер — TeleportService),
--   Bring { u } (лише цей сервер), Freeze { u, on }, GrantAll { what, amount, item, window (хв) },
--   Event { kind = "luck" | "money", mult, minutes } (mult 1 — стоп), Events, Servers, Shutdown, Logs,
--   Roles (список адмінів), SetRole { u | name, role = "admin" | "mod" | "none" }.
-- Ролі (рівні доступу): owner — userId з AdminConfig.ADMINS (змінити можна лише в конфігу); admin — усе, крім Shutdown і
--   керування адмінами; mod — перегляд, кік, бан до 24 год, оголошення, DM, телепорт / bring / freeze, пошук UID, журнал.
--   Видані ролі — DataStore AdminRoles (ключ "roles": { ["<userId>"] = { r, by, t, name } }); зміна розсилається всім серверам
--   (повідомлення roles), панель з'являється / зникає в гравця одразу. Роль гравця — атрибут AdminRole (owner | admin | mod).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")

local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local MonCfg = require(RS.Shared:WaitForChild("MonetizationConfig"))
local RollConfig = require(RS.Shared:WaitForChild("RollConfig"))
local NumberFormat = require(RS.Shared:WaitForChild("NumberFormat"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local CaveStandService = require(script.Parent:WaitForChild("CaveStandService"))
local GolemRegistry = require(script.Parent:WaitForChild("GolemRegistry"))

local AdminService = {}

local STUDIO = RunService:IsStudio()
local TOPIC = STUDIO and "MMG_Admin_Studio" or "MMG_Admin"
local SFX = STUDIO and "_Studio" or ""
local JOB = (game.JobId ~= "") and game.JobId or "studio"
local JOB_SHORT = string.sub(JOB, 1, 8)
local PRESENCE_SEC = 20
local STATE_SEC = 15
local REPLY_WAIT = 5
local TX_KEEP = 200
local START_T = os.time()
local RESOURCES = { Money = true, Diamonds = true, Tickets = true, LuckLvl = true, LuckRoll10 = true, LuckRoll99 = true }
local MultiCfg = require(RS.Shared:WaitForChild("MultiConfig"))
local TIER_MAX = { MoneyTier = function() return MultiCfg.maxDonateTier() end, MutTier = function() return #MonCfg.MUT_SPEED_TIERS end }
local TIER_ATTR = { MoneyTier = "DonateTier", MutTier = "MutSpeedTier" }
local MAX_AMOUNT = 1e60 -- межа видачі за раз (NumberFormat показує до Vg); точність double — ~15 значущих цифр
local MAX_GOLEMS_GRANT = 50

-- ===== доступ =====
local cfg = { ADMINS = {}, STUDIO_ALL = false }
do
	local mod = ServerStorage:FindFirstChild("AdminConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, res = pcall(require, mod)
		if ok and type(res) == "table" then cfg = res end
	end
end
-- ===== ролі =====
local LEVEL = { mod = 1, admin = 2, owner = 3 }
local roles: { [string]: any } = {}  -- видані ролі (DataStore AdminRoles)
local rolesMem: any = nil            -- Studio без доступу до API — ролі в пам'яті
local rolesStore = nil
local function isOwnerId(id: number): boolean
	for _, x in cfg.ADMINS or {} do if x == id then return true end end
	return false
end
local function roleOf(p: any): string?
	if typeof(p) ~= "Instance" or not p:IsA("Player") then return nil end
	if isOwnerId(p.UserId) then return "owner" end
	if STUDIO and cfg.STUDIO_ALL then return "owner" end
	local e = roles[tostring(p.UserId)]
	return (type(e) == "table" and LEVEL[e.r]) and e.r or nil
end
local function can(p: Player, need: string): boolean
	local r = roleOf(p)
	return r ~= nil and LEVEL[r] >= (LEVEL[need] or 3)
end
local function isAdmin(p: Player): boolean
	return roleOf(p) ~= nil
end
AdminService.IsAdmin = isAdmin
AdminService.RoleOf = roleOf
local function rstore()
	if not rolesStore then rolesStore = DataStoreService:GetDataStore("AdminRoles" .. SFX) end
	return rolesStore
end
-- (список | nil при помилці)
local function loadRoles(): any
	if rolesMem then return rolesMem end
	local ok, v = pcall(function() return rstore():GetAsync("roles") end)
	if ok then return type(v) == "table" and v or {} end
	if STUDIO then rolesMem = {}; return rolesMem end
	warn("AdminService: ролі: " .. tostring(v))
	return nil
end

-- ===== сховища (з запасним варіантом у Studio) =====
local function ms(kind: string, name: string): any
	local ok, obj = pcall(function()
		if kind == "sorted" then return MemoryStoreService:GetSortedMap(name .. SFX) end
		return MemoryStoreService:GetHashMap(name .. SFX)
	end)
	return ok and obj or nil
end
local presenceMap = ms("sorted", "AdminPresence")
local repliesMap = ms("hash", "AdminReplies")
local grantsMap = ms("sorted", "AdminGrants")
local stateMap = ms("hash", "AdminState")
local mailStore = nil
local function mail()
	if not mailStore then mailStore = DataStoreService:GetDataStore("AdminMail" .. SFX) end
	return mailStore
end
local localReplies = {} -- Studio / без MemoryStore: відповіді цього ж сервера
local localGrants = {}  -- те саме для видач усім

local function publish(msg: any): boolean
	msg.j = JOB
	local ok, err = pcall(function() MessagingService:PublishAsync(TOPIC, HttpService:JSONEncode(msg)) end)
	if not ok then warn("AdminService: publish " .. tostring(msg.c) .. ": " .. tostring(err)) end
	return ok
end

local function newId(): string return string.sub(string.gsub(HttpService:GenerateGUID(false), "-", ""), 1, 16) end

local broadcast: RemoteEvent = nil
local function toast(p: Player, text: string, color: string?)
	if broadcast and p.Parent == Players then broadcast:FireClient(p, "toast", { text = text, color = color or "green" }) end
end

-- важливі дії — ще й у Google-таблицю (аркуш AdminLog через BackendService): цей запис не стирається з гри
local SHEET = { give = true, grantall = true, role = true, ban = true, unban = true, shutdown = true, event = true, kick = true }
local function sheetLog(ev: any)
	local mod = script.Parent:FindFirstChild("BackendService")
	if not mod then return end
	local ok, B = pcall(require, mod)
	if ok and type(B) == "table" and B.AdminLog then B.AdminLog(ev) end
end
local function audit(by: any, what: string, data: any)
	GolemRegistry.Log({ e = "admin", u = tonumber(by) or 0, r = what, x = data })
	if SHEET[what] then sheetLog({ t = os.time(), e = "admin", by = tonumber(by) or 0, what = what, data = data, job = JOB_SHORT }) end
end

-- запит до панелі без ролі. Звичайному гравцю F2 нічого не шле (панелі в нього немає), тож такий запит — лише підробка
-- клієнта: подія SUSPECT у журнал і в таблицю (не частіше разу на 5 с), після SUSPECT_KICK спроб за 10 хв — кік.
local SUSPECT_KICK = 3
local suspects: { [number]: any } = {}
local function suspect(p: Player, action: any)
	local now = os.clock()
	local s = suspects[p.UserId]
	if not s or now - s.t0 > 600 then s = { n = 0, t0 = now, last = -math.huge }; suspects[p.UserId] = s end
	s.n += 1
	if now - s.last >= 5 or s.n >= SUSPECT_KICK then
		s.last = now
		local what = string.sub(tostring(action), 1, 40)
		GolemRegistry.Log({ e = "suspect", u = p.UserId, r = what, x = { name = p.Name, n = s.n, job = JOB_SHORT } })
		sheetLog({ t = os.time(), e = "suspect", by = p.UserId, name = p.Name, what = what, n = s.n, job = JOB_SHORT })
	end
	if s.n >= SUSPECT_KICK then p:Kick("Unauthorized request") end
end

-- ===== відповіді між серверами =====
local function reply(req: string, item: any)
	if not req then return end
	if repliesMap then
		local ok = pcall(function()
			repliesMap:UpdateAsync(req, function(old)
				old = old or {}
				table.insert(old, item)
				return old
			end, 60)
		end)
		if ok then return end
	end
	localReplies[req] = localReplies[req] or {}
	table.insert(localReplies[req], item)
end
local function collect(req: string, wait: number, enough: ((any) -> boolean)?): { any }
	local t0 = os.clock()
	local out = {}
	while os.clock() - t0 < wait do
		task.wait(0.5)
		out = {}
		for _, x in localReplies[req] or {} do table.insert(out, x) end
		if repliesMap then
			local ok, v = pcall(function() return repliesMap:GetAsync(req) end)
			if ok and type(v) == "table" then for _, x in v do table.insert(out, x) end end
		end
		if enough and enough(out) then break end
	end
	localReplies[req] = nil
	return out
end

-- ===== профіль гравця: tx, знімок для панелі =====
local txOf: { [Player]: { string } } = {}
local function hasTx(p: Player, tx: string): boolean
	return table.find(txOf[p] or {}, tx) ~= nil
end
local function addTx(p: Player, tx: string)
	local l = txOf[p] or {}
	table.insert(l, tx)
	while #l > TX_KEEP do table.remove(l, 1) end
	txOf[p] = l
end

local function decodeAttr(p: Player, name: string, default: any): any
	local s = p:GetAttribute(name)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end

-- голем у компактному вигляді для панелі: { uid, kind, cls, mut, where, locked }
local function packGolems(inv: { any }, placed: { number }, cave: { [string]: any }, locks: { string }): { any }
	local out = {}
	for _, g in inv or {} do
		if type(g) == "table" then
			table.insert(out, { g.uid or "", g.kind, g.cls, g.mut or 0, table.find(placed or {}, g.id) and "plot" or "inv",
				table.find(locks or {}, "Golem_" .. tostring(g.id)) and 1 or 0 })
		end
	end
	for k, g in cave or {} do
		if type(g) == "table" then table.insert(out, { g.uid or "", g.kind, g.cls, g.mut or 0, "cave#" .. k, g.locked and 1 or 0 }) end
	end
	return out
end

-- геймпаси гравця (ключі MonetizationConfig.Passes), get(attr) — атрибут
local function passList(get): { string }
	local out = {}
	for key in MonCfg.Passes do if get("Pass_" .. key) == true then table.insert(out, key) end end
	table.sort(out)
	return out
end

local function infoLocal(p: Player): any
	local a = function(n) return p:GetAttribute(n) end
	return {
		u = p.UserId, name = p.Name, display = p.DisplayName, status = "online", job = JOB_SHORT, age = p.AccountAge,
		money = a("Money") or 0, diamonds = a("Diamonds") or 0, tickets = a("Tickets") or 0, stage = a("Stage") or 1,
		luck = a("RollLuckLvl") or 1, rebirths = a("Rebirths") or 0, multi = a("TotalMulti") or 1,
		suspect = a("SuspectDupe") == true,
		passes = passList(a),
		tiers = { MoneyTier = a("DonateTier") or 0, MutTier = a("MutSpeedTier") or 0, LuckRoll10 = a("LuckRoll10") or 0, LuckRoll99 = a("LuckRoll99") or 0 },
		golems = packGolems(decodeAttr(p, "InvGolems", {}), decodeAttr(p, "PlotPlaced", {}), decodeAttr(p, "CaveStandGolems", {}), decodeAttr(p, "InvLocks", {})),
	}
end

local function infoOffline(userId: number): any
	local ok, rec = pcall(function()
		return DataStoreService:GetDataStore(STUDIO and "PlayerData_Studio" or "PlayerData"):GetAsync("P_" .. userId)
	end)
	if not ok then return { u = userId, status = "error", err = tostring(rec) } end
	local okN, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	if type(rec) ~= "table" or type(rec.data) ~= "table" then
		return { u = userId, name = okN and name or "?", status = "nodata", golems = {} }
	end
	local d = rec.data
	local at = d.attrs or {}
	local sec = d.sections or {}
	local inv = (type(sec.Inventory) == "table" and sec.Inventory.golems) or {}
	local cave = (type(sec.Cave) == "table" and sec.Cave.golems) or {}
	local locks = (type(sec.Inventory) == "table" and sec.Inventory.locks) or {}
	local placed = {}
	return {
		u = userId, name = okN and name or "?", status = "offline", lastSeen = d.stats and d.stats.lastSeen,
		money = at.Money or 0, diamonds = at.Diamonds or 0, tickets = at.Tickets or 0, stage = at.Stage or 1,
		luck = at.RollLuckLvl or 1, rebirths = at.Rebirths or 0,
		passes = passList(function(k) return at[k] end),
		tiers = { MoneyTier = at.DonateTier or 0, MutTier = at.MutSpeedTier or 0, LuckRoll10 = at.LuckRoll10 or 0, LuckRoll99 = at.LuckRoll99 or 0 },
		golems = packGolems(inv, placed, cave, locks),
	}
end

-- ===== застосувати видачу до гравця на цьому сервері =====
local function parseGolem(item: string): (string?, string, number)
	local s = string.lower(tostring(item or ""))
	local kind, rest = string.match(s, "^([%w_]+)(.*)$")
	if not kind then return nil, "miner", 0 end
	local cls = string.match(rest, ":(%a+)") or "miner"
	local mut = tonumber(string.match(rest, "@(%d+)")) or 0
	return Catalog.id(kind), Catalog.cls(cls), Catalog.mut(mut)
end

local function potionKey(item: any): string?
	for _, d in Items.POTIONS do
		if string.lower(d.key) == string.lower(tostring(item or "")) then return d.key end
	end
	return nil
end

-- перевірка видачі ще ДО відправки (панель отримує зрозумілу помилку)
local function validGrant(g: any): (boolean, string?)
	if type(g) ~= "table" then return false, "bad" end
	local n = tonumber(g.amount)
	if g.mode == "set" then
		if not RESOURCES[g.what] or not n or n ~= n or n < 0 or n > MAX_AMOUNT then return false, "amount" end
		return true
	end
	if g.what ~= "RemoveGolem" and (not n or n ~= n or math.abs(n) > MAX_AMOUNT or n == 0) then return false, "amount" end
	if RESOURCES[g.what] then return true end
	if g.what == "Potion" then return potionKey(g.item) ~= nil and n > 0, "potion" end
	if g.what == "Golem" then
		return parseGolem(g.item) ~= nil and n > 0 and n <= MAX_GOLEMS_GRANT, "golem"
	end
	if g.what == "RemoveGolem" then return GolemRegistry.IsUid(g.item), "uid" end
	if g.what == "Pass" then return (g.item == "*" or MonCfg.Passes[tostring(g.item)] ~= nil) and (n == 1 or n == -1), "pass" end
	if TIER_MAX[g.what] then return n >= 1 and n <= TIER_MAX[g.what]() and n == math.floor(n), "level" end
	return false, "what"
end

local function grantText(g: any): string
	local n = tonumber(g.amount) or 0
	-- число для тексту: великі — коротко (1Qi, 2.5B), як у HUD; дрібні — як є
	local function f(x: number): string
		if math.abs(x) >= 1e6 then return (x < 0 and "-" or "") .. NumberFormat.short(math.abs(x)) end
		return tostring(x)
	end
	if g.mode == "set" then
		return (g.what == "LuckLvl" and "Roll Luck" or tostring(g.what)) .. " = " .. f(n)
	elseif g.what == "RemoveGolem" then
		return "Golem " .. tostring(g.item) .. " deleted"
	elseif g.what == "Golem" then
		local id, _, mut = parseGolem(g.item)
		local def = id and Catalog.GOLEMS[id]
		local mu = Catalog.MUTATIONS[(mut or 0) + 1]
		local mname = (mu and mu.key ~= "Normal") and (mu.key .. " ") or ""
		return "+" .. (n > 1 and (n .. " ") or "") .. mname .. ((def and def.name) or "Golem")
	elseif g.what == "Pass" then
		local nm = g.item == "*" and "All Gamepasses" or (((MonCfg.Passes[tostring(g.item)] or {}).name or tostring(g.item)) .. " Gamepass")
		return (n > 0 and "+" or "Removed: ") .. nm
	elseif g.what == "Potion" then
		return "+" .. f(n) .. " " .. (potionKey(g.item) or "") .. " Potion"
	elseif g.what == "LuckLvl" then
		return (n >= 0 and "+" or "") .. f(n) .. " Roll Luck"
	elseif g.what == "MoneyTier" then
		return "x" .. NumberFormat.full(MultiCfg.donateMult(n)) .. " Money"
	elseif g.what == "MutTier" then
		return "x" .. tostring(MonCfg.mutSpeedMult(n)) .. " Fast Mutations"
	elseif g.what == "LuckRoll10" or g.what == "LuckRoll99" then
		return (n >= 0 and "+" or "") .. f(n) .. (g.what == "LuckRoll10" and " x10" or " x99") .. " Lucky Roll"
	end
	return (n >= 0 and "+" or "") .. f(n) .. " " .. tostring(g.what)
end

-- (ok, повідомлення). tx — ідемпотентність; silent — без тосту гравцю
local function applyGrant(p: Player, g: any, tx: string, silent: boolean?): (boolean, string?)
	if p.Parent ~= Players or not DataService.IsLoaded(p) then return false, "notloaded" end
	if p:GetAttribute("InvReady") ~= true then return false, "notloaded" end
	if hasTx(p, tx) then return true, "dup" end
	local okV, why = validGrant(g)
	if not okV then return false, why end
	local n = tonumber(g.amount) or 0
	if RESOURCES[g.what] then
		local attr = g.what == "LuckLvl" and "RollLuckLvl" or g.what
		local cur = tonumber(p:GetAttribute(attr)) or (attr == "RollLuckLvl" and 1 or 0)
		local new = math.max(attr == "RollLuckLvl" and 1 or 0, math.floor((g.mode == "set" and 0 or cur) + n))
		p:SetAttribute(attr, new)
		if attr == "RollLuckLvl" then p:SetAttribute("RollLuck", RollConfig.luckPercent(new)) end -- % удачі рахує RollUpgradeService лише при покупці
	elseif g.what == "Potion" then
		local key = "Pot_" .. (potionKey(g.item) :: string)
		p:SetAttribute(key, math.max(0, ((p:GetAttribute(key) :: number?) or 0) + math.floor(n)))
	elseif g.what == "Golem" then
		local id, cls, mut = parseGolem(g.item)
		for _ = 1, math.floor(n) do
			local newId = CaveStandService.MaxId(p) + 1
			if not InventoryService.AddGolem(p, newId, id :: string, cls, mut, "admin:" .. tostring(g.by or 0), true) then
				return false, "inventory"
			end
		end
	elseif g.what == "Pass" then
		for key in MonCfg.Passes do
			if g.item == "*" or g.item == key then
				p:SetAttribute("Pass_" .. key, n > 0 and true or nil)
				p:SetAttribute("PassOff_" .. key, n < 0 and true or nil) -- знято адміном: не повертати при вході (власник гри / покупець володіє геймпасом у Roblox)
			end
		end
	elseif TIER_ATTR[g.what] then
		-- «до ступеня»: вищий або такий самий вже є — нічого не міняємо і не показуємо тост
		local attr = TIER_ATTR[g.what]
		local cur = tonumber(p:GetAttribute(attr)) or 0
		if cur >= n then silent = true else p:SetAttribute(attr, math.floor(n)) end
	elseif g.what == "RemoveGolem" then
		local rec = InventoryService.RemoveByUid(p, g.item, "admin:" .. tostring(g.by or 0))
			or CaveStandService.RemoveByUid(p, g.item, "admin:" .. tostring(g.by or 0))
		if not rec then return false, "notfound" end
	end
	addTx(p, tx)
	GolemRegistry.Log({ e = "grant", u = p.UserId, r = g.what, x = { n = n, item = g.item, by = g.by, tx = tx } })
	task.spawn(DataService.SaveNow, p)
	if not silent and g.what ~= "RemoveGolem" then
		toast(p, grantText(g) .. (n >= 0 and "!" or ""), n >= 0 and "green" or "red")
	end
	return true, nil
end

-- пошта офлайн-гравцю
local function sendMail(userId: number, g: any, tx: string): boolean
	local entry = table.clone(g)
	entry.tx = tx
	local ok, err = pcall(function()
		mail():UpdateAsync("M_" .. userId, function(old)
			old = old or {}
			if #old >= 200 then table.remove(old, 1) end
			table.insert(old, entry)
			return old
		end)
	end)
	if not ok then warn("AdminService: пошта " .. userId .. ": " .. tostring(err)) end
	return ok
end

local function deliverMail(p: Player)
	local got = nil
	local ok, err = pcall(function()
		mail():UpdateAsync("M_" .. p.UserId, function(old)
			got = old
			if old == nil or #old == 0 then return nil end
			return {}
		end)
	end)
	if not ok then
		if not (STUDIO and string.find(tostring(err), "studio")) then warn("AdminService: пошта при вході: " .. tostring(err)) end
		return
	end
	for _, g in got or {} do
		if type(g) == "table" and type(g.tx) == "string" then
			local okA, why = applyGrant(p, g, g.tx)
			if not okA then
				-- не вийшло (напр. повний інвентар) — повертаємо в пошту
				sendMail(p.UserId, g, g.tx)
				warn("AdminService: пошту не видано " .. p.UserId .. ": " .. tostring(why))
			end
		end
	end
end

-- активні видачі всім (для тих, хто зайшов у вікно)
local function activeGrants(): { any }
	local out = {}
	local now = os.time()
	for _, g in localGrants do if (g.untilT or 0) > now then table.insert(out, g) end end
	if grantsMap then
		local ok, items = pcall(function() return grantsMap:GetRangeAsync(Enum.SortDirection.Descending, 50) end)
		if ok then
			for _, it in items do
				local g = it.value
				if type(g) == "table" and (g.untilT or 0) > now and not localGrants[g.id] then table.insert(out, g) end
			end
		end
	end
	return out
end

-- ===== події (удача / гроші) =====
-- luck — Roll Luck (рідкість голема), mutluck — Mutation Luck (шанс мутації), money — множник грошей
local EVENT_ATTR = { luck = "EventLuck", mutluck = "EventMutLuck", money = "EventMoney" }
local EVENT_NAME = { luck = "ROLL LUCK", mutluck = "MUTATION LUCK", money = "MONEY" }
-- ЧЕРГА: у кожного виду — розклад відрізків { m, startT, untilT } один за одним. Діє найбільший множник; менші чекають
--   (їхній залишок часу зберігається) і вмикаються, коли більший закінчиться. Той самий множник ще раз — час додається.
--   Приклад: x2 на 10 хв, через 3 хв x5 на 5 хв → x5 зараз (5 хв), потім x2 ще 7 хв.
local events: { [string]: any } = {} -- kind → { q = { відрізки } }
local function normalize(e: any, now: number): any
	if type(e) ~= "table" then return nil end
	if type(e.q) ~= "table" and tonumber(e.m) then -- старий формат { m, untilT }
		e = { q = { { m = e.m, startT = now, untilT = e.untilT or now, by = e.by } } }
	end
	if type(e.q) ~= "table" then return nil end
	local q = {}
	for _, sgm in e.q do
		if type(sgm) == "table" and tonumber(sgm.m) and (tonumber(sgm.untilT) or 0) > now then table.insert(q, sgm) end
	end
	return #q > 0 and { q = q } or nil
end
-- новий множник у чергу: залишки всіх відрізків + новий (той самий m — додаємо час), сортування за m ↓, підряд від now
local function enqueue(e: any, m: number, dur: number, now: number, by: number): any
	local items = {}
	for _, sgm in (e and e.q) or {} do
		local left = sgm.untilT - math.max(now, sgm.startT)
		if left > 0 then table.insert(items, { m = sgm.m, left = left, by = sgm.by }) end
	end
	local merged = false
	for _, it in items do if it.m == m then it.left += dur; merged = true end end
	if not merged then table.insert(items, { m = m, left = dur, by = by }) end
	table.sort(items, function(x, y) return x.m > y.m end)
	local q, t = {}, now
	for _, it in items do
		table.insert(q, { m = it.m, startT = t, untilT = t + it.left, by = it.by })
		t += it.left
	end
	return { q = q }
end
local function currentSeg(e: any, now: number): any
	for _, sgm in (e and e.q) or {} do
		if sgm.startT <= now and now < sgm.untilT then return sgm end
	end
	return nil
end
-- атрибути workspace: <Attr> = поточний множник, <Attr>Until = кінець поточного відрізка,
-- <Attr>Queue = JSON наступних { m, d (с) } — для панелі (написи гравцям показують лише поточний)
local function applyEvents(state: any)
	state = type(state) == "table" and state or {}
	local now = os.time()
	for kind, attr in EVENT_ATTR do
		local e = normalize(state[kind], now)
		events[kind] = e
		local cur = currentSeg(e, now)
		local nextQ = {}
		for _, sgm in (e and e.q) or {} do
			if sgm ~= cur and sgm.startT >= now then table.insert(nextQ, { m = sgm.m, d = sgm.untilT - sgm.startT }) end
		end
		local qs = #nextQ > 0 and HttpService:JSONEncode(nextQ) or nil
		local m = cur and (tonumber(cur.m) or 1) or nil
		if m and m <= 1 then m = nil end
		if workspace:GetAttribute(attr) ~= m then workspace:SetAttribute(attr, m) end
		local u = m and cur.untilT or nil
		if workspace:GetAttribute(attr .. "Until") ~= u then workspace:SetAttribute(attr .. "Until", u) end
		if workspace:GetAttribute(attr .. "Queue") ~= qs then workspace:SetAttribute(attr .. "Queue", qs) end
	end
end
local function readState()
	if not stateMap then return end
	local ok, v = pcall(function() return stateMap:GetAsync("events") end)
	if ok then applyEvents(v) end
end

-- ===== команди між серверами =====
local function findLocal(uid: string): { any }
	local hits = {}
	for _, p in Players:GetPlayers() do
		local g = InventoryService.FindByUid(p, uid)
		local where = nil
		if g then
			where = table.find(decodeAttr(p, "PlotPlaced", {}), g.id) and "plot" or "inv"
		else
			local slot
			slot, g = CaveStandService.FindByUid(p, uid)
			if g then where = "cave#" .. tostring(slot) end
		end
		if g then table.insert(hits, { u = p.UserId, name = p.Name, where = where, job = JOB_SHORT, kind = g.kind, cls = g.cls, mut = g.mut }) end
	end
	return hits
end

local function shutdownAll(by: number)
	for _, p in Players:GetPlayers() do
		p:Kick("The server is restarting for an update. Please rejoin!")
	end
end

local function onMessage(raw: any)
	local ok, msg = pcall(HttpService.JSONDecode, HttpService, raw.Data)
	if not ok or type(msg) ~= "table" then return end
	-- свої ж повідомлення (MessagingService доставляє і відправнику) — пропускаємо: send() уже виконав їх тут
	if msg.j == JOB and raw.Local ~= true then return end
	local c = msg.c
	if c == "give" then
		local p = Players:GetPlayerByUserId(tonumber(msg.u) or 0)
		if p then
			local okA, why = applyGrant(p, msg.g, msg.tx)
			reply(msg.req, { ok = okA, why = why, job = JOB_SHORT })
		end
	elseif c == "info" then
		local p = Players:GetPlayerByUserId(tonumber(msg.u) or 0)
		if p then reply(msg.req, infoLocal(p)) end
	elseif c == "find" then
		for _, h in findLocal(msg.g) do reply(msg.req, h) end
	elseif c == "kick" then
		local p = Players:GetPlayerByUserId(tonumber(msg.u) or 0)
		if p then p:Kick(msg.reason ~= "" and msg.reason or "Kicked by an admin.") end
	elseif c == "ann" then
		if broadcast then broadcast:FireAllClients("ann", { text = msg.text, color = msg.color, sec = msg.sec }) end
	elseif c == "ggrant" then
		local g = msg.g
		if type(g) ~= "table" then return end
		if not grantsMap then localGrants[g.id] = g end
		for _, p in Players:GetPlayers() do task.spawn(applyGrant, p, g, "G:" .. g.id) end
	elseif c == "event" then
		applyEvents(msg.state)
	elseif c == "shutdown" then
		shutdownAll(msg.by)
	elseif c == "roles" then
		if type(msg.roles) == "table" then AdminService._applyRoles(msg.roles) end
	elseif c == "freeze" then
		local p = Players:GetPlayerByUserId(tonumber(msg.u) or 0)
		if p then AdminService._freeze(p, msg.on == true) end
	elseif c == "dm" then
		local p = Players:GetPlayerByUserId(tonumber(msg.u) or 0)
		if p and broadcast then broadcast:FireClient(p, "ann", { text = msg.text, color = msg.color, sec = 10 }) end
	end
end

-- повідомлення: спершу цьому серверу (без затримки й навіть без MessagingService у Studio), потім іншим
local function send(msg: any)
	msg.j = JOB
	task.spawn(onMessage, { Data = HttpService:JSONEncode(msg), Local = true })
	publish(msg)
end

-- ===== присутність (список серверів і гравців) =====
local function writePresence()
	if not presenceMap then return end
	local list = {}
	for _, p in Players:GetPlayers() do table.insert(list, { p.UserId, p.Name }) end
	pcall(function()
		presenceMap:SetAsync(JOB, { players = list, n = #list, start = START_T, t = os.time(), place = game.PlaceVersion }, PRESENCE_SEC * 3)
	end)
end
local function readPresence(): { any }
	local out = {}
	local seenThis = false
	if presenceMap then
		local ok, items = pcall(function() return presenceMap:GetRangeAsync(Enum.SortDirection.Ascending, 200) end)
		if ok then
			for _, it in items do
				if type(it.value) == "table" then
					local v = it.value
					v.job = string.sub(it.key, 1, 8)
					v.here = it.key == JOB
					v.jobFull = it.key
					if v.here then seenThis = true end
					table.insert(out, v)
				end
			end
		end
	end
	if not seenThis then
		local list = {}
		for _, p in Players:GetPlayers() do table.insert(list, { p.UserId, p.Name }) end
		table.insert(out, 1, { players = list, n = #list, start = START_T, t = os.time(), job = JOB_SHORT, here = true, place = game.PlaceVersion })
	end
	return out
end
local function whereIsFull(userId: number): string?
	for _, s in readPresence() do
		if not s.here then
			for _, e in s.players or {} do if e[1] == userId then return s.jobFull end end
		end
	end
	return nil
end
local function whereIs(userId: number): string?
	if Players:GetPlayerByUserId(userId) then return "here" end
	for _, s in readPresence() do
		for _, e in s.players or {} do if e[1] == userId then return s.job end end
	end
	return nil
end

-- ===== дії панелі =====
local rate: { [Player]: { number } } = {}
local function limited(p: Player): boolean
	local now = os.clock()
	local l = rate[p] or {}
	while l[1] and now - l[1] > 3 do table.remove(l, 1) end
	if #l >= 12 then return true end
	table.insert(l, now)
	rate[p] = l
	return false
end

local function filterBroadcast(text: string, from: number): string?
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, from, Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()
	end)
	if ok then return res end
	if STUDIO then return text end
	return nil
end

local function resolveUser(arg: any): number?
	local u = tonumber(arg and arg.u)
	if u and u > 0 then return math.floor(u) end
	local name = arg and arg.name
	if type(name) == "string" and #name >= 2 and #name <= 32 then
		local num = tonumber(name)
		if num and num > 0 then return math.floor(num) end
		for _, p in Players:GetPlayers() do if string.lower(p.Name) == string.lower(name) then return p.UserId end end
		local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
		if ok then return id end
	end
	return nil
end

local A = {}

function A.Players(p)
	local out = {}
	for _, s in readPresence() do
		for _, e in s.players or {} do
			table.insert(out, { u = e[1], name = e[2], job = s.job, here = s.here })
		end
	end
	return { ok = true, players = out }
end

function A.PlayerInfo(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	local here = Players:GetPlayerByUserId(u)
	if here then return { ok = true, info = infoLocal(here) } end
	local where = whereIs(u)
	if where then
		local req = newId()
		send({ c = "info", u = u, req = req })
		local res = collect(req, REPLY_WAIT, function(l) return #l > 0 end)
		if res[1] then return { ok = true, info = res[1] } end
	end
	local info = infoOffline(u)
	if where then info.status = "online@" .. where .. " (no reply, saved data)" end
	return { ok = true, info = info }
end

function A.Give(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	local g = { what = arg.what, amount = tonumber(arg.amount), item = arg.item, by = p.UserId, mode = arg.mode == "set" and "set" or nil }
	local okV, why = validGrant(g)
	if not okV then return { ok = false, error = "Invalid " .. tostring(why) } end
	local tx = "A:" .. newId()
	audit(p.UserId, "give", { u = u, what = g.what, n = g.amount, item = g.item, tx = tx })
	local here = Players:GetPlayerByUserId(u)
	if here then
		local okA, w = applyGrant(here, g, tx)
		return { ok = okA, error = (not okA) and ("Failed: " .. tostring(w)) or nil, text = okA and (grantText(g) .. " → " .. here.Name) or nil }
	end
	if g.what == "RemoveGolem" and not whereIs(u) then
		return { ok = false, error = "Player is offline — golem removal works only online" }
	end
	if whereIs(u) then
		local req = newId()
		send({ c = "give", u = u, g = g, tx = tx, req = req })
		local res = collect(req, REPLY_WAIT, function(l) return #l > 0 end)
		if res[1] and res[1].ok then return { ok = true, text = grantText(g) .. " → server " .. tostring(res[1].job) } end
		if res[1] and not res[1].ok and res[1].why ~= "notloaded" then return { ok = false, error = "Failed: " .. tostring(res[1].why) } end
	end
	if g.what == "RemoveGolem" then return { ok = false, error = "No answer from player's server" } end
	-- офлайн / сервер не відповів — пошта (tx не дасть видати двічі)
	if sendMail(u, g, tx) then return { ok = true, text = grantText(g) .. " — mailed (offline)" } end
	return { ok = false, error = "Mail failed" }
end

function A.Kick(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	local reason = type(arg.reason) == "string" and string.sub(arg.reason, 1, 200) or ""
	audit(p.UserId, "kick", { u = u, reason = reason })
	send({ c = "kick", u = u, reason = reason })
	return { ok = true, text = "Kick sent" }
end

-- бани цього сервера (29.10.2026): BanAsync не працює в Studio / Team Test і доходить до серверів із затримкою —
-- забанений не зайде назад на цей сервер (u → { till = os.time або math.huge, reason })
local sessionBans: { [number]: { till: number, reason: string } } = {}
function A.Ban(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	if u == p.UserId then return { ok = false, error = "You can't ban yourself" } end
	local hours = math.max(0, tonumber(arg.hours) or 0)
	local reason = type(arg.reason) == "string" and string.sub(arg.reason, 1, 400) or ""
	local ok, err = pcall(function()
		Players:BanAsync({ UserIds = { u }, ApplyToUniverse = true, Duration = hours > 0 and math.floor(hours * 3600) or -1,
			DisplayReason = reason ~= "" and reason or "Banned by an admin.", PrivateReason = "admin " .. p.UserId .. ": " .. reason })
	end)
	audit(p.UserId, "ban", { u = u, hours = hours, reason = reason, ok = ok })
	sessionBans[u] = { till = hours > 0 and os.time() + math.floor(hours * 3600) or math.huge, reason = reason ~= "" and reason or "Banned by an admin." }
	send({ c = "kick", u = u, reason = reason ~= "" and reason or "Banned by an admin." })
	local here = Players:GetPlayerByUserId(u)
	if here then pcall(function() here:Kick(sessionBans[u].reason) end) end
	if not ok then
		if game:GetService("RunService"):IsStudio() then return { ok = true, text = "Banned on this server (Studio: no Roblox ban)" } end
		return { ok = false, error = "BanAsync: " .. tostring(err) }
	end
	return { ok = true, text = hours > 0 and ("Banned for " .. hours .. " h") or "Banned permanently" }
end

function A.Unban(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	sessionBans[u] = nil
	local ok, err = pcall(function() Players:UnbanAsync({ UserIds = { u }, ApplyToUniverse = true }) end)
	audit(p.UserId, "unban", { u = u, ok = ok })
	if not ok then return { ok = false, error = "UnbanAsync: " .. tostring(err) } end
	return { ok = true, text = "Unbanned" }
end

function A.FindUid(p, arg)
	local uid = type(arg) == "table" and type(arg.uid) == "string" and string.upper((string.gsub(arg.uid, "%s", ""))) or ""
	if not GolemRegistry.IsUid(uid) then return { ok = false, error = "Not a valid UID (26 chars)" } end
	local hits = findLocal(uid)
	local req = newId()
	publish({ c = "find", g = uid, req = req })
	local entry = GolemRegistry.Lookup(uid)
	local more = collect(req, 3)
	for _, h in more do table.insert(hits, h) end
	return { ok = true, uid = uid, minted = GolemRegistry.TimeOf(uid), index = entry, hits = hits }
end

function A.Announce(p, arg)
	local text = type(arg) == "table" and type(arg.text) == "string" and string.sub(arg.text, 1, 200) or ""
	if #text < 2 then return { ok = false, error = "Text is too short" } end
	local f = filterBroadcast(text, p.UserId)
	if not f then return { ok = false, error = "Filter failed, try again" } end
	local sec = math.clamp(tonumber(arg.sec) or 8, 3, 60)
	local color = type(arg.color) == "string" and string.sub(arg.color, 1, 12) or "yellow"
	audit(p.UserId, "announce", { text = f, sec = sec })
	send({ c = "ann", text = f, color = color, sec = sec })
	return { ok = true, text = "Announcement sent to all servers" }
end

function A.GrantAll(p, arg)
	local g = { what = arg.what, amount = tonumber(arg.amount), item = arg.item, by = p.UserId }
	if g.what == "RemoveGolem" then return { ok = false, error = "Not allowed" } end
	local okV, why = validGrant(g)
	if not okV then return { ok = false, error = "Invalid " .. tostring(why) } end
	if (tonumber(g.amount) or 0) < 0 then return { ok = false, error = "Amount must be positive" } end
	local window = math.clamp(tonumber(arg.window) or 0, 0, 7 * 24 * 60)
	g.id = newId()
	g.untilT = os.time() + window * 60
	audit(p.UserId, "grantall", { what = g.what, n = g.amount, item = g.item, window = window, id = g.id })
	if window > 0 then
		if grantsMap then
			pcall(function() grantsMap:SetAsync(g.id, g, window * 60 + 60) end)
		else
			localGrants[g.id] = g
		end
	end
	send({ c = "ggrant", g = g })
	return { ok = true, text = grantText(g) .. " → everyone" .. (window > 0 and (" (+ joiners for " .. window .. " min)") or "") }
end

function A.Event(p, arg)
	local kind = type(arg) == "table" and arg.kind
	if not EVENT_ATTR[kind] then return { ok = false, error = "Bad event" } end
	-- свій множник з панелі (1.5, 25…): Money — до x1000; Roll / Mutation Luck — без практичної межі
	local mult = tonumber(arg.mult) or 1
	if mult ~= mult then mult = 1 end
	mult = math.clamp(mult, 1, kind == "money" and 1000 or 1e15)
	local minutes = math.clamp(tonumber(arg.minutes) or 15, 1, 24 * 60)
	-- mult 1 (STOP) — прибрати весь вид разом з чергою; інакше — поставити в чергу (див. enqueue)
	local function change(old)
		old = type(old) == "table" and old or {}
		local now = os.time()
		if mult <= 1 then old[kind] = nil else old[kind] = enqueue(normalize(old[kind], now), mult, minutes * 60, now, p.UserId) end
		return old
	end
	local state = nil
	if stateMap then
		local ok, v = pcall(function() return stateMap:UpdateAsync("events", change, 7 * 24 * 3600) end)
		if ok and type(v) == "table" then state = v end
	end
	if not state then state = change(table.clone(events)) end
	audit(p.UserId, "event", { kind = kind, mult = mult, minutes = minutes })
	send({ c = "event", state = state })
	if mult > 1 then
		local ms = mult >= 1e6 and NumberFormat.short(mult) or tostring(mult)
		local label = EVENT_NAME[kind] .. " x" .. ms
		local cur = currentSeg(normalize(state[kind], os.time()), os.time())
		if cur and cur.m == mult then
			local col = kind == "luck" and "green" or (kind == "mutluck" and "purple" or "yellow")
			send({ c = "ann", text = "ADMIN ABUSE! " .. label .. " for " .. minutes .. " min!", color = col, sec = 8 })
			return { ok = true, text = label .. " started" }
		end
		return { ok = true, text = label .. " queued — starts after the bigger multiplier" }
	end
	return { ok = true, text = EVENT_NAME[kind] .. " event stopped (queue cleared)" }
end

function A.Events(p)
	local now = os.time()
	local out = {}
	for kind, e in events do
		for _, sgm in (e and e.q) or {} do
			if sgm.untilT > now then table.insert(out, { kind = kind, m = sgm.m, startIn = math.max(0, sgm.startT - now), left = sgm.untilT - math.max(now, sgm.startT) }) end
		end
	end
	return { ok = true, events = out }
end

function A.Servers(p)
	local list = {}
	for _, s in readPresence() do
		table.insert(list, { job = s.job, n = s.n or #(s.players or {}), up = os.time() - (s.start or os.time()), here = s.here, place = s.place })
	end
	return { ok = true, servers = list }
end

function A.Shutdown(p)
	audit(p.UserId, "shutdown", {})
	send({ c = "shutdown", by = p.UserId })
	return { ok = true, text = "Shutdown sent" }
end

function A.BanHistory(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	local ok, pages = pcall(function() return Players:GetBanHistoryAsync(u) end)
	if not ok then return { ok = false, error = "Ban history: " .. tostring(pages) } end
	local out = {}
	local okP, page = pcall(function() return pages:GetCurrentPage() end)
	for i, e in (okP and page or {}) do
		if i > 25 then break end
		table.insert(out, { ban = e.Ban, reason = e.DisplayReason, private = e.PrivateReason, dur = e.Duration, start = tostring(e.StartTime) })
	end
	return { ok = true, history = out }
end

function A.DM(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	local text = type(arg.text) == "string" and string.sub(arg.text, 1, 200) or ""
	if #text < 2 then return { ok = false, error = "Text is too short" } end
	local f = filterBroadcast(text, p.UserId)
	if not f then return { ok = false, error = "Filter failed, try again" } end
	if not whereIs(u) then return { ok = false, error = "Player is offline" } end
	audit(p.UserId, "dm", { u = u, text = f })
	send({ c = "dm", u = u, text = f, color = type(arg.color) == "string" and string.sub(arg.color, 1, 12) or "blue" })
	return { ok = true, text = "Message sent" }
end

function A.Teleport(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	local t = Players:GetPlayerByUserId(u)
	if t then
		local a, b = p.Character, t.Character
		if not (a and b) then return { ok = false, error = "No character" } end
		a:PivotTo(b:GetPivot() * CFrame.new(0, 0, 5))
		return { ok = true, text = "Teleported to @" .. t.Name }
	end
	local full = whereIsFull(u)
	if not full then return { ok = false, error = "Player is offline" } end
	audit(p.UserId, "teleport", { u = u, job = full })
	local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, full, p) end)
	if not ok then return { ok = false, error = "Teleport: " .. tostring(err) } end
	return { ok = true, text = "Teleporting to another server…" }
end

function A.Bring(p, arg)
	local u = resolveUser(arg)
	local t = u and Players:GetPlayerByUserId(u)
	if not t then return { ok = false, error = "Player is not on this server" } end
	local a, b = p.Character, t.Character
	if not (a and b) then return { ok = false, error = "No character" } end
	b:PivotTo(a:GetPivot() * CFrame.new(0, 0, -5))
	audit(p.UserId, "bring", { u = u })
	return { ok = true, text = "Brought @" .. t.Name }
end

function A.Freeze(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	if not whereIs(u) then return { ok = false, error = "Player is offline" } end
	audit(p.UserId, "freeze", { u = u, on = arg.on == true })
	send({ c = "freeze", u = u, on = arg.on == true })
	return { ok = true, text = arg.on and "Frozen" or "Unfrozen" }
end

function A.Roles(p)
	local list = {}
	for _, id in cfg.ADMINS or {} do
		local okN, name = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
		table.insert(list, { u = id, name = okN and name or "?", r = "owner", fixed = true })
	end
	for k, e in roles do
		if type(e) == "table" and not isOwnerId(tonumber(k) or 0) then
			table.insert(list, { u = tonumber(k), name = e.name or "?", r = e.r, by = e.by, t = e.t })
		end
	end
	return { ok = true, roles = list }
end

function A.SetRole(p, arg)
	local u = resolveUser(arg)
	if not u then return { ok = false, error = "User not found" } end
	if isOwnerId(u) then return { ok = false, error = "Owners are set in AdminConfig" } end
	local r = arg.role
	if r ~= "admin" and r ~= "mod" and r ~= "none" then return { ok = false, error = "Bad role" } end
	local okN, name = pcall(function() return Players:GetNameFromUserIdAsync(u) end)
	name = okN and name or "?"
	local function change(old)
		old = type(old) == "table" and old or {}
		if r == "none" then old[tostring(u)] = nil else old[tostring(u)] = { r = r, by = p.UserId, t = os.time(), name = name } end
		return old
	end
	local new
	if rolesMem then
		new = change(rolesMem); rolesMem = new
	else
		local ok, v = pcall(function() return rstore():UpdateAsync("roles", change) end)
		if ok then
			new = v
		elseif STUDIO then
			rolesMem = change(table.clone(roles)); new = rolesMem
		else
			return { ok = false, error = "DataStore: " .. tostring(v) }
		end
	end
	audit(p.UserId, "role", { u = u, role = r })
	send({ c = "roles", roles = new })
	return { ok = true, text = r == "none" and ("@" .. name .. " is no longer staff") or ("@" .. name .. " is now " .. string.upper(r)) }
end

-- arg.scope = "all" — увесь журнал дня (UTC) з усіх серверів, arg.back — скільки днів тому (0 — сьогодні); інакше — цей сервер
function A.Logs(p, arg)
	local out, list, day = {}, nil, nil
	if arg.scope == "all" then
		local back = math.clamp(math.floor(tonumber(arg.back) or 0), 0, 3650)
		day = os.date("!%Y%m%d", os.time() - back * 86400)
		list = GolemRegistry.History(day, 2000)
	else
		list = GolemRegistry.RecentLogs(150)
	end
	for _, e in list do
		table.insert(out, { t = e.t, e = e.e, u = e.u, g = e.g, k = e.k, m = e.m, r = e.r,
			x = type(e.x) == "table" and HttpService:JSONEncode(e.x) or (e.x ~= nil and tostring(e.x) or nil) })
	end
	return { ok = true, logs = out, day = day }
end

-- мінімальна роль для дії (усе, чого тут немає, — лише owner)
local PERM = {
	Players = "mod", PlayerInfo = "mod", Kick = "mod", Ban = "mod", BanHistory = "mod", FindUid = "mod", Announce = "mod",
	DM = "mod", Teleport = "mod", Bring = "mod", Freeze = "mod", Servers = "mod", Logs = "mod", Events = "mod",
	Unban = "admin", Give = "admin", GrantAll = "admin", Event = "admin",
	Shutdown = "owner", Roles = "owner", SetRole = "owner",
}
local function onInvoke(p: Player, action: any, arg: any)
	if not isAdmin(p) then suspect(p, action); return { ok = false, error = "denied" } end
	if limited(p) then return { ok = false, error = "Too fast" } end
	local fn = type(action) == "string" and A[action]
	if not fn then return { ok = false, error = "Unknown action" } end
	if not can(p, PERM[action] or "owner") then return { ok = false, error = "No permission (" .. tostring(PERM[action] or "owner") .. ")" } end
	-- модератор: бан лише тимчасовий, до 24 год
	if action == "Ban" and roleOf(p) == "mod" then
		local h = tonumber(type(arg) == "table" and arg.hours) or 0
		if h <= 0 or h > 24 then return { ok = false, error = "Moderators can ban for up to 24 h" } end
	end
	local ok, res = pcall(fn, p, type(arg) == "table" and arg or {})
	if not ok then
		warn("AdminService: " .. tostring(action) .. ": " .. tostring(res))
		return { ok = false, error = "Server error" }
	end
	return res
end

-- ===== гравці =====
local function giveUi(p: Player)
	if not isAdmin(p) then return end
	local src = ServerStorage:FindFirstChild("AdminUI")
	local gui = src and src:FindFirstChild("AdminPanelGui")
	if not gui then warn("AdminService: немає ServerStorage/AdminUI/AdminPanelGui"); return end
	local pg = p:WaitForChild("PlayerGui", 30)
	if not pg or pg:FindFirstChild("AdminPanelGui") then return end
	local c = gui:Clone()
	c.ResetOnSpawn = false
	c.Parent = pg
end

local function removeUi(p: Player)
	local pg = p:FindFirstChild("PlayerGui")
	local g = pg and pg:FindFirstChild("AdminPanelGui")
	if g then g:Destroy() end
end
local function refreshRole(p: Player)
	local r = roleOf(p)
	p:SetAttribute("AdminRole", r)
	if r then task.spawn(giveUi, p) else removeUi(p) end
end
function AdminService._applyRoles(map: any)
	roles = type(map) == "table" and map or {}
	if rolesMem then rolesMem = roles end
	for _, p in Players:GetPlayers() do refreshRole(p) end
end
-- заморожений гравець: HumanoidRootPart закріплено; атрибут AdminFrozen переживає респавн
function AdminService._freeze(p: Player, on: boolean)
	p:SetAttribute("AdminFrozen", on or nil)
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then hrp.Anchored = on end
	if broadcast then broadcast:FireClient(p, "toast", { text = on and "You were frozen by an admin" or "You can move again", color = on and "blue" or "green" }) end
end

local function onPlayer(p: Player)
	refreshRole(p)
	p.CharacterAdded:Connect(function(ch)
		if p:GetAttribute("AdminFrozen") then
			local hrp = ch:WaitForChild("HumanoidRootPart", 10)
			if hrp and hrp:IsA("BasePart") then hrp.Anchored = true end
		end
	end)
	if not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "AdminTx")
	txOf[p] = type(sec) == "table" and sec or {}
	while p.Parent == Players and (p:GetAttribute("InvReady") ~= true or p:GetAttribute("CaveReady") ~= true) do task.wait(0.2) end
	if p.Parent ~= Players then return end
	deliverMail(p)
	for _, g in activeGrants() do applyGrant(p, g, "G:" .. tostring(g.id)) end
end

local started = false
function AdminService.Start()
	if started then return end
	started = true
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local fn = remotes:FindFirstChild("AdminAction") or Instance.new("RemoteFunction")
	fn.Name = "AdminAction"; fn.Parent = remotes
	fn.OnServerInvoke = onInvoke
	broadcast = remotes:FindFirstChild("AdminBroadcast") or Instance.new("RemoteEvent")
	broadcast.Name = "AdminBroadcast"; broadcast.Parent = remotes

	DataService.RegisterSection("AdminTx", function(p, old)
		return txOf[p] or old
	end)
	Players.PlayerAdded:Connect(function(p)
		local b = sessionBans[p.UserId]
		if b and b.till > os.time() then p:Kick(b.reason); return end
		task.spawn(onPlayer, p)
	end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p)
		task.delay(5, function() txOf[p] = nil; rate[p] = nil end) -- після фінального збереження (DataService знімає знімок синхронно)
		task.defer(writePresence)
	end)
	Players.PlayerAdded:Connect(function() task.defer(writePresence) end)

	task.spawn(function()
		local ok, err = pcall(function() MessagingService:SubscribeAsync(TOPIC, onMessage) end)
		if not ok then warn("AdminService: MessagingService недоступний (" .. tostring(err) .. ") — команди діють лише на цьому сервері.") end
	end)
	task.spawn(function()
		while true do writePresence(); task.wait(PRESENCE_SEC) end
	end)
	-- ролі: при старті й раз на 2 хв (зміни з інших серверів приходять і повідомленням roles)
	task.spawn(function()
		while true do
			local m = loadRoles()
			if m then AdminService._applyRoles(m) end
			task.wait(120)
		end
	end)
	task.spawn(function()
		while true do readState(); task.wait(STATE_SEC) end
	end)
	-- черга подій: щосекунди перемикаємо на наступний відрізок / прибираємо атрибути, коли час минув
	task.spawn(function()
		while true do
			task.wait(1)
			applyEvents(table.clone(events))
		end
	end)
	game:BindToClose(function()
		if presenceMap then pcall(function() presenceMap:RemoveAsync(JOB) end) end
	end)
end

return AdminService
