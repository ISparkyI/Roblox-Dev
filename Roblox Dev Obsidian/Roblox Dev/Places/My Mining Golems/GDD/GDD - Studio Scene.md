---
tags: [gdd, place, studio]
status: draft
updated: 2026-10-25
---

# GDD - Studio Scene

← [[My Mining Golems - GDD|GDD]]

Як гра зібрана в Roblox Studio: що де лежить в Explorer, система ніш і технічні правила.

**Детально:** [Scripts](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FMy%20Mining%20Golems%20-%20Scripts) · [Main Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FMain%20Cave%2FMain%20Cave)

## Що де в Explorer
Плейс опубліковано як **My Mining Golems** (placeId 121679937506068). Перший прототип (голем б'є одну брилу в `Workspace`) прибрано: тепер усе працює в нішах гравців.

| Що | Де в Explorer | Тип |
| --- | --- | --- |
| Шаблон голема на плотах (Stone Golem v2, 68 Part; аніматор з Carry і LOD) | `ReplicatedStorage/PlotAssets/Golem` | Model |
| Жили руди Coal / Copper / Iron (S / M / L; реакція на удар `OreShake`) | `ReplicatedStorage/PlotAssets/Ores` | Model |
| Шматки руди, ящичок носія, звук удару кірки | `ReplicatedStorage/PlotAssets/Chunks`, `CarryBox`, `PickaxeHit` | Model, Sound |
| Ефект уламків | `ReplicatedStorage/Effects/HitChips` | ModuleScript |
| Формат чисел | `ReplicatedStorage/Shared/NumberFormat` | ModuleScript |
| Інвентар: вікно, хотбар, дії (`Remotes/InventoryAction` створює сервер), дані предметів | `StarterPlayerScripts/InventoryUI`, `ServerScriptService/InventoryService`, `ReplicatedStorage/Shared/ItemConfig` | LocalScript, ModuleScript |
| Фонова музика, гучність кроків | `StarterPlayerScripts/BackgroundMusic`, `FootstepVolume` | LocalScript |
| Тестова печера (карта) | `Workspace/Cave` (Floors, Shell, Hall, Greenery, Patch, CrackLights) — без ніш | Model |
| Сокети ніш | `Workspace/NicheSockets/Socket1L…3R` | Part (невидимі) |
| Префаб ніші, мапа 1 (шаблон; на старті сервера переїжджає в `ServerStorage/NichePrefabs`) | `Workspace/NichePrefabs/NichePrefab_Stage1` | Model |
| Спавн плота (невидимий, перед станцією ролу, обличчям до неї) | `…/NichePrefab_Stage1/PlotSpawn` | Part |
| 6 ніш у печері (сервер збирає їх із шаблону на старті) | `Workspace/Niches/Niche1…6` | Model |
| Система ніш: автоклейм, телепорт, скидання | `ServerScriptService/NicheService` | ModuleScript |
| Запуск системи ніш і кузень | `ServerScriptService/NicheBoot` | Script |
| Forge (кузня, правий передній кут ніші, ×1,8): навіс з дощатою стінкою, голем-коваль, ковадло, піч, бочка, відерце, ящики (`Props`), піддони, коло, табло покращень (`UpgradePanel` — копія табла Time Skip) | `…/NichePrefab_Stage1/Forge` | Model |
| Логіка Forge: пробудження, піддони, переплавка, покращення з кліку по табло, `Put` (вся руда) і `PutOre` (одна руда в потрібній кількості; руда й гроші поки — тестові атрибути гравця) | `ServerScriptService/ForgeService` | ModuleScript |
| Анімація голема-коваля, печі (вогонь, міх, звуки), заготовки на ковадлі, іскор + екран табла покращень (SurfaceGui, клік мишкою) + статус на табличці над колом (WAITING…) | `StarterPlayerScripts/ForgeClient` | LocalScript |
| Вікно кузні по центру екрана (стиль A): чипи стану, шкали, рядки Coal / Copper / Iron, кнопки Give Ore / Wake Up / Put All Ore / Take Bars, синій плюсик на плитках руди й попап вибору кількості (повзунок, All, Put N), зелена смуга переплавки, WAITING… | `StarterPlayerScripts/ForgeWindow` | LocalScript |
| Табло Roll Upgrades (падає зі стелі, коли власник стоїть біля станції ролу): зона й таймер на сервері, екран і анімація на клієнті, покупки Roll Luck / Roll Stands, поява підставок | `ServerScriptService/RollScreenService`, `RollUpgradeService`; `StarterPlayerScripts/RollScreenClient`, `RollUpgradeUI`, `RollStandFX`; `ReplicatedStorage/Shared/RollConfig`, `Remotes/RollUpgrade` | Script, LocalScript, ModuleScript |
| Елементи UI «стиль A» (9-slice кнопки, чипи, плитки) і наведення на картки | `ReplicatedStorage/Shared/StyleA`, `CardHover` | ModuleScript |
| Лічильник грошей (HUD, низ ліворуч): сума, множник, «+», анімація нарахування | `StarterPlayerScripts/MoneyHUD` | LocalScript |
| Числа Forge / скелет і пози голема-коваля | `ReplicatedStorage/Shared/ForgeConfig`, `ForgeRig` | ModuleScript |
| Дії гравця в колі Forge | `ReplicatedStorage/Remotes/ForgeAction` | RemoteEvent |
| Sell (лавка скупщика, лівий передній кут ніші): навіс, прилавок, голем-продавець Наґґет, ваги, рахівниця, дзвоник, сейф, вагонетка, дошка цін (`PriceBoard`), зелене коло з табличкою SELL | `…/NichePrefab_Stage1/Sell`, `Workspace/Niches/Niche*/Sell` | Model |
| Анімації голема-продавця (спокій + особливі дії, вітання, продаж за `SellSeq`, прощання), ефекти, дошка цін мапи, табличка SELL | `StarterPlayerScripts/SellClient`, `ReplicatedStorage/Shared/SellRig` | LocalScript, ModuleScript |
| Вікно продажу SELL (слоти руди й злитків, +/−, міні-меню з повзунком, гортання) | `StarterPlayerScripts/SellWindow` | LocalScript |
| Дія продажу (`Remotes/SellAction`): перевірки, Money, `SellSeq` / `SellAmount` | `ServerScriptService/SellService` | ModuleScript |
| Швидкість гравця ×1,75 (28 замість 16) | `StarterPlayer.CharacterWalkSpeed = 28` | налаштування |
| Головний HUD: усі кнопки, лічильники діамантів / тікетів / ребітхів, x2 Money (підпис і ціна за `DonateTier`), Rebirth, Boss і таймер | `StarterPlayerScripts/MainHUD` | LocalScript |
| Покупка наступного ступеня x2 Money (кнопка `X2Money`) | `StarterPlayerScripts/ShopActions` | LocalScript |
| Звук наведення на всі кнопки (+ однаковий звук карток) | `StarterPlayerScripts/UIHoverAuto`, `ReplicatedStorage/Shared/UIHover`, `SoundService/ButtonHover` | LocalScript, ModuleScript, Sound |
| Збереження даних гравця (DataStore, сесійне блокування) | `ServerScriptService/DataService` | ModuleScript |
| Глобальні множники Money (сервер) | `ServerScriptService/MultiService`, `ReplicatedStorage/Shared/MultiConfig` | ModuleScript |
| Покупки за Robux: ступені x2 Money, геймпаси | `ServerScriptService/MonetizationService`, `ReplicatedStorage/Shared/MonetizationConfig` | ModuleScript |
| Генератор префаба ніші | `ServerStorage/NicheTools/NichePrefab` | ModuleScript |
| Плоти (зони фарму) 1–6 у ніші (PlotBuilder v2): «зламана» платформа, бортик, ящик-приймальник, напис PLOT N; папки `Ores` / `Drops` / `Golems` | `…/NichePrefab_Stage1/Plots/Plot1…6` | Model |
| Генератор плотів (старі `plot1…6` і ящик користувача — у `ServerStorage/NicheBackup`) | `ServerStorage/NicheTools/PlotBuilder` | ModuleScript |
| Логіка плотів: спавн руди, майнери, носій, стаки, руда в інвентар, картки, `Remotes/PlotAction` | `ServerScriptService/PlotService`, `ReplicatedStorage/Shared/PlotConfig` | ModuleScript |
| Рух големів, ящичок носія, ріст / HP-бар / руйнування руди, світні стаки, наповнення ящика, кнопка COLLECT, LOCKED | `StarterPlayerScripts/PlotClient` | LocalScript |
| Шаблони плоту: голем (аніматор з Carry і LOD), руда Coal / Copper / Iron, шматки руди, ящичок носія | `ReplicatedStorage/PlotAssets` | Folder |
| Табло прокачки плоту (8 карток, Auto Sell — MAP 2) і вікно розстановки Place Golems | `StarterPlayerScripts/PlotBoard`, `PlotPlaceUI` | LocalScript |
| Станція ролу: пульт з екраном вибору типу голема, лампи, тумба з важелем, кнопка E · ROLL (старий важіль — `NicheBackup/RollLeverModel_old_v1`) | `…/NichePrefab_Stage1/RollSystem/RollLeverModel`, `StarterPlayerScripts/RollStationClient`, `ServerScriptService/RollRoleService`, `Remotes/RollRole` | Model, LocalScript, Script |
| Вхід у печеру големів: горб, темний прохід, жовте коло, напис CAVE, кнопка E · ENTER CAVE (затиск 0,9 с) | `…/NichePrefab_Stage1/GolemCave`, `ServerScriptService/CaveEntrance` | Model, Script |
| Печера-сховище големів: шаблон, копія на кожну зайняту нішу, права власника / гостя | `Workspace/Cave_Inside` (у грі → `ServerStorage/CaveInsideTemplate`, копії `Workspace/Caves/Cave_<N>`), `ServerScriptService/CaveService`, `ReplicatedStorage/Shared/CaveAccess` ([Golem Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FGolem%20Cave%2FGolem%20Cave)) | Model, Script, ModuleScript |
| Свої підказки E (`Style = Custom`) | `StarterPlayerScripts/CustomPrompts` | LocalScript |
| Моделі руди й злитків (Union у стилі жил) | `ReplicatedStorage/Prefabs/ForgeProps` (`ChunkCoal/Copper/Iron`, `BarCopper/Iron`), вихідні — `ServerStorage/ForgeChunkSources` | UnionOperation |
| 3D-іконки руди й злитків у слотах; один розмір і місце всіх вікон | `ReplicatedStorage/Shared/ItemViewport`, `WindowFit` | ModuleScript |
| Спавн у печері | `Workspace/Cave/CaveSpawn` (старий `SpawnLocation` вимкнено) | SpawnLocation |

Повні таблиці скриптів — [Client](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FClient%2FMy%20Mining%20Golems%20-%20Client), [Server](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FServer%2FMy%20Mining%20Golems%20-%20Server), [Modules](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FModules%2FMy%20Mining%20Golems%20-%20Modules). Сама печера, сокети й префаб ніші — [Main Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FMain%20Cave%2FMain%20Cave).

## Ніші в печері й автоклейм плота
- На старті сервера шаблони з `Workspace/NichePrefabs` переїжджають у `ServerStorage/NichePrefabs`, а `Workspace/Niches` збирається заново: у кожен із 6 сокетів (порядок `1L, 1R, 2L, 2R, 3L, 3R`) ставиться свіжа копія шаблону мапи 1. Копії `Niche1…6` в редакторі — тільки для перегляду; **джерело правди — шаблон**, правки вносити в нього.
- Гравець заходить → сервер видає йому першу вільну нішу (атрибут гравця `NicheIndex`) і при кожній появі персонажа телепортує на `PlotSpawn` своєї ніші (перед важелем, обличчям до нього).
- Вільна ніша = мапа 1 без власника: зони фарму порожні, табличка «Free Mine», UI на таблах вимкнений. Зайнята — табличка з ім'ям власника, UI увімкнений.
- Гравець виходить → ніша скидається до свіжої копії мапи 1.
- Атрибути ніші: `NicheIndex`, `Socket`, `Stage`, `OwnerUserId` (0 = вільна). Мапа гравця поки з атрибута гравця `Stage` (за замовчуванням 1) — шаблон `NichePrefab_Stage<N>`.
- API для інших систем: `GetNiche(player)`, `GetOwner(niche)`, події `Claimed` / `Released` (player, niche).
- На сервері максимум 6 гравців: `MaxPlayers = 6` треба поставити в Game Settings.

## Технічні правила
- Масштаб моделей: 1 од. = 0,5 стада; обличчя в +Z моделі, у Roblox — в −Z.
- Анімації й ефекти виконуються на клієнті. Економіка, роли, торгівля й збереження — **тільки на сервері**.
- Studs: `Texture`, видно на 80%. Моделі — `StudsPerTile 0.25`, карта — `StudsPerTile 1`.
