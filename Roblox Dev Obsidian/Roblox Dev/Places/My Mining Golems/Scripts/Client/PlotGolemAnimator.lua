--!strict
-- PlotGolem animator (копія StoneGolem animator v2 + LOD, Carry, синхронний Mine для плотів).
-- 27.10.2026: предмети в руці (Pickaxe / Sword) — окремі префаби, їдуть за кулаком (атрибут FistRel), блоки group з GolemData пропускаються.
-- StoneGolem animator v2 (клієнтський). Кліпи Idle / Walk / Run / Face (порт з golem_rig.py) + Mine (удар кіркою).
-- Керування атрибутами моделі:
--   State  = "Auto" | "Idle" | "Walk" | "Run" | "Mine"   (Auto — за швидкістю руху Root)
--   Mine: голем б'є кіркою; у момент удару ставить на модель з ObjectValue "MineTarget" атрибути HitPoint (кінчик леза) і HitTime = os.clock()
--   Face   = true/false   (кліпання/брови поверх будь-якого кліпу)
--   AnimSpeed = 1         (множник швидкості відтворення)
--   WalkSpeedThreshold / RunSpeedThreshold — пороги для Auto (стадів/с)
local RunService = game:GetService("RunService")
local model = script.Parent :: Model
local root = model:WaitForChild("Root") :: BasePart
local D = require(model:WaitForChild("GolemData")) :: any
-- [Plot] Carry: ящичок (локальна копія CarryBox, кладе PlotClient) тримається між кулаками
local BOX_DROP = 0.75 -- стадів: центр ящичка трохи нижче центру кулаків (кулаки тримають верхню половину)

local FLIP = CFrame.Angles(0, math.pi, 0) -- у моделі обличчя в +Z, у Roblox «вперед» це -Z
local UNIT = 0.5                          -- 1 од. моделі = 0,5 стада

-- ---------- скелет ----------
type Bone = { name: string, parent: string?, pos: Vector3, idx: number, parentIdx: number?, rest: Vector3 }
local bones: { Bone } = {}
local boneByName: { [string]: Bone } = {}
for i, b in D.bones do
	local bone: Bone = { name = b.name, parent = b.parent, pos = b.pos, idx = i, parentIdx = nil, rest = b.pos }
	bones[i] = bone
	boneByName[b.name] = bone
end
for _, bone in bones do
	if bone.parent then
		local p = boneByName[bone.parent]
		bone.parentIdx = p.idx
		bone.rest = bone.pos - p.pos
	end
end

type Blk = { part: BasePart, bone: number, offset: Vector3, rot: CFrame, size: Vector3, scaled: boolean }
local blocks: { Blk } = {}
local parts: { BasePart } = {}
local FACE_SCALED = { Eye_R = true, Eye_L = true, Pupil_R = true, Pupil_L = true }
for _, b in D.blocks do
	-- предмети в руці (group Pickaxe / Sword) — окремі префаби PlotAssets/<StonePickaxe…>, їх чіпляє GolemCatalog.applyClassItems
	-- (див. «предмет у руці» нижче); тут лише тіло
	if b.group then continue end
	local part = model:WaitForChild(b.name) :: BasePart
	local bone = boneByName[b.bone]
	-- блок задається або центром c + нахилом rz, або повним CFrame cf (координати моделі в стані спокою)
	local offset = if b.cf then b.cf.Position - bone.pos else b.c - bone.pos
	local rotCF = if b.cf then b.cf.Rotation else CFrame.Angles(0, 0, b.rz)
	table.insert(blocks, {
		part = part, bone = bone.idx, offset = offset,
		rot = rotCF, size = b.s, scaled = FACE_SCALED[b.bone] == true,
	})
	table.insert(parts, part)
end

-- ---------- кліпи (порт з golem_rig.py) ----------
local function rot(x: number, y: number, z: number): CFrame
	-- glTF quat(x,y,z) = qz*qy*qx
	return CFrame.Angles(0, 0, z) * CFrame.Angles(0, y, 0) * CFrame.Angles(x, 0, 0)
end
type Pose = { [string]: { t: Vector3?, r: CFrame?, s: Vector3? } }

local function poseIdle(p: number): Pose
	local s, c = math.sin(p), math.cos(p)
	return {
		Hips = { t = Vector3.new(0, -0.08 + 0.08 * c, 0) },
		Torso = { r = rot(0.03 * s, 0, 0) },
		Head = { r = rot(-0.02 * s, 0.05 * math.sin(p), 0.04 * math.sin(p + 1.2)) },
		UpperArm_R = { r = rot(0.05 * math.sin(p + 0.6), 0, 0.04 + 0.02 * s) },
		UpperArm_L = { r = rot(0.05 * math.sin(p + 0.6), 0, -0.04 - 0.02 * s) },
		Forearm_R = { r = rot(-0.12 - 0.04 * s, 0, 0) },
		Forearm_L = { r = rot(-0.12 - 0.04 * s, 0, 0) },
	}
end

local function poseGait(p: number, leg: number, knee: number, arm: number, elbow: number, bob: number, lean: number, twist: number): Pose
	local s, c = math.sin(p), math.cos(p)
	return {
		Hips = { t = Vector3.new(0, -bob * 0.5 + bob * 0.5 * math.cos(2 * p) - (if lean > 0.15 then 0.35 else 0), 0), r = rot(0, -twist * 0.5 * s, 0) },
		Torso = { r = rot(lean, twist * s, 0.04 * s) },
		Head = { r = rot(-lean * 0.6, -twist * 0.8 * s, -0.03 * s) },
		Thigh_R = { r = rot(-leg * s - lean * 0.3, 0, 0) },
		Thigh_L = { r = rot(leg * s - lean * 0.3, 0, 0) },
		Shin_R = { r = rot(knee * math.max(0, c) + 0.05, 0, 0) },
		Shin_L = { r = rot(knee * math.max(0, -c) + 0.05, 0, 0) },
		UpperArm_R = { r = rot(arm * s, 0, 0.06) },
		UpperArm_L = { r = rot(-arm * s, 0, -0.06) },
		Forearm_R = { r = rot(-elbow - 0.15 * math.max(0, -s), 0, 0) },
		Forearm_L = { r = rot(-elbow - 0.15 * math.max(0, s), 0, 0) },
	}
end

local function tri(t: number, at: number): number
	local close, open = 0.07, 0.1
	if t >= at and t < at + close then return (t - at) / close end
	if t >= at + close and t < at + close + open then return 1 - (t - at - close) / open end
	return 0
end
local function ease(t: number, a: number, b: number): number
	local x = math.clamp((t - a) / (b - a), 0, 1)
	return x * x * (3 - 2 * x)
end
local function poseFace(p: number): Pose
	local t = p / (2 * math.pi) * 4.0
	local blink = math.max(tri(t, 1.2), tri(t, 3.0), tri(t, 3.25))
	local look = 0.2 * ease(t, 1.6, 1.8) - 0.35 * ease(t, 2.4, 2.6) + 0.15 * ease(t, 3.4, 3.6)
	local hmph = ease(t, 0.3, 0.45) - ease(t, 0.8, 1.0)
	local raise = math.abs(look) * 0.6 - 0.06 * blink - 0.08 * hmph
	local out: Pose = {}
	for _, side in { { "R", 1 }, { "L", -1 } } do
		local n, sx = side[1] :: string, side[2] :: number
		out["Eye_" .. n] = { s = Vector3.new(1, 1 - 0.9 * blink, 1) }
		out["Pupil_" .. n] = { t = Vector3.new(look, -0.03 * blink, 0) }
		out["Brow_" .. n] = { t = Vector3.new(0, raise, 0), r = rot(0, 0, sx * (0.15 * hmph - 0.08 * math.abs(look))) }
	end
	return out
end

-- ---------- Mine: ключові пози (кути підібрані так, щоб лезо влучало в руду за 5 стадів) ----------
type Key = { t: number, ease: string, pose: { [string]: { r: { number }?, t: { number }? } } }
local MINE_T = 1.4
local MINE_HIT = 0.62
local READY = {
	Hips = { t = { 0, -0.10, 0 } },
	Torso = { r = { 0.12, 0.10, 0 } },
	Head = { r = { 0.12, 0, 0 } },
	UpperArm_L = { r = { -0.60, 0, -0.15 } },
	Forearm_L = { r = { -0.50, 0, 0 } },
	UpperArm_R = { r = { 0.05, 0, 0.08 } },
	Forearm_R = { r = { -0.25, 0, 0 } },
	Thigh_R = { r = { -0.08, 0, 0 } }, Thigh_L = { r = { -0.08, 0, 0 } },
	Shin_R = { r = { 0.12, 0, 0 } }, Shin_L = { r = { 0.12, 0, 0 } },
}
local WINDUP = {
	Hips = { t = { 0, 0, 0 } },
	Torso = { r = { -0.12, -0.18, 0 } },
	Head = { r = { -0.15, 0.05, 0 } },
	UpperArm_L = { r = { -2.70, 0, -0.20 } },
	Forearm_L = { r = { -0.70, 0, 0 } },
	UpperArm_R = { r = { -0.25, 0, 0.18 } },
	Forearm_R = { r = { -0.35, 0, 0 } },
	Thigh_R = { r = { -0.04, 0, 0 } }, Thigh_L = { r = { -0.04, 0, 0 } },
	Shin_R = { r = { 0.06, 0, 0 } }, Shin_L = { r = { 0.06, 0, 0 } },
}
local IMPACT = {
	Hips = { t = { 0, -0.15, 0 } },
	Torso = { r = { 0.45, 0.30, 0 } },
	Head = { r = { 0.30, -0.10, 0 } },
	UpperArm_L = { r = { -0.864, 0, -0.35 } },
	Forearm_L = { r = { -0.05, 0, 0 } },
	UpperArm_R = { r = { 0.30, 0, 0.12 } },
	Forearm_R = { r = { -0.45, 0, 0 } },
	Thigh_R = { r = { -0.15, 0, 0 } }, Thigh_L = { r = { -0.15, 0, 0 } },
	Shin_R = { r = { 0.22, 0, 0 } }, Shin_L = { r = { 0.22, 0, 0 } },
}
local RECOIL = table.clone(IMPACT)
RECOIL.Torso = { r = { 0.40, 0.28, 0 } }
RECOIL.UpperArm_L = { r = { -1.00, 0, -0.33 } }
RECOIL.Forearm_L = { r = { -0.15, 0, 0 } }
local MINE_KEYS: { Key } = {
	{ t = 0.00, ease = "inout", pose = READY },
	{ t = 0.45, ease = "inout", pose = WINDUP },  -- замах
	{ t = MINE_HIT, ease = "in", pose = IMPACT }, -- удар (прискорення)
	{ t = 0.74, ease = "out", pose = RECOIL },    -- віддача
	{ t = MINE_T, ease = "inout", pose = READY }, -- повернення
}
local function easeFn(kind: string, x: number): number
	if kind == "in" then return x * x end
	if kind == "out" then return 1 - (1 - x) * (1 - x) end
	return x * x * (3 - 2 * x)
end
local function lerp3(a: { number }?, b: { number }?, k: number): (number, number, number)
	local ax, ay, az = 0, 0, 0
	local bx, by, bz = 0, 0, 0
	if a then ax, ay, az = a[1], a[2], a[3] end
	if b then bx, by, bz = b[1], b[2], b[3] end
	return ax + (bx - ax) * k, ay + (by - ay) * k, az + (bz - az) * k
end
local function poseMine(p: number): Pose
	local t = p / (2 * math.pi) * MINE_T
	local i = 1
	while i < #MINE_KEYS - 1 and t >= MINE_KEYS[i + 1].t do i += 1 end
	local k0, k1 = MINE_KEYS[i], MINE_KEYS[i + 1]
	local k = easeFn(k1.ease, math.clamp((t - k0.t) / (k1.t - k0.t), 0, 1))
	local out: Pose = {}
	local names: { [string]: boolean } = {}
	for n in k0.pose do names[n] = true end
	for n in k1.pose do names[n] = true end
	for n in names do
		local a, b = k0.pose[n], k1.pose[n]
		local rx, ry, rz = lerp3(a and a.r, b and b.r, k)
		local tx, ty, tz = lerp3(a and a.t, b and b.t, k)
		out[n] = { r = rot(rx, ry, rz), t = Vector3.new(tx, ty, tz) }
	end
	return out
end

local CLIPS: { [string]: { T: number, fn: (number) -> Pose } } = {
	Mine = { T = MINE_T, fn = poseMine },
	Idle = { T = 2.4, fn = poseIdle },
	Walk = { T = 1.2, fn = function(p) return poseGait(p, 0.45, 0.7, 0.35, 0.25, 0.18, 0.05, 0.08) end },
	Run = { T = 0.7, fn = function(p) return poseGait(p, 0.75, 1.2, 0.6, 0.6, 0.35, 0.18, 0.12) end },
	Face = { T = 4.0, fn = poseFace },
}

-- ---------- стан ----------
local current, previous = "Idle", "Idle"
local blendT, BLEND = 1, 0.25
local clock = 0
local lastPos = root.Position
local smoothSpeed = 0
-- [Plot] LOD: далекі големи оновлюються 4 рази на секунду
local LOD_DIST, lodAcc = 150, 0
-- [Plot] Carry: руки тримають ящичок перед собою
local function holdPose(a: Pose): Pose
	local o = table.clone(a)
	o.UpperArm_R = { r = rot(-0.95, 0, 0.32) }
	o.UpperArm_L = { r = rot(-0.95, 0, -0.32) }
	o.Forearm_R = { r = rot(-0.55, 0, 0) }
	o.Forearm_L = { r = rot(-0.55, 0, 0) }
	return o
end

local function pickState(dt: number): string
	local wanted = model:GetAttribute("State")
	if wanted == "Idle" or wanted == "Walk" or wanted == "Run" or wanted == "Mine" then return wanted end
	local pos = root.Position
	local v = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(lastPos.X, 0, lastPos.Z)).Magnitude / math.max(dt, 1e-3)
	lastPos = pos
	smoothSpeed += (v - smoothSpeed) * math.min(1, dt * 8)
	local scale = model:GetScale()
	local walkT = (model:GetAttribute("WalkSpeedThreshold") :: number?) or 1 * scale
	local runT = (model:GetAttribute("RunSpeedThreshold") :: number?) or 9 * scale
	if smoothSpeed > runT then return "Run" elseif smoothSpeed > walkT then return "Walk" end
	return "Idle"
end

local function sample(name: string): Pose
	local c = CLIPS[name]
	return c.fn(2 * math.pi * ((clock % c.T) / c.T))
end

-- ---------- предмет у руці ----------
-- Дочірні моделі Pickaxe / Sword (клон префаба, ставить GolemCatalog.applyClassItems): кожна деталь має атрибут FistRel —
-- CFrame відносно деталі-кулака (Hand, за замовчуванням Fist_L) при масштабі Scale0; предмет їздить за кулаком.
type Item = { part: BasePart, rel: CFrame, s0: number, hand: number }
local items: { Item } = {}
local itemParts: { BasePart } = {}
local itemCfs: { CFrame } = {}
local function blockIndex(name: string): number?
	for i, blk in blocks do if blk.part.Name == name and blk.part.Parent == model then return i end end
	return nil
end
local function rebuildItems()
	table.clear(items); table.clear(itemParts); table.clear(itemCfs)
	for _, n in { "Pickaxe", "Sword" } do
		local g = model:FindFirstChild(n)
		if g then
			local hand = blockIndex((g:GetAttribute("Hand") :: string?) or "Fist_L")
			local s0 = (g:GetAttribute("Scale0") :: number?) or 1
			if hand then
				for _, d in g:GetDescendants() do
					local rel = d:GetAttribute("FistRel")
					if d:IsA("BasePart") and typeof(rel) == "CFrame" then
						table.insert(items, { part = d, rel = rel, s0 = s0, hand = hand })
						table.insert(itemParts, d)
						table.insert(itemCfs, d.CFrame)
					end
				end
			end
		end
	end
end
rebuildItems()
model.ChildAdded:Connect(function(c) if c.Name == "Pickaxe" or c.Name == "Sword" then task.defer(rebuildItems) end end)
model.ChildRemoved:Connect(function(c) if c.Name == "Pickaxe" or c.Name == "Sword" then rebuildItems() end end)

local boneCF: { CFrame } = table.create(#bones, CFrame.identity)
local boneSc: { Vector3 } = table.create(#bones, Vector3.one)
local cfs: { CFrame } = table.create(#parts, CFrame.identity)

RunService.PreRender:Connect(function(dt)
	if not model.Parent then return end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - root.Position).Magnitude > LOD_DIST then
		lodAcc += dt
		if lodAcc < 0.25 then return end
		dt, lodAcc = lodAcc, 0
	end
	clock += dt * ((model:GetAttribute("AnimSpeed") :: number?) or 1)
	local st = pickState(dt)
	if st ~= current then
		previous, current, blendT = current, st, 0
		if st == "Mine" then clock = 0 end -- [Plot] удар синхронний із сервером: перший удар через MINE_HIT / AnimSpeed
	end
	blendT = math.min(1, blendT + dt / BLEND)

	-- момент удару: повідомляємо ціль (руду) через атрибути HitPoint і HitTime
	local pendingHit: Instance? = nil
	if current == "Mine" then
		local tNow = clock % MINE_T
		local tPrev = (clock - dt * ((model:GetAttribute("AnimSpeed") :: number?) or 1)) % MINE_T
		local crossed = if tPrev <= tNow then (tPrev < MINE_HIT and tNow >= MINE_HIT) else (tPrev < MINE_HIT or tNow >= MINE_HIT)
		if crossed and blendT >= 1 then
			local target = model:FindFirstChild("MineTarget")
			if target and target:IsA("ObjectValue") and target.Value then
				pendingHit = target.Value -- спрацює після оновлення пози в цьому кадрі
			end
		end
	end

	local a = sample(current)
	if model:GetAttribute("Carry") then a = holdPose(a) end
	local b = if blendT < 1 then sample(previous) else nil
	local face = if model:GetAttribute("Face") ~= false then sample("Face") else nil
	local S = UNIT * model:GetScale()

	for i, bone in bones do
		local name = bone.name
		local pa = a[name] or (face and face[name])
		local t = (pa and pa.t) or Vector3.zero
		local r = (pa and pa.r) or CFrame.identity
		local sc = (pa and pa.s) or Vector3.one
		if b then
			local pb = b[name]
			if pb or pa then
				local tb = (pb and pb.t) or Vector3.zero
				local rb = (pb and pb.r) or CFrame.identity
				if pb or not (face and face[name]) then
					t = tb:Lerp(t, blendT)
					r = rb:Lerp(r, blendT)
				end
			end
		end
		local local_ = (bone.rest + t) * S
		if bone.parentIdx then
			local pi = bone.parentIdx
			boneCF[i] = boneCF[pi] * CFrame.new(local_ * boneSc[pi]) * r
			boneSc[i] = boneSc[pi] * sc
		else
			boneCF[i] = CFrame.new(local_) * r
			boneSc[i] = sc
		end
	end

	local base = root.CFrame * FLIP
	for i, blk in blocks do
		local sc = boneSc[blk.bone]
		cfs[i] = base * boneCF[blk.bone] * CFrame.new(blk.offset * S * sc) * blk.rot
		if blk.scaled then
			blk.part.Size = blk.size * S * sc
		end
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	if #items > 0 then
		local k = model:GetScale()
		for i, it in items do
			local r = it.rel
			itemCfs[i] = cfs[it.hand] * CFrame.new(r.Position * (k / it.s0)) * r.Rotation
		end
		workspace:BulkMoveTo(itemParts, itemCfs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	-- [Plot] Carry: ящичок рівно між кулаками (після пози, у тому ж кадрі) — руки справді його тримають
	if model:GetAttribute("Carry") then
		local box = model:FindFirstChild("CarryBox")
		local fl, fr = model:FindFirstChild("Fist_L"), model:FindFirstChild("Fist_R")
		if box and box:IsA("Model") and fl and fr and fl:IsA("BasePart") and fr:IsA("BasePart") then
			local mid = (fl.Position + fr.Position) / 2
			local ctr = (box:GetAttribute("CenterY") :: number?) or 0.575 -- висота центру ящичка над його півотом (дном)
			box:PivotTo(CFrame.new(mid) * root.CFrame.Rotation * CFrame.new(0, -(ctr + BOX_DROP) * model:GetScale(), 0))
		end
	end

	if pendingHit then
		local pick = model:FindFirstChild("Pickaxe")
		local tipPart = pick and pick:FindFirstChild("Pick4")
		if tipPart and tipPart:IsA("BasePart") then
			pendingHit:SetAttribute("HitPoint", tipPart.CFrame * Vector3.new(0, 0, tipPart.Size.Z / 2))
		end
		pendingHit:SetAttribute("HitTime", os.clock())
	end
end)
