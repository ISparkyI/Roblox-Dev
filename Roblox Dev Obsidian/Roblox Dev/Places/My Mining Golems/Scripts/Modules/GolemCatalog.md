---
tags: [script, module, golems]
status: in-game
updated: 2026-10-27
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
| `GOLEMS[id]` | `name` («<слово> Golem»), `rarity`, `map`, `odds` (рол «1 до N»), `size`, `model` (ім'я в `ReplicatedStorage/PlotAssets`; є Stone Golem = `"Golem"`, Wooden Golem = `"WoodenGolem"`, Clay Golem = `"ClayGolem"`, решта `nil`), `box` (ящичок носія в `PlotAssets`: Stone — `"CarryBox"`, Wooden — `"WoodenCarryBox"`, Clay — `"ClayCarryBox"`), `pickaxe` / `sword` (префаби предметів: `StonePickaxe` / `StoneSword`, `WoodenPickaxe` / `WoodenSword`, `ClayPickaxe` / `ClaySword`), `icon` (тимчасова PNG; є у Wooden, Stone, Ironclad, Quartzling, Aurelian) + три класи: `miner { price, dmg, speed }`, `carrier { price, cap, speed }`, `warrior { price, dmg, hp, speed }`; після завантаження — ще `id` і `index` |
| `RARITIES`, `RARITY_COLOR` | 9 рідкостей Common … Exclusive і їхні кольори. **Кольори Uncommon і вище — пропозиція** (у GDD їх ще немає) |
| `MUTATIONS` | 8 мутацій: Normal, Bronze, Silver, Gold, Diamond, Void, Rainbow, Secret (`mut` = 0…7), шанс `odds` «1 до N» (1, 10, 15, 40, 150, 1 250, 5 000, 50 000) і суцільний колір `color`; з 26.10.2026 — ще `gradient` (список hex по колу), `speed` (періодів/с), `shine` (блиск, лише Secret) для анімованої назви (`Shared/MutationText`; таблиця — у [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems)). Secret — голографічний хром, колір `bfefff` (до того сталевий `b8c4d0`, ще раніше червоний `ff3b5c`); фон слота за мутацією — `Shared/MutationSlotFX`. **Кольори й шанси — пропозиція** |
| `LEGACY` | старі тестові ID → нові: `wood → wooden`, `iron → ironclad`, `gold → aurelian`, `crystal → quartzling` |
| `BASE_SPEED`, `BASE_INTERVAL`, `FALLBACK_ICON` | 8 стад/с і 1,40 с при Швидкості x1; іконка Stone Golem для големів без своєї |

**Формули** (з 27.10.2026): множник сили M = `MUTATIONS[].power` (1 / 1,25 / 1,5 / 2 / 3 / 5 / 10 / 25; Bronze 1,2 → 1,25 — 27.10.2026); ціна, шкода, HP, місткість × M, швидкість без змін; шкода < 10 — до 0,1, інше — до цілого, місткість при M > 1 ≥ базова + 1. `mult(mut)` — M, `num(n)` — підпис числа (2.4 / 50). Швидкість — один множник на все: рух `8 × Швидкість` стад/с, удар раз на `1,40 / Швидкість` с, `AnimSpeed` = Швидкість.

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
| `model(kind)` | ім'я моделі голема в `PlotAssets` (немає — `"Golem"`) |
| `box(kind)` | ім'я ящичка носія в `PlotAssets` (немає — `"CarryBox"`) |
| `poseCarry(model, data, box?)` | статична поза «несе ящичок» для моделей без аніматора (слот, фігурка): руки як у `GolemAnimator` (Carry), ящичок між кулаками; `data` — `require(GolemData)` моделі; викликати до `ScaleTo` |
| `applyClassItems(model, cls, strip?, kind?)` | предмет у руці за класом: майнер — клон префаба `pickaxe` під ім'ям `Pickaxe`, воїн — `sword` під ім'ям `Sword`, носій — нічого. Предмет стає в кулак `Fist_L`; деталі отримують `FistRel`, модель — `Hand` і `Scale0` (за ними `GolemAnimator` водить предмет). Голем без моделі бере предмети Stone. `strip` — для сумісності ([Item Prefabs](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FInstruments%2FItem%20Prefabs%2FItem%20Prefabs)) |
| `stats(kind, cls, mut)` | `{ price, speed, move, interval, size, dmg?, cap?, hp? }` з урахуванням мутації (невідомий голем — Wooden) |
| `power(kind, cls, mut)` | сила для Equip Best: майнер — шкода за секунду, носій — `cap × move`, воїн — шкода за секунду × HP |
| `statText(kind, cls, mut)` | короткий підпис для UI: `"2 dmg · x1.05"`, `"2 ore · x1.13"`, `"2 dmg · 20 HP"` |

## Хто користується

- `ItemConfig` — `GOLEMS` (назва, рідкість, іконка; і для старих ID) і `RARITY` = `RARITY_COLOR`.
- `PlotConfig` — `stats(kind, mut)` для плотів і `minerPower` / `carrierPower` через `power`.
- `ItemViewport` — `golemKey`: 3D-модель голема в слоті, якщо в каталозі є `model`.
- `InventoryService` ([Server](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FServer%2FMy%20Mining%20Golems%20-%20Server)) — міграція старих ID, мутація в `InvGolems`, тестові големи.
- `HeldItemService` ([Server](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FServer%2FMy%20Mining%20Golems%20-%20Server)) — фігурка голема в руці (`model`) і табличка статів.
- `InventoryUI` ([Client](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FClient%2FMy%20Mining%20Golems%20-%20Client)) — назва, підпис «Рідкість Клас · стат», колір рідкості; мутація — окремою міткою з градієнтом (з v18).

## Бекап

Перед появою каталогу скрипти збережено в Studio: `ServerStorage/NicheBackup/Scripts_GolemCatalog_v1`.

## Історія
- **v1 (25.10.2026):** новий модуль; `ItemConfig`, `PlotConfig`, `ItemViewport`, `InventoryService`, `PlotService`, `InventoryUI`, `PlotPlaceUI` перейшли на каталог; старі тестові големи (Wood / Iron / Gold / Crystal) замінено на Wooden / Ironclad / Aurelian / Quartzling.
- **27.10.2026:** множник Bronze `power` 1,2 → 1,25 (змінив користувач; Stone майнер Bronze: ціна 188, шкода 2,5).
- **27.10.2026:** `wooden.model = "WoodenGolem"` (з'явилась 3D-модель Wooden Golem у `PlotAssets`); бекап до правки — `ServerStorage/NicheBackup/WoodenGolem_v1`.
- **27.10.2026 (2):** поле `box` (Stone, Wooden), функції `model`, `box`, `applyClassItems`; ними користуються `PlotService`, `PlotClient`, `ItemViewport`, `HeldItemService`, `CaveStandService`. Бекап — `ServerStorage/NicheBackup/WoodenGolem_v2`. Хеш копії 967717936 (18 684 байти).
- **27.10.2026 (3):** `poseCarry` — ящичок носія в руках у слоті (`ItemViewport`) і фігурці (`HeldItemService`). Бекап — `ServerStorage/NicheBackup/StoneCarryBox_v1`. Хеш копії 525254558 (20 947 байтів).
- **27.10.2026 (4, предмети):** поля `pickaxe` / `sword` (Stone — `StonePickaxe` / `StoneSword`, Wooden — `WoodenPickaxe` / `WoodenSword`); `applyClassItems` клонує префаб предмета в кулак замість показу груп. Бекап — `ServerStorage/NicheBackup/ItemPrefabs_v1`. Хеш копії 1224903926 (23 374 байти).
- **27.10.2026 (5, Clay):** `clay.model = "ClayGolem"`, `box = "ClayCarryBox"`, `pickaxe = "ClayPickaxe"`, `sword = "ClaySword"` ([Clay Golem](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FGolems%2FClay%20Golem%2FClay%20Golem)); Clay сам потрапив у пул ролу (шанси без змін: Wooden базовий, Stone 1 до 10, Clay 1 до 15). Бекап — `ServerStorage/NicheBackup/ClayGolem_v1`. Хеш копії 1727601854 (23 474 байти).
