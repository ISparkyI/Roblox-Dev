-- CaveStandUI — вікно стенда в печері (Cave слот, 10.11.2026): до 3 големів — один майнер, один воїн, один носій.
-- Де: StarterPlayer/StarterPlayerScripts/CaveStandUI (LocalScript). Сервер — ServerScriptService/CaveStandService.
-- Стиль і помічники — ті самі, що у вікні PLACE GOLEMS плоту (PlotPlaceUI: studs, «стиль A», слоти «C · Сяйво»).
-- Відкривається кнопкою стенда «OPEN» (E; StandPrompt, напис ставить CaveStandsClient), лише власнику в його печері.
-- Вікно:
--   ліворуч — вкладки Miners / Warriors / Carriers (синя — вибрана; під назвою «N / 1 saved»);
--   праворуч угорі — 3 слоти стенда: Miner · Warrior · Carrier; клік по зайнятому — забрати в інвентар, по порожньому — його вкладка;
--   нижче — сітка големів вибраного класу (без ексклюзивів і без 3D-моделі); голем з плоту — плашка PLOT N (його теж можна
--   поставити: сервер прибирає його з інвентаря, плот знімає його сам). Клік — поставити (клас зайнятий — заміна).
-- Дії — Remotes/CaveAction: "Place" { slot, id }, "Take" { slot, role }, "TutOpened" (навчання Cave, funnel).
-- Навчання Cave (атрибут CaveTut): вікно саме обирає, що запропонувати — найсильнішого голема першого вільного класу
--   (майнер → носій → воїн), ставить його першим у сітці; кнопка, на яку має показати рука (вкладка або слот голема),
--   отримує атрибут TutPick = true (TutorialClient шукає його). Тексту біля руки немає.
-- Закривається хрестиком, Esc, кліком по затемненню, коли гравець відійшов від стенда або вийшов з печери.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local Loc = require(RS.Shared:WaitForChild("Loc")) -- «PLOT N» — за рядком таблиці «PLOT {number1}» (старі записи «PLOT 3» давали «Сюжет»)
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog")) -- підпис статів (statText)
local GolemSort = require(RS.Shared:WaitForChild("GolemSort")) -- сортування (спільне з інвентарем) і кнопка зі списком SORT BY
local MutationSlotFX = require(RS.Shared:WaitForChild("MutationSlotFX")) -- фон слота за мутацією (як в інвентарі)
local NF = require(RS.Shared:WaitForChild("NumberFormat")) -- скорочення чисел у слотах (compact: 98.1K)
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local ItemVP = require(RS.Shared:WaitForChild("ItemViewport")) -- 3D-модель голема в слоті (у кого є модель: Stone, Wooden), як в інвентарі
local Action = RS:WaitForChild("Remotes"):WaitForChild("CaveAction") -- 10.11.2026: вікно стенда печери
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
	StyleA.studTile(studs, ox, oy, nx * CELL, ny * CELL, CELL, C("b3b8bf")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
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
	if s.fxSync then s.fxSync() end -- фон за мутацією: наведення / вибраний слот
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
	-- сяйва рідкості немає (як у інвентарі v20): у спокої слоти однакові темні; при наведенні й на вибраному (ON PLOT) — фон за мутацією
	local mfx = MutationSlotFX.new(card, { pos = Vector2.new(P, P), size = Vector2.new(S, S), z = 3 })
	local icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(P + pad, P + pad * 0.8),
		Size = UDim2.fromOffset(iw, iw), ZIndex = 4, Visible = false }, card)
	local name = textAt(card, P + 7, P + 15, S - 10, 13, "", WHITE, 2.2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	-- стат у два рядки (26.10.2026): головний — зелений, крупніше («98.1K dmg» / «25 ore», NumberFormat.compact), нижче — «Speed x2.81» світло-сірим
	local stat = textAt(card, P + 6, P + S - 27, S - 10, mini and 14 or 15, "", C("7dff5a"), 2.4, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	stat.TextScaled = true -- дуже довгий підпис зменшується, але не вилазить за картку
	new("UITextSizeConstraint", { MaxTextSize = mini and 14 or 15, MinTextSize = 10 }, stat)
	local spd = textAt(card, P + 6, P + S - 11, S - 10, 12, "", C("c9ced4"), 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local plus = textAt(card, P, P + S / 2, S, 34, "+", WHITE, 0, { TextTransparency = 0.62, ZIndex = 5, Visible = false })
	local lockImg = new("ImageLabel", { BackgroundTransparency = 1, Image = Items.ICONS.lock, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 0.15,
		Position = UDim2.fromOffset(P + S * 0.29, P + S * 0.16), Size = UDim2.fromOffset(S * 0.42, S * 0.42), ZIndex = 5, Visible = false }, card)
	local lockTxt = textAt(card, P, P + S - 13, S, 11, "Golem Slots", C("c9ced4"), 1.8, { FontFace = XBOLD, ZIndex = 5, Visible = false })
	local ring = frame(card, P - 1, P - 1, S + 2, S + 2, nil, { BackgroundTransparency = 1, ZIndex = 7, Visible = false })
	stroke(ring, LIME, 4)
	-- плашка ON PLOT / PLOT N — вище середини (з 26.10.2026), щоб не закривала дворядковий стат внизу
	local tag = frame(holder, P + S / 2 - 40, P + S * 0.42 - 12, 80, 24, C("3aa6ff"), { ZIndex = 8, Visible = false, Rotation = -8 })
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
		toneStroke.Color = WHITE; toneStroke.Transparency = 0.94
		mfx.setMut(has and (g.mut or 0) or nil)
		s.sel = opt.here == true
		s.dimmed = opt.dim == true
		icon.Visible = has
		if has then icon.Image = g.icon end
		-- голем з моделлю — g.vp ("GolemVP:<ID>:<клас>", з предметом за класом); сітка будує 3D лише у видимій зоні (s.lazyVP)
		s.icon = icon
		s.vpKey = has and g.vp or nil
		if s.lazyVP then s.vpDirty = true; s.lazyVP(s) else ItemVP.set(icon, s.vpKey) end
		name.Visible = has and not mini
		if has and not mini then name.Text = g.name end
		stat.Visible = has; spd.Visible = has
		if has then stat.Text = g.statMain or g.stat; spd.Text = g.statSpd or "" end
		plus.Visible = not has and opt.plus == true
		lockImg.Visible = opt.locked == true; lockTxt.Visible = opt.locked == true
		bgGrad.Color = cseq(opt.locked and { { 0, "2b3038" }, { 1, "1b1f25" } } or { { 0, "22262c" }, { 1, "15181c" } })
		ring.Visible = opt.here == true
		tag.Visible = opt.tag ~= nil
		if opt.tag then tagTxt.Text = opt.tag; tag.BackgroundColor3 = opt.tagHere and C("5bd12e") or C("3aa6ff") end
		local dim = opt.dim and 0.55 or 0
		icon.ImageTransparency = dim; bg.BackgroundTransparency = dim * 0.6
		s.fxSync()
	end
	function s.fxSync() mfx.setOn(s.g ~= nil and not s.dimmed and (s.hover or s.sel) == true) end
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
		StyleA.deny() -- звук відмови (tap цього кліку скасовується)
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
local PPS = game:GetService("ProximityPromptService")
local ROLES = { "miner", "warrior", "carrier" }
local ROLE_TITLE = { miner = "Miner", warrior = "Warrior", carrier = "Carrier" }
local ROLE_TAB = { miner = "Miners", warrior = "Warriors", carrier = "Carriers" }
local ROLE_ICON = { miner = Items.ICONS.class_miner, warrior = Items.ICONS.class_warrior, carrier = Items.ICONS.class_carrier }
local UI_REACH = 28 -- далі від кнопки стенда — вікно закривається (сервер приймає до 34)

local function decodeAttr(attr: string, default: any): any
	local v = player:GetAttribute(attr)
	if type(v) ~= "string" or v == "" then return default end
	local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
	return ok and type(t) == "table" and t or default
end
local RI = {}
for i, r in Catalog.RARITIES do RI[r] = i end
local function spdText(sp: number?): string
	return "Speed " .. (string.format("x%.2f", math.floor((sp or 1) * 100 + 0.5) / 100):gsub("0+$", ""):gsub("%.$", ""))
end
local function itemOf(g: any, order: number): any
	local def = Items.GOLEMS[g.kind]
	local cdef = Catalog.get(g.kind)
	if not (def and cdef) or type(g.id) ~= "number" then return nil end
	local cls = Catalog.cls(g.cls)
	local s = Catalog.stats(g.kind, cls, g.mut)
	return { id = g.id, kind = g.kind, cls = cls, mut = Catalog.mut(g.mut), name = def.name, icon = def.icon,
		vp = ItemVP.golemKey(g.kind, cls),
		statMain = cls == "carrier" and (NF.compact(s.cap or 0) .. " ore") or (NF.compact(s.dmg or 0) .. " dmg"),
		statSpd = cls == "warrior" and (NF.compact(s.hp or 0) .. " HP") or spdText(s.speed),
		power = Catalog.power(g.kind, cls, g.mut), order = order, ri = RI[def.rarity] or 0,
		ok = cdef.model ~= nil and not cdef.exclusive }
end
local golems = {}      -- големи інвентаря, які можна поставити
local onStand = {}     -- [клас] = голем на відкритому стенді
local savedAny = {}    -- [клас] = true, якщо голем цього класу стоїть на будь-якому стенді (навчання Cave)
local placedAt = {}    -- [id] = номер плоту
local standIdx = 0
local standModel: Instance? = nil
local function rebuild()
	table.clear(golems)
	for gi, g in decodeAttr("InvGolems", {}) do
		if type(g) == "table" then
			local it = itemOf(g, gi)
			if it and it.ok then table.insert(golems, it) end
		end
	end
	table.clear(placedAt)
	for k, s in decodeAttr("PlotAssign", {}) do
		local i = tonumber(k)
		if i and type(s) == "table" then
			if type(s.m) == "table" then for _, id in s.m do placedAt[id] = i end end
			if type(s.c) == "number" then placedAt[s.c] = i end
		end
	end
	table.clear(onStand)
	table.clear(savedAny)
	local gl = decodeAttr("CaveStandGolems", {})
	for _, rec in gl do if type(rec) == "table" then savedAny[Catalog.cls(rec.cls)] = true end end
	for _, r in ROLES do
		local rec = gl[tostring(standIdx) .. ":" .. r]
		if type(rec) == "table" then onStand[r] = itemOf(rec, 0) end
	end
end
local function bestOf(role: string): any
	local best = nil
	for _, g in golems do
		if g.cls == role and (not best or g.power > best.power or (g.power == best.power and g.order > best.order)) then best = g end
	end
	return best
end
-- навчання Cave: найсильніший голем першого класу (майнер → носій → воїн), якого ще немає в печері і який є в інвентарі
--   (воїна немає — його не пропонуємо); по черзі всі класи
local function tutPick(): any
	if player:GetAttribute("CaveTut") == nil then return nil end
	for _, r in { "miner", "carrier", "warrior" } do
		if not onStand[r] and not savedAny[r] then
			local b = bestOf(r)
			if b then return b end
		end
	end
	return nil
end
local function invFull(): boolean
	return Items.invGolemCount(decodeAttr("InvGolems", {}), decodeAttr("PlotPlaced", {})) >= Items.maxGolems(player)
end

-- =====================================================================
-- ===== вікно CAVE SLOT N =====
-- =====================================================================
local gui = new("ScreenGui", { Name = "CaveStandWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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
winF.Active = true

local titleBk = textAt(pop, WX + 32, WY - 8 + 7, 700, 96, "CAVE SLOT 1", INK, 9, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, WX + 32, WY - 8, 700, 96, "CAVE SLOT 1", WHITE, 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ffffff" }, { 0.3, "bdeaff" }, { 0.55, "5fc2ff" }, { 0.8, "2b86ee" }, { 1, "2a6fe0" } }) }, title)
local closeBtn = makeButton(pop, WX + WW - 70, WY - 34, 84, 84, { shadowDy = 8, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

local function btnOf(b: any): Instance return b.button or b.root end

-- ===== вкладки Miners / Warriors / Carriers =====
local tab = "miner"
local isOpen = false
local render -- нижче
local tabBtns = {}
for i, r in ROLES do
	local hold = frame(content, TX, 40 + (i - 1) * (TH + 12), TW, TH + 8, nil, { Name = "Tab_" .. r, BackgroundTransparency = 1, ZIndex = 4 })
	local b = makeButton(hold, 0, 0, TW, TH, { shadowDy = 7, color = "gray", z = 1, shine = false })
	b.onClick = function() tab = r; render() end
	new("ImageLabel", { BackgroundTransparency = 1, Image = ROLE_ICON[r], ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(62, 62), ZIndex = 4 }, hold)
	textAt(hold, 86, 32, 132, 25, ROLE_TAB[r], WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local c = textAt(hold, 86, 58, 132, 15, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5 })
	tabBtns[r] = { b = b, c = c }
end
local infoTxt = label(content, TX, 360, TW, 90, 16, "Saved golems stay with you on the next map", SUB_TXT, 2, { TextWrapped = true, FontFace = XBOLD, ZIndex = 4 })

-- ===== слоти стенда: Miner · Warrior · Carrier =====
local sec = frame(content, 288, 40, 650, 160, C("20242a"), { BackgroundTransparency = 0.45, ZIndex = 3 })
stroke(sec, C("14161a"), 3, 0.4)
local secPos = sec.Position
local slotRow = frame(content, 0, 0, WW, WH, nil, { BackgroundTransparency = 1, ZIndex = 5 })
local SL = {}
local SLX = { miner = 288 + 108 - SS / 2, warrior = 288 + 325 - SS / 2, carrier = 288 + 542 - SS / 2 }
for _, r in ROLES do
	textAt(content, SLX[r] - 40, 62, SS + 80, 22, ROLE_TITLE[r], WHITE, 2.8, { ZIndex = 4 })
	SL[r] = makeSlot(slotRow, SLX[r], SY, SS, true)
end
frame(content, 288 + 216, 72, 4, 112, INK, { BackgroundTransparency = 0.5, ZIndex = 4 })
frame(content, 288 + 433, 72, 4, 112, INK, { BackgroundTransparency = 0.5, ZIndex = 4 })

-- ===== сітка големів =====
local gridHdr = textAt(content, 290, 222, 360, 26, "", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local gridCap = textAt(content, 484, 222, 316, 15, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 4 })
local SORT_X, SORT_Y, SORT_W, SORT_H = 812, 204, 126, 40
local sortBtn = makeButton(content, SORT_X, SORT_Y, SORT_W, SORT_H, { shadowDy = 5, color = "gray", z = 5 })
local sortMenu = GolemSort.menu({ button = sortBtn, w = SORT_W, h = SORT_H, layer = pop,
	panelPos = Vector2.new(WX + SORT_X + SORT_W - 236, WY + SORT_Y + SORT_H + 8),
	onPick = function(key)
		player:SetAttribute("InvSort", key)
		local inv = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("InventoryAction")
		if inv then inv:FireServer("Sort", key) end
	end })
sortBtn.onClick = function() sortMenu.toggle() end
local gvp = frame(content, GX, GY, GW, GH, nil, { Name = "Grid", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 4 })
local gstrip = frame(gvp, 0, 0, GW, 10, nil, { BackgroundTransparency = 1, ZIndex = 1 })
local vsb = frame(content, GX + GW + 3, GY + GP, 10, GH - 2 * GP, WHITE, { Active = true, ZIndex = 5 })
new("UIGradient", { Color = cseq(TRACK), Rotation = 0 }, vsb); stroke(vsb, INK, 3)
local vth = frame(vsb, 0, 0, 10, 60, WHITE, { Active = true, ZIndex = 2 }); vgrad(vth, LIMEG)
textAt(content, 290, 497, 640, 13, "Tap a golem to save it · tap a slot to take it back", C("eef2f6"), 1.8, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 4 })
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

local gscroll, gH = 0, 0
local refreshGridVP: () -> () = function() end
local function gmax() return math.max(0, gH - GH) end
local function setG(v: number)
	gscroll = math.clamp(v, 0, gmax())
	gstrip.Position = UDim2.fromOffset(0, -gscroll)
	local th = math.max(40, (GH - 2 * GP) * GH / math.max(GH, gH))
	vth.Size = UDim2.fromOffset(10, th)
	vth.Position = UDim2.fromOffset(0, gmax() > 0 and gscroll / gmax() * (GH - 2 * GP - th) or 0)
	vsb.Visible = gmax() > 0
	refreshGridVP()
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
local function gridVP(s)
	local icon = s.icon
	if not icon then return end
	local margin = GS + GG
	local vis = s.holder.Visible and s.vpKey ~= nil and s.cy + GS / 2 >= gscroll - margin and s.cy - GS / 2 <= gscroll + GH + margin
	local want = if vis then s.vpKey else nil
	if s.vpShown == want and not s.vpDirty then return end
	s.vpShown = want
	s.vpDirty = false
	if want then
		ItemVP.set(icon, want)
	else
		ItemVP.set(icon, nil)
		local b = icon:FindFirstChild("ItemVP")
		if b then b:Destroy() end
		if s.g then icon.Image = s.g.icon end
	end
end
refreshGridVP = function() for _, s in gslots do gridVP(s) end end
local function gridSlot(i: number)
	local s = gslots[i]
	if not s then
		s = makeSlot(gstrip, 0, 0, GS, false)
		s.lazyVP = gridVP
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
render = function()
	titleBk.Text = "CAVE SLOT " .. standIdx; title.Text = "CAVE SLOT " .. standIdx
	local pick = tutPick()
	for _, r in ROLES do
		local t = tabBtns[r]
		t.b:setColor(tab == r and "blue" or "gray")
		t.c.Text = (onStand[r] and 1 or 0) .. " / 1 saved"
		btnOf(t.b):SetAttribute("TutPick", (pick ~= nil and pick.cls == r and tab ~= r) or nil)
	end
	-- слоти стенда
	for _, r in ROLES do
		local s = SL[r]
		local g = onStand[r]
		s.set(g, { plus = g == nil, here = g ~= nil })
		s.onClick = function()
			if g then
				if invFull() then s.shake(); say("Your inventory is full"); return end
				Action:FireServer("Take", { slot = standIdx, role = r })
			else
				tab = r; render()
			end
		end
	end
	-- сітка
	local list = {}
	for _, g in golems do if g.cls == tab then table.insert(list, g) end end
	GolemSort.sort(list, GolemSort.current(player))
	if pick and pick.cls == tab then
		local k = table.find(list, pick)
		if k and k > 1 then table.remove(list, k); table.insert(list, 1, pick) end
		gscroll = 0
	end
	gridHdr.Text = "Your " .. string.lower(ROLE_TAB[tab])
	gridCap.Text = #list .. " golems"
	sortMenu.refresh(GolemSort.current(player))
	local rows = math.max(2, math.ceil(#list / GCOLS))
	gH = rows * (GS + GG) - GG + 2 * GP + 4
	gstrip.Size = UDim2.fromOffset(GW, gH)
	for i, g in list do
		local s = gridSlot(i)
		s.holder.Visible = true
		s.place(((i - 1) % GCOLS) * (GS + GG) + GP, math.floor((i - 1) / GCOLS) * (GS + GG) + GP + 4)
		local w = placedAt[g.id]
		s.set(g, { tag = w and Loc.f("PLOT {number1}", w) or nil })
		s.hit:SetAttribute("TutPick", (pick ~= nil and g == pick) or nil)
	end
	for i = #list + 1, #gslots do gslots[i].holder.Visible = false; gslots[i].hit:SetAttribute("TutPick", nil) end
	setG(gscroll)
end

gridClick = function(s)
	local g = s.g
	Action:FireServer("Place", { slot = standIdx, id = g.id })
	local sl = SL[g.cls]
	if sl then task.delay(0.12, sl.pop) end
end

-- ===== масштаб, відкриття / закриття =====
local WindowFit = require(RS:WaitForChild("Shared"):WaitForChild("WindowFit"))
local WindowManager = require(RS:WaitForChild("Shared"):WaitForChild("WindowManager"))
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	if vs.X < 2 or vs.Y < 2 then return end
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
	WindowManager.opened("CaveStand") -- одне вікно на екрані: інші закриваються
	standIdx = idx
	rebuild()
	-- вкладка: навчання — клас запропонованого голема; інакше — перший порожній клас стенда
	local pick = tutPick()
	tab = pick and pick.cls or "miner"
	if not pick then
		for _, r in ROLES do if not onStand[r] then tab = r; break end end
	end
	fit()
	gscroll = 0
	render()
	if player:GetAttribute("CaveTut") ~= nil then Action:FireServer("TutOpened") end
	animToken += 1
	local my = animToken
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("CaveStandEsc", escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
end
close = function()
	if not isOpen then return end
	isOpen = false
	sortMenu.close()
	pcall(function() CAS:UnbindAction("CaveStandEsc") end)
	for _, r in ROLES do btnOf(tabBtns[r].b):SetAttribute("TutPick", nil) end
	for _, s in gslots do s.hit:SetAttribute("TutPick", nil) end
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
	end)
end
closeBtn.onClick = function() close() end
WindowManager.register("CaveStand", function() return isOpen end, function() close() end)
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

-- кнопка стенда «OPEN» (E) — відкрити вікно цього стенда
PPS.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if prompt.Name ~= "StandPrompt" or prompt:GetAttribute("UIText") ~= "OPEN" then return end
	local st = prompt.Parent and prompt.Parent.Parent
	local idx = st and st:GetAttribute("SlotIndex")
	if type(idx) ~= "number" or st:GetAttribute("Bought") ~= true then return end
	standModel = st
	open(idx)
end)

-- вийшов з печери / відійшов від стенда — вікно закривається
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not isOpen then return end
	acc += dt
	if acc < 0.2 then return end
	acc = 0
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local anchor = standModel and standModel:FindFirstChild("StandButton") :: BasePart?
	if player:GetAttribute("InCave") ~= true or not hrp or not anchor or (hrp.Position - anchor.Position).Magnitude > UI_REACH then close() end
end)

-- дані змінилися → перемалювати (раз за кадр)
local pending = false
player.AttributeChanged:Connect(function(name)
	if name == "InvGolems" or name == "PlotAssign" or name == "CaveStandGolems" or name == "InvSort" or name == "CaveTut" then
		if pending or not isOpen then return end
		pending = true
		task.defer(function()
			pending = false
			rebuild()
			if isOpen then render() end
		end)
	end
end)
