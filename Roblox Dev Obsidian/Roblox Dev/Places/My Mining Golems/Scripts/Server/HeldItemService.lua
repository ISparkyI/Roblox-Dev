--!strict
-- HeldItemService — предмет у руці гравця (видно всім гравцям): руда, злитки, големи. Зілля в руці нічого не показують (потім матимуть свою 3D-модель).
-- Де: ServerScriptService/HeldItemService (ModuleScript). Запуск: NicheBoot (після InventoryService).
-- Звідки знає, що в руці: атрибут гравця InvHeld (ставить InventoryService: "Ore_Coal", "Bars_Iron", "Golem_<id>", "Pot_*" або "").
--
-- Як показується: у персонажа з'являється Model «HeldItem», частини приварені (Weld) до RightHand так, щоб предмет
--   стояв ЗВЕРХУ на долоні, а персонаж отримує атрибут HoldPose = true. Позу руки (плече внизу, лікоть 90°, передпліччя
--   вперед, долоня вгору) ставить на кожному клієнті StarterPlayerScripts/HoldPose. Tool не використовуємо (його поза —
--   витягнута вперед рука — не підійшла). R6 (без RightHand) — предмет біля нижнього кінця Right Arm, без пози.
--   * Руда / злитки — ті самі Union-моделі, що в слотах (ReplicatedStorage/Prefabs/ForgeProps: ChunkCoal / ChunkCopper / ChunkIron /
--     BarCopper / BarIron).
--   * Голем — маленька фігурка (висота FIG_HEIGHT стадів) з моделі каталогу (Shared/GolemCatalog, поле model → PlotAssets/<model>):
--     без скриптів, носій — без кірки, з ящичком (CarryBox). Голем без моделі — у руці нічого (поза теж не вмикається).
--     Над фігуркою — табличка (BillboardGui «GolemInfo», як на рефі): мутація [множник сили] (не для Normal), рідкість, назва,
--     головний стат (зелений), «Cost: $…» (жовтий). Кольори — з каталогу.
--   * Над рудою / злитком — підпис (BillboardGui «ItemLabel»): назва білим + «×N» кольором руди
--     (ItemConfig.ORE_TONE), кількість оновлюється за атрибутом.
--   * Підписи й табличку голема видно до LABEL_DIST стадів.
-- Оновлення: зміна InvHeld, InvGolems (мутація / голем зник), нова поява персонажа; кількість — зміна атрибута предмета.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))

local HeldItemService = {}

local HOLDER_NAME = "HeldItem"
local PROPS: { [string]: string } = {
	Ore_Coal = "ChunkCoal", Ore_Copper = "ChunkCopper", Ore_Iron = "ChunkIron",
	Bars_Copper = "BarCopper", Bars_Iron = "BarIron",
	-- мапа 2 (29.10.2026)
	Ore_Tin = "ChunkTin", Ore_Silver = "ChunkSilver", Ore_Gold = "ChunkGold",
	Bars_Tin = "BarTin", Bars_Silver = "BarSilver", Bars_Gold = "BarGold",
}
-- долоня в позі HoldPose: грань −X кисті (RightHand) дивиться вгору, пальці (−Y кисті) — вперед.
-- PALM_ROT — «прямо» предмета у системі кисті: його Y (вгору) = −X кисті, його −Z (обличчя) = −Y кисті (вперед).
local PALM_ROT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0))
local PALM_FWD = 0.1                              -- предмет трохи ближче до пальців, стад
-- злитки: довгою стороною вздовж руки (поворот 90°) і трохи менші
local PROP_TUNE: { [string]: { rot: CFrame, scale: number } } = {
	BarCopper = { rot = CFrame.Angles(0, math.rad(90), 0), scale = 0.75 },
	BarIron = { rot = CFrame.Angles(0, math.rad(90), 0), scale = 0.75 },
	BarTin = { rot = CFrame.Angles(0, math.rad(90), 0), scale = 0.75 },
	BarSilver = { rot = CFrame.Angles(0, math.rad(90), 0), scale = 0.75 },
	BarGold = { rot = CFrame.Angles(0, math.rad(90), 0), scale = 0.75 },
	ChunkSilver = { rot = CFrame.Angles(math.rad(90), 0, 0), scale = 1 }, -- у паку стоїть «на ребрі»
}
-- мапи 3–7 (03.11.2026): шматок і продукт (злиток Bar… або огранований кристал Cut…) — з ForgeConfig
do
	local ForgeCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ForgeConfig"))
	for _, o in ForgeCfg.ALL_ORES do
		PROPS["Ore_" .. o.key] = PROPS["Ore_" .. o.key] or ("Chunk" .. o.key)
		if ForgeCfg.canSmelt(o) then
			local m = ForgeCfg.productModel(o.key)
			PROPS["Bars_" .. o.key] = PROPS["Bars_" .. o.key] or m
			if string.sub(m, 1, 3) == "Bar" and not PROP_TUNE[m] then PROP_TUNE[m] = { rot = CFrame.Angles(0, math.rad(90), 0), scale = 0.75 } end
		end
	end
end
local FIG_HEIGHT = 1.6                            -- висота фігурки голема, стад (маленька фігурка на долоні)
local FIG_YAW = math.rad(0)                       -- поворот фігурки (0 — дивиться туди ж, куди гравець)
local FIG_FWD = 0.25                              -- фігурка трохи далі від тіла, стад
local LABEL_DIST = 32                             -- з якої відстані видно табличку голема й підписи предметів, стад

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local INK = Color3.fromHex("14161a")
local GREEN = Color3.fromHex("7dff3a")
local YELLOW = Color3.fromHex("ffd23a")

-- ===== допоміжне =====
local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end

local function golemEntry(p: Player, key: string): any
	if string.sub(key, 1, 6) ~= "Golem_" then return nil end
	local id = tonumber(string.sub(key, 7))
	for _, g in decode(p, "InvGolems", {}) do
		if type(g) == "table" and g.id == id then return g end
	end
	return nil
end

-- частини візуалу: без фізики, без колізій, невагомі, приварені до кисті
local function prep(inst: Instance)
	for _, d in inst:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("ValueBase") then
			d:Destroy()
		elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	local list = inst:GetDescendants()
	if inst:IsA("BasePart") then table.insert(list, inst) end
	for _, d in list do
		if d:IsA("BasePart") then
			d.Anchored = false; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Massless = true
		end
	end
end
-- Weld з фіксованим C0 (зсув відносно кисті не залежить від того, де зараз рука на сервері)
local function weldTo(hand: BasePart, inst: Instance)
	local list = inst:GetDescendants()
	if inst:IsA("BasePart") then table.insert(list, inst) end
	for _, d in list do
		if d:IsA("BasePart") then
			local w = Instance.new("Weld")
			w.Part0 = hand; w.Part1 = d
			w.C0 = hand.CFrame:ToObjectSpace(d.CFrame)
			w.Parent = d
		end
	end
end

-- ===== фігурка голема =====
local function figurine(g: any, cls: string): Model?
	local assets = RS:FindFirstChild("PlotAssets")
	local src = g.model and assets and assets:FindFirstChild(g.model)
	if not src or not src:IsA("Model") then return nil end
	local m = src:Clone()
	m.Name = "Figurine"
	Catalog.applyClassItems(m, cls, true) -- майнер — кірка, воїн — меч, непотрібні групи видалені
	m:PivotTo(CFrame.new())
	if cls == "carrier" and assets then
		local box = assets:FindFirstChild(Catalog.box(g.id)) or assets:FindFirstChild("CarryBox")
		if box and box:IsA("Model") then
			local b = box:Clone()
			b.Name = "CarryBox"
			-- носій тримає ящичок у руках (поза як у грі, GolemCatalog.poseCarry) — до ScaleTo, тож фігурка масштабується разом із ящичком
			local gd = src:FindFirstChild("GolemData")
			local ok, data = pcall(function() return gd and require(gd :: ModuleScript) end)
			Catalog.poseCarry(m, ok and data or nil, b)
			b.Parent = m
		end
	end
	prep(m)
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * FIG_HEIGHT / math.max(size.Y, 0.1))
	return m
end

local function text(parent: Instance, order: number, h: number, str: string, color: Color3, font: Font)
	local t = Instance.new("TextLabel")
	t.LayoutOrder = order
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, h)
	t.FontFace = font
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Color = INK; s.Thickness = 2.2; s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	t.Parent = parent
	return t
end

-- табличка над фігуркою (як на рефі: мутація, рідкість, назва, стат, ціна)
local function infoBoard(adornee: BasePart, top: number, g: any, cls: string, mut: number, p: Player?)
	local bb = Instance.new("BillboardGui")
	bb.Name = "GolemInfo"
	bb.Adornee = adornee
	bb.Size = UDim2.fromScale(3.6, 1.6) -- стади: табличка зменшується з відстанню, як предмет у світі
	bb.StudsOffsetWorldSpace = Vector3.new(0, top + 0.95, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = LABEL_DIST
	bb.ResetOnSpawn = false
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = bb
	local mu = Catalog.mutation(mut)
	if mut > 0 then
		-- множник — рівно M з каталогу (MUTATIONS[].power): «x1.25» … «x25» (до 2 знаків) (27.10.2026)
		local ml = text(bb, 0, 0.15, mu.key .. " [x" .. (string.format("%.2f", mu.power or 1):gsub("0+$", ""):gsub("%.$", "")) .. "]", mu.color, XBOLD)
		-- градієнт з анімацією — на клієнті: StarterPlayerScripts/MutationTextClient знаходить мітки з атрибутом MutationText
		-- і викликає Shared/MutationText.apply; тут лише атрибут і базовий колір (mu.color)
		ml.Name = "Mutation"
		ml:SetAttribute("MutationText", mut)
	end
	-- ексклюзив: «65% BEST» над рідкістю (02.11.2026)
	local bt = Catalog.bestText and Catalog.bestText(g.id, cls)
	if bt then text(bb, 1, 0.15, bt, Catalog.BEST_COLOR, HEAVY).Name = "Best" end
	text(bb, 2, 0.17, g.rarity, Catalog.rarityColor(g.rarity), XBOLD)
	text(bb, 3, 0.22, g.name, Color3.new(1, 1, 1), HEAVY)
	-- p — власник: динамічні стати (Mushroom Golem = частка BestMinerDmg) рахуються від нього; оновлює onPlayer
	local st = text(bb, 4, 0.22, Catalog.statText(g.id, cls, mut, p), GREEN, HEAVY)
	st.Name = "Stat"
	bb:SetAttribute("Kind", g.id); bb:SetAttribute("Cls", cls); bb:SetAttribute("Mut", mut)
	text(bb, 5, 0.2, "Cost: " .. NF.money(Catalog.stats(g.id, cls, mut).price), YELLOW, HEAVY)
	bb.Parent = adornee
end

-- ===== підпис над рудою / злитком =====
-- назва і колір кількості для ключа (nil — не руда й не злиток)
local function labelInfo(key: string): (string?, Color3?)
	if string.sub(key, 1, 4) == "Ore_" then
		local k = string.sub(key, 5)
		return k, Items.ORE_TONE[k]
	elseif string.sub(key, 1, 5) == "Bars_" then
		local k = string.sub(key, 6)
		local okF, F = pcall(require, game:GetService("ReplicatedStorage").Shared.ForgeConfig)
		return (okF and F.productName(k)) or (k .. " Bar"), Items.ORE_TONE[k] -- «Cut Quartz» для кристалів
	end
	return nil, nil
end
local function labelText(p: Player, key: string): string
	local name, tone = labelInfo(key)
	local n = math.max(0, math.floor(tonumber(p:GetAttribute(key)) or 0))
	return string.format('%s <font color="#%s">×%s</font>', name or key, (tone or YELLOW):ToHex(), NF.short(n))
end
-- один рядок у стилі таблички голема; up — висота над adornee (світова)
local function itemLabel(parent: Instance, adornee: BasePart, up: number, text: string)
	local bb = Instance.new("BillboardGui")
	bb.Name = "ItemLabel"
	bb.Adornee = adornee
	bb.Size = UDim2.fromScale(3.6, 0.5) -- стади
	bb.StudsOffsetWorldSpace = Vector3.new(0, up, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = LABEL_DIST
	bb.ResetOnSpawn = false
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = HEAVY
	t.TextScaled = true
	t.RichText = true
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	local s = Instance.new("UIStroke")
	s.Color = INK; s.Thickness = 2.2; s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	t.Parent = bb
	bb.Parent = parent
end

-- ===== предмет на долоні =====
local function clear(char: Model)
	for _, c in char:GetChildren() do
		if c.Name == HOLDER_NAME and (c:IsA("Model") or c:IsA("Tool")) then c:Destroy() end
	end
	char:SetAttribute("HoldPose", nil)
end

-- точка «на долоні» (світова): Y — вгору в позі HoldPose, −Z — вперед. R6: нижній кінець руки, без пози
local function palmOf(hand: BasePart): CFrame
	if hand.Name == "RightHand" then
		return hand.CFrame * CFrame.new(-hand.Size.X / 2, -PALM_FWD, 0) * PALM_ROT
	end
	return hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, -hand.Size.Z / 2)
end

local function build(p: Player)
	local char = p.Character
	if not char then return end
	local key = p:GetAttribute("InvHeld")
	key = type(key) == "string" and key or ""
	-- той самий предмет (і та сама мутація голема) — нічого не робимо
	local g = golemEntry(p, key)
	local sig = key .. (g and (":" .. tostring(g.kind) .. ":" .. tostring(g.cls) .. ":" .. tostring(g.mut)) or "")
	local cur = char:FindFirstChild(HOLDER_NAME)
	if cur and cur:GetAttribute("Sig") == sig then return end
	clear(char)
	if key == "" then return end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end

	local visual: Instance? = nil
	local rot = CFrame.identity
	local info = nil
	local subs = nil -- 05.11.2026: деталі складеного шматка (Emberite, Eclipsium): { part, rel (від головної), size }
	if PROPS[key] then
		local fp = RS:FindFirstChild("Prefabs")
		fp = fp and fp:FindFirstChild("ForgeProps")
		local tpl = fp and fp:FindFirstChild(PROPS[key])
		if tpl and tpl:IsA("BasePart") then
			local v = tpl:Clone()
			-- складений шматок: деталі-діти трималися на WeldConstraint (prep їх знімає) — запам'ятовуємо їхнє місце відносно
			-- головної деталі ДО prep (відповідність за порядком нащадків), щоб поставити поруч і приварити до руки
			subs = {}
			local sd, cd = tpl:GetDescendants(), v:GetDescendants()
			for k, d in cd do
				local s0 = sd[k]
				if d:IsA("BasePart") and s0 and s0:IsA("BasePart") then table.insert(subs, { part = d, rel = tpl.CFrame:ToObjectSpace(s0.CFrame), size = s0.Size }) end
			end
			prep(v)
			local tune = PROP_TUNE[PROPS[key]]
			local f = tune and tune.scale or 1
			if tune then v.Size *= tune.scale; rot = rot * tune.rot end
			for _, e in subs do e.f = f end
			visual = v
		end
	elseif g then
		local def = Catalog.get(g.kind)
		local cls = Catalog.cls(g.cls)
		if def then
			local m = figurine(def, cls)
			if m then m:SetAttribute("Mut", Catalog.mut(g.mut)) end -- 3D-ефект мутації вмикає клієнт (MutationAuraClient)
			if m then
				visual = m
				-- висота верху фігурки над Root — поки вона стоїть прямо (на сервері рука не в позі HoldPose)
				local root = m:FindFirstChild("Root") or m.PrimaryPart
				local cf, size = m:GetBoundingBox()
				local top = (root and root:IsA("BasePart")) and (cf.Position.Y + size.Y / 2 - root.Position.Y) or size.Y
				info = { def = def, cls = cls, mut = Catalog.mut(g.mut), root = root, top = top }
			end
		end
	end
	if not visual then return end -- зілля, голем без моделі, невідомий ключ — у руці нічого

	local holder = Instance.new("Model")
	holder.Name = HOLDER_NAME
	holder:SetAttribute("Sig", sig)
	holder:SetAttribute("Key", key)
	-- низ предмета — на долоні, предмет «прямо» (вгору в позі HoldPose)
	local palm = palmOf(hand :: BasePart)
	if visual:IsA("BasePart") then
		visual.CFrame = palm * rot * CFrame.new(0, visual.Size.Y / 2, 0)
		for _, e in subs or {} do
			e.part.Size = e.size * e.f
			e.part.CFrame = visual.CFrame * (e.rel - e.rel.Position + e.rel.Position * e.f)
		end
	else
		local m = visual :: Model
		local cf, size = m:GetBoundingBox()
		-- фігурка стоїть СТОПАМИ на руці (вістря кірки звисає нижче); немає ступнів — низ рамки
		local footY = math.huge
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and (string.sub(d.Name, 1, 4) == "Foot" or string.sub(d.Name, 1, 3) == "Toe") then
				footY = math.min(footY, d.Position.Y - d.Size.Y / 2)
			end
		end
		local baseY = footY < math.huge and footY or (cf.Position.Y - size.Y / 2)
		local bottom = m:GetPivot():ToObjectSpace(CFrame.new(cf.Position.X, baseY, cf.Position.Z)).Position
		m:PivotTo(palm * CFrame.new(0, 0, -FIG_FWD) * CFrame.Angles(0, FIG_YAW, 0) * CFrame.new(-bottom))
	end
	visual.Parent = holder
	weldTo(hand :: BasePart, visual)
	if info and info.root and info.root:IsA("BasePart") then
		infoBoard(info.root, info.top, info.def, info.cls, info.mut, p)
	elseif visual:IsA("BasePart") then
		itemLabel(holder, visual, visual.Size.Y / 2 + 0.6, labelText(p, key))
	end
	holder.Parent = char
	if hand.Name == "RightHand" then char:SetAttribute("HoldPose", true) end
end

local function onPlayer(p: Player)
	p:GetAttributeChangedSignal("InvHeld"):Connect(function() build(p) end)
	p:GetAttributeChangedSignal("InvGolems"):Connect(function()
		local key = p:GetAttribute("InvHeld")
		if type(key) == "string" and string.sub(key, 1, 6) == "Golem_" then build(p) end
	end)
	-- кількість предмета в руці змінилась — оновити підпис
	p.AttributeChanged:Connect(function(name)
		if name == "BestMinerDmg" or name == "BestCarrierCap" or name == "BestWarriorDmg" or name == "BestWarriorHp" then -- динамічний голем у руці: оновити стат на табличці
			local holder = p.Character and p.Character:FindFirstChild(HOLDER_NAME)
			local bb = holder and holder:FindFirstChild("GolemInfo", true)
			local t = bb and bb:FindFirstChild("Stat")
			if t and t:IsA("TextLabel") then t.Text = Catalog.statText(bb:GetAttribute("Kind"), bb:GetAttribute("Cls"), bb:GetAttribute("Mut"), p) end
			return
		end
		if name ~= p:GetAttribute("InvHeld") then return end
		local holder = p.Character and p.Character:FindFirstChild(HOLDER_NAME)
		local bb = holder and holder:FindFirstChild("ItemLabel", true)
		local t = bb and bb:FindFirstChild("Text")
		if t and t:IsA("TextLabel") then t.Text = labelText(p, name) end
	end)
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 10)
		char:WaitForChild("RightHand", 10)
		task.wait(0.2)
		build(p)
	end)
	if p.Character then task.spawn(build, p) end
end

-- табличка голема для інших систем (стенди печери, CaveStandService) — та сама, що над фігуркою в руці
HeldItemService.InfoBoard = infoBoard

function HeldItemService.Start()
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return HeldItemService
