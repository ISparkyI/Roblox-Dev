---
tags: [scripts, server]
updated: 2026-11-16
---

# Server

← [[Merge Your Weapon - Scripts|Scripts]]

Script / ModuleScript у `ServerScriptService` (30 шт.). Список знято зі Studio 2026-11-16.

| Скрипт | Що робить | Рядків |
| --- | --- | --- |
| `AdminService` | адмін-панель (F2): ролі owner / admin / mod, кік, бан, телепорт, видача, івенти, логи, сервери — [[Places/Merge Your Weapon/GDD - Admin Panel\|GDD - Admin Panel]] | 772 |
| `AFKFarmService` | AFK FARM (геймпас Auto Fight): сам ходить у бій і назад | 102 |
| `AnalyticsFunnels` | воронки Creator Hub: туторіал, покупки, Rebirths | 137 |
| `BadgeService` | бейджі з `BadgeConfig` (id 0 — пропуск) | 54 |
| `CodeService` | коди: зараз лише `FREE` (Bow T4 + $20) | 33 |
| `CrateService` | рюкзак сундуків `Crates_<зона>`, відкриття до 8 одночасно | 165 |
| `DataService` | сейви DataStore, session lock, автосейв 60 с; префікси `Upg_ Found_ Reached_ Crates_ Code_ Pass_ Supply_ SStock_ Set_` | 172 |
| `DevCleanup` | прибирає з гри Studio-речі (`PrefabWorkshop`, `SupplyWorkshop`) | 11 |
| `DropService` | гроші, геми, сундуки з мобів; множники івентів адмінки | 184 |
| `Econ (Module)` | економічна аналітика: `Econ.add(p, cur, delta, txType, sku)`, відправка раз на хвилину | 46 |
| `FightService` | автострільба зброї з бойових слотів по своїх мобах | 202 |
| `FriendBonusService` | +% кешу за кожного друга на сервері | 33 |
| `HUDService` | BASE / HOME телепорт, тости, стартові атрибути | 61 |
| `MobRegistry (Module)` | моби кожного гравця без тіл: HP, позиція, смерть | 93 |
| `MobService` | перевірка позицій і ударів зомбі, отрута / холод / горіння | 139 |
| `MovementService` | швидкість: лобі ×2.2, дорога ×2, плот ÷1.5, зона 12, зачищена 24 | 146 |
| `OfflineService` | офлайн-заробіток при вході (`OfflineConfig`) | 44 |
| `PassService` | геймпаси (`PassConfig`), Slot Stand | 65 |
| `PlotService` | видає плот, табличка «Name's Base», спавн | 130 |
| `PlotStandService` | таблички плоту: AUTO BUY / AUTO MERGE / група | 77 |
| `PlotWeaponService` | зброя на плоті: підбір, мердж, DROP, BUY WEAPON, FIGHT, Lucky Merge | 885 |
| `RebirthService` | ребьорт: перевірка, скидання, бонус | 49 |
| `SettingsService` | зберігає налаштування (MUSIC / SFX / NAMES / FX → `Set_*`) | 21 |
| `ShopService` | покупки за Robux: продукти, геймпаси, x2 CASH, стенди наборів, подарунки | 366 |
| `StudioTestKit` | тільки Studio: без туторіалу, 10 000 кешу, 100 гемів | 18 |
| `SupplyService` | 3 слоти розхідників, використання в бою, ефекти | 265 |
| `SupplyShopService` | SUPPLY SHOP: рестік кожні 30 хв, купівля за Gems | 71 |
| `TutorialService` | кроки туторіалу (`TutorialStep`) | 100 |
| `UpgradeService` | дерево апгрейдів `Upg_*` | 63 |
| `ZoneService` | зони окремо по гравцях: спавн, зачистка, відродження | 236 |
