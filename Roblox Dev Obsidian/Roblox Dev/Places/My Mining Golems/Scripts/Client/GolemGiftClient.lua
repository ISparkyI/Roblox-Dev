--!nonstrict
-- GolemGiftClient — подарунок голема в лобі (05.11.2026, GDD/Plan - Golem Gifting). Правила й тексти — Shared/GolemGiftConfig.
-- Де: StarterPlayer/StarterPlayerScripts/GolemGiftClient (LocalScript). Сервер — GolemGiftService (Remotes/GolemGift).
-- Кнопка: локальний ProximityPrompt «GiftPrompt» (Style Custom — вигляд CustomPrompts, фіолетова GIFT) у HumanoidRootPart
--   КОЖНОГО іншого гравця. Увімкнена, лише коли я тримаю в руці голема, якого взагалі можна дарувати (не ексклюзив).
--   Не виконується умова (новачок, кулдаун, MAP N, повний інвентар…) — кнопка сіра (UIDisabled); натиснув — тост з причиною.
-- Натиснув — вікно GIFT GOLEM? (3D-іконка голема, назва з мутацією й рідкістю, кому) → GIFT → сервер → тост «чекаємо відповіді».
-- 06.11.2026: отримувачу — те саме вікно в режимі GIFT FOR YOU! (від кого, ACCEPT / DECLINE, смужка часу Cfg.ACCEPT_TIME);
--   голем переходить лише після ACCEPT. Налаштування отримувача Set_GiftMode (всі / друзі / ніхто) — кнопка сіра з причиною.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = RS:WaitForChild("Shared")
local HubCfg = require(Shared:WaitForChild("HubConfig"))
if HubCfg.isMarket() then return end -- на Marketplace подарунків немає
local Cfg = require(Shared:WaitForChild("GolemGiftConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local ItemVP = require(Shared:WaitForChild("ItemViewport"))
local MutationText = require(Shared:WaitForChild("MutationText"))
local T = Cfg.TEXT

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local C = Color3.fromHex
local INK = C("14161a")
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end

-- ===== вікно підтвердження =====
local gui = new("ScreenGui", { Name = "GolemGiftConfirm", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 60, Enabled = false }, pg)
local dim = new("TextButton", { Name = "Dim", Text = "", AutoButtonColor = false, BackgroundColor3 = BLACK, BackgroundTransparency = 0.45,
	Size = UDim2.fromScale(1, 1), ZIndex = 1 }, gui)
-- 06.11.2026 v2: вікно в стилі гри (рамка з градієнтом + світла панель зі studs, як Inventory / Index), вище — текст не налазить
--   на кнопки; рядок «мутація · рідкість · клас» — окремими мітками (кожна перекладається автоперекладом)
local CW, CH = 500, 452
local panel = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(CW, CH),
	BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2 }, gui)
new("UIStroke", { Color = INK, Thickness = 5 }, panel)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("5d636b"), C("3c4047")) }, panel)
local pScale = new("UIScale", {}, panel)
do -- світла панель зі studs усередині рамки
	local pw, ph = CW - 28, CH - 28
	local inner = new("Frame", { Name = "Inner", Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(pw, ph), BackgroundColor3 = C("a9aeb5"),
		BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2 }, panel)
	new("UIStroke", { Color = INK, Thickness = 4 }, inner)
	local CELL = 40
	local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
	local studs = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, inner)
	pcall(StyleA.studTile, studs, (pw - nx * CELL) / 2, (ph - ny * CELL) / 2, nx * CELL, ny * CELL, CELL, C("b3b8bf"))
	local shade = new("Frame", { BackgroundColor3 = BLACK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, inner)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.12, 1),
		NumberSequenceKeypoint.new(0.88, 1), NumberSequenceKeypoint.new(1, 0.85) }) }, shade)
end
local ttl = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 40, TextColor3 = C("c08cff"), Text = T.title,
	Position = UDim2.fromOffset(0, 26), Size = UDim2.fromOffset(CW, 48), ZIndex = 3 }, panel)
new("UIStroke", { Color = INK, Thickness = 4, LineJoinMode = Enum.LineJoinMode.Round }, ttl)
-- слот з голем
local slot = new("Frame", { Name = "Slot", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(CW / 2, 84), Size = UDim2.fromOffset(132, 132),
	BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, panel)
new("UIStroke", { Color = INK, Thickness = 4 }, slot)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C("2a2f36"), C("15181c")) }, slot)
local slotTone = new("UIStroke", { Color = WHITE, Thickness = 3, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, new("Frame", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 3 }, slot))
local icon = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(10, 10),
	Size = UDim2.fromOffset(112, 112), ZIndex = 4 }, slot)
local nameLbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 30, TextColor3 = WHITE, Text = "",
	Position = UDim2.fromOffset(24, 226), Size = UDim2.fromOffset(CW - 48, 34), ZIndex = 3 }, panel)
new("UIStroke", { Color = INK, Thickness = 3.5, LineJoinMode = Enum.LineJoinMode.Round }, nameLbl)
-- рядок «мутація · рідкість · клас» (по центру, окремі мітки)
local infoRow = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 262), Size = UDim2.fromOffset(CW - 48, 26), ZIndex = 3 }, panel)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, infoRow)
local function infoPart(order: number): TextLabel
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = XBOLD, TextSize = 21, TextColor3 = WHITE, Text = "", LayoutOrder = order,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), ZIndex = 3 }, infoRow)
	new("UIStroke", { Color = INK, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round }, t)
	return t
end
local mutLbl, dot1, rarLbl, dot2, clsLbl = infoPart(1), infoPart(2), infoPart(3), infoPart(4), infoPart(5)
dot1.Text, dot2.Text = "·", "·"
local toLbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = XBOLD, TextSize = 22, TextColor3 = WHITE, Text = "",
	Position = UDim2.fromOffset(24, 296), Size = UDim2.fromOffset(CW - 48, 28), ZIndex = 3 }, panel)
new("UIStroke", { Color = INK, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round }, toLbl)

local pending = nil -- { to = Player, id = number, uid = string }
local offer = nil -- 06.11.2026: вікно в режимі «мені дарують» { oid } (Remotes/GolemGiftOffer)
local busy = false
local friendCache: { [number]: boolean } = {} -- дружба з іншими гравцями (для Set_GiftMode = "friends")
local function close() gui.Enabled = false; pending = nil end

local function send()
	local p = pending
	close()
	if not p or busy then return end
	local rem = RS:FindFirstChild("Remotes")
	local rf = rem and rem:FindFirstChild("GolemGift")
	if not rf then toast(T.errBusy, "red", "deny"); return end
	busy = true
	local ok, res = pcall(rf.InvokeServer, rf, "Gift", { to = p.to.UserId, id = p.id, uid = p.uid })
	busy = false
	if ok and type(res) == "table" and res.ok then
		-- 06.11.2026: голем передається лише після ACCEPT отримувача — поки що «чекаємо відповіді»; тост «You gifted …» шле сервер
		if res.pending then toast(res.msg or "", "green") else UISounds.play("claim", 0.1) end
	else
		toast((ok and type(res) == "table" and res.msg) or T.errBusy, "red", "deny")
	end
end

local function button(x: number, text: string, color: string, onClick)
	local BW, BH = 190, 66
	local holder = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, CH - BH - 40), Size = UDim2.fromOffset(BW, BH + 5), ZIndex = 3 }, panel)
	local sh = new("Frame", { BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(BW, BH), ZIndex = 3 }, holder)
	local b = StyleA.new(holder, { size = Vector2.new(BW, BH), position = Vector2.new(0, 0), color = color, clickable = true, zIndex = 4 })
	StyleA.follow(b, sh)
	local t = new("TextLabel", { BackgroundTransparency = 1, FontFace = HEAVY, TextSize = 32, TextColor3 = WHITE, Text = text, Size = UDim2.fromOffset(BW, BH - 4), ZIndex = 8 }, b.root)
	new("UIStroke", { Color = INK, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	StyleA.bind(b, { debounce = 0.4, onClick = onClick })
	return { b = b, t = t }
end
-- відповідь на подарунок (режим offer)
local function respond(accept: boolean)
	local o = offer
	offer = nil
	gui.Enabled = false
	if not o then return end
	local rem = RS:FindFirstChild("Remotes")
	local rf = rem and rem:FindFirstChild("GolemGift")
	if not rf then return end
	task.spawn(function()
		local ok, res = pcall(rf.InvokeServer, rf, "Respond", { oid = o.oid, accept = accept })
		if accept and ok and type(res) == "table" and res.ok then UISounds.play("claim", 0.1) end
	end)
end
local btnL = button(48, T.confirm, "purple", function() if offer then respond(true) else send() end end)
local btnR = button(CW - 48 - 190, T.cancel, "gray", function() if offer then respond(false) else close() end end)
dim.MouseButton1Click:Connect(function() if offer then respond(false) else close() end end)
-- смужка часу на відповідь (режим offer), під кнопками
local timeBg = new("Frame", { BackgroundColor3 = INK, BackgroundTransparency = 0.3, BorderSizePixel = 0, Position = UDim2.fromOffset(48, CH - 32),
	Size = UDim2.fromOffset(CW - 96, 8), ZIndex = 3, Visible = false }, panel)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, timeBg)
local timeFill = new("Frame", { BackgroundColor3 = C("7ef05a"), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, timeBg)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, timeFill)
local function setMode(m: string)
	local off = m == "offer"
	ttl.Text = off and T.offerTitle or T.title
	btnL.t.Text = off and T.accept or T.confirm
	btnR.t.Text = off and T.decline or T.cancel
	pcall(function() btnL.b:setColor(off and "green" or "purple") end)
	pcall(function() btnR.b:setColor(off and "red" or "gray") end)
	timeBg.Visible = off
end

-- 06.11.2026: адаптивний розмір — як інші вікна: макет під полотно 1080 × 640, вікно займає ≤ 85 % (і менше на малих екранах)
local function fitPanel()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
	pScale.Scale = math.clamp(math.min(vs.X / 1080, vs.Y / 640) * 0.85, 0.42, 1)
end
local function bindCam()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() if gui.Enabled then fitPanel() end end) end
end
bindCam()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCam)

local function fill(g: any)
	local def = Catalog.get(g.kind)
	local tone = Catalog.rarityColor(def and def.rarity)
	icon.Image = Catalog.icon(g.kind)
	ItemVP.set(icon, ItemVP.golemKey(g.kind, g.cls))
	slotTone.Color = tone
	nameLbl.Text = def and def.name or tostring(g.kind)
	nameLbl.TextColor3 = tone
	local mi = Catalog.mut(g.mut)
	local cls = Catalog.cls(g.cls)
	mutLbl.Text = Catalog.MUTATIONS[mi + 1].key
	mutLbl.Visible, dot1.Visible = mi > 0, mi > 0 -- Normal не пишемо
	MutationText.clear(mutLbl)
	if mi > 0 then MutationText.apply(mutLbl, mi) end
	rarLbl.Text = def and def.rarity or ""
	rarLbl.TextColor3 = tone
	dot2.Visible = rarLbl.Text ~= ""
	clsLbl.Text = string.upper(string.sub(cls, 1, 1)) .. string.sub(cls, 2)
end
local function open(to: Player, g: any)
	if offer then return end -- спершу відповісти на подарунок мені
	pending = { to = to, id = g.id, uid = g.uid }
	fill(g)
	setMode("send")
	toLbl.Text = string.format(T.to, to.DisplayName)
	fitPanel()
	gui.Enabled = true
	UISounds.play("tap", 0.1)
end

-- 06.11.2026: мені дарують — вікно GIFT FOR YOU! (ACCEPT / DECLINE, смужка часу); сервер закриває його { close = oid }
task.spawn(function()
	local ev = RS:WaitForChild("Remotes"):WaitForChild("GolemGiftOffer", 60)
	if not ev then return end
	ev.OnClientEvent:Connect(function(d)
		if type(d) ~= "table" then return end
		if d.close then
			if offer and offer.oid == d.close then offer = nil; gui.Enabled = false end
			return
		end
		pending = nil
		offer = { oid = d.oid }
		fill({ kind = d.kind, cls = d.cls, mut = d.mut })
		setMode("offer")
		toLbl.Text = string.format(T.offerFrom, tostring(d.fromName))
		fitPanel()
		gui.Enabled = true
		UISounds.play("claim", 0.1)
		local total = tonumber(d.time) or Cfg.ACCEPT_TIME
		timeFill.Size = UDim2.fromScale(1, 1)
		TweenService:Create(timeFill, TweenInfo.new(total, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
	end)
end)

-- ===== кнопки GIFT над іншими гравцями =====
local prompts: { [Player]: ProximityPrompt } = {}

local function myGolem(): any
	return Cfg.golemOf(player, Cfg.heldId(player))
end

local function refresh(p: Player)
	local pr = prompts[p]
	if not pr or not pr.Parent then return end
	local g = myGolem()
	local show = g ~= nil and not Cfg.isExclusive(g.kind) and p.Parent ~= nil
	if pr.Enabled ~= show then pr.Enabled = show end
	if not show then return end
	local err = Cfg.check(player, p, g, friendCache[p.UserId])
	local dis = err ~= nil
	if (pr:GetAttribute("UIDisabled") == true) ~= dis then pr:SetAttribute("UIDisabled", dis or nil) end
end

local function attach(p: Player, ch: Model)
	local old = prompts[p]
	if old then old:Destroy() end
	local root = ch:WaitForChild("HumanoidRootPart", 10)
	if not root or p.Character ~= ch then return end
	local pr = new("ProximityPrompt", { Name = "GiftPrompt", ActionText = "Gift", ObjectText = "", Style = Enum.ProximityPromptStyle.Custom,
		HoldDuration = 0, MaxActivationDistance = Cfg.PROMPT_DIST, RequiresLineOfSight = false, Enabled = false }, nil)
	pr:SetAttribute("UIText", T.prompt)
	pr:SetAttribute("UIColor", "purple")
	pr:SetAttribute("UIOffsetY", 4.2)
	pr:SetAttribute("UIWidth", 6)
	pr:SetAttribute("UIWorld", true) -- 06.11.2026: розмір у стадах — над гравцем однаковий, з віддаленням камери меншає (CustomPrompts)
	pr.Parent = root
	prompts[p] = pr
	pr.Triggered:Connect(function()
		local g = myGolem()
		if not g then return end
		local err, msg = Cfg.check(player, p, g, friendCache[p.UserId])
		if err then toast(msg or T.errBusy, "red", "deny"); return end
		open(p, g)
	end)
	refresh(p)
end

local function track(p: Player)
	if p == player then return end
	task.spawn(function() local ok, v = pcall(player.IsFriendsWith, player, p.UserId); if ok then friendCache[p.UserId] = v == true end end)
	p.CharacterAdded:Connect(function(ch) task.spawn(attach, p, ch) end)
	if p.Character then task.spawn(attach, p, p.Character) end
	p.AttributeChanged:Connect(function(n)
		if n == "Stage" or n == "InvGolems" or n == "Stat_Playtime" or n == "InBossArena" or n == "PlotPlaced" or n == "Set_GiftMode" then refresh(p) end
	end)
end
for _, p in Players:GetPlayers() do track(p) end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(p)
	local pr = prompts[p]
	if pr then pr:Destroy() end
	prompts[p] = nil
	if pending and pending.to == p then close() end
end)

local function refreshAll() for p in prompts do refresh(p) end end
player.AttributeChanged:Connect(function(n)
	if n == "InvHeld" or n == "InvGolems" or n == "InvLocks" or n == "GiftCD" or n == "Stat_Playtime" or n == "InBossArena" then
		refreshAll()
		if n == "InvHeld" and gui.Enabled and not offer then close() end -- прибрав голема з рук — вікно закривається (не вікно подарунка мені)
	end
end)
-- кулдаун і час гри спливають самі — раз на секунду
task.spawn(function()
	while true do task.wait(1); refreshAll() end
end)
