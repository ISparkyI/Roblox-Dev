-- StyleA — кнопки, плитки й чипи «стиль A» з картинок (GDD «2D іконки», розділи 2 «Кнопки — стиль A» і 3 «Плитки й чипи»).
-- Де: ReplicatedStorage/Shared/StyleA (ModuleScript). Підключають ForgeWindow, ForgeClient, RollUpgradeUI:
--   local StyleA = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StyleA"))
-- Що всередині елемента (знизу догори):
--   1. Основа — PNG 400 × 200 (еталон 200 × 100 × 2): контур, світла рамка, грань з градієнтом і м'яким світлом, світла
--      лінія, губа. Без візерунка й напису. ImageButton (клікабельний) або ImageLabel, ScaleType = Slice,
--      SliceCenter = Rect(14, 14, 386, 160) (пікселі PNG), SliceScale = (H / 100) / 2, де H — висота в одиницях дизайну.
--   2. Грань — Frame з ClipsDescendants рівно над гранню; у ній візерунок «квадратик + L»: ImageLabel ScaleType = Tile,
--      PNG 128 × 128 = 2 × 2 клітинки, TileSize = 2 · клітинка; клітинка = висота грані / 4 (кнопки, плитки) або / 3
--      (чипи й малі кнопки, h < 70). Сітка від верху грані, по горизонталі по центру (зсув (ширина mod клітинка) / 2).
--      Кнопки — тайл повної сили (green / gray / red), плитки й чипи — половинної (*_half).
--   3. Іконка (ImageLabel, Fit) у межах грані з відступом iconPad · висота грані (0,06), напис (TextLabel, Montserrat
--      Heavy, білий, UIStroke #14161a Contextual ≈ 0,08 розміру шрифту) — по центру грані (не губи).
--   4. Відблиск (лише клікабельні кнопки, opts.shine ~= false) — ShineClip: Frame з ClipsDescendants рівно над гранню,
--      ZIndex 3 (над іконкою 2, під написом 4); у ньому білий Frame «Shine» з UIGradient (Rotation 25, широка й тонка
--      косі смуги). Раз на випадкові 4–8 с (перший — через 1–4 с, у кожної кнопки свій ритм) Offset градієнта їде
--      −1,3 → 1,3 за 1,8 с (Sine InOut) — смуга світла проходить зліва направо. Тільки коли колір не gray і кнопка на екрані.
-- Геометрія грані для висоти H (k = H / 100; O 4, B 3, губа 12, лінія 4 — еталон h = 100):
--   x = y = (O + B) · k, ширина = W − 2 (O + B) · k, висота = H − (O + губа + лінія) · k − (O + B) · k.
-- Розміри — в одиницях дизайну батька (Offset). На екрані масштабує UIScale предка, тому SliceScale рахуємо від
--   дизайнової висоти H, а не від AbsoluteSize. Без заокруглень (жодних UICorner).
-- ID картинок: ASSETS нижче — справжні ID, завантажені через Asset Manager; ключі = імена файлів з ui/buttons_v2/assets без .png.
--
-- API:
--   StyleA.new(parent, opts) → об'єкт. opts:
--     size = Vector2 (w, h); position = Vector2 (лівий верхній кут) або UDim2 (як є, разом з anchor);
--     anchor = Vector2 (за замовчуванням 0,5; 0,5 — щоб UIScale наведення / натискання масштабував від центру);
--     color = "green" | "gray" | "red" | "blue" | "orange" | "yellow" | "purple" | "ore_coal" | "ore_copper" | "ore_iron";
--     half = true — візерунок половинної сили (плитки, чипи); rows = 4 | 3 (за замовчуванням 4 при h ≥ 70, інакше 3);
--     text, textSize (за замовчуванням 0,52 висоти грані), textStroke (за замовчуванням 0,08 · textSize);
--     icon = assetId, iconPad = 0,06 (частка висоти грані; від'ємна — іконка більша за грань);
--     clickable = true → ImageButton; zIndex; name; shine = false — без відблиску (за замовчуванням є в клікабельних).
--   Поля: .root (ImageButton / ImageLabel), .button (= root, якщо клікабельний), .face, .tile, .icon, .label, .scale (UIScale),
--     .color, .w, .h, .enabled (true), .hover, .shaking.
--   Методи: :setColor(name) (основа + тайл, сила візерунка та сама), :setText(s), :setIcon(id), :setSize(Vector2),
--     :setPosition(Vector2 | UDim2), :destroy().
--   StyleA.bind(obj, opts) — поведінка кнопки (GDD): наведення — масштаб 1,04 (0,1 с); натискання — 0,92 і пружне
--     повернення (Back, 0,2 с); якщо не можна — хитання −10, 10, −7, 7, −3, 0 px по 0,03 с. opts:
--     canClick = function() → boolean (за замовчуванням obj.enabled); onClick = function(obj); debounce = секунди між діями;
--     hoverAlways = true — збільшувати при наведенні й тоді, коли дія недоступна. Повертає список з'єднань.
--   StyleA.shake(obj), StyleA.faceRect(w, h) → x, y, fw, fh; StyleA.sliceScale(h).

local TweenService = game:GetService("TweenService")

local StyleA = {}

StyleA.ASSETS = {
	-- 9-slice основи (без візерунка й напису)
	stylea_base_green = "rbxassetid://73269138650834",
	stylea_base_gray = "rbxassetid://103290422229133",
	stylea_base_red = "rbxassetid://75213556414551",
	stylea_base_blue = "rbxassetid://103206255254580",
	stylea_base_orange = "rbxassetid://99325442141416",
	stylea_base_yellow = "rbxassetid://128897335984391",
	stylea_base_purple = "rbxassetid://93955169790869",
	stylea_base_ore_coal = "rbxassetid://82195498687835",
	stylea_base_ore_copper = "rbxassetid://85543755746970",
	stylea_base_ore_iron = "rbxassetid://80741955091366",
	-- тайли візерунка повної сили (кнопки)
	stylea_tile_green = "rbxassetid://126934743767489",
	stylea_tile_gray = "rbxassetid://103426287107550",
	stylea_tile_red = "rbxassetid://127394882942605",
	-- тайли візерунка половинної сили (плитки й чипи)
	stylea_tile_green_half = "rbxassetid://128344900362622",
	stylea_tile_gray_half = "rbxassetid://113147180553208",
	stylea_tile_blue_half = "rbxassetid://113459856671982",
	stylea_tile_orange_half = "rbxassetid://113641944698053",
	stylea_tile_yellow_half = "rbxassetid://113083714872033",
	stylea_tile_purple_half = "rbxassetid://109882000828143",
	stylea_tile_ore_coal_half = "rbxassetid://108891956368661",
	stylea_tile_ore_copper_half = "rbxassetid://105948771467063",
	stylea_tile_ore_iron_half = "rbxassetid://75367734687427",
	-- іконки
	stylea_icon_x = "rbxassetid://124007225953986",       -- білий X з темним контуром (кнопка закриття)
	forge_ore_coal_v2 = "rbxassetid://128721473962141",   -- нові іконки руди
	forge_ore_copper_v2 = "rbxassetid://91559856120750",
	forge_ore_iron_v2 = "rbxassetid://89358844969060",
	forge_bar_iron_v2 = "rbxassetid://103278698396779",   -- новий злиток заліза (вугілля й мідь — старі ID у скриптах)
}
local ASSETS = StyleA.ASSETS

-- еталон основи (h = 100): контур, світла рамка, губа, світла лінія
local O, B, LIP, LINE = 4, 3, 12, 4
StyleA.SLICE_CENTER = Rect.new(14, 14, 386, 160)
local SLICE_CENTER = StyleA.SLICE_CENTER

local INK = Color3.fromHex("14161a")
local WHITE = Color3.new(1, 1, 1)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local SHAKE = { -10, 10, -7, 7, -3, 0 }

-- відблиск: широка й тонка косі смуги; спокій — за лівим краєм, прохід — до правого
local SHINE_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.15),
	NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.35),
	NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1),
})
local SHINE_REST = Vector2.new(-1.3, 0)
local SHINE_END = Vector2.new(1.3, 0)
local SHINE_INFO = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- прямокутник грані (одиниці дизайну) для елемента w × h
function StyleA.faceRect(w: number, h: number): (number, number, number, number)
	local k = h / 100
	local e = (O + B) * k
	return e, e, w - 2 * e, h - (O + LIP + LINE) * k - e
end
-- SliceScale для дизайнової висоти h: кути PNG намальовані ×2 від еталона h = 100
function StyleA.sliceScale(h: number): number
	return (h / 100) / 2
end

local function baseId(color: string): string
	return ASSETS["stylea_base_" .. color] or ASSETS.stylea_base_gray
end
-- тайл потрібної сили; якщо такого немає — інша сила того ж кольору, далі сірий
local function tileId(color: string, half: boolean): string
	local a = ASSETS["stylea_tile_" .. color .. (half and "_half" or "")]
	return a or ASSETS["stylea_tile_" .. color .. (half and "" or "_half")] or (half and ASSETS.stylea_tile_gray_half or ASSETS.stylea_tile_gray)
end

local function new(class: string, props, parent: Instance?)
	local o = Instance.new(class)
	for k, v in props do (o :: any)[k] = v end
	if parent then o.Parent = parent end
	return o
end

local Obj = {}
Obj.__index = Obj

-- перерахувати SliceScale, грань, тайл, іконку й напис під поточний розмір
function Obj:_layout()
	local w, h = self.w, self.h
	local fx, fy, fw, fh = StyleA.faceRect(w, h)
	self.root.Size = UDim2.fromOffset(w, h)
	self.root.SliceScale = StyleA.sliceScale(h)
	self.face.Position = UDim2.fromOffset(fx, fy)
	self.face.Size = UDim2.fromOffset(fw, fh)
	local cell = fh / (self.rows or (h >= 70 and 4 or 3))
	local t = 2 * cell
	-- сітка по центру: перший стовпчик з (fw mod cell) / 2; тайл починаємо на 2 клітинки лівіше, фаза та сама
	local ox = (fw % cell) / 2 - t
	self.tile.Position = UDim2.fromOffset(ox, 0)
	self.tile.Size = UDim2.fromOffset(fw - ox, fh)
	self.tile.TileSize = UDim2.fromOffset(t, t)
	if self.icon then
		local m = self.iconPad * fh
		self.icon.Position = UDim2.fromOffset(fx + m, fy + m)
		self.icon.Size = UDim2.fromOffset(fw - 2 * m, fh - 2 * m)
	end
	if self.label then
		local ts = self.textSize or math.floor(fh * 0.52 + 0.5)
		self.label.Position = UDim2.fromOffset(fx, fy)
		self.label.Size = UDim2.fromOffset(fw, fh)
		self.label.TextSize = ts
		self.labelStroke.Thickness = self.textStroke or ts * 0.08
	end
	if self.shineClip then
		self.shineClip.Position = UDim2.fromOffset(fx, fy)
		self.shineClip.Size = UDim2.fromOffset(fw, fh)
	end
end

function Obj:_place()
	local p = self.pos
	if typeof(p) == "Vector2" then
		local a = self.anchor
		self.root.Position = UDim2.fromOffset(p.X + self.w * a.X, p.Y + self.h * a.Y)
	elseif typeof(p) == "UDim2" then
		self.root.Position = p
	end
end

function Obj:setColor(name: string)
	if name == self.color then return end
	self.color = name
	self.root.Image = baseId(name)
	self.tile.Image = tileId(name, self.half)
	-- сіра кнопка не блищить: обриваємо прохід, якщо він саме йде
	if name == "gray" and self.shineTween then
		self.shineTween:Cancel()
		self.shineGrad.Offset = SHINE_REST
	end
end

function Obj:setText(s: string)
	if not self.label then
		self.label = new("TextLabel", { Name = "Label", BackgroundTransparency = 1, FontFace = HEAVY, Text = "", TextColor3 = WHITE,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Active = false, ZIndex = 4 }, self.root)
		self.labelStroke = new("UIStroke", { Color = INK, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Round,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, self.label)
		self:_layout()
	end
	if self.label.Text ~= s then self.label.Text = s end
end

function Obj:setIcon(id: string?)
	if not self.icon then
		self.icon = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Active = false, ZIndex = 2 }, self.root)
		self:_layout()
	end
	self.icon.Image = id or ""
end

function Obj:setSize(v: Vector2)
	if v.X == self.w and v.Y == self.h then return end
	self.w, self.h = v.X, v.Y
	self:_layout()
	self:_place()
end

function Obj:setPosition(p: Vector2 | UDim2)
	self.pos = p
	self:_place()
end

function Obj:destroy()
	self.root:Destroy()
end

-- ===== відблиск: один спільний планувальник на весь модуль =====
-- реєстр кнопок з відблиском (слабкі ключі — знищені й забуті кнопки не тримаємо); у кожної свій час наступного проходу
local shineSet = setmetatable({}, { __mode = "k" })
local shineRng = Random.new()
local shineLoop = false

-- кнопка справді на екрані: у грі, її LayerCollector (ScreenGui / SurfaceGui) увімкнений, ненульовий розмір,
-- і вона сама та всі предки-GuiObject видимі
local function onScreen(root: GuiObject): boolean
	if not root:IsDescendantOf(game) or root.AbsoluteSize.X <= 0 then return false end
	local lc = root:FindFirstAncestorWhichIsA("LayerCollector")
	if not lc or not lc.Enabled then return false end
	local p: Instance? = root
	while p and p ~= lc do
		if p:IsA("GuiObject") and not p.Visible then return false end
		p = p.Parent
	end
	return true
end

-- раз на 0,2 с: кому настав час — прохід (якщо можна), інакше перенос на 1–4 с, щоб після появи вікна кнопки не блиснули разом
local function shineStep()
	local now = os.clock()
	for obj in shineSet do
		if now >= obj.shineNext then
			if obj.color ~= "gray" and obj.shineTween.PlaybackState ~= Enum.PlaybackState.Playing and onScreen(obj.root) then
				obj.shineGrad.Offset = SHINE_REST
				obj.shineTween:Play()
				obj.shineNext = now + shineRng:NextNumber(4, 8)
			else
				obj.shineNext = now + shineRng:NextNumber(1, 4)
			end
		end
	end
end

local function addShine(self)
	local clip = new("Frame", { Name = "ShineClip", BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		Active = false, ZIndex = 3 }, self.root)
	local shine = new("Frame", { Name = "Shine", BackgroundColor3 = WHITE, BackgroundTransparency = 0, BorderSizePixel = 0,
		Active = false, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, clip)
	local grad = new("UIGradient", { Color = ColorSequence.new(WHITE), Transparency = SHINE_TRANSPARENCY, Rotation = 25,
		Offset = SHINE_REST }, shine)
	local tw = TweenService:Create(grad, SHINE_INFO, { Offset = SHINE_END })
	-- після проходу — одразу назад за лівий край (один твін на кнопку, без нових щокадру)
	tw.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then grad.Offset = SHINE_REST end
	end)
	self.shineClip, self.shine, self.shineGrad, self.shineTween = clip, shine, grad, tw
	self.shineNext = os.clock() + shineRng:NextNumber(1, 4)
	shineSet[self] = true
	-- знищена кнопка (сама чи разом з предком) — геть з реєстру
	self.root.Destroying:Connect(function()
		shineSet[self] = nil
		tw:Cancel()
	end)
	if not shineLoop then
		shineLoop = true
		task.spawn(function()
			while true do
				task.wait(0.2)
				shineStep()
			end
		end)
	end
end

function StyleA.new(parent: Instance?, opts)
	opts = opts or {}
	local size: Vector2 = opts.size or Vector2.new(200, 100)
	local clickable = opts.clickable == true
	local root = new(clickable and "ImageButton" or "ImageLabel", { Name = opts.name or (clickable and "StyleAButton" or "StyleA"),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Slice, SliceCenter = SLICE_CENTER,
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5), ZIndex = opts.zIndex or 1 })
	if clickable then (root :: ImageButton).AutoButtonColor = false end
	local face = new("Frame", { Name = "Face", BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Active = false, ZIndex = 1 }, root)
	local tile = new("ImageLabel", { Name = "Pattern", BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Tile,
		Active = false, ZIndex = 1 }, face)
	local self = setmetatable({
		root = root, button = clickable and root or nil, face = face, tile = tile, icon = nil, label = nil, labelStroke = nil,
		scale = new("UIScale", {}, root), color = nil, half = opts.half == true, rows = opts.rows,
		w = size.X, h = size.Y, anchor = opts.anchor or Vector2.new(0.5, 0.5), pos = opts.position or Vector2.zero,
		iconPad = opts.iconPad or 0.06, textSize = opts.textSize, textStroke = opts.textStroke,
		enabled = true, hover = false, shaking = false,
	}, Obj)
	if clickable and opts.shine ~= false then addShine(self) end
	self:setColor(opts.color or "green")
	self:_layout()
	self:_place()
	if opts.icon then self:setIcon(opts.icon) end
	if opts.text then self:setText(opts.text) end
	if parent then root.Parent = parent end
	return self
end

-- ===== поведінка кнопки =====
local function scaleTo(obj, s: number, t: number, style: Enum.EasingStyle)
	TweenService:Create(obj.scale, TweenInfo.new(t, style, Enum.EasingDirection.Out), { Scale = s }):Play()
end

-- хитання недоступної кнопки (не накладається саме на себе; повертає кнопку на місце, з якого почало)
function StyleA.shake(obj)
	if obj.shaking then return end
	obj.shaking = true
	local root = obj.root
	local p0 = root.Position
	task.spawn(function()
		for _, dx in SHAKE do root.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		root.Position = p0
		obj.shaking = false
	end)
end

function StyleA.bind(obj, opts)
	opts = opts or {}
	local btn = obj.button
	assert(btn, "StyleA.bind: елемент не клікабельний (clickable = true)")
	local canClick = opts.canClick or function() return obj.enabled end
	local debounce = opts.debounce or 0
	local lastFire = 0
	local conns = {}
	table.insert(conns, btn.MouseEnter:Connect(function()
		obj.hover = true
		if opts.hoverAlways or canClick() then scaleTo(obj, 1.04, 0.1, Enum.EasingStyle.Quad) end
	end))
	table.insert(conns, btn.MouseLeave:Connect(function()
		obj.hover = false
		scaleTo(obj, 1, 0.1, Enum.EasingStyle.Quad)
	end))
	table.insert(conns, btn.Activated:Connect(function()
		if canClick() then
			obj.scale.Scale = 0.92
			scaleTo(obj, 1, 0.2, Enum.EasingStyle.Back)
			if opts.onClick and os.clock() - lastFire > debounce then
				lastFire = os.clock()
				opts.onClick(obj)
			end
		else
			StyleA.shake(obj)
		end
	end))
	return conns
end

return StyleA
