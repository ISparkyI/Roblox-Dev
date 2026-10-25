-- RollStandFX — анімація появи нової підставки ролу (після покупки Roll Stands).
-- Де: StarterPlayer/StarterPlayerScripts/RollStandFX (LocalScript).
-- Сервер (RollUpgradeService) ставить підставку одразу на місце і пише атрибут SpawnAt = час сервера.
-- Клієнт, побачивши свіжу підставку (SpawnAt не старше 1.5 с), програє локально:
--   1) з підлоги вилітають кубики кольору підлоги (по периметру підставки);
--   2) підставка виринає з-під підлоги з легким перельотом угору (Back Out, 0.55 с), доворотом на 12° і масштабом 0.85 → 1;
--   3) на приземленні — білий спалах (Highlight, 0.35 с) і квадратна «хвиля» по підлозі, що розходиться і тане.
-- Усе локально й плавно (RenderStepped), сервер нічого не анімує.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RISE, DEPTH, YAW, S0 = 0.55, 1.7, math.rad(12), 0.85

local function backOut(k: number): number
	local c1 = 2.4 -- переліт ~15%
	return 1 + (c1 + 1) * (k - 1) ^ 3 + c1 * (k - 1) ^ 2
end

local function floorUnder(pos: Vector3, ignore: Instance)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = { ignore }
	p.RespectCanCollide = true
	return workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -12, 0), p)
end

-- кубики з підлоги по периметру підставки
local function dust(center: CFrame, half: number, color: Color3, material: Enum.Material, y: number)
	local folder = Instance.new("Folder")
	folder.Name = "StandDust"
	folder.Parent = workspace
	local chips = {}
	for i = 1, 16 do
		local a = (i / 16) * math.pi * 2 + math.random() * 0.3
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local start = Vector3.new(center.X, y + 0.15, center.Z) + dir * half * (0.85 + math.random() * 0.25)
		local s = 0.3 * (0.7 + math.random() * 0.6)
		local c = Instance.new("Part")
		c.Anchored = true; c.CanCollide = false; c.CanQuery = false; c.CanTouch = false; c.CastShadow = false
		c.Size = Vector3.new(s, s, s); c.Color = color; c.Material = material
		c.CFrame = CFrame.new(start) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		c.Parent = folder
		table.insert(chips, { p = c, v = dir * (4 + math.random() * 4) + Vector3.new(0, 9 + math.random() * 5, 0), s = s,
			r = Vector3.new(math.random() * 16 - 8, math.random() * 16 - 8, math.random() * 16 - 8) })
	end
	local t0, life = os.clock(), 0.75
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - t0
		for _, ch in chips do
			ch.v -= Vector3.new(0, 40 * dt, 0)
			local pos = ch.p.Position + ch.v * dt
			if pos.Y < y + ch.s / 2 then pos = Vector3.new(pos.X, y + ch.s / 2, pos.Z); ch.v = Vector3.new(ch.v.X * 0.5, 0, ch.v.Z * 0.5) end
			local k = math.clamp((t - life * 0.65) / (life * 0.35), 0, 1)
			local sz = ch.s * (1 - k)
			ch.p.Size = Vector3.new(sz, sz, sz)
			ch.p.CFrame = CFrame.new(pos) * (ch.p.CFrame - ch.p.Position) * CFrame.Angles(ch.r.X * dt, ch.r.Y * dt, ch.r.Z * dt)
		end
		if t >= life then conn:Disconnect(); folder:Destroy() end
	end)
end

-- квадратна «хвиля» по підлозі: 4 тонкі білі планки, розходяться і тануть
local function wave(center: CFrame, half: number, y: number)
	local folder = Instance.new("Folder")
	folder.Name = "StandWave"
	folder.Parent = workspace
	local base = CFrame.new(center.X, y + 0.06, center.Z) * (center - center.Position)
	local bars = {}
	for i = 0, 3 do
		local b = Instance.new("Part")
		b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
		b.Material = Enum.Material.SmoothPlastic; b.Color = Color3.new(1, 1, 1); b.Transparency = 0.25
		b.Parent = folder
		bars[i] = b
	end
	local t0, dur = os.clock(), 0.5
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / dur)
		local e = 1 - (1 - k) ^ 3
		local h = half * (1 + 0.45 * e)
		local w = 0.35 * (1 - 0.6 * e)
		for i = 0, 3 do
			local b = bars[i]
			b.Size = Vector3.new(h * 2 + w, 0.08, w)
			b.CFrame = base * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, h)
			b.Transparency = 0.25 + 0.75 * k
		end
		if k >= 1 then conn:Disconnect(); folder:Destroy() end
	end)
end

local function flash(model: Model)
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.45
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = model
	hl.Parent = model
	local tw = TweenService:Create(hl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 1 })
	tw:Play()
	tw.Completed:Connect(function() hl:Destroy() end)
end

local playing: { [Model]: boolean } = {}

local function play(model: Model)
	if playing[model] then return end
	playing[model] = true
	local target = model:GetPivot()
	local base = model:GetScale() -- шаблон має власний масштаб (не 1), анімація — відносно нього
	local ext = model:GetExtentsSize()
	local half = math.max(ext.X, ext.Z) / 2
	local hit = floorUnder(target.Position, model)
	local y = hit and hit.Position.Y or (target.Y - ext.Y / 2)
	if hit then dust(target, half, hit.Instance.Color, hit.Instance.Material, y) end

	model:ScaleTo(base * S0)
	model:PivotTo(target * CFrame.new(0, -DEPTH, 0) * CFrame.Angles(0, -YAW, 0))
	local t0, landed = os.clock(), false
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then conn:Disconnect(); playing[model] = nil; return end
		if not model:IsDescendantOf(workspace) then return end
		local k = math.min(1, (os.clock() - t0) / RISE)
		local e = backOut(k) -- 0 → ~1.15 → 1: на перельоті підставка трохи вище за своє місце
		local dy = -DEPTH * (1 - e)
		model:ScaleTo(base * (S0 + (1 - S0) * math.min(1, k * 1.6)))
		model:PivotTo(target * CFrame.new(0, dy, 0) * CFrame.Angles(0, -YAW * (1 - e), 0))
		if not landed and e >= 1 then
			landed = true
			flash(model)
			wave(target, half, y)
		end
		if k >= 1 then
			conn:Disconnect()
			model:ScaleTo(base)
			model:PivotTo(target)
			playing[model] = nil
		end
	end)
end

local function consider(inst: Instance)
	if not inst:IsA("Model") or not string.match(inst.Name, "^Stand%d") then return end
	local at = inst:GetAttribute("SpawnAt")
	if typeof(at) ~= "number" then return end
	if workspace:GetServerTimeNow() - at > 1.5 then return end
	play(inst)
end

-- слухаємо весь workspace: сервер на старті перебудовує Workspace/Niches, і стара папка зникає
workspace.DescendantAdded:Connect(consider)
