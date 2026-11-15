-- ShortServer — сцена для TikTok-ролика «Same 3 Golems: Normal vs Rainbow» (13.11.2026). ТИМЧАСОВО, прибрати після зйомки.
-- Де: ServerScriptService/ShortServer. Працює лише коли workspace:GetAttribute("ShortMode") == true.
-- Будує Workspace/ShortSet високо над картою (O): темна підлога й стіна, 6 подіумів у ряд (крок STEP), на кожному — голем
--   (GolemModel.build, State = Mine, атрибут Mut: 0 Normal / 6 Rainbow — аури малює MutationAuraClient) і руда перед ним.
-- Гравця ховає під підлогою сцени (заякорений), щоб стрімінг тримав сцену завантаженою; навчання вимикає.
if workspace:GetAttribute("ShortMode") ~= true then return end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GolemModel = require(RS:WaitForChild("Shared"):WaitForChild("GolemModel"))

local O = Vector3.new(0, 700, 4000)
local STEP = 70
local SHOTS = {
	-- 13.11.2026: ролик «8 рарностей» — у кожного своя руда й колір обідка = колір рарності (GolemCatalog.RARITY_COLOR)
	{ kind = "mossback", mut = 0, size = 1.05, ore = "Copper_L", s = 0.58, rim = "9aa3ad" },
	{ kind = "ironclad", mut = 0, size = 1.15, ore = "Silver_L", s = 0.52, rim = "3aa6ff" },
	{ kind = "sapphire", mut = 0, size = 1.2, ore = "Sapphire_L", s = 0.73, rim = "c86bff" },
	{ kind = "magmaheart", mut = 0, size = 1.25, ore = "Emberite_L", s = 1.04, rim = "ffc531" },
	{ kind = "prismatic", mut = 0, size = 1.4, ore = "Frostite_L", s = 0.88, rim = "ff4fd8" },
	{ kind = "astral", mut = 0, size = 1.5, ore = "Starmetal_L", s = 1.2, rim = "7ef6ff" },
}
local FACE = math.rad(145) -- голем 3/4 до камери, обличчям праворуч від неї (туди й руда); «вперед» голема = −Z

local set = Instance.new("Folder"); set.Name = "ShortSet"; set.Parent = workspace
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = true; p.CastShadow = false; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do (p :: any)[k] = v end
	p.Parent = set
	return p
end
local DARK = Color3.fromRGB(14, 14, 20)
part({ Name = "Floor", Size = Vector3.new(STEP * 7 + 120, 2, 200), Position = O + Vector3.new(STEP * 2.5, -1, 0), Color = DARK, Material = Enum.Material.SmoothPlastic })
part({ Name = "Back", Size = Vector3.new(STEP * 7 + 120, 120, 2), Position = O + Vector3.new(STEP * 2.5, 59, -45), Color = DARK, Material = Enum.Material.SmoothPlastic })

local function ore(at: Vector3, scale: number, name: string?)
	local assets = RS:FindFirstChild("PlotAssets")
	local f = assets and assets:FindFirstChild("Ores")
	local src = f and ((name and f:FindFirstChild(name)) or f:FindFirstChild("Gold") or f:FindFirstChildWhichIsA("Model") or f:FindFirstChildWhichIsA("BasePart"))
	if src then
		local o = src:Clone()
		for _, d in o:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
		if o:IsA("BasePart") then o.Anchored = true; o.Position = at + Vector3.new(0, o.Size.Y / 2, 0)
		else pcall(function() (o :: any):ScaleTo((o :: any):GetScale() * scale) end); o:PivotTo(CFrame.new(at)) ; local cf, sz = o:GetBoundingBox(); o:PivotTo(o:GetPivot() + Vector3.new(at.X - cf.Position.X, at.Y - (cf.Position.Y - sz.Y / 2), at.Z - cf.Position.Z)) end -- центр рамки (не півот) — у точку at
		if o:IsA("Model") then o.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end
		o.Parent = set
		return o
	end
	return part({ Name = "Rock", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 3, 4), Position = at + Vector3.new(0, 1.2, 0), Color = Color3.fromRGB(90, 84, 80), Material = Enum.Material.Slate })
end

-- моделі големів NicheBoot переносить у PlotAssets не одразу — чекаємо (до 30 с)
do local t0 = os.clock(); while os.clock() - t0 < 30 do local ok = true; for _, s in SHOTS do if not GolemModel.has(s.kind) then ok = false end end; if ok then break end; task.wait(0.25) end end
for i, s in SHOTS do
	local c = O + Vector3.new((i - 1) * STEP, 0, 0)
	local pod = part({ Name = "Podium" .. i, Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 28, 28), CFrame = CFrame.new(c + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(34, 34, 44), Material = Enum.Material.SmoothPlastic })
	-- тонкий неоновий обідок під краєм подіуму (виглядає кільцем збоку)
	part({ Name = "Rim" .. i, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 28.8, 28.8), CFrame = CFrame.new(c + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = s.rim and Color3.fromHex(s.rim) or (s.mut > 0 and Color3.fromRGB(255, 110, 210) or Color3.fromRGB(90, 200, 255)), Material = Enum.Material.Neon, CanCollide = false })
	local _ = pod
	local m = GolemModel.build(s.kind, "miner")
	if m then
		m.Name = "ShortGolem" .. i
		m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- стрімінг не вивантажує голема, коли гравець далеко
		m:SetAttribute("State", "Mine")
		if s.mut > 0 then m:SetAttribute("Mut", s.mut) end
		local base = CFrame.new(c + Vector3.new(0, 1, 0)) * CFrame.Angles(0, FACE, 0)
		m:PivotTo(base)
		local off = GolemModel.footOffset(m)
		m:PivotTo(base + Vector3.new(0, off, 0))
		m.Parent = set
		-- руда — перед големом (вперед = −Z після GolemModel.build)
		-- 13.11.2026: руда там, куди б'є кінчик леза (атрибут HitPoint аніматора, заміряно в Play): прямо перед големом,
		--   Ironclad ≈ 8 стадів, Sapphire ≈ 8.5, Prismatic ≈ 9.7, на висоті ≈ 2.5–3; верх руди — на висоті удару
		local HIT = { ironclad = { z = -7.8, s = 0.64 }, sapphire = { z = -8.4, s = 0.64 }, prismatic = { z = -9.6, s = 0.68 } }
		local h = HIT[s.kind] or { z = -6.85 * (s.size or 1.2), s = 0.64 }
		local o = ore((base * CFrame.new(0.8, 0, h.z - 1.2)).Position, s.s or h.s, s.ore)
		local mt = Instance.new("ObjectValue"); mt.Name = "MineTarget"; mt.Value = o; mt.Parent = m -- аніматор пише HitPoint (кінчик леза) у момент удару
	end
	local lamp = part({ Name = "Lamp" .. i, Size = Vector3.new(1, 1, 1), Position = c + Vector3.new(0, 26, 6), Transparency = 1, CanCollide = false })
	local sl = Instance.new("SpotLight"); sl.Face = Enum.NormalId.Bottom; sl.Angle = 55; sl.Range = 40; sl.Brightness = 1.8; sl.Color = Color3.fromRGB(255, 244, 230); sl.Shadows = true; sl.Parent = lamp
	-- заповнювальне світло спереду (з боку камери): обличчя й груди голема не в тіні
	local fill = part({ Name = "Fill" .. i, Size = Vector3.new(1, 1, 1), Position = c + Vector3.new(-4, 9, 16), Transparency = 1, CanCollide = false })
	local pl = Instance.new("PointLight"); pl.Range = 30; pl.Brightness = 0.7; pl.Color = Color3.fromRGB(235, 240, 255); pl.Shadows = false; pl.Parent = fill
end
workspace:SetAttribute("ShortOrigin", O); workspace:SetAttribute("ShortStep", STEP); workspace:SetAttribute("ShortCount", #SHOTS)

local function park(p: Player)
	p:SetAttribute("TutorialDone", true); p:SetAttribute("TutStep", nil)
	local ch = p.Character or p.CharacterAdded:Wait()
	local hrp = ch:WaitForChild("HumanoidRootPart") :: BasePart
	task.wait(1)
	hrp.Anchored = true
	hrp.CFrame = CFrame.new(O + Vector3.new(STEP * 2.5, -12, 0))
end
Players.PlayerAdded:Connect(park)
for _, p in Players:GetPlayers() do task.spawn(park, p) end
