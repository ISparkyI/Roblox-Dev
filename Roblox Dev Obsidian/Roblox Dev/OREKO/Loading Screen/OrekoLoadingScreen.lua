-- OrekoLoadingScreen (ReplicatedFirst, LocalScript)
-- Загрузочний екран студії OSIRIUS (до 27.10.2026 — OREKO; внутрішні імена Oreko* лишились). Порт веб-макета oreko_splash.html v3.4.
-- Логотип (камінь + кірка «MADE BY» + назва OSIRIUS) однаковий для всіх плейсів; фон/кольори можна міняти в CONFIG.
-- Координати — у «юнітах» макета (сцена 1000 × 562.5), UIScale підганяє під екран.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

ReplicatedFirst:RemoveDefaultLoadingScreen()

----------------------------------------------------------------- CONFIG (на кожному плейсі своє)
local CONFIG = {
	bgColor = Color3.fromHex("22262d"),
	bgDrift = Vector2.new(-16, 30), -- юнітів/сек: вниз і трохи вліво
	barFill = { Color3.fromHex("d8ff7a"), Color3.fromHex("7fe23a"), Color3.fromHex("38ad24") },
	fillSpeed = 0.45, -- максимальна швидкість шкали (частка/сек) → 0→100 % не швидше ніж за ~2.2 с
	waitCharacter = true, -- 100 % лише коли з'явився персонаж
	maxWait = 30, -- аварійний вихід (с)
}

----------------------------------------------------------------- ASSETS (логотип студії OSIRIUS, спільні для всіх плейсів)
-- картинки логотипу збережені з «alpha bleeding» (прозорі пікселі мають колір сусідів) — без цього Roblox дає білі обводки на краях
local IMG = {
	stone = "rbxassetid://127704892563527",
	stoneFront = "rbxassetid://133096195629658", -- камінь нижче верхнього контуру на 12: малюється ПОВЕРХ кірки, щоб вона входила в камінь
	stoneWhite = "rbxassetid://125310278434531",
	chunks = "rbxassetid://138434949413118",
	cracks = "rbxassetid://110834004357008",
	pick = "rbxassetid://79073653865153",
	pickWhite = "rbxassetid://75484105669816",
	bgTile = "rbxassetid://114055270976915",
	studsTile = "rbxassetid://134764452695368",
	vignette = "rbxassetid://84008052171508",
	name = "rbxassetid://129333938588274", -- назва OSIRIUS картинкою (Montserrat 900 у контурах): текст Roblox розмивається на великих розмірах (до 27.10.2026 OREKO: 101967857130070)
	nameGlow = "rbxassetid://92089445415596", -- (OREKO: 95840774309233)
}
-- звук удару кірки — той самий, що коли големи б'ють руду (ReplicatedStorage/PlotAssets/PickaxeHit, PlotClient: гучність 2 у 3D,
-- висота ×0,9–1,1). Тут 2D-звук, тому гучність менша (як удар з ~20 стадів у грі).
local HIT_SFX = { id = "rbxassetid://9120146349", volume = 0.8 }
-- тріск каменю, що осипається, на третьому ударі — той самий звук, що й при руйнуванні руди в грі
-- (ReplicatedStorage/PlotAssets/RockBreak, «Shale Break Low End Crackling Rock 2 (SFX)»). Тут числом: ReplicatedFirst стартує раніше за ReplicatedStorage
-- нарізка 0,08–0,58 с (без тиші на початку) і затухання до 0 за останні fade с — як у PlotAssets/RockBreak + PlotClient
local BREAK_SFX = { id = "rbxassetid://9119050441", volume = 0.3, region = NumberRange.new(0.08, 0.58), fade = 0.25 }
-- до цієї частки шкали фонова музика мовчить: далі SoundService атрибут LoadingMusicOK = true (скрипт музики чекає його)
local MUSIC_AT = 0.5
local INK = Color3.fromHex("14161a")
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)

----------------------------------------------------------------- GEOMETRY (з макета / meta.json)
local SC, SCC = 1.4, 0.9
local ST = { x = 150, y = 182, w = 700, h = 274 }
local HIT = Vector2.new(545, 300)
local SIL = { {166,250},{196,214},{290,214},{306,198},{452,198},{468,206},{620,206},{640,188},{770,188},{800,214} }
local CR = { x = 194, y = 204, w = 656, h = 252 }
local HS = 350
local TIPL = Vector2.new(-187.65, -243.23)
local HEADL = Vector2.new(0, -291.6)
local TEXTL = Vector2.new(0, -191.52)
-- x, y, w, h, ax, ay (атлас), vx, vy, vr, delay, cx, cy
local CHUNKS = {
	{153, 207, 88.2, 83.6, 0, 0, -258.9, -264.8, 279.9, 0.151, 187.7, 243.2},
	{209.5, 207, 118.1, 91.9, 92.2, 0, -204.2, -203.6, -137.2, 0.116, 271.3, 245.3},
	{307.1, 207, 101.8, 91.9, 214.3, 0, -151.6, -121.7, 253.1, 0.081, 358.6, 246.1},
	{391, 207, 118.1, 95.8, 320.1, 0, -42.9, -186.8, 209.6, 0.047, 445.7, 247.1},
	{474.1, 207, 135, 95.8, 442.1, 0, -72.2, -251, 252.7, 0.023, 542.3, 244.6},
	{577.1, 207, 98.7, 92.7, 0, 99.8, 83.2, -253.9, 5.2, 0.042, 629.7, 243.8},
	{657, 207, 114.7, 92.7, 102.7, 99.8, 203.1, -202.9, 239.5, 0.074, 715.7, 247.8},
	{758.3, 207, 88.7, 86.5, 221.4, 99.8, 306, -202.3, 174.3, 0.112, 807.5, 245.6},
	{153, 274.2, 88.2, 110.2, 314.1, 99.8, -317.3, -122, -253.2, 0.148, 191.2, 326.1},
	{223.7, 274.2, 93.4, 110.2, 406.4, 99.8, -310.3, -241.5, -219, 0.115, 269.9, 327.9},
	{297.5, 277.6, 123.5, 104, 503.7, 99.8, -190.4, -186.2, -69.1, 0.079, 356.6, 328},
	{391, 277.6, 118.1, 104, 0, 213.9, -90.8, -95.9, -67.7, 0.042, 448.4, 330.6},
	{472.6, 267.5, 137.7, 107.5, 122.1, 213.9, -48, -191.4, 28.4, 0.011, 542.3, 326.5},
	{577.1, 267.5, 89.9, 110.5, 263.8, 213.9, 132.8, -95.9, 268.5, 0.036, 626.5, 327.6},
	{651.5, 283.5, 137.2, 94.6, 357.7, 213.9, 224.2, -229.9, 36.5, 0.073, 717.2, 329.9},
	{761.7, 280.9, 85.3, 107, 498.8, 213.9, 222.6, -247.1, 81.8, 0.112, 812.6, 330.2},
	{153, 355.3, 80.7, 97.7, 0, 328.5, -322.8, -95.7, 18.4, 0.157, 186, 410.9},
	{210.4, 353.9, 129.6, 99.1, 84.7, 328.5, -281.2, -227.2, 38.8, 0.123, 270.4, 410.6},
	{297.5, 353.9, 134.1, 99.1, 218.3, 328.5, -100, -64.5, -190.8, 0.086, 370.1, 409.9},
	{411, 360.4, 114.7, 92.6, 356.4, 328.5, -11.7, -172.4, -118.6, 0.058, 460.2, 411.5},
	{472.6, 360.4, 137.7, 92.6, 475.1, 328.5, 46, -107.8, 212.2, 0.046, 545.3, 409.9},
	{572.7, 365.1, 92, 87.9, 0, 431.6, 69.5, -135.9, -150.5, 0.057, 624.8, 411.8},
	{651.5, 358.2, 137.2, 94.8, 96, 431.6, 100.7, -194.6, 209.1, 0.086, 719, 410.1},
	{771.3, 358.2, 75.7, 94.8, 237.1, 431.6, 209.7, -185.2, -89.5, 0.122, 815, 412.6}
}

----------------------------------------------------------------- MATH
local function cl(v, a, b) return math.max(a, math.min(b, v)) end
local function k(t, a, b) return cl((t - a) / (b - a), 0, 1) end
local function lerp(a, b, t) return a + (b - a) * t end
local ease = {
	out = function(t) return 1 - (1 - t) ^ 3 end,
	in2 = function(t) return t * t end,
	inout = function(t) if t < 0.5 then return 4 * t * t * t end return 1 - (-2 * t + 2) ^ 3 / 2 end,
	back = function(t) local c = 1.7 return 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2 end,
}
local function rotv(v, a)
	local r = math.rad(a)
	local c, s = math.cos(r), math.sin(r)
	return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
end
local function topAt(x)
	for i = 1, #SIL - 1 do
		local a, b = SIL[i], SIL[i + 1]
		if x >= a[1] and x <= b[1] then return lerp(a[2], b[2], (x - a[1]) / math.max(1, b[1] - a[1])) end
	end
	return 200
end

-- swing about the grip G: the strike angle puts the tip exactly on HIT
local R = TIPL.Magnitude
local PHI = math.rad(32)
local G = Vector2.new(HIT.X + R * math.cos(PHI), HIT.Y + R * math.sin(PHI))
local A_STRIKE = math.deg(math.atan2(HIT.Y - G.Y, HIT.X - G.X)) - math.deg(math.atan2(TIPL.Y, TIPL.X))
local A_WIND = A_STRIKE + 64
local A_FINAL = -90
local FX = 300
local headW = rotv(HEADL, A_FINAL)
local FINAL = Vector2.new(FX - headW.X, 198 - 17 - headW.Y)

local HITS = { 1.35, 2.0, 2.65 }
local B = HITS[3]
local SHINE_AT, LOAD_AT = B + 1.9, B + 2.45

----------------------------------------------------------------- UI HELPERS
-- «стоянка» далеко за екраном: усі рухомі елементи створюються й ховаються тут, щоб на жодному пристрої вони не блимнули в кутку
local PARK = -10000
local function new(class, props, parent)
	local o = Instance.new(class)
	for p, v in pairs(props) do o[p] = v end
	o.Parent = parent
	return o
end
local function frame(parent, x, y, w, h, color, z)
	return new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or Color3.new(1, 1, 1),
		BackgroundTransparency = color and 0 or 1, BorderSizePixel = 0, ZIndex = z or 1 }, parent)
end
local function img(parent, image, x, y, w, h, z)
	return new("ImageLabel", { Image = image, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = z or 1 }, parent)
end
local function stroke(parent, thick, color, t)
	return new("UIStroke", { Thickness = thick, Color = color or INK, LineJoinMode = Enum.LineJoinMode.Round, Transparency = t or 0 }, parent)
end
local function corner(parent, r) return new("UICorner", { CornerRadius = r }, parent) end
local function label(parent, text, size, x, y, w, h, z)
	return new("TextLabel", { Text = text, FontFace = FONT, TextSize = size, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = z or 1 }, parent)
end
-- transparency with a group alpha (base transparency remembered per object)
local base = {}
local function fade(o, a)
	local b = base[o]
	if not b then
		b = {}
		if o:IsA("GuiObject") then b.bg = o.BackgroundTransparency end
		if o:IsA("ImageLabel") then b.img = o.ImageTransparency end
		if o:IsA("TextLabel") then b.txt = o.TextTransparency end
		if o:IsA("UIStroke") then b.st = o.Transparency end
		base[o] = b
	end
	local function f(x) return 1 - (1 - x) * a end
	if b.bg then o.BackgroundTransparency = f(b.bg) end
	if b.img then o.ImageTransparency = f(b.img) end
	if b.txt then o.TextTransparency = f(b.txt) end
	if b.st then o.Transparency = f(b.st) end
end
local function fadeTree(root, a)
	fade(root, a)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") or d:IsA("UIStroke") then fade(d, a) end
	end
end

----------------------------------------------------------------- BUILD
local player = Players.LocalPlayer
local gui = new("ScreenGui", { Name = "OrekoLoadingScreen", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.None }, player:WaitForChild("PlayerGui"))

-- background
local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = CONFIG.bgColor, BorderSizePixel = 0, ZIndex = 1 }, gui)
local bgTiles = new("ImageLabel", { Image = IMG.bgTile, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Tile, ZIndex = 1 }, bg)
new("ImageLabel", { Image = IMG.vignette, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, bg)

-- stage 1000 × 562.5, fitted to the screen
local stage = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1000, 562.5),
	BackgroundTransparency = 1, ZIndex = 2 }, gui)
local stageScale = new("UIScale", {}, stage)

-- world (whole logo) & shake (stone) — both scale around (500, 320)
local world = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(500, 320), Size = UDim2.fromOffset(1000, 640),
	BackgroundTransparency = 1, ZIndex = 1 }, stage)
local worldScale = new("UIScale", {}, world)
local shake = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(500, 320), Size = UDim2.fromOffset(1000, 640),
	BackgroundTransparency = 1, ZIndex = 2 }, world)
local shakeScale = new("UIScale", {}, shake)

-- back stone + name
local stoneImg = img(shake, IMG.stone, ST.x, ST.y, ST.w, ST.h, 1)
local NM = { x = 180, y = 258, w = 640, h = 148 } -- рамка картинки назви (тінь + контур + золото); OSIRIUS ширша за OREKO (було x 200, w 600)
-- шари в shake: 1 камінь · 2 кірка (коли лежить) · 3 її блиск · 4 передня частина каменю · 5 назва · 6 спалах назви · 7 блиск каменю · 8 шматки · 9 тріщини
local stoneFront = img(shake, IMG.stoneFront, ST.x, ST.y, ST.w, ST.h, 4)
local nameImg = img(shake, IMG.name, NM.x, NM.y, NM.w, NM.h, 5)
local nameGlow = img(shake, IMG.nameGlow, NM.x, NM.y, NM.w, NM.h, 6)
nameGlow.ImageTransparency = 1

-- notch where the pick enters the stone
local notchX = FINAL.X + rotv(TIPL, A_FINAL).X
local notch = frame(shake, notchX - 14, topAt(notchX) + 2, 28, 10, Color3.fromHex("0c0e12"), 3)
corner(notch, UDim.new(0, 3))
local notchStroke = stroke(notch, 1.5)

-- front shell chunks
local chunkImgs = {}
for i, c in ipairs(CHUNKS) do
	local x, y, w, h, ax, ay = c[1], c[2], c[3], c[4], c[5], c[6]
	local im = img(shake, IMG.chunks, PARK, PARK, w, h, 8)
	im.AnchorPoint = Vector2.new(0.5, 0.5)
	im.ImageRectOffset = Vector2.new(ax * SC, ay * SC)
	im.ImageRectSize = Vector2.new(w * SC, h * SC)
	chunkImgs[i] = { im = im, bc = Vector2.new(x + w / 2, y + h / 2), c = Vector2.new(c[11], c[12]), vx = c[7], vy = c[8], vr = c[9], delay = c[10] }
end
-- crack stages
local crackImgs = {}
for i = 0, 2 do
	local im = img(shake, IMG.cracks, CR.x, CR.y, CR.w, CR.h, 9)
	im.ImageRectOffset = Vector2.new(0, math.floor(i * (CR.h + 4) * SCC + 0.5))
	im.ImageRectSize = Vector2.new(math.floor(CR.w * SCC + 0.5), math.floor(CR.h * SCC + 0.5))
	im.Visible = false
	crackImgs[i + 1] = im
end

-- fx: chips, flash, ring, dust
local fx = new("Frame", { Size = UDim2.fromOffset(1000, 640), BackgroundTransparency = 1, ZIndex = 3 }, world)
local rng = Random.new(11)
local SHADES = { "8d959f", "838b96", "97a0aa", "7e8691", "9ca4ad", "88909b" }
local function square(s, color, th)
	local f = frame(fx, PARK, PARK, s, s, Color3.fromHex(color), 1)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	stroke(f, th)
	f.Visible = false
	return f
end
local chips = {}
for h = 1, 3 do
	chips[h] = {}
	for n = 1, 7 do
		local s = 7 + rng:NextNumber() * 12
		chips[h][n] = { f = square(s, SHADES[(n - 1) % 6 + 1], 1.5), vx = (rng:NextNumber() - 0.35) * 460, vy = -180 - rng:NextNumber() * 280, vr = (rng:NextNumber() - 0.5) * 900 }
	end
end
local dust = {}
for n = 1, 8 do
	local s = 6 + rng:NextNumber() * 8
	dust[n] = { f = square(s, "9aa3ae", 1.25), vx = (n <= 4 and -1 or 1) * (80 + rng:NextNumber() * 170), vy = -120 - rng:NextNumber() * 160 }
end
local flash = frame(fx, PARK, PARK, 20, 20, Color3.new(1, 1, 1), 2)
flash.AnchorPoint = Vector2.new(0.5, 0.5); corner(flash, UDim.new(0.5, 0)); flash.Visible = false
local ring = frame(fx, PARK, PARK, 20, 20, nil, 2)
ring.AnchorPoint = Vector2.new(0.5, 0.5); corner(ring, UDim.new(0.5, 0)); ring.Visible = false
local ringStroke = stroke(ring, 5, Color3.new(1, 1, 1))

-- pickaxe (image centred on the grip) + «MADE BY»
local pick = img(world, IMG.pick, PARK, PARK, 2 * HS, 2 * HS, 4)
pick.AnchorPoint = Vector2.new(0.5, 0.5)
pick.Visible = false
local madeBy = label(pick, "MADE BY", 19, HS + TEXTL.X, HS + TEXTL.Y, 160, 26, 2)
madeBy.Rotation = 90
madeBy.TextTransparency = 1
local madeStroke = stroke(madeBy, 2.5, INK, 1)
-- під час замаху кірка над усім (world), з початку падіння — всередині shake між каменем і його передньою частиною:
-- видно над верхнім контуром, а нижче вона «входить» у камінь
local function pickInStone(on)
	local parent = on and shake or world
	if pick.Parent ~= parent then pick.Parent = parent end
	pick.ZIndex = on and 2 or 4
end

-- shine over the logo (white silhouettes + moving gradient band)
local stoneW = img(shake, IMG.stoneWhite, ST.x, ST.y, ST.w, ST.h, 7)
local stoneWG = new("UIGradient", { Rotation = 18 }, stoneW)
local pickW = img(shake, IMG.pickWhite, PARK, PARK, 2 * HS, 2 * HS, 3)
pickW.AnchorPoint = Vector2.new(0.5, 0.5)
local pickWG = new("UIGradient", { Rotation = 108 }, pickW)
stoneW.Visible, pickW.Visible = false, false
-- env 0..1 — яскравість смуги: на вході й виході з каменю вона гасне, щоб не «прилипала» сяйвом до бокових граней
local function band(tc, hw, env)
	local function tr(x) return 1 - (1 - x) * env end
	local kp = { NumberSequenceKeypoint.new(0, 1) }
	for _, p in ipairs({ { tc - hw, 1 }, { tc - hw * 0.4, tr(0.6) }, { tc, tr(0.2) }, { tc + hw * 0.4, tr(0.6) }, { tc + hw, 1 } }) do
		if p[1] > 0.002 and p[1] < 0.998 and p[1] > kp[#kp].Time + 0.001 then table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2])) end
	end
	table.insert(kp, NumberSequenceKeypoint.new(1, 1))
	return NumberSequence.new(kp)
end

-- loading bar
local LB = { x = 320, y = 486, w = 360, h = 30 }
local load = new("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(1000, 562.5), BackgroundTransparency = 1, ZIndex = 3 }, stage)
local barBg = frame(load, LB.x, LB.y, LB.w, LB.h, Color3.fromHex("1d2129"), 1)
corner(barBg, UDim.new(0, 10)); stroke(barBg, 3)
local clip = frame(barBg, 3, 3, 0, LB.h - 6, nil, 2)
clip.ClipsDescendants = true
local fill = frame(clip, 0, 0, LB.w - 6, LB.h - 6, Color3.new(1, 1, 1), 1)
corner(fill, UDim.new(0, 7))
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, CONFIG.barFill[1]),
	ColorSequenceKeypoint.new(0.55, CONFIG.barFill[2]), ColorSequenceKeypoint.new(1, CONFIG.barFill[3]) }) }, fill)
local studs = img(fill, IMG.studsTile, 4, 4, LB.w - 14, LB.h - 14, 2) -- studs з відступом від краю
studs.ScaleType = Enum.ScaleType.Tile
studs.TileSize = UDim2.fromScale(30 / (LB.w - 14), 30 / (LB.h - 14))
local hl = frame(fill, 0, 1, LB.w - 6, 6, Color3.new(1, 1, 1), 3)
hl.BackgroundTransparency = 0.65
local ltxt = label(load, "LOADING 0%", 21, 500, LB.y + LB.h / 2, 360, 30, 4)
stroke(ltxt, 2.5)

-- звук ударів кірки (2D, у нашому ScreenGui) і дозвіл для фонової музики
local hitSnd = new("Sound", { Name = "PickHit", SoundId = HIT_SFX.id, Volume = HIT_SFX.volume }, gui)
local breakSnd = new("Sound", { Name = "RockBreak", SoundId = BREAK_SFX.id, Volume = BREAK_SFX.volume,
	PlaybackRegionsEnabled = true, PlaybackRegion = BREAK_SFX.region }, gui)
-- події звуку: { час, гучність ×, висота, звук? }: два удари; третій (кора обсипається) — удар трохи нижчий
-- + тріск каменю RockBreak; падіння кірки в камінь (B + 1.3) — тихий глухий стук
local SFX = { { HITS[1], 1, 1 }, { HITS[2], 1, 1.04 }, { HITS[3], 1, 0.92 }, { HITS[3], 1, 1, breakSnd }, { B + 1.3, 0.7, 0.8 } }
local function playHitSfx(vol, pitch, src)
	src = src or hitSnd
	local s = src:Clone()
	s.Volume = src.Volume * vol
	s.PlaybackSpeed = pitch * (0.97 + math.random() * 0.06)
	s.Parent = gui
	s:Play()
	if src == breakSnd then -- тріск затухає за останні fade с нарізки
		local len = (BREAK_SFX.region.Max - BREAK_SFX.region.Min) / s.PlaybackSpeed -- з урахуванням висоти
		task.delay(math.max(0, len - BREAK_SFX.fade - 0.01), function()
			if s.Parent then game:GetService("TweenService"):Create(s, TweenInfo.new(BREAK_SFX.fade - 0.01, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Volume = 0 }):Play() end
		end)
	end
	task.delay(1.5, function() s:Destroy() end)
end
local musicOK = false
local function allowMusic()
	if musicOK then return end
	musicOK = true
	SoundService:SetAttribute("LoadingMusicOK", true)
end

-- dark overlay
local dark = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10 }, gui)

----------------------------------------------------------------- LAYOUT (screen fit + background drift)
local camera = workspace.CurrentCamera
local function vp()
	local s = gui.AbsoluteSize
	if s.X < 2 then s = camera and camera.ViewportSize or Vector2.new(1280, 720) end
	return s
end
local function layout(sec)
	local s = vp()
	local sc = math.min(s.X / 1000, s.Y / 562.5)
	stageScale.Scale = sc
	local T = 48 * sc
	local ox = ((sec * CONFIG.bgDrift.X * sc) % T + T) % T
	local oy = ((sec * CONFIG.bgDrift.Y * sc) % T + T) % T
	bgTiles.TileSize = UDim2.fromOffset(T, T)
	bgTiles.Size = UDim2.fromOffset(s.X + 2 * T, s.Y + 2 * T)
	bgTiles.Position = UDim2.fromOffset(ox - T, oy - T)
end
layout(0)

----------------------------------------------------------------- PROGRESS (справжнє завантаження)
-- 0–50 % — завантаження гри (черга ContentProvider), 50–100 % — картинки інтерфейсу й табло.
-- Їх створюють клієнтські скрипти вже ПІСЛЯ завантаження гри, і без цього етапу на слабкій графіці
-- картки й іконки на стендах з'являються лише через ~10 с після входу.
local maxQ, shown = 1, 0
local pre = { started = false, finished = false, total = 0, done = 0 }
local function collectImages()
	local list, seen = {}, {}
	local function add(id)
		if type(id) == "string" and id ~= "" and not seen[id] then seen[id] = true; table.insert(list, id) end
	end
	for _, root in { player:FindFirstChild("PlayerGui"), workspace } do
		if root then
			for _, d in root:GetDescendants() do
				if d:IsDescendantOf(gui) then continue end
				if d:IsA("ImageLabel") or d:IsA("ImageButton") then add(d.Image)
				elseif d:IsA("Decal") or d:IsA("Texture") then add(d.Texture) end
			end
		end
	end
	-- спільні плитки «стилю A» (кнопки, картки), навіть якщо вікно ще не відкривали
	pcall(function()
		local S = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared", 5):WaitForChild("StyleA", 5))
		for _, v in pairs(S.ASSETS or {}) do add(v) end
	end)
	return list
end
local function startPreload()
	if pre.started then return end
	pre.started = true
	task.spawn(function()
		task.wait(1) -- клієнтські скрипти встигають побудувати HUD і табла ніш
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and workspace.StreamingEnabled then
			pcall(function() player:RequestStreamAroundAsync(hrp.Position, 5) end)
			task.wait(0.5) -- табла, що щойно підвантажились, встигають побудуватись
		end
		local list = collectImages()
		pre.total = #list
		if #list > 0 then pcall(function() ContentProvider:PreloadAsync(list, function() pre.done += 1 end) end) end
		pre.finished = true
	end)
end
local function target(elapsed)
	local q = ContentProvider.RequestQueueSize
	if q > maxQ then maxQ = q end
	if elapsed > CONFIG.maxWait then return 1 end
	local loaded = game:IsLoaded() and q == 0 and (not CONFIG.waitCharacter or player.Character ~= nil or elapsed > CONFIG.maxWait * 0.5)
	if not loaded then return 0.5 * (1 - q / maxQ) end
	startPreload()
	if pre.finished then return 1 end
	return 0.5 + 0.49 * (pre.total > 0 and pre.done / pre.total or 0)
end

----------------------------------------------------------------- FRAME
local function swingAngle(t)
	if t < HITS[1] then return lerp(A_WIND, A_STRIKE, ease.in2(k(t, HITS[1] - 0.32, HITS[1]))) end
	local i = #HITS
	for j = 1, #HITS - 1 do if t < HITS[j + 1] then i = j break end end
	local d = t - HITS[i]
	local nxt = (HITS[i + 1] or 99) - HITS[i]
	local rec, up, down = k(d, 0, 0.12), k(d, 0.12, nxt - 0.3), k(d, nxt - 0.3, nxt)
	local a = A_STRIKE + math.sin(rec * math.pi) * 7
	if d > 0.12 then a = lerp(A_STRIKE, A_WIND, ease.out(up)) end
	if d > nxt - 0.3 then a = lerp(A_WIND, A_STRIKE, ease.in2(down)) end
	return a
end

local readyAt = nil
local finished = false
local function frameAt(t, dt, elapsed)
	local sIn = k(t, 0, 0.6)
	-- shake + intro scale
	local sx, sy = 0, 0
	for _, h in ipairs(HITS) do
		local d = t - h
		if d >= 0 and d < 0.25 then
			local m = (1 - d / 0.25) * (h == B and 10 or 6)
			sx += math.sin(d * 95) * m
			sy += math.cos(d * 70) * m * 0.5
		end
	end
	shake.Position = UDim2.fromOffset(500 + sx, 320 + sy)
	shakeScale.Scale = math.max(ease.back(sIn), 0.001) -- поп-ап: камінь виростає з точки з пружним перескоком
	-- cracks
	for i, im in ipairs(crackImgs) do im.Visible = t >= HITS[i] and t < B end
	-- chips
	for h, arr in ipairs(chips) do
		local d = t - HITS[h]
		for _, c in ipairs(arr) do
			if d < 0 or d > 1.1 then c.f.Visible = false; c.f.Position = UDim2.fromOffset(PARK, PARK) else
				c.f.Visible = true
				c.f.Position = UDim2.fromOffset(HIT.X + c.vx * d, HIT.Y + c.vy * d + 950 * d * d)
				c.f.Rotation = c.vr * d
				c.f.BackgroundTransparency = d / 1.1
				c.f.UIStroke.Transparency = d / 1.1
			end
		end
	end
	-- flash + ring
	local fl = 0
	for _, h in ipairs(HITS) do local d = t - h if d >= 0 and d < 0.2 then fl = math.max(fl, 1 - d / 0.2) end end
	flash.Visible, ring.Visible = fl > 0, fl > 0
	if fl > 0 then
		local r1, r2 = 8 + (1 - fl) * 34, 14 + (1 - fl) * 70
		flash.Position, flash.Size = UDim2.fromOffset(HIT.X, HIT.Y), UDim2.fromOffset(2 * r1, 2 * r1)
		flash.BackgroundTransparency = 1 - fl * 0.9
		ring.Position, ring.Size = UDim2.fromOffset(HIT.X, HIT.Y), UDim2.fromOffset(2 * r2, 2 * r2)
		ringStroke.Transparency = 1 - fl * 0.8
	end
	-- chunks fall
	for _, c in ipairs(chunkImgs) do
		local d = t - B - c.delay * 0.3
		if d < 0 then
			c.im.Position = UDim2.fromOffset(c.bc.X, c.bc.Y); c.im.Rotation = 0; c.im.Visible = true
		else
			local rot = c.vr * d
			local p = c.c + rotv(c.bc - c.c, rot) + Vector2.new(c.vx * d, c.vy * d + 1500 * d * d)
			c.im.Visible = d <= 1.1
			c.im.Position = d <= 1.1 and UDim2.fromOffset(p.X, p.Y) or UDim2.fromOffset(PARK, PARK); c.im.Rotation = rot
		end
	end
	-- the name is hidden while the front shell is intact (otherwise it peeks through the chunk seams)
	nameImg.Visible, nameGlow.Visible = t >= B, t >= B
	-- name glow
	local sh = k(t, B + 0.35, B + 0.9)
	nameGlow.ImageTransparency = (sh > 0 and sh < 1) and (1 - math.sin(sh * math.pi) * 0.5) or 1
	-- pickaxe
	local px, py, pa
	if t < 0.5 then
		pick.Visible = false
	elseif t < B + 0.05 then
		pick.Visible = true
		pickInStone(false)
		local fly = ease.out(k(t, 0.5, 1.0))
		local a = swingAngle(t)
		local wu = cl((a - A_STRIKE) / (A_WIND - A_STRIKE), 0, 1)
		px, py, pa = G.X + wu * 18 + (1 - fly) * 420, G.Y - wu * 10 - (1 - fly) * 360, a + (1 - fly) * 120
	else
		pick.Visible = true
		local up, fall, settle = k(t, B, B + 0.7), k(t, B + 0.7, B + 1.3), k(t, B + 1.3, B + 1.7)
		if up < 1 then
			px, py, pa = lerp(G.X, 640, ease.out(up)), lerp(G.Y, -80, ease.out(up)), lerp(A_STRIKE, A_STRIKE - 260, up)
		elseif fall < 1 then
			px, py, pa = lerp(640, FINAL.X, fall), lerp(-80, FINAL.Y, ease.in2(fall)), lerp(A_STRIKE - 260, A_FINAL - 360, ease.out(fall))
		else
			local b = math.sin(settle * math.pi) * (1 - settle) * 14
			px, py, pa = FINAL.X, FINAL.Y - b, A_FINAL - 360 + math.sin(settle * math.pi * 2) * (1 - settle) * 3
		end
		-- from the start of the fall the pick goes INTO the stone (between the stone and its front part)
		pickInStone(up >= 1)
		local mb = ease.out(k(t, B + 1.4, B + 1.8))
		madeBy.TextTransparency, madeStroke.Transparency = 1 - mb, 1 - mb
		notch.Visible = false -- кірка малюється позаду каменю, виріз зайвий
		local d = t - (B + 1.3)
		for _, p in ipairs(dust) do
			if d < 0 or d > 0.8 then p.f.Visible = false; p.f.Position = UDim2.fromOffset(PARK, PARK) else
				p.f.Visible = true
				p.f.Position = UDim2.fromOffset(FX + p.vx * d, topAt(FX) + 4 + p.vy * d + 700 * d * d)
				p.f.BackgroundTransparency = d / 0.8
				p.f.UIStroke.Transparency = d / 0.8
			end
		end
	end
	if t < B then madeBy.TextTransparency, madeStroke.Transparency = 1, 1; notch.Visible = false end
	if t < B + 1.3 then for _, p in ipairs(dust) do p.f.Visible = false end end
	if px then pick.Position = UDim2.fromOffset(px, py); pick.Rotation = pa end
	-- shine (left → right over stone + pick)
	local su = k(t, SHINE_AT, SHINE_AT + 0.75)
	local on = su > 0 and su < 1
	stoneW.Visible, pickW.Visible = on, on
	if on then
		-- рівномірно, без сповільнення на краях (інакше смуга «прилипає» до бокових граней каменю)
		local bx = lerp(40, 960, su)
		local env = math.sin(math.pi * cl((bx - ST.x - 20) / (ST.w - 40), 0, 1))
		stoneWG.Transparency = band((bx - ST.x) / ST.w, 45 / ST.w, env)
		pickW.Position, pickW.Rotation = pick.Position, pick.Rotation
		pickWG.Transparency = band((bx - (px - HS)) / (2 * HS), 45 / (2 * HS), env)
	end
	-- loading progress
	if t >= LOAD_AT + 0.2 then
		local tg = target(elapsed)
		shown = math.max(shown, math.min(tg, shown + dt * CONFIG.fillSpeed)) -- ніколи не йде назад
	end
	clip.Size = UDim2.fromOffset((LB.w - 6) * shown, LB.h - 6)
	ltxt.Text = shown >= 1 and "READY!" or ("LOADING " .. math.floor(shown * 100) .. "%")
	if shown >= 1 and not readyAt and t >= LOAD_AT then readyAt = t end
	if shown >= MUSIC_AT then allowMusic() end -- фонова музика — від 50 % шкали
	-- outro: logo pops away, bar springs down, quick darkening, place
	local OUT = readyAt and readyAt + 0.35 or 1e9
	local show, bo = k(t, LOAD_AT, LOAD_AT + 0.4), k(t, OUT + 0.05, OUT + 0.6)
	local function backIn(u) local c = 1.9 return (c + 1) * u * u * u - c * u * u end
	fadeTree(load, ease.out(show) * (1 - bo * bo))
	load.Position = UDim2.fromOffset(0, (1 - ease.out(show)) * 14 + backIn(bo) * 140)
	local lu = k(t, OUT, OUT + 0.5)
	local lsc = lu < 0.35 and lerp(1, 1.08, ease.out(lu / 0.35)) or lerp(1.08, 0, ease.in2((lu - 0.35) / 0.65))
	worldScale.Scale = math.max(lsc, 0.001)
	-- у вебі лого ще й зникає прозорістю; тут лише масштаб (інакше кірка просвічує крізь напівпрозорий камінь)
	local wa = ease.out(k(t, 0, 0.15))
	world.Visible = lu < 1
	-- world alpha (only static layers need it; moving fx are short-lived)
	fade(stoneImg, wa); fade(stoneFront, wa); fade(pick, wa)
	fade(nameImg, wa)
	for _, c in ipairs(chunkImgs) do fade(c.im, wa) end
	if t >= B + 1.4 then
		local mb = ease.out(k(t, B + 1.4, B + 1.8)) * wa
		madeBy.TextTransparency, madeStroke.Transparency = 1 - mb, 1 - mb
		fade(notch, wa); fade(notchStroke, wa)
	end
	local dk, undk = k(t, OUT + 0.45, OUT + 0.75), k(t, OUT + 0.9, OUT + 1.3)
	dark.BackgroundTransparency = 1 - dk * (1 - undk)
	if t >= OUT + 0.75 then bg.Visible = false; stage.Visible = false end
	if t >= OUT + 1.3 then finished = true end
end

----------------------------------------------------------------- RUN
-- 1) одразу статичний фон; 2) вантажимо ВСЕ для анімації й «прогріваємо» картинки; 3) чекаємо, поки гра завантажиться;
-- 4) чекаємо ~1 с рівних кадрів; 5) рахуємо перший кадр і тільки тоді показуємо сцену
stage.Visible = false
local startClock = os.clock()
-- «прогрів»: кожна картинка логотипу вже намальована в повний розмір, але майже прозора (під фоном) —
-- тоді Roblox заздалегідь завантажує її у відеопам'ять і поп-ап на старті не пропускає кадрів
local NATIVE = { stone = { 980, 384 }, stoneFront = { 980, 384 }, stoneWhite = { 980, 384 }, chunks = { 896, 697 }, cracks = { 590, 688 },
	pick = { 980, 980 }, pickWhite = { 980, 980 }, name = { 1024, 237 }, nameGlow = { 1024, 237 } }
-- прогрівочні картинки лежать в окремому ScreenGui ПІД нашим (DisplayOrder на 1 менший): їх повністю закриває непрозорий фон, але Roblox їх малює
local warmGui = new("ScreenGui", { Name = "OrekoLoadingWarm", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = gui.DisplayOrder - 1 }, gui.Parent)
local preload = {}
for key, id in pairs(IMG) do
	local sz = NATIVE[key] or { 64, 64 }
	local w = new("ImageLabel", { Image = id, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sz[1], sz[2]),
		BackgroundTransparency = 1 }, warmGui)
	table.insert(preload, w)
end
table.insert(preload, ltxt)
table.insert(preload, hitSnd) -- звуки вантажаться разом з картинками логотипу
table.insert(preload, breakSnd)
table.insert(preload, madeBy)
task.spawn(function()
	local done = false
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync(preload) end)
		done = true
	end)
	while not done and os.clock() - startClock < 10 do layout(0) task.wait() end
	-- гра завантажилась і є персонаж (старт інших скриптів і HUD дає найбільші підлагування); максимум 8 с від старту
	while (not game:IsLoaded() or (CONFIG.waitCharacter and not player.Character)) and os.clock() - startClock < 8 do layout(0) task.wait() end
	-- рівні кадри: ~1 с (60 кадрів поспіль коротших за 1/40 с); максимум 5 с
	local good, t1 = 0, os.clock()
	while good < 60 and os.clock() - t1 < 5 do
		local dt = RunService.RenderStepped:Wait()
		layout(0)
		good = dt < 1 / 40 and good + 1 or 0
	end
	startPreload() -- картинки інтерфейсу вантажаться, поки йде анімація логотипу
	-- перший кадр рахуємо ДО показу сцени: інакше на 1 кадр усі шматки стоять у верхньому лівому куті
	frameAt(0, 0, os.clock() - startClock)
	stage.Visible = true
	task.delay(1.5, function() warmGui:Destroy() end)
	local t = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		-- час анімації йде кроками не довшими за 1/30 с: якщо кадр підлагне, анімація сповільниться, а не перескочить
		local t0 = t
		t += math.min(dt, 1 / 30)
		layout(t)
		local dbg = script:GetAttribute("DebugT") -- тест: заморозити кадр на часі t (атрибут прибрати перед публікацією)
		if dbg then shown = script:GetAttribute("DebugP") or 0 readyAt = script:GetAttribute("DebugReadyAt") frameAt(dbg, 0, 0) return end
		for _, e in ipairs(SFX) do
			if t0 < e[1] and t >= e[1] then playHitSfx(e[2], e[3], e[4]) end
		end
		frameAt(t, dt, os.clock() - startClock)
		if finished then
			allowMusic() -- на випадок, якщо шкала так і не дійшла до 50 %
			conn:Disconnect()
			gui:Destroy()
		end
	end)
end)
