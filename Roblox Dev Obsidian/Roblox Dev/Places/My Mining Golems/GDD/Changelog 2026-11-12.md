# Changelog 12.11.2026

## Вибір ролі над кнопкою ROLL (варіант 1)
- `CustomPrompts`: атрибут підказки `UIRoleChips = true` → над кнопкою ряд із 3 плиток (Miner / Carrier / Warrior) у стилі карток станції: градієнт ролі, studs, чорна обводка, наші іконки.
  - Вибрана: 108 (решта 88), проміжок 26, лаймова рамка 4 + галочка 34. Ряд ширший за кнопку: полотно `CHIPS_W = 370` (кнопка 250 по центру), `CHIPS_H = 150`; у `fits` ширина береться з `f.ww`. Причина: на великих екранах і здалеку плитки було ледь видно. Бекап `RoleChips_pre2`; невибрані притемнені (0.55). Ряд піднято (baseY -24), щоб не налазив на бейдж клавіші E; плитки й рамки не перекриваються.
  - Warrior під час навчання — замок (тап → deny).
  - Тап → `Remotes.RollRole:FireServer(role)`.
  - Білборд вищий і ширший, кнопка на тому ж місці (`SizeOffset`).
  - Напис кнопки з плитками — TextScaled + UITextSizeConstraint (макс. звичайний розмір): «ROLL WARRIOR» більше не налазить на іконку важеля.
  - v2: плитки будуються один раз; перемикання — твіни 0.2 с (позиція, UIScale, затемнення, лаймова рамка; галочка вискакує Back). Тап міняє вигляд одразу, сервер підтверджує `RollRole`. Напис «ROLL <РОЛЬ>» — `setText` на місці; `UIText` для кнопки з плитками і `UIRole` більше НЕ перебудовують білборд (це давало ривок кнопки і пальця навчання). Замок Warrior — за `TutStep` без перебудови.
- `RollStationClient`: ставить на підказку важеля `UIRoleChips`, `UIText = "ROLL <РОЛЬ>"`; ліва панель вибору показується лише на кроці 3 навчання.
- Перевірено в Play: перемикання Miner → Carrier оновлює плитки й напис «ROLL CARRIER», помилок немає.
- Бекап: `ServerStorage/NicheBackup/RoleChips_pre`.

## Robux Stand — кнопка BUY
- `RobuxBuyAnchor` перед големом (pivot + faceDir×2, +1.8 вгору), hold = 0.

## Тап замість утримання
- Усі HOLD-константи (RollRoleService, CaveService, CaveStandService, RollService, MarketExclusiveService, CaveStandsClient, MutationMachineClient) = 0; 27 статичних підказок обнулено.
- CustomPrompts: вимкнена (UIDisabled) підказка при тапі — shake + deny.
- Бекап: `Prompts_pre_tap`.

## BUY на стенді не блимає «FREE»
- `RollRevealClient.paintPrompt`: якщо `RollPrice == nil` — лишає попередній текст. Бекап `RollRevealClient_pre_freeflash`.

## Навчання, крок 3
- Важіль заблоковано на кроці 3 (LeverScript у 6 префабах + RollService.onPull).
- `TutDim`: затемнення з отвором над `Card_Carrier`, плавне звуження 0.75 с (ease-out cubic), `ScreenInsets.None` — на всіх пристроях до країв.
- Повторний вибір Miner повертає на крок 3.
- Крок 1 (рол майнера): якщо гравець перемкнув на не-Miner — важіль заблоковано (LeverScript ×6 + RollService.onPull), затемнення з отвором на плитці Miner, рука на ній. Бекап `TutStep1_pre_dim`.
- v2 (12.11): стара ліва панель `RollRolePanel` більше НЕ показується (і на кроці 3). Кроки 1 (не-Miner) і 3 ведуть по плитках над ROLL: `chipRect(role)` у RollStationClient рахує екранний прямокутник плитки в білборді (WorldToViewportPoint, як рука TutorialClient; координати viewport = полотно TutDim, без віднімання AbsolutePosition). Важіль не вимикається (інакше зникли б плитки) — `UIDisabled` (сіра кнопка; CustomPrompts міняє колір на місці через `btnOf`). TutorialClient: `needRole` → рука на `Chip_<role>.Hit`, підпис ролі.
- Плавність (бекап `RoleChips_pre_smooth`): твіни плиток 0.32 с Quart Out (галочка 0.3 Back); отвір затемнення їде за плиткою згладжено (exp, k=12), поява затемнення exp k=6, звуження 0.9 с; 2D-рука навчання згладжує позицію й розмір цілі (`HSM`, k=14). Телефон: ряд плиток ×0.72 (`PHONE_CHIPS`, UIScale ряду, опора — центр над кнопкою).
- Навчання «бос» (бекап `BossTutDim_pre`): `BossTut = "roll"` і роль не Warrior — затемнення з отвором на плитці Warrior, рука на ній, ROLL сіра; сервер (LeverScript ×6 + RollService) не ролить. `BossTut = "join"` — отвір на кнопці JOIN біля NEXT BOSS (`MainHUD/Btn_BossJoin`); вікно реєстрації відкрите — без затемнення.
- Затемнення не блимає: ціль на мить зникла — тримаємо 0.4 с (`lastSeen`). 2D-рука: плавне проявлення (0.1 с затримка + 0.2 с), чорна обводка — ще пізніше (0.2 с), щоб не блимав чорний силует до того, як намалюється сама рука.
- Координати: viewport → полотно ScreenGui = `p - (gui.AbsolutePosition + (0, GuiInset.Y))`. TutDim (ScreenInsets.None) на пристроях з безпечною зоною більше за viewport і зсунуте — без цього отвір і рука розходились. Те саме для руки на кнопці у світі (TutorialClient).
- Фікс позиції: екранна позиція кнопки в білборді тепер враховує `bb.SizeOffset` (+X вправо, +Y вгору) — і в TutorialClient (рука на будь-якій кнопці у світі), і в `chipRect`. До цього затемнення й палець були нижче плитки.
- Бекап: `TutStep3_pre_dim`.

## Ящик плоту без ліміту (бекап `CrateNoLimit_pre`)
- `PlotConfig.CARD_ORDER` — без `Crate`: картки Crate Capacity немає на табло всіх мап, купити не можна, у прогрес «max all plot upgrades» (MapService / MapBoard) не входить. `CARDS.Crate` лишено для сумісності.
- `PlotService.crateCap` = ∞; атрибут плоту `CrateCap` більше не ставиться. Носій ніколи не чекає «повний ящик».
- `PlotClient`: над ящиком «37 ORE · $855» (ціна руди з ForgeConfig × TotalMulti, як у SellWindow; оновлення і при зміні TotalMulti), порожній — сіре «0 ORE» (EMPTY вже пише кнопка COLLECT). Руда всередині ящика виглядає повною від `VIS_FULL = 40` шматків.
- `CrateHintClient`: підказка Collect — коли в ящику ≥ `HINT_N = 20` руди (раніше — коли повний).

## Кола SELL / CAVE / WORKSHOP не блищать при русі камери
- Причина: прозорий диск `RingGlow` (Neon, Transparency 0.88) лежав за 0.036 стада над підлогою зі studs — затирання глибини і відблиск неону при русі камери.
- `RingGlow` (25 шт.): SmoothPlastic, Transparency 0.8, +0.08 вгору; `RingSeg` (1002 шт.): +0.04 вгору; усім CastShadow = false. У NichePrefabs, Cave, Cave_Inside, Marketplace.
- Початкові значення — у атрибуті деталі `RingFix` («Матеріал|Transparency|Y»).

## Музика лобі
- «Playground Of The Stars (A)» (rbxassetid://1840684208) → `SoundService/LobbyMusic/Lobby5`, Volume 0.07 (інші 0.05–0.11). Копія оригіналу — `NicheBackup`.

## Звук важеля на сірій ROLL
- `CustomPrompts`: E на сірій кнопці ROLL (навчання, не та роль) — відмова + хитання замість звуку важеля (раніше можна було спамити звуком). Бекап `CustomPrompts_pre_leverdeny`.

## Кнопки у світі не смикаються на планшеті
- `CustomPrompts.isPhone` і `PlotClient.isPhoneUI` (COLLECT): замість `GetLastInputType() == Touch` — флаг «був дотик» до кінця сесії. На планшеті з мишею / в емуляторі (рух WASD + затиснутий палець) останній тип вводу скакав, і кнопки перемикались між «статичними на екрані» і «у стадах з ростом» (то більші, то менші). Бекап `CustomPrompts_pre_phonelatch`.

## Бос: HP-смуга в мить удару
- `BossArenaClient`: зменшення HP боса від сервера йде в чергу `hpQ`; смуга і число падають, коли голем б’є мечем (`animHit` знімає запис, разом із цифрою шкоди), або через 1,3 с. Раніше HP падало за ~0,6–0,7 с до удару (на замаху). Діє і в навчальному, і в звичайному бою. Тест (навчальний бос): смуга змінюється через 0,02 с після удару.
- Смерть боса (`BossFx "boss" "die"`) чекає, поки показане HP (`dispHp`) стане 0 (останній удар мечем), макс. 1,4 с; вікно VICTORY чекає початку смерті до 2,2 с. Раніше бос падав, коли смуга ще показувала 1.

## Важіль ближче до входу
- `RollLeverModel` +6 studs (локальна Z префаба) у всіх 6 префабах; відстань до Stand1 = 13. Бекап `RollLever_pre_move`.

## Висновок по фанелу
- Просідання на кроці «Roll a Carrier» = гравці не вибирали Carrier. Дивитися фанел з 11.11 з розбивкою за пристроями.
