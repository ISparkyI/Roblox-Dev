--!nonstrict
-- PlotStatsClient — особисте табло статистики власника ніші (GDD - Leaderboards, «Біля кожної ніші»). 29.10.2026, v4.
-- Де: StarterPlayer/StarterPlayerScripts/PlotStatsClient (LocalScript). Табло — модель PlotStats у шаблоні ніші
--   (Workspace/NichePrefabs/NichePrefab_Stage1 → Workspace/Niches/Niche<N>): каркас лідерборда (×0,8, без статуї й ламп),
--   у правому куті біля входу, екраном назовні. Власник — атрибут ніші OwnerUserId; дані — атрибути власника (реплікуються всім).
-- Екран — як лідерборд, простіший: шапка кольору табла зі studs (аватар, ім'я, «PLAYER STATS · PLOT N»), список 14 рядків
--   (іконка, назва, значення) з прокруткою. 30.10: + Daily Streak (DailyStreak), Gamepasses (куплені / усі з MonetizationConfig.Passes);
--   + Best Income, Best Roll, Best Streak, Index (відкрито / усі записи, замість Golems Found), Best Golem (найрідкісніший → мутація →
--   сила; інвентар + стенди плоту), Mutations, Ores Mined, Bosses Killed (Stat_* — StatsService). Ніша вільна — «EMPTY PLOT». Будується ближче BUILD_AT, прибирається далі DROP_AT.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local NF = require(Shared:WaitForChild("NumberFormat"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local DailyCfg = require(Shared:WaitForChild("DailyConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local PlotCfg = require(Shared:WaitForChild("PlotConfig"))
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
local BUILD_AT, DROP_AT = 160, 220
local A = StyleA.ASSETS or {}
local ACC, ACC2 = "5cc8ff", "2a6fd6"
local MAP_NAMES = { "Mossy Grotto", "Rusty Mine", "Crystal Depths", "Magma Caverns", "Frozen Abyss", "Void Core" } -- як MapBoard / GDD - Maps

local function num(p: Player, a: string): number return tonumber(p:GetAttribute(a)) or 0 end
local function count(p: Player, a: string): number
	local raw = p:GetAttribute(a)
	if type(raw) ~= "string" or raw == "" then return 0 end
	local ok, t = pcall(HttpService.JSONDecode, HttpService, raw)
	return (ok and type(t) == "table") and #t or 0
end
local function fmtTime(sec: number): string
	sec = math.floor(sec)
	local h, m = sec // 3600, (sec % 3600) // 60
	if h >= 1 then return string.format("%dh %02dm", h, m) end
	return string.format("%dm", m)
end
-- геймпаси: куплені (атрибут Pass_<ключ>) / усі з id (разом із прихованими ступенями, напр. +1 Roll Stand II)
local function passes(p: Player): string
	local have, total = 0, 0
	for key, d in MonCfg.Passes do
		if (tonumber(d.id) or 0) > 0 then
			total += 1
			if p:GetAttribute("Pass_" .. key) == true then have += 1 end
		end
	end
	return have .. "/" .. total
end
-- Index: усі записи = звичайні големи × 3 класи × мутації + ексклюзиви × 3 (лише Normal) + руда (як IndexUI / IndexService)
local INDEX_TOTAL = 0
do
	local n = 0
	for _, id in Catalog.ORDER do local g = Catalog.get(id); if g and g.rarity ~= "Exclusive" then n += 1 end end
	INDEX_TOTAL = n * 3 * #Catalog.MUTATIONS + (#Catalog.exclusivesFor("miner") + #Catalog.exclusivesFor("carrier") + #Catalog.exclusivesFor("warrior")) + #(PlotCfg.INDEX_ORES or PlotCfg.ORES) -- руда мап 1–6 (03.11.2026)
	-- + оброблена руда (вкладка Crafted): усе, що плавиться
	local okF, Forge = pcall(require, Shared:WaitForChild("ForgeConfig"))
	if okF then
		for _, o in PlotCfg.INDEX_ORES or PlotCfg.ORES do
			local f = Forge.oreDef(o.key)
			if f and Forge.canSmelt(f) then INDEX_TOTAL += 1 end
		end
	end
end
-- найкращий голем власника: вища рідкість (ексклюзиви — найнижче, їхня сила залежить від інших) → мутація → сила;
-- големи — атрибути InvGolems і PlotPlaced (JSON-списки { kind, cls, mut })
local RANK = {}
for i, r in Catalog.RARITIES do RANK[r] = r == "Exclusive" and 0 or i end
local function bestGolem(p: Player): string
	local best, bk = nil, nil
	for _, a in { "InvGolems", "PlotPlaced" } do
		local raw = p:GetAttribute(a)
		local ok, t = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "[]")
		if ok and type(t) == "table" then
			for _, e in t do
				local g = type(e) == "table" and Catalog.get(e.kind)
				if g then
					local m = Catalog.mut(e.mut)
					local okP, pw = pcall(Catalog.power, g.id, e.cls, m, p)
					local k = { RANK[g.rarity] or 0, m, okP and pw or 0 }
					if not bk or k[1] > bk[1] or (k[1] == bk[1] and (k[2] > bk[2] or (k[2] == bk[2] and k[3] > bk[3]))) then
						best, bk = { g = g, m = m }, k
					end
				end
			end
		end
	end
	if not best then return "—" end
	local mu = Catalog.MUTATIONS[best.m + 1]
	return ((best.m > 0 and mu) and (mu.key .. " ") or "") .. best.g.name
end
-- рядки (GDD): назва, іконка, колір значення, значення(p)
local ROWS = {
	{ "Money", "rbxassetid://103015355952567", "7ef05a", function(p) return NF.money(num(p, "Money")) end },
	{ "Total", "rbxassetid://103015355952567", "b8ff5a", function(p) return NF.money(num(p, "Stat_TotalMoney")) end },
	{ "Income/s", "rbxassetid://103015355952567", "7ef05a", function(p) return NF.money(num(p, "IncomePerMin") / 60) .. "/s" end },
	{ "Best Income", "rbxassetid://103015355952567", "b8ff5a", function(p) return NF.money(num(p, "Stat_BestIncome") / 60) .. "/s" end },
	{ "Gems", "rbxassetid://126442692946356", "6fd2ff", function(p) return NF.short(num(p, "Diamonds")) end },
	{ "World", "rbxassetid://100812332622032", "ffd23a", function(p)
		local s = math.max(1, num(p, "Stage"))
		return s .. " · " .. (MAP_NAMES[s] or "???")
	end },
	{ "Rebirths", "rbxassetid://124015236802911", "ff7fc4", function(p) return NF.short(num(p, "Rebirths")) end },
	{ "Rolls", "rbxassetid://123138472161660", "c99bff", function(p) return NF.short(num(p, "Stat_Rolls")) end },
	{ "Best Roll", "rbxassetid://124578338510174", "c99bff", function(p)
		local n = num(p, "Stat_BestRoll")
		return n > 0 and ("1 in " .. NF.short(n)) or "—"
	end },
	{ "Playtime", "rbxassetid://76478987044650", "ffd23a", function(p) return fmtTime(num(p, "Stat_Playtime")) end },
	{ "Daily Streak", DailyCfg.ICON, "ffb04a", function(p)
		local n = num(p, "DailyStreak")
		return n .. (n == 1 and " day" or " days")
	end },
	{ "Best Streak", DailyCfg.ICON, "ffd23a", function(p)
		local n = math.max(num(p, "Stat_BestStreak"), num(p, "DailyStreak"))
		return n .. (n == 1 and " day" or " days")
	end },
	{ "Quests Done", "rbxassetid://140685411214992", "ff9a4a", function(p) return NF.short(num(p, "Stat_QuestsDone")) end },
	{ "Index", "rbxassetid://139239217489271", "6fd2ff", function(p) return count(p, "IndexFound") .. " / " .. INDEX_TOTAL end },
	{ "Golems Owned", "rbxassetid://107241982376806", "c99bff", function(p) return NF.short(count(p, "InvGolems")) end },
	{ "Best Golem", "rbxassetid://107241982376806", "ffd23a", bestGolem },
	{ "Working", "rbxassetid://87582280052157", "b8ff5a", function(p) return NF.short(count(p, "PlotPlaced")) end },
	{ "Mutations", "rbxassetid://90173095287975", "8fe3ff", function(p) return NF.short(num(p, "Stat_Mutations")) end },
	{ "Ores Mined", "rbxassetid://138440040019462", "ffb04a", function(p) return NF.short(num(p, "Stat_OresMined")) end },
	{ "Bosses Killed", "rbxassetid://111613717383454", "ff5c6e", function(p) return NF.short(num(p, "Stat_BossKills")) end },
	{ "Gamepasses", "rbxassetid://111200556390804", "ffd23a", passes },
	{ "R$ Spent", "rbxassetid://139687766069559", "7ef05a", function(p) return "R$ " .. NF.short(num(p, "Stat_RobuxSpent")) end },
	{ "R$ Gifted", "rbxassetid://139687766069559", "c99bff", function(p) return "R$ " .. NF.short(num(p, "Stat_RobuxGifted")) end },
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
local function fitLabel(parent, x, y, w, h, maxSize, text, color, sw, props)
	local t = label(parent, x, y, w, h, maxSize, text, color, sw, props)
	t.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 10 }, t)
	return t
end

-- ===== один екран =====
local function build(niche: Instance, screen: BasePart)
	local idx = tonumber(niche:GetAttribute("NicheIndex")) or 0
	local g = new("SurfaceGui", { Name = "PlotStats_" .. idx, Adornee = screen, Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1.1,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = DROP_AT + 40 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("1b1e25"), { ClipsDescendants = true })
	vgrad(root, "262a33", "121419")
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = A.stylea_tile_blue_half or A.stylea_tile_gray or "", ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 1 }, root)

	-- шапка (як у лідерборда): кольорова зі studs, аватар, ім'я з переливом, підпис
	local head = frame(root, 0, 0, PW, 132, WHITE, { ZIndex = 2, ClipsDescendants = true })
	vgrad(head, ACC, ACC2)
	new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = A.stylea_tile_blue_half or "", ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), ZIndex = 2 }, head)
	frame(head, 0, 0, PW, 10, WHITE, { BackgroundTransparency = 0.6, ZIndex = 3 })
	frame(root, 0, 132, PW, 6, INK, { ZIndex = 4 })
	local avH = frame(root, 18, 14, 104, 104, C("2a2e36"), { ZIndex = 5 })
	corner(avH, UDim.new(0.5, 0)); stroke(avH, INK, 5)
	local av = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6, ScaleType = Enum.ScaleType.Crop, Image = "" }, avH)
	corner(av, UDim.new(0.5, 0))
	local name = fitLabel(root, 136, 14, 494, 66, 56, "", WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, AutoLocalize = false }) -- нік гравця не перекладати
	local tg = new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C("e9eef4")) }, name)
	label(root, 138, 80, 490, 34, 26, "PLAYER STATS · PLOT " .. idx, WHITE, 3.5, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 6 })

	-- список з прокруткою
	local LY, LH = 152, 684
	local listBg = frame(root, 14, LY, PW - 28, LH, C("0e1014"), { BackgroundTransparency = 0.25, ZIndex = 3 })
	corner(listBg, 12); stroke(listBg, INK, 4)
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(20, LY + 6), Size = UDim2.fromOffset(PW - 40, LH - 12), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 10, ScrollBarImageColor3 = C(ACC), CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4 }, root)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local vals = {}
	for i, r in ROWS do
		local row = new("Frame", { Size = UDim2.fromOffset(PW - 62, 72), BackgroundColor3 = WHITE, BackgroundTransparency = i % 2 == 0 and 0.94 or 0.98,
			BorderSizePixel = 0, LayoutOrder = i, ZIndex = 5 }, list)
		corner(row, 10)
		new("ImageLabel", { BackgroundTransparency = 1, Image = r[2], ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(56, 56),
			Rotation = -8, ZIndex = 6 }, row)
		label(row, 78, 0, 250, 72, 30, r[1], C("e6edf5"), 3, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 6 })
		local v = fitLabel(row, 300, 8, PW - 62 - 316, 56, 36, "", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 })
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(r[3])) }, v)
		vals[i] = v
	end
	-- вільна ніша
	local free = frame(root, 0, 138, PW, PH - 138, C("121419"), { BackgroundTransparency = 0.15, ZIndex = 10, Visible = false })
	label(free, 0, 270, PW, 90, 80, "EMPTY PLOT", WHITE, 7, { ZIndex = 11 })

	local B = { gui = g, screen = screen, tg = tg, uid = -1 }
	function B.render()
		local uid = tonumber(niche:GetAttribute("OwnerUserId")) or 0
		local owner = uid > 0 and Players:GetPlayerByUserId(uid) or nil
		free.Visible = owner == nil
		if uid ~= B.uid then
			B.uid = uid
			av.Image = uid > 0 and ("rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=150&h=150") or ""
		end
		name.Text = owner and owner.DisplayName or require(game:GetService("ReplicatedStorage").Shared.Loc).f("PLOT {number1}", idx) -- без власника — «УЧАСТОК N» (мітка з AutoLocalize = false)
		for i, r in ROWS do
			local ok, t = pcall(r[4], owner or player)
			vals[i].Text = (owner and ok) and t or "—"
		end
	end
	B.render()
	return B
end

-- ===== усі табла: будувати поблизу камери, оновлювати раз на 0,5 с =====
local boards = {} -- [model] = B
local function refresh()
	local f = workspace:FindFirstChild("Niches")
	if not f then return end
	local camPos = camera.CFrame.Position
	local built = false -- не більше одного нового табла за прохід (03.11.2026: без фризу після телепорту)
	for _, n in f:GetChildren() do
		local m = n:FindFirstChild("PlotStats")
		local screen = m and m:FindFirstChild("Screen")
		if screen then
			local B = boards[m]
			local dist = (screen.Position - camPos).Magnitude
			local near = n:GetAttribute("LODNear") ~= false -- NicheLOD (03.11.2026): далека ніша — табло не будується
			if B and (not near or dist > DROP_AT or not screen:IsDescendantOf(workspace)) then B.gui:Destroy(); boards[m] = nil; B = nil end
			if not B and near and dist < BUILD_AT and not built then
				built = true
				local ok, res = pcall(build, n, screen)
				if ok then boards[m] = res else warn("PlotStatsClient: ", res) end
			end
		end
	end
	for m, B in boards do
		if not m:IsDescendantOf(workspace) then B.gui:Destroy(); boards[m] = nil else pcall(B.render) end
	end
end
task.spawn(function()
	while true do
		pcall(refresh)
		task.wait(0.5)
	end
end)
