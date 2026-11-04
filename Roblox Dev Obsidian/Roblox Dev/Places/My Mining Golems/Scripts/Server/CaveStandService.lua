--!strict
-- CaveStandService — стенди в печері-сховищі големів (Locations/Golem Cave): купівля за Money, голем на стенді, збереження.
-- Де: ServerScriptService/CaveStandService (ModuleScript). Запуск: NicheBoot (після InventoryService і HeldItemService).
-- Печеру будує CaveService (Workspace/Caves/Cave_<N> під нішею власника); тут — лише стенди в ній.
--
-- Правила (GDD: «слоти купуються за Money … для големів, які переживуть перехід на наступну мапу»; порядок у GDD не
--   вказано, тому по черзі): 14 стендів, номер — атрибут SlotIndex (1–14), ціна — атрибут Price (Money). Купувати можна
--   лише наступний (1 → 14). Діє лише власник печери, який зараз у ній (CaveAccess.canInteract) і стоїть поруч (REACH).
--   * Не куплений, наступний — «BUY $…» (зелена; грошей замало — сіра). Інші не куплені — сіра «LOCKED».
--   * Куплений і порожній — «PLACE», якщо в руці голем (InvHeld = Golem_<id>) з 3D-моделлю (GolemCatalog.model);
--     без моделі — сіра «NO MODEL YET», голем на плоті — сіра «ON PLOT», у руці не голем — сіра «HOLD A GOLEM».
--   * З големом — «TAKE»: голем повертається в інвентар, новим слотом у кінець хотбара й у руку (хотбар повний — лише
--     в інвентар); інвентар повний (ItemConfig.MAX_GOLEMS) — сіра «INVENTORY FULL».
--   Голем на стенді ПРИБРАНИЙ з інвентаря (InvGolems): повний запис { id, uid, kind, cls, mut, ix?, locked? } лежить на стенді
--   (UID той самий — GolemRegistry; стенд не змінює UID, TAKE повертає голема з тим самим UID).
--   Кнопки — ProximityPrompt «StandPrompt» (Style = Custom, малює CustomPrompts: вигляд COLLECT, клавіша E, затиск
--   HOLD с з тінню-заповненням) у невидимій точці StandButton над майданчиком, ближче до цінника. Напис / колір / сірий
--   стан ставить клієнт (StarterPlayerScripts/CaveStandsClient) лише для власника; гостям кнопок немає. Сервер сам
--   вирішує дію за станом стенда (RemoteEvent не потрібен) і перевіряє все: власник, у печері, відстань, порядок, гроші.
-- Після покупки: на камені-ціннику (PriceBoard) ціну сховано, зелене світло вимкнено — камінь сірий, як бортики стенда.
--   Звук покупки (BuySound) грає клієнт, коли зростає CaveStands.
-- Голем на стенді: модель із PlotAssets/<model> (та сама, що на плотах), розмір × GolemCatalog.size, аніматор у позі Idle,
--   носій — з ящичком, без кірки; над ним табличка, як над големом у руці (HeldItemService.InfoBoard; видно з ~32 стад).
--
-- Стан гравця (атрибути, їх читає клієнт):
--   CaveStands — JSON-список куплених номерів; CaveStandGolems — JSON { ["<номер>"] = { id, kind, cls, mut, locked? } };
--   CaveReady = true — дані завантажено. Ліміт MAX_GOLEMS рахує лише інвентар. Новий id голема (коли з'явиться видача
--   големів) має бути більшим за всі id і в InvGolems, і на стендах — CaveStandService.MaxId(p).
-- На стенді-моделі в печері: Bought (bool), GolemId (number?); на печері — StandsBought (скільки куплено).
-- Збереження: секція "Cave" у DataService — { bought = {номери}, golems = { ["<номер>"] = запис голема } }. НЕ скидається
--   на новій мапі (на відміну від Plots). Старий формат (golems = id) при вході переноситься: голем зникає з InvGolems.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local PPS = game:GetService("ProximityPromptService")

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
local HOLD = 0.5          -- затиск кнопки стенда, с
local PROMPT_DIST = 11    -- з якої відстані видно кнопку, стад
local REACH = 15          -- сервер: максимальна відстань гравця до кнопки, стад
local BTN_FWD = 3.6       -- кнопка: від центру майданчика в бік цінника, стад
local BTN_UP = 2.4        -- кнопка: над верхом майданчика, стад
local GOLEM_BACK = 1.2    -- голем: від центру майданчика вглиб (від цінника), стад
local BOARD_SCALE = 1.7   -- табличка над големом на стенді більша, ніж над фігуркою в руці
local ENTER_GRACE = 1.2   -- с після входу в печеру, поки кнопки стендів не діють (E ще затиснута після ENTER CAVE)

-- ===== дані гравця =====
local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function boughtOf(p: Player): { number } return decode(p, "CaveStands", {}) end
local function golemsOf(p: Player): { [string]: any } return decode(p, "CaveStandGolems", {}) end
local function invGolem(p: Player, id: number): any
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and g.id == id then return g end
	end
	return nil
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

-- модель голема на стенді
-- (збірка моделі — спільний Shared/GolemModel.build, той самий для підставок ролу; до 27.10.2026 жила тут)
local function golemModel(g: any): Model?
	local m = GolemModel.build(g.kind, g.cls)
	if not m then return nil end
	m.Name = "StandGolem"
	m:SetAttribute("GolemId", g.id); m:SetAttribute("Mut", Catalog.mut(g.mut))
	return m
end

local function placeGolem(stand: Model, g: any)
	local top, dir = standFrame(stand)
	if not top or not dir then return end
	local m = golemModel(g)
	if not m then return end
	-- стопи на майданчику: низ рамки моделі (поки стоїть прямо) відносно півота
	local cf, size = m:GetBoundingBox()
	local up = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
	local pos = top - dir * GOLEM_BACK + Vector3.new(0, up, 0)
	m:PivotTo(CFrame.lookAt(pos, pos + dir)) -- обличчям до цінника (у прохід)
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
		local g = b and gl[tostring(slot)] or nil
		local cur = stand:FindFirstChild("StandGolem")
		local sig = g and (tostring(g.id) .. ":" .. tostring(g.kind) .. ":" .. tostring(g.cls) .. ":" .. tostring(g.mut)) or nil
		if cur and cur:GetAttribute("Sig") ~= sig then cur:Destroy(); cur = nil end
		if g and not cur then
			placeGolem(stand, g)
			local m = stand:FindFirstChild("StandGolem")
			if m then m:SetAttribute("Sig", sig) end
		end
		stand:SetAttribute("GolemId", g and g.id or nil)
	end
	cave:SetAttribute("StandsBought", n)
end

-- записати стан у атрибути й оновити печеру
local function publish(p: Player, bought: { number }, gl: { [string]: any })
	table.sort(bought)
	p:SetAttribute("CaveStands", HttpService:JSONEncode(bought))
	p:SetAttribute("CaveStandGolems", HttpService:JSONEncode(gl))
	applyCave(p)
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

-- голем на стенді за UID → (номер стенда, запис) | nil
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
	local gl = golemsOf(p)
	local key = tostring(slot)
	if not table.find(bought, slot) then
		-- купівля: лише наступний по черзі, і грошей має вистачати
		if slot ~= #bought + 1 then return end
		local price = (stand:GetAttribute("Price") :: number?) or math.huge
		local money = (p:GetAttribute("Money") :: number?) or 0
		if money < price then return end
		p:SetAttribute("Money", money - price)
		table.insert(bought, slot)
		publish(p, bought, gl)
	elseif gl[key] then
		-- TAKE: голем повертається в інвентар (якщо є місце), у кінець хотбара й у руку
		local list = decode(p, "InvGolems", {})
		if Items.invGolemCount(list, decode(p, "PlotPlaced", {})) >= Items.maxGolems(p) then return end -- без големів на плотах
		local rec = gl[key]
		for _, g in list do
			if type(g) == "table" and g.id == rec.id then rec.id = CaveStandService.MaxId(p) + 1; break end -- id уже зайнятий
		end
		local locked = rec.locked == true
		table.insert(list, { id = rec.id, uid = rec.uid, kind = rec.kind, cls = rec.cls, mut = rec.mut, ix = rec.ix })
		gl[key] = nil
		p:SetAttribute("InvGolems", HttpService:JSONEncode(list))
		if locked then
			local locks = decode(p, "InvLocks", {})
			if not table.find(locks, "Golem_" .. rec.id) then table.insert(locks, "Golem_" .. rec.id) end
			p:SetAttribute("InvLocks", HttpService:JSONEncode(locks))
		end
		publish(p, bought, gl)
		InventoryService.Give(p, "Golem_" .. rec.id)
	else
		-- PLACE: голем з руки
		local held = p:GetAttribute("InvHeld")
		if type(held) ~= "string" or string.sub(held, 1, 6) ~= "Golem_" then return end
		local id = tonumber(string.sub(held, 7))
		local g = id and invGolem(p, id)
		if not g then return end
		local def = Catalog.get(g.kind)
		if not (def and def.model) then return end
		if def.exclusive then return end -- ексклюзиви (Mushroom Golem) не згоряють при переході — у печеру не ставляться
		if table.find(decode(p, "PlotPlaced", {}), id) then return end
		local rec = takeFromInventory(p, id :: number)
		if not rec then return end
		gl[key] = rec
		publish(p, bought, gl)
		InventoryService.Refresh(p) -- голема вже немає: з руки, хотбара й замків
	end
end

-- ===== вхід, збереження =====
local function onPlayer(p: Player)
	p:GetAttributeChangedSignal("InCave"):Connect(function()
		if p:GetAttribute("InCave") then enterT[p] = os.clock() end
	end)
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
				local slot = tonumber(k)
				if slot and table.find(bought, slot) then
					if type(v) == "table" and type(v.id) == "number" and Catalog.get(v.kind) then
						gl[tostring(slot)] = record(v)
					elseif tonumber(v) then -- старий формат: лише id, голем ще в інвентарі — переносимо
						local rec = takeFromInventory(p, tonumber(v) :: number)
						if rec then gl[tostring(slot)] = rec end
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
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) last[p] = nil; enterT[p] = nil end)
	task.spawn(function()
		local f = workspace:WaitForChild("Caves", 30)
		if f then hookCaves(f) else warn("CaveStandService: немає Workspace/Caves (CaveService)") end
	end)
end

return CaveStandService
