
-- =====================================================================
-- ===== вікно INVENTORY =====
-- =====================================================================
local gui = new("ScreenGui", { Name = "InventoryWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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

-- заголовок INVENTORY (синій перелив + відблиск) і X
textAt(pop, WX + 32, WY - 8 + 7, 640, 96, "INVENTORY", INK, 9, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = textAt(pop, WX + 32, WY - 8, 640, 96, "INVENTORY", WHITE, 8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local titleShine = textAt(pop, WX + 32, WY - 8, 640, 96, "INVENTORY", WHITE, 0, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
local titleShineGrad = new("UIGradient", { Rotation = 25, Offset = Vector2.new(-1.3, 0),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) }) }, titleShine)
do
	local P = { C("e6f6ff"), C("7fd0ff"), C("1c7fd8"), C("7fd0ff") }
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
local closeBtn = makeButton(pop, WX + WW - 70, WY - 34, 84, 84, { shadowDy = 8, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 6 })

-- ===== стан вікна =====
local tab = "ores"
local mode = nil -- nil | "delete" | "lock"
local picked = {} -- ключ → true
local selKey = nil
local isOpen = false
local MODE_COL = { delete = C("ff4f5e"), lock = C("ffd23a") }
local refreshAll -- нижче
local function pickedCount() local n = 0 for _ in picked do n += 1 end return n end
local function tabItems(k: string)
	local t = {}
	for _, it in items do if it.tab == k and it.n > 0 then table.insert(t, it) end end
	return t
end

-- ===== вкладки =====
local TABS = { { "golems", "Golems", Items.ICONS.tab_golems }, { "ores", "Ores / Bars", Items.ICONS.tab_orebars }, { "potions", "Potions", Items.ICONS.tab_potions } }
local tabBtns = {}
local setTab, setMode -- нижче
local function tabY(i: number) return 66 + (i - 1) * (TH + 14) end
for i, spec in TABS do
	local k = spec[1]
	local hold = frame(content, TX, tabY(i), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4 })
	local b = makeButton(hold, 0, 0, TW, TH, { shadowDy = 7, color = "gray", z = 1, shine = false })
	b.onClick = function() setTab(k) end
	new("ImageLabel", { BackgroundTransparency = 1, Image = spec[3], ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(8, 2), Size = UDim2.fromOffset(74, 74), ZIndex = 4 }, hold)
	textAt(hold, 86, 32, 132, #spec[2] > 8 and 21 or 25, spec[2], WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local c = textAt(hold, 86, 58, 132, 15, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 5 })
	tabBtns[k] = { hold = hold, b = b, c = c, i = i }
end

-- ===== заголовок вмісту, сітка зі смугою прокрутки =====
local hdr = textAt(content, 290, 86, 400, 32, "", WHITE, 3.2, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local cap = textAt(content, 640, 86, 296, 18, "", SUB_TXT, 2, { TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD, ZIndex = 3 })
local gvp = frame(content, GX, GY, GW, GH, nil, { Name = "Grid", BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 2 })
local gstrip = frame(gvp, 0, 0, GW, 10, nil, { BackgroundTransparency = 1, ZIndex = 1 })
local vsb = frame(content, GX + GW + 3, GY + GP, 10, GH - 2 * GP, WHITE, { Active = true, ZIndex = 3 })
new("UIGradient", { Color = cseq(TRACK), Rotation = 0 }, vsb); stroke(vsb, INK, 3)
local vth = frame(vsb, 0, 0, 10, 60, WHITE, { Active = true, ZIndex = 2 }); vgrad(vth, LIME)
local gscroll, gH = 0, 0
local function gmax() return math.max(0, gH - GH) end
local function setG(v: number)
	gscroll = math.clamp(v, 0, gmax())
	gstrip.Position = UDim2.fromOffset(0, -gscroll)
	local th = math.max(40, (GH - 2 * GP) * GH / math.max(GH, gH))
	vth.Size = UDim2.fromOffset(10, th)
	vth.Position = UDim2.fromOffset(0, gmax() > 0 and gscroll / gmax() * (GH - 2 * GP - th) or 0)
	vsb.Visible = gmax() > 0
end
local drag, dragEndAt = nil, -1
local function unitsPerPx() local a = gvp.AbsoluteSize.Y return a > 0 and GH / a or 1 end
local function isPress(inp) return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch end
local function beginDrag(inp, thumb) if isPress(inp) then drag = { y = inp.Position.Y, s = gscroll, moved = false, thumb = thumb } end end
local function wheel(inp) if inp.UserInputType == Enum.UserInputType.MouseWheel and gmax() > 0 then setG(gscroll - inp.Position.Z * 70) end end
slotIsDragging = function() return (drag ~= nil and drag.moved) or os.clock() - dragEndAt < 0.15 end
gvp.InputBegan:Connect(function(inp) beginDrag(inp, false) end)
gvp.InputChanged:Connect(wheel)
vth.InputBegan:Connect(function(inp) beginDrag(inp, true) end)
UIS.InputChanged:Connect(function(inp)
	if not drag or not (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) or gmax() <= 0 then return end
	local dy = (inp.Position.Y - drag.y) * unitsPerPx()
	if drag.thumb then setG(drag.s + dy * gmax() / math.max(1, GH - 2 * GP - vth.Size.Y.Offset))
	else
		if math.abs(dy) > 6 then drag.moved = true end
		if drag.moved then setG(drag.s - dy) end
	end
end)
UIS.InputEnded:Connect(function(inp)
	if isPress(inp) and drag then if drag.moved then dragEndAt = os.clock() end drag = nil end
end)

-- пул слотів сітки (росте за потреби)
local gslots = {}
local slotClick -- нижче
local function gridSlot(i: number)
	local s = gslots[i]
	if not s then
		s = makeSlot(gstrip, 0, 0, GS, false)
		s.onPress = function(inp) beginDrag(inp, false) end
		s.hit.InputChanged:Connect(wheel)
		s.onClick = function() if s.item then slotClick(s) end end
		s.blocked = function() return not isOpen end
		gslots[i] = s
	end
	return s
end

-- ===== картка вибраного предмета =====
local info = frame(content, 290, 392, 646, 100, WHITE, { ZIndex = 3 })
new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "353b43" }, { 1, "1b1e23" } }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.4) }) }, info)
stroke(info, INK, 3)
local infoIcon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(14, 7), Size = UDim2.fromOffset(86, 86), ZIndex = 2 }, info)
local infoName = textAt(info, 112, 32, 270, 28, "", WHITE, 3, { TextXAlignment = Enum.TextXAlignment.Left, RichText = true, ZIndex = 2 })
local infoSub = textAt(info, 112, 64, 270, 16, "", SUB_TXT, 1.8, { TextXAlignment = Enum.TextXAlignment.Left, FontFace = XBOLD, ZIndex = 2 })
local infoHint = textAt(info, 0, 50, 646, 20, "Tap an item to see it here", C("c9ced4"), 2, { RichText = true, FontFace = XBOLD, ZIndex = 2 })
local bHold = makeButton(info, 384, 12, 132, 72, { shadowDy = 6, color = "green", text = "Hold", textSize = 23, z = 3 })
local bPin = makeButton(info, 526, 12, 108, 72, { shadowDy = 6, color = "blue", text = "Hotbar", textSize = 22, z = 3 })
local function showInfoItem(on: boolean)
	infoIcon.Visible = on; infoName.Visible = on; infoSub.Visible = on; infoHint.Visible = not on
	for _, b in { bHold, bPin } do b.root.Visible = on; b.shadow.Visible = on end
end

-- ===== інструменти: видалення / блокування / Cancel; кнопки режиму на місці прихованих вкладок =====
local toolTrash = makeButton(content, TX, 404, 76, 72, { shadowDy = 6, color = "red", icon = Items.ICONS.trash, iconPad = 0.02, z = 4 })
local toolLock = makeButton(content, TX + 92, 404, 76, 72, { shadowDy = 6, color = "yellow", icon = Items.ICONS.lock, iconPad = 0.02, z = 4 })
local toolCancel = makeButton(content, TX, 404, TW, 72, { shadowDy = 6, color = "gray", text = "Cancel", textSize = 28, z = 4 })
local function showBtn(b, on) b.root.Visible = on; b.shadow.Visible = on end
showBtn(toolCancel, false)
local mAh = frame(content, TX, tabY(2), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
local mBh = frame(content, TX, tabY(3), TW, TH + 8, nil, { BackgroundTransparency = 1, ZIndex = 4, Visible = false })
local mA = makeButton(mAh, 0, 0, TW, TH, { shadowDy = 7, color = "blue", text = "Select All", textSize = 28, z = 1 })
local mB = makeButton(mBh, 0, 0, TW, TH, { shadowDy = 7, color = "red", z = 1 })
local mBicon = new("ImageLabel", { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(64, 64), ZIndex = 4 }, mBh)
local mBtext = textAt(mBh, 82, 40, 136, 26, "", WHITE, 2.8, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })

-- ===== вікно підтвердження видалення =====
local cfDim = frame(content, 0, 0, WW, WH, C("0d0f12"), { BackgroundTransparency = 0.45, Active = true, Visible = false, ZIndex = 40 })
local CFW, CFH = 560, 330
local cfRoot = frame(content, (WW - CFW) / 2, (WH - CFH) / 2 + 10, CFW, CFH, nil, { BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 41 })
local cfScale = new("UIScale", {}, cfRoot)
local _, cfC = windowFrame(cfRoot, 0, 0, CFW, CFH, 1, 10)
local cfTitle = textAt(cfC, 0, 62, CFW, 34, "", WHITE, 3.5, { ZIndex = 3 })
local cfRow = frame(cfC, 0, 96, CFW, 76, nil, { BackgroundTransparency = 1, ZIndex = 3 })
textAt(cfC, 0, 196, CFW, 18, "This can't be undone.", INK, 0, { FontFace = XBOLD, ZIndex = 3 })
local cfCancel = makeButton(cfC, 44, 226, 200, 72, { shadowDy = 6, color = "gray", text = "Cancel", textSize = 28, z = 3 })
local cfDelete = makeButton(cfC, 260, 226, CFW - 304, 72, { shadowDy = 6, color = "red", text = "Delete", textSize = 30, z = 3 })
local cfSlots = {}
local function closeConfirm() cfDim.Visible = false; cfRoot.Visible = false end
cfDim.InputBegan:Connect(function(inp) if isPress(inp) then closeConfirm() end end)
cfCancel.onClick = function() closeConfirm() end

-- =====================================================================
-- ===== логіка вікна =====
-- =====================================================================
local function selectable()
	local t = {}
	for _, it in tabItems(tab) do if not (mode == "delete" and lockSet[it.key]) then table.insert(t, it) end end
	return t
end

local function renderGrid()
	local list = tabItems(tab)
	local total = math.max(#list + (tab == "golems" and 2 or 4), GCOLS * 2)
	local rows = math.ceil(total / GCOLS)
	local count = rows * GCOLS
	gH = rows * (GS + GG) - GG + 2 * GP + 8
	gstrip.Size = UDim2.fromOffset(GW, gH)
	for i = 1, count do
		local s = gridSlot(i)
		s.holder.Visible = true
		s.place(((i - 1) % GCOLS) * (GS + GG) + GP, math.floor((i - 1) / GCOLS) * (GS + GG) + GP + 4)
		local it = list[i]
		if it then
			local opt = { locked = lockSet[it.key] == true }
			if mode then
				local on = picked[it.key] == true
				opt.ring = on and MODE_COL[mode] or nil
				opt.check = on and MODE_COL[mode] or nil
				opt.dim = mode == "delete" and lockSet[it.key] == true
			else
				opt.ring = selKey == it.key and C("c8ff6a") or nil
				local hi = tableFind(hotbar, it.key)
				opt.hotIndex = hi
			end
			s.set(it, opt)
		else
			s.set(nil)
		end
	end
	for i = count + 1, #gslots do gslots[i].holder.Visible = false end
	setG(gscroll)
	hdr.Text = tab == "golems" and "Golems" or tab == "ores" and "Ores / Bars" or "Potions"
	local n = 0
	for _, it in list do n += it.n end
	cap.Text = tab == "golems" and (#list .. " / " .. Items.MAX_GOLEMS .. " golems") or tab == "ores" and (#list .. " kinds · " .. NF.full(n) .. " items") or (#list .. " kinds")
	for k, t in tabBtns do
		local l = tabItems(k)
		local c = 0
		for _, it in l do c += it.n end
		t.c.Text = k == "golems" and (#l .. " golems") or (NF.full(c) .. " items")
	end
	-- кнопки режиму
	if mode then
		local sel = selectable()
		local all = #sel > 0
		for _, it in sel do if not picked[it.key] then all = false; break end end
		mA:setText(all and "Deselect All" or "Select All")
		mA:recolor(all and "orange" or "blue")
		local pc = pickedCount()
		if mode == "delete" then
			mBtext.Text = pc > 0 and ("Delete (" .. pc .. ")") or "Delete"
			mB:recolor("red"); mB:enable(pc > 0)
		else
			local allLocked = pc > 0
			for k in picked do if not lockSet[k] then allLocked = false; break end end
			mBtext.Text = pc > 0 and ((allLocked and "Unlock (" or "Lock (") .. pc .. ")") or "Lock"
			mB:recolor(allLocked and "blue" or "yellow"); mB:enable(pc > 0)
		end
		mBtext.TextSize = #mBtext.Text > 10 and 22 or 26
	end
end

local function renderInfo()
	local it = selKey and live(selKey) or nil
	local show = mode == nil and it ~= nil
	showInfoItem(show)
	if mode == "delete" then
		infoHint.Text = 'Tap items to delete · <font color="#ff8a96">' .. pickedCount() .. " selected</font> · locked can't be deleted"
	elseif mode == "lock" then
		infoHint.Text = 'Tap items to lock or unlock · <font color="#ffd23a">' .. pickedCount() .. " selected</font>"
	else
		infoHint.Text = "Tap an item to see it here"
	end
	if not show or not it then return end
	infoIcon.Image = it.icon
	infoName.Text = it.name .. (it.golem and "" or (' <font size="22" color="#c9ced4">×' .. NF.full(it.n) .. "</font>"))
	infoSub.Text = it.sub .. (lockSet[it.key] and " · locked" or "")
	local hi = tableFind(hotbar, it.key)
	local inHand = heldKey == it.key
	bHold:setText(inHand and "Put Away" or "Hold"); bHold:recolor(inHand and "red" or "green")
	bPin:setText(hi and "Unpin" or "Hotbar")
end

refreshAll = function()
	rebuild()
	-- вибране могло зникнути
	if selKey and not live(selKey) then selKey = nil end
	for k in picked do if not live(k) then picked[k] = nil end end
	refreshHotbar()
	if isOpen then renderGrid(); renderInfo() end
end

local function sendHotbar() Action:FireServer("Hotbar", hotbar) end

slotClick = function(s)
	local it = s.item
	if not it then return end
	if not mode then
		selKey = it.key
		renderGrid(); renderInfo()
		return
	end
	if mode == "delete" and lockSet[it.key] then s.shake(); s.toast("LOCKED"); return end
	if picked[it.key] then picked[it.key] = nil else picked[it.key] = true end
	renderGrid(); renderInfo()
end

bHold.onClick = function()
	local it = selKey and live(selKey)
	if not it then return end
	if heldKey == it.key then sendHold("") else
		if not tableFind(hotbar, it.key) then -- у руку можна взяти лише з хотбара: ставимо в перший вільний (або на місце вибраного)
			local i = tableFind(hotbar, "") or 1
			hotbar[i] = it.key
			sendHotbar()
			hot[i].pop()
		end
		sendHold(it.key)
	end
	refreshHotbar(); renderGrid(); renderInfo()
end
bPin.onClick = function()
	local it = selKey and live(selKey)
	if not it then return end
	local hi = tableFind(hotbar, it.key)
	if hi then
		hotbar[hi] = ""
		if heldKey == it.key then sendHold("") end
	else
		local i = tableFind(hotbar, "")
		if not i then StyleA.shake(bPin); return end
		hotbar[i] = it.key
		hot[i].pop()
	end
	sendHotbar()
	refreshHotbar(); renderGrid(); renderInfo()
end

setTab = function(k: string)
	if mode and k ~= tab then return end
	tab = k; selKey = nil; table.clear(picked); gscroll = 0
	for kk, t in tabBtns do
		local on = kk == k
		t.b:setColor(on and "blue" or "gray")
		t.hold.Position = UDim2.fromOffset(on and TX + 10 or TX, mode and tabY(1) or tabY(t.i))
	end
	renderGrid(); renderInfo()
	gstrip.Position = UDim2.fromOffset(0, 10)
	tween(gstrip, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(0, 0) })
end

setMode = function(m)
	mode = m; table.clear(picked); selKey = nil
	for k, t in tabBtns do
		t.hold.Visible = (m == nil) or k == tab
		t.hold.Position = UDim2.fromOffset(k == tab and TX + 10 or TX, m and tabY(1) or tabY(t.i))
	end
	mAh.Visible = m ~= nil; mBh.Visible = m ~= nil
	if m then
		mBicon.Image = m == "delete" and Items.ICONS.trash or Items.ICONS.lock
		for _, h in { mAh, mBh } do
			h.Position = UDim2.fromOffset(TX - 24, h.Position.Y.Offset)
			tween(h, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(TX, h.Position.Y.Offset) })
		end
	end
	showBtn(toolTrash, m == nil); showBtn(toolLock, m == nil); showBtn(toolCancel, m ~= nil)
	renderGrid(); renderInfo()
end
toolTrash.onClick = function() setMode("delete") end
toolLock.onClick = function() setMode("lock") end
toolCancel.onClick = function() setMode(nil) end
mA.onClick = function()
	local sel = selectable()
	local all = #sel > 0
	for _, it in sel do if not picked[it.key] then all = false; break end end
	table.clear(picked)
	if not all then for _, it in sel do picked[it.key] = true end end
	renderGrid(); renderInfo()
end

local function openConfirm()
	local keys = {}
	for k in picked do table.insert(keys, k) end
	local n = #keys
	cfTitle.Text = "Delete " .. n .. " item" .. (n > 1 and "s" or "") .. "?"
	for _, s in cfSlots do s.holder:Destroy() end
	table.clear(cfSlots)
	local show = math.min(6, n)
	local w = show * 70 + (n > 6 and 60 or 0)
	for i = 1, show do
		local s = makeSlot(cfRow, (CFW - w) / 2 + (i - 1) * 70 + 4, 4, 62, true)
		s.set(live(keys[i]))
		s.blocked = function() return true end
		table.insert(cfSlots, s)
	end
	if n > 6 then
		local t = textAt(cfRow, (CFW - w) / 2 + show * 70, 38, 60, 24, "+" .. (n - 6), WHITE, 2.6, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
		table.insert(cfSlots, { holder = t })
	end
	cfDim.Visible = true; cfRoot.Visible = true
	cfScale.Scale = 0.85
	tween(cfScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function()
		tween(cfScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 })
	end)
end
cfDelete.onClick = function()
	local keys = {}
	for k in picked do if not lockSet[k] then table.insert(keys, k) end end
	closeConfirm()
	if #keys == 0 then return end
	Action:FireServer("Delete", keys)
	local t = textAt(content, 290, 360, 646, 26, "Deleted " .. #keys, C("ff8a96"), 3, { ZIndex = 50 })
	tween(t, 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = t.Position - UDim2.fromOffset(0, 24), TextTransparency = 1 })
	task.delay(1.15, function() t:Destroy() end)
	table.clear(picked)
	renderGrid(); renderInfo()
end
mB.onClick = function()
	if pickedCount() == 0 then StyleA.shake(mB); return end
	if mode == "delete" then openConfirm(); return end
	local allLocked = true
	for k in picked do if not lockSet[k] then allLocked = false; break end end
	local keys = {}
	for k in picked do table.insert(keys, k); lockSet[k] = not allLocked or nil end
	Action:FireServer("Lock", { keys = keys, on = not allLocked })
	table.clear(picked)
	refreshHotbar(); renderGrid(); renderInfo()
end

-- =====================================================================
-- ===== масштаб, відкриття / закриття =====
-- =====================================================================
local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or gui.AbsoluteSize
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	fitHotbar()
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	local bottom = (HS + 10 + 10) * hbScale.Scale -- хотбар лишається видно під вікном
	local avail = vh - top - bottom
	modalRoot.Position = UDim2.new(0.5, 0, 0, top + avail / 2)
	local s = math.min((vw - 24) / CANVAS_W, (avail - 8) / CANVAS_H, 1)
	fitScale.Scale = math.clamp(s, 0.1, 1)
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
local open, close -- нижче
local function escKey(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	if cfRoot.Visible then closeConfirm() elseif mode then setMode(nil) else
		task.defer(function() if isOpen then close() end end) -- закрити вікно
	end
	return Enum.ContextActionResult.Sink
end
open = function()
	if isOpen then return end
	isOpen = true
	animToken += 1
	local my = animToken
	refreshAll()
	fit()
	setTab(tab)
	hbGui.DisplayOrder = 11 -- хотбар над затемненням вікна
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
	CAS:BindActionAtPriority("InventoryEsc", escKey, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)
end
close = function()
	if not isOpen then return end
	isOpen = false
	closeConfirm()
	if mode then setMode(nil) end
	pcall(function() CAS:UnbindAction("InventoryEsc") end)
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
		hbGui.DisplayOrder = hbOpenOrder
	end)
end
closeBtn.onClick = function() close() end
backdrop.InputBegan:Connect(function(inp) if isPress(inp) then close() end end)

-- кнопка рюкзака в HUD (MainHUD → UIEvents/HUDButton "Inventory") і клавіша B; 1–9 — хотбар
task.spawn(function()
	local ev = RS:WaitForChild("UIEvents", 30)
	ev = ev and ev:WaitForChild("HUDButton", 30)
	if ev then ev.Event:Connect(function(key) if key == "Inventory" then if isOpen then close() else open() end end end) end
end)
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven,
	Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	local i = tableFind(KEYS, inp.KeyCode)
	if i then toggleHeld(i) return end
	if inp.KeyCode == Enum.KeyCode.B then if isOpen then close() else open() end end
end)

-- дані: будь-яка зміна інвентаря → оновлення (раз за кадр)
local pending = false
local function schedule()
	if pending then return end
	pending = true
	task.defer(function() pending = false; refreshAll() end)
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 4) == "Ore_" or string.sub(name, 1, 5) == "Bars_" or string.sub(name, 1, 4) == "Pot_" or string.sub(name, 1, 3) == "Inv" then schedule() end
end)
refreshAll()
fit()
