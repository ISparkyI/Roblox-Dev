-- Запуск систем: збереження даних (ПЕРШИМ), множники й покупки за Robux, збірка 6 ніш у печері, автоклейм плота і телепорт на спавн;
-- кузні Forge; екран Roll Upgrades і покращення ролу (підставки); лавка Sell; інвентар і хотбар, предмет у руці; плоти (зони фарму, големи на плотах).
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
require(script.Parent:WaitForChild("HeldItemService")).Start() -- предмет у руці (руда, злитки, голем-фігурка з табличкою)
require(script.Parent:WaitForChild("PlotService")).Start()
require(script.Parent:WaitForChild("MapService")).Start() -- перехід на наступну мапу (кнопка MAP N, Remotes/MapAction)
require(script.Parent:WaitForChild("CaveStandService")).Start() -- стенди в печері-сховищі: купівля, големи на стендах, секція Cave
require(script.Parent:WaitForChild("IndexService")).Start() -- колекція Index: відкриті записи големів, діаманти за перше відкриття
require(script.Parent:WaitForChild("RollService")).Start() -- рол големів на підставках ролу: шанси, результат, купівля BUY, секція Roll
require(script.Parent:WaitForChild("BackendService")).Start() -- Google Таблиця: новини Updates, коди Codes, відгуки Feedback (ServerStorage/BackendConfig)
require(script.Parent:WaitForChild("AdminService")).Start() -- адмін-панель (F2, лише ServerStorage/AdminConfig): гравці, UID, глобальні події й видачі
require(script.Parent:WaitForChild("SettingsService")).Start() -- налаштування гравця (Remotes/SettingsAction, атрибути Set_*)
require(script.Parent:WaitForChild("QuestService")).Start() -- квести: щоденні, тижневі, спеціальні (секція Quests, Remotes/QuestAction)
require(script.Parent:WaitForChild("RebirthService")).Start() -- ребітхи: Remotes/RebirthAction, скидає Money, Rebirths + 1
require(script.Parent:WaitForChild("IncomeService")).Start() -- дохід за хвилину (IncomePerMin) — статистика й тайм-скіпи
require(script.Parent:WaitForChild("StatsService")).Start() -- статистика Stat_* і лідерборди в центрі зали (OrderedDataStore)
require(script.Parent:WaitForChild("StallShopService")).Start() -- лавки Diamonds Shop / Events Shop у кінці зали (Remotes/StallShopAction)
require(script.Parent:WaitForChild("MutationService")).Start() -- Mutation Machines у центрі зали: 3 однакових → наступна мутація (секція Mutation)
require(script.Parent:WaitForChild("GroupGolemService")).Start() -- груповий Mushroom Golem на стендах у центрі зали (група 996441586)
require(script.Parent:WaitForChild("DailyService")).Start() -- щоденні нагороди (Remotes/DailyAction, скіпи днів за Robux — MonetizationService)
require(script.Parent:WaitForChild("BossPortalService")).Start() -- розклад боса (кожні 15 хв: BossAt / BossOpenUntil) і телепорт до порталу в кінці зали
