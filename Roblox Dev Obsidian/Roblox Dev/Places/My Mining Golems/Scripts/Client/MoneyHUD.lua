-- MoneyHUD v9 — лічильник грошей гравця, варіант A «затухання вправо».
-- Де: StarterPlayer/StarterPlayerScripts/MoneyHUD (LocalScript). Інтерфейс будується кодом.
-- Вигляд: над сумою — TOTAL MULTI x… на дуже прозорій темній підкладці; сума — зелений Montserrat Heavy з темним контуром
-- на темній підкладці, що плавно зникає праворуч (UIGradient Transparency), зі слабкими studs (тайл stylea_tile_gray_half);
-- поруч проста зелена квадратна кнопка «+». Обидві підкладки розширюються під довжину тексту (множник — AutomaticSize,
-- сума — ширина за TextService).
-- Дані: атрибути гравця Money (гроші) і TotalMulti (загальний множник, за замовчуванням 1). Числа — ReplicatedStorage/Shared/NumberFormat.
-- Нарахування: сума плавно докручується (0.65 с), підстрибує, біля «+» вилітає «+$…». Ширина напису (а з нею й підкладки)
-- задається явно за TextService: на час докручування — довше з двох чисел, потім плавно звужується — кнопка не смикається.
-- Кнопка «+» шле BindableEvent ReplicatedStorage/UIEvents/MoneyPlus (для магазину).
-- Розміщення: завжди низ ліворуч (на телефоні теж, без окремої адаптації); масштаб за висотою екрана.
-- Підказка над TOTAL MULTI: при наведенні (на тачі — по тапу) показує множники за джерелами (MultiConfig.SOURCES, атрибути Multi_<key>),
-- підкладка контейнера — як у лічильників діамантів/тікетів/ребітхів (прозорість 0.48→0.53, studs).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UIS = game:GetService("UserInputService")

local NF = require(RS:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds")) -- звук натискання «+»
local player = Players.LocalPlayer

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local PLATE = C("0e1014")
local STUD_TILE = "rbxassetid://113147180553208" -- stylea_tile_gray_half (studs удвічі слабші)

-- розміри в одиницях макета (сума 44 px)
local MONEY_SIZE, MULTI_SIZE = 44, 16
local CASH_H, BTN = 56, 42 -- «+» на 20% менший (було 52)
local PAD_L, PAD_R = 14, 34
local PC_K = 64 / 44 * 1.19 -- як попередній HUD на ПК
local PHONE_K = 0.375 -- телефон: ×0.75 з макета, зменшене вдвічі (на екрані висотою 390)

-- ===== будівельники =====
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function frame(parent, props)
	local f = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
	for k, v in props do f[k] = v end
	return f
end
local function ns(t)
	local ks = {}
	for _, k in t do table.insert(ks, NumberSequenceKeypoint.new(k[1], k[2])) end
	return NumberSequence.new(ks)
end
local function textWidth(str: string, size: number): number
	local p = Instance.new("GetTextBoundsParams")
	p.Text = str; p.Font = HEAVY; p.Size = size; p.Width = 10000
	local ok, v = pcall(function() return TextService:GetTextBoundsAsync(p) end)
	return ok and v.X or #str * size * 0.62
end
local function multText(n: number): string
	if math.abs(n) < 1e6 and n == math.floor(n) then return "x" .. NF.full(n) end
	return NF.mult(n)
end
local function money(n) return NF.money(n) end

-- ===== збірка =====
local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("MoneyHUD"); if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "MoneyHUD", ResetOnSpawn = false, IgnoreGuiInset = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5 }, pg)
local root = frame(gui, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0) })
local uiScale = new("UIScale", {}, root)
new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Left }, root)

-- TOTAL MULTI (ще прозоріша підкладка)
-- слот у макеті (фіксований розмір = текст + відступи) → multi притиснутий лівим нижнім кутом; наведення збільшує його (UIScale росте від AnchorPoint)
-- в бік правого верхнього кута, без зміщення інших елементів HUD
local multiSlot = frame(root, { LayoutOrder = 1, Size = UDim2.fromOffset(160, 24) })
local multi = frame(multiSlot, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 0, BackgroundColor3 = PLATE })
local multiHover = new("UIScale", {}, multi)
new("UIGradient", { Transparency = ns({ { 0, 0.5 }, { 0.55, 0.58 }, { 1, 1 } }) }, multi)
local multLabel = new("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
	FontFace = HEAVY, TextSize = MULTI_SIZE, TextColor3 = C("e6edf5"), RichText = true, Text = "TOTAL MULTI", ZIndex = 2 }, multi)
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 22), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4) }, multLabel)
new("UIStroke", { Color = INK, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Round }, multLabel)
local function syncSlot() -- розмір слота = текст + відступи (10 + 22, 3 + 4)
	multiSlot.Size = UDim2.fromOffset(math.ceil(multLabel.TextBounds.X) + 32, math.ceil(multLabel.TextBounds.Y) + 7)
end
multLabel:GetPropertyChangedSignal("TextBounds"):Connect(syncSlot)
syncSlot()

-- рядок: сума + «+»
local line = frame(root, { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0) })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center }, line)

local cash = frame(line, { LayoutOrder = 1, Size = UDim2.fromOffset(200, CASH_H), BackgroundTransparency = 0,
	BackgroundColor3 = PLATE, ClipsDescendants = true })
new("UIGradient", { Transparency = ns({ { 0, 0.22 }, { 0.6, 0.3 }, { 1, 1 } }) }, cash)
local studs = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = STUD_TILE, ScaleType = Enum.ScaleType.Tile,
	TileSize = UDim2.fromOffset(28, 28), ImageTransparency = 0.15, ZIndex = 1 }, cash)
new("UIGradient", { Transparency = ns({ { 0, 0 }, { 0.5, 0 }, { 1, 1 } }) }, studs)
local moneyLabel = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	FontFace = HEAVY, TextSize = MONEY_SIZE, TextColor3 = C("7dff3a"), Text = "$0", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, cash)
new("UIPadding", { PaddingLeft = UDim.new(0, PAD_L), PaddingRight = UDim.new(0, PAD_R), PaddingBottom = UDim.new(0, 2) }, moneyLabel)
new("UIStroke", { Color = INK, Thickness = 3.5, LineJoinMode = Enum.LineJoinMode.Round }, moneyLabel)
local moneyScale = new("UIScale", {}, moneyLabel)

-- проста кнопка «+»: квадрат, темний контур, зелений градієнт, невелика губа, білий плюс
local btnHolder = frame(line, { LayoutOrder = 2, Size = UDim2.fromOffset(BTN, BTN) })
-- AnchorPoint 0.5/0.5: UIScale росте від AnchorPoint, тож кнопка збільшується від центра, а не від лівого верхнього кута
local btn = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1) }, btnHolder)
local btnScale = new("UIScale", {}, btn)
local LIP = BTN * 0.12
frame(btn, { BackgroundTransparency = 0, BackgroundColor3 = C("1f7a14"), Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6) })
local face = frame(btn, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6 - LIP) })
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("9dff4a"), C("2fc21c")) }, face)
frame(btn, { BackgroundTransparency = 0.65, BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 0, BTN * 0.1) })
local cy = (BTN - LIP) / 2
local function bar(w, h, color)
	frame(btn, { BackgroundTransparency = 0, BackgroundColor3 = color, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(BTN / 2, cy),
		Size = UDim2.fromOffset(w, h) })
end
local R = BTN * 0.2
bar(2 * R + BTN * 0.2, BTN * 0.2, INK); bar(BTN * 0.2, 2 * R + BTN * 0.2, INK)
bar(2 * R + BTN * 0.1, BTN * 0.1, Color3.new(1, 1, 1)); bar(BTN * 0.1, 2 * R + BTN * 0.1, Color3.new(1, 1, 1))

local uiEvents = RS:FindFirstChild("UIEvents") or new("Folder", { Name = "UIEvents" }, RS)
local plusEvent = uiEvents:FindFirstChild("MoneyPlus") or new("BindableEvent", { Name = "MoneyPlus" }, uiEvents)
local function tw(o, t, p, style) TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad), p):Play() end
btn.MouseEnter:Connect(function() tw(btnScale, 0.12, { Scale = 1.06 }) end)
btn.MouseLeave:Connect(function() tw(btnScale, 0.12, { Scale = 1 }) end)
btn.MouseButton1Down:Connect(function() tw(btnScale, 0.08, { Scale = 0.92 }) end)
btn.MouseButton1Up:Connect(function() tw(btnScale, 0.15, { Scale = 1.06 }, Enum.EasingStyle.Back) end)
btn.Activated:Connect(function() UISounds.play("tap", 0.08); plusEvent:Fire() end)

-- ===== розміщення й масштаб =====
local function isPhone(vp: Vector2): boolean
	return (UIS.TouchEnabled and not UIS.KeyboardEnabled) or vp.Y < 600
end
-- без окремої адаптації під телефон: всюди низ ліворуч, масштаб за висотою екрана (на малих екранах менший)
local function place()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	uiScale.Scale = math.clamp(vp.Y / 1080, 0.3, 1.4) * PC_K
	root.AnchorPoint = Vector2.new(0, 1)
	root.Position = UDim2.new(0, 16, 1, -16)
end
place()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)

-- ===== плашка з множниками (наведення на TOTAL MULTI) =====
local ORANGE, DIM = C("ffb02e"), C("8e98a6")
local TIP_W, ROW_H = 230, 30
local tip = new("CanvasGroup", { Name = "MultiTip", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
	AnchorPoint = Vector2.new(0, 1), GroupTransparency = 1, Visible = false, ZIndex = 20 }, gui)
local tipScale = new("UIScale", {}, tip)
local panel = new("Frame", { BackgroundColor3 = PLATE, BackgroundTransparency = 0, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.fromOffset(0, 0) }, tip)
new("UIGradient", { Transparency = ns({ { 0, 0.48 }, { 0.75, 0.53 }, { 1, 0.9 } }) }, panel)
local tipStuds = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = STUD_TILE, ScaleType = Enum.ScaleType.Tile,
	TileSize = UDim2.fromOffset(19, 19), ImageTransparency = 0.15, ZIndex = 1 }, panel)
new("UIGradient", { Transparency = ns({ { 0, 0 }, { 0.7, 0 }, { 1, 1 } }) }, tipStuds)
local tipList = frame(panel, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), ZIndex = 2 })
new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, tipList)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, tipList)

local tipVals = {}
for i, s in MultiCfg.SOURCES do
	local row = frame(tipList, { LayoutOrder = i, Size = UDim2.fromOffset(TIP_W, ROW_H), ZIndex = 2 })
	if s.icon ~= "" then
		local ih = 24
		new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(math.round(ih * s.aspect), ih), Image = s.icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, row)
	end
	local name = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -34 - 80, 1, 0), FontFace = HEAVY, TextSize = 16,
		TextColor3 = C("e6edf5"), TextXAlignment = Enum.TextXAlignment.Left, Text = s.label, ZIndex = 3 }, row)
	new("UIStroke", { Color = INK, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Round }, name)
	local val = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 110, 1, 0),
		FontFace = HEAVY, TextSize = 21, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right, Text = "x1", ZIndex = 3 }, row)
	new("UIStroke", { Color = INK, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round }, val)
	tipVals[s.key] = val
	local function upd()
		local v = player:GetAttribute("Multi_" .. s.key) or 1
		val.Text = NF.mult(v)
		val.TextColor3 = v > 1 and ORANGE or DIM -- x1 — приглушений сірий, бонус — помаранчевий
	end
	player:GetAttributeChangedSignal("Multi_" .. s.key):Connect(upd)
	upd()
end

-- рядок доходу (v10, 28.10.2026): скільки гравець заробляє за хвилину (атрибут IncomePerMin, IncomeService на сервері)
do
	local row = frame(tipList, { LayoutOrder = 100, Size = UDim2.fromOffset(TIP_W, ROW_H), ZIndex = 2 })
	local name = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -110, 1, 0), FontFace = HEAVY, TextSize = 16,
		TextColor3 = C("e6edf5"), TextXAlignment = Enum.TextXAlignment.Left, Text = "INCOME", ZIndex = 3 }, row)
	new("UIStroke", { Color = INK, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Round }, name)
	local val = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 140, 1, 0),
		FontFace = HEAVY, TextSize = 19, TextColor3 = C("7ef05a"), TextXAlignment = Enum.TextXAlignment.Right, Text = "", ZIndex = 3 }, row)
	new("UIStroke", { Color = INK, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round }, val)
	local function upd() val.Text = NF.money(tonumber(player:GetAttribute("IncomePerMin")) or 0) .. "/min" end
	player:GetAttributeChangedSignal("IncomePerMin"):Connect(upd)
	upd()
end

-- анімація наведення: плашка виростає з лівого нижнього кута (AnchorPoint 0,1) в бік правого верхнього
local TIP_FROM = 0.35
local tipAnim = new("NumberValue", { Value = TIP_FROM })
local tipShown = false
local tipGap = 6
local function placeTip()
	tipScale.Scale = uiScale.Scale * tipAnim.Value
	local p = multiSlot.AbsolutePosition - gui.AbsolutePosition
	-- не накладається на кнопки Shop/Index/Quests (MainHUD: лівий відступ 16 + x 11 + ширина 90, масштаб = висота / 720)
	local minX = (16 + 11 + 90 + 14) * (gui.AbsoluteSize.Y / 720)
	tip.Position = UDim2.fromOffset(math.max(p.X, minX), p.Y - tipGap * uiScale.Scale)
end
local function setTip(on: boolean)
	if on == tipShown then return end
	tipShown = on
	if on then
		tipAnim.Value = TIP_FROM
		placeTip(); tip.Visible = true
		TweenService:Create(tipAnim, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 }):Play()
		tw(tip, 0.12, { GroupTransparency = 0 })
		task.spawn(function()
			while tipShown or tip.Visible do
				placeTip()
				RunService.RenderStepped:Wait()
			end
		end)
	else
		TweenService:Create(tipAnim, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = TIP_FROM }):Play()
		tw(tip, 0.14, { GroupTransparency = 1 })
		task.delay(0.16, function() if not tipShown then tip.Visible = false end end)
	end
end
local tipHit = new("TextButton", { Name = "TipHit", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, multiSlot)
local MULTI_HOVER_K = 1.12 -- напис TOTAL MULTI при наведенні
tipHit.MouseEnter:Connect(function()
	setTip(true)
	tw(multiHover, 0.14, { Scale = MULTI_HOVER_K }, Enum.EasingStyle.Back)
end)
tipHit.MouseLeave:Connect(function()
	setTip(false)
	tw(multiHover, 0.12, { Scale = 1 })
end)
tipHit.Activated:Connect(function() -- на тачі: тап показує на 3 с
	if UIS.TouchEnabled and not UIS.MouseEnabled then
		setTip(true)
		task.delay(3, function() setTip(false) end)
	end
end)

-- ===== дані =====
local function setMulti(n: number)
	multLabel.Text = 'TOTAL MULTI <font color="#5ff2ff">' .. multText(n) .. "</font>"
end
local shown = player:GetAttribute("Money") or 0
local lockW: number? = nil
local animId = 0
moneyLabel.Text = money(shown)
setMulti(player:GetAttribute("TotalMulti") or 1)

-- ширина підкладки суми задається явно (текст + відступи): AutomaticSize у Roblox не завжди звужується назад
local function setW(w: number)
	cash.Size = UDim2.fromOffset(math.ceil(w) + PAD_L + PAD_R, CASH_H)
end
setW(textWidth(money(shown), MONEY_SIZE))

local function popup(gain: number)
	local t = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0),
		Size = UDim2.fromOffset(300, 34), FontFace = HEAVY, TextSize = 28, TextColor3 = C("7dff3a"), TextXAlignment = Enum.TextXAlignment.Left,
		Text = "+" .. money(gain), ZIndex = 10 }, btnHolder)
	local st = new("UIStroke", { Color = INK, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round }, t)
	tw(t, 1.1, { Position = t.Position - UDim2.fromOffset(-10, 44) }, Enum.EasingStyle.Quad)
	task.delay(0.6, function()
		tw(t, 0.5, { TextTransparency = 1 }); tw(st, 0.5, { Transparency = 1 })
	end)
	task.delay(1.2, function() t:Destroy() end)
end

local function onMoney()
	local target = player:GetAttribute("Money") or 0
	local from = shown
	if target == from then return end
	animId += 1
	local my = animId
	local wFrom, wTo = textWidth(money(from), MONEY_SIZE), textWidth(money(target), MONEY_SIZE)
	lockW = math.max(lockW or 0, wFrom, wTo)
	setW(lockW)
	if target > from then
		popup(target - from)
		moneyScale.Scale = 1
		local up = TweenService:Create(moneyScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.08 })
		up:Play()
		up.Completed:Connect(function() tw(moneyScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back) end)
	end
	local t0 = os.clock()
	while my == animId do
		local u = math.min(1, (os.clock() - t0) / 0.65)
		shown = from + (target - from) * (1 - (1 - u) ^ 3)
		moneyLabel.Text = money(shown)
		if u >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	if my ~= animId then return end
	shown = target
	moneyLabel.Text = money(target)
	-- підкладка плавно звужується до кінцевого числа
	local w0, s0 = lockW :: number, os.clock()
	while my == animId do
		local k = math.min(1, (os.clock() - s0) / 0.25)
		setW(w0 + (wTo - w0) * (1 - (1 - k) ^ 3))
		if k >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	if my == animId then lockW = nil end
end
player:GetAttributeChangedSignal("Money"):Connect(function() task.spawn(onMoney) end)
player:GetAttributeChangedSignal("TotalMulti"):Connect(function() setMulti(player:GetAttribute("TotalMulti") or 1) end)
