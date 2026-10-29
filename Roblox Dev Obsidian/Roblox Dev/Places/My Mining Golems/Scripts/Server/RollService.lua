--!strict
-- RollService — рол големів на підставках ролу в ніші (GDD - Roll, v1 27.10.2026). Сервер авторитетний.
-- Де: ServerScriptService/RollService (ModuleScript). Запуск: NicheBoot (після InventoryService, CaveStandService, IndexService).
-- Анімацію, табличку і вигляд кнопки BUY робить StarterPlayerScripts/RollRevealClient (у кожного гравця, гості бачать теж).
--
-- Рол: важіль (RollLever/LeverScript) у момент удару стріляє Pulled(player, role). Перевірки: власник ніші, дані завантажені,
--   попередня анімація скінчилася. Клас — RollRole (Warrior лише при Stage >= 2, інакше Miner).
--   Пул — големи каталогу з 3D-моделлю (Shared/GolemModel.has), map <= Stage, без Exclusive (зараз Wooden + Stone).
--   На кожній відкритій підставці (Stand1..RollStands): голем і мутація окремо (RollConfig.pick: «1 до N», удача RollLuck %),
--   + RollConfig.FAKES фейків для показу (випадковий голем пулу, випадкова мутація для краси). Некуплений попередній
--   результат замінюється. Атрибут ніші RollBusyUntil (час сервера) — до нього важіль вимкнений.
-- Атрибути підставки RollSystem/Stands/Stand<i> (читає клієнт):
--   RollSeq — JSON { k, c, m, f = { { k, m }, … }, cy } (результат, 4 фейки без повторів підряд, цикл фейка cy с; без f — відновлення, одразу фінал), nil — порожньо;
--   RollT0 — час сервера початку анімації (0 — без анімації); RollReadyAt — коли можна купувати;
--   RollPrice — ціна; RollBoughtT — час купівлі (ефект «забрав»); FaceDir — куди дивиться голем (до проходу).
-- Одна E — одна дія (v4): RollBuyPrompt і RollPrompt — Exclusivity OneGlobally (видно лише найближчу), покупка не йде
--   впродовж 0,6 с після смикання важеля (атрибут ніші RollPullT) і поки йде рол; після покупки — атрибут гравця
--   RollBuyT (LeverScript 0,4 с не ролить).
-- Купівля: ProximityPrompt «RollBuyPrompt» (Style Custom, затиск HOLD с) на невидимій деталі RollBuyAnchor перед
--   големом. Enabled — коли є результат і анімація скінчилася; напис / сірий стан — клієнт (лише власнику).
--   Сервер перевіряє: власник, є результат, анімація скінчилась, відстань, інвентар не повний, Money >= ціна.
--   Успіх: −Money, новий id = CaveStandService.MaxId + 1 → InventoryService.AddGolem (Index відкриється сам) →
--   InventoryService.Pin (закріплений слот хотбара, як кнопка Hotbar в інвентарі; в руку НЕ дається, 27.10.2026 v2).
-- Геймпаси (28.10.2026): Fast Roll (Pass_FastRoll) — без фейків, результат одразу; Auto Roll (Pass_AutoRoll і Set_AutoRoll ~= false) —
--   цикл у Start смикає важіль через RollLever/AutoPull, пауза AUTO_GAP після кінця ролу (з Fast Roll — AUTO_GAP_FAST).
--   Fast Roll також прискорює анімацію важеля вдвічі (LeverScript), тож і ручні роли частіші.
--   Фільтр (SETTINGS → AUTO ROLL FILTER, wanted): мутації Set_RollMuts і мінімум шкоди Set_RollMinDmg. Під фільтр і є Auto Buy
--   (Pass_AutoBuy, Set_AutoBuy) — купується сам (buyAt; спершу в хотбар, повний — в інвентар); немає Auto Buy / Money / місця — Auto Roll стоїть (AutoRollHold).
-- Збереження: атрибут гравця RollPending — JSON { ["<номер підставки>"] = { kind, cls, mut } }, секція "Roll" у DataService
--   ({ pending = … }). При вході результати стають на підставки без анімації. Скидається лише новим ролом,
--   купівлею, новою мапою (DataService.StageReset) і коли підставки немає (номер > RollStands).

-- квести (QuestService): лічильник дій гравця; require ліниво — без циклів між модулями
local function questAdd(p: Player, stat: string, n: number?)
	local okQ, QS = pcall(require, script.Parent:FindFirstChild("QuestService"))
	if okQ and QS and QS.Add then QS.Add(p, stat, n) end
end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local PPS = game:GetService("ProximityPromptService")

local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local RollConfig = require(RS.Shared:WaitForChild("RollConfig"))
local GolemModel = require(RS.Shared:WaitForChild("GolemModel"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local CaveStandService = require(script.Parent:WaitForChild("CaveStandService"))

local RollService = {}

local HOLD = 0.35        -- затиск BUY, с
local PROMPT_DIST = 5.5  -- з якої відстані видно BUY, стад (v4: було 7 — діставало до важеля)
local REACH = 14         -- сервер: максимальна відстань гравця до кнопки
local BTN_FWD = 2.9      -- кнопка: від центру підставки в бік проходу (перед големом ×0,5, біля краю плити 6,4 стада), стад
local BTN_UP = 1.2       -- кнопка: над точкою підставки, стад
local BUSY_PAD = 0.15    -- запас після анімації, с
-- Auto Roll (геймпас Pass_AutoRoll, перемикач Set_AutoRoll): пауза між кінцем ролу і наступним автоматичним — щоб устигнути
-- роздивитись і купити (з Fast Roll — коротша). Важіль смикає LeverScript через BindableEvent RollLever/AutoPull.
local AUTO_GAP = 2.5
local AUTO_GAP_FAST = 0.5 -- Fast Roll + Auto Roll (28.10.2026: було 1,5; важіль з Fast Roll ще й вдвічі швидший — LeverScript)

local rnd = Random.new()
local NicheService: any = nil

local function now(): number return workspace:GetServerTimeNow() end
local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end

-- ===== дані гравця =====
local function decode(p: Player, attr: string, default: any): any
	local s = p:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function pendingOf(p: Player): { [string]: any } return decode(p, "RollPending", {}) end
local function setPending(p: Player, t: { [string]: any })
	p:SetAttribute("RollPending", HttpService:JSONEncode(t))
end
-- запис голема з перевіркою (невідомий / без моделі — nil)
local function clean(g: any): any
	if type(g) ~= "table" then return nil end
	local id = Catalog.id(g.kind)
	if not id then return nil end
	return { kind = id, cls = Catalog.cls(g.cls), mut = Catalog.mut(g.mut) }
end

-- ===== пул і шанси =====
local function poolFor(stage: number): { any }
	local out = {}
	for _, id in Catalog.ORDER do
		local g = (Catalog.GOLEMS :: any)[id]
		if g and g.rarity ~= "Exclusive" and (g.map or 1) <= stage and GolemModel.has(id) then table.insert(out, g) end
	end
	return out
end
local MUTS = {}
for i, mu in Catalog.MUTATIONS do table.insert(MUTS, { odds = mu.odds or 1, mut = i - 1 }) end

local function roleCls(p: Player, role: any): string
	local c = Catalog.cls(type(role) == "string" and string.lower(role) or nil)
	if c == "warrior" and ((tonumber(p:GetAttribute("Stage")) or 1) < 2) then c = "miner" end
	return c
end

-- фейк для показу: випадковий голем пулу, мутація для краси (половина — Normal, решта Bronze…Void).
-- prev — попередня поява { k, m }: того самого голема з тією самою мутацією підряд не буває (v3: з пулом з 1–2 големів
-- це дає чергування; якщо в пулі більше големів — інший голем).
local function fake(pool: { any }, prev: any): any
	local list = pool
	if prev and #pool > 1 then -- без повтору попереднього голема
		list = {}
		for _, x in pool do if x.id ~= prev.k then table.insert(list, x) end end
	end
	local g = list[rnd:NextInteger(1, #list)]
	local m = if rnd:NextNumber() < 0.5 then 0 else rnd:NextInteger(1, 5)
	if prev and g.id == prev.k and m == prev.m then m = (m + rnd:NextInteger(1, 5)) % 6 end
	return { k = g.id, m = m }
end

-- ===== підставки =====
local function nicheOfStand(stand: Instance): Model?
	local holder = stand.Parent
	local rs = holder and holder.Parent
	local niche = rs and rs.Parent
	return (niche and niche:IsA("Model")) and niche or nil
end
local function standsOf(niche: Instance): { [number]: Model }
	local out = {}
	local rs = niche:FindFirstChild("RollSystem")
	local holder = rs and rs:FindFirstChild("Stands")
	if holder then
		for _, s in holder:GetChildren() do
			local i = s:GetAttribute("Index")
			if s:IsA("Model") and type(i) == "number" then out[i] = s end
		end
	end
	return out
end
-- куди дивиться голем на підставці: у бік гравця біля пульта (від екрана до кнопки ROLL)
local function faceDir(niche: Instance): Vector3
	local lm = niche:FindFirstChild("RollLeverModel", true)
	local a = lm and lm:FindFirstChild("PromptAnchor")
	local s = lm and lm:FindFirstChild("Screen")
	if a and s and a:IsA("BasePart") and s:IsA("BasePart") then
		local d = flat(a.Position - s.Position)
		if d.Magnitude > 0.05 then return d.Unit end
	end
	return Vector3.new(1, 0, 0)
end

-- кнопка BUY на підставці (один раз)
local function prepare(stand: Model)
	local niche = nicheOfStand(stand)
	if not niche then return end
	local dir = faceDir(niche)
	stand:SetAttribute("FaceDir", dir)
	local old = stand:FindFirstChild("RollBuyAnchor")
	if old and old:IsA("BasePart") then
		old.CFrame = CFrame.new(stand:GetPivot().Position + dir * BTN_FWD + Vector3.new(0, BTN_UP, 0))
		return
	end
	local a = Instance.new("Part")
	a.Name = "RollBuyAnchor"
	a.Size = Vector3.new(1, 1, 1); a.Transparency = 1
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false
	a.CFrame = CFrame.new(stand:GetPivot().Position + dir * BTN_FWD + Vector3.new(0, BTN_UP, 0))
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "RollBuyPrompt"
	pr.Style = Enum.ProximityPromptStyle.Custom
	pr.ActionText = "Buy"; pr.ObjectText = "Rolled Golem"
	pr.HoldDuration = HOLD
	pr.MaxActivationDistance = PROMPT_DIST
	pr.RequiresLineOfSight = false
	pr.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
	pr.Enabled = false
	pr:SetAttribute("UIText", "BUY")
	pr:SetAttribute("UIColor", "green")
	pr:SetAttribute("UIOffsetY", 0)
	pr:SetAttribute("UIWidth", 5.2)
	pr.Parent = a
	a.Parent = stand
end

local function promptOf(stand: Model): ProximityPrompt?
	local a = stand:FindFirstChild("RollBuyAnchor")
	local pr = a and a:FindFirstChild("RollBuyPrompt")
	return (pr and pr:IsA("ProximityPrompt")) and pr or nil
end

local function clearStand(stand: Model)
	stand:SetAttribute("RollSeq", nil)
	stand:SetAttribute("RollPrice", nil)
	local pr = promptOf(stand)
	if pr then pr.Enabled = false end
end

-- показати результат g на підставці; fakes = nil — без анімації (відновлення)
-- лічильник показів (v7, 27.10.2026): RollSeq завжди новий рядок. До цього однаковий результат із тими самими
-- фейками (пул з 2 големів, майже завжди Wooden Normal) давав той самий JSON — атрибут не змінювався, клієнт не бачив
-- нового ролу і на цій підставці анімація не йшла («інколи голем не ролиться»).
local showN = 0
local function showStand(stand: Model, g: any, fakes: { any }?, t0: number, readyAt: number, cy: number?)
	prepare(stand)
	showN += 1
	local seq: any = { k = g.kind, c = g.cls, m = g.mut, n = showN }
	if fakes then seq.f = fakes; seq.cy = cy end -- cy — тривалість циклу фейка, с
	stand:SetAttribute("RollPrice", Catalog.stats(g.kind, g.cls, g.mut).price)
	stand:SetAttribute("RollT0", t0)
	stand:SetAttribute("RollReadyAt", readyAt)
	stand:SetAttribute("RollSeq", HttpService:JSONEncode(seq))
	local pr = promptOf(stand)
	if pr then
		pr.Enabled = false
		local sig = stand:GetAttribute("RollSeq")
		local wait = readyAt - now()
		local function enable()
			if stand.Parent and stand:GetAttribute("RollSeq") == sig and stand:GetAttribute("RollReadyAt") == readyAt then pr.Enabled = true end
		end
		if wait > 0 then task.delay(wait, enable) else enable() end
	end
end

-- підставка відповідно до даних власника ніші (вхід, нова підставка, клейм / звільнення ніші)
local function applyStand(stand: Model)
	local niche = nicheOfStand(stand)
	if not niche then return end
	prepare(stand)
	local owner = NicheService.GetOwner(niche) :: Player?
	local idx = stand:GetAttribute("Index")
	local g = nil
	if owner and owner:GetAttribute("RollReady") == true and type(idx) == "number" then
		g = clean(pendingOf(owner)[tostring(idx)])
	end
	if not g then clearStand(stand); return end
	-- уже показано той самий результат (можливо, ще йде анімація) — не чіпаємо
	local cur = stand:GetAttribute("RollSeq")
	if type(cur) == "string" then
		local ok, v = pcall(HttpService.JSONDecode, HttpService, cur)
		if ok and type(v) == "table" and v.k == g.kind and v.c == g.cls and v.m == g.mut then return end
	end
	showStand(stand, g, nil, 0, 0)
end

local function applyNiche(niche: Instance?)
	if not niche then return end
	for _, s in standsOf(niche) do applyStand(s) end
end

-- ===== рол =====
local busyUntil: { [Player]: number } = {}
local nextAuto: { [Player]: number } = {} -- Auto Roll: не раніше цього часу

local function onPull(p: Player, role: any, niche: Model)
	if not (p and p.Parent == Players) then return end
	if NicheService.GetNiche(p) ~= niche then return end -- лише власник ніші
	if p:GetAttribute("RollReady") ~= true then return end
	local t = now()
	if busyUntil[p] and t < busyUntil[p] then return end
	local stage = (tonumber(p:GetAttribute("Stage")) or 1)
	local pool = poolFor(stage)
	if #pool == 0 then return end
	local cls = roleCls(p, role)
	local luck = tonumber(p:GetAttribute("RollLuck")) or 0
	-- глобальні події удачі з адмін-панелі (AdminService, атрибути workspace = множник, …Until = os.time кінця):
	--   EventLuck — Roll Luck: шанс рідкісних ГОЛЕМІВ × множник; EventMutLuck — Mutation Luck: шанс МУТАЦІЙ × множник.
	--   Обидві — поверх власного Roll Luck гравця (він діє і на голема, і на мутацію).
	-- геймпаси: x2 Roll Luck (Pass_Lucky) — рідкість голема; x2 Mutation Luck (Pass_MutLucky) — мутація
	-- Luck Potion (Boost_Luck): Roll Luck ×1,25 — і для голема, і для мутації
	local potL = Items.boostOn(p, "Luck") and 1.25 or 1
	-- бонус лідербордів (StatsService, атрибут LB_Luck — відсотки): Roll Luck × (1 + LB_Luck / 100), для голема й мутації
	potL *= 1 + math.max(0, tonumber(p:GetAttribute("LB_Luck")) or 0) / 100
	-- Lucky Roll (продукт SHOP): один рол ×99 або ×10 на всіх підставках — береться найсильніший з запасу
	for _, k in { 99, 10 } do
		local a = "LuckRoll" .. k
		local n = tonumber(p:GetAttribute(a)) or 0
		if n > 0 then
			p:SetAttribute(a, n - 1)
			potL *= k
			p:SetAttribute("LuckRollUsed", k); p:SetAttribute("LuckRollT", os.clock())
			break
		end
	end
	local passGolem = ((p:GetAttribute("Pass_Lucky") == true) and 2 or 1) * potL
	local passMut = ((p:GetAttribute("Pass_MutLucky") == true) and 2 or 1) * potL
	local function boosted(attr: string, passMul: number): number
		local ev = tonumber(workspace:GetAttribute(attr)) or 1
		if not (ev > 1 and os.time() < (tonumber(workspace:GetAttribute(attr .. "Until")) or 0)) then ev = 1 end
		if ev == 1 and passMul == 1 then return luck end
		return ((1 + luck / 100) * ev * passMul - 1) * 100
	end
	local luckGolem, luckMut = boosted("EventLuck", passGolem), boosted("EventMutLuck", passMut)
	local count = RollConfig.totalStands(p) -- за Money + геймпаси Roll Stand
	local stands = standsOf(niche)
	local pend = {}
	local n = 0
	local best = 0 -- найрідкісніший результат цього ролу («1 до N») — лідерборд TOP BEST ROLL
	local cy = RollConfig.cycle(count) -- цикл фейка: остання підставка закінчує рівно на RollConfig.TOTAL
	-- геймпас Fast Roll: без фейків — результат одразу з'являється на всіх підставках (RollRevealClient: поява + спалах)
	local fast = p:GetAttribute("Pass_FastRoll") == true and p:GetAttribute("Set_FastRoll") ~= false
	for i = 1, count do
		local stand = stands[i]
		if stand then
			n = i
			local g = RollConfig.pick(pool, luckGolem, rnd)
			local mu = RollConfig.pick(MUTS, luckMut, rnd)
			local rec = { kind = g.id, cls = cls, mut = mu.mut }
			best = math.max(best, (tonumber(g.odds) or 1) * (tonumber(mu.odds) or 1))
			pend[tostring(i)] = rec
			local fakes = {}
			local prev = nil
			for j = 1, RollConfig.FAKES do
				-- фейки без повторів підряд; останній не збігається з результатом повністю (той самий голем — інша мутація)
				local f = fake(pool, prev)
				if j == RollConfig.FAKES and f.k == rec.kind and f.m == rec.mut then f.m = (f.m + rnd:NextInteger(1, 5)) % 6 end
				table.insert(fakes, f)
				prev = f
			end
			if fast then
				showStand(stand, rec, {}, t, t + RollConfig.RESULT_APPEAR, nil)
			else
				local t0 = t + RollConfig.STAGGER * (i - 1)
				local readyAt = t0 + cy * RollConfig.FAKES + RollConfig.RESULT_APPEAR
				showStand(stand, rec, fakes, t0, readyAt, cy)
			end
		end
	end
	if n == 0 then return end
	-- некуплені результати попереднього ролу замінюються (у тому числі на підставках, яких уже немає)
	setPending(p, pend)
	local okS, Stats = pcall(require, script.Parent:FindFirstChild("StatsService"))
	if okS and Stats then Stats.Max(p, "BestRoll", best) end
	busyUntil[p] = t + (fast and RollConfig.RESULT_APPEAR or RollConfig.revealTime(n)) + BUSY_PAD
	niche:SetAttribute("RollBusyUntil", busyUntil[p])
	questAdd(p, "Roll", 1)
end

-- ===== купівля =====
local lastBuy: { [Player]: number } = {}

-- купити результат підставки idx (ручна покупка — onBuy, автоматична — геймпас Auto Buy); false — не вийшло (немає / місця / Money)
local function buyAt(p: Player, stand: Model, idx: number, auto: boolean): boolean
	local pend = pendingOf(p)
	local g = clean(pend[tostring(idx)])
	if not g then return false end
	if Items.invGolemCount(decode(p, "InvGolems", {}), decode(p, "PlotPlaced", {})) >= Items.maxGolems(p) then return false end -- без големів на плотах
	local price = Catalog.stats(g.kind, g.cls, g.mut).price
	local money = (tonumber(p:GetAttribute("Money")) or 0)
	if money < price then return false end
	local id = CaveStandService.MaxId(p) + 1
	if not InventoryService.AddGolem(p, id, g.kind, g.cls, g.mut, "roll") then return false end -- UID видається тут (Mint), не при ролі
	if price > 0 then p:SetAttribute("Money", money - price) end
	pend[tostring(idx)] = nil
	setPending(p, pend)
	clearStand(stand)
	stand:SetAttribute("RollBoughtT", now())
	p:SetAttribute("RollBuyT", now()) -- LeverScript не ролить у той самий момент
	questAdd(p, "Buy", 1)
	-- закріплений слот хотбара, як кнопка Hotbar (не в руку; хотбар повний — лише в інвентар).
	-- Автопокупки (Auto Buy) — теж спершу в хотбар, поки він не заповниться (28.10.2026; раніше йшли лише в інвентар).
	InventoryService.Pin(p, "Golem_" .. id)
	return true
end

-- фільтр AUTO ROLL у SETTINGS: Set_RollMuts — біти мутацій (1 << mut; 0 — будь-яка мутація),
-- Set_RollRars — біти рідкостей (0 — будь-яка), Set_RollMinDmg — мінімум шкоди голема з мутацією (носій — місткість).
-- Підходить = мутація вибрана І рідкість вибрана І сила >= мінімуму.
local function wanted(p: Player, g: any): boolean
	-- мутацій не вибрано — будь-яка мутація; не вибрано нічого і MIN DAMAGE = 0 — фільтр вимкнено
	local mask = math.floor(tonumber(p:GetAttribute("Set_RollMuts")) or 0)
	local minD = tonumber(p:GetAttribute("Set_RollMinDmg")) or 0
	-- рідкість (Set_RollRars — біти за Catalog.RARITIES: Common = 1 << 0 …; 0 — будь-яка)
	local rars = math.floor(tonumber(p:GetAttribute("Set_RollRars")) or 0)
	if mask <= 0 and rars <= 0 and minD <= 0 then return false end
	if mask > 0 and bit32.band(mask, bit32.lshift(1, g.mut)) == 0 then return false end
	if rars > 0 then
		local def = Catalog.get(g.kind)
		local ri = def and table.find(Catalog.RARITIES, def.rarity)
		if not ri or bit32.band(rars, bit32.lshift(1, ri - 1)) == 0 then return false end
	end
	local st = Catalog.stats(g.kind, g.cls, g.mut)
	local power = (g.cls == "carrier") and (st.cap or 0) or (st.dmg or 0)
	return power >= minD
end

-- після ролу: результати під фільтр — з Auto Buy (Pass_AutoBuy і Set_AutoBuy ~= false) купуються самі; що не купилось
-- (немає геймпаса / Money / місця) — Auto Roll стоїть (true), поки гравець не забере або не зролить сам
local function filterHold(p: Player, niche: Instance): boolean
	local autobuy = p:GetAttribute("Pass_AutoBuy") == true and p:GetAttribute("Set_AutoBuy") ~= false
	local stands = standsOf(niche)
	-- інвентар повний (без големів на плотах, як у buyAt) — Auto Roll і Auto Buy стоять, клієнт показує тост (атрибут AutoRollFull)
	local full = Items.invGolemCount(decode(p, "InvGolems", {}), decode(p, "PlotPlaced", {})) >= Items.maxGolems(p)
	local autoOn = (p:GetAttribute("Pass_AutoRoll") == true and p:GetAttribute("Set_AutoRoll") ~= false) or autobuy
	local fullFlag = full and autoOn
	if (p:GetAttribute("AutoRollFull") == true) ~= fullFlag then p:SetAttribute("AutoRollFull", fullFlag or nil) end
	if full then autobuy = false end
	local hold = full
	for k, rec in pendingOf(p) do
		local g = clean(rec)
		local i = tonumber(k)
		if g and i and wanted(p, g) then
			local st = stands[i]
			if not (autobuy and st and buyAt(p, st, i, true)) then hold = true end
		end
	end
	if (p:GetAttribute("AutoRollHold") == true) ~= hold then p:SetAttribute("AutoRollHold", hold or nil) end
	return hold
end

local function onBuy(prompt: ProximityPrompt, p: Player)
	if prompt.Name ~= "RollBuyPrompt" then return end
	local anchor = prompt.Parent
	local stand = anchor and anchor.Parent
	if not (anchor and anchor:IsA("BasePart") and stand and stand:IsA("Model")) then return end
	local niche = nicheOfStand(stand)
	if not niche or NicheService.GetNiche(p) ~= niche then return end
	if p:GetAttribute("RollReady") ~= true then return end
	local c = os.clock()
	if lastBuy[p] and c - lastBuy[p] < 0.3 then return end
	lastBuy[p] = c
	local char = p.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) or (hrp.Position - anchor.Position).Magnitude > REACH then return end
	local idx = stand:GetAttribute("Index")
	if type(idx) ~= "number" then return end
	local ready = stand:GetAttribute("RollReadyAt")
	if type(ready) == "number" and now() < ready - 0.05 then return end -- анімація ще йде
	-- одне натискання E — одна дія: щойно смикнули важіль (LeverScript ставить RollPullT) або йде рол — не купуємо
	local pullT = niche:GetAttribute("RollPullT")
	if type(pullT) == "number" and now() - pullT < 0.6 then return end
	local busyT = niche:GetAttribute("RollBusyUntil")
	if type(busyT) == "number" and now() < busyT then return end
	buyAt(p, stand, idx, false)
end

-- ===== гравці =====
local function dropMissing(p: Player)
	-- результати на підставках, яких більше немає (номер > RollStands, напр. нова мапа), зникають
	local count = RollConfig.totalStands(p)
	local pend = pendingOf(p)
	local changed = false
	for k in pend do
		local i = tonumber(k)
		if not i or i > count or i < 1 then pend[k] = nil; changed = true end
	end
	if changed then setPending(p, pend) end
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local sec = DataService.GetSection(p, "Roll")
	local pend = {}
	if type(sec) == "table" and type(sec.pending) == "table" then
		for k, g in sec.pending do
			local r = clean(g)
			if r and tonumber(k) and GolemModel.has(r.kind) then pend[tostring(k)] = r end
		end
	end
	setPending(p, pend)
	dropMissing(p)
	p:SetAttribute("RollReady", true)
	for _, a in { "RollStands", "Pass_RollStand1", "Pass_RollStand2" } do
		p:GetAttributeChangedSignal(a):Connect(function()
			dropMissing(p)
			task.defer(applyNiche, NicheService.GetNiche(p))
		end)
	end
	applyNiche(NicheService.GetNiche(p))
end

local function hookNiche(niche: Instance)
	if not niche:IsA("Model") then return end
	task.spawn(function()
		local rs = niche:WaitForChild("RollSystem", 10)
		if not rs then return end
		local lever = rs:FindFirstChild("RollLever", true)
		local pulled = lever and lever:FindFirstChild("Pulled")
		if pulled and pulled:IsA("BindableEvent") then
			pulled.Event:Connect(function(p, role) onPull(p, role, niche :: Model) end)
		else
			warn("RollService: немає RollLever/Pulled у ", niche:GetFullName())
		end
		local holder = rs:WaitForChild("Stands", 10)
		if not holder then return end
		holder.ChildAdded:Connect(function(s)
			if s:IsA("Model") then task.defer(applyStand, s) end
		end)
		applyNiche(niche)
	end)
end

function RollService.Start()
	NicheService = require(script.Parent:WaitForChild("NicheService"))
	DataService.RegisterSection("Roll", function(p: Player, old: any)
		if p:GetAttribute("RollReady") ~= true then return old end
		return { pending = pendingOf(p) }
	end)
	DataService.StageReset.Event:Connect(function(p: Player)
		setPending(p, {})
		task.defer(applyNiche, NicheService.GetNiche(p))
	end)
	local niches = workspace:WaitForChild("Niches")
	for _, n in niches:GetChildren() do hookNiche(n) end
	niches.ChildAdded:Connect(hookNiche)
	NicheService.Claimed.Event:Connect(function(_, n) task.defer(function() task.defer(applyNiche, n) end) end)
	NicheService.Released.Event:Connect(function(_, n) if n and n.Parent then task.defer(function() task.defer(applyNiche, n) end) end end)
	PPS.PromptTriggered:Connect(onBuy)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) busyUntil[p] = nil; lastBuy[p] = nil; nextAuto[p] = nil end)
	-- Auto Roll: раз на 0,1 с — кому пора, смикаємо його важіль (та сама анімація й перевірки, що й від E)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local t = now()
			for _, p in Players:GetPlayers() do
				local niche0 = (p:GetAttribute("RollReady") == true and t >= (busyUntil[p] or 0)) and NicheService.GetNiche(p) or nil
				-- Auto Buy працює і на ручних ролах; Auto Roll стоїть, поки під фільтр є некуплений результат
				local hold = niche0 ~= nil and filterHold(p, niche0)
				if not hold and p:GetAttribute("Pass_AutoRoll") == true and p:GetAttribute("Set_AutoRoll") ~= false and p:GetAttribute("RollReady") == true then
					local gap = (p:GetAttribute("Pass_FastRoll") == true and p:GetAttribute("Set_FastRoll") ~= false) and AUTO_GAP_FAST or AUTO_GAP
					if t >= (busyUntil[p] or 0) + gap and t >= (nextAuto[p] or 0) then
						local niche = NicheService.GetNiche(p)
						local rsys = niche and niche:FindFirstChild("RollSystem")
						local lever = rsys and rsys:FindFirstChild("RollLever", true)
						local ap = lever and lever:FindFirstChild("AutoPull")
						if ap and ap:IsA("BindableEvent") then
							nextAuto[p] = t + ((p:GetAttribute("Pass_FastRoll") == true and p:GetAttribute("Set_FastRoll") ~= false) and 0.6 or 1.2) -- поки важіль іде до удару (≈0,5 с; з Fast Roll ≈0,25 с), не стріляємо вдруге
							ap:Fire(p)
						end
					end
				end
			end
		end
	end)
end

return RollService
