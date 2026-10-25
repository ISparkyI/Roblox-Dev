-- InventoryUI — інвентар гравця: хотбар унизу (9 слотів «C · Сяйво») і вікно INVENTORY (кнопка рюкзака в HUD або клавіша B).
-- Де: StarterPlayer/StarterPlayerScripts/InventoryUI (LocalScript). Інтерфейс будується кодом (ScreenGui Hotbar і InventoryWindow).
-- Макет: 2D/Inventory (веб-макет v3, затверджений). Стиль — як вікна Forge / Sell (studs, «стиль A», квадратне).
--
-- Хотбар: показує ЛИШЕ зайняті слоти, по центру, нумерація 1..n без пропусків. Слот з'являється, коли предмет беруть у руку
--   (Hold у вікні), і зникає, коли його прибирають з рук (та сама цифра / клік ще раз, Put Away, Unpin) — решта зсуваються.
--   Предмет при цьому лишається в інвентарі. 1–n або клік — перемкнути предмет у руці (лаймова рамка, слот піднімається,
--   над хотбаром «Coal ×25 · in hand»). Перемкнувся на інший — попередній слот лишається.
--   Стандартний рюкзак Roblox вимкнено (StarterGui Backpack).
-- Вікно: вкладки Golems / Ores·Bars / Potions (власні іконки), сітка слотів 5 у ряд (гортається колесом, перетягуванням і повзунком),
--   клік по предмету — картка внизу (Hold / Put Away, Hotbar / Unpin). Внизу ліворуч: червона кнопка з кошиком — режим видалення,
--   жовта із замком — режим блокування. У режимі інші вкладки ховаються, з'являються Select All (на все — Deselect All) і
--   Delete (N) → вікно підтвердження / Lock (N) або Unlock (N). Заблоковане не видаляється (притемнене, «LOCKED»), але його можна
--   брати в руку. Cancel або Esc — вихід з режиму.
-- Наведення на слот: ×1,025 і нахил до 1,5° (нахиляється лише картка слота), натискання 0,96. Звук наведення слота —
--   SoundService/SlotHover (порожній SoundId — тиша; спільний з вікном Sell).
-- Дані: атрибути гравця Ore_*, Bars_*, Pot_*, InvGolems, InvLocks, InvHotbar, InvHeld (ставить сервер InventoryService);
--   дії — Remotes/InventoryAction ("Delete", "Lock", "Hotbar", "Hold"). Предмети — Shared/ItemConfig.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local CAS = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local Forge = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local ItemVP = require(RS.Shared:WaitForChild("ItemViewport")) -- 3D-моделі руди й злитків у слотах замість PNG
local Action = RS:WaitForChild("Remotes"):WaitForChild("InventoryAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- стандартний рюкзак Roblox — вимкнено (свій хотбар)
task.spawn(function()
	for _ = 1, 20 do
		if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) then break end
		task.wait(0.5)
	end
end)

local ICON_ORE = { Coal = StyleA.ASSETS.forge_ore_coal_v2, Copper = StyleA.ASSETS.forge_ore_copper_v2, Iron = StyleA.ASSETS.forge_ore_iron_v2 }
local ICON_BAR = { Coal = "rbxassetid://101473380326305", Copper = "rbxassetid://106483042191242", Iron = StyleA.ASSETS.forge_bar_iron_v2 }

-- ===== константи макета (одиниці дизайну) =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528 -- вікно
local TX, TW, TH = 40, 222, 92          -- вкладки
local GX, GY, GW, GH = 288, 106, 636, 278 -- сітка
local GS, GG, GCOLS, GP = 102, 24, 5, 12
local HS, HG = 74, 8                    -- хотбар
local HB_W = Items.HOTBAR * HS + (Items.HOTBAR - 1) * HG
local GLOW_N = 16

-- ===== кольори =====
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local LIME = { { 0, "eaff9a" }, { 0.5, "c3f04a" }, { 1, "8ccc22" } }
local TRACK = { { 0, "1a1d22" }, { 1, "353b44" } }
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }

-- ===== помічники (як у ForgeWindow) =====
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
-- текст за «центром великих літер» cy: бокс 1,2 × розміру з центром у cy
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

-- квадратне вікно зі studs (як Forge): тінь, темний обідок, світла лінія, панель зі studs і затіненням. Повертає (window, вміст)
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

-- кнопка «стиль A» + квадратна тінь. opt: shadowDy, color, text, textSize, icon, iconPad, z, noSound.
-- b.onClick(b); b.base — колір, коли кнопка доступна; b:enable(on) — сіра й хитається, коли недоступна.
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, shine = opt.shine, zIndex = opt.z + 1 })
	b.shadow = sh
	b.base = opt.color
	b.onClick = nil
	if opt.noSound then b.root:SetAttribute("NoHoverSound", true) end
	if not opt.manual then
		StyleA.bind(b, { debounce = opt.debounce or 0.15, onClick = function() if b.onClick then b.onClick(b) end end })
	end
	function b.enable(self, on: boolean)
		self.enabled = on
		self:setColor(on and self.base or "gray")
	end
	function b.recolor(self, color: string)
		self.base = color
		if self.enabled then self:setColor(color) end
	end
	return b
end


local function tableFind(t, v) for i, x in t do if x == v then return i end end return nil end

-- сяйво: прозорість i-го з GLOW_N вкладених кіл, щоб непрозорість на відстані d була A · (1 − d / R)^P
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

local function slotHoverSound()
	local s = SoundService:FindFirstChild("SlotHover")
	if s and s:IsA("Sound") and s.SoundId ~= "" then s.TimePosition = 0; s:Play() end
end

-- лаймова / червона / жовта галочка в колі: темне коло 30, кольоровий круг 24 з бліком, темна «пташка» з круглими кінцями.
-- Без UIStroke (обвідка UIStroke у слоті давала чорний квадрат під кружком). Колір круга — check.Fill.BackgroundColor3.
local function makeCheck(parent, x, y, color)
	local ring = frame(parent, x - 1, y - 1, 30, 30, INK, { Name = "Check", ZIndex = 20, Visible = false }); corner(ring, UDim.new(0.5, 0))
	local fill = frame(ring, 3, 3, 24, 24, color, { Name = "Fill", ZIndex = 21 }); corner(fill, UDim.new(0.5, 0))
	local gl = frame(fill, 5, 2, 14, 7, WHITE, { ZIndex = 21, BackgroundTransparency = 0.6 }); corner(gl, UDim.new(0.5, 0))
	local function seg(x1, y1, x2, y2, th)
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local f = frame(ring, (x1 + x2) / 2, (y1 + y2) / 2, len + th, th, INK, { AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = math.deg(math.atan2(dy, dx)), ZIndex = 23 })
		corner(f, UDim.new(0.5, 0))
	end
	seg(9.5, 15.5, 13.5, 19.5, 4)
	seg(13.5, 19.5, 21, 10.5, 4)
	return ring
end

-- ===== наведення слотів (×1,025, нахил до 1,5°, натискання 0,96) =====
local hoverSet = {}
local hoverConn = nil
local function hoverStep(dt: number)
	local a = 1 - math.exp(-14 * dt)
	for s in hoverSet do
		local ts = s.down and 0.96 or (s.hover and 1.025 or 1)
		local tr = (s.hover and not s.down) and s.rel * 1.5 or 0
		local ty = s.lift and -8 or 0
		s.sc += (ts - s.sc) * a
		s.rot += (tr - s.rot) * a
		s.ly += (ty - s.ly) * a
		if not s.hover and not s.down and math.abs(s.sc - 1) < 0.0005 and math.abs(s.rot) < 0.02 and math.abs(s.ly - ty) < 0.05 then
			s.sc, s.rot, s.ly = 1, 0, ty
			hoverSet[s] = nil
		end
		s.scale.Scale = s.sc
		s.card.Rotation = s.rot
		s.holder.Position = UDim2.fromOffset(s.cx, s.cy + s.ly)
	end
	if next(hoverSet) == nil and hoverConn then hoverConn:Disconnect(); hoverConn = nil end
end
local function wakeHover(s)
	hoverSet[s] = true
	if not hoverConn then hoverConn = RunService.RenderStepped:Connect(hoverStep) end
end

-- ===== слот «C · Сяйво» =====
-- makeSlot(parent, x, y, S, mini) → s; s:set(item або nil, opt) — оновлює вміст. opt: ring (Color3), check (Color3), dim, keyNum, hotIndex.
-- s.onClick(s) — клік (не після перетягування). Вміст картки нахиляється (card), кнопка й значки — ні.
local slotIsDragging -- функція: чи щойно було перетягування сітки (нижче)
local function makeSlot(parent, x, y, S, mini)
	local P = 16
	local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(S + 2 * P, S + 2 * P),
		Position = UDim2.fromOffset(x + S / 2, y + S / 2), ZIndex = 1 }, parent)
	local scale = new("UIScale", {}, holder)
	local card = frame(holder, 0, 0, S + 2 * P, S + 2 * P, nil, { Name = "Card", BackgroundTransparency = 1, ZIndex = 1 })
	frame(card, P, P + math.floor(S * 0.04 + 0.5), S, S, BLACK, { BackgroundTransparency = 0.7, ZIndex = 1 })
	local bg = frame(card, P, P, S, S, WHITE, { ZIndex = 2 })
	vgrad(bg, { { 0, "22262c" }, { 1, "15181c" } }); stroke(bg, INK, S > 90 and 4 or 3)
	local tone = frame(card, P + 3, P + 3, S - 6, S - 6, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local toneStroke = stroke(tone, WHITE, S > 90 and 3 or 2, 0.94)
	local pad = S * (mini and 0.14 or 0.16)
	local iw = S - 2 * pad
	local gcx, gcy = P + pad + iw / 2, P + pad * (mini and 0.8 or 0.75) + iw / 2
	local R = S * 0.5
	local glow = frame(card, 0, 0, S + 2 * P, S + 2 * P, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local circles = {}
	for i = GLOW_N, 1, -1 do
		local rr = R * i / GLOW_N
		local g = frame(glow, gcx - rr, gcy - rr, rr * 2, rr * 2, WHITE, { BackgroundTransparency = 1, ZIndex = 1 })
		corner(g, UDim.new(0.5, 0))
		circles[i] = g
	end
	local icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(P + pad, P + pad * (mini and 0.8 or 0.75)),
		Size = UDim2.fromOffset(iw, iw), ZIndex = 4, Visible = false }, card)
	local name = textAt(card, P + 7, P + 16, S - 10, 14, "", WHITE, 2.2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local cnt = textAt(card, P, P + S - (mini and 14 or 17), S - 8, mini and 19 or 22, "", WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5, Visible = false })
	local rar = textAt(card, P, P + S - 14, S - 8, 13, "", WHITE, 2, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local keyNum = mini and textAt(card, P + 6, P + 13, 30, 15, "", C("c9ced4"), 2.2, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }) or nil
	local ring = frame(card, P - 1, P - 1, S + 2, S + 2, nil, { BackgroundTransparency = 1, ZIndex = 7, Visible = false })
	local ringStroke = stroke(ring, C("c8ff6a"), 4)
	local lockImg = new("ImageLabel", { BackgroundTransparency = 1, Image = Items.ICONS.lock, ScaleType = Enum.ScaleType.Fit, ZIndex = 8, Visible = false,
		Position = UDim2.fromOffset(P + (mini and -5 or -8), P + S - (mini and 24 or 32)), Size = UDim2.fromOffset(mini and 26 or 36, mini and 26 or 36) }, holder)
	local check = makeCheck(holder, P + S - 18, P - 10, C("ff4f5e"))
	local hot = nil -- значок «у хотбарі N»
	local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(P, P),
		Size = UDim2.fromOffset(S, S), ZIndex = 30 }, holder)
	hit:SetAttribute("NoHoverSound", true)
	local s = { holder = holder, card = card, scale = scale, sc = 1, rot = 0, ly = 0, rel = 0, hover = false, down = false, lift = false,
		cx = x + S / 2, cy = y + S / 2, item = nil, onClick = nil, S = S }
	function s.place(nx: number, ny: number) s.cx, s.cy = nx + S / 2, ny + S / 2; holder.Position = UDim2.fromOffset(s.cx, s.cy + s.ly) end
	function s.set(it, opt)
		opt = opt or {}
		s.item = it
		local has = it ~= nil
		local tc = has and it.tone or WHITE
		local tbl = has and GLOW_ITEM or GLOW_EMPTY
		for i = 1, GLOW_N do circles[i].BackgroundColor3 = tc; circles[i].BackgroundTransparency = tbl[i] end
		toneStroke.Color = tc; toneStroke.Transparency = has and 0.67 or 0.94
		icon.Visible = has
		if has then icon.Image = it.icon end
		ItemVP.set(icon, has and it.key or nil)
		name.Visible = has and not mini
		if has and not mini then name.Text = it.name; name.TextSize = (#it.name > 12) and 12 or 14 end
		cnt.Visible = has and not it.golem
		if has and not it.golem then cnt.Text = "×" .. NF.short(it.n) end
		rar.Visible = has and it.golem == true and not mini
		if has and it.golem then rar.Text = it.rar; rar.TextColor3 = it.tone end
		if keyNum then keyNum.Text = opt.keyNum or "" end
		ring.Visible = opt.ring ~= nil
		if opt.ring then ringStroke.Color = opt.ring end
		check.Visible = opt.check ~= nil
		if opt.check then check.Fill.BackgroundColor3 = opt.check end
		lockImg.Visible = has and opt.locked == true
		card.Visible = true
		holder.ZIndex = opt.top and 5 or 1
		-- притемнення (заблоковане в режимі видалення)
		local dim = opt.dim and 0.55 or 0
		icon.ImageTransparency = dim; bg.BackgroundTransparency = dim * 0.6
		if opt.hotIndex and not hot then
			hot = StyleA.new(holder, { size = Vector2.new(34, 30), position = Vector2.new(P + S - 30, P - 10), anchor = Vector2.zero, color = "blue",
				half = true, rows = 3, text = "", textSize = 17, zIndex = 9 })
		end
		if hot then hot.root.Visible = opt.hotIndex ~= nil; if opt.hotIndex then hot:setText(tostring(opt.hotIndex)) end end
		if s.lift ~= (opt.lift == true) then s.lift = opt.lift == true; wakeHover(s) end
	end
	local function aim(px: number)
		local c = holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2
		s.rel = math.clamp((px - c) / math.max(1, hit.AbsoluteSize.X / 2), -1, 1)
	end
	hit.MouseEnter:Connect(function(px)
		if s.blocked and s.blocked() then return end
		if not s.hover and s.item then slotHoverSound() end
		s.hover = true; aim(px); wakeHover(s)
	end)
	hit.MouseMoved:Connect(function(px) if s.blocked and s.blocked() then return end s.hover = true; aim(px); wakeHover(s) end)
	hit.MouseLeave:Connect(function() s.hover = false; s.down = false; wakeHover(s) end)
	hit.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			s.down = true; wakeHover(s)
			if s.onPress then s.onPress(inp) end
		end
	end)
	hit.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then s.down = false; wakeHover(s) end
	end)
	hit.Activated:Connect(function()
		if slotIsDragging and slotIsDragging() then return end
		if s.onClick then s.onClick(s) end
	end)
	s.hit = hit
	function s.shake()
		local p0 = holder.Position
		task.spawn(function()
			for _, dx in { -8, 8, -5, 5, -2, 0 } do holder.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
			holder.Position = UDim2.fromOffset(s.cx, s.cy + s.ly)
		end)
	end
	function s.toast(text: string, color: Color3?)
		local t = textAt(holder, 0, P + S / 2, S + 2 * P, 20, text, color or C("ffd34d"), 2.6, { ZIndex = 40 })
		task.delay(0.7, function() t:Destroy() end)
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
local function num(key: string): number return math.max(0, math.floor(tonumber(player:GetAttribute(key)) or 0)) end

local items, byKey = {}, {}
local lockSet = {}
local pinSet = {} -- закріплені кнопкою Hotbar (InvPinned): їхній слот не зникає, коли предмет прибирають з рук
local hotbar = {} -- 9 ключів ("" — порожньо)
local heldKey = ""
local function rebuild()
	items, byKey = {}, {}
	local function add(it) table.insert(items, it); byKey[it.key] = it end
	for _, o in Forge.ORES do
		add({ key = "Ore_" .. o.key, tab = "ores", name = o.key, sub = "Ore · " .. NF.money(o.price) .. " each", n = num("Ore_" .. o.key),
			icon = ICON_ORE[o.key] or "", tone = Items.ORE_TONE[o.key] or WHITE })
	end
	for _, o in Forge.ORES do
		if not Forge.canSmelt(o) and num("Bars_" .. o.key) <= 0 then continue end -- злитків вугілля не буває
		add({ key = "Bars_" .. o.key, tab = "ores", name = o.key .. " Bar", sub = "Bar · " .. NF.money(o.price * Forge.BAR_MULT) .. " each",
			n = num("Bars_" .. o.key), icon = ICON_BAR[o.key] or "", tone = Items.ORE_TONE[o.key] or WHITE })
	end
	for _, d in Items.POTIONS do
		add({ key = "Pot_" .. d.key, tab = "potions", name = d.name, sub = d.desc, n = num("Pot_" .. d.key), icon = d.icon, tone = d.tone })
	end
	for _, g in decodeAttr("InvGolems", {}) do
		local def = Items.GOLEMS[g.kind]
		if def and type(g.id) == "number" then
			add({ key = "Golem_" .. g.id, tab = "golems", name = def.name, sub = def.rarity .. " · mines " .. def.rate .. " ore/s", n = 1, golem = true,
				rar = def.rarity, icon = def.icon, tone = Items.RARITY[def.rarity] or WHITE })
		end
	end
	lockSet = {}
	for _, k in decodeAttr("InvLocks", {}) do lockSet[k] = true end
	pinSet = {}
	for _, k in decodeAttr("InvPinned", {}) do pinSet[k] = true end
	local h = decodeAttr("InvHotbar", {})
	table.clear(hotbar)
	for _, k in h do if type(k) == "string" and k ~= "" and #hotbar < Items.HOTBAR then table.insert(hotbar, k) end end
	local hk = player:GetAttribute("InvHeld")
	heldKey = type(hk) == "string" and hk or ""
end
local function live(key: string): any
	local it = byKey[key]
	return (it and it.n > 0) and it or nil
end

-- =====================================================================
-- ===== хотбар =====
-- =====================================================================
local hbGui = new("ScreenGui", { Name = "Hotbar", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5 }, playerGui)
local hbRoot = new("Frame", { Name = "Root", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(HB_W, HS + 64) }, hbGui)
local hbScale = new("UIScale", {}, hbRoot)
local heldPill = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(320, 42), Position = UDim2.fromOffset(HB_W / 2 - 160, 2), ZIndex = 20 }, hbRoot)
local heldBg = StyleA.new(heldPill, { size = Vector2.new(320, 42), position = Vector2.zero, anchor = Vector2.zero, color = "green", half = true, rows = 3, text = "", textSize = 20, zIndex = 1 })
heldPill.Visible = false
local hot = {}
local toggleHeld -- нижче
for i = 1, Items.HOTBAR do
	local s = makeSlot(hbRoot, (i - 1) * (HS + HG), 58, HS, true)
	s.onClick = function() toggleHeld(i) end
	hot[i] = s
end

local hbOpenOrder = 5
local function fitHotbar()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or hbGui.AbsoluteSize
	if vs.X < 2 or vs.Y < 2 then return end
	local s = vs.Y / 720
	-- між Money HUD (зліва) і Boss (справа): ≈ 370 одиниць HUD з кожного боку
	s = math.min(s, (vs.X - 2 * 370 * (vs.Y / 720)) / HB_W, (vs.X - 24) / HB_W)
	hbScale.Scale = math.max(0.35, s)
	hbRoot.Position = UDim2.new(0.5, 0, 1, -math.floor(10 * vs.Y / 720))
end

local shownKeys = {} -- ключі, що були в хотбарі минулого разу (новий слот — «поп»)
local function refreshHotbar()
	-- лише зайняті слоти, по центру
	local n = 0
	for i = 1, #hotbar do if live(hotbar[i]) then n = i end end
	local x0 = (HB_W - (n * HS + math.max(0, n - 1) * HG)) / 2
	for i = 1, Items.HOTBAR do
		local s = hot[i]
		s.holder.Visible = i <= n
		if i <= n then s.place(x0 + (i - 1) * (HS + HG), 58) end
		if i <= n and hotbar[i] and not shownKeys[hotbar[i]] then task.defer(s.pop) end
	end
	table.clear(shownKeys)
	for i = 1, n do shownKeys[hotbar[i]] = true end
	for i = 1, n do
		local it = live(hotbar[i])
		hot[i].set(it, { keyNum = tostring(i), ring = (it and heldKey == hotbar[i]) and C("c8ff6a") or nil, lift = it ~= nil and heldKey == hotbar[i],
			top = it ~= nil and heldKey == hotbar[i], locked = it ~= nil and lockSet[hotbar[i]] == true })
		hot[i].holder.ZIndex = (it and heldKey == hotbar[i]) and 5 or 1 -- вибраний слот над сусідами (рамку не перекриває наступний)
	end
	local it = heldKey ~= "" and live(heldKey) or nil
	if it then
		heldBg:setText(it.name .. (it.golem and "" or (" ×" .. NF.short(it.n))) .. " · in hand")
		if not heldPill.Visible then heldPill.Visible = true end
	else
		heldPill.Visible = false
	end
end

local isOpenRef, renderAllRef = function() return false end, function() end -- задаються нижче (вікно)
local function sendHold(key: string)
	heldKey = key
	Action:FireServer("Hold", key)
end
toggleHeld = function(i: number)
	local key = hotbar[i]
	if not key or not live(key) then return end
	if heldKey == key then -- прибрав з рук → слот зникає (сервер теж прибирає), решта зсуваються; закріплений (Hotbar) — лишається
		if not pinSet[key] then table.remove(hotbar, i) end
		sendHold("")
	else
		sendHold(key)
	end
	refreshHotbar()
	if isOpenRef() then renderAllRef() end
end

-- =====================================================================
-- ===== вікно INVENTORY =====
-- =====================================================================
local gui = new("ScreenGui", { Name = "InventoryWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10, Enabled = true }, playerGui)
local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local _, content = windowFrame(pop, WX, WY, WW, WH, 1, 14)

-- заголовок INVENTORY (синій перелив + відблиск) і X
textAt(pop, WX + 32, WY - 8 + 7, 640, 96, "INVENTORY", INK, 9, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, WX + 32, WY - 8, 640, 96, "INVENTORY", WHITE, 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local titleShine = textAt(pop, WX + 32, WY - 8, 640, 96, "INVENTORY", WHITE, 0, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
do
	local P = { C("e6f6ff"), C("7fd0ff"), C("1c7fd8"), C("7fd0ff") }
	local function sample(u)
		local x = (u % 1) * #P
		local i = math.floor(x)
		local t = x - i
		t = t * t * (3 - 2 * t)
		return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
	end
	RunService.Heartbeat:Connect(function()
		if not modalRoot.Visible then return end
		local phase = -(os.clock() / 4)
		local ks = {}
		for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end
		titleGrad.Color = ColorSequence.new(ks)
	end)
	local tw = TweenService:Create(titleShineGrad, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
	tw.Completed:Connect(function() titleShineGrad.Offset = Vector2.new(-1.3, 0) end)
	task.spawn(function() while true do task.wait(3 + math.random() * 3); if modalRoot.Visible then tw:Play() end end end)
end
local closeBtn = makeButton(pop, WX + WW - 70, WY - 34, 84, 84, { shadowDy = 8, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

-- ===== стан вікна =====
local tab = "ores"
local mode = nil -- nil | "delete" | "lock"
local picked = {} -- ключ → true
local selKey = nil
local isOpen = false
local MODE_COL = { delete = C("ff4f5e"), lock = C("ffd23a") }
local refreshAll -- нижче
local function pickedCount() local n = 0 for _ in picked do n += 1 end return n end
local function tabItems(k: string)
	local t = {}
	for _, it in items do if it.tab == k and it.n > 0 then table.insert(t, it) end end
	return t
end

-- ===== вкладки =====
local TABS = { { "golems", "Golems", Items.ICONS.tab_golems }, { "ores", "Ores / Bars", Items.ICONS.tab_orebars }, { "potions", "Potions", Items.ICONS.tab_potions } }
local tabBtns = {}
local setTab, setMode -- нижче
local function tabY(i: number) return 66 + (i - 1) * (TH + 14) end
for i, spec in TABS do
	local k = spec[1]
	local hold = frame(content, TX, tabY(i), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local b = makeButton(hold, 0, 0, TW, TH, { shadowDy = 7, color = "gray", z = 1, shine = false })
	b.onClick = function() setTab(k) end
	new("ImageLabel", { BackgroundTransparency = 1, Image = spec[3], ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(8, 2), Size = UDim2.fromOffset(74, 74), ZIndex = 4 }, hold)
	textAt(hold, 86, 32, 132, #spec[2] > 8 and 21 or 25, spec[2], WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local c = textAt(hold, 86, 58, 132, 15, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5 })
	tabBtns[k] = { hold = hold, b = b, c = c, i = i }
end

-- ===== заголовок вмісту, сітка зі смугою прокрутки =====
local hdr = textAt(content, 290, 86, 400, 32, "", WHITE, 3.2, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local cap = textAt(content, 640, 86, 296, 18, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 3 })
local gvp = frame(content, GX, GY, GW, GH, nil, { Name = "Grid", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 2 })
local gstrip = frame(gvp, 0, 0, GW, 10, nil, { BackgroundTransparency = 1, ZIndex = 1 })
local vsb = frame(content, GX + GW + 3, GY + GP, 10, GH - 2 * GP, WHITE, { Active = true, ZIndex = 3 })
new("UIGradient", { Color = cseq(TRACK), Rotation = 0 }, vsb); stroke(vsb, INK, 3)
local vth = frame(vsb, 0, 0, 10, 60, WHITE, { Active = true, ZIndex = 2 }); vgrad(vth, LIME)
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

-- пул слотів сітки (росте за потреби)
local gslots = {}
local slotClick -- нижче
local function gridSlot(i: number)
	local s = gslots[i]
	if not s then
		s = makeSlot(gstrip, 0, 0, GS, false)
		s.onPress = function(inp) beginDrag(inp, false) end
		s.hit.InputChanged:Connect(wheel)
		s.onClick = function() if s.item then slotClick(s) end end
		s.blocked = function() return not isOpen end
		gslots[i] = s
	end
	return s
end

-- ===== картка вибраного предмета =====
local info = frame(content, 290, 392, 646, 100, WHITE, { ZIndex = 3 })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.4) }) }, info)
stroke(info, INK, 3)
local infoIcon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(14, 7), Size = UDim2.fromOffset(86, 86), ZIndex = 2 }, info)
local infoName = textAt(info, 112, 32, 270, 28, "", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, RichText = true, ZIndex = 2 })
local infoSub = textAt(info, 112, 64, 270, 16, "", SUB_TXT, 1.8, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 2 })
local infoHint = textAt(info, 0, 50, 646, 20, "Tap an item to see it here", C("c9ced4"), 2, { RichText = true, FontFace = XBOLD, ZIndex = 2 })
local bHold = makeButton(info, 384, 12, 132, 72, { shadowDy = 6, color = "green", text = "Hold", textSize = 23, z = 3 })
local bPin = makeButton(info, 526, 12, 108, 72, { shadowDy = 6, color = "blue", text = "Hotbar", textSize = 22, z = 3 })
local function showInfoItem(on: boolean)
	infoIcon.Visible = on; infoName.Visible = on; infoSub.Visible = on; infoHint.Visible = not on
	for _, b in { bHold, bPin } do b.root.Visible = on; b.shadow.Visible = on end
end

-- ===== інструменти: видалення / блокування / Cancel; кнопки режиму на місці прихованих вкладок =====
-- три кнопки в ряд під вкладками: кошик (видалення), замок (блокування), рюкзак — все з поточної вкладки з хотбара назад у інвентар
local TOOL_W, TOOL_G = 66, 12
local toolTrash = makeButton(content, TX, 404, TOOL_W, 72, { shadowDy = 6, color = "red", icon = Items.ICONS.trash, iconPad = 0.02, z = 4 })
local toolLock = makeButton(content, TX + TOOL_W + TOOL_G, 404, TOOL_W, 72, { shadowDy = 6, color = "yellow", icon = Items.ICONS.lock, iconPad = 0.02, z = 4 })
local toolBack = makeButton(content, TX + 2 * (TOOL_W + TOOL_G), 404, TOOL_W, 72, { shadowDy = 6, color = "blue", icon = "rbxassetid://107241982376806", iconPad = 0.08, z = 4 }) -- hud_inventory (рюкзак)
local toolCancel = makeButton(content, TX, 404, TW, 72, { shadowDy = 6, color = "gray", text = "Cancel", textSize = 28, z = 4 })
local function showBtn(b, on) b.root.Visible = on; b.shadow.Visible = on end
showBtn(toolCancel, false)
local mAh = frame(content, TX, tabY(2), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
local mBh = frame(content, TX, tabY(3), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
local mA = makeButton(mAh, 0, 0, TW, TH, { shadowDy = 7, color = "blue", text = "Select All", textSize = 28, z = 1 })
local mB = makeButton(mBh, 0, 0, TW, TH, { shadowDy = 7, color = "red", z = 1 })
local mBicon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(64, 64), ZIndex = 4 }, mBh)
local mBtext = textAt(mBh, 82, 40, 136, 26, "", WHITE, 2.8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })

-- ===== вікно підтвердження видалення =====
local cfDim = frame(content, 0, 0, WW, WH, C("0d0f12"), { BackgroundTransparency = 0.45, Active = true, Visible = false, ZIndex = 40 })
local CFW, CFH = 560, 330
local cfRoot = frame(content, (WW - CFW) / 2, (WH - CFH) / 2 + 10, CFW, CFH, nil, { BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 41 })
local cfScale = new("UIScale", {}, cfRoot)
local _, cfC = windowFrame(cfRoot, 0, 0, CFW, CFH, 1, 10)
local cfTitle = textAt(cfC, 0, 62, CFW, 34, "", WHITE, 3.5, { ZIndex = 3 })
local cfRow = frame(cfC, 0, 96, CFW, 76, nil, { BackgroundTransparency = 1, ZIndex = 3 })
textAt(cfC, 0, 196, CFW, 18, "This can't be undone.", INK, 0, { FontFace = XBOLD, ZIndex = 3 })
local cfCancel = makeButton(cfC, 44, 226, 200, 72, { shadowDy = 6, color = "gray", text = "Cancel", textSize = 28, z = 3 })
local cfDelete = makeButton(cfC, 260, 226, CFW - 304, 72, { shadowDy = 6, color = "red", text = "Delete", textSize = 30, z = 3 })
local cfSlots = {}
local cfClosedAt = -1 -- коли закрили підтвердження: той самий клік не має провалитися в тло і закрити інвентар
local function closeConfirm()
	if cfRoot.Visible then cfClosedAt = os.clock() end
	cfDim.Visible = false; cfRoot.Visible = false
	if mode == nil then table.clear(picked) end -- підтвердження одного предмета (смітник без режиму)
end
cfDim.InputBegan:Connect(function(inp) if isPress(inp) then closeConfirm() end end)
cfCancel.onClick = function() closeConfirm() end

-- =====================================================================
-- ===== логіка вікна =====
-- =====================================================================
local function selectable()
	local t = {}
	for _, it in tabItems(tab) do if not (mode == "delete" and lockSet[it.key]) then table.insert(t, it) end end
	return t
end

local function renderGrid()
	local list = tabItems(tab)
	local total = math.max(#list + (tab == "golems" and 2 or 4), GCOLS * 2)
	local rows = math.ceil(total / GCOLS)
	local count = rows * GCOLS
	gH = rows * (GS + GG) - GG + 2 * GP + 8
	gstrip.Size = UDim2.fromOffset(GW, gH)
	for i = 1, count do
		local s = gridSlot(i)
		s.holder.Visible = true
		s.place(((i - 1) % GCOLS) * (GS + GG) + GP, math.floor((i - 1) / GCOLS) * (GS + GG) + GP + 4)
		local it = list[i]
		if it then
			local opt = { locked = lockSet[it.key] == true }
			if mode then
				local on = picked[it.key] == true
				opt.ring = on and MODE_COL[mode] or nil
				opt.check = on and MODE_COL[mode] or nil
				opt.dim = mode == "delete" and lockSet[it.key] == true
			else
				opt.ring = selKey == it.key and C("c8ff6a") or nil
				local hi = tableFind(hotbar, it.key)
				opt.hotIndex = hi
			end
			s.set(it, opt)
		else
			s.set(nil)
		end
	end
	for i = count + 1, #gslots do gslots[i].holder.Visible = false end
	setG(gscroll)
	hdr.Text = tab == "golems" and "Golems" or tab == "ores" and "Ores / Bars" or "Potions"
	local n = 0
	for _, it in list do n += it.n end
	cap.Text = tab == "golems" and (#list .. " / " .. Items.MAX_GOLEMS .. " golems") or tab == "ores" and (#list .. " kinds · " .. NF.full(n) .. " items") or (#list .. " kinds")
	for k, t in tabBtns do
		local l = tabItems(k)
		local c = 0
		for _, it in l do c += it.n end
		t.c.Text = k == "golems" and (#l .. " golems") or (NF.full(c) .. " items")
	end
	-- кнопки режиму
	if mode then
		local sel = selectable()
		local all = #sel > 0
		for _, it in sel do if not picked[it.key] then all = false; break end end
		mA:setText(all and "Deselect All" or "Select All")
		mA:recolor(all and "orange" or "blue")
		local pc = pickedCount()
		if mode == "delete" then
			mBtext.Text = pc > 0 and ("Delete (" .. pc .. ")") or "Delete"
			mB:recolor("red"); mB:enable(pc > 0)
		else
			local allLocked = pc > 0
			for k in picked do if not lockSet[k] then allLocked = false; break end end
			mBtext.Text = pc > 0 and ((allLocked and "Unlock (" or "Lock (") .. pc .. ")") or "Lock"
			mB:recolor(allLocked and "blue" or "yellow"); mB:enable(pc > 0)
		end
		mBtext.TextSize = #mBtext.Text > 10 and 22 or 26
	end
end

local function renderInfo()
	local it = selKey and live(selKey) or nil
	local show = mode == nil and it ~= nil
	showInfoItem(show)
	if mode == "delete" then
		infoHint.Text = 'Tap items to delete · <font color="#ff8a96">' .. pickedCount() .. " selected</font> · locked can't be deleted"
	elseif mode == "lock" then
		infoHint.Text = 'Tap items to lock or unlock · <font color="#ffd23a">' .. pickedCount() .. " selected</font>"
	else
		infoHint.Text = "Tap an item to see it here"
	end
	if not show or not it then return end
	infoIcon.Image = it.icon
	ItemVP.set(infoIcon, it.key, 1.13) -- у панелі опису: у межах іконки, не налазить на текст
	infoName.Text = it.name .. (it.golem and "" or (' <font size="22" color="#c9ced4">×' .. NF.full(it.n) .. "</font>"))
	infoSub.Text = it.sub .. (lockSet[it.key] and " · locked" or "")
	local hi = tableFind(hotbar, it.key)
	local inHand = heldKey == it.key
	bHold:setText(inHand and "Put Away" or "Hold"); bHold:recolor(inHand and "red" or "green")
	bPin:setText(pinSet[it.key] and "Unpin" or "Hotbar")
end

refreshAll = function()
	rebuild()
	-- вибране могло зникнути
	if selKey and not live(selKey) then selKey = nil end
	for k in picked do if not live(k) then picked[k] = nil end end
	refreshHotbar()
	if isOpen then renderGrid(); renderInfo() end
end

local function sendHotbar() Action:FireServer("Hotbar", hotbar) end
isOpenRef = function() return isOpen end
renderAllRef = function() renderGrid(); renderInfo() end

slotClick = function(s)
	local it = s.item
	if not it then return end
	if not mode then
		-- повторне натискання на вибраний слот знімає виділення
		if selKey == it.key then selKey = nil else selKey = it.key end
		renderGrid(); renderInfo()
		return
	end
	if mode == "delete" and lockSet[it.key] then s.shake(); s.toast("LOCKED"); return end
	if picked[it.key] then picked[it.key] = nil else picked[it.key] = true end
	renderGrid(); renderInfo()
end

bHold.onClick = function()
	local it = selKey and live(selKey)
	if not it then return end
	if heldKey == it.key then -- Put Away: прибрати з рук — слот зникає (крім закріплених кнопкою Hotbar)
		local hi = tableFind(hotbar, it.key)
		if hi and not pinSet[it.key] then table.remove(hotbar, hi) end
		sendHold("")
	else
		if not tableFind(hotbar, it.key) then -- узяв у руку → новий слот у кінці хотбара
			if #hotbar >= Items.HOTBAR then StyleA.shake(bHold); return end
			table.insert(hotbar, it.key)
		end
		sendHold(it.key)
	end
	refreshHotbar(); renderGrid(); renderInfo()
end
bPin.onClick = function()
	local it = selKey and live(selKey)
	if not it then return end
	local hi = tableFind(hotbar, it.key)
	if pinSet[it.key] then -- Unpin: слот зникає, решта зсуваються (якщо в руці — випадає з руки)
		pinSet[it.key] = nil
		if hi then table.remove(hotbar, hi) end
		if heldKey == it.key then heldKey = "" end
		Action:FireServer("Pin", { key = it.key, on = false })
	else -- Hotbar: закріпити (слот лишається і після Put Away)
		if not hi then
			if #hotbar >= Items.HOTBAR then StyleA.shake(bPin); return end
			table.insert(hotbar, it.key)
		end
		pinSet[it.key] = true
		Action:FireServer("Pin", { key = it.key, on = true })
	end
	refreshHotbar(); renderGrid(); renderInfo()
end

setTab = function(k: string)
	if mode and k ~= tab then return end
	tab = k; selKey = nil; table.clear(picked); gscroll = 0
	for kk, t in tabBtns do
		local on = kk == k
		t.b:setColor(on and "blue" or "gray")
		t.hold.Position = UDim2.fromOffset(on and TX + 10 or TX, mode and tabY(1) or tabY(t.i))
	end
	renderGrid(); renderInfo()
	gstrip.Position = UDim2.fromOffset(0, 10)
	tween(gstrip, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(0, 0) })
end

setMode = function(m)
	mode = m; table.clear(picked); selKey = nil
	for k, t in tabBtns do
		t.hold.Visible = (m == nil) or k == tab
		t.hold.Position = UDim2.fromOffset(k == tab and TX + 10 or TX, m and tabY(1) or tabY(t.i))
	end
	mAh.Visible = m ~= nil; mBh.Visible = m ~= nil
	if m then
		mBicon.Image = m == "delete" and Items.ICONS.trash or Items.ICONS.lock
		for _, h in { mAh, mBh } do
			h.Position = UDim2.fromOffset(TX - 24, h.Position.Y.Offset)
			tween(h, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(TX, h.Position.Y.Offset) })
		end
	end
	showBtn(toolTrash, m == nil); showBtn(toolLock, m == nil); showBtn(toolBack, m == nil); showBtn(toolCancel, m ~= nil)
	renderGrid(); renderInfo()
end
-- смітник: обробник нижче (після openConfirm) — як замок: вибрано предмет → підтвердження, інакше — режим вибору
-- замок: якщо вибрано предмет — одразу блокує / розблоковує саме його; якщо нічого не вибрано — режим вибору кількох предметів
toolLock.onClick = function()
	local it = selKey and live(selKey)
	if not it then setMode("lock"); return end
	local on = not lockSet[it.key]
	lockSet[it.key] = on or nil
	Action:FireServer("Lock", { keys = { it.key }, on = on })
	local t = textAt(content, 290, 360, 646, 26, (on and "Locked " or "Unlocked ") .. it.name, C("ffd23a"), 3, { ZIndex = 50 })
	tween(t, 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 24), TextTransparency = 1 })
	task.delay(1.15, function() t:Destroy() end)
	refreshHotbar(); renderGrid(); renderInfo()
end
toolCancel.onClick = function() setMode(nil) end
-- «в інвентар»: усе з поточної вкладки, що стоїть у хотбарі (закріплене чи взяте в руку), прибирається зі слотів і з руки
toolBack.onClick = function()
	local keys = {}
	for i = #hotbar, 1, -1 do
		local k = hotbar[i]
		local it = byKey[k]
		if it and it.tab == tab then
			table.insert(keys, k)
			table.remove(hotbar, i)
			pinSet[k] = nil
			if heldKey == k then heldKey = "" end
		end
	end
	if #keys == 0 then StyleA.shake(toolBack); return end
	Action:FireServer("Clear", keys)
	refreshHotbar(); renderGrid(); renderInfo()
end
mA.onClick = function()
	local sel = selectable()
	local all = #sel > 0
	for _, it in sel do if not picked[it.key] then all = false; break end end
	table.clear(picked)
	if not all then for _, it in sel do picked[it.key] = true end end
	renderGrid(); renderInfo()
end

local function openConfirm()
	local keys = {}
	for k in picked do table.insert(keys, k) end
	local n = #keys
	cfTitle.Text = "Delete " .. n .. " item" .. (n > 1 and "s" or "") .. "?"
	for _, s in cfSlots do s.holder:Destroy() end
	table.clear(cfSlots)
	local show = math.min(6, n)
	local w = show * 70 + (n > 6 and 60 or 0)
	for i = 1, show do
		local s = makeSlot(cfRow, (CFW - w) / 2 + (i - 1) * 70 + 4, 4, 62, true)
		s.set(live(keys[i]))
		s.blocked = function() return true end
		table.insert(cfSlots, s)
	end
	if n > 6 then
		local t = textAt(cfRow, (CFW - w) / 2 + show * 70, 38, 60, 24, "+" .. (n - 6), WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
		table.insert(cfSlots, { holder = t })
	end
	cfDim.Visible = true; cfRoot.Visible = true
	cfScale.Scale = 0.85
	tween(cfScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function()
		tween(cfScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 })
	end)
end
cfDelete.onClick = function()
	local keys = {}
	for k in picked do if not lockSet[k] then table.insert(keys, k) end end
	closeConfirm()
	if #keys == 0 then return end
	Action:FireServer("Delete", keys)
	for _, k in keys do if selKey == k then selKey = nil end end
	local t = textAt(content, 290, 360, 646, 26, "Deleted " .. #keys, C("ff8a96"), 3, { ZIndex = 50 })
	tween(t, 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 24), TextTransparency = 1 })
	task.delay(1.15, function() t:Destroy() end)
	table.clear(picked)
	renderGrid(); renderInfo()
end
-- смітник (як замок): якщо вибрано предмет — одразу вікно підтвердження видалення саме цього предмета;
-- заблокований (Lock) видалити не можна — кнопка трясеться й підказка. Нічого не вибрано — режим вибору кількох.
toolTrash.onClick = function()
	local it = selKey and live(selKey)
	if not it then setMode("delete"); return end
	if lockSet[it.key] then
		StyleA.shake(toolTrash)
		local t = textAt(content, 290, 360, 646, 26, it.name .. " is locked", C("ffd23a"), 3, { ZIndex = 50 })
		tween(t, 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 24), TextTransparency = 1 })
		task.delay(1.15, function() t:Destroy() end)
		return
	end
	table.clear(picked)
	picked[it.key] = true
	openConfirm()
end

mB.onClick = function()
	if pickedCount() == 0 then StyleA.shake(mB); return end
	if mode == "delete" then openConfirm(); return end
	local allLocked = true
	for k in picked do if not lockSet[k] then allLocked = false; break end end
	local keys = {}
	for k in picked do table.insert(keys, k); lockSet[k] = not allLocked or nil end
	Action:FireServer("Lock", { keys = keys, on = not allLocked })
	table.clear(picked)
	refreshHotbar(); renderGrid(); renderInfo()
end

-- =====================================================================
-- ===== масштаб, відкриття / закриття =====
-- =====================================================================
local WindowFit = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WindowFit"))
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	fitHotbar()
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	local bottom = (HS + 10 + 10) * hbScale.Scale -- хотбар лишається видно під вікном
	local avail = vh - top - bottom
	modalRoot.Position = UDim2.new(0.5, 0, 0, top + avail / 2)
	-- адаптивний масштаб: вікно займає однакову частку екрана (Shared/WindowFit), хотбар лишається видно
	local UIS_ = game:GetService("UserInputService")
	local phone = (vh - top) < 500 or (UIS_.TouchEnabled and not UIS_.MouseEnabled)
	-- розмір і місце — спільне правило всіх вікон (Shared/WindowFit.place); хотбар лишається видно знизу
	WindowFit.HS, WindowFit.HB_W = HS, HB_W
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
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fit) end)
bindCamera()

local animToken = 0
local open, close -- нижче
local hiddenGuis = {}
local function escKey(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	if cfRoot.Visible then closeConfirm() elseif mode then setMode(nil) else
		task.defer(function() if isOpen then close() end end) -- закрити вікно
	end
	return Enum.ContextActionResult.Sink
end
open = function()
	if isOpen then return end
	isOpen = true
	animToken += 1
	local my = animToken
	refreshAll()
	fit()
	setTab(tab)
	hbGui.DisplayOrder = 11 -- хотбар над затемненням вікна
	-- вікна Forge / Sell (якщо гравець у колі) ховаємо, поки відкритий інвентар — щоб не накладалися
	for _, n in { "ForgeWindow", "SellWindow" } do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false; hiddenGuis[g] = true end
	end
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("InventoryEsc", escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
end
close = function()
	if not isOpen then return end
	isOpen = false
	closeConfirm()
	if mode then setMode(nil) end
	pcall(function() CAS:UnbindAction("InventoryEsc") end)
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
		hbGui.DisplayOrder = hbOpenOrder
		for g in hiddenGuis do if g.Parent then g.Enabled = true end end
		table.clear(hiddenGuis)
	end)
end
closeBtn.onClick = function() close() end
backdrop.InputBegan:Connect(function(inp)
	if not isPress(inp) then return end
	if cfRoot.Visible or os.clock() - cfClosedAt < 0.3 then return end -- клік по Cancel / Delete / затемненню підтвердження
	-- закриває лише клік ПОЗА вікном: клік по порожній частині вікна (панель зі studs, проміжки між слотами)
	-- провалювався в тло і закривав інвентар
	local p = Vector2.new(inp.Position.X, inp.Position.Y) + GuiService:GetGuiInset()
	local a, s = content.AbsolutePosition, content.AbsoluteSize
	local top = s.Y * 0.18 -- заголовок INVENTORY і X над рамкою
	if p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y - top and p.Y <= a.Y + s.Y then return end
	close()
end)

-- кнопка рюкзака в HUD (MainHUD → UIEvents/HUDButton "Inventory") і клавіша B; 1–9 — хотбар
task.spawn(function()
	local ev = RS:WaitForChild("UIEvents", 30)
	ev = ev and ev:WaitForChild("HUDButton", 30)
	if ev then ev.Event:Connect(function(key) if key == "Inventory" then if isOpen then close() else open() end end end) end
end)
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven,
	Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	local i = tableFind(KEYS, inp.KeyCode)
	if i then toggleHeld(i) return end
	if inp.KeyCode == Enum.KeyCode.B then if isOpen then close() else open() end end
end)

-- дані: будь-яка зміна інвентаря → оновлення (раз за кадр)
local pending = false
local function schedule()
	if pending then return end
	pending = true
	task.defer(function() pending = false; refreshAll() end)
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 4) == "Ore_" or string.sub(name, 1, 5) == "Bars_" or string.sub(name, 1, 4) == "Pot_" or string.sub(name, 1, 3) == "Inv" then schedule() end
end)
refreshAll()
fit()
