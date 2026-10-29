--!strict
-- InventoryService — серверна частина інвентаря гравця: хотбар (9 слотів), предмет у руці, замки, видалення, големи й зілля.
-- Де: ServerScriptService/InventoryService (ModuleScript). Запуск: NicheBoot (після DataService).
-- Клієнт — StarterPlayerScripts/InventoryUI. Предмети й ключі — Shared/ItemConfig.
--
-- Стан — атрибути гравця (їх читає клієнт):
--   Ore_* / Bars_* (ставлять ForgeService, SellService), Pot_<зілля> — кількість;
--   InvGolems — JSON-список { { id, uid, kind, cls, mut, ix? } } (големи не стакаються; kind — ID з Shared/GolemCatalog,
--     uid — глобальний UID (GolemRegistry: Mint при появі, Burn при Delete; старі записи без UID отримують його при вході),
--     ix = 1 — голем у глобальному індексі (цінний / виданий адміном);
--     cls = "miner" | "carrier", mut — мутація 0..7). Старі ID (wood, iron…) при завантаженні замінюються новими (Catalog.LEGACY);
--   PlotPlaced (ставить PlotService) — id големів на плотах: вони лишаються в InvGolems (ліміт MAX_GOLEMS їх НЕ рахує — Items.invGolemCount),
--     але для інвентаря «не існують» (v24): зникають з хотбара й руки, їх не можна видалити / заблокувати; зняли з плоту — повертаються;
--   голем на стенді печери (CaveStandService) з InvGolems прибирається (лежить у секції Cave); TAKE повертає його через Give;
--   InvLocks — JSON-список заблокованих ключів (не видаляються, але їх можна брати в руку / пити / ставити в хотбар);
--   InvHotbar — JSON-список з 9 ключів ("" = порожній слот);  InvHeld — ключ предмета в руці ("" = нічого).
-- Збереження: секція "Inventory" у DataService (големи, зілля, замки, хотбар). Руда й злитки зберігаються як атрибути (DataService).
-- Хотбар — список без дірок: слот з'являється, коли гравець бере предмет у руку (у кінці), і зникає, коли прибирає його з рук
--   (або Unpin, або предмет закінчився); решта слотів зсуваються, нумерація 1..n без пропусків.
--
-- Дії (RemoteEvent ReplicatedStorage/Remotes/InventoryAction):
--   "Delete", { keys }        — видалити (стак — увесь; заблоковані пропускає);
--   "Lock",   { keys, on }    — заблокувати (on = true) / розблокувати;
--   "Hotbar", { ключі }       — новий список хотбара;
--   "Pin",    { key, on }      — кнопка Hotbar / Unpin: закріплений слот лишається після Put Away (InvPinned);
--   "Clear",  { ключі }       — кнопка «в інвентар»: ці предмети зникають з хотбара й руки;
--   "Use",    "Pot_<зілля>"   — випити зілля: −1, атрибут Boost_<зілля> = кінець дії (ItemConfig.boostLeft);
--   "Sort",   ключ (Shared/GolemSort.LIST) — сортування големів (атрибут InvSort, спільний для інвентаря й вікна плоту; зберігається в секції, поле sort);
--   "Hold",   ключ або ""     — взяти в руку (створює слот) / прибрати з рук (слот зникає). Модель у руці й табличку над
--                             големом показує HeldItemService (за атрибутом InvHeld).
-- Новий гравець (без збереженої секції) починає з порожнім інвентарем: тестові големи й зілля прибрано.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Items = require(RS:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local GolemSort = require(RS.Shared:WaitForChild("GolemSort"))
local GolemRegistry = require(script.Parent:WaitForChild("GolemRegistry"))

local InventoryService = {}
local N = Items.HOTBAR

local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function encode(p: Player, attr: string, v: any)
	p:SetAttribute(attr, HttpService:JSONEncode(v))
end

local function golems(p: Player): { any } return decode(p, "InvGolems", {}) end
local function locks(p: Player): { string } return decode(p, "InvLocks", {}) end
-- InvPinned — предмети, поставлені в хотбар кнопкою Hotbar: їхній слот ЛИШАЄТЬСЯ, коли предмет прибирають з рук
-- (для швидкого доступу, напр. зілля на лівий клік — наступний крок); слот зникає лише через Unpin або «в інвентар».
local function pins(p: Player): { string } return decode(p, "InvPinned", {}) end
local function isPinned(p: Player, key: string): boolean return table.find(pins(p), key) ~= nil end
-- хотбар — СПИСОК без дірок (1..n, n ≤ 9): слот є лише в того, що гравець брав у руку; прибрав з рук — слот зникає, решта зсуваються
local function hotbar(p: Player): { string }
	local h = decode(p, "InvHotbar", {})
	local out = {}
	for _, k in h do if type(k) == "string" and k ~= "" and #out < N and not table.find(out, k) then table.insert(out, k) end end
	return out
end

local function exists(p: Player, key: string): boolean
	if Items.isStack(key) then return ((p:GetAttribute(key) :: number?) or 0) > 0 end
	if string.sub(key, 1, 6) == "Golem_" then
		local id = tonumber(string.sub(key, 7))
		-- голем на плоті (PlotPlaced) — не в інвентарі (v24): його не можна взяти в руку / в хотбар / заблокувати / видалити
		if table.find(decode(p, "PlotPlaced", {}), id) then return false end
		for _, g in golems(p) do if g.id == id then return true end end
	end
	return false
end
local function isLocked(p: Player, key: string): boolean
	return table.find(locks(p), key) ~= nil
end
-- голем, що працює на плоті (PlotService ставить PlotPlaced), не видаляється
local function isPlaced(p: Player, key: string): boolean
	if string.sub(key, 1, 6) ~= "Golem_" then return false end
	return table.find(decode(p, "PlotPlaced", {}), tonumber(string.sub(key, 7))) ~= nil
end

-- додати предмет у кінець хотбара (новий слот), якщо його там ще немає і є місце
local function addHotbar(p: Player, key: string): boolean
	local h = hotbar(p)
	if table.find(h, key) then return true end
	if not exists(p, key) or #h >= N then return false end
	table.insert(h, key)
	encode(p, "InvHotbar", h)
	return true
end
local function removeHotbar(p: Player, key: string)
	local h = hotbar(p)
	local i = table.find(h, key)
	if i then table.remove(h, i); encode(p, "InvHotbar", h) end
end
-- прибрати з хотбара / руки / замків те, чого більше немає
local function cleanup(p: Player)
	local h = hotbar(p)
	local keep = {}
	for _, k in h do if exists(p, k) then table.insert(keep, k) end end
	if #keep ~= #h then encode(p, "InvHotbar", keep) end
	local held = p:GetAttribute("InvHeld")
	if type(held) == "string" and held ~= "" and not exists(p, held) then p:SetAttribute("InvHeld", "") end
	local l = locks(p)
	local keep = {}
	for _, k in l do if exists(p, k) or Items.isStack(k) or isPlaced(p, k) then table.insert(keep, k) end end -- замок голема на плоті лишається -- замок стака лишається (руда повернеться)
	if #keep ~= #l then encode(p, "InvLocks", keep) end
	-- закріплені — лише ті, що ще в хотбарі
	local hb = hotbar(p)
	local pl = pins(p)
	local keepP = {}
	for _, k in pl do if table.find(hb, k) then table.insert(keepP, k) end end
	if #keepP ~= #pl then encode(p, "InvPinned", keepP) end
end

local function onAction(p: Player, action: any, arg: any)
	if action == "Delete" and type(arg) == "table" then
		local gl = golems(p)
		local removeIds = {}
		for _, key in arg do
			if type(key) == "string" and #key < 40 and not isLocked(p, key) and not isPlaced(p, key) then
				if Items.isStack(key) then
					if ((p:GetAttribute(key) :: number?) or 0) > 0 then p:SetAttribute(key, 0) end
				elseif string.sub(key, 1, 6) == "Golem_" then
					local id = tonumber(string.sub(key, 7))
					if id then removeIds[id] = true end
				end
			end
		end
		if next(removeIds) then
			local keep = {}
			for _, g in gl do
				if removeIds[g.id] then GolemRegistry.Burn(p, g, "delete") else table.insert(keep, g) end -- видалення назавжди: UID зникає
			end
			encode(p, "InvGolems", keep)
		end
		cleanup(p)
	elseif action == "Lock" and type(arg) == "table" and type(arg.keys) == "table" then
		local l = locks(p)
		for _, key in arg.keys do
			if type(key) == "string" and #key < 40 and exists(p, key) then
				local i = table.find(l, key)
				if arg.on and not i then table.insert(l, key) elseif not arg.on and i then table.remove(l, i) end
			end
		end
		encode(p, "InvLocks", l)
	elseif action == "Hotbar" and type(arg) == "table" then
		local h = {}
		for _, k in arg do
			if type(k) == "string" and k ~= "" and #k < 40 and #h < N and exists(p, k) and not table.find(h, k) then table.insert(h, k) end
		end
		encode(p, "InvHotbar", h)
		cleanup(p)
	elseif action == "Pin" and type(arg) == "table" and type(arg.key) == "string" and #arg.key < 40 then
		-- кнопка Hotbar / Unpin: закріпити в хотбарі (слот не зникає після Put Away) або зняти (слот зникає)
		local pl = pins(p)
		local i = table.find(pl, arg.key)
		if arg.on then
			if addHotbar(p, arg.key) and not i then table.insert(pl, arg.key); encode(p, "InvPinned", pl) end
		else
			if i then table.remove(pl, i); encode(p, "InvPinned", pl) end
			removeHotbar(p, arg.key)
			if p:GetAttribute("InvHeld") == arg.key then p:SetAttribute("InvHeld", "") end
		end
	elseif action == "Clear" and type(arg) == "table" then
		-- «в інвентар»: прибрати з хотбара (і з руки) всі вказані предмети — клієнт шле ключі поточної вкладки
		local h, pl = hotbar(p), pins(p)
		local held = p:GetAttribute("InvHeld")
		for _, k in arg do
			if type(k) == "string" then
				local i = table.find(h, k); if i then table.remove(h, i) end
				local j = table.find(pl, k); if j then table.remove(pl, j) end
				if held == k then p:SetAttribute("InvHeld", "") end
			end
		end
		encode(p, "InvHotbar", h); encode(p, "InvPinned", pl)
	elseif action == "Sort" then
		if type(arg) == "string" and GolemSort.VALID[arg] then p:SetAttribute("InvSort", arg) end
	elseif action == "Use" and type(arg) == "string" and string.sub(arg, 1, 4) == "Pot_" then
		-- випити зілля: −1 і + час дії (Boost_<зілля> — коли скінчиться, час сервера; ще раз — додається)
		local def = Items.potion(string.sub(arg, 5))
		local n = (tonumber(p:GetAttribute(arg)) or 0) :: number
		if not def or n <= 0 then return end
		local now = workspace:GetServerTimeNow()
		if now - ((p:GetAttribute("PotUseT") :: number?) or 0) < 0.25 then return end -- не частіше 4 разів на секунду
		p:SetAttribute("PotUseT", now)
		p:SetAttribute(arg, n - 1)
		local cur = (tonumber(p:GetAttribute("Boost_" .. def.key)) or 0) :: number
		p:SetAttribute("Boost_" .. def.key, math.max(cur, now) + (def.dur or 300))
	elseif action == "Hold" then
		if arg == "" or arg == nil then -- прибрав з рук → слот цього предмета зникає (якщо він не закріплений кнопкою Hotbar)
			local held = p:GetAttribute("InvHeld")
			if type(held) == "string" and held ~= "" and not isPinned(p, held) then removeHotbar(p, held) end
			p:SetAttribute("InvHeld", "")
		elseif type(arg) == "string" and #arg < 40 and exists(p, arg) then -- узяв у руку → з'являється слот (у кінці)
			if addHotbar(p, arg) then p:SetAttribute("InvHeld", arg) end
		end
	end
end

local function sectionOf(p: Player, old: any): any
	if p:GetAttribute("InvReady") ~= true then return old end
	local pot = {}
	for _, d in Items.POTIONS do pot[d.key] = (p:GetAttribute("Pot_" .. d.key) :: number?) or 0 end
	local boosts = {} -- скільки секунд дії зіль лишилось (офлайн час не йде)
	for _, d in Items.POTIONS do
		local left = Items.boostLeft(p, d.key)
		if left > 1 then boosts[d.key] = math.floor(left) end
	end
	return { golems = golems(p), locks = locks(p), hotbar = hotbar(p), pinned = pins(p), potions = pot, boosts = boosts, sort = GolemSort.current(p) }
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "Inventory")
	if type(sec) == "table" then
		if type(sec.golems) == "table" then
			-- міграція: старі тестові ID → каталог, мутація за замовчуванням Normal; невідомих големів не губимо (лишаються як є)
			for _, g in sec.golems do
				if type(g) == "table" then
					g.kind = Catalog.id(g.kind) or g.kind
					g.mut = Catalog.mut(g.mut)
					GolemRegistry.Ensure(p, g, "inv") -- старий запис без UID → UID «legacy»
				end
			end
			-- той самий UID двічі (дюп) → лишається перший; спільний список UID — для перевірки печери (CaveStandService)
			local seen = {}
			local list = GolemRegistry.Dedupe(p, sec.golems, seen, "inv")
			encode(p, "InvGolems", list)
			GolemRegistry.CheckOwnership(p, list)
		end
		if type(sec.locks) == "table" then encode(p, "InvLocks", sec.locks) end
		if type(sec.hotbar) == "table" then encode(p, "InvHotbar", sec.hotbar) end
		encode(p, "InvPinned", type(sec.pinned) == "table" and sec.pinned or {})
		p:SetAttribute("InvSort", (type(sec.sort) == "string" and GolemSort.VALID[sec.sort]) and sec.sort or GolemSort.DEFAULT)
		for _, d in Items.POTIONS do
			local n = type(sec.potions) == "table" and tonumber(sec.potions[d.key]) or 0
			p:SetAttribute("Pot_" .. d.key, math.max(0, math.floor(n or 0)))
			local left = type(sec.boosts) == "table" and tonumber(sec.boosts[d.key]) or 0
			if left and left > 0 then p:SetAttribute("Boost_" .. d.key, workspace:GetServerTimeNow() + math.min(left, 7 * 86400)) end
		end
	else
		local gl = {} -- новий гравець починає з порожнім інвентарем (тестові големи й зілля прибрано)
		encode(p, "InvGolems", gl)
		encode(p, "InvLocks", {})
		encode(p, "InvHotbar", {})
		encode(p, "InvPinned", {})
		p:SetAttribute("InvSort", GolemSort.DEFAULT)
		for _, d in Items.POTIONS do
			p:SetAttribute("Pot_" .. d.key, 0)
		end
	end
	p:SetAttribute("InvHeld", "")
	cleanup(p)
	p:SetAttribute("InvReady", true)
	-- руда / злитки / зілля закінчилися → їхній слот зникає з хотбара
	p.AttributeChanged:Connect(function(name)
		-- голем став на плот (PlotPlaced) → прибрати його з хотбара й руки (v24)
		if name == "PlotPlaced" then task.defer(function() if p.Parent then cleanup(p) end end) end
		if Items.isStack(name) then
			task.defer(function()
				if p.Parent and not exists(p, name) then cleanup(p) end
			end)
		end
	end)
end

-- прибрати з руки / хотбара / замків те, чого вже немає (напр. голем щойно став на стенд печери)
function InventoryService.Refresh(p: Player)
	cleanup(p)
end

-- предмет щойно з'явився (голем зі стенда печери, TAKE): новий слот у кінці хотбара і в руку; хотбар повний — лише в інвентарі
function InventoryService.Give(p: Player, key: string)
	if addHotbar(p, key) then p:SetAttribute("InvHeld", key) end
end

-- новий голем у інвентар (купівля на підставці ролу, RollService): у кінець InvGolems. id дає викликач (більший за
-- CaveStandService.MaxId). false — інвентар не готовий, повний (Items.MAX_GOLEMS) або id зайнятий. Хотбар і рука — окремо (Give).
-- закріпити предмет у хотбарі, як кнопка Hotbar в інвентарі (дія "Pin", on = true): новий слот у кінці + InvPinned, без InvHeld.
-- Хотбар повний — лише в інвентарі. Бере RollService після купівлі голема на підставці ролу.
function InventoryService.Pin(p: Player, key: string)
	onAction(p, "Pin", { key = key, on = true })
end

-- reason — джерело для журналу GolemRegistry ("buy" за замовчуванням, "code:<код>", "admin:<userId>"); force — без ліміту MAX_GOLEMS (адмін).
-- Повертає (true, uid) або false. UID видається ЛИШЕ тут (Mint), тобто в момент появи голема в профілі.
function InventoryService.AddGolem(p: Player, id: number, kind: string, cls: string, mut: number, reason: string?, force: boolean?): (boolean, string?)
	if p:GetAttribute("InvReady") ~= true then return false end
	local gl = golems(p)
	if not force and Items.invGolemCount(gl, decode(p, "PlotPlaced", {})) >= Items.maxGolems(p) then return false end -- без големів на плотах
	for _, g in gl do if type(g) == "table" and g.id == id then return false end end
	local rec = GolemRegistry.Mint(p, { id = id, kind = Catalog.id(kind) or kind, cls = Catalog.cls(cls), mut = Catalog.mut(mut) }, reason or "buy")
	table.insert(gl, rec)
	encode(p, "InvGolems", gl)
	return true, rec.uid
end

-- голем інвентаря (разом з тими, що на плотах) за UID → запис | nil
function InventoryService.FindByUid(p: Player, uid: string): any
	for _, g in golems(p) do if type(g) == "table" and g.uid == uid then return g end end
	return nil
end

-- видалити голема за UID назавжди (адмін-панель): навіть заблокованого й з плоту (PlotService сам прибере його з плоту).
-- Повертає запис або nil.
function InventoryService.RemoveByUid(p: Player, uid: string, reason: string): any
	if p:GetAttribute("InvReady") ~= true then return nil end
	local gl = golems(p)
	local keep, found = {}, nil
	for _, g in gl do
		if type(g) == "table" and g.uid == uid and not found then found = g else table.insert(keep, g) end
	end
	if not found then return nil end
	GolemRegistry.Burn(p, found, reason)
	encode(p, "InvGolems", keep)
	local l = locks(p)
	local i = table.find(l, "Golem_" .. tostring(found.id))
	if i then table.remove(l, i); encode(p, "InvLocks", l) end
	cleanup(p)
	return found
end

-- нова мапа (MapService, GDD - Maps): големи інвентаря скидаються, КРІМ Exclusive (Catalog exclusive).
-- Големи на стендах печери й у машинах мутацій — окремі атрибути, їх не чіпаємо. Повертає скільки прибрано.
function InventoryService.ResetForNewMap(p: Player): number
	if p:GetAttribute("InvReady") ~= true then return 0 end
	local keep, n = {}, 0
	for _, g in golems(p) do
		local def = type(g) == "table" and Catalog.GOLEMS[Catalog.id(g.kind) or g.kind] or nil
		if def and def.exclusive then table.insert(keep, g)
		elseif type(g) == "table" then GolemRegistry.Burn(p, g, "newmap"); n += 1 end
	end
	encode(p, "InvGolems", keep)
	p:SetAttribute("PlotPlaced", nil)
	cleanup(p)
	return n
end

function InventoryService.Start()
	DataService.RegisterSection("Inventory", sectionOf)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("InventoryAction") or Instance.new("RemoteEvent")
	ev.Name = "InventoryAction"; ev.Parent = remotes
	ev.OnServerEvent:Connect(onAction)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	-- дія зілля скінчилась → атрибут Boost_<зілля> = nil (на нього підписані MultiService і BoostsHUD)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = workspace:GetServerTimeNow()
			for _, p in Players:GetPlayers() do
				for _, d in Items.POTIONS do
					local u = p:GetAttribute("Boost_" .. d.key)
					if u ~= nil and (tonumber(u) or 0) <= now then p:SetAttribute("Boost_" .. d.key, nil) end
				end
			end
		end
	end)
end

return InventoryService
