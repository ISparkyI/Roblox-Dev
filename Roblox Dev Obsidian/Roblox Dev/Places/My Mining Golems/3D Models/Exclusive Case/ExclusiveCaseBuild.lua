-- Exclusive Case: 3D-модель кейсу ексклюзивних големів (блоковий стиль, як у големів: Plastic + StudsSmall, світло — Neon).
-- Будує Workspace/PlotPrefabs/ExclusiveCase (PrefabOf = "ExclusiveCase" → PlotService.syncPrefabs копіює в ReplicatedStorage/PlotAssets).
-- Координати — у стадах моделі (півот = центр низу, перед = +Z), множаться на S.
-- Групи: деталі корпусу — прямо в моделі; кришка — Model "Lid" (обертається навколо атрибута Hinge);
-- кристали-орбіти — Model "Orbits". Ефекти: InnerGlow (світло CaseLight, частинки Burst і Glimmer).
local S = 1.5
local BASE = CFrame.new(-1143, -0.4, 186.8) * CFrame.Angles(0, math.rad(90), 0) -- кінець платформи, перед кейсу дивиться вздовж ряду (+X)
local COL = {
	crimson = Color3.fromHex("#5c1426"), dark = Color3.fromHex("#22161f"), gold = Color3.fromHex("#f2c14e"),
	red = Color3.fromHex("#ff5a5a"), pink = Color3.fromHex("#ff4fa0"), light = Color3.fromHex("#fff3f3"),
}
local NEON = { red = true, pink = true }
local R45Y = CFrame.Angles(0, math.rad(45), 0)
local R45Z = CFrame.Angles(0, 0, math.rad(45))
local R45X = CFrame.Angles(math.rad(45), 0, 0)
local OCTA = CFrame.Angles(math.rad(35.264), 0, 0) * CFrame.Angles(0, 0, math.rad(45))

local pp = workspace.PlotPrefabs
local old = pp:FindFirstChild("ExclusiveCase"); if old then old:Destroy() end
local m = Instance.new("Model"); m.Name = "ExclusiveCase"
local lid = Instance.new("Model"); lid.Name = "Lid"; lid.Parent = m
local orbits = Instance.new("Model"); orbits.Name = "Orbits"; orbits.Parent = m

local function P(name, parent, col, x, y, z, sx, sy, sz, rot)
	local p = Instance.new("Part")
	p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = COL[col]
	if NEON[col] then p.Material = Enum.Material.Neon else p.Material = Enum.Material.Plastic; p.MaterialVariant = "StudsSmall" end
	p.Size = Vector3.new(sx, sy, sz) * S
	p.CFrame = BASE * CFrame.new(x * S, y * S, z * S) * (rot or CFrame.identity)
	p.Parent = parent
	return p
end

-- ---------- корпус ----------
P("Plinth", m, "dark", 0, 0.25, 0, 6.8, 0.5, 4.8)
P("PlinthTrim", m, "gold", 0, 0.6, 0, 7.0, 0.2, 5.0)
P("Body", m, "crimson", 0, 1.8, 0, 6.0, 2.2, 4.0)
P("Band", m, "gold", 0, 0.95, 0, 6.16, 0.3, 4.16)
for _, sx in ipairs({ 1, -1 }) do
	for _, sz in ipairs({ 1, -1 }) do
		P("Post" .. (sx > 0 and "R" or "L") .. (sz > 0 and "F" or "B"), m, "gold", 2.86 * sx, 1.82, 1.86 * sz, 0.56, 2.24, 0.56)
	end
	P("SideGem" .. (sx > 0 and "R" or "L"), m, "red", 3.06 * sx, 1.95, 0, 0.12, 0.8, 0.8, R45X)
	P("Hinge" .. (sx > 0 and "R" or "L"), m, "dark", 1.8 * sx, 2.9, -2.05, 0.8, 0.5, 0.5)
end
-- емблема спереду: золота рамка-ромб, червоне світло, світлий самоцвіт
P("EmblemFrame", m, "gold", 0, 1.95, 2.07, 1.3, 1.3, 0.14, R45Z)
P("EmblemGlow", m, "red", 0, 1.95, 2.1, 0.9, 0.9, 0.2, R45Z)
P("EmblemGem", m, "light", 0, 1.95, 2.13, 0.32, 0.32, 0.26, R45Z)
-- світло всередині (видно, коли кришка відкрита)
local glow = P("InnerGlow", m, "red", 0, 2.86, 0, 5.6, 0.1, 3.6)

-- ---------- кришка (шарнір ззаду зверху) ----------
P("LidSlab", lid, "crimson", 0, 3.2, 0, 6.1, 0.6, 4.1)
P("LidTrim", lid, "gold", 0, 3.04, 0, 6.26, 0.24, 4.26)
P("LidTop", lid, "dark", 0, 3.7, 0, 5.0, 0.4, 3.1)
P("LidDiamond", lid, "gold", 0, 3.97, 0, 2.0, 0.14, 2.0, R45Y)
P("LidDiamondGlow", lid, "red", 0, 4.04, 0, 1.4, 0.2, 1.4, R45Y)
P("GemMount", lid, "gold", 0, 4.25, 0, 0.6, 0.3, 0.6, R45Y)
P("CrownGem", lid, "red", 0, 4.85, 0, 0.9, 0.9, 0.36, R45Z)
P("CrownShine", lid, "light", 0, 4.85, 0, 0.34, 0.34, 0.44, R45Z)
P("Lock", lid, "gold", 0, 2.95, 2.15, 0.7, 0.9, 0.25)
P("LockGem", lid, "pink", 0, 2.9, 2.3, 0.26, 0.26, 0.1, R45Z)
for _, sx in ipairs({ 1, -1 }) do
	for _, sz in ipairs({ 1, -1 }) do
		P("LidCap" .. (sx > 0 and "R" or "L") .. (sz > 0 and "F" or "B"), lid, "gold", 2.8 * sx, 3.62, 1.8 * sz, 0.6, 0.3, 0.6)
	end
end

-- ---------- кристали навколо (кружляють) ----------
for k = 1, 4 do
	local a = math.rad(45 + 90 * (k - 1))
	P("Crystal" .. k, orbits, k % 2 == 1 and "red" or "pink", 4.6 * math.sin(a), 2.6, 4.6 * math.cos(a), 0.45, 0.9, 0.45, R45Y)
end

-- ---------- світло й частинки ----------
local light = Instance.new("PointLight")
light.Name = "CaseLight"; light.Color = Color3.fromRGB(255, 120, 140); light.Brightness = 0; light.Range = 8 * S; light.Shadows = false
light.Parent = glow
local function emitter(name, rate, speed, life, size, acc, spread)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = name
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, COL.red), ColorSequenceKeypoint.new(0.5, COL.pink), ColorSequenceKeypoint.new(1, COL.gold) })
	pe.LightEmission = 1; pe.LightInfluence = 0
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(life * 0.6, life); pe.Rate = rate; pe.Speed = NumberRange.new(speed * 0.6, speed)
	pe.EmissionDirection = Enum.NormalId.Top; pe.SpreadAngle = Vector2.new(spread, spread)
	pe.Acceleration = acc; pe.Drag = 1.2; pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-120, 120)
	pe.Parent = glow
	return pe
end
emitter("Burst", 0, 22 * S / 1.5, 1.6, 0.7 * S, Vector3.new(0, -14, 0), 40)
emitter("Glimmer", 3, 2, 1.4, 0.35 * S, Vector3.new(0, 1.5, 0), 60)

m:SetAttribute("PrefabOf", "ExclusiveCase")
m:SetAttribute("Scale", S)
m:SetAttribute("Hinge", Vector3.new(0, 2.9, -2.0) * S) -- у системі півота кейсу
m:SetAttribute("Top", 2.9 * S)
m.PrimaryPart = m.Plinth
m.WorldPivot = BASE
m.Parent = pp
return m
