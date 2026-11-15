---
tags: [gdd, place]
status: active
updated: 2026-11-15
---

# GDD

← [[Merge Your Weapon]]

Загальний дизайн гри **Merge Your Weapon**: концепція, цикл, таблиця систем. Правила й числа кожної системи — у своїй нотатці `GDD - <Система>`. **TBD** — ще не вирішено.

> [!summary] Коротко
> Гравець купує зброю на своєму плоті, мерджить дві однакові в сильнішу і йде в забіг по зонах із зомбі. Найкраща зброя літає навколо й стріляє сама, гравець бігає, ухиляється, спринтує, збирає гроші, геми й сундуки. Потім купує ще зброю, мерджить далі, качає апгрейди і робить ребьорт за постійний бонус до грошей.

## Концепція
- **Жанр:** merge + idle-шутер із забігами (Simulator / Tycoon-лайк).
- **Фантазія гравця:** «з палки до найкрутішої зброї» — кожен мердж робить мене сильнішим.
- **Стиль:** блоковий стиль студії. **Аудиторія:** 8–14, ПК і мобільні (рух простий, стрільба автоматична).
- **Сервер:** 6 гравців, у кожного свій плот і своя гра (див. Multiplayer).

## Системи
| Нотатка | Що там | Стан |
| --- | --- | --- |
| [[Places/Merge Your Weapon/GDD/GDD - Spawn and Zones\|Spawn and Zones]] | Spawn з 6 плотами, зони-арени, проходи, відродження зомбі | Zone 1 готова |
| [[Places/Merge Your Weapon/GDD/GDD - Weapons and Merge\|Weapons and Merge]] | 35 тірів, мердж, плот, слоти в бою, покупка, Index | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Fight\|Fight]] | автострільба, HP, спринт і стаміна, камера, цифри урону, атаки зброї | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Mobs and Drops\|Mobs and Drops]] | зомбі, їхні атаки, дроп грошей, гемів, сундуків | Zone 1 |
| [[Places/Merge Your Weapon/GDD/GDD - Crates\|Crates]] | сундуки, лут, відкриття до 8 за раз | Zone 1 |
| [[Places/Merge Your Weapon/GDD/GDD - Upgrades\|Upgrades]] | дерево апгрейдів із шестикутників | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Rebirth\|Rebirth]] | умови, скидання, +100%, обмеження мерджу | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Balance\|Balance]] | урон, ціни, HP і гроші зон 1–10, симуляція | застосовано |
| [[Places/Merge Your Weapon/GDD/GDD - Shop and Passes\|Shop and Passes]] | монетизація: геймпаси, паки, набори зброї, x2 CASH, подарунки | у грі, ID створені |
| [[Places/Merge Your Weapon/GDD/GDD - Tutorial\|Tutorial]] | туторіал першого входу | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Multiplayer\|Multiplayer]] | що спільне, що своє; локальні моби | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Saves\|Saves]] | DataStore, що зберігається | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - HUD and Windows\|HUD and Windows]] | HUD, вікна, інвентар | у грі |
| [[Places/Merge Your Weapon/GDD/GDD - Item Shop\|Item Shop]] | магазин гранат / аптечок за Gems | чернетка |

## Ігровий цикл
1. **База:** купити зброю (BUY WEAPON) і змерджити однакові.
2. **FIGHT:** найкращі N зброї (N = слоти) злітають з плоту, телепорт на старт Zone 1.
3. **Забіг:** зачищати зони по черзі. Зброя стріляє сама, гравець рухається, спринтує, збирає дроп. Зачистив зону — HP повне, прохід далі відкритий, через 20 с зомбі відроджуються.
4. **Повернення:** RETURN / пішки / смерть — на плот. Усе підібране вже твоє (гроші й геми в балансі, сундуки в рюкзаку).
5. **Прогрес:** відкрити сундуки, купити апгрейди, змерджити далі → новий забіг, уже глибше.
6. **Rebirth:** зброя тіру 9 / 14 / 19 / 24 / 29 / 34 → скинути все за +100% до грошей. Без ребьорту мердж вище цього тіру закритий.

## Сутності
| Клас | Що | Де деталі |
| --- | --- | --- |
| Weapons | 35 тірів: Stick → … → Titan Cannon | Weapons and Merge, [Weapons](obsidian://open?vault=Roblox%20Dev&file=Places%2FMerge%20Your%20Weapon%2F3D%20Models%2FWeapons%2FWeapons) |
| Mobs | зомбі, у кожної зони свої (Zone 1 — фермер і бос з вилами) | Mobs and Drops |
| Crates | свій сундук у кожної зони | Crates |
| Drops | купюри, геми (2D), сундуки (3D) | Mobs and Drops |
| Interactive Objects | плоти, стенди наборів зброї, стенд слота, проходи зон | [Interactive Objects](obsidian://open?vault=Roblox%20Dev&file=Places%2FMerge%20Your%20Weapon%2FInteractive%20Objects%2FInteractive%20Objects) |

## Економіка
- **Гроші ($):** з мобів і сундуків; на зброю й апгрейди. **Gems:** рідко з мобів і сундуків; на Item Shop.
- **Множник грошей:** `(1 + ребьорт% + CASH-апгрейд%) × x2 CASH`. Ребьорт і апгрейд додаються, тільки x2 CASH (Robux) множить.
- Усі числа — `GDD - Balance`.

## Сцена в Roblox Studio
| Що | Де |
| --- | --- |
| Spawn і плоти | `Workspace/Spawn/Plots/Plot1..6` (поле, стенди, стенд слота) |
| Зони | `Workspace/Zones/Zone<N>` (Ground, Walls, Decor, Gates, Markers) |
| Зброя | `ReplicatedStorage/Weapons/MYW_<Name>`; вітрина `Workspace/PrefabWorkshop` (тільки Studio) |
| Моби | `ReplicatedStorage/MobModels` (тіла малює клієнт), звуки `MobSounds` |
| Конфіги | `ReplicatedStorage`: WeaponConfig, WeaponAttacks, MobConfig, CrateConfig, UpgradeConfig, RebirthConfig, ShopConfig, PassConfig, CashBoostConfig |
| Скрипти | [Scripts](obsidian://open?vault=Roblox%20Dev&file=Places%2FMerge%20Your%20Weapon%2FScripts%2FMerge%20Your%20Weapon%20-%20Scripts) |

## Технічні правила
- **Сервер — джерело правди:** покупка, мердж, урон, HP, дроп, підбір, сундуки, апгрейди, ребьорт, покупки за Robux. Клієнт показує й надсилає запити, сервер перевіряє.
- Усі числа — у конфіг-модулях, баланс правиться без коду.
- **Швидкість** (`MovementService`): лобі 16 × 2.2, дорога ще ×2, свій плот ÷1.5; у зоні 12, у зачищеній 24.
- **Камера:** `CameraMaxZoomDistance = 64`.
- Тексти UI — під автопереклад Roblox (числа окремими `TextLabel` з `AutoLocalize = false`).

## Референси
![[MYW ref - map scheme.png]]
![[MYW ref - spawn road.png]]

## Стан
- [x] Концепція, системи, 35 тірів з моделями (2026-11-13…14)
- [x] Бій, атаки й анімації зброї, моби Zone 1, дроп, сундуки (2026-11-14)
- [x] Апгрейди, ребьорт, Index, коди, налаштування (2026-11-14)
- [x] Баланс світу 1 (10 зон) застосовано, ціни округлені (2026-11-15)
- [x] Сейви, мультиплеєр (локальні моби), туторіал (2026-11-15)
- [x] Монетизація: 4 геймпаси, 23 Developer Products, x2 CASH, подарунки (2026-11-15)
- [ ] Зони 2–10: макети, зомбі, сундуки
- [ ] Item Shop
- [ ] Рядки плейсу в таблиці «Що Roblox передає плейсам»

## Відкриті питання
- Теми і зомбі зон 6–10.
- Ребьорти після 6-го і що далі після світу 1.
