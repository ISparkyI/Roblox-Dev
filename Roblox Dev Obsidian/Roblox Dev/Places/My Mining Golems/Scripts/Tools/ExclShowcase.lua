-- Тестова вітрина ексклюзивів (лише Play у Studio, сервер): три големи в ряд перед гравцем із предметами,
-- анімації по черзі: Idle → Walk → Run → Mine → Pick → Carry. Запуск: require(NicheTools.ExclShowcase:Clone()).run()
local S = {}

function S.run(): string
	local Players = game:GetService("Players")
	local t0 = os.clock()
	while #Players:GetPlayers() == 0 and os.clock() - t0 < 20 do task.wait(0.5) end
	local p = Players:GetPlayers()[1]
	if not p then return "no player" end
	local ch = p.Character or p.CharacterAdded:Wait()
	local hrp = ch:WaitForChild("HumanoidRootPart", 10) :: BasePart
	local C = require(game.ReplicatedStorage.Shared.GolemCatalog) :: any
	local A = game.ReplicatedStorage:WaitForChild("PlotAssets", 10) :: any
	local old = workspace:FindFirstChild("ExclTest") if old then old:Destroy() end
	local F = Instance.new("Folder") F.Name = "ExclTest" F.Parent = workspace
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
	local side = look:Cross(Vector3.yAxis)
	local center = hrp.Position + look * 16
	local rp = RaycastParams.new() rp.FilterDescendantsInstances = { ch, F } rp.FilterType = Enum.RaycastFilterType.Exclude
	local defs = { { "CyborgGolem", "cyborg", "miner", "Cyborg" }, { "LampMinerGolem", "lampminer", "carrier", "Lamp Miner" }, { "SpartanGolem", "spartan", "warrior", "Spartan" } }
	local G = {}
	local stash = Instance.new("Folder") stash.Name = "ExclStash" stash.Parent = game.ServerStorage
	local box: any = nil
	for i, d in defs do
		local m = A[d[1]]:Clone() m:SetAttribute("Kind", d[2])
		local pos = center + side * ((i - 2) * 10)
		local hit = workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), rp)
		local y = hit and hit.Position.Y or (hrp.Position.Y - 3)
		for _, b in m:GetDescendants() do if b:IsA("BasePart") then b.Anchored = true end end
		m.Parent = F
		m:PivotTo(CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(pos.X, y, pos.Z) - look))
		local cf, sz = m:GetBoundingBox() m:PivotTo(m:GetPivot() + Vector3.new(0, y - (cf.Position.Y - sz.Y / 2), 0))
		C.applyClassItems(m, d[3], nil, d[2])
		if d[3] == "carrier" then
			box = A.LampMinerCarryBox:Clone() box.Name = "CarryBox"
			for _, x in box:GetDescendants() do if x:IsA("BasePart") then x.Anchored = true x.CanCollide = false end end
			box.Parent = stash
		end
		m:SetAttribute("State", "Idle")
		local bg = Instance.new("BillboardGui") bg.Size = UDim2.fromOffset(260, 60) bg.StudsOffset = Vector3.new(0, 9.5, 0)
		bg.AlwaysOnTop = true bg.Adornee = m:FindFirstChild("Root") :: any bg.Name = "TestLabel"
		local tl = Instance.new("TextLabel") tl.Size = UDim2.fromScale(1, 1) tl.BackgroundTransparency = 1 tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextStrokeTransparency = 0 tl.Font = Enum.Font.GothamBold tl.TextScaled = true tl.Text = d[4] tl.Parent = bg bg.Parent = m
		;(m :: any).GolemAnimator.Enabled = true -- у префабі вимкнений (на ділянці вмикає клієнт)
		G[i] = { m = m, name = d[4] }
	end
	local phases = {
		{ "Idle", 4, function(m, i) m:SetAttribute("State", "Idle") end },
		{ "Walk", 5, function(m, i) m:SetAttribute("State", "Walk") end },
		{ "Run", 5, function(m, i) m:SetAttribute("State", "Run") end },
		{ "Mine / Attack", 8, function(m, i) m:SetAttribute("State", "Mine") end },
		{ "Pick", 6, function(m, i) m:SetAttribute("State", "Idle") m:SetAttribute("PickLoop", true) end },
		{ "Carry", 6, function(m, i) m:SetAttribute("State", "Walk") m:SetAttribute("Carry", true) if i == 2 then box.Parent = m end end },
	}
	task.spawn(function()
		while F.Parent do
			for _, ph in phases do
				if not F.Parent then break end
				for i, g in G do
					g.m:SetAttribute("Carry", false) g.m:SetAttribute("PickLoop", false)
					ph[3](g.m, i)
					g.m.TestLabel.TextLabel.Text = g.name .. "\n" .. ph[1]
				end
				local t = os.clock()
				while os.clock() - t < ph[2] do
					for _, g in G do if g.m:GetAttribute("PickLoop") then g.m:SetAttribute("Load", (g.m:GetAttribute("Load") or 0) + 1) end end
					task.wait(1.2)
				end
				if box and box.Parent ~= stash then box.Parent = stash end
				for _, g in G do g.m:SetAttribute("Load", 0) end
			end
		end
	end)
	return "showcase started"
end

return S
