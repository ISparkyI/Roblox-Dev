--!strict
-- ItemViewport — 3D-іконки предметів у слотах: замість PNG у ImageLabel показуємо ViewportFrame з тією самою
-- Union-моделлю, що лежить на піддонах кузні (ReplicatedStorage/Prefabs/ForgeProps).
-- Де: ReplicatedStorage/Shared/ItemViewport. Використання: ItemViewport.set(imageLabel, key) — після того, як код
--   виставив label.Image. Якщо для key є модель — Image очищується, а всередині label з'являється Frame «ItemVP»:
--   темний контур (8 силуетів, зсунутих на OUTLINE px) + сама модель. Модель більша за картинку (SCALE).
--   ImageTransparency / ImageColor3 мітки повторюються на моделі (сірий і напівпрозорий «порожній» слот).
--   Якщо моделі немає (зілля, големи…) — ItemVP ховається і працює звичайна картинка.

local RS = game:GetService("ReplicatedStorage")

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

function M.has(key: string?): boolean
	return key ~= nil and MODELS[key] ~= nil
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
	local name = key and MODELS[key]
	local box = label:FindFirstChild("ItemVP") :: Frame?
	if not name then
		if box then box.Visible = false end
		return
	end
	label.Image = "" -- стара PNG-картинка більше не показується
	if box and box:GetAttribute("Model") ~= name then box:Destroy(); box = nil end
	if not box then box = build(label, name) end
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
