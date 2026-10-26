-- PlotPlaceUI — розстановка големів на плот: кнопка PLACE GOLEMS (коли гравець стоїть на своєму відкритому плоті)
-- і вікно «PLOT N» (стиль вікна інвентаря: studs, «стиль A», слоти «C · Сяйво»).
-- Де: StarterPlayer/StarterPlayerScripts/PlotPlaceUI (LocalScript). Сервер — ServerScriptService/PlotService.
-- Макет: веб-макет plot_ui (розділ «Place Golems», затверджений).
--
-- Вікно:
--   ліворуч — вкладки Miners / Carriers (синя — вибрана; під назвою «N / S placed») і зелена EQUIP BEST
--     (найкращі майнери й носії на всі відкриті плоти, безкоштовно → PlotAction "EquipBest");
--   праворуч угорі — слоти плоту: 5 майнерів (відкрито стільки, скільки дає картка Golem Slots, решта — замок
--     «Golem Slots») і 1 носій; клік по зайнятому слоту — зняти голема, по порожньому — відкрити потрібну вкладку;
--   нижче — сітка големів вибраного класу (найсильніші першими): на цьому плоті — лаймова рамка й ON PLOT,
--     на іншому — притемнений і PLOT N (клік переставить сюди), вільний — клік ставить у перший вільний слот.
--   Усі слоти майнерів зайняті — секція слотів хитається, «All miner slots are full».
-- Дії — Remotes/PlotAction: "Place" { plot, slot = "m1".."m5" | "c", id | nil }, "EquipBest".
-- Дані — атрибути гравця: InvGolems ({ id, kind, cls }), PlotAssign ({ [плот] = { m = {id..}, c = id } }), PlotLv (рівні карток).
-- Вікно закривається хрестиком, Esc, кліком по затемненню або коли гравець сходить з плоту.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local Action = RS:WaitForChild("Remotes"):WaitForChild("PlotAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== константи макета (одиниці дизайну; як у вікні інвентаря) =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528
local TX, TW, TH = 40, 222, 92
local SX, SY, SS, SG = 304, 86, 92, 100   -- слоти плоту: x першого, y, розмір, крок
local CX = 838                             -- слот носія
local GX, GY, GW, GH = 288, 240, 636, 246  -- сітка
local GS, GG, GCOLS, GP = 96, 24, 5, 12
local GLOW_N = 16
local CARRIER_ICON = "rbxassetid://91341404610533" -- ящик з рудою (як Crate Capacity)

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local LIME = C("c8ff6a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local TRACK = { { 0, "1a1d22" }, { 1, "353b44" } }
local LIMEG = { { 0, "eaff9a" }, { 0.5, "c3f04a" }, { 1, "8ccc22" } }

-- ===== помічники (як у InventoryUI) =====
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
local function textAt(parent, x, cy, w, size, text, color, sw, props)
	return label(parent, x, cy - size * 0.6, w, size * 1.2, size, text, color, sw, props)
end
local function stud(parent, x, y, cell, fill, shade, edge, edgeTh)
	local s = cell * 0.62
	local o = (cell - s) / 2
	local d = s * 0.12
	local r = s * 0.16
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade, { ZIndex = 1 }); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill, { ZIndex = 2 }); corner(st, r)
	if edge then stroke(st, edge, edgeTh or 2) end
end
local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end
local function isPress(inp: InputObject): boolean
	return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end
local function windowFrame(parent, x, y, w, h, z, shadowDy)
	frame(parent, x, y + shadowDy, w, h, BLACK, { Name = "WindowShadow", BackgroundTransparency = 0.65, ZIndex = z })
	local win = frame(parent, x, y, w, h, WHITE, { Name = "Window", ZIndex = z + 1 })
	vgrad(win, RIM); stroke(win, INK, 5)
	local rl = frame(win, 6, 6, w - 12, h - 12, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	stroke(rl, C("6a7078"), 1.5, 0.1)
	local pw, ph = w - 36, h - 36
	local panel = frame(win, 18, 18, pw, ph, C("a9aeb5"), { Name = "Panel", ZIndex = 2, ClipsDescendants = true })
	stroke(panel, INK, 4)
	local studs = frame(panel, 0, 0, pw, ph, nil, { Name = "Studs", BackgroundTransparency = 1, ZIndex = 1 })
	local CELL = 40
	local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
	local ox, oy = (pw - nx * CELL) / 2, (ph - ny * CELL) / 2
	for cx = 0, nx - 1 do
		for cy = 0, ny - 1 do stud(studs, ox + cx * CELL, oy + cy * CELL, CELL, C("b3b8bf"), C("868b92"), C("c8ccd1"), 1) end
	end
	local shade = frame(panel, 0, 0, pw, ph, WHITE, { Name = "Shade", ZIndex = 2 })
	new("UIGradient", { Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE), ColorSequenceKeypoint.new(1, WHITE) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1), NumberSequenceKeypoint.new(1, 0.82) }) }, shade)
	local content = frame(win, 0, 0, w, h, nil, { Name = "Content", BackgroundTransparency = 1, ZIndex = 3 })
	return win, content
end
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, shine = opt.shine, zIndex = opt.z + 1 })
	b.shadow = sh
	StyleA.follow(b, sh) -- тінь масштабується й хитається разом з кнопкою
	b.onClick = nil
	StyleA.bind(b, { debounce = opt.debounce or 0.15, hoverAlways = true, onClick = function() if b.onClick then b.onClick(b) end end })
	return b
end

-- сяйво слота (як в інвентарі)
local function glowTable(A, P)
	local function op(f) return A * math.max(0, 1 - f) ^ P end
	local t = {}
	for i = 1, GLOW_N do
		local a = 1 - (1 - op((i - 1) / GLOW_N)) / math.max(1e-6, 1 - op(i / GLOW_N))
		t[i] = 1 - math.clamp(a, 0, 1)
	end
	return t
end
local GLOW_ITEM = glowTable(0.85, 0.9)
local GLOW_EMPTY = glowTable(0.16, 1.4)

-- ===== наведення слотів (×1,025, нахил до 1,5°, натискання 0,96) =====
local hoverSet = {}
local hoverConn = nil
local function hoverStep(dt: number)
	local a = 1 - math.exp(-14 * dt)
	for s in hoverSet do
		local ts = s.down and 0.96 or (s.hover and 1.025 or 1)
		local tr = (s.hover and not s.down) and s.rel * 1.5 or 0
		s.sc += (ts - s.sc) * a
		s.rot += (tr - s.rot) * a
		if not s.hover and not s.down and math.abs(s.sc - 1) < 0.0005 and math.abs(s.rot) < 0.02 then
			s.sc, s.rot = 1, 0
			hoverSet[s] = nil
		end
		s.scale.Scale = s.sc
		s.card.Rotation = s.rot
	end
	if next(hoverSet) == nil and hoverConn then hoverConn:Disconnect(); hoverConn = nil end
end
local function wakeHover(s)
	hoverSet[s] = true
	if not hoverConn then hoverConn = RunService.Heartbeat:Connect(hoverStep) end
end

-- ===== слот голема =====
-- makeSlot(parent, x, y, S, mini) → s; s.set(g або nil, opt). opt: here (лаймова рамка), dim, tag (текст плашки), tagHere,
--   locked (замок «Golem Slots»), plus («+» у порожньому). s.onClick(s).
local slotIsDragging -- функція: чи щойно було перетягування сітки
local function makeSlot(parent, x, y, S, mini)
	local P = 16
	local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(S + 2 * P, S + 2 * P),
		Position = UDim2.fromOffset(x + S / 2, y + S / 2), ZIndex = 1 }, parent)
	local scale = new("UIScale", {}, holder)
	local card = frame(holder, 0, 0, S + 2 * P, S + 2 * P, nil, { Name = "Card", BackgroundTransparency = 1, ZIndex = 1 })
	frame(card, P, P + math.floor(S * 0.04 + 0.5), S, S, BLACK, { BackgroundTransparency = 0.7, ZIndex = 1 })
	local bg = frame(card, P, P, S, S, WHITE, { ZIndex = 2 })
	local bgGrad = vgrad(bg, { { 0, "22262c" }, { 1, "15181c" } }); stroke(bg, INK, S > 90 and 4 or 3)
	local tone = frame(card, P + 3, P + 3, S - 6, S - 6, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local toneStroke = stroke(tone, WHITE, S > 90 and 3 or 2, 0.94)
	local pad = S * (mini and 0.15 or 0.17)
	local iw = S - 2 * pad
	local gcx, gcy = P + pad + iw / 2, P + pad * 0.8 + iw / 2
	local R = S * 0.5
	local glow = frame(card, 0, 0, S + 2 * P, S + 2 * P, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local circles = {}
	for i = GLOW_N, 1, -1 do
		local rr = R * i / GLOW_N
		local g = frame(glow, gcx - rr, gcy - rr, rr * 2, rr * 2, WHITE, { BackgroundTransparency = 1, ZIndex = 1 })
		corner(g, UDim.new(0.5, 0))
		circles[i] = g
	end
	local icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(P + pad, P + pad * 0.8),
		Size = UDim2.fromOffset(iw, iw), ZIndex = 4, Visible = false }, card)
	local name = textAt(card, P + 7, P + 15, S - 10, 13, "", WHITE, 2.2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local stat = textAt(card, P + 6, P + S - 12, S - 10, mini and 11 or 12, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local plus = textAt(card, P, P + S / 2, S, 34, "+", WHITE, 0, { TextTransparency = 0.62, ZIndex = 5, Visible = false })
	local lockImg = new("ImageLabel", { BackgroundTransparency = 1, Image = Items.ICONS.lock, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 0.15,
		Position = UDim2.fromOffset(P + S * 0.29, P + S * 0.16), Size = UDim2.fromOffset(S * 0.42, S * 0.42), ZIndex = 5, Visible = false }, card)
	local lockTxt = textAt(card, P, P + S - 13, S, 11, "Golem Slots", C("c9ced4"), 1.8, { FontFace = XBOLD, ZIndex = 5, Visible = false })
	local ring = frame(card, P - 1, P - 1, S + 2, S + 2, nil, { BackgroundTransparency = 1, ZIndex = 7, Visible = false })
	stroke(ring, LIME, 4)
	local tag = frame(holder, P + S / 2 - 40, P + S * 0.58 - 12, 80, 24, C("3aa6ff"), { ZIndex = 8, Visible = false, Rotation = -8 })
	stroke(tag, INK, 3)
	local tagTxt = textAt(tag, 0, 12, 80, 13, "", WHITE, 2, { ZIndex = 9 })
	local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(P, P),
		Size = UDim2.fromOffset(S, S), ZIndex = 30 }, holder)
	hit:SetAttribute("NoHoverSound", true)
	local s = { holder = holder, card = card, scale = scale, sc = 1, rot = 0, rel = 0, hover = false, down = false,
		cx = x + S / 2, cy = y + S / 2, g = nil, onClick = nil, onPress = nil, S = S, hit = hit }
	function s.place(nx: number, ny: number) s.cx, s.cy = nx + S / 2, ny + S / 2; holder.Position = UDim2.fromOffset(s.cx, s.cy) end
	function s.set(g, opt)
		opt = opt or {}
		s.g = g
		local has = g ~= nil
		local tc = has and g.tone or WHITE
		local tbl = has and GLOW_ITEM or GLOW_EMPTY
		for i = 1, GLOW_N do
			circles[i].BackgroundColor3 = tc
			circles[i].BackgroundTransparency = opt.locked and 1 or tbl[i]
		end
		toneStroke.Color = tc; toneStroke.Transparency = has and 0.67 or 0.94
		icon.Visible = has
		if has then icon.Image = g.icon end
		name.Visible = has and not mini
		if has and not mini then name.Text = g.name end
		stat.Visible = has
		if has then stat.Text = g.stat end
		plus.Visible = not has and opt.plus == true
		lockImg.Visible = opt.locked == true; lockTxt.Visible = opt.locked == true
		bgGrad.Color = cseq(opt.locked and { { 0, "2b3038" }, { 1, "1b1f25" } } or { { 0, "22262c" }, { 1, "15181c" } })
		ring.Visible = opt.here == true
		tag.Visible = opt.tag ~= nil
		if opt.tag then tagTxt.Text = opt.tag; tag.BackgroundColor3 = opt.tagHere and C("5bd12e") or C("3aa6ff") end
		local dim = opt.dim and 0.55 or 0
		icon.ImageTransparency = dim; bg.BackgroundTransparency = dim * 0.6
		for i = 1, GLOW_N do if opt.dim then circles[i].BackgroundTransparency = 1 - (1 - tbl[i]) * 0.45 end end
	end
	local function aim(px: number)
		local c = holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2
		s.rel = math.clamp((px - c) / math.max(1, hit.AbsoluteSize.X / 2), -1, 1)
	end
	hit.MouseEnter:Connect(function(px) s.hover = true; aim(px); wakeHover(s) end)
	hit.MouseMoved:Connect(function(px) s.hover = true; aim(px); wakeHover(s) end)
	hit.MouseLeave:Connect(function() s.hover = false; s.down = false; wakeHover(s) end)
	hit.InputBegan:Connect(function(inp)
		if isPress(inp) then
			s.down = true; wakeHover(s)
			if s.onPress then s.onPress(inp) end
		end
	end)
	hit.InputEnded:Connect(function(inp) if isPress(inp) then s.down = false; wakeHover(s) end end)
	hit.Activated:Connect(function()
		if slotIsDragging and slotIsDragging() then return end
		StyleA.tap() -- звук натискання (слот — не StyleA.bind)
		if s.onClick then s.onClick(s) end
	end)
	function s.shake()
		task.spawn(function()
			for _, dx in { -8, 8, -5, 5, -2, 0 } do holder.Position = UDim2.fromOffset(s.cx + dx, s.cy); task.wait(0.03) end
			holder.Position = UDim2.fromOffset(s.cx, s.cy)
		end)
	end
	function s.pop()
		scale.Scale = 0.6
		tween(scale, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.15 }).Completed:Connect(function()
			tween(scale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 })
		end)
	end
	s.set(nil)
	return s
end

-- =====================================================================
-- ===== дані =====
-- =====================================================================
local function decodeAttr(attr: string, default: any): any
	local v = player:GetAttribute(attr)
	if type(v) ~= "string" or v == "" then return default end
	local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
	return ok and type(t) == "table" and t or default
end
local golems = {}   -- { id, kind, cls ("m" | "c"), name, icon, tone, stat, power }
local byId = {}
local assign = {}   -- [плот] = { m = {id..}, c = id? }
local lv = {}
local function rebuild()
	table.clear(golems); table.clear(byId)
	for _, g in decodeAttr("InvGolems", {}) do
		local def = Items.GOLEMS[g.kind]
		if def and type(g.id) == "number" then
			local st = Cfg.stats(g.kind, g.mut)
			local cls = g.cls == "carrier" and "c" or "m"
			local it = { id = g.id, kind = g.kind, mut = g.mut, cls = cls, name = def.name, icon = def.icon, tone = Items.RARITY[def.rarity] or WHITE,
				stat = cls == "m" and string.format("%d dmg · %.2fs", st.dmg, st.int) or string.format("%d ore · %.1f sp", st.cap, st.spd),
				power = cls == "m" and Cfg.minerPower(g.kind, g.mut) or Cfg.carrierPower(g.kind, g.mut) }
			table.insert(golems, it); byId[g.id] = it
		end
	end
	table.clear(assign)
	for k, s in decodeAttr("PlotAssign", {}) do
		local i = tonumber(k)
		if i and type(s) == "table" then assign[i] = { m = type(s.m) == "table" and s.m or {}, c = type(s.c) == "number" and s.c or nil } end
	end
	lv = decodeAttr("PlotLv", {})
end
local function slotsN(): number return Cfg.slotsOf(math.floor(tonumber(lv.Slots) or 1)) end
local function whereIs(id: number): number
	for i, s in assign do
		if s.c == id or table.find(s.m, id) then return i end
	end
	return 0
end

-- плот, на якому стоїть гравець (свій і відкритий) → індекс, модель
local function myNiche(): Model?
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return nil end
	for _, n in niches:GetChildren() do
		if n:GetAttribute("OwnerUserId") == player.UserId then return n end
	end
	return nil
end
local function standingPlot(): (number, Model?)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local n = myNiche()
	local plots = n and n:FindFirstChild("Plots")
	if not hrp or not plots then return 0, nil end
	for _, m in plots:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("Unlocked") == true then
			local base = m:FindFirstChild("Base") :: BasePart?
			local cf = base and base.CFrame or m:GetPivot()
			local l = cf:PointToObjectSpace(hrp.Position)
			if math.abs(l.X) <= Cfg.HALF + 1.5 and math.abs(l.Z) <= Cfg.HALF + 1.5 and l.Y > -4 and l.Y < 14 then
				return (m:GetAttribute("PlotIndex") :: number?) or 0, m
			end
		end
	end
	return 0, nil
end

-- =====================================================================
-- ===== кнопка PLACE GOLEMS =====
-- =====================================================================
local bGui = new("ScreenGui", { Name = "PlacePlotButton", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4 }, playerGui)
local bRoot = new("Frame", { Name = "Root", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(300, 120),
	Position = UDim2.new(0.5, 0, 0.5, 150), Visible = false }, bGui)
local bScale = new("UIScale", {}, bRoot)
-- поява / зникнення: CanvasGroup (прозорість усієї кнопки разом) з власним UIScale від центру; запас по краях — під збільшення
-- при наведенні (CanvasGroup обрізає все, що за її межами)
local BPX, BPY = 24, 18
local bAnim = new("CanvasGroup", { Name = "Anim", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(150, 60),
	Size = UDim2.fromOffset(300 + 2 * BPX, 120 + 2 * BPY), GroupTransparency = 1 }, bRoot)
local bPop = new("UIScale", { Scale = 0.8 }, bAnim)
local bTag = textAt(bAnim, BPX, BPY + 14, 300, 20, "", WHITE, 2.6, { FontFace = XBOLD })
local placeShadow = frame(bAnim, BPX, BPY + 38 + 7, 300, 80, BLACK, { BackgroundTransparency = 0.7 })
-- anchor за замовчуванням (центр) — наведення й натискання масштабують кнопку від центру
local placeBtn = StyleA.new(bAnim, { size = Vector2.new(300, 80), position = Vector2.new(BPX, BPY + 38), color = "green", text = "",
	clickable = true, zIndex = 2 })
StyleA.follow(placeBtn, placeShadow) -- тінь і надпис плоту над кнопкою масштабуються й хитаються разом з нею
StyleA.follow(placeBtn, bTag)
do
	local fx, fy, fw, fh = StyleA.faceRect(300, 80)
	new("ImageLabel", { BackgroundTransparency = 1, Image = Items.GOLEMS.stone.icon, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(fx + 14, fy - 2), Size = UDim2.fromOffset(fh + 4, fh + 4), ZIndex = 5 }, placeBtn.root)
	textAt(placeBtn.root, fx + fh + 22, fy + fh / 2, fw - fh - 30, 27, "PLACE GOLEMS", WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
end
local showButton -- нижче (плавна поява / зникнення)
local function fitButton()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or bGui.AbsoluteSize
	if vs.Y < 2 then return end
	local s = math.clamp(vs.Y / 720, 0.55, 1.4)
	s = math.min(s, (vs.X - 24) / 300)
	bScale.Scale = s
	bRoot.Position = UDim2.new(0.5, 0, 0.5, math.floor(150 * vs.Y / 720))
end

-- =====================================================================
-- ===== вікно PLOT N =====
-- =====================================================================
local gui = new("ScreenGui", { Name = "PlotPlaceWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10 }, playerGui)
local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local winF, content = windowFrame(pop, WX, WY, WW, WH, 1, 14)
winF.Active = true -- клік усередині вікна не доходить до затемнення (воно закриває вікно)

-- заголовок PLOT N (синій градієнт + тінь) і X
local titleBk = textAt(pop, WX + 32, WY - 8 + 7, 640, 96, "PLOT 1", INK, 9, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, WX + 32, WY - 8, 640, 96, "PLOT 1", WHITE, 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ffffff" }, { 0.3, "bdeaff" }, { 0.55, "5fc2ff" }, { 0.8, "2b86ee" }, { 1, "2a6fe0" } }) }, title)
local closeBtn = makeButton(pop, WX + WW - 70, WY - 34, 84, 84, { shadowDy = 8, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

-- ===== вкладки Miners / Carriers =====
local tab = "m"
local plotIdx = 0
local isOpen = false
local render -- нижче
local TABS = { { "m", "Miners", Items.GOLEMS.stone.icon }, { "c", "Carriers", CARRIER_ICON } }
local tabBtns = {}
for i, spec in TABS do
	local k = spec[1]
	local hold = frame(content, TX, 66 + (i - 1) * (TH + 14), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local b = makeButton(hold, 0, 0, TW, TH, { shadowDy = 7, color = "gray", z = 1, shine = false })
	b.onClick = function() tab = k; render() end
	new("ImageLabel", { BackgroundTransparency = 1, Image = spec[3], ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(70, 70), ZIndex = 4 }, hold)
	textAt(hold, 86, 32, 132, 25, spec[2], WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local c = textAt(hold, 86, 58, 132, 15, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5 })
	tabBtns[k] = { b = b, c = c }
end
local equipBtn = makeButton(content, TX, 300, TW, 84, { shadowDy = 7, color = "green", text = "EQUIP BEST", textSize = 30, z = 4 })
textAt(content, TX, 410, TW, 13, "Best golems on all plots · free", SUB_TXT, 1.8, { FontFace = XBOLD, ZIndex = 4 })

-- ===== слоти плоту =====
local sec = frame(content, 288, 40, 650, 160, C("20242a"), { BackgroundTransparency = 0.45, ZIndex = 3 })
stroke(sec, C("14161a"), 3, 0.4)
local secPos = sec.Position
local minersHdr = textAt(content, SX, 60, 400, 22, "", WHITE, 2.8, { TextXAlignment = Enum.TextXAlignment.Left, RichText = true, ZIndex = 4 })
textAt(content, CX - 10, 60, 120, 22, "Carrier", WHITE, 2.8, { ZIndex = 4 })
frame(content, CX - 22, 80, 4, 104, INK, { BackgroundTransparency = 0.5, ZIndex = 4 })
local slotRow = frame(content, 0, 0, WW, WH, nil, { BackgroundTransparency = 1, ZIndex = 5 })
local mSlots = {}
for i = 1, 5 do mSlots[i] = makeSlot(slotRow, SX + (i - 1) * SG, SY, SS, true) end
local cSlot = makeSlot(slotRow, CX, SY, SS, true)

-- ===== сітка големів =====
local gridHdr = textAt(content, 290, 222, 360, 26, "", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local gridCap = textAt(content, 620, 222, 316, 15, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 4 })
local gvp = frame(content, GX, GY, GW, GH, nil, { Name = "Grid", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 4 })
local gstrip = frame(gvp, 0, 0, GW, 10, nil, { BackgroundTransparency = 1, ZIndex = 1 })
local vsb = frame(content, GX + GW + 3, GY + GP, 10, GH - 2 * GP, WHITE, { Active = true, ZIndex = 5 })
new("UIGradient", { Color = cseq(TRACK), Rotation = 0 }, vsb); stroke(vsb, INK, 3)
local vth = frame(vsb, 0, 0, 10, 60, WHITE, { Active = true, ZIndex = 2 }); vgrad(vth, LIMEG)
local emptyHint = textAt(content, GX, GY + GH / 2, GW, 18, "", C("eef2f6"), 2.2, { FontFace = XBOLD, ZIndex = 5 })
textAt(content, 290, 497, 640, 13, "Tap a golem to place it · tap a slot to take it off", C("eef2f6"), 1.8, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 4 })
local toast = textAt(content, 288, 222, 650, 22, "", C("ff6b6b"), 3, { ZIndex = 60, TextTransparency = 1 })
local toastStroke = toast:FindFirstChildOfClass("UIStroke")
local toastTok = 0
local function say(text: string, color: Color3?)
	toastTok += 1
	local my = toastTok
	toast.Text = text; toast.TextColor3 = color or C("ff6b6b"); toast.TextTransparency = 0
	if toastStroke then toastStroke.Transparency = 0 end
	task.delay(1.4, function()
		if toastTok ~= my then return end
		tween(toast, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextTransparency = 1 })
		if toastStroke then tween(toastStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 }) end
	end)
end
local function shakeSec()
	task.spawn(function()
		for _, dx in { -8, 8, -5, 5, -2, 0 } do sec.Position = secPos + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		sec.Position = secPos
	end)
end

local gscroll, gH = 0, 0
local function gmax() return math.max(0, gH - GH) end
local function setG(v: number)
	gscroll = math.clamp(v, 0, gmax())
	gstrip.Position = UDim2.fromOffset(0, -gscroll)
	local th = math.max(40, (GH - 2 * GP) * GH / math.max(GH, gH))
	vth.Size = UDim2.fromOffset(10, th)
	vth.Position = UDim2.fromOffset(0, gmax() > 0 and gscroll / gmax() * (GH - 2 * GP - th) or 0)
	vsb.Visible = gmax() > 0
end
local drag, dragEndAt = nil, -1
local function unitsPerPx() local a = gvp.AbsoluteSize.Y return a > 0 and GH / a or 1 end
local function beginDrag(inp, thumb) if isPress(inp) then drag = { y = inp.Position.Y, s = gscroll, moved = false, thumb = thumb } end end
local function wheel(inp) if inp.UserInputType == Enum.UserInputType.MouseWheel and gmax() > 0 then setG(gscroll - inp.Position.Z * 70) end end
slotIsDragging = function() return (drag ~= nil and drag.moved) or os.clock() - dragEndAt < 0.15 end
gvp.InputBegan:Connect(function(inp) beginDrag(inp, false) end)
gvp.InputChanged:Connect(wheel)
vth.InputBegan:Connect(function(inp) beginDrag(inp, true) end)
UIS.InputChanged:Connect(function(inp)
	if not drag or not (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) or gmax() <= 0 then return end
	local dy = (inp.Position.Y - drag.y) * unitsPerPx()
	if drag.thumb then setG(drag.s + dy * gmax() / math.max(1, GH - 2 * GP - vth.Size.Y.Offset))
	else
		if math.abs(dy) > 6 then drag.moved = true end
		if drag.moved then setG(drag.s - dy) end
	end
end)
UIS.InputEnded:Connect(function(inp)
	if isPress(inp) and drag then if drag.moved then dragEndAt = os.clock() end drag = nil end
end)

local gslots = {}
local gridClick -- нижче
local function gridSlot(i: number)
	local s = gslots[i]
	if not s then
		s = makeSlot(gstrip, 0, 0, GS, false)
		s.onPress = function(inp) beginDrag(inp, false) end
		s.hit.InputChanged:Connect(wheel)
		s.onClick = function() if s.g then gridClick(s) end end
		gslots[i] = s
	end
	return s
end

-- =====================================================================
-- ===== логіка =====
-- =====================================================================
local function listOf(cls: string)
	local t = {}
	for _, g in golems do if g.cls == cls then table.insert(t, g) end end
	table.sort(t, function(a, b) if a.power ~= b.power then return a.power > b.power end return a.id < b.id end)
	return t
end
local function fire(slot: string, id: number?)
	Action:FireServer("Place", { plot = plotIdx, slot = slot, id = id })
end

render = function()
	local a = assign[plotIdx] or { m = {}, c = nil }
	local S = slotsN()
	titleBk.Text = "PLOT " .. plotIdx; title.Text = "PLOT " .. plotIdx
	-- вкладки
	for k, t in tabBtns do
		local on = tab == k
		t.b:setColor(on and "blue" or "gray")
		t.c.Text = k == "m" and (#a.m .. " / " .. S .. " placed") or ((a.c and 1 or 0) .. " / 1 placed")
	end
	-- слоти плоту
	minersHdr.Text = string.format('Miners <font color="#D4FF3E">%d / %d</font>', #a.m, S)
	for i = 1, 5 do
		local s = mSlots[i]
		if i > S then
			s.set(nil, { locked = true })
			s.onClick = function() s.shake(); say("Upgrade Golem Slots on the board") end
		else
			local g = a.m[i] and byId[a.m[i]] or nil
			s.set(g, { plus = g == nil })
			s.onClick = function()
				if g then fire("m" .. i, nil) else tab = "m"; render() end
			end
		end
	end
	local cg = a.c and byId[a.c] or nil
	cSlot.set(cg, { plus = cg == nil })
	cSlot.onClick = function() if cg then fire("c", nil) else tab = "c"; render() end end
	-- сітка
	local list = listOf(tab)
	gridHdr.Text = tab == "m" and "Your miners" or "Your carriers"
	gridCap.Text = #list .. " golems · strongest first"
	emptyHint.Text = #list == 0 and (tab == "m" and "No miner golems yet" or "No carrier golems yet") or ""
	local rows = math.max(2, math.ceil(#list / GCOLS))
	gH = rows * (GS + GG) - GG + 2 * GP + 4 -- 2 ряди влазять без повзунка
	gstrip.Size = UDim2.fromOffset(GW, gH)
	for i, g in list do
		local s = gridSlot(i)
		s.holder.Visible = true
		s.place(((i - 1) % GCOLS) * (GS + GG) + GP, math.floor((i - 1) / GCOLS) * (GS + GG) + GP + 4)
		local w = whereIs(g.id)
		s.set(g, { here = w == plotIdx, dim = w ~= 0 and w ~= plotIdx, tag = (w == plotIdx and "ON PLOT") or (w ~= 0 and ("PLOT " .. w)) or nil, tagHere = w == plotIdx })
	end
	for i = #list + 1, #gslots do gslots[i].holder.Visible = false end
	setG(gscroll)
end

gridClick = function(s)
	local g = s.g
	local a = assign[plotIdx] or { m = {}, c = nil }
	local w = whereIs(g.id)
	if w == plotIdx then -- уже тут → зняти
		if g.cls == "m" then
			local k = table.find(a.m, g.id)
			if k then fire("m" .. k, nil) end
		else
			fire("c", nil)
		end
		return
	end
	if g.cls == "m" then
		if #a.m >= slotsN() then shakeSec(); s.shake(); say("All miner slots are full"); return end
		fire("m" .. (#a.m + 1), g.id)
		local nxt = mSlots[#a.m + 1]
		if nxt then task.delay(0.12, nxt.pop) end
	else
		fire("c", g.id)
		task.delay(0.12, cSlot.pop)
	end
end
equipBtn.onClick = function()
	Action:FireServer("EquipBest")
	say("Best golems placed on all plots", C("d4ff3e"))
	task.delay(0.15, function()
		for _, s in mSlots do if s.g then s.pop() end end
		if cSlot.g then cSlot.pop() end
	end)
end

-- ===== масштаб, відкриття / закриття =====
local WindowFit = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowFit"))
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	fitButton()
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	local avail = vh - top - 8
	modalRoot.Position = UDim2.new(0.5, 0, 0, top + avail / 2)
	-- адаптивний масштаб: вікно займає однакову частку екрана (Shared/WindowFit)
	local UIS_ = game:GetService("UserInputService")
	local phone = avail < 500 or (UIS_.TouchEnabled and not UIS_.MouseEnabled)
	-- розмір і місце — спільне правило всіх вікон (Shared/WindowFit.place)
	WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WX, winY = WY, winW = WW, winH = WH })
end
local camConn
local function bindCamera()
	if camConn then camConn:Disconnect(); camConn = nil end
	local cam = workspace.CurrentCamera
	if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local animToken = 0
local open, close
local function escKey(_, state)
	if state == Enum.UserInputState.Begin then task.defer(function() if isOpen then close() end end) end
	return Enum.ContextActionResult.Sink
end
open = function(idx: number)
	if isOpen then return end
	isOpen = true
	plotIdx = idx
	rebuild()
	fit()
	gscroll = 0
	render()
	animToken += 1
	local my = animToken
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("PlotPlaceEsc", escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
end
close = function()
	if not isOpen then return end
	isOpen = false
	pcall(function() CAS:UnbindAction("PlotPlaceEsc") end)
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
	end)
end
closeBtn.onClick = function() close() end
-- затемнення закриває вікно лише кліком ПОЗА вікном (InputBegan затемнення спрацьовує й під самим вікном,
-- winF.Active цього не зупиняє). Позиція кліку й AbsolutePosition — в одному просторі (без GetGuiInset; заміряно в Play).
local function insideGui(p: Vector3, g: GuiObject?): boolean
	if not (g and g.Visible) then return false end
	local a, sz = g.AbsolutePosition, g.AbsoluteSize
	return p.X >= a.X and p.X <= a.X + sz.X and p.Y >= a.Y and p.Y <= a.Y + sz.Y
end
backdrop.InputBegan:Connect(function(inp)
	if not isPress(inp) then return end
	if insideGui(inp.Position, winF) or insideGui(inp.Position, title) or insideGui(inp.Position, closeBtn.root) then return end
	close()
end)

local curPlot = 0
-- плавна поява (0,2 с, Back) і зникнення (0,15 с) кнопки PLACE GOLEMS
local bShown = false
local bTok = 0
function showButton(on: boolean)
	if on == bShown then return end
	bShown = on
	bTok += 1
	local my = bTok
	if on then
		bRoot.Visible = true
		tween(bAnim, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { GroupTransparency = 0 })
		tween(bPop, 0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	else
		tween(bPop, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.8 })
		tween(bAnim, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency = 1 }).Completed:Connect(function()
			if bTok == my then bRoot.Visible = false end
		end)
	end
end
StyleA.bind(placeBtn, { hoverAlways = true, debounce = 0.3, onClick = function() if curPlot > 0 then open(curPlot) end end })

-- кнопка видна, коли гравець на своєму відкритому плоті; вікно закривається, коли зійшов з плоту
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.15 then return end
	acc = 0
	local idx = standingPlot()
	curPlot = idx
	if isOpen and idx ~= plotIdx then close() end
	local show = idx > 0 and not isOpen
	if show then bTag.Text = "Plot " .. idx end
	showButton(show)
end)

-- дані змінилися → перемалювати (раз за кадр)
local pending = false
player.AttributeChanged:Connect(function(name)
	if name == "InvGolems" or name == "PlotAssign" or name == "PlotLv" then
		if pending then return end
		pending = true
		task.defer(function()
			pending = false
			rebuild()
			if isOpen then render() end
		end)
	end
end)
rebuild()
