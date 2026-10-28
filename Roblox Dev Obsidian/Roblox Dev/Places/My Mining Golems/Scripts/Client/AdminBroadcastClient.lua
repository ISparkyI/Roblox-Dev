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
local function showBanner(text: string, color: string, sec: number)
	bannerToken += 1
	local my = bannerToken
	if current then current:Destroy(); current = nil end
	local grp, gs, labels = textGroup("Announcement", 1100, 120, 46, 18, PALETTES[color] or PALETTES.yellow, true)
	setText(labels, text)
	current = grp
	grp.Position = UDim2.fromOffset(640, -80)
	gs.Scale = 0.9
	tween(grp, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(640, 190) })
	tween(gs, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	pcall(UISounds.play, "claim", 0.1)
	task.delay(sec, function()
		if bannerToken ~= my or not grp.Parent then return end
		tween(grp, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = UDim2.fromOffset(640, -80) }).Completed:Connect(function()
			if bannerToken == my then grp:Destroy(); current = nil end
		end)
	end)
end

-- ===== тост (видача гравцю) =====
local toasts = {}
local function showToast(text: string, color: string)
	local grp, gs, labels = textGroup("Toast", 760, 54, 34, 16, PALETTES[color] or PALETTES.green, false)
	setText(labels, text)
	table.insert(toasts, 1, grp)
	for i, t in toasts do
		if t.Parent then tween(t, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(640, 540 - (i - 1) * 62) }) end
	end
	grp.Position = UDim2.fromOffset(640, 560)
	gs.Scale = 0.6
	tween(gs, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	pcall(UISounds.play, "claim", 0.1)
	task.delay(2.6, function()
		tween(gs, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0 }).Completed:Connect(function()
			local i = table.find(toasts, grp)
			if i then table.remove(toasts, i) end
			grp:Destroy()
		end)
	end)
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

local remotes = RS:WaitForChild("Remotes", 60)
local ev = remotes and remotes:WaitForChild("AdminBroadcast", 60)
if ev then
	ev.OnClientEvent:Connect(function(kind, data)
		if type(data) ~= "table" then return end
		if kind == "ann" and type(data.text) == "string" then
			showBanner(data.text, tostring(data.color), math.clamp(tonumber(data.sec) or 8, 3, 60))
		elseif kind == "toast" and type(data.text) == "string" then
			showToast(data.text, tostring(data.color))
		end
	end)
end
