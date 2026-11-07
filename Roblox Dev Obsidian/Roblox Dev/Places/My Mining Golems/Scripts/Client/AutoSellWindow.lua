--!nonstrict
-- AutoSellWindow — вікно налаштувань AUTO SELL (29.10.2026). Відкривається кнопкою SETTINGS на картці Auto Sell табло плоту
--   (PlotBoard → UIEvents/AutoSellOpen), коли Auto Sell є (куплена картка на мапі або геймпас Auto Sell).
-- Де: StarterPlayer/StarterPlayerScripts/AutoSellWindow (LocalScript). Сервер — ServerScriptService/AutoSellService.
-- Що у вікні: головний перемикач AUTO SELL: ON / OFF (Set_AutoSell) і плитки предметів (руда й злитки поточної мапи, далі —
--   попередніх): лайм SELL — продається одразу, сіра KEEP — лишається в інвентарі (Set_AutoSellOff), помаранчева WORKSHOP —
--   руду забирає Auto Workshop на переплавку. Клік по плитці — перемкнути (Remotes/AutoSellAction "Item").
-- v2 (05.11.2026): кнопки SELL ALL / KEEP ALL, підказка-легенда, предмети згруповані за мапами (плашка MAP N · Назва),
--   на плитці — ціна за штуку й перемикач з двох половин SELL | KEEP (Remotes/AutoSellAction "All", bool — усе одразу).
-- Стиль — як вікна лавок (StallShopWindow): квадратне вікно зі studs, заголовок КАПСОМ з іконкою й переливом, червона X.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")

local Shared = RS:WaitForChild("Shared")
local Loc = require(Shared:WaitForChild("Loc"))
local Forge = require(Shared:WaitForChild("ForgeConfig"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CANVAS_W, CANVAS_H = 1286, 740
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1206, 650

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
	StyleA.studTile(studs, ox, oy, nx * CELL, ny * CELL, CELL, C("b3b8bf")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
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
-- ===== вікно AUTO SELL =====
local ICON_AS = "rbxassetid://110396437023647"
local LIME = C("d4ff3e")
local gui = new("ScreenGui", { Name = "AutoSellWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10, Enabled = true }, playerGui)
local backdrop = new("TextButton", { Name = "Backdrop", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK,
	BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, gui)
local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local _, content = windowFrame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, 1, 14)

-- заголовок: іконка (−8°, тінь) + AUTO SELL з переливом (рожевий, як картка Auto Sell)
local TITLE_IS = 150
local TITLE_ICX, TITLE_ICY = 56 + TITLE_IS / 2, 44
local TITLE_X = TITLE_ICX + TITLE_IS / 2 + 8
new("ImageLabel", { BackgroundTransparency = 1, Image = ICON_AS, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY + 9), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 3 }, pop)
new("ImageLabel", { BackgroundTransparency = 1, Image = ICON_AS, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 4 }, pop)
textAt(pop, TITLE_X, 50 + 9, 900, 104, "AUTO SELL", INK, 11, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, TITLE_X, 50, 900, 104, "AUTO SELL", WHITE, 10, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
do
	local P = { C("ffe0f6"), C("ff8ad8"), C("e83cb4"), C("ff8ad8") }
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
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })

-- верхній рядок (05.11.2026, v2 — інтуїтивніше): головний перемикач ON / OFF і масові кнопки SELL ALL / KEEP ALL;
-- під ними — підказка, що зараз відбувається
local master = makeButton(content, 40, 70, 330, 64, { shadowDy = 6, color = "green", text = "AUTO SELL: ON", textSize = 30, z = 4 })
local allSell = makeButton(content, 392, 70, 220, 64, { shadowDy = 6, color = "green", text = "SELL ALL", textSize = 26, z = 4 })
local allKeep = makeButton(content, 630, 70, 220, 64, { shadowDy = 6, color = "gray", text = "KEEP ALL", textSize = 26, z = 4 })
local hintBox = frame(content, 40, 148, WIN_W - 80, 48, C("14161a"), { BackgroundTransparency = 0.35, ZIndex = 4 })
corner(hintBox, 12); stroke(hintBox, INK, 4)
local hint = label(hintBox, 18, 0, WIN_W - 116, 48, 22, "", WHITE, 3, { ZIndex = 5, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, FontFace = XBOLD })
fit(hint, 22)

-- список предметів (прокрутка), згрупований за мапами (поточна — першою): плашка «MAP N · Назва» і плитки.
-- Плитка: 3D-іконка, назва, ORE / BAR / GEM, ціна за штуку, перемикач з двох половин SELL | KEEP (активна — кольорова);
-- клік по половині — саме цей стан, клік по плитці — перемкнути. Руду забирає Auto Workshop — помаранчева плашка WORKSHOP.
local LIST_X, LIST_Y, LIST_W, LIST_H = 40, 210, WIN_W - 80, WIN_H - 210 - 40
local list = new("ScrollingFrame", { Position = UDim2.fromOffset(LIST_X, LIST_Y), Size = UDim2.fromOffset(LIST_W, LIST_H), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, ScrollBarImageColor3 = C("2a2e35"), CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4 }, content)
local TILE_W, TILE_H, TGAP = 170, 232, 14
local HDR_H = 36
local COLS = math.floor((LIST_W - 10 + TGAP) / (TILE_W + TGAP))
local MAP_NAMES = { "Mossy Grotto", "Rusty Mine", "Crystal Depths", "Magma Caverns", "Frozen Abyss", "Void Core", "Map 7" }
local MUTED = C("8b939c")
local DARK = C("23272d")
local tiles = {} -- [key] = tile
local builtSig = ""

local function money(v: number): string
	v = math.floor(v + 0.5)
	for _, u in { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } } do
		if v >= u[1] then
			local x = v / u[1]
			return "$" .. (x >= 100 and string.format("%d", math.floor(x)) or (string.format("%.1f", x):gsub("%.0$", ""))) .. u[2]
		end
	end
	return "$" .. v
end
local function offSet(): { [string]: boolean }
	local set = {}
	local raw = player:GetAttribute("Set_AutoSellOff")
	if type(raw) == "string" and raw ~= "" then
		local ok, l = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(l) == "table" then for _, k in l do set[k] = true end end
	end
	return set
end
local function items(): { any }
	local st = math.clamp(tonumber(player:GetAttribute("Stage")) or 1, 1, Forge.MAX_STAGE)
	local out = {}
	for s = st, 1, -1 do -- спершу руда поточної мапи
		for _, o in Forge.STAGE_ORES[s] do
			table.insert(out, { key = "Ore_" .. o.key, name = o.key, kind = "ORE", ore = o, stage = s, price = o.price })
			if Forge.canSmelt(o) then
				table.insert(out, { key = "Bars_" .. o.key, name = Forge.productName(o.key), kind = (Forge.productOf(o.key) == "Cut" and "GEM" or "BAR"), ore = o, stage = s,
					price = o.price * Forge.BAR_MULT })
			end
		end
	end
	return out
end
local ev = RS:WaitForChild("Remotes"):WaitForChild("AutoSellAction")
local function setItem(key: string, sell: boolean)
	if (offSet()[key] == true) == not sell then return end -- уже так
	UISounds.play("tap", 0.08)
	ev:FireServer("Item", key, sell)
end
local function build()
	for _, c in list:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	tiles = {}
	local its = items()
	local st = tonumber(player:GetAttribute("Stage")) or 1
	local y, col, curStage = 4, 0, nil
	for _, it in its do
		if it.stage ~= curStage then
			if curStage ~= nil then y += TILE_H + TGAP end
			curStage = it.stage
			col = 0
			local hd = frame(list, 4, y, LIST_W - 22, HDR_H, C("14161a"), { BackgroundTransparency = 0.3, ZIndex = 5 })
			stroke(hd, INK, 3)
			frame(hd, 0, 0, 6, HDR_H, it.stage == st and LIME or MUTED, { ZIndex = 6 })
			label(hd, 18, 0, LIST_W - 60, HDR_H, 20, "MAP " .. it.stage .. " · " .. (MAP_NAMES[it.stage] or "") .. (it.stage == st and "  (current map)" or ""),
				it.stage == st and LIME or SUB_TXT, 2.5, { ZIndex = 6, TextXAlignment = Enum.TextXAlignment.Left })
			y += HDR_H + 10
		elseif col >= COLS then
			col = 0
			y += TILE_H + TGAP
		end
		local x = 4 + col * (TILE_W + TGAP)
		col += 1
		local root = new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(TILE_W, TILE_H),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5 }, list)
		vgrad(root, { { 0, "2e333a" }, { 1, "16191d" } })
		stroke(root, INK, 4)
		local ring = frame(root, 5, 5, TILE_W - 10, TILE_H - 10, nil, { BackgroundTransparency = 1, ZIndex = 5 })
		local rs = stroke(ring, LIME, 4)
		local ic = new("ImageLabel", { BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(TILE_W / 2, 58), Size = UDim2.fromOffset(84, 84), ZIndex = 6 }, root)
		pcall(ItemViewport.set, ic, it.key, 1.25)
		fit(label(root, 8, 102, TILE_W - 16, 28, 23, it.name, WHITE, 3, { ZIndex = 7 }), 23)
		label(root, 8, 128, TILE_W - 16, 18, 15, it.kind, SUB_TXT, 2, { ZIndex = 7, FontFace = XBOLD })
		label(root, 8, 148, TILE_W - 16, 22, 19, money(it.price) .. " each", C("ffd23a"), 2.5, { ZIndex = 7 })
		-- перемикач SELL | KEEP
		local SW_W, SW_H = TILE_W - 24, 40
		local sw = frame(root, 12, TILE_H - SW_H - 14, SW_W, SW_H, C("101215"), { ZIndex = 7 })
		stroke(sw, INK, 3)
		local half = SW_W / 2
		local sB = new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(half, SW_H),
			BackgroundColor3 = LIME, BorderSizePixel = 0, ZIndex = 8 }, sw)
		local sT = label(sB, 0, 0, half, SW_H, 18, "SELL", WHITE, 2.5, { ZIndex = 9 })
		local kB = new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(half, 0), Size = UDim2.fromOffset(half, SW_H),
			BackgroundColor3 = DARK, BorderSizePixel = 0, ZIndex = 8 }, sw)
		local kT = label(kB, 0, 0, half, SW_H, 18, "KEEP", MUTED, 2.5, { ZIndex = 9 })
		frame(sw, half - 1, 0, 2, SW_H, INK, { ZIndex = 9 })
		local ws = frame(root, 12, TILE_H - SW_H - 14, SW_W, SW_H, C("ffb15c"), { ZIndex = 10, Visible = false })
		stroke(ws, INK, 3)
		fit(label(ws, 4, 0, SW_W - 8, SW_H, 18, "WORKSHOP", WHITE, 2.5, { ZIndex = 11 }), 18)
		local t = { root = root, it = it, rs = rs, ic = ic, sB = sB, sT = sT, kB = kB, kT = kT, ws = ws }
		sB.MouseButton1Click:Connect(function() setItem(it.key, true) end)
		kB.MouseButton1Click:Connect(function() setItem(it.key, false) end)
		root.MouseButton1Click:Connect(function() setItem(it.key, offSet()[it.key] == true) end)
		tiles[it.key] = t
	end
	list.CanvasSize = UDim2.fromOffset(0, y + TILE_H + 12)
end
local function refresh()
	local st = tonumber(player:GetAttribute("Stage")) or 1
	local sig = tostring(st)
	if sig ~= builtSig then builtSig = sig; build() end
	local on = player:GetAttribute("Set_AutoSell") ~= false
	master:setColor(on and "green" or "red")
	if master.setText then master:setText(on and "AUTO SELL: ON" or "AUTO SELL: OFF") end
	local ws = player:GetAttribute("AutoWorkshopOn") == true
	local off = offSet()
	if on then
		-- 07.11.2026: цілі рядки через Shared/Loc (автопереклад не ловить склеєний текст із тегами)
		hint.AutoLocalize = false
		hint.Text = Loc.t("<font color=\"#D4FF3E\">SELL</font> — sells the moment you pick it up.  <font color=\"#B9C0C8\">KEEP</font> — stays in your inventory.")
			.. (ws and ("  " .. Loc.t("<font color=\"#FFB15C\">WORKSHOP</font> — Auto Workshop smelts it.")) or "")
	else
		hint.AutoLocalize = false
		hint.Text = Loc.t("<font color=\"#FF6B5E\">Auto Sell is OFF</font> — nothing sells by itself. Turn it ON to sell items marked SELL.")
	end
	for key, t in tiles do
		local held = ws and t.it.kind == "ORE" and Forge.canSmelt(t.it.ore) and t.it.stage == st
		local sell = not off[key]
		t.ws.Visible = held
		t.sB.BackgroundColor3 = sell and (on and LIME or C("7d9433")) or DARK
		t.sT.TextColor3 = sell and WHITE or MUTED
		t.kB.BackgroundColor3 = sell and DARK or C("8a929c")
		t.kT.TextColor3 = sell and MUTED or WHITE
		t.rs.Color = held and C("ffb15c") or LIME
		t.rs.Transparency = ((sell and on) or held) and 0 or 1
		t.ic.ImageTransparency = (sell or held) and 0 or 0.35
	end
end
allSell.onClick = function() UISounds.play("tap", 0.08); ev:FireServer("All", true) end
allKeep.onClick = function() UISounds.play("tap", 0.08); ev:FireServer("All", false) end

-- ===== масштаб, відкриття / закриття =====
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

local isOpen, animToken = false, 0
local function open()
	if isOpen then return end
	isOpen = true
	WindowManager.opened("AutoSell")
	animToken += 1
	local my = animToken
	fitWin()
	builtSig = ""
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
closeBtn.onClick = function() close() end
backdrop.MouseButton1Click:Connect(close)
master.onClick = function() ev:FireServer("Master", player:GetAttribute("Set_AutoSell") == false) end
WindowManager.register("AutoSell", function() return isOpen end, close)
CAS:BindActionAtPriority("AutoSellEsc", function(_, state)
	if state == Enum.UserInputState.Begin and isOpen then close(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
player.AttributeChanged:Connect(function(a)
	if isOpen and (a == "Set_AutoSell" or a == "Set_AutoSellOff" or a == "AutoWorkshopOn" or a == "Stage") then refresh() end
end)

-- відкриття: кнопка SETTINGS на картці Auto Sell (PlotBoard) → UIEvents/AutoSellOpen
local uiEvents = RS:FindFirstChild("UIEvents") or new("Folder", { Name = "UIEvents" }, RS)
local openEv = uiEvents:FindFirstChild("AutoSellOpen") or new("BindableEvent", { Name = "AutoSellOpen" }, uiEvents)
openEv.Event:Connect(function() if isOpen then close() else open() end end)
