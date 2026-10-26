--!strict
-- ItemViewport — 3D-іконки предметів у слотах: замість PNG у ImageLabel показуємо ViewportFrame з тією самою
-- Union-моделлю, що лежить на піддонах кузні (ReplicatedStorage/Prefabs/ForgeProps).
-- Де: ReplicatedStorage/Shared/ItemViewport. Використання: ItemViewport.set(imageLabel, key) — після того, як код
--   виставив label.Image. Якщо для key є модель — Image очищується, а всередині label з'являється Frame «ItemVP»:
--   темний контур (8 силуетів, зсунутих на OUTLINE px) + сама модель. Модель більша за картинку (SCALE).
--   ImageTransparency / ImageColor3 мітки повторюються на моделі (сірий і напівпрозорий «порожній» слот).
--   Якщо моделі немає (зілля, голем без моделі…) — ItemVP ховається і працює звичайна картинка.
-- Големи: ключ "GolemVP:<ID>:<клас>" (M.golemKey) — модель з каталогу (Shared/GolemCatalog, поле model → PlotAssets/<model>),
--   стоїть у 3/4 обличчям до камери; майнер — з кіркою, носій — без кірки, з ящичком біля ніг. Контур — 4 силуети (не 8: модель важка).

local RS = game:GetService("ReplicatedStorage")
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))

local M = {}

local MODELS: { [string]: string } = {
	Ore_Coal = "ChunkCoal", Ore_Copper = "ChunkCopper", Ore_Iron = "ChunkIron",
	Bars_Copper = "BarCopper", Bars_Iron = "BarIron",
}
-- ракурс: { поворот навколо Y, нахил камери (градуси), FIT (більше — модель менша), зсув угору (частка висоти) }
local VIEW: { [string]: { number } } = {
	ChunkCoal = { 30, 30, 0.8, 0 }, ChunkCopper = { 30, 24, 0.842, 0.07 }, ChunkIron = { 30, 30, 0.842, 0.07 }, -- −5 % від 0.8
	BarCopper = { 32, 34, 1.08, 0.02 }, BarIron = { 32, 34, 1.08, 0.02 },
}
local FOV = 26
local SCALE = 1.45 -- розмір моделі відносно ImageLabel (у плитках PNG мала поля)
local FIT = 0.8    -- 1 = модель уписана в сферу; менше — ближче
local OUTLINE = 2  -- товщина контуру, px (UIScale вікна масштабує й її)
local INK = Color3.fromHex("14161a")

local function props(): Instance?
	local p = RS:FindFirstChild("Prefabs")
	return p and p:FindFirstChild("ForgeProps")
end

-- голем: ключ для set(), або nil, якщо 3D-моделі цього голема ще немає
function M.golemKey(kind: string?, cls: string?): string?
	local g = Catalog.get(kind)
	if not g or not g.model then return nil end
	return "GolemVP:" .. g.id .. ":" .. Catalog.cls(cls)
end
local function golemSpec(key: string?): (any, string?)
	if not key or string.sub(key, 1, 8) ~= "GolemVP:" then return nil, nil end
	local id, cls = string.match(key, "^GolemVP:(%w+):(%w+)$")
	local g = Catalog.get(id)
	if not g or not g.model then return nil, nil end
	return g, cls
end

function M.has(key: string?): boolean
	return key ~= nil and (MODELS[key] ~= nil or golemSpec(key) ~= nil)
end

-- ===== голем у ViewportFrame =====
-- ракурс голема: yaw / pitch — градуси, fit — більше = менший, up — точка прицілу вище центру (частка висоти; модель нижче в слоті,
-- щоб не налазила на назву); світло — спереду зліва (ззаду обличчя виходило темним)
local GOLEM_VIEW = { yaw = 20, pitch = 8, fit = 0.8, up = 0.07 } -- fit 0.8 = на 10 % менше, ніж 0.72
local GOLEM_AMBIENT = Color3.fromRGB(185, 185, 190)
local GOLEM_LIGHT = Vector3.new(-0.4, -0.7, 0.6)
local golemCache: { [string]: Model } = {}
-- шаблон: модель без скриптів, стоїть у (0,0,0) обличчям до −Z; носій — без кірки, з ящичком біля ніг
local function golemTemplate(g: any, cls: string): Model?
	local ck = g.id .. ":" .. cls
	if golemCache[ck] then return golemCache[ck] end
	local assets = RS:FindFirstChild("PlotAssets")
	local src = assets and assets:FindFirstChild(g.model)
	if not src or not src:IsA("Model") then return nil end
	local m = src:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("ValueBase") then d:Destroy() end
	end
	if cls ~= "miner" then
		local pick = m:FindFirstChild("Pickaxe"); if pick then pick:Destroy() end
	end
	m:PivotTo(CFrame.new())
	if cls == "carrier" then
		local box = assets:FindFirstChild("CarryBox")
		if box and box:IsA("Model") then
			local b = box:Clone()
			for _, d in b:GetDescendants() do if d:IsA("LuaSourceContainer") then d:Destroy() end end
			local _, gs = m:GetBoundingBox()
			local _, bs = b:GetBoundingBox()
			local k = math.min(1, gs.X * 0.55 / math.max(bs.X, bs.Z))
			b:ScaleTo(b:GetScale() * k)
			local _, bs2 = b:GetBoundingBox()
			local gcf, gs2 = m:GetBoundingBox()
			b:PivotTo(CFrame.new(gcf.Position.X + gs2.X * 0.18, gcf.Position.Y - gs2.Y / 2 + bs2.Y / 2, gcf.Position.Z - gs2.Z / 2 - bs2.Z * 0.15))
			b.Parent = m
		end
	end
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
	golemCache[ck] = m
	return m
end

local function golemViewport(parent: Instance, tpl: Model, z: number, silhouette: boolean, dx: number, dy: number): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Position = UDim2.fromOffset(dx, dy)
	vp.ZIndex = z
	local m = tpl:Clone()
	if silhouette then
		vp.Name = "Outline"
		vp.Ambient = Color3.new(0, 0, 0); vp.LightColor = Color3.new(0, 0, 0)
		vp.ImageColor3 = INK
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = Color3.new(0, 0, 0); d.Material = Enum.Material.SmoothPlastic; d.MaterialVariant = ""
				if d.Transparency < 1 then d.Transparency = 0 end
				for _, t in d:GetChildren() do if t:IsA("Decal") or t:IsA("Texture") then t:Destroy() end end
			end
		end
	else
		vp.Name = "Model"
		vp.Ambient = GOLEM_AMBIENT
		vp.LightColor = Color3.fromRGB(255, 252, 245)
		vp.LightDirection = GOLEM_LIGHT
	end
	m.Parent = vp
	local cf, size = m:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = FOV
	local r = size.Magnitude / 2
	local dist = r / math.sin(math.rad(FOV / 2)) * GOLEM_VIEW.fit
	-- обличчя дивиться в −Z: камера спереду (−Z), повернута на yaw і трохи згори
	local dir = (CFrame.Angles(0, math.rad(180 + GOLEM_VIEW.yaw), 0) * CFrame.Angles(-math.rad(GOLEM_VIEW.pitch), 0, 0)).LookVector
	local target = cf.Position + Vector3.new(0, size.Y * GOLEM_VIEW.up, 0)
	cam.CFrame = CFrame.lookAt(target - dir * dist, target)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	return vp
end

local function buildGolem(label: GuiObject, key: string, g: any, cls: string): Frame?
	local tpl = golemTemplate(g, cls)
	if not tpl then return nil end
	local box = Instance.new("Frame")
	box.Name = "ItemVP"
	box.BackgroundTransparency = 1
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(SCALE, SCALE)
	box.ZIndex = label.ZIndex
	box:SetAttribute("Model", key)
	box:SetAttribute("Golem", true)
	for _, d in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
		golemViewport(box, tpl, label.ZIndex, true, d[1] * OUTLINE, d[2] * OUTLINE)
	end
	golemViewport(box, tpl, label.ZIndex, false, 0, 0)
	box.Parent = label
	return box
end

local function viewport(parent: Instance, tpl: BasePart, name: string, z: number, silhouette: boolean, dx: number, dy: number): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Position = UDim2.fromOffset(dx, dy)
	vp.ZIndex = z
	if silhouette then
		vp.Name = "Outline"
		vp.Ambient = Color3.new(0, 0, 0); vp.LightColor = Color3.new(0, 0, 0)
		vp.ImageColor3 = INK
	else
		vp.Name = "Model"
		vp.Ambient = Color3.fromRGB(150, 150, 155)
		vp.LightColor = Color3.fromRGB(255, 252, 245)
		vp.LightDirection = Vector3.new(-0.6, -1, -0.45)
	end
	local part = tpl:Clone() :: BasePart
	part.Anchored = true
	part.CFrame = CFrame.new(0, 0, 0)
	if silhouette then
		local u = part :: any
		if u:IsA("UnionOperation") then u.UsePartColor = true end
		part.Color = Color3.new(0, 0, 0); part.MaterialVariant = ""; part.Material = Enum.Material.SmoothPlastic
	end
	part.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = FOV
	local v = VIEW[name] or { 30, 30, FIT, 0 }
	local r = part.Size.Magnitude / 2
	local dist = r / math.sin(math.rad(FOV / 2)) * (v[3] or FIT)
	local dir = (CFrame.Angles(0, math.rad(v[1]), 0) * CFrame.Angles(-math.rad(v[2]), 0, 0)).LookVector
	cam.CFrame = CFrame.lookAt(-dir * dist, Vector3.zero)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	return vp
end

local function build(label: GuiObject, name: string): Frame?
	local src = props()
	local tpl = src and src:FindFirstChild(name)
	if not tpl or not tpl:IsA("BasePart") then return nil end
	local box = Instance.new("Frame")
	box.Name = "ItemVP"
	box.BackgroundTransparency = 1
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5 - ((VIEW[name] or {})[4] or 0)) -- мідь і залізо трохи вище: не налазять на низ плитки
	box.Size = UDim2.fromScale(SCALE, SCALE)
	box.ZIndex = label.ZIndex
	box:SetAttribute("Model", name)
	for _, d in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		viewport(box, tpl, name, label.ZIndex, true, d[1] * OUTLINE, d[2] * OUTLINE)
	end
	viewport(box, tpl, name, label.ZIndex, false, 0, 0)
	box.Parent = label
	return box
end

local bound: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function sync(label: ImageLabel, box: Frame)
	for _, v in box:GetChildren() do
		if v:IsA("ViewportFrame") then
			v.ImageTransparency = label.ImageTransparency
			if v.Name == "Model" then v.ImageColor3 = label.ImageColor3 end
		end
	end
end

-- scale (необов'язково) — розмір моделі відносно мітки; за замовчуванням SCALE (для плиток), 1 — рівно в межах мітки
function M.set(label: ImageLabel, key: string?, scale: number?)
	local g, cls = golemSpec(key)
	local name = (key and MODELS[key]) or (g and key)
	local box = label:FindFirstChild("ItemVP") :: Frame?
	if not name then
		if box then box.Visible = false end
		return
	end
	label.Image = "" -- стара PNG-картинка більше не показується
	if box and box:GetAttribute("Model") ~= name then box:Destroy(); box = nil end
	if not box then
		if g then box = buildGolem(label, name :: string, g, cls or "miner") else box = build(label, name :: string) end
	end
	if not box then return end
	box.Visible = true
	local s = scale or SCALE
	box.Size = UDim2.fromScale(s, s)
	sync(label, box)
	if not bound[label] then
		bound[label] = true
		local function re()
			local b = label:FindFirstChild("ItemVP") :: Frame?
			if b then sync(label, b) end
		end
		label:GetPropertyChangedSignal("ImageTransparency"):Connect(re)
		label:GetPropertyChangedSignal("ImageColor3"):Connect(re)
	end
end

return M
