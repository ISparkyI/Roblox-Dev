--!nonstrict
-- QuestsWindow — вікно QUESTS (кнопка Quests ліворуч у HUD). Сервер — ServerScriptService/QuestService
--   (атрибут гравця QuestState — JSON зі станом; RemoteFunction Remotes/QuestAction: Claim / ClaimAll).
-- Де: StarterPlayer/StarterPlayerScripts/QuestsWindow (LocalScript). Каркас вікна — як InfoWindows / SettingsWindow
--   (980 × 528 зі studs, заголовок з іконкою Quests −8°, перелив жовтий, червона X, Esc / клік поза вікном, WindowManager "Quests").
-- Ліворуч — вкладки DAILY / WEEKLY / SPECIAL (кнопки «стиль A», вибрана жовта й зсунута), червоні лічильники готових нагород,
--   таймер до оновлення (щоденні — північ UTC, тижневі — понеділок 00:00 UTC), CLAIM ALL.
-- Праворуч — картки квестів: назва, смуга прогресу «34 / 60» (час — «1h 05m / 2h 00m»), нагорода (діамант + число або назва),
--   кнопка CLAIM (зелена — можна забрати; сіра — ще ні, DONE / MAXED — забрано, SOON — ще немає системи). Не влазить — прокрутка.
-- Червоний лічильник на кнопці Quests у HUD — скільки нагород можна забрати.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Shared = RS:WaitForChild("Shared")
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ICON = { -- іконки кнопок HUD (MainHUD, 2D/Main HUD)
	quests = "rbxassetid://140685411214992", diamond = "rbxassetid://126442692946356",
}

-- ===== розміри (як усі вікна) =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528

-- ===== кольори й шрифти =====
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local MUTED = C("9aa3ad")
local GOOD = C("7ef05a")
local BAD = C("ff5a5a")
local BADGE_RED = C("ff3b4f")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local SLOT_BG = { { 0, "22262c" }, { 1, "15181c" } }
local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right

-- ===== помічники (як у IndexUI / InventoryUI) =====
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
local function isPress(inp: InputObject): boolean
	return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end
local function cardBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.4) }) }, f)
	stroke(f, INK, 3)
	return f
end
-- темне поле (як слот інвентаря)
local function slotBg(parent, x, y, w, h, z)
	local f = frame(parent, x, y, w, h, WHITE, { ZIndex = z or 3 })
	vgrad(f, SLOT_BG); stroke(f, INK, 4)
	return f
end
-- вікно зі studs (як Forge / Inventory / Index). Повертає (window, вміст)
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

-- звук відмови (сіра / недоступна дія)
local function denySound()
	if StyleA.deny then StyleA.deny() else UISounds.play("deny", 0.08) end
end
-- кнопка-група «стиль A» (як у IndexUI): тінь, основа, напис в одному Frame — масштабуються й хитаються разом
local function shakeGroup(grp: GuiObject)
	denySound()
	if grp:GetAttribute("Shaking") then return end
	grp:SetAttribute("Shaking", true)
	local p0 = grp.Position
	task.spawn(function()
		for _, dx in { -10, 10, -7, 7, -3, 0 } do grp.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		grp.Position = p0
		grp:SetAttribute("Shaking", nil)
	end)
end
local function makeGroupButton(parent, x, y, w, h, opt)
	local grp = new("Frame", { Name = opt.name or "Group", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x + w / 2, y + h / 2), Size = UDim2.fromOffset(w, h), ZIndex = opt.z or 1 }, parent)
	local gs = new("UIScale", {}, grp)
	frame(grp, 0, opt.shadowDy, w, h, BLACK, { Name = "Shadow", BackgroundTransparency = 0.7, ZIndex = 1 })
	local b = StyleA.new(grp, { size = Vector2.new(w, h), position = Vector2.new(0, 0), color = opt.color, clickable = true,
		shine = opt.shine, zIndex = 2, icon = opt.icon, iconPad = opt.iconPad, text = opt.text, textSize = opt.textSize })
	b.root.Name = "Button"
	b.scale = gs
	b.group = grp
	b.onClick = nil
	StyleA.bind(b, { debounce = 0.15, hoverAlways = true, tap = opt.tap, canClick = function() return true end, onClick = function()
		if b.enabled == false then shakeGroup(grp) elseif b.onClick then b.onClick(b) end
	end })
	return b
end
local function makeBadge(parent, z, sz)
	local f = frame(parent, 0, 0, sz, sz, INK, { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Visible = false })
	corner(f, UDim.new(0.5, 0))
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = BADGE_RED, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -4, 1, -4), ZIndex = z }, f)
	corner(fill, UDim.new(0.5, 0))
	local t = label(fill, 0, 0, sz, sz, math.floor(sz * 0.6 + 0.5), "", WHITE, 1.4, { Size = UDim2.fromScale(1, 1), ZIndex = z + 1 })
	return { f = f, t = t, sz = sz }
end
local function setBadge(b, n: number)
	if not b then return end
	b.f.Visible = n > 0
	if n <= 0 then return end
	local s = n > 9 and "9+" or tostring(n)
	b.t.Text = s
	b.f.Size = UDim2.fromOffset(math.max(b.sz, math.floor(b.sz * 0.46 + #s * b.sz * 0.35)), b.sz)
end


local uiEvents = RS:WaitForChild("UIEvents", 30)
local hudEvent = uiEvents and uiEvents:WaitForChild("HUDButton", 30)

-- =====================================================================
-- ===== вікно: рамка, заголовок з іконкою, X, відкриття / закриття =====
-- =====================================================================
-- spec: key (WindowManager / HUDButton), gui, title, icon, palette (4 кольори переливу)
local function makeWindow(spec)
	local W = { isOpen = false }
	local gui = new("ScreenGui", { Name = spec.gui, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10, Enabled = true }, playerGui)
	local backdrop = new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
		Active = true, Visible = false, ZIndex = 1 }, gui)
	local modalRoot = new("Frame", { Name = "ModalRoot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
	local fitScale = new("UIScale", {}, modalRoot)
	local pop = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
	local popScale = new("UIScale", {}, pop)
	local _, content = windowFrame(pop, WX, WY, WW, WH, 1, 14)
	W.gui, W.content, W.modalRoot = gui, content, modalRoot

	-- заголовок: іконка кнопки HUD (≈ 2 × висоти літер, нахил −8°) + текст з переливом і відблиском; обводка й тіні — чорні
	local TITLE_ICON = 132
	local TI_CX, TI_CY = WX + 26 + TITLE_ICON / 2, WY - 6
	new("ImageLabel", { Name = "TitleIconShadow", BackgroundTransparency = 1, Image = spec.icon, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TI_CX, TI_CY + 7), Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON), Rotation = -8, ZIndex = 3 }, pop)
	new("ImageLabel", { Name = "TitleIcon", BackgroundTransparency = 1, Image = spec.icon, ScaleType = Enum.ScaleType.Fit, Rotation = -8,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TI_CX, TI_CY), Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON), ZIndex = 4 }, pop)
	local TITLE_X = WX + 26 + TITLE_ICON + 2
	textAt(pop, TITLE_X, WY - 8 + 7, 600, 96, spec.title, INK, 9, { TextXAlignment = LEFT, ZIndex = 3 })
	local title = textAt(pop, TITLE_X, WY - 8, 600, 96, spec.title, WHITE, 8, { TextXAlignment = LEFT, ZIndex = 4 })
	local titleGrad = new("UIGradient", { Rotation = 0 }, title)
	local titleShine = textAt(pop, TITLE_X, WY - 8, 600, 96, spec.title, WHITE, 0, { TextXAlignment = LEFT, ZIndex = 5 })
	local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
			NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
			NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
	do
		local P = {}
		for _, h in spec.palette do table.insert(P, C(h)) end
		local function sample(u)
			local x = (u % 1) * #P
			local i = math.floor(x)
			local t = x - i
			t = t * t * (3 - 2 * t)
			return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
		end
		RunService.Heartbeat:Connect(function()
			if not modalRoot.Visible then return end
			local phase = -(os.clock() / 4)
			local ks = {}
			for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end
			titleGrad.Color = ColorSequence.new(ks)
		end)
		local tw = TweenService:Create(titleShineGrad, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
		tw.Completed:Connect(function() titleShineGrad.Offset = Vector2.new(-1.3, 0) end)
		task.spawn(function() while true do task.wait(3 + math.random() * 3); if modalRoot.Visible then tw:Play() end end end)
	end
	local closeBtn = makeGroupButton(pop, WX + WW - 70, WY - 34, 84, 84, { name = "Close", shadowDy = 8, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

	local function fit()
		WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WX, winY = WY, winW = WW, winH = WH })
	end
	local camConn
	local function bindCamera()
		if camConn then camConn:Disconnect(); camConn = nil end
		local cam = workspace.CurrentCamera
		if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
		fit()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
	pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fit) end)
	bindCamera()

	local animToken = 0
	local hotbarOrder = nil
	local escName = spec.key .. "Esc"
	local function escKey(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
		task.defer(function() if W.isOpen then W.close() end end)
		return Enum.ContextActionResult.Sink
	end
	function W.open()
		if W.isOpen then return end
		W.isOpen = true
		WindowManager.opened(spec.key) -- одне вікно на екрані: інші закриваються
		animToken += 1
		local my = animToken
		-- хотбар лишається видно над затемненням (як у INVENTORY / INDEX)
		local hb = playerGui:FindFirstChild("Hotbar")
		if hb and hb:IsA("ScreenGui") then
			hotbarOrder = hb.DisplayOrder < 11 and hb.DisplayOrder or 5
			hb.DisplayOrder = 11
			task.delay(0.2, function() if W.isOpen and animToken == my then hb.DisplayOrder = 11 end end)
		end
		fit()
		if W.onOpen then W.onOpen() end
		backdrop.Visible = true; modalRoot.Visible = true
		backdrop.BackgroundTransparency = 1
		popScale.Scale = 0.85
		tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
		tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
			if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
		end)
		CAS:BindActionAtPriority(escName, escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
	end
	function W.close()
		if not W.isOpen then return end
		W.isOpen = false
		pcall(function() CAS:UnbindAction(escName) end)
		if W.onClose then W.onClose() end
		animToken += 1
		local my = animToken
		tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
		tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
			if animToken ~= my then return end
			backdrop.Visible = false; modalRoot.Visible = false
			local hb = playerGui:FindFirstChild("Hotbar")
			-- інше вікно (Inventory / Index…), що вже відкрилось, саме тримає хотбар нагорі — порядок не чіпаємо
			local other = false
			for _, n in { "InventoryWindow", "IndexWindow", "FeedbackWindow", "CodesWindow", "UpdatesWindow", "SettingsWindow", "QuestsWindow", "RebirthWindow" } do
				local g = playerGui:FindFirstChild(n)
				local mr = g and g:FindFirstChild("ModalRoot")
				if g ~= gui and mr and mr.Visible then other = true end
			end
			if hb and hotbarOrder and not other then hb.DisplayOrder = hotbarOrder end
			hotbarOrder = nil
		end)
	end
	closeBtn.onClick = function() W.close() end
	WindowManager.register(spec.key, function() return W.isOpen end, function() W.close() end)
	local function inside(o: GuiObject, p: Vector2, top: number?): boolean
		local a, s = o.AbsolutePosition, o.AbsoluteSize
		return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y - (top or 0) and p.Y <= a.Y + s.Y
	end
	backdrop.InputBegan:Connect(function(inp)
		if not isPress(inp) then return end
		-- закриває лише клік ПОЗА вікном (заголовок і X над рамкою — теж вікно); без GetGuiInset: inp.Position і AbsolutePosition в одному просторі
		local p = Vector2.new(inp.Position.X, inp.Position.Y)
		if inside(content, p, content.AbsoluteSize.Y * 0.18) then return end
		W.close()
	end)
	if hudEvent then
		hudEvent.Event:Connect(function(key) if key == spec.key then if W.isOpen then W.close() else W.open() end end end)
	end
	return W
end
-- =====================================================================
-- ===== QUESTS =====
-- =====================================================================
local DAY, WEEK = 86400, 7 * 86400
local win = makeWindow({ key = "Quests", gui = "QuestsWindow", title = "QUESTS", icon = ICON.quests, palette = { "fff6c4", "ffd23a", "ff9a1f", "ffd23a" } })
local content = win.content

-- ліворуч — вкладки DAILY / WEEKLY / SPECIAL, таймер оновлення, CLAIM ALL
local TX, TW, TH = 30, 226, 66
local TABS = { { "daily", "DAILY", "3 new every day" }, { "weekly", "WEEKLY", "Chains, reset Monday" }, { "special", "SPECIAL", "Exclusive rewards" } }
local tab = "daily"
local tabs = {}
local render
for i, spec in TABS do
	local hold = frame(content, TX, 66 + (i - 1) * (TH + 14), TW + 16, TH + 8, nil, { Name = "Tab_" .. spec[1], BackgroundTransparency = 1, ZIndex = 4 })
	local b = makeGroupButton(hold, 0, 0, TW, TH, { name = "Btn", shadowDy = 7, color = "gray", z = 1, shine = false })
	textAt(b.group, 16, 25, TW - 30, 26, spec[2], WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 5 })
	textAt(b.group, 16, 48, TW - 30, 14, spec[3], SUB_TXT, 1.8, { TextXAlignment = LEFT, FontFace = XBOLD, ZIndex = 5 })
	local badge = makeBadge(b.group, 8, 26)
	badge.f.Position = UDim2.new(1, -6, 0, 4)
	b.onClick = function() if tab ~= spec[1] then tab = spec[1]; render(true) end end
	tabs[spec[1]] = { hold = hold, b = b, badge = badge }
end
local resetLbl = textAt(content, TX, 318, TW, 17, "", SUB_TXT, 2, { ZIndex = 5, FontFace = XBOLD })
local resetVal = textAt(content, TX, 342, TW, 24, "", WHITE, 2.6, { ZIndex = 5 })
local claimAll = makeGroupButton(content, TX, 436, TW, 58, { name = "ClaimAll", shadowDy = 6, color = "green", text = "CLAIM ALL", textSize = 26, z = 5 })

-- праворуч — картки квестів
local LX, LY, LW, LH = 284, 62, 664, 444
local list = new("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(LX, LY), Size = UDim2.fromOffset(LW, LH), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = C("2a2e35"), ScrollBarImageTransparency = 0.1, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 4 }, content)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 18) }, list)
local CW = LW - 26
local CARD_H = 96
local emptyLbl = textAt(content, LX, LY + 200, LW, 22, "", WHITE, 2.4, { ZIndex = 5 })

local Q = nil -- останній QuestState
local function readState()
	local ok, v = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("QuestState") or "")
	Q = (ok and type(v) == "table") and v or nil
end

local Action = nil
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 60)
	Action = r and r:WaitForChild("QuestAction", 60)
end)
local function call(action: string, arg: any): any
	local t0 = os.clock()
	while not Action and os.clock() - t0 < 5 do task.wait(0.1) end
	if not Action then return nil end
	local ok, res = pcall(Action.InvokeServer, Action, action, arg)
	return ok and res or nil
end

local function fmt(n: number): string
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if r:sub(1, 1) == "," then r = r:sub(2) end
	return r
end
local function progText(q, isTime: boolean): string
	if isTime then
		local function tm(m) if m >= 60 then return string.format("%dh %02dm", m // 60, m % 60) end return string.format("%dm", m) end
		return tm(q.prog) .. " / " .. tm(q.target)
	end
	return fmt(q.prog) .. " / " .. fmt(q.target)
end

-- стан картки: "claim" | "progress" | "done" | "soon"
local function cardState(kind: string, q): string
	if q.soon then return "soon" end
	if kind == "weekly" then
		if q.done then return "done" end
	elseif q.claimed then
		return "done"
	end
	return q.prog >= q.target and "claim" or "progress"
end
local function claimable(): (number, number)
	if not Q then return 0, 0 end
	local d, w = 0, 0
	for _, q in Q.daily or {} do if cardState("daily", q) == "claim" then d += 1 end end
	for _, q in Q.weekly or {} do if cardState("weekly", q) == "claim" then w += 1 end end
	return d, w
end

local cards = {}
local function clearCards()
	for _, c in cards do c.root:Destroy() end
	table.clear(cards)
end
local BAR_W, BAR_H = 360, 24
local GOLD = { { 0, "fff3a8" }, { 0.5, "ffc83a" }, { 1, "f08a12" } }
local DONE = { { 0, "c6ffad" }, { 0.5, "7ef05a" }, { 1, "3fae2a" } }
local function makeCard(order: number)
	local root = new("Frame", { Name = "Card" .. order, Size = UDim2.fromOffset(CW, CARD_H), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 4 }, list)
	cardBg(root, 0, 0, CW, CARD_H, 4)
	local title = textAt(root, 18, 26, CW - 220, 24, "", WHITE, 2.6, { TextXAlignment = LEFT, ZIndex = 5 })
	local lvl = textAt(root, 18 + BAR_W - 160, 26, 160, 15, "", C("ffd23a"), 2, { TextXAlignment = RIGHT, ZIndex = 5, FontFace = XBOLD })
	local track = frame(root, 18, 52, BAR_W, BAR_H, WHITE, { Name = "Track", ZIndex = 5 })
	vgrad(track, SLOT_BG); stroke(track, INK, 3)
	local fill = frame(track, 0, 0, BAR_W, BAR_H, WHITE, { Name = "Fill", ZIndex = 6 })
	local fillGrad = vgrad(fill, GOLD)
	local progLbl = textAt(track, 0, BAR_H / 2, BAR_W, 17, "", WHITE, 2.2, { ZIndex = 7 })
	local RX = CW - 16 - 140
	local rIcon = new("ImageLabel", { Name = "RewardIcon", BackgroundTransparency = 1, Image = ICON.diamond, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(RX + 22, 7), Size = UDim2.fromOffset(24, 30), ZIndex = 5 }, root)
	local rText = textAt(root, RX + 52, 22, 90, 24, "", C("8fe3ff"), 2.4, { TextXAlignment = LEFT, ZIndex = 5 })
	local btn = makeGroupButton(root, RX, 42, 140, 44, { name = "Claim", shadowDy = 5, color = "green", text = "CLAIM", textSize = 22, z = 5 })
	return { root = root, title = title, lvl = lvl, fill = fill, fillGrad = fillGrad, progLbl = progLbl, rIcon = rIcon, rText = rText, btn = btn, RX = RX }
end

local function fillCard(c, kind: string, q)
	local isTime = (q.stat == "Play" or q.key == "Play" or kind == "special")
	c.title.Text = q.text
	c.lvl.Text = (kind == "weekly") and string.format("LEVEL %d / %d", math.min(q.lvl + (q.done and 0 or 1), q.max), q.max) or ""
	local st = cardState(kind, q)
	local k = q.target > 0 and math.clamp(q.prog / q.target, 0, 1) or 0
	if st == "done" then k = 1 end
	c.fill.Visible = k > 0
	c.fill.Size = UDim2.fromOffset(BAR_W * k, BAR_H)
	c.fillGrad.Color = cseq(st == "done" and DONE or GOLD)
	c.progLbl.Text = st == "done" and "COMPLETED" or ((st == "soon" and kind ~= "special") and "COMING SOON" or progText(q, isTime))
	if type(q.reward) == "number" then
		c.rIcon.Visible = true
		c.rText.Position = UDim2.fromOffset(c.RX + 52, c.rText.Position.Y.Offset)
		c.rText.Size = UDim2.fromOffset(90, c.rText.Size.Y.Offset)
		c.rText.TextXAlignment = LEFT
		c.rText.Text = "+" .. fmt(q.reward)
		c.rText.TextColor3 = C("8fe3ff")
	else
		c.rIcon.Visible = false
		c.rText.Position = UDim2.fromOffset(c.RX - 30, c.rText.Position.Y.Offset)
		c.rText.Size = UDim2.fromOffset(200, c.rText.Size.Y.Offset)
		c.rText.TextXAlignment = Enum.TextXAlignment.Center
		c.rText.Text = tostring(q.reward)
		c.rText.TextColor3 = C("ffd23a")
	end
	local b = c.btn
	if st == "claim" then b:setColor("green"); b:setText("CLAIM"); b.enabled = true
	elseif st == "done" then b:setColor("gray"); b:setText(kind == "weekly" and "MAXED" or "DONE"); b.enabled = false
	elseif st == "soon" then b:setColor("gray"); b:setText("SOON"); b.enabled = false
	else b:setColor("gray"); b:setText("CLAIM"); b.enabled = false end
	b.onClick = function()
		if st ~= "claim" then return end
		b.enabled = false
		local res = call("Claim", kind == "daily" and { kind = "daily", i = q.i } or { kind = "weekly", key = q.key })
		if res and res.ok then UISounds.play("claim", 0.1) else denySound() end
	end
end

local shownKey = nil
render = function(resetScroll: boolean?)
	for k, t in tabs do
		local sel = k == tab
		t.b:setColor(sel and "yellow" or "gray")
		t.hold.Position = UDim2.fromOffset(TX + (sel and 14 or 0), t.hold.Position.Y.Offset)
	end
	local d, w = claimable()
	setBadge(tabs.daily.badge, d); setBadge(tabs.weekly.badge, w)
	claimAll:setColor((d + w) > 0 and "green" or "gray")
	claimAll.enabled = (d + w) > 0
	local items = Q and Q[tab] or {}
	local key = tab .. ":" .. #items .. ":" .. tostring(Q and Q.day) .. ":" .. tostring(Q and Q.week)
	if key ~= shownKey then
		clearCards()
		for i = 1, #items do cards[i] = makeCard(i) end
		shownKey = key
		resetScroll = true
	end
	for i, q in items do fillCard(cards[i], tab, q) end
	emptyLbl.Text = Q and "" or "Loading…"
	if resetScroll then list.CanvasPosition = Vector2.zero end
end

-- таймер до оновлення вкладки
local function fmtLeft(s: number): string
	s = math.max(0, math.floor(s))
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %02dm", h, m) end
	return string.format("%dm %02ds", m, s % 60)
end
RunService.Heartbeat:Connect(function()
	if not win.isOpen then return end
	local t = workspace:GetServerTimeNow()
	if tab == "daily" then
		resetLbl.Text = "NEW QUESTS IN"; resetVal.Text = fmtLeft(DAY - t % DAY)
	elseif tab == "weekly" then
		resetLbl.Text = "WEEK RESETS IN"; resetVal.Text = fmtLeft(WEEK - (t + 3 * DAY) % WEEK)
	else
		resetLbl.Text = "NEVER RESETS"; resetVal.Text = ""
	end
end)

claimAll.onClick = function()
	claimAll.enabled = false
	local res = call("ClaimAll")
	if res and res.ok then UISounds.play("claim", 0.1) else denySound() end
end

-- червоний лічильник на кнопці Quests у HUD (значок додаємо звідси, MainHUD не змінюється)
local hudBadge = nil
local function updateHud()
	local d, w = claimable()
	setBadge(hudBadge, d + w)
end
task.spawn(function()
	local hud = playerGui:WaitForChild("MainHUD", 60)
	for _ = 1, 60 do
		if not hud or not hud.Parent then hud = playerGui:FindFirstChild("MainHUD") end
		if hud then
			for _, dd in hud:GetDescendants() do
				if dd:IsA("TextLabel") and dd.Name == "Label" and dd.Text == "Quests" and dd.Parent then
					hudBadge = makeBadge(dd.Parent, 10, 26)
					hudBadge.f.Position = UDim2.new(1, -8, 0, 10)
					updateHud()
					return
				end
			end
		end
		task.wait(1)
	end
end)

local function onState()
	readState()
	updateHud()
	if win.isOpen then render(false) end
end
player:GetAttributeChangedSignal("QuestState"):Connect(onState)
onState()
win.onOpen = function() render(true) end
