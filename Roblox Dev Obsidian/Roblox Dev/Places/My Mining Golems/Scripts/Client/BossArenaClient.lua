--!nonstrict
-- BossArenaClient — бій з босом на арені (вигляд). 04.11.2026, Plan - Boss Fight System §6–9.
-- Де: StarterPlayer/StarterPlayerScripts/BossArenaClient (LocalScript). Сервер — BossFightService (уся логіка й шкода там).
-- Тут: моделі бойових големів (Shared/GolemModel, плавно за позиціями з Remotes/BossTick; State Walk / Idle / Mine),
--   HP-бар над кожним (свій — зелений, чужий — синій з ніком, < 30 % — червоний і пульсує, удар — біла вспишка + «хвіст»),
--   зони ударів боса на підлозі (червоні напівпрозорі прямокутники з рамкою, пульс, удар — спалах), HUD: HP боса вгорі з поділками,
--   таймер, лідерборд DAMAGE праворуч (Workspace.BossDamage), вікно результатів (Remotes/BossResult).
-- 05.11.2026 v2: стиль як у вікнах гри (заокруглені темні блоки, studs на смугах HP), без «YOUR WARRIORS»; EXIT — внизу по центру
--   (TeleportHUD); на арені ховається зайвий HUD (Shop, Index, Quests, Rebirth, Daily, x2 Money, NEXT BOSS, TOTAL MULTI) — як на Marketplace.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local Cfg = require(Shared:WaitForChild("BossConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local GolemModel = require(Shared:WaitForChild("GolemModel"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = RS:WaitForChild("Remotes")

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

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
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, color, th, contextual)
	return new("UIStroke", { Color = color, Thickness = th, LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, true) end
	return t
end
local function decode(s, default)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function fmtLeft(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end
local function tween(o, t, props, style)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- ===== HUD =====
local gui = new("ScreenGui", { Name = "BossArenaHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local root = frame(gui, 0, 0, 1280, 720, nil, { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
local rootScale = new("UIScale", {}, root)
local function fit()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local v = cam.ViewportSize
	rootScale.Scale = math.min(v.X / 1280, v.Y / 720)
	root.Size = UDim2.fromOffset(v.X / rootScale.Scale, v.Y / rootScale.Scale)
end

-- 05.11.2026 v2: HUD у стилі гри — заокруглені темні блоки (як DIAMONDS SHOP), смуги HP з напівпрозорими studs
local STUD = StyleA.ASSETS.stud_tile
local CLOCK = "rbxassetid://76478987044650"
local function studs(parent, w, h, cell, tr, z)
	return new("ImageLabel", { Name = "Studs", BackgroundTransparency = 1, Image = STUD, ImageColor3 = WHITE, ImageTransparency = tr, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(cell, cell), Size = UDim2.fromOffset(w, h), ZIndex = z }, parent)
end
local function gloss(parent, z)
	local g = new("Frame", { Size = UDim2.fromScale(1, 0.48), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = z }, parent)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }) }, g)
	return g
end
-- studs як на кнопках: тайл кнопки (2 клітинки), 3 ряди по висоті, сітка по центру; tr — прозорість (ледь видимі)
local function btnStuds(parent, w, h, color, tr, z)
	local cell = h / 3
	local t = 2 * cell
	local ox = (w % cell) / 2 - t
	return new("ImageLabel", { Name = "Studs", BackgroundTransparency = 1, Image = StyleA.ASSETS["stylea_tile_" .. color] or StyleA.ASSETS["stylea_tile_" .. color .. "_half"],
		ImageTransparency = tr, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(t, t), Position = UDim2.fromOffset(ox, 0),
		Size = UDim2.fromOffset(w - ox, h), ZIndex = z }, parent)
end
local function darkBox(parent, x, y, w, h, props)
	local b = frame(parent, x, y, w, h, INK, { BackgroundTransparency = 0.35 })
	if props then for k, v in props do b[k] = v end end
	corner(b, 12); stroke(b, INK, 4)
	return b
end

-- HP боса (05.11.2026 v4): у кожного боса своя картинка-рамка з назвою (BossConfig.BOSSES[id].bar); заповнення лежить під нею
--   рівно у прозорому вікні картинки. Без картинки — назва текстом + проста смуга 640 × 46.
local _, BDEF = Cfg.current()
local BART = BDEF.bar or {}
local HAS_ART = type(BART.image) == "string" and BART.image ~= ""
local IMG_W = 646 -- 06.11.2026: менше в 1,3 раза (було 840)
local IMG_SC = IMG_W / (BART.w or 1024)
local IMG_H = HAS_ART and (BART.h or 204) * IMG_SC or 100
local WIN = BART.win or { 78, 88, 860, 46 }
local WX, WY, BAR_W, BAR_H
if HAS_ART then
	WX, WY, BAR_W, BAR_H = WIN[1] * IMG_SC, WIN[2] * IMG_SC, WIN[3] * IMG_SC, WIN[4] * IMG_SC
else
	WX, WY, BAR_W, BAR_H = (IMG_W - 640) / 2, 48, 640, 46
end
local bossBar = frame(root, 0, 0, IMG_W, IMG_H, nil, { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, HAS_ART and 14 or 50) })
local bossName = label(bossBar, 0, 0, IMG_W, 44, 38, tostring(BDEF.name), WHITE, 5, { Visible = not HAS_ART })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "e6ffd0" }, { 1, "7fd24a" } }) }, bossName)
if HAS_ART then
	new("ImageLabel", { Name = "BarArt", BackgroundTransparency = 1, Image = BART.image, ScaleType = Enum.ScaleType.Stretch,
		Size = UDim2.fromOffset(IMG_W, IMG_H), ZIndex = 8 }, bossBar)
end
-- 05.11.2026 v3: без заокруглень; заповнення — рівний колір зі studs як на кнопках StyleA (тайл stylea_tile_*, 3 ряди), ледь видимі
local barBack = frame(bossBar, WX, WY, BAR_W, BAR_H, C("1d2026"))
if not HAS_ART then stroke(barBack, INK, 5) end
local barGhost = frame(barBack, 0, 0, BAR_W, BAR_H, C("ffd0d0"), { ZIndex = 1, BackgroundTransparency = 0.2 })
local barFill = frame(barBack, 0, 0, BAR_W, BAR_H, WHITE, { ZIndex = 2, ClipsDescendants = true })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "e8403c" }, { 1, "c42b2b" } }) }, barFill)
btnStuds(barFill, BAR_W, BAR_H, "red", 0.72, 3)
for k = 1, 3 do frame(barBack, BAR_W * k / 4 - 1.5, 4, 3, BAR_H - 8, INK, { BackgroundTransparency = 0.35, ZIndex = 5 }) end
local barNum = label(bossBar, WX, WY, BAR_W, BAR_H, math.floor(BAR_H * 0.6), "", WHITE, 3.5, { ZIndex = 9 })

-- таймер під смугою (v3): без підкладки й іконки — великі цифри, під ними дрібний напис
local timerBox = frame(root, 0, 0, 200, 60, nil, { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, HAS_ART and (14 + IMG_H - 4) or 152) })
local timer = label(timerBox, 0, 0, 200, 40, 36, "", WHITE, 4.5)
local timerT = label(timerBox, 0, 38, 200, 18, 14, "TIME LEFT", C("d6dbe2"), 2.5)
-- 06.11.2026: HP боса — під самий верх, між кнопками зліва (меню Roblox + наші) і справа; не влазить — зменшуємо (до 0,6),
--   зовсім ніяк — під кнопки на всю ширину. Таймер — одразу під смугою
local barScale = new("UIScale", {}, bossBar)
local lastLay = 0
local function layoutTop()
	if os.clock() - lastLay < 0.5 then return end
	lastLay = os.clock()
	local sc = rootScale.Scale
	local vx = workspace.CurrentCamera.ViewportSize.X
	local cx = vx / 2
	local tb = GuiService.TopbarInset
	local left, right, bottom = tb.Min.X, (tb.Max.X > tb.Min.X) and tb.Max.X or vx, tb.Max.Y
	local inset = GuiService:GetGuiInset()
	for _, sg in playerGui:GetChildren() do
		if sg:IsA("ScreenGui") and sg.Enabled and sg ~= gui then
			for _, d in sg:GetDescendants() do
				if d:IsA("GuiButton") and d.Visible and d.AbsoluteSize.X > 16 then
					local p, s = d.AbsolutePosition + (sg.IgnoreGuiInset and Vector2.zero or inset), d.AbsoluteSize
					-- лише невеликі кнопки у верхній смузі (повноекранні затемнення / модалки — напр. «Leave boss arena?» — не рахуємо)
					if p.Y < 70 * sc and s.X < 220 * sc and s.Y < 140 * sc then
						local vis, a = true, d.Parent
						while a and a ~= sg do
							if a:IsA("GuiObject") and not a.Visible then vis = false; break end
							a = a.Parent
						end
						if vis then
							if p.X + s.X / 2 < cx then left = math.max(left, p.X + s.X) else right = math.min(right, p.X) end
							bottom = math.max(bottom, p.Y + s.Y)
						end
					end
				end
			end
		end
	end
	local avail = 2 * math.min(cx - left, right - cx) - 24 * sc
	local k = math.min(1, avail / ((HAS_ART and IMG_W or BAR_W) * sc))
	local y = 4
	if k < 0.6 then
		k = math.min(1, (vx - 32 * sc) / ((HAS_ART and IMG_W or BAR_W) * sc))
		y = bottom / sc + 4
	end
	barScale.Scale = k
	bossBar.Position = UDim2.new(0.5, 0, 0, y)
	timerBox.Position = UDim2.new(0.5, 0, 0, y + (HAS_ART and IMG_H - 4 or 102) * k)
end

-- лідерборд DAMAGE праворуч — 05.11.2026 v3: як лічильники грошей / тікетів — темна підкладка біля краю екрана, що плавно
--   зникає ліворуч (UIGradient Transparency) зі слабкими studs; без рамок і заливок рядків: місце — кольорова цифра, «You» — зелений
local LB_W, LB_ROW, LB_TOP = 330, 40, 50
local LB_FADE = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.3), NumberSequenceKeypoint.new(1, 0.22) })
local lb = frame(root, 0, 0, LB_W, 60, C("0e1014"), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 96), ClipsDescendants = true })
new("UIGradient", { Transparency = LB_FADE }, lb)
local lbStuds = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = "rbxassetid://113147180553208",
	ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(28, 28), ImageTransparency = 0.15, ZIndex = 1 }, lb)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0) }) }, lbStuds)
local lbTitle = label(lb, 0, 6, LB_W - 18, 40, 30, "DAMAGE", WHITE, 4.5, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ffe2e2" }, { 1, "ff5a5a" } }) }, lbTitle)
local RANK = { "ffd84a", "dfe6ee", "e0a26a" }
local lbRows = {}
for i = 1, Cfg.MAX_PLAYERS do
	local r = frame(lb, 0, LB_TOP + (i - 1) * LB_ROW, LB_W, LB_ROW, nil, { BackgroundTransparency = 1, Visible = false, ZIndex = 3 })
	local rk = label(r, 74, 0, 30, LB_ROW, 24, tostring(i), C(RANK[i] or "c9d0d8"), 3, { ZIndex = 4 })
	local nm = label(r, 110, 0, 120, LB_ROW, 18, "", WHITE, 2.5, { TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 })
	local dm = label(r, 230, 0, LB_W - 18 - 230, LB_ROW, 20, "", C("ffb3b3"), 3, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4 })
	lbRows[i] = { f = r, nm = nm, dm = dm }
end

-- зайвий HUD на арені ховаємо (як на Marketplace), після арени — вертаємо
local HIDE_TEXT = { Shop = true, Quests = true, Index = true, ["x2 Money"] = true, Rebirth = true, Daily = true, ["NEXT BOSS"] = true, Boss = true, BOSS = true, ["TOTAL MULTI"] = true }
local hiddenHud: { [GuiObject]: { conn: RBXScriptConnection, was: boolean } } = {}
local function keepHidden(o: GuiObject)
	if hiddenHud[o] then return end
	local e = { was = o.Visible, conn = nil :: any }
	o.Visible = false
	-- інший скрипт хоче показати / сховати — запам'ятовуємо його бажання, але на арені тримаємо схованим
	e.conn = o:GetPropertyChangedSignal("Visible"):Connect(function() if o.Visible then e.was = true; o.Visible = false end end)
	hiddenHud[o] = e
end
local function firstText(o: Instance): string?
	for _, d in o:GetDescendants() do
		if d:IsA("TextLabel") and d.Text ~= "" then return d.Text end
	end
	return nil
end
local function hideHud()
	-- TOTAL MULTI — окрема плашка в MoneyHUD (гроші лишаємо)
	local mh = playerGui:FindFirstChild("MoneyHUD")
	local mf = mh and mh:FindFirstChild("Frame")
	if mf then
		for _, c in mf:GetChildren() do
			local t = c:IsA("GuiObject") and firstText(c)
			if (t and t:find("^TOTAL MULTI")) or c:FindFirstChild("TotalMulti", true) then keepHidden(c) end -- текст може бути перекладений (Shared/Loc)
		end
	end
	local hud = playerGui:FindFirstChild("MainHUD")
	-- 05.11.2026: у верхньому ряду — без інвентаря (Invite лишаємо); 06.11.2026: Settings лишаємо (спрощені налаштування)
	local top = hud and hud:FindFirstChild("TopRow")
	if top then
		for _, n in { "Btn_Inventory" } do
			local b = top:FindFirstChild(n)
			if b and b:IsA("GuiObject") then keepHidden(b) end
		end
	end
	local f = hud and hud:FindFirstChild("Frame")
	if not f then return end
	local money: GuiObject? = nil
	for _, c in f:GetChildren() do
		if c:IsA("GuiObject") then
			local t = firstText(c)
			if c.Name:sub(1, 8) == "Counter_" or (t and (HIDE_TEXT[t] or t:find("^TOTAL MULTI"))) then keepHidden(c) end -- лічильники (діаманти, квитки, ребірти) теж
			if t == "x2 Money" then money = c end
		end
	end
	if money then -- ціна наступного ступеня x2 Money — окрема рамка над кнопкою
		local mp, ms = money.AbsolutePosition, money.AbsoluteSize
		for _, c in f:GetChildren() do
			if c:IsA("GuiObject") and c ~= money and not hiddenHud[c] and c.Visible then
				local p, s = c.AbsolutePosition, c.AbsoluteSize
				local cx = p.X + s.X / 2
				if ms.X > 0 and cx > mp.X and cx < mp.X + ms.X and p.Y < mp.Y and p.Y + s.Y > mp.Y - 80 then keepHidden(c) end
			end
		end
	end
end
local function showHud()
	for o, e in hiddenHud do e.conn:Disconnect(); if o.Parent then o.Visible = e.was end end
	table.clear(hiddenHud)
end

-- результати
-- 06.11.2026: затемнення всього екрана під вікном результатів (плавно з'являється разом з вікном)
local resDim = frame(root, 0, 0, 0, 0, BLACK, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 19, Active = true })
local res = frame(root, 0, 0, 520, 470, nil, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 20 })
local resScale = new("UIScale", {}, res)
frame(res, 0, 14, 520, 470, BLACK, { BackgroundTransparency = 0.6, ZIndex = 20 })
local resWin = frame(res, 0, 0, 520, 470, WHITE, { ZIndex = 21 })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "5d636b" }, { 1, "3c4047" } }) }, resWin); stroke(resWin, INK, 6)
local resPanel = frame(resWin, 16, 16, 488, 438, C("a9aeb5"), { ZIndex = 22, ClipsDescendants = true }); stroke(resPanel, INK, 4)
StyleA.studTile(frame(resPanel, 0, 0, 488, 438, nil, { BackgroundTransparency = 1, ZIndex = 22 }), 4, 0, 480, 438, 40, C("b3b8bf"))
do
	local sh = frame(resPanel, 0, 0, 488, 438, WHITE, { ZIndex = 23 })
	new("UIGradient", { Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE), ColorSequenceKeypoint.new(1, WHITE) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1), NumberSequenceKeypoint.new(1, 0.82) }) }, sh)
end
local resTitle = label(resPanel, 0, 14, 488, 64, 54, "VICTORY!", C("b8ff8a"), 7, { ZIndex = 24 })
local resSub = label(resPanel, 0, 74, 488, 28, 21, "", WHITE, 3.5, { ZIndex = 24, FontFace = XBOLD })
local statBox = frame(resPanel, 24, 116, 440, 100, INK, { BackgroundTransparency = 0.35, ZIndex = 24 }); corner(statBox, 12); stroke(statBox, INK, 4)
local statV = {}
for i, nm in { "PLACE", "DAMAGE", "IMPACT" } do
	label(statBox, (i - 1) * 146, 12, 146, 20, 15, nm, C("c9ced6"), 2, { ZIndex = 25 })
	statV[i] = label(statBox, (i - 1) * 146, 34, 146, 54, 38, "", ({ C("d9e2ec"), C("ff9a9a"), C("ffe08a") })[i], 5, { ZIndex = 25 })
end
-- 06.11.2026: нагороди — окремі плашки (як блок PLACE / DAMAGE): іконка, «+N» і підпис під ним; без зубів — лише діаманти по центру
local rewardRow = frame(resPanel, 24, 230, 440, 84, nil, { BackgroundTransparency = 1, ZIndex = 24 })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, rewardRow)
local function rewardItem(icon, color, cap, order)
	local box = frame(rewardRow, 0, 0, 212, 84, INK, { BackgroundTransparency = 0.35, ZIndex = 24, LayoutOrder = order }); corner(box, 12); stroke(box, INK, 4)
	new("ImageLabel", { Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(62, 62), BackgroundTransparency = 1, Image = icon,
		ScaleType = Enum.ScaleType.Fit, ZIndex = 25 }, box)
	local t = label(box, 84, 6, 120, 48, 38, "", color, 5, { ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left })
	label(box, 84, 54, 120, 20, 14, cap, C("c9ced6"), 2, { ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Left })
	return box, t
end
local toothIm, toothT = rewardItem(Cfg.ICON_TOOTH, C("fff1cf"), "FOSSIL TEETH", 1)
local diaIm, diaT = rewardItem(Cfg.ICON_DIAMOND, C("8fe0ff"), "DIAMONDS", 2)
local loseNote = label(resPanel, 0, 316, 488, 24, 19, "", WHITE, 3, { ZIndex = 24, FontFace = XBOLD })
local okBtn = StyleA.new(resPanel, { size = Vector2.new(220, 64), position = Vector2.new(134, 352), color = "green", text = "CLAIM", textSize = 30, clickable = true, zIndex = 26 })
-- 06.11.2026: CLAIM — нагороди «летять» у кнопку інвентаря (рюкзак, MainHUD … Btn_Inventory; на арені схована — летять туди ж)
local flyN = 0
local lastRes: any = nil
local flyLayer = new("Frame", { Name = "Fly", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40 }, gui)
local function invTarget(): Vector2
	local hud = playerGui:FindFirstChild("MainHUD")
	local b = hud and hud:FindFirstChild("Btn_Inventory", true)
	if b and b:IsA("GuiObject") and b.AbsoluteSize.X > 0 then
		return b.AbsolutePosition + b.AbsoluteSize / 2
	end
	return Vector2.new(70, 70)
end
local function flyIcons(from: GuiObject, icon: string, n: number)
	-- 06.11.2026: усе в координатах шару Fly (AbsolutePosition — від низу топбару, кнопка рюкзака у топбарі має y < 0)
	local o0 = flyLayer.AbsolutePosition
	local c0 = from.AbsolutePosition + Vector2.new(from.AbsoluteSize.Y * 0.5, from.AbsoluteSize.Y * 0.5) - o0
	local tgt = invTarget() - o0
	local sz = from.AbsoluteSize.Y * 0.62
	for i = 1, n do
		flyN += 1
		task.delay((i - 1) * 0.05, function()
			local im = new("ImageLabel", { BackgroundTransparency = 1, Image = icon, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(sz, sz),
				Position = UDim2.fromOffset(c0.X, c0.Y), ZIndex = 41 }, flyLayer)
			local mid = c0 + Vector2.new((math.random() - 0.5) * 170, (math.random() - 0.5) * 120 - 40)
			tween(im, 0.22, { Position = UDim2.fromOffset(mid.X, mid.Y) }).Completed:Connect(function()
				local tw = TweenService:Create(im, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = UDim2.fromOffset(tgt.X, tgt.Y), Size = UDim2.fromOffset(sz * 0.45, sz * 0.45) })
				tw.Completed:Connect(function() im:Destroy(); flyN -= 1 end)
				tw:Play()
			end)
		end)
	end
end
StyleA.bind(okBtn, { debounce = 0.3, onClick = function()
	local r = lastRes
	if r and r.win then
		if (r.teeth or 0) > 0 then flyIcons(toothIm, Cfg.ICON_TOOTH, math.clamp(r.teeth, 3, 10)) end
		if (r.dia or 0) > 0 then flyIcons(diaIm, Cfg.ICON_DIAMOND, math.clamp(math.floor(r.dia / 25), 4, 12)) end
	end
	res.Visible = false
	-- 06.11.2026: забрав нагороду — одразу додому на плот
	local ba = remotes:FindFirstChild("BossAction")
	if ba and player:GetAttribute("InBossArena") == true then ba:FireServer("Home") end
end })
-- цифри у вікні нагород «набігають» від 0
local function countUp(lbl: TextLabel, to: number, fmt: (number) -> string, dur: number, delay: number)
	lbl.Text = fmt(0)
	task.delay(delay, function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local k = (os.clock() - t0) / dur
			lbl.Text = fmt(to * (1 - (1 - k) ^ 3))
			RunService.RenderStepped:Wait()
		end
		lbl.Text = fmt(to)
		local s = lbl:FindFirstChildOfClass("UIScale") or new("UIScale", {}, lbl)
		s.Scale = 1.25
		tween(s, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end
res:GetPropertyChangedSignal("Visible"):Connect(function()
	resDim.Visible = res.Visible
	if res.Visible then fit() end -- розмір під екран і тоді, коли гравець уже не на арені
	if res.Visible then resDim.BackgroundTransparency = 1; tween(resDim, 0.25, { BackgroundTransparency = 0.45 }) end
end)

-- ===== зони ударів =====
local fxFolder = new("Folder", { Name = "BossFx" }, workspace)
local zones = {} -- [id] = { parts, t0, warn }
local function floorY(): number return tonumber(workspace:GetAttribute("BossFloorY")) or 0 end
local function zonePart(cf, size, color, tr, neon)
	return new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Size = size, CFrame = cf,
		Color = color, Transparency = tr, Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic }, fxFolder)
end
-- 04.11.2026: звуки бою (ReplicatedStorage/BossSfx) — 3D, з точки джерела (Attachment у Terrain), чути тим, хто поруч.
--   o: vol (множник до Volume шаблону), spd (PlaybackSpeed), var (±розкид висоти), min/max (RollOff, стади), delay (с), skip (TimePosition)
local SFX = RS:WaitForChild("BossSfx", 10)
local function sfx(name: string, pos: Vector3, o: any?)
	o = o or {}
	local tpl = SFX and SFX:FindFirstChild(name)
	if not (tpl and tpl:IsA("Sound")) then return end
	local function go()
		local att = Instance.new("Attachment")
		att.WorldPosition = pos
		att.Parent = workspace.Terrain
		local s = tpl:Clone()
		s.Volume = tpl.Volume * (o.vol or 1)
		s.PlaybackSpeed = (o.spd or 1) * (1 + ((math.random() * 2 - 1) * (o.var or 0)))
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = o.min or 20
		s.RollOffMaxDistance = o.max or 220
		s.Parent = att
		if o.skip then s.TimePosition = o.skip end
		s:Play()
		task.delay((tpl.TimeLength > 0 and tpl.TimeLength or 3) / math.max(0.3, s.PlaybackSpeed) + 0.3, function() att:Destroy() end)
	end
	if (o.delay or 0) > 0 then task.delay(o.delay, go) else go() end
end
local function bossHead(): Vector3?
	local bm = workspace:FindFirstChild("Boss Map")
	local m = bm and bm:FindFirstChild("Boss")
	local hb = m and m:FindFirstChild("Hitbox")
	if hb and hb:IsA("BasePart") then return hb.Position + Vector3.new(0, hb.Size.Y * 0.35, 0) end
	return nil
end
-- 05.11.2026 v2: зона без обводки — заливка проявляється (fade in 0.35 с + «наростає» 85 → 100 %), усередині «заряд» росте від
--   центру до країв за час попередження (коли заповнить зону — удар); при ударі спалах і плавне зникнення
local ZONE_IN = 0.35
local function drawRects(id, rects, warn)
	local parts = {}
	local y = floorY() + 0.12
	for _, r in rects do
		local cf = CFrame.new(r.cx, y, r.cz) * CFrame.Angles(0, r.yaw, 0)
		local size = Vector3.new(r.w, 0.1, r.d)
		table.insert(parts, { p = zonePart(cf, size, C("ff2b2b"), 1, false), kind = "base", c = cf, size = size })
		table.insert(parts, { p = zonePart(cf * CFrame.new(0, 0.05, 0), Vector3.new(0.1, 0.1, 0.1), C("ff4a3a"), 1, true), kind = "charge", c = cf * CFrame.new(0, 0.05, 0), size = size })
	end
	zones[id] = { parts = parts, t0 = os.clock(), warn = warn }
end
local function hitRects(id)
	local z = zones[id]
	if not z then return end
	zones[id] = nil
	for _, e in z.parts do
		if e.kind == "charge" then
			e.p.Size = Vector3.new(e.size.X, 0.1, e.size.Z)
			e.p.Color = C("ffd0b8"); e.p.Transparency = 0.2
		else
			e.p.Color = C("ff8a70"); e.p.Transparency = 0.35
		end
		tween(e.p, 0.45, { Transparency = 1 }, Enum.EasingStyle.Sine).Completed:Connect(function() e.p:Destroy() end)
	end
end

-- ===== големи =====
local golems = {} -- [key] = { m, x, z, yaw, tx, tz, tyaw, hp, max, mine, own, bar, ... }
-- v3: спокійне заповнення — легкий вертикальний перехід одного кольору (без «вирвиглазу»), studs як на кнопках того ж кольору
local function hpColor(g, k)
	if k < 0.3 then return cseq({ { 0, "e8403c" }, { 1, "c42b2b" } }), "red" end
	if g.own then return cseq({ { 0, "5fd23a" }, { 1, "45b52a" } }), "green" end
	return cseq({ { 0, "4a9be8" }, { 1, "3580d0" } }), "blue"
end
local function tileOf(color: string): string
	return StyleA.ASSETS["stylea_tile_" .. color] or StyleA.ASSETS["stylea_tile_" .. color .. "_half"]
end
local function makeBar(g, model, info)
	local ht = 6
	pcall(function() ht = GolemModel.headTop(model) end)
	local adorn = model.PrimaryPart or model:FindFirstChild("Root") or model:FindFirstChildWhichIsA("BasePart", true)
	local bb = new("BillboardGui", { Name = "HPBar", Size = UDim2.new(4.8, 0, 1.4, 0), StudsOffsetWorldSpace = Vector3.new(0, ht + 1.4, 0),
		AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 120, Adornee = adorn }, model)
	local def = Catalog.get(info.k)
	local txt = g.own and (def and def.name or "Golem") or tostring(info.n)
	local nm = new("TextLabel", { Size = UDim2.fromScale(1, 0.42), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true, Text = txt,
		TextColor3 = g.own and WHITE or C("bfe9ff") }, bb)
	stroke(nm, INK, 2, true)
	-- смуга (05.11.2026 v2): темна основа, «хвіст» удару, градієнт + напівпрозорі studs + відблиск, заокруглена, чорна обводка
	-- v3: без заокруглень; studs як на кнопках (3 ряди: тайл = 2/3 висоти смуги; смуга 4.8 × 0.7 → ширина тайла ≈ 0.097)
	local back = new("Frame", { Position = UDim2.fromScale(0, 0.48), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = C("1d2026"), BorderSizePixel = 0 }, bb)
	local bs = stroke(back, INK, 2.5)
	local ghost = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C("ffd0d0"), BackgroundTransparency = 0.2, BorderSizePixel = 0 }, back)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, ClipsDescendants = true }, back)
	local col, tname = hpColor(g, 1)
	local grad = new("UIGradient", { Rotation = 90, Color = col }, fill)
	local st = new("ImageLabel", { Name = "Studs", BackgroundTransparency = 1, Image = tileOf(tname), ImageTransparency = 0.72, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromScale(0.0972, 0.6667), Size = UDim2.fromScale(1, 1), ZIndex = 3 }, fill)
	local pct = new("TextLabel", { Size = UDim2.fromScale(0.95, 0.9), Position = UDim2.fromScale(0, 0.05), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true, Text = NF.short(math.floor(info.max or 0)),
		TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 }, back)
	stroke(pct, INK, 1.5, true)
	g.bar = { bb = bb, fill = fill, ghost = ghost, grad = grad, studs = st, pct = pct, stroke = bs, k = 1 }
end
local animHit: (any) -> () = function() end -- 06.11.2026: удар в анімації голема → цифра шкоди (визначено нижче)
local function spawnGolems(list)
	for _, info in list do
		if not golems[info.key] then
			local m = GolemModel.build(info.k, "warrior")
			if m then
				m.Name = "BossGolem"
				local _, size = m:GetBoundingBox()
				local kS = math.min(1, 7 / math.max(0.1, size.Y), 5.5 / math.max(0.1, math.max(size.X, size.Z)))
				if kS < 0.999 then m:ScaleTo(m:GetScale() * kS) end
				m:SetAttribute("Mut", info.m)
				m:SetAttribute("State", "Idle")
				local g = { kind = info.k, flash = 0, m = m, x = nil, z = nil, yaw = 0, tx = 0, tz = 0, tyaw = 0, hp = info.max, max = info.max, own = info.u == player.UserId, foot = 0, st = 0 }
				pcall(function() g.foot = GolemModel.footOffset(m) end)
				makeBar(g, m, info)
				-- 06.11.2026: один замах = інтервал удару сервера (MINE_T аніматора = 1,4 с); удар мечем → цифра шкоди
				if info.iv then m:SetAttribute("AnimSpeed", 1.4 / math.max(0.3, info.iv)) end
				local tgt = new("Configuration", { Name = "BossHitTarget" }, m)
				new("ObjectValue", { Name = "MineTarget", Value = tgt }, m)
				tgt:GetAttributeChangedSignal("HitTime"):Connect(function() animHit(g) end)
				m.Parent = fxFolder
				golems[info.key] = g
			end
		end
	end
end
-- 06.11.2026: спливаючі цифри шкоди над точкою удару голема (у бік боса): «-N», 0,6 с — вискакує, піднімається й тане.
--   Свої — червоні (3,3 × 1,2 стада), чужих гравців — білі й менші (2,2 × 0,8); розмір у світі, не від камери
local function popAt(g: any, val: number)
	local bm = workspace:FindFirstChild("Boss Map")
	local bmod = bm and bm:FindFirstChild("Boss")
	local hb = bmod and bmod:FindFirstChild("Hitbox")
	if not hb or not hb:IsA("BasePart") or not g.x then return end
	local bp = hb.Position
	local to = Vector3.new(bp.X - g.x, 0, bp.Z - g.z)
	local dir = to.Magnitude > 0.1 and to.Unit or Vector3.zero
	local pos = Vector3.new(g.x, floorY() + 4.5, g.z) + dir * 2.2 + Vector3.new((math.random() - 0.5) * 1.6, math.random() * 1.2, (math.random() - 0.5) * 1.6)
	local att = new("Attachment", { WorldPosition = pos }, workspace.Terrain)
	local bb = new("BillboardGui", { Adornee = att, Size = g.own and UDim2.fromScale(3.3, 1.2) or UDim2.fromScale(2.2, 0.8), AlwaysOnTop = true, -- у студах: розмір у світі сталий
		MaxDistance = 180, LightInfluence = 0, StudsOffset = Vector3.zero }, fxFolder)
	local lbl = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true,
		Text = "-" .. NF.short(val or 0), TextColor3 = g.own and C("ff4a4a") or WHITE }, bb)
	local st = stroke(lbl, INK, g.own and 2 or 1.5, true)
	local sc = new("UIScale", { Scale = 0.4 }, lbl)
	tween(sc, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(bb, 0.6, { StudsOffset = Vector3.new(0, 2.6, 0) })
	task.delay(0.25, function()
		tween(lbl, 0.35, { TextTransparency = 1 })
		tween(st, 0.35, { Transparency = 1 })
	end)
	task.delay(0.62, function() bb:Destroy(); att:Destroy() end)
end
-- 06.11.2026: цифра — у мить удару мечем в анімації (GolemAnimator ставить HitTime на ціль MineTarget), а не в мить
--   серверного удару: сервер лише «кладе в чергу» шкоду (g.pend), анімація її показує. Якщо анімації удару немає
--   (голем іде / стан ще не Mine) — черга показується сама через 1,2 с
local function dmgPops(list)
	for _, e in list do
		local g = golems[e[1]]
		if g then
			g.dmgVal = e[2] or 0
			if (g.pend or 0) == 0 then g.pendT = os.clock() end
			g.pend = math.min((g.pend or 0) + 1, 3)
		end
	end
end
animHit = function(g: any)
	-- 04.11.2026: звук удару голема — у мить удару мечем; швидкість звуку = швидкість замаху (AnimSpeed)
	if g.x and g.m and g.m.Parent then
		local bp = bossHead()
		local p = Vector3.new(g.x, floorY() + 3, g.z)
		if bp then local d = Vector3.new(bp.X - g.x, 0, bp.Z - g.z); if d.Magnitude > 0.1 then p += d.Unit * 2.5 end end
		local sp = math.clamp(tonumber(g.m:GetAttribute("AnimSpeed")) or 1, 0.75, 1.6)
		sfx("GolemHit", p, { vol = g.own and 1 or 0.6, spd = sp, var = 0.06, min = g.own and 14 or 8, max = g.own and 110 or 70, skip = 0.12 })
	end
	if (g.pend or 0) > 0 then
		g.pend -= 1
		g.pendT = os.clock()
		popAt(g, g.dmgVal)
	end
end
local function killGolem(key)
	local g = golems[key]
	if not g then return end
	golems[key] = nil
	local m = g.m
	if g.bar then g.bar.bb.Enabled = false end
	-- «розсипається»: деталі падають і тануть
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			tween(d, 0.7, { Transparency = 1, CFrame = d.CFrame * CFrame.new(math.random(-15, 15) / 10, -1.5, math.random(-15, 15) / 10) * CFrame.Angles(math.random() - 0.5, math.random() - 0.5, 0) })
		end
	end
	task.delay(0.8, function() m:Destroy() end)
end
local function clearAll()
	for k in golems do local g = golems[k]; if g.m then g.m:Destroy() end end
	table.clear(golems)
	for id in zones do for _, e in zones[id].parts do e.p:Destroy() end end
	table.clear(zones)
end

remotes:WaitForChild("BossTick").OnClientEvent:Connect(function(pk)
	for _, e in pk do
		local g = golems[e[1]]
		if g then
			g.tx, g.tz, g.tyaw = e[2], e[3], e[4]
			if not g.x then g.x, g.z, g.yaw = e[2], e[3], e[4] end
			local hp = e[5]
			if hp < g.hp and g.bar then
				-- удар: вспишка й «хвіст»
				g.bar.ghost.Size = UDim2.fromScale(g.hp / g.max, 1)
				tween(g.bar.ghost, 0.45, { Size = UDim2.fromScale(hp / g.max, 1) })
				g.flash = os.clock()
			end
			g.hp = hp
			g.st = e[6]
		end
	end
end)

-- ===== GOBKING: анімація v2 (05.11.2026) =====
-- Сервер ставить модель цілком (Hitbox — PrimaryPart, поворот до цілі); клієнт щокадру розставляє деталі по суглобах (папка Joints,
--   атрибут деталі J). Атака — ключові кадри з власним згладжуванням кожного відрізка: підготовка (out) → важкий замах (inout) →
--   різкий удар (in3, рівно в момент удару сервера) → «застигання» з тремтінням → низька поза → повернення з перехльостом (back).
--   Ноги — без батька (ступні на землі), руки, що не б'ють, підтягуються при присіданні. Слід кулака (Trail) — лише на мить удару.
local A = { m = nil :: Model?, hb = nil :: BasePart?, joints = {}, order = {}, parts = {}, list = {}, cfs = {}, yaw = nil :: number?,
	atk = nil :: string?, t0 = 0, warn = 1.5, side = 0, dead = false, trails = {} }
local function animInit(m: Model): boolean
	local hb = m:FindFirstChild("Hitbox") :: BasePart?
	local jf = m:FindFirstChild("Joints")
	if not hb or not jf then return false end
	A.m, A.hb, A.dead, A.atk, A.yaw, A.pos, A.spd = m, hb, false, nil, nil, nil, 0
	A.die = nil -- 06.11.2026: новий бій — без анімації смерті
	A.sc = (m:GetAttribute("BossScale") :: number?) or 1 -- 06.11.2026: масштаб моделі (×6 = 0,75 від ×8) — зсуви поз у студах множимо
	A.joints, A.order, A.parts, A.list, A.cfs, A.trails = {}, {}, {}, {}, {}, {}
	for _, v in jf:GetChildren() do
		if v:IsA("CFrameValue") then A.joints[v.Name] = { rest = v.Value, parent = v:GetAttribute("Parent") } end
	end
	local done = {}
	local function add(n)
		if done[n] then return end
		local j = A.joints[n]
		if j.parent and A.joints[j.parent] then add(j.parent) end
		done[n] = true
		table.insert(A.order, n)
	end
	for n in A.joints do add(n) end
	for _, j in A.joints do j.rel = (j.parent and A.joints[j.parent]) and A.joints[j.parent].rest:Inverse() * j.rest or j.rest end
	-- поза збірки (атрибут BuildCF від сервера): деталі, крім Hitbox, на сервері стоять у ній завжди — зміщення рахуємо від неї
	local base = m:GetAttribute("BuildCF") or hb.CFrame
	local function addPart(p: Instance)
		if p:IsA("BasePart") and p ~= hb then
			local j = A.joints[p:GetAttribute("J") or ""]
			if j then
				table.insert(A.parts, { p = p, j = p:GetAttribute("J"), off = j.rest:Inverse() * base:ToObjectSpace(p.CFrame) })
				table.insert(A.list, p)
			end
		elseif p:IsA("Trail") and p.Parent then
			A.trails[p.Parent.Name] = p
		end
	end
	for _, p in m:GetDescendants() do addPart(p) end
	if A.conn then A.conn:Disconnect() end
	A.conn = m.DescendantAdded:Connect(addPart) -- деталі, що догрузилися пізніше (стрімінг), теж анімуються
	return true
end
local stepFx: (Vector3) -> () = function() end -- важкий крок (визначено нижче, у VFX)
local dieFx: (number, Vector3) -> () = function() end -- 06.11.2026: етапи смерті боса (1 — рик, 2 — удар, 3 — відскок, 4 — осипання)
local EASE = {
	out = function(k) return 1 - (1 - k) * (1 - k) end,
	inout = function(k) return k < 0.5 and 2 * k * k or 1 - (-2 * k + 2) ^ 2 / 2 end,
	in2 = function(k) return k * k end,
	in3 = function(k) return k * k * k end,
	back = function(k) local c1 = 1.70158; local c3 = c1 + 1; return 1 + c3 * (k - 1) ^ 3 + c1 * (k - 1) ^ 2 end,
}
local function idlePose(t: number): any
	local b = math.sin(t * 1.5)
	local sw = math.sin(t * 0.75)
	return {
		Root = { 0, 0.03 * sw, 0, 0.35 * b, 0 }, Torso = { -0.14 + 0.03 * b, 0.04 * sw, 0, 0, 0 },
		Head = { 0.06 * math.sin(t * 1.5 + 0.7), -0.06 * sw, 0, 0, 0 }, Jaw = { -0.05 - 0.04 * b, 0, 0, 0, 0 },
		ArmL = { 0.08 * math.sin(t * 1.5 + 0.4), 0, -0.07, 0, 0 }, ArmR = { 0.08 * math.sin(t * 1.5 + 1), 0, 0.07, 0, 0 },
		ForeL = { 0.2, 0, 0, 0, 0 }, ForeR = { 0.2, 0, 0, 0, 0 },
	}
end
-- ключові кадри: { час, поза | "hold" | "idle", згладжування відрізка, що закінчується цим кадром }
local function attackKeys(key: string, w: number, s: number): any
	if key == "Slam" then
		return {
			{ 0.32, { Root = { 0, 0, 0, -1.2, 0.6 }, Torso = { -0.05 }, Head = { -0.1 }, ArmL = { -0.55, 0, -0.1 }, ArmR = { -0.55, 0, 0.1 }, ForeL = { 0.5 }, ForeR = { 0.5 } }, "out" },
			{ w - 0.2, { Root = { 0, 0, 0, 1.6, 1.2 }, Torso = { 0.28 }, Head = { 0.32 }, Jaw = { -0.35 }, ArmL = { 2.95, 0, -0.12 }, ArmR = { 2.95, 0, 0.12 }, ForeL = { 0.75 }, ForeR = { 0.75 } }, "inout" },
			{ w, { Root = { 0, 0, 0, -2.2, -2 }, Torso = { -0.47 }, Head = { -0.2 }, Jaw = { -0.15 }, ArmL = { 1.0, 0, 0.12 }, ArmR = { 1.0, 0, -0.12 }, ForeL = { 0.2 }, ForeR = { 0.2 } }, "in3" },
			{ w + 0.14, "hold" },
			{ w + 0.6, { Root = { 0, 0, 0, -1.6, -1.2 }, Torso = { -0.36 }, Head = { 0.05 }, ArmL = { 0.8, 0, 0.1 }, ArmR = { 0.8, 0, -0.1 }, ForeL = { 0.3 }, ForeR = { 0.3 } }, "out" },
			{ w + 1.35, "idle", "back" },
		}, { FistL = { w - 0.22, w + 0.05 }, FistR = { w - 0.22, w + 0.05 } }
	elseif key == "Sweep" then
		local arm, fore, other = s < 0 and "ArmL" or "ArmR", s < 0 and "ForeL" or "ForeR", s < 0 and "ArmR" or "ArmL"
		return {
			{ 0.3, { Root = { 0, 0, 0, -0.8, 0 }, Torso = { -0.1, -s * 0.2 }, [arm] = { 0.2, 0, s * 0.35 } }, "out" },
			{ w - 0.22, { Root = { 0, 0, 0, 0.5, 1 }, Torso = { -0.1, -s * 0.62 }, Head = { 0.1, -s * 0.3 }, Jaw = { -0.25 }, [arm] = { -0.6, 0, s * 1.15 }, [fore] = { 0.45 }, [other] = { 0.45, 0, -s * 0.25 } }, "inout" },
			{ w - 0.06, { Root = { 0, 0, 0, -2.6, -0.5 }, Torso = { -0.28, 0 }, [arm] = { 0, 0, s * 0.6 }, [fore] = { 0.1 }, [other] = { 0.4, 0, -s * 0.2 } }, "in2" },
			{ w + 0.12, { Root = { 0, 0, 0, -2.4, -1 }, Torso = { -0.25, s * 0.6 }, Head = { 0, s * 0.35 }, [arm] = { 0.35, 0, s * 0.6 }, [fore] = { 0.1 }, [other] = { 0.4, 0, -s * 0.2 } }, "out" },
			{ w + 0.35, "hold" },
			{ w + 1.25, "idle", "back" },
		}, { [s < 0 and "FistL" or "FistR"] = { w - 0.26, w + 0.14 } }
	elseif key == "Eruption" then
		return {
			{ 0.3, { Root = { 0, 0, 0, -1, 0.4 }, Torso = { 0, 0.25 }, ArmR = { -0.5, 0, 0.2 }, ForeR = { 0.6 } }, "out" },
			{ w - 0.2, { Root = { 0, 0, 0, 1.2, 1 }, Torso = { 0.22, 0.3 }, Head = { 0.25, 0.1 }, Jaw = { -0.3 }, ArmR = { 2.85, 0, 0.25 }, ForeR = { 0.8 }, ArmL = { 0.5, 0, -0.4 } }, "inout" },
			{ w, { Root = { 0, 0, 0, -2.2, -2 }, Torso = { -0.5, -0.1 }, Head = { -0.15 }, ArmR = { 1.05, 0, -0.1 }, ForeR = { 0.2 }, ArmL = { 0.45, 0, -0.35 } }, "in3" },
			{ w + 0.14, "hold" },
			{ w + 0.6, { Root = { 0, 0, 0, -1.5, -1.2 }, Torso = { -0.35, -0.05 }, ArmR = { 0.85, 0, -0.05 }, ForeR = { 0.3 }, ArmL = { 0.4, 0, -0.3 } }, "out" },
			{ w + 1.3, "idle", "back" },
		}, { FistR = { w - 0.22, w + 0.05 } }
	elseif key == "RockRain" then
		return {
			{ 0.35, { Root = { 0, 0, 0, -1.6, 0 }, Torso = { -0.25 }, Head = { -0.2 }, ArmL = { 0.3, 0, 0.25 }, ArmR = { 0.3, 0, -0.25 }, ForeL = { 0.9 }, ForeR = { 0.9 } }, "out" },
			{ w * 0.55, { Root = { 0, 0, 0, 1.8, 0.6 }, Torso = { 0.32 }, Head = { 0.6 }, Jaw = { -0.65 }, ArmL = { 2.4, 0, -0.85 }, ArmR = { 2.4, 0, 0.85 }, ForeL = { 0.25 }, ForeR = { 0.25 } }, "back" },
			{ w + 0.25, "hold" },
			{ w + 1.1, "idle", "inout" },
		}, {}
	end
	return { { 0.4, "idle", "out" } }, {}
end
local function blendPose(a: any, b: any, k: number): any
	local out = {}
	for n in A.joints do
		local pa, pb = a[n] or {}, b[n] or {}
		local q = {}
		for i = 1, 5 do q[i] = (pa[i] or 0) + ((pb[i] or 0) - (pa[i] or 0)) * k end
		out[n] = q
	end
	return out
end
local function currentPose(t: number): any
	local idle = idlePose(t)
	if not A.atk then return idle end
	local keys, trails = attackKeys(A.atk, A.warn, A.side ~= 0 and A.side or 1)
	local age = os.clock() - A.t0
	for name, tr in A.trails do
		local win = trails[name]
		tr.Enabled = win ~= nil and age >= win[1] and age <= win[2]
	end
	local prevT, prevP = 0, idle
	for _, kf in keys do
		local kt, kp, ez = kf[1], kf[2], kf[3]
		if kp == "hold" then kp = prevP elseif kp == "idle" then kp = idle end
		if age <= kt then
			local k = math.clamp((age - prevT) / math.max(0.01, kt - prevT), 0, 1)
			local pose = blendPose(prevP, kp, (EASE[ez or "inout"] or EASE.inout)(k))
			-- тремтіння: «застигання» після удару та рик
			local trem = (kf[2] == "hold" and (A.atk == "RockRain" and 0.35 or 0.22)) or 0
			if trem > 0 and pose.Root then
				pose.Root[4] += (math.random() - 0.5) * trem
				pose.Root[2] += (math.random() - 0.5) * trem * 0.04
			end
			return pose
		end
		prevT, prevP = kt, kp
	end
	A.atk = nil
	for _, tr in A.trails do tr.Enabled = false end
	return idle
end
-- тряска камери (затухання) + «удар» поля зору
local shakeT0, shakeDur, shakeAmp = 0, 0, 0
local fovKick = 0
local baseFov: number? = nil
local function shake(amp: number, dur: number)
	local left = math.max(0, shakeT0 + shakeDur - os.clock()) / math.max(0.01, shakeDur) * shakeAmp
	if amp >= left then shakeT0, shakeDur, shakeAmp = os.clock(), dur, amp end
end
RunService:BindToRenderStep("BossCamShake", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = workspace.CurrentCamera
	local age = os.clock() - shakeT0
	if age < shakeDur then
		local k = (1 - age / shakeDur) ^ 2 * shakeAmp
		local t = os.clock() * 28
		cam.CFrame = cam.CFrame * CFrame.new(math.noise(t, 1.3) * k, math.noise(t, 7.1) * k, 0) * CFrame.Angles(math.noise(t, 3.7) * k * 0.012, 0, math.noise(t, 9.9) * k * 0.01)
	end
	if fovKick > 0.01 then
		if not baseFov then baseFov = cam.FieldOfView end
		cam.FieldOfView = baseFov + fovKick
		fovKick *= 0.86
		if fovKick <= 0.01 then cam.FieldOfView = baseFov; baseFov = nil end
	end
end)
-- 06.11.2026: смерть боса (перемога): рик і відкид назад → коліна підгинаються → падає обличчям уперед (опора — передній
--   нижній край хітбоксу) → удар об землю (пил, уламки, тряска), відскок → лежить і осипається (прозорість). Вікно нагород —
--   через DIE_LEN + 2 с після початку (BossResult чекає)
local DIE_LEN = 3.2
local DIE_KEYS = {
	{ 0.55, { Root = { 0.12, 0, 0, 1.2, 1.4 }, Torso = { 0.4 }, Head = { 0.55 }, Jaw = { -0.75 }, ArmL = { 1.5, 0, -1.0 }, ArmR = { 1.5, 0, 1.0 }, ForeL = { 0.7 }, ForeR = { 0.7 } }, "out" },
	{ 1.35, { Root = { -0.1, 0, 0.06, -3.2, -0.6 }, Torso = { -0.3 }, Head = { -0.25 }, Jaw = { -0.35 }, ArmL = { -0.5, 0, -0.35 }, ArmR = { -0.6, 0, 0.3 }, ForeL = { 0.4 }, ForeR = { 0.5 }, LegL = { 0.55 }, LegR = { 0.45 } }, "inout" },
	{ 2.25, { Root = { 0, 0, 0.04, -3.2, -0.6 }, Torso = { -0.15 }, Head = { 0.35 }, Jaw = { -0.2 }, ArmL = { 2.6, 0, -0.5 }, ArmR = { 2.6, 0, 0.5 }, ForeL = { 0.2 }, ForeR = { 0.2 }, LegL = { -0.3 }, LegR = { -0.3 } }, "in2" },
}
local function dieFall(t: number): number
	if t < 1.2 then return 0 end
	if t < 2.25 then local k = (t - 1.2) / 1.05; return -1.4 * k * k * k end
	if t < 2.5 then local k = (t - 2.25) / 0.25; return -1.4 + 0.1 * (1 - (1 - k) * (1 - k)) end
	if t < 2.8 then local k = (t - 2.5) / 0.3; return -1.3 - 0.1 * k * k end
	return -1.4
end
local function diePose(t: number, root: CFrame, hb: BasePart): (any, CFrame)
	local prevT, prevP = 0, idlePose(0)
	local pose = nil
	for _, kf in DIE_KEYS do
		if t <= kf[1] then
			local k = math.clamp((t - prevT) / math.max(0.01, kf[1] - prevT), 0, 1)
			pose = blendPose(prevP, kf[2], (EASE[kf[3]] or EASE.inout)(k))
			break
		end
		prevT, prevP = kf[1], kf[2]
	end
	pose = pose or blendPose(prevP, prevP, 1)
	local hY, hZ = hb.Size.Y / 2, hb.Size.Z / 2
	local base = root * CFrame.new(0, -hY, -hZ)
	local r2 = base * CFrame.Angles(dieFall(t), 0, 0) * CFrame.new(0, hY, hZ)
	if t > 3.6 then r2 = r2 - Vector3.new(0, math.min(4, (t - 3.6) * 2), 0) end -- осідає в землю
	-- удар об землю й відскок
	if t >= 2.25 and not A.dieHit then
		A.dieHit = true
		dieFx(2, (base * CFrame.new(0, 0, -hY * 0.85)).Position)
	end
	if t >= 2.8 and not A.dieHit2 then
		A.dieHit2 = true
		dieFx(3, (base * CFrame.new(0, 0, -hY * 0.6)).Position)
	end
	if t >= 3.0 and not A.dieFade then
		A.dieFade = true
		dieFx(4, base.Position)
	end
	return pose, r2
end
local function animStep()
	local bm = workspace:FindFirstChild("Boss Map")
	local m = bm and bm:FindFirstChild("Boss")
	if not m or not m:IsA("Model") then A.m = nil; return end
	if A.m ~= m and not animInit(m) then return end
	if not A.hb or (A.dead and not A.die) then return end
	local hb = A.hb :: BasePart
	local now = os.clock()
	local dt = math.clamp(now - (A.lastT or now), 0, 0.1)
	A.lastT = now
	local lv = hb.CFrame.LookVector
	local yaw = math.atan2(-lv.X, -lv.Z)
	if not A.yaw then A.yaw = yaw end
	local dy = (yaw - A.yaw + math.pi) % (2 * math.pi) - math.pi
	A.yaw += dy * (A.atk and 0.22 or 0.1) -- під час атаки розвертається швидше
	-- 05.11.2026: бос ходить — сервер рухає лише Hitbox (10 разів/с), тут плавно доганяємо й міряємо швидкість для ходьби
	local prev = A.pos or hb.Position
	A.pos = prev + (hb.Position - prev) * math.min(1, dt * 9)
	local v = dt > 0 and Vector3.new(A.pos.X - prev.X, 0, A.pos.Z - prev.Z).Magnitude / dt or 0
	A.spd += (v - A.spd) * math.min(1, dt * 6)
	local root = CFrame.new(A.pos) * CFrame.Angles(0, A.yaw :: number, 0)
	local pose = currentPose(now)
	if A.die then pose, root = diePose(now - A.die, root, hb) end
	-- ходьба: крок ногами, гойдання тулуба й рук, важкі кроки з пилом і тряскою
	local amp = (A.atk or A.die) and 0 or math.clamp(A.spd / 7, 0, 1)
	if amp > 0.02 then
		local ph0 = A.ph or 0
		A.ph = ph0 + dt * (2.2 + A.spd * 0.18)
		local s, c = math.sin(A.ph), math.cos(A.ph)
		pose.LegL = { 0.42 * s * amp, 0, 0, 0, 0 }
		pose.LegR = { -0.42 * s * amp, 0, 0, 0, 0 }
		local r, t, h, al, ar = pose.Root or {}, pose.Torso or {}, pose.Head or {}, pose.ArmL or {}, pose.ArmR or {}
		pose.Root = { r[1] or 0, (r[2] or 0) + 0.08 * s * amp, (r[3] or 0) + 0.05 * s * amp, (r[4] or 0) + (math.abs(c) * 1.1 - 0.9) * amp, r[5] or 0 }
		pose.Torso = { (t[1] or 0) - 0.08 * amp, (t[2] or 0) - 0.1 * s * amp, (t[3] or 0) - 0.04 * s * amp, 0, 0 }
		pose.Head = { (h[1] or 0) + 0.05 * c * amp, (h[2] or 0) + 0.08 * s * amp, 0, 0, 0 }
		pose.ArmL = { (al[1] or 0) - 0.38 * s * amp, al[2] or 0, al[3] or 0, 0, 0 }
		pose.ArmR = { (ar[1] or 0) + 0.38 * s * amp, ar[2] or 0, ar[3] or 0, 0, 0 }
		if math.floor(A.ph / math.pi) ~= math.floor(ph0 / math.pi) and amp > 0.5 then
			local side = (math.floor(A.ph / math.pi) % 2 == 0) and 1 or -1
			local foot = (root * CFrame.new(7.5 * A.sc * side, 0, -2 * A.sc)).Position
			stepFx(Vector3.new(foot.X, floorY(), foot.Z))
		end
	end
	local world = {}
	for _, n in A.order do
		local j = A.joints[n]
		local q = pose[n] or {}
		local pw = (j.parent and world[j.parent]) or root
		world[n] = pw * j.rel * CFrame.new(0, (q[4] or 0) * A.sc, (q[5] or 0) * A.sc) * CFrame.Angles(q[1] or 0, q[2] or 0, q[3] or 0) -- tz < 0 — уперед
	end
	for i, e in A.parts do A.cfs[i] = world[e.j] * e.off end
	workspace:BulkMoveTo(A.list, A.cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

-- ===== VFX ударів (05.11.2026 v2): пил (ParticleEmitter), ударна хвиля, уламки з фізикою, тріщини, спалах світла =====
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local function anchor(pos: Vector3, life: number): BasePart
	local p = zonePart(CFrame.new(pos), Vector3.new(0.2, 0.2, 0.2), WHITE, 1, false)
	task.delay(life, function() p:Destroy() end)
	return p
end
local function dust(pos: Vector3, n: number, speed: number, s0: number, s1: number, col: Color3?)
	local a = anchor(pos + Vector3.new(0, 1, 0), 3)
	local e = new("ParticleEmitter", { Texture = SMOKE, Enabled = false, Color = ColorSequence.new(col or C("a7aeb5"), C("6e7780")),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s0), NumberSequenceKeypoint.new(1, s1) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.55, 0.45), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.8, 1.5), Speed = NumberRange.new(speed * 0.45, speed), SpreadAngle = Vector2.new(88, 88),
		Drag = 3.5, Acceleration = Vector3.new(0, 3, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-70, 70),
		LightInfluence = 0.7, ZOffset = 1 }, a)
	e:Emit(n)
end
local function sparks(pos: Vector3, n: number, col: Color3)
	local a = anchor(pos + Vector3.new(0, 2, 0), 2.5)
	local e = new("ParticleEmitter", { Texture = SPARK, Enabled = false, Color = ColorSequence.new(col), LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(14, 30), SpreadAngle = Vector2.new(60, 60), Drag = 2,
		Acceleration = Vector3.new(0, -25, 0) }, a)
	e:Emit(n)
end
local function ring(pos: Vector3, r: number, col: Color3, dur: number, tr0: number)
	local p = zonePart(CFrame.new(pos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.5, 2, 2), col, tr0, true)
	p.Shape = Enum.PartType.Cylinder
	tween(p, dur, { Size = Vector3.new(0.3, r * 2, r * 2), Transparency = 1 }, Enum.EasingStyle.Quart).Completed:Connect(function() p:Destroy() end)
end
local function flash(pos: Vector3, col: Color3, range: number, br: number)
	local a = anchor(pos + Vector3.new(0, 4, 0), 1)
	local l = new("PointLight", { Color = col, Range = range, Brightness = br, Shadows = false }, a)
	tween(l, 0.45, { Brightness = 0 })
end
local function debris(pos: Vector3, n: number, size: number, power: number, cols: { Color3 }, neon: boolean?)
	for _ = 1, n do
		local s = size * (0.5 + math.random() * 0.8)
		local p = new("Part", { Anchored = false, CanCollide = true, CanQuery = false, CanTouch = false, Massless = true, CastShadow = true,
			Size = Vector3.new(s, s * (0.6 + math.random() * 0.6), s), Color = cols[math.random(1, #cols)],
			Material = neon and Enum.Material.Neon or Enum.Material.Plastic,
			CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 3, 1 + s, (math.random() - 0.5) * 3)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) }, fxFolder)
		if not neon then p.MaterialVariant = "Studs" end
		local a = math.random() * math.pi * 2
		p.AssemblyLinearVelocity = Vector3.new(math.cos(a), 0, math.sin(a)) * power * (0.4 + math.random() * 0.6) + Vector3.new(0, power * (0.9 + math.random() * 0.8), 0)
		p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 18
		task.delay(1.4 + math.random() * 0.6, function()
			if p.Parent then tween(p, 0.5, { Transparency = 1 }).Completed:Connect(function() p:Destroy() end) end
		end)
	end
end
local function cracks(pos: Vector3, n: number, len: number)
	local y = floorY() + 0.06
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + (math.random() - 0.5) * 0.6
		local l = len * (0.5 + math.random() * 0.7)
		local cf = CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -l / 2)
		local p = zonePart(cf, Vector3.new(0.5 + math.random() * 0.5, 0.12, l), C("15181c"), 0.15, false)
		task.delay(2.2, function() tween(p, 0.8, { Transparency = 1 }).Completed:Connect(function() p:Destroy() end) end)
	end
end
local function nearBoss(r: number): boolean
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	return hrp ~= nil and A.hb ~= nil and (hrp.Position - (A.hb :: BasePart).Position).Magnitude <= r
end
local STONES = { C("4b5866"), C("3e4954"), C("56646f") }
stepFx = function(pos: Vector3)
	sfx("Footstep", pos, { spd = 0.85, var = 0.07, min = 25, max = 180 })
	dust(pos, 6, 16, 3, 8)
	if nearBoss(70) then shake(0.45, 0.22) end
end
local function impact(pos: Vector3, big: number)
	dust(pos, math.floor(18 * big), 34 * big, 5 * big, 13 * big)
	ring(pos, 22 * big, C("e8eef2"), 0.4, 0.15)
	ring(pos, 30 * big, C("8d969e"), 0.7, 0.45)
	debris(pos, math.floor(7 * big), 2.2, 32 * big, STONES)
	cracks(pos, 7, 10 * big)
	flash(pos, C("fff2d6"), 45 * big, 5)
end
dieFx = function(stage: number, pos: Vector3)
	local p = Vector3.new(pos.X, floorY(), pos.Z)
	if stage == 1 then
		local hp = bossHead()
		if hp then sfx("AttackScream", hp, { spd = 0.72, vol = 1.2, min = 40, max = 320 }) end
		if nearBoss(160) then shake(0.7, 1.2) end
	elseif stage == 2 then
		sfx("Punch", p, { spd = 0.7, vol = 1.4, min = 40, max = 320 })
		impact(p, 2)
		dust(p + Vector3.new(0, 0, 0), 30, 40, 8, 18)
		if nearBoss(200) then shake(2.4, 1.1); fovKick = math.max(fovKick, 9) end
	elseif stage == 3 then
		sfx("Punch", p, { spd = 0.95, vol = 0.7, min = 30, max = 260 })
		impact(p, 1)
		if nearBoss(200) then shake(1, 0.5) end
	elseif stage == 4 then
		local m = A.m
		if m then
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Name ~= "Hitbox" then tween(d, 2, { Transparency = 1 }, Enum.EasingStyle.Quad) end
			end
		end
		dust(p, 24, 18, 10, 22, C("8d969e"))
	end
end
local function crystalSpikes(r: any)
	local y = floorY()
	local center = Vector3.new(r.cx, y, r.cz)
	for i = 1, 5 do
		local h = 8 + math.random() * 8
		local w = 2.5 + math.random() * 2
		local x, z = (math.random() - 0.5) * r.w * 0.75, (math.random() - 0.5) * r.d * 0.75
		local base = CFrame.new(r.cx, y, r.cz) * CFrame.Angles(0, r.yaw, 0) * CFrame.new(x, 0, z)
			* CFrame.Angles((math.random() - 0.5) * 0.7, math.random() * 3, (math.random() - 0.5) * 0.7) * CFrame.Angles(0, math.rad(45), 0)
		local body = zonePart(base * CFrame.new(0, -h / 2, 0), Vector3.new(w, h, w), C("3fdc4f"), 0, true)
		local face = zonePart(base * CFrame.new(-w * 0.18, -h / 2, 0), Vector3.new(w * 0.3, h * 0.85, w * 1.04), C("b6ffb0"), 0, true)
		local up = base * CFrame.new(0, h / 2 - 0.6, 0)
		local upF = base * CFrame.new(-w * 0.18, h / 2 - 0.9, 0)
		tween(body, 0.16, { CFrame = up }, Enum.EasingStyle.Back)
		tween(face, 0.16, { CFrame = upF }, Enum.EasingStyle.Back)
		task.delay(1.1 + math.random() * 0.3, function()
			debris((up * CFrame.new(0, h / 4, 0)).Position, 3, 1.1, 16, { C("3fdc4f"), C("b6ffb0") }, true)
			for _, p in { body, face } do
				tween(p, 0.35, { CFrame = p.CFrame * CFrame.new(0, -h * 0.6, 0), Transparency = 1 }).Completed:Connect(function() p:Destroy() end)
			end
		end)
	end
	dust(center, 12, 24, 4, 10, C("9fb59a"))
	sparks(center, 24, C("8dff86"))
	flash(center, C("5fff6a"), 30, 4)
	cracks(center, 5, 7)
end
local function fallingRocks(rects: any, warn: number)
	local fall = 0.6
	task.delay(math.max(0, warn - fall), function()
		for _, r in rects do
			local s = 5 + math.random() * 3
			local land = Vector3.new(r.cx, floorY() + s / 2, r.cz)
			-- звук на кожен камінь: початок удару звуку (~0,13 с) = мить падіння; розкид висоти/затримки — відчуття «багато каменів»
			local rsp = 0.88 + math.random() * 0.24
			sfx("RocksFall", Vector3.new(r.cx, floorY() + 2, r.cz), { spd = rsp, vol = 1, min = 30, max = 170, delay = math.max(0, fall - 0.13 / rsp + math.random() * 0.06) })
			local rock = zonePart(CFrame.new(land + Vector3.new(0, 80, 0)) * CFrame.Angles(math.random() * 3, math.random() * 3, 0), Vector3.new(s, s * 0.9, s), C("4b5866"), 0, false)
			rock.MaterialVariant = "Studs"; rock.Material = Enum.Material.Plastic; rock.CastShadow = true
			local chunk = new("Part", { Anchored = false, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true, Size = Vector3.new(s * 0.6, s * 0.5, s * 0.6),
				Color = C("3e4954"), Material = Enum.Material.Plastic, MaterialVariant = "Studs", CFrame = rock.CFrame * CFrame.new(s * 0.35, s * 0.35, -s * 0.2) }, rock)
			new("WeldConstraint", { Part0 = rock, Part1 = chunk }, rock)
			local a0 = new("Attachment", { Position = Vector3.new(0, s * 0.4, 0) }, rock)
			local a1 = new("Attachment", { Position = Vector3.new(0, -s * 0.4, 0) }, rock)
			new("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.25, Color = ColorSequence.new(C("c9ced3")), LightEmission = 0.2,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, rock)
			-- тінь, що росте під каменем
			local sh = zonePart(CFrame.new(r.cx, floorY() + 0.3, r.cz) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.1, 1, 1), C("101215"), 0.75, false)
			sh.Shape = Enum.PartType.Cylinder
			tween(sh, fall, { Size = Vector3.new(0.1, s * 1.6, s * 1.6), Transparency = 0.35 }, Enum.EasingStyle.Quad)
			local tw = TweenService:Create(rock, TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ CFrame = CFrame.new(land) * CFrame.Angles(math.random() * 3, math.random() * 3, 0) })
			tw:Play()
			tw.Completed:Connect(function()
				sh:Destroy()
				sfx("Punch", Vector3.new(land.X, floorY() + 2, land.Z), { spd = 1.25, var = 0.1, vol = 0.5, min = 25, max = 150 }) -- глухий удар каменя об землю
				impact(Vector3.new(land.X, floorY(), land.Z), 0.6)
				task.wait(0.5)
				tween(rock, 0.5, { Transparency = 1, Size = rock.Size * 0.5 }).Completed:Connect(function() rock:Destroy() end)
				if chunk.Parent then tween(chunk, 0.5, { Transparency = 1 }) end
			end)
		end
	end)
end
local function attackFx(key: string, rects: any, warn: number)
	-- 04.11.2026: голос боса під замах (розтягнутий під тривалість замаху) і удар кулака/ноги в мить удару (пік звуку = удар)
	local hp = bossHead()
	if hp then
		if key == "RockRain" then
			local roar = warn * 0.45 + 0.45 -- рик: від w·0,55 до кінця «застигання»
			sfx("AttackScream", hp, { spd = math.clamp(1.16 / roar, 0.75, 1.1), min = 40, max = 300, delay = math.max(0, warn * 0.55 - 0.15) })
		else
			local up = math.max(0.3, warn - 0.52) -- замах: від 0,32 с до w − 0,2
			local nm = math.random() < 0.5 and "Scream1" or "Scream2"
			sfx(nm, hp, { spd = math.clamp(0.75 / up, 0.72, 1.05), min = 35, max = 280, delay = 0.32 })
		end
	end
	if key ~= "RockRain" then
		task.delay(math.max(0, warn - 0.04), function()
			local bp = bossHead()
			for i, r in rects do
				if i > 2 then break end
				local p = Vector3.new(r.cx, floorY() + 2, r.cz)
				if key == "Eruption" and bp then
					p = (CFrame.new(bp.X, floorY() + 2, bp.Z) * CFrame.Angles(0, A.yaw or 0, 0) * CFrame.new(14, 0, -32)).Position
				end
				sfx("Punch", p, { spd = key == "Slam" and 0.82 or (key == "Sweep" and 1.05 or 0.92), vol = key == "Slam" and 1.3 or 1, var = 0.04, min = 35, max = 300 })
				if key == "Eruption" then break end
			end
		end)
	end
	if key == "RockRain" then
		fallingRocks(rects, warn)
		task.delay(warn * 0.55, function() if nearBoss(140) then shake(0.9, warn * 0.45 + 0.3) end end) -- рик
		return
	end
	task.delay(warn, function()
		for _, r in rects do
			local center = Vector3.new(r.cx, floorY(), r.cz)
			local cf = CFrame.new(r.cx, floorY(), r.cz) * CFrame.Angles(0, r.yaw, 0)
			if key == "Slam" then
				for _, lx in { -0.4, 0.4 } do impact((cf * CFrame.new(r.w * lx, 0, r.d * 0.15)).Position, 1) end
				ring(center, 46, C("8d969e"), 0.9, 0.5)
				if nearBoss(140) then shake(2.4, 0.6); fovKick = 7 end
			elseif key == "Sweep" then
				for i = 0, 5 do
					task.delay(i * 0.045, function()
						local p = (cf * CFrame.new(0, 0, r.d / 2 - (i + 0.5) * r.d / 6)).Position
						dust(p, 7, 26, 4, 10); debris(p, 2, 1.8, 22, STONES)
					end)
				end
				cracks(center, 4, 12)
				if nearBoss(140) then shake(1.5, 0.45); fovKick = 4 end
			elseif key == "Eruption" then
				crystalSpikes(r)
			end
		end
		if key == "Eruption" and nearBoss(140) then shake(1.6, 0.45); fovKick = 4 end
	end)
	-- удар кулака боса об землю перед Eruption (у точці кулака)
	if key == "Eruption" and A.hb then
		task.delay(warn, function()
			if not A.hb then return end
			local hb = A.hb :: BasePart
			local p = (CFrame.new(hb.Position.X, floorY(), hb.Position.Z) * CFrame.Angles(0, A.yaw or 0, 0) * CFrame.new(14, 0, -32)).Position
			impact(p, 0.8)
		end)
	end
end
local function bossAnim(kind, key, warn, side)
	local bm = workspace:FindFirstChild("Boss Map")
	local m = bm and bm:FindFirstChild("Boss")
	if not m then return end
	if kind == "attack" then
		A.atk, A.t0, A.warn, A.side = tostring(key), os.clock(), tonumber(warn) or 1.5, tonumber(side) or 0
	elseif kind == "die" then
		-- 06.11.2026: перемога — анімація смерті (diePose у animStep), а не просто зникнення
		if not A.die then
			A.dead, A.die, A.atk, A.dieHit, A.dieHit2, A.dieFade = true, os.clock(), nil, nil, nil, nil
			for _, tr in A.trails do tr.Enabled = false end
			if A.hb then dieFx(1, (A.hb :: BasePart).Position) end
		end
	elseif kind == "escape" then
		A.dead = true
		for _, tr in A.trails do tr.Enabled = false end
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "Hitbox" then
				tween(d, 1.2, { Transparency = 1, CFrame = d.CFrame + Vector3.new(0, 12, 0) })
			end
		end
	end
end

remotes:WaitForChild("BossFx").OnClientEvent:Connect(function(kind, a, b, c, d)
	if kind == "spawn" then spawnGolems(a)
	elseif kind == "warn" then drawRects(a, c, d); attackFx(tostring(b), c, tonumber(d) or 1.5)
	elseif kind == "hit" then hitRects(a)
	elseif kind == "dead" then killGolem(a)
	elseif kind == "dmg" then dmgPops(a)
	elseif kind == "boss" then bossAnim(a, b, c, d)
	end
end)

remotes:WaitForChild("BossResult").OnClientEvent:Connect(function(r)
	-- 06.11.2026: перемога — вікно лише після анімації смерті боса й ще 2 с
	if r.win then
		local w0 = os.clock()
		while not A.die and os.clock() - w0 < 0.8 do task.wait() end
		task.wait(math.max(0, (A.die or os.clock()) + DIE_LEN + 2 - os.clock()))
	end
	lastRes = r
	resTitle.Text = r.win and "VICTORY!" or "BOSS ESCAPED"
	resTitle.TextColor3 = r.win and C("b8ff8a") or C("ff8a8a")
	resSub.Text = r.win and (tostring(BDEF.name) .. " defeated") or (r.why == "wiped" and "Your warriors fell — no Fossil Teeth" or "Time ran out — no Fossil Teeth")
	statV[1].Text = "#" .. tostring(r.place)
	countUp(statV[2], r.dmg or 0, function(x) return NF.short(math.floor(x)) end, 0.9, 0.25)
	countUp(statV[3], math.floor((r.share or 0) * 100 + 0.5), function(x) return string.format("%d%%", math.floor(x + 0.5)) end, 0.9, 0.35)
	toothIm.Visible = (r.teeth or 0) > 0
	countUp(toothT, r.teeth or 0, function(x) return "+" .. math.floor(x + 0.5) end, 0.8, 1.0)
	countUp(diaT, r.dia or 0, function(x) return "+" .. math.floor(x + 0.5) end, 0.8, 1.15)
	diaIm.Visible = (r.dia or 0) > 0
	loseNote.Text = "" -- 06.11.2026: «Diamonds ×0.1» прибрано (зайва для гравця інфа)
	okBtn:setColor(r.win and "green" or "gray"); okBtn:setText(r.win and "CLAIM" or "OK")
	res.Visible = true
	resScale.Scale = 0.85
	tween(resScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
end)

-- ===== кадр =====
local thumbs = {}
local function thumb(uid, im)
	if thumbs[uid] then im.Image = thumbs[uid]; return end
	thumbs[uid] = ""
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok and url then thumbs[uid] = url; im.Image = url end
	end)
end
local function names(): { [number]: string }
	local m = {}
	for _, p in Players:GetPlayers() do m[p.UserId] = p.DisplayName end
	return m
end

local lastUi = 0
local lastHide = 0
local shownHp = 1
RunService.RenderStepped:Connect(function(dt)
	animStep()
	local active = player:GetAttribute("InBossArena") == true and (workspace:GetAttribute("BossPhase") == "fight" or workspace:GetAttribute("BossPhase") == "results")
	local want = active or res.Visible or flyN > 0
	if gui.Enabled ~= want then gui.Enabled = want end
	local inArena = player:GetAttribute("InBossArena") == true
	if inArena and os.clock() - lastHide > 1 then lastHide = os.clock(); pcall(hideHud) end
	if not inArena and next(hiddenHud) then showHud() end
	if not active then
		if next(golems) or next(zones) then clearAll() end
		return
	end
	fit()
	layoutTop()
	-- големи: плавно до цілі
	local y0 = floorY()
	local k = math.min(1, dt * 12)
	for _, g in golems do
		if (g.pend or 0) > 0 and os.clock() - (g.pendT or 0) > 1.2 then animHit(g) end -- запасний показ без анімації
		if g.x then
			g.x += (g.tx - g.x) * k
			g.z += (g.tz - g.z) * k
			local dy = (g.tyaw - g.yaw + math.pi) % (2 * math.pi) - math.pi
			g.yaw += dy * k
			g.m:PivotTo(CFrame.new(g.x, y0 + g.foot, g.z) * CFrame.Angles(0, g.yaw, 0))
			local st = g.st == 2 and "Mine" or (g.st == 1 and "Walk" or "Idle")
			-- 06.11.2026: стан тримається ≥ 0,5 с — анімації (удар, крок) програються повністю, без смикання
			if g.m:GetAttribute("State") ~= st and os.clock() - (g.stT or 0) > 0.5 then
				g.stT = os.clock()
				g.m:SetAttribute("State", st)
			end
		end
		local b = g.bar
		if b then
			local kk = math.clamp(g.hp / math.max(1, g.max), 0, 1)
			b.fill.Size = UDim2.fromScale(kk, 1)
			b.studs.Size = UDim2.fromScale(1 / math.max(kk, 0.02), 1) -- studs не тягнуться разом зі смугою
			b.pct.Text = NF.short(math.max(0, math.ceil(g.hp))) -- 06.11.2026: саме HP голема (ціле), а не відсоток; удари боса знімають % від макс. HP
			b.grad.Enabled = os.clock() - g.flash > 0.08
			if (kk < 0.3) ~= (b.k < 0.3) then local col, tname = hpColor(g, kk); b.grad.Color = col; b.studs.Image = tileOf(tname) end
			b.k = kk
			b.stroke.Color = kk < 0.3 and C("ff5050"):Lerp(INK, 0.5 + 0.5 * math.sin(os.clock() * 8)) or INK
		end
	end
	-- зони: проявлення, пульс заливки, «заряд» від центру до країв
	for _, z in zones do
		local age = os.clock() - z.t0
		local u = math.clamp(age / math.max(0.1, z.warn), 0, 1)
		local fi = math.clamp(age / ZONE_IN, 0, 1)
		fi = 1 - (1 - fi) * (1 - fi) -- ease out
		local sc = 0.85 + 0.15 * fi
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * (7 + u * 12))
		for _, e in z.parts do
			if e.kind == "base" then
				e.p.Transparency = 1 - (1 - (0.7 - 0.12 * u - 0.06 * pulse)) * fi
				if fi < 1 then e.p.Size = Vector3.new(e.size.X * sc, e.size.Y, e.size.Z * sc) end
			else
				local k = 0.04 + 0.96 * u * u
				e.p.Size = Vector3.new(e.size.X * k, 0.1, e.size.Z * k)
				e.p.Transparency = 1 - (1 - 0.5) * fi
			end
		end
	end
	-- HP боса
	local mx = math.max(1, tonumber(workspace:GetAttribute("BossMaxHP")) or 1)
	local hp = math.max(0, tonumber(workspace:GetAttribute("BossHP")) or 0)
	local kk = hp / mx
	barFill.Size = UDim2.new(kk, 0, 1, 0)
	shownHp += (kk - shownHp) * math.min(1, dt * 3)
	barGhost.Size = UDim2.new(math.max(kk, shownHp), 0, 1, 0)
	barNum.Text = NF.short(hp) .. " / " .. NF.short(mx)
	bossName.Text = tostring(workspace:GetAttribute("BossName") or "BOSS")
	local ph = workspace:GetAttribute("BossPhase")
	timer.Text = ph == "fight" and fmtLeft((tonumber(workspace:GetAttribute("BossPhaseEnd")) or 0) - workspace:GetServerTimeNow()) or "0:00"
	-- лідерборд — 4 рази на секунду
	if os.clock() - lastUi < 0.25 then return end
	lastUi = os.clock()
	local dmg = decode(workspace:GetAttribute("BossDamage"), {})
	local list = {}
	for uid, v in dmg do table.insert(list, { u = tonumber(uid), d = v }) end
	table.sort(list, function(a, b) return a.d > b.d end)
	local nm = names()
	for i, r in lbRows do
		local e = list[i]
		r.f.Visible = e ~= nil
		if e then
			local me = e.u == player.UserId
			r.nm.TextColor3 = me and C("7dff3a") or WHITE
			r.nm.Text = e.u == player.UserId and "You" or (nm[e.u] or "Player")
			r.dm.Text = NF.short(e.d)
		end
	end
	lb.Size = UDim2.fromOffset(LB_W, LB_TOP + 8 + math.max(1, #list) * LB_ROW)
end)

-- новий бій — скинути піктограми воїнів
workspace:GetAttributeChangedSignal("BossPhase"):Connect(function()
	if workspace:GetAttribute("BossPhase") == "fight" then
		shownHp = 1
	end
end)
