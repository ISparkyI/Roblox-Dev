--!strict
-- RobuxStandClient — стенд големів за Robux у нішах (10.11.2026). Конфіг — Shared/RobuxStandConfig.
-- У кожній ніші Niches/*/RollSystem/RobuxStand: голем-майнер (клієнтська модель GolemModel × 0,5, як на стендах ролу),
-- що повільно погойдується вліво-вправо; стенд стоїть рівно, голем повернутий діагонально до важеля (атрибут стенду FaceDirLocal — напрям у просторі стенду).
-- Над ним табличка як після ролу: рідкість, назва, ціна (значок Robux, як біля x2 Money, і число), Speed / Damage відносно Wooden.
-- Кнопка BUY (RobuxBuyPrompt, CustomPrompts, зелена) — вікно оплати Developer Product поточного голема
-- (RobuxStandConfig.OFFERS[i].product; 0 — ще не підключено: над табличкою «COMING SOON»).
-- Голем змінюється кожні ROTATE с за часом сервера (у всіх гравців однаково). Видача — сервер (RobuxStandService).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("RobuxStandConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog"))
local GolemModel = require(RS.Shared:WaitForChild("GolemModel"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))

local player = Players.LocalPlayer
local STAND_SCALE = 0.55 -- 10.11.2026: +10 % (стенд теж ×1,1)
local SWAY_AMP = math.rad(14)   -- погойдування: ±14°
local SWAY_SPEED = 0.7          -- рад/с (повний цикл ≈ 9 с)
local SWAY_DIST = 90            -- далі — не гойдаємо (не рухаємо модель щокадру)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local INK = Color3.fromHex("14161a")
local GREEN = Color3.fromHex("7dff3a")
local YELLOW = Color3.fromHex("ffd23a")

type St = { stand: Model, top: Vector3, idx: number, golem: Model?, k: number, anchor: BasePart?, bb: BillboardGui?,
	rar: TextLabel?, name: TextLabel?, price: TextLabel?, speed: TextLabel?, dmg: TextLabel?, soon: TextLabel?,
	prompt: ProximityPrompt?, base: number, foot: number }
local stands: { [Model]: St } = {}

-- верх плити — лише за деталями самого стенду (без якорів кнопки / таблички й голема)
local function standTop(stand: Model): Vector3
	local y = -math.huge
	for _, d in stand:GetChildren() do
		if d:IsA("BasePart") and not d.Name:find("Anchor") then
			local cf, sz = d.CFrame, d.Size
			local h = math.abs(cf.XVector.Y) * sz.X / 2 + math.abs(cf.YVector.Y) * sz.Y / 2 + math.abs(cf.ZVector.Y) * sz.Z / 2
			y = math.max(y, cf.Y + h)
		end
	end
	local p = stand:GetPivot().Position
	return Vector3.new(p.X, if y > -math.huge then y else p.Y, p.Z)
end

local function label(parent: Instance, order: number, h: number, color: Color3, font: Font): TextLabel
	local t = Instance.new("TextLabel")
	t.LayoutOrder = order; t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, h); t.FontFace = font; t.TextScaled = true
	t.Text = ""; t.TextColor3 = color
	local s = Instance.new("UIStroke"); s.Color = INK; s.Thickness = 2.4; s.LineJoinMode = Enum.LineJoinMode.Round; s.Parent = t
	t.Parent = parent
	return t
end

-- ціна: рядок як «FREE» / «$…» на табличці ролу — значок Robux (як біля x2 Money) і число
local function priceLine(parent: Instance, order: number): TextLabel
	local row = Instance.new("Frame")
	row.Name = "Price"; row.LayoutOrder = order; row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 0.17)
	local ll = Instance.new("UIListLayout")
	ll.FillDirection = Enum.FillDirection.Horizontal; ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ll.VerticalAlignment = Enum.VerticalAlignment.Center; ll.Padding = UDim.new(0.015, 0); ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = row
	local ic = Instance.new("ImageLabel")
	ic.LayoutOrder = 1; ic.BackgroundTransparency = 1; ic.Size = UDim2.fromScale(0.95, 0.95); ic.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ic.Image = Cfg.ROBUX_ICON; ic.ScaleType = Enum.ScaleType.Fit; ic.Parent = row
	local t = Instance.new("TextLabel")
	t.LayoutOrder = 2; t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(0, 1); t.AutomaticSize = Enum.AutomaticSize.X
	t.FontFace = HEAVY; t.TextSize = 40; t.TextScaled = false; t.TextColor3 = YELLOW; t.Text = ""
	local ts = Instance.new("UIStroke"); ts.Color = INK; ts.Thickness = 2.4; ts.LineJoinMode = Enum.LineJoinMode.Round; ts.Parent = t
	t.Parent = row
	row.Parent = parent
	-- розмір тексту — під висоту рядка (табличка в стадах, пікселі змінюються з відстанню)
	local function fit() t.TextSize = math.max(6, math.floor(row.AbsoluteSize.Y * 0.95)) end
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit); fit()
	return t
end

local function makeBoard(st: St)
	local a = Instance.new("Part")
	a.Name = "RobuxBoardAnchor"; a.Size = Vector3.new(0.2, 0.2, 0.2); a.Transparency = 1
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false
	a.CFrame = CFrame.new(st.top + Vector3.new(0, 5, 0))
	local bb = Instance.new("BillboardGui")
	bb.Name = "RobuxBoard"; bb.Size = UDim2.fromScale(5.28, 3.19) -- +10 % від таблички ролу; bb.LightInfluence = 0
	bb.MaxDistance = 60; bb.AlwaysOnTop = false; bb.ResetOnSpawn = false; bb.Adornee = a
	bb.SizeOffset = Vector2.new(0, 0.5) -- низ таблички — на якорі (над головою)
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder; list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom; list.Parent = bb
	st.soon = label(bb, 0, 0.13, Color3.fromHex("ffd23a"), XBOLD)
	st.rar = label(bb, 1, 0.13, Color3.new(1, 1, 1), XBOLD)
	st.name = label(bb, 2, 0.18, Color3.new(1, 1, 1), HEAVY)
	st.price = priceLine(bb, 3)
	st.speed = label(bb, 4, 0.14, GREEN, HEAVY)
	st.dmg = label(bb, 5, 0.14, GREEN, HEAVY)
	bb.Parent = a
	a.Parent = st.stand
	st.anchor = a; st.bb = bb
end

local function ratio(a: number?, b: number?): string
	if not a or not b or b == 0 then return "x1" end
	return NF.mult(a / b)
end

local function place(st: St, k: number, t: number)
	local m = st.golem
	if not m then return end
	k = math.max(0.05, k)
	if math.abs(m:GetScale() - st.base * k) > 1e-4 then m:ScaleTo(st.base * k) end
	local pos = st.top + Vector3.new(0, st.foot * k, 0)
	local fd = st.stand:GetAttribute("FaceDirLocal") -- у просторі стенду (ніші праворуч розвернуті)
	local dir = if typeof(fd) == "Vector3" and fd.Magnitude > 0.01 then st.stand:GetPivot():VectorToWorldSpace(fd.Unit) else st.stand:GetPivot().LookVector
	local yaw = SWAY_AMP * math.sin(t * SWAY_SPEED)
	m:PivotTo(CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, yaw, 0))
end

local function showOffer(st: St, i: number)
	st.idx = i
	local o = Cfg.OFFERS[i]
	local def = Catalog.get(o.kind)
	if st.golem then local old = st.golem; st.golem = nil; old:Destroy() end
	local m = GolemModel.build(o.kind, Cfg.CLS)
	if m then
		m.Name = "RobuxStandGolem"
		for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.CanQuery = false end end
		m:ScaleTo(m:GetScale() * STAND_SCALE)
		st.golem = m; st.base = m:GetScale(); st.foot = GolemModel.footOffset(m); st.k = 0.05
		place(st, 1, os.clock())
		local _, gsz = m:GetBoundingBox()
		if st.anchor then st.anchor.CFrame = CFrame.new(st.top + Vector3.new(0, gsz.Y + 0.6, 0)) end
		place(st, 0.05, os.clock())
		m.Parent = st.stand
		-- поява: зростає з нуля за 0,22 с із невеликим перескоком
		local t0 = os.clock()
		task.spawn(function()
			while st.golem == m and m.Parent do
				local t = (os.clock() - t0) / 0.22
				if t >= 1 then st.k = 1; break end
				st.k = TweenService:GetValue(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				RunService.Heartbeat:Wait()
			end
		end)
	end
	local s = Catalog.stats(o.kind, Cfg.CLS, 0)
	local w = Catalog.stats("wooden", Cfg.CLS, 0)
	local r = def and def.rarity or "Epic"
	if st.rar then st.rar.Text = r; st.rar.TextColor3 = Catalog.rarityColor(r) end
	if st.name then st.name.Text = def and def.name or o.kind end
	if st.price then st.price.Text = tostring(o.robux) end
	if st.speed then st.speed.Text = "Speed " .. ratio(s.speed, w.speed) end
	if st.dmg then st.dmg.Text = "Damage " .. ratio(s.dmg, w.dmg) end
	if st.soon then st.soon.Text = "" end
	if st.bb then
		local sc = st.bb:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		sc.Scale = 0.6; sc.Parent = st.bb
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	if st.prompt then st.prompt.ObjectText = def and def.name or o.kind end
end

local function addStand(stand: Instance)
	if not stand:IsA("Model") or stand.Name ~= "RobuxStand" or stands[stand] then return end
	if not stand:IsDescendantOf(workspace) or stand:FindFirstAncestor("NichePrefabs") then return end
	local anchor = stand:WaitForChild("RobuxBuyAnchor", 10)
	local pr = anchor and anchor:FindFirstChild("RobuxBuyPrompt")
	local st: St = { stand = stand, top = standTop(stand), idx = 0, k = 1, base = 1, foot = 0,
		prompt = (pr and pr:IsA("ProximityPrompt")) and pr or nil }
	stands[stand] = st
	makeBoard(st)
	if st.prompt then
		local p = st.prompt
		p:SetAttribute("UIText", "BUY"); p:SetAttribute("UIColor", "green"); p:SetAttribute("UIIcon", nil); p:SetAttribute("UIDisabled", false)
		p.Triggered:Connect(function()
			local o = Cfg.OFFERS[st.idx]
			if not o then return end
			if o.product ~= 0 then
				MarketplaceService:PromptProductPurchase(player, o.product)
			elseif st.soon then
				st.soon.Text = "COMING SOON"
				local idx = st.idx
				task.delay(2, function() if st.idx == idx and st.soon then st.soon.Text = "" end end)
			end
		end)
	end
	stand.AncestryChanged:Connect(function()
		if not stand:IsDescendantOf(workspace) then
			if st.golem then st.golem:Destroy() end
			stands[stand] = nil
		end
	end)
end

local niches = workspace:WaitForChild("Niches", math.huge)
for _, d in niches:GetDescendants() do if d.Name == "RobuxStand" then task.spawn(addStand, d) end end
niches.DescendantAdded:Connect(function(d) if d.Name == "RobuxStand" then task.spawn(addStand, d) end end)

-- погойдування і поява — лише поблизу камери
RunService.Heartbeat:Connect(function()
	local cam = workspace.CurrentCamera
	local cp = cam and cam.CFrame.Position
	local t = os.clock()
	for _, st in stands do
		if st.golem and (st.k < 1 or not cp or (cp - st.top).Magnitude < SWAY_DIST) then place(st, st.k, t) end
	end
end)

while true do
	local i = Cfg.indexAt(workspace:GetServerTimeNow())
	for _, st in stands do
		if st.idx ~= i then
			local ok, err = pcall(showOffer, st, i)
			if not ok then warn("RobuxStandClient: " .. tostring(err)) end
		end
	end
	task.wait(0.25)
end
