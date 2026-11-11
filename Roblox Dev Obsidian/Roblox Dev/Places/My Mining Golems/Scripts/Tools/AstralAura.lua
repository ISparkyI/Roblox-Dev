-- Astral Golem: аура (світло, зоряний пил), хитання частин кірки й меча (GolemAnimator v3.4), іскри в скрині.
-- Викликати після GolemBuilder.build("Astral", …): require(ServerStorage.NicheTools.AstralAura)()
return function()
	local pp = workspace.PlotPrefabs
	local m = pp.AstralGolem
	local function motes(part, name, rate, size, life, speed, c1, c2)
		local pe = Instance.new("ParticleEmitter")
		pe.Name = name
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(c1, c2); pe.LightEmission = 1; pe.LightInfluence = 0
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(life * 0.6, life); pe.Rate = rate; pe.Speed = NumberRange.new(speed * 0.5, speed)
		pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, 0.6, 0); pe.Drag = 1
		pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-90, 90)
		pe.Parent = part
		return pe
	end
	local cyan, mag = Color3.fromRGB(110, 225, 255), Color3.fromRGB(255, 90, 220)
	local core = m:FindFirstChild("GalaxyCore", true)
	local l = Instance.new("PointLight")
	l.Name = "StarLight"; l.Color = Color3.fromRGB(140, 200, 255); l.Brightness = 0.9; l.Range = 11; l.Shadows = false; l.Parent = core
	motes(core, "Stardust", 6, 0.4, 2, 2, cyan, mag)
	for _, j in ipairs({ "KneeOrb_R", "KneeOrb_L", "ElbowOrb_R", "ElbowOrb_L", "ShoulderOrb_R", "ShoulderOrb_L" }) do
		local p = m:FindFirstChild(j, true)
		if p then motes(p, "JointDust", 1.5, 0.22, 0.9, 0.5, cyan, cyan) end
	end
	m:SetAttribute("Aura", "stars"); m:SetAttribute("MagicJoints", true)
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
	local pk, sw, bx = pp.AstralPickaxe, pp.AstralSword, pp.AstralCarryBox
	wob(pk, { "HandleTop" }, 0.06, 3, 0)
	wob(pk, { "Head", "HeadBand" }, 0.1, 3, 1.3)
	wob(pk, { "Pick1", "Pick2", "Pick3", "Pick4", "PickEdge1", "PickEdge2" }, 0.08, 3, 2.4)
	wob(pk, { "SignMoon1", "SignMoon2", "SignMoon3", "SignDiamond", "SignCore" }, 0.12, 3, 3.6)
	for i = 1, 3 do wob(sw, { "Shard" .. i, "ShardCore" .. i }, 0.1, 3.4, i * 1.1) end
	wob(sw, { "SwordTip", "ShardCore4" }, 0.1, 3.4, 4.4)
	local fl = bx:FindFirstChild("FloorRaised", true)
	local pe = motes(fl, "StoneMagic", 5, 0.28, 1.2, 0.6, cyan, mag)
	pe.Acceleration = Vector3.new(0, 2.5, 0); pe.SpreadAngle = Vector2.new(25, 25); pe.EmissionDirection = Enum.NormalId.Top
end
