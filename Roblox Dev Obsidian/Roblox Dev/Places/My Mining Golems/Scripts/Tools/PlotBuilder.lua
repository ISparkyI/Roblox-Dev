--!strict
-- PlotBuilder v2 — збирає модель плоту (зона фарму) для ніші: «зламана» кам'яна платформа з плиток і каміння,
-- нерівний бортик, ящик-приймальник, напис над центром плоту. Точок руди немає: сервер ставить руду у випадкові місця.
-- Де: ServerStorage/NicheTools/PlotBuilder. Запускати з командного рядка / MCP у режимі Edit:
--   require(game.ServerStorage.NicheTools.PlotBuilder).Apply(nicheModel)  -- замінює плити plotN / Plots у ніші (бекап у NicheBackup)
-- Координати плоту: X — праворуч від входу в нішу, Z — до входу (вперед до гравця). side = -1 (лівий ряд) / 1 (правий ряд):
-- ящик завжди у внутрішньому (до доріжки) передньому куті.
-- Атрибути моделі плоту: PlotIndex, Side, FloorUp (висота поверхні плиток над низом плити), OreHalf (руда спавниться в ±OreHalf),
-- CrateX / CrateZ / CrateR (зона ящика в координатах плоту, туди руда не ставиться).
local B = {}

B.SIZE = 44          -- плита
B.FLOOR_UP = 1.99    -- верх кам'яної підлоги ніші над Anchor
B.BASE_H = 0.8       -- товщина темної основи під плитками
B.TILE_H = 0.6       -- товщина плиток
B.ORE_HALF = 15.5    -- руда — не ближче ~6,5 стада до бортика
B.CRATE = Vector3.new(17.2, 0, 17.2)
B.CRATE_SCALE = 0.95
B.DROP = Vector3.new(13.4, 0, 13.4)

local C = Color3.fromHex
local TILE_COLS = { "7d8693", "75808c", "858e9a", "6f7884", "8a939e" }
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: string, mv: string?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = C(color)
	p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Plastic
	if mv then p.MaterialVariant = mv end
	p.Parent = parent
	return p
end

-- розбити відрізок [a, b] на шматки довжиною lo..hi
local function cuts(r: Random, a: number, b: number, lo: number, hi: number): { number }
	local out = { a }
	local x = a
	while b - x > hi do
		x += lo + r:NextNumber() * (hi - lo)
		table.insert(out, x)
	end
	table.insert(out, b)
	return out
end

function B.Build(cf: CFrame, index: number, side: number): Model
	local r = Random.new(index * 1013 + (side + 2) * 71)
	local m = Instance.new("Model")
	m.Name = "Plot" .. index
	local S, H, T = B.SIZE, B.BASE_H, B.TILE_H
	local function X(x: number): number return x * (side == -1 and 1 or -1) end
	local function deg(a: number): number return math.rad(a) end
	m:SetAttribute("PlotIndex", index)
	m:SetAttribute("Side", side)
	m:SetAttribute("FloorUp", H + T)
	m:SetAttribute("OreHalf", B.ORE_HALF)
	m:SetAttribute("CrateX", X(B.CRATE.X)); m:SetAttribute("CrateZ", B.CRATE.Z); m:SetAttribute("CrateR", 7.5)

	-- темна основа (видно в щілинах і дірках)
	local base = part(m, "Base", Vector3.new(S, H, S), cf * CFrame.new(0, H / 2, 0), "3b4149", "Studs")
	m.PrimaryPart = base
	local tiles = Instance.new("Folder"); tiles.Name = "Floor"; tiles.Parent = m

	-- плитки: ряди різної ширини, у ряду — плитки різної довжини; зсув, поворот 2–3°, різна висота й колір
	local half = S / 2 - 0.15
	local rows = cuts(r, -half, half, 3.6, 6.4)
	for i = 1, #rows - 1 do
		local z0, z1 = rows[i], rows[i + 1]
		local cols = cuts(r, -half, half, 3.4, 7.2)
		for j = 1, #cols - 1 do
			local x0, x1 = cols[j], cols[j + 1]
			local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
			local w, d = x1 - x0, z1 - z0
			local edge = math.max(math.abs(cx), math.abs(cz)) > B.ORE_HALF + 2
			local roll = r:NextNumber()
			if edge and roll < 0.09 then
				-- дірка: плитки немає, всередині уламки й (іноді) кристалики
				for k = 1, r:NextInteger(2, 4) do
					local s = 0.5 + r:NextNumber() * 0.9
					part(tiles, "Rubble", Vector3.new(s, s * 0.7, s * (0.8 + r:NextNumber() * 0.4)),
						cf * CFrame.new(X(cx + (r:NextNumber() - 0.5) * (w - 1.5)), H + s * 0.3, cz + (r:NextNumber() - 0.5) * (d - 1.5))
							* CFrame.Angles(deg(r:NextInteger(-25, 25)), deg(r:NextInteger(0, 359)), deg(r:NextInteger(-25, 25))),
						r:NextNumber() < 0.5 and "5f6974" or "8a929c", "StudsSmall")
				end
				if r:NextNumber() < 0.6 then
					local glow = r:NextNumber() < 0.5 and "5ff3ff" or "c58bff"
					local root = cf * CFrame.new(X(cx), H, cz)
					for k = 1, 3 do
						local h = 0.9 + r:NextNumber() * 1.1
						local cr = part(tiles, "CrystalShard", Vector3.new(0.35, h, 0.35),
							root * CFrame.new((k - 2) * 0.45, h / 2 - 0.1, (r:NextNumber() - 0.5) * 0.6) * CFrame.Angles(deg((k - 2) * 18), deg(r:NextInteger(0, 90)), deg((k - 2) * -14)),
							glow)
						cr.Material = Enum.Material.Neon; cr.Transparency = 0.15; cr.CanCollide = false
					end
					local l = Instance.new("PointLight"); l.Color = C(glow); l.Range = 8; l.Brightness = 0.8; l.Shadows = false
					l.Parent = tiles:GetChildren()[#tiles:GetChildren()]
				end
			elseif roll < 0.16 and w > 4.5 then
				-- тріснута плитка: дві половинки з нерівною щілиною
				local split = x0 + w * (0.35 + r:NextNumber() * 0.3)
				for _, seg in { { x0, split - 0.18 }, { split + 0.18, x1 } } do
					local sw = seg[2] - seg[1] - 0.25
					if sw > 0.6 then
						local hh = T + (r:NextNumber() - 0.5) * 0.2
						part(tiles, "Tile", Vector3.new(sw, hh, d - 0.3),
							cf * CFrame.new(X((seg[1] + seg[2]) / 2), H + hh / 2 - 0.05, cz) * CFrame.Angles(0, deg((r:NextNumber() - 0.5) * 6), 0),
							TILE_COLS[r:NextInteger(1, #TILE_COLS)], "Studs")
					end
				end
			else
				local hh = T + (r:NextNumber() - 0.4) * 0.22
				local dx, dz = (r:NextNumber() - 0.5) * 0.3, (r:NextNumber() - 0.5) * 0.3
				part(tiles, "Tile", Vector3.new(w - 0.22 - r:NextNumber() * 0.25, hh, d - 0.22 - r:NextNumber() * 0.25),
					cf * CFrame.new(X(cx + dx), H + hh / 2 - 0.05, cz + dz) * CFrame.Angles(0, deg((r:NextNumber() < 0.5 and -1 or 1) * (1.5 + r:NextNumber() * 1.5)), 0),
					TILE_COLS[r:NextInteger(1, #TILE_COLS)], "Studs")
			end
		end
	end

	-- бортик з окремих каменів різної висоти й зі зсувом (місцями «відколотий»)
	local rimW = 1.7
	for _, d in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		local segs = cuts(r, -S / 2 - rimW, S / 2 + rimW, 4, 8)
		for k = 1, #segs - 1 do
			local a0, a1 = segs[k], segs[k + 1]
			local len = a1 - a0 - 0.12
			local hgt = 1.5 + r:NextNumber() * 0.6
			if r:NextNumber() < 0.12 then hgt = 0.8 end -- відколотий шматок
			local along = (a0 + a1) / 2
			local off = S / 2 + rimW / 2 + (r:NextNumber() - 0.5) * 0.25
			local pos = d[1] == 0 and Vector3.new(along, hgt / 2, d[2] * off) or Vector3.new(d[1] * off, hgt / 2, along)
			local size = d[1] == 0 and Vector3.new(len, hgt, rimW) or Vector3.new(rimW, hgt, len)
			part(m, "Rim", size, cf * CFrame.new(pos) * CFrame.Angles(0, deg((r:NextNumber() - 0.5) * 3), 0),
				r:NextNumber() < 0.5 and "5f6974" or "566069", "Studs")
		end
	end
	for _, d in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		part(m, "RimCorner", Vector3.new(2.8, 2.6, 2.8), cf * CFrame.new(d[1] * (S / 2 + rimW / 2), 1.3, d[2] * (S / 2 + rimW / 2)) * CFrame.Angles(0, deg(r:NextInteger(-6, 6)), 0), "4b525c", "Studs")
	end
	-- відколоті камені біля бортика (на плитах і зовні) + мох
	for k = 1, 14 do
		local s = 0.6 + r:NextNumber() * 1.1
		local t = r:NextNumber() * 4
		local along = (r:NextNumber() - 0.5) * (S - 4)
		local inset = S / 2 - 1.2 - r:NextNumber() * 2.2
		local px, pz
		if t < 1 then px, pz = along, -inset elseif t < 2 then px, pz = along, inset elseif t < 3 then px, pz = -inset, along else px, pz = inset, along end
		if not (math.abs(X(px) - X(B.CRATE.X)) < 5 and math.abs(pz - B.CRATE.Z) < 5) then
			part(m, "Stone", Vector3.new(s, s * 0.75, s * (0.8 + r:NextNumber() * 0.5)),
				cf * CFrame.new(px, H + T + s * 0.3, pz) * CFrame.Angles(deg(r:NextInteger(-20, 20)), deg(r:NextInteger(0, 359)), deg(r:NextInteger(-20, 20))),
				r:NextNumber() < 0.5 and "5f6974" or "8a929c", "StudsSmall")
		end
	end
	for k = 1, 3 do
		local corner = ({ { -1, -1 }, { -1, 1 }, { 1, -1 } })[k]
		local px, pz = corner[1] * (S / 2 - 2.6), corner[2] * (S / 2 - 2.6)
		local moss = part(m, "Moss", Vector3.new(2.6 + r:NextNumber() * 2, 0.25, 1.6 + r:NextNumber() * 1.6),
			cf * CFrame.new(X(px), H + T + 0.1, pz) * CFrame.Angles(0, deg(r:NextInteger(-30, 30)), 0), "5cb83a", "StudsSmall")
		moss.CanCollide = false
	end

	-- темна плівка закритого плоту (клієнт ховає її, коли плот відкритий)
	local lk = part(m, "LockedTint", Vector3.new(S, 0.1, S), cf * CFrame.new(0, H + T + 0.45, 0), "1d222a")
	lk.Transparency = 0.4; lk.CanCollide = false; lk.CanQuery = false; lk.CanTouch = false; lk.CastShadow = false

	-- ящик-приймальник (менший): носій висипає сюди руду → вона йде в інвентар власника
	local crateSrc = game.ServerStorage:FindFirstChild("PlotCrate", true) :: Model?
	if crateSrc then
		local crate = crateSrc:Clone()
		crate.Name = "Crate"
		crate:ScaleTo(B.CRATE_SCALE)
		local ccf, csz = crate:GetBoundingBox()
		local want = cf * CFrame.new(X(B.CRATE.X), H + T + csz.Y / 2, B.CRATE.Z) * CFrame.Angles(0, math.rad(side == -1 and 12 or -12), 0)
		crate:PivotTo(want * ccf:ToObjectSpace(crate:GetPivot()))
		crate.Parent = m
	end
	local drop = Instance.new("Attachment"); drop.Name = "DropPoint"
	drop.Position = Vector3.new(X(B.DROP.X), H / 2, B.DROP.Z); drop.Parent = base
	local home = Instance.new("Attachment"); home.Name = "HomePoint"
	home.Position = Vector3.new(X(4), H / 2, 6); home.Parent = base

	-- напис над центром плоту
	local lab = part(m, "Label", Vector3.new(1, 1, 1), cf * CFrame.new(0, H + T + 13, 0), "ffffff")
	lab.Transparency = 1; lab.CanCollide = false; lab.CanQuery = false; lab.CanTouch = false
	local bb = Instance.new("BillboardGui"); bb.Name = "PlotLabel"
	bb.Size = UDim2.fromScale(16, 5.5); bb.MaxDistance = 140; bb.LightInfluence = 0; bb.AlwaysOnTop = false
	bb.Parent = lab
	local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
	local function lbl(name: string, y: number, h: number, text: string, col: string, stroke: number)
		local t = Instance.new("TextLabel"); t.Name = name
		t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, h); t.Position = UDim2.fromScale(0, y)
		t.FontFace = HEAVY; t.TextScaled = true; t.Text = text; t.TextColor3 = C(col)
		local s = Instance.new("UIStroke"); s.Color = C("040435"); s.Thickness = stroke; s.Parent = t
		t.Parent = bb
	end
	lbl("Title", 0, 0.62, "PLOT " .. index, "ffffff", 4)
	lbl("Status", 0.62, 0.36, "", "ffd34d", 3)

	for _, f in { "Ores", "Drops", "Golems" } do
		local fo = Instance.new("Folder"); fo.Name = f; fo.Parent = m
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and not d:IsDescendantOf(m:FindFirstChild("Crate") or m) then d.CastShadow = d.Name ~= "LockedTint" end
	end
	return m
end

-- ніша: знайти старі плити plotN (або Plots), визначити порядок 1..6 (ближні → дальні, лівий → правий), замінити
function B.Apply(niche: Model): { string }
	local log = {}
	local anchor = niche:FindFirstChild("Anchor") :: BasePart
	assert(anchor, "немає Anchor у " .. niche:GetFullName())
	local spots = {}
	local old = niche:FindFirstChild("Plots")
	if old then
		for _, p in old:GetChildren() do
			local b = p:IsA("Model") and p:FindFirstChild("Base")
			if b and b:IsA("BasePart") then table.insert(spots, { pos = b.Position, inst = p }) end
		end
	end
	for _, c in niche:GetChildren() do
		if c:IsA("BasePart") and string.match(c.Name, "^plot%d$") then table.insert(spots, { pos = c.Position, inst = c }) end
	end
	assert(#spots == 6, "очікував 6 плотів, знайшов " .. #spots)
	for _, s in spots do
		local l = anchor.CFrame:PointToObjectSpace(s.pos)
		s.depth = -l.Z; s.side = l.X < 0 and -1 or 1
	end
	table.sort(spots, function(a, b)
		if math.abs(a.depth - b.depth) > 5 then return a.depth < b.depth end
		return a.side < b.side
	end)
	local bk = game.ServerStorage:FindFirstChild("NicheBackup") or Instance.new("Folder")
	bk.Name = "NicheBackup"; bk.Parent = game.ServerStorage
	local folder = Instance.new("Folder"); folder.Name = "Plots"
	for i, s in spots do
		local l = anchor.CFrame:PointToObjectSpace(s.pos)
		local cf = anchor.CFrame * CFrame.new(l.X, B.FLOOR_UP, l.Z)
		local m = B.Build(cf, i, s.side)
		m.Parent = folder
		table.insert(log, string.format("%s -> Plot%d (depth %.0f, %s, %d parts)", s.inst.Name, i, s.depth, s.side < 0 and "left" or "right", #m:GetDescendants()))
		if s.inst:IsA("BasePart") then
			local c = s.inst:Clone(); c.Name = niche.Name .. "_" .. s.inst.Name .. "_old"; c.Parent = bk
			s.inst:Destroy()
		end
	end
	if old then old:Destroy() end
	folder.Parent = niche
	return log
end

return B
