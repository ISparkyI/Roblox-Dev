---
tags: [place, locations, cave, golems]
status: in-game (стенди без логіки)
author: друг користувача
updated: 2026-10-26
version: 2
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

## Що перевірити / поправити
Помічено під час читання. ✅ — виправлено у v2 (прив'язка до сокетів).

1. **Стенди без логіки:** купівлі, постановки й підбору голема ще немає, `PriceBoard` статична, `CaveAccess.canInteract` ніде не викликається. Збереження стендів (секція `DataService`) теж немає.
2. **Назви стендів не збігаються з номером:** `Golem_Stand_2` має `SlotIndex 3` (STAND 3), `Golem_Stand_8` — STAND 2 тощо. Варто перейменувати за `SlotIndex` або брати номер лише з атрибута.
3. **Вага копій:** *(v2: печера є лише в зайнятій ніші, як і раніше; створення при першому вході — не робили.)* шаблон — 5159 інстансів і 32 світла; при 6 зайнятих нішах це ≈ 31K інстансів на сервері. Перевірити навантаження й стрімінг; можливо, створювати печеру лише при першому вході власника або гостя.
4. ✅ **Затиск 0,9 с не задається кодом.** *(v2: ставить `CaveService` для `CavePrompt` і `ExitPrompt`.)* Раніше `CaveEntrance` сам ставив `HoldDuration 0.9`, тепер значення є лише в шаблонах. Для ROLL його ставить `RollRoleService`, бо значення з Edit одного разу злетіло на 0. Варто повернути це в код.
5. ✅ **Мертвий код:** *(v2: перевірку `ComingSoon` у `CaveEntrance` прибрано; клієнтська анімація COMING SOON у `CustomPrompts` лишилась для інших підказок.)* у `CaveEntrance` лишилася перевірка атрибута `ComingSoon`, якого вже немає.
6. ✅ **Атрибути до телепорту:** *(v2: ставляться лише після вдалого телепорту.)* `InCave` / `CaveOwner` / `CaveFrom` ставляться до `teleport`. Якщо в персонажа немає `PrimaryPart`, гравець лишається в ніші, але вважається «в печері».
7. ✅ **Один кулдаун на вхід і вихід** (1 с). *(v2: окремі кулдауни.)* Можна розвести, щоб гравець одразу після входу не впирався в кулдаун.
8. ✅ **Поворот при виході:** *(v2: обличчям від печерного входу.)* `CFrame.new(позиція)` без повороту — персонаж дивиться в довільний бік. Краще розвертати обличчям від входу.
9. ✅ **Патерн сервісів:** *(v2: події `NicheService.Claimed` / `Released`, `ChildAdded` / атрибут `OwnerUserId` замість циклу 0,5 с; `WaitForChild` з тайм-аутом 10 с. `CaveService` лишився Script-ом, не ModuleScript у `NicheBoot`.)* `CaveService` — окремий Script з опитуванням кожні 0,5 с. Інші системи — ModuleScript із `Start()` у `NicheBoot` і подіями `NicheService.Claimed` / `Released`. `WaitForChild("CaveInsideTemplate")` без тайм-ауту: якщо шаблону немає, скрипт мовчки зависне.
10. ✅ **Місце копій:** *(v2: печери під своїми нішами; перевірено кодом для всіх 6 сокетів — `GetPartBoundsInBox` без жодного перетину з картою, нішами чи іншими печерами, terrain немає.)* печери йдуть по +Z від z ≈ 314 до ≈ 964 на висоті ≈ −33. Перевірити, що вони не перетинають іншу геометрію під картою.
11. **Формат цін** на табличках (`$12,900`, `$2.17M`) звірити з `NumberFormat` гри і стилем табличок (стиль A, заголовки КАПСОМ).
12. **Гості:** у будь-яку зайняту печеру може зайти будь-хто. Підтвердити з користувачем, що це задумано (а не лише друзі чи запрошені).

## Прив'язка під нішами (v2)
![[golem_cave_side_under_niches.jpg]]
*Вигляд збоку (Play, лівий ряд): три ніші Socket1L / Socket2L / Socket3L і під кожною — своя печера (середня ніша на сокеті x = −60, тому її печера на 30 стадів далі).*

![[golem_cave_inside_niche1.jpg]]
*Гравець після ENTER CAVE у ніші 1 — у `Cave_1` під своєю нішею (спавн (−115, −45, 150)).*

> Помічено: з печери видно білборд **x2 Money** ніші над нею (`AlwaysOnTop`) — раніше печера була далеко, тепер вона під нішею. Варто обмежити `MaxDistance` / вимикати, коли гравець у печері.

## Структура папки
- `Preview/golem_cave_side_under_niches.jpg`, `Preview/golem_cave_inside_niche1.jpg` — скріни v2

## Історія
- **v2 (26.10.2026):** печери прив'язано до сокетів ніш (`CAVE_FROM_SOCKET`), не до тестового префаба: кожен гравець потрапляє в печеру під своєю нішею. `CaveService` на подіях `NicheService`, затиск 0,9 с у коді; `CaveEntrance` — атрибути після телепорту, окремі кулдауни, розворот при виході, без `ComingSoon`. Бекап — `ServerStorage/NicheBackup/Scripts_CaveBind_v1` (+ копія `Cave_Inside`).
- **v1 (26.10.2026):** печера зроблена другом користувача: шаблон `Cave_Inside`, своя копія на кожну нішу (`CaveService`), вхід і вихід (`CaveEntrance`), права гостя й власника (`CaveAccess`). Задокументовано зі Studio.
