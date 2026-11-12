-- PlotBoard — табло прокачки плотів (8 карток; Auto Sell закрита до MAP 2: сіра, замок, кнопка «MAP 2») на Niche*/Upgrade panels/Plot_Upgrade_panel/screen.
-- Де: StarterPlayer/StarterPlayerScripts/PlotBoard (LocalScript). Сервер — ServerScriptService/PlotService.
-- Стиль і поведінка — як табло Forge (ForgeClient): SurfaceGui у PlayerGui з Adornee на screen (так працює клік мишкою),
-- сіра підкладка зі studs, квадратні картки з градієнтом, косими смугами, блиском і кнопкою «стиль A»; ряд карток
-- прокручується коліщатком, повзунком, стрілками або перетягуванням карток.
-- Картки (діють на ВСІ плоти; PlotConfig.CARDS / CARD_ORDER): Plots, Ore Limit, Ore Spawn, Golem Slots, Carrier Speed,
-- Crate, Ore Drop, Auto Sell (закрита до Stage >= minStage — PlotConfig.cardOpen; сервер теж не продасть). Рівні — атрибут власника ніші PlotLv (JSON), гроші — Money. Купівля — PlotAction:FireServer("Upgrade", key).
-- Своя ніша: кнопки працюють. Чужа / вільна: видно рівні й ціни, кнопки неактивні.
-- Екран будується, коли камера ближче 140 стадів, і прибирається далі 200.
-- Грань екрана — атрибут screen.ScreenFace (на Plot_Upgrade_panel це "Front" — бік до гравця), за замовчуванням Front.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local CardHover = require(RS.Shared:WaitForChild("CardHover"))
local UISfx = require(RS.Shared:WaitForChild("UISfx"))
local Action = RS:WaitForChild("Remotes"):WaitForChild("PlotAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local PH = 1000 -- висота полотна; ширина — з пропорцій екрана (26 × 12,5 → 2080 × 1000)
local CW, CH, GAP = 500, 790, 90
local CARD_K, SIDE, CARD_TOP = 0.85, 150, 130
local VP_Y, VP_H = 0, 850
local TRACK_W, TRACK_H, TRACK_Y = 1100, 40, 866
local ARROW = 56

-- [ключ] = { назва, розмір назви, іконка, тема }
local CARDS = {
	Plots = { "Plots", 72, "rbxassetid://76570845261767",
		{ grad = { { 0, "8ef05a" }, { 0.55, "43b62a" }, { 1, "237a16" } }, rim = "d4ffb8", stud = "a9f57e", studShade = "2f8a1c" } },
	Points = { "Ore Limit", 66, "rbxassetid://76791391215352",
		{ grad = { { 0, "ff8a96" }, { 0.55, "ef3d55" }, { 1, "a8182f" } }, rim = "ffd0d6", stud = "ffaab4", studShade = "b01d36" } },
	Spawn = { "Ore Spawn", 66, "rbxassetid://101407224526084",
		{ grad = { { 0, "6fc6ff" }, { 0.55, "2f8ee6" }, { 1, "1a5cb0" } }, rim = "bfe6ff", stud = "8fd2ff", studShade = "1b62b8" } },
	Slots = { "Golem Slots", 60, "rbxassetid://87582280052157",
		{ grad = { { 0, "ffb15c" }, { 0.55, "f07a1e" }, { 1, "b8500c" } }, rim = "ffd2a3", stud = "ffc890", studShade = "b3520f" } },
	Carry = { "Carrier Speed", 54, "rbxassetid://71048403724455",
		{ grad = { { 0, "d59bff" }, { 0.55, "9a4cf0" }, { 1, "5f22b4" } }, rim = "ecd4ff", stud = "dcb4ff", studShade = "5c1fa8" } },
	Crate = { "Crate Capacity", 54, "rbxassetid://91341404610533",
		{ grad = { { 0, "6ff0d8" }, { 0.55, "1fb89c" }, { 1, "0d7a66" } }, rim = "c8fff2", stud = "8ff5e0", studShade = "0f8a72" } },
	Drop = { "Ore Drop", 72, "rbxassetid://115012765065923",
		{ grad = { { 0, "ffe27a" }, { 0.55, "f5b616" }, { 1, "b07a06" } }, rim = "fff1b8", stud = "ffe89a", studShade = "b98309" } },
	AutoSell = { "Auto Sell", 72, "rbxassetid://110396437023647",
		{ grad = { { 0, "ff8ad8" }, { 0.55, "e83cb4" }, { 1, "a3187c" } }, rim = "ffd0ef", stud = "ffaee6", studShade = "a8187e" } },
	-- 09.11.2026: Auto Collect — іконка геймпаса Auto Collect, синьо-фіолетова тема
	AutoCollect = { "Auto Collect", 60, "rbxassetid://81190850894357",
		{ grad = { { 0, "a9b6ff" }, { 0.55, "6170f0" }, { 1, "3038a8" } }, rim = "d6dcff", stud = "bcc6ff", studShade = "3540ad" } },
}
-- закрита картка (ще не та карта): сіра тема, сіра іконка, замок поверх
local LOCK_TH = { grad = { { 0, "9aa1aa" }, { 0.55, "6f7680" }, { 1, "4a5058" } }, rim = "c9ced4", stud = "b4bac2", studShade = "555b63" }
local LOCK_ICON = "rbxassetid://122986621331664"
local function stageOf(owner: Player?): number return owner and tonumber(owner:GetAttribute("Stage")) or 1 end

-- значення картки на рівні l (текст) — «зараз › далі»
local function valueOf(key: string, l: number): string
	if key == "Plots" then return tostring(Cfg.plotsOf(l))
	elseif key == "Points" then return tostring(Cfg.pointsOf(l))
	elseif key == "Spawn" then return string.format("%.2fs", Cfg.spawnOf(l))
	elseif key == "Slots" then return tostring(Cfg.slotsOf(l))
	elseif key == "Carry" then return string.format("x%.2f", Cfg.carryOf(l))
	elseif key == "Crate" then return NF.full(Cfg.crateOf(l)) -- кількість руди, без «$»
	elseif key == "Drop" then return string.format("x%.1f", Cfg.dropOf(l))
	elseif key == "AutoSell" then return l >= 2 and "On" or "Off"
	elseif key == "AutoCollect" then local s = Cfg.autoCollectSecs(l) return s and (s .. "s") or "Off" -- 09.11.2026: інтервал автозбору
	end
	return tostring(l)
end
local MAX_SUFFIX = { Plots = " plots", Points = " ores", Slots = " golems", Crate = " ore" }

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function frame(parent, x, y, w, h, color, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or WHITE, BorderSizePixel = 0 }, parent)
	if props then for k, v in props do f[k] = v end end
	return f
end
local function corner(o, r) new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
local function stroke(o, color, th, tr, contextual)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0,
		LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function vgrad(o, keys) return new("UIGradient", { Color = cseq(keys), Rotation = 90 }, o) end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	return t
end
local function stud(parent, x, y, cell, fill, shade, edge)
	local s = math.floor(cell * 0.62)
	local o = (cell - s) / 2
	local d = math.max(2, math.floor(s * 0.12 + 0.5))
	local r = math.max(3, math.floor(s * 0.16))
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill); corner(st, r)
	if edge then stroke(st, edge, 2) end
end
local function darken(c, k) return Color3.new(c.R * (1 - k), c.G * (1 - k), c.B * (1 - k)) end
local function bands(parent, w, h)
	local f = frame(parent, 0, 0, w, h, WHITE, { Name = "Bands", Active = false })
	local K = NumberSequenceKeypoint.new
	new("UIGradient", { Rotation = 65, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new({ K(0, 1), K(0.16, 1), K(0.17, 0.82),
		K(0.31, 0.82), K(0.32, 1), K(0.47, 1), K(0.48, 0.9), K(0.53, 0.9), K(0.54, 1), K(0.70, 1), K(0.71, 0.85), K(0.83, 0.85), K(0.84, 1), K(1, 1) }) }, f)
	return f
end

local function card(parent, x, y, key)
	local d = CARDS[key]
	local th = d[4]
	local holder, o = CardHover.holder(parent, x, y, CW, CH, 14)
	frame(holder, o.X, o.Y + 14, CW, CH, Color3.new(0, 0, 0), { BackgroundTransparency = 0.65 })
	local c = frame(holder, o.X, o.Y, CW, CH, WHITE); local cgrad = vgrad(c, th.grad); stroke(c, INK, 6)
	-- шар studs — звичайний Frame (CanvasGroup у таблах на слабкій графіці не малювався); прозорість 0.68 — кожній пупочці
	-- 03.11.2026: студи картки — одна картинка-плитка (StyleA.studTile, card), було ~320 Frame + UICorner на картку; прозорість 0.68
	local studs = StyleA.studTile(c, 10, 10, CW - 20, CH - 20, 46, C(th.stud), { ImageTransparency = 0.68 }, true)
	bands(c, CW, CH)
	local gloss = frame(c, 12, 12, CW - 24, math.floor(CH * 0.36), WHITE)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 12, 12, CW - 24, CH - 24, nil, { BackgroundTransparency = 1 }); local rimS = stroke(rim, C(th.rim), 6, 0.25)
	local stripH = math.max(10, math.floor(CH * 0.03))
	local strip = frame(c, 0, CH - stripH, CW, stripH, darken(C(th.grad[#th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	local icon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(CW / 2, 240), Size = UDim2.fromOffset(340, 340),
		BackgroundTransparency = 1, Image = d[3], ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, c)
	local lock = new("ImageLabel", { Position = UDim2.fromOffset(155, 150), Size = UDim2.fromOffset(190, 190), BackgroundTransparency = 1,
		Image = LOCK_ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Visible = false }, c)
	label(c, 0, 432, CW, 90, d[2], d[1], WHITE, 7)
	local value = label(c, 0, 530, CW, 70, key == "AutoCollect" and 40 or 50, "", WHITE, 6, { RichText = true }) -- Auto Collect: довший текст
	local bx, by, bw, bh = 70, 640, CW - 140, 100
	local saShadow = frame(c, bx, by + 8, bw, bh, Color3.new(0, 0, 0), { BackgroundTransparency = 0.7 })
	local sa = StyleA.new(c, { size = Vector2.new(bw, bh), position = Vector2.new(bx, by), color = "green", text = "", textSize = 58,
		clickable = true, zIndex = 2 })
	StyleA.follow(sa, saShadow) -- тінь кнопки масштабується й хитається разом з нею
	return { value = value, btn = sa.button, sa = sa, holder = holder, card = c, th = th, grad = cgrad, rim = rimS, strip = strip, studs = studs, icon = icon, lock = lock, locked = false }
end

-- закрита / відкрита картка: перефарбування (лише коли стан змінився)
local function setLocked(cd, locked: boolean)
	if cd.locked == locked then return end
	cd.locked = locked
	local th = locked and LOCK_TH or cd.th
	cd.grad.Color = cseq(th.grad)
	cd.rim.Color = C(th.rim)
	cd.strip.BackgroundColor3 = darken(C(th.grad[#th.grad][2]), 0.30)
	StyleA.studTint(cd.studs, C(th.stud))
	cd.icon.ImageColor3 = locked and C("8c9096") or WHITE
	cd.icon.ImageTransparency = locked and 0.25 or 0
	cd.lock.Visible = locked
end

local function buildPanel(niche: Model, screen: BasePart, ownerId: number)
	local mine = ownerId == player.UserId
	local PW = math.floor(PH * screen.Size.X / screen.Size.Y + 0.5)
	local g = new("SurfaceGui", { Name = "PlotUpgrades_" .. niche.Name, Adornee = screen,
		Face = Enum.NormalId[screen:GetAttribute("ScreenFace") or "Front"], SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = 400 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("8e939a"), { ClipsDescendants = true, Active = true })
	local PC = 56
	StyleA.studTile(root, 0, 0, PW, PH, PC, C("979ca3")) -- 03.11.2026: одна картинка замість ~1,000 Frame + UICorner + UIStroke
	local shade = frame(root, 0, 0, PW, PH, WHITE, { ZIndex = 2, Active = false })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.08, 1), NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 0.8) }) }, shade)
	local pb = frame(root, 0, 0, PW, PH, nil, { BackgroundTransparency = 1, ZIndex = 9, Active = false }); stroke(pb, INK, 5)
	local order = Cfg.CARD_ORDER
	local step0 = (CW + GAP) * CARD_K
	local rowW = math.ceil(SIDE * 2 + #order * CW * CARD_K + (#order - 1) * GAP * CARD_K)
	local vp = new("ScrollingFrame", { Position = UDim2.fromOffset(0, VP_Y), Size = UDim2.fromOffset(PW, VP_H), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.fromOffset(rowW, 0), ScrollBarThickness = 0, ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollingEnabled = true, ZIndex = 4 }, root)
	local row = frame(vp, 0, 0, rowW, VP_H, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local cards = {}
	for i, key in order do
		local cx = SIDE + CW * CARD_K / 2 + (i - 1) * step0
		local cy = CARD_TOP + (CH + 14) * CARD_K / 2
		cards[key] = card(row, cx - CW / 2, cy - (CH + 14) / 2, key)
	end
	local FADE_W = 150
	local function fade(x, rot)
		local f0 = frame(root, x, 0, FADE_W, PH, C("282c32"), { ZIndex = 5, Active = false })
		new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, f0)
		return f0
	end
	fade(0, 0); fade(PW - FADE_W, 180)
	local trackX = (PW - TRACK_W) / 2
	local track = new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(trackX, TRACK_Y), Size = UDim2.fromOffset(TRACK_W, TRACK_H),
		BackgroundColor3 = C("14161a"), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 6 }, root)
	track:SetAttribute("NoHoverSound", true)
	stroke(track, INK, 5)
	local thumbW = math.max(140, TRACK_W * PW / rowW)
	local thumb = StyleA.new(track, { size = Vector2.new(thumbW, TRACK_H), position = Vector2.new(0, 0), anchor = Vector2.new(0, 0), color = "green", zIndex = 7 })
	local arrows = {}
	for i, dir in { -1, 1 } do
		local ax = dir < 0 and trackX - ARROW - 18 or trackX + TRACK_W + 18
		local a = StyleA.new(root, { size = Vector2.new(ARROW, ARROW), position = Vector2.new(ax, TRACK_Y + TRACK_H / 2 - ARROW / 2), anchor = Vector2.new(0, 0), color = "gray",
			clickable = true, shine = false, zIndex = 7 })
		label(a.root, 0, -7, ARROW, 50, 54, dir < 0 and "‹" or "›", WHITE, 5, { ZIndex = 9 })
		arrows[i] = { sa = a, dir = dir }
	end
	local pn = { gui = g, screen = screen, ownerId = ownerId, cards = cards, can = {}, owned = {}, toggle = {}, x = 0, tx = 0, maxX = math.max(0, rowW - PW), anim = false }
	-- 10.11.2026: справжній максимум прокрутки (CanvasSize − вікно в одиницях SurfaceGui); розрахунковий rowW − PW міг бути більшим —
	--   у кінці ряду повзунок стояв посередині
	local function realMax() local m = vp.AbsoluteCanvasSize.X - vp.AbsoluteWindowSize.X; if m > 0 then pn.maxX = m end; return pn.maxX end
	local function clampT() pn.tx = math.clamp(pn.tx, 0, realMax()) end
	local function layout()
		pn.x = vp.CanvasPosition.X
		realMax()
		local u = pn.maxX > 0 and math.clamp(pn.x / pn.maxX, 0, 1) or 0
		thumb:setPosition(Vector2.new(u * (TRACK_W - thumbW), 0))
	end
	layout()
	vp:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not pn.anim then pn.tx = vp.CanvasPosition.X end
		layout()
	end)
	local step = RunService.Heartbeat:Connect(function(dt)
		if not pn.anim then return end
		local x = vp.CanvasPosition.X
		if math.abs(pn.tx - x) < 0.5 then
			vp.CanvasPosition = Vector2.new(pn.tx, 0)
			pn.anim = false
			return
		end
		vp.CanvasPosition = Vector2.new(x + (pn.tx - x) * (1 - math.exp(-14 * dt)), 0)
	end)
	g.Destroying:Connect(function() step:Disconnect() end)
	local function go() clampT(); pn.anim = true end
	for _, a in arrows do
		StyleA.bind(a.sa, { hoverAlways = true, canClick = function() return true end,
			onClick = function() pn.tx = pn.x + a.dir * step0; go() end })
	end
	local drag = nil
	-- 11.11.2026: свайп на телефоні. Зсув пальця рахуємо на ЕКРАНІ × масштаб полотна (заміряний на старті), а не променем щокадру:
	--   камера й персонаж рухались разом із пальцем → точка на табло стрибала → ряд смикався. Поріг 14 тепер без стрибка
	--   (рух починається з нуля), на відпусканні — інерція, а кнопка під пальцем після свайпу не натискається (StyleA.swipeUntil).
	--   Нативне гортання ScrollingFrame для дотику вимкнене зовсім (воно перехоплювало початок свайпу).
	local TOUCH_ONLY = UIS.TouchEnabled and not UIS.MouseEnabled
	if TOUCH_ONLY then vp.ScrollingEnabled = false end
	-- точка в координатах вьюпорта: мишка — GetMouseLocation, дотик — позиція + верхній відступ GUI
	local function pointOf(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			local inset = game:GetService("GuiService"):GetGuiInset()
			return Vector2.new(input.Position.X, input.Position.Y) + inset
		end
		return nil
	end
	-- одиниць полотна на 1 піксель екрана по X біля точки p
	local function kAt(p)
		local a = CardHover.surfaceX(g, p - Vector2.new(20, 0))
		local b = CardHover.surfaceX(g, p + Vector2.new(20, 0))
		if a and b and math.abs(b - a) > 1 then return (b - a) / 40 end
		return nil
	end
	local function startDrag(kind, input)
		if pn.maxX <= 0 then return end
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local p = pointOf(input) or UIS:GetMouseLocation()
		local sx = CardHover.surfaceX(g, p) or 0
		drag = { kind = kind, sx = sx, st = pn.tx, input = input, moved = false, touch = isTouch, px = p.X, k = isTouch and kAt(p) or nil,
			d0 = 0, v = 0, lt = os.clock(), ltx = pn.tx }
		if isTouch then vp.ScrollingEnabled = false end
		if kind == "track" then -- клік по доріжці поза повзунком — стрибок туди
			local rel = sx - track.AbsolutePosition.X
			local tl = pn.x / math.max(1, pn.maxX) * (TRACK_W - thumbW)
			if rel < tl or rel > tl + thumbW then pn.tx = (rel - thumbW / 2) / (TRACK_W - thumbW) * pn.maxX; go() end
			drag.st = pn.tx
		else
			drag.st = pn.x
		end
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then startDrag("track", input) end
	end)
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then startDrag("cards", input) end
	end)
	local moveConn = UIS.InputChanged:Connect(function(input)
		if not drag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= drag.input then return end
		local sx
		if drag.touch and drag.k then
			sx = drag.sx + (input.Position.X - drag.px) * drag.k
		else
			sx = CardHover.surfaceX(g, pointOf(input))
		end
		if not sx then return end
		local d = sx - drag.sx
		if drag.kind == "track" then
			pn.tx = drag.st + d * pn.maxX / math.max(1, TRACK_W - thumbW); go()
		elseif drag.moved or math.abs(d) > 14 then
			if not drag.moved then drag.moved = true; drag.d0 = d end
			pn.tx = drag.st - (d - drag.d0); go()
			StyleA.swipeUntil = os.clock() + 0.3
			local now = os.clock()
			local dt = now - drag.lt
			if dt > 0.004 then
				drag.v = drag.v * 0.5 + ((pn.tx - drag.ltx) / dt) * 0.5
				drag.lt, drag.ltx = now, pn.tx
			end
		end
	end)
	local endConn = UIS.InputEnded:Connect(function(input)
		if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then
			if drag.moved then
				StyleA.swipeUntil = os.clock() + 0.25
				-- інерція: лише якщо палець ще рухався в момент відпускання
				if drag.touch and os.clock() - drag.lt < 0.1 then
					pn.tx += math.clamp(drag.v * 0.16, -step0 * 2.5, step0 * 2.5); go()
				end
			end
			drag = nil
			vp.ScrollingEnabled = not TOUCH_ONLY
		end
	end)
	g.Destroying:Connect(function() moveConn:Disconnect(); endConn:Disconnect() end)
	for _, cd in cards do CardHover.attach(cd.holder, cd.card, function() return true end, CARD_K) end
	if mine then
		for key, cd in cards do
			-- tap = false: у покупки свій звук BuySound (без нашарування з tap)
			StyleA.bind(cd.sa, { hoverAlways = true, tap = false, canClick = function() return pn.can[key] == true end,
				onClick = function()
					-- 11.11.2026: перемикач — і з геймпасом, і з карткою на MAX (pn.toggle); той самий Set_AutoCollect, що й у SETTINGS
					if (pn.owned[key] or pn.toggle[key]) and key == "AutoCollect" then -- 09.11.2026: Auto Collect уже є — кнопка перемикає ON / OFF (Set_AutoCollect)
						local r = RS:FindFirstChild("Remotes")
						local ev = r and r:FindFirstChild("SettingsAction")
						if ev then ev:FireServer("AutoCollect", player:GetAttribute("Set_AutoCollect") == false) end
						return
					end
					if pn.owned[key] then -- Auto Sell уже є (картка або геймпас): кнопка SETTINGS відкриває вікно AutoSellWindow
						local ui = RS:FindFirstChild("UIEvents")
						local e = ui and ui:FindFirstChild("AutoSellOpen")
						if e then e:Fire() end
						return
					end
					UISfx.play("BuySound"); Action:FireServer("Upgrade", key)
				end })
		end
	else
		for _, cd in cards do
			cd.btn.Active = false
			cd.btn.Selectable = false
			pcall(function() cd.btn.Interactable = false end)
		end
	end
	return pn
end

-- рівні карток власника (атрибут PlotLv — JSON)
local function levelsOf(owner: Player?): { [string]: number }
	local raw = owner and owner:GetAttribute("PlotLv")
	if type(raw) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(t) == "table" then return t end
	end
	return {}
end

local panels = {} -- [niche] = pn
local function refresh()
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return end
	local camPos = camera.CFrame.Position
	for n, pn in panels do
		if not n:IsDescendantOf(workspace) or not pn.screen:IsDescendantOf(workspace) then pn.gui:Destroy(); panels[n] = nil end
	end
	for _, n in niches:GetChildren() do
		local ups = n:FindFirstChild("Upgrade panels")
		local board = ups and ups:FindFirstChild("Plot_Upgrade_panel")
		local screen = board and board:FindFirstChild("screen")
		local ownerId = (n:GetAttribute("OwnerUserId") :: number?) or 0
		local dist = screen and (screen.Position - camPos).Magnitude or math.huge
		local pn = panels[n]
		if pn and (dist > 200 or pn.ownerId ~= ownerId or pn.screen ~= screen) then pn.gui:Destroy(); panels[n] = nil; pn = nil end
		if not pn and screen and dist < 140 then pn = buildPanel(n, screen, ownerId); panels[n] = pn end
		if pn then
			local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil
			local money = owner and owner:GetAttribute("Money") or 0
			local lv = levelsOf(owner)
			local stage = stageOf(owner)
			for key, cd in pn.cards do
				local def = Cfg.CARDS[key]
				local l = math.clamp(math.floor(tonumber(lv[key]) or 1), 1, def.max)
				-- Auto Sell (29.10.2026): куплена картка або геймпас Auto Sell (тоді відкрита з мапи 1) — кнопка SETTINGS
				local owned = def.pass ~= nil and owner ~= nil and Cfg.cardOwned(key, owner) -- Auto Sell / Auto Collect (09.11.2026)
				pn.owned[key] = owned
				pn.toggle[key] = nil
				local open = owned or Cfg.cardOpen(key, stage)
				-- 11.11.2026: Auto Collect карткою (без геймпаса) теж слухається перемикача Set_AutoCollect (SETTINGS) — показуємо OFF
				local acOn = key == "AutoCollect" and owner ~= nil and owner:GetAttribute("Set_AutoCollect") ~= false
				setLocked(cd, not open)
				if owned then
					local on = owner:GetAttribute("Set_" .. key) ~= false
					cd.value.Text = on and '<font color="#D4FF3E">ON</font>' or '<font color="#FF8A96">OFF</font>'
					-- 09.11.2026: геймпас Auto Collect — збір одразу
					if key == "AutoCollect" then cd.value.Text = on and '<font color="#D4FF3E">Instant · ON</font>' or '<font color="#FF8A96">Instant · OFF</font>' end
					if key == "AutoCollect" then -- кнопка — перемикач
						cd.sa:setText(on and "TURN OFF" or "TURN ON")
						cd.sa:setColor(on and "red" or "green")
					else
						cd.sa:setText("SETTINGS")
						cd.sa:setColor("blue")
					end
					pn.can[key] = owner == player
				elseif not open then
					cd.value.Text = "Map " .. tostring(def.minStage)
					cd.sa:setText("MAP " .. tostring(def.minStage))
					cd.sa:setColor("gray")
					pn.can[key] = false
				elseif l >= def.max and key == "AutoCollect" then
					-- 11.11.2026: картка Auto Collect на MAX — кнопка стає перемикачем ON / OFF (як із геймпасом)
					cd.value.Text = acOn and string.format('<font color="#D4FF3E">Every %s · ON</font>', valueOf(key, l))
						or string.format('<font color="#FF8A96">Every %s · OFF</font>', valueOf(key, l))
					cd.sa:setText(acOn and "TURN OFF" or "TURN ON")
					cd.sa:setColor(acOn and "red" or "green")
					pn.toggle[key] = true
					pn.can[key] = owner == player
				elseif l >= def.max then
					cd.value.Text = string.format('<font color="#D4FF3E">MAX (%s%s)</font>', (key == "AutoCollect" and "every " or "") .. valueOf(key, l), MAX_SUFFIX[key] or "")
					cd.sa:setText("MAX")
					cd.sa:setColor("gray")
					pn.can[key] = false
				else
					local price = Cfg.cardPrice(key, l, stage)
					if key == "AutoCollect" then -- 09.11.2026: «раз на N с», щоб було зрозуміло, чому збір не моментальний
						cd.value.Text = string.format('<font color="#FFFFFF">%s</font> <font color="#D4FF3E">› %s</font>', l >= 2 and ("every " .. valueOf(key, l)) or "Off", (l >= 2 and "" or "every ") .. valueOf(key, l + 1))
						-- 11.11.2026: картку куплено, але в SETTINGS вимкнено — видно, що автозбір зараз не працює
						if l >= 2 and not acOn then cd.value.Text = string.format('<font color="#FF8A96">OFF</font> <font color="#D4FF3E">› every %s</font>', valueOf(key, l + 1)) end
					else
					cd.value.Text = string.format('<font color="#FFFFFF">%s</font>  <font color="#D4FF3E">›  %s</font>', valueOf(key, l), valueOf(key, l + 1))
					end
					cd.sa:setText(NF.money(price))
					cd.sa:setColor(money >= price and "green" or "gray")
					pn.can[key] = owner ~= nil and money >= price
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.15)
		local ok, err = pcall(refresh)
		if not ok then warn("PlotBoard: " .. tostring(err)) end
	end
end)
