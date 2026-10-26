-- RollStationClient — екран станції ролу в ніші: 3 картки типу голема (Miner, Carrier, Warrior — закритий до MAP 2)
-- + лампи над екраном (світиться над вибраним типом).
-- Де: StarterPlayer/StarterPlayerScripts/RollStationClient (LocalScript). Сервер — ServerScriptService/RollRoleService.
-- Екран — Niche*/RollSystem/RollLeverModel/Screen (похилий, грань Back). SurfaceGui у PlayerGui з Adornee (так клікається мишкою).
-- Стиль карток — як табло плоту (PlotBoard): градієнт, studs, косі смуги, блиск, обвідка, кнопка «стиль A».
-- Вибір: своя ніша — клік по картці або кнопці → Remotes.RollRole:FireServer(роль); атрибут власника RollRole.
-- Чужа / вільна ніша: видно вибір власника, кнопки неактивні. Лампи Lamp1..3 перемикаються локально в кожного гравця.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local CardHover = require(RS.Shared:WaitForChild("CardHover"))
local Remote = RS:WaitForChild("Remotes"):WaitForChild("RollRole")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local LIME = C("c9ff3a")
local PH = 1000
local CW, CH, GAP, ROW_Y = 500, 790, 110, 120
local LOCK_ICON = "rbxassetid://122986621331664"

local ROLES = {
	{ key = "Miner", title = "Miner", line = "Mines ore", icon = "rbxassetid://116047648949185",
		th = { grad = { { 0, "6fc6ff" }, { 0.55, "2f8ee6" }, { 1, "1a5cb0" } }, rim = "bfe6ff", stud = "8fd2ff", studShade = "1b62b8" } },
	{ key = "Carrier", title = "Carrier", line = "Carries ore", icon = "rbxassetid://138033481006266",
		th = { grad = { { 0, "d59bff" }, { 0.55, "9a4cf0" }, { 1, "5f22b4" } }, rim = "ecd4ff", stud = "dcb4ff", studShade = "5c1fa8" } },
	{ key = "Warrior", title = "Warrior", line = "Fights bosses", icon = "rbxassetid://83348632276419", lockText = "MAP 2", minStage = 2,
		th = { grad = { { 0, "ff8a96" }, { 0.55, "ef3d55" }, { 1, "a8182f" } }, rim = "ffd0d6", stud = "ffaab4", studShade = "b01d36" } },
}
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
local function stud(parent, x, y, cell, fill, shade, edge)
	local s = math.floor(cell * 0.62)
	local o = (cell - s) / 2
	local d = math.max(2, math.floor(s * 0.12 + 0.5))
	local r = math.max(3, math.floor(s * 0.16))
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill); corner(st, r)
	if edge then stroke(st, edge, 2) end
end
local function darken(c, k) return Color3.new(c.R * (1 - k), c.G * (1 - k), c.B * (1 - k)) end
local function bands(parent, w, h)
	local f = frame(parent, 0, 0, w, h, WHITE, { Name = "Bands", Active = false })
	local K = NumberSequenceKeypoint.new
	new("UIGradient", { Rotation = 65, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new({ K(0, 1), K(0.16, 1), K(0.17, 0.82),
		K(0.31, 0.82), K(0.32, 1), K(0.47, 1), K(0.48, 0.9), K(0.53, 0.9), K(0.54, 1), K(0.70, 1), K(0.71, 0.85), K(0.83, 0.85), K(0.84, 1), K(1, 1) }) }, f)
	return f
end

-- галочка вибору: темне коло з лаймовим кругом (градієнт, блік) і білою «пташкою» з круглими кінцями.
-- Без UIStroke: обвідки — це ті самі фігури темним кольором, трохи більші (UIStroke у CanvasGroup давав чорний квадрат).
local function checkBadge(parent, cx, cy)
	local D = 100
	local b = frame(parent, cx - D / 2, cy - D / 2, D, D, INK, { Name = "Check", ZIndex = 6 }); corner(b, UDim.new(0.5, 0))
	local f = frame(b, 7, 7, D - 14, D - 14, WHITE, { Name = "Fill", ZIndex = 6 }); corner(f, UDim.new(0.5, 0))
	new("UIGradient", { Color = cseq({ { 0, "e8ff8a" }, { 0.55, "9be22e" }, { 1, "5fb81a" } }), Rotation = 90 }, f)
	local hl = frame(f, 14, 8, D - 42, 24, WHITE, { Name = "Gloss", ZIndex = 6, BackgroundTransparency = 0.55 }); corner(hl, UDim.new(0.5, 0))
	-- відрізок-капсула від (x1,y1) до (x2,y2) товщиною th
	local function seg(x1, y1, x2, y2, th, color, z)
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local s = frame(b, (x1 + x2) / 2, (y1 + y2) / 2, len + th, th, color, { AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = math.deg(math.atan2(dy, dx)), ZIndex = z })
		corner(s, UDim.new(0.5, 0))
	end
	local P1, P2, P3 = { 28, 52 }, { 43, 67 }, { 72, 35 }
	seg(P1[1], P1[2], P2[1], P2[2], 23, INK, 7)
	seg(P2[1], P2[2], P3[1], P3[2], 23, INK, 7)
	seg(P1[1], P1[2], P2[1], P2[2], 12, WHITE, 8)
	seg(P2[1], P2[2], P3[1], P3[2], 12, WHITE, 8)
	return b
end

local function card(parent, x, y, r)
	-- запас тримача більший за стандартний: рамка вибору й галочка виходять за картку і нахиляються разом з нею
	local pad0 = CardHover.PAD; CardHover.PAD = 56
	local holder, o = CardHover.holder(parent, x, y, CW, CH, 14)
	CardHover.PAD = pad0
	local cd = { r = r, holder = holder, o = o }
	cd.shadow = frame(holder, o.X, o.Y + 14, CW, CH, Color3.new(0, 0, 0), { BackgroundTransparency = 0.65 })
	local c = frame(holder, o.X, o.Y, CW, CH, WHITE); cd.card = c
	cd.grad = vgrad(c, r.th.grad); stroke(c, INK, 6)
	-- шар studs — звичайний Frame (CanvasGroup у таблах на слабкій графіці не малювався); прозорість 0.68 — кожній пупочці
	local sg = new("Frame", { Name = "Studs", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(CW - 20, CH - 20), BackgroundTransparency = 1, ClipsDescendants = true }, c)
	task.defer(function() for _, d in sg:GetChildren() do if d:IsA("GuiObject") then d.BackgroundTransparency = 0.68 end end end)
	cd.studs = {}
	local cell = 46
	for gx = 0, math.ceil((CW - 20) / cell) - 1 do
		for gy = 0, math.ceil((CH - 20) / cell) - 1 do
			local s = cell * 0.6; local so = (cell - s) / 2
			local a = frame(sg, gx * cell + so - 2, gy * cell + so + 2, s, s, C(r.th.studShade)); corner(a, 5)
			local b = frame(sg, gx * cell + so, gy * cell + so, s, s, C(r.th.stud)); corner(b, 5)
			table.insert(cd.studs, { a, b })
		end
	end
	bands(c, CW, CH)
	local gloss = frame(c, 12, 12, CW - 24, math.floor(CH * 0.36), WHITE)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 12, 12, CW - 24, CH - 24, nil, { BackgroundTransparency = 1 }); cd.rim = stroke(rim, C(r.th.rim), 6, 0.25)
	local stripH = math.max(10, math.floor(CH * 0.03))
	cd.strip = frame(c, 0, CH - stripH, CW, stripH, darken(C(r.th.grad[#r.th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	cd.icon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(CW / 2, 240), Size = UDim2.fromOffset(340, 340),
		BackgroundTransparency = 1, Image = r.icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, c)
	cd.lock = new("ImageLabel", { Position = UDim2.fromOffset(155, 150), Size = UDim2.fromOffset(190, 190), BackgroundTransparency = 1,
		Image = LOCK_ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Visible = false }, c)
	label(c, 0, 432, CW, 90, 80, r.title, WHITE, 7)
	cd.value = label(c, 0, 530, CW, 70, 50, r.line, C("d4ff3e"), 6)
	local bx, by, bw, bh = 70, 640, CW - 140, 100
	local saShadow = frame(c, bx, by + 8, bw, bh, Color3.new(0, 0, 0), { BackgroundTransparency = 0.7 })
	cd.sa = StyleA.new(c, { size = Vector2.new(bw, bh), position = Vector2.new(bx, by), color = "blue", text = "SELECT", textSize = 54,
		clickable = true, zIndex = 2 })
	StyleA.follow(cd.sa, saShadow) -- тінь кнопки масштабується й хитається разом з нею
	-- клік по всій картці (під кнопкою)
	cd.hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1, AutoButtonColor = false }, c)
	-- рамка вибору: лаймова смуга + темний контур, галочка в правому верхньому куті
	cd.ring = frame(holder, o.X - 4, o.Y - 4, CW + 8, CH + 8, nil, { BackgroundTransparency = 1, ZIndex = 5, Visible = false })
	stroke(cd.ring, LIME, 10)
	local ringOut = frame(cd.ring, -10, -10, CW + 28, CH + 28, nil, { BackgroundTransparency = 1, ZIndex = 5 }); stroke(ringOut, INK, 6)
	cd.check = checkBadge(holder, o.X + CW + 1, o.Y - 1); cd.check.Visible = false
	cd.state = nil
	return cd
end

local function applyTheme(cd, th, locked)
	cd.grad.Color = cseq(th.grad)
	cd.rim.Color = C(th.rim)
	cd.strip.BackgroundColor3 = darken(C(th.grad[#th.grad][2]), 0.30)
	for _, s in cd.studs do s[1].BackgroundColor3 = C(th.studShade); s[2].BackgroundColor3 = C(th.stud) end
	cd.icon.ImageColor3 = locked and C("8c9096") or WHITE
	cd.icon.ImageTransparency = locked and 0.25 or 0
	cd.lock.Visible = locked
	cd.value.TextColor3 = locked and WHITE or C("d4ff3e")
end

local function shake(cd)
	local p0 = cd.holder.Position
	task.spawn(function()
		for _, dx in { -14, 12, -9, 6, -3, 0 } do
			cd.holder.Position = p0 + UDim2.fromOffset(dx, 0)
			task.wait(0.04)
		end
		cd.holder.Position = p0
	end)
end

local function buildPanel(niche: Model, screen: BasePart, ownerId: number)
	local mine = ownerId == player.UserId
	local PW = math.floor(PH * screen.Size.X / screen.Size.Y + 0.5)
	local g = new("SurfaceGui", { Name = "RollStation_" .. niche.Name, Adornee = screen,
		Face = Enum.NormalId[screen:GetAttribute("ScreenFace") or "Back"], SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = 300 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("8e939a"), { ClipsDescendants = true, Active = true })
	local PC = 56
	for cx = 0, math.ceil(PW / PC) - 1 do
		for cy = 0, math.ceil(PH / PC) - 1 do
			stud(root, cx * PC, cy * PC, PC, C("979ca3"), C("6c7178"), C("aeb3b9"))
		end
	end
	local shade = frame(root, 0, 0, PW, PH, WHITE, { ZIndex = 2, Active = false })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.08, 1), NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 0.8) }) }, shade)
	local pb = frame(root, 0, 0, PW, PH, nil, { BackgroundTransparency = 1, ZIndex = 9, Active = false }); stroke(pb, INK, 5)
	label(root, 0, 6, PW, 80, 60, "CHOOSE GOLEM", C("ffd34d"), 7, { ZIndex = 4 })
	local row = frame(root, 0, 0, PW, PH, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local rowW = #ROLES * CW + (#ROLES - 1) * GAP
	local x0 = math.floor((PW - rowW) / 2)
	local pn = { gui = g, screen = screen, ownerId = ownerId, niche = niche, cards = {} }
	for i, r in ROLES do
		local cd = card(row, x0 + (i - 1) * (CW + GAP), ROW_Y, r)
		pn.cards[i] = cd
		CardHover.attach(cd.holder, cd.card, function() return true end, 1)
		local function choose()
			if not mine then return end
			if cd.locked then shake(cd); return end
			if cd.state == "sel" then return end
			-- звук вибору картки — tap (UISounds; клік по кнопці й по картці дають один tap — minGap)
			StyleA.tap()
			Remote:FireServer(r.key)
		end
		if mine then
			StyleA.bind(cd.sa, { hoverAlways = true, canClick = function() return not cd.locked and cd.state ~= "sel" end, onClick = choose })
			cd.hit.MouseButton1Click:Connect(choose)
			cd.sa.button.MouseButton1Click:Connect(function() if cd.locked then shake(cd) end end)
		else
			for _, b in { cd.sa.button, cd.hit } do
				b.Active = false; b.Selectable = false
				pcall(function() b.Interactable = false end)
			end
		end
	end
	return pn
end

-- лампи над екраном: Lamp1 = Miner, Lamp2 = Carrier, Lamp3 = Warrior
local LAMP_ON, LAMP_OFF = C("7dff3a"), C("2a2f36")
local function setLamps(model: Instance, idx: number)
	for i = 1, 3 do
		local l = model:FindFirstChild("Lamp" .. i)
		if l and l:IsA("BasePart") then
			local on = i == idx
			if l:GetAttribute("On") ~= on then
				l:SetAttribute("On", on)
				l.Material = on and Enum.Material.Neon or Enum.Material.Glass
				l.Color = on and LAMP_ON or LAMP_OFF
				l.Transparency = on and 0 or 0.15
				local pl = l:FindFirstChildOfClass("PointLight")
				if pl then pl.Enabled = on end
			end
		end
	end
end

local panels = {} -- [niche] = pn
local function refresh()
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return end
	local camPos = camera.CFrame.Position
	for n, pn in panels do
		if not n:IsDescendantOf(workspace) or not pn.screen:IsDescendantOf(workspace) then pn.gui:Destroy(); panels[n] = nil end
	end
	for _, n in niches:GetChildren() do
		local rsys = n:FindFirstChild("RollSystem")
		local model = rsys and rsys:FindFirstChild("RollLeverModel")
		local screen = model and model:FindFirstChild("Screen")
		local ownerId = (n:GetAttribute("OwnerUserId") :: number?) or 0
		local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil
		local role = owner and owner:GetAttribute("RollRole") or "Miner"
		local stage = owner and tonumber(owner:GetAttribute("Stage")) or 1
		local selIdx = 1
		for i, r in ROLES do if r.key == role then selIdx = i end end
		if model then setLamps(model, selIdx) end
		local dist = screen and (screen.Position - camPos).Magnitude or math.huge
		local pn = panels[n]
		if pn and (dist > 200 or pn.ownerId ~= ownerId or pn.screen ~= screen) then pn.gui:Destroy(); panels[n] = nil; pn = nil end
		if not pn and screen and dist < 140 then pn = buildPanel(n, screen, ownerId); panels[n] = pn end
		if pn then
			for i, cd in pn.cards do
				local r = cd.r
				local locked = r.minStage ~= nil and stage < r.minStage
				local st = locked and "lock" or (i == selIdx and "sel" or "free")
				if cd.state ~= st then
					cd.state = st; cd.locked = locked
					applyTheme(cd, locked and LOCK_TH or r.th, locked)
					cd.ring.Visible = st == "sel"
					cd.check.Visible = st == "sel"
					if st == "lock" then cd.sa:setText(r.lockText or "LOCKED"); cd.sa:setColor("gray")
					elseif st == "sel" then cd.sa:setText("SELECTED"); cd.sa:setColor("green")
					else cd.sa:setText("SELECT"); cd.sa:setColor("blue") end
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.15)
		local ok, err = pcall(refresh)
		if not ok then warn("RollStationClient: " .. tostring(err)) end
	end
end)
