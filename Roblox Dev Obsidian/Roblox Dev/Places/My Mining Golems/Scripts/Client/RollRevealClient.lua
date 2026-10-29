--!strict
-- RollRevealClient — анімація ролу големів на підставках ролу, табличка результату й кнопка BUY (GDD - Roll, v1 27.10.2026).
-- Де: StarterPlayer/StarterPlayerScripts/RollRevealClient (LocalScript). Сервер — ServerScriptService/RollService.
-- Усе локально: моделі големів (Shared/GolemModel.build) створює кожен клієнт; гості бачать те саме, але без кнопок.
-- Дані — атрибути підставки Niches/*/RollSystem/Stands/Stand<i>: RollSeq (JSON { k, c, m, f = { {k, m}, … } }), RollT0,
--   RollReadyAt, RollPrice, RollBoughtT, FaceDir.
-- Таймлайн (Shared/RollConfig, v3 — без обертання): 4 фейки, кожен — поява APPEAR (виростає з точки, Back Out) →
--   показ → зникнення VANISH (у точку), цикл cy з RollSeq (сервер стискає його, щоб усе тривало рівно TOTAL = 2 с);
--   5-та поява — результат: RESULT_APPEAR (0,2 с) + спалах кольору рідкості
--   (Highlight, світло, кубики), голем лишається в Idle з табличкою. У фейків з мутацією — обвідка кольору мутації.
--   Запізнився (зайшов під час анімації) — анімація дограє з поточного моменту; без f або пізно — одразу фінал.
-- Розмір: голем на підставці × STAND_SCALE (0,5) від звичайного (v2, 27.10.2026: великі налазили один на одного).
-- Табличка (BillboardGui RollInfo): мутація [xM] (не Normal, градієнт MutationText), рідкість, назва, ціна ($… / FREE), Speed x…,
--   майнер — Damage x…, носій — Capacity x…, воїн — Damage x… · N HP. x1 — Wooden Golem Normal того ж класу.
-- Кнопки (лише власник ніші): RollBuyPrompt — «BUY $…» / «FREE» (зелена), грошей замало — сіра (UIDisabled),
--   інвентар повний — сіра «INVENTORY FULL»; гостям і RollBuyPrompt, і важіль RollPrompt вимикаються локально.
-- Звуки (лише власнику, Shared/UISounds): кожна поява фейка — легкий hover (minGap 0,15, вище з кожною), результат — claim,
--   купівля — BuySound. Відмова (deny) — CustomPrompts на сірій кнопці.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local RollConfig = require(Shared:WaitForChild("RollConfig"))
local GolemModel = require(Shared:WaitForChild("GolemModel"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local MutationText = require(Shared:WaitForChild("MutationText"))

local player = Players.LocalPlayer
local APPEAR, VANISH, RESULT = RollConfig.APPEAR, RollConfig.VANISH, RollConfig.RESULT_APPEAR
local CYCLE = RollConfig.cycle(1) -- за замовчуванням (якщо в RollSeq немає cy)
local MIN_SCALE = 0.02
local STAND_SCALE = 0.5 -- голем на підставці ролу вудвічі менший за звичайний (рішення користувача 27.10.2026)
local BOARD_DIST = 48
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local INK = Color3.fromHex("14161a")
local GREEN = Color3.fromHex("7dff3a")
local YELLOW = Color3.fromHex("ffd23a")

local function now(): number return workspace:GetServerTimeNow() end
local function decode(s: any): any
	if type(s) ~= "string" or s == "" then return nil end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or nil
end
local function backOut(x: number): number
	local c1, c3 = 1.9, 2.9
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end
local function inOut(x: number): number return x < 0.5 and 2 * x * x or 1 - (-2 * x + 2) ^ 2 / 2 end

-- ===== власник ніші =====
local function nicheOfStand(stand: Instance): Instance?
	local h = stand.Parent
	local rs = h and h.Parent
	return rs and rs.Parent or nil
end
local function isOwner(niche: Instance?): boolean
	return niche ~= nil and niche:GetAttribute("OwnerUserId") == player.UserId
end

-- ===== геометрія підставки =====
-- центр верхньої плити (найбільша за площею деталь, що не є нашою)
local function standTop(stand: Model): Vector3
	local best, area = nil, 0
	for _, d in stand:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "RollBuyAnchor" and d.Transparency < 1 then
			local a = d.Size.X * d.Size.Z
			if a > area + 0.01 or (math.abs(a - area) < 0.01 and best and d.Position.Y > best.Position.Y) then best, area = d, a end
		end
	end
	local pv = stand:GetPivot().Position
	if best then return Vector3.new(pv.X, best.Position.Y + best.Size.Y / 2, pv.Z) end
	return pv
end
local function faceOf(stand: Model): Vector3
	local d = stand:GetAttribute("FaceDir")
	if typeof(d) == "Vector3" and d.Magnitude > 0.01 then return d.Unit end
	return Vector3.new(1, 0, 0)
end

-- ===== табличка =====
local function label(parent: Instance, order: number, h: number, str: string, color: Color3, font: Font): TextLabel
	local t = Instance.new("TextLabel")
	t.LayoutOrder = order
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, h)
	t.FontFace = font
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Color = INK; s.Thickness = 2.4; s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	t.Parent = parent
	return t
end

local function ratio(a: number?, b: number?): string
	if not a or not b or b == 0 then return "x1" end
	return NF.mult(a / b)
end

local function buildBoard(root: BasePart, top: number, kind: string, cls: string, mut: number): BillboardGui
	local def = Catalog.get(kind)
	local s = Catalog.stats(kind, cls, mut)
	local w = Catalog.stats("wooden", cls, 0)
	local bb = Instance.new("BillboardGui")
	bb.Name = "RollInfo"
	bb.Adornee = root
	bb.Size = UDim2.fromScale(4.8, 2.9)
	bb.StudsOffsetWorldSpace = Vector3.new(0, top + 1.7, 0)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = true -- табло Roll Upgrades опускається перед големами, коли гравець біля важеля
	bb.MaxDistance = BOARD_DIST
	bb.ResetOnSpawn = false
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = bb
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = bb
	if mut > 0 then
		local mu = Catalog.mutation(mut)
		local ml = label(bb, 1, 0.15, mu.key .. " [" .. NF.mult(mu.power or 1) .. "]", mu.color, XBOLD)
		ml.Name = "Mutation"
		MutationText.apply(ml, mut)
	end
	label(bb, 2, 0.13, def.rarity, Catalog.rarityColor(def.rarity), XBOLD)
	label(bb, 3, 0.18, def.name, Color3.new(1, 1, 1), HEAVY)
	label(bb, 4, 0.17, s.price > 0 and NF.money(s.price) or "FREE", YELLOW, HEAVY)
	label(bb, 5, 0.14, "Speed " .. ratio(s.speed, w.speed), GREEN, HEAVY)
	local second
	if cls == "carrier" then
		second = "Capacity " .. ratio(s.cap, w.cap)
	elseif cls == "warrior" then
		second = "Damage " .. ratio(s.dmg, w.dmg) .. " · " .. NF.short(s.hp or 0) .. " HP"
	else
		second = "Damage " .. ratio(s.dmg, w.dmg)
	end
	label(bb, 6, 0.14, second, GREEN, HEAVY)
	bb.Parent = root
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	return bb
end

-- ===== ефекти =====
local function burst(at: Vector3, color: Color3)
	for i = 1, 12 do
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.Neon; p.Color = color
		p.Size = Vector3.one * (0.3 + math.random() * 0.3)
		local a = (i / 12) * math.pi * 2 + math.random() * 0.4
		p.CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 0.8, 0.4, math.sin(a) * 0.8))
		p.Parent = workspace
		local goal = p.CFrame + Vector3.new(math.cos(a) * 3, 2 + math.random() * 2, math.sin(a) * 3)
		TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = goal * CFrame.Angles(math.random() * 3, math.random() * 3, 0), Size = Vector3.one * 0.05, Transparency = 0.7 }):Play()
		task.delay(0.65, function() p:Destroy() end)
	end
end

local function flash(m: Model, color: Color3, dur: number)
	local h = Instance.new("Highlight")
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillColor = Color3.new(1, 1, 1); h.FillTransparency = 0.05
	h.OutlineColor = color; h.OutlineTransparency = 0
	h.Parent = m
	TweenService:Create(h, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(dur + 0.05, function() h:Destroy() end)
	local root = m:FindFirstChild("Root")
	if root then
		local l = Instance.new("PointLight")
		l.Color = color; l.Range = 14; l.Brightness = 4; l.Shadows = false
		l.Parent = root
		TweenService:Create(l, TweenInfo.new(dur + 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
		task.delay(dur + 0.35, function() l:Destroy() end)
	end
end

-- ===== стан підставки =====
type Golem = { m: Model, base: number, foot: number }
type Vis = { token: number, final: Golem?, live: { Golem }, seq: string? }
local vis: { [Model]: Vis } = {}

local function spawnGolem(kind: string, cls: string): Golem?
	local m = GolemModel.build(kind, cls)
	if not m then return nil end
	m.Name = "RollGolem"
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.CanQuery = false; d.CastShadow = true end end
	m:ScaleTo(m:GetScale() * STAND_SCALE)
	local g = { m = m, base = m:GetScale(), foot = GolemModel.footOffset(m) }
	return g
end

-- поставити голема: k — масштаб (0..1+), yaw — додатковий поворот
local function pose(g: Golem, stand: Model, k: number, yaw: number, lift: number?)
	local kk = math.max(MIN_SCALE, k)
	local top = standTop(stand)
	local dir = faceOf(stand)
	local pos = top + Vector3.new(0, g.foot * kk + (lift or 0), 0)
	if math.abs(g.m:GetScale() - g.base * kk) > 1e-4 then g.m:ScaleTo(g.base * kk) end
	g.m:PivotTo(CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, yaw, 0))
end

local function clearVis(stand: Model, v: Vis)
	for _, g in v.live do if g.m.Parent then g.m:Destroy() end end
	v.live = {}
	if v.final then v.final.m:Destroy(); v.final = nil end
end

-- фінал: справжній результат стоїть із табличкою
-- звуки ролу й купівлі — лише коли персонаж поруч зі стендом (Auto Roll крутить і тоді, коли власник далеко)
local SOUND_DIST = 45
local function nearStand(stand: Model): boolean
	local ch = game:GetService("Players").LocalPlayer.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end
	return (hrp.Position - stand:GetPivot().Position).Magnitude <= SOUND_DIST
end

local function placeFinal(stand: Model, v: Vis, seq: any, animate: boolean, owner: boolean)
	local cls = Catalog.cls(seq.c)
	local mut = Catalog.mut(seq.m)
	local g = spawnGolem(seq.k, cls)
	if not g then return end
	v.final = g
	pose(g, stand, animate and MIN_SCALE or 1, 0)
	g.m:SetAttribute("AuraScale", STAND_SCALE); g.m:SetAttribute("Mut", mut) -- 3D-ефект мутації (MutationAuraClient)
	g.m.Parent = stand
	local root = g.m:FindFirstChild("Root") :: BasePart?
	local def = Catalog.get(seq.k)
	local color = (mut > 0) and Catalog.mutation(mut).color or Catalog.rarityColor(def and def.rarity)
	if mut > 0 then
		local h = Instance.new("Highlight")
		h.Name = "MutGlow"; h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.FillTransparency = 1; h.OutlineColor = color; h.OutlineTransparency = 0.25
		h.Parent = g.m
	end
	local function board()
		if root and g.m.Parent then
			local top = GolemModel.headTop(g.m)
			buildBoard(root, top, def.id, cls, mut)
		end
	end
	if not animate then board(); return end
	if owner and nearStand(stand) then UISounds.play("claim", 0.1) end
	flash(g.m, color, 0.3)
	burst(standTop(stand), color)
	local t0 = os.clock()
	local tok = v.token
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if v.token ~= tok or not g.m.Parent then conn:Disconnect(); return end
		local a = math.clamp((os.clock() - t0) / RESULT, 0, 1)
		pose(g, stand, backOut(a), 0)
		if a >= 1 then conn:Disconnect(); board() end
	end)
end

-- фейк: поява → показ → зникнення (без обертання); startT — час сервера початку циклу, cy — його тривалість
local function runFake(stand: Model, v: Vis, f: any, cls: string, startT: number, cycle: number, owner: boolean, cy: number)
	local g = spawnGolem(f.k, cls)
	if not g then return end
	local mut = Catalog.mut(f.m)
	if mut > 0 then
		local h = Instance.new("Highlight")
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.FillColor = Catalog.mutation(mut).color; h.FillTransparency = 0.75
		h.OutlineColor = Catalog.mutation(mut).color; h.OutlineTransparency = 0.1
		h.Parent = g.m
	end
	table.insert(v.live, g)
	pose(g, stand, MIN_SCALE, 0)
	g.m:SetAttribute("AuraScale", STAND_SCALE); g.m:SetAttribute("Mut", mut) -- 3D-ефект мутації (MutationAuraClient)
	g.m.Parent = stand
	-- легкий звук на кожну появу (minGap — один на «хвилю» підставок), трохи вище з кожною появою
	if owner and now() - startT < 0.08 and nearStand(stand) then UISounds.play("hover", 0.15, 1 + 0.06 * (cycle - 1)) end
	local tok = v.token
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if v.token ~= tok or not g.m.Parent then conn:Disconnect(); if g.m.Parent then g.m:Destroy() end; return end
		local a = now() - startT
		if a < APPEAR then
			pose(g, stand, backOut(math.clamp(a / APPEAR, 0, 1)), 0)
		elseif a < cy - VANISH then
			pose(g, stand, 1, 0)
		elseif a < cy then
			local x = math.clamp((a - (cy - VANISH)) / VANISH, 0, 1)
			pose(g, stand, 1 - x * x, 0)
		else
			conn:Disconnect()
			g.m:Destroy()
			local i = table.find(v.live, g)
			if i then table.remove(v.live, i) end
		end
	end)
end

-- куплений голем: стискається й піднімається
local function boughtFx(stand: Model, g: Golem)
	local t0 = os.clock()
	local board = g.m:FindFirstChild("RollInfo", true)
	if board then board:Destroy() end
	flash(g.m, YELLOW, 0.3)
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / 0.3, 0, 1)
		if not g.m.Parent then conn:Disconnect(); return end
		pose(g, stand, 1 - a * a, a * math.pi, a * 2.5)
		if a >= 1 then conn:Disconnect(); g.m:Destroy() end
	end)
end

local function refresh(stand: Model)
	local v = vis[stand]
	if not v then return end
	local raw = stand:GetAttribute("RollSeq")
	if raw == v.seq then return end
	v.seq = raw
	v.token += 1
	local niche = nicheOfStand(stand)
	local owner = isOwner(niche)
	local seq = decode(raw)
	if not seq then
		-- порожньо: куплено (ефект) або просто прибрано
		local bt = stand:GetAttribute("RollBoughtT")
		if v.final and type(bt) == "number" and now() - bt < 1.5 then
			if owner and nearStand(stand) then UISounds.play("BuySound", 0.1) end
			boughtFx(stand, v.final)
			v.final = nil
		end
		clearVis(stand, v)
		return
	end
	clearVis(stand, v)
	local t0 = (stand:GetAttribute("RollT0") :: number?) or 0
	local cls = Catalog.cls(seq.c)
	local fakes = type(seq.f) == "table" and seq.f or {}
	local cy = tonumber(seq.cy) or CYCLE
	local endT = t0 + cy * #fakes
	if t0 <= 0 or #fakes == 0 or now() >= endT then
		-- Fast Roll (геймпас): фейків немає, але рол свіжий — результат з'являється з анімацією і спалахом
		placeFinal(stand, v, seq, #fakes == 0 and t0 > 0 and now() - t0 < 1, owner)
		return
	end
	local tok = v.token
	task.spawn(function()
		for i, f in fakes do
			local st = t0 + cy * (i - 1)
			if now() < st + cy then
				if now() < st then task.wait(st - now()) end
				if v.token ~= tok then return end
				runFake(stand, v, f, cls, st, i, owner, cy)
			end
		end
		local wait = endT - now()
		if wait > 0 then task.wait(wait) end
		if v.token ~= tok or not stand.Parent then return end
		placeFinal(stand, v, seq, true, owner)
	end)
end

-- ===== кнопка BUY (лише власник) =====
local function invCount(): number
	return Items.invGolemCount(decode(player:GetAttribute("InvGolems")), decode(player:GetAttribute("PlotPlaced"))) -- без големів на плотах
end
local function paintPrompt(stand: Model)
	local a = stand:FindFirstChild("RollBuyAnchor")
	local pr = a and a:FindFirstChild("RollBuyPrompt")
	if not (pr and pr:IsA("ProximityPrompt")) then return end
	if not isOwner(nicheOfStand(stand)) then
		if pr.Enabled then pr.Enabled = false end -- гость: без кнопки
		return
	end
	local price = (stand:GetAttribute("RollPrice") :: number?) or 0
	local money = (player:GetAttribute("Money") :: number?) or 0
	local text, disabled
	if invCount() >= Items.maxGolems(player) then
		text, disabled = "INVENTORY FULL", true
	elseif price <= 0 then
		text, disabled = "FREE", false
	else
		text, disabled = "BUY " .. NF.money(price), money < price
	end
	if pr:GetAttribute("UIText") ~= text then pr:SetAttribute("UIText", text) end
	if (pr:GetAttribute("UIDisabled") == true) ~= disabled then pr:SetAttribute("UIDisabled", disabled or nil) end
end

local prompts: { [Model]: boolean } = {}
local function hookPrompt(stand: Model)
	local a = stand:FindFirstChild("RollBuyAnchor")
	local pr = a and a:FindFirstChild("RollBuyPrompt")
	if not (pr and pr:IsA("ProximityPrompt")) or prompts[stand] then return end
	prompts[stand] = true
	pr:GetPropertyChangedSignal("Enabled"):Connect(function() paintPrompt(stand) end)
	paintPrompt(stand)
end

-- ===== підставки та ніші =====
local function hookStand(stand: Instance)
	if not stand:IsA("Model") or vis[stand] then return end
	vis[stand] = { token = 0, live = {}, final = nil, seq = nil }
	stand:GetAttributeChangedSignal("RollSeq"):Connect(function() refresh(stand) end)
	stand:GetAttributeChangedSignal("RollPrice"):Connect(function() paintPrompt(stand) end)
	stand.ChildAdded:Connect(function(c) if c.Name == "RollBuyAnchor" then task.defer(hookPrompt, stand) end end)
	local anc
	anc = stand.AncestryChanged:Connect(function()
		if not stand:IsDescendantOf(workspace) then
			local v = vis[stand]
			if v then v.token += 1; clearVis(stand, v) end
			vis[stand] = nil; prompts[stand] = nil
			anc:Disconnect() -- стрімінг / знищення: повернеться через Stands.ChildAdded → hookStand з нуля
		end
	end)
	hookPrompt(stand)
	refresh(stand)
end

-- важіль: гостям кнопка ROLL не показується (сервер також ігнорує чужий важіль)
local function hookLever(niche: Instance, pr: ProximityPrompt)
	local function apply()
		if not isOwner(niche) and pr.Enabled then pr.Enabled = false end
	end
	pr:GetPropertyChangedSignal("Enabled"):Connect(apply)
	niche:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		if isOwner(niche) then pr.Enabled = true end -- серверний стан повернеться з наступною зміною
		apply()
	end)
	apply()
end

local function hookNiche(niche: Instance)
	task.spawn(function()
		-- без тайм-аутів (v7): зі StreamingEnabled частини ніші можуть прийти пізно — тоді підставки не підхоплювались
		-- тайм-аут math.huge = чекати скільки завгодно, але без попередження «Infinite yield possible» в консолі (далекі ніші ще не прийшли стрімінгом)
		local rs = niche:WaitForChild("RollSystem", math.huge)
		task.spawn(function()
			local lm = rs:WaitForChild("RollLeverModel", math.huge)
			local anchor = lm:WaitForChild("PromptAnchor", math.huge)
			local pr = anchor:WaitForChild("RollPrompt", math.huge)
			if pr:IsA("ProximityPrompt") then hookLever(niche, pr) end
		end)
		local holder = rs:WaitForChild("Stands", math.huge)
		for _, s in holder:GetChildren() do hookStand(s) end
		holder.ChildAdded:Connect(hookStand)
	end)
	niche:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		for s in vis do if s:IsDescendantOf(niche) then paintPrompt(s) end end
	end)
end

local niches = workspace:WaitForChild("Niches")
for _, n in niches:GetChildren() do hookNiche(n) end
niches.ChildAdded:Connect(hookNiche)

-- гроші / інвентар змінились — перефарбувати кнопки BUY
local function repaintAll() for s in vis do paintPrompt(s) end end
player:GetAttributeChangedSignal("Money"):Connect(repaintAll)
player:GetAttributeChangedSignal("InvGolems"):Connect(repaintAll)

-- інвентар повний — Auto Roll / Auto Buy стоять (RollService, атрибут AutoRollFull): тост на екрані (UIEvents/Toast)
player:GetAttributeChangedSignal("AutoRollFull"):Connect(function()
	if player:GetAttribute("AutoRollFull") ~= true then return end
	local ui = game:GetService("ReplicatedStorage"):FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire("Inventory full! Auto Roll paused", "red", "deny") end
end)
