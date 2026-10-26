-- MainHUD v1 — головний екран: усі кнопки, лічильники, x2 Money, Rebirth, Boss і таймер боса (макет Main HUD, v22).
-- Де: StarterPlayer/StarterPlayerScripts/MainHUD (LocalScript). Інтерфейс будується кодом.
-- Лічильник грошей і TOTAL MULTI — окремо, скрипт MoneyHUD (тут його немає).
--
-- Розміри — в одиницях макета висотою 720 (UIScale = висота екрана / 720); ширина слідує за екраном:
-- ліві елементи прив'язані до лівого краю з відступом INSET, праві — до правого. ScreenInsets = CoreUISafeInsets (вирізи телефона).
-- Великі кнопки — іконка і великий підпис під нею, без підкладок. Малі кнопки зверху — висотою 40 без підписів.
-- Лічильники (діаманти, тікети, ребіти) — підкладка як у грошей: темна, зникає праворуч, зі слабкими studs.
--
-- Дані (атрибути гравця): Diamonds, Tickets, Rebirths (числа, за замовчуванням 0).
-- Таймер боса: атрибут Workspace BossAt (час сервера GetServerTimeNow, коли з'явиться бос); без нього показує --:--.
-- Кнопки шлють ReplicatedStorage/UIEvents/HUDButton:Fire(ключ) — ключі: Shop, Index, Quests, Rebirth, Boss, Settings, Inventory,
-- Feedback, Codes, Updates, X2Money. Invite відкриває системне вікно запрошення друзів Roblox.
--
-- ICON: asset ID іконок (завантажені через Asset Manager з Main HUD/Roblox/Import). Порожній ID — картинки не видно.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local NF = require(RS:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds")) -- звук натискання кнопок HUD
local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local player = Players.LocalPlayer

local ICON = { -- усі ID перевірені через MarketplaceService:GetProductInfo (ім'я hud_*)
	shop = "rbxassetid://91791061262477", index = "rbxassetid://139239217489271", quests = "rbxassetid://140685411214992",
	rebirth = "rbxassetid://124015236802911", cash = "rbxassetid://103015355952567", robux = "rbxassetid://139687766069559", boss = "rbxassetid://96163616047646",
	invite = "rbxassetid://109796913398904", settings = "rbxassetid://111541402429276", inventory = "rbxassetid://107241982376806",
	feedback = "rbxassetid://84284099600077", codes = "rbxassetid://116306459544574", updates = "rbxassetid://133326399418460",
	diamond = "rbxassetid://126442692946356", ticket = "rbxassetid://85299808396483", rebirth_c = "rbxassetid://134045976199050",
}
-- ширина / висота обрізаних іконок (малі кнопки й лічильники)
local ASP = { invite = 1.0711, settings = 1.024, inventory = 0.8516, feedback = 1.0894, codes = 1.3545, updates = 1.1327,
	diamond = 0.7734, ticket = 0.8516, rebirth_c = 0.9844 }

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local PLATE = C("0e1014")
local WHITE = Color3.new(1, 1, 1)
local LIME = C("c9ff3a")
local STUD_TILE = "rbxassetid://113147180553208" -- stylea_tile_gray_half (як у MoneyHUD)
local INSET = 16
local DH = 720

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
local function tw(o, t, p, style) TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad), p):Play() end

-- текст із темним контуром (як у макеті): розмір fs, контур ≈ 0.12·fs
local function text(parent, props, fs)
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = fs, TextColor3 = WHITE, TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	for k, v in props do t[k] = v end
	new("UIStroke", { Color = INK, Thickness = math.max(1.5, fs * 0.12), LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	return t
end

local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("MainHUD"); if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "MainHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4 }, pg)
local root = frame(gui, { Size = UDim2.fromOffset(1280, DH) })
local uiScale = new("UIScale", {}, root)
local function fit()
	local a = gui.AbsoluteSize
	if a.Y < 10 then return end
	local s = a.Y / DH
	uiScale.Scale = s
	root.Size = UDim2.fromOffset(a.X / s, DH)
end
fit()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

local uiEvents = RS:FindFirstChild("UIEvents") or new("Folder", { Name = "UIEvents" }, RS)
local hudEvent = uiEvents:FindFirstChild("HUDButton") or new("BindableEvent", { Name = "HUDButton" }, uiEvents)

-- позиція: x — від лівого краю (INSET уже враховано в L), або d — відстань від лівої межі елемента до правого краю (R)
local function pos(x, y, fromRight, raw)
	local i = raw and 0 or INSET
	if fromRight then return UDim2.new(1, -(i + x), 0, y) end
	return UDim2.fromOffset(i + x, y)
end

-- кнопка: тримач (зона натискання) → content (масштабується від центру) → іконка (+ підпис) і прозора кнопка зверху
local function button(parent, o)
	local holder = frame(parent, { Position = pos(o.x, o.y, o.right, o.raw), Size = UDim2.fromOffset(o.w, o.h) })
	local content = frame(holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1) })
	local scale = new("UIScale", {}, content)
	local ih = o.ih or o.h
	local labelY = ih - (o.fs or 0) * 0.85
	if o.tile then
		-- підкладка (макет HUD B): плитка стилю A кольору o.tile; рожевої в StyleA немає — сіра, тонована ImageColor3.
		-- Плитка ts × ts по центру, іконка ≈0,78 плитки трохи вище центру, підпис залазить на низ плитки.
		local ts = o.ts or math.round(ih * 0.92)
		local ty = o.ty or math.round(ih * 0.04)
		local pink = o.tile == "pink"
		local t = StyleA.new(content, { size = Vector2.new(ts, ts), position = Vector2.new((o.w - ts) / 2, ty), anchor = Vector2.new(0, 0),
			color = pink and "gray" or o.tile, half = true, clickable = false, zIndex = 1, name = "Tile" })
		if pink then t.root.ImageColor3 = C("ff9ad9"); t.tile.ImageColor3 = C("ff9ad9") end
		local ii = o.iconIn or math.round(ts * 0.78)
		new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromOffset((o.w - ii) / 2, ty + ts * (o.iconY or 0.44) - ii / 2),
			Size = UDim2.fromOffset(ii, ii), Image = ICON[o.icon], ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, content)
		labelY = ty + ts - (o.fs or 0) * 0.55
	else
		new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(o.w, ih),
			Image = ICON[o.icon] ~= "" and ICON[o.icon] or "", ScaleType = Enum.ScaleType.Fit }, content)
	end
	if o.label then
		text(content, { Name = "Label", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, labelY),
			Size = UDim2.fromOffset(o.w + 60, o.fs), Text = o.label, TextColor3 = o.lc or WHITE, ZIndex = 3 }, o.fs)
	end
	local b = new("TextButton", { Name = "Hit", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, content)
	b.MouseEnter:Connect(function() tw(scale, 0.12, { Scale = 1.08 }) end)
	b.MouseLeave:Connect(function() tw(scale, 0.12, { Scale = 1 }) end)
	b.MouseButton1Down:Connect(function() tw(scale, 0.08, { Scale = 0.92 }) end)
	b.MouseButton1Up:Connect(function() tw(scale, 0.15, { Scale = 1.08 }, Enum.EasingStyle.Back) end)
	b.Activated:Connect(function()
		UISounds.play("tap", 0.08)
		if o.key == "Invite" then
			pcall(function()
				if SocialService:CanSendGameInviteAsync(player) then SocialService:PromptGameInvite(player) end
			end)
		else
			hudEvent:Fire(o.key)
		end
	end)
	return holder, content, b
end

-- ===== верхній ряд (Invite, Settings, Inventory ліворуч; Feedback, Codes, Updates праворуч) =====
-- У реальних пікселях (без UIScale), щоб стояти в один ряд з кнопками Roblox (меню, чат): висота — TOP_H, центр по вертикалі — TOP_CY,
-- ліва група починається саме після лівих кнопок Roblox (GuiService.TopbarInset.Min.X) і наслідує їх зміни.
local GuiService = game:GetService("GuiService")
local TOP_H, TOP_CY, G = 40, 35, 18
local TOP_TS = 40 -- малі верхні кнопки на плитках: плитка 40 × 40 (як кнопка чату Roblox), іконка 30
local topLayer = frame(gui, { Size = UDim2.fromScale(1, 1), Name = "TopRow" })
local leftTop = {}
do
	for _, a in { { "invite", "Invite", "green" }, { "settings", "Settings", "gray" }, { "inventory", "Inventory", "orange" } } do
		local w = TOP_TS
		local h = button(topLayer, { x = 0, y = TOP_CY - TOP_TS / 2, w = w, h = TOP_TS, icon = a[1], key = a[2], raw = true,
			tile = a[3], ts = TOP_TS, ty = 0, iconIn = TOP_TS - 10, iconY = 0.45 })
		table.insert(leftTop, { holder = h, w = w })
	end
	local function layoutTop()
		local x = GuiService.TopbarInset.Min.X + 16
		for _, t in leftTop do
			t.holder.Position = UDim2.fromOffset(x, TOP_CY - TOP_TS / 2)
			x += t.w + G
		end
	end
	layoutTop()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutTop)

	local d = 16
	for _, a in { { "updates", "Updates", "blue" }, { "codes", "Codes", "yellow" }, { "feedback", "Feedback", "pink" } } do
		local w = TOP_TS
		d += w
		button(topLayer, { x = d, y = TOP_CY - TOP_TS / 2, w = w, h = TOP_TS, icon = a[1], key = a[2], right = true, raw = true,
			tile = a[3], ts = TOP_TS, ty = 0, iconIn = TOP_TS - 10, iconY = 0.45 })
		d += G
	end
end

-- ===== лічильники: підкладка як у грошей (темна, зникає праворуч, слабкі studs) =====
local counters = {}
local function counter(y, icon, attr, key)
	local plate = frame(root, { Name = "Counter_" .. attr, Position = pos(-16, y), Size = UDim2.fromOffset(210, 38), BackgroundTransparency = 0, BackgroundColor3 = PLATE,
		ClipsDescendants = true })
	-- непрозорість менша на 33% за гроші (0.78 → 0.52, 0.70 → 0.47)
	new("UIGradient", { Transparency = ns({ { 0, 0.48 }, { 0.6, 0.53 }, { 1, 1 } }) }, plate)
	local studs = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = STUD_TILE, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(19, 19), ImageTransparency = 0.15 }, plate)
	new("UIGradient", { Transparency = ns({ { 0, 0 }, { 0.5, 0 }, { 1, 1 } }) }, studs)
	-- одна висота іконки (30) у слоті 44, по центру плашки
	local ih = 30
	local iw = math.round(ih * ASP[icon])
	local iconImg = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(30 + 22, 19),
		Size = UDim2.fromOffset(iw, ih), Image = ICON[icon], ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, plate)
	local iconScale = new("UIScale", {}, iconImg)
	local v = text(plate, { Name = "Value", Position = UDim2.fromOffset(30 + 44 + 10, 0), Size = UDim2.new(1, -94, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
		Text = "0", ZIndex = 2 }, 24)
	-- плашка теж клікабельна (відкриває потрібну сторінку магазину)
	local hit = new("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, plate)
	hit:SetAttribute("NoHoverSound", true) -- лічильники без звуку наведення (бажання користувача)
	hit.Activated:Connect(function() UISounds.play("tap", 0.08); hudEvent:Fire(key) end)
	-- зростання з будь-якого джерела (Index Claim, квест, покупка…): число рахує вгору від старого до нового (~0,6 с),
	-- іконка «попає» масштабом; зменшення (витрата) — одразу
	local shown = new("NumberValue", { Name = "Shown", Value = tonumber(player:GetAttribute(attr)) or 0 }, plate)
	shown.Changed:Connect(function(x) v.Text = NF.short(math.floor(x + 0.5)) end)
	local countTw = nil
	local function upd()
		local n = tonumber(player:GetAttribute(attr)) or 0
		if countTw then countTw:Cancel(); countTw = nil end
		if n > shown.Value + 0.5 then
			countTw = TweenService:Create(shown, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = n })
			countTw:Play()
			local up = TweenService:Create(iconScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.25 })
			up.Completed:Connect(function(st)
				if st == Enum.PlaybackState.Completed then tw(iconScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back) end
			end)
			up:Play()
		else
			shown.Value = n
		end
		v.Text = NF.short(math.floor(shown.Value + 0.5))
	end
	player:GetAttributeChangedSignal(attr):Connect(upd)
	upd()
	counters[attr] = v
end
counter(104, "diamond", "Diamonds", "DiamondsPlus")
counter(148, "ticket", "Tickets", "TicketsPlus")
counter(192, "rebirth_c", "Rebirths", "Rebirth")

-- ===== великі кнопки ліворуч: Shop, Index, Quests (іконка 90, підпис 23; менші та вище, щоб між ними й Money було більше місця) =====
-- (x = 11: центр такий самий, як був у іконки 104 при x = 4)
for _, a in { { "shop", "Shop", 242, "red" }, { "index", "Index", 350, "blue" }, { "quests", "Quests", 458, "orange" } } do
	button(root, { x = 11, y = a[3], w = 90, h = 90 + math.round(23 * 0.2), ih = 90, icon = a[1], label = a[2], fs = 23, key = a[2], tile = a[4] })
end

-- ===== праворуч: x2 Money (+ ціна в Robux над іконкою), Rebirth, Boss і таймер =====
do
	-- x2 Money: іконка 86, лівіше й вище від правого ряду; лівий край на 280 від правого краю (R)
	local mx, my, ms = 280, 135, 86
	local x2holder, x2content = button(root, { x = mx, y = my, w = ms, h = ms + math.round(24 * 0.2), ih = ms, icon = "cash", label = "x2 Money", fs = 24, lc = LIME, key = "X2Money", right = true })
	x2holder.ZIndex = 3 -- під час відльоту на MAX летить поверх Rebirth
	-- ціна: іконка Robux 32 і число 28 в один рядок по центру над іконкою (центральна лінія на 9 вище верху іконки)
	local price = frame(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -(INSET + mx - ms / 2), 0, my - 9), Size = UDim2.fromOffset(80, 32) })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, price)
	new("ImageLabel", { LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.fromOffset(32, 32), Image = ICON.robux, ScaleType = Enum.ScaleType.Fit }, price)
	local priceTxt = text(price, { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 32), Text = "8", TextColor3 = LIME }, 28)

	-- підпис і ціна — наступний ступінь x2 Money (атрибут DonateTier, множники й ціни — MultiConfig.DONATE_TIERS).
	-- Покупка (DonateTier зрос під час гри) — анімація «Cash Burst»: пачка стискається й підстрибує (±8°), лаймове кільце,
	-- 8 маленьких пачок і 6 іскор розлітаються, напис перекочується на наступний множник з білим спалахом.
	-- Остання покупка: той самий вибух, напис стає MAX (ціна зникає), через 0,7 с кнопка присідає, нахиляється на −14°
	-- і відлітає вправо-вгору за екран із слідом іскор. Зайшов у гру вже з MAX — кнопки просто немає.
	local lbl = x2content:FindFirstChild("Label") :: TextLabel
	local icon = x2content:FindFirstChild("Icon") :: ImageLabel
	local lblStroke = lbl:FindFirstChildOfClass("UIStroke")
	local iconScale = new("UIScale", {}, icon)
	local lblScale = new("UIScale", {}, lbl)
	local priceIcon = price:FindFirstChildOfClass("ImageLabel")
	local priceStroke = priceTxt:FindFirstChildOfClass("UIStroke")
	local lblPos0 = lbl.Position
	local holderPos0 = x2holder.Position
	local function multText(tier) return "x" .. NF.full(MultiCfg.nextDonateMult(tier) :: number) .. " Money" end -- x262,144 Money
	local function setX2(tier)
		local p = MultiCfg.nextDonatePrice(tier)
		lbl.Text = p and multText(tier) or "MAX"
		price.Visible = p ~= nil
		if p then priceTxt.Text = NF.full(p) end
		x2holder.Visible = p ~= nil
	end
	-- ефекти: шар поверх кнопки (центр — центр пачки)
	local fx = frame(x2holder, { Name = "Fx", Size = UDim2.fromOffset(ms, ms), ZIndex = 6 })
	local function burst()
		local c = Vector2.new(ms / 2, ms / 2)
		-- кільце
		local ring = frame(fx, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y), Size = UDim2.fromOffset(40, 40), ZIndex = 6 })
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
		local rs = new("UIStroke", { Color = LIME, Thickness = 12 }, ring)
		TweenService:Create(ring, TweenInfo.new(0.52, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(180, 180) }):Play()
		TweenService:Create(rs, TweenInfo.new(0.52, Enum.EasingStyle.Linear), { Thickness = 1, Transparency = 1 }):Play()
		task.delay(0.55, function() ring:Destroy() end)
		-- пачки грошей і іскри (фізика — вручну, RenderStepped)
		local parts = {}
		for i = 1, 8 do
			local a = math.rad(-90 + (i - 4.5) * 34 + math.random(-7, 7))
			local im = new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(30, 30), Image = ICON.cash,
				ScaleType = Enum.ScaleType.Fit, ZIndex = 7, Position = UDim2.fromOffset(c.X, c.Y), Rotation = math.random(0, 359) }, fx)
			table.insert(parts, { o = im, kind = "bill", vx = math.cos(a) * (95 + math.random() * 45), vy = math.sin(a) * (95 + math.random() * 45),
				vr = (math.random() < 0.5 and -1 or 1) * (200 + math.random() * 240), r0 = im.Rotation, life = 0.9 })
		end
		for i = 1, 6 do
			local a = math.random() * math.pi * 2
			local s = frame(fx, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y), Size = UDim2.fromOffset(12, 12), Rotation = 45,
				BackgroundTransparency = 0, BackgroundColor3 = i % 2 == 0 and WHITE or C("ffe066"), ZIndex = 7 })
			new("UIStroke", { Color = INK, Thickness = 2 }, s)
			table.insert(parts, { o = s, kind = "spark", a = a, d = 50 + math.random() * 30, life = 0.62 })
		end
		local t = 0
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			t += dt
			for _, p in parts do
				local u = math.min(1, t / p.life)
				if p.kind == "bill" then
					local tt = u * 0.9
					p.o.Position = UDim2.fromOffset(c.X + p.vx * tt, c.Y + p.vy * tt + 260 * tt * tt)
					p.o.Rotation = p.r0 + p.vr * tt
					p.o.ImageTransparency = u < 0.65 and 0 or (u - 0.65) / 0.35
				else
					local e = 1 - (1 - u) ^ 3
					local k = (u < 0.3 and u / 0.3 or 1 - (u - 0.3) / 0.7) * 1.3
					p.o.Position = UDim2.fromOffset(c.X + math.cos(p.a) * p.d * e, c.Y + math.sin(p.a) * p.d * e)
					p.o.Size = UDim2.fromOffset(12 * k, 12 * k)
					p.o.Rotation = 45 + u * 180
				end
			end
			if t >= 0.9 then conn:Disconnect(); for _, p in parts do p.o:Destroy() end end
		end)
	end
	local function punch() -- 0,85 → 1,25 (Back) → 1, з похитуванням ±8°
		TweenService:Create(iconScale, TweenInfo.new(0.07), { Scale = 0.85 }):Play()
		task.wait(0.07)
		TweenService:Create(iconScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.25 }):Play()
		TweenService:Create(icon, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), { Rotation = 8 }):Play()
		task.wait(0.1)
		TweenService:Create(icon, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), { Rotation = -8 }):Play()
		task.wait(0.1)
		icon.Rotation = 0
		TweenService:Create(iconScale, TweenInfo.new(0.26, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	local function rollLabel(newText) -- старий напис їде вгору й тане, новий виринає знизу з білим спалахом
		local i1 = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(lbl, i1, { Position = lblPos0 + UDim2.fromOffset(0, -18), TextTransparency = 1 }):Play()
		if lblStroke then TweenService:Create(lblStroke, i1, { Transparency = 1 }):Play() end
		task.wait(0.16)
		lbl.Text = newText
		lbl.Position = lblPos0 + UDim2.fromOffset(0, 16)
		lbl.TextColor3 = WHITE
		lblScale.Scale = 1.3
		local i2 = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(lbl, i2, { Position = lblPos0, TextTransparency = 0 }):Play()
		if lblStroke then TweenService:Create(lblStroke, TweenInfo.new(0.14), { Transparency = 0 }):Play() end
		TweenService:Create(lblScale, TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(0.14, function() TweenService:Create(lbl, TweenInfo.new(0.14), { TextColor3 = LIME }):Play() end)
	end
	local function flyAway() -- присідання, нахил і відліт вправо-вгору з іскрами, потім кнопка ховається
		local hs = x2holder:FindFirstChild("FlyScale") or new("UIScale", { Name = "FlyScale" }, x2holder)
		TweenService:Create(hs, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Scale = 0.93 }):Play()
		TweenService:Create(x2holder, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = holderPos0 + UDim2.fromOffset(0, 8) }):Play()
		task.wait(0.16)
		local flying = true
		task.spawn(function() -- слід з іскор
			while flying do
				local p = x2holder.Position
				local d = frame(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = p + UDim2.fromOffset(ms / 2, ms * 0.8), Size = UDim2.fromOffset(10, 10), Rotation = 45,
					BackgroundTransparency = 0, BackgroundColor3 = C("ffe066"), ZIndex = 2 })
				new("UIStroke", { Color = INK, Thickness = 2 }, d)
				TweenService:Create(d, TweenInfo.new(0.45), { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) }):Play()
				task.delay(0.46, function() d:Destroy() end)
				task.wait(0.045)
			end
		end)
		local fi = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		TweenService:Create(x2holder, fi, { Position = holderPos0 + UDim2.fromOffset(520, -90) }):Play()
		TweenService:Create(x2holder, TweenInfo.new(0.32, Enum.EasingStyle.Quad), { Rotation = -14 }):Play()
		TweenService:Create(hs, TweenInfo.new(0.2), { Scale = 1 }):Play()
		local fade = TweenInfo.new(0.21, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.49)
		TweenService:Create(icon, fade, { ImageTransparency = 1 }):Play()
		TweenService:Create(lbl, fade, { TextTransparency = 1 }):Play()
		if lblStroke then TweenService:Create(lblStroke, fade, { Transparency = 1 }):Play() end
		task.wait(0.7)
		flying = false
		x2holder.Visible = false
	end
	local busy = false
	local shown = nil -- ступінь, який зараз на кнопці
	local function onTier()
		local tier = player:GetAttribute("DonateTier") or 0
		-- перше значення (вхід у гру, завантаження даних) або зменшення — без анімації
		if shown == nil or tier <= shown or busy then shown = tier; if not busy then setX2(tier) end; return end
		shown = tier
		busy = true
		task.spawn(function()
			burst()
			task.spawn(punch)
			local p = MultiCfg.nextDonatePrice(tier)
			if p then
				priceTxt.Text = NF.full(p)
				rollLabel(multText(tier))
				task.wait(0.3)
			else
				-- останній ступінь: спершу MAX (ціна зникає), пауза, потім відліт
				local pf = TweenInfo.new(0.2)
				TweenService:Create(priceTxt, pf, { TextTransparency = 1 }):Play()
				if priceStroke then TweenService:Create(priceStroke, pf, { Transparency = 1 }):Play() end
				if priceIcon then TweenService:Create(priceIcon, pf, { ImageTransparency = 1 }):Play() end
				rollLabel("MAX")
				task.wait(0.3 + 0.7)
				price.Visible = false
				flyAway()
			end
			busy = false
			local now = player:GetAttribute("DonateTier") or 0
			if now ~= tier then shown = tier; onTier() end -- за час анімації купили ще раз
		end)
	end
	player:GetAttributeChangedSignal("DonateTier"):Connect(onTier)
	if player:GetAttribute("DonateTier") ~= nil then onTier() else setX2(0) end

	-- Rebirth: іконка 112, підпис 25
	button(root, { x = 105, y = 272, w = 98, h = 98 + math.round(22 * 0.2), ih = 98, icon = "rebirth", label = "Rebirth", fs = 22, key = "Rebirth", right = true, tile = "pink" })

	-- Boss: іконка 72, центр по вертикалі 669 (як центр плашки Money); таймер — плашка 250 × 54, права межа = центр іконки
	local bs, cy = 72, 669
	local timer = frame(root, { Position = UDim2.new(1, -(INSET + bs / 2 + 250), 0, cy - 27), Size = UDim2.fromOffset(250, 54), BackgroundTransparency = 0, BackgroundColor3 = PLATE })
	new("UIGradient", { Transparency = ns({ { 0, 1 }, { 0.45, 0.5 }, { 1, 0.14 } }) }, timer)
	local cap = text(timer, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(bs / 2 + 10), 0, 6), Size = UDim2.fromOffset(160, 14), TextXAlignment = Enum.TextXAlignment.Right,
		Text = "NEXT BOSS", TextColor3 = C("e7f0ff"), ZIndex = 2 }, 12)
	local clock = text(timer, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(bs / 2 + 10), 0, 18), Size = UDim2.fromOffset(160, 34), TextXAlignment = Enum.TextXAlignment.Right,
		Text = "--:--", ZIndex = 2 }, 32)
	button(root, { x = bs, y = cy - bs / 2, w = bs, h = bs + math.round(18 * 0.2), ih = bs, icon = "boss", label = "Boss", fs = 18, key = "Boss", right = true })

	task.spawn(function()
		while gui.Parent do
			local at = workspace:GetAttribute("BossAt")
			if type(at) == "number" then
				local left = math.max(0, math.ceil(at - workspace:GetServerTimeNow()))
				clock.Text = string.format("%02d:%02d", left // 60, left % 60)
			else
				clock.Text = "--:--"
			end
			task.wait(0.25)
		end
	end)
end
