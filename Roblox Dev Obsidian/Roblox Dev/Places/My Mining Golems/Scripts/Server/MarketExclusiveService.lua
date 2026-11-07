--!nonstrict
-- MarketExclusiveService — стенди ексклюзивних големів на Marketplace (05.11.2026, GDD/Plan - Market Exclusive Golems).
-- Де: ServerScriptService/MarketExclusiveService (ModuleScript). Запуск: NicheBoot у режимі маркету (після MarketServerService —
--   той копіює префаби в PlotAssets). Конфіг — Shared/MarketExclusiveConfig, клієнт — StarterPlayerScripts/MarketExclusiveClient.
--
-- На кожному стенді (Marketplace/Floor/<stand>): модель голема ExclDisplay (Shared/GolemModel.build × DISPLAY_SCALE, аніматор Idle,
--   носій — з вагонеткою; крутить її клієнт), табличка ExclInfo над нею (MARKET EXCLUSIVE, назва, «300% BEST MINER», ціна,
--   LIMIT 1 PER PLAYER) і кнопка — ProximityPrompt BuyPrompt (Style = Custom, малює CustomPrompts) у невидимій деталі ExclButton
--   на краю стенда в бік центру маркету. Напис BUY / OWNED / SOON ставить клієнт; сервер сам вирішує дію й перевіряє все.
-- Покупка (Triggered):
--   robux    — перевірка (не куплено, є місце) → MarketplaceService:PromptProductPurchase; видача — у ProcessReceipt
--              (MonetizationService → MarketExclusiveService.GrantProduct, дублікати відсікає MonetizationService);
--   tickets  — атомарно через DataStore STORE (UpdateAsync ключа <kind>: { n, list }): ціна = price + step × n, тікетів
--              вистачає → n + 1 і запис покупця на початок list (останні BOARD_ROWS); потім −Tickets, видача, дошка, MessagingService;
--   diamonds — −Diamonds, видача.
--   Видача: InventoryService.AddGolem (id = CaveStandService.MaxId + 1, мутація 0, reason "market:<kind>"), Pin у хотбар,
--   атрибут Pass_MktExcl_<kind> = true (ліміт 1 на гравця), SaveNow. Відповідь гравцеві — тост (Remotes/AdminBroadcast "toast").
-- П'єдестали (05.11.2026) — статичні моделі <stand>/ExclPedestal (власний стиль кожного голема, збудовані в Studio):
--   GolemSpot — центр верху (стопи голема, LookVector — лицем до центру маркету), ButtonSpot — кнопка BUY по центру
--   спереду, BuyersBoard/BoardPanel — дошка покупців (у Lamp Miner). Старі диски стендів — ServerStorage/NicheBackup/MarketStands_pre.
-- Дошка покупців (лише для tickets): SurfaceGui на BoardPanel — NEXT PRICE + останні покупці «#N Нік — ціна».
--   Оновлення на всіх серверах: MessagingService TOPIC + опитування кожні POLL с. Studio без доступу до API — лічильник у пам'яті.
-- Стенд — атрибути MktExcl = <kind>, Sold = n (скільки куплено глобально; для tickets), Price = поточна ціна.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Shared = RS:WaitForChild("Shared")
local Cfg = require(Shared:WaitForChild("MarketExclusiveConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local M = {}
local T = Cfg.TEXT
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local INK = Color3.fromHex("14161a")
local CUR_COLOR = { robux = Color3.fromHex("7dff3a"), tickets = Color3.fromHex("ffd23a"), diamonds = Color3.fromHex("5fd8ff") }

local stands = {}       -- kind -> { e, stand, priceLabel, board }
local sold = {}         -- kind -> скільки куплено глобально (tickets)
local buyers = {}       -- kind -> останні покупці { { i, u, n, p, t } }
local busy: { [Player]: boolean } = {}
local store = nil
local memory = {}       -- Studio без API: лічильник у пам'яті
local useMemory = false

-- ===== допоміжне =====
local function notify(p: Player, text: string, color: string)
	local r = RS:FindFirstChild("Remotes")
	local ev = r and r:FindFirstChild("AdminBroadcast")
	if ev and ev:IsA("RemoteEvent") then ev:FireClient(p, "toast", { text = text, color = color }) end
end

local function decode(p: Player, a: string): any
	local s = p:GetAttribute(a)
	if type(s) ~= "string" or s == "" then return {} end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return (ok and type(v) == "table") and v or {}
end

local function invFull(p: Player): boolean
	return Items.invGolemCount(decode(p, "InvGolems"), decode(p, "PlotPlaced")) >= Items.maxGolems(p)
end

local function priceText(e: any, price: number): string
	return NF.full(price) .. " " .. T.cur[e.cur]
end

local function label(parent: Instance, order: number, h: number, text: string, color: Color3, font: Font): TextLabel
	local t = Instance.new("TextLabel")
	t.LayoutOrder = order
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, h)
	t.FontFace = font
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Color = INK; s.Thickness = 2.4; s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	t.Parent = parent
	return t
end

-- верх і центр стенда, радіус, напрям до центру маркету (XZ)
local function standFrame(stand: Model): (Vector3, number, Vector3)
	local cf, size = stand:GetBoundingBox()
	local topY = -math.huge
	for _, d in stand:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "ExclButton" and not d:FindFirstAncestor("ExclDisplay") and not d:FindFirstAncestor("ExclBoard") then
			topY = math.max(topY, d.Position.Y + d.Size.X / 2) -- диски-циліндри: вісь X вертикальна
		end
	end
	local top = Vector3.new(cf.Position.X, topY, cf.Position.Z)
	local d = Vector3.new(Cfg.CENTER.X - top.X, 0, Cfg.CENTER.Z - top.Z)
	local dir = d.Magnitude > 1e-3 and d.Unit or Vector3.new(0, 0, -1)
	return top, math.max(size.Y, size.Z) / 2, dir
end

-- ===== вітрина: голем, табличка, кнопка, дошка =====
-- дошка покупців: текст на статичній панелі ExclPedestal/BuyersBoard/BoardPanel (дерев'яне табло у стилі LeaderBoard,
-- лицевий бік — атрибут Face панелі, за замовчуванням Front); темна підкладка з заокругленими кутами
local function buildBoard(st: any, panel: BasePart)
	local old = panel:FindFirstChild("Gui")
	if old then old:Destroy() end
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Gui"
	local faceName = panel:GetAttribute("Face")
	sg.Face = (type(faceName) == "string" and (Enum.NormalId :: any)[faceName]) or Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(panel.Size.X * 50, panel.Size.Y * 50)
	sg.LightInfluence = 0
	sg.MaxDistance = 700 -- 06.11.2026: 140 → 700 (видно з будь-якої точки маркету)
	sg.Parent = panel
	local bg = Instance.new("Frame")
	bg.Name = "Back"
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.Size = UDim2.new(1, -36, 1, -36)
	bg.BackgroundColor3 = Color3.fromHex("1c1f26")
	bg.BackgroundTransparency = 0.08
	bg.Parent = sg
	local cr = Instance.new("UICorner") cr.CornerRadius = UDim.new(0, 18) cr.Parent = bg
	local bst = Instance.new("UIStroke") bst.Color = Color3.fromHex("ffb21f") bst.Thickness = 4 bst.Parent = bg
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 16); pad.PaddingBottom = UDim.new(0, 16); pad.PaddingLeft = UDim.new(0, 20); pad.PaddingRight = UDim.new(0, 20)
	pad.Parent = bg
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = bg
	label(bg, 1, 0.1, T.boardTitle, Color3.fromHex("ffd23a"), HEAVY)
	st.boardPrice = label(bg, 2, 0.075, "", CUR_COLOR.tickets, XBOLD)
	st.boardRows = {}
	for i = 1, Cfg.BOARD_ROWS do
		local r = label(bg, 2 + i, 0.075, "", Color3.new(1, 1, 1), XBOLD)
		r.TextXAlignment = Enum.TextXAlignment.Left
		st.boardRows[i] = r
	end
end

local function render(kind: string)
	local st = stands[kind]
	if not st then return end
	local e = st.e
	local price = Cfg.priceOf(e, sold[kind] or 0)
	st.stand:SetAttribute("Price", price)
	if e.cur == "tickets" then st.stand:SetAttribute("Buyers", HttpService:JSONEncode(buyers[kind] or {})) end
	st.stand:SetAttribute("Sold", sold[kind] or 0)
	if st.priceLabel then st.priceLabel.Text = priceText(e, price) end
	if st.boardPrice then
		st.boardPrice.Text = T.boardPrice .. ": " .. priceText(e, price)
		local list = buyers[kind] or {}
		for i, row in st.boardRows do
			local b = list[i]
			if b then
				row.Text = string.format("#%d  %s  —  %s", tonumber(b.i) or 0, tostring(b.n), NF.full(tonumber(b.p) or 0))
			else
				row.Text = (i == 1) and T.boardEmpty or ""
			end
		end
	end
end

local function buildStand(e: any, floor: Instance)
	local stand = floor:FindFirstChild(e.stand)
	if not (stand and stand:IsA("Model")) then warn("MarketExclusiveService: немає стенда " .. e.stand); return end
	for _, n in { "ExclDisplay", "ExclButton", "ExclBoard" } do local o = stand:FindFirstChild(n); if o then o:Destroy() end end
	local ped = stand:FindFirstChild("ExclPedestal")
	local gs = ped and ped:FindFirstChild("GolemSpot")
	local bs = ped and ped:FindFirstChild("ButtonSpot")
	local top, radius, dir
	if gs and gs:IsA("BasePart") then
		top, dir = gs.Position, gs.CFrame.LookVector
	else
		top, radius, dir = standFrame(stand)
	end
	stand:SetAttribute("MktExcl", e.kind)
	local st = { e = e, stand = stand }
	stands[e.kind] = st
	local GolemModel = require(Shared:WaitForChild("GolemModel"))
	local m = GolemModel.build(e.kind, e.cls)
	local def = Catalog.get(e.kind)
	if m then
		m.Name = "ExclDisplay"
		m:ScaleTo(m:GetScale() * Cfg.DISPLAY_SCALE)
		local pos = top + Vector3.new(0, GolemModel.footOffset(m), 0)
		m:PivotTo(CFrame.lookAt(pos, pos + dir))
		m.Parent = stand
		local root = m:FindFirstChild("Root") or m.PrimaryPart
		if root and root:IsA("BasePart") then
			local bb = Instance.new("BillboardGui")
		bb.Name = "ExclInfo"
			bb.Adornee = root
			bb.Size = UDim2.fromScale(11, 6.2) -- стади
			bb.StudsOffsetWorldSpace = Vector3.new(0, GolemModel.headTop(m) + 3.6, 0)
			bb.LightInfluence = 0
			bb.MaxDistance = 450 -- 06.11.2026: 140 → 450
			local list = Instance.new("UIListLayout")
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.VerticalAlignment = Enum.VerticalAlignment.Bottom
			list.Parent = bb
			label(bb, 1, 0.15, T.exclusive, Catalog.rarityColor(def.rarity), XBOLD)
			label(bb, 2, 0.24, def.name, Color3.new(1, 1, 1), HEAVY)
			local bt = Catalog.bestText(e.kind, e.cls) or ""
			label(bb, 3, 0.19, bt .. " " .. T.cls[e.cls], Catalog.BEST_COLOR, HEAVY)
			st.priceLabel = label(bb, 4, 0.22, "", CUR_COLOR[e.cur], HEAVY)
			label(bb, 5, 0.12, T.limit, Color3.fromHex("c8ccd1"), XBOLD)
			bb.Parent = root
		end
	end
	-- кнопка на краю стенда в бік центру маркету
	local btn = Instance.new("Part")
	btn.Name = "ExclButton"
	btn.Size = Vector3.new(1, 1, 1)
	btn.Transparency = 1
	btn.Anchored = true; btn.CanCollide = false; btn.CanQuery = false; btn.CanTouch = false
	-- 06.11.2026: кнопка по центру стенда (біля стоп голема, трохи вперед), а не на краю (ButtonSpot); розмір — у стадах (UIWorld)
	btn.CFrame = if gs and gs:IsA("BasePart") then CFrame.new(top + dir * 2.5 + Vector3.new(0, 0.5, 0))
		elseif bs and bs:IsA("BasePart") then bs.CFrame else CFrame.new(top + dir * ((radius or 10) - 2.2) + Vector3.new(0, 3.2, 0))
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "BuyPrompt"
	pp.Style = Enum.ProximityPromptStyle.Custom
	pp.ActionText = T.buy
	pp.ObjectText = def and def.name or e.kind
	pp.HoldDuration = 0.5
	pp.MaxActivationDistance = Cfg.PROMPT_DIST
	pp.RequiresLineOfSight = false
	pp:SetAttribute("UIText", T.buy)
	pp:SetAttribute("UIColor", "green")
	pp:SetAttribute("UIWorld", true) -- 06.11.2026: у стадах — не «роздувається» на півекрана здалеку
	pp:SetAttribute("UIWidth", 7)
	pp:SetAttribute("UIOffsetY", 1.5)
	pp.Parent = btn
	btn.Parent = stand
	pp.Triggered:Connect(function(p) M.Buy(p, e.kind) end)
	local bb = ped and ped:FindFirstChild("BuyersBoard")
	local panel = bb and bb:FindFirstChild("BoardPanel")
	-- 05.11.2026: дошку покупців малює клієнт (MarketExclusiveClient, у стилі табел маркету) з атрибутів стенда Buyers / Price
	if panel and panel:IsA("BasePart") then local og = panel:FindFirstChild("Gui"); if og then og:Destroy() end end
	if false then buildBoard(st, panel :: any) end
	render(e.kind)
end

-- ===== глобальний лічильник (tickets) =====
local function apply(kind: string, v: any)
	if type(v) ~= "table" then return end
	sold[kind] = math.max(0, math.floor(tonumber(v.n) or 0))
	buyers[kind] = type(v.list) == "table" and v.list or {}
	render(kind)
end

local function refresh(kind: string)
	if useMemory then apply(kind, memory[kind]); return end
	local ok, v = pcall(store.GetAsync, store, kind)
	if ok then apply(kind, v or { n = 0, list = {} }) end
end

-- забрати наступний номер покупки: (ціна | nil, помилка | nil)
local function claim(p: Player, e: any): (number?, string?)
	local paid, err, newV = nil, nil, nil
	local function transform(old: any): any
		if type(old) ~= "table" then old = { n = 0, list = {} } end
		local n = math.max(0, math.floor(tonumber(old.n) or 0))
		local price = Cfg.priceOf(e, n)
		if (tonumber(p:GetAttribute("Tickets")) or 0) < price then paid, err = nil, "tickets"; return nil end
		local list = type(old.list) == "table" and table.clone(old.list) or {}
		table.insert(list, 1, { i = n + 1, u = p.UserId, n = p.Name, p = price, t = os.time() })
		while #list > Cfg.BOARD_ROWS do table.remove(list) end
		paid, err = price, nil
		newV = { n = n + 1, list = list }
		return newV
	end
	if useMemory then
		local v = transform(memory[e.kind])
		if v then memory[e.kind] = v end
	else
		local ok = pcall(store.UpdateAsync, store, e.kind, transform)
		if not ok then return nil, "busy" end
	end
	if paid and newV then apply(e.kind, newV) end
	return paid, err
end

-- ===== видача =====
local function grant(p: Player, e: any, force: boolean?): boolean
	local okI, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
	local okC, Cave = pcall(require, script.Parent:FindFirstChild("CaveStandService"))
	if not (okI and Inv) then return false end
	local id = 0
	if okC and Cave and Cave.MaxId then local okM, mx = pcall(Cave.MaxId, p); if okM and type(mx) == "number" then id = mx end end
	for _, g in decode(p, "InvGolems") do if type(g) == "table" and type(g.id) == "number" then id = math.max(id, g.id) end end
	id += 1
	if not Inv.AddGolem(p, id, e.kind, e.cls, 0, "market:" .. e.kind, force) then return false end
	p:SetAttribute(Cfg.ownedAttr(e.kind), true)
	if Inv.Pin then pcall(Inv.Pin, p, "Golem_" .. id) end
	return true
end

local function done(p: Player, e: any)
	local def = Catalog.get(e.kind)
	notify(p, string.format(T.done, def and def.name or e.kind), "green")
	task.spawn(function() pcall(DataService.SaveNow, p) end)
end

-- кнопка BUY на стенді
function M.Buy(p: Player, kind: string)
	local st = stands[kind]
	if not st or busy[p] or not DataService.IsLoaded(p) or p:GetAttribute("InvReady") ~= true then return end
	local e = st.e
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local btn = st.stand:FindFirstChild("ExclButton")
	if not (hrp and btn) or (hrp.Position - btn.Position).Magnitude > Cfg.REACH then return end
	if p:GetAttribute(Cfg.ownedAttr(kind)) == true then notify(p, T.errOwned, "red"); return end
	if invFull(p) then notify(p, T.errFull, "red"); return end
	if e.cur == "robux" then
		if (e.productId or 0) == 0 then notify(p, T.errSoon, "gray"); return end
		MarketplaceService:PromptProductPurchase(p, e.productId)
		return
	end
	busy[p] = true
	local ok, err = pcall(function()
		if e.cur == "diamonds" then
			local dia = tonumber(p:GetAttribute("Diamonds")) or 0
			if dia < e.price then notify(p, T.errDiamonds, "red"); return end
			p:SetAttribute("Diamonds", dia - e.price)
			if not grant(p, e) then p:SetAttribute("Diamonds", (tonumber(p:GetAttribute("Diamonds")) or 0) + e.price); notify(p, T.errFull, "red"); return end
			done(p, e)
		elseif e.cur == "tickets" then
			local price = Cfg.priceOf(e, sold[kind] or 0)
			if (tonumber(p:GetAttribute("Tickets")) or 0) < price then notify(p, T.errTickets, "red"); return end
			local paid, why = claim(p, e)
			if not paid then notify(p, why == "tickets" and T.errTickets or T.errBusy, "red"); return end
			p:SetAttribute("Tickets", math.max(0, (tonumber(p:GetAttribute("Tickets")) or 0) - paid))
			if not grant(p, e, true) then
				p:SetAttribute("Tickets", (tonumber(p:GetAttribute("Tickets")) or 0) + paid) -- не вийшло — повертаємо (лічильник лишається)
				notify(p, T.errFull, "red")
				return
			end
			done(p, e)
			pcall(MessagingService.PublishAsync, MessagingService, Cfg.TOPIC, kind)
		end
	end)
	busy[p] = nil
	if not ok then warn("MarketExclusiveService.Buy: " .. tostring(err)) end
end

-- Developer Product (викликає MonetizationService з ProcessReceipt): true / false (ще не можна — повторити пізніше) /
-- nil (не наш продукт). Платна покупка — без ліміту інвентаря (force); ліміт «1 на гравця» перевірено перед вікном оплати.
function M.GrantProduct(p: Player, productId: number): boolean?
	local e = Cfg.byProduct(productId)
	if not e then return nil end
	if p:GetAttribute("InvReady") ~= true then return false end
	if not grant(p, e, true) then return false end
	local def = Catalog.get(e.kind)
	notify(p, string.format(T.done, def and def.name or e.kind), "green")
	return true
end

function M.Start()
	local mk = workspace:FindFirstChild("Marketplace")
	local floor = mk and mk:FindFirstChild("Floor")
	if not floor then warn("MarketExclusiveService: немає Marketplace/Floor"); return end
	local name = Cfg.STORE .. (RunService:IsStudio() and "_Studio" or "")
	local okS, s = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	store = okS and s or nil
	if not store or not pcall(store.GetAsync, store, "_ping") then useMemory = true end
	for _, e in Cfg.LIST do
		local ok, err = pcall(buildStand, e, floor)
		if not ok then warn("MarketExclusiveService: стенд " .. e.stand .. ": " .. tostring(err)) end
		if e.cur == "tickets" then task.spawn(refresh, e.kind) end
	end
	pcall(MessagingService.SubscribeAsync, MessagingService, Cfg.TOPIC, function(msg)
		if type(msg.Data) == "string" and stands[msg.Data] then task.spawn(refresh, msg.Data) end
	end)
	task.spawn(function()
		while true do
			task.wait(Cfg.POLL)
			for _, e in Cfg.LIST do if e.cur == "tickets" then refresh(e.kind) end end
		end
	end)
	Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
end

return M
