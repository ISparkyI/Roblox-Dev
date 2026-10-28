---
tags: [place, locations, cave, golems]
status: in-game
author: друг користувача
updated: 2026-10-26
version: 8
---

# Golem Cave

← [[Locations]]

*Печера-сховище големів.* У кожної зайнятої ніші — своя печера, **рівно під нішею** (прив'язана до сокета ніші, не до моделі етапу). Гравець заходить через вхід у ніші ([Cave Entrance](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FCave%20Entrance%2FCave%20Entrance)): затискає **E · ENTER CAVE** 0,9 с і опиняється всередині. Тут стоять 14 стендів для големів з табличками цін. Вийти — червона **EXIT CAVE** (теж затиск 0,9 с), гравець повертається до кола входу ніші.

> **Автор:** друг користувача. Буде доопрацьовано разом. Скрипти й модель зі Studio описано як є, без змін.

## Як влаштовано
| Що | Як |
| --- | --- |
| Шаблон | `Workspace/Cave_Inside` (Model): **тестовий префаб** — лежить у Workspace під тестовою нішею `NichePrefabs/NichePrefab_Stage1`, щоб його було зручно редагувати в Edit; гравців туди не телепортуємо. Піввот (−829, −33,5, 314), габарит ≈ 160 × 40,5 × 84, 5159 інстансів (1059 деталей, 32 світла, усе Anchored) |
| На старті сервера | `CaveService` переносить шаблон у `ServerStorage/CaveInsideTemplate` (як `NichePrefabs` / `PlotPrefabs`) і створює папку `Workspace/Caves`; шаблону немає 10 с — попередження й печери вимкнено (без вічного `WaitForChild`) |
| Печера ніші (v2) | ніша отримала власника (`NicheService.Claimed`) → копія шаблону `Workspace/Caves/Cave_<NicheIndex>` за CFrame **сокета** `Workspace/NicheSockets/Socket*` × `CAVE_FROM_SOCKET` = `CFrame.new(0, −42, −135) · rotY −90°` (простір сокета: −Z углиб ніші). Центр печери — під центром підлоги ніші (розбіжність ≤ 1,5 стада), верх печери на ≈ 8 стадів нижче низу підлоги (y ≈ −11,7 проти −3,8), довга вісь 160 — углиб ніші, ширина 84 — уздовж ряду (сусідні печери через 66 стадів). Атрибути `NicheIndex`, `Socket`, `OwnerUserId`. NicheIndex = номер слота `NicheService` (1:1 із сокетом) |
| Етапи | ніша етапу (карта 1, 2…) — окрема модель, яку `NicheService` перебудовує; печера прив'язана до сокета й **не перебудовується** зі зміною етапу (дизайн печери між етапами той самий) |
| Звільнення | `NicheService.Released` → гостей повернуто до входу ніші, з якої зайшли (якщо це та сама ніша — до власної ніші гостя), печеру видалено (у вільних нішах печер немає — економія 5159 інстансів) |
| Підказка ENTER CAVE | події, без опитування: папка `Niches` (`ChildAdded`, ніша перебудована) і атрибут `OwnerUserId` ніші → `CavePrompt.Enabled` лише в зайнятій ніші |
| Вхід | `CaveEntrance`: `CavePrompt` (`Niche*/GolemCave/PromptAnchor`) → `GolemCaveSpawn` печери **цієї** ніші (+3 угору). Заходити може будь-хто, і в чужу печеру теж |
| Вихід | `CaveEntrance`: `ExitPrompt` (`Cave_<N>/CaveExit/PromptAnchor`) → `RingCenter` входу ніші, якій належить печера (+3 угору), **обличчям від печерного входу** (у бік ніші); якщо ніші немає — до власної ніші гравця |
| Атрибути й кулдаун | атрибути гравця ставляться / знімаються лише **після вдалого телепорту**; кулдаун входу й виходу окремий (по 1 с) |
| Затиск | `HoldDuration 0.9` для `CavePrompt` і `ExitPrompt` ставить `CaveService` у коді (не лише значення з Edit) |
| Права | `Shared/CaveAccess`: `canEnter` / `canExit` — усім; `isOwner(player, ownerId?)`; `canInteract(player, ownerId?)` — лише власник, який зараз у печері. Нові дії в печері (купівля стенда, постановка / підбір голема) мають перед дією викликати `canInteract` |
| Стрімінг | `StreamingEnabled = true`, тому перед телепортом — `RequestStreamAroundAsync` |
| Респавн | `CharacterAdded` скидає атрибути печери; `NicheService` ставить гравця на спавн ніші |

**Атрибути**

| Де | Атрибут | Значення |
| --- | --- | --- |
| гравець | `InCave` | `true`, поки в печері |
| гравець | `CaveOwner` | UserId власника печери |
| гравець | `CaveFrom` | ім'я ніші, через яку зайшов |
| гравець | `CaveIndex` | номер печери (`Cave_<N>`), у якій гравець (v2) |
| `Cave_<N>` | `NicheIndex`, `Socket`, `OwnerUserId` | ніша, сокет і власник |
| `Golem_Stand_*` | `SlotIndex`, `Price` | номер стенда (1–14) і ціна в Money |

RemoteEvent немає: вхід і вихід — лише через `ProximityPrompt`. **Збереження немає:** печера щоразу будується з шаблону, куплені стенди й големи на них поки нікуди не пишуться.

## Модель (`Cave_Inside`)
| Частина | Що там |
| --- | --- |
| `Floors`, `Walls`, `Ceiling`, `Frame` | підлога з проходом, стіни (247 деталей), стеля, каркас |
| `Doorway_Rock`, `Doorway_Void` | кам'яна арка входу і темний прохід |
| `Lights` | ліхтарі (32 джерела світла, без тіней) |
| `Crystals`, `Timber`, `Greenery`, `Details` | кристали руди, дерев'яні опори, мох і ліани, болти |
| `Stands` | 14 стендів `Golem_Stand_*`: бортики `Rim`, `Bed`, `MossCap`, табличка `PriceBoard` (`SurfaceGui PriceGui`, Montserrat: `STAND N` і ціна) |
| `CaveExit` | коло `Ring` з написом EXIT (`SignAnchor/ExitSign`) і `PromptAnchor/ExitPrompt` |
| `GolemCaveSpawn` | невидима точка появи (Anchored, без колізії) |

**Підказки:** `CavePrompt` — `UIText "ENTER CAVE"`, `UIColor "blue"`; `ExitPrompt` — `UIText "EXIT CAVE"`, `UIColor "red"`, `ActionText "Exit Cave"`, `ObjectText "Golem Cave"`. В обох: `Style = Custom`, іконка печери `rbxassetid://135564008543327`, `UIOffsetY −1.4`, `MaxActivationDistance 10`, `RequiresLineOfSight = true`, `HoldDuration 0.9`. Малює їх `CustomPrompts`.

**Ціни стендів** (`Price`, Money): 1 — 1,000 · 2 — 3,600 · 3 — 12,900 · 4 — 46,600 · 5 — 167,000 · 6 — 604,000 · 7 — 2.17M · 8 — 7.83M · 9 — 28.2M · 10 — 101M · 11 — 365M · 12 — 1.31B · 13 — 4.73B · 14 — 17B (крок ≈ ×3,6).

## Скрипти
| Скрипт | Де | Копія |
| --- | --- | --- |
| `CaveService` | `ServerScriptService/CaveService` (Script) | `Scripts/Server/CaveService.lua` |
| `CaveEntrance` | `ServerScriptService/CaveEntrance` (Script) | `Scripts/Server/CaveEntrance.lua` |
| `CaveAccess` | `ReplicatedStorage/Shared/CaveAccess` (ModuleScript) | `Scripts/Modules/CaveAccess.lua` |
| `CaveStandService` (v3) | `ServerScriptService/CaveStandService` (ModuleScript, `NicheBoot`) | `Scripts/Server/CaveStandService.lua` |
| ~~`CaveLighting`~~ (v5–v6, прибрано у v7) | був `StarterPlayerScripts/CaveLighting` — зараз вимкнений у `ServerStorage/NicheBackup/Scripts_CaveLight_v7` | `Scripts/Client/CaveLighting.lua` (історична копія) |
| `CaveStandsClient` (v3) | `StarterPlayerScripts/CaveStandsClient` (LocalScript) | `Scripts/Client/CaveStandsClient.lua` |

## Що перевірити / поправити
Помічено під час читання. ✅ — виправлено у v2 (прив'язка до сокетів).

1. ✅ **Стенди без логіки:** *(v3: купівля, PLACE / TAKE, збереження — розділ «Стенди»; `CaveAccess.canInteract` викликає `CaveStandService`.)* купівлі, постановки й підбору голема ще немає, `PriceBoard` статична, `CaveAccess.canInteract` ніде не викликається. Збереження стендів (секція `DataService`) теж немає.
2. ✅ **Назви стендів не збігаються з номером:** *(v3: у шаблоні перейменовано `Golem_Stand_<SlotIndex>`; код однаково бере номер з атрибута.)* `Golem_Stand_2` має `SlotIndex 3` (STAND 3), `Golem_Stand_8` — STAND 2 тощо. Варто перейменувати за `SlotIndex` або брати номер лише з атрибута.
3. **Вага копій:** *(v2: печера є лише в зайнятій ніші, як і раніше; створення при першому вході — не робили.)* шаблон — 5159 інстансів і 32 світла; при 6 зайнятих нішах це ≈ 31K інстансів на сервері. Перевірити навантаження й стрімінг; можливо, створювати печеру лише при першому вході власника або гостя.
4. ✅ **Затиск 0,9 с не задається кодом.** *(v2: ставить `CaveService` для `CavePrompt` і `ExitPrompt`.)* Раніше `CaveEntrance` сам ставив `HoldDuration 0.9`, тепер значення є лише в шаблонах. Для ROLL його ставить `RollRoleService`, бо значення з Edit одного разу злетіло на 0. Варто повернути це в код.
5. ✅ **Мертвий код:** *(v2: перевірку `ComingSoon` у `CaveEntrance` прибрано; клієнтська анімація COMING SOON у `CustomPrompts` лишилась для інших підказок.)* у `CaveEntrance` лишилася перевірка атрибута `ComingSoon`, якого вже немає.
6. ✅ **Атрибути до телепорту:** *(v2: ставляться лише після вдалого телепорту.)* `InCave` / `CaveOwner` / `CaveFrom` ставляться до `teleport`. Якщо в персонажа немає `PrimaryPart`, гравець лишається в ніші, але вважається «в печері».
7. ✅ **Один кулдаун на вхід і вихід** (1 с). *(v2: окремі кулдауни.)* Можна розвести, щоб гравець одразу після входу не впирався в кулдаун.
8. ✅ **Поворот при виході:** *(v2: обличчям від печерного входу.)* `CFrame.new(позиція)` без повороту — персонаж дивиться в довільний бік. Краще розвертати обличчям від входу.
9. ✅ **Патерн сервісів:** *(v2: події `NicheService.Claimed` / `Released`, `ChildAdded` / атрибут `OwnerUserId` замість циклу 0,5 с; `WaitForChild` з тайм-аутом 10 с. `CaveService` лишився Script-ом, не ModuleScript у `NicheBoot`.)* `CaveService` — окремий Script з опитуванням кожні 0,5 с. Інші системи — ModuleScript із `Start()` у `NicheBoot` і подіями `NicheService.Claimed` / `Released`. `WaitForChild("CaveInsideTemplate")` без тайм-ауту: якщо шаблону немає, скрипт мовчки зависне.
10. ✅ **Місце копій:** *(v2: печери під своїми нішами; перевірено кодом для всіх 6 сокетів — `GetPartBoundsInBox` без жодного перетину з картою, нішами чи іншими печерами, terrain немає.)* печери йдуть по +Z від z ≈ 314 до ≈ 964 на висоті ≈ −33. Перевірити, що вони не перетинають іншу геометрію під картою.
11. **Формат цін** *(кнопка BUY — `NumberFormat.money`: `$1,000`, `$2.17M`; самі таблички не чіпали)* на табличках (`$12,900`, `$2.17M`) звірити з `NumberFormat` гри і стилем табличок (стиль A, заголовки КАПСОМ).
12. **Гості:** *(v3: гість бачить стенди й големи власника, кнопок не має, сервер відкидає його дії.)* у будь-яку зайняту печеру може зайти будь-хто. Підтвердити з користувачем, що це задумано (а не лише друзі чи запрошені).

## Стенди (v3)
Кожен стенд — `Stands/Golem_Stand_<N>` (`SlotIndex` N = 1–14, `Price` у Money). Логіка — `CaveStandService` (сервер) і `CaveStandsClient` (клієнт); кнопку малює `CustomPrompts`.

| Стан стенда | Кнопка над майданчиком (ближче до цінника) | Затиск 0,5 с |
| --- | --- | --- |
| не куплений, **наступний по черзі** | зелена **BUY $1,000** (грошей вистачає) / сіра (не вистачає) | купує: −Money, звук `BuySound`, ціна з цінника зникає, зелене світло цінника вимкнено — камінь сірий, як бортики |
| не куплений, не наступний | сіра **LOCKED** | — |
| куплений, порожній, у руці голем із моделлю | зелена **PLACE** | ставить голема з руки на стенд: голем **зникає з інвентаря** (переїжджає в секцію `Cave`), рука й хотбар звільняються |
| куплений, порожній, інакше | сіра **HOLD A GOLEM** / **NO MODEL YET** (голем без 3D-моделі, напр. Wooden, Clay) / **ON PLOT** (голем працює на плоті) | — |
| з големом | синя **TAKE**; інвентар повний (`MAX_GOLEMS`, з 27.10.2026 — 300) — сіра **INVENTORY FULL** | голем повертається в інвентар, новим слотом у кінець хотбара й у руку (хотбар повний — лише в інвентар) |

- **Порядок:** у GDD сказано лише «слоти купуються за Money», порядку немає — тому по черзі 1 → 14 (наступний — лише після попереднього).
- **Кнопка:** `ProximityPrompt` `StandPrompt` у невидимій точці `StandButton` (3,6 стада від центру майданчика до цінника, 2,4 над ним), `Style = Custom` — той самий вигляд, що COLLECT / ENTER CAVE: кнопка стилю A, клавіша E, тінь-заповнення затиску. Видно з 11 стадів, лише найближча (`Exclusivity = OneGlobally`). Сіра — затиск не заповнюється, кнопка хитається з глухим звуком (атрибут `UIDisabled`, `CustomPrompts`).
- **Лише власник:** кнопки бачить тільки власник печери, поки він у ній; сервер перевіряє власника (`CaveAccess.canInteract`), відстань (≤ 15 стад), порядок, гроші, голема в руці. 1,2 с після входу в печеру кнопки не діють (щоб E, затиснута на ENTER CAVE, нічого не купила). Гість бачить куплені стенди й големів, але кнопок не має.
- **Голем на стенді:** та сама модель, що на плотах (`PlotAssets/<model>`, зараз лише Stone Golem), розмір × `GolemCatalog.size`, аніматор у позі Idle; майнер — з кіркою, носій — з ящичком, без кірки; обличчям до проходу. Над ним табличка, як над големом у руці (мутація, рідкість, назва, стат, ціна; видно з 32 стад).
- **Інвентар (v4):** голем на стенді **прибраний з `InvGolems`** — у вікні інвентаря його немає; повний запис `{ id, kind, cls, mut, locked? }` лежить на стенді (замок інвентаря повертається при TAKE). Ліміт `MAX_GOLEMS` рахує лише інвентар. Index відкриття не губить (лише додає). Новим големам треба брати id, більший за `CaveStandService.MaxId(p)` (інвентар + стенди).
- **Збереження:** секція `Cave` у DataService — `{ bought = {1, 2, …}, golems = { ["<номер>"] = { id, kind, cls, mut } } }`, **не скидається** на новій мапі. При вході відновлюється, печера оновлюється з даних; старий формат (лише id) переноситься автоматично. Атрибути гравця: `CaveStands`, `CaveStandGolems`, `CaveReady`; на стенді — `Bought`, `GolemId`; на печері — `StandsBought`.

![[golem_cave_stand_buy_green.jpg]]
*BUY $12,900 — зелена (грошей вистачає).*

![[golem_cave_stand_buy_gray.jpg]]
*Та сама кнопка сіра — грошей замало.*

![[golem_cave_stand_bought.jpg]]
*STAND 1 після покупки: ціни немає, камінь сірий. Далі — носій з ящичком на STAND 3.*

![[golem_cave_stand_golem.jpg]]
*Stone-майнер на STAND 1 з табличкою (Common · Stone Golem · 2 dmg · x1.05 · Cost: $150) і Stone-носій на STAND 3.*

![[golem_cave_stand_hold_a_golem.jpg]]
*Куплений порожній стенд, у руці нічого — сіра HOLD A GOLEM.*

![[golem_cave_stand_inventory_full.jpg]]
*v4: інвентар повний (40 / 40) — над големом сіра INVENTORY FULL.*

![[golem_cave_stand_take_hotbar.jpg]]
*v4: після TAKE голем знову в інвентарі, у хотбарі й у руці («Stone Golem · in hand»).*

## Освітлення (фінал, v8)
**Як зараз:** печера освітлена тим самим глобальним освітленням, що й ніша (Lighting плейсу не змінюється ні на сервері, ні на клієнті), без різких плям і без жодних сторонніх деталей.
- Зовнішня оболонка печери в шаблоні `Cave_Inside` (`Walls`, `Ceiling`, `Frame`, `Floors`, `Doorway_Rock`) — `CastShadow = true`: вона сама закриває підлогу від сонця й від тіні ніші / карти над печерою. Внутрішній декор (балки `Timber`, ліхтарі, кристали, зелень, деталі) — без тіней. Світильники — `Shadows = false` (як у друга користувача).
- Перевірено кодом: промені від 1431 точки підлоги в бік сонця (для обох поворотів печери — лівий і правий ряд ніш) — усередині печери жоден не проходить крізь оболонку (світло лише на крайніх точках поза стінами). Тому коробка `SunBlock` (v7) не потрібна — **прибрана повністю** (її було видно ззовні під картою, правка користувача).
- Клієнтський `CaveLighting` (v5–v6) прибрано з гри (вимкнений, у `ServerStorage/NicheBackup/Scripts_CaveLight_v7`); копія `Scripts/Client/CaveLighting.lua` — історична.
- Lighting на клієнті в Play збігається з Edit (перевірено у v7).

![[golem_cave_light_v8.jpg]]
*Печера (ракурс від EXIT): освітлення як у ніші, без плям, без SunBlock.*

![[golem_cave_outside_v8.jpg]]
*Ззовні під картою: видно лише саму печеру (її кам'яна оболонка з моделі друга), чорної коробки немає.*

![[niche_light_v7.jpg]]
*Ніша 1 — освітлення як було.*

Історія спроб (не використовуються): v4 — вимкнено `CastShadow` у всій печері (сонце світило крізь стелю, плями від ніші); v5 — `GlobalShadows = false` на клієнті (занадто світло); v6 — сонце 0 і темний ambient на клієнті (занадто темно); v7 — чорна коробка `SunBlock` навколо печери (видно ззовні). Скріни: `golem_cave_light_v4.jpg` … `golem_cave_light_v7.jpg`.

## Прив'язка під нішами (v2)
![[golem_cave_side_under_niches.jpg]]
*Вигляд збоку (Play, лівий ряд): три ніші Socket1L / Socket2L / Socket3L і під кожною — своя печера (середня ніша на сокеті x = −60, тому її печера на 30 стадів далі).*

![[golem_cave_inside_niche1.jpg]]
*Гравець після ENTER CAVE у ніші 1 — у `Cave_1` під своєю нішею (спавн (−115, −45, 150)).*

![[golem_cave_inside_check.jpg]]
*Перевірка з печери: крізь стелю нічого з ніші не видно. «x2 Money» праворуч угорі — це кнопка HUD (`PlayerGui/MainHUD`, ScreenGui; на всіх скрінах стоїть у тому самому місці екрана), а не білборд ніші. Перевірено кодом: поки гравець у печері, жоден BillboardGui / SurfaceGui ніш не має `AlwaysOnTop` (усі закриває геометрія), тож ховати нічого не треба.*

## Структура папки
- `Preview/golem_cave_side_under_niches.jpg`, `Preview/golem_cave_inside_niche1.jpg`, `Preview/golem_cave_inside_check.jpg` — скріни v2
- `Preview/golem_cave_stand_*.jpg` — скріни стендів v3–v4 (BUY зелена / сіра, після покупки, голем на стенді, HOLD A GOLEM, INVENTORY FULL, TAKE у хотбар)
- `Preview/golem_cave_light_v4.jpg`, `golem_cave_light_v5_before.jpg`, `golem_cave_light_v5.jpg`, `golem_cave_light_v6.jpg`, `golem_cave_light_v7.jpg`, `golem_cave_light_v8.jpg`, `golem_cave_outside_v8.jpg`, `niche_light_v7.jpg` — освітлення (v5 — без плям)

## Історія
- **v8 (26.10.2026, правка користувача «прибери чорні стіни»):** коробку `SunBlock` прибрано повністю — оболонка печери з `CastShadow = true` сама закриває підлогу від сонця (перевірено променями й скріном). Бекап — `ServerStorage/NicheBackup/Scripts_CaveLight_v8` (копія `Cave_Inside` із SunBlock).
- **v7 (26.10.2026, відгук користувача «як у ніші»):** `CaveLighting` прибрано (Lighting не змінюється); світильникам повернуто `Shadows = false`; оболонці печери повернуто `CastShadow = true`, додано непрозору коробку `SunBlock` навколо печери від сонця. Бекап — `ServerStorage/NicheBackup/Scripts_CaveLight_v7` (копія `Cave_Inside` до змін + `CaveLighting`).
- **v6 (26.10.2026, відгук користувача):** освітлення — не «світло, як надворі»: замість вимкнених глобальних тіней — печерний профіль на клієнті (сонце 0, темніший ambient) і м'які тіні ліхтарів (`PointLight.Shadows`). Бекап шаблону — `ServerStorage/NicheBackup/Scripts_CaveStands_v2` (копія `Cave_Inside` до змін).
- **v5 (26.10.2026, відгук користувача):** плями тіні на підлозі від ніші над печерою — на клієнті, поки гравець у печері, `Lighting.GlobalShadows = false` (`CaveLighting`), при виході повертається. Бекап не потрібен (новий скрипт).
- **v4 (26.10.2026, правки користувача):** голем на стенді прибирається з інвентаря (запис у секції `Cave`), позначку ON STAND прибрано; TAKE — в інвентар, у хотбар і в руку, повний інвентар — INVENTORY FULL; без тіней на підлозі (`CastShadow = false` у шаблоні, крім стендів). Бекап — `ServerStorage/NicheBackup/Scripts_CaveStands_v2` (+ копія `Cave_Inside`).
- **v3 (26.10.2026):** стенди працюють: купівля по черзі за Money (BUY зелена / сіра, LOCKED), PLACE / TAKE голема (модель з плотів, Idle, табличка), позначка `InvOnStand` в інвентарі, збереження в секції `Cave` (не скидається на новій мапі). Стенди в шаблоні перейменовано за `SlotIndex`. Бекап — `ServerStorage/NicheBackup/Scripts_CaveStands_v1` (+ копія `Cave_Inside`).
- **v2 (26.10.2026):** печери прив'язано до сокетів ніш (`CAVE_FROM_SOCKET`), не до тестового префаба: кожен гравець потрапляє в печеру під своєю нішею. `CaveService` на подіях `NicheService`, затиск 0,9 с у коді; `CaveEntrance` — атрибути після телепорту, окремі кулдауни, розворот при виході, без `ComingSoon`. Бекап — `ServerStorage/NicheBackup/Scripts_CaveBind_v1` (+ копія `Cave_Inside`).
- **v1 (26.10.2026):** печера зроблена другом користувача: шаблон `Cave_Inside`, своя копія на кожну нішу (`CaveService`), вхід і вихід (`CaveEntrance`), права гостя й власника (`CaveAccess`). Задокументовано зі Studio.
