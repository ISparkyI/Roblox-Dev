-- Chrono Golem: аура (м'яке фіолетове світло, піщинки часу), хитання шестерень кірки й «стрілки» меча, іскри часу в скрині.
-- Викликати після GolemBuilder.build("Chrono", …): require(ServerStorage.NicheTools.ChronoAura)()
return function()
	local pp = workspace.PlotPrefabs
	local m = pp.ChronoGolem
	local function motes(part, name, rate, size, life, speed, c1, c2)
		local pe = Instance.new("ParticleEmitter")
		pe.Name = name
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(c1, c2); pe.LightEmission = 0.6; pe.LightInfluence = 0
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(life * 0.6, life); pe.Rate = rate; pe.Speed = NumberRange.new(speed * 0.5, speed)
		pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, -0.4, 0); pe.Drag = 1
		pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-60, 60)
		pe.Parent = part
		return pe
	end
	local violet, gold = Color3.fromRGB(130, 120, 255), Color3.fromRGB(242, 200, 90)
	local sand = m:FindFirstChild("SandBot", true)
	if sand then
		local l = Instance.new("PointLight")
		l.Name = "TimeLight"; l.Color = Color3.fromRGB(150, 140, 255); l.Brightness = 0.7; l.Range = 9; l.Shadows = false; l.Parent = sand
		motes(sand, "TimeSand", 5, 0.3, 1.8, 1.2, gold, violet)
	end
	local hub = m:FindFirstChild("DialHub", true)
	if hub then motes(hub, "DialDust", 2, 0.22, 1.2, 0.6, violet, violet) end
	for _, j in ipairs({ "GearHub_R", "GearHub_L" }) do
		local p = m:FindFirstChild(j, true)
		if p then motes(p, "GearDust", 1.2, 0.2, 0.9, 0.5, gold, violet) end
	end
	m:SetAttribute("Aura", "time"); m:SetAttribute("MagicJoints", true)
	local U = Vector3.new(0, 0.1215, 0.99259)
	local function wob(model, names, amp, speed, phase)
		for _, n in ipairs(names) do
			local p = model:FindFirstChild(n, true)
			if p then
				p:SetAttribute("WobbleAxis", U); p:SetAttribute("WobbleAmp", amp)
				p:SetAttribute("WobbleSpeed", speed); p:SetAttribute("WobblePhase", phase)
			end
		end
	end
	local pk, sw, bx = pp.ChronoPickaxe, pp.ChronoSword, pp.ChronoCarryBox
	wob(pk, { "SmallGear", "SmallGearB" }, 0.1, 2.5, 0)
	wob(pk, { "PickGlow" }, 0.08, 2.5, 1.5)
	wob(sw, { "PendulumRod", "SwordPommel", "PommelCore" }, 0.12, 2, 0)
	wob(sw, { "BladeSpade", "SpadeCore" }, 0.06, 2, 2)
	local fl = bx:FindFirstChild("FloorRaised", true)
	if fl then
		local pe = motes(fl, "TimeSpark", 4, 0.26, 1.2, 0.6, gold, violet)
		pe.Acceleration = Vector3.new(0, 2.2, 0); pe.SpreadAngle = Vector2.new(25, 25); pe.EmissionDirection = Enum.NormalId.Top
	end
end
