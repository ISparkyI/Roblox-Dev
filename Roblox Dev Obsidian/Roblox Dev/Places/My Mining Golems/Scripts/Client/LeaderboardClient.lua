--!nonstrict
-- LeaderboardClient — екрани лідербордів у центрі зали (Workspace/Cave/Hub/Leaderboards/<key>/Screen).
-- Де: StarterPlayer/StarterPlayerScripts/LeaderboardClient (LocalScript). Дані — атрибут Data (JSON [{u, n, v}]) і NextAt на моделі
-- табла (ставить StatsService). Набір табел, кольори, формат чисел — Shared/HubConfig.BOARDS.
-- Екран (SurfaceGui у PlayerGui з Adornee — працює прокрутка), полотно 650 × 850:
--   шапка кольору табла зі studs (іконка, заголовок з переливом, підпис, таймер оновлення), п'єдестал топ-3
--   (золото / срібло / бронза, аватари, корона в #1), список 4–100 з прокруткою, внизу — місце й значення гравця.
-- Екран будується, коли камера ближче BUILD_AT, і прибирається далі DROP_AT.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = RS:WaitForChild("Shared")
local HubCfg = require(Shared:WaitForChild("HubConfig"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

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
}
-- текст бонусу за місце (HubConfig.PERK_TIERS): «+50% Money»
local function perkText(def, rank: number?): string
	local pct = HubCfg.perkPct(def.tier, rank)
	if pct <= 0 then return "" end
	return "+" .. pct .. "% " .. (HubCfg.PERK_NAMES[def.perk] or "")
end
local CROWN = "rbxassetid://111200556390804"
local MEDAL = {
	{ fill = "ffe066", fill2 = "f0a400", text = "ffffff" }, -- золото
	{ fill = "eef3f8", fill2 = "9aa7b6", text = "ffffff" }, -- срібло
	{ fill = "ffb880", fill2 = "c2632b", text = "ffffff" }, -- бронза
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

-- ===== один екран =====
local function build(model: Model, def, screen: BasePart)
	local accent, accent2 = C(def.accent), C(def.accent2)
	local g = new("SurfaceGui", { Name = "Leaderboard_" .. def.key, Adornee = screen, Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1.1,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = DROP_AT + 40 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("1b1e25"), { ClipsDescendants = true })
	vgrad(root, "262a33", "121419")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TILES[def.tile] or A.stylea_tile_gray or "", ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 1 }, root)

	-- шапка
	local head = frame(root, 0, 0, PW, 132, WHITE, { ZIndex = 2, ClipsDescendants = true })
	vgrad(head, def.accent, def.accent2)
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TILES[def.tile] or "", ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 2 }, head)
	frame(head, 0, 0, PW, 10, WHITE, { BackgroundTransparency = 0.6, ZIndex = 3 })
	frame(root, 0, 132, PW, 6, INK, { ZIndex = 4 })
	local icS = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS[def.key] or "", ImageColor3 = INK, ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(20, 22), Size = UDim2.fromOffset(100, 100), Rotation = -8, ZIndex = 4 }, root)
	local ic = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS[def.key] or "", ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(100, 100), Rotation = -8, ZIndex = 5 }, root)
	local title = label(root, 130, 18, 500, 64, 58, def.title, WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
	local tg = new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C("e9eef4")) }, title)
	label(root, 132, 78, 500, 28, 24, def.sub, WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 6 })
	local timer = label(root, 132, 104, 500, 22, 18, "", C("f4f7fb"), 2.5, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 6, TextTransparency = 0.1 })

	-- п'єдестал топ-3: #2 ліворуч, #1 по центру (вище), #3 праворуч
	local POD = { { x = 225, y = 152, w = 200, h = 258 }, { x = 18, y = 192, w = 196, h = 218 }, { x = 436, y = 212, w = 196, h = 198 } }
	local cards = {}
	for i, p in POD do
		local md = MEDAL[i]
		frame(root, p.x, p.y + 8, p.w, p.h, INK, { BackgroundTransparency = 0.45, ZIndex = 3 })
		local card = frame(root, p.x, p.y, p.w, p.h, WHITE, { ZIndex = 4, ClipsDescendants = false })
		corner(card, 14)
		vgrad(card, md.fill, md.fill2)
		stroke(card, INK, 5)
		local shine = frame(card, 8, 6, p.w - 16, 12, WHITE, { BackgroundTransparency = 0.55, ZIndex = 5 })
		corner(shine, 6)
		local as = i == 1 and 104 or 88
		local av, img = avatar(card, (p.w - as) / 2, 22, as, nil, INK)
		local rank = frame(card, -14, -14, 52, 52, INK, { ZIndex = 8 })
		corner(rank, UDim.new(0.5, 0))
		local rIn = frame(rank, 4, 4, 44, 44, C(md.fill), { ZIndex = 9 })
		corner(rIn, UDim.new(0.5, 0)); vgrad(rIn, md.fill, md.fill2)
		label(rIn, 0, 0, 44, 44, 26, tostring(i), WHITE, 3, { ZIndex = 10 })
		if i == 1 then
			new("ImageLabel", { BackgroundTransparency = 1, Image = CROWN, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromOffset(p.w / 2, 30), Size = UDim2.fromOffset(78, 64), Rotation = 8, ZIndex = 9 }, card)
		end
		local nm = fitLabel(card, 8, 22 + as + 8, p.w - 16, 34, i == 1 and 30 or 26, "—", WHITE, 3.5, { ZIndex = 7 })
		local val = fitLabel(card, 8, 22 + as + 44, p.w - 16, 40, i == 1 and 36 or 30, "", accent, 4, { ZIndex = 7 })
		val.TextColor3 = WHITE
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("ffffff"), accent) }, val)
		-- бонус за місце — ярлик, що звисає з нижнього краю картки
		local chip = frame(card, 14, p.h - 14, p.w - 28, 28, INK, { ZIndex = 8 })
		corner(chip, 8)
		local chipIn = frame(chip, 3, 3, p.w - 34, 22, accent, { ZIndex = 9 })
		corner(chipIn, 6); vgrad(chipIn, def.accent, def.accent2)
		fitLabel(chipIn, 4, 1, p.w - 42, 20, 18, perkText(def, i), WHITE, 2.5, { ZIndex = 10 })
		cards[i] = { img = img, name = nm, val = val }
	end

	-- список 4–100
	local LY, LH = 428, 340
	local listBg = frame(root, 14, LY, PW - 28, LH, C("0e1014"), { BackgroundTransparency = 0.25, ZIndex = 3 })
	corner(listBg, 12); stroke(listBg, INK, 4)
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(20, LY + 6), Size = UDim2.fromOffset(PW - 40, LH - 12), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = accent, CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4 }, root)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local empty = label(root, 20, LY + LH / 2 - 20, PW - 40, 40, 26, "No players yet", C("9aa3ad"), 3, { ZIndex = 6, FontFace = XBOLD })

	-- низ: місце гравця
	local foot = frame(root, 14, 780, PW - 28, 58, WHITE, { ZIndex = 3 })
	corner(foot, 12); stroke(foot, INK, 4); vgrad(foot, def.accent, def.accent2)
	local fAv = avatar(foot, 10, 7, 44, player.UserId, INK)
	local fRank = label(foot, 64, 0, 170, 58, 30, "YOU", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
	local fPerk = fitLabel(foot, 214, 8, 190, 42, 22, "", WHITE, 3, { ZIndex = 7 })
	local fVal = fitLabel(foot, 404, 6, PW - 28 - 418, 46, 32, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })

	local B = { gui = g, screen = screen, model = model, rows = {}, timer = timer, title = title, tg = tg }
	function B.render()
		local raw = model:GetAttribute("Data")
		local ok, data = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
		if not ok or type(data) ~= "table" then data = {} end
		for i = 1, 3 do
			local e = data[i]
			cards[i].img.Image = e and ("rbxthumb://type=AvatarHeadShot&id=" .. e.u .. "&w=150&h=150") or ""
			cards[i].name.Text = e and tostring(e.n) or "—"
			cards[i].val.Text = e and fmtValue(def.fmt, e.v) or ""
		end
		for _, r in B.rows do r:Destroy() end
		B.rows = {}
		local myRank = nil
		for i, e in data do if e.u == player.UserId then myRank = i end end
		for i = 4, #data do
			local e = data[i]
			local mine = e.u == player.UserId
			local row = new("Frame", { Size = UDim2.fromOffset(PW - 56, 46), BackgroundColor3 = mine and accent or C("ffffff"),
				BackgroundTransparency = mine and 0.55 or (i % 2 == 0 and 0.94 or 0.98), BorderSizePixel = 0, LayoutOrder = i, ZIndex = 5 }, list)
			corner(row, 8)
			if mine then stroke(row, accent, 2) end
			label(row, 4, 0, 62, 46, 22, "#" .. i, C("c9d1da"), 2.5, { ZIndex = 6 })
			avatar(row, 70, 5, 36, e.u, INK)
			fitLabel(row, 116, 4, 290, 38, 22, tostring(e.n), WHITE, 2.5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, FontFace = XBOLD })
			local v = fitLabel(row, 400, 4, PW - 56 - 412, 38, 24, fmtValue(def.fmt, e.v), accent, 2.5, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 })
			table.insert(B.rows, row)
		end
		empty.Visible = #data <= 3
		empty.Text = #data == 0 and "No players yet" or "Climb the ranks to get here!"
		local mv = tonumber(player:GetAttribute(def.stat)) or 0
		fRank.Text = "YOU  " .. (myRank and ("#" .. myRank) or ("#" .. HubCfg.LB_TOP .. "+"))
		fPerk.Text = myRank and perkText(def, myRank) or ("Top 100: " .. perkText(def, 4))
		fVal.Text = fmtValue(def.fmt, (myRank and data[myRank].v) or mv)
	end
	model:GetAttributeChangedSignal("Data"):Connect(B.render)
	player:GetAttributeChangedSignal(def.stat):Connect(function() if not B.gui.Parent then return end B.render() end)
	B.render()
	return B
end

-- ===== усі табла: будувати поблизу камери, оновлювати таймер і перелив =====
local boards = {} -- [key] = B
local function folder()
	local cave = workspace:FindFirstChild("Cave")
	local hub = cave and cave:FindFirstChild("Hub")
	return hub and hub:FindFirstChild("Leaderboards")
end
local function refresh()
	local f = folder()
	local camPos = camera.CFrame.Position
	for _, def in HubCfg.BOARDS do
		local m = f and f:FindFirstChild(def.key)
		local screen = m and m:FindFirstChild("Screen")
		local B = boards[def.key]
		local dist = screen and (screen.Position - camPos).Magnitude or math.huge
		if B and (dist > DROP_AT or B.screen ~= screen or not B.screen:IsDescendantOf(workspace)) then B.gui:Destroy(); boards[def.key] = nil; B = nil end
		if not B and screen and dist < BUILD_AT then
			local ok, res = pcall(build, m, def, screen)
			if ok then boards[def.key] = res else warn("LeaderboardClient: ", res) end
		end
	end
end
task.spawn(function()
	while true do
		pcall(refresh)
		task.wait(0.5)
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
		local nx = tonumber(B.model:GetAttribute("NextAt")) or 0
		local left = math.max(0, math.ceil(nx - now))
		B.timer.Text = nx > 0 and string.format("Updates in %d:%02d", left // 60, left % 60) or "Updating..."
	end
end)
