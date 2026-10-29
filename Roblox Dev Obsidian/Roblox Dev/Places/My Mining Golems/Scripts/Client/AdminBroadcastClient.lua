--!nonstrict
-- AdminBroadcastClient — що бачать УСІ гравці від адмін-панелі: банер оголошення, тост видачі й написи активних подій.
-- Де: StarterPlayer/StarterPlayerScripts/AdminBroadcastClient (LocalScript). Сервер — ServerScriptService/AdminService.
--   RemoteEvent Remotes/AdminBroadcast: ("ann", { text, color, sec }) — банер угорі по центру (падає, тримається sec с, зникає);
--     ("toast", { text, color }) — тост над хотбаром (2,6 с), звук claim.
--   Написи подій (Admin Abuse) — за атрибутами workspace EventLuck / EventLuckUntil і EventMoney / EventMoneyUntil:
--     «ROLL LUCK x2  9:41» (зелений), «MUTATION LUCK x5  1:00» (фіолетовий) і «MONEY x2  3:12» (жовтий) під верхньою панеллю,
--     зворотний відлік до кінця. Атрибути: EventLuck / EventMutLuck / EventMoney (+ …Until).
--   Усі ці тексти — без «кнопкової» підкладки: текст з переливом, чорні обводка й тінь, а під ним м'яка чорна підкладка
--     (50 % у центрі, плавно зникає вліво й вправо), розмір — від реального розміру тексту.
-- Розміри — в одиницях дизайну (висота екрана 720), UIScale під висоту вікна.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = RS:WaitForChild("Shared")
local UISounds = require(Shared:WaitForChild("UISounds"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AdminBroadcast"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0)
root.Position = UDim2.fromScale(0.5, 0)
root.Size = UDim2.fromOffset(1280, 720)
root.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = root
local function fit()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(v.Y / 720, v.X / 1280), 0.45, 1.6)
end
fit()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end

-- ===== текст без «кнопкової» підкладки (банер, тост, написи подій) =====
-- Текст з переливом кольору, чорні обводка й тінь. Під ним — м'яка тінь-підкладка: чорна, 50 % у центрі,
-- плавно зникає вліво й вправо (по центру від тексту, ширина й висота — від реального розміру тексту).
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local INK = Color3.fromHex("14161a")
local PALETTES = {
	yellow = { "fff1a0", "ffb21f" }, green = { "c8ff7a", "4fd62a" }, red = { "ffc0c0", "ff3b4f" }, blue = { "d4f1ff", "3aa0ff" },
	purple = { "f0d4ff", "b05cff" }, orange = { "ffd9a8", "ff8a1f" }, gray = { "ffffff", "c8ccd1" },
}
local SHADE_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.22, 0.55), NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.78, 0.55), NumberSequenceKeypoint.new(1, 1),
})
local function addShade(grp: Frame, main: TextLabel, padX: number, padY: number)
	local sh = Instance.new("Frame")
	sh.Name = "Shade"
	sh.BackgroundColor3 = Color3.new(0, 0, 0)
	sh.BackgroundTransparency = 0.5 -- 50 % у центрі
	sh.BorderSizePixel = 0
	sh.AnchorPoint = Vector2.new(0.5, 0.5)
	sh.Position = UDim2.new(0.5, 0, 0.5, 2)
	sh.ZIndex = 0
	sh.Parent = grp
	local g = Instance.new("UIGradient")
	g.Transparency = SHADE_FADE
	g.Parent = sh
	local function resize()
		local abs = grp.AbsoluteSize.X
		if abs <= 0 then return end
		local k = grp.Size.X.Offset / abs -- пікселі екрана → одиниці дизайну групи
		local b = main.TextBounds
		sh.Size = UDim2.fromOffset(b.X * k + padX * 2, b.Y * k + padY * 2)
	end
	main:GetPropertyChangedSignal("TextBounds"):Connect(resize)
	grp:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	task.defer(resize)
	return sh
end
-- група: тінь тексту + текст з переливом + підкладка; повертає (група, UIScale, { мітки })
local function textGroup(name: string, w: number, h: number, maxSize: number, minSize: number, pal: { string }, wrap: boolean)
	local grp = Instance.new("Frame")
	grp.Name = name
	grp.BackgroundTransparency = 1
	grp.AnchorPoint = Vector2.new(0.5, 0.5)
	grp.Size = UDim2.fromOffset(w, h)
	grp.Parent = root
	local gs = Instance.new("UIScale")
	gs.Parent = grp
	local labels = {}
	for i = 1, 2 do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Position = i == 1 and UDim2.fromOffset(0, math.max(3, math.floor(maxSize * 0.11))) or UDim2.fromOffset(0, 0)
		t.FontFace = HEAVY
		t.TextWrapped = wrap
		t.TextScaled = true
		t.TextColor3 = i == 1 and INK or Color3.new(1, 1, 1)
		t.ZIndex = i
		t.Parent = grp
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = maxSize
		c.MinTextSize = minSize
		c.Parent = t
		local st = Instance.new("UIStroke")
		st.Color = INK
		st.Thickness = math.max(2, maxSize * 0.09)
		st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent = t
		if i == 2 then
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Color = ColorSequence.new(Color3.fromHex(pal[1]), Color3.fromHex(pal[2]))
			g.Parent = t
		end
		labels[i] = t
	end
	addShade(grp, labels[2], math.floor(maxSize * 3), math.floor(maxSize * 0.45))
	return grp, gs, labels
end
local function setText(labels, text: string)
	for _, l in labels do l.Text = text end
end

-- ===== банер оголошення (і особисте повідомлення адміна) =====
local bannerToken = 0
local current = nil
local currentTag = nil -- мітка банера (напр. "mkt" — відлік телепорту): той самий tag оновлює текст без нового падіння
local currentLabels, currentGs = nil, nil
local function hideBanner()
	bannerToken += 1
	local my = bannerToken
	local grp = current
	if not grp then return end
	tween(grp, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = UDim2.fromOffset(640, -80) }).Completed:Connect(function()
		if bannerToken == my then grp:Destroy(); if current == grp then current = nil; currentTag = nil end end
	end)
end
local function showBanner(text: string, color: string, sec: number, tag: string?, sound: string?)
	bannerToken += 1
	local my = bannerToken
	-- той самий tag і банер ще на екрані — лише новий текст і легкий «поп»
	if tag and current and current.Parent and currentTag == tag and currentLabels then
		setText(currentLabels, text)
		currentGs.Scale = 1.12
		tween(currentGs, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
		if sound ~= "" then pcall(UISounds.play, sound or "tap", 0.05) end
		local grp = current
		task.delay(sec, function()
			if bannerToken ~= my or not grp.Parent then return end
			hideBanner()
		end)
		return
	end
	if current then current:Destroy(); current = nil end
	currentTag = tag
	local grp, gs, labels = textGroup("Announcement", 1100, 120, 46, 18, PALETTES[color] or PALETTES.yellow, true)
	setText(labels, text)
	current = grp
	currentLabels, currentGs = labels, gs
	grp.Position = UDim2.fromOffset(640, -80)
	gs.Scale = 0.9
	tween(grp, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(640, 190) })
	tween(gs, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	if sound ~= "" then pcall(UISounds.play, sound or "claim", 0.1) end
	task.delay(sec, function()
		if bannerToken ~= my or not grp.Parent then return end
		tween(grp, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = UDim2.fromOffset(640, -80) }).Completed:Connect(function()
			if bannerToken == my then grp:Destroy(); current = nil end
		end)
	end)
end

-- ===== тост (видача гравцю) =====
local toasts = {}
-- на рівні тостів одночасно лише ОДИН напис (29.10.2026): новий тост прибирає старі й відлік, відлік — тости
local cd = nil -- { tGrp, tGs, tLabels, nGrp, nGs, nLabels } (відлік, нижче)
local function clearToasts()
	for _, t in toasts do t:Destroy() end
	table.clear(toasts)
end
local function killCountdown()
	local c = cd
	if not c then return end
	cd = nil
	c.grp:Destroy()
end
local function showToast(text: string, color: string, sound: string?)
	clearToasts()
	killCountdown()
	local grp, gs, labels = textGroup("Toast", 760, 54, 34, 16, PALETTES[color] or PALETTES.green, false)
	setText(labels, text)
	table.insert(toasts, 1, grp)
	for i, t in toasts do
		if t.Parent then tween(t, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(640, 540 - (i - 1) * 62) }) end
	end
	grp.Position = UDim2.fromOffset(640, 560)
	gs.Scale = 0.6
	tween(gs, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	pcall(UISounds.play, sound or "claim", 0.1)
	task.delay(2.6, function()
		if not grp.Parent then return end
		tween(gs, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0 }).Completed:Connect(function()
			local i = table.find(toasts, grp)
			if i then table.remove(toasts, i) end
			grp:Destroy()
		end)
	end)
end

-- ===== відлік (напр. телепорт у Marketplace): два рядки на рівні тостів — напис і велика цифра під ним =====
-- UIEvents/Countdown:Fire(title, text, color?, sound?) — показати / оновити (цифра «попає»); UIEvents/CountdownHide:Fire() — сховати
local function hideCountdown()
	local c = cd
	if not c then return end
	cd = nil
	tween(c.gs, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0 })
	task.delay(0.16, function() c.grp:Destroy() end)
end
-- (29.10.2026) ОДИН рядок на рівні тостів: спершу напис (title, text = ""), потім цифри 3 → 2 → 1 замінюють його.
-- text ~= "" — велика цифра; text == "" — напис title.
local function showCountdown(title: string, text: string, color: string, sound: string?)
	local pal = PALETTES[color] or PALETTES.yellow
	clearToasts()
	local kind = text ~= "" and "num" or "title"
	local line = text ~= "" and text or title
	if cd and cd.kind ~= kind then killCountdown() end
	if not cd then
		local grp, gs, labels
		if kind == "num" then grp, gs, labels = textGroup("CountdownNum", 300, 110, 96, 30, pal, false)
		else grp, gs, labels = textGroup("CountdownTitle", 900, 54, 36, 14, pal, false) end
		grp.Position = UDim2.fromOffset(640, 540)
		cd = { kind = kind, grp = grp, gs = gs, labels = labels, tGrp = grp, nGrp = grp }
	end
	setText(cd.labels, line)
	cd.gs.Scale = kind == "num" and 1.35 or 0.6
	tween(cd.gs, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	if sound ~= "" then pcall(UISounds.play, sound or "tap", 0.05) end
end

-- ===== написи подій =====
local pills = {}
local EVENTS = {
	{ key = "EventLuck", label = "ROLL LUCK", pal = PALETTES.green }, { key = "EventMutLuck", label = "MUTATION LUCK", pal = PALETTES.purple },
	{ key = "EventMoney", label = "MONEY", pal = PALETTES.yellow },
}
local function fmt(sec: number): string
	sec = math.max(0, math.floor(sec))
	if sec >= 3600 then return string.format("%d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60) end
	return string.format("%d:%02d", sec // 60, sec % 60)
end
local function makePill(e)
	local grp, gs, labels = textGroup("Event_" .. e.key, 390, 44, 30, 14, e.pal, false)
	return { grp = grp, gs = gs, labels = labels }
end
local function refreshPills()
	local now = workspace:GetServerTimeNow()
	local active = {}
	for _, e in EVENTS do
		local m = tonumber(workspace:GetAttribute(e.key)) or 1
		local u = tonumber(workspace:GetAttribute(e.key .. "Until")) or 0
		if m > 1 and u > now then
			local ms = m >= 1e6 and NumberFormat.short(m) or tostring(m)
			table.insert(active, { e = e, text = e.label .. " x" .. ms .. "  " .. fmt(u - now) })
		end
	end
	for key, p in pills do
		local still = false
		for _, a in active do if a.e.key == key then still = true end end
		if not still then p.grp:Destroy(); pills[key] = nil end
	end
	local total = #active
	for i, a in active do
		local p = pills[a.e.key]
		if not p then
			p = makePill(a.e)
			p.gs.Scale = 0
			tween(p.gs, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
			pills[a.e.key] = p
		end
		setText(p.labels, a.text)
		p.grp.Position = UDim2.fromOffset(640 + (i - (total + 1) / 2) * 400, 84)
	end
end

task.spawn(function()
	while true do
		refreshPills()
		task.wait(1)
	end
end)

-- локальний тост з інших клієнтських скриптів (той самий стиль): ReplicatedStorage/UIEvents/Toast:Fire(text, color?, sound?)
--   напр. табло NEXT MAP (MapBoard): «Come closer to the board!»
do
	local ui = RS:WaitForChild("UIEvents", 30)
	if ui then
		local b = ui:FindFirstChild("Toast") or Instance.new("BindableEvent")
		b.Name = "Toast"; b.Parent = ui
		b.Event:Connect(function(text, color, sound)
			if type(text) == "string" then showToast(text, tostring(color or "green"), type(sound) == "string" and sound or nil) end
		end)
		-- банер у стилі адмін-оголошення з інших клієнтських скриптів: UIEvents/Banner:Fire(text, color?, sec?, tag?, sound?)
		--   (tag — оновити той самий банер без нового падіння, sound "" — без звуку); UIEvents/BannerHide:Fire(tag) — сховати банер з цим tag
		--   (напр. відлік телепорту в Marketplace — MarketplaceClient)
		local bn = ui:FindFirstChild("Banner") or Instance.new("BindableEvent")
		bn.Name = "Banner"; bn.Parent = ui
		bn.Event:Connect(function(text, color, sec, tag, sound)
			if type(text) == "string" then
				showBanner(text, tostring(color or "yellow"), math.clamp(tonumber(sec) or 4, 0.5, 60), type(tag) == "string" and tag or nil, type(sound) == "string" and sound or nil)
			end
		end)
		local cdE = ui:FindFirstChild("Countdown") or Instance.new("BindableEvent")
		cdE.Name = "Countdown"; cdE.Parent = ui
		cdE.Event:Connect(function(title, text, color, sound)
			if type(title) == "string" then showCountdown(title, tostring(text or ""), tostring(color or "yellow"), type(sound) == "string" and sound or nil) end
		end)
		local cdH = ui:FindFirstChild("CountdownHide") or Instance.new("BindableEvent")
		cdH.Name = "CountdownHide"; cdH.Parent = ui
		cdH.Event:Connect(hideCountdown)
		local bh = ui:FindFirstChild("BannerHide") or Instance.new("BindableEvent")
		bh.Name = "BannerHide"; bh.Parent = ui
		bh.Event:Connect(function(tag)
			if current and (tag == nil or tag == currentTag) then hideBanner() end
		end)
	end
end

local remotes = RS:WaitForChild("Remotes", 60)
local ev = remotes and remotes:WaitForChild("AdminBroadcast", 60)
if ev then
	ev.OnClientEvent:Connect(function(kind, data)
		if kind == "debug" and type(data) == "table" then
			print(tostring(data.text))
			-- журнал налагодження (останні рядки) — StringValue PlayerGui/DebugLog
			local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
			if pg then
				local v = pg:FindFirstChild("DebugLog") or Instance.new("StringValue")
				v.Name = "DebugLog"; v.Parent = pg
				v.Value = string.sub(v.Value .. os.date("%H:%M:%S ") .. tostring(data.text) .. "\n", -6000)
			end
			return
		end -- налагодження сервера в Studio (GiftService)
		if type(data) ~= "table" then return end
		if kind == "ann" and type(data.text) == "string" then
			showBanner(data.text, tostring(data.color), math.clamp(tonumber(data.sec) or 8, 3, 60))
		elseif kind == "toast" and type(data.text) == "string" then
			showToast(data.text, tostring(data.color))
		end
	end)
end
