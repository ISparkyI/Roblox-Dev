--!nonstrict
-- DailyWindow — вікно DAILY REWARDS (щоденні нагороди, 29.10.2026). Відкривається кнопкою Daily під Rebirth у HUD
--   (UIEvents/HUDButton "Daily"). Сервер — ServerScriptService/DailyService, числа й генерація — Shared/DailyConfig.
-- Де: StarterPlayer/StarterPlayerScripts/DailyWindow (LocalScript). Стиль — як вікна лавок: квадратне вікно зі studs, заголовок КАПСОМ
--   з іконкою календаря й переливом, червона X.
-- Що у вікні: стрік (днів підряд), таймер до наступної нагороди (08:00 за Києвом), кнопка CLAIM (зелена, коли сьогоднішня ще не взята)
--   або SKIP DAY · R$ 19 / 69 (фіолетова: наступна нагорода одразу, Developer Product DailyConfig.SKIP / SKIP7), і календар з 31
--   наступних нагород (DAY n): відкрито лише перші Cfg.VISIBLE (7), решта — затемнені «?»; кожен 7-й день —
--   золотий. Забрали — список зсувається на 1.
-- Плитки клікабельні (звук hover + збільшення): CLAIM (лаймова рамка) — забрати; SKIP (фіолетова, наступна після
--   доступної) — покупка скіпу; дальші — відмова (труситься, червона рамка, Deny).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = RS:WaitForChild("Shared")
local Cfg = require(Shared:WaitForChild("DailyConfig"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local CurrencyFly = require(Shared:WaitForChild("CurrencyFly"))
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
-- ===== іконки нагород =====
local ICON = {
	skip = "rbxassetid://76478987044650", cash = "rbxassetid://103015355952567", diamonds = "rbxassetid://126442692946356",
	tickets = "rbxassetid://85299808396483", luckroll = "rbxassetid://124578338510174", luckroll99 = "rbxassetid://124578338510174", robux = "rbxassetid://139687766069559",
}
local function potIcon(key: string): string
	for _, d in Items.POTIONS do if d.key == key then return d.icon end end
	return ""
end
local LIME = C("d4ff3e")
local GOLD = C("ffd23a")
local VIOLET = C("cf9bff")
local DENY_RED = C("e5484d")
local VISIBLE = Cfg.VISIBLE or 7

-- ===== вікно =====
local gui = new("ScreenGui", { Name = "DailyWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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

-- заголовок: календар (−8°, тінь) + DAILY REWARDS з переливом (теплий жовто-помаранчевий)
local TITLE_IS = 150
local TITLE_ICX, TITLE_ICY = 56 + TITLE_IS / 2, 44
local TITLE_X = TITLE_ICX + TITLE_IS / 2 + 8
new("ImageLabel", { BackgroundTransparency = 1, Image = Cfg.ICON, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY + 9), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 3 }, pop)
new("ImageLabel", { BackgroundTransparency = 1, Image = Cfg.ICON, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(TITLE_ICX, TITLE_ICY), Size = UDim2.fromOffset(TITLE_IS, TITLE_IS), Rotation = -8, ZIndex = 4 }, pop)
textAt(pop, TITLE_X, 50 + 9, 900, 104, "DAILY REWARDS", INK, 11, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, TITLE_X, 50, 900, 104, "DAILY REWARDS", WHITE, 10, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
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
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })

-- верхній рядок: стрік, таймер, кнопка CLAIM / SKIP
local function darkBox(x, w)
	local b = frame(content, x, 74, w, 64, INK, { BackgroundTransparency = 0.35, ZIndex = 4 })
	corner(b, 12); stroke(b, INK, 4)
	return b
end
local streakBox = darkBox(40, 330)
new("ImageLabel", { BackgroundTransparency = 1, Image = Cfg.ICON, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(52, 52), ZIndex = 5 }, streakBox)
local streakText = label(streakBox, 72, 0, 250, 64, 30, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, RichText = true })
local timerBox = darkBox(390, 430)
local timerText = label(timerBox, 18, 0, 400, 64, 30, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, RichText = true })
local actBtn = makeButton(content, 840, 74, WIN_W - 40 - 840, 64, { shadowDy = 6, color = "green", text = "", textSize = 30, z = 4 })
local actRow = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((WIN_W - 40 - 840) / 2, 29),
	Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 9 }, actBtn.root)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, actRow)
local actText = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 30, TextColor3 = WHITE, Text = "",
	Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 1, ZIndex = 10 }, actRow)
stroke(actText, INK, 3.4, 0, true)
local actIcon = new("ImageLabel", { BackgroundTransparency = 1, Image = ICON.robux, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(34, 34), LayoutOrder = 2, ZIndex = 10 }, actRow)
local actPrice = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 30, TextColor3 = WHITE, Text = "",
	Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 3, ZIndex = 10 }, actRow)
stroke(actPrice, INK, 3.4, 0, true)

-- календар: 31 плитка, 8 × 4
local COLS, TG = 8, 12
local GX, GY, GW, GH = 40, 156, WIN_W - 80, WIN_H - 156 - 40
local TW = math.floor((GW - (COLS - 1) * TG) / COLS)
local TH = math.floor((GH - 3 * TG) / 4)
local grid = frame(content, GX, GY, GW, GH, nil, { BackgroundTransparency = 1, ZIndex = 4 })
local tiles = {}
local builtFor = nil
local claimable, onTile -- нижче

local function rewardIcon(parent, rw, cx, cy, s)
	local function img(id, x, y, size, z, rot)
		for _, m in { { 4, INK, 0.35, z }, { 0, WHITE, 0, z + 1 } } do
			new("ImageLabel", { BackgroundTransparency = 1, Image = id, ImageColor3 = m[2], ImageTransparency = m[3], ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y + m[1]), Size = UDim2.fromOffset(size, size), Rotation = rot or -8, ZIndex = m[4] }, parent)
		end
	end
	if rw.kind == "golem" then
		local k = ItemViewport.golemKey(rw.key, rw.cls)
		local ic = new("ImageLabel", { BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s * 0.85, s * 0.85), ZIndex = 7 }, parent)
		if k then ItemViewport.set(ic, k) end
	elseif rw.kind == "skip" then
		img(ICON.skip, cx, cy, s, 6)
		img(ICON.cash, cx + s * 0.3, cy + s * 0.3, s * 0.55, 8)
	elseif rw.kind == "potion" then img(potIcon(rw.key), cx, cy, s, 6)
	elseif rw.kind == "potionpack" then
		img(potIcon("Luck"), cx - s * 0.22, cy, s * 0.75, 6, -14)
		img(potIcon("Money"), cx + s * 0.22, cy, s * 0.75, 6, 10)
	else img(ICON[rw.kind] or "", cx, cy, s, 6) end
end

-- закрита плитка: затемнення + великий «?» (з тінню, −8°) + «???»
local function mystery(t, seventh)
	frame(t, 0, 0, TW, TH, INK, { BackgroundTransparency = 0.45, ZIndex = 6 })
	textAt(t, 0, TH / 2 + 6, TW, 62, "?", INK, 0, { Rotation = -8, ZIndex = 7, TextTransparency = 0.35 })
	textAt(t, 0, TH / 2 + 2, TW, 62, "?", seventh and GOLD or WHITE, 4, { Rotation = -8, ZIndex = 8 })
	fit(label(t, 6, TH - 26, TW - 12, 22, 16, "???", SUB_TXT, 2.4, { ZIndex = 10, FontFace = XBOLD }), 16)
end

local function stateKey(): string
	return tostring(player:GetAttribute("DailySeed")) .. ":" .. tostring(player:GetAttribute("DailyIdx")) .. ":" .. tostring(claimable())
end

local function build()
	for _, t in tiles do t:Destroy() end
	tiles = {}
	local seed = tonumber(player:GetAttribute("DailySeed")) or 1
	local idx = tonumber(player:GetAttribute("DailyIdx")) or 0
	local avail = claimable()
	local claimI, skipI = avail and 1 or nil, avail and 2 or 1
	for i = 1, Cfg.SHOW do
		local n = idx + i
		local rw = Cfg.reward(seed, n)
		local col, row = (i - 1) % COLS, (i - 1) // COLS
		local x, y = col * (TW + TG) + TW / 2, row * (TH + TG) + TH / 2
		local seventh = Cfg.isSeventh(n)
		local hidden = i > VISIBLE
		local t = frame(grid, x, y, TW, TH, WHITE, { AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5, ClipsDescendants = true })
		local sc = new("UIScale", {}, t)
		vgrad(t, seventh and { { 0, "ffe27a" }, { 1, "b07a06" } } or { { 0, "3a4049" }, { 1, "1b1e23" } })
		stroke(t, INK, 4)
		if seventh then
			new("ImageLabel", { BackgroundTransparency = 1, Image = StyleA.ASSETS.stylea_tile_yellow or StyleA.ASSETS.stylea_tile_yellow_half or "",
				ImageTransparency = 0.2, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(24, 24), Size = UDim2.fromScale(1, 1), ZIndex = 5 }, t)
		end
		local head, headCol = "DAY " .. n, WHITE
		if i == claimI then head, headCol = "CLAIM · DAY " .. n, LIME
		elseif i == skipI then head, headCol = "SKIP · DAY " .. n, VIOLET end
		if i == claimI or i == skipI then
			local ring = frame(t, 4, 4, TW - 8, TH - 8, nil, { BackgroundTransparency = 1, ZIndex = 9 })
			stroke(ring, headCol, 4)
		end
		fit(label(t, 6, 4, TW - 12, 20, 17, head, headCol, 2.4, { ZIndex = 10 }), 17)
		if hidden then
			mystery(t, seventh)
		else
			rewardIcon(t, rw, TW / 2, TH / 2 + 2, math.min(TH - 50, 58))
			fit(label(t, 6, TH - 26, TW - 12, 22, 16, Cfg.label(rw, MonCfg), seventh and WHITE or SUB_TXT, 2.4, { ZIndex = 10, FontFace = XBOLD }), 16)
		end
		-- наведення: звук + збільшення (плитка поверх сусідів); клік — CLAIM / SKIP / відмова
		local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, t)
		hit.MouseEnter:Connect(function()
			UISounds.play("hover", 0.04)
			t.ZIndex = 6
			tween(sc, 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1.08 })
		end)
		hit.MouseLeave:Connect(function()
			t.ZIndex = 5
			tween(sc, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
		end)
		hit.Activated:Connect(function()
			if onTile then onTile(i == claimI and "claim" or (i == skipI and "skip" or "deny"), t, n) end
		end)
		table.insert(tiles, t)
	end
	builtFor = stateKey()
end

local function fmtLeft(sec: number): string
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
end
claimable = function(): boolean
	local day = tonumber(RS:GetAttribute("DailyDay"))
	return day ~= nil and (tonumber(player:GetAttribute("DailyLast")) or -1) < day
end
local function refresh()
	local seed = tonumber(player:GetAttribute("DailySeed")) or 1
	local idx = tonumber(player:GetAttribute("DailyIdx")) or 0
	if builtFor ~= stateKey() then build() end
	local streak = tonumber(player:GetAttribute("DailyStreak")) or 0
	streakText.Text = 'STREAK: <font color="#FFD23A">' .. streak .. (streak == 1 and " DAY" or " DAYS") .. "</font>"
	local can = claimable()
	if can then
		timerText.Text = 'REWARD <font color="#D4FF3E">READY!</font>'
		actBtn:setColor("green"); actText.Text = "CLAIM!"; actIcon.Visible = false; actPrice.Text = ""
	else
		local nx = tonumber(RS:GetAttribute("DailyNextAt")) or 0
		timerText.Text = 'NEXT IN <font color="#FFD23A">' .. fmtLeft(nx - workspace:GetServerTimeNow()) .. "</font>"
		local pr = Cfg.skipProduct(idx + 1)
		actBtn:setColor("purple"); actText.Text = "SKIP DAY"; actIcon.Visible = true; actPrice.Text = tostring(pr.robux)
	end
end

local busy = false
local function doClaim(tile)
	if busy then return end
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("DailyAction")
	if not rf then return end
	busy = true
	local ok, res = pcall(rf.InvokeServer, rf, "Claim")
	busy = false
	if ok and type(res) == "table" and res.ok then
		UISounds.play("purchase", 0.1)
	else
		UISounds.play("deny", 0.08)
		if tile then shake(tile) end
	end
	refresh()
end
-- скіп за Robux; n — номер плитки SKIP (ціна 69 R$, якщо це 7-й день)
local function doSkip(n: number)
	local pr = Cfg.skipProduct(n)
	if pr.id ~= 0 then pcall(function() MarketplaceService:PromptProductPurchase(player, pr.id) end) end
end
onTile = function(kind: string, tile: GuiObject, n: number)
	if kind == "claim" then
		UISounds.play("tap")
		doClaim(tile)
	elseif kind == "skip" then
		UISounds.play("tap")
		doSkip(n)
	else
		-- ще рано: трус, червона рамка, Deny
		UISounds.play("deny", 0.08)
		shake(tile)
		local s = tile:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = DENY_RED
			task.delay(0.35, function() if s.Parent then s.Color = INK end end)
		end
	end
end
actBtn.onClick = function()
	if claimable() then doClaim(nil) else doSkip((tonumber(player:GetAttribute("DailyIdx")) or 0) + 1) end
end

-- тост з отриманою нагородою (DailyGot ставить сервер і при CLAIM, і при SKIP);
-- тікети / діаманти летять до лічильника в HUD (Shared/CurrencyFly) з плитки, яку щойно забрали (вона ще перша —
-- список перебудовується пізніше, у refresh); вікно закрите — з центру екрана.
local FLY_ATTR = { tickets = "Tickets", diamonds = "Diamonds" }
player:GetAttributeChangedSignal("DailyGot"):Connect(function()
	local ok, rw = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("DailyGot") or "")
	if not (ok and type(rw) == "table") then return end
	toast("Day " .. tostring(rw.day or "") .. ": +" .. Cfg.label(rw, MonCfg) .. "!", "green", "claim")
	local attr = FLY_ATTR[rw.kind]
	if attr then
		local from = modalRoot.Visible and tiles[1] and tiles[1].Parent and tiles[1] or nil
		pcall(CurrencyFly.fly, attr, from, tonumber(rw.n) or 1)
	end
end)

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
	WindowManager.opened("Daily")
	animToken += 1
	local my = animToken
	fitWin()
	builtFor = nil
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
WindowManager.register("Daily", function() return isOpen end, close)
CAS:BindActionAtPriority("DailyEsc", function(_, state)
	if state == Enum.UserInputState.Begin and isOpen then close(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)

local uiEvents = RS:FindFirstChild("UIEvents") or new("Folder", { Name = "UIEvents" }, RS)
local hudEvent = uiEvents:FindFirstChild("HUDButton") or new("BindableEvent", { Name = "HUDButton" }, uiEvents)
hudEvent.Event:Connect(function(key) if key == "Daily" then if isOpen then close() else open() end end end)

task.spawn(function()
	while true do
		if isOpen then pcall(refresh) end
		task.wait(0.5)
	end
end)
