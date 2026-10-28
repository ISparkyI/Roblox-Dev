--!strict
-- MutationAura — 3D-аури мутацій на моделях големів (лише клієнт). GDD - Golems, «Ефекти мутацій (аури)», v5 (27.10.2026).
-- Де: ReplicatedStorage/Shared/MutationAura. Вмикає StarterPlayerScripts/MutationAuraClient для кожної моделі голема у Workspace
--   з атрибутом Mut > 0 (плот, фігурка в руці, стенд печери, підставки ролу). Слоти інвентаря (ViewportFrame) — без аур.
-- API: apply(model, mut, opts?) / clear(model) / count(). opts.scale — масштаб (1 = голем ≈ 7 стадів заввишки);
--   без нього — атрибут AuraScale або висота рамки моделі / 7. Мала модель (фігурка) — менші частинки й рідше.
-- v4-A (веб-макет mutation_fx/web/auras.html, обрав користувач): одна мова ефектів для всіх мутацій, різниця — колір
--   (GolemCatalog.MUTATIONS[].color) і трохи кількість:
--   • Bronze … Rainbow: лише іскри-зірочки з контуром (Shape Cylinder Surface) і двотонні ромбики-жарини, що здіймаються
--     (Shape Cylinder Volume), без світіння; густина трохи росте до Rainbow. Silver — світле срібло з легким блакитним
--     (SILVER_*), без чорного. Rainbow — колір переливається.
--   • Secret (v5, унікальна чорно-біла): 5 білих комет (Neon-куля, єдине світіння) зі шлейфом Trail білий → графіт позаду
--     руху на двох нахилених орбітах; білі зірочки; майже чорні ромбики з білою гранню; повільні темні осколки, що кружляють
--     навколо (LockedToPart, якір обертається); рідкі білі зірки-спалахи (Emit раз на 1,6–2,6 с).
--   Без кіл під ногами, без плям і PointLight.
-- Якір: одна невидима заякорена деталь на голема у Workspace/MutationAuraFx (поза моделлю — ScaleTo і зварювання фігурки її
--   не чіпають); спільний Heartbeat ставить якорі в Root (BulkMoveTo) і водить комети. LOD: далі LOD_DIST стадів від камери —
--   усе вимкнено (перевірка раз на 0,3 с). Коли поруч понад DENSE аур — Rate іскор і жарин зменшується (не нижче 40 %).

local RunService = game:GetService("RunService")
local Catalog = require(script.Parent:WaitForChild("GolemCatalog"))

local M = {}
M.LOD_DIST = 80
M.DENSE = 10

local TEX = {
	comet = "rbxassetid://85324709623968", -- куля з ореолом (decal 104697808668305); запас — голова комети в грі = Neon-куля
	star = "rbxassetid://89825351264086", -- 4-променева зірочка з темним контуром (decal 103251156230517)
	rhomb = "rbxassetid://71794116629222", -- ромбик два тони + темний контур (decal 115208808634761)
	rhombDark = "rbxassetid://115218568152883", -- графітовий ромбик з білою гранню, Secret (decal 90992627698278)
	trail = "rbxassetid://121383551573029", -- смуга шлейфу: суцільний центр, м'які краї (decal 112671822166899)
}
M.TEX = TEX

local WHITE = Color3.new(1, 1, 1)
local GRAPHITE = Color3.fromHex("2a2c30")
-- Silver в аурі — тепле світле срібло з легким блакитним (щоб не плутати з чорно-білим Secret); каталог не змінюємо
local SILVER_MAIN, SILVER_LIGHT = Color3.fromHex("cfdbe8"), Color3.fromHex("f4f8ff")
M.SPIN_SECRET = 0.6 -- рад/с, обертання якоря Secret (осколки з LockedToPart кружляють)
local function NS(...: number): NumberSequence
	local a = { ... }
	if #a == 1 then return NumberSequence.new(a[1]) end
	local k = {}
	for i = 1, #a, 2 do table.insert(k, NumberSequenceKeypoint.new(a[i], a[i + 1])) end
	return NumberSequence.new(k)
end
local function hueC(h: number): Color3 return Color3.fromHSV(h % 1, 0.85, 1) end
local function rainbowSeq(off: number): ColorSequence
	local k = {}
	for i = 0, 6 do table.insert(k, ColorSequenceKeypoint.new(i / 6, hueC(i / 7 + off))) end
	return ColorSequence.new(k)
end

-- орбіти комет (частки висоти h / радіуса R): перша — нижче й ширше, друга — вище, вужча, назустріч
local ORBITS = {
	{ r = 1.0, y = 0.47, tilt = 0.14, w = 1.6, ph = 0 },
	{ r = 0.86, y = 0.79, tilt = -0.12, w = -1.9, ph = 0.8 },
}

type Comet = { head: Part, trail: Trail, orbit: number, phase: number, idx: number }
type Aura = { model: Model, root: BasePart, mut: number, s: number, h: number, R: number, footY: number, anchor: Part,
	comets: { Comet }, sparks: ParticleEmitter, embers: ParticleEmitter, baseS: number, baseE: number, on: boolean, tw: number,
	shards: ParticleEmitter?, flash: ParticleEmitter?, nextFlash: number }
local active: { [Model]: Aura } = {}
local loop: RBXScriptConnection? = nil
local density = 1

local fxFolder: Folder? = nil
local function folder(): Folder
	if fxFolder and fxFolder.Parent then return fxFolder end
	local f = Instance.new("Folder")
	f.Name = "MutationAuraFx"
	f.Parent = workspace
	fxFolder = f
	return f
end

local function rootOf(model: Model): BasePart?
	local r = model:FindFirstChild("Root")
	if r and r:IsA("BasePart") then return r end
	return model.PrimaryPart
end

-- кольори мутації: основний, світлий
local function colorsOf(mut: number): (Color3, Color3)
	local u = Catalog.MUTATIONS[mut + 1]
	if u.key == "Secret" then return WHITE, WHITE end
	if u.key == "Silver" then return SILVER_MAIN, SILVER_LIGHT end
	local c = u.color :: Color3
	return c, c:Lerp(WHITE, 0.5)
end

local function setOn(a: Aura, on: boolean)
	a.on = on
	a.sparks.Enabled = on
	a.embers.Enabled = on
	if a.shards then a.shards.Enabled = on end
	for _, c in a.comets do
		c.head.Transparency = if on then 0 else 1
		c.trail.Enabled = on
	end
end

local function applyDensity()
	for _, a in active do
		a.sparks.Rate = a.baseS * density
		a.embers.Rate = a.baseE * density
	end
end

-- світова позиція голови комети (base — CFrame якоря без повороту по нахилу орбіти)
local function cometCF(a: Aura, c: Comet, base: CFrame, t: number): CFrame
	local o = ORBITS[c.orbit]
	local ang = t * o.w + c.phase
	local R = o.r * a.R
	return CFrame.new(base:PointToWorldSpace(Vector3.new(math.cos(ang) * R, (o.y - 0.5) * a.h + math.cos(ang) * R * o.tilt, math.sin(ang) * R)))
end

local function startLoop()
	if loop then return end
	local acc, rAcc = 0, 0
	loop = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		acc += dt; rAcc += dt
		local lod = acc >= 0.3
		if lod then acc = 0 end
		local rain = rAcc >= 1 / 15
		if rain then rAcc = 0 end
		local cam = workspace.CurrentCamera
		local parts: { BasePart }, cfs: { CFrame } = {}, {}
		local near = 0
		for model, a in active do
			if not model.Parent or not a.root.Parent then
				M.clear(model)
				continue
			end
			if lod then
				local on = cam == nil or (cam.CFrame.Position - a.root.Position).Magnitude <= M.LOD_DIST
				if on ~= a.on then setOn(a, on) end
			end
			if not a.on then continue end
			near += 1
			local base = a.root.CFrame * CFrame.new(0, a.footY + 0.5 * a.h, 0)
			table.insert(parts, a.anchor)
			table.insert(cfs, if a.shards then base * CFrame.Angles(0, t * M.SPIN_SECRET, 0) else base)
			if a.flash and t >= a.nextFlash then
				a.nextFlash = t + 1.6 + math.random()
				a.flash:Emit(1)
			end
			for _, c in a.comets do
				table.insert(parts, c.head)
				table.insert(cfs, cometCF(a, c, base, t))
			end
			if rain and a.mut == 6 then -- Rainbow: перелив
				local n = #a.comets
				for _, c in a.comets do
					local col = hueC(t * 0.25 + c.idx / n)
					c.head.Color = col
					c.trail.Color = ColorSequence.new(col:Lerp(WHITE, 0.3), col)
				end
				a.sparks.Color = rainbowSeq(t * 0.25)
				a.embers.Color = rainbowSeq(t * 0.25 + 0.5)
			end
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
		if lod then
			local nd = if near > M.DENSE then math.max(0.4, M.DENSE / near) else 1
			if math.abs(nd - density) > 0.05 then density = nd; applyDensity() end
		end
		if next(active) == nil and loop then loop:Disconnect(); loop = nil end
	end)
end

function M.clear(model: Model)
	local a = active[model]
	if not a then return end
	active[model] = nil
	if a.anchor.Parent then a.anchor:Destroy() end
end

-- рамка моделі лише з деталей поблизу Root (≤ NEAR стадів). У щойно створеній моделі (реплікація, ящичок носія, фейк ролу до
-- PivotTo) окремі деталі бувають далеко — тоді GetBoundingBox давав циліндр-емітер на сотні стадів і частинки «літали» по всій
-- карті (баг 27.10.2026, v5.1). Немає деталей поруч — рамка 1 × 1 × 1 біля Root.
local NEAR = 12
local function nearBounds(model: Model, root: BasePart): (CFrame, Vector3)
	local o = root.Position
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and (p.Position - o).Magnitude <= NEAR then
			local e = p.Size / 2
			lo = lo:Min(p.Position - e)
			hi = hi:Max(p.Position + e)
		end
	end
	if lo.X > hi.X then return CFrame.new(o), Vector3.one end
	return CFrame.new((lo + hi) / 2), hi - lo
end

function M.apply(model: Model, mut: number, opts: { scale: number? }?)
	M.clear(model)
	if mut < 1 or mut > 7 then return end
	local root = rootOf(model)
	if not root then return end
	local bcf, size = nearBounds(model, root)
	local fixed = (opts and opts.scale) or (model:GetAttribute("AuraScale") :: number?)
	local h = if fixed then 7 * fixed else math.clamp(size.Y, 0.5, 2 * NEAR)
	local s = fixed or (h / 7)
	local R = if fixed then 0.6 * h else math.clamp(math.max(size.X, size.Z) * 0.5 * 1.15, 0.6 * h, 0.8 * h) -- не ширше 0,8 висоти
	local footY = if fixed then -0.057 * h else (bcf.Position.Y - size.Y / 2) - root.Position.Y
	local k = mut - 1 -- 0 (Bronze) .. 6 (Secret)
	local small = s < 0.45
	local rateK = math.clamp(s, 0.35, 1)
	local main, light = colorsOf(mut)
	local secret = mut == 7

	local anchor = Instance.new("Part")
	anchor.Name = "MutAura_" .. model.Name
	anchor.Anchored = true; anchor.CanCollide = false; anchor.CanQuery = false; anchor.CanTouch = false; anchor.CastShadow = false
	anchor.Locked = true; anchor.Transparency = 1
	anchor.Size = Vector3.new(2 * R * 0.85, 0.9 * h, 2 * R * 0.85) -- область іскор і жарин
	anchor.CFrame = root.CFrame * CFrame.new(0, footY + 0.5 * h, 0)

	-- іскри-зірочки з контуром (без світіння)
	local sp = Instance.new("ParticleEmitter")
	sp.Name = "Sparks"
	sp.Texture = TEX.star
	sp.Color = ColorSequence.new(light, main)
	sp.LightEmission = 0; sp.LightInfluence = 0
	sp.Shape = Enum.ParticleEmitterShape.Cylinder; sp.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	sp.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward; sp.EmissionDirection = Enum.NormalId.Top
	sp.Speed = NumberRange.new(0); sp.Acceleration = Vector3.new(0, 0.8 * s, 0)
	sp.Lifetime = NumberRange.new(0.8, 1.0)
	local ss = (if secret then 0.7 else 0.9) * s * (1 + k * 0.045) -- без комет зірочки трохи більші
	sp.Size = NS(0, 0, 0.45, ss, 1, 0)
	sp.Transparency = NS(0)
	sp.Rotation = NumberRange.new(0); sp.ZOffset = 0.1
	local baseS = (if secret then 9 else 5 + 1.2 * k) * 1.3 * rateK -- без комет — трохи густіше (v5)
	sp.Rate = baseS * density
	sp.Parent = anchor

	-- ромбики-жарини, два тони (Secret — графітові з білою гранню)
	local em = Instance.new("ParticleEmitter")
	em.Name = "Embers"
	em.Texture = if secret then TEX.rhombDark else TEX.rhomb
	em.Color = ColorSequence.new(main)
	em.LightEmission = 0; em.LightInfluence = 0
	em.Shape = Enum.ParticleEmitterShape.Cylinder; em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	em.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward; em.EmissionDirection = Enum.NormalId.Top
	em.Speed = NumberRange.new(0.2 * s, 0.5 * s); em.Drag = 0.3
	em.Acceleration = Vector3.new(0, 1.5 * s, 0)
	em.Lifetime = NumberRange.new(2.4, 3.0)
	em.Size = NS(0, (if secret then 0.5 else 0.6) * s, 1, 0.25 * s)
	em.Transparency = NS(0, 1, 0.1, 0, 0.8, 0, 1, 1)
	em.Rotation = NumberRange.new(0)
	local baseE = (if secret then 16 else 9 + 2 * k) * 0.45 * rateK
	em.Rate = baseE * density
	em.Parent = anchor

	local a: Aura = { model = model, root = root, mut = mut, s = s, h = h, R = R, footY = footY, anchor = anchor, comets = {},
		sparks = sp, embers = em, baseS = baseS, baseE = baseE, on = true, tw = 0.28 * s * (1 + k * 0.04), nextFlash = os.clock() + 1 }

	if secret then
		-- повільні темні осколки навколо (обертаються разом з якорем)
		local sh = Instance.new("ParticleEmitter")
		sh.Name = "Shards"
		sh.Texture = TEX.rhombDark
		sh.Color = ColorSequence.new(WHITE)
		sh.LightEmission = 0; sh.LightInfluence = 0
		sh.Shape = Enum.ParticleEmitterShape.Cylinder; sh.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		sh.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward; sh.EmissionDirection = Enum.NormalId.Top
		sh.Speed = NumberRange.new(0); sh.LockedToPart = true
		sh.Lifetime = NumberRange.new(4, 5)
		sh.Size = NS(0, 0, 0.15, 0.85 * s, 0.85, 0.85 * s, 1, 0)
		sh.Rotation = NumberRange.new(-20, 20); sh.RotSpeed = NumberRange.new(-25, 25)
		sh.Rate = 2.4 * rateK
		sh.ZOffset = 0.05
		sh.Parent = anchor
		a.shards = sh
		-- рідкі великі білі зірки-спалахи
		local fl = Instance.new("ParticleEmitter")
		fl.Name = "Flash"
		fl.Texture = TEX.star
		fl.Color = ColorSequence.new(WHITE)
		fl.LightEmission = 0.3; fl.LightInfluence = 0
		fl.Shape = Enum.ParticleEmitterShape.Cylinder; fl.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		fl.Speed = NumberRange.new(0)
		fl.Lifetime = NumberRange.new(0.45)
		fl.Size = NS(0, 0, 0.3, 1.7 * s, 1, 0)
		fl.Rotation = NumberRange.new(0, 45)
		fl.Rate = 0
		fl.ZOffset = 0.2
		fl.Parent = anchor
		a.flash = fl
	end

	-- комети — лише Secret (v5): 5, фігурка — 3
	local n = if secret then (if small then 3 else 5) else 0
	local n1 = math.ceil(n / 2)
	local headSize = 0.34 * s * (1 + k * 0.05)
	local trailLife = 0.54 + k * 0.04
	for i = 1, n do
		local orbit = if i <= n1 then 1 else 2
		local j = if orbit == 1 then i - 1 else i - n1 - 1
		local cnt = if orbit == 1 then n1 else n - n1
		-- голова: маленька куля Neon (легке світіння), шлейф — Trail між двома Attachment у кулі
		local head = Instance.new("Part")
		head.Name = "CometHead"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.one * headSize
		head.Material = Enum.Material.Neon
		head.Color = main -- Neon сам висвітлює колір
		head.Anchored = true; head.CanCollide = false; head.CanQuery = false; head.CanTouch = false; head.CastShadow = false; head.Locked = true
		local t0 = Instance.new("Attachment"); t0.Position = Vector3.new(0, a.tw, 0); t0.Parent = head
		local t1 = Instance.new("Attachment"); t1.Position = Vector3.new(0, -a.tw, 0); t1.Parent = head
		local tr = Instance.new("Trail")
		tr.Attachment0 = t0; tr.Attachment1 = t1
		tr.Texture = TEX.trail; tr.TextureMode = Enum.TextureMode.Stretch
		tr.Color = if secret then ColorSequence.new(WHITE, GRAPHITE) else ColorSequence.new(light, main) -- Secret: білий → графіт
		tr.Transparency = NS(0, 0, 0.6, 0.35, 1, 1)
		tr.WidthScale = NS(0, 1, 1, 0)
		tr.Lifetime = trailLife
		tr.FaceCamera = true
		tr.LightEmission = if secret then 0 else 0.5; tr.LightInfluence = 0 -- без додавання, щоб графіт був темним
		tr.MinLength = 0.02
		tr.Parent = head
		local c: Comet = { head = head, trail = tr, orbit = orbit, phase = ORBITS[orbit].ph + j / cnt * math.pi * 2, idx = i }
		head.CFrame = cometCF(a, c, anchor.CFrame, os.clock())
		head.Parent = anchor
		table.insert(a.comets, c)
	end
	anchor.Parent = folder()
	active[model] = a
	startLoop()
end

function M.count(): number
	local n = 0
	for _ in active do n += 1 end
	return n
end

return M
