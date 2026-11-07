-- Запуск систем: збереження даних (ПЕРШИМ), множники й покупки за Robux, збірка 6 ніш у печері, автоклейм плота і телепорт на спавн;
-- кузні Forge; екран Roll Upgrades і покращення ролу (підставки); лавка Sell; інвентар і хотбар, предмет у руці; плоти (зони фарму, големи на плотах).
-- Режим маркету (HubConfig.isMarket — цей самий файл, опублікований як плейс Marketplace; 03.11.2026): лише дані, інвентар, покупки,
--   налаштування, статистика, адмінка й MarketServerService (спавн, облік сервера); печера, ніші, плоти тощо не стартують.
--   Головний плейс натомість прибирає Workspace/Marketplace (на головних серверах він не потрібен).
local HubCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("HubConfig"))
-- 06.11.2026: об'єкти лише для Studio (атрибут StudioOnly: Workspace/ThumbStudio — полігон превʼюшок, тестові моделі поруч) —
--   існують тільки в режимі редагування Studio. Будь-який запущений сервер (живий і Play-тест у Studio) видаляє їх першим ділом,
--   до входу гравців — клієнти їх ніколи не отримують.
for _, c in workspace:GetChildren() do
	if c:GetAttribute("StudioOnly") == true then c:Destroy() end
end
if HubCfg.isMarket() then
	require(script.Parent:WaitForChild("DataService")).Start()
	require(script.Parent:WaitForChild("GolemRegistry")).Start()
	require(script.Parent:WaitForChild("MultiService")).Start()
	require(script.Parent:WaitForChild("MonetizationService")).Start()
	require(script.Parent:WaitForChild("GiftService")).Start()
	require(script.Parent:WaitForChild("InventoryService")).Start()
	require(script.Parent:WaitForChild("HeldItemService")).Start()
	require(script.Parent:WaitForChild("IndexService")).Start()
	require(script.Parent:WaitForChild("BackendService")).Start() -- 06.11.2026: на маркеті теж Updates / Codes / Feedback (було «No news yet»)
	require(script.Parent:WaitForChild("AdminService")).Start()
	require(script.Parent:WaitForChild("SettingsService")).Start()
	require(script.Parent:WaitForChild("IncomeService")).Start()
	require(script.Parent:WaitForChild("StatsService")).Start()
	require(script.Parent:WaitForChild("DailyService")).Start()
	require(script.Parent:WaitForChild("MarketServerService")).Start()
	require(script.Parent:WaitForChild("MarketExclusiveService")).Start() -- 05.11.2026: стенди ексклюзивів (Cyborg / Lamp Miner / Spartan)
	require(script.Parent:WaitForChild("OfflineService")).Start({ grant = false }) -- 04.11.2026: лише LastSeen (час на маркеті — не офлайн)
	return
end
local mk = workspace:FindFirstChild("Marketplace")
if mk then mk:Destroy() end
require(script.Parent:WaitForChild("DataService")).Start()
require(script.Parent:WaitForChild("GolemRegistry")).Start() -- UID големів, глобальний індекс цінних, журнал подій
require(script.Parent:WaitForChild("MultiService")).Start()
require(script.Parent:WaitForChild("MonetizationService")).Start()
require(script.Parent:WaitForChild("GiftService")).Start() -- подарунки геймпасів іншим гравцям за Robux (Remotes/GiftAction)
require(script.Parent:WaitForChild("NicheService")).Start()
require(script.Parent:WaitForChild("ForgeService")).Start()
require(script.Parent:WaitForChild("RollScreenService")).Start()
require(script.Parent:WaitForChild("RollUpgradeService")).Start()
require(script.Parent:WaitForChild("SellService")).Start()
require(script.Parent:WaitForChild("InventoryService")).Start()
require(script.Parent:WaitForChild("MarketLotService")).StartMain() -- виставлені на маркеті големи: на плоті / видалені — знімаються (секція MarketLots)
require(script.Parent:WaitForChild("GolemGiftService")).Start() -- 05.11.2026: подарунок голема іншому гравцю в лобі (Remotes/GolemGift)
require(script.Parent:WaitForChild("HeldItemService")).Start() -- предмет у руці (руда, злитки, голем-фігурка з табличкою)
require(script.Parent:WaitForChild("PlotService")).Start()
require(script.Parent:WaitForChild("MapService")).Start() -- перехід на наступну мапу (кнопка MAP N, Remotes/MapAction)
require(script.Parent:WaitForChild("CaveStandService")).Start() -- стенди в печері-сховищі: купівля, големи на стендах, секція Cave
require(script.Parent:WaitForChild("IndexService")).Start() -- колекція Index: відкриті записи големів, діаманти за перше відкриття
require(script.Parent:WaitForChild("CaseService")).Start() -- кейси з інвентаря: Exclusive Case → ексклюзивний голем (Remotes/CaseAction, CaseResult)
require(script.Parent:WaitForChild("RollService")).Start() -- рол големів на підставках ролу: шанси, результат, купівля BUY, секція Roll
require(script.Parent:WaitForChild("BackendService")).Start() -- Google Таблиця: новини Updates, коди Codes, відгуки Feedback (ServerStorage/BackendConfig)
require(script.Parent:WaitForChild("AdminService")).Start() -- адмін-панель (F2, лише ServerStorage/AdminConfig): гравці, UID, глобальні події й видачі
require(script.Parent:WaitForChild("SettingsService")).Start() -- налаштування гравця (Remotes/SettingsAction, атрибути Set_*)
require(script.Parent:WaitForChild("QuestService")).Start() -- квести: щоденні, тижневі, спеціальні (секція Quests, Remotes/QuestAction)
require(script.Parent:WaitForChild("RebirthService")).Start() -- ребітхи: Remotes/RebirthAction, скидає Money, Rebirths + 1
require(script.Parent:WaitForChild("IncomeService")).Start() -- дохід за хвилину (IncomePerMin) — статистика й тайм-скіпи
require(script.Parent:WaitForChild("TutorialService")).Start() -- 05.11.2026: інтерактивне навчання новачка (Remotes/TutorialAction, TutorialClient)
require(script.Parent:WaitForChild("OfflineService")).Start() -- 04.11.2026: офлайн-дохід (до 24 год, вікно OfflineWindow, Remotes/OfflineAction)
require(script.Parent:WaitForChild("StatsService")).Start() -- статистика Stat_* і лідерборди в центрі зали (OrderedDataStore)
require(script.Parent:WaitForChild("StallShopService")).Start() -- лавки Diamonds Shop / Events Shop у кінці зали (Remotes/StallShopAction)
require(script.Parent:WaitForChild("MutationService")).Start() -- Mutation Machines у центрі зали: 3 однакових → наступна мутація (секція Mutation)
require(script.Parent:WaitForChild("GroupGolemService")).Start() -- груповий Mushroom Golem на стендах у центрі зали (група 996441586)
require(script.Parent:WaitForChild("DailyService")).Start() -- щоденні нагороди (Remotes/DailyAction, скіпи днів за Robux — MonetizationService)
require(script.Parent:WaitForChild("BossPortalService")).Start() -- розклад боса (кожні 15 хв: BossAt / BossOpenUntil) і телепорт до порталу в кінці зали
require(script.Parent:WaitForChild("BossFightService")).Start() -- 04.11.2026: бій з босом (реєстрація, арена, лут) — Plan - Boss Fight System
