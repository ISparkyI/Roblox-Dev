---
tags: [model, instrument, block-style]
status: active
updated: 2026-10-27
style: "GDD - Блоковий стиль моделей"
---

# Item Prefabs

← [[Instruments]]

*Префаби предметів у руці голема: кірки й мечі.*

![[prefabs_row.jpg]]

З 27.10.2026 кірки й мечі — окремі префаби, а не групи всередині моделі голема. Моделі `Golem`, `WoodenGolem` і `ClayGolem` — без предметів. Предмет додає `GolemCatalog.applyClassItems` ([GolemCatalog](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FModules%2FGolemCatalog)): він клонує префаб і ставить його в кулак голема.

## Префаби

Усі лежать у `Workspace/PlotPrefabs` в один ряд біля ящичків, Y = 2,6. На старті сервера `PlotService.syncPrefabs` копіює їх у `ReplicatedStorage/PlotAssets`.

| Префаб | Деталей | Позиція (x, z) | Для кого | Вигляд |
| --- | --- | --- | --- | --- |
| `StonePickaxe` | 15 | −757,8; 176,8 | майнер Stone (і всі големи без своєї моделі) | колишня група `Pickaxe` зі Stone Golem: кам'яна голова на темному держаку, кінчик `Pick4` для `HitPoint` |
| `StoneSword` | 9 | −757,8; 170,8 | воїн Stone (і всі големи без своєї моделі) | новий, у кам'яному стилі (див. нижче) |
| `WoodenPickaxe` | 15 | −747,8; 176,8 | майнер Wooden | колишня група `Pickaxe` з Wooden Golem |
| `WoodenSword` | 7 | −747,8; 170,8 | воїн Wooden | колишня група `Sword` з Wooden Golem |
| `ClayPickaxe` | 15 | −737,8; 176,8 | майнер Clay | глиняна кірка ([Clay Golem](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FGolems%2FClay%20Golem%2FClay%20Golem)): держак з мокрої глини, теракотова голова з камінцем, леза із сухої глини, кінчик `Pick4` |
| `ClaySword` | 11 | −737,8; 170,8 | воїн Clay | глиняний меч: теракотове лезо зі світлою кромкою, гарда з камінцем, руків'я з кільцями |

**Атрибути префаба:** `PrefabOf` = власне ім'я, `Hand = "Fist_L"`. У деталі руків'я є `Attachment Grip` — точка хвату.

**Півот префаба** — це CFrame кулака `Fist_L` голема в позі спокою. Тому `PivotTo(кулак.CFrame)` ставить предмет точно туди, де раніше стояла група. Позиції деталей збігаються зі старими (розбіжність ≤ 0,0001 стада).

### StoneSword

Будова дерев'яного меча, перенесена в кулак Stone, того самого розміру. Матеріал Plastic з `MaterialVariant = StudsSmall` (як тіло Stone).

| Деталь | Колір |
| --- | --- |
| `SwordPommel`, `SwordVine`, `SwordGuard` | `#66717e` |
| `SwordGrip` | `#7a5233` |
| `SwordBlade`, `SwordTip` | `#8b96a3` |
| `SwordStripe` | `#a3adb8` |
| `Crystal1`, `Crystal2` (кубики 0,32 на кінцях гарди) | `#6fd3e0` |

## Як предмет потрапляє в руку

`GolemCatalog.applyClassItems(model, cls, strip?, kind?)`:

1. Видаляє старі `Pickaxe` / `Sword`.
2. Майнер отримує `pickaxe` з каталогу, воїн — `sword`, носій — нічого.
3. Голем без своєї моделі (показується моделлю Stone) бере предмети Stone.
4. Клон називається `Pickaxe` або `Sword` і масштабується під модель.
5. Клон ставиться в кулак. Кожна деталь отримує атрибут `FistRel` — CFrame відносно кулака. Модель отримує атрибути `Hand` і `Scale0`.

`GolemAnimator` пропускає блоки `group` з `GolemData`. Щокадру він ставить деталі предмета так: кулак × `FistRel` (з поправкою на масштаб). Тому предмет, доданий сервером, їде за кулаком клієнтської анімації.

Тип голема функція бере з `kind`, з атрибута `Kind` або з `GolemKind` шаблону: `Golem` = `"stone"`, `WoodenGolem` = `"wooden"`.

Хто викликає: `PlotService.spawnGolem` (плот), `GolemModel.build` (стенд печери, підставки ролу), `HeldItemService.figurine` (фігурка в руці), `ItemViewport` (слоти).

## Перевірка в Play (27.10.2026)

- **Плот:** майнер б'є руду кіркою в кліпі Mine; носій без предмета.
- **У руці:** Stone-воїн тримає кам'яний меч з кристалами, Wooden-воїн — дерев'яний. У слотах хотбара мечі теж видно.
- **Рол і стенд печери:** `GolemModel.build` дає кірку майнеру й меч воїну (Stone і Wooden), носій без предмета.
- Помилок у консолі немає.

![[miner_pickaxe_plot.jpg]]
![[stone_warrior_hold.jpg]]
![[wooden_warrior_hold.jpg]]

## Бекап

`ServerStorage/NicheBackup/ItemPrefabs_v1`: моделі `Golem` і `WoodenGolem` з груп `PlotPrefabs` і `PlotAssets` (з предметами), `GolemCatalog`, `GolemModel` до правки.

## Історія
- **27.10.2026:** окремі префаби Stone і Wooden, `StoneSword` (бекап `ItemPrefabs_v1`).
- **27.10.2026 (Clay):** `ClayPickaxe`, `ClaySword` — з `ClayGolemData` (група `Pickaxe` / `Sword`), півот = кулак `Fist_L` Clay (повернутий на ≈ 6,9° навколо Y), `Grip` у `Grip` / `SwordGrip`. Бекап — `ClayGolem_v1`.
