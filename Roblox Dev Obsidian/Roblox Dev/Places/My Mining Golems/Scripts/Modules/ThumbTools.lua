--!nonstrict
-- ThumbTools — інструменти для рендера превʼю (06.11.2026). Не для гри: викликається з командного рядка Studio (Edit).
-- Полігон: Workspace/ThumbStudio (далеко від карти, 4000, 0, 4000): зелена підлога, небо — Lighting.Sky гри.
-- API:
--   T.bacon(parent, cf) -> Model — класичний Бекон (Pal Hair, Blue and Black Motorcycle Shirt, Dark Green Jeans, Smile, біла шкіра), стопи на cf
--   T.golem(parent, kind, cls, cf) -> Model — голем із PlotPrefabs (як GolemModel.build), стопи на cf
--   T.ground(m, cf) — поставити модель низом рамки на cf
--   T.pose(rig, joints) — повернути Motor6D (ім'я → CFrame.Angles) для статичної пози
--   T.noBlur(on) — вимкнути / повернути Lighting.DepthOfField на час рендера
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local T = {}

function T.ground(m: Model, cf: CFrame)
	m:PivotTo(CFrame.new(m:GetPivot().Position)) -- спершу без повороту, щоб рамка була вирівняна
	local bcf, sz = m:GetBoundingBox()
	local off = m:GetPivot().Position.Y - (bcf.Position.Y - sz.Y / 2)
	m:PivotTo(cf * CFrame.new(0, off, 0))
end

function T.bacon(parent: Instance, cf: CFrame): Model
	local d = Instance.new("HumanoidDescription")
	d.HairAccessory = "63690008" -- Pal Hair
	d.Shirt = 144076358          -- Blue and Black Motorcycle Shirt
	d.Pants = 144076760          -- Dark Green Jeans
	d.Face = 144075659           -- Smile
	local w = Color3.fromRGB(245, 245, 245)
	d.HeadColor, d.TorsoColor, d.LeftArmColor, d.RightArmColor, d.LeftLegColor, d.RightLegColor = w, w, w, w, w, w
	local b = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	b.Name = "Bacon"
	b.Parent = parent
	b.Humanoid:BuildRigFromAttachments()
	for _, acc in b:GetChildren() do
		if acc:IsA("Accessory") then
			local h = acc:FindFirstChild("Handle")
			local a = h and h:FindFirstChildOfClass("Attachment")
			local tgt = a and b:FindFirstChild(a.Name, true)
			if tgt and tgt ~= a then
				h.CFrame = tgt.WorldCFrame * a.CFrame:Inverse()
				if not h:FindFirstChild("AccessoryWeld") then
					local wd = Instance.new("Weld"); wd.Name = "AccessoryWeld"; wd.Part0 = h; wd.Part1 = tgt.Parent; wd.C0 = a.CFrame; wd.C1 = tgt.CFrame; wd.Parent = h
				end
			end
		end
	end
	do -- класична голова зі Smile (дефолтна динамічна голова не показує decal-обличчя)
		local h = b:FindFirstChild("Head") :: BasePart
		h.Transparency = 1
		local p = Instance.new("Part")
		p.Name = "ClassicHead"; p.CanCollide = false; p.Size = Vector3.new(2, 1, 1); p.CFrame = h.CFrame; p.Color = h.Color
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		local sm = Instance.new("SpecialMesh"); sm.MeshType = Enum.MeshType.Head; sm.Scale = Vector3.new(1.25, 1.25, 1.25) * (h.Size.Y / 1.2); sm.Parent = p
		local dc = Instance.new("Decal"); dc.Name = "face"; dc.Face = Enum.NormalId.Front; dc.Texture = "rbxassetid://144080495"; dc.Parent = p
		local wd = Instance.new("Weld"); wd.Part0 = h; wd.Part1 = p; wd.Parent = p
		p.Parent = b
	end
	for _, p in b:GetDescendants() do if p:IsA("BasePart") then p.Anchored = true end end
	T.ground(b, cf)
	return b
end

function T.golem(parent: Instance, kind: string, cls: string, cf: CFrame): Model?
	local Catalog = require(RS.Shared.GolemCatalog)
	local GM = require(RS.Shared.GolemModel)
	local def = Catalog.get(kind)
	local pa = RS:FindFirstChild("PlotAssets")
	local pp = workspace:FindFirstChild("PlotPrefabs")
	local added = {}
	if def and pa and pp then
		for _, n in { def.model, def.pickaxe, def.sword, def.box } do
			if n and not pa:FindFirstChild(n) and pp:FindFirstChild(n) then local c = pp[n]:Clone(); c.Parent = pa; table.insert(added, c) end
		end
	end
	local m = GM.build(kind, cls)
	for _, c in added do c:Destroy() end
	if not m then return nil end
	m.Parent = parent
	T.ground(m, cf)
	return m
end

function T.pose(rig: Model, joints: { [string]: CFrame })
	for name, rot in joints do
		local j = rig:FindFirstChild(name, true)
		if j and j:IsA("Motor6D") then
			if j:GetAttribute("BaseC0") == nil then j:SetAttribute("BaseC0", j.C0) end
			j.C0 = (j:GetAttribute("BaseC0") :: CFrame) * rot
		end
	end
end

-- поворот кінцівки анкерованого R15 (AnimationConstraint не дають ставити C0): parts крутяться навколо світової точки attachment
function T.limb(rig: Model, parts: { string }, pivotAtt: string, rot: CFrame)
	local att = rig:FindFirstChild(pivotAtt, true) :: Attachment
	local pv = att.WorldPosition
	local base = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local r = base.CFrame.Rotation
	for _, n in parts do
		local p = rig:FindFirstChild(n) :: BasePart
		if p then
			local rel = CFrame.new(pv) * r * rot * r:Inverse() * CFrame.new(-pv)
			p.CFrame = rel * p.CFrame
			for _, acc in rig:GetChildren() do
				local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
				local w = h and h:FindFirstChild("AccessoryWeld")
				if w and (w :: Weld).Part1 == p then (h :: BasePart).CFrame = rel * (h :: BasePart).CFrame end
			end
		end
	end
end
T.ARM_R = { "RightUpperArm", "RightLowerArm", "RightHand" }
T.ARM_L = { "LeftUpperArm", "LeftLowerArm", "LeftHand" }

function T.noBlur(on: boolean)
	local dof = game:GetService("Lighting"):FindFirstChild("DepthOfField")
	if not dof then return end
	if on then
		if dof:GetAttribute("ThumbWas") == nil then dof:SetAttribute("ThumbWas", dof.Enabled) end
		dof.Enabled = false
	else
		local was = dof:GetAttribute("ThumbWas")
		if was ~= nil then dof.Enabled = was; dof:SetAttribute("ThumbWas", nil) end
	end
end

return T
