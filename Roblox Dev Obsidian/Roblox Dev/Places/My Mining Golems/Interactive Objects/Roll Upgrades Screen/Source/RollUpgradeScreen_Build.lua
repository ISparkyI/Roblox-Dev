-- RollUpgradeScreen_Build — збирає модель RollUpgradeScreen у префабі ніші (виконати в Studio, Edit).
-- Табличка — копія таблички користувача `Upgrade panels/Plot_Upgrade_panel`, масштаб ×1.3,
-- ніжки стовпів знизу обрізані (висить симетрично). Висить під жолобом `Roll_Upgrade_placer`
-- на двох ланцюгах. У префабі стоїть у позі «опущено»; ховає й анімує її RollScreenClient.
local pf = workspace.NichePrefabs.NichePrefab_Stage1
assert(not pf:FindFirstChild("RollUpgradeScreen"), "RollUpgradeScreen уже є")
local src = pf["Upgrade panels"].Plot_Upgrade_panel
local SCALE = 1.3
local SLOT = Vector3.new(-821.986, 0, 300.35) -- центр щілини жолоба (x, z)
local SHOWN_CENTER_Y = 28.2                   -- центр таблички в опущеному стані (низ ≈ 17.9)
local ANCHOR_Y = 52                           -- звідки йдуть ланцюги (всередині жолоба)
local SLOT_BOTTOM_Y = 50.65                   -- низ жолоба (нижній край похилих планок)
local CHAIN_DZ = 11                           -- ланцюги на ±11 від центру
local LINKS, PITCH = 26, 0.95

local model = Instance.new("Model"); model.Name = "RollUpgradeScreen"
model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
local board = src:Clone(); board.Name = "Board"; board.Parent = model
for _, d in board:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "Rock" and d.Size.Y > 10 then
		local top = d.Position.Y + d.Size.Y / 2
		local bottom = 3.585 - 0.25 -- кінець стовпа на 0.25 нижче нижнього кільця
		d.Size = Vector3.new(d.Size.X, top - bottom, d.Size.Z)
		d.CFrame = d.CFrame + Vector3.new(0, (top + bottom) / 2 - d.Position.Y, 0)
	end
end
board:ScaleTo(SCALE)
local cf, sz = board:GetBoundingBox()
board:PivotTo(board:GetPivot() + (Vector3.new(SLOT.X, SHOWN_CENTER_Y, SLOT.Z) - cf.Position))
cf, sz = board:GetBoundingBox()
local barTop = -math.huge
for _, d in board:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "1" and d.Size.Y < 1.4 * SCALE and d.Size.X > 20 then barTop = math.max(barTop, d.Position.Y + d.Size.Y / 2) end
end
for _, d in board:GetDescendants() do
	if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false end
end
-- вушка під ланцюги (заходять у верхню планку на 0.1)
local eyes = Instance.new("Folder"); eyes.Name = "Eyelets"; eyes.Parent = board
for i, dz in { -CHAIN_DZ, CHAIN_DZ } do
	local e = Instance.new("Part"); e.Name = "Eyelet" .. i
	e.Size = Vector3.new(0.8, 1.2, 0.8); e.Color = Color3.fromHex("535353"); e.Material = Enum.Material.Plastic; e.MaterialVariant = "Studs"
	e.Anchored = true; e.CanCollide = false; e.CanTouch = false; e.CanQuery = false
	e.CFrame = CFrame.new(SLOT.X, barTop + 0.5, SLOT.Z + dz)
	e.Parent = eyes
end
-- ланцюги: ланки 0.22 × 1.05 × 0.62, кожна друга повернута на 90°
for i, dz in { -CHAIN_DZ, CHAIN_DZ } do
	local f = Instance.new("Folder"); f.Name = "Chain" .. i; f.Parent = model
	for k = 1, LINKS do
		local l = Instance.new("Part"); l.Name = "Link" .. k
		l.Size = Vector3.new(0.22, 1.05, 0.62); l.Color = Color3.fromHex("4b4f55"); l.Material = Enum.Material.Metal
		l.Anchored = true; l.CanCollide = false; l.CanTouch = false; l.CanQuery = false
		local y = ANCHOR_Y - (k - 0.5) * PITCH
		l.CFrame = CFrame.new(SLOT.X, y, SLOT.Z + dz) * CFrame.Angles(0, (k % 2 == 0) and math.pi / 2 or 0, 0)
		l.Transparency = (y < barTop + 1.1) and 1 or 0
		l.Parent = f
	end
end
-- пил зі щілини жолоба (вбудована текстура диму Roblox)
local dustPart = Instance.new("Part"); dustPart.Name = "DustEmitter"
dustPart.Size = Vector3.new(1, 0.2, 34); dustPart.Transparency = 1; dustPart.Anchored = true
dustPart.CanCollide = false; dustPart.CanTouch = false; dustPart.CanQuery = false
dustPart.CFrame = CFrame.new(SLOT.X, SLOT_BOTTOM_Y - 0.15, SLOT.Z); dustPart.Parent = model
local pe = Instance.new("ParticleEmitter"); pe.Name = "Dust"; pe.Enabled = false
pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
pe.Color = ColorSequence.new(Color3.fromHex("b9ad98"))
pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) })
pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
pe.Lifetime = NumberRange.new(1, 1.8); pe.Speed = NumberRange.new(1, 2.5); pe.SpreadAngle = Vector2.new(8, 8)
pe.EmissionDirection = Enum.NormalId.Bottom; pe.Acceleration = Vector3.new(0, -6, 0); pe.Drag = 1
pe.Shape = Enum.ParticleEmitterShape.Box; pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-40, 40)
pe.Parent = dustPart

model:SetAttribute("Open", false)
model:SetAttribute("AnchorY", ANCHOR_Y)
model:SetAttribute("ShownTop", barTop)
model:SetAttribute("HiddenTop", SLOT_BOTTOM_Y + (barTop - (cf.Position.Y - sz.Y / 2)) + 0.6)
model:SetAttribute("ZoneRadius", 20)
model:SetAttribute("HoldTime", 1)
model.Parent = pf
