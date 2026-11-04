--!nonstrict
-- NicheLOD — оптимізація для телефонів (v2.1, 03.11.2026; v2.1 — ще й BillboardGui). Лише на клієнті, сервер нічого не знає.
-- Що вимикає в «далеких» нішах: світло (PointLight / SpotLight / SurfaceLight), частинки (ParticleEmitter)
--   і табла — SurfaceGui (у PlayerGui з Adornee у ніші та всередині ніші): у далекій ніші вони не малюються.
-- Відстань рахуємо від ГРАВЦЯ (HumanoidRootPart), а не від камери; перевірка раз на STEP с, змінюємо лише при зміні стану.
-- Ніша «близька», якщо:
--   * гравець стоїть у ній (над її підлогою Floor/NicheFloor + MARGIN) — своя ніша (чи чужа, куди зайшов);
--   * або гравець ближче NEAR_ON до її входу (деталь Anchor) — напр. сусід навпроти, коли підійшов до коридору.
--   Далеко — далі NEAR_OFF (гістерезис, щоб не мигало на межі).
-- Атрибут ніші LODNear (клієнт): табла зі своєю побудовою (MapBoard, PlotStatsClient) далеких ніш взагалі не будують.
-- Вимкнене до нас (Enabled = false) не чіпаємо: пам'ятаємо й вертаємо лише те, що вимкнули самі.
-- Освітлення ніш (03.11.2026 v3): без джерел світла — Lighting.GlobalShadows = false (без тіней, усе рівно світле),
--   OutdoorAmbient c6c2ba, Ambient b0aca6, EnvironmentDiffuseScale 0.25. Декоративні лампи не світять.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NEAR_ON, NEAR_OFF = 45, 60 -- стадів від гравця до входу ніші (вхід сусіда навпроти ≈ 60 від свого)
local MARGIN = 6                 -- стадів навколо підлоги ніші
local STEP = 2                   -- с між перевірками

local function isFx(d: Instance): boolean
	-- 03.11.2026: і BillboardGui (таблички плотів, вивіски) — їхній текст щокадру перемальовується в новому розмірі (телефони:
	--   переповнення атласу шрифтів → зникають/мерехтять цифри); HPBar руди не чіпаємо (його вмикає сам PlotClient)
	return d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("SurfaceGui") or (d:IsA("BillboardGui") and d.Name ~= "HPBar")
end

type St = { far: boolean, off: { [Instance]: boolean } }
local states: { [Instance]: St } = {} -- 04.11.2026: НЕ слабкі ключі (GC губив стан ніші й список вимкненого — щось могло не ввімкнутись)

-- ніша, якій належить об'єкт (сам у ніші або SurfaceGui з Adornee в ніші)
local function nicheOf(d: Instance): Instance?
	local f = workspace:FindFirstChild("Niches")
	if not f then return nil end
	local x: Instance? = d
	if (d:IsA("SurfaceGui") or d:IsA("BillboardGui")) and d.Adornee then x = d.Adornee end
	while x and x.Parent and x.Parent ~= f do x = x.Parent end
	return (x and x.Parent == f) and x or nil
end

local function off(st: St, d: Instance)
	if (d :: any).Enabled then (d :: any).Enabled = false; st.off[d] = true end
end

local function setFar(n: Instance, st: St, far: boolean)
	if st.far == far then return end
	st.far = far
	n:SetAttribute("LODNear", not far) -- лише в цього гравця: MapBoard / PlotStatsClient не будують табла далеких ніш
	if far then
		for _, d in n:GetDescendants() do if isFx(d) then off(st, d) end end
		for _, g in playerGui:GetChildren() do
			if (g:IsA("SurfaceGui") or g:IsA("BillboardGui")) and g.Adornee and g.Adornee:IsDescendantOf(n) then off(st, g) end
		end
	else
		for d in st.off do if d.Parent then (d :: any).Enabled = true end end
		table.clear(st.off)
	end
end

local function stateOf(n: Instance): St
	local st = states[n]
	if st then return st end
	st = { far = false, off = {} }
	states[n] = st
	n.DescendantAdded:Connect(function(d)
		if isFx(d) then task.defer(function() if st.far and d.Parent then off(st, d) end end) end
	end)
	n.DescendantRemoving:Connect(function(d) st.off[d] = nil end)
	return st
end

-- табло, що з'являються пізніше (скрипти табел будують SurfaceGui у PlayerGui й ставлять Adornee)
playerGui.ChildAdded:Connect(function(g)
	if not (g:IsA("SurfaceGui") or g:IsA("BillboardGui")) then return end
	task.delay(0.2, function()
		local n = g.Parent and nicheOf(g)
		local st = n and states[n]
		if st and st.far then off(st, g) end
	end)
end)

local function over(p: Vector3, floor: BasePart): boolean
	local l = floor.CFrame:PointToObjectSpace(p)
	return math.abs(l.X) <= floor.Size.X / 2 + MARGIN and math.abs(l.Z) <= floor.Size.Z / 2 + MARGIN
end

local function step()
	local f = workspace:FindFirstChild("Niches")
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not f or not hrp then return end
	local pos = (hrp :: BasePart).Position
	for _, n in f:GetChildren() do
		local fl = n:FindFirstChild("Floor")
		local floor = fl and fl:FindFirstChild("NicheFloor")
		local anchor = n:FindFirstChild("Anchor")
		if floor and floor:IsA("BasePart") and anchor and anchor:IsA("BasePart") then
			local st = stateOf(n)
			local inside = over(pos, floor)
			local d = ((anchor.Position - pos) * Vector3.new(1, 0, 1)).Magnitude
			if st.far and (inside or d < NEAR_ON) then setFar(n, st, false)
			elseif not st.far and not inside and d > NEAR_OFF then setFar(n, st, true) end
		end
	end
end

task.spawn(function()
	while true do
		local ok, err = pcall(step)
		if not ok then warn("NicheLOD: " .. tostring(err)) end
		task.wait(STEP)
	end
end)
