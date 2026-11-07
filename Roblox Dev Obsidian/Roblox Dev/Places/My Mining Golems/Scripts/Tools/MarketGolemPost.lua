-- MarketGolemPost (Claude, 05.11.2026): доводить префаби ексклюзів Marketplace після GolemBuilder.build: GolemAnimator v4 (NicheTools/GolemAnimatorV4),
-- матеріали за кольорами палітри, форми деталей, світло, частинки, атрибути анімацій деталей предметів і ящика.
-- Виклик: require(NicheTools.MarketGolemPost).build("Cyborg", "cyborg", X, specJSON) — дані з NicheTools/<Name>Data, spec — з mkx/gen.py (<Name>.json).
local HS = game:GetService("HttpService")
local P = {}
local PRE = {
	jet = function(e: ParticleEmitter)
		e.Color = ColorSequence.new(Color3.fromHex("7ff6ff"), Color3.fromHex("ff3df2"))
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new(0.1, 1)
		e.Lifetime = NumberRange.new(0.25, 0.45)
		e.Rate = 14
		e.Speed = NumberRange.new(4, 7)
		e.SpreadAngle = Vector2.new(12, 12)
		e.EmissionDirection = Enum.NormalId.Bottom
	end,
	dust = function(e: ParticleEmitter)
		e.Color = ColorSequence.new(Color3.fromHex("fff1c4"))
		e.LightEmission = 0.7
		e.Size = NumberSequence.new(0.08)
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.4), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(2, 3)
		e.Rate = 4
		e.Speed = NumberRange.new(0.1, 0.4)
		e.SpreadAngle = Vector2.new(180, 180)
	end,
	glint = function(e: ParticleEmitter)
		e.Color = ColorSequence.new(Color3.fromHex("fff3c4"))
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new(0)
		e.Lifetime = NumberRange.new(0.35, 0.5)
		e.Rate = 2.5
		e.Speed = NumberRange.new(0)
		e.Rotation = NumberRange.new(0, 360)
	end,
}
local function v3(a: any): any
	if type(a) == "table" then return Vector3.new(a[1], a[2], a[3]) end
	return a
end
function P.post(name: string, spec: any): string
	local PF = workspace.PlotPrefabs
	local g = PF:FindFirstChild(name .. "Golem") :: Model
	local pick, sword, box = PF:FindFirstChild(name .. "Pickaxe"), PF:FindFirstChild(name .. "Sword"), PF:FindFirstChild(name .. "CarryBox")
	g.GolemAnimator.Source = game.ServerStorage.NicheTools.GolemAnimatorV4.Source
	g:SetAttribute("Version", "v4")
	local D = require(g.GolemData:Clone()) :: any
	local colOf = {}
	for k, hex in D.colors do colOf[Color3.fromHex(hex):ToHex()] = k end
	local n = 0
	for _, m in { g, pick, sword, box } do
		if m then
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					-- матеріал як у всіх големів гри: Plastic + MaterialVariant StudsSmall (неон — без змін)
					if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Plastic; p.MaterialVariant = "StudsSmall"; p.Reflectance = 0; n += 1 end
					local sh = spec.shapes[p.Name]
					if sh and (m == g or m == box) then (p :: Part).Shape = (Enum.PartType :: any)[sh] end
				end
			end
		end
	end
	local function target(l: any): BasePart?
		local m = if l.box then box elseif l.item == "Sword" then sword elseif l.item == "Pickaxe" then pick else g
		return m and m:FindFirstChild(l.part, true) :: BasePart?
	end
	for _, l in spec.lights do
		local p = target(l)
		if p then
			for _, o in p:GetChildren() do if o:IsA("Light") then o:Destroy() end end
			local lt = Instance.new(l.kind) :: any
			lt.Color = Color3.fromHex(l.color); lt.Range = l.range; lt.Brightness = l.brightness; lt.Shadows = false
			if l.kind == "SpotLight" then lt.Angle = l.angle or 45; lt.Face = (Enum.NormalId :: any)[l.face or "Front"] end
			lt.Parent = p
			if l.max then p:SetAttribute("LightMax", l.max) end
		end
	end
	for _, e in spec.particles do
		local p = target(e)
		if p then
			for _, o in p:GetChildren() do if o:IsA("ParticleEmitter") then o:Destroy() end end
			local pe = Instance.new("ParticleEmitter")
			PRE[e.preset](pe)
			pe.Parent = p
		end
	end
	for _, m in { pick, sword } do
		if m then
			for pn, attrs in spec.itemAttrs do
				local p = m:FindFirstChild(pn)
				if p then for k, v in attrs do p:SetAttribute(k, v3(v)) end end
			end
		end
	end
	if box then
		for pn, attrs in spec.boxAttrs do
			local p = box:FindFirstChild(pn)
			if p then for k, v in attrs do p:SetAttribute(k, v3(v)) end end
		end
	end
	return "post ok, materials " .. n
end
function P.build(name: string, kind: string, X: number, specJSON: string): string
	local B = require(game.ServerStorage.NicheTools.GolemBuilder:Clone()) :: any
	local src = (game.ServerStorage.NicheTools :: any)[name .. "Data"].Source
	local r = B.build(name, kind, X, src, {})
	local out = r .. " | " .. P.post(name, HS:JSONDecode(specJSON))
	-- ексклюз одного класу (GolemCatalog only): зайві префаби GolemBuilder (інших класів) прибираємо
	local g = (require(game.ReplicatedStorage.Shared.GolemCatalog:Clone()) :: any).GOLEMS[kind]
	local keep = g and g.only and ({ miner = "Pickaxe", carrier = "CarryBox", warrior = "Sword" })[g.only]
	if keep then
		for _, s in { "Pickaxe", "Sword", "CarryBox" } do
			local m = workspace.PlotPrefabs:FindFirstChild(name .. s)
			if s ~= keep and m then m:Destroy() end
		end
	end
	return out
end
return P
