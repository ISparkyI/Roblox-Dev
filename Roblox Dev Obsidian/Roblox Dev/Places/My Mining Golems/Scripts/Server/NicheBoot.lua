-- Запуск систем: збереження даних (ПЕРШИМ), множники й покупки за Robux, збірка 6 ніш у печері, автоклейм плота і телепорт на спавн;
-- кузні Forge; екран Roll Upgrades і покращення ролу (підставки); лавка Sell; інвентар і хотбар, предмет у руці; плоти (зони фарму, големи на плотах).
require(script.Parent:WaitForChild("DataService")).Start()
require(script.Parent:WaitForChild("GolemRegistry")).Start() -- UID големів, глобальний індекс цінних, журнал подій
require(script.Parent:WaitForChild("MultiService")).Start()
require(script.Parent:WaitForChild("MonetizationService")).Start()
require(script.Parent:WaitForChild("NicheService")).Start()
require(script.Parent:WaitForChild("ForgeService")).Start()
require(script.Parent:WaitForChild("RollScreenService")).Start()
require(script.Parent:WaitForChild("RollUpgradeService")).Start()
require(script.Parent:WaitForChild("SellService")).Start()
require(script.Parent:WaitForChild("InventoryService")).Start()
require(script.Parent:WaitForChild("HeldItemService")).Start() -- предмет у руці (руда, злитки, голем-фігурка з табличкою)
require(script.Parent:WaitForChild("PlotService")).Start()
require(script.Parent:WaitForChild("CaveStandService")).Start() -- стенди в печері-сховищі: купівля, големи на стендах, секція Cave
require(script.Parent:WaitForChild("IndexService")).Start() -- колекція Index: відкриті записи големів, діаманти за перше відкриття
require(script.Parent:WaitForChild("RollService")).Start() -- рол големів на підставках ролу: шанси, результат, купівля BUY, секція Roll
require(script.Parent:WaitForChild("BackendService")).Start() -- Google Таблиця: новини Updates, коди Codes, відгуки Feedback (ServerStorage/BackendConfig)
require(script.Parent:WaitForChild("AdminService")).Start() -- адмін-панель (F2, лише ServerStorage/AdminConfig): гравці, UID, глобальні події й видачі
