--!strict
-- MarketExclusiveClient — стенди ексклюзивних големів на Marketplace (05.11.2026). Сервер — ServerScriptService/MarketExclusiveService.
-- Де: StarterPlayer/StarterPlayerScripts/MarketExclusiveClient (LocalScript). Лише в режимі маркету (є Workspace/Marketplace).
--   * голем на стенді (ExclDisplay) повільно крутиться: клієнт обертає його Root (аніматор ставить усі деталі від Root);
--   * кнопка BuyPrompt: BUY (зелена) / OWNED (сіра, вже куплено — атрибут Pass_MktExcl_<kind>) / SOON (сіра, продукт ще не створено).
--   Покупку, ціну й дошку покупців робить сервер.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local mk = workspace:WaitForChild("Marketplace", 30)
if not mk then return end
local floor = mk:WaitForChild("Floor", 30)
if not floor then return end

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("MarketExclusiveConfig"))
local T = Cfg.TEXT
local player = Players.LocalPlayer

type Spin = { root: BasePart, base: CFrame }
local spins: { [Model]: Spin } = {}

local function track(m: Instance)
	if not (m:IsA("Model") and m.Name == "ExclDisplay") or spins[m] then return end
	local root = m:WaitForChild("Root", 10)
	if not (root and root:IsA("BasePart")) then return end
	spins[m] = { root = root, base = root.CFrame }
	m.AncestryChanged:Connect(function() if not m:IsDescendantOf(workspace) then spins[m] = nil end end)
end

local function paint(e: any, pp: ProximityPrompt)
	local owned = player:GetAttribute(Cfg.ownedAttr(e.kind)) == true
	local soon = e.cur == "robux" and (e.productId or 0) == 0
	if owned then
		pp:SetAttribute("UIText", T.owned); pp:SetAttribute("UIColor", "gray"); pp:SetAttribute("UIDisabled", true)
	elseif soon then
		pp:SetAttribute("UIText", T.soon); pp:SetAttribute("UIColor", "gray"); pp:SetAttribute("UIDisabled", true)
	else
		pp:SetAttribute("UIText", T.buy); pp:SetAttribute("UIColor", "green"); pp:SetAttribute("UIDisabled", false)
	end
end

-- ===== дошка покупців (Lamp Miner) — у стилі табел маркету (LeaderboardClient): шапка з градієнтом і studs,
-- іконка, заголовок, список рядків з аватарками, низ — наступна ціна. Дані — атрибути стенда Buyers (JSON) і Price.
local HttpService = game:GetService("HttpService")
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local A = (StyleA :: any).ASSETS or {}
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local TICKET = "rbxassetid://85299808396483"
local PW, PH = 650, 850
local function new(class: string, props: any, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function frame(parent, x, y, w, h, color, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or WHITE, BorderSizePixel = 0 }, parent)
	if props then for k, v in props do f[k] = v end end
	return f
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, color, th, ctx)
	return new("UIStroke", { Color = color, Thickness = th, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = ctx and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function vgrad(o, a, b) return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(a), C(b)) }, o) end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, ZIndex = 6 }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, true) end
	return t
end
local function fitLabel(parent, x, y, w, h, maxSize, text, color, sw, props)
	local t = label(parent, x, y, w, h, maxSize, text, color, sw, props)
	t.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 10 }, t)
	return t
end

local function buyersBoard(stand: Instance, e: any)
	local ped = stand:WaitForChild("ExclPedestal", 30)
	local bb = ped and ped:WaitForChild("BuyersBoard", 10)
	local screen = bb and bb:WaitForChild("BoardPanel", 10)
	if not (screen and screen:IsA("BasePart")) then return end
	local face = (Enum.NormalId :: any)[screen:GetAttribute("Face") or "Front"] or Enum.NormalId.Front
	local ppx = math.max(PW / screen.Size.X, PH / screen.Size.Y)
	local g = new("SurfaceGui", { Name = "ExclBuyers_" .. e.kind, Adornee = screen, Face = face, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = ppx, LightInfluence = 0, Brightness = 1.1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false,
		ClipsDescendants = true, MaxDistance = 700 }, player:WaitForChild("PlayerGui")) -- 06.11.2026: 300 → 700 (видно з будь-якої точки маркету)
	local root = frame(g, math.floor((screen.Size.X * ppx - PW) / 2), math.floor((screen.Size.Y * ppx - PH) / 2), PW, PH, C("1b1e25"), { ClipsDescendants = true })
	vgrad(root, "262a33", "121419")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = A.stylea_tile_yellow_half or "", ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 1 }, root)
	-- шапка
	local hh = 132
	local head = frame(root, 0, 0, PW, hh, WHITE, { ZIndex = 2, ClipsDescendants = true })
	vgrad(head, "ffd23a", "ff9a1f")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = A.stylea_tile_yellow_half or "", ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 2 }, head)
	frame(head, 0, 0, PW, 10, WHITE, { BackgroundTransparency = 0.6, ZIndex = 3 })
	frame(root, 0, hh, PW, 6, INK, { ZIndex = 4 })
	new("ImageLabel", { BackgroundTransparency = 1, Image = TICKET, ImageColor3 = INK, ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(20, 22), Size = UDim2.fromOffset(100, 100), Rotation = -8, ZIndex = 4 }, root)
	new("ImageLabel", { BackgroundTransparency = 1, Image = TICKET, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(100, 100), Rotation = -8, ZIndex = 5 }, root)
	local title = fitLabel(root, 130, 18, PW - 150, 64, 58, T.boardTitle, WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C("e9eef4")) }, title)
	fitLabel(root, 132, 80, PW - 150, 32, 24, string.format(T.boardSub, NF.full(e.step or 0)), WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD })
	-- список
	local LY, LH = 152, 614
	local listBg = frame(root, 14, LY, PW - 28, LH, C("0e1014"), { BackgroundTransparency = 0.25, ZIndex = 3 })
	corner(listBg, 12); stroke(listBg, INK, 4)
	local list = frame(root, 20, LY + 8, PW - 40, LH - 16, WHITE, { BackgroundTransparency = 1, ZIndex = 4 })
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local empty = label(root, 20, LY + LH / 2 - 20, PW - 40, 40, 28, T.boardEmpty, C("9aa3ad"), 3, { FontFace = XBOLD })
	-- низ: наступна ціна
	local foot = frame(root, 14, 780, PW - 28, 58, WHITE, { ZIndex = 3 })
	corner(foot, 12); stroke(foot, INK, 4); vgrad(foot, "ffd23a", "ff9a1f")
	label(foot, 18, 0, 260, 58, 30, T.boardPrice, WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
	new("ImageLabel", { BackgroundTransparency = 1, Image = TICKET, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(PW - 28 - 74, 6),
		Size = UDim2.fromOffset(46, 46), ZIndex = 7 }, foot)
	local fVal = fitLabel(foot, 280, 6, PW - 28 - 280 - 84, 46, 34, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })
	local rows = {}
	local RW = PW - 40
	local function render()
		fVal.Text = NF.full(tonumber(stand:GetAttribute("Price")) or Cfg.priceOf(e, 0))
		local raw = stand:GetAttribute("Buyers")
		local ok, data = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
		if not ok or type(data) ~= "table" then data = {} end
		for _, r in rows do r:Destroy() end
		rows = {}
		empty.Visible = #data == 0
		for i, b in data do
			if i > Cfg.BOARD_ROWS then break end
			local mine = b.u == player.UserId
			local first = i == 1
			local rh = 64
			local row = frame(list, 0, 0, RW, rh, first and WHITE or (mine and C("ffd23a") or WHITE), { LayoutOrder = i, ZIndex = 5,
				BackgroundTransparency = first and 0 or (mine and 0.55 or (i % 2 == 0 and 0.94 or 0.98)) })
			corner(row, 8)
			if first then vgrad(row, "ffd84a", "e09400"); stroke(row, INK, 3) end
			local av = frame(row, 10, 8, 48, 48, C("2a2e36"), { ZIndex = 6 })
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, av); stroke(av, INK, 3)
			local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 7, ScaleType = Enum.ScaleType.Crop,
				Image = (tonumber(b.u) or 0) > 0 and ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(b.u) .. "&w=150&h=150") or "" }, av)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, img)
			label(row, 68, 0, 84, rh, 30, "#" .. tostring(b.i or i), WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
			fitLabel(row, 150, 8, RW - 150 - 210, rh - 16, 28, tostring(b.n or "?"), WHITE, 3.5, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
				TextTruncate = Enum.TextTruncate.AtEnd })
			fitLabel(row, RW - 200, 8, 140, rh - 16, 28, NF.full(tonumber(b.p) or 0), C("fff1a0"), 3.5, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 })
			new("ImageLabel", { BackgroundTransparency = 1, Image = TICKET, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(RW - 52, 11),
				Size = UDim2.fromOffset(42, 42), ZIndex = 7 }, row)
			table.insert(rows, row)
		end
	end
	render()
	stand:GetAttributeChangedSignal("Buyers"):Connect(render)
	stand:GetAttributeChangedSignal("Price"):Connect(render)
end

for _, e in Cfg.LIST do
	if e.cur == "tickets" then
		task.spawn(function()
			local stand = floor:WaitForChild(e.stand, 60)
			if stand then buyersBoard(stand, e) end
		end)
	end
	task.spawn(function()
		local stand = floor:WaitForChild(e.stand, 60)
		if not stand then return end
		stand.ChildAdded:Connect(function(c) task.spawn(track, c) end)
		local d = stand:WaitForChild("ExclDisplay", 60)
		if d then task.spawn(track, d) end
		local btn = stand:WaitForChild("ExclButton", 60)
		local pp = btn and btn:WaitForChild("BuyPrompt", 10)
		if not (pp and pp:IsA("ProximityPrompt")) then return end
		paint(e, pp)
		player:GetAttributeChangedSignal(Cfg.ownedAttr(e.kind)):Connect(function() paint(e, pp) end)
	end)
end

RunService.RenderStepped:Connect(function()
	local a = os.clock() * Cfg.SPIN
	for _, s in spins do
		s.root.CFrame = s.base * CFrame.Angles(0, a, 0)
	end
end)
