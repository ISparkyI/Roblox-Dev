-- OrekoLoadingScreen (ReplicatedFirst, LocalScript)
-- Загрузочний екран студії OREKO. Порт веб-макета oreko_splash.html v3.4.
-- Логотип (камінь + кірка «MADE BY» + назва OREKO) однаковий для всіх плейсів; фон/кольори можна міняти в CONFIG.
-- Координати — у «юнітах» макета (сцена 1000 × 562.5), UIScale підганяє під екран.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
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

----------------------------------------------------------------- ASSETS (OREKO, спільні для всіх плейсів)
local IMG = {
	stone = "rbxassetid://95100394001883",
	stoneWhite = "rbxassetid://131554417964783",
	chunks = "rbxassetid://120550521214732",
	cracks = "rbxassetid://80554187243271",
	pick = "rbxassetid://89358069152781",
	pickWhite = "rbxassetid://125699053935592",
	bgTile = "rbxassetid://114055270976915",
	studsTile = "rbxassetid://134764452695368",
	vignette = "rbxassetid://84008052171508",
}
local INK = Color3.fromHex("14161a")
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Black)

----------------------------------------------------------------- GEOMETRY (з макета / meta.json)
local SC, SCC = 1.4, 0.9
local ST = { x = 150, y = 182, w = 700, h = 274 }
local HIT = Vector2.new(545, 300)
local SIL = { {166,250},{196,214},{290,214},{306,198},{452,198},{468,206},{620,206},{640,188},{770,188},{800,214} }
local CR = { x = __CRX__, y = __CRY__, w = __CRW__, h = __CRH__ }
local HS = 350
local TIPL = Vector2.new(__TIPLX__, __TIPLY__)
local HEADL = Vector2.new(0, __HEADLY__)
local TEXTL = Vector2.new(0, __TEXTLY__)
-- x, y, w, h, ax, ay (атлас), vx, vy, vr, delay, cx, cy
local CHUNKS = {
__CHUNKS__
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
local nameBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(500, __NAMEY__), Size = UDim2.fromOffset(500, 55),
	BackgroundTransparency = 1, ZIndex = 2 }, shake)
new("UIScale", { Scale = 2 }, nameBox)
local nameShadow = label(nameBox, "OREKO", 74, 250, 27.5 + 4, 500, 55, 1)
nameShadow.TextColor3 = Color3.fromHex("0c0e12")
stroke(nameShadow, 5.5)
local nameText = label(nameBox, "OREKO", 74, 250, 27.5, 500, 55, 2)
stroke(nameText, 5)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("fff6b0")), ColorSequenceKeypoint.new(0.45, Color3.fromHex("ffd23a")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("ff9a1a")) }) }, nameText)
local nameGlow = label(nameBox, "OREKO", 74, 250, 27.5, 500, 55, 3)
nameGlow.TextTransparency = 1

-- notch where the pick enters the stone
local notchX = FINAL.X + rotv(TIPL, A_FINAL).X
local notch = frame(shake, notchX - 14, topAt(notchX) + 2, 28, 10, Color3.fromHex("0c0e12"), 3)
corner(notch, UDim.new(0, 3))
local notchStroke = stroke(notch, 1.5)

-- front shell chunks
local chunkImgs = {}
for i, c in ipairs(CHUNKS) do
	local x, y, w, h, ax, ay = c[1], c[2], c[3], c[4], c[5], c[6]
	local im = img(shake, IMG.chunks, 0, 0, w, h, 4)
	im.AnchorPoint = Vector2.new(0.5, 0.5)
	im.ImageRectOffset = Vector2.new(ax * SC, ay * SC)
	im.ImageRectSize = Vector2.new(w * SC, h * SC)
	chunkImgs[i] = { im = im, bc = Vector2.new(x + w / 2, y + h / 2), c = Vector2.new(c[11], c[12]), vx = c[7], vy = c[8], vr = c[9], delay = c[10] }
end
-- crack stages
local crackImgs = {}
for i = 0, 2 do
	local im = img(shake, IMG.cracks, CR.x, CR.y, CR.w, CR.h, 5)
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
	local f = frame(fx, 0, 0, s, s, Color3.fromHex(color), 1)
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
local flash = frame(fx, 0, 0, 20, 20, Color3.new(1, 1, 1), 2)
flash.AnchorPoint = Vector2.new(0.5, 0.5); corner(flash, UDim.new(0.5, 0)); flash.Visible = false
local ring = frame(fx, 0, 0, 20, 20, nil, 2)
ring.AnchorPoint = Vector2.new(0.5, 0.5); corner(ring, UDim.new(0.5, 0)); ring.Visible = false
local ringStroke = stroke(ring, 5, Color3.new(1, 1, 1))

-- pickaxe (image centred on the grip) + «MADE BY»
local pick = img(world, IMG.pick, 0, 0, 2 * HS, 2 * HS, 4)
pick.AnchorPoint = Vector2.new(0.5, 0.5)
pick.Visible = false
local madeBy = label(pick, "MADE BY", 19, HS + TEXTL.X, HS + TEXTL.Y, 160, 26, 2)
madeBy.Rotation = 90
madeBy.TextTransparency = 1
local madeStroke = stroke(madeBy, 2.5, INK, 1)

-- shine over the logo (white silhouettes + moving gradient band)
local shine = new("Frame", { Size = UDim2.fromOffset(1000, 640), BackgroundTransparency = 1, ZIndex = 5 }, world)
local stoneW = img(shine, IMG.stoneWhite, ST.x, ST.y, ST.w, ST.h, 1)
local stoneWG = new("UIGradient", { Rotation = 18 }, stoneW)
local pickW = img(shine, IMG.pickWhite, 0, 0, 2 * HS, 2 * HS, 2)
pickW.AnchorPoint = Vector2.new(0.5, 0.5)
local pickWG = new("UIGradient", { Rotation = 108 }, pickW)
stoneW.Visible, pickW.Visible = false, false
local function band(tc, hw)
	local kp = { NumberSequenceKeypoint.new(0, 1) }
	for _, p in ipairs({ { tc - hw, 1 }, { tc, 0.25 }, { tc + hw, 1 } }) do
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
local studs = img(fill, IMG.studsTile, 0, 0, LB.w - 6, LB.h - 6, 2)
studs.ScaleType = Enum.ScaleType.Tile
studs.TileSize = UDim2.fromScale(30 / (LB.w - 6), 30 / (LB.h - 6))
local hl = frame(fill, 0, 1, LB.w - 6, 6, Color3.new(1, 1, 1), 3)
hl.BackgroundTransparency = 0.65
local ltxt = label(load, "LOADING 0%", 21, 500, LB.y + LB.h / 2, 360, 30, 4)
stroke(ltxt, 2.5)

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
local maxQ, shown = 1, 0
local function target(elapsed)
	local q = ContentProvider.RequestQueueSize
	if q > maxQ then maxQ = q end
	local p = 0.9 * (1 - q / maxQ)
	local ready = game:IsLoaded() and q == 0
	if CONFIG.waitCharacter and not player.Character and elapsed < CONFIG.maxWait * 0.5 then ready = false end
	if ready or elapsed > CONFIG.maxWait then return 1 end
	return math.min(p, 0.9)
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
	local sIn = k(t, 0, 0.45)
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
	shakeScale.Scale = lerp(0.9, 1, ease.back(sIn))
	-- cracks
	for i, im in ipairs(crackImgs) do im.Visible = t >= HITS[i] and t < B end
	-- chips
	for h, arr in ipairs(chips) do
		local d = t - HITS[h]
		for _, c in ipairs(arr) do
			if d < 0 or d > 1.1 then c.f.Visible = false else
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
			c.im.Position = UDim2.fromOffset(p.X, p.Y); c.im.Rotation = rot; c.im.Visible = d <= 1.1
		end
	end
	-- name glow
	local sh = k(t, B + 0.35, B + 0.9)
	nameGlow.TextTransparency = (sh > 0 and sh < 1) and (1 - math.sin(sh * math.pi) * 0.5) or 1
	-- pickaxe
	local px, py, pa
	if t < 0.5 then
		pick.Visible = false
	elseif t < B + 0.05 then
		pick.Visible = true
		pick.ZIndex = 4
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
		-- from the start of the fall the pick goes INTO the stone: draw it behind the stone layer
		pick.ZIndex = up >= 1 and 1 or 4
		local mb = ease.out(k(t, B + 1.4, B + 1.8))
		madeBy.TextTransparency, madeStroke.Transparency = 1 - mb, 1 - mb
		notch.Visible = settle > 0
		local d = t - (B + 1.3)
		for _, p in ipairs(dust) do
			if d < 0 or d > 0.8 then p.f.Visible = false else
				p.f.Visible = true
				p.f.Position = UDim2.fromOffset(FX + p.vx * d, topAt(FX) + 4 + p.vy * d + 700 * d * d)
				p.f.BackgroundTransparency = d / 0.8
				p.f.UIStroke.Transparency = d / 0.8
			end
		end
	end
	if t < B then madeBy.TextTransparency, madeStroke.Transparency = 1, 1; notch.Visible = false end
	if px then pick.Position = UDim2.fromOffset(px, py); pick.Rotation = pa end
	-- shine (left → right over stone + pick)
	local su = k(t, SHINE_AT, SHINE_AT + 0.75)
	local on = su > 0 and su < 1
	stoneW.Visible, pickW.Visible = on, on
	if on then
		local bx = lerp(80, 940, ease.inout(su))
		stoneWG.Transparency = band((bx - ST.x) / ST.w, 60 / ST.w)
		pickW.Position, pickW.Rotation = pick.Position, pick.Rotation
		pickWG.Transparency = band((bx - (px - HS)) / (2 * HS), 60 / (2 * HS))
	end
	-- loading progress
	if t >= LOAD_AT + 0.2 then
		local tg = target(elapsed)
		shown = math.min(tg, shown + math.min(math.max(tg - shown, 0), dt * CONFIG.fillSpeed))
	end
	clip.Size = UDim2.fromOffset((LB.w - 6) * shown, LB.h - 6)
	ltxt.Text = shown >= 1 and "READY!" or ("LOADING " .. math.floor(shown * 100) .. "%")
	if shown >= 1 and not readyAt and t >= LOAD_AT then readyAt = t end
	-- outro: logo pops away, bar springs down, quick darkening, place
	local OUT = readyAt and readyAt + 0.35 or 1e9
	local show, bo = k(t, LOAD_AT, LOAD_AT + 0.4), k(t, OUT + 0.05, OUT + 0.6)
	local function backIn(u) local c = 1.9 return (c + 1) * u * u * u - c * u * u end
	fadeTree(load, ease.out(show) * (1 - bo * bo))
	load.Position = UDim2.fromOffset(0, (1 - ease.out(show)) * 14 + backIn(bo) * 140)
	local lu = k(t, OUT, OUT + 0.5)
	local lsc = lu < 0.35 and lerp(1, 1.08, ease.out(lu / 0.35)) or lerp(1.08, 0, ease.in2((lu - 0.35) / 0.65))
	worldScale.Scale = math.max(lsc, 0.001)
	local wa = ease.out(sIn) * (lu < 0.35 and 1 or 1 - ease.in2((lu - 0.35) / 0.65))
	world.Visible = wa > 0.001
	-- world alpha (only static layers need it; moving fx are short-lived)
	fade(stoneImg, wa); fade(pick, wa)
	for _, o in ipairs({ nameShadow, nameText }) do fade(o, wa); fade(o.UIStroke, wa) end
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
local hidden = { stoneImg, pick, stage }
stage.Visible = false
local startClock = os.clock()
task.spawn(function()
	-- preload the logo images (max 4 s), then start the timeline
	local done = false
	task.delay(4, function() done = true end)
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({ stoneImg, pick, chunkImgs[1].im, crackImgs[1], stoneW, pickW, studs }) end)
		done = true
	end)
	while not done do layout(os.clock() - startClock) task.wait() end
	stage.Visible = true
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		layout(now - startClock)
		frameAt(now - t0, dt, now - startClock)
		if finished then
			conn:Disconnect()
			gui:Destroy()
		end
	end)
end)
