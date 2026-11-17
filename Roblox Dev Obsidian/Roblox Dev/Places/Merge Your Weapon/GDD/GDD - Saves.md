---
tags: [gdd, saves]
status: done
updated: 2026-11-15
---

# GDD - Saves

← [[Merge Your Weapon - GDD|GDD]]

Прогрес гравця зберігається в DataStore `PlayerData_v1` (ключ `u_<UserId>`). Скрипт: `ServerScriptService.DataService`.

## Що зберігається
| Що | Атрибути |
| --- | --- |
| Гроші | Cash, Gems |
| Ребьорт | Rebirths, RebirthBonus, Reached_* (умова ребьорту в поточному забігу) |
| Апгрейди | Upg_* (Stat_*, BuyTier, PlotSlots перераховуються самі) |
| Індекс зброї | Found_* |
| Рюкзак | Crates_* (сундуки по зонах) |
| Магазин | PackStage, Pass_*, PassWeaponSlot, CashMultiplier (x2 CASH) |
| Туторіал | TutorialStep (`nil` = пройдено) |
| Розхідники | Supply_* (скільки є), SStock_* (запас у магазині цього циклу), SStockCycle, SupplySlot1..3 |
| Коди | Code_* |
| Плот | вся зброя: тір + місце на полі (зброя в бою теж — вона лишається в плоті) |

Не зберігається: налаштування (поки локальні на клієнті), поточна зона, дропи на землі.

**Окремий DataStore `PendingGifts_v1`** (`u_<UserId>`): подарунки гравцю, який був не на сервері, коли їх купили. Видаються після `DataLoaded` і стираються (`ShopService`).

## Коли
- Вхід — завантаження. До кінця завантаження нічого не пишеться (`DataLoaded = true` після).
- Кожні 60 с, при виході, при вимкненні сервера (BindToClose).

## Захист
- Session lock: дані «тримає» один сервер. Перехід на інший сервер чекає збереження старого (до ~20 с), завислий lock (> 90 с) забирається.
- Ретраї при помилках Roblox. Не вдалося завантажити → kick «rejoin» (щоб не затерти сейв пустим).
- Зброя посеред мерджу зберігається як результат мерджу.
- Гравці з DevMoney ніколи не зберігаються. DevMoney вимкнено.
- Повний вайп: змінити `STORE` на `PlayerData_v2`.
- Новий гравець: `Cash = 0`, `TutorialStep = buy1`.

## Тест
Team Test (DataStore працює). У звичайному Play без «Enable Studio Access to API Services» гра йде без сейвів (warning у консолі).

## План
- Офлайн-заробіток (Roadmap, п. 5) — варіант ще не вибраний.
- Нові поля: `GroupReward` (нагорода за групу видана), прапорці бейджів не потрібні (BadgeService сам пам'ятає).
