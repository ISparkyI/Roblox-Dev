---
tags: [model, golem, block-style]
status: in-game
version: 1
updated: 2026-10-27
style: "GDD - Блоковий стиль моделей"
---

# Clay Golem

← [[Golems]]

*Глиняний голем.* Третій голем каталогу (ID `clay`, Common, рол 1 до 15, `size = 1.05`). Важкий, повільний і добродушний трудяга з мокрої теракотової глини. Модель погодив користувач 27.10.2026.

![[clay_front.png]]

Концепт-лист і веб-макет (`Preview/clay_golem.html` — обертання, класи, анімації Idle / Walk / Mine):

![[clay_golem_concept.png]]

| Параметр | Значення |
| --- | --- |
| Блоків | 67 (тіло), з них повернутих 49 |
| Трикутників | 804 |
| Кольорів | 6 у тілі (+ суха глина лише в предметах) |
| Правило 0,1 | виправлено 27 граней, 0 збігів |
| Розмір (од. моделі) | 15,08 × 13,81 × 6,74 |
| Розмір (стади) | 7,54 × 6,91 × 3,37; з `size 1.05` — 7,92 × 7,25 × 3,54 |
| Кістки | 21 (як у Stone + рот з Wooden: `Mouth`, `MouthCorner_R`, `MouthCorner_L`) |
| Точка опори | центр X/Z, низ на Y = 0 |

## Маси
1. **Ноги:** короткі й товсті, пласкі стопи з «носками», патьоки мокрої глини на гомілках, камінці на колінах.
2. **Таз** з мокрої глини.
3. **Корпус:** кремезний торс, пузо вперед (два шари), широкі обвислі плечі. Спереду відбиток долоні й тріщини, на спині плита зі слідами пальців і камінці.
4. **Голова:** маленька, з «защипом» і грудкою зверху, щелепа.
5. **Руки:** плече з наплічником і патьоком, передпліччя з тріщиною на лікті, великий кулак з кісточками й великим пальцем.

## Палітра
| Роль | HEX | Де застосовується |
| --- | --- | --- |
| Теракота (основний) | `#c4714a` | тіло, голова, руки, ноги, стінки ящика |
| Мокра глина | `#8c4a33` | стопи, таз, кулаки, патьоки, тріщини, відбиток долоні |
| Камінці | `#a39e94` | камінці на тілі, у кірці, мечі й ящику |
| Суха глина (лише предмети) | `#e3ab80` | леза кірки, кромка меча, обідок ящика |
| Світлий (спільний) | `#f1f5f8` | білки очей, блиск |
| Темний (спільний) | `#1c2836` | зіниці, рот |
| Щічки (спільний) | `#f2a0b4` | щічки |

## Стиль для референсу
З веб-макета (`Preview/clay_golem.html`):

| Поле | Опис |
| --- | --- |
| Матеріал / тема | мокра теракотова глина з гончарні; важкий, повільний, добродушний трудяга |
| Силует | кремезний і приземкуватий: пузо вперед, широкі обвислі плечі, короткі товсті ноги з пласкими стопами, маленька голова з «защипом» зверху |
| Фірмові деталі | відбиток долоні на пузі, сліди пальців на спині, патьоки мокрої глини з плечей і гомілок, втиснуті камінці, тріщини |
| Обличчя | великі очі, брови трохи вгору до центру, рожеві щічки, проста усмішка — спокійний і лагідний |
| Меч | лезо з випаленої теракоти зі світлими краями, дол «проведений пальцем», гарда — валик мокрої глини з камінцем, руків'я з глиняними кільцями |
| Кірка | голова з теракоти з камінцем, леза зі світлої випаленої глини з відбитком пальця, держак — скачаний валик мокрої глини |
| Ящик | глибоке глиняне корито: товсті стінки, світлий загорнутий обідок, вушка-ручки, відбитки пальців і камінець спереду; руду видно зверху |
| Не робити | без гончарного круга й округлих форм, без глазурі й блиску, без дрібних тріщин-текстур — лише блоки |

![[clay_34.png]]
![[clay_back.png]]
![[clay_side.png]]
![[clay_items.png]]

## Roblox
Модель зібрана з `Part` у тому ж форматі, що й [Wooden Golem](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FGolems%2FWooden%20Golem%2FWooden%20Golem): `Root` + 67 деталей тіла з іменами блоків (атрибут `Bone`), `GolemData` (модуль `ClayGolemData`: палітра, 21 кістка, 93 блоки — 67 тіла + 15 кірки `group = "Pickaxe"` + 11 меча `group = "Sword"`; групи аніматор пропускає), копія `GolemAnimator` (той самий код, що в Stone і Wooden), `MineTarget` (ObjectValue).

| Що | Де | Деталей |
| --- | --- | --- |
| Префаб голема | `Workspace/PlotPrefabs/ClayGolem` (x −737,8; z 198,8 — у ряду після `Golem` і `WoodenGolem`); атрибути `PrefabOf = "ClayGolem"`, `GolemKind = "clay"`, `Version = "v1"` | 68: `Root` + 67 тіла (без предметів) |
| Шаблон | `ReplicatedStorage/PlotAssets/ClayGolem` — на старті сервера копіює `PlotService.syncPrefabs` | 68 |
| Кірка | `Workspace/PlotPrefabs/ClayPickaxe` (x −737,8; z 176,8), `Hand = "Fist_L"`, `Grip` у деталі `Grip`, кінчик `Pick4` для `HitPoint` | 15 |
| Меч | `Workspace/PlotPrefabs/ClaySword` (x −737,8; z 170,8), `Grip` у `SwordGrip` | 11 |
| Ящичок носія | `Workspace/PlotPrefabs/ClayCarryBox` (x −737,8; z 186,8), будова як `CarryBox` v8 ([Carrier Crate](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FInstruments%2FCarrier%20Crate%2FCarrier%20Crate)) | 18 + 10 `Load` |
| Каталог | `GolemCatalog.GOLEMS.clay`: `model = "ClayGolem"`, `box = "ClayCarryBox"`, `pickaxe = "ClayPickaxe"`, `sword = "ClaySword"` ([GolemCatalog](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FModules%2FGolemCatalog)) | — |

- Масштаб: 1 од. моделі = 0,5 стада. `size = 1.05` застосовують `GolemModel.build` (стенд печери, підставки ролу) і з 27.10.2026 плот (`PlotService.spawnGolem`, навколо `Root` — ноги на підлозі; майнер стає на `REACH × size` від руди, ящичок носія того ж масштабу) — [Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FPlots%2FPlots).
- Усі деталі `Plastic` + `MaterialVariant = StudsSmall` (як у Stone і Wooden); `Root` прозорий. `Anchored`, `CanCollide / CanQuery / CanTouch = false`.
- Розмітка деталей: `Root.CFrame × Ry(180°) × (позиція з GolemData × 0,5)` — так само, як у Wooden.
- Предмети — окремі префаби ([Item Prefabs](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FInstruments%2FItem%20Prefabs%2FItem%20Prefabs)); у моделі голема їх немає, `GolemCatalog.applyClassItems` клонує їх у кулак `Fist_L`. Півот префаба = кулак `Fist_L` у спокої (у Clay кулак повернутий на ≈ 6,9° навколо Y).
- Копія модуля даних — `Scripts/Modules/ClayGolemData.lua` (хеш 961405660, 16 861 байт).

![[clay_game_01_prefabs_row.jpg]]

*Префаби в Studio: Clay, Wooden і Stone, ящички й предмети в ряд.*

![[clay_game_02_clay_prefab_front.jpg]]

### Предмети (глиняні)
| Предмет | Деталей | Вигляд |
| --- | --- | --- |
| Кірка `ClayPickaxe` (майнер) | 15 | держак — валик мокрої глини `#8c4a33`, обмотка теракотою, голова з теракоти `#c4714a` з камінцем, леза зі світлої сухої глини `#e3ab80` (4 сходинки до кінчика `Pick4`), відбиток пальця |
| Меч `ClaySword` (воїн) | 11 | лезо з теракоти зі світлою кромкою `#e3ab80`, дол мокрою глиною, гарда — валик мокрої глини з камінцем, руків'я з двома глиняними кільцями, навершя |
| Ящичок `ClayCarryBox` (носій) | 18 + 10 `Load` | глибоке корито: дно й цоколь з мокрої глини, теракотові стінки 0,26 стада, обідок із сухої глини, вушка-ручки, три відбитки пальців, камінець і патьок спереду; підняте дно `FloorRaised` (верх на +1,3) |

Атрибути ящичка: `InnerX 1.68`, `InnerZ 0.83`, `InnerY0 1.3`, `InnerY1 2.0`, `CenterY 1.05`, `Offset (0; 3,1; −2,2)`; `PrimaryPart = Bottom`.

## Рол
Пул ролу — големи каталогу з моделлю (`GolemModel.has`), тож Clay потрапив у пул сам: Wooden (базовий), Stone 1 до 10, Clay 1 до 15. Перевірка `RollConfig.pick` (300 000 ролів, удача 5 %): Stone 1 до 9,56, Clay 1 до 14,14 (за формулою 1 до 9,52 і 1 до 14,29). Шанси в каталозі не змінювались.

## Перевірка в Play (27.10.2026)
- **Плот:** Clay-майнер (Diamond) б'є руду кіркою. Точка удару `HitPoint` — усередині руди (зсув від центру 1,3 / −0,2 / 1,35 при пів-розмірі руди 3,8 / 2,4 / 3,1), тож кути удару не правились. Clay-носій несе глиняний ящичок, руду в ньому видно.
- **Воїн у руці:** Clay-воїн (Void) з глиняним мечем, аура Void; у слоті хотбара — 3D Clay з мечем.
- **Інвентар, вікно плоту:** 3D Clay у слотах (майнер з кіркою, носій з ящичком, воїн з мечем).
- **Index:** силует Clay з кіркою (ще не відкритий).
- **Рол:** Clay випав на 4-му ролі (підставка 2), з кіркою.
- **Стенд печери:** тестові моделі через `GolemModel.build` на стендах 1–3 (носій Gold, воїн Void, майнер Secret) — масштаб 1,05, предмети й аури є; після скріну прибрано.
- **Аури мутацій** (`Shared/MutationAura`) на Clay працюють: Diamond на плоті, Void у руці, Gold і Secret на стендах.
- Помилок у консолі немає.

![[clay_game_03_plot_miner_swing.jpg]]
![[clay_game_04_plot_carrier_box_ore.jpg]]
![[clay_game_05_warrior_hold_void_aura.jpg]]
![[clay_game_06_inventory_slot.jpg]]
![[clay_game_07_index_silhouette.jpg]]
![[clay_game_08_plot_window.jpg]]
![[clay_game_09_roll_stand_clay.jpg]]
![[clay_game_10_cave_stands_gold_secret.jpg]]

**Розмір на плоті (v1.1):** Clay-майнер 1,05 поруч зі Stone 1,0; у вікні плоту Clay-майнер без мутації — 3 dmg (воїнів у списку більше немає).

![[clay_game_11_plot_clay_vs_stone_size105.jpg]]
![[clay_game_12_plot_window_fixed_3dmg.jpg]]

Кадри з веб-макета (анімації):

![[clay_miner.png]]
![[clay_miner_swing.png]]
![[clay_miner_hit.png]]
![[clay_carrier.png]]
![[clay_warrior.png]]
![[clay_walk.png]]

## Структура папки
- `Preview/`: концепт-лист `clay_golem_concept.png`, веб-макет `clay_golem.html`, кадри макета (`clay_front` / `clay_34` / `clay_back` / `clay_side` / `clay_items` / `clay_miner*` / `clay_carrier` / `clay_warrior` / `clay_walk` / `clay_page_ui`), скріни з гри `clay_game_*.jpg`
- `Source/`: `clay_golem_generator.py` (блоки, правило 0,1, `ClayGolemData.lua`, `clay_golem_blocks.json`), `clay_golem_blocks.json` (тіло, кістки, префаби `ClayPickaxe` / `ClaySword` / `ClayCarryBox` у локальних координатах), `clay_golem_report.txt`, шаблон макета `clay_golem_template.html` і `build_html.py`, `render_shots.js` (кадри макета), `make_concept_sheet.py` (концепт-лист)
- GLB немає: модель у Roblox зібрана з `Part` за `ClayGolemData`.

## Чекліст
- [x] 5 мас + накладки, 67 блоків
- [x] Не більше 6 кольорів у тілі
- [x] Правило 0,1: 0 збігів
- [x] Очі шарами по 0,1
- [x] До 1 000 трикутників
- [x] Зібрано в Roblox Studio з Part, Plastic + StudsSmall
- [x] Кірка, меч, ящичок — окремі префаби
- [x] Плот, слоти, рука, Index, вікно плоту, рол і стенд печери показують Clay (перевірено в Play)
- [ ] Анімація Attack для воїна
- [x] `size 1.05` на плоті (ноги на підлозі, кірка влучає в руду, ящичок у руках)

## Історія
- **v1 (27.10.2026):** модель погоджено; перенесено в гру як Wooden: префаб `ClayGolem`, предмети `ClayPickaxe` / `ClaySword`, ящичок `ClayCarryBox`, `GolemCatalog.clay` з `model` / `box` / `pickaxe` / `sword`. Бекап каталогу до правки — `ServerStorage/NicheBackup/ClayGolem_v1`.
- **v1.1 (27.10.2026):** на плоті — масштаб `size 1.05`; воїни більше не потрапляють у майнери плоту (баг «15 dmg»). Бекап — `ServerStorage/NicheBackup/ClayGolem_v2`.
