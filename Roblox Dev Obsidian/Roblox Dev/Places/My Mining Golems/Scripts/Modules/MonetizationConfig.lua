--!nonstrict
-- MonetizationConfig — ID геймпасів і Developer Products (спільний для сервера й клієнта).
-- Де: ReplicatedStorage/Shared/MonetizationConfig.
-- ID = 0 — ще не створено в Creator Hub (кнопка не працює, у Studio виводиться підказка).
-- 28.10.2026: усі геймпаси й продукти (крім MUT_SPEED_TIERS) створені в Creator Hub з цими цінами й іконками гри; Managed pricing вимкнено.

local Config = {}

-- геймпаси (купуються один раз, атрибут гравця Pass_<ключ> = true; DataService зберігає префікс Pass_).
-- Магазин SHOP (StarterPlayerScripts/ShopWindow) показує їх у порядку order; featured — велика картка зверху.
--   id — GamePassId у Creator Hub (0 — ще не створено: за Robux купити не можна, лише за тікети);
--   robux — ціна в Robux (ПРОПОЗИЦІЯ, у Creator Hub ставити ту саму); за тікети — ticketPrice(robux) = robux × 1,25, вгору до цілого;
--   icon — іконка картки й «падаючих» іконок фону; tone — колір підсвітки картки.
-- Що дає кожен (де працює):
--   VIP         — x1.5 Money назавжди (MultiService, рядок VIP у TOTAL MULTI) + 2 слоти лотів на маркеті (HubConfig.marketSlots)
--   Lucky       — x2 Roll Luck: рідкісні големи й мутації (RollService, поверх Roll Luck і подій)
--   AutoEquip   — Auto Equip Best: найкращі големи самі стають на плоти; перемикач у SETTINGS (PlotService, SettingsService)
--   FastForge   — кузня плавить у 2 рази швидше (ForgeService)
--   AutoCollect — руда з ящика плоту одразу йде в інвентар, без COLLECT (PlotService)
--   Lucky / MutLucky — x2 Roll Luck (рідкість голема) / x2 Mutation Luck (мутація) окремо (RollService)
--   RollStand1 / RollStand2 — +1 підставка ролу кожен (RollConfig.totalStands, точки Point6 / Point7)
Config.Passes = {
	VIP = { id = 2057519489, robux = 149, order = 1, featured = true, name = "VIP", icon = "rbxassetid://111200556390804", tone = "ffd23a",
		desc = "x1.5 Money forever on every sale and +2 Marketplace listing slots. VIP crown in TOTAL MULTI!" },
	Lucky = { id = 2058155578, robux = 79, order = 2, name = "x2 Roll Luck", icon = "rbxassetid://116109725516204", tone = "7ef05a",
		desc = "Double Roll Luck forever: rare golems drop 2x more often." },
	MutLucky = { id = 2060446843, robux = 99, order = 2.5, name = "x2 Mutation Luck", icon = "rbxassetid://90173095287975", tone = "8fe3ff",
		desc = "Double Mutation Luck forever: mutations drop 2x more often." },
	AutoEquip = { id = 2058749563, robux = 99, order = 3, name = "Auto Equip Best", icon = "rbxassetid://85163785197859", tone = "5cc8ff",
		desc = "Your best golems go to your plots automatically. Toggle it in Settings." },
	FastForge = { id = 2057903547, robux = 149, order = 4, name = "Fast Workshop", icon = "rbxassetid://102635405420682", tone = "ff8a3a",
		desc = "The Workshop smelts ore into bars 2x faster." },
	-- Auto Sell / Auto Workshop (29.10.2026): та сама механіка, що й картки за Money (плот: Auto Sell з мапи 2; Workshop: Auto з мапи 3), але діє
	--   з мапи 1 і НЕ скидається. Геймпаси створено 29.10.2026 (Creator Hub). Ціни — рішення користувача.
	AutoSell = { id = 2060909193, robux = 79, order = 4.6, name = "Auto Sell", icon = "rbxassetid://110396437023647", tone = "ff6fd0",
		desc = "Mined ore and bars sell by themselves. Pick what to sell on the Auto Sell card. Works on every map!" },
	AutoWorkshop = { id = 2062258340, robux = 149, order = 4.7, name = "Auto Workshop", icon = "rbxassetid://102635405420682", tone = "ffb15c",
		desc = "The Workshop takes ore from your inventory, smelts it and puts the bars back. Works on every map!" },
	AutoCollect = { id = 2058077602, robux = 249, order = 5, name = "Auto Collect", icon = "rbxassetid://91341404610533", tone = "c08cff",
		desc = "Ore from plot crates goes straight to your inventory. No more COLLECT!" },
	-- +1 підставка ролу у 2 етапи (Point6, Point7): спершу RollStand1, потім RollStand2 (requires); у магазині — одна картка «1/2 → 2/2»
	RollStand1 = { id = 2059511549, robux = 49, order = 6, name = "+1 Roll Stand", icon = "rbxassetid://106904376756862", tone = "c9ced5",
		desc = "One more golem every roll. Two stages!", stages = { "RollStand1", "RollStand2" } },
	RollStand2 = { id = 2058509528, robux = 79, order = 7, name = "+1 Roll Stand II", icon = "rbxassetid://106904376756862", tone = "c9ced5",
		desc = "One more golem every roll (stage 2).", requires = "RollStand1", hidden = true },
	-- Fast Roll — рол без анімації фейків: результат одразу (RollService, RollRevealClient)
	FastRoll = { id = 2060926733, robux = 149, order = 8, name = "Fast Roll", icon = "rbxassetid://94434685510270", tone = "5cc8ff",
		desc = "Roll results appear instantly. No waiting between rolls!" },
	-- Auto Roll — важіль смикається сам (RollService, AutoPull у LeverScript); перемикач у SETTINGS (Set_AutoRoll)
	AutoRoll = { id = 2059577564, robux = 199, order = 9, name = "Auto Roll", icon = "rbxassetid://123138472161660", tone = "ff6fb8",
		desc = "The lever rolls by itself. Toggle it in Settings." },
	-- Auto Buy — результати ролу під фільтр (SETTINGS → AUTO ROLL FILTER: мутації, мінімум шкоди) купуються самі (RollService.filterHold)
	AutoBuy = { id = 2058257506, robux = 249, order = 10, name = "Auto Buy", icon = "rbxassetid://73783624459990", tone = "7ef05a",
		desc = "Rolled golems that match your filter are bought for you." },
}
Config.TICKET_RATE = 1.25

-- пакети тікетів (Developer Products, багаторазові): перші два — 1 Robux = 1 тікет, далі вигода +4 … +25 % (10K)
--   (вигода = tickets / robux − 1, не більше 25 %). id = 0 — продукт ще не створено в Creator Hub (кнопка хитається).
Config.TicketProducts = {
	{ tickets = 9, robux = 9, id = 3723334366 },        -- 1 R$ = 1 тікет
	{ tickets = 27, robux = 27, id = 3723334398 },      -- 1 R$ = 1 тікет
	{ tickets = 99, robux = 95, id = 3723334428 },      -- +4,2 %
	{ tickets = 249, robux = 232, id = 3723334459 },    -- +7,3 %
	{ tickets = 499, robux = 450, id = 3723334497 },    -- +10,9 %
	{ tickets = 999, robux = 873, id = 3723334592 },    -- +14,4 %
	{ tickets = 2499, robux = 2118, id = 3723334627 },  -- +18,0 %
	{ tickets = 4999, robux = 4114, id = 3723334654 },  -- +21,5 %
	{ tickets = 10000, robux = 8000, id = 3723334689 }, -- +25,0 %
}
function Config.ticketBonus(t): number return t.tickets / t.robux - 1 end

-- інші Developer Products (багаторазові): Potion Pack — по potions кожного зілля (ItemConfig.POTIONS). За тікети — ticketPrice(robux).
Config.Products = {
	PotionPack = { id = 3723334276, robux = 79, potions = 5 },
	-- Starter Pack: +$50K Money, 3 Luck Potions, Diamond Stone Golem — один раз (Pass_StarterPack)
	StarterPack = { id = 3722656338, robux = 19, once = true, money = 50000, luckPotions = 3 },
	-- Extra Storage: +50 слотів големів (атрибут ExtraSlots), багаторазовий
	ExtraStorage = { id = 3723334088, robux = 49, slots = 50 },
	-- Time Skips (SHOP → TIME SKIPS, багаторазові): одразу Money = дохід за хвилину (IncomeService.Rate) × skipMin.
	--   Чим довший скіп, тим дешевша хвилина (бонус — skipBonus). Ціни — пропозиція.
	TS5 = { id = 3723334727, robux = 15, skipMin = 5 },
	TS15 = { id = 3723334757, robux = 39, skipMin = 15 },
	TS30 = { id = 3723334918, robux = 69, skipMin = 30 },
	TS60 = { id = 3723334950, robux = 119, skipMin = 60 },
	TS120 = { id = 3723334993, robux = 199, skipMin = 120 },
	TS360 = { id = 3723335023, robux = 449, skipMin = 360 },
	TS720 = { id = 3723335051, robux = 749, skipMin = 720 },
	TS1440 = { id = 3723335078, robux = 1249, skipMin = 1440 },
	TS2880 = { id = 3723335120, robux = 1999, skipMin = 2880 },
	-- Lucky Rolls (багаторазові): +1 рол з Roll Luck ×luckRoll на ВСІХ підставках (атрибути LuckRoll10 / LuckRoll99;
	--   наступне смикання важеля бере найсильніший з наявних, RollService). Ціни — пропозиція.
	LuckRoll10 = { id = 3723335158, robux = 49, luckRoll = 10 },
	LuckRoll99 = { id = 3723335193, robux = 249, luckRoll = 99 },
	-- Exclusive Cases (SHOP → CASES, 03.11.2026; лише Robux, багаторазові): +cases кейсів класу, вибраного в магазині
	--   (ShopAction "CaseClass" → атрибут CaseBuyCls перед вікном оплати): Case_Miner / Case_Carrier / Case_Warrior; класу немає — Case_Exclusive.
	CaseX1 = { id = 3727960215, robux = 249, cases = 1 },
	CaseX5 = { id = 3727960291, robux = 999, cases = 5 },
	-- +3 слоти лотів на маркеті (03.11.2026): один раз → Pass_MarketSlots (HubConfig.marketSlots); купується у вікні My Listed Golems (MarketUI)
	MarketSlots = { id = 3727988663, robux = 79, once = true, mktSlots = 3 },
	-- Diamonds (SHOP → DIAMONDS, багаторазові, лише за Robux): +diamonds до атрибута Diamonds. Кількості — від користувача (28.10.2026),
	--   вигода рахується відносно Dia1 (diamondBonus). Ціни в R$ — пропозиція.
	Dia1 = { id = 3723335234, robux = 25, diamonds = 100 },
	Dia2 = { id = 3723335268, robux = 49, diamonds = 250 },
	Dia3 = { id = 3723335300, robux = 99, diamonds = 500 },
	Dia4 = { id = 3723335358, robux = 199, diamonds = 1250 },
	Dia5 = { id = 3723335384, robux = 399, diamonds = 2500 },
	Dia6 = { id = 3723335416, robux = 799, diamonds = 5000 },
	Dia7 = { id = 3723335448, robux = 1499, diamonds = 10000 },
	Dia8 = { id = 3723335479, robux = 2999, diamonds = 25000 },
	Dia9 = { id = 3723335507, robux = 4999, diamonds = 50000 },
}
Config.DIAMOND_PACKS = { "Dia1", "Dia2", "Dia3", "Dia4", "Dia5", "Dia6", "Dia7", "Dia8", "Dia9" }
-- вигода пакета діамантів відносно найменшого (Dia1)
function Config.diamondBonus(key: string): number
	local b, d = Config.Products.Dia1, Config.Products[key]
	return (d.diamonds / d.robux) / (b.diamonds / b.robux) - 1
end
Config.TIME_SKIPS = { "TS5", "TS15", "TS30", "TS60", "TS120", "TS360", "TS720", "TS1440", "TS2880" }
-- вигода скіпа відносно найкоротшого: ціна хвилини 5-хвилинного / ціна хвилини цього − 1
function Config.skipBonus(key: string): number
	local b, d = Config.Products.TS5, Config.Products[key]
	return (b.robux / b.skipMin) / (d.robux / d.skipMin) - 1
end

-- Fast Mutations — драбина швидкості Mutation Machine (Developer Products, лише за Robux, атрибут MutSpeedTier).
-- Ціни трохи вищі за драбину x2 Money (пропозиція). Ступінь — на гравця: діє на ОБИДВІ машини (MutationService, кнопка xN TIME на панелі).
-- Продукти створені в Creator Hub 29.10.2026 («Fast Mutations xN», іконка — годинник скіпа з бейджем xN, Managed pricing вимкнено).
Config.MUT_SPEED_TIERS = {
	{ mult = 2, robux = 19, id = 3723430618 }, { mult = 3, robux = 29, id = 3723430637 }, { mult = 4, robux = 49, id = 3723430646 },
	{ mult = 8, robux = 79, id = 3723430652 }, { mult = 16, robux = 129, id = 3723430658 }, { mult = 32, robux = 199, id = 3723430665 },
	{ mult = 64, robux = 299, id = 3723430676 }, { mult = 128, robux = 449, id = 3723430685 }, { mult = 256, robux = 649, id = 3723430694 },
	{ mult = 512, robux = 899, id = 3723430702 }, { mult = 1024, robux = 1199, id = 3723430707 },
}
-- Skip Rebirth — Developer Product (багаторазовий), 39 R$: робить наступний ребітх БЕЗ вимоги й скидання Money (29.10.2026).
-- Кнопка SKIP у вікні REBIRTH; видає RebirthService.SkipRebirth (MonetizationService.baseGrant).
Config.RebirthSkip = { robux = 39, id = 3723604112 } -- створено в Creator Hub 29.10.2026 (іконка Rebirth, Managed pricing вимкнено)

function Config.mutSpeedMult(tier: number): number
	local t = Config.MUT_SPEED_TIERS[math.floor(tier)]
	return t and t.mult or 1
end
function Config.ticketPrice(robux: number): number
	return math.ceil(robux * Config.TICKET_RATE - 1e-9)
end

-- Developer Products для ступенів x2 Money: [ступінь] = ProductId (номер ступеня = рядок MultiConfig.DONATE_TIERS).
-- Ціна ступеня — у MultiConfig.DONATE_TIERS; у Creator Hub стоїть та сама ціна (Managed pricing вимкнено).
-- Продукти створені в Creator Hub 24.10.2026 (назва «xN Money», іконка — пачка грошей).
Config.MoneyTierProducts = {
	[1] = 3721927655,  -- x2 Money
	[2] = 3721927921,  -- x3 Money
	[3] = 3721928105,  -- x4 Money
	[4] = 3721928351,  -- x8 Money
	[5] = 3721928373,  -- x16 Money
	[6] = 3721928644,  -- x32 Money
	[7] = 3721928802,  -- x64 Money
	[8] = 3721928838,  -- x128 Money
	[9] = 3721928868,  -- x256 Money
	[10] = 3721929008, -- x512 Money
	[11] = 3721929046, -- x1,024 Money
	[12] = 3721929082, -- x2,048 Money
	[13] = 3721929746, -- x4,096 Money
	[14] = 3721930194, -- x8,192 Money
	[15] = 3721930045, -- x16,384 Money
	[16] = 3721930321, -- x32,768 Money
	[17] = 3721930359, -- x65,536 Money
	[18] = 3721930510, -- x131,072 Money
	[19] = 3721930572, -- x262,144 Money
	[20] = 3721930680, -- x524,288 Money
	[21] = 3721930724, -- x1,048,576 Money
}


-- неймтеги над головою (вибір у SETTINGS → NAMETAG; SettingsService перевіряє власність, малює BillboardGui).
--   pass — геймпас, що дає тег (Pass_<pass>); c1 / c2 — перелив тексту зверху вниз. Спочатку тегу немає.
Config.TAGS = {
	{ key = "VIP", text = "VIP", pass = "VIP", c1 = "fff3a8", c2 = "ff9a1f" },
}
function Config.ownsTag(p: Instance, key: string): boolean
	for _, t in Config.TAGS do
		if t.key == key then return t.pass == nil or p:GetAttribute("Pass_" .. t.pass) == true end
	end
	return false
end

-- ===== подарунки геймпасів іншим гравцям (GiftService, кнопка з подарунком на картці геймпаса в SHOP) =====
-- Лише за Robux (за тікети не можна). Кожен геймпас — окремий Developer Product «Gift: <назва>» з ціною геймпаса.
-- 0 — продукт ще не створено: кнопка показує «Gifting is coming soon!». Roll Stand — кожен етап свій продукт (дарується наступний етап цілі).
-- Developer Products (ступені Money Boost, Lucky Rolls, бандли, тікети, скіпи, діаманти) даруються ТИМ САМИМ продуктом:
--   GiftService запам'ятовує ціль, і наступна оплата цього продукту покупцем (протягом GIFT_TTL с) іде цілі.
Config.GiftProducts = {
	-- створені в Creator Hub 29.10.2026 («Gift: <назва>», ціна геймпаса, іконка геймпаса з подарунком, Managed pricing вимкнено)
	VIP = 3723400043, Lucky = 3723400189, MutLucky = 3723400427, AutoEquip = 3723400471, FastForge = 3723400486, AutoCollect = 3723400499,
	FastRoll = 3723400547, AutoRoll = 3723400574, AutoBuy = 3723400591, RollStand1 = 3723400516, RollStand2 = 3723400528,
	AutoSell = 3723656718, AutoWorkshop = 3723656919, -- 29.10.2026
}
Config.GIFT_TTL = 600
function Config.giftPassOf(productId: number): string?
	for key, id in Config.GiftProducts do if id ~= 0 and id == productId then return key end end
	return nil
end
-- подарунки Developer Products (29.10.2026): [productId товару] = productId «Gift: …» (та сама ціна й іконка з подарунком,
-- Managed pricing вимкнено). Ступені Money Boost, Lucky Rolls, бандли, тікети, скіпи, діаманти.
Config.GiftDevProducts = {
	[3723335507] = 3723410630, [3723335479] = 3723410638, [3723335448] = 3723410645, [3723335416] = 3723410651, [3723335384] = 3723410665, -- Diamonds
	[3723335358] = 3723410673, [3723335300] = 3723410680, [3723335268] = 3723410691, [3723335234] = 3723410701,
	[3723335193] = 3723410713, [3723335158] = 3723410724, -- Lucky Roll x99 / x10
	[3723335120] = 3723410744, [3723335078] = 3723410753, [3723335051] = 3723410770, [3723335023] = 3723410870, [3723334993] = 3723410882, -- Time Skips
	[3723334950] = 3723410889, [3723334918] = 3723410898, [3723334757] = 3723410907, [3723334727] = 3723410918,
	[3723334689] = 3723410939, [3723334654] = 3723410952, [3723334627] = 3723410962, [3723334592] = 3723410980, [3723334497] = 3723410993, -- Tickets
	[3723334459] = 3723411000, [3723334428] = 3723411012, [3723334398] = 3723411023, [3723334366] = 3723411036,
	[3723334276] = 3723411048, [3723334088] = 3723411073, [3722656338] = 3723411095, -- Potion Pack, Extra Storage, Starter Pack
	[3721930724] = 3723411114, [3721930680] = 3723411123, [3721930572] = 3723411130, [3721930510] = 3723411139, [3721930359] = 3723411150, -- Money tiers
	[3721930321] = 3723411158, [3721930194] = 3723411168, [3721930045] = 3723411181, [3721929746] = 3723411193, [3721929082] = 3723411209,
	[3721929046] = 3723411227, [3721929008] = 3723411234, [3721928868] = 3723411245, [3721928838] = 3723411256, [3721928802] = 3723411266,
	[3721928644] = 3723411274, [3721928373] = 3723411283, [3721928351] = 3723411294, [3721928105] = 3723411300, [3721927921] = 3723411314,
	[3721927655] = 3723411322,
}
-- gift-продукт → productId товару (nil — не подарунок)
local giftReal = nil
function Config.giftRealOf(productId: number): number?
	if not giftReal then
		giftReal = {}
		for real, g in Config.GiftDevProducts do giftReal[g] = real end
	end
	return giftReal[productId]
end
return Config
