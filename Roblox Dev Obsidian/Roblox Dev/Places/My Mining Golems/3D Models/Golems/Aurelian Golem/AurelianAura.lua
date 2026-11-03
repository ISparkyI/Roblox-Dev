-- Aurelian Golem: сонячна аура — крок після GolemBuilder.build (запускати в Studio, Edit).
-- Додає справжнє світло (PointLight) у сонце на грудях і сонячний диск та золоті іскри (ParticleEmitter) від диска.
-- PlotService.syncPrefabs копіює їх у ReplicatedStorage/PlotAssets разом із моделлю, тож світло є на плоті, у носія й у фігурки в руці.
local m = workspace.PlotPrefabs.AurelianGolem
local gold = Color3.fromRGB(255, 190, 80)
local function light(part, br, rg)
	local l = Instance.new("PointLight")
	l.Name = "SunLight"; l.Color = gold; l.Brightness = br; l.Range = rg; l.Shadows = false; l.Parent = part
end
light(m:FindFirstChild("ChestCore", true), 0.7, 8)
local face = m:FindFirstChild("SunFace", true)
light(face, 1.1, 12)
local pe = Instance.new("ParticleEmitter")
pe.Name = "SunMotes"
pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 150, 40))
pe.LightEmission = 1; pe.LightInfluence = 0
pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
pe.Lifetime = NumberRange.new(1.2, 2); pe.Rate = 7; pe.Speed = NumberRange.new(1, 2.2)
pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, 2, 0); pe.Drag = 1
pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-90, 90)
pe.Parent = face
m:SetAttribute("Aura", "sun")
