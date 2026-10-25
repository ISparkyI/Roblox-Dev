--!strict
-- InventoryService — серверна частина інвентаря гравця: хотбар (9 слотів), предмет у руці, замки, видалення, големи й зілля.
-- Де: ServerScriptService/InventoryService (ModuleScript). Запуск: NicheBoot (після DataService).
-- Клієнт — StarterPlayerScripts/InventoryUI. Предмети й ключі — Shared/ItemConfig.
--
-- Стан — атрибути гравця (їх читає клієнт):
--   Ore_* / Bars_* (ставлять ForgeService, SellService), Pot_<зілля> — кількість;
--   InvGolems — JSON-список { { id, kind, cls } } (големи не стакаються; cls = "miner" | "carrier");
--   PlotPlaced (ставить PlotService) — id големів на плотах: їх не можна видалити;
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
--   "Hold",   ключ або ""     — взяти в руку (створює слот) / прибрати з рук (слот зникає). Модель у руці — наступний крок.
-- ТЕСТ: у Studio без збереженої секції — тестові големи й зілля (ItemConfig.TEST_*).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Items = require(RS:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

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
	for _, k in l do if exists(p, k) or Items.isStack(k) then table.insert(keep, k) end end -- замок стака лишається (руда повернеться)
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
			for _, g in gl do if not removeIds[g.id] then table.insert(keep, g) end end
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
	return { golems = golems(p), locks = locks(p), hotbar = hotbar(p), pinned = pins(p), potions = pot }
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "Inventory")
	if type(sec) == "table" then
		if type(sec.golems) == "table" then encode(p, "InvGolems", sec.golems) end
		if type(sec.locks) == "table" then encode(p, "InvLocks", sec.locks) end
		if type(sec.hotbar) == "table" then encode(p, "InvHotbar", sec.hotbar) end
		encode(p, "InvPinned", type(sec.pinned) == "table" and sec.pinned or {})
		for _, d in Items.POTIONS do
			local n = type(sec.potions) == "table" and tonumber(sec.potions[d.key]) or 0
			p:SetAttribute("Pot_" .. d.key, math.max(0, math.floor(n or 0)))
		end
	else
		local gl = {}
		if RunService:IsStudio() then -- ТЕСТ: зілля й големи для перевірки вкладок
			for i, e in Items.TEST_GOLEMS do
				local kind, cls = string.match(e, "^(%w+):?(%w*)$")
				table.insert(gl, { id = i, kind = kind, cls = (cls == "carrier") and "carrier" or "miner" })
			end
		end
		encode(p, "InvGolems", gl)
		encode(p, "InvLocks", {})
		encode(p, "InvHotbar", {})
		encode(p, "InvPinned", {})
		for _, d in Items.POTIONS do
			p:SetAttribute("Pot_" .. d.key, RunService:IsStudio() and (Items.TEST_POTIONS[d.key] or 0) or 0)
		end
	end
	p:SetAttribute("InvHeld", "")
	cleanup(p)
	p:SetAttribute("InvReady", true)
	-- руда / злитки / зілля закінчилися → їхній слот зникає з хотбара
	p.AttributeChanged:Connect(function(name)
		if Items.isStack(name) then
			task.defer(function()
				if p.Parent and not exists(p, name) then cleanup(p) end
			end)
		end
	end)
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
end

return InventoryService
