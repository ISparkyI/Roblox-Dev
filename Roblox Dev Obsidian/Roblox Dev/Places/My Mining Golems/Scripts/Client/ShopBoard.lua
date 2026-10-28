-- ShopBoard — табло TIME SKIPS у ніші між SELL і CAVE: Niche*/Upgrade panels/Time_skip_panel/screen (v2, 28.10.2026).
-- Де: StarterPlayer/StarterPlayerScripts/ShopBoard (LocalScript). Стиль і поведінка — як табло плотів (PlotBoard):
--   SurfaceGui у PlayerGui з Adornee на screen, сіра підкладка зі studs, високі картки з градієнтом, studs, косими смугами й кнопкою
--   «стиль A»; ряд карток прокручується вбок коліщатком, повзунком, стрілками або перетягуванням карток.
-- Картки — MonetizationConfig.TIME_SKIPS: назва, «+$…» (IncomePerMin × хв), вигода (skipBonus), кнопка з ціною в Robux.
--   Клік: є id — вікно покупки Roblox; id = 0 — SHOP на розділі TIME SKIPS (UIEvents/ShopOpenAt; там і за тікети).
--   Купує сам гравець, будь-яка ніша. Екран будується ближче 140 стадів, прибирається далі 200.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local CardHover = require(RS.Shared:WaitForChild("CardHover"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local PH = 1000 -- висота полотна; ширина — з пропорцій екрана (16 × 12,5 → 1280 × 1000)
local CW, CH, GAP = 500, 790, 90
local CARD_K, SIDE, CARD_TOP = 0.78, 110, 120
local VP_Y, VP_H = 0, 850
local TRACK_W, TRACK_H, TRACK_Y = 820, 40, 866
local ARROW = 56
local ROBUX = "rbxassetid://139687766069559"
local CASH = "rbxassetid://103015355952567"
local SKIP_ICON = "rbxassetid://76478987044650"

-- теми карток (як у PlotBoard): 1–3 — зелені, 4–6 — жовті, 7–9 — помаранчеві
local THEMES = {
	{ grad = { { 0, "8ef05a" }, { 0.55, "43b62a" }, { 1, "237a16" } }, rim = "d4ffb8", stud = "a9f57e", studShade = "2f8a1c" },
	{ grad = { { 0, "ffe27a" }, { 0.55, "f5b616" }, { 1, "b07a06" } }, rim = "fff1b8", stud = "ffe89a", studShade = "b98309" },
	{ grad = { { 0, "ffb15c" }, { 0.55, "f07a1e" }, { 1, "b8500c" } }, rim = "ffd2a3", stud = "ffc890", studShade = "b3520f" },
}
local function fmtMin(m: number): string
	if m < 60 then return m .. " Min" end
	local h = m / 60
	return h .. (h == 1 and " Hour" or " Hours")
end
local ITEMS = {}
for i, key in MonCfg.TIME_SKIPS do
	local d = MonCfg.Products[key]
	table.insert(ITEMS, { key = key, name = fmtMin(d.skipMin) .. " Skip", min = d.skipMin, robux = d.robux, id = d.id,
		bonus = math.floor(MonCfg.skipBonus(key) * 100 + 0.5), th = THEMES[math.clamp(math.ceil(i / 3), 1, 3)] })
end

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
local function tilted(parent, img, cx, cy, sz, z)
	new("ImageLabel", { BackgroundTransparency = 1, Image = img, ImageColor3 = INK, ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy + 10), Size = UDim2.fromOffset(sz, sz), Rotation = -8, ZIndex = z }, parent)
	new("ImageLabel", { BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(sz, sz), Rotation = -8, ZIndex = z + 1 }, parent)
end

-- картка (як у PlotBoard): годинник + маленькі гроші, назва, «+$…», вигода, кнопка з ціною в Robux
local function card(parent, x, y, it)
	local th = it.th
	local holder, o = CardHover.holder(parent, x, y, CW, CH, 14)
	frame(holder, o.X, o.Y + 14, CW, CH, Color3.new(0, 0, 0), { BackgroundTransparency = 0.65 })
	local c = frame(holder, o.X, o.Y, CW, CH, WHITE); vgrad(c, th.grad); stroke(c, INK, 6)
	local sg = new("Frame", { Name = "Studs", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(CW - 20, CH - 20), BackgroundTransparency = 1, ClipsDescendants = true }, c)
	local cell = 46
	for cx = 0, math.ceil((CW - 20) / cell) - 1 do
		for cy = 0, math.ceil((CH - 20) / cell) - 1 do
			local s = cell * 0.6; local so = (cell - s) / 2
			local a = frame(sg, cx * cell + so - 2, cy * cell + so + 2, s, s, C(th.studShade), { BackgroundTransparency = 0.68 }); corner(a, 5)
			local b = frame(sg, cx * cell + so, cy * cell + so, s, s, C(th.stud), { BackgroundTransparency = 0.68 }); corner(b, 5)
		end
	end
	bands(c, CW, CH)
	local gloss = frame(c, 12, 12, CW - 24, math.floor(CH * 0.36), WHITE)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 12, 12, CW - 24, CH - 24, nil, { BackgroundTransparency = 1 }); stroke(rim, C(th.rim), 6, 0.25)
	local stripH = math.max(10, math.floor(CH * 0.03))
	frame(c, 0, CH - stripH, CW, stripH, darken(C(th.grad[#th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	tilted(c, SKIP_ICON, CW / 2, 230, 330, 2)
	tilted(c, CASH, CW / 2 + 110, 330, 170, 4) -- маленькі гроші поверх годинника (як у SHOP)
	local title = label(c, 16, 432, CW - 32, 90, 68, it.name, WHITE, 7, { ZIndex = 6, TextScaled = true })
	new("UITextSizeConstraint", { MaxTextSize = 68 }, title)
	local value = label(c, 0, 520, CW, 66, 52, "", C("d4ff3e"), 6, { ZIndex = 6 })
	label(c, 0, 582, CW, 46, 34, it.bonus > 0 and ("+" .. it.bonus .. "% value") or "Instant Money", WHITE, 5, { ZIndex = 6 })
	local bx, by, bw, bh = 70, 650, CW - 140, 100
	local saShadow = frame(c, bx, by + 8, bw, bh, Color3.new(0, 0, 0), { BackgroundTransparency = 0.7 })
	local sa = StyleA.new(c, { size = Vector2.new(bw, bh), position = Vector2.new(bx, by), color = "green", text = "", clickable = true, zIndex = 2 })
	StyleA.follow(sa, saShadow)
	-- іконка Robux + ціна — однією групою по центру кнопки
	local pr = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -4),
		Size = UDim2.fromOffset(0, bh), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 12 }, sa.root)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, pr)
	new("ImageLabel", { BackgroundTransparency = 1, Image = ROBUX, ScaleType = Enum.ScaleType.Fit, LayoutOrder = 1,
		Size = UDim2.fromOffset(64, 64), ZIndex = 12 }, pr)
	label(pr, 0, 0, 0, bh, 58, NF.full(it.robux), WHITE, 6, { AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, ZIndex = 12 })
	return { it = it, value = value, sa = sa, holder = holder, card = c }
end

local function buy(it)
	if (it.id or 0) ~= 0 then
		pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, it.id)
	else
		-- продукт ще не створено в Creator Hub — SHOP на TIME SKIPS (там можна за тікети)
		local ev = RS:FindFirstChild("UIEvents")
		local b = ev and ev:FindFirstChild("ShopOpenAt")
		if b then b:Fire("TIME SKIPS") end
	end
end

local function buildPanel(niche: Model, screen: BasePart)
	local PW = math.floor(PH * screen.Size.X / screen.Size.Y + 0.5)
	local g = new("SurfaceGui", { Name = "TimeSkips_" .. niche.Name, Adornee = screen,
		Face = Enum.NormalId[screen:GetAttribute("ScreenFace") or "Front"], SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = 400 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("8e939a"), { ClipsDescendants = true, Active = true })
	local PC = 56
	for cx = 0, math.ceil(PW / PC) - 1 do
		for cy = 0, math.ceil(PH / PC) - 1 do stud(root, cx * PC, cy * PC, PC, C("979ca3"), C("6c7178"), C("aeb3b9")) end
	end
	local shade = frame(root, 0, 0, PW, PH, WHITE, { ZIndex = 2, Active = false })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.08, 1), NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 0.8) }) }, shade)
	local pb = frame(root, 0, 0, PW, PH, nil, { BackgroundTransparency = 1, ZIndex = 9, Active = false }); stroke(pb, INK, 5)
	local step0 = (CW + GAP) * CARD_K
	local rowW = math.ceil(SIDE * 2 + #ITEMS * CW * CARD_K + (#ITEMS - 1) * GAP * CARD_K)
	local vp = new("ScrollingFrame", { Position = UDim2.fromOffset(0, VP_Y), Size = UDim2.fromOffset(PW, VP_H), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.fromOffset(rowW, 0), ScrollBarThickness = 0, ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollingEnabled = true, ZIndex = 4 }, root)
	local row = frame(vp, 0, 0, rowW, VP_H, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local cards = {}
	for i, it in ITEMS do
		local cx = SIDE + CW * CARD_K / 2 + (i - 1) * step0
		local cy = CARD_TOP + (CH + 14) * CARD_K / 2
		cards[i] = card(row, cx - CW / 2, cy - (CH + 14) / 2, it)
	end
	local FADE_W = 150
	local function fade(x, rot)
		local f0 = frame(root, x, 0, FADE_W, PH, C("282c32"), { ZIndex = 5, Active = false })
		new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, f0)
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
	local pn = { gui = g, screen = screen, cards = cards, x = 0, tx = 0, maxX = math.max(0, rowW - PW), anim = false }
	local function clampT() pn.tx = math.clamp(pn.tx, 0, pn.maxX) end
	local function layout()
		pn.x = vp.CanvasPosition.X
		local u = pn.maxX > 0 and pn.x / pn.maxX or 0
		thumb:setPosition(Vector2.new(u * (TRACK_W - thumbW), 0))
	end
	-- старт з першої картки (Roblox іноді перекидає щойно створений ScrollingFrame в кінець)
	task.defer(function() vp.CanvasPosition = Vector2.zero; pn.tx = 0 end)
	task.delay(0.3, function() if not pn.anim and pn.tx == 0 then vp.CanvasPosition = Vector2.zero end end)
	layout()
	vp:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not pn.anim then pn.tx = vp.CanvasPosition.X end
		layout()
	end)
	local step = RunService.Heartbeat:Connect(function(dt)
		if not pn.anim then return end
		local x = vp.CanvasPosition.X
		if math.abs(pn.tx - x) < 0.5 then vp.CanvasPosition = Vector2.new(pn.tx, 0); pn.anim = false; return end
		vp.CanvasPosition = Vector2.new(x + (pn.tx - x) * (1 - math.exp(-14 * dt)), 0)
	end)
	g.Destroying:Connect(function() step:Disconnect() end)
	local function go() clampT(); pn.anim = true end
	for _, a in arrows do
		StyleA.bind(a.sa, { hoverAlways = true, canClick = function() return true end, onClick = function() pn.tx = pn.x + a.dir * step0; go() end })
	end
	local drag = nil
	local function pointOf(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			local inset = game:GetService("GuiService"):GetGuiInset()
			return Vector2.new(input.Position.X, input.Position.Y) + inset
		end
		return nil
	end
	local function startDrag(kind, input)
		if pn.maxX <= 0 then return end
		local sx = CardHover.surfaceX(g, pointOf(input)) or 0
		drag = { kind = kind, sx = sx, st = pn.tx, input = input, moved = false }
		if kind == "track" then
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
		local sx = CardHover.surfaceX(g, pointOf(input))
		if not sx then return end
		local d = sx - drag.sx
		if drag.kind == "track" then
			pn.tx = drag.st + d * pn.maxX / math.max(1, TRACK_W - thumbW); go()
		elseif input.UserInputType == Enum.UserInputType.MouseMovement and (drag.moved or math.abs(d) > 14) then
			drag.moved = true
			pn.tx = drag.st - d; go()
		end
	end)
	local endConn = UIS.InputEnded:Connect(function(input)
		if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then drag = nil end
	end)
	g.Destroying:Connect(function() moveConn:Disconnect(); endConn:Disconnect() end)
	for _, cd in cards do
		CardHover.attach(cd.holder, cd.card, function() return true end, CARD_K)
		StyleA.bind(cd.sa, { hoverAlways = true, canClick = function() return true end, onClick = function() buy(cd.it) end })
	end
	return pn
end

local panels = {} -- [niche] = pn
local function refresh()
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return end
	local camPos = camera.CFrame.Position
	for n, pn in panels do
		if not n:IsDescendantOf(workspace) or not pn.screen:IsDescendantOf(workspace) then pn.gui:Destroy(); panels[n] = nil end
	end
	local rate = tonumber(player:GetAttribute("IncomePerMin")) or 100
	for _, n in niches:GetChildren() do
		local ups = n:FindFirstChild("Upgrade panels")
		local board = ups and ups:FindFirstChild("Time_skip_panel")
		local screen = board and board:FindFirstChild("screen")
		local dist = screen and (screen.Position - camPos).Magnitude or math.huge
		local pn = panels[n]
		if pn and (dist > 200 or pn.screen ~= screen) then pn.gui:Destroy(); panels[n] = nil; pn = nil end
		if not pn and screen and screen:IsA("BasePart") and dist < 140 then pn = buildPanel(n, screen); panels[n] = pn end
		if pn then
			for _, cd in pn.cards do cd.value.Text = "+" .. NF.money(rate * cd.it.min) end
		end
	end
end

task.spawn(function()
	while true do
		local ok, err = pcall(refresh)
		if not ok then warn("ShopBoard: " .. tostring(err)) end
		task.wait(0.5)
	end
end)
