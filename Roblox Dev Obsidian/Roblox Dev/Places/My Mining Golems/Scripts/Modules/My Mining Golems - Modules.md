# Modules

← [[My Mining Golems - Scripts|Scripts]]

ModuleScript — дані й модулі.

| Файл | Де в Roblox | Що містить |
| --- | --- | --- |
| `GolemData.lua` | `ReplicatedStorage/PlotAssets/Golem/GolemData` (і `Workspace/PlotPrefabs/Golem/GolemData`) | палітра, 18 кісток і 67 блоків: 52 блоки кам'яного голема v2 + 15 блоків інструмента в руці (`group = "Pickaxe"`, `bone = "Forearm_L"`). Усі блоки мають повний `cf` у координатах моделі |
| `WoodenGolemData.lua` | `ReplicatedStorage/PlotAssets/WoodenGolem/GolemData` (і `Workspace/PlotPrefabs/WoodenGolem/GolemData`) | Wooden Golem: палітра, 24 кістки й 81 блок — 59 блоків тіла + 15 блоків дерев'яної кірки (`group = "Pickaxe"`) + 7 блоків дерев'яного меча (`group = "Sword"`, прихований), усі з повним `cf`. Згенеровано `wooden_golem_roblox_data.py` (папка Source моделі Wooden Golem) |
| `ClayGolemData.lua` | `ReplicatedStorage/PlotAssets/ClayGolem/GolemData` (і `Workspace/PlotPrefabs/ClayGolem/GolemData`) | [Clay Golem](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FGolems%2FClay%20Golem%2FClay%20Golem): палітра, 21 кістка й 93 блоки — 67 тіла + 15 глиняної кірки (`group = "Pickaxe"`) + 11 глиняного меча (`group = "Sword"`); групи — джерело префабів `ClayPickaxe` / `ClaySword`, аніматор їх пропускає. Згенеровано `clay_golem_generator.py` (папка Source моделі Clay Golem) |
| `ForgeConfig.lua` | `ReplicatedStorage/Shared/ForgeConfig` | числа Forge: руди мапи 1 (ціни, кольори), множник злитка ×1,5 (`BAR_MULT`), вимоги для пробудження 20 / 10 / 5, радіус кола 8,64, слово стану без руди `WAIT_WORD` («WAITING»), формули місткості, швидкості (до `SPD_MIN` = 0,25 с, `spdMax`) і Ore per Hit (`ophOf`, `OPH_MAX` = 10, `ophPrice`) та їхніх цін, тестовий старт, `TEST_SELL_BARS = false` (злитки з кузні — в інвентар). Ціни руди й `BAR_MULT` бере й лавка Sell |
| `ForgeRig.lua` | `ReplicatedStorage/Shared/ForgeRig` | скелет голема-коваля (деталі Stone Golem + обличчя + фартух + молот), суглоби, пози (сон, робота, відпочинок), ходьба, цикл удару молотом. Масштаб сцени `S = 1.8` (пози у веб-одиницях, `rootCF` множить на S і піднімає на 0,1 стада); спідниця фартуха кріпиться до тулуба й висить прямо |
| `SellRig.lua` | `ReplicatedStorage/Shared/SellRig` | анімації голема-продавця Наґґета (з веб-макета Sell Shop): базова поза `BASE`, 11 анімацій ключовими кадрами (rest, coin, abacus, glance, rub, greet, waitRest, tap, rubW, sell, bye), особливі дії `SPECIAL`, довжини рук для IK, полюси ліктів, радіус кола |
| `RollConfig.lua` | `ReplicatedStorage/Shared/RollConfig` | числа покращень ролу за GDD: Roll Luck (5% за рівень, ціна 1 000 → ×(4 − 0,05·(n−1)), мін. ×1,25), місця ролу 1 → 5 (500 × 3^(k−1) × множник мапи), множник мапи ×1, ×5, ×40, ×440 … Спільний для сервера й екрана; **рол големів (v1):** `TOTAL 2.0` / `FAKES 4` / `APPEAR 0.1` / `VANISH 0.1` / `RESULT_APPEAR 0.2` / `STAGGER 0.04`, `cycle(n)`, `revealTime(n)`, `pick(items, luck, rnd)` — шанси «1 до N» кумулятивними інтервалами з удачею (GDD - Roll) |
| `StyleA.lua` | `ReplicatedStorage/Shared/StyleA` | елементи UI «стиль A» з картинок (GDD «2D іконки», розділи 2–3): 9-slice основа (ImageButton / ImageLabel, `ScaleType Slice`, `SliceCenter Rect(14, 14, 386, 160)`, `SliceScale = H / 200`) + тайл візерунка «квадратик + L» (`ScaleType Tile`, клітинка = висота грані / 4 або / 3), обрізаний рамкою грані (`ClipsDescendants`) + необов'язкові іконка й TextLabel (Montserrat Heavy, білий, контур #14161a). Кольори: green, gray, red, blue, orange, yellow, purple, ore_coal, ore_copper, ore_iron; `half = true` — візерунок половинної сили (плитки, чипи). `StyleA.new(parent, opts)` → об'єкт з `:setColor` / `:setText` / `:setIcon` / `:setSize` / `:setPosition` / `:destroy`; `StyleA.bind(obj, opts)` — поведінка кнопки: наведення 1,04, натискання 0,92 з пружним поверненням, недоступна — хитається; також `StyleA.shake`, `faceRect`, `sliceScale`; `StyleA.follow(obj, gui)` — сусідній елемент кнопки (тінь, бейдж, підпис) отримує свій UIScale, синхронний з кнопкою, і хитається разом з нею; `StyleA.bind` грає `tap` (UISounds) на успішний клік (`tap = false` — вимкнути), `StyleA.tap()` — для кнопок без bind; `StyleA.ICON_NUDGE` — оптичний зсув окремих іконок (хрестик X — по центру грані). ID картинок — таблиця `StyleA.ASSETS` (27 шт., див. нижче). Підключають ForgeWindow, ForgeClient, RollUpgradeUI |
| `CardHover.lua` | `ReplicatedStorage/Shared/CardHover` | наведення на картки покращень (клієнт): `CardHover.holder(parent, x, y, w, h, extraBottom)` — тримач `CanvasGroup` з центром у середині картки (запас `PAD` 16), повертає тримач і зсув для малювання; `CardHover.attach(holder, hit, enabled?, base?)` — при наведенні ×1,05 від `base` і нахил до 3° у бік мишки, плавно (RenderStepped, один цикл на всі картки). У `SurfaceGui` позицію мишки на полотні рахує променем з камери на грань. Звук наведення бере зі спільного `UIHover` і позначає картку атрибутом `HoverSoundBy`, щоб автозвук кнопок не грав двічі. `CardHover.surfaceX(gui, point?)` — x мишки (або точки) на полотні SurfaceGui, для повзунка й перетягування карток табла кузні. Підключають RollUpgradeUI (base 0,95) і ForgeClient (base 0,85). У `SurfaceGui` тримач — звичайний `Frame` і без нахилу (лише масштаб): `CanvasGroup` у таблах світу на низькій графіці не малювались |
| `PlotConfig.lua` | `ReplicatedStorage/Shared/PlotConfig` | плоти ([GDD - Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Plots)): руда мапи 1 (HP 5 / 15 / 30, шанси 1 до 3 / 9 / 20, `rollOre`), картки `CARDS` (Plots, Ore Spawn, Golem Slots, Carrier Speed — макс. рівні й ціни), `spawnOf` (5 с → 0,25 с), `slotsOf`, `carryOf` (×1 → ×3), `stats(kind, mut)` — характеристики голема на плоті з `GolemCatalog` з урахуванням мутації (майнер `dmg` / `int` / `mspd` / `anim`, носій `cap` / `spd`), `minerPower` / `carrierPower` (через `GolemCatalog.power`), константи руху й стаків (`PICKUP_R` = 8,5 стада — гравець сам підбирає стак), `AUTO_EQUIP_PASS`. Спільний для сервера й клієнта |
| `GolemCatalog.lua` | `ReplicatedStorage/Shared/GolemCatalog` | [[GolemCatalog]] — каталог големів: 24 големи × 3 класи (майнер / носій / воїн), рідкості й кольори, мутації (шанси, кольори), формули `stats` / `power` / `statText`, старі ID (`LEGACY`). Джерело — таблиці GDD Golem Stats. Спільний для сервера й клієнта |
| `GolemModel.lua` | `ReplicatedStorage/Shared/GolemModel` | «живий» голем у світі з моделі каталогу (спільний для сервера й клієнта): `build(kind, cls)` — клон `PlotAssets/<model>`, предмет за класом, ящичок носія, Anchored, масштаб × `size`, увімкнений `GolemAnimator` (nil — моделі немає); `has(kind)`, `footOffset(m)`, `headTop(m)`. Беруть `CaveStandService` (стенди печери) і `RollRevealClient` (підставки ролу) |
| `ItemConfig.lua` | `ReplicatedStorage/Shared/ItemConfig` | предмети інвентаря: големи (`GOLEMS` і `RARITY` — з `GolemCatalog`, і для старих ID; тестові — `"ID"`, `"ID:carrier"`, `"ID@мутація"`), зілля (назва, колір, опис, іконка), кольори рідкостей і руди, іконки вкладок / кошика / замка / класів големів (`class_all`, `class_miner`, `class_carrier`, `class_warrior`), розмір хотбара (9), ліміт големів `MAX_GOLEMS` (300, з 27.10.2026; було 40), тестові големи й зілля, `stackKeys`, `isStack`. Спільний для сервера й клієнта |
| `MultiConfig.lua` | `ReplicatedStorage/Shared/MultiConfig` | глобальні множники Money: бонус за друга (0,25), VIP ×2, ребіти (вимкнено), таблиця мап `STAGE_MULTS`, драбина донату `DONATE_TIERS` (множник і ціна R$), ціни драбини — за [GDD - Monetization](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Monetization), рядки плашки `SOURCES` (Friends, Rebirth, Money Boost, VIP, Map — з власними іконками `hud_vip` / `hud_map`). Функції `friendsMult`, `rebirthMult`, `donateMult`, `nextDonateMult`, `nextDonatePrice`, `stageMult`. Спільний для сервера й HUD |
| `MonetizationConfig.lua` | `ReplicatedStorage/Shared/MonetizationConfig` | ID геймпасів (`Passes`: VIP, MoreCrates) і Developer Products ступенів x2 Money (`MoneyTierProducts`, 21 ID, створені 24.10.2026); 0 — ще не створено в Creator Hub (геймпаси поки 0) |
| `ItemViewport.lua` | `ReplicatedStorage/Shared/ItemViewport` | 3D-іконки руди й злитків у слотах вікон: ViewportFrame з Union з `Prefabs/ForgeProps`, темний контур (8 силуетів), `VIEW` — кут, масштаб і зсув для кожної моделі; `ItemViewport.set(label, key, scale?)`. Големи: ключ `"GolemVP:<ID>:<клас>"` (`ItemViewport.golemKey(kind, cls)`; `nil`, якщо в каталозі немає `model` — 3D є у Stone Golem і Wooden Golem): модель з `PlotAssets` у 3/4 обличчям до камери, предмет за класом (`GolemCatalog.applyClassItems`, зайві групи видаляються): майнер з кіркою, воїн з мечем, носій без предмета з ящичком `GolemCatalog.box` у руках (`GolemCatalog.poseCarry`), контур — 4 силуети, `GOLEM_VIEW.fit = 0.8` |
| `WindowFit.lua` | `ReplicatedStorage/Shared/WindowFit` | одне правило розміру й місця для всіх вікон: `WindowFit.place(modalRoot, fitScale, { canvasW, canvasH, winX, winY, winW, winH, extraH? })` — рамка ≈68 % ширини, заголовок + рамка ≈72 % висоти, по центру між верхньою смугою Roblox і хотбаром; на телефоні — максимум з полями. Правило: вміст не влазить — гортати, вікно не збільшувати |
| `WindowManager.lua` | `ReplicatedStorage/Shared/WindowManager` | правило «на екрані лише одне вікно» (лише клієнт): `WindowManager.register(name, isOpen, close)` — вікно закривається, коли відкривається інше; `WindowManager.opened(name)` — на початку `open()` вікна, закриває всі інші. Користуються Inventory, Index, PlotPlace, Forge, Sell |
| `UISfx.lua` | `ReplicatedStorage/Shared/UISfx` | прості UI-звуки з `SoundService`: `UISfx.play("BuySound")` тощо |
| `UISounds.lua` | `ReplicatedStorage/Shared/UISounds` | спільні звуки інтерфейсу (клієнт): `UISounds.play("tap" \| "claim" \| "lever" \| "hover" \| "purchase" \| "deny", minGap?, speed?)` — копія звуку з `SoundService` (Tap, ClaimReward, LeverPull — гучність 0,25, ButtonHover, PurchaseSuccess, Deny) з `PlayOnRemove`, `minGap` гасить подвійні виклики. tap — натискання кнопок (у `StyleA.bind` централізовано), claim — нагорода, lever — важіль ролу, purchase — успішна покупка за Robux (`ShopActions`), deny — відмова (сіра / недоступна кнопка; tap того ж кліку скасовується) |
| `CaveAccess.lua` | `ReplicatedStorage/Shared/CaveAccess` | права в печері-сховищі: `canEnter` / `canExit` — усі гравці, `isOwner`, `canInteract` (лише власник печери в ній; гість — ні). Використовують `CaveEntrance` і майбутні стенди (поки `canInteract` ніде не викликається). Автор — друг користувача; [Golem Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FGolem%20Cave%2FGolem%20Cave) |
| `GolemSort.lua` | `ReplicatedStorage/Shared/GolemSort` | сортування големів (Newest — нові першими / Best — лише сила / Rarity / Mutation / Name / Class) і кнопка зі списком SORT BY — для InventoryUI і PlotPlaceUI; атрибут `InvSort` |
| `MutationText.lua` | `ReplicatedStorage/Shared/MutationText` | анімовані градієнти назв мутацій (клієнт): `apply(label, mut)` — UIGradient «MutationGradient» за `GolemCatalog.MUTATIONS[].gradient` (Secret — з бліком), `clear(label)`; один спільний Heartbeat (~30 оновлень/с) лише поки є живі мітки, знищені відписуються самі |
| `MutationAura.lua` | `ReplicatedStorage/Shared/MutationAura` | [[MutationAura]] — 3D-аури мутацій v5 (клієнт): іскри-зірочки з контуром і двотонні ромбики-жарини кольору мутації (ParticleEmitter); Secret — чорно-біла: білі комети (Neon + Trail білий → графіт), темні осколки на орбіті, білі зірки-спалахи. `apply(model, mut, {scale?})`, `clear(model)`, `count()`; LOD 80 стадів. Вмикає `MutationAuraClient` |
| `MutationSlotFX.lua` | `ReplicatedStorage/Shared/MutationSlotFX` | анімований фон слота за мутацією (клієнт): `new(parent, {pos, size, z})` → `setMut(mut|nil)`, `setOn(on)` (фейд 0,15 с), `destroy()`; 8 стилів (Normal … Secret: обсидіан + голографічний хром, іскри, пульсуюча рамка, аура); спільний Heartbeat ≈30/с лише для увімкнених слотів; текстури — іскра 103166730261377, сяйво 9-slice 100291177927012 |
| `NumberFormat.lua` | `ReplicatedStorage/Shared/NumberFormat` | формат чисел гри (копія глобального модуля з розділу Scripts) |
| — | `ReplicatedStorage/Shared/UIHover` | спільний модуль звуку наведення (код і опис — у розділі Scripts бази); `CardHover` і `UIHoverAuto` користуються ним |
| — | `ReplicatedStorage/Effects/HitChips` | глобальний ефект частинок удару (код і опис у розділі Effects бази) |

## StyleA — ID картинок

Ключі = імена PNG без `.png` (ті самі, що в `StyleA.ASSETS`). ID завантажені в цю гру — у глобальні нотатки Style їх не переносимо.

| Ключ | ID | Що |
| --- | --- | --- |
| `stylea_base_blue` | `rbxassetid://103206255254580` | 9-slice основа |
| `stylea_base_gray` | `rbxassetid://103290422229133` | 9-slice основа |
| `stylea_base_green` | `rbxassetid://73269138650834` | 9-slice основа |
| `stylea_base_orange` | `rbxassetid://99325442141416` | 9-slice основа |
| `stylea_base_ore_coal` | `rbxassetid://82195498687835` | 9-slice основа |
| `stylea_base_ore_copper` | `rbxassetid://85543755746970` | 9-slice основа |
| `stylea_base_ore_iron` | `rbxassetid://80741955091366` | 9-slice основа |
| `stylea_base_purple` | `rbxassetid://93955169790869` | 9-slice основа |
| `stylea_base_red` | `rbxassetid://75213556414551` | 9-slice основа |
| `stylea_base_yellow` | `rbxassetid://128897335984391` | 9-slice основа |
| `stylea_icon_x` | `rbxassetid://124007225953986` | іконка: білий X з темним контуром (кнопка закриття) |
| `stylea_tile_blue_half` | `rbxassetid://113459856671982` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_gray` | `rbxassetid://103426287107550` | тайл візерунка, повна сила (кнопки) |
| `stylea_tile_gray_half` | `rbxassetid://113147180553208` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_green` | `rbxassetid://126934743767489` | тайл візерунка, повна сила (кнопки) |
| `stylea_tile_green_half` | `rbxassetid://128344900362622` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_orange_half` | `rbxassetid://113641944698053` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_ore_coal_half` | `rbxassetid://108891956368661` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_ore_copper_half` | `rbxassetid://105948771467063` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_ore_iron_half` | `rbxassetid://75367734687427` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_purple_half` | `rbxassetid://109882000828143` | тайл візерунка, половинна сила (плитки, чипи) |
| `stylea_tile_red` | `rbxassetid://127394882942605` | тайл візерунка, повна сила (кнопки) |
| `stylea_tile_yellow_half` | `rbxassetid://113083714872033` | тайл візерунка, половинна сила (плитки, чипи) |
| `forge_ore_coal_v2` | `rbxassetid://128721473962141` | іконка руди у вікні кузні («кристали з каменя») |
| `forge_ore_copper_v2` | `rbxassetid://91559856120750` | іконка руди у вікні кузні («кристали з каменя») |
| `forge_ore_iron_v2` | `rbxassetid://89358844969060` | іконка руди у вікні кузні («кристали з каменя») |
| `forge_bar_iron_v2` | `rbxassetid://103278698396779` | іконка залізного злитка у вікні кузні (сіріша) |

**Оновлено 25.10.2026:** `ForgeConfig` — вугілля `smelt = false` + `canSmelt(o)`, `WAKE_MONEY = 1000`, тестовий старт $10 000; `PlotConfig` — картка `AutoSell` (`minStage = 2`), `CARD_ORDER` з 8 карток, `cardOpen(key, stage)`; `ItemConfig` — без злитка вугілля. Копії `.lua` у цій папці оновлено зі Studio.

**Оновлено 25.10.2026 (3):** новий [[GolemCatalog]] (каталог големів; бекап скриптів до нього — `ServerStorage/NicheBackup/Scripts_GolemCatalog_v1`); `ItemConfig` — големи й кольори рідкостей з каталогу, нові тестові големи; `PlotConfig` — стати з каталогу з мутацією, `PICKUP_R` 4,5 → 8,5; `ItemViewport` — 3D-голем у слотах. Копії `.lua` у цій папці оновлено зі Studio.

**Оновлено 25.10.2026 (4):** `ItemConfig` — іконки класів големів `class_*` (фільтр і бейдж класу в інвентарі). Копію `ItemConfig.lua` оновлено зі Studio (хеш 1652423437, 4 894 байти).

**Оновлено 25.10.2026 (5):** `StyleA.follow(obj, gui)` — елемент, що візуально належить кнопці, але лежить поруч (тінь-сусід, бейдж, підпис), масштабується (наведення 1,04 / натискання 0,92) і хитається разом з нею; якір переноситься в центр без зміни місця; `StyleA.shake` рухає й таких сусідів. Використовують ForgeWindow, SellWindow, PlotPlaceUI, PlotBoard, RollUpgradeUI, RollStationClient, ForgeClient. Копія `StyleA.lua` оновлена (хеш 1679900370, 21 359 байтів). Бекап — `ServerStorage/NicheBackup/Scripts_UIAudit_v1`.

**Оновлено 25.10.2026 (6):** новий рядок `UISounds` (модуль створив координатор, копія `UISounds.lua`, хеш 971899856). `StyleA` — звук `tap` у `bind` (опція `tap = false`), `StyleA.tap()`, `ICON_NUDGE` (хрестик X по центру грані — виправлення діє й в Inventory / Index). Копія `StyleA.lua` оновлена (хеш 2049789325, 23 178 байтів). Бекап — `ServerStorage/NicheBackup/Scripts_UIAudit_v3`.

**Оновлено 25.10.2026 (7):** `UISounds` — ключ `purchase` (SoundService/PurchaseSuccess; додав координатор), грає `ShopActions` при успішній покупці. Копія `UISounds.lua` оновлена (хеш 142459525, 1 438 байтів).

**Оновлено 26.10.2026:** `ItemConfig` — іконки інвентаря з чорним контуром: `ICONS.tab_*`, `trash`, `class_*` і `POTIONS[].icon` — нові ID; новий ключ `ICONS.lock_inv` (чорний замок для вікна інвентаря), `ICONS.lock` лишився синім (його бере `PlotPlaceUI`). Копію `ItemConfig.lua` оновлено зі Studio (хеш 1372145360, 5 906 байтів). Бекап — `ServerStorage/NicheBackup/Scripts_InvFilter_v7`.

**Оновлено 26.10.2026 (UISounds):** `UISounds.play(kind, minGap?, speed?)` — новий необов'язковий `speed`, множник PlaybackSpeed копії (висота тону); старі виклики працюють як раніше. Використовує автоповтор +/− у [Sell Shop](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FSell%20Shop%2FSell%20Shop). Бекап — `ServerStorage/NicheBackup/Scripts_UIAudit_v6`. Копію оновлено зі Studio (хеш 1698762278).

**Оновлено 26.10.2026 (statText):** `GolemCatalog.statText` — швидкість підписана: «2 dmg · Speed x1.05», «2 ore · Speed x1.13» (округлення до сотих: 1.125 → 1.13). Зміна координатора; копію оновлено зі Studio (хеш 467694355, 13 543 байти). Де показується: табличка голема в руці й на стенді печери, картка інвентаря, картки вікна PLOT N; у Index — «Speed x…».

**Оновлено 26.10.2026 (8):** новий `GolemSort` (сортування големів і кнопка SORT BY; іконка `sort_icon` — Image 120943936939331). Копія `GolemSort.lua` (хеш 1287286926, 11 386 байтів).

**Оновлено 26.10.2026 (мутації):** `GolemCatalog.MUTATIONS` — поля `gradient`, `speed`, `shine`; Secret — металевий `b8c4d0` (був червоний `ff3b5c`); новий `MutationText`; `GolemSort` — Newest нові першими, Best лише за силою (погоджено користувачем). Бекап — `ServerStorage/NicheBackup/Scripts_Sort_v2`. Копії: `GolemCatalog.lua` (хеш 1615569949, 14 795 байтів), `GolemSort.lua` (хеш 996954343, 11 406 байтів), `MutationText.lua` (хеш 1863455557, 4 961 байт).

**Оновлено 26.10.2026 (фон за мутацією):** новий `MutationSlotFX`; `GolemCatalog` — Secret: колір `bfefff`, градієнт голографічний (білий / блідо-ціан / блідо-рожевий). Бекап — `ServerStorage/NicheBackup/Scripts_MutSlots_v1`. Копії: `MutationSlotFX.lua` (хеш 891904921, 15 626 байтів), `GolemCatalog.lua` (хеш 928866946, 15 031 байт).

**Оновлено 26.10.2026 (стати / Void):** `NumberFormat.compact(n)` — до 1000 ціле, далі K / M / B з одним знаком вниз (98K, 54.4K, 1.5M, 2B); `MutationSlotFX` — Void у межах слота (ClipsDescendants не діє на нахиленому слоті); `ItemConfig.TEST_GOLEMS` — Stone Golem на кожну мутацію 0..7 + носії (25). Бекап — `ServerStorage/NicheBackup/Scripts_MutSlots_v2`. Копії: `NumberFormat.lua` (хеш 1926439283, 5 361 байт), `MutationSlotFX.lua` (хеш 1404306926, 15 989 байтів), `ItemConfig.lua` (хеш 1580541468, 6 185 байтів).

**Оновлено 26.10.2026 (Void / Rainbow):** `MutationSlotFX` — Void як металевий перелив (палітра 3d1478 · 7a2fd6 · a24bff · d9b8ff · 5a1fb0), Rainbow — насичена веселка (ff2a2a · ff8a00 · ffe600 · 22e04a · 00c8ff · 2a5cff · b02aff); `GolemCatalog` — градієнт тексту Rainbow той самий. Бекап — `Scripts_MutSlots_v3`. Копії: `MutationSlotFX.lua` (хеш 900730064, 14 156 байтів), `GolemCatalog.lua` (хеш 1685997381, 15 103 байти).

**Оновлено 27.10.2026 (Secret):** `GolemCatalog` — Secret чорно-графітовий (поля `textColor`, `stroke`); `MutationText` — колір тексту й обводки з мутації (`textColor`, `stroke`, відновлення обводки для інших); `MutationSlotFX` — Secret обсидіан + біло-сірий блиск, без кольорової аури. Бекап — `Scripts_MutSlots_v4`. Копії: `GolemCatalog.lua` (хеш 2059370398, 15 692 байти), `MutationText.lua` (хеш 1375431849, 5 900 байтів), `MutationSlotFX.lua` (хеш 59711267, 14 149 байтів).

**Оновлено 27.10.2026 (множник сили мутацій):** `GolemCatalog` — `MUTATIONS[].power` (M: 1 / 1,2 / 1,5 / 2 / 3 / 5 / 10 / 25), `stats` × M без зміни швидкості (шкода < 10 — до 0,1), нові `mult(mut)`, `num(n)`, `statText` без `%d` (2.4 dmg); `NumberFormat.compact` — дробові < 1000 з одним знаком. Бекап — `ServerStorage/NicheBackup/Scripts_MutPower_v1`. Копії: `GolemCatalog.lua` (хеш 1647669550, 17 026 байтів), `NumberFormat.lua` (хеш 51451764, 5 502 байти).

**Оновлено 27.10.2026 (звук відмови):** `UISounds` — ключ `deny` (`SoundService/Deny` — копія `Tap` з PlaybackSpeed 0,6, той самий глухий звук, що був на сірих кнопках печери); `tap` відкладено до кінця кадру й скасовується, якщо той самий клік скінчився `deny` (±0,12 с). `StyleA.shake` грає `deny` (minGap 0,15), новий `StyleA.deny()` — лише звук, для власних хитань у скриптах. Бекап — `ServerStorage/NicheBackup/Scripts_DenySound_v1`. Копії: `UISounds.lua` (хеш 1231386051  2 580 байтів), `StyleA.lua` (хеш 1651423630  23 712 байтів).

**Оновлено 27.10.2026 (ролли v1):** новий `GolemModel` (винесено з `CaveStandService`; копія — хеш 2122689687, 3 703 байти); `RollConfig` — таймінги анімації ролу, `revealTime`, `pick` (хеш 603855048, 4 321 байт). Бекап — `ServerStorage/NicheBackup/Rolls_v1`.

**Оновлено 27.10.2026 (аури мутацій v2):** новий [[MutationAura]] — аури лише з частинок (плями-сяйво й світло v1 прибрано). Бекап v1 — `ServerStorage/NicheBackup/MutationAura_v2_glow`. Копія: `MutationAura.lua` (хеш 1985725231, 22 869 байтів).

**Оновлено 27.10.2026 (аури мутацій v4-A):** `MutationAura` переписано під затверджений варіант A (комети + іскри + ромбики, без кіл і плям); нові текстури mg_aura4_*; текстури v2 (mg_aura_*) більше не використовуються. Бекап v2 — `ServerStorage/NicheBackup/MutationAura_v3`. Копія: `MutationAura.lua` (хеш 1169187163, 13 035 байтів).

**Оновлено 27.10.2026 (аури мутацій v5):** `MutationAura` — комети лише в Secret, Secret чорно-біла (шлейф білий → графіт, темні осколки, зірки-спалахи), Silver — світле срібло з блакитним; густіші іскри й жарини. Бекап v4-A — `ServerStorage/NicheBackup/MutationAura_v4`. Копія: `MutationAura.lua` (хеш 1362841020, 15 886 байтів).

**Оновлено 27.10.2026 (ролли, швидкість ×2):** `RollConfig` — поява 0,1 / оберт 0,5 / зникнення 0,1, хвиля 0,04 (хеш 1122036150, 4 411 байтів). Бекап — `ServerStorage/NicheBackup/Rolls_v5`.

**Оновлено 27.10.2026 (ролли v3, без обертання):** `RollConfig` — `TOTAL 2.0`, `FAKES 4`, `RESULT_APPEAR 0.2`, `cycle(n)` (цикл фейка під рівно 2 с з «хвилею»), `SPIN` прибрано (хеш 1066574917, 4 995 байтів). Бекап — `ServerStorage/NicheBackup/Rolls_v6`.

**Оновлено 27.10.2026 (Secret на темних фонах):** `GolemCatalog` — Secret тепер світлий перелив (9aa0a8 · dfe3e8 · ffffff · b4bac2 · f0f2f5 · a3a9b1) з графітово-чорною обводкою `14161a` і білим блиском, що біжить (без `textColor`; раніше темний текст 2a2c30 + біла обводка — на темних фонах майже не видно). `MutationText` — мітка без UIStroke отримує тимчасову обводку `MutationStroke` (1,5 px) для мутацій з полем `stroke`, `clear` її прибирає. Працює скрізь, де `MutationText.apply`: підказка хотбара, картка інвентаря, пігулки й картка Index, таблички над големом (MutationTextClient). Бекап — `ServerStorage/NicheBackup/SecretText_v1`. Копії: `GolemCatalog.lua` (хеш 1175939314, 21 273 байти), `MutationText.lua` (хеш 213433591, 6 525 байтів).

**Оновлено 27.10.2026 (ліміт големів):** `ItemConfig` — нова `invGolemCount(golems, placed)`: кількість големів в інвентарі без тих, що на плотах (для ліміту `MAX_GOLEMS` = 300 і лічильників). Копія: `ItemConfig.lua` (хеш 471059085, 7 140 байтів; у старій копії ще був `MAX_GOLEMS = 40` — оновлено).

**Оновлено 27.10.2026 (одне вікно):** новий `WindowManager` — правило «на екрані лише одне вікно» ([GDD - Interface](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Interface)). Копія: `WindowManager.lua` (хеш 720532859, 1 163 байти). Бекап змінених скриптів — `ServerStorage/NicheBackup/OneWindow_v1`.

**Оновлено 27.10.2026 (префаби предметів):** [[GolemCatalog]] — поля `pickaxe` / `sword` і новий `applyClassItems(model, cls, strip?, kind?)`: кірка й меч — клони префабів з `PlotAssets` у кулак ([Item Prefabs](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FInstruments%2FItem%20Prefabs%2FItem%20Prefabs)). `GolemModel` — лише коментарі. Бекап — `ServerStorage/NicheBackup/ItemPrefabs_v1`. Копії: `GolemCatalog.lua` (хеш 1224903926, 23 374 байти), `GolemModel.lua` (хеш 1605368063, 3 636 байтів).

**Оновлено 27.10.2026 (Clay Golem):** [[GolemCatalog]] — `clay` отримав `model`, `box`, `pickaxe`, `sword` ([Clay Golem](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FGolems%2FClay%20Golem%2FClay%20Golem)); новий модуль даних `ClayGolemData` у моделі `ClayGolem`. Бекап — `ServerStorage/NicheBackup/ClayGolem_v1`. Копії: `GolemCatalog.lua` (хеш 1727601854, 23 474 байти), `ClayGolemData.lua` (хеш 961405660, 16 861 байт).

**Оновлено 28.10.2026 (удача):** `RollConfig.pick` — перевірки від найрідшого, шанс `min(1, M/N)`, `M = 1 + luck/100`; удача без стелі. [[GDD - Roll]]

**Оновлено 28.10.2026 (ребітхи):** `MultiConfig` — `REBIRTH_ENABLED = true` (множник 2^Rebirths), `REBIRTH_BASE` 100 000, `REBIRTH_GROWTH` 5, `REBIRTH_LIMIT` 5, `REBIRTH_PER_STAGE` 3; функції `rebirthPrice(n)`, `rebirthLimit(stage)`, `rebirthStageFor(n)`.

**Оновлено 28.10.2026 (Shop):** `MonetizationConfig.Passes` — VIP, Lucky, AutoEquip, FastForge, AutoCollect (id, robux, order, featured, name, desc, icon, tone); `TICKET_RATE` 1,25, `ticketPrice(robux)`; MoreCrates прибрано.

**Оновлено 28.10.2026 (Shop v4):** `RollConfig` — STANDS_BASE 5, STANDS_MAX 7, `totalStands(p)`; `ItemConfig.maxGolems(p)`; `MonetizationConfig` — MutLucky, RollStand1/2, Products StarterPack / ExtraStorage, MUT_SPEED_TIERS.

## Додано в індекс 29.10.2026

| Файл | Де в Roblox | Що робить |
| --- | --- | --- |
| `MutationConfig.lua` | `ReplicatedStorage/Shared/MutationConfig` | Mutation Machine: 2 машини × 3 слоти, таймери за GDD (15 хв … 120 год), `left` / `progress` / `fmt`, `same` (та сама назва, клас, мутація). [[GDD - Mutation Machine]] |
| `StallShopConfig.lua` | `ReplicatedStorage/Shared/StallShopConfig` | лавки в кінці зали: оновлення (Diamonds 30 хв, Events 3 год), скіпи (вага, кількість, ціна в 💎), кількість видів, рідкісні геймпаси, кольори рідкостей. [[GDD - Diamonds Shop]] |
| `HubConfig.lua` | `ReplicatedStorage/Shared/HubConfig` | числа центральної зали: Marketplace (коло, відлік, PLACE_ID), лідерборди (`BOARDS`), магазини, мутаційні установки, груповий голем |
| `CurrencyFly.lua` | `ReplicatedStorage/Shared/CurrencyFly` | іконки тікетів / діамантів летять до лічильника в HUD (покупки, нагороди квестів) |
| `WorkshopRig.lua` | `ReplicatedStorage/Shared/WorkshopRig` | скелет 6-рукого голема-майстра Workshop (на основі ForgeRig) — чернетка |
| `WorkshopGolem.lua` | `ReplicatedStorage/Shared/WorkshopGolem` | модель голема-майстра «Брасс» (латунь, мідь, топка в грудях, 6 рук) — чернетка |
| `MushroomGolemData.lua` | `Workspace/PlotPrefabs/MushroomGolem/GolemData` → `ReplicatedStorage/PlotAssets` | модель Mushroom Golem (кольори, кістки, 105 блоків) для групового голема. [[GDD - Monetization]] |
| `GolemCatalog.lua` | `ReplicatedStorage/Shared/GolemCatalog` | (оновлено 29.10.2026) `mushroom` (Exclusive, `dynamic = "bestMiner"`), `bestMinerDmg`, `ownerOf`, параметр `p` у `stats` / `power` / `statText` |
