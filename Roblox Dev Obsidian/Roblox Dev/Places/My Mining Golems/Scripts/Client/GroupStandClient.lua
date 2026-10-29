--!nonstrict
-- GroupStandClient — стенди групового Mushroom Golem (Workspace/Cave/Hub/GroupStands) і вікно GROUP REWARD. 29.10.2026.
-- Сервер — GroupGolemService. На стенді лише голем і кнопка E (GroupPrompt, «OPEN»); підказки — у вікні (рішення користувача).
-- Вікно (стиль як SELL / DIAMONDS SHOP): 3D-голем (ItemViewport), EXCLUSIVE, «+50% of your Best Miner», поточна шкода
--   (BestMinerDmg), кроки 1 Join the group / 2 Like the game / 3 Claim, кнопка JOIN GROUP (вікно Roblox PromptJoinAsync →
--   "Check") / CLAIM ("Check") / OWNED. Закривається хрестиком, Esc або коли гравець відійшов від стенда.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")

local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local UISfx = require(Shared:WaitForChild("UISfx"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local ItemVP = require(Shared:WaitForChild("ItemViewport"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GROUP_ID = 996441586
local KIND = "mushroom"
local OPEN_R = 8      -- зайшов у радіус стенда (від центру Base) — вікно відкривається саме (без кнопки E)
local EXIT_PAD = 1.5   -- закривається, коли відійшов далі OPEN_R + EXIT_PAD; хрестик / Esc — до наступного входу
local WIN_SCALE = 0.68 -- маленьке вікно: усе полотно зменшене, без затемнення екрана (можна ходити)

local CANVAS_W, CANVAS_H = 1120, 700
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 70, 1040, 590

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
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
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, color, th, contextual)
	-- Round скрізь: на заокруглених рамках Miter дає чорні квадратні кути
	return new("UIStroke", { Color = color, Thickness = th, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, true) end
	return t
end
local function stud(parent, x, y, cell, fill, shade, edge)
	local s = cell * 0.62
	local o = (cell - s) / 2
	local d = s * 0.12
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade, { ZIndex = 1 }); corner(sh, s * 0.16)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill, { ZIndex = 2 }); corner(st, s * 0.16)
	if edge then stroke(st, edge, 1) end
end
local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end
local function windowFrame(parent, x, y, w, h)
	frame(parent, x, y + 14, w, h, BLACK, { BackgroundTransparency = 0.65, ZIndex = 1 })
	local win = frame(parent, x, y, w, h, WHITE, { ZIndex = 2 })
	new("UIGradient", { Color = cseq(RIM), Rotation = 90 }, win); stroke(win, INK, 5)
	local pw, ph = w - 36, h - 36
	local panel = frame(win, 18, 18, pw, ph, C("a9aeb5"), { ZIndex = 2, ClipsDescendants = true })
	stroke(panel, INK, 4)
	local studs = frame(panel, 0, 0, pw, ph, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	local CELL = 40
	local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
	local ox, oy = (pw - nx * CELL) / 2, (ph - ny * CELL) / 2
	for cx = 0, nx - 1 do for cy = 0, ny - 1 do stud(studs, ox + cx * CELL, oy + cy * CELL, CELL, C("b3b8bf"), C("868b92"), C("c8ccd1")) end end
	local content = frame(win, 0, 0, w, h, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	return win, content
end
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + opt.shadowDy, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, zIndex = opt.z + 1 })
	b.shadow = sh
	StyleA.follow(b, sh)
	b.onClick = nil
	StyleA.bind(b, { debounce = 0.4, canClick = opt.canClick, onClick = function() if b.onClick then b.onClick(b) end end })
	return b
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end
local function decode(attr: string, default: any): any
	local s = player:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function ownsMushroom(): boolean
	for _, g in decode("InvGolems", {}) do if type(g) == "table" and g.kind == KIND then return true end end
	for _, g in decode("CaveStandGolems", {}) do if type(g) == "table" and g.kind == KIND then return true end end
	for _, mm in decode("MutMachines", {}) do
		if type(mm) == "table" and type(mm.slots) == "table" then
			for _, g in mm.slots do if type(g) == "table" and g.kind == KIND then return true end end
		end
	end
	return false
end

-- ===== вікно =====
local gui = new("ScreenGui", { Name = "GroupRewardWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10 }, playerGui)
local backdrop = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, Visible = false }, gui)
local modalRoot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(CANVAS_W, CANVAS_H),
	BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)
local _, content = windowFrame(pop, WIN_X, WIN_Y, WIN_W, WIN_H)

-- заголовок з переливом (як у вікнах магазинів)
local tShadow = label(pop, 70, WIN_Y - 58 + 9, 900, 110, 96, "GROUP REWARD", INK, 11, { ZIndex = 5 })
local title = label(pop, 70, WIN_Y - 58, 900, 110, 96, "GROUP REWARD", WHITE, 10, { ZIndex = 6 })
local tg = new("UIGradient", {}, title)
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 7 })

-- ліва картка: 3D-голем
local card = frame(content, 46, 70, 400, 470, C("2a2148"), { ZIndex = 4, ClipsDescendants = true })
corner(card, 14); stroke(card, INK, 5)
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "5a3a7a" }, { 1, "22182f" } }) }, card)
local glow = frame(card, 50, 110, 300, 300, C("ff5a5a"), { ZIndex = 4, BackgroundTransparency = 0.8 }); corner(glow, 150)
local vp = new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 70), Size = UDim2.fromOffset(340, 340), ZIndex = 5 }, card)
local exTag = frame(card, 110, 16, 180, 44, C("ff5a5a"), { ZIndex = 6 }); corner(exTag, 10); stroke(exTag, INK, 4)
label(exTag, 0, 0, 180, 44, 26, "EXCLUSIVE", WHITE, 3, { ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Center })
label(card, 0, 410, 400, 54, 38, "MUSHROOM GOLEM", C("ffd0c8"), 5, { ZIndex = 6, TextXAlignment = Enum.TextXAlignment.Center })

-- праворуч: що дає і як отримати
local RX = 486
local perkBox = frame(content, RX, 70, 508, 150, C("14161a"), { ZIndex = 4, BackgroundTransparency = 0.35 }); corner(perkBox, 14); stroke(perkBox, INK, 4)
label(perkBox, 22, 30, 300, 90, 84, "+50%", C("7ef05a"), 8, { ZIndex = 5 })
label(perkBox, 236, 35, 260, 80, 30, "of your\nBEST MINER", WHITE, 4, { ZIndex = 5, TextWrapped = true })
-- рядок «Right now: … dmg» прибрано (рішення користувача)

local steps = {}
local STEP_TXT = { "Join the group", "Like the game", "Claim your golem!" }
for i = 1, 3 do
	local y = 236 + (i - 1) * 62
	local row = frame(content, RX, y, 508, 52, C("14161a"), { ZIndex = 4, BackgroundTransparency = 0.5 }); corner(row, 12)
	local num = frame(row, 8, 6, 40, 40, C("ffcf4a"), { ZIndex = 5 }); corner(num, 20); stroke(num, INK, 3)
	local nl = label(num, 0, 0, 40, 40, 26, tostring(i), WHITE, 3, { ZIndex = 6, TextXAlignment = Enum.TextXAlignment.Center })
	label(row, 62, 0, 420, 52, 30, STEP_TXT[i], WHITE, 4, { ZIndex = 5 })
	steps[i] = { num = num, nl = nl }
end
local actBtn = makeButton(content, RX, 444, 508, 96, { shadowDy = 8, color = "orange", text = "JOIN GROUP", textSize = 46, z = 5,
	canClick = function() return not ownsMushroom() end })

-- ===== стан =====
local function refresh()
	local inG = player:GetAttribute("InGroup") == true
	local owned = ownsMushroom()
	local done = { inG, inG, owned }
	for i, st in steps do
		st.num.BackgroundColor3 = done[i] and C("7ef05a") or C("ffcf4a")
		st.nl.Text = done[i] and "✓" or tostring(i)
	end
	if owned then
		actBtn:setText("OWNED"); if actBtn.color ~= "gray" then actBtn:setColor("gray") end
	elseif inG then
		actBtn:setText("CLAIM"); if actBtn.color ~= "green" then actBtn:setColor("green") end
	else
		actBtn:setText("JOIN GROUP"); if actBtn.color ~= "orange" then actBtn:setColor("orange") end
	end
end

local remote = RS:WaitForChild("Remotes"):WaitForChild("GroupGolemAction")
local joining = false
local function join()
	if joining then return end
	joining = true
	local ok = pcall(function() GroupService:PromptJoinAsync(GROUP_ID) end)
	joining = false
	if ok then remote:FireServer("Check") end
end
actBtn.onClick = function()
	if ownsMushroom() then return end
	if player:GetAttribute("InGroup") == true then remote:FireServer("Check") else task.spawn(join) end
end
remote.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Join" then task.spawn(join)
	elseif kind == "Toast" then toast(a, b)
	elseif kind == "Claimed" then UISfx.play("BuySound"); refresh() end
end)

-- ===== відкриття / закриття =====
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

local isOpen, dismissed, animToken = false, false, 0
local vpSet = false
local function open()
	isOpen = true
	WindowManager.opened("GroupReward")
	animToken += 1
	local my = animToken
	fitWin()
	if not vpSet then vpSet = true; pcall(ItemVP.set, vp, ItemVP.golemKey(KIND, "miner"), 1.1) end
	refresh()
	backdrop.Visible = false; modalRoot.Visible = true
	popScale.Scale = 0.85 * WIN_SCALE
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 * WIN_SCALE }).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = WIN_SCALE }) end
	end)
end
local function close()
	if not isOpen then return end
	isOpen = false
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 * WIN_SCALE }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
	end)
end
closeBtn.onClick = function() dismissed = true; close() end
WindowManager.register("GroupReward", function() return isOpen end, function() dismissed = true; close() end)
CAS:BindActionAtPriority("GroupRewardEsc", function(_, state)
	if state == Enum.UserInputState.Begin and isOpen then dismissed = true; close(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)

-- стенди: центр (Base) для радіуса і голем-вітрина (ShowGolem: ширяє й повільно крутиться, анімація Idle грає)
local standList = {}
local HOVER, BOB, SPIN = 1, 0.5, 0.6 -- над підставкою (стад), амплітуда підйому (стад), швидкість обертання (рад/с)
local function hook(s: Instance)
	local base = s:WaitForChild("Base", 10)
	if not (base and base:IsA("BasePart")) then return end
	local e = { stand = s, base = base }
	table.insert(standList, e)
	local function grab(m)
		if m.Name ~= "ShowGolem" or not m:IsA("Model") then return end
		local root = m:WaitForChild("Root", 10)
		if not root then return end
		e.golem = m; e.root = root; e.base0 = root.CFrame; e.phase = math.random() * 6
		-- зелений надпис «+50% BEST» над големом (їде разом з Root)
		if e.tag then e.tag:Destroy() end
		local cf, size = m:GetBoundingBox()
		local top = cf.Position.Y + size.Y / 2 - root.Position.Y
		local bb = Instance.new("BillboardGui")
		bb.Name = "GroupBestTag"
		bb.Adornee = root
		bb.Size = UDim2.fromScale(7, 1.6)
		bb.StudsOffsetWorldSpace = Vector3.new(0, top + 1.1, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 70
		bb.ResetOnSpawn = false
		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.fromScale(1, 1)
		tl.FontFace = HEAVY
		tl.TextScaled = true
		tl.Text = "+50% BEST"
		tl.TextColor3 = C("7ef05a")
		local st = Instance.new("UIStroke")
		st.Color = INK; st.Thickness = 3; st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent = tl
		tl.Parent = bb
		bb.Parent = playerGui
		e.tag = bb
		m.Destroying:Connect(function() if e.tag == bb then bb:Destroy(); e.tag = nil end end)
	end
	for _, c in s:GetChildren() do task.spawn(grab, c) end
	s.ChildAdded:Connect(function(c) task.spawn(grab, c) end)
end
task.spawn(function()
	local hub = workspace:WaitForChild("Cave"):WaitForChild("Hub")
	local f = hub:WaitForChild("GroupStands", 60)
	if not f then return end
	for _, s in f:GetChildren() do task.spawn(hook, s) end
	f.ChildAdded:Connect(function(s) task.spawn(hook, s) end)
end)
-- голем ширяє: Root (анкерований) зсуваємо й повертаємо — GolemAnimator ставить деталі від Root
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, e in standList do
		local r = e.root
		if r and r.Parent then
			local ph = t + e.phase
			local y = HOVER + BOB * (0.5 - 0.5 * math.cos(ph * 1.6))
			r.CFrame = CFrame.new(e.base0.Position + Vector3.new(0, y, 0)) * CFrame.Angles(0, ph * SPIN, 0) * e.base0.Rotation
		end
	end
end)
-- вікно відкривається в радіусі стенда і закривається, коли відійшов
task.spawn(function()
	while true do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local best = math.huge
		if hrp then
			for _, e in standList do
				local d = e.base.Position - hrp.Position
				if math.abs(d.Y) < 12 then best = math.min(best, Vector2.new(d.X, d.Z).Magnitude) end
			end
		end
		local inside = best <= OPEN_R + ((isOpen or dismissed) and EXIT_PAD or 0)
		if not inside then dismissed = false end
		if inside and not dismissed and not isOpen then open()
		elseif not inside and isOpen then close() end
		task.wait(0.15)
	end
end)

local WATCH = { InvGolems = true, CaveStandGolems = true, MutMachines = true, InGroup = true, BestMinerDmg = true }
player.AttributeChanged:Connect(function(n) if WATCH[n] and isOpen then refresh() end end)

local TITLE_PAL = { C("fff3a8"), C("ffcf4a"), C("ff8a3a"), C("ffcf4a") }
local function sample(P, u)
	local x = (u % 1) * #P
	local i = math.floor(x)
	local t = x - i
	t = t * t * (3 - 2 * t)
	return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
end
RunService.Heartbeat:Connect(function()
	if not isOpen then return end
	local ph = -(os.clock() / 4)
	local ks = {}
	for k = 0, 12 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 12, sample(TITLE_PAL, k / 12 * 2 + ph)) end
	tg.Color = ColorSequence.new(ks)
	glow.BackgroundTransparency = 0.78 + 0.08 * math.sin(os.clock() * 2.5)
end)
