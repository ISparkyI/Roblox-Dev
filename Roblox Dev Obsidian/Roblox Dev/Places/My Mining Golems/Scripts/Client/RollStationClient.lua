-- RollStationClient — вибір типу голема для ролу: 3 картки НА ПІДЛОЗІ перед важелем (Miner, Carrier, Warrior — закритий до MAP 2).
-- Де: StarterPlayer/StarterPlayerScripts/RollStationClient (LocalScript). Сервер — ServerScriptService/RollRoleService.
-- 07.11.2026 v2: екран з картками на машині ролу прибрано (лишився лише важіль по центру). Картки — деталі
--   Niche*/RollSystem/RoleCards/Card1..3 (атрибут Role, прозорі, лежать на підлозі). SurfaceGui (грань Top) у PlayerGui з Adornee —
--   так клікається мишкою / тапом. Замість кнопок — великий напис: SELECTED (лайм) / SELECT / MAP 2 (закрито).
-- Стиль карток — як табло плоту (PlotBoard): градієнт, studs, косі смуги, блиск, обвідка.
-- Вибір: своя ніша — клік / тап по картці → Remotes.RollRole:FireServer(роль); атрибут власника RollRole.
-- Чужа / вільна ніша: видно вибір власника, картки не натискаються.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local Remote = RS:WaitForChild("Remotes"):WaitForChild("RollRole")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local LIME = C("c9ff3a")
local CW, CH = 500, 790
local LOCK_ICON = "rbxassetid://122986621331664"

local ROLES = {
	{ key = "Miner", title = "Miner", line = "Mines ore", icon = "rbxassetid://116047648949185",
		th = { grad = { { 0, "6fc6ff" }, { 0.55, "2f8ee6" }, { 1, "1a5cb0" } }, rim = "bfe6ff", stud = "8fd2ff", studShade = "1b62b8" } },
	{ key = "Carrier", title = "Carrier", line = "Carries ore", icon = "rbxassetid://138033481006266",
		th = { grad = { { 0, "d59bff" }, { 0.55, "9a4cf0" }, { 1, "5f22b4" } }, rim = "ecd4ff", stud = "dcb4ff", studShade = "5c1fa8" } },
	{ key = "Warrior", title = "Warrior", line = "Fights bosses", icon = "rbxassetid://83348632276419", lockText = "MAP 2", minStage = 2,
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
local function checkBadge(parent, cx, cy)
	local D = 110
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

-- одна картка = свій SurfaceGui на грані Top деталі CardN (деталь: X — уздовж «до гравця» 6 стадів = висота картки, Z — ширина 3,8;
--   на грані Top ширина GUI іде вздовж −Z, висота — вздовж +X, тож картка читається гравцем, що стоїть перед важелем)
local function buildCard(part: BasePart, r, niche: Instance)
	local g = new("SurfaceGui", { Name = "RollCard_" .. niche.Name .. "_" .. r.key, Adornee = part, Face = Enum.NormalId.Top,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = CW / part.Size.Z, LightInfluence = 0, Brightness = 1.1,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = 300, AlwaysOnTop = false }, playerGui)
	local cd = { r = r, gui = g, part = part }
	local c = frame(g, 0, 0, CW, CH, WHITE, { Active = true }); cd.card = c
	cd.grad = vgrad(c, r.th.grad); stroke(c, INK, 10)
	cd.studs = StyleA.studTile(c, 10, 10, CW - 20, CH - 20, 46, C(r.th.stud), { ImageTransparency = 0.68 }, true)
	bands(c, CW, CH)
	local gloss = frame(c, 12, 12, CW - 24, math.floor(CH * 0.36), WHITE)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 14, 14, CW - 28, CH - 28, nil, { BackgroundTransparency = 1 }); cd.rim = stroke(rim, C(r.th.rim), 6, 0.25)
	local stripH = math.max(10, math.floor(CH * 0.03))
	cd.strip = frame(c, 0, CH - stripH, CW, stripH, darken(C(r.th.grad[#r.th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	cd.icon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(CW / 2, 235), Size = UDim2.fromOffset(330, 330),
		BackgroundTransparency = 1, Image = r.icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, c)
	cd.lock = new("ImageLabel", { Position = UDim2.fromOffset(155, 140), Size = UDim2.fromOffset(190, 190), BackgroundTransparency = 1,
		Image = LOCK_ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Visible = false }, c)
	label(c, 0, 420, CW, 90, 84, r.title, WHITE, 8, { ZIndex = 3 })
	cd.value = label(c, 0, 515, CW, 64, 48, r.line, C("d4ff3e"), 6, { ZIndex = 3 })
	-- статус замість кнопки: великий напис з товстою обвідкою на темній смузі
	local bar = frame(c, 24, 610, CW - 48, 120, INK, { BackgroundTransparency = 0.35, ZIndex = 3 }); corner(bar, 18)
	cd.bar = bar
	cd.status = label(bar, 0, 0, CW - 48, 120, 76, "SELECT", WHITE, 8, { ZIndex = 4 })
	-- рамка вибору (лайм, усередині картки) і галочка в правому верхньому куті
	cd.ring = frame(c, 0, 0, CW, CH, nil, { BackgroundTransparency = 1, ZIndex = 5, Visible = false })
	stroke(cd.ring, LIME, 16)
	cd.check = checkBadge(c, CW - 72, 72); cd.check.Visible = false
	cd.hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9, AutoButtonColor = false }, c)
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
			c.Position = UDim2.fromOffset(dx, 0)
			task.wait(0.04)
		end
		c.Position = UDim2.fromOffset(0, 0)
	end)
end

local function cardsOf(niche: Instance): { [number]: BasePart }
	local rsys = niche:FindFirstChild("RollSystem")
	local f = rsys and rsys:FindFirstChild("RoleCards")
	local out = {}
	if f then
		for _, p in f:GetChildren() do
			local i = p:IsA("BasePart") and BY_KEY[p:GetAttribute("Role") or ""]
			if i then out[i] = p end
		end
	end
	return out
end

local function buildPanel(niche: Instance, parts: { [number]: BasePart }, ownerId: number)
	local mine = ownerId == player.UserId
	local pn = { ownerId = ownerId, niche = niche, cards = {}, parts = parts }
	for i, r in ROLES do
		local part = parts[i]
		if part then
			local cd = buildCard(part, r, niche)
			pn.cards[i] = cd
			if mine then
				cd.hit.MouseButton1Click:Connect(function()
					if cd.locked then shake(cd); return end
					if cd.state == "sel" then return end
					StyleA.tap()
					Remote:FireServer(r.key)
				end)
			else
				cd.hit.Active = false; cd.hit.Selectable = false
				pcall(function() cd.hit.Interactable = false end)
			end
		end
	end
	return pn
end
local function destroyPanel(pn) for _, cd in pn.cards do cd.gui:Destroy() end end

local panels = {} -- [niche] = pn
local function refresh()
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return end
	local camPos = camera.CFrame.Position
	for n, pn in panels do
		local alive = n:IsDescendantOf(workspace)
		for _, p in pn.parts do if not p:IsDescendantOf(workspace) then alive = false end end
		if not alive then destroyPanel(pn); panels[n] = nil end
	end
	for _, n in niches:GetChildren() do
		local parts = cardsOf(n)
		local ownerId = (n:GetAttribute("OwnerUserId") :: number?) or 0
		local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil
		local role = owner and owner:GetAttribute("RollRole") or "Miner"
		local stage = owner and tonumber(owner:GetAttribute("Stage")) or 1
		local selIdx = BY_KEY[role] or 1
		local mid = parts[2] or parts[1]
		local dist = mid and (mid.Position - camPos).Magnitude or math.huge
		local pn = panels[n]
		if pn and (dist > 200 or pn.ownerId ~= ownerId or pn.parts[2] ~= parts[2]) then destroyPanel(pn); panels[n] = nil; pn = nil end
		if not pn and mid and dist < 140 then pn = buildPanel(n, parts, ownerId); panels[n] = pn end
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
					if st == "lock" then cd.status.Text = r.lockText or "LOCKED"; cd.status.TextColor3 = C("d9dde2")
					elseif st == "sel" then cd.status.Text = "SELECTED"; cd.status.TextColor3 = LIME
					else cd.status.Text = "SELECT"; cd.status.TextColor3 = WHITE end
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
