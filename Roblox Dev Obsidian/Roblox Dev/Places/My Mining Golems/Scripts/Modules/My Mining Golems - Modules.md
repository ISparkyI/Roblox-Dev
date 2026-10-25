# Modules

← [[My Mining Golems - Scripts|Scripts]]

ModuleScript — дані й модулі.

| Файл | Де в Roblox | Що містить |
| --- | --- | --- |
| `GolemData.lua` | `Workspace/StoneGolem/GolemData` | палітра, 18 кісток і 67 блоків: 52 блоки кам'яного голема v2 + 15 блоків інструмента в руці (`group = "Pickaxe"`, `bone = "Forearm_L"`). Усі блоки мають повний `cf` у координатах моделі |
| `ForgeConfig.lua` | `ReplicatedStorage/Shared/ForgeConfig` | числа Forge: руди мапи 1 (ціни, кольори), множник злитка ×1,5 (`BAR_MULT`), вимоги для пробудження 20 / 10 / 5, радіус кола 8,64, слово стану без руди `WAIT_WORD` («WAITING»), формули місткості, швидкості (до `SPD_MIN` = 0,25 с, `spdMax`) і Ore per Hit (`ophOf`, `OPH_MAX` = 10, `ophPrice`) та їхніх цін, тестовий старт, `TEST_SELL_BARS = false` (злитки з кузні — в інвентар). Ціни руди й `BAR_MULT` бере й лавка Sell |
| `ForgeRig.lua` | `ReplicatedStorage/Shared/ForgeRig` | скелет голема-коваля (деталі Stone Golem + обличчя + фартух + молот), суглоби, пози (сон, робота, відпочинок), ходьба, цикл удару молотом. Масштаб сцени `S = 1.8` (пози у веб-одиницях, `rootCF` множить на S і піднімає на 0,1 стада); спідниця фартуха кріпиться до тулуба й висить прямо |
| `SellRig.lua` | `ReplicatedStorage/Shared/SellRig` | анімації голема-продавця Наґґета (з веб-макета Sell Shop): базова поза `BASE`, 11 анімацій ключовими кадрами (rest, coin, abacus, glance, rub, greet, waitRest, tap, rubW, sell, bye), особливі дії `SPECIAL`, довжини рук для IK, полюси ліктів, радіус кола |
| `RollConfig.lua` | `ReplicatedStorage/Shared/RollConfig` | числа покращень ролу за GDD: Roll Luck (5% за рівень, ціна 1 000 → ×(4 − 0,05·(n−1)), мін. ×1,25), місця ролу 1 → 5 (500 × 3^(k−1) × множник мапи), множник мапи ×1, ×5, ×40, ×440 … Спільний для сервера й екрана |
| `StyleA.lua` | `ReplicatedStorage/Shared/StyleA` | елементи UI «стиль A» з картинок (GDD «2D іконки», розділи 2–3): 9-slice основа (ImageButton / ImageLabel, `ScaleType Slice`, `SliceCenter Rect(14, 14, 386, 160)`, `SliceScale = H / 200`) + тайл візерунка «квадратик + L» (`ScaleType Tile`, клітинка = висота грані / 4 або / 3), обрізаний рамкою грані (`ClipsDescendants`) + необов'язкові іконка й TextLabel (Montserrat Heavy, білий, контур #14161a). Кольори: green, gray, red, blue, orange, yellow, purple, ore_coal, ore_copper, ore_iron; `half = true` — візерунок половинної сили (плитки, чипи). `StyleA.new(parent, opts)` → об'єкт з `:setColor` / `:setText` / `:setIcon` / `:setSize` / `:setPosition` / `:destroy`; `StyleA.bind(obj, opts)` — поведінка кнопки: наведення 1,04, натискання 0,92 з пружним поверненням, недоступна — хитається; також `StyleA.shake`, `faceRect`, `sliceScale`. ID картинок — таблиця `StyleA.ASSETS` (27 шт., див. нижче). Підключають ForgeWindow, ForgeClient, RollUpgradeUI |
| `CardHover.lua` | `ReplicatedStorage/Shared/CardHover` | наведення на картки покращень (клієнт): `CardHover.holder(parent, x, y, w, h, extraBottom)` — тримач `CanvasGroup` з центром у середині картки (запас `PAD` 16), повертає тримач і зсув для малювання; `CardHover.attach(holder, hit, enabled?, base?)` — при наведенні ×1,05 від `base` і нахил до 3° у бік мишки, плавно (RenderStepped, один цикл на всі картки). У `SurfaceGui` позицію мишки на полотні рахує променем з камери на грань. Звук наведення бере зі спільного `UIHover` і позначає картку атрибутом `HoverSoundBy`, щоб автозвук кнопок не грав двічі. `CardHover.surfaceX(gui, point?)` — x мишки (або точки) на полотні SurfaceGui, для повзунка й перетягування карток табла кузні. Підключають RollUpgradeUI (base 0,95) і ForgeClient (base 0,85) |
| `PlotConfig.lua` | `ReplicatedStorage/Shared/PlotConfig` | плоти ([GDD - Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Plots)): руда мапи 1 (HP 5 / 15 / 30, шанси 1 до 3 / 9 / 20, `rollOre`), картки `CARDS` (Plots, Ore Spawn, Golem Slots, Carrier Speed — макс. рівні й ціни), `spawnOf` (5 с → 0,25 с), `slotsOf`, `carryOf` (×1 → ×3), статистика тестових големів `GOLEMS` (майнер `dmg` / `int`, носій `cap` / `spd`), константи руху й стаків, `AUTO_EQUIP_PASS`. Спільний для сервера й клієнта |
| `ItemConfig.lua` | `ReplicatedStorage/Shared/ItemConfig` | предмети інвентаря: големи (назва, рідкість, іконка; тестові — `"вид"` або `"вид:carrier"`), зілля (назва, колір, опис, іконка), кольори рідкостей і руди, іконки вкладок / кошика / замка, розмір хотбара (9), ліміт големів (40), тестові големи й зілля, `stackKeys`, `isStack`. Спільний для сервера й клієнта |
| `MultiConfig.lua` | `ReplicatedStorage/Shared/MultiConfig` | глобальні множники Money: бонус за друга (0,25), VIP ×2, ребіти (вимкнено), таблиця мап `STAGE_MULTS`, драбина донату `DONATE_TIERS` (множник і ціна R$), ціни драбини — за [GDD - Monetization](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Monetization), рядки плашки `SOURCES` (Friends, Rebirth, Money Boost, VIP, Map — з власними іконками `hud_vip` / `hud_map`). Функції `friendsMult`, `rebirthMult`, `donateMult`, `nextDonateMult`, `nextDonatePrice`, `stageMult`. Спільний для сервера й HUD |
| `MonetizationConfig.lua` | `ReplicatedStorage/Shared/MonetizationConfig` | ID геймпасів (`Passes`: VIP, MoreCrates) і Developer Products ступенів x2 Money (`MoneyTierProducts`, 21 ID, створені 24.10.2026); 0 — ще не створено в Creator Hub (геймпаси поки 0) |
| `ItemViewport.lua` | `ReplicatedStorage/Shared/ItemViewport` | 3D-іконки руди й злитків у слотах вікон: ViewportFrame з Union з `Prefabs/ForgeProps`, темний контур (8 силуетів), `VIEW` — кут, масштаб і зсув для кожної моделі; `ItemViewport.set(label, key, scale?)` |
| `WindowFit.lua` | `ReplicatedStorage/Shared/WindowFit` | одне правило розміру й місця для всіх вікон: `WindowFit.place(modalRoot, fitScale, { canvasW, canvasH, winX, winY, winW, winH, extraH? })` — рамка ≈68 % ширини, заголовок + рамка ≈72 % висоти, по центру між верхньою смугою Roblox і хотбаром; на телефоні — максимум з полями. Правило: вміст не влазить — гортати, вікно не збільшувати |
| `UISfx.lua` | `ReplicatedStorage/Shared/UISfx` | прості UI-звуки з `SoundService`: `UISfx.play("BuySound")` тощо |
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
