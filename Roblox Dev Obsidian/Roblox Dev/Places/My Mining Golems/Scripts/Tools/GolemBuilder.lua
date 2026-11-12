-- GolemBuilder (Claude, 01.11.2026): збирає голема з модуля GolemData (формат Clay) у Workspace/PlotPrefabs:
-- <Name>Golem (клон ClayGolem: GolemAnimator, MineTarget), <Name>Pickaxe / <Name>Sword (групи блоків, півот = кулак Fist_L),
-- <Name>CarryBox (клон ClayCarryBox, перефарбований за boxCols, або власний ящик з блоків group = "Box"). Кольори з D.neon = true будуються з Material = Neon. build(name, kind, x, src, boxCols) — один запис в історії.
local B = {}
function B.build(name: string, kind: string, X: number, SRC: string, boxCols: {[string]: string})
	local CHS = game:GetService("ChangeHistoryService")
	local rec = CHS:TryBeginRecording("Build " .. name .. "Golem")
	local PF = workspace.PlotPrefabs
	for _, n in { name .. "Golem", name .. "Pickaxe", name .. "Sword", name .. "CarryBox" } do
		local o = PF:FindFirstChild(n); if o then o:Destroy() end
	end
	local FLIP = CFrame.Angles(0, math.pi, 0)
	local clay = PF.ClayGolem
	local g = clay:Clone(); g.Name = name .. "Golem"
	local tmpl = clay.Torso:Clone()
	for _, c in g:GetChildren() do if c:IsA("BasePart") and c.Name ~= "Root" then c:Destroy() end end
	g.GolemData.Source = SRC
	g:SetAttribute("PrefabOf", name .. "Golem"); g:SetAttribute("GolemKind", kind); g:SetAttribute("Version", "v1")
	local rcf = clay.Root.CFrame
	g:PivotTo(CFrame.new(X, rcf.Y, rcf.Z) * rcf.Rotation)
	local D = require(g.GolemData)
	local root = g.Root
	local function C(hex) return Color3.fromHex(hex) end
	local NEON = D.neon or {}
	local ALPHA = D.alpha or {} -- 02.11.2026 (Phantom): колір -> Transparency (напівпрозорі деталі)
	local function mat(p, col) if NEON[col] then p.Material = Enum.Material.Neon; p.MaterialVariant = "" end; if ALPHA[col] then p.Transparency = ALPHA[col] end end
	local function W(b) return root.CFrame * FLIP * CFrame.new(b.cf.Position * 0.5) * b.cf.Rotation end
	local fistW
	for _, b in D.blocks do
		if b.name == "Fist_L" and not b.group then fistW = W(b) end
		if not b.group then
			local p = tmpl:Clone(); p.Name = b.name; p.Size = b.s * 0.5; p.CFrame = W(b); p.Color = C(D.colors[b.col]); mat(p, b.col); p:SetAttribute("Bone", b.bone); p.Parent = g
		end
	end
	g.Parent = PF
	local function mkItem(nm, group, pos, src)
		local m = Instance.new("Model"); m.Name = nm
		local pivot = CFrame.new(pos) * fistW.Rotation
		local ptm = src:FindFirstChildWhichIsA("BasePart")
		for _, b in D.blocks do if b.group == group then
			local p = ptm:Clone(); for _, ch in p:GetChildren() do ch:Destroy() end
			p.Name = b.name; p.Size = b.s * 0.5; p.Color = C(D.colors[b.col]); p.CFrame = pivot * fistW:Inverse() * W(b); mat(p, b.col); p.Parent = m
		end end
		for _, a in src:GetDescendants() do if a:IsA("Attachment") then
			local tgt = m:FindFirstChild(a.Parent.Name); if tgt then a:Clone().Parent = tgt end
		end end
		for k, v in src:GetAttributes() do m:SetAttribute(k, v) end
		m:SetAttribute("PrefabOf", nm); m.WorldPivot = pivot; m.Parent = PF
		return m
	end
	local pk = PF.ClayPickaxe:GetPivot().Position
	local sw = PF.ClaySword:GetPivot().Position
	local pick = mkItem(name .. "Pickaxe", "Pickaxe", Vector3.new(X, pk.Y, pk.Z), PF.ClayPickaxe)
	local sword = mkItem(name .. "Sword", "Sword", Vector3.new(X, sw.Y, sw.Z), PF.ClaySword)
	local box = PF.ClayCarryBox:Clone(); box.Name = name .. "CarryBox"; box:SetAttribute("PrefabOf", name .. "CarryBox")
	local bp = PF.ClayCarryBox:GetPivot()
	box:PivotTo(CFrame.new(X, bp.Y, bp.Z) * bp.Rotation)
	local own = false
	for _, b in D.blocks do if b.group == "Box" then own = true break end end
	if own then -- власний ящик (Ironclad+): блоки group = "Box" у стадах відносно півота (центр дна); Load і атрибути — від ClayCarryBox
		local ptm = box:FindFirstChild("WallF"):Clone()
		for _, c in box:GetChildren() do if c:IsA("BasePart") then c:Destroy() end end
		local piv = box:GetPivot()
		for _, b in D.blocks do if b.group == "Box" then
			local p = ptm:Clone(); for _, ch in p:GetChildren() do ch:Destroy() end
			p.Name = b.name; p.Size = b.s; p.CFrame = piv * b.cf; p.Color = C(D.colors[b.col]); mat(p, b.col); p.Parent = box
		end end
		box.PrimaryPart = box:FindFirstChild("Bottom") -- півот ClayCarryBox = центр Bottom, тож Bottom у (0,0,0) зберігає його
	else
		for n, c in boxCols do local p = box:FindFirstChild(n); if p then p.Color = C(D.colors[c]); mat(p, c) end end
	end
	box.Parent = PF
	if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
	local n = 0 for _, c in g:GetChildren() do if c:IsA("BasePart") then n += 1 end end
	return string.format("golem parts %d pick %d sword %d box %d", n, #pick:GetChildren(), #sword:GetChildren(), #box:GetDescendants())
end
return B
