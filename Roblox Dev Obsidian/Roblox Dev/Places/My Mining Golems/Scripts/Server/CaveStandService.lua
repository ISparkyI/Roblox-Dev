--!strict
-- CaveStandService — стенди (Cave слоти) у печері-сховищі големів: купівля за Money, до 3 големів на стенді, збереження.
-- Де: ServerScriptService/CaveStandService (ModuleScript). Запуск: NicheBoot (після InventoryService і HeldItemService).
-- Печеру будує CaveService (Workspace/Caves/Cave_<N> під нішею власника); тут — лише стенди в ній.
--
-- 10.11.2026 v2 (рішення користувача): на стенді — ТРИ големи: один майнер, один воїн, один носій (вид голема будь-який,
--   але двох одного класу на одному стенді не буває). Вікно стенда — StarterPlayerScripts/CaveStandUI (як PLACE GOLEMS на плоті).
-- Правила: 14 стендів, номер — атрибут SlotIndex (1–14), ціна — атрибут Price (Money). Купувати можна лише наступний (1 → 14).
--   Діє лише власник печери, який зараз у ній (CaveAccess.canInteract) і стоїть поруч (REACH / UI_REACH).
--   Кнопка стенда (StandPrompt, E, затиск HOLD с; вигляд — CustomPrompts, напис — CaveStandsClient):
--   * не куплений, наступний — «BUY $…»; інші — «LOCKED»;
--   * куплений: у руці голем, чий клас на стенді вільний — «PLACE» (E ставить його одразу); інакше — «OPEN» (вікно стенда).
--   Вікно → Remotes/CaveAction: "Place" { slot, id } — поставити голема з інвентаря (клас зайнятий — заміна: старий іде в
--   інвентар); "Take" { slot, role } — забрати в інвентар (інвентар повний — ні).
--   Голем з плоту теж можна поставити: він зникає з InvGolems — PlotService сам знімає його з плоту (sanitize).
--   Ексклюзиви й големи без 3D-моделі в печеру не ставляться.
--   Голем на стенді ПРИБРАНИЙ з інвентаря (InvGolems): повний запис { id, uid, kind, cls, mut, ix?, locked? } лежить на стенді
--   (UID той самий — GolemRegistry; TAKE повертає голема з тим самим UID).
-- Після покупки: на камені-ціннику (PriceBoard) ціну сховано, зелене світло вимкнено.
-- Големи на стенді трикутником спинами один до одного, обличчям назовні (ROLE_ANG), моделі StandGolem_<клас>,
--   аніматор у позі Idle, над кожним — табличка (HeldItemService.InfoBoard).
--
-- Стан гравця (атрибути, їх читає клієнт):
--   CaveStands — JSON-список куплених номерів; CaveStandGolems — JSON { ["<номер>:<клас>"] = { id, uid, kind, cls, mut, locked? } };
--   CaveReady = true — дані завантажено. Ліміт MAX_GOLEMS рахує лише інвентар.
-- На стенді-моделі: Bought (bool), G_miner / G_warrior / G_carrier (id голема або nil), GolemCount, GolemId (будь-який — сумісність);
--   на печері — StandsBought.
-- Збереження: секція "Cave" у DataService — { bought = {номери}, golems = { ["<номер>:<клас>"] = запис } }. НЕ скидається на новій мапі.
--   Старий формат (ключ "<номер>" — один голем на стенді; ще раніше — лише id) переноситься при вході в ключ "<номер>:<клас голема>".
--
-- Навчання Cave (10.11.2026): перший раз, коли гравець на мапі 1 тисне MAP 2 і в печері немає жодного голема, MapService
--   не пускає ("cave") і ставить атрибут CaveTut = "on". Клієнт (TutorialClient) веде: вхід у печеру → купити стенд →
--   відкрити його → поставити найкращих големів: майнера, носія і воїна (воїна — лише якщо він у гравця є; клас, якого
--   в інвентарі немає взагалі, пропускається). Кінець — коли в печері є голем кожного класу, який у гравця був:
--   CaveTut = nil, CaveTutDone = true (DataService, global). Поки навчання йде, MAP 2 не пускає (MapService).
--   Funnel CaveTutorial: 1 Started · 2 Entered cave · 3 Bought slot · 4 Opened slot · 5 Saved golem · 6 Saved all classes.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local PPS = game:GetService("ProximityPromptService")
local AnalyticsService = game:GetService("AnalyticsService")

local DataService = require(script.Parent:WaitForChild("DataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local HeldItemService = require(script.Parent:WaitForChild("HeldItemService"))
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local CaveAccess = require(RS.Shared:WaitForChild("CaveAccess"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local GolemModel = require(RS.Shared:WaitForChild("GolemModel"))
local GolemRegistry = require(script.Parent:WaitForChild("GolemRegistry"))

local CaveStandService = {}

local MAX = 14
local ROLES = { "miner", "warrior", "carrier" }
-- 10.11.2026: големи трикутником спинами один до одного, кожен дивиться назовні (рішення користувача): майнер — на стороні
--   до цінника (обличчям у прохід), воїн і носій — на двох задніх сторонах трикутника. ROLE_ANG[клас] — поворот напряму
--   «до цінника» навколо вертикалі, градуси; голем стоїть на TRI_R стад від центру майданчика в цьому напрямі й дивиться туди ж.
local ROLE_ANG = { miner = 0, warrior = 120, carrier = -120 }
local TRI_R = 3.7
local STAND_SCALE = 0.85 -- 10.11.2026: големи на стенді на 15 % менші за свій звичайний розмір
local ROLE_SIDE = ROLE_ANG -- для перевірки назви класу в діях вікна
local HOLD = 0.5          -- затиск кнопки стенда, с
local PROMPT_DIST = 11    -- з якої відстані видно кнопку, стад
local REACH = 15          -- сервер: максимальна відстань гравця до кнопки, стад
local UI_REACH = 34       -- сервер: дії з вікна стенда — гравець не далі, стад
local BTN_FWD = 3.6       -- кнопка: від центру майданчика в бік цінника, стад
local BTN_UP = 2.4        -- кнопка: над верхом майданчика, стад
local BOARD_SCALE = 1.25  -- табличка над големом на стенді
local ENTER_GRACE = 1.2   -- с після входу в печеру, поки кнопки стендів не діють
local FUNNEL = "CaveTutorial"
local STEPS = { "Started", "Entered cave", "Bought slot", "Opened slot", "Saved golem", "Saved all classes" }

-- ===== дані гравця =====
local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function boughtOf(p: Player): { number } return decode(p, "CaveStands", {}) end
local function golemsOf(p: Player): { [string]: any } return decode(p, "CaveStandGolems", {}) end
local function keyOf(slot: number, role: string): string return tostring(slot) .. ":" .. role end
local function invGolem(p: Player, id: number): any
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and g.id == id then return g end
	end
	return nil
end
-- голем може стояти в печері: є 3D-модель і не ексклюзив
local function caveable(kind: any): boolean
	local def = Catalog.get(kind)
	return def ~= nil and def.model ~= nil and not def.exclusive
end

-- ===== печера і стенди =====
local function caveOf(p: Player): Model?
	local caves = workspace:FindFirstChild("Caves")
	if not caves then return nil end
	for _, c in caves:GetChildren() do
		if c:IsA("Model") and c:GetAttribute("OwnerUserId") == p.UserId then return c end
	end
	return nil
end
local function standsOf(cave: Model): { [number]: Model }
	local out = {}
	local f = cave:FindFirstChild("Stands")
	if f then
		for _, s in f:GetChildren() do
			local i = s:GetAttribute("SlotIndex")
			if s:IsA("Model") and type(i) == "number" then out[i] = s end
		end
	end
	return out
end
local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end
-- центр і верх майданчика, напрям до цінника
local function standFrame(stand: Model): (Vector3?, Vector3?)
	local bed = stand:FindFirstChild("Bed")
	local board = stand:FindFirstChild("PriceBoard")
	if not (bed and bed:IsA("BasePart") and board and board:IsA("BasePart")) then return nil, nil end
	local top = Vector3.new(bed.Position.X, bed.Position.Y + bed.Size.Y / 2, bed.Position.Z)
	local d = flat(board.Position - bed.Position)
	return top, (d.Magnitude > 0.01) and d.Unit or Vector3.new(0, 0, -1)
end

-- кнопка стенда (один раз на копію печери)
local function prepareStand(stand: Model)
	if stand:FindFirstChild("StandButton") then return end
	local top, dir = standFrame(stand)
	if not top or not dir then return end
	local a = Instance.new("Part")
	a.Name = "StandButton"
	a.Size = Vector3.new(1, 1, 1); a.Transparency = 1
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false
	a.CFrame = CFrame.new(top + dir * BTN_FWD + Vector3.new(0, BTN_UP, 0))
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "StandPrompt"
	pr.Style = Enum.ProximityPromptStyle.Custom
	pr.ActionText = "Stand"; pr.ObjectText = "Golem Stand"
	pr.HoldDuration = HOLD
	pr.MaxActivationDistance = PROMPT_DIST
	pr.RequiresLineOfSight = false
	pr.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally -- лише найближча кнопка стенда
	pr.Enabled = false -- вмикає клієнт (лише власнику)
	pr:SetAttribute("UIText", "BUY")
	pr:SetAttribute("UIColor", "green")
	pr:SetAttribute("UIOffsetY", 0)
	pr:SetAttribute("UIWidth", 7.2)
	pr.Parent = a
	a.Parent = stand
end

-- вигляд цінника: куплено — ціни немає, світло вимкнено (камінь сірий, як бортики)
local function paintBoard(stand: Model, bought: boolean)
	local board = stand:FindFirstChild("PriceBoard")
	if not board then return end
	local gui = board:FindFirstChild("PriceGui")
	local price = gui and gui:FindFirstChild("Price")
	if price and price:IsA("GuiObject") then price.Visible = not bought end
	for _, l in board:GetChildren() do
		if l:IsA("Light") then l.Enabled = not bought end
	end
end

-- модель голема на стенді (Shared/GolemModel.build — та сама, що для підставок ролу)
local function golemModel(g: any, role: string): Model?
	local m = GolemModel.build(g.kind, g.cls)
	if not m then return nil end
	pcall(function() m:ScaleTo(m:GetScale() * STAND_SCALE) end)
	m.Name = "StandGolem_" .. role
	m:SetAttribute("GolemId", g.id); m:SetAttribute("Mut", Catalog.mut(g.mut))
	return m
end

local function placeGolem(stand: Model, g: any, role: string): Model?
	local top, dir = standFrame(stand)
	if not top or not dir then return nil end
	local m = golemModel(g, role)
	if not m then return nil end
	local side = dir:Cross(Vector3.yAxis)
	side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
	-- стопи на майданчику: низ рамки моделі (поки стоїть прямо) відносно півота
	local cf, size = m:GetBoundingBox()
	local up = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
	local out = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(ROLE_ANG[role] or 0)):VectorToWorldSpace(dir)
	local pos = top + out * TRI_R + Vector3.new(0, up, 0)
	m:PivotTo(CFrame.lookAt(pos, pos + out)) -- обличчям назовні
	m.Parent = stand
	local root = m:FindFirstChild("Root") or m.PrimaryPart
	if root and root:IsA("BasePart") then
		local cf2, size2 = m:GetBoundingBox()
		local headTop = cf2.Position.Y + size2.Y / 2 - root.Position.Y
		local def = Catalog.get(g.kind)
		HeldItemService.InfoBoard(root, headTop, def, Catalog.cls(g.cls), Catalog.mut(g.mut))
		local bb = root:FindFirstChild("GolemInfo")
		if bb and bb:IsA("BillboardGui") then
			bb.Size = UDim2.fromScale(3.6 * BOARD_SCALE, 1.6 * BOARD_SCALE)
			bb.StudsOffsetWorldSpace = Vector3.new(0, headTop + 0.8 * BOARD_SCALE, 0)
		end
	end
	return m
end

-- привести печеру гравця у відповідність до його даних
local function applyCave(p: Player)
	if p:GetAttribute("CaveReady") ~= true then return end
	local cave = caveOf(p)
	if not cave then return end
	local bought = {}
	for _, i in boughtOf(p) do bought[i] = true end
	local gl = golemsOf(p)
	local n = 0
	for slot, stand in standsOf(cave) do
		prepareStand(stand)
		local b = bought[slot] == true
		if b then n += 1 end
		stand:SetAttribute("Bought", b)
		paintBoard(stand, b)
		local legacy = stand:FindFirstChild("StandGolem") -- модель v1 (один голем на стенді)
		if legacy then legacy:Destroy() end
		local cnt, anyId = 0, nil
		for _, role in ROLES do
			local g = b and gl[keyOf(slot, role)] or nil
			local cur = stand:FindFirstChild("StandGolem_" .. role)
			local sig = g and (tostring(g.id) .. ":" .. tostring(g.kind) .. ":" .. tostring(g.cls) .. ":" .. tostring(g.mut)) or nil
			if cur and cur:GetAttribute("Sig") ~= sig then cur:Destroy(); cur = nil end
			if g and not cur then
				local m = placeGolem(stand, g, role)
				if m then m:SetAttribute("Sig", sig) end
			end
			stand:SetAttribute("G_" .. role, g and g.id or nil)
			if g then cnt += 1; anyId = anyId or g.id end
		end
		stand:SetAttribute("GolemCount", cnt)
		stand:SetAttribute("GolemId", anyId)
	end
	cave:SetAttribute("StandsBought", n)
end

-- ===== навчання Cave: funnel і кінець =====
local tutLogged: { [Player]: number } = {}
local function tutStep(p: Player, n: number)
	if p:GetAttribute("CaveTut") == nil then return end
	local done = tutLogged[p] or 0
	for k = done + 1, n do
		pcall(function() AnalyticsService:LogFunnelStepEvent(p, FUNNEL, tostring(p.UserId), k, STEPS[k]) end)
	end
	if n > done then tutLogged[p] = n end
end
local function tutCheck(p: Player)
	if p:GetAttribute("CaveTut") == nil then return end
	tutStep(p, 1)
	if p:GetAttribute("InCave") == true then tutStep(p, 2) end
	if #boughtOf(p) > 0 and p:GetAttribute("InCave") == true then tutStep(p, 3) end
	local gl = golemsOf(p)
	if next(gl) == nil then return end
	tutStep(p, 5)
	-- ще треба: клас, якого в печері немає, а в інвентарі є голем, що може стояти в печері
	local have = {}
	for _, g in gl do if type(g) == "table" then have[Catalog.cls(g.cls)] = true end end
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and caveable(g.kind) and not have[Catalog.cls(g.cls)] then return end
	end
	tutStep(p, 6)
	p:SetAttribute("CaveTutDone", true)
	p:SetAttribute("CaveTut", nil)
end

-- записати стан у атрибути й оновити печеру
local function publish(p: Player, bought: { number }, gl: { [string]: any })
	table.sort(bought)
	p:SetAttribute("CaveStands", HttpService:JSONEncode(bought))
	p:SetAttribute("CaveStandGolems", HttpService:JSONEncode(gl))
	applyCave(p)
	tutCheck(p)
end

-- запис голема (лише потрібні поля)
local function record(g: any): any
	return { id = g.id, uid = g.uid, kind = Catalog.id(g.kind) or g.kind, cls = Catalog.cls(g.cls), mut = Catalog.mut(g.mut),
		ix = g.ix, locked = g.locked == true or nil }
end
-- прибрати голема з інвентаря (InvGolems; замок запам'ятовується в записі)
local function takeFromInventory(p: Player, id: number): any
	local list = decode(p, "InvGolems", {})
	local keep, found = {}, nil
	for _, g in list do
		if type(g) == "table" and g.id == id and not found then found = g else table.insert(keep, g) end
	end
	if not found then return nil end
	local rec = record(found)
	local locks = decode(p, "InvLocks", {})
	if table.find(locks, "Golem_" .. id) then rec.locked = true end
	p:SetAttribute("InvGolems", HttpService:JSONEncode(keep))
	return rec
end

-- найбільший id голема гравця (інвентар + стенди): нові големи мають брати id більший за нього
function CaveStandService.MaxId(p: Player): number
	local m = 0
	for _, g in decode(p, "InvGolems", {}) do if type(g) == "table" and type(g.id) == "number" then m = math.max(m, g.id) end end
	for _, g in golemsOf(p) do if type(g) == "table" and type(g.id) == "number" then m = math.max(m, g.id) end end
	-- големи в Mutation Machines (MutationService, атрибут MutMachines)
	for _, mm in decode(p, "MutMachines", {}) do
		if type(mm) == "table" and type(mm.slots) == "table" then
			for _, g in mm.slots do if type(g) == "table" and type(g.id) == "number" then m = math.max(m, g.id) end end
		end
	end
	-- збережені секції DataService (03.11.2026): на сервері Marketplace сервіси печери й Mutation Machines не стартують, тож
	-- CaveStandGolems / MutMachines немає — беремо id з усіх секцій (записи з kind і числовим id), щоб новий голем не взяв зайнятий id
	local d = DataService.GetData(p)
	if d and type(d.sections) == "table" then
		local function scan(t: any, depth: number)
			if depth > 6 or type(t) ~= "table" then return end
			if type(t.id) == "number" and type(t.kind) == "string" then m = math.max(m, t.id) end
			for _, v in t do if type(v) == "table" then scan(v, depth + 1) end end
		end
		scan(d.sections, 0)
	end
	return m
end

-- повернути запис зі стенда в інвентар (у кінець InvGolems; замок відновлюється). Повертає id в інвентарі.
local function backToInventory(p: Player, rec: any): number
	local list = decode(p, "InvGolems", {})
	for _, g in list do
		if type(g) == "table" and g.id == rec.id then rec.id = CaveStandService.MaxId(p) + 1; break end -- id уже зайнятий
	end
	table.insert(list, { id = rec.id, uid = rec.uid, kind = rec.kind, cls = rec.cls, mut = rec.mut, ix = rec.ix })
	p:SetAttribute("InvGolems", HttpService:JSONEncode(list))
	if rec.locked == true then
		local locks = decode(p, "InvLocks", {})
		if not table.find(locks, "Golem_" .. rec.id) then table.insert(locks, "Golem_" .. rec.id) end
		p:SetAttribute("InvLocks", HttpService:JSONEncode(locks))
	end
	return rec.id
end

-- голем на стенді за UID → (ключ "<номер>:<клас>", запис) | nil
function CaveStandService.FindByUid(p: Player, uid: string): (string?, any)
	for k, g in golemsOf(p) do
		if type(g) == "table" and g.uid == uid then return k, g end
	end
	return nil, nil
end

-- видалити голема зі стенда за UID назавжди (адмін-панель). Повертає запис або nil.
function CaveStandService.RemoveByUid(p: Player, uid: string, reason: string): any
	if p:GetAttribute("CaveReady") ~= true then return nil end
	local gl = golemsOf(p)
	for k, g in gl do
		if type(g) == "table" and g.uid == uid then
			gl[k] = nil
			GolemRegistry.Burn(p, g, reason)
			publish(p, boughtOf(p), gl)
			return g
		end
	end
	return nil
end

-- ===== дії =====
-- поставити голема з інвентаря на стенд slot (клас зайнятий — заміна, старий — в інвентар)
local function placeOn(p: Player, slot: number, id: number): boolean
	local bought = boughtOf(p)
	if not table.find(bought, slot) then return false end
	local g = invGolem(p, id)
	if not g or not caveable(g.kind) then return false end
	local role = Catalog.cls(g.cls)
	local gl = golemsOf(p)
	local key = keyOf(slot, role)
	local old = gl[key]
	local rec = takeFromInventory(p, id)
	if not rec then return false end
	if old then backToInventory(p, old) end
	gl[key] = rec
	publish(p, bought, gl)
	InventoryService.Refresh(p) -- голема вже немає: з руки, хотбара й замків
	return true
end
-- забрати голема класу role зі стенда slot в інвентар (give — ще й у руку)
local function takeOff(p: Player, slot: number, role: string, give: boolean): boolean
	local gl = golemsOf(p)
	local key = keyOf(slot, role)
	local rec = gl[key]
	if not rec then return false end
	if Items.invGolemCount(decode(p, "InvGolems", {}), decode(p, "PlotPlaced", {})) >= Items.maxGolems(p) then return false end -- без големів на плотах
	gl[key] = nil
	local id = backToInventory(p, rec)
	publish(p, boughtOf(p), gl)
	if give then InventoryService.Give(p, "Golem_" .. id) else InventoryService.Refresh(p) end
	return true
end

local last: { [Player]: number } = {}
local enterT: { [Player]: number } = {}

local function onTrigger(prompt: ProximityPrompt, p: Player)
	if prompt.Name ~= "StandPrompt" then return end
	local anchor = prompt.Parent
	local stand = anchor and anchor.Parent
	if not (anchor and anchor:IsA("BasePart") and stand and stand:IsA("Model")) then return end
	local cave = stand:FindFirstAncestorWhichIsA("Model")
	while cave and cave.Parent ~= workspace:FindFirstChild("Caves") do cave = cave:FindFirstAncestorWhichIsA("Model") end
	if not cave then return end
	local ownerId = (cave:GetAttribute("OwnerUserId") :: number?) or 0
	if ownerId ~= p.UserId or not CaveAccess.canInteract(p, ownerId) then return end
	if p:GetAttribute("CaveReady") ~= true then return end
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) or (hrp.Position - anchor.Position).Magnitude > REACH then return end
	local t = os.clock()
	if last[p] and t - last[p] < 0.3 then return end
	if enterT[p] and t - enterT[p] < ENTER_GRACE then return end
	last[p] = t

	local slot = stand:GetAttribute("SlotIndex")
	if type(slot) ~= "number" then return end
	local bought = boughtOf(p)
	if not table.find(bought, slot) then
		-- купівля: лише наступний по черзі, і грошей має вистачати
		if slot ~= #bought + 1 then return end
		local price = (stand:GetAttribute("Price") :: number?) or math.huge
		local money = (p:GetAttribute("Money") :: number?) or 0
		if money < price then return end
		p:SetAttribute("Money", money - price)
		table.insert(bought, slot)
		publish(p, bought, golemsOf(p))
		return
	end
	-- PLACE: голем з руки, якщо його клас на стенді вільний (інакше клієнт відкриває вікно стенда — OPEN)
	local held = p:GetAttribute("InvHeld")
	if type(held) ~= "string" or string.sub(held, 1, 6) ~= "Golem_" then return end
	local id = tonumber(string.sub(held, 7))
	local g = id and invGolem(p, id)
	if not g or not caveable(g.kind) then return end
	if golemsOf(p)[keyOf(slot, Catalog.cls(g.cls))] then return end
	placeOn(p, slot, id :: number)
end

-- вікно стенда (CaveStandUI): власник у своїй печері, стенд куплений, гравець поруч
local actT: { [Player]: number } = {}
local function onAction(p: Player, action: any, arg: any)
	local t = os.clock()
	if actT[p] and t - actT[p] < 0.15 then return end
	actT[p] = t
	if action == "TutOpened" then
		if p:GetAttribute("CaveTut") ~= nil then tutStep(p, 4) end
		return
	end
	if type(arg) ~= "table" then return end
	local slot = tonumber(arg.slot)
	if not slot or slot ~= math.floor(slot) or slot < 1 or slot > MAX then return end
	if p:GetAttribute("CaveReady") ~= true or not CaveAccess.canInteract(p, p.UserId) then return end
	local cave = caveOf(p)
	local stand = cave and standsOf(cave)[slot]
	local anchor = stand and stand:FindFirstChild("StandButton")
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not (anchor and anchor:IsA("BasePart") and hrp and hrp:IsA("BasePart")) then return end
	if (hrp.Position - anchor.Position).Magnitude > UI_REACH then return end
	if not table.find(boughtOf(p), slot) then return end
	if action == "Place" and type(arg.id) == "number" then
		placeOn(p, slot, arg.id)
	elseif action == "Take" and type(arg.role) == "string" and ROLE_SIDE[arg.role] then
		takeOff(p, slot, arg.role, false)
	end
end

-- ===== вхід, збереження =====
local function onPlayer(p: Player)
	p:GetAttributeChangedSignal("InCave"):Connect(function()
		if p:GetAttribute("InCave") then enterT[p] = os.clock() end
		tutCheck(p)
	end)
	p:GetAttributeChangedSignal("CaveTut"):Connect(function() tutCheck(p) end)
	p:GetAttributeChangedSignal("InvGolems"):Connect(function() if p:GetAttribute("CaveTut") ~= nil then task.defer(tutCheck, p) end end)
	if not DataService.WaitLoaded(p) then return end
	while p.Parent == Players and p:GetAttribute("InvReady") ~= true do task.wait(0.1) end -- InvGolems від InventoryService
	if p.Parent ~= Players then return end
	local sec = DataService.GetSection(p, "Cave")
	local bought: { number } = {}
	local gl: { [string]: any } = {}
	if type(sec) == "table" then
		if type(sec.bought) == "table" then
			for _, i in sec.bought do
				local n = tonumber(i)
				if n and n >= 1 and n <= MAX and n == math.floor(n) and not table.find(bought, n) then table.insert(bought, n) end
			end
		end
		if type(sec.golems) == "table" then
			for k, v in sec.golems do
				local sk = string.match(tostring(k), "^(%d+):%a+$")
				local slot = tonumber(sk or k)
				if slot and table.find(bought, slot) then
					if type(v) == "table" and type(v.id) == "number" and Catalog.get(v.kind) then
						local rec = record(v)
						local key = keyOf(slot, rec.cls) -- клас — із запису (старий ключ "<номер>" теж сюди)
						if not gl[key] then gl[key] = rec end
					elseif not sk and tonumber(v) then -- найстаріший формат: лише id, голем ще в інвентарі — переносимо
						local rec = takeFromInventory(p, tonumber(v) :: number)
						if rec then
							local key = keyOf(slot, rec.cls)
							if gl[key] then backToInventory(p, rec) else gl[key] = rec end
						end
					end
				end
			end
		end
	end
	-- UID: старі записи без UID отримують його; голем, чий UID уже є в інвентарі (дюп), зі стенда прибирається
	local seen: { [string]: boolean } = {}
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and GolemRegistry.IsUid(g.uid) then seen[g.uid] = true end
	end
	local checkList = {}
	for k, rec in gl do
		GolemRegistry.Ensure(p, rec, "cave")
		if seen[rec.uid] then
			GolemRegistry.Log({ e = "dupe", u = p.UserId, g = rec.uid, k = rec.kind, m = rec.mut, r = "cave" })
			gl[k] = nil
		else
			seen[rec.uid] = true
			table.insert(checkList, rec)
		end
	end
	GolemRegistry.CheckOwnership(p, checkList)
	publish(p, bought, gl)
	InventoryService.Refresh(p)
	p:SetAttribute("CaveReady", true)
	applyCave(p)
end

local function sectionOf(p: Player, old: any): any
	if p:GetAttribute("CaveReady") ~= true then return old end
	return { bought = boughtOf(p), golems = golemsOf(p) }
end

local function hookCaves(folder: Instance)
	local function onCave(c: Instance)
		if not c:IsA("Model") then return end
		task.defer(function()
			for _, s in standsOf(c) do prepareStand(s) end
			local p = Players:GetPlayerByUserId((c:GetAttribute("OwnerUserId") :: number?) or 0)
			if p then applyCave(p) end
		end)
	end
	for _, c in folder:GetChildren() do onCave(c) end
	folder.ChildAdded:Connect(onCave)
end

function CaveStandService.Start()
	DataService.RegisterSection("Cave", sectionOf)
	PPS.PromptTriggered:Connect(onTrigger)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("CaveAction") :: RemoteEvent?
	if not ev then
		local n = Instance.new("RemoteEvent"); n.Name = "CaveAction"; n.Parent = remotes
		ev = n
	end
	(ev :: RemoteEvent).OnServerEvent:Connect(onAction)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) last[p] = nil; enterT[p] = nil; actT[p] = nil; tutLogged[p] = nil end)
	task.spawn(function()
		local f = workspace:WaitForChild("Caves", 30)
		if f then hookCaves(f) else warn("CaveStandService: немає Workspace/Caves (CaveService)") end
	end)
end

return CaveStandService
