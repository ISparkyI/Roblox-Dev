# Server

← [[Merge Your Weapon - Scripts|Scripts]]

Script у `ServerScriptService`. Оновлено 2026-11-15.

| Скрипт | Що робить |
| --- | --- |
| `DataService` | сейви: DataStore `PlayerData_v1`, session lock, автосейв 60 с — GDD - Saves |
| `PlotService` | видає плот, табличка «Name's Base», спавн на плоті |
| `PlotWeaponService` | зброя на плоті: підбір / мердж дотиком (межа ребьорту), DROP, BUY WEAPON, FIGHT (найкращі N зброї, телепорт, камера), `WeaponGrant`, `WeaponSave` / `WeaponRestore`, `Found_*`, Lucky Merge |
| `MovementService` | швидкість: лобі ×2.2, дорога ×2, свій плот ÷1.5, зона 12, зачищена 24 (`Cleared_<N>`) |
| `ZoneService` | стан зон окремо по гравцях, спавн / скидання, зачистка → HP повне, відродження через 20 с, туторіальна арена |
| `MobRegistry` (ModuleScript) | моби кожного гравця без тіл: HP, позиція, урон, смерть → `MobDied` |
| `MobService` | перевірка позицій мобів (`MobSync`) і ударів зомбі; колізійні групи |
| `FightService` | автострільба зброї по своїх мобах, FX тільки власнику |
| `DropService` | гроші, геми, сундуки з мобів (атрибут `Owner`), підбір |
| `CrateService` | рюкзак сундуків, відкриття до 8 за раз, фільтр Buy Tier / межа ребьорту |
| `UpgradeService` | дерево апгрейдів: `Upg_*`, `Stat_*`, BuyTier (до межі ребьорту), PlotSlots |
| `RebirthService` | ребьорт: перевірка, скидання, `Rebirths`, `RebirthBonus` |
| `TutorialService` | кроки туторіалу (`TutorialStep`), телепорт після луту |
| `ShopService` | покупки за Robux: Developer Products (ProcessReceipt), геймпаси SHOP, x2 CASH, стенди наборів, подарунки (`GiftBuy`, `PendingGifts_v1`) |
| `PassService` | геймпас +1 Weapon Slot: перевірка при вході, Slot Stand |
| `HUDService` | BASE / HOME телепорт, тости, стартові атрибути |
| `CodeService` | коди |
| `DevCleanup` | прибирає з гри Studio-речі (`PrefabWorkshop`, `WeaponShowcase`) |
| `DevMoney` | вимкнено (тест: 1T кешу в Studio, такі гравці не зберігаються) |
