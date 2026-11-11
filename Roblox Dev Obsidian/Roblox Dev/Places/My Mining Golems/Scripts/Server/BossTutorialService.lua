--!strict
-- BossTutorialService — навчання «бос» v2 (10.11.2026). Де: ServerScriptService/BossTutorialService (Script).
-- Не залежить від таймера боса (15 хв): своя арена й свій бос для кожного гравця.
-- Хто: пройшов основне навчання ДО КІНЦЯ (TutorialService ставить BossTutWant = true; пропустив — не ставить, і цього навчання немає),
--   ще не бачив цього (BossTutDone ~= true). Обидва атрибути зберігає DataService.
-- Коли: через DELAY (120) с після кінця основного навчання (або після входу в гру, якщо навчання було в минулій сесії).
-- Атрибут гравця BossTut (не зберігається) — крок для клієнта (TutorialClient, «бос-режим»):
--   "roll"  — вибрати Warrior на картці біля важеля й смикнути важіль (TutRig = true: RollService дає безкоштовного Wooden;
--             10.11.2026: TutRig тримається весь час до арени — будь-який рол у навчанні дає лише Wooden);
--   "buy"   — забрати воїна з підставки;
--   "join"  — кнопка JOIN біля NEXT BOSS (MainHUD/Btn_BossJoin) — у цьому кроці видна завжди, незалежно від реєстрації;
--             Remotes/BossAction "TutJoin" → телепорт на навчальну арену;
--   "fight" — на арені: бос BOSS_HP (10) HP; як у справжньому бою — гравець біля боса (≤ ENGAGE_R) — воїни б'ють,
--             відійшов — воїни йдуть за ним; удари боса слабкі (DMG_MULT) і не вбивають;
--   "dodge" — 10.11.2026: урок ухилення на першій атаці боса: удар повільний (DODGE_WARN с — «сповільнення часу» на клієнті),
--             рука показує точку TB_Safe подалі від боса — гравець відходить, воїн іде за ним із червоної зони.
--             Ухилився — "back" (рука на TB_Back біля боса, повернутись) → "fight"; не встиг — урок ще раз (до DODGE_TRIES);
--   "claim" — бос переміг: вікно VICTORY! (BossArenaClient) з нагородою REWARD_TEETH Fossil Teeth + REWARD_DIA діамантів
--             (10.11.2026; видається в мить перемоги) — рука на CLAIM → BossAction "Home" → додому.
--   Кнопка SKIP (TutorialClient) — лише в "roll" / "buy" / "join": BossAction "TutSkip". На арені пропустити не можна (EXIT схований).
-- Навчальна арена: клон ServerStorage/BossArenas/<arena> → Workspace/BossTutArena_<UserId>, зсунутий на SLOT_STEP·k по Z (k — вільний слот);
--   бос — клон ServerStorage/BossModels/Gobking. Атрибути бою — у гравця (TB_BossHP, TB_BossMaxHP, TB_BossPhase, TB_BossPhaseEnd,
--   TB_BossName, TB_BossFloorY, TB_BossDamage) і BossTutArena = ім'я арени; BossArenaClient читає їх замість Workspace.*.
--   Події — ті самі Remotes (BossFx, BossTick, BossResult), лише цьому гравцю. InBossArena = true, як на звичайній арені.
--   "shop"  — 10.11.2026: після CLAIM, удома — стрілки на підлозі ведуть до Boss Shop (Workspace/Cave/Hub/Shops/EventShop,
--             магазин за Fossil Teeth); позиція — атрибут гравця BossShopPos. Відкрив вікно BOSS SHOP (клієнт: BossAction
--             "TutShopSeen"), дійшов (SHOP_R) або SHOP_MAX с — кінець, стрілки зникають.
-- Кілька гравців одночасно — у кожного своя арена (слот k, зсув SLOT_STEP·k), свій бос і свої події; одне одному не заважають.
-- Кінець: CLAIM / 60 с після перемоги / вийшов з арени — BossTutDone = true. Нагорода — лише за перемогу (10 зубів + 25 діамантів).
-- Funnels (Creator Hub → Analytics → Funnels): BossTutorial — 1 Started · 2 Rolled warrior · 3 Got warrior · 4 Joined arena ·
--   5 Boss defeated · 6 Returned home. Пропуск — Custom event BossTutorialSkipped (значення — крок, на якому пропустив).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")

local Shared = RS:WaitForChild("Shared")
local okH, Hub = pcall(require, Shared:WaitForChild("HubConfig"))
if okH and Hub and Hub.isMarket and Hub.isMarket() then return end -- на маркеті боса немає

local DataService = require(script.Parent:WaitForChild("DataService"))
local Cfg = require(Shared:WaitForChild("BossConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))

local DELAY = 120       -- с після основного навчання
if game:GetService("RunService"):IsStudio() then DELAY = 10 end -- тест у Studio — не чекати 2 хв
local BOSS_HP = 10      -- HP навчального боса (б'ємо одним безкоштовним воїном); 10.11.2026: 25 → 10
local DMG_MULT = 0.3    -- удари боса в навчанні слабші; HP голема не падає нижче 1
local FIGHT_MAX = 240   -- запобіжник: довше — бос падає сам
local CLAIM_MAX = 60    -- не натиснув CLAIM — додому сам
local SLOT_STEP = 800   -- зсув навчальних арен по Z (арена ~630 стад)
local REWARD_TEETH = 10  -- 10.11.2026: нагорода за навчального боса — Fossil Teeth (було 5)
local REWARD_DIA = 25     -- і діаманти
local DODGE_WARN = 6      -- урок ухилення: стільки секунд до удару (повільна атака)
local DODGE_TRIES = 3     -- скільки разів повторити урок, якщо не встиг
local LESSON_HP = 3       -- до кінця уроку ухилення HP боса не нижче цього
local FUNNEL = "BossTutorial"
local STEPS = { "Started", "Rolled warrior", "Got warrior", "Joined arena", "Boss defeated", "Returned home", "Opened boss shop" }
local SHOP_R = 16         -- 10.11.2026: так близько до Boss Shop — дійшов
local SHOP_MAX = 150      -- стільки секунд ведемо до магазину, далі — кінець
local TB = { "BossFloorY", "BossName", "BossMaxHP", "BossHP", "BossDamage", "BossPhase", "BossPhaseEnd" }

local function decode(p: Player, attr: string): any
	local raw = p:GetAttribute(attr)
	if type(raw) ~= "string" or raw == "" then return nil end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, raw)
	return ok and v or nil
end
local function now(): number return workspace:GetServerTimeNow() end

-- воїни в інвентарі, не поставлені на плот
local function warriors(p: Player): { any }
	local inv = decode(p, "InvGolems")
	local placed = decode(p, "PlotPlaced")
	local out = {}
	if type(inv) ~= "table" then return out end
	for _, g in inv do
		if type(g) == "table" and Catalog.cls(g.cls) == "warrior" and Catalog.get(g.kind)
			and not (type(placed) == "table" and table.find(placed, g.id)) then
			table.insert(out, g)
		end
	end
	return out
end
local function pendingWarrior(p: Player): boolean
	local pend = decode(p, "RollPending")
	if type(pend) ~= "table" then return false end
	for _, r in pend do
		if type(r) == "table" and Catalog.cls(r.cls) == "warrior" then return true end
	end
	return false
end
local function inLobby(p: Player): boolean
	local ok, list = pcall(HttpService.JSONDecode, HttpService, workspace:GetAttribute("BossLobby") or "[]")
	if not ok or type(list) ~= "table" then return false end
	for _, e in list do if type(e) == "table" and e.u == p.UserId then return true end end
	return false
end
-- як AUTO у вікні реєстрації: найсильніші воїни у відкриті слоти — лише якщо в слотах немає жодного з наявних воїнів
local function autoPick(p: Player)
	local list = warriors(p)
	if #list == 0 then return end
	local have = {}
	for _, g in list do have[g.id] = true end
	local picks = decode(p, "BossPicks")
	if type(picks) == "table" then
		for _, id in picks do if have[id] then return end end
	end
	table.sort(list, function(a, b) return Catalog.power(a.kind, "warrior", a.mut, p) > Catalog.power(b.kind, "warrior", b.mut, p) end)
	local out, k = {}, 0
	for i = 1, Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS do
		if Cfg.slotOpen(p, i) and list[k + 1] then k += 1; out[i] = list[k].id else out[i] = 0 end
	end
	p:SetAttribute("BossPicks", HttpService:JSONEncode(out))
end
-- вибрані бійці (як BossFightService.validPicks)
local function validPicks(p: Player): { any }
	local byId = {}
	for _, g in warriors(p) do byId[g.id] = g end
	local out, seen = {}, {}
	local picks = decode(p, "BossPicks")
	for i, id in (type(picks) == "table" and picks or {}) do
		if not Cfg.slotOpen(p, i) then continue end
		local g = type(id) == "number" and byId[id] or nil
		if g and not seen[id] then seen[id] = true; table.insert(out, g) end
	end
	return out
end

-- ===== Funnels =====
local logged: { [Player]: { [number]: boolean } } = {}
local lastStep: { [Player]: number } = {}
local function step(p: Player, n: number)
	logged[p] = logged[p] or {}
	lastStep[p] = math.max(lastStep[p] or 0, n)
	if logged[p][n] then return end
	logged[p][n] = true
	pcall(function() AnalyticsService:LogFunnelStepEvent(p, FUNNEL, tostring(p.UserId), n, STEPS[n]) end)
end

-- ===== стан =====
type G = { key: string, id: number, kind: string, mut: number, hp: number, max: number, dmg: number, interval: number,
	move: number, pos: Vector3, yaw: number, nextAtk: number, st: string, ringA: number }
type T = { p: Player, k: number, arena: Instance, center: Vector3, floorY: number, golems: { G }, hp: number, dmg: number,
	phase: string, home: boolean, conn: RBXScriptConnection?, lesson: number, tries: number }
local loaded: { [Player]: boolean } = {}
local due: { [Player]: number } = {}
local active: { [Player]: boolean } = {}
local arenas: { [Player]: T } = {}
local slots: { [number]: Player } = {}
local remotes: Folder? = nil
local shopUntil: { [Player]: number } = {}
local function bossShop(): Model?
	local hub = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Hub")
	local shops = hub and hub:FindFirstChild("Shops")
	local m = shops and shops:FindFirstChild("EventShop")
	return (m and m:IsA("Model")) and m or nil
end

local function finish(p: Player, skipped: boolean)
	active[p] = nil
	due[p] = nil
	if skipped then
		local at = lastStep[p] or 1
		pcall(function() AnalyticsService:LogCustomEvent(p, "BossTutorialSkipped", at) end)
	end
	p:SetAttribute("BossTut", nil)
	if p:GetAttribute("TutStep") == nil then p:SetAttribute("TutRig", nil) end
	p:SetAttribute("BossTutDone", true)
	task.spawn(function() pcall(DataService.SaveNow, p) end)
end

-- ===== навчальна арена =====
local H = Cfg.BOSSES.goblin.half
local function shift(inst: Instance, off: Vector3)
	for _, c in inst:GetChildren() do
		if c:IsA("Model") then
			c:PivotTo(c:GetPivot() + off)
		elseif c:IsA("BasePart") then
			c.CFrame += off
			shift(c, off)
		else
			shift(c, off)
		end
	end
end
local function bossDist(T: T, pos: Vector3): number
	local dx = math.max(0, math.abs(pos.X - T.center.X) - H.X)
	local dz = math.max(0, math.abs(pos.Z - T.center.Z) - H.Z)
	return math.sqrt(dx * dx + dz * dz)
end
-- точка на «кільці» навколо хітбоксу (бос дивиться в −Z, не повертається) під кутом a (як atan2(dx, dz))
local function ringPoint(T: T, a: number): Vector3
	local d = Vector3.new(math.sin(a), 0, math.cos(a))
	local mg = 2.2
	local t = math.min((H.X + mg) / math.max(math.abs(d.X), 1e-3), (H.Z + mg) / math.max(math.abs(d.Z), 1e-3))
	return Vector3.new(T.center.X, T.floorY, T.center.Z) + d * t
end
local function clearArena(T: T)
	local p = T.p
	if T.conn then T.conn:Disconnect(); T.conn = nil end
	if arenas[p] == T then arenas[p] = nil end
	if slots[T.k] == p then slots[T.k] = nil end
	if p.Parent == Players then
		for _, n in TB do p:SetAttribute("TB_" .. n, nil) end
		p:SetAttribute("TB_Safe", nil); p:SetAttribute("TB_Back", nil)
		p:SetAttribute("BossTutArena", nil)
	end
	local a = T.arena
	task.delay(1, function() a:Destroy() end)
end
-- додому (CLAIM, таймаут, вийшов з арени)
local function goHome(T: T, claimed: boolean)
	if T.home then return end
	T.home = true
	local p = T.p
	local won = T.phase == "results"
	T.phase = "done"
	if p.Parent == Players then
		if won then step(p, 6) end
		if p:GetAttribute("InBossArena") == true then
			local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
			-- 10.11.2026: спершу підвантажити дім повністю (арена далеко — інакше після телепорту світ «порожній» / недовантажений)
			local niche = okN and NS and NS.GetNiche and NS.GetNiche(p)
			if niche then pcall(function() p:RequestStreamAroundAsync(niche:GetPivot().Position) end) end
			p:SetAttribute("InBossArena", nil)
			if okN and NS and NS.TeleportHome then pcall(NS.TeleportHome, p) end
		end
		local shop = won and bossShop() or nil
		if shop and p.Parent == Players then
			-- 10.11.2026: отримав зуби — стрілки до Boss Shop
			p:SetAttribute("BossTutDone", true)
			task.spawn(function() pcall(DataService.SaveNow, p) end)
			p:SetAttribute("BossShopPos", shop:GetPivot().Position)
			shopUntil[p] = os.clock() + SHOP_MAX
			p:SetAttribute("BossTut", "shop")
		else
			finish(p, false)
		end
	end
	clearArena(T)
end

local function fightLoop(T: T)
	local p = T.p
	local rem = remotes :: Folder
	local evFx = rem:FindFirstChild("BossFx") :: RemoteEvent
	local evTick = rem:FindFirstChild("BossTick") :: RemoteEvent
	local evRes = rem:FindFirstChild("BossResult") :: RemoteEvent
	local _, def = Cfg.current()
	local t0 = now()
	local nextAtk = t0 + 4
	local seqI, atkId = 0, 0
	local lastSend, lastDmg = 0, 0
	while T.phase == "fight" and p.Parent == Players and arenas[p] == T do
		task.wait(0.1)
		if T.phase ~= "fight" then return end
		local t = now()
		if t - t0 > FIGHT_MAX then T.hp = 0 end
		-- 10.11.2026: як у BossFightService — гравець біля боса (≤ ENGAGE_R): воїни на кільце й б'ють; далі — йдуть за гравцем
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local base = hrp and Vector3.new(hrp.Position.X, T.floorY, hrp.Position.Z) or nil
		local engage = base ~= nil and bossDist(T, base :: Vector3) <= Cfg.ENGAGE_R
		local ang0 = 0
		if hrp then local lv = (hrp :: BasePart).CFrame.LookVector; ang0 = math.atan2(lv.X, lv.Z) end
		if p:GetAttribute("BossTut") == "back" and engage then p:SetAttribute("BossTut", "fight") end
		local hits = {}
		for gi, g in T.golems do
			local target
			if engage or not base then
				target = ringPoint(T, g.ringA)
			else
				local n = #T.golems
				local a = ang0 + math.pi + (gi - (n + 1) / 2) * 0.75
				target = (base :: Vector3) + Vector3.new(math.sin(a), 0, math.cos(a)) * Cfg.FOLLOW_R * (n > 1 and 1 or 0.7)
			end
			local d = target - g.pos
			d = Vector3.new(d.X, 0, d.Z)
			local moving = d.Magnitude > 0.6
			if moving then g.pos += d.Unit * math.min(g.move * 0.1, d.Magnitude) end
			if engage and bossDist(T, g.pos) <= Cfg.ATTACK_RANGE and T.hp > 0 then
				local to = Vector3.new(T.center.X - g.pos.X, 0, T.center.Z - g.pos.Z)
				if to.Magnitude > 0.1 then g.yaw = math.atan2(-to.X, -to.Z) end
				g.st = (moving and d.Magnitude > 1.5) and "Walk" or "Mine"
				if t >= g.nextAtk then
					g.nextAtk = t + g.interval
					-- 10.11.2026: поки урок ухилення не пройдено, бос не падає (лишається LESSON_HP)
					local before = T.hp
					T.hp = math.max(if T.lesson < 2 then math.min(T.hp, LESSON_HP) else 0, T.hp - g.dmg)
					T.dmg += before - T.hp -- у DAMAGE — лише справжня шкода (не більше HP боса)
					table.insert(hits, { g.key, math.floor(g.dmg + 0.5) })
				end
			else
				if moving then g.yaw = math.atan2(-d.X, -d.Z) end
				g.st = moving and "Walk" or "Idle"
			end
		end
		if #hits > 0 then evFx:FireClient(p, "dmg", hits) end
		p:SetAttribute("TB_BossHP", math.floor(T.hp + 0.5))
		if t - lastDmg > 0.4 then
			lastDmg = t
			p:SetAttribute("TB_BossDamage", HttpService:JSONEncode({ [tostring(p.UserId)] = math.floor(T.dmg) }))
		end
		if t - lastSend >= Cfg.SEND_EVERY then
			lastSend = t
			local pk = {}
			for _, g in T.golems do
				table.insert(pk, { g.key, math.floor(g.pos.X * 10) / 10, math.floor(g.pos.Z * 10) / 10, math.floor(g.yaw * 100) / 100,
					math.floor(g.hp), g.st == "Mine" and 2 or (g.st == "Walk" and 1 or 0) })
			end
			evTick:FireClient(p, pk)
		end
		-- атаки боса: по черзі Slam / Sweep (права, ліва); слабкі
		if t >= nextAtk and T.hp > 0 and p:GetAttribute("BossTut") ~= "back" then
			-- 10.11.2026: урок ухилення — перша атака (Slam перед босом, де стоять воїни) повільна; поки урок не пройдено — лише вона
			local lessonNow = T.lesson == 0 and engage
			if not lessonNow then seqI += 1 end
			local key = if lessonNow then "Slam" elseif (seqI % 2 == 1) then "Slam" else "Sweep"
			local side = key == "Sweep" and ((seqI % 4 == 2) and 1 or -1) or 0
			local atk = def.attacks[1]
			for _, a in def.attacks do if a.key == key then atk = a; break end end
			local warnT = if lessonNow then DODGE_WARN else atk.warn
			if lessonNow then
				T.lesson = 1
				T.tries += 1
				local c0 = T.center
				p:SetAttribute("TB_Safe", Vector3.new(c0.X, T.floorY, c0.Z - (H.Z + 40))) -- за межею ENGAGE_R, позаду від гравця
				p:SetAttribute("TB_Back", Vector3.new(c0.X, T.floorY, c0.Z - (H.Z + 18)))
				p:SetAttribute("BossTut", "dodge")
			end
			local c = T.center
			local rects
			if key == "Slam" then
				rects = { { cx = c.X, cz = c.Z - (H.Z + 10), w = 30, d = 20, yaw = 0 } }
			else
				rects = { { cx = c.X + side * (H.X + 9), cz = c.Z - 4.5, w = 18, d = 44, yaw = 0 } }
			end
			atkId += 1
			local id = atkId
			evFx:FireClient(p, "warn", id, key, rects, warnT)
			evFx:FireClient(p, "boss", "attack", key, warnT, side)
			nextAtk = t + warnT + 5
			task.delay(warnT, function()
				if T.phase ~= "fight" or p.Parent ~= Players then return end
				local hit = {}
				for _, g in T.golems do
					for _, r in rects do
						local lx, lz = g.pos.X - r.cx, g.pos.Z - r.cz
						if math.abs(lx) <= r.w / 2 + 1 and math.abs(lz) <= r.d / 2 + 1 then
							g.hp = math.max(1, g.hp - g.max * atk.pct * Cfg.hitMult(g.max) * DMG_MULT)
							table.insert(hit, g.key)
							break
						end
					end
				end
				evFx:FireClient(p, "hit", id, hit)
				if lessonNow then
					if #hit == 0 or T.tries >= DODGE_TRIES then
						-- ухилився (або вже досить спроб) — повертаємось до боса
						T.lesson = 2
						p:SetAttribute("BossTut", "back")
						if #hit == 0 then pcall(function() AnalyticsService:LogCustomEvent(p, "BossTutorialDodged", T.tries) end) end
					else
						T.lesson = 0 -- не встиг — урок ще раз на наступній атаці
						p:SetAttribute("BossTut", "fight")
					end
					nextAtk = now() + 2.5
				end
			end)
		end
		-- перемога
		if T.hp <= 0 then
			T.phase = "results"
			p:SetAttribute("TB_BossHP", 0)
			p:SetAttribute("TB_BossDamage", HttpService:JSONEncode({ [tostring(p.UserId)] = math.floor(T.dmg) }))
			p:SetAttribute("TB_BossPhaseEnd", now() + CLAIM_MAX)
			p:SetAttribute("TB_BossPhase", "results")
			evFx:FireClient(p, "boss", "die")
			step(p, 5)
			p:SetAttribute("FossilTeeth", (tonumber(p:GetAttribute("FossilTeeth")) or 0) + REWARD_TEETH)
			p:SetAttribute("Diamonds", (tonumber(p:GetAttribute("Diamonds")) or 0) + REWARD_DIA)
			task.spawn(function() pcall(DataService.SaveNow, p) end)
			evRes:FireClient(p, { win = true, place = 1, dmg = math.floor(T.dmg), share = 1, teeth = REWARD_TEETH, dia = REWARD_DIA, n = 1, why = "win", tut = true })
			p:SetAttribute("BossTut", "claim")
			task.delay(CLAIM_MAX + 12, function() if arenas[p] == T then goHome(T, false) end end)
			return
		end
	end
end

local function startArena(p: Player)
	if arenas[p] or not active[p] or p:GetAttribute("BossTut") ~= "join" then return end
	if p:GetAttribute("InBossArena") == true or inLobby(p) then return end
	autoPick(p)
	local picks = validPicks(p)
	if #picks == 0 then return end
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (char and hrp and hum and hum.Health > 0) then return end
	local _, def = Cfg.current()
	local store = SS:FindFirstChild("BossArenas")
	local src = store and store:FindFirstChild(def.arena)
	if not src then warn("BossTutorialService: no arena " .. tostring(def.arena)); return end
	local k = 1
	while slots[k] do k += 1 end
	slots[k] = p
	local arena = src:Clone()
	arena.Name = "BossTutArena_" .. p.UserId
	shift(arena, Vector3.new(0, 0, -SLOT_STEP * k))
	arena.Parent = workspace
	local sp = arena:FindFirstChild("ArenaSpawn") :: BasePart?
	if not (sp and sp:IsA("BasePart")) then slots[k] = nil; arena:Destroy(); return end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { arena }
	local r = workspace:Raycast(sp.Position + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rp)
	local fy = r and r.Position.Y or sp.Position.Y
	local T: T = { p = p, k = k, arena = arena, center = Vector3.new(sp.Position.X, fy, sp.Position.Z), floorY = fy, golems = {},
		hp = BOSS_HP, dmg = 0, phase = "fight", home = false, lesson = 0, tries = 0 }
	arenas[p] = T
	-- бос (як BossFightService.buildBoss), стоїть у центрі, дивиться в −Z
	local bstore = SS:FindFirstChild("BossModels")
	local pre = bstore and bstore:FindFirstChild("Gobking")
	local m: Model = (pre and pre:IsA("Model")) and pre:Clone() or require(script.Parent:WaitForChild("BossModelBuilder")).build()
	m.Name = "Boss"
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.PrimaryPart = m:FindFirstChild("Hitbox") :: BasePart
	m:PivotTo(CFrame.new(T.center.X, fy + H.Y, T.center.Z))
	m:SetAttribute("BuildCF", (m.PrimaryPart :: BasePart).CFrame)
	m.Parent = arena
	-- атрибути бою (BossArenaClient читає TB_*, коли є BossTutArena)
	p:SetAttribute("TB_BossFloorY", fy)
	p:SetAttribute("TB_BossName", def.name)
	p:SetAttribute("TB_BossMaxHP", BOSS_HP)
	p:SetAttribute("TB_BossHP", BOSS_HP)
	p:SetAttribute("TB_BossDamage", HttpService:JSONEncode({ [tostring(p.UserId)] = 0 }))
	p:SetAttribute("TB_BossPhaseEnd", now() + FIGHT_MAX)
	p:SetAttribute("TB_BossPhase", "fight")
	p:SetAttribute("BossTutArena", arena.Name)
	-- гравець — перед босом, у межах ENGAGE_R
	local pos = Vector3.new(T.center.X, fy + 3.5, T.center.Z - (H.Z + 22))
	local spot = CFrame.lookAt(pos, Vector3.new(T.center.X, pos.Y, T.center.Z))
	pcall(function() p:RequestStreamAroundAsync(spot.Position) end)
	if p.Parent ~= Players or p.Character ~= char or arenas[p] ~= T then clearArena(T); return end
	char:PivotTo(spot + Vector3.new(0, hum.HipHeight, 0))
	;(hrp :: BasePart).AssemblyLinearVelocity = Vector3.zero
	p:SetAttribute("InBossArena", true)
	if p:GetAttribute("TutStep") == nil then p:SetAttribute("TutRig", nil) end -- на арені — звичайні роли знову
	p:SetAttribute("BossTut", "fight")
	step(p, 4)
	-- воїни
	local list = {}
	for i, g in picks do
		local st = Catalog.stats(g.kind, "warrior", g.mut, p)
		local hp = math.max(10, st.hp or 10)
		local gg: G = { key = tostring(p.UserId) .. ":" .. tostring(g.id), id = g.id, kind = Catalog.id(g.kind) or g.kind, mut = Catalog.mut(g.mut),
			hp = hp, max = hp, dmg = Cfg.golemDmg(st.dmg or 1), interval = math.max(0.5, st.interval or 1.4),
			move = math.clamp(st.move or 8, Cfg.MIN_MOVE, Cfg.MAX_MOVE),
			pos = Vector3.new(pos.X + (i - (#picks + 1) / 2) * 3, fy, pos.Z + 3), yaw = 0, nextAtk = 0, st = "Idle",
			ringA = math.pi + (i - (#picks + 1) / 2) * 0.45 }
		table.insert(T.golems, gg)
		table.insert(list, { key = gg.key, u = p.UserId, n = p.DisplayName, k = gg.kind, m = gg.mut, max = gg.max, iv = gg.interval })
	end
	-- вийшов з арени (смерть, новий персонаж) — навчання скінчено
	T.conn = p:GetAttributeChangedSignal("InBossArena"):Connect(function()
		if p:GetAttribute("InBossArena") ~= true and not T.home then goHome(T, false) end
	end)
	task.wait(0.5)
	if T.phase ~= "fight" then return end
	local evFx = (remotes :: Folder):FindFirstChild("BossFx") :: RemoteEvent
	evFx:FireClient(p, "spawn", list)
	task.spawn(fightLoop, T)
end

-- ===== кроки до арени =====
local function tick(p: Player)
	if not loaded[p] or arenas[p] then return end
	if p:GetAttribute("BossTut") == "shop" then
		local shop = bossShop()
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local near = shop and hrp and Vector3.new(hrp.Position.X - shop:GetPivot().Position.X, 0, hrp.Position.Z - shop:GetPivot().Position.Z).Magnitude <= SHOP_R
		if near then step(p, 7) end
		if near or not shop or os.clock() > (shopUntil[p] or 0) then
			shopUntil[p] = nil
			p:SetAttribute("BossShopPos", nil)
			finish(p, false)
		end
		return
	end
	if p:GetAttribute("BossTutDone") == true or p:GetAttribute("BossTutWant") ~= true then due[p] = nil; return end
	if not active[p] then
		if p:GetAttribute("TutorialDone") ~= true or p:GetAttribute("TutStep") ~= nil then due[p] = nil; return end
		if not due[p] then due[p] = os.clock() + DELAY; return end
		if os.clock() < (due[p] :: number) or p:GetAttribute("InBossArena") == true or inLobby(p) then return end
		active[p] = true
		step(p, 1)
		if #warriors(p) > 0 then autoPick(p); p:SetAttribute("BossTut", "join") else p:SetAttribute("BossTut", "roll") end
		return
	end
	local cur = p:GetAttribute("BossTut")
	-- 10.11.2026: увесь час до арени (roll / buy / join) кожен рол дає лише безкоштовного Wooden (TutRig), навіть якщо ролить ще раз
	if (cur == "roll" or cur == "buy" or cur == "join") and p:GetAttribute("TutRig") ~= true then p:SetAttribute("TutRig", true) end
	if cur == "roll" then
		if #warriors(p) > 0 then
			step(p, 2); step(p, 3); autoPick(p); p:SetAttribute("BossTut", "join")
		elseif pendingWarrior(p) then
			step(p, 2); p:SetAttribute("BossTut", "buy")
		end
	elseif cur == "buy" then
		if #warriors(p) > 0 then
			step(p, 3); autoPick(p); p:SetAttribute("BossTut", "join")
		elseif not pendingWarrior(p) then
			p:SetAttribute("BossTut", "roll") -- результат зник (наприклад, рол заново) — знову рол
		end
	elseif cur == "join" then
		if #warriors(p) == 0 then p:SetAttribute("BossTut", "roll") else autoPick(p) end
	elseif cur == nil then
		active[p] = nil -- атрибут зняли ззовні — почнемо знову
	end
end

local function onAction(p: Player, action: any)
	if action == "TutJoin" then
		if active[p] and not arenas[p] then
			local ok, err = pcall(startArena, p)
			if not ok then
				warn("BossTutorialService: " .. tostring(err))
				local T = arenas[p]
				if T then clearArena(T) end
			end
		end
	elseif action == "TutSkip" then
		local cur = p:GetAttribute("BossTut")
		if active[p] and not arenas[p] and (cur == "roll" or cur == "buy" or cur == "join") then finish(p, true) end
	elseif action == "Home" then
		local T = arenas[p]
		if T and T.phase == "results" then goHome(T, true) end
	elseif action == "TutShopSeen" then
		-- 10.11.2026: відкрив вікно BOSS SHOP — показали, де магазин; стрілки прибираємо
		if p:GetAttribute("BossTut") == "shop" then
			step(p, 7)
			shopUntil[p] = nil
			p:SetAttribute("BossShopPos", nil)
			finish(p, false)
		end
	end
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) or p.Parent ~= Players then return end
	loaded[p] = true
end
Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(p)
	local T = arenas[p]
	if T then T.home = true; T.phase = "done"; clearArena(T) end
	active[p] = nil; loaded[p] = nil; logged[p] = nil; due[p] = nil; lastStep[p] = nil; shopUntil[p] = nil
end)

task.spawn(function()
	local rem = RS:WaitForChild("Remotes")
	rem:WaitForChild("BossFx"); rem:WaitForChild("BossTick"); rem:WaitForChild("BossResult")
	remotes = rem :: Folder
	;(rem:WaitForChild("BossAction") :: RemoteEvent).OnServerEvent:Connect(function(p: Player, action: any)
		local ok, err = pcall(onAction, p, action)
		if not ok then warn("BossTutorialService: " .. tostring(err)) end
	end)
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in Players:GetPlayers() do
			local ok, err = pcall(tick, p)
			if not ok then warn("BossTutorialService: " .. tostring(err)) end
		end
	end
end)
