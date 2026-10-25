-- RollUpgradeUI — екран табла Roll Upgrades у кожній ніші (свою можна прокачувати, чужі — лише дивитися): дві вертикальні картки (Roll Luck і Roll Stands) на 2D-підкладці зі studs.
-- Де: StarterPlayer/StarterPlayerScripts/RollUpgradeUI (LocalScript). Інтерфейс будується кодом.
-- SurfaceGui лежить у PlayerGui з Adornee на Board/screen табла (так працює клік мишкою), полотно 2080 × 1000.
-- Видно, лише коли табло опущене (коли RollScreenClient ховає табло, ховається й екран).
-- Дані — атрибути гравця RollLuckLvl, RollStands, Stage, Money; ціни — Shared/RollConfig, числа — Shared/NumberFormat.
-- Кнопки шлють Remotes/RollUpgrade ("Luck" / "Stands"); сервер перевіряє гроші (RollUpgradeService).
-- Іконки: картинки (Image) — конюшина й підставка з «+», відрендерені з веб-макета.
-- Стиль: усе квадратне (без UICorner, обводки рамок Miter), блиск картки — прямокутна смужка зверху. Кнопки купівлі —
-- «стиль A» з картинок (модуль Shared/StyleA). Заокруглення лишилися тільки на самих пупочках studs.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NF = require(RS:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local RollConfig = require(RS.Shared:WaitForChild("RollConfig"))
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local CardHover = require(RS.Shared:WaitForChild("CardHover")) -- наведення: ×1.05 і нахил до 3° у бік мишки
local UISfx = require(RS.Shared:WaitForChild("UISfx")) -- звук покупки
local remote = RS:WaitForChild("Remotes"):WaitForChild("RollUpgrade")

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local W, H = 2080, 1000
local CW, CH, GAP = 700, 790, 96

-- ===== будівельники =====
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
-- UICorner — тільки для пупочок studs (і форми sparkle); картки, кнопки, рамки — квадратні
local function corner(o, r) new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) }, o) end
-- обводка рамки — Miter (гострі кути); обводка тексту (contextual) — Round
local function stroke(o, color, th, tr, contextual)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0,
		LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function vgrad(o, keys, rot)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return new("UIGradient", { Color = ColorSequence.new(ks), Rotation = rot or 90 }, o)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	return t
end
-- пупочка studs з «L»-тінню (як у Money HUD)
local function stud(parent, x, y, cell, fill, shade, edge)
	local s = math.floor(cell * 0.62)
	local o = (cell - s) / 2
	local d = math.max(2, math.floor(s * 0.12 + 0.5))
	local r = math.max(3, math.floor(s * 0.16))
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill); corner(st, r)
	if edge then stroke(st, edge, 2) end
end
-- темніший колір (для нижньої смуги картки)
local function darken(c, k) return Color3.new(c.R * (1 - k), c.G * (1 - k), c.B * (1 - k)) end
-- косі світлі смуги на картці (як у «Store»): біла рамка Bands на всю картку, UIGradient під кутом 65°
-- дає три статичні смуги (широка, тонка, широка) з білим ≈ 10–18 %. Кліки не перехоплює (Active = false).
local function bands(parent, w, h)
	local f = frame(parent, 0, 0, w, h, WHITE, { Name = "Bands", Active = false })
	local K = NumberSequenceKeypoint.new
	new("UIGradient", { Rotation = 65, Color = ColorSequence.new(WHITE), Transparency = NumberSequence.new({ K(0, 1), K(0.16, 1), K(0.17, 0.82),
		K(0.31, 0.82), K(0.32, 1), K(0.47, 1), K(0.48, 0.9), K(0.53, 0.9), K(0.54, 1), K(0.70, 1), K(0.71, 0.85), K(0.83, 0.85), K(0.84, 1), K(1, 1) }) }, f)
	return f
end
local function sparkle(parent, cx, cy, r, tr)
	local g = frame(parent, cx - r, cy - r, 2 * r, 2 * r, nil, { BackgroundTransparency = 1 })
	local a = frame(g, r - r * 0.16, 0, r * 0.32, 2 * r, WHITE, { BackgroundTransparency = tr or 0 }); corner(a, UDim.new(0.5, 0))
	local b = frame(g, 0, r - r * 0.16, 2 * r, r * 0.32, WHITE, { BackgroundTransparency = tr or 0 }); corner(b, UDim.new(0.5, 0))
	local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(r * 0.7, r * 0.7), Rotation = 45,
		BackgroundColor3 = WHITE, BackgroundTransparency = tr or 0, BorderSizePixel = 0 }, g)
	return g
end

-- ===== іконки =====
-- Відрендерені з векторного макета PNG 512 px з прозорим фоном (Obsidian: Roll Upgrades Screen/Roblox),
-- завантажені в проект через Asset Manager.
local ICONS = {
	luck = { id = "rbxassetid://116109725516204", w = 420, h = 420 },   -- clover.png
	stands = { id = "rbxassetid://106904376756862", w = 440, h = 382 }, -- roll_stand.png (з зеленим «+»)
}
local function icon(parent, kind, cx, cy)
	local ic = ICONS[kind]
	return new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(ic.w, ic.h),
		BackgroundTransparency = 1, Image = ic.id, ScaleType = Enum.ScaleType.Fit, ZIndex = 2 }, parent)
end

-- ===== картка =====
local THEMES = {
	luck = { grad = { { 0, "a6e862" }, { 0.55, "6cc934" }, { 1, "3f9d18" } }, rim = "d6ff9e", stud = "b6f07a", studShade = "3f9a19" },
	stands = { grad = { { 0, "ff6f66" }, { 0.55, "e2322f" }, { 1, "a8161b" } }, rim = "ffb0a8", stud = "ff8f86", studShade = "a3161b" },
}
-- квадратна картка: квадратні тінь, обідок, косі світлі смуги Bands, темна суцільна смуга BottomStrip знизу, прямокутний
-- блиск зверху; кнопка купівлі — «стиль A» (StyleA)
local function card(parent, x, y, kind, title)
	local th = THEMES[kind]
	-- тримач (CanvasGroup) — щоб картку разом з тінню можна було збільшувати й нахиляти при наведенні
	local holder, o = CardHover.holder(parent, x, y, CW, CH, 14)
	frame(holder, o.X, o.Y + 14, CW, CH, Color3.new(0, 0, 0), { BackgroundTransparency = 0.65 })
	local c = frame(holder, o.X, o.Y, CW, CH, WHITE); vgrad(c, th.grad); stroke(c, INK, 6)
	-- studs на картці (ледь помітні)
	local sg = new("CanvasGroup", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(CW - 20, CH - 20), BackgroundTransparency = 1, GroupTransparency = 0.68 }, c)
	local cell = 46
	for cx = 0, math.ceil((CW - 20) / cell) - 1 do
		for cy = 0, math.ceil((CH - 20) / cell) - 1 do
			local s = cell * 0.6; local o = (cell - s) / 2
			local a = frame(sg, cx * cell + o - 2, cy * cell + o + 2, s, s, C(th.studShade)); corner(a, 5)
			local b = frame(sg, cx * cell + o, cy * cell + o, s, s, C(th.stud)); corner(b, 5)
		end
	end
	-- косі світлі смуги: над шаром studs, під блиском / іконкою / текстом
	bands(c, CW, CH)
	-- блиск: прямокутна смужка на всю ширину всередині обідка (12 від краю), зверху, біла з вертикальним градієнтом прозорості
	local gloss = frame(c, 12, 12, CW - 24, math.floor(CH * 0.36), WHITE)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.68), NumberSequenceKeypoint.new(1, 1) }) }, gloss)
	local rim = frame(c, 12, 12, CW - 24, CH - 24, nil, { BackgroundTransparency = 1 }); stroke(rim, C(th.rim), 6, 0.25)
	-- нижня суцільна смуга (замість старої напівпрозорої): найтемніший колір теми, затемнений на 30 %; ZIndex 2 — над обідком
	local stripH = math.max(10, math.floor(CH * 0.03))
	frame(c, 0, CH - stripH, CW, stripH, darken(C(th.grad[#th.grad][2]), 0.30), { Name = "BottomStrip", ZIndex = 2 })
	icon(c, kind, CW / 2, kind == "luck" and 262 or 270)
	label(c, 0, 470, CW, 96, 78, title, WHITE, 7)
	local value = label(c, 0, 560, CW, 70, 58, "", WHITE, 6, { RichText = true })
	-- кнопка купівлі — «стиль A» (Shared/StyleA): green — грошей вистачає, gray — не вистачає або MAX; напис — ціна / MAX.
	-- Квадратна тінь під нею лишилася.
	local bx, by, bw, bh = 95, 650, CW - 190, 102
	frame(c, bx, by + 8, bw, bh, Color3.new(0, 0, 0), { BackgroundTransparency = 0.7 })
	local sa = StyleA.new(c, { size = Vector2.new(bw, bh), position = Vector2.new(bx, by), color = "green", text = "", textSize = 60,
		clickable = true, zIndex = 2 })
	CardHover.attach(holder, c, nil, 0.95) -- картки на 5 % менші
	return { card = c, value = value, btn = sa.button, sa = sa }
end

-- ===== збірка екрана =====
-- Екран є на таблі кожної ніші: у своїй ніші кнопки працюють, у чужих видно рівні й ціни їхнього власника,
-- але кнопки неактивні (без наведення, кліків і запитів на сервер). Вільна ніша показує стартові значення.
-- SurfaceGui будується, коли табло ніші вперше опускається, і перебудовується, якщо змінився власник.
local screensByNiche = {} -- [niche] = { gui, screenPart, ownerId, conns }

local function destroyFor(niche)
	local e = screensByNiche[niche]
	if e then
		for _, c in e.conns do c:Disconnect() end
		e.gui:Destroy()
		screensByNiche[niche] = nil
	end
end

local function build(niche: Model, screenPart: BasePart)
	destroyFor(niche)
	local ownerId = niche:GetAttribute("OwnerUserId") or 0
	local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil
	local mine = owner == player
	local function attr(name, default)
		return owner and owner:GetAttribute(name) or default
	end
	local gui = new("SurfaceGui", { Name = "RollUpgradeUI_" .. niche.Name, Adornee = screenPart, Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = W / screenPart.Size.X, LightInfluence = 0, Brightness = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false,
		ClipsDescendants = true, MaxDistance = 400 }, player:WaitForChild("PlayerGui"))
	-- сіра підкладка зі studs на весь екран (як на таблі кузні; темної рамки зі studs більше немає) + тіні по лівому й правому краю
	local root = frame(gui, 0, 0, W, H, C("8e939a"), { ClipsDescendants = true })
	local IX, IY, IW, IH = 64, 64, W - 128, H - 128 -- поле карток (картки стоять там само, де й раніше)
	local x0 = math.floor((W - (2 * CW + GAP)) / 2) - IX
	local y0 = math.floor((H - CH) / 2) - 4 - IY
	local PC = 56
	for cx = 0, math.ceil(W / PC) - 1 do
		for cy = 0, math.ceil(H / PC) - 1 do
			local x, y = cx * PC, cy * PC
			local covered = false -- під непрозорими картками studs не малюємо (картки тут не рухаються)
			for _, kx in { IX + x0, IX + x0 + CW + GAP } do
				if x >= kx + 20 and x + PC <= kx + CW - 20 and y >= IY + y0 + 20 and y + PC <= IY + y0 + CH - 20 then covered = true end
			end
			if not covered then stud(root, x, y, PC, C("979ca3"), C("6c7178"), C("aeb3b9")) end
		end
	end
	local shade = frame(root, 0, 0, W, H, WHITE, { ZIndex = 2 })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.08, 1), NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 0.8) }) }, shade)
	for _, side in { { 0, 0 }, { W - 150, 180 } } do -- тінь по самому краю, на всю висоту, завжди
		local f0 = frame(root, side[1], 0, 150, H, C("282c32"), { ZIndex = 2 })
		new("UIGradient", { Rotation = side[2], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, f0)
	end
	local pb = frame(root, 0, 0, W, H, nil, { BackgroundTransparency = 1, ZIndex = 3 }); stroke(pb, INK, 5)
	local cards = frame(root, IX, IY, IW, IH, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local luck = card(cards, x0, y0, "luck", "Roll Luck")
	local stands = card(cards, x0 + CW + GAP, y0, "stands", "Roll Stands")
	if not mine then
		-- чужа або вільна ніша: кнопки лише для перегляду
		for _, b in { luck, stands } do
			b.btn.Active = false
			b.btn.Selectable = false
			pcall(function() b.btn.Interactable = false end)
		end
	end
	-- ===== дані (власника цієї ніші) =====
	local function refresh()
		local money = attr("Money", 0)
		local lvl = attr("RollLuckLvl", 1)
		local cur, nxt = RollConfig.luckPercent(lvl), RollConfig.luckPercent(lvl + 1)
		luck.value.Text = string.format('<font color="#FFFFFF">%s%%</font>  <font color="#D4FF3E">›  %s%%</font>', NF.full(cur), NF.full(nxt))
		local lp = RollConfig.luckPrice(lvl)
		luck.sa:setText(NF.money(lp))
		luck.sa:setColor(money >= lp and "green" or "gray")
		local count = attr("RollStands", 1)
		local sp = RollConfig.standPrice(count, attr("Stage", 1))
		local color
		if sp then
			stands.value.Text = string.format('<font color="#FFFFFF">%d</font>  <font color="#D4FF3E">›  %d</font>', count, count + 1)
			stands.sa:setText(NF.money(sp))
			color = money >= sp and "green" or "gray"
		else
			stands.value.Text = string.format('<font color="#D4FF3E">MAX (%d)</font>', count)
			stands.sa:setText("MAX")
			color = "gray"
		end
		stands.sa:setColor(color)
	end

	local conns = {}
	if mine then
		-- наведення 1,04 завжди; натискання 0,92 + Back і запит, якщо можна; інакше (грошей нема / MAX) — хитання
		local function hookButton(b, what, canBuy)
			for _, cn in StyleA.bind(b.sa, { hoverAlways = true, canClick = canBuy, onClick = function() UISfx.play("BuySound"); remote:FireServer(what) end }) do
				table.insert(conns, cn)
			end
		end
		hookButton(luck, "Luck", function()
			return (player:GetAttribute("Money") or 0) >= RollConfig.luckPrice(player:GetAttribute("RollLuckLvl") or 1)
		end)
		hookButton(stands, "Stands", function()
			local sp = RollConfig.standPrice(player:GetAttribute("RollStands") or 1, player:GetAttribute("Stage") or 1)
			return sp ~= nil and (player:GetAttribute("Money") or 0) >= sp
		end)
	end
	if owner then
		for _, a in { "Money", "RollLuckLvl", "RollStands", "Stage" } do
			table.insert(conns, owner:GetAttributeChangedSignal(a):Connect(refresh))
		end
	end
	-- екран видно лише разом із таблом
	local function vis() gui.Enabled = screenPart.LocalTransparencyModifier < 1 end
	table.insert(conns, screenPart:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(vis))
	vis()
	refresh()
	screensByNiche[niche] = { gui = gui, screenPart = screenPart, ownerId = ownerId, conns = conns }
end

-- ===== усі ніші =====
local niches = workspace:WaitForChild("Niches")
local watched = {}
local hookedParts = setmetatable({}, { __mode = "k" })

local function screenOf(niche)
	local sc = niche:FindFirstChild("RollUpgradeScreen")
	local board = sc and sc:FindFirstChild("Board")
	return board and board:FindFirstChild("screen", true)
end

-- (пере)будувати, якщо табло опущене і екрана ще немає, або змінився власник / сама деталь
local function check(niche)
	if not niche.Parent then destroyFor(niche) return end
	local part = screenOf(niche)
	local e = screensByNiche[niche]
	if not part then destroyFor(niche) return end
	local ownerId = niche:GetAttribute("OwnerUserId") or 0
	if e and (e.screenPart ~= part or e.ownerId ~= ownerId) then destroyFor(niche); e = nil end
	if not e and part.LocalTransparencyModifier < 1 then build(niche, part) end
end

local function watch(niche)
	if not niche:IsA("Model") or watched[niche] then return end
	watched[niche] = true
	niche:GetAttributeChangedSignal("OwnerUserId"):Connect(function() check(niche) end)
	local function hookPart()
		local part = screenOf(niche)
		if part and not hookedParts[part] then
			hookedParts[part] = true
			part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function() check(niche) end)
		end
		check(niche)
	end
	niche.DescendantAdded:Connect(function(d) if d.Name == "screen" or d.Name == "RollUpgradeScreen" then task.defer(hookPart) end end)
	niche.AncestryChanged:Connect(function(_, p) if not p then destroyFor(niche); watched[niche] = nil end end)
	hookPart()
end
for _, n in niches:GetChildren() do watch(n) end
niches.ChildAdded:Connect(function(n) task.defer(watch, n) end)
-- власник міг зайти пізніше за ніші: оновити, коли гравці приходять / йдуть
Players.PlayerAdded:Connect(function() for n in screensByNiche do screensByNiche[n].ownerId = -1; check(n) end end)
Players.PlayerRemoving:Connect(function() task.defer(function() for n in screensByNiche do screensByNiche[n].ownerId = -1; check(n) end end) end)
