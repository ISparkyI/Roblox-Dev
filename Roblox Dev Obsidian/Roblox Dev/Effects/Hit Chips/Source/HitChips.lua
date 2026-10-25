--!strict
-- HitChips: ефект удару — з об'єкта вилітають маленькі блоки його кольору,
-- летять дугою (гравітація) в різні боки, потім зменшуються до 0 і видаляються.
-- Клієнтський візуальний ефект: викликати з LocalScript / Script з RunContext = Client.
--
-- Використання:
--   local HitChips = require(ReplicatedStorage.Effects.HitChips)
--   HitChips.spawn(targetModel, hitPoint)              -- з налаштуваннями за замовчуванням
--   HitChips.spawn(targetModel, hitPoint, { count = 14, speed = 9 })
--
-- Налаштування (opts) можна також задати атрибутами на targetModel з префіксом "Chips":
--   ChipsCount, ChipsSpeed, ChipsLift, ChipsGravity, ChipsLife, ChipsSize, ChipsRadius
local RunService = game:GetService("RunService")

export type Options = {
	count: number?,   -- скільки блоків (за замовчуванням 10)
	speed: number?,   -- горизонтальна швидкість, стадів/с (6)
	lift: number?,    -- початкова швидкість угору, стадів/с (9)
	gravity: number?, -- прискорення вниз, стадів/с² (40)
	life: number?,    -- час життя, с (0.8); останні 35% часу блок зменшується до 0
	size: number?,    -- розмір блока, стадів (0.28), ±35% випадково
	radius: number?,  -- з якої відстані від точки удару брати кольори деталей (1.6)
}

local HitChips = {}

local DEFAULTS = { count = 10, speed = 6, lift = 9, gravity = 40, life = 0.8, size = 0.28, radius = 1.6 }

local function opt(target: Instance, opts: Options?, key: string): number
	local o = opts :: any
	if o and o[key] ~= nil then return o[key] end
	local attr = target:GetAttribute("Chips" .. key:sub(1, 1):upper() .. key:sub(2))
	if typeof(attr) == "number" then return attr end
	return (DEFAULTS :: any)[key]
end

-- деталі, з яких беремо колір і матеріал: найближчі до точки удару, без «блисків»
local function sourceParts(target: Instance, point: Vector3, radius: number): { BasePart }
	local near, all = {}, {}
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 and not d.Name:find("Glint") then
			table.insert(all, d)
			local closest = d.CFrame:PointToWorldSpace(
				(d.CFrame:PointToObjectSpace(point)):Max(-d.Size / 2):Min(d.Size / 2))
			if (closest - point).Magnitude <= radius then table.insert(near, d) end
		end
	end
	return if #near > 0 then near else all
end

local function groundY(point: Vector3, ignore: { Instance }): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true -- ігноруємо інструменти та декор без колізії (кірку тощо)
	local hit = workspace:Raycast(point + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position.Y else point.Y - 50
end

function HitChips.spawn(target: Instance, point: Vector3, opts: Options?)
	local count = math.floor(opt(target, opts, "count"))
	local speed = opt(target, opts, "speed")
	local lift = opt(target, opts, "lift")
	local gravity = opt(target, opts, "gravity")
	local life = opt(target, opts, "life")
	local size = opt(target, opts, "size")
	local radius = opt(target, opts, "radius")

	local sources = sourceParts(target, point, radius)
	if #sources == 0 then return end

	-- напрям «назовні»: від центру об'єкта до точки удару (по горизонталі)
	local center = if target:IsA("Model") then target:GetPivot().Position else (target :: any).Position
	local outward = Vector3.new(point.X - center.X, 0, point.Z - center.Z)
	outward = if outward.Magnitude > 1e-3 then outward.Unit else Vector3.zAxis

	local folder = Instance.new("Folder")
	folder.Name = "HitChips"
	local floor = groundY(point, { target, folder })

	type Chip = { part: BasePart, pos: Vector3, vel: Vector3, rot: CFrame, spin: Vector3, size: Vector3, age: number, life: number }
	local chips: { Chip } = {}
	for i = 1, count do
		local src = sources[math.random(1, #sources)]
		local s = size * (0.65 + math.random() * 0.7)
		local p = Instance.new("Part")
		p.Name = "Chip"
		p.Size = Vector3.new(s, s, s)
		p.Color = src.Color
		p.Material = src.Material
		p.MaterialVariant = src.MaterialVariant
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.CastShadow = false
		p.CFrame = CFrame.new(point)
		p.Parent = folder
		-- випадковий напрям у півсфері навколо «назовні», не дуже сильно
		local ang = (math.random() - 0.5) * math.pi * 1.4
		local dir = CFrame.Angles(0, ang, 0):VectorToWorldSpace(outward)
		local v = dir * speed * (0.5 + math.random() * 0.6) + Vector3.new(0, lift * (0.7 + math.random() * 0.5), 0)
		table.insert(chips, {
			part = p, pos = point + dir * 0.15, vel = v,
			rot = CFrame.Angles(math.random() * 6.28, math.random() * 6.28, math.random() * 6.28),
			spin = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 18,
			size = p.Size, age = 0, life = life * (0.8 + math.random() * 0.4),
		})
	end
	folder.Parent = workspace

	local conn: RBXScriptConnection
	conn = RunService.PreRender:Connect(function(dt)
		local alive = 0
		for _, c in chips do
			if c.age >= c.life then continue end
			c.age += dt
			alive += 1
			c.vel += Vector3.new(0, -gravity * dt, 0)
			c.pos += c.vel * dt
			local half = c.size.Y / 2
			if c.pos.Y - half < floor then -- впав на землю: зупиняємось і ковзаємо
				c.pos = Vector3.new(c.pos.X, floor + half, c.pos.Z)
				c.vel = Vector3.new(c.vel.X * 0.5, 0, c.vel.Z * 0.5)
				c.spin *= 0.5
			end
			c.rot *= CFrame.Angles(c.spin.X * dt, c.spin.Y * dt, c.spin.Z * dt)
			-- останні 35% життя — зменшення до 0
			local k = c.age / c.life
			local scale = if k < 0.65 then 1 else math.max(0, 1 - (k - 0.65) / 0.35)
			if scale <= 0 then
				c.part:Destroy()
				c.age = c.life
				continue
			end
			c.part.Size = c.size * scale
			c.part.CFrame = CFrame.new(c.pos) * c.rot
		end
		if alive == 0 then
			conn:Disconnect()
			folder:Destroy()
		end
	end)
end

return HitChips
