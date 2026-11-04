--!nonstrict
-- LeaderboardClient — екрани лідербордів у центрі зали (Workspace/Cave/Hub/Leaderboards/<key>/Screen) і на маркеті.
-- Де: StarterPlayer/StarterPlayerScripts/LeaderboardClient (LocalScript). Дані — атрибут Data (JSON [{u, n, v}]) і NextAt на моделі
-- табла (ставить StatsService). Набір табел, кольори, формат чисел — Shared/HubConfig.BOARDS (печера) / MARKET_BOARDS (маркет).
-- Екран (SurfaceGui у PlayerGui з Adornee — працює прокрутка), полотно 650 × 850:
--   шапка кольору табла зі studs (іконка, заголовок з переливом, підпис, таймер оновлення), список 1–100 з прокруткою
--   (03.11.2026: без п'єдесталу топ-3 — місця 1 / 2 / 3 лише виділені кольором рядка: золото / срібло / бронза), внизу — місце й значення гравця.
-- Маркет (HubConfig.isMarket): табла Marketplace/Floor/<model>/Screen (бік — атрибут Face), по центру — екран покупки пакетів тікетів
--   (HubConfig.TICKETS_BOARD; MonetizationConfig.TicketProducts, як у SHOP → TICKETS; клік — вікно покупки Roblox).
--   Четверте табло — RECENT TRADES (HubConfig.tradesBoard): останні 100 угод цього сервера з атрибута Trades (MarketServerService.LogTrade):
--   картки: 3D-голем ліворуч, назва з переливом кольору мутації, рідкість · клас, «продавець → покупець» (ніки), ціна й час.
-- Екран будується, коли камера ближче BUILD_AT, і прибирається далі DROP_AT.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = RS:WaitForChild("Shared")
local HubCfg = require(Shared:WaitForChild("HubConfig"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local MutationText = require(Shared:WaitForChild("MutationText"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local MARKET = HubCfg.isMarket()

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local PW, PH = 650, 850
local BUILD_AT, DROP_AT = 200, 260
local A = StyleA.ASSETS or {}
local TILES = { green = A.stylea_tile_green, blue = A.stylea_tile_blue_half, pink = A.stylea_tile_red, yellow = A.stylea_tile_yellow_half,
	orange = A.stylea_tile_orange_half, purple = A.stylea_tile_purple_half, red = A.stylea_tile_red }
local ICONS = {
	Money = "rbxassetid://103015355952567", Rolls = "rbxassetid://123138472161660",
	Donators = "rbxassetid://139687766069559", Playtime = "rbxassetid://76478987044650",
	Income = "rbxassetid://103015355952567", BestRoll = "rbxassetid://120776574619004",
	Gifters = "rbxassetid://139687766069559", Bosses = "rbxassetid://111200556390804",
	MarketBuys = "rbxassetid://91791061262477", MarketSales = "rbxassetid://103015355952567",
}
local ROBUX = "rbxassetid://139687766069559"
local TICKET = "rbxassetid://85299808396483"
-- текст бонусу за місце (HubConfig.PERK_TIERS): «+50% Money»
local function perkText(def, rank: number?): string
	if not def.tier then return "" end
	local pct = HubCfg.perkPct(def.tier, rank)
	if pct <= 0 then return "" end
	return "+" .. pct .. "% " .. (HubCfg.PERK_NAMES[def.perk] or "")
end
local MEDAL = {
	{ fill = "ffd84a", fill2 = "e09400", ring = "fff1a8" }, -- золото
	{ fill = "dfe6ee", fill2 = "8d9aab", ring = "ffffff" }, -- срібло
	{ fill = "ffaa6a", fill2 = "b8571f", ring = "ffd2b0" }, -- бронза
}

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
local function stroke(o, color, th, contextual)
	return new("UIStroke", { Color = color, Thickness = th, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function vgrad(o, a, b) return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(a), C(b)) }, o) end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6 }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, true) end
	return t
end
-- текст, що зменшується, якщо не влазить (імена, числа)
local function fitLabel(parent, x, y, w, h, maxSize, text, color, sw, props)
	local t = label(parent, x, y, w, h, maxSize, text, color, sw, props)
	t.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 10 }, t)
	return t
end
local function avatar(parent, x, y, s, uid, ring)
	local holder = frame(parent, x, y, s, s, C("2a2e36"), { ZIndex = 5 })
	corner(holder, UDim.new(0.5, 0))
	stroke(holder, ring or INK, math.max(3, s * 0.05))
	local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6, ScaleType = Enum.ScaleType.Crop,
		Image = (uid and uid > 0) and ("rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=150&h=150") or "" }, holder)
	corner(img, UDim.new(0.5, 0))
	return holder, img
end

local function fmtValue(kind: string, v: number): string
	v = math.floor(tonumber(v) or 0)
	if kind == "money" then return NF.money(v)
	elseif kind == "robux" then return "R$ " .. NF.short(v)
	elseif kind == "income" then return NF.money(v) .. "/min"
	elseif kind == "odds" then return "1 in " .. NF.short(v)
	elseif kind == "time" then
		local h, m = v // 3600, (v % 3600) // 60
		if h >= 1 then return string.format("%dh %02dm", h, m) end
		return string.format("%dm", m)
	end
	return NF.short(v)
end

-- SurfaceGui на екрані: полотно cw × ch, по центру грані (масштаб — щоб полотно вкрило всю грань)
local function surface(name: string, screen: BasePart, cw: number, ch: number): (SurfaceGui, Frame)
	local face = Enum.NormalId[screen:GetAttribute("Face") or "Front"] or Enum.NormalId.Front
	-- атрибут Inset (стади) — відступ від країв грані, якщо рамка табла накриває екран (Selling Info — заокруглені кути)
	local inset = tonumber(screen:GetAttribute("Inset")) or 0
	local ppx = math.max(cw / (screen.Size.X - 2 * inset), ch / (screen.Size.Y - 2 * inset))
	local g = new("SurfaceGui", { Name = name, Adornee = screen, Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = ppx, LightInfluence = 0, Brightness = 1.1,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = DROP_AT + 40 }, playerGui)
	local root = frame(g, math.floor((screen.Size.X * ppx - cw) / 2), math.floor((screen.Size.Y * ppx - ch) / 2), cw, ch, C("1b1e25"), { ClipsDescendants = true })
	return g, root
end

-- шапка табла: колір, studs, іконка, заголовок з переливом, підпис і рядок таймера
local function header(root, cw, def, hh)
	local head = frame(root, 0, 0, cw, hh, WHITE, { ZIndex = 2, ClipsDescendants = true })
	vgrad(head, def.accent, def.accent2)
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TILES[def.tile] or "", ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 2 }, head)
	frame(head, 0, 0, cw, 10, WHITE, { BackgroundTransparency = 0.6, ZIndex = 3 })
	frame(root, 0, hh, cw, 6, INK, { ZIndex = 4 })
	new("ImageLabel", { BackgroundTransparency = 1, Image = def.icon or ICONS[def.key] or "", ImageColor3 = INK, ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(20, 22), Size = UDim2.fromOffset(100, 100), Rotation = -8, ZIndex = 4 }, root)
	new("ImageLabel", { BackgroundTransparency = 1, Image = def.icon or ICONS[def.key] or "", ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(100, 100), Rotation = -8, ZIndex = 5 }, root)
	local title = label(root, 130, 18, cw - 150, 64, 58, def.title, WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
	local tg = new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C("e9eef4")) }, title)
	label(root, 132, 78, cw - 150, 28, 24, def.sub, WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 6 })
	local timer = label(root, 132, 104, cw - 150, 22, 18, "", C("f4f7fb"), 2.5, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 6, TextTransparency = 0.1 })
	return title, tg, timer
end

-- ===== одне табло-лідерборд =====
local function build(model: Model, def, screen: BasePart)
	local accent = C(def.accent)
	local g, root = surface("Leaderboard_" .. def.key, screen, PW, PH)
	vgrad(root, "262a33", "121419")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TILES[def.tile] or A.stylea_tile_gray or "", ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 1 }, root)
	local title, tg, timer = header(root, PW, def, 132)

	-- список 1–100 (місця 1–3 — кольорові рядки)
	local LY, LH = 152, 614
	local listBg = frame(root, 14, LY, PW - 28, LH, C("0e1014"), { BackgroundTransparency = 0.25, ZIndex = 3 })
	corner(listBg, 12); stroke(listBg, INK, 4)
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(20, LY + 6), Size = UDim2.fromOffset(PW - 40, LH - 12), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = accent, CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4 }, root)
	new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, list)
	local empty = label(root, 20, LY + LH / 2 - 20, PW - 40, 40, 26, "No players yet", C("9aa3ad"), 3, { ZIndex = 6, FontFace = XBOLD })

	-- низ: місце гравця
	local foot = frame(root, 14, 780, PW - 28, 58, WHITE, { ZIndex = 3 })
	corner(foot, 12); stroke(foot, INK, 4); vgrad(foot, def.accent, def.accent2)
	avatar(foot, 10, 7, 44, player.UserId, INK)
	local fRank = label(foot, 64, 0, 170, 58, 30, "YOU", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
	local fPerk = fitLabel(foot, 214, 8, 190, 42, 22, "", WHITE, 3, { ZIndex = 7 })
	local fVal = fitLabel(foot, 404, 6, PW - 28 - 418, 46, 32, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })

	local RW = PW - 56
	local B = { gui = g, screen = screen, model = model, rows = {}, timer = timer, title = title, tg = tg }
	function B.render()
		local raw = model:GetAttribute("Data")
		local ok, data = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
		if not ok or type(data) ~= "table" then data = {} end
		for _, r in B.rows do r:Destroy() end
		B.rows = {}
		local myRank = nil
		for i, e in data do if e.u == player.UserId then myRank = i end end
		for i, e in data do
			local mine = e.u == player.UserId
			local md = MEDAL[i]
			local rh = md and 54 or 46
			local row = new("Frame", { Size = UDim2.fromOffset(RW, rh), BackgroundColor3 = md and WHITE or (mine and accent or C("ffffff")),
				BackgroundTransparency = md and 0 or (mine and 0.55 or (i % 2 == 0 and 0.94 or 0.98)), BorderSizePixel = 0, LayoutOrder = i, ZIndex = 5 }, list)
			corner(row, 8)
			if md then
				vgrad(row, md.fill, md.fill2)
				stroke(row, mine and accent or INK, 3)
				-- місце — круглий значок кольору медалі
				local badge = frame(row, 8, (rh - 40) / 2, 40, 40, INK, { ZIndex = 6 })
				corner(badge, UDim.new(0.5, 0))
				local bIn = frame(badge, 3, 3, 34, 34, WHITE, { ZIndex = 7 })
				corner(bIn, UDim.new(0.5, 0)); vgrad(bIn, md.ring, md.fill)
				label(bIn, 0, 0, 34, 34, 22, tostring(i), WHITE, 3, { ZIndex = 8 })
			else
				if mine then stroke(row, accent, 2) end
				label(row, 4, 0, 54, rh, 22, "#" .. i, C("c9d1da"), 2.5, { ZIndex = 6 })
			end
			local as = md and 42 or 36
			avatar(row, 60, (rh - as) / 2, as, e.u, INK)
			local perk = md and perkText(def, i) or ""
			local nameW = perk ~= "" and 200 or 290
			fitLabel(row, 112, 4, nameW, rh - 8, md and 26 or 22, tostring(e.n), WHITE, md and 3 or 2.5,
				{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, FontFace = md and HEAVY or XBOLD })
			if perk ~= "" then fitLabel(row, 316, 10, 110, rh - 20, 18, perk, WHITE, 2.5, { ZIndex = 6 }) end
			fitLabel(row, 420, 4, RW - 432, rh - 8, md and 28 or 24, fmtValue(def.fmt, e.v), md and WHITE or accent, md and 3.5 or 2.5,
				{ TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 })
			table.insert(B.rows, row)
		end
		empty.Visible = #data == 0
		local mv = tonumber(player:GetAttribute(def.stat)) or 0
		fRank.Text = "YOU  " .. (myRank and ("#" .. myRank) or ("#" .. HubCfg.LB_TOP .. "+"))
		fPerk.Text = def.tier and (myRank and perkText(def, myRank) or ("Top 100: " .. perkText(def, 4))) or ""
		fVal.Text = fmtValue(def.fmt, (myRank and data[myRank].v) or mv)
	end
	model:GetAttributeChangedSignal("Data"):Connect(B.render)
	player:GetAttributeChangedSignal(def.stat):Connect(function() if not B.gui.Parent then return end B.render() end)
	B.render()
	return B
end

-- ===== маркет: табло покупки пакетів тікетів (як SHOP → TICKETS) =====
local TICKET_DEF = { key = "Tickets", title = "TICKETS", sub = "Buy Tickets with Robux", accent = "ffd23a", accent2 = "ff9a1f", tile = "yellow", icon = TICKET }
local TONES = { { "ffe27a", "f5b616", "yellow" }, { "ffb15c", "f07a1e", "orange" }, { "ff8fc8", "e0408e", "red" } }
local function buildTickets(model: Model, screen: BasePart)
	local TW = 760
	local TH = math.floor(TW * screen.Size.Y / screen.Size.X)
	local g, root = surface("TicketsBoard", screen, TW, TH)
	vgrad(root, "262a33", "121419")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = A.stylea_tile_gray or "", ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 1 }, root)
	local title, tg, timer = header(root, TW, TICKET_DEF, 132)
	timer.Text = "Tap a pack to buy"
	local list = MonCfg.TicketProducts
	local GX, GY, TOP = 12, 12, 150
	local cw = math.floor((TW - 32 - 2 * GX) / 3)
	local chh = math.floor((TH - TOP - 16 - 2 * GY) / 3)
	for i, t in list do
		local col, rowi = (i - 1) % 3, (i - 1) // 3
		local x, y = 16 + col * (cw + GX), TOP + rowi * (chh + GY)
		local tone = TONES[(rowi % 3) + 1]
		frame(root, x, y + 6, cw, chh, INK, { BackgroundTransparency = 0.5, ZIndex = 2 })
		local card = frame(root, x, y, cw, chh, WHITE, { ZIndex = 3, ClipsDescendants = true })
		corner(card, 12); vgrad(card, tone[1], tone[2]); stroke(card, INK, 4)
		new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TILES[tone[3]] or "", ImageTransparency = 0.55,
			ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(48, 48), ZIndex = 3 }, card)
		new("ImageLabel", { BackgroundTransparency = 1, Image = TICKET, ScaleType = Enum.ScaleType.Fit, Rotation = -8,
			Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(62, 62), ZIndex = 5 }, card)
		fitLabel(card, 72, 8, cw - 80, 38, 34, NF.full(t.tickets), WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
		local bonus = math.floor(MonCfg.ticketBonus(t) * 1000 + 0.5) / 10
		fitLabel(card, 72, 44, cw - 80, 22, 18, bonus > 0 and ("+" .. tostring(bonus) .. "% bonus") or "Tickets", WHITE, 2.5,
			{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, FontFace = XBOLD })
		-- кнопка з ціною (стиль A)
		local bw, bh = cw - 20, math.max(40, chh - 86)
		local hold = frame(card, 10, chh - bh - 12, bw, bh + 5, nil, { BackgroundTransparency = 1, ZIndex = 6 })
		local sh = frame(hold, 0, 5, bw, bh, INK, { BackgroundTransparency = 0.6, ZIndex = 6 })
		local b = StyleA.new(hold, { size = Vector2.new(bw, bh), position = Vector2.new(0, 0), color = "green", clickable = true, zIndex = 7 })
		StyleA.follow(b, sh)
		local rowF = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -2),
			Size = UDim2.fromOffset(0, bh), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 9 }, b.root)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder }, rowF)
		new("ImageLabel", { BackgroundTransparency = 1, Image = ROBUX, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(math.floor(bh * 0.5), math.floor(bh * 0.5)),
			LayoutOrder = 1, ZIndex = 10 }, rowF)
		local pt = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = math.min(30, math.floor(bh * 0.6)), TextColor3 = WHITE, Text = NF.full(t.robux),
			Size = UDim2.fromOffset(0, bh), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, ZIndex = 10 }, rowF)
		stroke(pt, INK, 3, true)
		StyleA.bind(b, { debounce = 0.5, onClick = function()
			if (t.id or 0) == 0 then return end
			local r = RS:FindFirstChild("Remotes")
			local rf = r and r:FindFirstChild("GiftAction")
			if rf then pcall(rf.InvokeServer, rf, "Clear") end -- покупка для себе
			pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, t.id)
		end })
	end
	return { gui = g, screen = screen, model = model, title = title, tg = tg, timer = timer, static = true }
end

-- ===== маркет: останні угоди на цьому сервері =====
local TRADES_DEF = { key = "Trades", title = "RECENT TRADES", sub = "Last 100 trades on this server", accent = "c99bff", accent2 = "7a3fe0", tile = "purple",
	icon = "rbxassetid://91791061262477" }
local CUR_ICON = { money = "rbxassetid://103015355952567", diamonds = "rbxassetid://126442692946356", tickets = TICKET }
local CUR_COLOR = { money = "7ef05a", diamonds = "6fd2ff", tickets = "ffd23a" }
local function ago(t: number): string
	local d = math.max(0, os.time() - (tonumber(t) or 0))
	if d < 60 then return d .. "s" elseif d < 3600 then return (d // 60) .. "m" end
	return (d // 3600) .. "h"
end
local function buildTrades(model: Model, screen: BasePart)
	local TW = 900
	local ins = 2 * (tonumber(screen:GetAttribute("Inset")) or 0)
	local TH = math.floor(TW * (screen.Size.Y - ins) / (screen.Size.X - ins))
	local g, root = surface("TradesBoard", screen, TW, TH)
	vgrad(root, "262a33", "121419")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TILES.purple or "", ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 1 }, root)
	local title, tg, timer = header(root, TW, TRADES_DEF, 132)
	-- картки угод (03.11.2026, v2): ліворуч 3D-голем у слоті, праворуч — назва (перелив кольором мутації), рідкість · клас,
	-- «продавець → покупець» (лише ніки), ціна з іконкою валюти і «… ago»
	local RW = TW - 56
	local CHH, IC = 112, 96
	local LY = 150
	local LH = TH - LY - 16
	local listBg = frame(root, 14, LY, TW - 28, LH, C("0e1014"), { BackgroundTransparency = 0.25, ZIndex = 3 })
	corner(listBg, 12); stroke(listBg, INK, 4)
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(20, LY + 6), Size = UDim2.fromOffset(TW - 40, LH - 12), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C(TRADES_DEF.accent), CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4 }, root)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, list)
	local empty = label(root, 20, LY + LH / 2 - 20, TW - 40, 40, 28, "No trades on this server yet", C("9aa3ad"), 3, { ZIndex = 6, FontFace = XBOLD })
	local B = { gui = g, screen = screen, model = model, rows = {}, timer = timer, title = title, tg = tg, static = true, ages = {} }
	function B.render()
		local raw = model:GetAttribute("Trades")
		local ok, data = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
		if not ok or type(data) ~= "table" then data = {} end
		for _, r in B.rows do r:Destroy() end
		B.rows = {}; B.ages = {}
		for i, e in data do
			local mine = e.s == player.UserId or e.b == player.UserId
			local def = e.k and Catalog.get(e.k)
			local mutN = tonumber(e.m) or 0
			local mut = Catalog.mutation(mutN)
			local rcol = def and Catalog.rarityColor(def.rarity) or WHITE
			local card = new("Frame", { Size = UDim2.fromOffset(RW - 8, CHH), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 5 }, list)
			corner(card, 12)
			vgrad(card, mine and "4a3a6e" or "2e3340", mine and "2c2147" or "1c1f27")
			stroke(card, mine and C(TRADES_DEF.accent) or INK, 3)
			-- слот з големом
			local slot = frame(card, 8, (CHH - IC) / 2, IC, IC, C("14161a"), { ZIndex = 6 })
			corner(slot, 10); stroke(slot, rcol, 3)
			vgrad(slot, "2a2f3a", "15171d")
			local img = new("ImageLabel", { BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(1, 1), ZIndex = 7 }, slot)
			if def then pcall(ItemViewport.set, img, ItemViewport.golemKey(def.id, Catalog.cls(e.c)), 1) end
			local X = 8 + IC + 16
			local W = RW - 8 - X - 12
			-- 1: назва (перелив кольором мутації) і ціна праворуч
			local gname = def and def.name or "Golem"
			if mutN > 0 and mut and mut.key then gname = mut.key .. " " .. gname end
			local nm = fitLabel(card, X, 8, W - 230, 38, 32, gname, WHITE, 3.5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
			pcall(MutationText.apply, nm, mutN)
			local cur = CUR_ICON[e.cur] and e.cur or "money"
			new("ImageLabel", { BackgroundTransparency = 1, Image = CUR_ICON[cur], ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(X + W - 222, 10),
				Size = UDim2.fromOffset(34, 34), ZIndex = 7 }, card)
			fitLabel(card, X + W - 184, 8, 184, 38, 32, cur == "money" and NF.money(e.p or 0) or NF.full(e.p or 0), C(CUR_COLOR[cur]), 3.5,
				{ TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })
			-- 2: рідкість · клас і час
			local cls = Catalog.cls(e.c)
			fitLabel(card, X, 46, W - 160, 24, 20, (def and def.rarity or "?") .. " · " .. (cls:sub(1, 1):upper() .. cls:sub(2)), rcol, 2.5,
				{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, FontFace = XBOLD })
			local ag = label(card, X + W - 160, 46, 160, 24, 20, ago(e.t) .. " ago", C("9aa3ad"), 2.5,
				{ TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7, FontFace = XBOLD })
			table.insert(B.ages, { l = ag, t = e.t })
			-- 3: продавець → покупець (лише ніки)
			fitLabel(card, X, 74, W, 30, 24, string.format('<font color="#ffffff">%s</font>  <font color="#%s">→</font>  <font color="#ffffff">%s</font>',
				tostring(e.sn or "?"), TRADES_DEF.accent, tostring(e.bn or "?")), WHITE, 2.5,
				{ TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, RichText = true, FontFace = XBOLD })
			table.insert(B.rows, card)
		end
		empty.Visible = #data == 0
		timer.Text = #data > 0 and (#data .. " trade" .. (#data == 1 and "" or "s")) or "Sell golems with the Sell Golems button"
	end
	model:GetAttributeChangedSignal("Trades"):Connect(B.render)
	B.render()
	task.spawn(function() -- «… ago» оновлюється раз на 15 с
		while g.Parent do
			task.wait(15)
			for _, a in B.ages do if a.l.Parent then a.l.Text = ago(a.t) .. " ago" end end
		end
	end)
	return B
end

-- ===== усі табла: будувати поблизу камери, оновлювати таймер і перелив =====
local boards = {} -- [key] = B
-- джерела: { key, def, model, screen, kind }
local function sources(): { any }
	local out = {}
	if MARKET then
		local m = workspace:FindFirstChild("Marketplace")
		local fl = m and m:FindFirstChild("Floor")
		if not fl then return out end
		for _, def in HubCfg.MARKET_BOARDS or {} do
			local mm = fl:FindFirstChild(def.model)
			table.insert(out, { key = def.key, def = def, model = mm, screen = mm and mm:FindFirstChild("Screen") })
		end
		local tm = HubCfg.TICKETS_BOARD and fl:FindFirstChild(HubCfg.TICKETS_BOARD)
		table.insert(out, { key = "Tickets", model = tm, screen = tm and tm:FindFirstChild("Screen"), tickets = true })
		local tr = HubCfg.tradesBoard and HubCfg.tradesBoard()
		table.insert(out, { key = "Trades", model = tr, screen = tr and tr:FindFirstChild("Screen", true), trades = true })
		return out
	end
	local cave = workspace:FindFirstChild("Cave")
	local hub = cave and cave:FindFirstChild("Hub")
	local f = hub and hub:FindFirstChild("Leaderboards")
	for _, def in HubCfg.BOARDS do
		local mm = f and f:FindFirstChild(def.key)
		table.insert(out, { key = def.key, def = def, model = mm, screen = mm and mm:FindFirstChild("Screen") })
	end
	return out
end
-- за один прохід будується не більше ОДНОГО табла (03.11.2026): після телепорту в залу 8 табел не будуються в одному кадрі (фриз)
local function refresh()
	local camPos = camera.CFrame.Position
	local built = false
	for _, s in sources() do
		local screen = s.screen
		local B = boards[s.key]
		local dist = (screen and screen:IsA("BasePart")) and (screen.Position - camPos).Magnitude or math.huge
		if B and (dist > DROP_AT or B.screen ~= screen or not B.screen:IsDescendantOf(workspace)) then B.gui:Destroy(); boards[s.key] = nil; B = nil end
		if not B and screen and dist < BUILD_AT and not built then
			built = true
			local ok, res
			if s.tickets then ok, res = pcall(buildTickets, s.model, screen)
			elseif s.trades then ok, res = pcall(buildTrades, s.model, screen) else ok, res = pcall(build, s.model, s.def, screen) end
			if ok then boards[s.key] = res else warn("LeaderboardClient: ", res) end
		end
	end
end
task.spawn(function()
	while true do
		pcall(refresh)
		task.wait(0.2)
	end
end)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	local t = os.clock()
	for _, B in boards do
		-- перелив заголовка: білий відблиск пробігає раз на ~4 с
		local u = (t % 4) / 4
		B.tg.Rotation = 20
		B.tg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C("e9eef4")), ColorSequenceKeypoint.new(math.clamp(u - 0.08, 0.001, 0.997), C("e9eef4")),
			ColorSequenceKeypoint.new(math.clamp(u, 0.002, 0.998), WHITE), ColorSequenceKeypoint.new(math.clamp(u + 0.08, 0.003, 0.999), C("e9eef4")),
			ColorSequenceKeypoint.new(1, C("e9eef4")) })
	end
	if acc < 0.5 then return end
	acc = 0
	local now = workspace:GetServerTimeNow()
	for _, B in boards do
		if not B.static then
			local nx = tonumber(B.model:GetAttribute("NextAt")) or 0
			local left = math.max(0, math.ceil(nx - now))
			B.timer.Text = nx > 0 and string.format("Updates in %d:%02d", left // 60, left % 60) or "Updating..."
		end
	end
end)
