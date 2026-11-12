-- RollStationClient — вибір типу голема для ролу: 3 картки НА ЕКРАНІ (Miner, Carrier, Warrior — закритий під час навчання).
-- Де: StarterPlayer/StarterPlayerScripts/RollStationClient (LocalScript). Сервер — ServerScriptService/RollRoleService.
-- 10.11.2026 v3: картки перенесено з підлоги перед важелем на екран (на телефоні в світі їх погано видно).
--   ScreenGui RollRolePanel: стовпчик з 3 широких карток зліва (праворуч від кнопок Shop / Index / Quests), посередині висоти —
--   не закриває персонажа й кнопку ROLL (10.11.2026 v3.1–3.2; спершу був ряд по центру над хотбаром). Виїжджає зліва, коли гравець у СВОЇЙ ніші
--   біля важеля (ближче SHOW_R стадів до RollLeverModel по горизонталі), ховається, коли відійшов / на арені боса.
--   3D-картки й рампа (RollSystem/RoleCards) з префабів прибрані (копії — ServerStorage/NicheBackup/RoleCards_<префаб>).
-- Стиль карток — як табло плоту (PlotBoard): градієнт, studs, косі смуги, блиск, обвідка; наведення — CardHover.
-- Вибір: клік / тап по картці → Remotes.RollRole:FireServer(роль); атрибут гравця RollRole. Замість кнопок — великий напис:
--   SELECTED (лайм) / SELECT / LOCKED. v3.3: вкладка зі стрілкою праворуч — згорнути в міні-версію (лише значки) і назад.
-- Навчання (TutorialClient, крок 3): кнопка картки — PlayerGui.RollRolePanel.Root.Card_<роль>…TextButton «Hit»;
--   панель видно — атрибут Shown = true на RollRolePanel.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local CardHover = require(RS.Shared:WaitForChild("CardHover")) -- 07.11.2026: наведення (збільшення) як на старому екрані
local Remote = RS:WaitForChild("Remotes"):WaitForChild("RollRole")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local LIME = C("c9ff3a")
local CW, CH = 640, 200 -- широка картка: значок зліва, назва / опис / статус справа
-- запас навколо картки — щоб влазили збільшення при наведенні й лаймова рамка вибору
local PAD = 40
local LOCK_ICON = "rbxassetid://122986621331664"

local ROLES = {
	{ key = "Miner", title = "Miner", line = "Mines ore", icon = "rbxassetid://116047648949185",
		th = { grad = { { 0, "6fc6ff" }, { 0.55, "2f8ee6" }, { 1, "1a5cb0" } }, rim = "bfe6ff", stud = "8fd2ff", studShade = "1b62b8" } },
	{ key = "Carrier", title = "Carrier", line = "Carries ore", icon = "rbxassetid://138033481006266",
		th = { grad = { { 0, "d59bff" }, { 0.55, "9a4cf0" }, { 1, "5f22b4" } }, rim = "ecd4ff", stud = "dcb4ff", studShade = "5c1fa8" } },
	{ key = "Warrior", title = "Warrior", line = "Fights bosses", icon = "rbxassetid://83348632276419", lockText = "LOCKED", tutLock = true, -- 08.11.2026: з мапи 1 (було MAP 2), закрита лише під час навчання
		th = { grad = { { 0, "ff8a96" }, { 0.55, "ef3d55" }, { 1, "a8182f" } }, rim = "ffd0d6", stud = "ffaab4", studShade = "b01d36" } },
}
local BY_KEY = {}
for i, r in ROLES do BY_KEY[r.key] = i end
local LOCK_TH = { grad = { { 0, "9aa1aa" }, { 0.55, "6f7680" }, { 1, "4a5058" } }, rim = "c9ced4", stud = "b4bac2", studShade = "555b63" }

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
local function darken(c, k) return Color3.new(c.R * (1 - k), c.G * (1 - k), c.B * (1 - k)) end
local function bands(parent, w, h)
	local f = frame(parent, 0, 0, w, h, WHITE, { Name = "Bands", Active = false })
	local K = NumberSequenceKeypoint.new
	new("UIGradient", { Rotation = 65, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new({ K(0, 1), K(0.16, 1), K(0.17, 0.82),
		K(0.31, 0.82), K(0.32, 1), K(0.47, 1), K(0.48, 0.9), K(0.53, 0.9), K(0.54, 1), K(0.70, 1), K(0.71, 0.85), K(0.83, 0.85), K(0.84, 1), K(1, 1) }) }, f)
	return f
end

-- галочка вибору: темне коло з лаймовим кругом і білою «пташкою»
local function checkBadge(parent, cx, cy, D)
	D = D or 110
	local b = frame(parent, cx - D / 2, cy - D / 2, D, D, INK, { Name = "Check", ZIndex = 6 }); corner(b, UDim.new(0.5, 0))
	local f = frame(b, 7, 7, D - 14, D - 14, WHITE, { Name = "Fill", ZIndex = 6 }); corner(f, UDim.new(0.5, 0))
	new("UIGradient", { Color = cseq({ { 0, "e8ff8a" }, { 0.55, "9be22e" }, { 1, "5fb81a" } }), Rotation = 90 }, f)
	local hl = frame(f, 14, 8, D - 42, 26, WHITE, { Name = "Gloss", ZIndex = 6, BackgroundTransparency = 0.55 }); corner(hl, UDim.new(0.5, 0))
	local k = D / 100
	local function seg(x1, y1, x2, y2, th, color, z)
		x1, y1, x2, y2 = x1 * k, y1 * k, x2 * k, y2 * k
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local s = frame(b, (x1 + x2) / 2, (y1 + y2) / 2, len + th, th, color, { AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = math.deg(math.atan2(dy, dx)), ZIndex = z })
		corner(s, UDim.new(0.5, 0))
	end
	local P1, P2, P3 = { 28, 52 }, { 43, 67 }, { 72, 35 }
	seg(P1[1], P1[2], P2[1], P2[2], 25, INK, 7)
	seg(P2[1], P2[2], P3[1], P3[2], 25, INK, 7)
	seg(P1[1], P1[2], P2[1], P2[2], 13, WHITE, 8)
	seg(P2[1], P2[2], P3[1], P3[2], 13, WHITE, 8)
	return b
end

-- одна широка картка (640 × 200 одиниць) у тримачі CardHover усередині кореня панелі; y — верхній край картки
local function buildCard(parent: GuiObject, r, y: number)
	local pad0 = CardHover.PAD; CardHover.PAD = PAD
	local holder, o = CardHover.holder(parent, PAD, y, CW, CH)
	CardHover.PAD = pad0
	holder.Name = "Card_" .. r.key
	local cd = { r = r, holder = holder, o = o }
	local c = frame(holder, o.X, o.Y, CW, CH, WHITE, { Active = true }); cd.card = c
	cd.grad = vgrad(c, r.th.grad); stroke(c, INK, 8)
	c.ClipsDescendants = true -- згорнута картка (лише значок) обрізає написи
	cd.studs = StyleA.studTile(c, 8, 8, CW - 16, CH - 16, 40, C(r.th.stud), { ImageTransparency = 0.68 }, true)
	bands(c, CW, CH)
	local gloss = frame(c, 10, 10, CW - 20, math.floor(CH * 0.4), WHITE)
	cd.gloss = gloss
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 12, 12, CW - 24, CH - 24, nil, { BackgroundTransparency = 1 }); cd.rim = stroke(rim, C(r.th.rim), 5, 0.25); cd.rimF = rim
	local stripH = 8
	cd.strip = frame(c, 0, CH - stripH, CW, stripH, darken(C(r.th.grad[#r.th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	cd.icon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(102, CH / 2), Size = UDim2.fromOffset(176, 176),
		BackgroundTransparency = 1, Image = r.icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, c)
	cd.lock = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(102, CH / 2), Size = UDim2.fromOffset(110, 110),
		BackgroundTransparency = 1, Image = LOCK_ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Visible = false }, c)
	cd.title = label(c, 200, 14, 380, 70, 64, r.title, WHITE, 7, { ZIndex = 3, TextXAlignment = Enum.TextXAlignment.Left })
	cd.value = label(c, 200, 82, 400, 40, 34, r.line, C("d4ff3e"), 5, { ZIndex = 3, TextXAlignment = Enum.TextXAlignment.Left })
	-- статус замість кнопки: напис з обвідкою на темній смузі
	local bar = frame(c, 196, 128, CW - 216, 56, INK, { BackgroundTransparency = 0.35, ZIndex = 3 }); corner(bar, 14)
	cd.bar = bar
	cd.status = label(bar, 0, 0, CW - 216, 56, 40, "SELECT", WHITE, 6, { ZIndex = 4 })
	-- лаймова рамка вибору ЗОВНІ картки: лайм 10 + темний контур 6; галочка в правому верхньому куті
	cd.ring = frame(holder, o.X - 4, o.Y - 4, CW + 8, CH + 8, nil, { BackgroundTransparency = 1, ZIndex = 5, Visible = false })
	stroke(cd.ring, LIME, 10)
	local ringOut = frame(cd.ring, -10, -10, CW + 28, CH + 28, nil, { BackgroundTransparency = 1, ZIndex = 5 }); stroke(ringOut, INK, 6); cd.ringOut = ringOut
	cd.check = checkBadge(c, CW - 50, 50, 76); cd.check.Visible = false
	cd.hit = new("TextButton", { Name = "Hit", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9, AutoButtonColor = false }, c)
	cd.state = nil
	return cd
end

local function applyTheme(cd, th, locked)
	cd.grad.Color = cseq(th.grad)
	cd.rim.Color = C(th.rim)
	cd.strip.BackgroundColor3 = darken(C(th.grad[#th.grad][2]), 0.30)
	StyleA.studTint(cd.studs, C(th.stud))
	cd.icon.ImageColor3 = locked and C("8c9096") or WHITE
	cd.icon.ImageTransparency = locked and 0.25 or 0
	cd.lock.Visible = locked
	cd.value.TextColor3 = locked and WHITE or C("d4ff3e")
end

local function shake(cd)
	StyleA.deny()
	local c = cd.card
	task.spawn(function()
		for _, dx in { -16, 13, -9, 6, -3, 0 } do
			c.Position = UDim2.fromOffset(cd.o.X + dx, cd.o.Y)
			task.wait(0.04)
		end
		c.Position = UDim2.fromOffset(cd.o.X, cd.o.Y)
	end)
end

-- ===== панель на екрані =====
local GAP = 26            -- проміжок між картками (одиниці картки)
local COL_H = 0.42        -- висота стовпчика — частка висоти екрана
local MAX_W = 0.30        -- ширина картки — не більше частки ширини екрана
local CENTER_Y = 0.54     -- центр стовпчика по висоті (нижче валют зліва вгорі)
local SHOW_R = 12         -- ближче до важеля (стади по горизонталі) — панель видно (кнопка ROLL — 8)
local TW = CW + 2 * PAD
local TH = 3 * CH + 2 * GAP + 2 * PAD

local gui = new("ScreenGui", { Name = "RollRolePanel", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets, DisplayOrder = 4,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false }, playerGui)
local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(TW, TH) }, gui)
local scale = new("UIScale", {}, root)
local cards = {}
for i, r in ROLES do
	local cd = buildCard(root, r, PAD + (i - 1) * (CH + GAP))
	cards[i] = cd
	CardHover.attach(cd.holder, cd.card, function() return gui:GetAttribute("Shown") == true end, 1)
	cd.hit.MouseButton1Click:Connect(function()
		if gui:GetAttribute("Shown") ~= true then return end
		if cd.locked then shake(cd); return end
		if cd.state == "sel" then return end
		StyleA.tap()
		Remote:FireServer(r.key)
	end)
end

-- ===== 10.11.2026 v3.3: згортання в міні-версію (лише значки) =====
-- Вкладка зі стрілкою праворуч від стовпчика посередині: «‹» — згорнути (картки стають квадратами зі значком, вибрана — з лаймовою
--   рамкою), «›» — розгорнути. Плавно. Стан пам'ятається до кінця сесії. Під час навчання — завжди розгорнуто, вкладки немає.
local MINI_W = CH -- згорнута картка — квадрат зі значком
local TAB_W, TAB_H, TAB_GAP = 70, 200, 16
local mini = false
local miniT = 0 -- 0 — розгорнуто, 1 — згорнуто
local tab = new("TextButton", { Name = "CollapseTab", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0, 0.5),
	Size = UDim2.fromOffset(TAB_W, TAB_H), BackgroundColor3 = INK, BackgroundTransparency = 0.2, ZIndex = 10 }, root)
corner(tab, 20) -- без обвідки (біла напівпрозора давала квадратну «підкладку» на кутах)
local chev = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 60),
	BackgroundTransparency = 1, ZIndex = 11 }, tab)
-- шеврон «‹» з двох лаймових смуг; у згорнутому стані повернутий на 180° («›»)
for _, b in { { 19, 19, -45 }, { 19, 41, 45 } } do
	local bar = frame(chev, b[1], b[2], 38, 12, LIME, { AnchorPoint = Vector2.new(0.5, 0.5), Rotation = b[3], ZIndex = 11 })
	corner(bar, UDim.new(0.5, 0))
end
local function applyWidth(w: number)
	for _, cd in cards do
		cd.card.Size = UDim2.fromOffset(w, CH)
		cd.holder.Size = UDim2.fromOffset(w + 2 * PAD, CH + 2 * PAD)
		cd.holder.Position = UDim2.fromOffset(PAD + w / 2, cd.holder.Position.Y.Offset)
		cd.ring.Size = UDim2.fromOffset(w + 8, CH + 8)
		cd.ringOut.Size = UDim2.fromOffset(w + 28, CH + 28)
		cd.rimF.Size = UDim2.fromOffset(w - 24, CH - 24)
		cd.gloss.Size = UDim2.fromOffset(w - 20, cd.gloss.Size.Y.Offset)
		cd.studs.Size = UDim2.fromOffset(w - 16, CH - 16)
		cd.strip.Size = UDim2.fromOffset(w, cd.strip.Size.Y.Offset)
		local bands = cd.card:FindFirstChild("Bands")
		if bands then bands.Size = UDim2.fromOffset(w, CH) end
		-- написи — лише в розгорнутій картці: при наведенні картка нахиляється, а в повернутих елементах Roblox не обрізає вміст
		local full = w > CW - 60
		cd.title.Visible = full; cd.value.Visible = full; cd.bar.Visible = full
		cd.check.Visible = full and cd.state == "sel"
	end
	root.Size = UDim2.fromOffset(w + 2 * PAD + TAB_GAP + TAB_W, TH)
	tab.Position = UDim2.fromOffset(PAD + w + TAB_GAP, TH / 2)
	chev.Rotation = miniT > 0.5 and 180 or 0
end
tab.MouseButton1Click:Connect(function()
	if gui:GetAttribute("Shown") ~= true then return end
	StyleA.tap()
	mini = not mini
end)
RunService.RenderStepped:Connect(function(dt)
	local tut = player:GetAttribute("TutStep") ~= nil
	tab.Visible = not tut
	local tgt = (mini and not tut) and 1 or 0
	if miniT == tgt then return end
	miniT += (tgt - miniT) * math.min(1, dt * 14)
	if math.abs(tgt - miniT) < 0.005 then miniT = tgt end
	applyWidth(CW + (MINI_W - CW) * miniT)
end)
applyWidth(CW)

-- 10.11.2026 v3.2 (адаптивно): стовпчик точно повторює колонку кнопок MainHUD Shop / Index / Quests —
--   лівий край праворуч від них, верх = верх Shop, низ = низ Quests (на будь-якому екрані не налазить на кнопки, валюти й джойстик).
--   Кнопок не знайдено — запасний варіант: частки екрана. Рахується щоразу, поки панель видно (HUD міг змінитись).
local function hudBox(): (number?, number?, number?)
	local hud = playerGui:FindFirstChild("MainHUD")
	if not hud then return nil end
	local right, top, bottom = nil, nil, nil
	for _, n in { "Btn_Shop", "Btn_Index", "Btn_Quests" } do
		local b = hud:FindFirstChild(n, true)
		local h = b and b:FindFirstChild("Hit", true)
		local g = (h and h:IsA("GuiObject")) and h or ((b and b:IsA("GuiObject")) and b or nil)
		if g and g.AbsoluteSize.X > 2 and g.AbsoluteSize.Y > 2 then
			local p, sz = g.AbsolutePosition, g.AbsoluteSize
			right = math.max(right or 0, p.X + sz.X)
			top = math.min(top or math.huge, p.Y)
			bottom = math.max(bottom or 0, p.Y + sz.Y)
		end
	end
	if not (right and top and bottom) or bottom - top < 40 then return nil end
	-- AbsolutePosition рахується без смуги Roblox згори; у Position панелі — від верху самого ScreenGui
	local o = gui.AbsolutePosition
	return right - o.X, top - o.Y, bottom - o.Y
end

local shownT = 0 -- 0 — схована (за лівим краєм), 1 — на місці
local function layout()
	local vs = camera.ViewportSize
	if vs.X < 2 or vs.Y < 2 then return end
	local u = vs.Y / 720
	local right, top, bottom = hudBox()
	local x, cy, colH
	if right then
		x = right + 20 * u -- 10.11.2026: +12 — не налазить на значки-лічильники кнопок (було 8); координати збігаються: ScreenGui як у MainHUD (IgnoreGuiInset + DeviceSafeInsets)
		cy = (top + bottom) / 2
		colH = bottom - top
	else
		x = 150 * u
		cy = CENTER_Y * vs.Y
		colH = COL_H * vs.Y
	end
	-- висота — як колонка кнопок; ширина картки не більше MAX_W екрана
	local s = math.min(colH / (TH - 2 * PAD), MAX_W * vs.X / CW)
	scale.Scale = s
	local x0 = x - PAD * s
	local hidden = x0 + root.Size.X.Offset * s + 20
	root.Position = UDim2.fromOffset(x0 - (1 - shownT) * hidden, cy)
end

local function myNiche(): Instance?
	local f = workspace:FindFirstChild("Niches")
	if not f then return nil end
	for _, n in f:GetChildren() do
		if n:GetAttribute("OwnerUserId") == player.UserId then return n end
	end
	return nil
end
local function nearLever(): boolean
	if player:GetAttribute("InBossArena") == true then return false end
	local n = myNiche()
	local rsys = n and n:FindFirstChild("RollSystem")
	local lever = rsys and rsys:FindFirstChild("RollLeverModel")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (lever and hrp and hum and hum.Health > 0) then return false end
	local d = (hrp.Position - lever:GetPivot().Position) * Vector3.new(1, 0, 1)
	return d.Magnitude < SHOW_R and math.abs(hrp.Position.Y - lever:GetPivot().Position.Y) < 12
end

local function refresh()
	local role = player:GetAttribute("RollRole") or "Miner"
	local selIdx = BY_KEY[role] or 1
	local stage = tonumber(player:GetAttribute("Stage")) or 1
	for i, cd in cards do
		local r = cd.r
		local locked = (r.minStage ~= nil and stage < r.minStage) or (r.tutLock == true and player:GetAttribute("TutStep") ~= nil)
		local st = locked and "lock" or (i == selIdx and "sel" or "free")
		if cd.state ~= st then
			cd.state = st; cd.locked = locked
			applyTheme(cd, locked and LOCK_TH or r.th, locked)
			cd.ring.Visible = st == "sel"
			cd.check.Visible = st == "sel" and miniT < 0.1
			if st == "lock" then cd.status.Text = r.lockText or "LOCKED"; cd.status.TextColor3 = C("d9dde2")
			elseif st == "sel" then cd.status.Text = "SELECTED"; cd.status.TextColor3 = LIME
			else cd.status.Text = "SELECT"; cd.status.TextColor3 = WHITE end
		end
	end
end

local want = false
task.spawn(function()
	while true do
		task.wait(0.15)
		local ok, err = pcall(function()
			want = nearLever()
			refresh()
			if gui.Enabled then layout() end
		end)
		if not ok then warn("RollStationClient: " .. tostring(err)) end
	end
end)

-- виїзд / ховання зліва (плавно, ~0,25 с)
RunService.RenderStepped:Connect(function(dt)
	local target = want and 1 or 0
	if shownT == target and gui.Enabled == (target == 1) then return end
	shownT += (target - shownT) * math.min(1, dt * 12)
	if math.abs(target - shownT) < 0.01 then shownT = target end
	gui.Enabled = shownT > 0
	gui:SetAttribute("Shown", shownT > 0.9 or nil)
	layout()
end)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()
