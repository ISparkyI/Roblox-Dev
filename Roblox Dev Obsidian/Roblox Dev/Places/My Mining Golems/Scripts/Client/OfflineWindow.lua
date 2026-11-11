--!nonstrict
-- OfflineWindow — вікно офлайн-доходу (04.11.2026). Де: StarterPlayer/StarterPlayerScripts/OfflineWindow (LocalScript).
-- Сервер — OfflineService: атрибути гравця OfflinePending ($ до видачі) і OfflineSec (скільки був відсутній).
-- Через SHOW_DELAY с після входу (після загрузочного екрана: SoundService.LoadingMusicOK) — маленьке вікно в стилі гри:
--   «WELCOME BACK!», «You were away for …», сума з анімацією 0 → N, зелена кнопка CLAIM → Remotes/OfflineAction ("Claim").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = RS:WaitForChild("Shared")
local NF = require(Shared:WaitForChild("NumberFormat"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOW_DELAY = 5
local COUNT_TIME = 1.6
local CASH_ICON = "rbxassetid://103015355952567"
local SKIP_ICON = "rbxassetid://76478987044650"
local W, H = 540, 330

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
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
local function stroke(o, color, th, tr, contextual)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0,
		LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	return t
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function fmtAway(sec: number): string
	sec = math.max(0, math.floor(sec))
	local h, m = sec // 3600, (sec % 3600) // 60
	if h > 0 then return h .. "h " .. m .. "m" end
	return math.max(1, m) .. "m"
end

-- ===== вікно =====
local gui = new("ScreenGui", { Name = "OfflineWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 30, Enabled = false }, playerGui)
local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true }, gui)
local root = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H + 80),
	BackgroundTransparency = 1 }, gui)
local fitScale = new("UIScale", {}, root)
local pop = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, root)
local popScale = new("UIScale", { Scale = 1 }, pop)

local WY = 60 -- вікно нижче заголовка
frame(pop, 0, WY + 12, W, H, BLACK, { BackgroundTransparency = 0.65 })
local win = frame(pop, 0, WY, W, H, WHITE, { ZIndex = 2 })
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("5d636b"), C("3c4047")) }, win)
stroke(win, INK, 5)
local pw, ph = W - 30, H - 30
local panel = frame(win, 15, 15, pw, ph, C("a9aeb5"), { ZIndex = 2, ClipsDescendants = true })
stroke(panel, INK, 4)
local CELL = 36
local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
pcall(StyleA.studTile, frame(panel, 0, 0, pw, ph, nil, { BackgroundTransparency = 1, ZIndex = 2 }), (pw - nx * CELL) / 2, (ph - ny * CELL) / 2, nx * CELL, ny * CELL, CELL, C("b3b8bf"))
local shade = frame(panel, 0, 0, pw, ph, BLACK, { ZIndex = 3 })
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 0.55) }) }, shade)

-- заголовок над вікном: годинник з купюрою + «WELCOME BACK!» з переливом
local tIcon = new("ImageLabel", { BackgroundTransparency = 1, Image = SKIP_ICON, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(62, WY - 2), Size = UDim2.fromOffset(104, 104), Rotation = -8, ZIndex = 6 }, pop)
new("ImageLabel", { BackgroundTransparency = 1, Image = CASH_ICON, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(86, 82), Size = UDim2.fromOffset(60, 60), ZIndex = 7 }, tIcon)
label(pop, 122, WY - 40 + 7, W - 130, 70, 60, "WELCOME BACK!", INK, 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local title = label(pop, 122, WY - 40, W - 130, 70, 60, "WELCOME BACK!", WHITE, 7, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
local tGrad = new("UIGradient", { Rotation = 0 }, title)

-- переклад (автопереклад Roblox): фраза окремо від чисел — «You were away for» перекладається, час і сума — ні (AutoLocalize = false)
local function autoText(parent, text, size, color, sw, order, localize, h)
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = XBOLD, TextSize = size, TextColor3 = color, Text = text, AutoLocalize = localize,
		Size = UDim2.fromOffset(0, h or 34), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = order, ZIndex = 6 }, parent)
	stroke(t, INK, sw, 0, true)
	return t
end
local awayRow = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(W / 2, 58),
	Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 6 }, win)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, awayRow)
autoText(awayRow, "You were away for", 26, SUB_TXT, 3.5, 1, true)
local away = autoText(awayRow, "", 26, C("ffd23a"), 3.5, 2, false)
local row = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(W / 2, 140),
	Size = UDim2.fromOffset(0, 80), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 6 }, win)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, row)
new("ImageLabel", { BackgroundTransparency = 1, Image = CASH_ICON, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(70, 70), Rotation = -8, LayoutOrder = 1, ZIndex = 7 }, row)
local amount = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 66, TextColor3 = C("b8ff5a"), Text = "$0", AutoLocalize = false,
	Size = UDim2.fromOffset(0, 80), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, ZIndex = 7 }, row)
stroke(amount, INK, 6, 0, true)
local amtScale = new("UIScale", {}, amount)
label(win, 0, 184, W, 24, 18, "Your golems kept mining while you were away · max 24h", SUB_TXT, 2.5, { ZIndex = 6, FontFace = XBOLD })

-- 10.11.2026: дві кнопки — CLAIM (безкоштовно) і x2 CLAIM за Robux (Developer Product OfflineX2, MonetizationConfig.Products)
local BW, BG = 236, 20
local bx0 = (W - BW * 2 - BG) / 2
local btn = StyleA.new(win, { size = Vector2.new(BW, 74), position = Vector2.new(bx0, H - 100), color = "green", text = "CLAIM",
	textSize = 38, clickable = true, shine = true, zIndex = 8 })
StyleA.bind(btn, { debounce = 0.3, onClick = function() if btn.onClaim then btn.onClaim() end end })
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local X2 = MonCfg.Products.OfflineX2
local btn2 = StyleA.new(win, { size = Vector2.new(BW, 74), position = Vector2.new(bx0 + BW + BG, H - 100), color = "yellow", text = "x2 CLAIM",
	textSize = 36, clickable = true, shine = true, zIndex = 8 })
-- ціна в Robux — плашка на правому верхньому куті кнопки
do
	-- 10.11.2026: без рамки; над верхнім краєм кнопки, щоб не налазила на напис «x2 CLAIM»
	local tag = frame(win, bx0 + BW * 2 + BG - 72, H - 116, 78, 26, INK, { ZIndex = 12 })
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, tag)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4) }, tag)
	new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://139687766069559", ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(20, 20), ZIndex = 13 }, tag)
	new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 20, TextColor3 = WHITE, Text = tostring(X2 and X2.robux or 19), AutoLocalize = false,
		Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 13 }, tag)
end
StyleA.bind(btn2, { debounce = 0.6, onClick = function()
	if not X2 or (X2.id or 0) == 0 then
		local ui = RS:FindFirstChild("UIEvents")
		local toast = ui and ui:FindFirstChild("Toast")
		if toast then toast:Fire("Coming soon!", "gray", nil) end
		return
	end
	pcall(function() game:GetService("MarketplaceService"):PromptProductPurchase(player, X2.id) end)
end })

local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	fitScale.Scale = math.clamp(math.min(vp.X / (W + 80), vp.Y / (H + 200)), 0.45, 1.15)
end

local isOpen, counting = false, false
local shown = 0
RunService.Heartbeat:Connect(function()
	if not isOpen then return end
	local P = { C("fffbe0"), C("b8ff5a"), C("4fd14a"), C("b8ff5a") }
	local phase = -(os.clock() / 4)
	local ks = {}
	for k = 0, 12 do
		local u = (k / 12 * 2 + phase) % 1 * #P
		local i = math.floor(u)
		local t = u - i
		t = t * t * (3 - 2 * t)
		ks[#ks + 1] = ColorSequenceKeypoint.new(k / 12, P[i + 1]:Lerp(P[(i + 1) % #P + 1], t))
	end
	tGrad.Color = ColorSequence.new(ks)
end)

local function countUp(target: number)
	counting = true
	local t0 = os.clock()
	local lastStep = -1
	task.spawn(function()
		while isOpen and os.clock() - t0 < COUNT_TIME do
			local k = (os.clock() - t0) / COUNT_TIME
			k = 1 - (1 - k) ^ 3
			shown = math.floor(target * k)
			amount.Text = NF.money(shown)
			local step = math.floor(k * 14)
			if step ~= lastStep then lastStep = step; UISounds.play("tap", 0.05, 1 + k * 0.4) end
			RunService.Heartbeat:Wait()
		end
		shown = target
		amount.Text = NF.money(target)
		amtScale.Scale = 1.25
		tween(amtScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		counting = false
	end)
end

local function open()
	local n = tonumber(player:GetAttribute("OfflinePending")) or 0
	if n <= 0 or isOpen then return end
	isOpen = true
	fit()
	away.Text = fmtAway(tonumber(player:GetAttribute("OfflineSec")) or 0)
	amount.Text = "$0"
	gui.Enabled = true
	dim.BackgroundTransparency = 1
	tween(dim, 0.25, { BackgroundTransparency = 0.45 })
	popScale.Scale = 0.6
	tween(popScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(0.3, function() countUp(n) end)
	-- 11.11.2026: аналітика — фанел OfflineEarnings, крок 1 «Window shown» (OfflineService)
	task.spawn(function()
		local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("OfflineAction")
		if rf then pcall(rf.InvokeServer, rf, "Shown") end
	end)
end
local function close()
	if not isOpen then return end
	isOpen = false
	tween(popScale, 0.15, { Scale = 0.8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(dim, 0.15, { BackgroundTransparency = 1 }).Completed:Connect(function() if not isOpen then gui.Enabled = false end end)
end

btn.onClaim = function()
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("OfflineAction")
	if not rf then return end
	local ok, res = pcall(rf.InvokeServer, rf, "Claim")
	if ok and type(res) == "table" and res.ok then
		UISounds.play("claim", 0.1)
		local ui = RS:FindFirstChild("UIEvents")
		local toast = ui and ui:FindFirstChild("Toast")
		if toast then toast:Fire("+" .. NF.money(res.gain or 0) .. " Money!", "green", nil) end
		close()
	else
		pcall(StyleA.shake, btn)
		close()
	end
end
-- 10.11.2026: x2 куплено (OfflineService.ClaimX2 ставить OfflineX2Gain) — тост і закрити вікно
player:GetAttributeChangedSignal("OfflineX2Gain"):Connect(function()
	local g = tonumber(player:GetAttribute("OfflineX2Gain")) or 0
	if g <= 0 then return end
	UISounds.play("claim", 0.1)
	local ui = RS:FindFirstChild("UIEvents")
	local toast = ui and ui:FindFirstChild("Toast")
	if toast then toast:Fire("+" .. NF.money(g) .. " Money! (x2)", "green", nil) end
	close()
end)
local cam = workspace.CurrentCamera
if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then fit() end end) end

-- ===== підказка в HUD зверху по центру (04.11.2026): «Golems mine $N/h even offline» — неяскрава плашка, нагадує повернутись =====
--   N = IncomePerMin × 60 (до 24 год офлайну). Ховається на арені боса (InBossArena) і поки відкрите вікно WELCOME BACK.
-- 05.11.2026: адаптивно — плашка стоїть у ряду верхніх кнопок (MainHUD/TopRow), по центру екрана; якщо там тісно — зсувається
--   в проміжок між лівою і правою групою кнопок і трохи зменшується (не менше HINT_MIN); не влазить і так — опускається під ряд кнопок.
--   Позиція рахується від реальних кнопок, тож інші вікна / меню її не зсувають.
local hint = new("ScreenGui", { Name = "OfflineHint", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None, DisplayOrder = 2, Enabled = true }, playerGui)
-- 10.11.2026: підказка перенесена з верхнього ряду кнопок — маленьким текстом зліва над TOTAL MULTI (MoneyHUD), коротко:
--   «Offline $N/h» (на телефонах теж). Позиція й масштаб — від мітки TOTAL MULTI.
local pill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(16, 600), Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, hint)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, pill)
local hintScale = new("UIScale", {}, pill)
new("ImageLabel", { BackgroundTransparency = 1, Image = SKIP_ICON, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(18, 18), LayoutOrder = 1 }, pill)
-- частини (для автоперекладу): «Offline» / сума (не перекладається)
local function hintPart(text, color, order, localize)
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = XBOLD, TextSize = 15, TextColor3 = color, AutoLocalize = localize,
		Text = text, Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = order }, pill)
	stroke(t, INK, 2, 0, true)
	return t
end
hintPart("Offline", C("dfe4ea"), 2, true)
local hintText = hintPart("", C("b8ff5a"), 3, false)
local GuiService = game:GetService("GuiService")
local hintWant, hintFits = false, true
local function hintLayout()
	local hud = playerGui:FindFirstChild("MoneyHUD")
	local tm = hud and hud:FindFirstChild("TotalMulti", true)
	if not (tm and tm:IsA("GuiObject") and tm.AbsoluteSize.Y > 2 and hud.Enabled) then hintFits = false; pill.Visible = false; return end
	hintFits = tm.Visible
	local base = hint.AbsolutePosition
	local k = math.clamp(tm.AbsoluteSize.Y / 36, 0.5, 1.4)
	if math.abs(hintScale.Scale - k) > 0.02 then hintScale.Scale = k end
	pill.Position = UDim2.fromOffset(math.floor(tm.AbsolutePosition.X - base.X + 4 * k + 0.5), math.floor(tm.AbsolutePosition.Y - base.Y - 1 * k + 0.5))
	pill.Visible = hintWant and hintFits
end
local function hintUpdate()
	local rate = tonumber(player:GetAttribute("IncomePerMin")) or 0
	hintText.Text = NF.money(math.floor(rate * 60)) .. "/h"
	-- 06.11.2026: на маркеті (ReplicatedStorage.MarketMode / HubConfig.isMarket) підказки немає
	local okH, Hub = pcall(require, game:GetService("ReplicatedStorage").Shared.HubConfig)
	local mkt = okH and Hub.isMarket and Hub.isMarket() or false
	hintWant = rate > 0 and player:GetAttribute("InBossArena") ~= true and not isOpen and not mkt
	pill.Visible = hintWant and hintFits
	hintLayout()
end
hint:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() task.defer(hintLayout) end)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function() task.defer(hintLayout) end)
player:GetAttributeChangedSignal("IncomePerMin"):Connect(hintUpdate)
player:GetAttributeChangedSignal("InBossArena"):Connect(hintUpdate)
task.spawn(function() while true do hintUpdate(); task.wait(0.5) end end)

-- показ: після загрузочного екрана + SHOW_DELAY с; сума могла прийти пізніше (дані ще вантажились) — чекаємо до 30 с
local t0 = os.clock()
while not SoundService:GetAttribute("LoadingMusicOK") and os.clock() - t0 < 30 do task.wait(0.2) end
task.wait(SHOW_DELAY)
local t1 = os.clock()
while (tonumber(player:GetAttribute("OfflinePending")) or 0) <= 0 and os.clock() - t1 < 30 do task.wait(0.5) end
open()
