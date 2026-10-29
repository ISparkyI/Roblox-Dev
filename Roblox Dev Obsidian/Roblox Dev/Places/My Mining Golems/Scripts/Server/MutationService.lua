--!strict
-- MutationService — Mutation Machines у центрі зали (GDD - Mutation Machine): 3 однакових голема → 1 з наступною мутацією.
-- Де: ServerScriptService/MutationService (ModuleScript). Запуск: NicheBoot (після CaveStandService).
-- Конфіг — Shared/MutationConfig, вигляд і написи кнопок — StarterPlayerScripts/MutationMachineClient.
--
-- Машини — Workspace/Cave/Hub/MutationMachines/Machine<N> (атрибут MachineIndex): Slot1..3 (атрибут SlotIndex, кнопка
--   MutSlotPrompt), Core (кнопка MutClaimPrompt), пульт швидкості (MutSpeedPrompt — покупку відкриває клієнт).
-- У кожного гравця свої слоти (машина локальна): гравець бачить лише своїх големів.
-- Дії (E на кнопці, сервер сам вирішує за станом):
--   * слот порожній, у руці голем (InvHeld = Golem_<id>) — PLACE: голем зникає з інвентаря (запис із тим самим UID
--     лежить у машині). Умови: не на плоті, не Secret, такий самий, як уже покладені в цю машину.
--   * 3 однакових покладено — кнопка START на панелі машини (Remotes/MutationAction "Start", номер машини) запускає мутацію (job).
--   * слот з големом — TAKE: голем повертається в інвентар (той самий UID), мутація скасовується (таймер скидається).
--   * мутація готова — CLAIM (на ядрі або будь-якому слоті): 3 записи спалюються (GolemRegistry.Burn "mutate"),
--     новий голем (mut + 1, новий UID) — у інвентар, у хотбар і в руку. Інвентар повний — чекає.
-- Стан — атрибут гравця MutMachines (JSON): { ["1"] = { slots = { ["1"] = запис, ... }, job = { dur, done, t0, mult }? }, ["2"] = ... };
--   MutReady = true — дані завантажено. Запис голема — { id, uid, kind, cls, mut, ix?, locked? } (як на стенді печери).
--   id големів у машинах враховує CaveStandService.MaxId.
-- Час: t0 — workspace:GetServerTimeNow() (Unix-час, тож таймер іде й офлайн). Купівля ступеня Fast Mutations (MutSpeedTier)
--   під час мутації: пройдене додається в done за старим множником, далі — новий множник.
-- Збереження: секція "Mutation" у DataService (не скидається на новій мапі).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local PPS = game:GetService("ProximityPromptService")

local DataService = require(script.Parent:WaitForChild("DataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local CaveStandService = require(script.Parent:WaitForChild("CaveStandService"))
local GolemRegistry = require(script.Parent:WaitForChild("GolemRegistry"))
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local MutCfg = require(RS.Shared:WaitForChild("MutationConfig"))
local MonCfg = require(RS.Shared:WaitForChild("MonetizationConfig"))

local MutationService = {}

local REACH = 16 -- сервер: максимальна відстань гравця до кнопки, стад

local function now(): number return workspace:GetServerTimeNow() end

local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end

local function speedMult(p: Player): number
	return MonCfg.mutSpeedMult(tonumber(p:GetAttribute("MutSpeedTier")) or 0)
end

-- запис голема (лише потрібні поля)
local function record(g: any): any
	return { id = g.id, uid = g.uid, kind = Catalog.id(g.kind) or g.kind, cls = Catalog.cls(g.cls), mut = Catalog.mut(g.mut),
		ix = g.ix, locked = g.locked == true or nil }
end

-- порожній стан усіх машин
local function emptyState(): any
	local st = {}
	for i = 1, MutCfg.MACHINES do st[tostring(i)] = { slots = {} } end
	return st
end
local function stateOf(p: Player): any
	local st = decode(p, "MutMachines", nil)
	if type(st) ~= "table" then return emptyState() end
	for i = 1, MutCfg.MACHINES do
		local m = st[tostring(i)]
		if type(m) ~= "table" then st[tostring(i)] = { slots = {} }
		elseif type(m.slots) ~= "table" then m.slots = {} end
	end
	return st
end
local function publish(p: Player, st: any)
	p:SetAttribute("MutMachines", HttpService:JSONEncode(st))
end

local function slotCount(m: any): number
	local n = 0
	for i = 1, MutCfg.SLOTS do if type(m.slots[tostring(i)]) == "table" then n += 1 end end
	return n
end
local function firstRec(m: any): any
	for i = 1, MutCfg.SLOTS do
		local r = m.slots[tostring(i)]
		if type(r) == "table" then return r end
	end
	return nil
end
local function isDone(m: any): boolean
	return type(m.job) == "table" and MutCfg.left(m.job, now()) <= 0
end

-- третій однаковий голем — старт мутації
local function startIfFull(p: Player, m: any)
	if m.job or slotCount(m) < MutCfg.SLOTS then return end
	local r = firstRec(m)
	if not r or r.mut >= MutCfg.MAX_MUT then return end
	m.job = { dur = MutCfg.duration(r.mut), done = 0, t0 = now(), mult = speedMult(p) }
end

-- забрати голема з інвентаря (замок запам'ятовується в записі)
local function takeFromInventory(p: Player, id: number): any
	local list = decode(p, "InvGolems", {})
	local keep, found = {}, nil
	for _, g in list do
		if type(g) == "table" and g.id == id and not found then found = g else table.insert(keep, g) end
	end
	if not found then return nil end
	local rec = record(found)
	if table.find(decode(p, "InvLocks", {}), "Golem_" .. id) then rec.locked = true end
	p:SetAttribute("InvGolems", HttpService:JSONEncode(keep))
	return rec
end
-- повернути запис у інвентар (той самий UID); повертає ключ Golem_<id>
local function returnToInventory(p: Player, rec: any): string
	local list = decode(p, "InvGolems", {})
	for _, g in list do
		if type(g) == "table" and g.id == rec.id then rec.id = CaveStandService.MaxId(p) + 1; break end -- id уже зайнятий
	end
	table.insert(list, { id = rec.id, uid = rec.uid, kind = rec.kind, cls = rec.cls, mut = rec.mut, ix = rec.ix })
	p:SetAttribute("InvGolems", HttpService:JSONEncode(list))
	if rec.locked then
		local locks = decode(p, "InvLocks", {})
		if not table.find(locks, "Golem_" .. rec.id) then table.insert(locks, "Golem_" .. rec.id) end
		p:SetAttribute("InvLocks", HttpService:JSONEncode(locks))
	end
	return "Golem_" .. rec.id
end
local function invFull(p: Player, extra: number): boolean
	return Items.invGolemCount(decode(p, "InvGolems", {}), decode(p, "PlotPlaced", {})) + extra > Items.maxGolems(p)
end

-- големи в машинах (для CaveStandService.MaxId і адмін-пошуку)
function MutationService.Records(p: Player): { any }
	local out = {}
	local st = stateOf(p)
	for i = 1, MutCfg.MACHINES do
		for s = 1, MutCfg.SLOTS do
			local r = st[tostring(i)].slots[tostring(s)]
			if type(r) == "table" then table.insert(out, r) end
		end
	end
	return out
end

-- ===== дії =====
local last: { [Player]: number } = {}

local function claim(p: Player, st: any, key: string): boolean
	local m = st[key]
	if not isDone(m) then return false end
	if invFull(p, 1) then return false end
	local r = firstRec(m)
	if not r then m.job = nil; publish(p, st); return false end
	local kind, cls, mut = r.kind, r.cls, math.min(MutCfg.MAX_MUT, r.mut + 1)
	for s = 1, MutCfg.SLOTS do
		local rec = m.slots[tostring(s)]
		if type(rec) == "table" then GolemRegistry.Burn(p, rec, "mutate") end
	end
	st[key] = { slots = {} }
	publish(p, st)
	local id = CaveStandService.MaxId(p) + 1
	local ok = InventoryService.AddGolem(p, id, kind, cls, mut, "mutate", true)
	if ok then
		InventoryService.Give(p, "Golem_" .. id)
		p:SetAttribute("MutClaimT", now()) -- клієнт: звук і спалах
	end
	task.spawn(function() pcall(DataService.SaveNow, p) end)
	return ok
end

-- START з панелі (гравець поруч із машиною)
local START_REACH = 45
local function onAction(p: Player, action: any, idx: any)
	if action ~= "Start" or type(idx) ~= "number" or idx < 1 or idx > MutCfg.MACHINES or idx ~= math.floor(idx) then return end
	if p:GetAttribute("MutReady") ~= true then return end
	local f = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub") and workspace.Cave.Hub:FindFirstChild("MutationMachines")
	local machine = f and f:FindFirstChild("Machine" .. idx)
	local body = machine and machine:FindFirstChild("Body")
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (body and body:IsA("BasePart") and hrp and hrp:IsA("BasePart")) then return end
	if (hrp.Position - body.Position).Magnitude > START_REACH then return end
	local t = os.clock()
	if last[p] and t - last[p] < 0.3 then return end
	last[p] = t
	local st = stateOf(p)
	local m = st[tostring(idx)]
	if m.job or slotCount(m) ~= MutCfg.SLOTS then return end
	startIfFull(p, m)
	publish(p, st)
	task.spawn(function() pcall(DataService.SaveNow, p) end)
end

local function onTrigger(prompt: ProximityPrompt, p: Player)
	local name = prompt.Name
	if name ~= "MutSlotPrompt" and name ~= "MutClaimPrompt" and name ~= "MutStartPrompt" then return end
	if p:GetAttribute("MutReady") ~= true or p:GetAttribute("InvReady") ~= true then return end
	local anchor = prompt.Parent
	if not (anchor and anchor:IsA("BasePart")) then return end
	local machine: Instance? = anchor
	while machine and machine:GetAttribute("MachineIndex") == nil do machine = machine.Parent end
	if not machine then return end
	local idx = machine:GetAttribute("MachineIndex")
	if type(idx) ~= "number" or idx < 1 or idx > MutCfg.MACHINES then return end
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) or (hrp.Position - anchor.Position).Magnitude > REACH then return end
	local t = os.clock()
	if last[p] and t - last[p] < 0.3 then return end
	last[p] = t

	local st = stateOf(p)
	local key = tostring(idx)
	local m = st[key]
	if isDone(m) then claim(p, st, key); return end
	if name == "MutClaimPrompt" then return end
	if name == "MutStartPrompt" then
		if not m.job and slotCount(m) == MutCfg.SLOTS then
			startIfFull(p, m)
			publish(p, st)
			task.spawn(function() pcall(DataService.SaveNow, p) end)
		end
		return
	end

	local slotModel = anchor.Parent
	local si = slotModel and slotModel:GetAttribute("SlotIndex")
	if type(si) ~= "number" or si < 1 or si > MutCfg.SLOTS then return end
	local sk = tostring(si)
	local cur = m.slots[sk]
	if type(cur) == "table" then
		-- TAKE: голем назад у інвентар, мутація скасовується
		if invFull(p, 1) then return end
		m.slots[sk] = nil
		m.job = nil
		local k = returnToInventory(p, cur)
		publish(p, st)
		InventoryService.Give(p, k)
		return
	end
	-- PLACE: голем з руки
	local held = p:GetAttribute("InvHeld")
	if type(held) ~= "string" or string.sub(held, 1, 6) ~= "Golem_" then return end
	local id = tonumber(string.sub(held, 7))
	if not id then return end
	if table.find(decode(p, "PlotPlaced", {}), id) then return end
	local g = nil
	for _, e in decode(p, "InvGolems", {}) do if type(e) == "table" and e.id == id then g = e end end
	if not g or not Catalog.get(g.kind) then return end
	local probe = record(g)
	if probe.mut >= MutCfg.MAX_MUT then return end
	local other = firstRec(m)
	if other and not MutCfg.same(other, probe) then return end
	local rec = takeFromInventory(p, id)
	if not rec then return end
	m.slots[sk] = rec
	publish(p, st)
	InventoryService.Refresh(p) -- голема вже немає: з руки, хотбара й замків
end

-- купив ступінь швидкості під час мутації: пройдене за старим множником → done, далі новий
local function onSpeedChanged(p: Player)
	if p:GetAttribute("MutReady") ~= true then return end
	local st = stateOf(p)
	local mult = speedMult(p)
	local t = now()
	local changed = false
	for i = 1, MutCfg.MACHINES do
		local j = st[tostring(i)].job
		if type(j) == "table" and j.mult ~= mult then
			j.done = math.min(j.dur, (tonumber(j.done) or 0) + math.max(0, t - (tonumber(j.t0) or t)) * (tonumber(j.mult) or 1))
			j.t0 = t
			j.mult = mult
			changed = true
		end
	end
	if changed then publish(p, st) end
end

-- ===== вхід, збереження =====
local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	while p.Parent == Players and (p:GetAttribute("InvReady") ~= true or p:GetAttribute("CaveReady") ~= true) do task.wait(0.1) end
	if p.Parent ~= Players then return end
	local sec = DataService.GetSection(p, "Mutation")
	local st = emptyState()
	-- UID вже є в інвентарі чи на стенді печери — дюп, з машини прибирається
	local seen: { [string]: boolean } = {}
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and GolemRegistry.IsUid(g.uid) then seen[g.uid] = true end
	end
	for _, g in decode(p, "CaveStandGolems", {}) do
		if type(g) == "table" and GolemRegistry.IsUid(g.uid) then seen[g.uid] = true end
	end
	local checkList = {}
	if type(sec) == "table" and type(sec.machines) == "table" then
		for i = 1, MutCfg.MACHINES do
			local src = sec.machines[tostring(i)]
			if type(src) == "table" and type(src.slots) == "table" then
				local m = st[tostring(i)]
				for s = 1, MutCfg.SLOTS do
					local v = src.slots[tostring(s)]
					if type(v) == "table" and type(v.id) == "number" and Catalog.get(v.kind) then
						local rec = record(v)
						GolemRegistry.Ensure(p, rec, "mutate")
						if seen[rec.uid] then
							GolemRegistry.Log({ e = "dupe", u = p.UserId, g = rec.uid, k = rec.kind, m = rec.mut, r = "mutate" })
						else
							seen[rec.uid] = true
							m.slots[tostring(s)] = rec
							table.insert(checkList, rec)
						end
					end
				end
				local j = src.job
				if type(j) == "table" and slotCount(m) == MutCfg.SLOTS then
					m.job = { dur = tonumber(j.dur) or MutCfg.duration(firstRec(m).mut), done = tonumber(j.done) or 0,
						t0 = tonumber(j.t0) or now(), mult = tonumber(j.mult) or 1 }
				end
			end
		end
	end
	GolemRegistry.CheckOwnership(p, checkList)
	publish(p, st)
	p:SetAttribute("MutReady", true)
	onSpeedChanged(p) -- ступінь куплено, поки гравця не було
	p:GetAttributeChangedSignal("MutSpeedTier"):Connect(function() onSpeedChanged(p) end)
end

local function sectionOf(p: Player, old: any): any
	if p:GetAttribute("MutReady") ~= true then return old end
	return { machines = stateOf(p) }
end

function MutationService.Start()
	DataService.RegisterSection("Mutation", sectionOf)
	PPS.PromptTriggered:Connect(onTrigger)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("MutationAction") or Instance.new("RemoteEvent")
	ev.Name = "MutationAction"; ev.Parent = remotes
	ev.OnServerEvent:Connect(onAction)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end

return MutationService
