
local function tableFind(t, v) for i, x in t do if x == v then return i end end return nil end

-- сяйво: прозорість i-го з GLOW_N вкладених кіл, щоб непрозорість на відстані d була A · (1 − d / R)^P
local function glowTable(A, P)
	local function op(f) return A * math.max(0, 1 - f) ^ P end
	local t = {}
	for i = 1, GLOW_N do
		local a = 1 - (1 - op((i - 1) / GLOW_N)) / math.max(1e-6, 1 - op(i / GLOW_N))
		t[i] = 1 - math.clamp(a, 0, 1)
	end
	return t
end
local GLOW_ITEM = glowTable(0.85, 0.9)
local GLOW_EMPTY = glowTable(0.16, 1.4)

local function slotHoverSound()
	local s = SoundService:FindFirstChild("SlotHover")
	if s and s:IsA("Sound") and s.SoundId ~= "" then s.TimePosition = 0; s:Play() end
end

-- лаймова / червона / жовта галочка в колі (як у Forge): контейнер-коло 28
local function makeCheck(parent, x, y, color)
	local ring = frame(parent, x, y, 28, 28, color, { ZIndex = 20, Visible = false }); corner(ring, UDim.new(0.5, 0))
	stroke(ring, INK, 3)
	for layer = 1, 2 do
		for _, a in { { -3.5, 2, 9.5, 45 }, { 2.5, 0, 15, -48 } } do
			local s = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(14 + a[1], 14 + a[2]), Size = UDim2.fromOffset(a[3], 3.6),
				Rotation = a[4], BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 21 + layer }, ring)
			corner(s, 2)
		end
	end
	return ring
end

-- ===== наведення слотів (×1,025, нахил до 1,5°, натискання 0,96) =====
local hoverSet = {}
local hoverConn = nil
local function hoverStep(dt: number)
	local a = 1 - math.exp(-14 * dt)
	for s in hoverSet do
		local ts = s.down and 0.96 or (s.hover and 1.025 or 1)
		local tr = (s.hover and not s.down) and s.rel * 1.5 or 0
		local ty = s.lift and -8 or 0
		s.sc += (ts - s.sc) * a
		s.rot += (tr - s.rot) * a
		s.ly += (ty - s.ly) * a
		if not s.hover and not s.down and math.abs(s.sc - 1) < 0.0005 and math.abs(s.rot) < 0.02 and math.abs(s.ly - ty) < 0.05 then
			s.sc, s.rot, s.ly = 1, 0, ty
			hoverSet[s] = nil
		end
		s.scale.Scale = s.sc
		s.card.Rotation = s.rot
		s.holder.Position = UDim2.fromOffset(s.cx, s.cy + s.ly)
	end
	if next(hoverSet) == nil and hoverConn then hoverConn:Disconnect(); hoverConn = nil end
end
local function wakeHover(s)
	hoverSet[s] = true
	if not hoverConn then hoverConn = RunService.RenderStepped:Connect(hoverStep) end
end

-- ===== слот «C · Сяйво» =====
-- makeSlot(parent, x, y, S, mini) → s; s:set(item або nil, opt) — оновлює вміст. opt: ring (Color3), check (Color3), dim, keyNum, hotIndex.
-- s.onClick(s) — клік (не після перетягування). Вміст картки нахиляється (card), кнопка й значки — ні.
local slotIsDragging -- функція: чи щойно було перетягування сітки (нижче)
local function makeSlot(parent, x, y, S, mini)
	local P = 16
	local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(S + 2 * P, S + 2 * P),
		Position = UDim2.fromOffset(x + S / 2, y + S / 2), ZIndex = 1 }, parent)
	local scale = new("UIScale", {}, holder)
	local card = frame(holder, 0, 0, S + 2 * P, S + 2 * P, nil, { Name = "Card", BackgroundTransparency = 1, ZIndex = 1 })
	frame(card, P, P + math.floor(S * 0.04 + 0.5), S, S, BLACK, { BackgroundTransparency = 0.7, ZIndex = 1 })
	local bg = frame(card, P, P, S, S, WHITE, { ZIndex = 2 })
	vgrad(bg, { { 0, "22262c" }, { 1, "15181c" } }); stroke(bg, INK, S > 90 and 4 or 3)
	local tone = frame(card, P + 3, P + 3, S - 6, S - 6, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local toneStroke = stroke(tone, WHITE, S > 90 and 3 or 2, 0.94)
	local pad = S * (mini and 0.14 or 0.16)
	local iw = S - 2 * pad
	local gcx, gcy = P + pad + iw / 2, P + pad * (mini and 0.8 or 0.75) + iw / 2
	local R = S * 0.5
	local glow = frame(card, 0, 0, S + 2 * P, S + 2 * P, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local circles = {}
	for i = GLOW_N, 1, -1 do
		local rr = R * i / GLOW_N
		local g = frame(glow, gcx - rr, gcy - rr, rr * 2, rr * 2, WHITE, { BackgroundTransparency = 1, ZIndex = 1 })
		corner(g, UDim.new(0.5, 0))
		circles[i] = g
	end
	local icon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(P + pad, P + pad * (mini and 0.8 or 0.75)),
		Size = UDim2.fromOffset(iw, iw), ZIndex = 4, Visible = false }, card)
	local name = textAt(card, P + 7, P + 16, S - 10, 14, "", WHITE, 2.2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local cnt = textAt(card, P, P + S - (mini and 14 or 17), S - 8, mini and 19 or 22, "", WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5, Visible = false })
	local rar = textAt(card, P, P + S - 14, S - 8, 13, "", WHITE, 2, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 5, Visible = false })
	local keyNum = mini and textAt(card, P + 6, P + 13, 30, 15, "", C("c9ced4"), 2.2, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }) or nil
	local ring = frame(card, P - 1, P - 1, S + 2, S + 2, nil, { BackgroundTransparency = 1, ZIndex = 7, Visible = false })
	local ringStroke = stroke(ring, C("c8ff6a"), 4)
	local lockImg = new("ImageLabel", { BackgroundTransparency = 1, Image = Items.ICONS.lock, ScaleType = Enum.ScaleType.Fit, ZIndex = 8, Visible = false,
		Position = UDim2.fromOffset(P + (mini and -5 or -8), P + S - (mini and 24 or 32)), Size = UDim2.fromOffset(mini and 26 or 36, mini and 26 or 36) }, holder)
	local check = makeCheck(holder, P + S - 18, P - 10, C("ff4f5e"))
	local hot = nil -- значок «у хотбарі N»
	local hit = new("TextButton", { Name = "Hit", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(P, P),
		Size = UDim2.fromOffset(S, S), ZIndex = 30 }, holder)
	hit:SetAttribute("NoHoverSound", true)
	local s = { holder = holder, card = card, scale = scale, sc = 1, rot = 0, ly = 0, rel = 0, hover = false, down = false, lift = false,
		cx = x + S / 2, cy = y + S / 2, item = nil, onClick = nil, S = S }
	function s.place(nx: number, ny: number) s.cx, s.cy = nx + S / 2, ny + S / 2; holder.Position = UDim2.fromOffset(s.cx, s.cy + s.ly) end
	function s.set(it, opt)
		opt = opt or {}
		s.item = it
		local has = it ~= nil
		local tc = has and it.tone or WHITE
		local tbl = has and GLOW_ITEM or GLOW_EMPTY
		for i = 1, GLOW_N do circles[i].BackgroundColor3 = tc; circles[i].BackgroundTransparency = tbl[i] end
		toneStroke.Color = tc; toneStroke.Transparency = has and 0.67 or 0.94
		icon.Visible = has
		if has then icon.Image = it.icon end
		name.Visible = has and not mini
		if has and not mini then name.Text = it.name; name.TextSize = (#it.name > 12) and 12 or 14 end
		cnt.Visible = has and not it.golem
		if has and not it.golem then cnt.Text = "×" .. NF.short(it.n) end
		rar.Visible = has and it.golem == true and not mini
		if has and it.golem then rar.Text = it.rar; rar.TextColor3 = it.tone end
		if keyNum then keyNum.Text = opt.keyNum or "" end
		ring.Visible = opt.ring ~= nil
		if opt.ring then ringStroke.Color = opt.ring end
		check.Visible = opt.check ~= nil
		if opt.check then check.BackgroundColor3 = opt.check end
		lockImg.Visible = has and opt.locked == true
		card.Visible = true
		holder.ZIndex = opt.top and 5 or 1
		-- притемнення (заблоковане в режимі видалення)
		local dim = opt.dim and 0.55 or 0
		icon.ImageTransparency = dim; bg.BackgroundTransparency = dim * 0.6
		if opt.hotIndex and not hot then
			hot = StyleA.new(holder, { size = Vector2.new(34, 30), position = Vector2.new(P + S - 30, P - 10), anchor = Vector2.zero, color = "blue",
				half = true, rows = 3, text = "", textSize = 17, zIndex = 9 })
		end
		if hot then hot.root.Visible = opt.hotIndex ~= nil; if opt.hotIndex then hot:setText(tostring(opt.hotIndex)) end end
		if s.lift ~= (opt.lift == true) then s.lift = opt.lift == true; wakeHover(s) end
	end
	local function aim(px: number)
		local c = holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2
		s.rel = math.clamp((px - c) / math.max(1, hit.AbsoluteSize.X / 2), -1, 1)
	end
	hit.MouseEnter:Connect(function(px)
		if s.blocked and s.blocked() then return end
		if not s.hover and s.item then slotHoverSound() end
		s.hover = true; aim(px); wakeHover(s)
	end)
	hit.MouseMoved:Connect(function(px) if s.blocked and s.blocked() then return end s.hover = true; aim(px); wakeHover(s) end)
	hit.MouseLeave:Connect(function() s.hover = false; s.down = false; wakeHover(s) end)
	hit.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			s.down = true; wakeHover(s)
			if s.onPress then s.onPress(inp) end
		end
	end)
	hit.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then s.down = false; wakeHover(s) end
	end)
	hit.Activated:Connect(function()
		if slotIsDragging and slotIsDragging() then return end
		if s.onClick then s.onClick(s) end
	end)
	s.hit = hit
	function s.shake()
		local p0 = holder.Position
		task.spawn(function()
			for _, dx in { -8, 8, -5, 5, -2, 0 } do holder.Position = p0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
			holder.Position = UDim2.fromOffset(s.cx, s.cy + s.ly)
		end)
	end
	function s.toast(text: string, color: Color3?)
		local t = textAt(holder, 0, P + S / 2, S + 2 * P, 20, text, color or C("ffd34d"), 2.6, { ZIndex = 40 })
		task.delay(0.7, function() t:Destroy() end)
	end
	function s.pop()
		scale.Scale = 0.6
		tween(scale, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.15 }).Completed:Connect(function()
			tween(scale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 })
		end)
	end
	s.set(nil)
	return s
end

-- =====================================================================
-- ===== дані =====
-- =====================================================================
local function decodeAttr(attr: string, default: any): any
	local v = player:GetAttribute(attr)
	if type(v) ~= "string" or v == "" then return default end
	local ok, t = pcall(HttpService.JSONDecode, HttpService, v)
	return ok and type(t) == "table" and t or default
end
local function num(key: string): number return math.max(0, math.floor(tonumber(player:GetAttribute(key)) or 0)) end

local items, byKey = {}, {}
local lockSet = {}
local hotbar = {} -- 9 ключів ("" — порожньо)
local heldKey = ""
local function rebuild()
	items, byKey = {}, {}
	local function add(it) table.insert(items, it); byKey[it.key] = it end
	for _, o in Forge.ORES do
		add({ key = "Ore_" .. o.key, tab = "ores", name = o.key, sub = "Ore · " .. NF.money(o.price) .. " each", n = num("Ore_" .. o.key),
			icon = ICON_ORE[o.key] or "", tone = Items.ORE_TONE[o.key] or WHITE })
	end
	for _, o in Forge.ORES do
		add({ key = "Bars_" .. o.key, tab = "ores", name = o.key .. " Bar", sub = "Bar · " .. NF.money(o.price * Forge.BAR_MULT) .. " each",
			n = num("Bars_" .. o.key), icon = ICON_BAR[o.key] or "", tone = Items.ORE_TONE[o.key] or WHITE })
	end
	for _, d in Items.POTIONS do
		add({ key = "Pot_" .. d.key, tab = "potions", name = d.name, sub = d.desc, n = num("Pot_" .. d.key), icon = d.icon, tone = d.tone })
	end
	for _, g in decodeAttr("InvGolems", {}) do
		local def = Items.GOLEMS[g.kind]
		if def and type(g.id) == "number" then
			add({ key = "Golem_" .. g.id, tab = "golems", name = def.name, sub = def.rarity .. " · mines " .. def.rate .. " ore/s", n = 1, golem = true,
				rar = def.rarity, icon = def.icon, tone = Items.RARITY[def.rarity] or WHITE })
		end
	end
	lockSet = {}
	for _, k in decodeAttr("InvLocks", {}) do lockSet[k] = true end
	local h = decodeAttr("InvHotbar", {})
	for i = 1, Items.HOTBAR do hotbar[i] = type(h[i]) == "string" and h[i] or "" end
	local hk = player:GetAttribute("InvHeld")
	heldKey = type(hk) == "string" and hk or ""
end
local function live(key: string): any
	local it = byKey[key]
	return (it and it.n > 0) and it or nil
end

-- =====================================================================
-- ===== хотбар =====
-- =====================================================================
local hbGui = new("ScreenGui", { Name = "Hotbar", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5 }, playerGui)
local hbRoot = new("Frame", { Name = "Root", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(HB_W, HS + 64) }, hbGui)
local hbScale = new("UIScale", {}, hbRoot)
local heldPill = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(320, 42), Position = UDim2.fromOffset(HB_W / 2 - 160, 2), ZIndex = 20 }, hbRoot)
local heldBg = StyleA.new(heldPill, { size = Vector2.new(320, 42), position = Vector2.zero, anchor = Vector2.zero, color = "green", half = true, rows = 3, text = "", textSize = 20, zIndex = 1 })
heldPill.Visible = false
local hot = {}
local toggleHeld -- нижче
for i = 1, Items.HOTBAR do
	local s = makeSlot(hbRoot, (i - 1) * (HS + HG), 58, HS, true)
	s.onClick = function() toggleHeld(i) end
	hot[i] = s
end

local hbOpenOrder = 5
local function fitHotbar()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or hbGui.AbsoluteSize
	if vs.X < 2 or vs.Y < 2 then return end
	local s = vs.Y / 720
	-- між Money HUD (зліва) і Boss (справа): ≈ 370 одиниць HUD з кожного боку
	s = math.min(s, (vs.X - 2 * 370 * (vs.Y / 720)) / HB_W, (vs.X - 24) / HB_W)
	hbScale.Scale = math.max(0.35, s)
	hbRoot.Position = UDim2.new(0.5, 0, 1, -math.floor(10 * vs.Y / 720))
end

local function refreshHotbar()
	for i = 1, Items.HOTBAR do
		local it = live(hotbar[i])
		hot[i].set(it, { keyNum = tostring(i), ring = (it and heldKey == hotbar[i]) and C("c8ff6a") or nil, lift = it ~= nil and heldKey == hotbar[i],
			top = it ~= nil and heldKey == hotbar[i], locked = it ~= nil and lockSet[hotbar[i]] == true })
		hot[i].holder.ZIndex = (it and heldKey == hotbar[i]) and 5 or 1 -- вибраний слот над сусідами (рамку не перекриває наступний)
	end
	local it = heldKey ~= "" and live(heldKey) or nil
	if it then
		heldBg:setText(it.name .. (it.golem and "" or (" ×" .. NF.short(it.n))) .. " · in hand")
		if not heldPill.Visible then heldPill.Visible = true end
	else
		heldPill.Visible = false
	end
end

local function sendHold(key: string)
	heldKey = key
	Action:FireServer("Hold", key)
end
toggleHeld = function(i: number)
	local key = hotbar[i]
	if key == "" or not live(key) then hot[i].shake(); return end
	sendHold(heldKey == key and "" or key)
	refreshHotbar()
end
