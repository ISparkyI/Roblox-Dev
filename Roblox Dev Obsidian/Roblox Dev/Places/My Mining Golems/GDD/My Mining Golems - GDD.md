---
tags: [gdd, place]
status: draft
version: 42
updated: 2026-10-25
---

# GDD

← [[My Mining Golems]]

> [!summary] Коротко
> Мультиплеєрний tycoon на 6 гравців у величезній печері. У кожного гравця своя ніша (плот). У зонах фарму (плотах) ніші големи-майнери ламають руду, а голем-носій збирає шматки з підлоги й висипає в ящик плоту, а звідти гравець забирає руду в інвентар (кнопка COLLECT). Гравець продає руду в магазині (дешево) або несе в **Forge**, де голем-коваль переплавляє її в дорожчі злитки, і отримує Money. За Money гравець ролить і купує нових големів, прокачує плот і роли. Далі він переходить на нові мапи печери і робить ребітхи. Рідкісних і мутованих големів можна покращувати в Mutation Machine, торгувати ними на маркетплейсі та виставляти воїнами проти боса.

> [!note] Позначки
> **(пропозиція)** — число або правило, яке запропонував Claude для старту балансу; міняємо після тестів. *(уточнити)* — ще не вирішено.

Це **загальний** GDD: що за гра, з чого складається і як усе пов'язано. Кожна система описана детально у своїй нотатці (таблиця «Системи»), а кожен об'єкт, модель, вікно чи локація — у своїй нотатці в розділах плейсу (таблиця «Де що описано»).

## 1. Концепція
- **Жанр:** tycoon / idle-mining з ролами (gacha), колекцією й торгівлею.
- **Фантазія гравця:** власник бригади големів-шахтарів, яка росте від дерев'яного голема до армії рідкісних мутованих големів.
- **Сервери:** основна гра — 6 гравців; маркетплейс — до 60; арена боса — до 20.
- **Візуальний стиль:** блоковий стиль моделей зі studs.
- **Аудиторія:** 8–16 років, ПК і мобільні.

## 2. Карта
### 2.1 Головна печера
Печера **продовгувата**: довгий центральний прохід згори вниз, по боках ніші гравців. По центру над головою трохи видно небо.

![[map_sketch.png]]

| Де (згори вниз) | Що там |
| --- | --- |
| Верхній край | **телепорт на івент з босом** (арка в стіні, відкривається раз на 10 хв) |
| Під ним | 2 лідерборди обабіч проходу |
| Центр | **телепорт на маркетплейс** (круглий портал) |
| Під телепортом | **стенд нагороди за групу** (для новачків) |
| Нижче | **Mutation Machine** (довга машина вздовж проходу) |
| Нижній край | **Diamonds Shop** (2 прилавки) |
| Ліворуч і праворуч | **6 ніш гравців**, по 3 з кожного боку, відкриті в прохід |

Будова печери в Studio (прохід, площа, сокети ніш) — [Main Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FMain%20Cave%2FMain%20Cave).

### 2.2 Ніша гравця
Кожен гравець отримує свою нішу (6 ніш, по 3 з кожного боку проходу). Вигляд ніші залежить від мапи; кожна мапа — готовий префаб (мапа 1 — [Niche Stage 1](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FNiche%20Stage%201%2FNiche%20Stage%201)).

| Що в ніші | Де | Детально |
| --- | --- | --- |
| **6 плотів** (зони фарму 44 × 44), купуються 1 → 6 | уздовж ніші, 3 + 3 | [[GDD - Plots]], [Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FPlots%2FPlots) |
| **Ящик плоту** з кнопкою COLLECT | внутрішній передній кут кожного плоту | [Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FPlots%2FPlots) |
| **Станція ролу** (вибір типу голема, важіль E · ROLL), 1–5 підставок ролу, табло покращень ролу | біля спавну гравця (спавн дивиться на станцію) | [[GDD - Roll]], [Roll Station](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FRoll%20Station%2FRoll%20Station), [Roll Upgrades Screen](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FRoll%20Upgrades%20Screen%2FRoll%20Upgrades%20Screen) |
| **Вхід у печеру големів** (CAVE, затиск 0,9 с → печера-сховище ніші) | у ніші | [Cave Entrance](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FCave%20Entrance%2FCave%20Entrance) |
| **Печера-сховище големів** (своя на кожну нішу, 14 стендів; автор — друг користувача, стенди ще без логіки) | окремо під картою | [Golem Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FGolem%20Cave%2FGolem%20Cave) |
| **Табло прокачки плоту** (8 карток) | ліворуч від лавки SELL | [[GDD - Plots]] |
| **Forge** — голем-коваль, переплавка руди в злитки | правий передній кут біля входу | [[GDD - Ores and Bars]], [Forge](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FForge%2FForge) |
| **Sell** — лавка скупщика Наґґета | лівий передній кут біля входу | [[GDD - Ores and Bars]], [Sell Shop](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FSell%20Shop%2FSell%20Shop) |
| Особистий борд гравця | біля ніші | [[GDD - Leaderboards]] |
| Магазин предметів за Money | *(уточнити)* | — |

### 2.3 Інші місця
- **Печера збереження** (вхід — Cave Entrance у ніші): слоти (купуються за Money, ліміт наприклад 15) для големів, які переживуть перехід на наступну мапу.
- **Утилізація:** місце, де можна позбутися непотрібних големів ([[GDD - Golems]]).
- **Арена боса** і **маркетплейс** — окремі сервери ([[GDD - Boss Events]], [[GDD - Marketplace]]).

## 3. Основний цикл
1. На відкритих плотах у вільних місцях виростає руда мапи (3 види за шансами, жила S / M / L — [[GDD - Ores and Bars]]) — росте на очах.
2. Майнери ламають руду (знімають їй HP; над рудою міні HP-бар).
3. Зламана руда падає 1–3 шматками на підлогу. Шматки світяться; шматки однієї руди поруч зливаються в стак з написом ×N. Стак, який ніхто не підібрав 30 с, зникає.
4. Носій збирає шматки у свій ящичок і висипає в ящик плоту; гравець забирає руду з ящика кнопкою **COLLECT** (або підбирає стаки сам).
5. Гравець продає руду:
   - **у магазині (скупщик / Sell)**: одразу, але дешево, з невеликим прибутком;
   - **через Forge**: кладе руду на піддон, голем-коваль переплавляє її в злитки, гравець забирає злитки й продає ([[GDD - Ores and Bars]]).
6. Магазин платить Money: **ціна × множник плоту × множник ребітху × глобальний множник (геймпас)**. Ціна руди — з таблиці в [[GDD - Ores and Bars]], ціна злитка — ціна руди × 1,5 (`ForgeConfig.BAR_MULT`). Вугілля не плавиться — його лише продають.
7. Money йде на роли й покупку големів ([[GDD - Roll]]), покращення, слоти збереження, ребітхи й перехід на мапу.

**Перенесення ящиків — скасовано:** руду з ящика плоту гравець забирає кнопкою COLLECT на місці, тож геймпас «Більше ящиків» і голем-збирач не потрібні.

## 4. Системи
Детальний дизайн кожної системи — у своїй нотатці:

| Система | Що там |
| --- | --- |
| [[GDD - Golems]] | класи (майнер, носій, воїн), рідкість, мутації, каталог, формули, утилізація, як працює удар |
| [[GDD - Roll]] | вибір типу на станції, шанси «1 до N», Roll Luck, анімація ролу, підписи над големами, покращення ролу |
| [[GDD - Plots]] | 8 карток прокачки плоту й ціни, множник цін на нових мапах, поведінка големів на плоті, Place Golems |
| [[GDD - Maps]] | 6 мап печери, нова рідкість і руди кожної, ціна переходу, що скидається |
| [[GDD - Ores and Bars]] | руда всіх мап (шанси, ціни, HP), Forge (пробудження, переплавка, табло), Sell (продаж, правила) |
| [[GDD - Currencies and Rebirths]] | Money, діаманти, тікети, руда й злитки; ребітхи |
| [[GDD - Monetization]] | геймпаси, кейси, TOTAL MULTI, драбина x2 Money і ID продуктів, стенд для новачків |
| [[GDD - Diamonds Shop]] | скіпалки часу за діаманти |
| [[GDD - Mutation Machine]] | 3 → 1 з наступною мутацією, таймери |
| [[GDD - Quests and Index]] | щоденні, тижневі, спеціальні квести; Index |
| [[GDD - Boss Events]] | бос раз на 10 хв, арена, нагороди, мутації боса, Cracked Colossus |
| [[GDD - Marketplace]] | торгівля големами, логування угод |
| [[GDD - Leaderboards]] | лідерборди в печері, особистий борд |
| [[GDD - Interface]] | HUD, правила вікон, підказки E, інвентар і хотбар |
| [[GDD - Data Saving]] | DataStore, сесійний замок, що зберігається |
| [[GDD - Studio Scene]] | що де в Explorer, ніші й автоклейм, технічні правила |

## 5. Де що описано
Об'єкти, моделі, вікна й локації мають свої нотатки в розділах плейсу:

| Розділ | Нотатки |
| --- | --- |
| Interactive Objects | [Roll Station](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FRoll%20Station%2FRoll%20Station), [Roll Upgrades Screen](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FRoll%20Upgrades%20Screen%2FRoll%20Upgrades%20Screen), [Cave Entrance](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FCave%20Entrance%2FCave%20Entrance), [Forge](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FForge%2FForge), [Sell Shop](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FSell%20Shop%2FSell%20Shop), [Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FPlots%2FPlots) |
| 3D Models | [Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FGolems%2FGolems) (Stone, Forest, Wooden), [Ores](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FOres%2FOres) (Coal Ore, Copper Ore, Iron Ore), [Bars](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FBars%2FBars) (Copper Bar, Iron Bar), [Instruments](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F3D%20Models%2FInstruments%2FInstruments) (Pickaxe, Carrier Crate) |
| 2D | [Main HUD](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F2D%2FMain%20HUD%2FMain%20HUD), [Money HUD](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F2D%2FMoney%20HUD%2FMoney%20HUD), [Inventory](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F2D%2FInventory%2FInventory) |
| Locations | [Main Cave](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FMain%20Cave%2FMain%20Cave), [Niche Stage 1](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FNiche%20Stage%201%2FNiche%20Stage%201) |
| Scripts | [Scripts](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FMy%20Mining%20Golems%20-%20Scripts) (Client, Server, Modules) |

## 6. Стан
**Зроблено:**
- [x] Stone Golem v2 з анімацією Mine, кірка, руда зі здриганням і уламками
- [x] Формат великих чисел (NumberFormat)

**До зробити:**
- [x] Тестова печера v9: центральна площа, 6 однакових ніш з входом за малюнком, без дірок
- [x] Ніша мапи 1 (декор), 6 копій у печері, автоклейм плота і телепорт на спавн
- [ ] Карта: фінальна печера, скупщик, печера збереження, утилізація, префаби мап
- [x] Плот (прототип): 6 плотів у порядку 1 → 6, 5 точок руди, спавн з анімацією, HP-бар, майнери, носій з ящичком, світні стаки ×N, руда одразу в інвентар ([[GDD - Plots]])
- [x] Плот: UI розстановки (Place Golems, Equip Best), табло прокачки плоту (8 карток), ящик з місткістю й COLLECT, жили Coal / Copper / Iron (S / M / L)
- [x] Руда й злитки в стилі жил (Union) на піддонах, плотах, у ящику й 3D-іконками в слотах; вугілля не плавиться
- [x] Станція ролу з вибором типу голема (Miner / Carrier, Warrior — MAP 2), свої підказки E
- [x] Вхід у печеру големів (коло CAVE, ENTER CAVE — затиск 0,9 с, телепорт у свою печеру ніші)
- [x] Вікна Inventory / Sell / Forge / Place Golems — однаковий розмір і місце (`WindowFit`), гортання замість росту вікна
- [ ] Картка Auto Sell — механіка й ціна (мапа 2)
- [x] Forge мапи 1 у Roblox: сцена, анімації голема й печі, пробудження, піддони, переплавка, апгрейдер (руда й гроші — тестові атрибути)
- [x] HUD: лічильник грошей (Money HUD), підключено до Forge (тест: «Забрати злитки» продає їх)
- [x] Forge v3: усе ×1,8, нова піч без дірок і з трубою в стіну, бочка з водою, відерце, ящики, заготовка замість меча, табло покращень з кліком мишкою, жодних перетинів об'єктів
- [x] Forge: вікно кузні у стилі A (6 станів, WAITING…, смуга переплавки), звуки кузні
- [x] Forge: вибір кількості руди — синій плюсик на плитках руди, попап з повзунком (All / Put N), кнопка «Put All Ore», серверна дія `PutOre`
- [x] Forge: справжній інвентар руди й гроші (пробудження + $1 000)
- [x] Sell: лавка скупщика з големом-продавцем Наґґетом, зелене коло SELL, дошка цін мапи, анімації (веб-макет затверджено, у всіх нішах)
- [x] Sell: вікно продажу (UI) і серверна дія продажу (`SellSeq` / `SellAmount`)
- [x] Інвентар гравця: вікно за кнопкою рюкзака (вкладки Golems, Ores/Bars, Potions), хотбар у стилі «C · Сяйво», видалення з підтвердженням і блокування ([[GDD - Interface]])
- [ ] Предмет у руці: модель у руці персонажа, пити зілля; справжні джерела големів і зіль в інвентарі
- [ ] Референс-картки Wooden і Stone Golem (шаблон готовий)
- [ ] Wooden Golem, предмети 3 підкласів (меч, кірка, ящик), анімації носія і воїна
- [ ] Каталог големів і формули мутацій у коді
- [ ] Ролл-система «1 до N», анімація ролу, підписи (вибір класу на станції ролу — готово; Roll Luck — табло готове)
- [x] Прокачка плоту: сервер і табло (8 карток; `PlotAction` Upgrade)
- [x] Збереження даних (DataStore, сесійне блокування, автозбереження, Forge) — [[GDD - Data Saving]]; решту систем (големи, квести, Index тощо) додаємо в збереження разом з ними
- [x] Глобальні множники Money і плашка над TOTAL MULTI ([[GDD - Monetization]]); 21 Developer Product x2 Money створено в Creator Hub; геймпаси ще ні
- [x] Табло Forge: третя картка Ore per Hit, прокрутка, іконки в стилі HUD; Speed до 0,25 с; анімація голема йде в темп швидкості; x2 Money — коми, анімація покупки, відліт на MAX
- [ ] Мапи й печера збереження (вхід у ніші вже стоїть)
- [ ] Ребітхи
- [x] Макет головного HUD (веб): ПК і телефон, усі кнопки й лічильники, власні іконки в стилі пака (діамант, тікет, Feedback, Codes, Updates)
- [x] HUD перенесено в гру (PNG → Asset Manager → код)
- [ ] HUD: підключити дані (діаманти, тікети, ребіти, таймер боса `BossAt`) і вікна кнопок (`HUDButton`)
- [ ] Квести, Index
- [ ] Diamonds Shop
- [ ] Mutation Machine
- [ ] Утилізація
- [ ] Лідерборди й борди
- [ ] Стенд для новачків
- [ ] Маркетплейс, торгівля, логування
- [ ] Арена боса, воїни
- [ ] Геймпаси й кейси

## 7. Відкриті питання
1. Хто буде першим босом (Cracked Colossus — пропозиція) і механіки наступних босів.
2. Ціни мап, ребітхів і Roll Luck (зараз пропозиція) — після тестів.
3. Forge: вимоги для пробудження, ліміт місткості і чи потрібен ліміт на піддоні Bars.
4. ~~Магазин, де продається руда й злитки, — скупщик у головному проході чи магазин біля входу в нішу?~~ **Вирішено:** лавка [Sell Shop](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FInteractive%20Objects%2FSell%20Shop%2FSell%20Shop) у лівому передньому куті ніші.
5. ~~Руда мапи 1 Stone → Coal (кам'яних злитків не буває). Coal досі стоїть і в рудах мапи 2 (Rusty Mine: Coal / Silver / Gold) — потрібна інша руда для мапи 2.~~ **Вирішено:** мапа 2: Coal → **Tin** (олово) — м'який сріблясто-сірий метал, пасує до іржавої шахти між залізом і сріблом. Вигляд: тьмяні синьо-сірі металеві самородки в бурому камені; колір руди `#9fb0b8`, злитка `#c9d3d8`. Ціна, HP і шанс — як були в Coal мапи 2.
6. HUD на телефоні: Money лишаємо внизу ліворуч, як у веб-макеті, чи зверху ліворуч під кнопками Roblox, як у Money HUD v9 (внизу ліворуч — джойстик)?

## Як вести GDD
- Тут — тільки загальна картина й посилання. Числа, формули й правила системи — у її нотатці `GDD - <Система>` (дочірня цього GDD).
- Як виглядає й де лежить конкретна річ (модель, об'єкт, вікно, локація) — у її нотатці в 3D Models / Interactive Objects / 2D / Locations. GDD на неї посилається obsidian-посиланням (не малює лінію в графі).
- Один факт — в одному місці. Змінилось правило — правимо нотатку системи; змінилась модель — нотатку моделі.
- Нова система → нова нотатка `GDD - <Назва>` у папці GDD і рядок у таблиці «Системи».
