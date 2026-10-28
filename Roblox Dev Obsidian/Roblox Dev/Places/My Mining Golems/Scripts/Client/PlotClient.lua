--!strict
-- PlotClient — клієнтська частина плотів (зон фарму): рух големів, ящичок носія, поява / HP-бар / руйнування руди,
-- світні стаки руди на підлозі, вигляд закритих плотів (плівка + LOCKED під написом PLOT N над плотом), «+N» над ящиком плоту.
-- Де: StarterPlayer/StarterPlayerScripts/PlotClient (LocalScript). Сервер — ServerScriptService/PlotService.
--
-- Ящик плоту: над ним «N / CAP» (повний — FULL червоним), усередині видно руду (CRATE_VISUAL = 16 шматків):
--   це один щільний шар 4 × 4 шматки (без дірок), який піднімається від дна до краю пропорційно заповненню (50 з 100 —
--   на половині висоти); кольори — за складом (CrateMix); «+N ore» при Collect.
--   Кнопка COLLECT над ящиком (StyleA, клік, дотик або E) — лише власнику, коли КАМЕРА ближче CLOSE стадів до ящика відкритого плоту;
--   порожній ящик — сіра кнопка EMPTY. Дія "Collect" → Remotes/PlotAction.
-- Голем: сервер ставить MoveFrom / MoveTo / MoveT0 / MoveDur (час сервера) і Look; тут кожен кадр Root ставиться
--   на позицію руху й плавно повертається (аніматор голема — PlotAssets/Golem/GolemAnimator — будує решту тіла від Root).
-- Носій (Role = carrier): локальна копія PlotAssets/CarryBox у руках (між кулаками, ставить аніматор); Load / LoadOres — скільки й якої руди в ящичку.
-- Руда: GrowT0 / GrowDur — ріст по стадіях на очах (growOre: уламки → камінь → кристали → супутники → відскок); HP / MaxHP — HP-бар «C · Сегменти» (колір від зеленого до червоного, «N HP»);
--   Broken — руда стискається й розлітається уламками (HitChips).
-- Стак (Drops/Stack): світиться (ореол + світло, ставить сервер), гойдається й крутиться; BornT / From — шматок летить дугою
--   від руди; AddT / AddFrom — ще один шматок прилітає в наявний стак. Count — напис ×N (ставить сервер).
--   ExpireT — коли зникне (останні STACK_BLINK с блимає); Expired — стискається й зникає; PickedT / PickedBy / PickedN —
--   шматки летять до гравця, що підібрав, над ним «+N ore».

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HitChips = require(RS:WaitForChild("Effects"):WaitForChild("HitChips"))
local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds")) -- claim — руда з ящика (COLLECT)
local ASSETS = RS:WaitForChild("PlotAssets")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local INK = Color3.fromHex("040435")
local LOD = 160

local player = Players.LocalPlayer
local function now(): number return workspace:GetServerTimeNow() end
local function camPos(): Vector3
	local c = workspace.CurrentCamera
	return c and c.CFrame.Position or Vector3.zero
end

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog")) -- ящичок носія за Kind (Catalog.box)
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local UIS = game:GetService("UserInputService")
local PlotAction = RS:WaitForChild("Remotes"):WaitForChild("PlotAction") :: RemoteEvent
local CLOSE = 50 -- стадів від камери до ящика: ближче — над ящиком кнопка COLLECT
local CHUNK_COLOR: { [string]: Color3 } = {}
for _, c in ASSETS:WaitForChild("Chunks"):GetChildren() do
	local main = c:FindFirstChild("Main")
	if main and main:IsA("BasePart") then CHUNK_COLOR[c.Name] = main.Color end
end
-- нові моделі руди (Union-и з ReplicatedStorage/Prefabs/ForgeProps — ті самі, що на піддонах кузні й у слотах)
local CHUNK_TPL: { [string]: BasePart } = {}
do
	local pf = RS:FindFirstChild("Prefabs")
	local fp = pf and pf:WaitForChild("ForgeProps", 5)
	for key, n in { Coal = "ChunkCoal", Copper = "ChunkCopper", Iron = "ChunkIron" } do
		local u = fp and fp:FindFirstChild(n)
		if u and u:IsA("BasePart") then CHUNK_TPL[key] = u end
	end
end
-- візуал шматка руди на місці «якоря» (невидима деталь): Union потрібного типу, найбільший розмір = maxDim.
-- Кешується на якорі; інший тип — заміна моделі; key = nil — ховається.
local chunkVisOf: { [BasePart]: { key: string, part: BasePart } } = setmetatable({}, { __mode = "k" }) :: any
local function chunkVis(anchor: BasePart, key: string?, maxDim: number, parent: Instance, jitter: boolean?)
	local e = chunkVisOf[anchor]
	if not key or not CHUNK_TPL[key] then
		if e and e.part.Parent then e.part.Transparency = 1 end
		return
	end
	if not e or e.key ~= key or not e.part.Parent then
		if e then e.part:Destroy() end
		local u = CHUNK_TPL[key]:Clone()
		local sz = u.Size
		u.Size = sz * (maxDim / math.max(sz.X, sz.Y, sz.Z))
		u.Anchored = true; u.CanCollide = false; u.CanQuery = false; u.CanTouch = false
		u.Name = "ChunkVis"
		u.Parent = parent
		-- jitter (ящичок носія): як у ящику плоту — випадковий поворот у всіх осях (±25° нахил, будь-який поворот навколо Y);
		-- положення всередині ящичка підправляє fitInBox (шматок не вилазить за стінки й дно)
		local off = if jitter then CFrame.Angles(math.rad(math.random(-25, 25)), math.rad(math.random(0, 359)), math.rad(math.random(-25, 25))) else CFrame.identity
		e = { key = key, part = u, off = off }
		chunkVisOf[anchor] = e
	end
	e.part.Transparency = 0
	e.part.CFrame = anchor.CFrame * (e.off or CFrame.identity)
end

-- шматок у ящичку носія: зсуваємо всередину, щоб його повернута рамка (× 0,75 — Union круглий, не заповнює кути рамки) не виходила за внутрішній об'єм
-- (атрибути ящичка InnerX / InnerZ / InnerY0 / InnerY1 — у координатах його півота)
local function fitInBox(part: BasePart, box: Model)
	local pv = box:GetPivot()
	local r = pv:ToObjectSpace(part.CFrame)
	local h = part.Size / 2 * 0.75
	local X, Y, Z = r.XVector, r.YVector, r.ZVector
	local hx = math.abs(X.X) * h.X + math.abs(Y.X) * h.Y + math.abs(Z.X) * h.Z
	local hy = math.abs(X.Y) * h.X + math.abs(Y.Y) * h.Y + math.abs(Z.Y) * h.Z
	local hz = math.abs(X.Z) * h.X + math.abs(Y.Z) * h.Y + math.abs(Z.Z) * h.Z
	local ix = (box:GetAttribute("InnerX") :: number?) or 1.68
	local iz = (box:GetAttribute("InnerZ") :: number?) or 0.83
	local y0 = (box:GetAttribute("InnerY0") :: number?) or 0.23
	local y1 = (box:GetAttribute("InnerY1") :: number?) or 2
	local p = r.Position
	local x = math.clamp(p.X, -ix + hx, math.max(-ix + hx, ix - hx))
	local z = math.clamp(p.Z, -iz + hz, math.max(-iz + hz, iz - hz))
	local y = math.clamp(p.Y, y0 + hy, math.max(y0 + hy, y1 - hy))
	part.CFrame = pv * CFrame.new(x, y, z) * r.Rotation
end

-- ===================== големи =====================
type G = { model: Model, root: BasePart, yaw: number, box: Model?, boxOff: CFrame?, loadParts: { BasePart } }
local golems: { [Model]: G } = {}

local function lerpAngle(a: number, b: number, k: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * k
end

local function refreshLoad(g: G)
	local n = (g.model:GetAttribute("Load") :: number?) or 0
	local list = string.split((g.model:GetAttribute("LoadOres") :: string?) or "", ",")
	for i, p in g.loadParts do
		local key = list[i]
		local show = i <= n and key and CHUNK_COLOR[key] ~= nil
		if CHUNK_TPL[key or ""] then
			-- нова модель руди на місці деталі Load (сама деталь — лише «якір»), рухається разом із ящичком
			p.Transparency = 1
			-- шматок більший за крок гнізд (× 1,2): сусідні налазять, прогалин немає (як у ящику плоту)
			chunkVis(p, if show then key else nil, math.max(p.Size.X, p.Size.Y, p.Size.Z) * 1.2, g.box or p.Parent :: Instance, true)
			local e = chunkVisOf[p]
			if show and e and e.part.Parent and g.box then fitInBox(e.part, g.box) end
		elseif show then
			p.Transparency = 0
			p.Color = CHUNK_COLOR[key]
		else
			p.Transparency = 1
			chunkVis(p, nil, 1, p)
		end
	end
end

local function popup(at: Vector3, text: string, color: Color3)
	local a = Instance.new("Part")
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false; a.Transparency = 1
	a.Size = Vector3.one * 0.2; a.Position = at; a.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(5, 1.6); bb.LightInfluence = 0; bb.AlwaysOnTop = true; bb.MaxDistance = 90; bb.Parent = a
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.FontFace = HEAVY; t.TextScaled = true
	t.Text = text; t.TextColor3 = color; t.Parent = bb
	local s = Instance.new("UIStroke"); s.Color = INK; s.Thickness = 3; s.Parent = t
	TweenService:Create(a, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = at + Vector3.new(0, 3.2, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.65), { TextTransparency = 1 }):Play()
	TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.65), { Transparency = 1 }):Play()
	task.delay(1.2, function() a:Destroy() end)
end

local function addGolem(m: Model)
	if golems[m] then return end
	local root = m:WaitForChild("Root", 5) :: BasePart?
	if not root or not m.Parent then return end
	local g: G = { model = m, root = root, yaw = 0, box = nil, boxOff = nil, loadParts = {} }
	local look = m:GetAttribute("Look")
	if typeof(look) == "Vector3" then
		local d = look - root.Position
		g.yaw = math.atan2(-d.X, -d.Z)
	end
	if m:GetAttribute("Role") == "carrier" then
		local boxSrc = ASSETS:FindFirstChild(Catalog.box(m:GetAttribute("Kind"))) or ASSETS.CarryBox
		local box = boxSrc:Clone()
		-- голем більшого розміру (GolemCatalog.size, сервер робить ScaleTo) — ящичок того ж масштабу (локальна копія, ScaleTo тут безпечний)
		local k = m:GetScale()
		if math.abs(k - box:GetScale()) > 1e-4 then box:ScaleTo(k) end
		box.Name = "CarryBox" -- аніматор шукає ящичок саме під цим ім'ям
		local off = box:GetAttribute("Offset")
		g.boxOff = CFrame.new(typeof(off) == "Vector3" and off or Vector3.new(0, 3.1, -2.2))
		for _, p in (box:FindFirstChild("Load") :: Folder):GetChildren() do
			if p:IsA("BasePart") then table.insert(g.loadParts, p) end
		end
		table.sort(g.loadParts, function(a, b) return (tonumber(string.sub(a.Name, 2)) or 0) < (tonumber(string.sub(b.Name, 2)) or 0) end)
		-- у ящичку видно максимум 10 шматків: гнізда L1–L10 — сітка 5 × 2 по всьому (піднятому) дну,
		-- заповнюються у випадковому порядку (руда розкидана по всьому дну з першого шматка)
		do
			local lp = g.loadParts
			while #lp > 10 do table.remove(lp) end
			local function shuffle(a: number, b: number) for k = b, a + 1, -1 do local j = math.random(a, k); lp[k], lp[j] = lp[j], lp[k] end end
			shuffle(1, #lp)
		end
		box.Parent = m
		g.box = box
		refreshLoad(g)
		m:GetAttributeChangedSignal("Load"):Connect(function() refreshLoad(g) end)
		m:GetAttributeChangedSignal("LoadOres"):Connect(function() refreshLoad(g) end)
		m:GetAttributeChangedSignal("DeliverT"):Connect(function()
			local n = (m:GetAttribute("Delivered") :: number?) or 0
			local plot = m.Parent and m.Parent.Parent
			local crate = plot and plot:FindFirstChild("Crate")
			if n > 0 and crate and crate:IsA("Model") then
				local cf, size = crate:GetBoundingBox()
				popup(cf.Position + Vector3.new(0, size.Y / 2 + 1.5, 0), "+" .. n .. " ore", Color3.fromHex("7dff3a"))
			end
		end)
	end
	golems[m] = g
	m.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(workspace) then golems[m] = nil end
	end)
end

local function updateGolems(dt: number)
	local t = now()
	local cam = camPos()
	for m, g in golems do
		local from = m:GetAttribute("MoveFrom")
		local to = m:GetAttribute("MoveTo")
		if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" then continue end
		local t0 = (m:GetAttribute("MoveT0") :: number?) or 0
		local dur = (m:GetAttribute("MoveDur") :: number?) or 0
		local a = if dur > 0 then math.clamp((t - t0) / dur, 0, 1) else 1
		local pos = (from :: Vector3):Lerp(to :: Vector3, a)
		local dir: Vector3? = nil
		if a < 1 and ((to :: Vector3) - (from :: Vector3)).Magnitude > 0.05 then
			dir = (to :: Vector3) - (from :: Vector3)
		else
			local look = m:GetAttribute("Look")
			if typeof(look) == "Vector3" then dir = look - pos end
		end
		if dir and Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.05 then
			g.yaw = lerpAngle(g.yaw, math.atan2(-dir.X, -dir.Z), math.min(1, dt * 10))
		end
		local far = (cam - pos).Magnitude > LOD
		local cf = CFrame.new(pos) * CFrame.Angles(0, g.yaw, 0)
		g.root.CFrame = cf
		-- ящичок носія ставить аніматор голема — між кулаками (PlotGolemAnimator, Carry)
	end
end

-- ===================== руда =====================
local function backOut(x: number): number
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function dust(at: Vector3, color: Color3, n: number)
	for _ = 1, n do
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Size = Vector3.one * (0.35 + math.random() * 0.35)
		p.Color = color; p.Material = Enum.Material.SmoothPlastic
		local a = math.random() * math.pi * 2
		p.CFrame = CFrame.new(at + Vector3.new(math.cos(a), 0.2, math.sin(a)) * 1.2)
		p.Parent = workspace
		local goal = p.CFrame + Vector3.new(math.cos(a) * 2.6, 1.0 + math.random(), math.sin(a) * 2.6)
		TweenService:Create(p, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = goal, Size = Vector3.one * 0.05, Transparency = 0.6 }):Play()
		task.delay(0.6, function() p:Destroy() end)
	end
end

-- масштаб моделі вручну (Model:ScaleTo на клієнті ламається, коли сервер реплікує Scale = 1 назад)
type Scaler = { set: (number, CFrame) -> (), restore: () -> () }
local function scaler(m: Model): Scaler
	local pivot = m:GetPivot()
	local parts, size, rel = {}, {}, {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(size, d.Size)
			table.insert(rel, pivot:ToObjectSpace(d.CFrame))
		end
	end
	local cfs = table.create(#parts)
	local self = {}
	function self.set(k: number, at: CFrame)
		for i, p in parts do
			p.Size = size[i] * k
			local r = rel[i]
			cfs[i] = at * CFrame.new(r.Position * k) * r.Rotation
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
	function self.restore() self.set(1, pivot) end
	return self :: any
end

-- HP-бар «C · Сегменти» (затверджено): до 10 сегментів, колір від зеленого (повне HP) до червоного, над смугою «N HP»
local SEG_MAX = 10
local function hpBar(m: Model): (BillboardGui, { Frame }, TextLabel)
	local base = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	local _, size = m:GetBoundingBox()
	local bb = Instance.new("BillboardGui")
	bb.Name = "HPBar"; bb.Adornee = base; bb.Size = UDim2.fromScale(4.4, 1.15)
	bb.StudsOffsetWorldSpace = Vector3.new(0, size.Y + 1.1, 0); bb.MaxDistance = 80; bb.LightInfluence = 0; bb.Enabled = false
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1; txt.Size = UDim2.fromScale(1, 0.5); txt.FontFace = HEAVY; txt.TextScaled = true
	txt.TextColor3 = Color3.new(1, 1, 1); txt.Parent = bb
	local ts = Instance.new("UIStroke"); ts.Color = INK; ts.Thickness = 2; ts.Parent = txt
	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromScale(0, 0.56); bar.Size = UDim2.fromScale(1, 0.44); bar.BackgroundColor3 = Color3.fromHex("14161a"); bar.BorderSizePixel = 0
	bar.Parent = bb
	local pad = Instance.new("UIPadding")
	for _, k in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do (pad :: any)[k] = UDim.new(0, 2) end
	pad.Parent = bar
	-- сегменти без UIListLayout: кожен займає свою комірку [(i−1)/n; i/n] ширини рамки (мінус 1 px з боків, де сусід → проміжок 2 px).
	-- Позиція й ширина кожного рахуються від рамки окремо, тож округлення пікселів не накопичується і останній сегмент
	-- не вилазить за праву межу (раніше: ширина 1/n − 2(n−1)/n px + Padding 2 px у UIListLayout давала +n px на малому білборді).
	-- n — ціле: MaxHP буває дробовим (мутації), тому ceil, від 1 до SEG_MAX.
	local segs = {}
	local mx = math.max(1, (m:GetAttribute("MaxHP") :: number?) or 1)
	local n = math.clamp(math.ceil(mx - 1e-6), 1, SEG_MAX)
	for i = 1, n do
		local f = Instance.new("Frame")
		f.LayoutOrder = i; f.BorderSizePixel = 0
		local l = if i > 1 then 1 else 0
		local r = if i < n then 1 else 0
		f.Position = UDim2.new((i - 1) / n, l, 0, 0)
		f.Size = UDim2.new(1 / n, -(l + r), 1, 0)
		local g = Instance.new("UIGradient"); g.Rotation = 90
		g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)); g.Parent = f
		f.Parent = bar
		segs[i] = f
	end
	bb.Parent = m
	return bb, segs, txt
end

-- звук удару кіркою (PlotAssets/PickaxeHit): HP руди зменшилось — 3D-звук на руді, висота трохи випадкова
local HIT_SND = ASSETS:FindFirstChild("PickaxeHit") :: Sound?
local function playHit(m: Model)
	if not HIT_SND then return end
	local base = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	if not base or (camPos() - base.Position).Magnitude > 90 then return end
	local s = HIT_SND:Clone()
	s.PlaybackSpeed = HIT_SND.PlaybackSpeed * (0.9 + math.random() * 0.2)
	s.Parent = base
	s:Play()
	game:GetService("Debris"):AddItem(s, 1.5)
end
-- звук руйнування руди (PlotAssets/RockBreak, «Shale Break Low End Crackling Rock 2», 9119050441): лише на останньому ударі
-- (атрибут Broken), 3D на руді, та сама дальність (90), що й у playHit.
-- Нарізка на самому Sound: PlaybackRegion 0,08–0,58 с (без тиші на початку), гучність 0,3; тут — затухання до 0 за останні 0,25 с
local BREAK_SND = ASSETS:FindFirstChild("RockBreak") :: Sound?
local function playBreak(m: Model)
	if not BREAK_SND then return end
	local base = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	if not base or (camPos() - base.Position).Magnitude > 90 then return end
	local s = BREAK_SND:Clone()
	s.PlaybackSpeed = BREAK_SND.PlaybackSpeed * (0.92 + math.random() * 0.16)
	-- руда зникає через ~0,3 с — звук висить на невидимій точці в світі, щоб дограти до кінця
	local a = Instance.new("Attachment")
	a.WorldPosition = base.Position
	a.Parent = workspace.Terrain
	s.Parent = a
	s:Play()
	-- тривалість нарізки з урахуванням висоти: гасне до 0 точно в кінці регіону
	local len = (s.PlaybackRegion.Max - s.PlaybackRegion.Min) / s.PlaybackSpeed
	task.delay(math.max(0, len - 0.26), function()
		if s.Parent then TweenService:Create(s, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Volume = 0 }):Play() end
	end)
	game:GetService("Debris"):AddItem(a, 1)
end

-- ===================== ріст руди (затверджений веб-макет ore_grow) =====================
-- Сервер ставить на руду GrowT0 (час сервера) і GrowDur (= інтервал спавну, картка Ore Spawn); поки руда росте, її не б'ють.
-- Стадії (частки GrowDur): 1 — уламки й основа (0–16 %), 2 — кам'яне тіло знизу вгору (14–42 %), 3 — кристали руди по одному,
--   за кожним ядро (Core) і блиск (Glint) (40–80 %), 4 — супутники Sat_* у M / L, кожен у своєму під-вікні (78–94 %),
--   5 — відскок з іскрами. Кожен шматок вискакує різко: з нуля з перескоком (Back), з-під себе; уся руда плавно виринає
--   й докручується (синус). Невирослі шматки — LocalTransparencyModifier = 1 (лише на клієнті). Далі LOD — без анімації.
local GROW_WIN = { { 0, 0.16 }, { 0.14, 0.42 }, { 0.40, 0.80 }, { 0.78, 0.94 } }
local BODY_PREFIX = { "Body", "Lump", "Upper", "Cap", "PlateTop", "PlateSideR" }
local GROUND = { Base = true, BaseRound = true, Pebble1 = true, Pebble2 = true, PlateFrontLow = true, PlateBackL = true }
local function growStage(n: string): number
	local b = string.gsub(n, "^Sat_", "")
	if GROUND[b] then return 0 end
	for _, p in BODY_PREFIX do if string.sub(b, 1, #p) == p then return 1 end end
	return 2
end
local function popCurve(x: number): number -- Back з сильнішим перескоком (2,6)
	x -= 1
	return 1 + x * x * (3.6 * x + 2.6)
end
type GI = { p: BasePart, rel: CFrame, size: Vector3, n: string, st: number, si: number, y: number, t: number, glint: boolean, puff: number,
	shown: boolean, done: boolean }
local function growOre(m: Model, t0: number, D: number)
	local pivot = m:GetPivot()
	local _, bsize = m:GetBoundingBox()
	local items: { GI } = {}
	local anchors: { Vector3 } = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(d.CFrame)
			local sat = string.sub(d.Name, 1, 4) == "Sat_"
			table.insert(items, { p = d, rel = rel, size = d.Size, n = d.Name, st = sat and 3 or growStage(d.Name), si = 0, y = rel.Position.Y,
				t = 0, glint = false, puff = 0, shown = false, done = false })
			if d.Name == "Sat_Body" then table.insert(anchors, rel.Position) end
		end
	end
	-- супутники: кожен шматок Sat_ — до найближчого Sat_Body
	for _, it in items do
		if it.st == 3 then
			local bi, bd = 1, math.huge
			for i, a in anchors do
				local dd = (it.rel.Position - a).Magnitude
				if dd < bd then bi, bd = i, dd end
			end
			it.si = bi
		end
	end
	local nSat = math.max(1, #anchors)
	-- розклад
	local byStage: { { GI } } = { {}, {}, {}, {} }
	for _, it in items do table.insert(byStage[it.st + 1], it) end
	for st = 0, 1 do
		local l = byStage[st + 1]
		table.sort(l, function(a, b) return a.y < b.y end)
		local w = GROW_WIN[st + 1]
		for i, it in l do
			it.t = w[1] + (w[2] - w[1]) * (i - 1) / math.max(1, #l - 1)
			it.puff = (i % 2 == 1) and 3 or 0
		end
	end
	do -- кристали; ядро й блиск — одразу за своїм кристалом
		local l = byStage[3]
		local w = GROW_WIN[3]
		local main, byName = {}, {}
		for _, it in l do
			byName[it.n] = it
			if not (string.find(it.n, "Core$") or string.find(it.n, "Glint$")) then table.insert(main, it) end
		end
		table.sort(main, function(a, b) return a.y < b.y end)
		for i, it in main do
			it.t = w[1] + (w[2] - w[1]) * 0.92 * (i - 1) / math.max(1, #main - 1)
			it.puff = 4
			local c = byName[it.n .. "Core"]; if c then c.t = it.t + 0.025 end
			local g = byName[it.n .. "Glint"]; if g then g.t = it.t + 0.05; g.glint = true; g.puff = 2 end
		end
		for _, it in l do if it.t == 0 then it.t = (w[1] + w[2]) / 2 end end -- ядро / блиск без «свого» кристала
	end
	do -- супутники: кожен у своєму під-вікні, шматки швидко знизу вгору
		local w = GROW_WIN[4]
		for si = 1, nSat do
			local a = w[1] + (w[2] - w[1]) * (si - 1) / nSat
			local b = a + (w[2] - w[1]) / nSat
			local l = {}
			for _, it in byStage[4] do if it.si == si or (#anchors == 0) then table.insert(l, it) end end
			table.sort(l, function(x, y)
				local sx, sy = growStage(x.n), growStage(y.n)
				if sx ~= sy then return sx < sy end
				return x.y < y.y
			end)
			for j, it in l do it.t = a + (b - a) * (j - 1) / math.max(1, #l); it.puff = (j == 1) and 2 or 0 end
		end
	end
	for _, it in items do it.p.LocalTransparencyModifier = 1 end
	local pop = math.clamp(D * 0.12, 0.06, 0.2)
	local H = bsize.Y
	local parts: { BasePart } = {}
	local cfs: { CFrame } = {}
	local sparkled = false
	local con: RBXScriptConnection
	con = RunService.Heartbeat:Connect(function()
		if not m.Parent then con:Disconnect(); return end
		local el = now() - t0
		local u = math.clamp(el / D, 0, 1)
		local g = 0.5 - 0.5 * math.cos(math.pi * u)
		-- плавна частина: уся руда виринає (до 12 % висоти) і докручується (0,35 рад)
		local frame = pivot * CFrame.new(0, -(1 - g) * H * 0.12, 0) * CFrame.Angles(0, (1 - g) * 0.35, 0)
		-- фінальний відскок (0,35 с) — увесь масштаб
		local bk = 1
		if el >= D then
			local k = math.clamp((el - D) / 0.35, 0, 1)
			bk = 1 + math.sin(k * math.pi * 2) * 0.06 * (1 - k)
			if not sparkled then
				sparkled = true
				local ore = (m:GetAttribute("Ore") :: string?) or "Coal"
				dust(pivot.Position + Vector3.new(0, H * 0.6, 0), Color3.fromHex("fff6c8"), 8)
				dust(pivot.Position + Vector3.new(0, H * 0.3, 0), CHUNK_COLOR[ore] or Color3.new(1, 1, 1), 4)
			end
			if k >= 1 then
				con:Disconnect()
				table.clear(parts); table.clear(cfs)
				for _, it in items do
					it.p.Size = it.size
					it.p.LocalTransparencyModifier = 0
					table.insert(parts, it.p); table.insert(cfs, pivot * it.rel)
				end
				workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
				return
			end
		end
		table.clear(parts); table.clear(cfs)
		for _, it in items do
			local ts = it.t * D
			if el >= ts then
				if not it.shown then
					it.shown = true
					it.p.LocalTransparencyModifier = 0
					if it.puff > 0 then
						local col = if it.glint then Color3.fromHex("fff1e0") else it.p.Color
						dust((frame * it.rel).Position, col, it.puff)
					end
				end
				local k = math.clamp((el - ts) / pop, 0, 1)
				local s = math.max(0.02, popCurve(k)) * bk
				if k < 1 or bk ~= 1 or not it.done then
					it.p.Size = it.size * s
					if k >= 1 and bk == 1 then it.done = true end
				end
				local up = (1 - math.min(1, k * 1.4)) * it.size.Y * 0.6
				table.insert(parts, it.p)
				table.insert(cfs, frame * CFrame.new(it.rel.Position * bk - Vector3.new(0, up, 0)) * it.rel.Rotation)
			end
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end)
end

local function addOre(m: Model)
	if not m:IsA("Model") then return end
	-- HP-бар
	local bb, segs, txt = hpBar(m)
	local function hp()
		local h = (m:GetAttribute("HP") :: number?) or 0
		local mx = math.max(1, (m:GetAttribute("MaxHP") :: number?) or 1)
		local k = math.clamp(h / mx, 0, 1)
		bb.Enabled = h < mx and h > 0
		-- шкода мутації буває дрібною (2.4) — HP показуємо з одним знаком, без хвоста float
		local hr = math.floor(h * 10 + 0.5) / 10
		txt.Text = (hr == math.floor(hr) and string.format("%d", hr) or string.format("%.1f", hr)) .. " HP"
		-- ціле число сегментів без хвоста float (3.0000001 → 3); будь-яке HP > 0 — хоча б один сегмент
		local filled = if h > 0 then math.max(1, math.ceil(k * #segs - 1e-6)) else 0
		local col = Color3.fromHSV(0.29 * k, 0.85, 1) -- 0,29 ≈ зелений, 0 — червоний
		for i, f in segs do
			f.BackgroundColor3 = if i <= filled then col else Color3.fromHex("2a2f36")
		end
	end
	hp()
	m:GetAttributeChangedSignal("HP"):Connect(hp)
	local lastHp = (m:GetAttribute("HP") :: number?) or 0
	m:GetAttributeChangedSignal("HP"):Connect(function()
		local h = (m:GetAttribute("HP") :: number?) or 0
		if h < lastHp then playHit(m) end
		lastHp = h
	end)
	-- ріст (стадії, див. growOre); далі LOD або вже вирослу руду — показуємо одразу
	local gt0, gdur = m:GetAttribute("GrowT0"), m:GetAttribute("GrowDur")
	if type(gt0) == "number" and type(gdur) == "number" and gdur > 0 and now() - gt0 < gdur + 0.35
		and (camPos() - m:GetPivot().Position).Magnitude < LOD then
		growOre(m, gt0, gdur)
	end
	-- руйнування
	local broke = false
	m:GetAttributeChangedSignal("Broken"):Connect(function()
		bb.Enabled = false
		if not broke and m:GetAttribute("Broken") then broke = true; playBreak(m) end
		local pivot = m:GetPivot()
		local _, size = m:GetBoundingBox()
		local center = pivot.Position + Vector3.new(0, size.Y * 0.35, 0)
		HitChips.spawn(m, center, { count = 14, speed = 10, lift = 12 })
		local sc = scaler(m)
		local t0 = os.clock()
		local con: RBXScriptConnection
		con = RunService.Heartbeat:Connect(function()
			if not m.Parent then con:Disconnect(); return end
			local a = math.clamp((os.clock() - t0) / 0.3, 0, 1)
			sc.set(math.max(0.05, 1 - a * 0.95), pivot)
			if a >= 1 then con:Disconnect() end
		end)
	end)
end

-- ===================== стаки руди на підлозі =====================
type S = { model: Model, parts: { BasePart }, rel: { CFrame }, base: CFrame, phase: number, born: number, from: Vector3?, bump: number, hidden: boolean? }
local stacks: { [Model]: S } = {}

local function flyChunk(key: string, from: Vector3, to: Vector3, dur: number)
	local src = ASSETS.Chunks:FindFirstChild(key)
	if not src then return end
	local c = src:Clone() :: Model
	c.Parent = workspace
	local t0 = os.clock()
	local con: RBXScriptConnection
	con = RunService.Heartbeat:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		local p = from:Lerp(to, a) + Vector3.new(0, 4.5 * a * (1 - a) * 2 + 1.2 * (1 - a), 0)
		c:PivotTo(CFrame.new(p) * CFrame.Angles(a * 5, a * 3, 0))
		if a >= 1 then con:Disconnect(); c:Destroy() end
	end)
end

local function addStack(m: Model)
	if not m:IsA("Model") or stacks[m] then return end
	local main = m:WaitForChild("Main", 3) :: BasePart?
	if not main then return end
	local parts, rel = {}, {}
	local base = main.CFrame
	for _, n in { "Main", "Bit", "Glint" } do
		local p = m:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			table.insert(parts, p)
			table.insert(rel, base:ToObjectSpace(p.CFrame))
		end
	end
	local from = m:GetAttribute("From")
	local s: S = {
		model = m, parts = parts, rel = rel, base = base, phase = math.random() * 6,
		born = (m:GetAttribute("BornT") :: number?) or 0, from = typeof(from) == "Vector3" and from or nil, bump = 0,
	}
	stacks[m] = s
	-- зникнення: час вийшов — стискається на місці; підібрав гравець — летить до нього
	local function vanish(toPlayer: Player?)
		stacks[m] = nil
		local parts = {}
		for _, d in m:GetDescendants() do if d:IsA("BasePart") then table.insert(parts, { p = d, cf = d.CFrame, size = d.Size }) end end
		local t0 = os.clock()
		local con: RBXScriptConnection
		con = RunService.Heartbeat:Connect(function()
			local a = math.clamp((os.clock() - t0) / (toPlayer and 0.2 or 0.35), 0, 1) -- до гравця — швидко (0,2 с)
			local target: Vector3? = nil
			if toPlayer and toPlayer.Character then
				local hrp = toPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				target = hrp and hrp.Position
			end
			for _, e in parts do
				if e.p.Parent then
					e.p.Size = e.size * math.max(0.05, 1 - a)
					local pos = if target then e.cf.Position:Lerp(target, a * a) + Vector3.new(0, math.sin(a * math.pi) * 2, 0) else e.cf.Position - Vector3.new(0, a * 0.4, 0)
					e.p.CFrame = CFrame.new(pos) * e.cf.Rotation
				end
			end
			if a >= 1 or not m.Parent then con:Disconnect() end
		end)
	end
	m:GetAttributeChangedSignal("Expired"):Connect(function() vanish(nil) end)
	m:GetAttributeChangedSignal("PickedT"):Connect(function()
		local who = Players:GetPlayerByUserId((m:GetAttribute("PickedBy") :: number?) or 0)
		vanish(who)
		local n = (m:GetAttribute("PickedN") :: number?) or 0
		local hrp = who and who.Character and who.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and n > 0 then popup(hrp.Position + Vector3.new(0, 3.5, 0), "+" .. n .. " ore", Color3.fromHex("7dff3a")) end
	end)
	m:GetAttributeChangedSignal("AddT"):Connect(function()
		local af = m:GetAttribute("AddFrom")
		if typeof(af) == "Vector3" and (camPos() - s.base.Position).Magnitude < LOD then
			flyChunk((m:GetAttribute("Ore") :: string?) or "Coal", af, s.base.Position, 0.45)
			task.delay(0.45, function() s.bump = os.clock() end)
		end
	end)
	m.AncestryChanged:Connect(function() if not m:IsDescendantOf(workspace) then stacks[m] = nil end end)
end

local FLY = 0.5
local cfs: { CFrame } = {}
local list: { BasePart } = {}
local function updateStacks()
	local t = now()
	local clock = os.clock()
	local cam = camPos()
	table.clear(cfs); table.clear(list)
	for m, s in stacks do
		if (cam - s.base.Position).Magnitude > LOD then continue end
		local cf: CFrame
		local age = t - s.born
		if s.from and age < FLY then
			local a = math.clamp(age / FLY, 0, 1)
			local p = (s.from :: Vector3):Lerp(s.base.Position, a) + Vector3.new(0, 4.5 * a * (1 - a) * 2 + 1.2 * (1 - a), 0)
			cf = CFrame.new(p) * CFrame.Angles(a * 6, a * 4, 0)
		else
			local after = age - FLY
			local hop = if s.from and after < 0.35 then math.sin(math.clamp(after / 0.35, 0, 1) * math.pi) * 0.5 else 0
			local bob = math.sin(clock * 2.4 + s.phase) * 0.14 + 0.18
			cf = CFrame.new(s.base.Position + Vector3.new(0, bob + hop, 0)) * CFrame.Angles(0, clock * 1.3 + s.phase, 0)
		end
		local k = 1
		if s.bump > 0 and clock - s.bump < 0.25 then k = 1 + math.sin((clock - s.bump) / 0.25 * math.pi) * 0.25 end
		-- останні секунди перед зникненням — блимає
		local left = ((m:GetAttribute("ExpireT") :: number?) or math.huge) - t
		local hide = left < Cfg.STACK_BLINK and math.floor(left * (if left < 2 then 8 else 4)) % 2 == 0
		if hide ~= (s.hidden == true) then
			s.hidden = hide
			for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier = if hide then 1 else 0 end end
		end
		for i, p in s.parts do
			local r = s.rel[i]
			table.insert(list, p)
			table.insert(cfs, cf * CFrame.new(r.Position * k) * r.Rotation)
		end
	end
	if #list > 0 then workspace:BulkMoveTo(list, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end

-- ===================== ящик плоту: лічильник і руда всередині =====================
-- один шар 4 × 4 (CRATE_VISUAL = 16): шматки трохи перекриваються й упираються в стінки — дна не видно
local GRID_N, GRID_STEP = 4, 1.2
local FILL_Y0, FILL_Y1 = 0.75, 4.55 -- висота шару над дном ящика: порожній / повний (одиниці ящика до масштабу)
local crates: { any } = {}
local function setupCrate(plot: Model, crate: Model)
	local floor = crate.PrimaryPart or crate:WaitForChild("Floor", 5) :: BasePart?
	if not floor then return end
	local k = crate:GetScale()
	local rng = Random.new(plot:GetAttribute("PlotIndex") :: number? or 1)
	local pieces: { BasePart } = {}
	local rel: { CFrame } = {}
	local folder = Instance.new("Folder"); folder.Name = "CrateFill"; folder.Parent = crate
	local half = (GRID_N - 1) / 2
	for ix = 0, GRID_N - 1 do
		for iz = 0, GRID_N - 1 do
			local p = Instance.new("Part")
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
			local s = (1.38 + rng:NextNumber() * 0.14) * k
			p.Size = Vector3.new(s, s * 0.8, s * (0.92 + rng:NextNumber() * 0.12))
			p.Material = Enum.Material.Plastic; p.MaterialVariant = "StudsSmall"
			p.Transparency = 1
			p.Parent = folder
			table.insert(pieces, p)
			-- довільний поворот навколо Y і нахил до 25°: шматки лежать під різними кутами й накладаються
			table.insert(rel, CFrame.new((ix - half) * GRID_STEP + rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.15, 0.1), (iz - half) * GRID_STEP + rng:NextNumber(-0.12, 0.12))
				* CFrame.Angles(math.rad(rng:NextInteger(-25, 25)), math.rad(rng:NextInteger(0, 359)), math.rad(rng:NextInteger(-25, 25))))
		end
	end
	-- другий шар 3 × 3 у шаховому порядку (на півкроку зсунутий і трохи вище) — закриває щілини між шматками
	for ix = 0, GRID_N - 2 do
		for iz = 0, GRID_N - 2 do
			local p = Instance.new("Part")
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
			local s = (1.38 + rng:NextNumber() * 0.14) * k
			p.Size = Vector3.new(s, s * 0.8, s)
			p.Transparency = 1
			p.Parent = folder
			table.insert(pieces, p)
			table.insert(rel, CFrame.new((ix - half + 0.5) * GRID_STEP + rng:NextNumber(-0.12, 0.12), 0.28 + rng:NextNumber(-0.06, 0.06), (iz - half + 0.5) * GRID_STEP + rng:NextNumber(-0.12, 0.12))
				* CFrame.Angles(math.rad(rng:NextInteger(-25, 25)), math.rad(rng:NextInteger(0, 359)), math.rad(rng:NextInteger(-25, 25))))
		end
	end
	-- порядок кольорів — перемішаний, щоб руда різних видів лежала вперемішку, а не рядами
	local order = {}
	for i = 1, #pieces do order[i] = i end
	for i = #order, 2, -1 do local j = rng:NextInteger(1, i); order[i], order[j] = order[j], order[i] end
	-- напис над ящиком
	local bb = Instance.new("BillboardGui")
	bb.Name = "CrateCount"; bb.Adornee = floor; bb.Size = UDim2.fromScale(6, 1.6)
	local _, sz = crate:GetBoundingBox()
	bb.StudsOffsetWorldSpace = Vector3.new(0, sz.Y + 1.2, 0); bb.MaxDistance = 90; bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.FontFace = HEAVY; t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1); t.Parent = bb
	local s = Instance.new("UIStroke"); s.Color = INK; s.Thickness = 3; s.Parent = t
	bb.Parent = crate
	local function refresh()
		local n = (plot:GetAttribute("CrateCount") :: number?) or 0
		local cap = math.max(1, (plot:GetAttribute("CrateCap") :: number?) or 10)
		local full = n >= cap
		t.Text = (full and "FULL  " or "") .. string.format("%d / %d", n, cap)
		t.TextColor3 = if full then Color3.fromHex("ff5c4d") else Color3.new(1, 1, 1)
		bb.Enabled = plot:GetAttribute("Unlocked") == true
		-- шар руди: порожньо — схований; інакше висота від дна до краю пропорційно заповненню
		local frac = math.clamp(n / cap, 0, 1)
		local y = FILL_Y0 + (FILL_Y1 - FILL_Y0) * frac
		for i, p in pieces do
			p.CFrame = floor.CFrame * CFrame.new(0, y * k, 0) * CFrame.new(rel[i].Position * k) * rel[i].Rotation
		end
		-- кольори за складом: рівномірно перемішані (кожен наступний шматок — руда з найбільшим «боргом»)
		local mix: { [string]: number } = {}
		for part in string.gmatch((plot:GetAttribute("CrateMix") :: string?) or "", "[^,]+") do
			local key, cnt = string.match(part, "(%a+):(%d+)")
			if key then mix[key] = tonumber(cnt) :: number end
		end
		local given: { [string]: number } = {}
		for step, i in order do
			local p = pieces[i]
			if n > 0 then
				local best, bestD = "Coal", -math.huge
				for key, cnt in mix do
					local d = cnt / math.max(1, n) * step - (given[key] or 0)
					if d > bestD then best, bestD = key, d end
				end
				given[best] = (given[best] or 0) + 1
				if CHUNK_TPL[best] then
					p.Transparency = 1 -- деталь — «якір»; видно Union-модель руди
					chunkVis(p, best, p.Size.X * 1.5, folder) -- більше за крок сітки: сусідні шматки накладаються, дірок немає
				else
					p.Color = CHUNK_COLOR[best] or Color3.new(1, 1, 1)
					p.Transparency = 0
				end
			else
				p.Transparency = 1
				chunkVis(p, nil, 1, folder)
			end
		end
	end
	refresh()
	for _, a in { "CrateCount", "CrateCap", "CrateMix", "Unlocked" } do plot:GetAttributeChangedSignal(a):Connect(refresh) end
	plot:GetAttributeChangedSignal("CollectT"):Connect(function()
		local n = (plot:GetAttribute("Collected") :: number?) or 0
		if n > 0 then
			local cf2, size = crate:GetBoundingBox()
			popup(cf2.Position + Vector3.new(0, size.Y / 2 + 3, 0), "+" .. n .. " ore", Color3.fromHex("ffd34d"))
			-- свій ящик (власник ніші = я) — звук нагороди
			local nf = workspace:FindFirstChild("Niches")
			local p: Instance? = plot
			while p and p.Parent and p.Parent ~= nf do p = p.Parent end
			if p and p.Parent == nf and p:GetAttribute("OwnerUserId") == player.UserId then UISounds.play("claim") end
		end
	end)
	table.insert(crates, { plot = plot, crate = crate, floor = floor, height = sz.Y })
end

-- ===================== кнопка COLLECT над своїм ящиком =====================
type CR = { plot: Model, crate: Model, floor: BasePart, height: number }
local cbb = Instance.new("BillboardGui")
-- розмір у стадах (як частина ящика): на відстані кнопка менша, як усе у світі; стоїть рівно над написом «N / CAP»
local CB_W, CB_H = 230, 74          -- полотно кнопки (пікселі StyleA)
local CB_SW = 8.8                   -- ширина кнопки у стадах (висота — за пропорцією)
local CB_SH = CB_SW * CB_H / CB_W
cbb.Name = "PlotCollect"; cbb.Size = UDim2.fromScale(CB_SW, CB_SH); cbb.AlwaysOnTop = true; cbb.Enabled = false
cbb.ResetOnSpawn = false
cbb.Active = true -- без Active BillboardGui не пропускає клік мишкою й дотик до кнопки
cbb.Parent = player:WaitForChild("PlayerGui")
-- уміст — у рамці 230 × 74 з UIScale, який підганяється під фактичний розмір білборда в пікселях
local cholder = Instance.new("Frame")
cholder.Name = "Holder"; cholder.BackgroundTransparency = 1; cholder.Size = UDim2.fromOffset(CB_W, CB_H)
cholder.Parent = cbb
local cscale = Instance.new("UIScale"); cscale.Parent = cholder
cbb:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() cscale.Scale = cbb.AbsoluteSize.X / CB_W end)
-- поява / зникнення: рамка Anim по центру полотна з власним UIScale (0 → 1, Back) — кнопка виростає з центру й так само зникає
local canim = Instance.new("Frame")
canim.Name = "Anim"; canim.BackgroundTransparency = 1; canim.AnchorPoint = Vector2.new(0.5, 0.5)
canim.Position = UDim2.fromOffset(CB_W / 2, CB_H / 2); canim.Size = UDim2.fromOffset(CB_W, CB_H)
canim.Parent = cholder
local cpop = Instance.new("UIScale"); cpop.Scale = 0; cpop.Parent = canim
local cbtn = StyleA.new(canim, { size = Vector2.new(214, 66), position = Vector2.new(8, 4), color = "green", text = "COLLECT", textSize = 28, clickable = true, name = "Collect" })
local key = Instance.new("TextLabel")
-- клавіша E — як на підказках печери (CustomPrompts): фон #1d2233, ЧОРНА обводка #14161a (не INK цього скрипта #040435);
-- дитина кнопки (рухається й масштабується разом з нею); лівий верхній кут кнопки — (8, 4)
key.Size = UDim2.fromOffset(30, 30); key.Position = UDim2.fromOffset(-6 - 8, -8 - 4); key.BackgroundColor3 = Color3.fromHex("1d2233")
key.BorderSizePixel = 0; key.FontFace = HEAVY; key.TextScaled = true; key.Text = "E"; key.TextColor3 = Color3.new(1, 1, 1); key.ZIndex = 8
local ks = Instance.new("UIStroke"); ks.Color = Color3.fromHex("14161a"); ks.Thickness = 2.5; ks.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ks.Parent = key
key.Parent = cbtn.root
local near: CR? = nil
local function doCollect()
	if not near then return end
	if ((near.plot:GetAttribute("CrateCount") :: number?) or 0) <= 0 then StyleA.shake(cbtn); return end
	PlotAction:FireServer("Collect", near.plot:GetAttribute("PlotIndex"))
end
StyleA.bind(cbtn, { onClick = doCollect, debounce = 0.25, canClick = function() return near ~= nil and ((near.plot:GetAttribute("CrateCount") :: number?) or 0) > 0 end })
UIS.InputBegan:Connect(function(io, gp)
	if gp or io.KeyCode ~= Enum.KeyCode.E or not cbb.Enabled then return end
	doCollect()
end)
local lastEmpty: boolean? = nil
-- плавна поява (0,22 с, Back) і зникнення (0,14 с); білборд вимикається лише після зникнення
local cShown, cTok = false, 0
local function showCollect(on: boolean)
	if on == cShown then return end
	cShown = on
	cTok += 1
	local my = cTok
	if on then
		cbb.Enabled = true
		TweenService:Create(cpop, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		local tw = TweenService:Create(cpop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		tw.Completed:Connect(function() if cTok == my then cbb.Enabled = false end end)
		tw:Play()
	end
end
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
losParams.RespectCanCollide = true
local function updateCollect()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local best: CR?, bd = nil, CLOSE
	local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
	if hrp and camPos then
		for _, c in crates :: { CR } do
			local niche = c.plot.Parent and c.plot.Parent.Parent
			if c.crate.Parent and niche and niche:GetAttribute("OwnerUserId") == player.UserId and c.plot:GetAttribute("Unlocked") == true then
				local d = (camPos - c.floor.Position).Magnitude
				if d < bd then best, bd = c, d end
			end
		end
	end
	-- кнопка малюється поверх усього (AlwaysOnTop — щоб не ховалась у власному ящику), тому самі перевіряємо,
	-- чи її не затуляє стіна / табло: промінь від камери до кнопки (лише тверді деталі, без свого персонажа й ящика)
	if best and camPos then
		local target = best.floor.Position + Vector3.new(0, best.height + 2.05 + CB_SH / 2, 0)
		losParams.FilterDescendantsInstances = { char :: Instance, best.crate }
		local dir = target - camPos
		local hit = workspace:Raycast(camPos, dir, losParams)
		if hit and (hit.Position - camPos).Magnitude < dir.Magnitude - 1 then best = nil end
	end
	near = best
	showCollect(best ~= nil)
	if best then
		cbb.Adornee = best.floor
		-- напис «N / CAP» — центр на height + 1.2, висота 1.6 стада → верх на height + 2.0; кнопка одразу над ним
		cbb.StudsOffsetWorldSpace = Vector3.new(0, best.height + 2.05 + CB_SH / 2, 0)
		local empty = ((best.plot:GetAttribute("CrateCount") :: number?) or 0) <= 0
		if empty ~= lastEmpty then
			lastEmpty = empty
			cbtn:setColor(if empty then "gray" else "green")
			cbtn:setText(if empty then "EMPTY" else "COLLECT")
		end
	end
end

-- ===================== закриті плоти =====================
local function setupPlot(m: Model)
	-- діти моделі можуть реплікуватися трохи пізніше за саму модель
	local tint = m:WaitForChild("LockedTint", 10) :: BasePart?
	local lab = m:WaitForChild("Label", 10)
	local gui = lab and lab:WaitForChild("PlotLabel", 10)
	local status = gui and gui:WaitForChild("Status", 10) :: TextLabel?
	local function apply()
		local niche = m.Parent and m.Parent.Parent
		local owned = niche and (niche:GetAttribute("OwnerUserId") or 0) ~= 0
		local open = m:GetAttribute("Unlocked") == true
		if tint then tint.Transparency = if open then 1 else 0.4 end
		if status then status.Text = if open or not owned then "" else "LOCKED" end
	end
	apply()
	m:GetAttributeChangedSignal("Unlocked"):Connect(apply)
	local crate = m:WaitForChild("Crate", 10)
	if crate and crate:IsA("Model") then task.spawn(setupCrate, m, crate) end
	local niche = m.Parent and m.Parent.Parent
	if niche then niche:GetAttributeChangedSignal("OwnerUserId"):Connect(apply) end
end

-- ===================== підписка на ніші =====================
local function onDesc(d: Instance)
	local parent = d.Parent
	if not parent then return end
	if d:IsA("Model") then
		if parent.Name == "Golems" then task.spawn(addGolem, d)
		elseif parent.Name == "Ores" then task.spawn(addOre, d)
		elseif parent.Name == "Drops" then task.spawn(addStack, d)
		elseif parent.Name == "Plots" and d:GetAttribute("PlotIndex") then task.spawn(setupPlot, d)
		end
	end
end

local niches = workspace:WaitForChild("Niches")
niches.DescendantAdded:Connect(onDesc)
for _, d in niches:GetDescendants() do onDesc(d) end
-- ніші перебудовуються (Niches можуть замінити цілком)
workspace.ChildAdded:Connect(function(c)
	if c.Name == "Niches" and c ~= niches then
		niches = c
		c.DescendantAdded:Connect(onDesc)
		for _, d in c:GetDescendants() do onDesc(d) end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	updateGolems(dt)
	updateStacks()
	updateCollect()
end)
