--!strict
-- PlotService — плоти (зони фарму) у ніші гравця: спавн руди, големи-майнери, голем-носій, руда на підлозі, прокачка.
-- Де: ServerScriptService/PlotService (ModuleScript). Запуск: NicheBoot після NicheService та InventoryService.
-- Конфіг — Shared/PlotConfig. Моделі — ReplicatedStorage/PlotAssets (Golem, Ores/*, Chunks/*, CarryBox).
-- Ніша: Plots/Plot1..6 (PlotBuilder v2): Base (DropPoint, HomePoint), Floor (плитки), Crate, Label; папки Ores / Drops / Golems.
--   Атрибути плоту: FloorUp (висота поверхні), OreHalf (межі спавну), CrateX / CrateZ / CrateR (зона ящика без руди).
--
-- Цикл плоту:
--   * Поки на плоті менше pointsOf(Points) руди, у випадковому вільному місці з'являється нова руда й росте на очах
--     spawnOf(Spawn) с (GrowT0 / GrowDur; поки росте — її не б'ють), наступна — коли ця доросла. Місце (не біля бортиків,
--     не в ящику, не на рудах і големах, випадковий поворот). Руда: Coal / Copper / Iron за вагами 1/3, 1/9, 1/20,
--     розмір жили S / M / L (60 / 30 / 10%): HP 5 / 15 / 30 × 1 / 1,25 / 1,5 (вгору). З руди падає 1–3 шматки (60 / 30 / 10%)
--     × 1 / 1,5 / 2 за розміром (вниз) × картка Ore Drop (вниз).
--   * Майнер іде до найближчої вільної руди (її ніхто не б'є) і б'є її: шкода dmg раз на int с.
--     Вільної руди немає — приєднується до руди, яку вже б'ють, і стає по колу між іншими майнерами (до 3 на руду);
--     з'явилась вільна — один із «зайвих» переходить на неї. Зламана руда → шматок падає на підлогу; шматки однієї руди поруч зливаються в стак (Count).
--   * Носій (1 на плот) збирає стаки в ящичок (cap за ходку, швидкість spd × картка Carry), несе до ящика плоту й висипає.
--     Руду на підлозі гравець-власник підбирає сам: підходить ближче PICKUP_R — шматки летять до нього й ідуть в інвентар.
--     Стак, який ніхто не підібрав STACK_LIFE с (від останнього шматка), зникає (останні 5 с блимає).
--     Ящик плоту вміщає crateOf(Crate) руди (10 → 1000); повний — носій чекає біля нього з рудою в ящичку.
--   * Гравець забирає руду з ящика: підходить до свого ящика — над ним кнопка COLLECT (клік або E, PlotClient)
--     → дія "Collect" (сервер перевіряє відстань) → Ore_<руда> в інвентар.
--   Атрибути плоту для клієнта: CrateCount, CrateCap, CrateMix ("Coal:3,Copper:1"), Collected / CollectT.
-- Рух не фізичний: сервер ставить на модель голема атрибути MoveFrom / MoveTo / MoveT0 / MoveDur (час сервера) і Look,
--   клієнт (PlotClient) рухає Root, аніматор (State / AnimSpeed / Carry / MineTarget) — решту.
-- Стан для клієнта: плот — атрибут Unlocked; гравець — PlotLv (JSON рівнів карток), PlotAssign (JSON: { [плот] = { m = {id..}, c = id } }),
--   PlotPlaced (JSON id големів на плотах; їх не можна видалити в інвентарі).
-- Дії (RemoteEvent Remotes/PlotAction):
--   "Place", { plot, slot = "m1".."m5" | "c", id = number | nil }  — поставити голема в слот (nil — зняти);
--   "EquipBest"                                                    — найкращі майнери й носії на всі відкриті плоти (1→6);
--   "Collect", plot                                                — забрати руду з ящика плоту (гравець ≤ 70 стадів від ящика);
--   "Upgrade", key ("Plots" | "Points" | "Spawn" | "Slots" | "Carry" | "Crate" | "Drop") — купити рівень картки за Money.
-- Збереження: секція "Plots" { stage, lv, assign, crates } (скидається на новій мапі, GDD 6).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local NicheService = require(script.Parent:WaitForChild("NicheService"))

local ASSETS = RS:WaitForChild("PlotAssets")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local INK = Color3.fromHex("040435")

local PlotService = {}
local rng = Random.new()
local function now(): number return workspace:GetServerTimeNow() end

type Ore = { model: Model, key: string, size: any, hp: number, max: number, pos: Vector3, radius: number, miners: number, dead: boolean,
	angles: { [any]: number }, readyAt: number } -- angles: кут кожного майнера навколо руди (щоб спільна руда — по колу, а не один в одному)
type Stack = { model: Model, key: string, n: number, pos: Vector3, label: TextLabel, dead: boolean, t: number }
type Golem = {
	id: number, kind: string, role: string, model: Model, pos: Vector3,
	mode: string, until_: number, ore: Ore?, nextHit: number, stack: Stack?, load: { string },
	from: Vector3, to: Vector3, t0: number, dur: number,
}
type Plot = {
	idx: number, model: Model, base: BasePart, cf: CFrame, y: number, floor: number, half: number, crate: Vector3, crateR: number,
	ores: { Ore }, stacks: { Stack }, golems: { Golem }, acc: number, drop: Vector3, home: Vector3,
	bin: { [string]: number }, binN: number,
}
type State = {
	player: Player, niche: Model, plots: { Plot }, lv: { [string]: number }, assign: { [number]: { m: { number }, c: number? } },
}
local states: { [Player]: State } = {}

-- ===== допоміжне =====
local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end
-- скрипти в шаблонах PlotAssets вимкнені (клієнтські скрипти в ReplicatedStorage інакше працювали б і на шаблонах)
local function enableScripts(m: Instance)
	for _, d in m:GetDescendants() do if d:IsA("Script") then d.Enabled = true end end
end
local function encode(p: Player, attr: string, v: any) p:SetAttribute(attr, HttpService:JSONEncode(v)) end
local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function invGolems(p: Player): { [number]: any }
	local out = {}
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and type(g.id) == "number" then out[g.id] = g end
	end
	return out
end
local function roleOf(g: any): string return (g and g.cls == "carrier") and "carrier" or "miner" end

-- точка всередині плоту (локальні межі ±HALF)
local function clampIn(pl: Plot, v: Vector3): Vector3
	local l = pl.cf:PointToObjectSpace(v)
	local h = Cfg.HALF
	return pl.cf:PointToWorldSpace(Vector3.new(math.clamp(l.X, -h, h), 0, math.clamp(l.Z, -h, h))) * Vector3.new(1, 0, 1) + Vector3.new(0, pl.y, 0)
end

-- ===== руда =====
local oreBottom: { [string]: number } = {}
local function bottomOffset(t: Model): number
	local key = t.Name
	if not oreBottom[key] then
		local cf, size = t:GetBoundingBox()
		oreBottom[key] = t:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
	end
	return oreBottom[key]
end

-- випадкове вільне місце для руди радіусом r (у координатах плоту ±half, поза ящиком, рудами й големами)
local function freeSpot(pl: Plot, r: number): Vector3?
	for _ = 1, 40 do
		local lx = (rng:NextNumber() * 2 - 1) * (pl.half - math.max(0, r - 4))
		local lz = (rng:NextNumber() * 2 - 1) * (pl.half - math.max(0, r - 4))
		local ok = (Vector3.new(lx, 0, lz) - pl.crate).Magnitude > pl.crateR + r
		if ok then
			local w = pl.cf:PointToWorldSpace(Vector3.new(lx, 0, lz))
			local pos = Vector3.new(w.X, pl.floor, w.Z)
			for _, o in pl.ores do
				if (flat(o.pos) - flat(pos)).Magnitude < o.radius + r + Cfg.ORE_GAP then ok = false; break end
			end
			if ok then
				for _, g in pl.golems do
					if (flat(g.pos) - flat(pos)).Magnitude < r + 2.5 then ok = false; break end
				end
			end
			if ok then return pos end
		end
	end
	return nil
end

local function spawnOre(pl: Plot, grow: number): boolean
	local def = Cfg.rollOre(rng)
	local size = Cfg.rollSize(rng)
	local t = ASSETS.Ores:FindFirstChild(def.key .. "_" .. size.key) :: Model
	local radius = (t:GetAttribute("Radius") :: number?) or 3.5
	local p = freeSpot(pl, radius * 0.8)
	if not p then return false end
	local m = t:Clone()
	-- випадковий поворот і легкий нахил, щоб руда не стояла «рядами»
	m:PivotTo(CFrame.new(p + Vector3.new(0, bottomOffset(t) - 0.15, 0))
		* CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), rng:NextNumber() * math.pi * 2, math.rad(rng:NextNumber(-5, 5))))
	local hp = Cfg.hpOf(def, size)
	m:SetAttribute("Ore", def.key)
	m:SetAttribute("Size", size.key)
	m:SetAttribute("HP", hp)
	m:SetAttribute("MaxHP", hp)
	local t0 = now()
	m:SetAttribute("GrowT0", t0)   -- клієнт показує ріст по стадіях (PlotClient.growOre)
	m:SetAttribute("GrowDur", grow)
	m.Name = def.key .. "_" .. size.key
	enableScripts(m)
	m.Parent = pl.model:FindFirstChild("Ores")
	table.insert(pl.ores, { model = m, key = def.key, size = size, hp = hp, max = hp, pos = p, radius = radius * 0.8, miners = 0, dead = false, angles = {}, readyAt = t0 + grow })
	return true
end

-- ===== шматки руди на підлозі (стаки) =====
local function newStack(pl: Plot, key: string, pos: Vector3, from: Vector3): Stack
	pos = Vector3.new(pos.X, pl.floor, pos.Z)
	local m = (ASSETS.Chunks:FindFirstChild(key) :: Model):Clone()
	m.Name = "Stack"
	local glow = Color3.fromHex((m:GetAttribute("Glow") :: string?) or "ffffff")
	m:PivotTo(CFrame.new(pos + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0))
	local halo = Instance.new("Part")
	halo.Name = "Halo"; halo.Shape = Enum.PartType.Cylinder
	halo.Size = Vector3.new(0.06, 2.4, 2.4)
	halo.CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	halo.Material = Enum.Material.Neon; halo.Color = glow; halo.Transparency = 0.55
	halo.Anchored = true; halo.CanCollide = false; halo.CanQuery = false; halo.CanTouch = false; halo.CastShadow = false
	halo.Parent = m
	local light = Instance.new("PointLight")
	light.Color = glow; light.Range = 7; light.Brightness = 1.4; light.Shadows = false
	light.Parent = m.PrimaryPart
	local bb = Instance.new("BillboardGui")
	bb.Name = "Count"; bb.Size = UDim2.fromScale(2.2, 1); bb.StudsOffset = Vector3.new(0, 1.9, 0)
	bb.MaxDistance = 70; bb.LightInfluence = 0; bb.Adornee = m.PrimaryPart
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.FontFace = HEAVY; t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1); t.Text = ""; t.Visible = false
	local s = Instance.new("UIStroke"); s.Color = INK; s.Thickness = 2.5; s.Parent = t
	t.Parent = bb
	bb.Parent = m
	m:SetAttribute("Ore", key)
	m:SetAttribute("Count", 1)
	m:SetAttribute("BornT", now())
	m:SetAttribute("From", from)
	m:SetAttribute("ExpireT", now() + Cfg.STACK_LIFE)
	m.Parent = pl.model:FindFirstChild("Drops")
	local st: Stack = { model = m, key = key, n = 1, pos = pos, label = t, dead = false, t = now() }
	table.insert(pl.stacks, st)
	return st
end

local function setCount(st: Stack, n: number)
	st.n = n
	st.model:SetAttribute("Count", n)
	st.label.Text = "×" .. n
	st.label.Visible = n > 1
end

local function dropChunk(pl: Plot, key: string, from: Vector3, n: number, oreR: number)
	-- місце падіння: поруч з рудою (за її краєм), у межах плоту
	local a = rng:NextNumber() * math.pi * 2
	local r = oreR + 0.6 + rng:NextNumber() * 1.6
	local pos = clampIn(pl, from + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	for _, st in pl.stacks do
		if not st.dead and st.key == key and st.n < Cfg.STACK_MAX and (flat(st.pos) - flat(pos)).Magnitude <= Cfg.STACK_RADIUS then
			local add = math.min(n, Cfg.STACK_MAX - st.n)
			st.t = now() -- новий шматок — відлік зникнення заново
			st.model:SetAttribute("ExpireT", st.t + Cfg.STACK_LIFE)
			st.model:SetAttribute("AddFrom", from)
			st.model:SetAttribute("AddT", now())
			setCount(st, st.n + add)
			n -= add
			if n <= 0 then return end
		end
	end
	while n > 0 do
		local st = newStack(pl, key, pos, from)
		local c = math.min(n, Cfg.STACK_MAX)
		setCount(st, c)
		n -= c
		pos = clampIn(pl, pos + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)))
	end
end

local function removeStack(pl: Plot, st: Stack)
	st.dead = true
	local i = table.find(pl.stacks, st)
	if i then table.remove(pl.stacks, i) end
	st.model:Destroy()
end

-- стак зникає: attr = "Expired" (час вийшов) або "PickedT" (підібрав гравець); клієнт грає анімацію 0,35 с
local function killStack(pl: Plot, sk: Stack, attr: string)
	sk.dead = true
	local i = table.find(pl.stacks, sk)
	if i then table.remove(pl.stacks, i) end
	sk.model:SetAttribute(attr, now())
	task.delay(0.4, function() sk.model:Destroy() end)
end

-- власник підходить до руди на підлозі — вона сама йде в інвентар
local function pickup(st: State, pl: Plot, hrp: BasePart?)
	local t = now()
	for k = #pl.stacks, 1, -1 do
		local sk = pl.stacks[k]
		if t - sk.t > Cfg.STACK_LIFE then
			killStack(pl, sk, "Expired")
		elseif hrp and math.abs(hrp.Position.Y - sk.pos.Y) < 8 and (flat(hrp.Position) - flat(sk.pos)).Magnitude <= Cfg.PICKUP_R then
			local p = st.player
			p:SetAttribute("Ore_" .. sk.key, ((p:GetAttribute("Ore_" .. sk.key) :: number?) or 0) + sk.n)
			sk.model:SetAttribute("PickedN", sk.n)
			sk.model:SetAttribute("PickedBy", p.UserId)
			killStack(pl, sk, "PickedT")
		end
	end
end

local function breakOre(st: State, pl: Plot, o: Ore)
	o.dead = true
	local i = table.find(pl.ores, o)
	if i then table.remove(pl.ores, i) end
	o.model:SetAttribute("Broken", now())
	-- 1–3 шматки × розмір жили × картка Ore Drop; падають 1–3 купками навколо руди
	local n = Cfg.rollDrop(rng, o.size, st.lv.Drop or 1)
	o.model:SetAttribute("Dropped", n)
	local piles = math.min(n, if o.size.key == "L" then 3 elseif o.size.key == "M" then 2 else 1)
	for k = 1, piles do
		local share = math.floor(n / piles) + (if k <= n % piles then 1 else 0)
		dropChunk(pl, o.key, o.pos, share, o.radius)
	end
	task.delay(0.4, function() o.model:Destroy() end)
end

-- ===== големи: рух і стан =====
local function setMove(g: Golem, to: Vector3, speed: number, state: string): number
	local from = g.pos
	local dist = (flat(to) - flat(from)).Magnitude
	local dur = dist / math.max(speed, 0.1)
	g.from, g.to, g.t0, g.dur = from, to, now(), dur
	local m = g.model
	m:SetAttribute("MoveFrom", from)
	m:SetAttribute("MoveTo", to)
	m:SetAttribute("MoveT0", now())
	m:SetAttribute("MoveDur", dur)
	if dist > 0.05 then m:SetAttribute("Look", to + (to - from).Unit * 5) end
	local run = speed > 13
	m:SetAttribute("State", run and "Run" or "Walk")
	m:SetAttribute("AnimSpeed", run and speed / 16 or speed / 8)
	return dur
end

local function stand(g: Golem, state: string, look: Vector3?)
	local m = g.model
	m:SetAttribute("MoveFrom", g.pos)
	m:SetAttribute("MoveTo", g.pos)
	m:SetAttribute("MoveT0", now())
	m:SetAttribute("MoveDur", 0)
	if look then m:SetAttribute("Look", look) end
	m:SetAttribute("State", state)
	if state ~= "Mine" then m:SetAttribute("AnimSpeed", 1) end
end

local function setLoad(g: Golem)
	g.model:SetAttribute("Load", #g.load)
	g.model:SetAttribute("LoadOres", table.concat(g.load, ","))
end

local function spawnGolem(pl: Plot, id: number, kind: string, role: string): Golem
	local m = ASSETS.Golem:Clone()
	m.Name = (role == "carrier" and "Carrier_" or "Miner_") .. id
	m:SetAttribute("GolemId", id); m:SetAttribute("Kind", kind); m:SetAttribute("Role", role)
	m:SetAttribute("Carry", role == "carrier")
	if role == "carrier" then
		local pick = m:FindFirstChild("Pickaxe")
		if pick then for _, d in pick:GetDescendants() do if d:IsA("BasePart") then d.Transparency = 1 end end end
	end
	-- з'являються по колу навколо HomePoint, щоб не стояти один в одному
	local k = #pl.golems
	local a = k * math.rad(72) + rng:NextNumber() * 0.3
	local r = if role == "carrier" then 0 else 7
	local pos = role == "carrier" and pl.drop + (pl.home - pl.drop).Unit * 2.5 or clampIn(pl, pl.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	m:PivotTo(CFrame.new(pos))
	enableScripts(m)
	local g: Golem = {
		id = id, kind = kind, role = role, model = m, pos = pos, mode = "idle", until_ = 0, ore = nil, nextHit = 0,
		stack = nil, load = {}, from = pos, to = pos, t0 = 0, dur = 0,
	}
	stand(g, "Idle", pos + (pl.cf.LookVector * -5))
	setLoad(g)
	m.Parent = pl.model:FindFirstChild("Golems")
	table.insert(pl.golems, g)
	return g
end

local function releaseOre(g: Golem)
	if g.ore then g.ore.miners = math.max(0, g.ore.miners - 1); g.ore.angles[g] = nil; g.ore = nil end
	local mt = g.model:FindFirstChild("MineTarget")
	if mt and mt:IsA("ObjectValue") then mt.Value = nil end
end

local function despawnGolem(pl: Plot, g: Golem)
	releaseOre(g)
	local i = table.find(pl.golems, g)
	if i then table.remove(pl.golems, i) end
	g.model:Destroy()
end

-- ===== майнер =====
-- Спершу ВІЛЬНА руда (її ніхто не б'є), найближча. Вільної немає — голем приєднується до руди, яку вже б'ють
-- (менше майнерів, потім ближча; до SHARE_MAX на одну руду) і стає по колу між іншими.
-- Щойно з'являється вільна руда, «зайві» майнери спільної руди переходять на неї (по одному — хто перший).
local SHARE_MAX = 3
local function pickOre(pl: Plot, g: Golem, freeOnly: boolean?): Ore?
	local best: Ore?, bestScore = nil, math.huge
	local shared: Ore?, sharedScore = nil, math.huge
	local tn = now()
	for _, o in pl.ores do
		if not o.dead and o.readyAt <= tn then -- руда, що ще росте, не рахується
			local d = (flat(o.pos) - flat(g.pos)).Magnitude
			if o.miners == 0 then
				if d < bestScore then best, bestScore = o, d end
			elseif not freeOnly and o.miners < SHARE_MAX then
				local sc = o.miners * 1000 + d
				if sc < sharedScore then shared, sharedScore = o, sc end
			end
		end
	end
	return best or shared
end

-- точка біля руди: з боку, звідки йде голем; якщо руду вже б'ють — кут, найдальший від кутів інших майнерів
-- (кандидати ±15°, ±30° … від власного напрямку, з малою перевагою ближчих) — стають по колу, а не один в одному
local function standPoint(pl: Plot, g: Golem, o: Ore): Vector3
	local d = flat(g.pos) - flat(o.pos)
	if d.Magnitude < 0.1 then d = Vector3.new(1, 0, 0) end
	local ang = math.atan2(d.Z, d.X)
	local others = {}
	for og, a in o.angles do if og ~= g then table.insert(others, a) end end
	if #others > 0 then
		local bestA, bestGap = ang, -math.huge
		for k = 0, 12 do
			for _, sgn in { 1, -1 } do
				if k > 0 or sgn == 1 then
					local a = ang + sgn * k * math.rad(15)
					local gap = math.huge
					for _, b in others do
						local dd = math.abs((a - b + math.pi) % (2 * math.pi) - math.pi)
						if dd < gap then gap = dd end
					end
					gap -= k * 0.01
					if gap > bestGap then bestA, bestGap = a, gap end
				end
			end
		end
		ang = bestA
	end
	o.angles[g] = ang
	local reach = Cfg.REACH + math.max(0, o.radius / 0.8 - Cfg.REACH_R) * 0.8
	return clampIn(pl, o.pos + Vector3.new(math.cos(ang), 0, math.sin(ang)) * reach)
end

local function tickMiner(st: State, pl: Plot, g: Golem, t: number)
	local s = Cfg.stats(g.kind)
	if g.mode == "move" then
		if g.ore and g.ore.dead then -- руду зламав інший майнер, поки цей ішов: зупиняємось там, де він зараз
			g.ore = nil
			g.pos = g.from:Lerp(g.to, math.clamp((t - g.t0) / math.max(g.dur, 1e-3), 0, 1))
			g.mode = "idle"
			stand(g, "Idle")
			return
		end
		if t < g.until_ then return end
		g.pos = g.to
		local o = g.ore
		if not o or o.dead then g.ore = nil; g.mode = "idle"; stand(g, "Idle"); return end
		g.mode = "mine"
		local as = Cfg.MINE_CLIP / s.int
		g.model:SetAttribute("AnimSpeed", as)
		local mt = g.model:FindFirstChild("MineTarget")
		if mt and mt:IsA("ObjectValue") then mt.Value = o.model end
		stand(g, "Mine", o.pos)
		g.nextHit = t + Cfg.MINE_HIT / as
		return
	elseif g.mode == "mine" then
		local o = g.ore
		if not o or o.dead then releaseOre(g); g.mode = "idle"; stand(g, "Idle"); return end
		-- б'ємо спільну руду, а з'явилась вільна — переходимо на неї (лише вільна, щоб не перескакувати між спільними)
		if o.miners > 1 then
			local f = pickOre(pl, g, true)
			if f then
				releaseOre(g)
				g.ore = f
				f.miners += 1
				local dur = setMove(g, standPoint(pl, g, f), Cfg.MINER_SPEED, "Walk")
				g.mode = "move"
				g.until_ = t + dur
				return
			end
		end
		if t >= g.nextHit then
			g.nextHit += s.int
			o.hp -= s.dmg
			o.model:SetAttribute("HP", math.max(0, o.hp))
			if o.hp <= 0 then
				releaseOre(g)
				breakOre(st, pl, o)
				g.mode = "idle"
				g.until_ = t + 0.25 -- коротка пауза після останнього удару
				stand(g, "Idle")
			end
		end
		return
	end
	-- idle
	if t < g.until_ then return end
	local o = pickOre(pl, g)
	if not o then
		if g.model:GetAttribute("State") ~= "Idle" then stand(g, "Idle") end
		g.until_ = t + 0.3
		return
	end
	g.ore = o
	o.miners += 1
	local dest = standPoint(pl, g, o)
	local dur = setMove(g, dest, Cfg.MINER_SPEED, "Walk")
	g.mode = "move"
	g.until_ = t + dur
end

-- ===== носій =====
local function nearestStack(pl: Plot, from: Vector3): Stack?
	local best: Stack?, bd = nil, math.huge
	for _, st in pl.stacks do
		if not st.dead then
			local d = (flat(st.pos) - flat(from)).Magnitude
			if d < bd then best, bd = st, d end
		end
	end
	return best
end

-- ===== ящик плоту =====
local function crateCap(st: State): number return Cfg.crateOf(st.lv.Crate or 1) end
local function showCrate(st: State, pl: Plot)
	local m = pl.model
	local mix = {}
	for _, o in Cfg.ORES do
		local n = pl.bin[o.key] or 0
		if n > 0 then table.insert(mix, o.key .. ":" .. n) end
	end
	m:SetAttribute("CrateCount", pl.binN)
	m:SetAttribute("CrateCap", crateCap(st))
	m:SetAttribute("CrateMix", table.concat(mix, ","))
end

-- носій висипає ящичок у ящик плоту, скільки влазить; решта лишається в ящичку (force — усе, напр. коли носія знімають)
local function deliver(st: State, pl: Plot, g: Golem, force: boolean?)
	local space = if force then math.huge else crateCap(st) - pl.binN
	local put = 0
	while #g.load > 0 and put < space do
		local k = table.remove(g.load) :: string
		pl.bin[k] = (pl.bin[k] or 0) + 1
		put += 1
	end
	pl.binN += put
	if put > 0 then
		g.model:SetAttribute("Delivered", put)
		g.model:SetAttribute("DeliverT", now())
		setLoad(g)
		showCrate(st, pl)
	end
end

local function collect(st: State, pl: Plot)
	if pl.binN <= 0 then return end
	local p = st.player
	for k, n in pl.bin do
		if n > 0 then p:SetAttribute("Ore_" .. k, ((p:GetAttribute("Ore_" .. k) :: number?) or 0) + n) end
	end
	pl.model:SetAttribute("Collected", pl.binN)
	pl.model:SetAttribute("CollectT", now())
	table.clear(pl.bin)
	pl.binN = 0
	showCrate(st, pl)
end

local function tickCarrier(st: State, pl: Plot, g: Golem, t: number)
	local s = Cfg.stats(g.kind)
	local speed = s.spd * Cfg.carryOf(st.lv.Carry or 1)
	if t < g.until_ then return end
	if g.mode == "fetch" then
		g.pos = g.to
		local sk = g.stack
		g.stack = nil
		if sk and not sk.dead then
			local take = math.min(sk.n, s.cap - #g.load)
			for _ = 1, take do table.insert(g.load, sk.key) end
			if take >= sk.n then removeStack(pl, sk) else setCount(sk, sk.n - take) end
			setLoad(g)
		end
		g.mode = "pick"
		g.until_ = t + Cfg.PICK_TIME
		stand(g, "Idle")
		return
	elseif g.mode == "deliver" then
		g.pos = g.to
		g.mode = "dump"
		g.until_ = t + Cfg.DROP_TIME
		stand(g, "Idle", pl.drop + (pl.drop - pl.home).Unit * 6) -- обличчям до ящика
		return
	elseif g.mode == "dump" or g.mode == "full" then
		deliver(st, pl, g)
		if #g.load > 0 then -- ящик повний: чекаємо біля нього, поки гравець не забере руду
			g.mode = "full"
			g.until_ = t + 0.5
			return
		end
		g.mode = "idle"
	elseif g.mode == "home" then
		g.pos = g.to
		g.mode = "idle"
		stand(g, "Idle")
	end
	-- idle / pick → наступна дія
	local full = #g.load >= s.cap
	local sk = not full and nearestStack(pl, g.pos) or nil
	if sk then
		g.stack = sk
		local d = flat(sk.pos) - flat(g.pos)
		local dest = d.Magnitude > 1.6 and (sk.pos - d.Unit * 1.4) or g.pos
		g.until_ = t + setMove(g, Vector3.new(dest.X, pl.y, dest.Z), speed, "Walk")
		g.mode = "fetch"
	elseif #g.load > 0 then
		g.until_ = t + setMove(g, pl.drop, speed, "Walk")
		g.mode = "deliver"
	elseif (flat(g.pos) - flat(pl.drop)).Magnitude > 3.5 and g.mode ~= "wait" then
		g.until_ = t + setMove(g, pl.drop + (pl.home - pl.drop).Unit * 2.5, speed, "Walk")
		g.mode = "home"
	else
		if g.model:GetAttribute("State") ~= "Idle" then stand(g, "Idle") end
		g.mode = "wait"
		g.until_ = t + 0.25
	end
end

-- ===== плоти гравця =====
local function plotsOf(niche: Model): { Model }
	local out = {}
	local f = niche:FindFirstChild("Plots")
	if f then
		for _, m in f:GetChildren() do
			local i = m:GetAttribute("PlotIndex")
			if m:IsA("Model") and type(i) == "number" then out[i] = m end
		end
	end
	return out
end

local function makePlot(m: Model, i: number): Plot
	local base = m:FindFirstChild("Base") :: BasePart
	local bottom = base.Position.Y - base.Size.Y / 2
	local floor = bottom + ((m:GetAttribute("FloorUp") :: number?) or base.Size.Y) -- поверхня плиток
	local y = floor + 0.4 -- Root голема — 0,4 стада над підлогою
	local cf = CFrame.new(base.Position) * base.CFrame.Rotation
	local drop = (base:FindFirstChild("DropPoint") :: Attachment).WorldPosition
	local home = (base:FindFirstChild("HomePoint") :: Attachment).WorldPosition
	return {
		idx = i, model = m, base = base, cf = cf, y = y, floor = floor,
		half = (m:GetAttribute("OreHalf") :: number?) or 15,
		crate = Vector3.new((m:GetAttribute("CrateX") :: number?) or 0, 0, (m:GetAttribute("CrateZ") :: number?) or 0),
		crateR = (m:GetAttribute("CrateR") :: number?) or 7,
		ores = {}, stacks = {}, golems = {}, acc = 0,
		drop = Vector3.new(drop.X, y, drop.Z), home = Vector3.new(home.X, y, home.Z),
		bin = {}, binN = 0,
	}
end

local function unlockedCount(st: State): number return Cfg.plotsOf(st.lv.Plots or 1) end

local function publish(st: State)
	local p = st.player
	encode(p, "PlotLv", st.lv)
	local a = {}
	local placed = {}
	for i, s in st.assign do
		a[tostring(i)] = { m = s.m, c = s.c }
		for _, id in s.m do table.insert(placed, id) end
		if s.c then table.insert(placed, s.c) end
	end
	encode(p, "PlotAssign", a)
	encode(p, "PlotPlaced", placed)
	for i, pl in st.plots do
		pl.model:SetAttribute("Unlocked", i <= unlockedCount(st))
		showCrate(st, pl)
	end
end

-- привести моделі големів на плотах у відповідність до st.assign
local function syncGolems(st: State)
	local inv = invGolems(st.player)
	for i, pl in st.plots do
		local s = st.assign[i]
		local want: { [number]: string } = {}
		if s and i <= unlockedCount(st) then
			for k, id in s.m do if k <= Cfg.slotsOf(st.lv.Slots or 1) and inv[id] then want[id] = "miner" end end
			if s.c and inv[s.c] then want[s.c] = "carrier" end
		end
		for k = #pl.golems, 1, -1 do
			local g = pl.golems[k]
			if want[g.id] ~= g.role then
				-- знімаємо: руда в ящичку носія не пропадає
				if g.role == "carrier" and #g.load > 0 then deliver(st, pl, g, true) end
				despawnGolem(pl, g)
			else
				want[g.id] = nil
			end
		end
		for id, role in want do spawnGolem(pl, id, inv[id].kind, role) end
	end
end

-- прибрати з призначень те, чого вже немає в інвентарі / не того класу / зайве
local function sanitize(st: State)
	local inv = invGolems(st.player)
	local used: { [number]: boolean } = {}
	local slots = Cfg.slotsOf(st.lv.Slots or 1)
	for i = 1, Cfg.MAX_PLOTS do
		local s = st.assign[i]
		if s then
			local m = {}
			for _, id in s.m do
				if #m < slots and inv[id] and roleOf(inv[id]) == "miner" and not used[id] then table.insert(m, id); used[id] = true end
			end
			s.m = m
			if s.c and not (inv[s.c] and roleOf(inv[s.c]) == "carrier" and not used[s.c]) then s.c = nil end
			if s.c then used[s.c] = true end
			if #s.m == 0 and not s.c then st.assign[i] = nil end
		end
	end
end

local function equipBest(st: State)
	local inv = invGolems(st.player)
	local miners, carriers = {}, {}
	for id, g in inv do table.insert(roleOf(g) == "carrier" and carriers or miners, { id = id, kind = g.kind }) end
	table.sort(miners, function(a, b)
		local pa, pb = Cfg.minerPower(a.kind), Cfg.minerPower(b.kind)
		if pa ~= pb then return pa > pb end
		return a.id < b.id
	end)
	table.sort(carriers, function(a, b)
		local pa, pb = Cfg.carrierPower(a.kind), Cfg.carrierPower(b.kind)
		if pa ~= pb then return pa > pb end
		return a.id < b.id
	end)
	local slots = Cfg.slotsOf(st.lv.Slots or 1)
	table.clear(st.assign)
	local mi, ci = 1, 1
	for i = 1, unlockedCount(st) do
		local s = { m = {}, c = nil }
		for _ = 1, slots do
			if miners[mi] then table.insert(s.m, miners[mi].id); mi += 1 end
		end
		if carriers[ci] then s.c = carriers[ci].id; ci += 1 end
		if #s.m > 0 or s.c then st.assign[i] = s end
	end
end

local function hasAutoEquip(p: Player): boolean
	if p:GetAttribute("AutoEquipBest") ~= true then return false end
	if Cfg.AUTO_EQUIP_PASS == 0 then return RunService:IsStudio() end
	local ok, own = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, Cfg.AUTO_EQUIP_PASS)
	return ok and own
end

local function refresh(st: State)
	if hasAutoEquip(st.player) then equipBest(st) end
	sanitize(st)
	syncGolems(st)
	publish(st)
end

-- ===== прокачка =====
local function upgrade(st: State, key: string)
	local card = Cfg.CARDS[key]
	if not card then return end
	local l = st.lv[key] or 1
	if l >= card.max then return end
	local p = st.player
	if not Cfg.cardOpen(key, tonumber(p:GetAttribute("Stage"))) then return end -- закрита до наступної карти (Auto Sell)
	local price = card.price(l)
	local money = (p:GetAttribute("Money") :: number?) or 0
	if money < price then return end
	p:SetAttribute("Money", money - price)
	st.lv[key] = l + 1
	refresh(st)
end

-- ===== життєвий цикл =====
local function setup(p: Player, niche: Model)
	local sec = DataService.GetSection(p, "Plots")
	local stage = (niche:GetAttribute("Stage") :: number?) or 1
	local st: State = { player = p, niche = niche, plots = {}, lv = Cfg.defaultLevels(), assign = {} }
	if type(sec) == "table" and (sec.stage or 1) == stage then
		if type(sec.lv) == "table" then
			for k, card in Cfg.CARDS do st.lv[k] = math.clamp(math.floor(tonumber(sec.lv[k]) or 1), 1, card.max) end
		end
		if type(sec.assign) == "table" then
			for k, s in sec.assign do
				local i = tonumber(k)
				if i and type(s) == "table" then
					local m = {}
					if type(s.m) == "table" then for _, id in s.m do if type(id) == "number" then table.insert(m, id) end end end
					st.assign[i] = { m = m, c = type(s.c) == "number" and s.c or nil }
				end
			end
		end
	end
	for i, m in plotsOf(niche) do st.plots[i] = makePlot(m, i) end
	-- руда, що лежала в ящиках (збереження)
	if type(sec) == "table" and (sec.stage or 1) == stage and type(sec.crates) == "table" then
		for k, bin in sec.crates do
			local pl = st.plots[tonumber(k) or 0]
			if pl and type(bin) == "table" then
				for _, o in Cfg.ORES do
					local n = math.max(0, math.floor(tonumber(bin[o.key]) or 0))
					if n > 0 then pl.bin[o.key] = n; pl.binN += n end
				end
			end
		end
	end
	states[p] = st
	-- ТЕСТ (Studio, немає збереження): одразу ставимо найкращих големів, щоб плот працював
	if sec == nil and RunService:IsStudio() then
		while p.Parent and p:GetAttribute("InvReady") ~= true do task.wait(0.1) end
		equipBest(st)
	end
	refresh(st)
end

local function teardown(p: Player)
	states[p] = nil
	p:SetAttribute("PlotPlaced", nil)
end

local function sectionOf(p: Player, old: any): any
	local st = states[p]
	if not st then return old end
	local a = {}
	for i, s in st.assign do a[tostring(i)] = { m = s.m, c = s.c } end
	local crates = {}
	for i, pl in st.plots do
		if pl.binN > 0 then crates[tostring(i)] = table.clone(pl.bin) end
		-- руда в ящичку носія теж зберігається (у ящик плоту)
		for _, g in pl.golems do
			for _, k in g.load do
				crates[tostring(i)] = crates[tostring(i)] or {}
				crates[tostring(i)][k] = (crates[tostring(i)][k] or 0) + 1
			end
		end
	end
	return { stage = (st.niche:GetAttribute("Stage") :: number?) or 1, lv = st.lv, assign = a, crates = crates }
end

local function onAction(p: Player, action: any, arg: any)
	local st = states[p]
	if not st then return end
	if action == "Upgrade" and type(arg) == "string" then
		upgrade(st, arg)
	elseif action == "Collect" then
		local i = tonumber(arg)
		local pl = i and st.plots[i]
		if not pl or (i :: number) > unlockedCount(st) then return end
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local crate = pl.model:FindFirstChild("Crate")
		if hrp and crate and crate:IsA("Model") and (flat(hrp.Position) - flat(crate:GetPivot().Position)).Magnitude <= 70 then -- кнопку видно за відстанню камери (≤ 50), гравець — поруч
			collect(st, pl)
		end
	elseif action == "EquipBest" then
		equipBest(st)
		refresh(st)
	elseif action == "Place" and type(arg) == "table" then
		local i = tonumber(arg.plot)
		if not i or i < 1 or i > unlockedCount(st) then return end
		local slot = arg.slot
		local id = arg.id
		if id ~= nil and type(id) ~= "number" then return end
		local inv = invGolems(p)
		if id and not inv[id] then return end
		-- голем може стояти лише в одному слоті: знімаємо його звідусіль
		if id then
			for _, s in st.assign do
				local k = table.find(s.m, id); if k then table.remove(s.m, k) end
				if s.c == id then s.c = nil end
			end
		end
		local s = st.assign[i] or { m = {}, c = nil }
		st.assign[i] = s
		if slot == "c" then
			if id and roleOf(inv[id]) ~= "carrier" then return end
			s.c = id
		elseif type(slot) == "string" and string.match(slot, "^m%d$") then
			local k = tonumber(string.sub(slot, 2)) :: number
			if k < 1 or k > Cfg.slotsOf(st.lv.Slots or 1) then return end
			if id and roleOf(inv[id]) ~= "miner" then return end
			local m = s.m
			if id then
				if k <= #m then m[k] = id else table.insert(m, id) end
			elseif k <= #m then
				table.remove(m, k)
			end
		end
		refresh(st)
	end
end

local lastTick = 0
local function step()
	local t = now()
	local dt = t - lastTick
	if dt < 0.1 then return end
	lastTick = t
	dt = math.min(dt, 0.5)
	for _, st in states do
		local n = unlockedCount(st)
		local interval = Cfg.spawnOf(st.lv.Spawn or 1)
		local char = st.player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		for i, pl in st.plots do
			if i <= n then
				-- спавн руди: нова руда росте на очах interval с (картка Ore Spawn); наступна починає рости, коли попередня
				-- доросла — темп той самий, що раніше; руди вже максимум (Ore Limit) або немає місця — чекаємо
				local growing = false
				for _, o in pl.ores do if not o.dead and o.readyAt > t then growing = true; break end end
				if not growing and #pl.ores < Cfg.pointsOf(st.lv.Points or 1) then spawnOre(pl, math.max(interval, 0.25)) end
				for _, g in pl.golems do
					if g.role == "carrier" then tickCarrier(st, pl, g, t) else tickMiner(st, pl, g, t) end
				end
				pickup(st, pl, hrp)
			end
		end
	end
end

-- Workspace/PlotPrefabs — префаби для правки в Studio (поза картою, в ряд): на старті сервера кожна модель з атрибутом
-- PrefabOf замінює однойменний шаблон у PlotAssets (тож правки в Workspace одразу діють у грі), а сама папка прибирається
-- з карти. Правити треба саме їх, а не PlotAssets: при запуску копії з Workspace перекривають шаблони.
local function syncPrefabs()
	local stage = workspace:FindFirstChild("PlotPrefabs")
	if not stage then return end
	for _, m in stage:GetDescendants() do
		local key = m:IsA("Model") and m:GetAttribute("PrefabOf")
		if type(key) == "string" and key ~= "" then
			local c = m:Clone()
			c.Name = key
			c:SetAttribute("PrefabOf", nil)
			local old = ASSETS:FindFirstChild(key)
			if old then old:Destroy() end
			c.Parent = ASSETS
		end
	end
	stage:Destroy()
end

function PlotService.Start()
	syncPrefabs()
	DataService.RegisterSection("Plots", sectionOf)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("PlotAction") or Instance.new("RemoteEvent")
	ev.Name = "PlotAction"; ev.Parent = remotes
	ev.OnServerEvent:Connect(onAction)

	NicheService.Claimed.Event:Connect(function(p: Player, niche: Model) task.spawn(setup, p, niche) end)
	NicheService.Released.Event:Connect(function(p: Player) teardown(p) end)
	DataService.StageReset.Event:Connect(function(p: Player)
		local st = states[p]
		if not st then return end
		st.lv = Cfg.defaultLevels()
		table.clear(st.assign)
		for _, pl in st.plots do table.clear(pl.bin); pl.binN = 0 end
		refresh(st)
	end)
	-- інвентар змінився (новий голем / видалення) → перевірити плоти
	local function watch(p: Player)
		p:GetAttributeChangedSignal("InvGolems"):Connect(function()
			local st = states[p]
			if st then task.defer(refresh, st) end
		end)
		p:GetAttributeChangedSignal("AutoEquipBest"):Connect(function()
			local st = states[p]
			if st then refresh(st) end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
		local n = NicheService.GetNiche(p)
		if n and not states[p] then task.spawn(setup, p, n) end
	end
	RunService.Heartbeat:Connect(step)
end

return PlotService
