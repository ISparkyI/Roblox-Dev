--!strict
-- BossFightService — бій з босом (Plan - Boss Fight System, 04.11.2026).
-- Де: ServerScriptService/BossFightService (ModuleScript). Запуск: NicheBoot (після BossPortalService). Конфіг — Shared/BossConfig.
-- Фази (атрибут Workspace.BossPhase): "idle" → "reg" (останні REG_TIME с до BossAt, біля порталу JOIN) → "fight" (до FIGHT_TIME с
--   або смерті боса) → "results" (RESULTS_TIME с) → усі додому. BossPhaseEnd — кінець поточної фази (час сервера).
-- Лобі: Workspace.BossLobby (JSON [{u, n, g = {{k, m}}}]) — гравці, що зареєструвались (макс. MAX_PLAYERS).
-- Вибір бійців: атрибут гравця BossPicks (JSON масив id големів-воїнів з InvGolems, до BossConfig.slots(p)).
-- Remotes/BossAction (клієнт → сервер): ("Pick", slot, id | 0), ("Auto"), ("Join"), ("Leave"), ("BuySlot") — 4-й слот за діаманти.
-- Remotes/BossFx (сервер → клієнти на арені): ("spawn", list) — статичні дані големів; ("warn", id, key, rects, warn);
--   ("hit", id, hitKeys); ("dead", key); ("atk", key) — голем ударив; ("boss", "attack", atkKey, warn, side) | ("boss", "die" | "escape").
-- Remotes/BossTick (сервер → клієнти): { {key, x, z, yaw, hp, st}, … } кожні SEND_EVERY с.
-- Remotes/BossResult (сервер → гравець): { win, place, dmg, share, teeth, dia, n }.
-- Шкода: сервер (голем упритул до хітбоксу боса, інтервал удару). Удари боса — прямокутники на підлозі (rects { cx, cz, w, d, yaw }).
-- Арена: ServerStorage/BossArenas/<BossConfig.BOSSES[id].arena> → клон у Workspace як «Boss Map» (старий «Boss Map» переміщено туди).
-- Вийшов з арени (EXIT / смерть / вийшов з гри) — вибуває без нагороди. Fossil Tooth — атрибут FossilTeeth (секція "Boss" у DataService).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("BossConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local BossFightService = {}

local rng = Random.new()
local function now(): number return workspace:GetServerTimeNow() end
local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function enc(t: any): string return HttpService:JSONEncode(t) end

local remotes: Folder
local evFx: RemoteEvent
local evTick: RemoteEvent
local evResult: RemoteEvent

-- ===== арена =====
local arena: Instance? = nil
local center = Vector3.zero -- 05.11.2026: позиція боса (ходить по арені); центр арени — arenaCenter
local arenaCenter = Vector3.zero
local floorY = 0
local function setupArena()
	local _, def = Cfg.current()
	local store = SS:FindFirstChild("BossArenas")
	local src = store and store:FindFirstChild(def.arena)
	local old = workspace:FindFirstChild("Boss Map")
	if src then
		if old then old:Destroy() end
		arena = src:Clone()
		;(arena :: Instance).Name = "Boss Map"
		;(arena :: Instance).Parent = workspace
	else
		arena = old
	end
	local sp = arena and arena:FindFirstChild("ArenaSpawn")
	if sp and sp:IsA("BasePart") then
		center = sp.Position
		arenaCenter = sp.Position
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { arena :: Instance }
		local r = workspace:Raycast(sp.Position + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rp)
		floorY = r and r.Position.Y or sp.Position.Y
		workspace:SetAttribute("BossFloorY", floorY)
		workspace:SetAttribute("BossCenter", Vector3.new(center.X, floorY, center.Z))
	end
end

-- ===== бос-заглушка (блоковий Големо-Гоблін; модель і анімації — окремий етап) =====
local boss: Model? = nil
local bossYaw = 0
local function part(par: Instance, name: string, size: Vector3, cf: CFrame, col: string, neon: boolean?): Part
	local b = Instance.new("Part")
	b.Name = name; b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false
	b.Size = size; b.CFrame = cf; b.Color = Color3.fromHex(col)
	if neon then b.Material = Enum.Material.Neon else b.Material = Enum.Material.Plastic; b.MaterialVariant = "Studs" end
	b.TopSurface = Enum.SurfaceType.Smooth; b.BottomSurface = Enum.SurfaceType.Smooth
	b.Parent = par
	return b
end
local function buildBoss(): Model
	-- 05.11.2026: GOBKING — префаб ServerStorage/BossModels/Gobking (немає — будує ServerScriptService/BossModelBuilder)
	local store = SS:FindFirstChild("BossModels")
	local pre = store and store:FindFirstChild("Gobking")
	local m: Model = (pre and pre:IsA("Model")) and pre:Clone() or require(script.Parent:WaitForChild("BossModelBuilder")).build()
	m.Name = "Boss"
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- приходить клієнту цілою моделлю (інакше частина деталей «відстає»)
	m.PrimaryPart = m:FindFirstChild("Hitbox") :: BasePart
	m:PivotTo(CFrame.new(center.X, floorY + Cfg.BOSSES.goblin.half.Y, center.Z))
	m:SetAttribute("BuildCF", (m.PrimaryPart :: BasePart).CFrame) -- поза збірки: деталі (крім Hitbox) на сервері більше не рухаються
	m.Parent = arena
	return m
end
local function bossCF(): CFrame return CFrame.new(center.X, floorY, center.Z) * CFrame.Angles(0, bossYaw, 0) end
-- 06.11.2026: точка на «кільці» навколо хітбоксу боса під кутом a (світовий, як atan2(dx, dz)) — тут големи стоять і б'ють
local function ringPoint(a: number, mg: number?): Vector3
	local h = Cfg.BOSSES.goblin.half
	local cf = bossCF()
	local d = cf:VectorToObjectSpace(Vector3.new(math.sin(a), 0, math.cos(a)))
	mg = mg or 2.2
	local t = math.min((h.X + mg :: number) / math.max(math.abs(d.X), 1e-3), (h.Z + mg :: number) / math.max(math.abs(d.Z), 1e-3))
	return cf:PointToWorldSpace(d * t)
end
local RING_M = { 2.2, 8.2 } -- 06.11.2026: відступ кілець від краю хітбоксу боса (внутрішнє, зовнішнє)
local RING_GAP = 6.5         -- мінімальний крок між големами на внутрішньому кільці, стад
local function faceBoss(yaw: number)
	bossYaw = yaw
	local b = boss
	if b and b.PrimaryPart then
		-- 05.11.2026: рухаємо лише Hitbox (PrimaryPart) — решту деталей розставляє клієнт (BossArenaClient) відносно нього;
		--   так сервер не реплікує ~800 деталей щокроку, коли бос ходить
		b.PrimaryPart.CFrame = CFrame.new(center.X, floorY + Cfg.BOSSES.goblin.half.Y, center.Z) * CFrame.Angles(0, yaw, 0)
	end
end
-- відстань у площині XZ від точки до прямокутника хітбоксу боса (0 — всередині)
local function bossDist(pos: Vector3): number
	local h = Cfg.BOSSES.goblin.half
	local l = bossCF():PointToObjectSpace(pos)
	local dx = math.max(0, math.abs(l.X) - h.X)
	local dz = math.max(0, math.abs(l.Z) - h.Z)
	return math.sqrt(dx * dx + dz * dz)
end
-- виштовхнути точку з хітбоксу (големи не заходять у боса)
local function pushOut(pos: Vector3): Vector3
	local h = Cfg.BOSSES.goblin.half
	local cf = bossCF()
	local l = cf:PointToObjectSpace(pos)
	local ex, ez = h.X + 1.6, h.Z + 1.6
	if math.abs(l.X) < ex and math.abs(l.Z) < ez then
		local kx, kz = ex - math.abs(l.X), ez - math.abs(l.Z)
		if kx < kz then l = Vector3.new(math.sign(l.X ~= 0 and l.X or 1) * ex, l.Y, l.Z)
		else l = Vector3.new(l.X, l.Y, math.sign(l.Z ~= 0 and l.Z or 1) * ez) end
		return cf:PointToWorldSpace(l)
	end
	return pos
end

-- ===== стан =====
local phase = "idle"
local phaseEnd = 0
local regEnd = 0
type G = { key: string, id: number, kind: string, mut: number, hp: number, max: number, dmg: number, interval: number,
	move: number, pos: Vector3, yaw: number, nextAtk: number, dead: boolean, st: string, slot: number, n: number, ringA: number?, ringM: number? }
type F = { p: Player, golems: { G }, dmg: number, out: boolean }
local lobby: { [Player]: boolean } = {}
local lobbyOrder: { Player } = {}
local fighters: { [Player]: F } = {}
local bossHp, bossMax = 0, 1
local fightEnd = 0
local attackId = 0

local function setPhase(ph: string, ends: number)
	phase = ph; phaseEnd = ends
	workspace:SetAttribute("BossPhase", ph)
	workspace:SetAttribute("BossPhaseEnd", ends)
end

-- вибір бійців гравця: валідні id воїнів з інвентаря
local function validPicks(p: Player): { any }
	local inv = decode(p, "InvGolems", {})
	local placed = decode(p, "PlotPlaced", {})
	local byId = {}
	for _, g in inv do if type(g) == "table" and Catalog.cls(g.cls) == "warrior" and Catalog.get(g.kind) then byId[g.id] = g end end
	local out, seen = {}, {}
	for i, id in decode(p, "BossPicks", {}) do
		if not Cfg.slotOpen(p, i) then continue end -- 05.11.2026: слоти 4 (діаманти) і 5 (геймпас) відкриваються окремо
		local g = type(id) == "number" and byId[id] or nil
		if g and not seen[id] and not table.find(placed, id) then seen[id] = true; table.insert(out, g) end
	end
	return out
end

local function publishLobby()
	local list = {}
	for _, p in lobbyOrder do
		if lobby[p] and p.Parent == Players then
			local gs = {}
			for _, g in validPicks(p) do table.insert(gs, { k = Catalog.id(g.kind) or g.kind, m = Catalog.mut(g.mut) }) end
			table.insert(list, { u = p.UserId, n = p.DisplayName, g = gs })
		end
	end
	workspace:SetAttribute("BossLobby", enc(list))
end
local function removeFromLobby(p: Player)
	if not lobby[p] then return end
	lobby[p] = nil
	local i = table.find(lobbyOrder, p)
	if i then table.remove(lobbyOrder, i) end
	publishLobby()
end
local function lobbyCount(): number
	local n = 0
	for p in lobby do if p.Parent == Players then n += 1 end end
	return n
end

local function nearPortal(p: Player): boolean
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local portal = hub and hub:FindFirstChild("BossPortal")
	local ring = portal and portal:FindFirstChild("Ring")
	local c = ring and ring:FindFirstChild("RingCenter")
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (c and c:IsA("BasePart") and hrp and hrp:IsA("BasePart")) then return false end
	local d = hrp.Position - c.Position
	return Vector2.new(d.X, d.Z).Magnitude <= 30 and math.abs(d.Y) < 15
end

-- ===== дії з вікна порталу =====
local last: { [Player]: number } = {}
local function onAction(p: Player, action: any, a: any, b: any)
	if type(action) ~= "string" then return end
	local t = os.clock()
	if last[p] and t - last[p] < 0.15 then return end
	last[p] = t
	if action == "Pick" then
		local slot, id = tonumber(a), tonumber(b)
		if not slot or slot ~= math.floor(slot) or not Cfg.slotOpen(p, slot) then return end
		local picks = decode(p, "BossPicks", {})
		local out = {}
		for i = 1, Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS do out[i] = tonumber(picks[i]) or 0 end
		if id and id ~= 0 then for i = 1, #out do if out[i] == id then out[i] = 0 end end end
		out[slot] = id or 0
		p:SetAttribute("BossPicks", enc(out))
	elseif action == "Auto" then
		local inv = decode(p, "InvGolems", {})
		local placed = decode(p, "PlotPlaced", {})
		local list = {}
		for _, g in inv do
			if type(g) == "table" and Catalog.cls(g.cls) == "warrior" and Catalog.get(g.kind) and not table.find(placed, g.id) then
				table.insert(list, { id = g.id, pw = Catalog.power(g.kind, "warrior", g.mut, p) })
			end
		end
		table.sort(list, function(x, y) return x.pw > y.pw end)
		local out, k = {}, 0
		for i = 1, Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS do
			if Cfg.slotOpen(p, i) and list[k + 1] then k += 1; out[i] = list[k].id else out[i] = 0 end
		end
		p:SetAttribute("BossPicks", enc(out))
	elseif action == "BuySlot" then
		-- 05.11.2026: 4-й слот бійця за діаманти (раз і назавжди; секція "Boss" → slotDia)
		if p:GetAttribute("BossSlotDia") == true then return end
		local d = tonumber(p:GetAttribute("Diamonds")) or 0
		if d < Cfg.DIA_SLOT_PRICE then return end
		p:SetAttribute("Diamonds", d - Cfg.DIA_SLOT_PRICE)
		p:SetAttribute("BossSlotDia", true)
		task.spawn(function() pcall(DataService.SaveNow, p) end)
	elseif action == "Join" then
		if phase ~= "reg" or lobby[p] then return end
		if (tonumber(p:GetAttribute("Stage")) or 1) < Cfg.MIN_STAGE then return end
		if #validPicks(p) == 0 or lobbyCount() >= Cfg.MAX_PLAYERS then return end -- 10.11.2026: JOIN з будь-якого місця (кнопка JOIN біля NEXT BOSS у HUD), не лише в колі порталу
		lobby[p] = true
		table.insert(lobbyOrder, p)
	elseif action == "Home" then
		-- 06.11.2026: CLAIM / OK у вікні нагород → одразу додому на плот (не чекаючи кінця RESULTS_TIME)
		if phase == "results" and p:GetAttribute("InBossArena") == true then
			p:SetAttribute("InBossArena", nil)
			local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
			if okN and NS and NS.TeleportHome then pcall(NS.TeleportHome, p) end
		end
		return
	elseif action == "Leave" then
		if phase ~= "reg" then return end
		removeFromLobby(p)
		return
	else
		return
	end
	if lobby[p] then publishLobby() end
end

-- ===== бій =====
local function hrpOf(p: Player): BasePart?
	local c = p.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	return (h and h:IsA("BasePart")) and h or nil
end
local function fighterList(): { Player }
	local l = {}
	for p, f in fighters do if not f.out and p.Parent == Players then table.insert(l, p) end end
	return l
end
local function sendFx(...: any)
	for _, p in fighterList() do evFx:FireClient(p, ...) end
end

local function spawnSpot(i: number, n: number): CFrame
	local a = (i / math.max(1, n)) * math.pi * 2 + math.pi / 2
	local pos = Vector3.new(center.X + math.cos(a) * 58, floorY + 3.5, center.Z + math.sin(a) * 46) -- 06.11.2026: бос ×6
	return CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
end

local function staticList(): { any }
	local list = {}
	for p, f in fighters do
		for _, g in f.golems do
			table.insert(list, { key = g.key, u = p.UserId, n = p.DisplayName, k = g.kind, m = g.mut, max = g.max, iv = g.interval })
		end
	end
	return list
end

local function startFight()
	local players = {}
	for _, p in lobbyOrder do if lobby[p] and p.Parent == Players then table.insert(players, p) end end
	table.clear(lobby); table.clear(lobbyOrder)
	publishLobby()
	if #players == 0 then setPhase("idle", 0); return end
	local _, def = Cfg.current()
	table.clear(fighters)
	local dpsSum = 0
	for i, p in players do
		local f: F = { p = p, golems = {}, dmg = 0, out = false }
		for s, g in validPicks(p) do
			local st = Catalog.stats(g.kind, "warrior", g.mut, p)
			local d = Cfg.golemDmg(st.dmg or 1)
			local key = tostring(p.UserId) .. ":" .. tostring(g.id)
			table.insert(f.golems, { key = key, id = g.id, kind = Catalog.id(g.kind) or g.kind, mut = Catalog.mut(g.mut),
				hp = math.max(10, st.hp or 10), max = math.max(10, st.hp or 10), dmg = d, interval = math.max(0.5, st.interval or 1.4),
				move = math.clamp(st.move or 8, Cfg.MIN_MOVE, Cfg.MAX_MOVE), pos = Vector3.zero, yaw = 0, nextAtk = 0,
				dead = false, st = "Idle", slot = s, n = 0 })
			dpsSum += d / math.max(0.5, st.interval or 1.4)
		end
		for _, g in f.golems do g.n = #f.golems end
		fighters[p] = f
		-- телепорт
		local spot = spawnSpot(i, #players)
		pcall(function() p:RequestStreamAroundAsync(spot.Position) end)
		local char = p.Character
		local hrp = hrpOf(p)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if char and hrp and hum then
			char:PivotTo(spot + Vector3.new(0, hum.HipHeight, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		p:SetAttribute("InBossArena", true)
		for _, g in f.golems do g.pos = Vector3.new(spot.Position.X, floorY, spot.Position.Z) + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)) end
	end
	bossMax = Cfg.niceHp(math.max(def.minHp, dpsSum * def.hpPerDps)) -- 06.11.2026: кругле число (10K, 25K, 50K, 100K, 250K…)
	bossHp = bossMax
	if boss then boss:Destroy() end
	center = arenaCenter
	boss = buildBoss()
	faceBoss(0)
	workspace:SetAttribute("BossName", def.name)
	workspace:SetAttribute("BossMaxHP", bossMax)
	workspace:SetAttribute("BossHP", bossHp)
	workspace:SetAttribute("BossDamage", "{}")
	fightEnd = now() + Cfg.FIGHT_TIME
	setPhase("fight", fightEnd)
	task.wait(0.5)
	sendFx("spawn", staticList())
end

local function damageJson()
	local t = {}
	for p, f in fighters do if not f.out then t[tostring(p.UserId)] = math.floor(f.dmg) end end
	workspace:SetAttribute("BossDamage", enc(t))
end

-- форми атак (прямокутники на підлозі)
local function rectAround(pos: Vector3, w: number, d: number, yaw: number): any
	return { cx = pos.X, cz = pos.Z, w = w, d = d, yaw = yaw }
end
local function inRect(pos: Vector3, r: any): boolean
	local cf = CFrame.new(r.cx, 0, r.cz) * CFrame.Angles(0, r.yaw, 0)
	local l = cf:PointToObjectSpace(Vector3.new(pos.X, 0, pos.Z))
	return math.abs(l.X) <= r.w / 2 + 1 and math.abs(l.Z) <= r.d / 2 + 1
end
local function aliveGolems(): { G }
	local l = {}
	for _, f in fighters do if not f.out then for _, g in f.golems do if not g.dead then table.insert(l, g) end end end end
	return l
end
local function clusterOf(f: F): Vector3?
	local s, n = Vector3.zero, 0
	for _, g in f.golems do if not g.dead then s += g.pos; n += 1 end end
	return n > 0 and s / n or nil
end

local function makeAttack(atk: any, forceSide: number?): ({ any }, number)
	local h = Cfg.BOSSES.goblin.half
	local rects = {}
	-- ціль — випадковий живий голем (бос повертається до нього)
	local al = aliveGolems()
	local tgt = #al > 0 and al[rng:NextInteger(1, #al)].pos or (center + Vector3.new(0, 0, -20))
	local dir = Vector3.new(tgt.X - center.X, 0, tgt.Z - center.Z)
	local yaw = dir.Magnitude > 0.1 and math.atan2(-dir.X, -dir.Z) or bossYaw
	faceBoss(yaw)
	local cf = bossCF()
	-- 05.11.2026: 4 атаки GOBKING (06.11.2026: бос ×6 до големів, хітбокс 24 × 42 × 18, зони × 0,75); side — бік для Arm Sweep (−1 — ліва рука, 1 — права)
	local side = 0
	if atk.key == "Slam" then -- обидва кулаки об землю перед собою
		table.insert(rects, rectAround(cf:PointToWorldSpace(Vector3.new(0, 0, -(h.Z + 10))), 30, 20, yaw))
	elseif atk.key == "Sweep" then -- рука мете збоку: довга смуга від спини до передньої зони
		side = forceSide or (rng:NextNumber() < 0.5 and -1 or 1)
		table.insert(rects, rectAround(cf:PointToWorldSpace(Vector3.new(side * (h.X + 9), 0, -4.5)), 18, 44, yaw))
	elseif atk.key == "Eruption" then -- кристали з землі під кожною групою големів
		for _, f in fighters do
			local c = (not f.out) and clusterOf(f) or nil
			if c then table.insert(rects, rectAround(c + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)), 13, 13, rng:NextNumber() * math.pi)) end
		end
	elseif atk.key == "RockRain" then -- каміння з неба; у другій фазі більше
		local nR = bossHp < bossMax * 0.5 and 14 or 9
		for _ = 1, nR do
			local a = rng:NextNumber() * math.pi * 2
			local d = rng:NextNumber(h.X + 5, 50)
			table.insert(rects, rectAround(center + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d), 10, 10, rng:NextNumber() * math.pi))
		end
	end
	return rects, side
end

local function finish(win: boolean, why: string?)
	setPhase("results", now() + Cfg.RESULTS_TIME)
	if boss then sendFx("boss", win and "die" or "escape") end
	-- місця і нагороди
	local list = {}
	local sum = 0
	for p, f in fighters do if not f.out and p.Parent == Players then table.insert(list, f); sum += f.dmg end end
	table.sort(list, function(a, b) return a.dmg > b.dmg end)
	for place, f in list do
		local teeth, dia = Cfg.reward(f.dmg, sum, place, #list, win)
		local p = f.p
		if teeth > 0 then p:SetAttribute("FossilTeeth", (tonumber(p:GetAttribute("FossilTeeth")) or 0) + teeth) end
		if dia > 0 then p:SetAttribute("Diamonds", (tonumber(p:GetAttribute("Diamonds")) or 0) + dia) end
		if win then
			local okS, Stats = pcall(require, script.Parent:FindFirstChild("StatsService"))
			if okS and Stats and Stats.Add then pcall(Stats.Add, p, "BossKills", 1) end
		end
		evResult:FireClient(p, { win = win, place = place, dmg = math.floor(f.dmg), share = sum > 0 and f.dmg / sum or 0,
			teeth = teeth, dia = dia, n = #list, why = why or (win and "win" or "time") })
		task.spawn(function() pcall(DataService.SaveNow, p) end)
	end
	task.delay(Cfg.RESULTS_TIME, function()
		local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
		for p, f in fighters do
			if p.Parent == Players and p:GetAttribute("InBossArena") == true then
				p:SetAttribute("InBossArena", nil)
				if okN and NS and NS.TeleportHome then pcall(NS.TeleportHome, p) end
			end
		end
		table.clear(fighters)
		if boss then boss:Destroy(); boss = nil end
		workspace:SetAttribute("BossDamage", "{}")
		setPhase("idle", 0)
	end)
end

-- головний цикл бою
local function fightLoop()
	local _, def = Cfg.current()
	local nextAtk = now() + 3
	local seqI = 0 -- 04.11.2026: номер атаки в черзі def.sequence (з початку в кожному бою)
	local busyUntil = now() + 2 -- 05.11.2026: бос не ходить, поки атакує (замах + удар + відновлення)
	local lastSend, lastDmg = 0, 0
	while phase == "fight" do
		local dt = Cfg.TICK
		task.wait(dt)
		local t = now()
		-- хто вийшов з арени — вибуває
		for p, f in fighters do
			if not f.out and (p.Parent ~= Players or p:GetAttribute("InBossArena") ~= true) then
				f.out = true
				for _, g in f.golems do if not g.dead then g.dead = true; sendFx("dead", g.key) end end
			end
		end
		-- 06.11.2026: големи гравців біля боса обступають його по колу — рівні проміжки, порядок як зараз стоять
		local ring = {}
		for p, f in fighters do
			local hrp = (not f.out) and hrpOf(p) or nil
			if hrp and bossDist(Vector3.new(hrp.Position.X, floorY, hrp.Position.Z)) <= Cfg.ENGAGE_R then
				for _, g in f.golems do
					if not g.dead then table.insert(ring, { g = g, a = math.atan2(g.pos.X - center.X, g.pos.Z - center.Z) }) end
				end
			end
		end
		if #ring > 0 then
			-- 06.11.2026: багато големів (кілька гравців) — два кільця: внутрішнє (2,2 від краю) і зовнішнє (8,2); кожне — рівні
			--   проміжки, щоб големи різних гравців не стояли один в одному. Місткість внутрішнього — периметр / RING_GAP
			table.sort(ring, function(x, y) return x.a < y.a end)
			local h = Cfg.BOSSES.goblin.half
			local cap1 = math.max(1, math.floor(4 * (h.X + h.Z + 4.4) / RING_GAP))
			local rings = { {}, {} }
			for i, r in ring do table.insert((#ring > cap1 and i % 2 == 0) and rings[2] or rings[1], r) end
			for ri, rr in rings do
				if #rr > 0 then
					local step = 2 * math.pi / #rr
					local sx, sz = 0, 0
					for i, r in rr do sx += math.sin(r.a - (i - 1) * step); sz += math.cos(r.a - (i - 1) * step) end
					local off = math.atan2(sx, sz) + (ri == 2 and step / 2 or 0)
					for i, r in rr do r.g.ringA = off + (i - 1) * step; r.g.ringM = RING_M[ri] end
				end
			end
		end
		local hits = {} -- 06.11.2026: удари големів цього кроку → клієнтам (спливаючі цифри шкоди)
		-- рух і удари големів
		for p, f in fighters do
			if not f.out then
				local hrp = hrpOf(p)
				local base = hrp and Vector3.new(hrp.Position.X, floorY, hrp.Position.Z) or nil
				local look = hrp and hrp.CFrame.LookVector or Vector3.new(0, 0, -1)
				local ang0 = math.atan2(look.X, look.Z)
				-- 04.11.2026: гравець біля боса (≤ ENGAGE_R) — големи йдуть до боса з боку гравця і б'ють; інакше — «хмарка» за гравцем
				local engage = base and bossDist(base) <= Cfg.ENGAGE_R
				for _, g in f.golems do
					if not g.dead and base then
						local target
						if engage then
							-- 06.11.2026: свій кут на кільці; йде по дузі (не крізь боса), крок кута ≤ 0,5 рад
							local cur = math.atan2(g.pos.X - center.X, g.pos.Z - center.Z)
							local diff = ((g.ringA or cur) - cur + math.pi) % (2 * math.pi) - math.pi
							target = pushOut(ringPoint(cur + math.clamp(diff, -0.5, 0.5), g.ringM))
						else
							local a = ang0 + math.pi + (g.slot - (g.n + 1) / 2) * 0.75
							-- 06.11.2026: за гравцем — крізь боса (без pushOut), щоб можна було вивести големів із зони удару навпростець
							target = base + Vector3.new(math.sin(a), 0, math.cos(a)) * Cfg.FOLLOW_R * (g.n > 1 and 1 or 0.7)
						end
						local d = target - g.pos
						d = Vector3.new(d.X, 0, d.Z)
						local step = g.move * dt
						local moving = d.Magnitude > 0.6
						if moving then
							local np = g.pos + d.Unit * math.min(step, d.Magnitude)
							g.pos = engage and pushOut(np) or np -- у бою — довкола боса; коли йдуть за гравцем — проходять крізь нього
						end
						local bd = bossDist(g.pos)
						if bd <= Cfg.ATTACK_RANGE + ((engage and g.ringM) and g.ringM - RING_M[1] or 0) and bossHp > 0 then
							local to = Vector3.new(center.X - g.pos.X, 0, center.Z - g.pos.Z)
							if to.Magnitude > 0.1 then g.yaw = math.atan2(-to.X, -to.Z) end
							-- 06.11.2026: дрібні підкроки по кільцю — не «Walk» (інакше удар кожен раз починався спочатку й не доходив до кінця)
							g.st = (moving and d.Magnitude > 1.5) and "Walk" or "Mine"
							if t >= g.nextAtk then
								g.nextAtk = t + g.interval
								bossHp = math.max(0, bossHp - g.dmg)
								f.dmg += g.dmg
								table.insert(hits, { g.key, math.floor(g.dmg + 0.5) })
							end
						else
							if moving then g.yaw = math.atan2(-d.X, -d.Z) end
							g.st = moving and "Walk" or "Idle"
						end
					end
				end
			end
		end
		if #hits > 0 then sendFx("dmg", hits) end
		workspace:SetAttribute("BossHP", math.floor(bossHp))
		if t - lastDmg > 0.5 then lastDmg = t; damageJson() end
		-- позиції клієнтам
		if t - lastSend >= Cfg.SEND_EVERY then
			lastSend = t
			local pk = {}
			for _, f in fighters do
				for _, g in f.golems do
					if not g.dead then
						table.insert(pk, { g.key, math.floor(g.pos.X * 10) / 10, math.floor(g.pos.Z * 10) / 10, math.floor(g.yaw * 100) / 100,
							math.floor(g.hp), g.st == "Mine" and 2 or (g.st == "Walk" and 1 or 0) })
					end
				end
			end
			for _, p in fighterList() do evTick:FireClient(p, pk) end
		end
		-- 05.11.2026: бос ходить по арені — до найближчого гравця-учасника (між атаками); під час атаки стоїть
		if t >= busyUntil and bossHp > 0 then
			local best, bd = nil, math.huge
			for p, f in fighters do
				if not f.out then
					local hrp = hrpOf(p)
					if hrp then
						local d = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z).Magnitude
						if d < bd then bd, best = d, hrp.Position end
					end
				end
			end
			if best and bd > Cfg.BOSS_STOP then
				local dir = Vector3.new(best.X - center.X, 0, best.Z - center.Z).Unit
				local np = center + dir * math.min(Cfg.BOSS_SPEED * dt, bd - Cfg.BOSS_STOP)
				local off = Vector3.new(np.X - arenaCenter.X, 0, np.Z - arenaCenter.Z)
				if off.Magnitude > Cfg.BOSS_ROAM then np = Vector3.new(arenaCenter.X, center.Y, arenaCenter.Z) + off.Unit * Cfg.BOSS_ROAM end
				center = Vector3.new(np.X, center.Y, np.Z)
				faceBoss(math.atan2(-dir.X, -dir.Z))
			end
		end
		-- атаки боса
		if t >= nextAtk and bossHp > 0 then
			local p2 = bossHp < bossMax * 0.5
			local pool, total = {}, 0
			for _, a in def.attacks do if not a.phase2 or p2 then table.insert(pool, a); total += a.weight end end
			local r = rng:NextNumber() * total
			local atk = pool[1]
			for _, a in pool do r -= a.weight; if r <= 0 then atk = a; break end end
			-- 04.11.2026: заскриптована черга замість випадку (якщо задана)
			local forceSide: number? = nil
			if def.sequence and #def.sequence > 0 then
				seqI = seqI % #def.sequence + 1
				local step = def.sequence[seqI]
				for _, a in pool do if a.key == step[1] then atk = a; break end end
				forceSide = step[2]
			end
			attackId += 1
			local id = attackId
			local rects, side = makeAttack(atk, forceSide)
			sendFx("warn", id, atk.key, rects, atk.warn)
			sendFx("boss", "attack", atk.key, atk.warn, side)
			local pause = rng:NextNumber(def.pause[1], def.pause[2]) * (p2 and 0.7 or 1)
			nextAtk = t + atk.warn + pause
			busyUntil = t + atk.warn + 1.3
			task.delay(atk.warn, function()
				if phase ~= "fight" then return end
				local hit = {}
				for _, g in aliveGolems() do
					for _, rc in rects do
						if inRect(g.pos, rc) then
							g.hp = math.max(0, g.hp - g.max * atk.pct * Cfg.hitMult(g.max)) -- 06.11.2026: сильнішим — менший %
							table.insert(hit, g.key)
							if g.hp <= 0 then g.dead = true; sendFx("dead", g.key) end
							break
						end
					end
				end
				sendFx("hit", id, hit)
			end)
		end
		-- кінець
		if bossHp <= 0 then damageJson(); finish(true); return end
		if t >= fightEnd then damageJson(); finish(false); return end
		if #aliveGolems() == 0 and #fighterList() > 0 then damageJson(); finish(false, "wiped"); return end -- усі бійці загинули — бос перемагає
		if #fighterList() == 0 then
			table.clear(fighters)
			if boss then boss:Destroy(); boss = nil end
			setPhase("idle", 0)
			return
		end
	end
end

-- ===== розклад =====
local function scheduler()
	while true do
		task.wait(0.25)
		local t = now()
		local at = tonumber(workspace:GetAttribute("BossAt")) or 0
		if phase == "idle" then
			if at > 0 and t >= at - Cfg.REG_TIME and t < at then
				regEnd = at
				setPhase("reg", at)
			end
		elseif phase == "reg" then
			if t >= regEnd then
				startFight()
				if phase == "fight" then task.spawn(fightLoop) end
			end
		end
	end
end

-- ===== збереження зубів =====
local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "Boss")
	if type(sec) == "table" then
		p:SetAttribute("FossilTeeth", math.max(0, math.floor(tonumber(sec.teeth) or 0)))
		if type(sec.picks) == "table" then p:SetAttribute("BossPicks", enc(sec.picks)) end
		if sec.slotDia == true then p:SetAttribute("BossSlotDia", true) end
	end
	p:SetAttribute("BossReady", true)
end
local function sectionOf(p: Player, old: any): any
	if p:GetAttribute("BossReady") ~= true then return old end
	return { teeth = tonumber(p:GetAttribute("FossilTeeth")) or 0, picks = decode(p, "BossPicks", {}), slotDia = p:GetAttribute("BossSlotDia") == true or nil }
end

function BossFightService.Start()
	local okH, Hub = pcall(require, RS.Shared:FindFirstChild("HubConfig"))
	if okH and Hub and Hub.isMarket and Hub.isMarket() then return end -- маркетплейс — без боса
	DataService.RegisterSection("Boss", sectionOf)
	remotes = RS:FindFirstChild("Remotes") :: Folder or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local function ev(name: string): RemoteEvent
		local e = remotes:FindFirstChild(name) :: RemoteEvent?
		if not e then local n = Instance.new("RemoteEvent"); n.Name = name; n.Parent = remotes; e = n end
		return e :: RemoteEvent
	end
	ev("BossAction").OnServerEvent:Connect(onAction)
	evFx = ev("BossFx"); evTick = ev("BossTick"); evResult = ev("BossResult")
	setupArena()
	setPhase("idle", 0)
	workspace:SetAttribute("BossLobby", "[]")
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p)
		removeFromLobby(p)
		last[p] = nil
	end)
	task.spawn(scheduler)
	-- тест у Studio: workspace:SetAttribute("BossDebugReg", сек) — реєстрація зараз
	if game:GetService("RunService"):IsStudio() then
		workspace:GetAttributeChangedSignal("BossDebugReg"):Connect(function()
			local v = tonumber(workspace:GetAttribute("BossDebugReg"))
			if v and v > 0 then BossFightService.DebugReg(v) end
		end)
	end
end

-- адмін / тест у Studio: почати реєстрацію зараз (ServerScriptService.BossFightService — require(...).DebugReg(сек))
function BossFightService.DebugReg(sec: number?)
	if phase ~= "idle" then return end
	regEnd = now() + (sec or 20)
	setPhase("reg", regEnd)
end

return BossFightService
