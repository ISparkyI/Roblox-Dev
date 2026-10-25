-- Запуск систем: збереження даних (ПЕРШИМ), множники й покупки за Robux, збірка 6 ніш у печері, автоклейм плота і телепорт на спавн;
-- кузні Forge; екран Roll Upgrades і покращення ролу (підставки); лавка Sell; інвентар і хотбар; плоти (зони фарму, големи на плотах).
require(script.Parent:WaitForChild("DataService")).Start()
require(script.Parent:WaitForChild("MultiService")).Start()
require(script.Parent:WaitForChild("MonetizationService")).Start()
require(script.Parent:WaitForChild("NicheService")).Start()
require(script.Parent:WaitForChild("ForgeService")).Start()
require(script.Parent:WaitForChild("RollScreenService")).Start()
require(script.Parent:WaitForChild("RollUpgradeService")).Start()
require(script.Parent:WaitForChild("SellService")).Start()
require(script.Parent:WaitForChild("InventoryService")).Start()
require(script.Parent:WaitForChild("PlotService")).Start()
