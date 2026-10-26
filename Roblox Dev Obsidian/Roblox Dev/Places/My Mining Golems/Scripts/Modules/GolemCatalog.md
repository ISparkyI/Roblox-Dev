---
tags: [script, module, golems]
status: in-game
updated: 2026-10-25
---

# GolemCatalog

← [[My Mining Golems - Modules|Modules]]

`ReplicatedStorage/Shared/GolemCatalog` (ModuleScript, спільний для сервера й клієнта). Копія коду — `GolemCatalog.lua` у цій папці.

Каталог големів у коді: **24 големи × 3 класи** (майнер / носій / воїн), рідкості, мутації та формули характеристик. Одне місце, звідки всі скрипти беруть назву, рідкість, іконку й стати голема.

## Джерело даних

Значення Normal — з таблиць GDD: [Golem Stats - Miner](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Miner), [Golem Stats - Carrier](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Carrier), [Golem Stats - Warrior](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Warrior); формули мутацій і швидкості — [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems). **Змінив таблицю в GDD — зміни й рядок тут** (голем у коді = три рядки GDD з тим самим ID).

## Що всередині

| Поле | Що |
| --- | --- |
| `ORDER` | 24 ID по порядку каталогу: `wooden`, `stone`, `clay`, `gravel`, `mossback`, `copperhead`, `flint`, `rustbolt`, `granite`, `lantern`, `ironclad`, `quartzling`, `tinker`, `silverjaw`, `geode`, `amethyst`, `sapphire`, `obsidian`, `magmaheart`, `ruby`, `frostforged`, `platinum`, `aurelian`, `astral` |
| `GOLEMS[id]` | `name` («<слово> Golem»), `rarity`, `map`, `odds` (рол «1 до N»), `size`, `model` (ім'я в `ReplicatedStorage/PlotAssets`; поки є лише Stone Golem = `"Golem"`, решта `nil`), `icon` (тимчасова PNG; є у Wooden, Stone, Ironclad, Quartzling, Aurelian) + три класи: `miner { price, dmg, speed }`, `carrier { price, cap, speed }`, `warrior { price, dmg, hp, speed }`; після завантаження — ще `id` і `index` |
| `RARITIES`, `RARITY_COLOR` | 9 рідкостей Common … Exclusive і їхні кольори. **Кольори Uncommon і вище — пропозиція** (у GDD їх ще немає) |
| `MUTATIONS` | 8 мутацій: Normal, Bronze, Silver, Gold, Diamond, Void, Rainbow, Secret (`mut` = 0…7), шанс `odds` «1 до N» (1, 10, 15, 40, 150, 1 250, 5 000, 50 000) і колір. **Кольори й шанси — пропозиція** |
| `LEGACY` | старі тестові ID → нові: `wood → wooden`, `iron → ironclad`, `gold → aurelian`, `crystal → quartzling` |
| `BASE_SPEED`, `BASE_INTERVAL`, `FALLBACK_ICON` | 8 стад/с і 1,40 с при Швидкості x1; іконка Stone Golem для големів без своєї |

**Формули** (мутація `k`, Normal = 0): ціна ×1,5^k, шкода й HP ×1,35^k, місткість ×1,25^k (вниз, мінімум 1), Швидкість ×1,05^k. Швидкість — один множник на все: рух `8 × Швидкість` стад/с, удар раз на `1,40 / Швидкість` с, `AnimSpeed` = Швидкість.

## API

| Функція | Повертає |
| --- | --- |
| `id(kind)` | нормалізований ID (зі старих — через `LEGACY`) або `nil` |
| `get(kind)` | запис голема з `GOLEMS` або `nil` |
| `cls(cls)` | `"carrier"` / `"warrior"` або `"miner"` (за замовчуванням) |
| `mut(m)` | номер мутації 0…7 (ціле, обрізане) |
| `mutation(m)` | запис мутації `{ key, odds, color }` |
| `rarityColor(r)` | колір рідкості (невідома — Common) |
| `icon(kind)` | іконка голема або іконка Stone |
| `stats(kind, cls, mut)` | `{ price, speed, move, interval, size, dmg?, cap?, hp? }` з урахуванням мутації (невідомий голем — Wooden) |
| `power(kind, cls, mut)` | сила для Equip Best: майнер — шкода за секунду, носій — `cap × move`, воїн — шкода за секунду × HP |
| `statText(kind, cls, mut)` | короткий підпис для UI: `"2 dmg · x1.05"`, `"2 ore · x1.13"`, `"2 dmg · 20 HP"` |

## Хто користується

- `ItemConfig` — `GOLEMS` (назва, рідкість, іконка; і для старих ID) і `RARITY` = `RARITY_COLOR`.
- `PlotConfig` — `stats(kind, mut)` для плотів і `minerPower` / `carrierPower` через `power`.
- `ItemViewport` — `golemKey`: 3D-модель голема в слоті, якщо в каталозі є `model`.
- `InventoryService` ([Server](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FServer%2FMy%20Mining%20Golems%20-%20Server)) — міграція старих ID, мутація в `InvGolems`, тестові големи.
- `HeldItemService` ([Server](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FServer%2FMy%20Mining%20Golems%20-%20Server)) — фігурка голема в руці (`model`) і табличка статів.
- `InventoryUI` ([Client](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FClient%2FMy%20Mining%20Golems%20-%20Client)) — назва, підпис «Мутація Рідкість Клас · стат», колір рідкості.

## Бекап

Перед появою каталогу скрипти збережено в Studio: `ServerStorage/NicheBackup/Scripts_GolemCatalog_v1`.

## Історія
- **v1 (25.10.2026):** новий модуль; `ItemConfig`, `PlotConfig`, `ItemViewport`, `InventoryService`, `PlotService`, `InventoryUI`, `PlotPlaceUI` перейшли на каталог; старі тестові големи (Wood / Iron / Gold / Crystal) замінено на Wooden / Ironclad / Aurelian / Quartzling.
