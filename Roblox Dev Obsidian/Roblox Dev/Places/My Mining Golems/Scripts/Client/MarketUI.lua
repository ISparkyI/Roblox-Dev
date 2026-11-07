--!nonstrict
-- MarketUI — продаж големів на маркеті (лише режим маркету, HubConfig.isMarket). 03.11.2026.
-- Де: StarterPlayer/StarterPlayerScripts/MarketUI (LocalScript). Сервер — ServerScriptService/MarketLotService (Remotes/MarketAction).
-- Унизу по центру (над хотбаром) — дві кнопки: SELL GOLEMS (зелена) і HISTORY (червона). Одне вікно (studs, як інші), три сторінки:
--   MY LISTED GOLEMS — плитка CREATE, мої лоти (3D-голем, мутація зверху з переливом, ціна з валютою під плиткою), вільні слоти,
--     одна плитка «+ · +3 SLOTS · R$ 79» (MonetizationConfig.Products.MarketSlots; VIP +2 тут не показується — лише в SHOP лобі).
--     Клік по лоту — вибір (галочка); знизу «N selected» + DELETE (Remotes/MarketAction "Unlist"). Праворуч зверху «Listed n/max».
--   LIST GOLEMS — ліворуч сітка вільних големів інвентаря (не на плотах, не виставлені; сортування за силою),
--     праворуч картка: рідкість, мутація, 3D-голем, назва, сила, «10% Fee», валюта (MONEY / GEMS / TICKETS), поле ціни
--     (розуміє 1.5K / 2M / 3B), «You get» після комісії, кнопка SELL ("List"). Унизу — попередження про шахраїв.
--   HISTORY — вкладки BOUGHT / SOLD (атрибут MktHistory): «Bought from @нік for N Tickets» (колір валюти), 3D-голем, назва,
--     рідкість · клас, мутація, «… ago».
--   SELLER (03.11.2026) — лоти іншого гравця: підійшов — стандартна підказка Roblox [E] «View Golems» (ProximityPrompt на його
--     HumanoidRootPart, лише коли в нього є лоти) → сітка його лотів; клік — вибір, знизу «Buy … for …?» + BUY (Remotes/MarketAction "Buy").
-- Големи-лоти ходять за власником (усі гравці бачать): блок FOLLOWERS нижче — клієнтські моделі (GolemModel.build) у точках
--   сітки за спиною гравця (ряди по 4), аура мутації, табличка «назва / Listed for / ціна».
local HubCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("HubConfig"))
if not HubCfg.isMarket() then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = RS:WaitForChild("Shared")
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local MutationText = require(Shared:WaitForChild("MutationText"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local GolemModel = require(Shared:WaitForChild("GolemModel"))
local okAura, MutationAura = pcall(require, Shared:WaitForChild("MutationAura"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CANVAS_W, CANVAS_H = 1286, 800
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1206, 650

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local ICON = {
	money = "rbxassetid://103015355952567", diamonds = "rbxassetid://126442692946356", tickets = "rbxassetid://85299808396483",
	vip = "rbxassetid://111200556390804", robux = "rbxassetid://139687766069559", sell = "rbxassetid://91791061262477",
}
-- 04.11.2026: діаманти — сині (як у HUD), назва Diamonds (було «Gems», фіолетові)
local CUR_COL = { money = "7ef05a", diamonds = "6fd2ff", tickets = "ffb21f" }
local CUR_NAME = { money = "Money", diamonds = "Diamonds", tickets = "Tickets" }
local MIN_PRICE = HubCfg.MARKET_MIN_PRICE or { money = 10000, diamonds = 100, tickets = 2 }

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
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], typeof(k[2]) == "Color3" and k[2] or C(k[2]))) end
	return ColorSequence.new(ks)
end
local function vgrad(o, keys) return new("UIGradient", { Color = cseq(keys), Rotation = 90 }, o) end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 6 }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	return t
end
local function fit(t, maxSize)
	t.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 9 }, t)
	return t
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
-- іконка монітора «Servers» (варіант 1 + рядки списку на екрані, 03.11.2026): світла рамка, блакитний екран,
-- 3 рядки (точка заповненості + смужка), ніжка й підставка; усе з фреймів у сітці 100×100, size — сторона в px
local SERVERS_ICON = "rbxassetid://127315281697455" -- rbxassetid іконки кнопки Servers (Free Icon Pack: Magnifying Glass 2nd Outline 256px)
local function monitorIcon(parent, x, y, size, z)
	local k = size / 100
	-- без чорних підкладок: краї — тонка сіро-синя лінія кольору рамки, а не товстий INK
	local EDGE = C("4a5566")
	local function R(px, py, w, h, col, zz, r, th, keys)
		local f = frame(parent, x + px * k, y + py * k, w * k, h * k, C(col), { ZIndex = zz })
		if r then corner(f, r >= 99 and UDim.new(1, 0) or r * k) end
		if th then stroke(f, EDGE, math.max(1, th * k)) end
		if keys then vgrad(f, keys) end
		return f
	end
	R(42, 69, 16, 14, "9aa4b0", z, nil, 2)                                   -- ніжка
	R(29, 82, 42, 8, "ffffff", z + 1, 99, 2, { { 0, "e3e8ee" }, { 1, "aab4bf" } }) -- підставка
	R(9, 13, 82, 58, "ffffff", z + 1, 14, 2, { { 0, "f2f5f8" }, { 1, "b9c2cc" } }) -- рамка
	R(18, 21, 64, 41, "ffffff", z + 2, 8, 2, { { 0, "8fe0ff" }, { 1, "2f86e8" } }) -- екран
	local rows = { { 27, 38, "7ef05a" }, { 38, 30, "7ef05a" }, { 49, 34, "ffd23a" } }
	for _, rw in rows do
		R(23, rw[1], 8, 8, rw[3], z + 3, 99)
		R(35, rw[1] + 1, rw[2], 6, "ffffff", z + 3, 99)
	end
end
-- вибрана клітинка: перефарбовується її власна обводка (другий UIStroke на тому ж фреймі малювався в випадковому порядку — «крива» обводка)
local function pickRing(tile: GuiObject)
	local st = tile:FindFirstChildOfClass("UIStroke")
	if st then st.Color = C("c8ff6a"); st.Thickness = 6; st.Transparency = 0 else stroke(tile, C("c8ff6a"), 6) end
end
local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
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
	local content = frame(win, 0, 0, w, h, nil, { Name = "Content", BackgroundTransparency = 1, ZIndex = 3 })
	return win, content
end
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + (opt.shadowDy or 5), w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z or 5 })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, shine = opt.shine, zIndex = (opt.z or 5) + 1, half = opt.half })
	b.shadow = sh
	StyleA.follow(b, sh)
	b.onClick = nil
	StyleA.bind(b, { debounce = 0.2, onClick = function() if b.onClick then b.onClick(b) end end })
	function b:show(on) b.root.Visible = on; sh.Visible = on end
	return b
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end
local function decode(a: string, def: any): any
	local s = player:GetAttribute(a)
	if type(s) ~= "string" or s == "" then return def end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return (ok and type(v) == "table") and v or def
end
local function priceText(p: number, cur: string): string
	if cur == "money" then return NF.money(p) end
	return NF.short(p) .. " " .. (CUR_NAME[cur] or "")
end
local function mutName(m: number): string
	local d = Catalog.mutation(m)
	return (d and d.key) or "Normal"
end
local function ago(t: number): string
	local d = math.max(0, os.time() - (tonumber(t) or 0))
	if d < 60 then return d .. "s ago" elseif d < 3600 then return (d // 60) .. "m ago" elseif d < 86400 then return (d // 3600) .. "h ago" end
	return (d // 86400) .. "d ago"
end
local function rarityGrad(rar: string?)
	local c = Catalog.rarityColor(rar)
	return { { 0, c:Lerp(WHITE, 0.45) }, { 1, c:Lerp(BLACK, 0.25) } }
end
local function action(name: string, arg: any): any
	local r = RS:FindFirstChild("Remotes")
	local rf = r and r:FindFirstChild("MarketAction")
	if not rf then return nil end
	local ok, res = pcall(rf.InvokeServer, rf, name, arg)
	return ok and res or nil
end
-- "1.5K" / "2M" / "3B" / "12,500" → число
-- 06.11.2026: усі суфікси NumberFormat (K, M, B, T, Qa, Qi, Sx … Vg), регістр не важливий; і науковий запис 1.23e66
local SUF = { k = 1e3 }
for i, s in NF.SUFFIXES do SUF[string.lower(s)] = 10 ^ (3 * i + 3) end
local function parsePrice(s: string): number?
	s = string.lower((s or ""):gsub("[%s,%$]", ""))
	local n = if string.match(s, "^[%d%.]+e%d+$") then tonumber(s) else nil
	if not n then
		local num, suf = string.match(s, "^([%d%.]+)(%a*)$")
		n = tonumber(num or "")
		if not n then return nil end
		if suf ~= "" then
			if not SUF[suf] then return nil end
			n *= SUF[suf]
		end
	end
	if n ~= n or n >= math.huge then return nil end
	n = math.floor(n)
	return n >= 1 and n or nil
end

-- ===== дані =====
local function golems(): { any }
	local placed = {}
	for _, id in decode("PlotPlaced", {}) do placed[id] = true end
	local listed = {}
	for _, l in decode("MktLots", {}) do if type(l) == "table" then listed[l.id] = true end end
	local out = {}
	for _, g in decode("InvGolems", {}) do
		local def = type(g) == "table" and Catalog.get(g.kind)
		if def and type(g.id) == "number" and not placed[g.id] and not listed[g.id] and not HubCfg.marketBlocked(def.id, Catalog.cls(g.cls)) then
			local cls, mut = Catalog.cls(g.cls), Catalog.mut(g.mut)
			table.insert(out, { id = g.id, def = def, cls = cls, mut = mut, power = Catalog.power(def.id, cls, mut) })
		end
	end
	table.sort(out, function(a, b) if a.power ~= b.power then return a.power > b.power end return a.id < b.id end)
	return out
end
local function golemById(id: number): any
	for _, g in decode("InvGolems", {}) do if type(g) == "table" and g.id == id then return g end end
	return nil
end

-- ===== вікно =====
local gui = new("ScreenGui", { Name = "MarketWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10 }, playerGui)
local backdrop = new("TextButton", { Name = "Backdrop", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK,
	BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local _, content = windowFrame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, 1, 14)

-- заголовок з переливом (жовто-помаранчевий)
-- довгі назви (нік продавця) зменшуються і не налазять на кнопки справа (ширина до лічильника / X)
fit(label(pop, WIN_X + 10, 6 + 7, WIN_W - 140, 100, 84, "", INK, 9, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Name = "TitleShadow" }), 84)
local title = fit(label(pop, WIN_X + 10, 6, WIN_W - 140, 100, 84, "", WHITE, 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }), 84)
local titleShadow = pop:FindFirstChild("TitleShadow")
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
-- «Listed N/M» — переклад через Shared/Loc (таблиця локалізації), автопереклад на цій мітці вимкнений
local Loc = require(RS:WaitForChild("Shared"):WaitForChild("Loc"))
local counter = label(pop, WIN_X + WIN_W - 560, 22, 440, 60, 46, "", C("5cc8ff"), 6, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, AutoLocalize = false })
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })
local backBtn = makeButton(pop, WIN_X + WIN_W - 300, WIN_Y - 30, 190, 72, { shadowDy = 6, color = "gray", text = "< BACK", textSize = 30, z = 5 })
local function setTitle(s: string)
	title.Text = s; titleShadow.Text = s
	-- з лічильником / BACK праворуч заголовок вужчий
	local w = (s == "LIST GOLEMS") and 640 or (s == "MY LISTED GOLEMS") and 640 or (WIN_W - 140)
	title.Size = UDim2.fromOffset(w, 100); titleShadow.Size = UDim2.fromOffset(w, 100)
end
do
	local P = { C("fff3c4"), C("ffd23a"), C("f58a1f"), C("ffd23a") }
	RunService.Heartbeat:Connect(function()
		if not modalRoot.Visible then return end
		local function sample(u)
			local x = (u % 1) * #P
			local i = math.floor(x)
			local t = x - i
			t = t * t * (3 - 2 * t)
			return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
		end
		local phase = -(os.clock() / 4)
		local ks = {}
		for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end
		titleGrad.Color = ColorSequence.new(ks)
	end)
end
local warn1 = label(pop, 0, WIN_Y + WIN_H + 20, CANVAS_W, 40, 30, "Beware of scams! Don't trust strangers or suspicious offers.", C("ff5ab4"), 4, { ZIndex = 4 })

local pages = {}
local function page(name: string): Frame
	local f = frame(content, 18, 18, WIN_W - 36, WIN_H - 36, nil, { Name = name, BackgroundTransparency = 1, ZIndex = 4, Visible = false })
	pages[name] = f
	return f
end
local PW, PH = WIN_W - 36, WIN_H - 36
local function scroll(parent, x, y, w, h, cellW, cellH, pad)
	local s = new("ScrollingFrame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 10, ScrollBarImageColor3 = INK, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 5 }, parent)
	-- верхній відступ: заголовок вікна не напливає на перший ряд слотів
	new("UIPadding", { PaddingTop = UDim.new(0, cellW and 46 or 18), PaddingLeft = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }, s)
	if cellW then
		new("UIGridLayout", { CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset(pad, pad), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	else
		new("UIListLayout", { Padding = UDim.new(0, pad), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	end
	return s
end
local function clear(s) for _, c in s:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end end
-- плитка голема: градієнт рідкості, 3D-модель, ціна / сила внизу
-- фон мутації як у слотах інвентаря (Bronze…Secret; Shared/MutationSlotFX), 03.11.2026
local okMFX, MutationSlotFX = pcall(require, RS:WaitForChild("Shared"):WaitForChild("MutationSlotFX"))
local function golemTile(parent, w, h, kind, cls, mut, bottomText, bottomColor, order)
	local def = Catalog.get(kind)
	local cell = frame(parent, 0, 0, w, h, nil, { BackgroundTransparency = 1, LayoutOrder = order or 0, ZIndex = 5 })
	local tile = frame(cell, 0, 0, w, h, WHITE, { ZIndex = 5, ClipsDescendants = true })
	vgrad(tile, rarityGrad(def and def.rarity)); stroke(tile, INK, 4)
	local m = Catalog.mut(mut)
	if okMFX and m > 0 then
		local ok, fx = pcall(MutationSlotFX.new, tile, { pos = Vector2.new(0, 0), size = Vector2.new(w, h), z = 5 })
		if ok and fx then fx.setMut(m); fx.setOn(true) end
	end
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = StyleA.ASSETS.stylea_tile_gray or "", ImageTransparency = 0.75,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(48, 48), ZIndex = 5 }, tile)
	local img = new("ImageLabel", { BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(w - 12, h - 30), ZIndex = 6 }, tile)
	if def then pcall(ItemViewport.set, img, ItemViewport.golemKey(def.id, cls), 1.05) end
	if bottomText then fit(label(tile, 4, h - 40, w - 8, 36, 28, bottomText, bottomColor or C("b6ff5c"), 3.5, { ZIndex = 8 }), 28) end
	local btn = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9 }, cell)
	return cell, btn, tile
end

-- ===== сторінка 1: MY LISTED GOLEMS =====
local pList = page("Listed")
local listedScroll = scroll(pList, 0, 0, PW, PH - 70, 190, 236, 18)
local selBar = frame(pList, PW - 720, PH - 66, 720, 64, nil, { BackgroundTransparency = 1, ZIndex = 6, Visible = false })
local selText = label(selBar, 0, 0, 470, 64, 34, "", WHITE, 5, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })
local delBtn = makeButton(selBar, 490, 2, 220, 60, { shadowDy = 5, color = "red", text = "DELETE", textSize = 30, z = 7 })
local selected: { [number]: boolean } = {}

-- ===== сторінка 2: LIST GOLEMS =====
local pSell = page("Sell")
local RPW = 400
local SC = 164 -- 04.11.2026: плитка 164 + проміжок 12 — 4 големи в ряд (було 176 / 16 — 3)
local sellScroll = scroll(pSell, 0, 0, PW - RPW - 16, PH, SC, SC, 12)
local right = frame(pSell, PW - RPW, 0, RPW, PH, C("6f757d"), { ZIndex = 5 })
stroke(right, INK, 4)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.15) }, right)
local rRar = fit(label(right, 10, 40, RPW - 20, 36, 34, "", WHITE, 4, { ZIndex = 7 }), 34)
local rMut = fit(label(right, 10, 74, RPW - 20, 24, 22, "", WHITE, 3, { ZIndex = 7 }), 22)
local rImgHold = frame(right, (RPW - 210) / 2, 100, 210, 154, nil, { BackgroundTransparency = 1, ZIndex = 6 })
local rImg = new("ImageLabel", { BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(1, 1), ZIndex = 7 }, rImgHold)
local rName = fit(label(right, 10, 254, RPW - 20, 40, 36, "", WHITE, 4, { ZIndex = 7 }), 36)
local rPow = fit(label(right, 10, 292, RPW - 20, 32, 30, "", C("b6ff5c"), 4, { ZIndex = 7 }), 30)
label(right, 10, 340, RPW - 20, 30, 26, "Sell it for:", WHITE, 4, { ZIndex = 7 }) -- комісії немає (03.11.2026)
local curBtns = {}
local curSel = "tickets"
for i, k in { "money", "diamonds", "tickets" } do
	local b = makeButton(right, 12 + (i - 1) * 128, 388, 120, 50, { shadowDy = 4, color = "gray", text = CUR_NAME[k], textSize = 22, z = 7 })
	curBtns[k] = b
end
local priceBoxBg = frame(right, 24, 450, RPW - 48, 58, WHITE, { ZIndex = 7 })
stroke(priceBoxBg, INK, 4)
local priceBox = new("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), FontFace = HEAVY, TextSize = 32,
	TextColor3 = INK, PlaceholderText = "Enter price", PlaceholderColor3 = C("8a9097"), Text = "", ClearTextOnFocus = false, ZIndex = 8,
	TextSize = 30, ClipsDescendants = true }, priceBoxBg)
-- 04.11.2026 v2 (телефон): TextScaled у полі вводу на деяких телефонах не діє під час набору — цифри вилазили за рамку.
--   Тепер шрифт сталий (30), а в полі лише цифри, крапка, кома й суфікс K / M / B / T, не довше PRICE_MAX_LEN символів —
--   так текст завжди влазить у рамку (10 символів × ~22 px < ширини поля).
-- 06.11.2026: без ліміту довжини (лише захисна межа 320 символів — далі число все одно «нескінченність»); довший текст — менший шрифт.
--   Після вводу (FocusLost) довге число скорочується: 1111111111111111 → 1.11Qa, далі Vg — 1.11e90. Суфікси — будь-які літери.
local PRICE_MAX_LEN = 320
local priceFixing = false
priceBox:GetPropertyChangedSignal("Text"):Connect(function()
	if priceFixing then return end
	local s = priceBox.Text:gsub("[^%d%.,%a]", "")
	if #s > PRICE_MAX_LEN then s = s:sub(1, PRICE_MAX_LEN) end
	priceBox.TextSize = #s <= 10 and 30 or math.max(12, math.floor(30 * 10 / #s))
	if s ~= priceBox.Text then
		priceFixing = true
		priceBox.Text = s
		priceBox.CursorPosition = #s + 1
		priceFixing = false
	end
end)
-- 06.11.2026: довге число після вводу — короткий запис (ціна = скорочене число, як у Price:)
priceBox.FocusLost:Connect(function()
	if #priceBox.Text <= 10 then return end
	local p = parsePrice(priceBox.Text)
	if p and p >= 1e6 then
		local t = NF.short(p)
		if t ~= priceBox.Text then priceBox.Text = t end
	end
end)
local rGet = fit(label(right, 10, 512, RPW - 20, 28, 22, "", WHITE, 3, { ZIndex = 7, FontFace = XBOLD, RichText = true }), 22)
local sellBtn = makeButton(right, (RPW - 220) / 2, PH - 72, 220, 62, { shadowDy = 5, color = "green", text = "SELL", textSize = 34, z = 7 })
local pickId: number? = nil
local sellEmpty = label(pSell, 0, PH / 2 - 60, PW, 120, 40, "No golems to sell\nRoll golems in the cave first!", WHITE, 4, { ZIndex = 8, Visible = false })

-- ===== сторінка 3: HISTORY =====
local pHist = page("History")
local hTab = "b"
-- 06.11.2026: вкладки нижче (y 4 → 30) — на малому екрані заголовок HISTORY налазив на BOUGHT
local tabB = makeButton(pHist, PW / 2 - 250, 30, 230, 64, { shadowDy = 5, color = "green", text = "BOUGHT", textSize = 32, z = 6 })
local tabS = makeButton(pHist, PW / 2 + 20, 30, 230, 64, { shadowDy = 5, color = "gray", text = "SOLD", textSize = 32, z = 6 })
local histScroll = scroll(pHist, 0, 110, PW, PH - 110, nil, nil, 12)
local histEmpty = label(pHist, 0, PH / 2, PW, 40, 30, "", WHITE, 4, { ZIndex = 6 })

-- ===== сторінка 4: лоти іншого гравця (купівля) =====
local pSeller = page("Seller")
local sellerScroll = scroll(pSeller, 0, 0, PW, PH - 76, 190, 236, 18)
local sellerEmpty = label(pSeller, 0, PH / 2 - 40, PW, 80, 36, "This player has no golems for sale", WHITE, 4, { ZIndex = 8, Visible = false })
local buyBar = frame(pSeller, 0, PH - 70, PW, 68, nil, { BackgroundTransparency = 1, ZIndex = 6, Visible = false })
local buyText = fit(label(buyBar, 10, 0, PW - 290, 68, 34, "", WHITE, 4.5, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7, RichText = true }), 34)
local buyBtn = makeButton(buyBar, PW - 260, 4, 240, 62, { shadowDy = 5, color = "green", text = "BUY", textSize = 36, z = 7 })
local sellerP: Player? = nil
local buyPick: number? = nil
local renderSeller

-- ===== сторінка 5: сервери маркету (кнопка з монітором; Remotes/MarketServers) =====
local pSrv = page("Servers")
local srvScroll = scroll(pSrv, 0, 36, PW, PH - 36, nil, nil, 12) -- відступ від заголовка SERVERS
local srvInfo = label(pSrv, 0, PH / 2 - 30, PW, 60, 32, "Loading...", WHITE, 4, { ZIndex = 8 })
local renderServers
local srvBusy, srvJoining = false, false
local function srvCall(a, k)
	local r = RS:FindFirstChild("Remotes")
	local rf = r and r:FindFirstChild("MarketServers")
	if not rf then return nil end
	local ok, res = pcall(rf.InvokeServer, rf, a, k)
	return ok and res or nil
end
function renderServers(silent: boolean?)
	if srvBusy or srvJoining then return end
	srvBusy = true
	if not silent then clear(srvScroll); srvInfo.Visible = true; srvInfo.Text = "Loading..." end
	local res = srvCall("List")
	if res and res.err == "busy" then -- ліміт 1 запит/с на сервері: повторити трохи пізніше, а не показувати «No servers»
		task.wait(1.1)
		res = srvCall("List")
		if res and res.err then res = nil end
	end
	srvBusy = false
	if silent and not res then return end -- тихе оновлення не зтирає список при помилці
	clear(srvScroll)
	local list = res and res.servers or {}
	srvInfo.Visible = #list == 0
	srvInfo.Text = res and "No servers found" or "Try again in a moment"
	for i, s in list do
		local row = frame(srvScroll, 0, 0, PW - 40, 96, C("5a6068"), { LayoutOrder = s.current and 0 or i, ZIndex = 5 })
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.1) }, row)
		stroke(row, s.current and C("7ef05a") or INK, s.current and 4 or 3)
		-- моніторчик
		if SERVERS_ICON ~= "" then
			new("ImageLabel", { BackgroundTransparency = 1, Image = SERVERS_ICON, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(16, 8),
				Size = UDim2.fromOffset(80, 80), ZIndex = 6 }, row)
		else
			monitorIcon(row, 16, 8, 80, 6)
		end
		fit(label(row, 110, 8, 420, 44, 36, "Server " .. i .. (s.current and "  (you are here)" or ""), s.current and C("b6ff5c") or WHITE, 4,
			{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }), 36)
		-- заповненість
		local k = math.clamp((tonumber(s.n) or 0) / math.max(1, tonumber(s.max) or 60), 0, 1)
		local bar = frame(row, 110, 58, 340, 22, INK, { ZIndex = 6 })
		local fill = frame(bar, 3, 3, math.floor(334 * k), 16, k < 0.75 and C("7ef05a") or (k < 1 and C("ffd23a") or C("ff5c6e")), { ZIndex = 7 })
		fit(label(row, 462, 52, 220, 34, 28, (s.n or 0) .. " / " .. (s.max or 60) .. " players", WHITE, 3.5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }), 28)
		if not s.current then
			local full = (tonumber(s.n) or 0) >= (tonumber(s.max) or 60)
			local jb = makeButton(row, PW - 40 - 230, 17, 210, 62, { shadowDy = 5, color = full and "gray" or "green", text = full and "FULL" or "JOIN", textSize = 32, z = 7 })
			jb.onClick = function()
				if full then StyleA.shake(jb); return end
				jb.enabled = false; srvJoining = true
				local r = srvCall("Join", s.key)
				if r and r.ok then toast("Teleporting...", "green", "claim"); task.delay(10, function() srvJoining = false end)
				else
					srvJoining = false; jb.enabled = true; StyleA.shake(jb)
					toast(r and r.err == "full" and "This server is full!" or "Can't join this server", "red", "deny")
					task.delay(0.5, renderServers)
				end
			end
		end
	end
end
-- список серверів сам оновлюється кожні 5 с, поки відкрита сторінка Servers (без кнопки REFRESH)
task.spawn(function()
	while true do
		task.wait(5)
		if modalRoot.Visible and pSrv.Visible then pcall(renderServers, true) end
	end
end)

-- ===== рендер =====
local curPage = "Listed"
local renderListed, renderSell, renderHist
function renderListed()
	clear(listedScroll)
	local lots = decode("MktLots", {})
	local max = HubCfg.marketSlots(player)
	counter.Text = Loc.f("Listed {1}/{2}", #lots, max)
	-- CREATE
	local cc = frame(listedScroll, 0, 0, 190, 236, nil, { BackgroundTransparency = 1, LayoutOrder = 0, ZIndex = 5 })
	local cb = makeButton(cc, 0, 0, 190, 190, { shadowDy = 6, color = "green", z = 5 })
	-- написи лише в межах грані кнопки (y ≈ 13…150), не на губі; обводка «+» тонка
	label(cb.root, 0, 16, 190, 80, 96, "+", C("2fc21c"), 3, { ZIndex = 9 })
	label(cb.root, 0, 98, 190, 44, 34, "CREATE", WHITE, 3.5, { ZIndex = 9 })
	cb.onClick = function()
		if #decode("MktLots", {}) >= HubCfg.marketSlots(player) then StyleA.shake(cb); toast("No free slots!", "red", "deny"); return end
		curPage = "Sell"; pickId = nil; renderSell()
	end
	for i, l in lots do
		local g = golemById(l.id)
		if g then
			local def = Catalog.get(g.kind)
			local mut = Catalog.mut(g.mut)
			local cell, btn, tile = golemTile(listedScroll, 190, 190, g.kind, g.cls, mut, nil, nil, i)
			cell.Size = UDim2.fromOffset(190, 236)
			local mt = fit(label(tile, 4, 4, 182, 30, 26, mutName(mut), WHITE, 3.5, { ZIndex = 8 }), 26)
			pcall(MutationText.apply, mt, mut)
			-- ціна під плиткою
			local chip = frame(cell, 8, 196, 174, 40, C(CUR_COL[l.c] or "ffffff"), { ZIndex = 6 })
			stroke(chip, INK, 3)
			vgrad(chip, { { 0, C(CUR_COL[l.c] or "ffffff"):Lerp(WHITE, 0.25) }, { 1, C(CUR_COL[l.c] or "ffffff"):Lerp(BLACK, 0.2) } })
			new("ImageLabel", { BackgroundTransparency = 1, Image = ICON[l.c] or "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(4, 4),
				Size = UDim2.fromOffset(32, 32), ZIndex = 7 }, chip)
			fit(label(chip, 38, 2, 132, 36, 26, l.c == "money" and NF.money(l.p) or NF.short(l.p), WHITE, 3.5, { ZIndex = 7 }), 26)
			if selected[l.id] then
				pickRing(tile)
				label(tile, 140, 0, 50, 50, 44, "✓", C("7ef05a"), 4, { ZIndex = 9 })
			end
			btn.MouseButton1Click:Connect(function()
				selected[l.id] = (not selected[l.id]) or nil
				StyleA.tap()
				renderListed()
			end)
		end
	end
	-- вільні слоти
	for i = #lots + 1, max do
		local e = frame(listedScroll, 0, 0, 190, 190, INK, { BackgroundTransparency = 0.75, LayoutOrder = 100 + i, ZIndex = 5 })
		stroke(e, INK, 3, 0.3)
		label(e, 0, 0, 190, 190, 26, "EMPTY", C("e9edf1"), 3, { ZIndex = 6 })
	end
	-- закриті: VIP +2, покупка +3
	local function locked(order, text, icon, color, onClick)
		local cell = frame(listedScroll, 0, 0, 190, 236, nil, { BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 5 })
		local b = makeButton(cell, 0, 0, 190, 190, { shadowDy = 6, color = color, z = 5, half = true })
		if icon then
			new("ImageLabel", { BackgroundTransparency = 1, Image = icon, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(45, 18),
				Size = UDim2.fromOffset(100, 90), ZIndex = 9 }, b.root)
		else
			label(b.root, 0, 14, 190, 70, 90, "+", WHITE, 3, { ZIndex = 9 })
		end
		fit(label(b.root, 12, 86, 166, 58, 28, text, WHITE, 3.5, { ZIndex = 9 }), 28)
		b.onClick = onClick
	end
	-- одна плитка «+3 SLOTS · R$ 79» (VIP +2 тут не показуємо — це в SHOP лобі)
	if player:GetAttribute("Pass_MarketSlots") ~= true then
		local d = MonCfg.Products.MarketSlots
		do
			locked(300, "+3 SLOTS\nR$ " .. (d and d.robux or 79), nil, "purple", function()
				if not d or (d.id or 0) == 0 then toast("Coming soon!", "yellow", "deny"); return end
				local r = RS:FindFirstChild("Remotes")
				local rf = r and r:FindFirstChild("GiftAction")
				if rf then pcall(rf.InvokeServer, rf, "Clear") end
				pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, d.id)
			end)
		end
	end
	-- вибрані
	local n = 0
	for id in selected do
		local still = false
		for _, l in lots do if l.id == id then still = true end end
		if still then n += 1 else selected[id] = nil end
	end
	selBar.Visible = n > 0
	selText.Text = n .. " Listed Golem" .. (n == 1 and "" or "s") .. " selected"
end
delBtn.onClick = function()
	local ids = {}
	for id in selected do table.insert(ids, id) end
	if #ids == 0 then return end
	table.clear(selected)
	action("Unlist", { ids = ids })
	task.delay(0.2, function() if curPage == "Listed" then renderListed() end end)
end

local function updateGet()
	local p = parsePrice(priceBox.Text)
	if p and p < (MIN_PRICE[curSel] or 1) then
		rGet.Text = "<font color=\"#ff6a6a\">Min price: " .. priceText(MIN_PRICE[curSel], curSel) .. "</font>"
	elseif p then
		rGet.Text = "Price: <font color=\"#" .. CUR_COL[curSel] .. "\">" .. priceText(p, curSel) .. "</font>"
	elseif priceBox.Text == "" then
		rGet.Text = "Min price: " .. priceText(MIN_PRICE[curSel] or 1, curSel)
	else
		rGet.Text = priceBox.Text ~= "" and "<font color=\"#ff6a6a\">Invalid price</font>" or ""
	end
end
local function setCur(k)
	curSel = k
	for kk, b in curBtns do b:setColor(kk == k and (k == "money" and "green" or k == "diamonds" and "blue" or "orange") or "gray") end
	updateGet()
end
for k, b in curBtns do b.onClick = function() setCur(k) end end
priceBox:GetPropertyChangedSignal("Text"):Connect(updateGet)

-- 06.11.2026: вибір голема без перебудови сітки (раніше клік → renderSell/renderSeller → усі клітинки заново, фон рідкості «мерехтів»):
--   пам'ятаємо клітинки та їхню обводку, по кліку лише перекидаємо рамку й оновлюємо панель справа / рядок покупки
local PK = { sell = {}, seller = {} } -- [сторінка][id] = { tile, c, th, tr, data }
function PK.remember(map, id, tile, data)
	local st = tile:FindFirstChildOfClass("UIStroke")
	map[id] = { tile = tile, data = data, c = st and st.Color, th = st and st.Thickness, tr = st and st.Transparency, had = st ~= nil }
end
function PK.swap(map, oldId, newId)
	local o = oldId ~= nil and map[oldId] or nil
	if o and o.tile.Parent then
		local st = o.tile:FindFirstChildOfClass("UIStroke")
		if st then
			if o.had then st.Color, st.Thickness, st.Transparency = o.c, o.th, o.tr else st:Destroy() end
		end
	end
	local n = newId ~= nil and map[newId] or nil
	if n and n.tile.Parent then pickRing(n.tile) end
end
function PK.showSell(pick)
	right.Visible = pick ~= nil
	if pick then
		rRar.Text = pick.def.rarity or ""
		rRar.TextColor3 = Catalog.rarityColor(pick.def.rarity)
		-- 04.11.2026: точний множник (NF.short округлював 1.25 → «x1»): 1.25 / 1.5 / 2 / 3 / 5 / 10 / 25
		local mm = Catalog.mult(pick.mut)
		rMut.Text = mutName(pick.mut) .. " [x" .. (string.format("%.2f", mm):gsub("0+$", ""):gsub("%.$", "")) .. "]"
		pcall(MutationText.apply, rMut, pick.mut)
		pcall(ItemViewport.set, rImg, ItemViewport.golemKey(pick.def.id, pick.cls), 1)
		rName.Text = pick.def.name
		rPow.Text = Catalog.bestText(pick.def.id, pick.cls) or Catalog.statText(pick.def.id, pick.cls, pick.mut)
	end
	updateGet()
end
function renderSell()
	clear(sellScroll)
	table.clear(PK.sell)
	local list = golems()
	local lots = decode("MktLots", {})
	counter.Text = Loc.f("Listed {1}/{2}", #lots, HubCfg.marketSlots(player))
	if pickId then
		local still = false
		for _, g in list do if g.id == pickId then still = true end end
		if not still then pickId = nil end
	end
	if not pickId and list[1] then pickId = list[1].id end
	local pick
	for i, g in list do
		local st = Catalog.bestText(g.def.id, g.cls) or Catalog.statText(g.def.id, g.cls, g.mut) -- ексклюзив: «65% BEST» (сила залежить від власника)
		local cell, btn, tile = golemTile(sellScroll, SC, SC, g.def.id, g.cls, g.mut, (string.split(st, " · ")[1] or st), nil, i)
		if g.mut > 0 then
			local mt = fit(label(tile, 4, 4, SC - 8, 26, 22, mutName(g.mut), WHITE, 3, { ZIndex = 8 }), 22)
			pcall(MutationText.apply, mt, g.mut)
		end
		PK.remember(PK.sell, g.id, tile, g)
		if g.id == pickId then pick = g; pickRing(tile) end
		btn.MouseButton1Click:Connect(function()
			if pickId == g.id then return end
			StyleA.tap()
			PK.swap(PK.sell, pickId, g.id)
			pickId = g.id
			PK.showSell(g)
		end)
	end
	sellEmpty.Visible = #list == 0 -- по центру сторінки (не в клітинці сітки)
	PK.showSell(pick)
end
sellBtn.onClick = function()
	if not pickId then StyleA.shake(sellBtn); return end
	local p = parsePrice(priceBox.Text)
	if not p then StyleA.shake(sellBtn); toast("Enter a price", "red", "deny"); return end
	if p < (MIN_PRICE[curSel] or 1) then StyleA.shake(sellBtn); toast("Min price: " .. priceText(MIN_PRICE[curSel], curSel), "red", "deny"); return end
	sellBtn.enabled = false
	local res = action("List", { id = pickId, price = p, cur = curSel })
	sellBtn.enabled = true
	if res and res.ok then
		toast("Golem listed for " .. priceText(p, curSel) .. "!", "green", "claim")
		priceBox.Text = ""
		pickId = nil
		curPage = "Listed"
		task.delay(0.15, function() renderListed() end)
	else
		local err = res and res.err
		StyleA.shake(sellBtn)
		toast(err == "full" and "No free slots!" or err == "price" and "Invalid price" or err == "min" and ("Min price: " .. priceText(MIN_PRICE[curSel] or 1, curSel)) or err == "blocked" and "This golem can't be sold" or err == "region" and "Trading is not available in your region" or "Can't list this golem", "red", "deny")
	end
end

local function histCard(e, kind, order)
	local def = e.k and Catalog.get(e.k)
	local mut = tonumber(e.m) or 0
	local cls = Catalog.cls(e.c)
	local card = frame(histScroll, 0, 0, PW - 40, 170, C("5a6068"), { LayoutOrder = order, ZIndex = 5 })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.1) }, card)
	stroke(card, INK, 3)
	local cur = CUR_COL[e.cur] and e.cur or "money"
	local head = (kind == "b" and "Bought from @" or "Sold to @") .. tostring(e.n or "?") .. " for " .. priceText(tonumber(e.p) or 0, cur)
	fit(label(card, 20, 6, PW - 200, 48, 40, head, C(CUR_COL[cur]), 5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }), 40)
	local img = new("ImageLabel", { BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(40, 52),
		Size = UDim2.fromOffset(170, 112), ZIndex = 7 }, card)
	if def then pcall(ItemViewport.set, img, ItemViewport.golemKey(def.id, cls), 1) end
	fit(label(card, 250, 54, PW - 520, 44, 40, def and def.name or "Golem", WHITE, 5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }), 40)
	fit(label(card, 250, 98, PW - 520, 30, 26, (def and def.rarity or "?") .. " · " .. cls:sub(1, 1):upper() .. cls:sub(2), def and Catalog.rarityColor(def.rarity) or WHITE, 3.5,
		{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }), 26)
	local mt = fit(label(card, 250, 128, PW - 520, 30, 26, mutName(mut) .. " [x" .. (string.format("%.2f", Catalog.mult(mut)):gsub("0+$", ""):gsub("%.$", "")) .. "]", WHITE, 3.5,
		{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }), 26)
	pcall(MutationText.apply, mt, mut)
	label(card, PW - 280, 124, 230, 36, 30, ago(e.t), C("ffb21f"), 4, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })
end
function renderHist()
	clear(histScroll)
	counter.Text = ""
	tabB:setColor(hTab == "b" and "green" or "gray")
	tabS:setColor(hTab == "s" and "red" or "gray")
	local h = decode("MktHistory", { b = {}, s = {} })
	local list = h[hTab] or {}
	for i, e in list do if type(e) == "table" then histCard(e, hTab, i) end end
	histEmpty.Visible = #list == 0
	histEmpty.Text = hTab == "b" and "You haven't bought anything yet" or "You haven't sold anything yet"
end
tabB.onClick = function() hTab = "b"; renderHist() end
tabS.onClick = function() hTab = "s"; renderHist() end

local function sellerLots(p: Player): ({ any }, { [number]: any })
	local function dec(a)
		local s = p:GetAttribute(a)
		local ok, v = pcall(HttpService.JSONDecode, HttpService, type(s) == "string" and s ~= "" and s or "[]")
		return (ok and type(v) == "table") and v or {}
	end
	local inv = {}
	for _, g in dec("InvGolems") do if type(g) == "table" then inv[g.id] = g end end
	local out = {}
	for _, l in dec("MktLots") do if type(l) == "table" and inv[l.id] then table.insert(out, l) end end
	return out, inv
end
-- 06.11.2026: голем з мапи, яку покупець ще не відкрив (GolemCatalog map > атрибут Stage; ексклюзиви — без обмеження),
--   купити не можна: на слоті в меню продавця — затемнення й «Unlocks on Map N», кнопка BUY сіра. Над големами у світі — нічого.
--   Сервер (MarketLotService.doBuy) перевіряє те саме (err = "map").
function PK.mapLock(kind): number?
	local def = Catalog.get(kind)
	local st = tonumber(player:GetAttribute("Stage"))
	if not (def and st) or def.rarity == "Exclusive" then return nil end
	local m = tonumber(def.map) or 1
	return m > st and m or nil
end
function renderSeller()
	clear(sellerScroll)
	table.clear(PK.seller)
	counter.Text = ""
	if not (sellerP and sellerP.Parent) then sellerEmpty.Visible = true; buyBar.Visible = false; return end
	setTitle(string.upper(sellerP.DisplayName) .. "'S GOLEMS")
	local lots, inv = sellerLots(sellerP)
	local pickLot
	for i, l in lots do
		local g = inv[l.id]
		local mut = Catalog.mut(g.mut)
		local cls = Catalog.cls(g.cls)
		local st = Catalog.bestText(g.kind, cls) or Catalog.statText(g.kind, cls, mut)
		local cell, btn, tile = golemTile(sellerScroll, 190, 190, g.kind, cls, mut, (string.split(st, " · ")[1] or st), nil, i)
		cell.Size = UDim2.fromOffset(190, 236)
		local mt = fit(label(tile, 4, 4, 182, 30, 26, mutName(mut), WHITE, 3.5, { ZIndex = 8 }), 26)
		pcall(MutationText.apply, mt, mut)
		local chip = frame(cell, 8, 196, 174, 40, C(CUR_COL[l.c] or "ffffff"), { ZIndex = 6 })
		stroke(chip, INK, 3)
		vgrad(chip, { { 0, C(CUR_COL[l.c] or "ffffff"):Lerp(WHITE, 0.25) }, { 1, C(CUR_COL[l.c] or "ffffff"):Lerp(BLACK, 0.2) } })
		new("ImageLabel", { BackgroundTransparency = 1, Image = ICON[l.c] or "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(4, 4),
			Size = UDim2.fromOffset(32, 32), ZIndex = 7 }, chip)
		fit(label(chip, 38, 2, 132, 36, 26, l.c == "money" and NF.money(l.p) or NF.short(l.p), WHITE, 3.5, { ZIndex = 7 }), 26)
		local lk = PK.mapLock(g.kind)
		if lk then
			local veil = frame(tile, 0, 0, 190, 190, BLACK, { BackgroundTransparency = 0.35, ZIndex = 8 })
			fit(label(veil, 6, 62, 178, 34, 30, "MAP " .. lk, C("ffd23a"), 3.5, { ZIndex = 9, AutoLocalize = false }), 30)
			fit(label(veil, 6, 98, 178, 30, 22, Loc.f("Unlocks on Map {number1}", lk), WHITE, 3, { ZIndex = 9, AutoLocalize = false, TextWrapped = true }), 22)
		end
		PK.remember(PK.seller, l.id, tile, { l = l, g = g })
		if buyPick == l.id then pickLot = { l = l, g = g }; pickRing(tile) end
		btn.MouseButton1Click:Connect(function()
			if buyPick == l.id then return end
			StyleA.tap()
			PK.swap(PK.seller, buyPick, l.id)
			buyPick = l.id
			PK.showBuy({ l = l, g = g })
		end)
	end
	sellerEmpty.Visible = #lots == 0
	PK.showBuy(pickLot)
end
function PK.showBuy(pickLot)
	buyBar.Visible = pickLot ~= nil
	if pickLot then
		local def = Catalog.get(pickLot.g.kind)
		local mut = Catalog.mut(pickLot.g.mut)
		local nm = (mut > 0 and (mutName(mut) .. " ") or "") .. (def and def.name or "Golem")
		buyText.Text = "Buy " .. nm .. " for <font color=\"#" .. (CUR_COL[pickLot.l.c] or "ffffff") .. "\">" .. priceText(pickLot.l.p, pickLot.l.c) .. "</font>?"
		buyBtn.pick = pickLot.l
		buyBtn.locked = PK.mapLock(pickLot.g.kind)
		if buyBtn.locked then buyText.Text = "<font color=\"#ffd23a\">" .. Loc.f("Unlocks on Map {number1}", buyBtn.locked) .. "</font>" end
		buyBtn:setColor(buyBtn.locked and "gray" or "green")
	else
		buyPick = nil
	end
end
buyBtn.onClick = function()
	local l = buyBtn.pick
	if not (l and sellerP) then return end
	if buyBtn.locked then StyleA.shake(buyBtn); toast(Loc.f("Unlocks on Map {number1}", buyBtn.locked), "red", "deny"); return end
	if (tonumber(player:GetAttribute(({ money = "Money", diamonds = "Diamonds", tickets = "Tickets" })[l.c])) or 0) < l.p then
		StyleA.shake(buyBtn); toast("Not enough " .. (CUR_NAME[l.c] or "") .. "!", "red", "deny"); return
	end
	buyBtn.enabled = false
	local res = action("Buy", { seller = sellerP.UserId, id = l.id, p = l.p, c = l.c })
	buyBtn.enabled = true
	if res and res.ok then
		toast("Golem bought!", "green", "purchase")
		buyPick = nil
		task.delay(0.2, function() if curPage == "Seller" then renderSeller() end end)
	else
		local e = res and res.err
		StyleA.shake(buyBtn)
		toast(e == "map" and Loc.f("Unlocks on Map {number1}", res.map or 2) or e == "full" and "Your inventory is full!" or e == "changed" and "The price has changed!" or (e == "money" or e == "diamonds" or e == "tickets") and ("Not enough " .. CUR_NAME[e] .. "!")
			or e == "busy" and "Try again" or e == "region" and "Trading is not available in your region" or "This golem is no longer for sale", "red", "deny")
		renderSeller()
	end
end

local function render()
	for n, f in pages do f.Visible = n == curPage end
	backBtn:show(curPage == "Sell")
	warn1.Visible = curPage == "Sell"
	counter.Position = UDim2.fromOffset(WIN_X + WIN_W - (curPage == "Sell" and 760 or 560), 22)
	if curPage == "Listed" then setTitle("MY LISTED GOLEMS"); renderListed()
	elseif curPage == "Sell" then setTitle("LIST GOLEMS"); renderSell()
	elseif curPage == "Seller" then renderSeller()
	elseif curPage == "Servers" then setTitle("SERVERS"); counter.Text = ""; task.spawn(renderServers)
	else setTitle("HISTORY"); renderHist() end
end
-- рендер сторінки після зміни — через render (щоб видимість сторінок оновилась)
local _rl, _rs = renderListed, renderSell
renderListed = function() if curPage == "Listed" then for n, f in pages do f.Visible = n == "Listed" end; backBtn:show(false); warn1.Visible = false; counter.Position = UDim2.fromOffset(WIN_X + WIN_W - 560, 22); setTitle("MY LISTED GOLEMS"); _rl() else render() end end
renderSell = function() if curPage == "Sell" then for n, f in pages do f.Visible = n == "Sell" end; backBtn:show(true); warn1.Visible = true; counter.Position = UDim2.fromOffset(WIN_X + WIN_W - 760, 22); setTitle("LIST GOLEMS"); _rs() else render() end end
backBtn.onClick = function() curPage = "Listed"; render() end
setCur("tickets")

-- ===== масштаб, відкриття / закриття =====
local function fitWin() WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WIN_X, winY = WIN_Y, winW = WIN_W, winH = WIN_H + 70 }) end
local camConn
local function bindCamera()
	if camConn then camConn:Disconnect(); camConn = nil end
	local cam = workspace.CurrentCamera
	if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitWin) end
	fitWin()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fitWin) end)
bindCamera()

local isOpen, animToken = false, 0
local function open(pg: string)
	curPage = pg
	render()
	if isOpen then return end
	isOpen = true
	WindowManager.opened("Market")
	animToken += 1
	local my = animToken
	fitWin()
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
end
local function close()
	if not isOpen then return end
	isOpen = false
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
	end)
end
closeBtn.onClick = function() close() end
backdrop.MouseButton1Click:Connect(close)
WindowManager.register("Market", function() return isOpen end, close)
CAS:BindActionAtPriority("MarketEsc", function(_, state)
	if state == Enum.UserInputState.Begin and isOpen then close(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
for _, a in { "MktLots", "MktHistory", "InvGolems", "PlotPlaced", "Pass_VIP", "Pass_MarketSlots" } do
	player:GetAttributeChangedSignal(a):Connect(function()
		if not isOpen then return end
		if curPage == "Sell" and (a == "InvGolems" or a == "MktLots") then return end -- не збивати вибір під час вводу ціни
		render()
	end)
end

-- ===== кнопки внизу по центру: SELL GOLEMS · HISTORY =====
local hud = new("ScreenGui", { Name = "MarketHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4 }, playerGui)
local BW1, BW2, BH, GAP = 300, 240, 76, 22
local row = new("Frame", { Name = "Row", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(BW1 + GAP + BW2, BH + 6) }, hud)
local rowScale = new("UIScale", {}, row)
local bSell = makeButton(row, 0, 0, BW1, BH, { shadowDy = 6, color = "green", text = "Sell Golems", textSize = 36, z = 2 })
local bHist = makeButton(row, BW1 + GAP, 0, BW2, BH, { shadowDy = 6, color = "red", text = "History", textSize = 36, z = 2 })
bSell.onClick = function() if isOpen and curPage ~= "History" then close() else open("Listed") end end
bHist.onClick = function() if isOpen and curPage == "History" then close() else open("History") end end

-- ===== кнопка з монітором у правому нижньому куті: вибір сервера маркету =====
do
	local S = 96
	local holder = new("Frame", { Name = "ServersBtn", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -8),
		Size = UDim2.fromOffset(S, S + 16) }, hud)
	local sc = new("UIScale", {}, holder)
	local b = makeButton(holder, 0, 0, S, S, { shadowDy = 6, color = "blue", z = 2 })
	-- іконка — запечений PNG з нашого пака (SERVERS_ICON); поки ID нема — тимчасовий монітор з фреймів
	if SERVERS_ICON ~= "" then
		new("ImageLabel", { BackgroundTransparency = 1, Image = SERVERS_ICON, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(18, 9),
			Size = UDim2.fromOffset(60, 60), ZIndex = 9 }, b.root)
	else
		monitorIcon(b.root, 10, 6, 76, 9)
	end
	fit(label(holder, -10, S - 14, S + 20, 30, 24, "SERVERS", WHITE, 3.5, { ZIndex = 20 }), 24) -- надпис трохи налазить на низ кнопки
	b.onClick = function() if isOpen and curPage == "Servers" then close() else open("Servers") end end
	task.spawn(function()
		while holder.Parent do
			local cam = workspace.CurrentCamera
			sc.Scale = math.clamp((cam and cam.ViewportSize.X or 1280) / 1500, 0.55, 1)
			task.wait(1)
		end
	end)
end

-- ===== [E] біля продавця: стандартний ProximityPrompt на його HumanoidRootPart (лише коли є лоти) =====
local prompts: { [Player]: ProximityPrompt } = {}
local function syncPrompts()
	for _, p in Players:GetPlayers() do
		-- Studio: workspace.MktSelfTest = true — підказка й на собі (перевірка вікна одним гравцем)
		if p ~= player or (RunService:IsStudio() and workspace:GetAttribute("MktSelfTest") == true) then
			local ch = p.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local has = #sellerLots(p) > 0
			local pr = prompts[p]
			if pr and (not has or not hrp or pr.Parent ~= hrp) then pr:Destroy(); prompts[p] = nil; pr = nil end
			if has and hrp and not pr then
				pr = new("ProximityPrompt", { Name = "MarketLotsPrompt", ActionText = "View Golems", ObjectText = p.DisplayName,
					KeyboardKeyCode = Enum.KeyCode.E, HoldDuration = 0, MaxActivationDistance = 12, RequiresLineOfSight = false }, hrp)
				pr.Triggered:Connect(function()
					sellerP = p; buyPick = nil
					open("Seller")
				end)
				prompts[p] = pr
			end
		end
	end
	for p, pr in prompts do if not p.Parent then pr:Destroy(); prompts[p] = nil end end
end
task.spawn(function() while true do pcall(syncPrompts); task.wait(1) end end)
-- лоти продавця змінились (купили / зняв) — оновити сторінку
task.spawn(function()
	local last = ""
	while true do
		task.wait(0.5)
		if isOpen and curPage == "Seller" and sellerP then
			local k = tostring(sellerP:GetAttribute("MktLots"))
			if k ~= last then last = k; pcall(renderSeller) end
			if not sellerP.Parent then close() end
		else last = "" end
	end
end)
-- 04.11.2026: на маркеті хотбара немає (ховаємо Hotbar) — кнопки завжди внизу по центру; масштаб — під ширину екрана
task.spawn(function()
	while hud.Parent do
		local cam = workspace.CurrentCamera
		local vw = cam and cam.ViewportSize.X or 1280
		rowScale.Scale = math.clamp(vw / 1500, 0.55, 1)
		local hb = playerGui:FindFirstChild("Hotbar")
		if hb and hb:IsA("ScreenGui") and hb.Enabled then hb.Enabled = false end
		row.Position = UDim2.new(0.5, 0, 1, -16)
		task.wait(0.5)
	end
end)

-- ===== FOLLOWERS: големи-лоти ходять за власником =====
local folder = workspace:FindFirstChild("MarketLots") or new("Folder", { Name = "MarketLots" }, workspace)
local ROW_N, SPACE, BACK, LOT_SCALE = 4, 3.6, 4.5, 1 / 3 -- големи-лоти в 3 рази менші за префаб (03.11.2026) -- ряд за спиною, крок сітки, відстань до першого ряду, масштаб голема
local followers = {} -- [Player] = { [lotId] = { model, foot, key, pos } }
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function lotsOf(p: Player): { any }
	local s = p:GetAttribute("MktLots")
	if type(s) ~= "string" or s == "" then return {} end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return (ok and type(v) == "table") and v or {}
end
local function invOf(p: Player): { [number]: any }
	local s = p:GetAttribute("InvGolems")
	local ok, v = pcall(HttpService.JSONDecode, HttpService, type(s) == "string" and s or "[]")
	local t = {}
	if ok and type(v) == "table" then for _, g in v do if type(g) == "table" then t[g.id] = g end end end
	return t
end
local function makeSign(m: Model, def, lot, mut)
	local root = m:FindFirstChild("Root") or m.PrimaryPart
	if not root then return end
	-- 06.11.2026 v2: менше тексту — без назви голема й «Listed for:»; мутація (лише якщо є), сила, ціна з іконкою валюти
	--   (усі валюти скорочено: 477K, 3.2K, 1.5M).
	-- розмір у стадах (а не в пікселях): віддаляєш камеру — табличка зменшується разом з големом; далі 45 стадів — ховається
	local hasMut = Catalog.mut(mut) > 0
	local H = hasMut and 72 or 50
	local bb = new("BillboardGui", { Name = "LotSign", Size = UDim2.fromScale(4.4, 4.4 * H / 220), StudsOffsetWorldSpace = Vector3.new(0, GolemModel.headTop(m) + 0.4 + 2.2 * H / 220, 0),
		AlwaysOnTop = false, MaxDistance = 45, LightInfluence = 0 }, root)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, bb)
	new("UIAspectRatioConstraint", { AspectRatio = 220 / H }, holder)
	local function line(y, h, text, color, sw, props)
		local t = label(holder, 0, 0, 0, 0, 20, text, color, sw, props)
		t.Position = UDim2.fromScale(0, y / H); t.Size = UDim2.fromScale(1, h / H)
		t.TextScaled = true
		return t
	end
	local y = 0
	if hasMut then
		local mt = line(0, 20, mutName(mut), WHITE, 1.5, { ZIndex = 1 })
		pcall(MutationText.apply, mt, mut)
		y = 22
	end
	-- сила за класом: майнер / воїн — шкода (+HP), носій — місткість
	-- ексклюзив: «65% BEST» (його сила — частка найкращого голема власника, у кожного своя), 03.11.2026
	local best = Catalog.bestText(def.id, m:GetAttribute("Role"))
	local okS, st = pcall(Catalog.statText, def.id, m:GetAttribute("Role"), mut)
	local stat = best or (okS and st and (string.split(st, " · Speed")[1]) or "")
	line(y, 20, stat, best and Catalog.BEST_COLOR or C("b6ff5c"), 1.5, { ZIndex = 1 })
	-- ціна: іконка валюти + скорочене число, разом по центру (ширина тексту — за кількістю символів)
	-- скорочення для всіх валют: 477K, 3.2K, 1.5M, 2B (валюту показує іконка)
	local txt
	do
		local v = math.floor((tonumber(lot.p) or 0) + 0.5)
		txt = if v >= 1e15 then NF.short(v) else tostring(v) -- 06.11.2026: від Qa — суфікси NumberFormat (Qa, Qi … і 1.2e90)
		for _, u in (if v >= 1e15 then {} else { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
			if v >= u[1] then
				local x = v / u[1]
				txt = (x >= 100 and tostring(math.floor(x)) or (string.gsub(string.format("%.1f", x), "%.0$", ""))) .. u[2]
				break
			end
		end
	end
	local row = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0, (y + 22) / H), Size = UDim2.fromScale(1, 28 / H) }, holder)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local ic = new("ImageLabel", { LayoutOrder = 1, BackgroundTransparency = 1, Image = ICON[lot.c] or "", ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1, 1), ZIndex = 1 }, row)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ic)
	local pt = label(row, 0, 0, 0, 0, 24, txt, C(CUR_COL[lot.c] or "ffffff"), 2, { ZIndex = 1, LayoutOrder = 2, TextXAlignment = Enum.TextXAlignment.Left, AutoLocalize = false })
	pt.Size = UDim2.fromScale(math.clamp(0.075 * #txt + 0.04, 0.2, 0.8), 1)
	pt.TextScaled = true
end
local function sync()
	for _, p in Players:GetPlayers() do
		local want = {}
		local inv = invOf(p)
		local i = 0 -- безперервна нумерація, щоб ряд центрувався без дірок
		-- 06.11.2026: SETTINGS → HIDE GOLEMS — чужих големів-лотів не будуємо (лише в мене)
		local skip = p ~= player and player:GetAttribute("Set_HideGolems") == true
		for _, l in (skip and {} or lotsOf(p)) do
			local g = type(l) == "table" and inv[l.id]
			if g then i += 1; want[l.id] = { i = i, g = g, l = l } end
		end
		local mine = followers[p] or {}
		followers[p] = mine
		for id, f in mine do
			local w = want[id]
			local key = w and (w.g.kind .. ":" .. tostring(w.g.cls) .. ":" .. tostring(w.g.mut) .. ":" .. w.l.p .. ":" .. w.l.c)
			if not w or f.key ~= key then f.model:Destroy(); mine[id] = nil end
		end
		for id, w in want do
			if mine[id] then mine[id].i = w.i
			else
				local def = Catalog.get(w.g.kind)
				local m = def and GolemModel.build(def.id, w.g.cls)
				if m then
					local mut = Catalog.mut(w.g.mut)
					m.Name = "Lot_" .. p.UserId .. "_" .. id
					pcall(function() m:ScaleTo(m:GetScale() * LOT_SCALE) end)
					m:SetAttribute("State", "Auto")
					m.Parent = folder
					if okAura and mut > 0 then pcall(MutationAura.apply, m, mut, {}) end
					makeSign(m, def, w.l, mut)
					mine[id] = { model = m, foot = GolemModel.footOffset(m), i = w.i, pos = nil,
						key = w.g.kind .. ":" .. tostring(w.g.cls) .. ":" .. tostring(w.g.mut) .. ":" .. w.l.p .. ":" .. w.l.c }
				end
			end
		end
	end
	for p, mine in followers do
		if not p.Parent then for _, f in mine do f.model:Destroy() end; followers[p] = nil end
	end
end
task.spawn(function() while true do pcall(sync); task.wait(0.5) end end)
RunService.Heartbeat:Connect(function(dt)
	local k = 1 - math.exp(-dt * 6)
	for p, mine in followers do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			rayParams.FilterDescendantsInstances = { folder, ch }
			local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
			look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
			local rightV = Vector3.new(-look.Z, 0, look.X)
			local n = 0
			for _ in mine do n += 1 end
			for _, f in mine do
				local idx = f.i - 1
				local r, c = idx // ROW_N, idx % ROW_N
				local inRow = math.clamp(n - r * ROW_N, 1, ROW_N) -- ряд центрується за спиною за кількістю големів у ньому
				local target = hrp.Position - look * (BACK + r * SPACE) + rightV * ((c - (inRow - 1) / 2) * SPACE)
				f.pos = f.pos and f.pos:Lerp(target, k) or target
				local hit = workspace:Raycast(f.pos + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), rayParams)
				local y = hit and hit.Position.Y or (hrp.Position.Y - 3)
				local pos = Vector3.new(f.pos.X, y + f.foot, f.pos.Z)
				f.model:PivotTo(CFrame.lookAt(pos, pos + look))
			end
		end
	end
end)

-- ===== 06.11.2026: TRADE FEED — тонке напівпрозоре сповіщення вгорі по центру екрана, коли хтось у когось щось купив =====
-- Бачать усі гравці сервера. Джерело — атрибут Trades табла RECENT TRADES (MarketServerService.LogTrade, нові — на початку списку).
-- Одночасно до 3 рядків (новий зверху), кожен ~4,5 с, поява / зникнення плавні. Текст — Shared/Loc «{1} bought {2} from {3} for {4}».
do
	local FEED_MAX, FEED_LIFE = 3, 4.5
	local feedGui = new("ScreenGui", { Name = "TradeFeed", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
	local feedRoot = new("Frame", { Name = "Root", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.fromOffset(900, 140) }, feedGui)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }, feedRoot)
	local feedScale = new("UIScale", {}, feedRoot)
	local function fitFeed()
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
		feedScale.Scale = math.clamp(math.min(vs.Y / 720, vs.X / 960), 0.55, 1.4)
		feedRoot.Position = UDim2.new(0.5, 0, 0, math.floor(GuiService.TopbarInset.Max.Y + 18 * feedScale.Scale))
	end
	fitFeed()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitFeed) end
	local order = 0
	local rows = {}
	local function esc(s: string): string return (string.gsub(s, "[<>&]", { ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;" })) end
	local function show(e)
		local def = e.k and Catalog.get(e.k)
		local mut = tonumber(e.m) or 0
		local base = def and def.name or "Golem"
		local rc = def and Catalog.rarityColor(def.rarity) or Color3.new(1, 1, 1)
		local cur = CUR_COL[e.cur] and e.cur or "money"
		local price = cur == "money" and NF.money(e.p or 0) or (NF.short(e.p or 0) .. " " .. Loc.t(CUR_NAME[cur] or ""))
		-- 06.11.2026 v2: назва голема — окремими мітками: слово мутації переливається (MutationText), решта — кольором рідкості голема.
		--   Перекладена повна назва ділиться на перше слово (мутація) і решту: «Rainbow | Obsidian Golem», «Радужный | обсидиановый голем».
		local mutWord, nameRest = nil, Loc.t(base)
		if mut > 0 then
			local full = Loc.t(mutName(mut) .. " " .. base)
			mutWord, nameRest = string.match(full, "^(%S+)%s+(.+)$")
			if not mutWord then mutWord, nameRest = mutName(mut), Loc.t(base) end
		end
		local SEP = "\u{1}"
		local whole = Loc.f("{1} bought {2} from {3} for {4}",
			'<font color="#ffffff">' .. esc(tostring(e.bn or "?")) .. "</font>", SEP,
			'<font color="#ffffff">' .. esc(tostring(e.sn or "?")) .. "</font>",
			'<font color="#' .. (CUR_COL[cur] or "ffffff") .. '">' .. price .. "</font>")
		local left, right = string.match(whole, "^(.-)" .. SEP .. "(.*)$")
		if not left then left, right = whole, "" end
		order -= 1
		local pill = new("Frame", { Name = "Trade", BackgroundColor3 = C("0e1014"), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 34), LayoutOrder = order }, feedRoot)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
		new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, pill)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }, pill)
		local st = new("UIStroke", { Color = C("ffffff"), Transparency = 1, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pill)
		local labels, strokes = {}, {}
		local n = 0
		local function part(text: string, color: Color3?, rich: boolean): TextLabel?
			if text == "" then return nil end
			n += 1
			local l = new("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), FontFace = XBOLD,
				TextSize = 19, TextColor3 = color or C("d9dee5"), RichText = rich, AutoLocalize = false, Text = text, TextTransparency = 1, LayoutOrder = n }, pill)
			table.insert(labels, l)
			table.insert(strokes, new("UIStroke", { Color = INK, Thickness = 1.6, Transparency = 1 }, l))
			return l
		end
		-- проміжки між частинами — Padding списку (5 px), пробіли по краях обрізаємо
		part((string.gsub(left, "%s+$", "")), nil, true)
		if mutWord then
			local ml = part(mutWord, nil, false)
			if ml then pcall(MutationText.apply, ml, mut) end
		end
		part(nameRest, rc, false)
		part((string.gsub(right, "^%s+", "")), nil, true)
		table.insert(rows, 1, pill)
		while #rows > FEED_MAX do local old = table.remove(rows); old:Destroy() end
		local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(pill, ti, { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(st, ti, { Transparency = 0.85 }):Play()
		for _, l in labels do TweenService:Create(l, ti, { TextTransparency = 0 }):Play() end
		for _, s in strokes do TweenService:Create(s, ti, { Transparency = 0.3 }):Play() end
		task.delay(FEED_LIFE, function()
			if not pill.Parent then return end
			local to = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(pill, to, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(st, to, { Transparency = 1 }):Play()
			for _, s in strokes do TweenService:Create(s, to, { Transparency = 1 }):Play() end
			local tw
			for _, l in labels do tw = TweenService:Create(l, to, { TextTransparency = 1 }); tw:Play() end
			task.delay(0.45, function()
				local i = table.find(rows, pill)
				if i then table.remove(rows, i) end
				pill:Destroy()
			end)
		end)
	end
	-- нові угоди = записи перед попереднім першим (ключ: час, продавець, покупець, ціна)
	local function keyOf(e) return tostring(e.t) .. ":" .. tostring(e.s) .. ":" .. tostring(e.b) .. ":" .. tostring(e.p) end
	local lastKey: string? = nil
	local board: Instance? = nil
	local function read(): { any }
		local raw = board and board:GetAttribute("Trades")
		local ok, data = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
		return (ok and type(data) == "table") and data or {}
	end
	local function onTrades(init: boolean?)
		local data = read()
		local first = data[1]
		if init then lastKey = first and keyOf(first) or ""; return end -- перший прохід: старі угоди не показуємо
		if not first then return end
		local fresh = {}
		for _, e in data do
			if keyOf(e) == lastKey then break end
			table.insert(fresh, e)
			if #fresh >= FEED_MAX then break end
		end
		lastKey = keyOf(first)
		for i = #fresh, 1, -1 do pcall(show, fresh[i]) end -- найстаріша з нових першою, найновіша — зверху
	end
	task.spawn(function()
		while not board do
			board = HubCfg.tradesBoard and HubCfg.tradesBoard()
			if not board then task.wait(2) end
		end
		local b = board :: Instance
		b:GetAttributeChangedSignal("Trades"):Connect(function() onTrades() end)
		onTrades(true)
	end)
end
