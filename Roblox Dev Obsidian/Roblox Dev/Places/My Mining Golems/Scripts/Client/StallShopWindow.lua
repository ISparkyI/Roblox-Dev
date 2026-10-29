--!nonstrict
-- StallShopWindow — вікна лавок у кінці зали: DIAMONDS SHOP і EVENTS SHOP (Workspace/Cave/Shops/DiamondShop | EventShop). 29.10.2026.
-- Де: StarterPlayer/StarterPlayerScripts/StallShopWindow (LocalScript). Сервер — StallShopService, конфіг — Shared/StallShopConfig.
-- Відкривається, коли гравець стоїть у колі лавки (Ring/RingCenter, радіус SellRig.RING_R), закривається, коли вийшов;
--   хрестик — до наступного входу в коло. Стиль — як вікно SELL: квадратне вікно зі studs, заголовок КАПСОМ з іконкою й переливом.
-- DIAMONDS SHOP: таймер оновлення (StallShops.DiaNextAt), баланс діамантів, картки лотів (StallShops.DiaLots): рідкість кольором,
--   іконка, назва, що дає (скіп — «+$…» за поточним доходом), залишок на сервері «N / M LEFT», кнопка з ціною в діамантах
--   (не вистачає — сіра й хитається; розпродано — SOLD OUT; геймпас уже є — OWNED). Купівля — Remotes/StallShopAction ("BuyDia", id).
-- EVENTS SHOP: таймер (StallShops.EventNextAt) і «COMING SOON».
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")

local Shared = RS:WaitForChild("Shared")
local Cfg = require(Shared:WaitForChild("StallShopConfig"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local Rig = require(Shared:WaitForChild("SellRig"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CANVAS_W, CANVAS_H = 1286, 740
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1206, 650
local EXIT_PAD = 0.5
local DIA_ICON = "rbxassetid://126442692946356"
local SKIP_ICON = "rbxassetid://76478987044650"
local EVENT_ICON = "rbxassetid://133326399418460"
local CASH_ICON = "rbxassetid://103015355952567" -- купюра поверх годинника (як картки TIME SKIPS у SHOP)
local PATTERN_TILE = 24 -- візерунок StyleA на картках (як у SHOP)

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }

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
local function fit(t, maxSize)
	t.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 10 }, t)
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
local function shake(grp: GuiObject)
	if grp:GetAttribute("Shaking") then return end
	grp:SetAttribute("Shaking", true)
	local p0 = grp.Position
	task.spawn(function()
		for _, dx in { -10, 10, -7, 7, -3, 0 } do grp.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		grp.Position = p0
		grp:SetAttribute("Shaking", nil)
	end)
end
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, shine = opt.shine, zIndex = opt.z + 1 })
	b.shadow = sh
	StyleA.follow(b, sh)
	b.onClick = nil
	StyleA.bind(b, { debounce = 0.2, onClick = function() if b.onClick then b.onClick(b) end end })
	return b
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end
local function fmtLeft(sec: number): string
	sec = math.max(0, math.floor(sec))
	local h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

-- ===== вікно (одне на обидві лавки: режим "dia" | "event") =====
local gui = new("ScreenGui", { Name = "StallShopWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10, Enabled = true }, playerGui)
local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local _, content = windowFrame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, 1, 14)

-- заголовок: іконка (−8°, тінь) + текст КАПСОМ з переливом
local TITLE_IS = 150
local TITLE_ICX, TITLE_ICY = 56 + TITLE_IS / 2, 44
local TITLE_X = TITLE_ICX + TITLE_IS / 2 + 8
local tIconS = new("ImageLabel", { BackgroundTransparency = 1, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY + 9), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 3 }, pop)
local tIcon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 4 }, pop)
local titleShadow = textAt(pop, TITLE_X, 50 + 9, 900, 104, "", INK, 11, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, TITLE_X, 50, 900, 104, "", WHITE, 10, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local PAL = { dia = { C("e0f6ff"), C("6fd2ff"), C("2a7fe0"), C("6fd2ff") }, event = { C("ffe0f6"), C("ff7fc4"), C("b04ce0"), C("ff7fc4") } }
local mode = "dia"
RunService.Heartbeat:Connect(function()
	if not modalRoot.Visible then return end
	local P = PAL[mode]
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
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })

-- верхній рядок: таймер оновлення (ліворуч) і баланс діамантів (праворуч)
local timerBox = frame(content, 40, 74, 520, 64, C("14161a"), { BackgroundTransparency = 0.35, ZIndex = 4 })
corner(timerBox, 12); stroke(timerBox, INK, 4)
new("ImageLabel", { BackgroundTransparency = 1, Image = SKIP_ICON, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(52, 52), ZIndex = 5 }, timerBox)
local timerText = label(timerBox, 72, 0, 440, 64, 34, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, RichText = true })
local balBox = frame(content, WIN_W - 40 - 330, 74, 330, 64, C("14161a"), { BackgroundTransparency = 0.35, ZIndex = 4 })
corner(balBox, 12); stroke(balBox, INK, 4)
new("ImageLabel", { BackgroundTransparency = 1, Image = DIA_ICON, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(52, 52), ZIndex = 5 }, balBox)
local balText = label(balBox, 72, 0, 240, 64, 38, "", C("8fe0ff"), 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })

-- картки лотів
local CARD_W, CARD_H, CARD_GAP, CARD_Y = 214, 440, 18, 160
local cardsHolder = frame(content, 0, 0, WIN_W, WIN_H, nil, { BackgroundTransparency = 1, ZIndex = 4 })
local soon = frame(content, 40, 160, WIN_W - 80, 420, C("14161a"), { BackgroundTransparency = 0.35, ZIndex = 4, Visible = false })
corner(soon, 16); stroke(soon, INK, 4)
local soonT = label(soon, 0, 120, WIN_W - 80, 130, 120, "COMING SOON", WHITE, 10, { ZIndex = 6 })
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("ffe0f6"), C("ff7fc4")) }, soonT)
label(soon, 0, 260, WIN_W - 80, 50, 34, "Event items arrive with the next events!", SUB_TXT, 4, { ZIndex = 6, FontFace = XBOLD })

local cards = {} -- [id] = card
local function potDef(key: string?): any
	for _, d in Items.POTIONS do if d.key == key then return d end end
	return nil
end
-- іконки товару падають на фоні картки (згори вниз, 40 % прозорі) — як у SHOP
local function startRain(clip: Frame, icon: string, w: number, h: number, every: number)
	task.spawn(function()
		while clip.Parent do
			if modalRoot.Visible and icon ~= "" then
				local s = math.random(22, 40)
				local img = new("ImageLabel", { BackgroundTransparency = 1, Image = icon, ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(s, s), Rotation = math.random(-25, 25),
					Position = UDim2.fromOffset(math.random(10, math.max(11, math.floor(w) - 10)), -s), ZIndex = 2 }, clip)
				local tw = TweenService:Create(img, TweenInfo.new(3 + math.random() * 3, Enum.EasingStyle.Linear), {
					Position = UDim2.fromOffset(img.Position.X.Offset + math.random(-30, 30), h + s), Rotation = img.Rotation + math.random(-60, 60) })
				tw.Completed:Connect(function() img:Destroy() end)
				tw:Play()
			end
			task.wait(every * (0.6 + math.random() * 0.8))
		end
	end)
end
local function lotPrice(l): number
	if l.kind == "potion" then return Cfg.potionPrice(l.price, player:GetAttribute("Stage")) end
	return l.price
end
local lotsCache = {}
local function lotName(l): string
	if l.kind == "pass" then return (MonCfg.Passes[l.pass] and MonCfg.Passes[l.pass].name) or l.pass end
	if l.kind == "potion" then local d = potDef(l.potion); return d and d.name or (tostring(l.potion) .. " Potion") end
	if l.min >= 60 then return (l.min // 60) .. (l.min >= 120 and " Hours" or " Hour") .. " Skip" end
	return l.min .. " Min Skip"
end
local function buy(c)
	local l = c.lot
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("StallShopAction")
	if not rf then return end
	local ok, res = pcall(rf.InvokeServer, rf, "BuyDia", l.id)
	if ok and type(res) == "table" and res.ok then
		UISounds.play("purchase", 0.1)
		if res.kind == "pass" then toast(lotName(l) .. " unlocked!", "purple", "claim")
		elseif res.kind == "potion" then toast("+1 " .. lotName(l) .. "!", "green", "claim")
		else toast("+" .. NF.money(res.gain or 0) .. " Money!", "green", "claim") end
	else
		shake(c.btn.group or c.btn.root)
		local err = ok and type(res) == "table" and res.err
		local msg = err == "diamonds" and "Not enough Diamonds!" or (err == "soldout" and "Sold out! Wait for the restock" or (err == "owned" and "You already own it!" or "Can't buy right now"))
		toast(msg, "red", "deny")
	end
end
local function buildCards(lots)
	for _, c in cards do c.root:Destroy() end
	cards = {}
	local n = #lots
	-- ширина картки: 4–5 лотів — як було (214), 6 (скіпи + зілля + геймпас) — вужчі, щоб влізли у вікно
	local cw = math.min(CARD_W, math.floor((WIN_W - 80 - (n - 1) * CARD_GAP) / math.max(1, n)))
	local ch = CARD_H - 92
	local total = n * cw + (n - 1) * CARD_GAP
	local x0 = (WIN_W - total) / 2
	for i, l in lots do
		local x = x0 + (i - 1) * (cw + CARD_GAP)
		local pc = l.kind == "potion" and Cfg.potion(l.potion) or nil
		local pd = l.kind == "potion" and potDef(l.potion) or nil
		local col = pc and pc.col or (Cfg.RARITY[l.rarity] or Cfg.RARITY.Common)
		local root = frame(cardsHolder, x, CARD_Y, cw, CARD_H, nil, { BackgroundTransparency = 1, ZIndex = 4 })
		frame(root, 0, 10, cw, ch, BLACK, { BackgroundTransparency = 0.65, ZIndex = 4 })
		local card = frame(root, 0, 0, cw, ch, WHITE, { ZIndex = 5, ClipsDescendants = true })
		vgrad(card, { { 0, col[1] }, { 1, col[2] } }); stroke(card, INK, 5)
		-- фон як у SHOP: візерунок StyleA (studs) + тінь донизу + іконки товару, що падають
		local tile = pc and pc.tile or (Cfg.TILE[l.rarity] or "gray")
		local A = StyleA.ASSETS
		new("ImageLabel", { Name = "Pattern", BackgroundTransparency = 1, Image = A["stylea_tile_" .. tile] or A["stylea_tile_" .. tile .. "_half"] or A.stylea_tile_gray,
			ImageTransparency = 0.15, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(PATTERN_TILE, PATTERN_TILE), Size = UDim2.fromOffset(cw, ch), ZIndex = 1 }, card)
		local shade = frame(card, 0, 0, cw, ch, BLACK, { Name = "Shade", ZIndex = 1 })
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 0.6) }) }, shade)
		local rainIcon = l.kind == "pass" and ((MonCfg.Passes[l.pass] and MonCfg.Passes[l.pass].icon) or "") or (pd and pd.icon or SKIP_ICON)
		local clip = frame(card, 0, 0, cw, ch, nil, { Name = "Rain", BackgroundTransparency = 1, ZIndex = 2, ClipsDescendants = true })
		startRain(clip, rainIcon, cw, ch, 0.75)
		local gl = frame(card, 8, 8, cw - 16, 110, WHITE, { ZIndex = 3 })
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }) }, gl)
		fit(label(card, 10, 10, cw - 20, 30, 24, string.upper(l.rarity == "Pass" and "Rare Pass" or (l.kind == "potion" and "Potion" or l.rarity)), WHITE, 3, { ZIndex = 7 }), 24)
		local isz = math.min(140, cw - 40)
		if pd then -- зілля — 3D-модель (як у SHOP / інвентарі)
			local ic = new("ImageLabel", { BackgroundTransparency = 1, Image = pd.icon, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(cw / 2, 118), Size = UDim2.fromOffset(isz, isz), ZIndex = 6 }, card)
			ItemViewport.set(ic, "Pot_" .. pd.key, 1.12)
		else
			local icon = l.kind == "pass" and ((MonCfg.Passes[l.pass] and MonCfg.Passes[l.pass].icon) or "") or SKIP_ICON
			for _, m in { { 6, INK, 0.35, 5 }, { 0, WHITE, 0, 6 } } do
				new("ImageLabel", { BackgroundTransparency = 1, Image = icon, ImageColor3 = m[2], ImageTransparency = m[3], ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(cw / 2, 118 + m[1]), Size = UDim2.fromOffset(isz, isz), Rotation = -8, ZIndex = m[4] }, card)
			end
			if l.kind == "skip" then -- купюра поверх годинника (правий нижній кут), як TIME SKIPS у SHOP
				local cs = math.floor(isz * 0.58)
				for _, m in { { 4, INK, 0.35, 6 }, { 0, WHITE, 0, 7 } } do
					new("ImageLabel", { BackgroundTransparency = 1, Image = CASH_ICON, ImageColor3 = m[2], ImageTransparency = m[3], ScaleType = Enum.ScaleType.Fit,
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cw / 2 + isz * 0.32, 118 + isz * 0.32 + m[1]),
						Size = UDim2.fromOffset(cs, cs), Rotation = -8, ZIndex = m[4] }, card)
				end
			end
		end
		fit(label(card, 10, 196, cw - 20, 40, 32, lotName(l), WHITE, 4, { ZIndex = 7 }), 32)
		local gain = fit(label(card, 10, 240, cw - 20, 34, 28, "", C("b8ff5a"), 3.5, { ZIndex = 7 }), 28)
		local left = fit(label(card, 10, 300, cw - 20, 30, 24, "", WHITE, 3, { ZIndex = 7, FontFace = XBOLD }), 24)
		local btn = makeButton(root, 0, CARD_H - 80, cw, 70, { shadowDy = 6, color = "blue", icon = nil, z = 6 })
		local row = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cw / 2, 32),
			Size = UDim2.fromOffset(0, 60), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 9 }, btn.root)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		local bIcon = new("ImageLabel", { BackgroundTransparency = 1, Image = DIA_ICON, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(38, 38), LayoutOrder = 1, ZIndex = 9 }, row)
		local bText = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 34, TextColor3 = WHITE, Text = NF.full(l.price),
			Size = UDim2.fromOffset(0, 60), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, ZIndex = 10 }, row)
		stroke(bText, INK, 3.4, 0, true)
		local c = { root = root, lot = l, btn = btn, bIcon = bIcon, bText = bText, gain = gain, left = left }
		btn.onClick = function() buy(c) end
		cards[i] = c
	end
end
local function refreshCards()
	local raw = RS:FindFirstChild("StallShops") and RS.StallShops:GetAttribute("DiaLots")
	local ok, lots = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
	if not ok or type(lots) ~= "table" then lots = {} end
	local sig = {}
	for _, l in lots do table.insert(sig, l.id .. ":" .. l.key .. ":" .. l.max) end
	sig = table.concat(sig, ",")
	if sig ~= lotsCache.sig then lotsCache.sig = sig; buildCards(lots) end
	local dia = tonumber(player:GetAttribute("Diamonds")) or 0
	local rate = tonumber(player:GetAttribute("IncomePerMin")) or 0
	for i, l in lots do
		local c = cards[i]
		if c then
			c.lot = l
			if l.kind == "skip" then c.gain.Text = "+" .. NF.money(rate * l.min)
			elseif l.kind == "potion" then local d = potDef(l.potion); c.gain.Text = d and d.desc or ""
			else c.gain.Text = "Gamepass" end
			c.left.Text = l.stock .. " / " .. l.max .. " LEFT"
			local owned = l.kind == "pass" and player:GetAttribute("Pass_" .. l.pass) == true
			if owned then c.btn:setColor("gray"); c.bIcon.Visible = false; c.bText.Text = "OWNED"
			elseif l.stock <= 0 then c.btn:setColor("gray"); c.bIcon.Visible = false; c.bText.Text = "SOLD OUT"
			else
				local price = lotPrice(l)
				c.bIcon.Visible = true; c.bText.Text = NF.full(price)
				c.btn:setColor(dia >= price and "blue" or "gray")
			end
		end
	end
end

local function refresh()
	local st = RS:FindFirstChild("StallShops")
	local now = workspace:GetServerTimeNow()
	if mode == "dia" then
		local nx = st and tonumber(st:GetAttribute("DiaNextAt")) or 0
		timerText.Text = 'RESTOCK IN <font color="#8fe0ff">' .. fmtLeft(nx - now) .. "</font>"
		balText.Text = NF.full(tonumber(player:GetAttribute("Diamonds")) or 0)
		refreshCards()
	else
		local nx = st and tonumber(st:GetAttribute("EventNextAt")) or 0
		timerText.Text = 'NEW ITEMS IN <font color="#ff9ae0">' .. fmtLeft(nx - now) .. "</font>"
		balText.Text = NF.full(tonumber(player:GetAttribute("Diamonds")) or 0)
	end
end

-- ===== масштаб під екран, відкриття / закриття =====
local function fitWin() WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WIN_X, winY = WIN_Y, winW = WIN_W, winH = WIN_H }) end
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

local isOpen, dismissed, openShop = false, false, nil
local animToken = 0
local function setMode(m)
	mode = m
	local txt = m == "dia" and "DIAMONDS SHOP" or "EVENTS SHOP"
	title.Text = txt; titleShadow.Text = txt
	tIcon.Image = m == "dia" and DIA_ICON or EVENT_ICON; tIconS.Image = tIcon.Image
	cardsHolder.Visible = m == "dia"
	soon.Visible = m ~= "dia"
end
local function open(m)
	setMode(m)
	isOpen = true
	WindowManager.opened("StallShop")
	animToken += 1
	local my = animToken
	fitWin()
	lotsCache.sig = nil
	refresh()
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
closeBtn.onClick = function() dismissed = true; close() end
WindowManager.register("StallShop", function() return isOpen end, function() dismissed = true; close() end)
CAS:BindActionAtPriority("StallShopEsc", function(_, state)
	if state == Enum.UserInputState.Begin and isOpen then dismissed = true; close(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)

-- у колі якої лавки стоїть гравець
local function nearest(): (Model?, number)
	local shops = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Shops")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (shops and hrp) then return nil, math.huge end
	local best, bd = nil, math.huge
	for _, s in shops:GetChildren() do
		local rc = s:FindFirstChild("Ring") and s.Ring:FindFirstChild("RingCenter")
		if rc and rc:IsA("BasePart") then
			local d = rc.CFrame:PointToObjectSpace(hrp.Position)
			local dist = Vector2.new(d.X, d.Z).Magnitude
			if math.abs(d.Y) < 10 and dist < bd then best, bd = s, dist end
		end
	end
	return best, bd
end
while true do
	local ok, err = pcall(function()
		local s, dist = nearest()
		local inside = s and dist <= Rig.RING_R + ((isOpen or dismissed) and EXIT_PAD or 0)
		if not inside then dismissed = false end
		if inside and not dismissed then
			local m = s:GetAttribute("Shop") == "Events" and "event" or "dia"
			if not isOpen or openShop ~= s then openShop = s; open(m) else refresh() end
		elseif isOpen then
			close()
		end
	end)
	if not ok then warn("StallShopWindow: " .. tostring(err)) end
	task.wait(0.2)
end
