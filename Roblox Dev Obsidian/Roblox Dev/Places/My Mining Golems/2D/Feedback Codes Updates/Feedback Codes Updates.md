---
tags: [ui, feedback, codes, updates, backend]
status: in-game
version: 5
updated: 2026-10-28
---

# Feedback Codes Updates

← [[My Mining Golems - 2D|2D]]

Три вікна для малих кнопок праворуч угорі HUD — **FEEDBACK**, **CODES**, **UPDATES** ([Main HUD](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F2D%2FMain%20HUD%2FMain%20HUD)). Зроблено одразу в грі, без веб-макета. Дані — **Google Таблиця + Apps Script Web App** (таблицю й скрипт робить окремий агент). Правила інтерфейсу — [GDD - Interface](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Interface).

![[fcu_updates.jpg]]

## Спільне для трьох вікон

- Стиль як у [Inventory](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F2D%2FInventory%2FInventory) / [Index](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2F2D%2FIndex%2FIndex): рамка 980 × 528 зі studs (полотно 1080 × 640, `Shared/WindowFit`), кнопки «стиль A», червона X, поява 0,85 → 1,05 → 1.
- **Заголовок:** іконка кнопки HUD ліворуч (≈ 2 × висоти літер, нахил −8°), чорні обводка й тіні. Перелив кольору кнопки HUD: Feedback — рожевий, Codes — жовтий, Updates — синій.
- **Закриття:** X, Esc, клік поза вікном (без `GetGuiInset`). Повторне натискання кнопки HUD теж закриває вікно.
- **Одне вікно на екрані:** `Shared/WindowManager` (імена `"Feedback"`, `"Codes"`, `"Updates"`). Хотбар лишається над затемненням. Клавіші B / ~ / R під час набору в полі не спрацьовують.
- **Звуки** (`Shared/UISounds`): tap / hover на кнопках, claim — успіх, deny — відмова.
- Якщо вміст не влазить — прокрутка (список новин, поле відгуку).

## UPDATES

- **Ліворуч — стовпчик вкладок-версій** (як класи в Index):
  - кнопки «стиль A»; вибрана — синя й зсунута праворуч;
  - на вкладці — «v0.3» і дата; нові версії зверху (за датою, далі за номером);
  - закріплена версія стоїть серед інших і має помаранчеву мітку **PIN**;
  - не переглянута версія — червона крапка;
  - вкладок багато — стовпчик гортається.
- **Праворуч — новини вибраної версії:**
  - усі рядки таблиці з цією версією, кожен — картка на всю область;
  - на картці: версія · дата, PINNED, заголовок кольору `titleColor`, текст RichText кольору `textColor`, велика картинка під текстом на всю ширину;
  - прокрутка.
- **За замовчуванням** відкрита найновіша версія (перша вкладка). Закріплена — лише позначена PIN, щоб гравець одразу бачив свіже.
- **Розмітка тексту з таблиці:** `[#ff5a5a]слова[/]` → колір, `**жирний**` → жирний. Символи `<`, `>`, `&` екрануються.
- **Переглянуто:**
  - відкрили версію — її id зберігаються в даних гравця (секція й атрибут `UpdatesSeen`), крапка зникає;
  - червоний лічильник на кнопці Updates у HUD — кількість непереглянутих версій.
- **Без таблиці** — запасний список сервера (3 новини). Стан бекенду гравцю не показуємо: службові написи лише там, де вони пояснюють результат дії гравця (Codes / Feedback).

![[fcu_codes.jpg]]

## CODES

- **Введення:** поле (усе UPPERCASE, до 24 символів), кнопка **REDEEM** або Enter.
- **Результат під полем** (звуки claim / deny):
  - зелений: «+50 Diamonds!», «+2 Luck Potions!», «+Stone Golem!»;
  - червоний: «Invalid code», «Already used», «Expired», «Code limit reached», «Codes are offline», «Inventory full», «Too many tries · wait 4:25».
- Анімацію нарахування діамантів у HUD робить MainHUD сам.

![[fcu_feedback.jpg]]

## FEEDBACK

- **Категорії:** Bug (червона) / Idea (жовта) / Other (синя) — перемикачі, вибрана кольорова, інші сірі.
- **Поле:** багаторядкове, до 500 символів; лічильник «N / 500». Менше 10 символів — жовтий, 500 — червоний.
- **SEND:**
  - «Thanks! Sent.» — зелений, кнопка сіра 2 хв;
  - «Wait 1:43» — ліміт, зворотний відлік;
  - «Can't send right now» — немає зв'язку або помилка;
  - «Too short · at least 10 characters».
- Клієнт додає пристрій: Touch / Gamepad / Keyboard.

### Хто може надіслати відгук

Перевіряє сервер (`BackendService`), вікно лише показує стан. Константи вгорі `BackendService`: `FEEDBACK_MIN_SESSION = 300` (секунди), `FEEDBACK_MIN_ACCOUNT_DAYS = 3`.

- **Час у сесії:** не менше 5 хв від `PlayerAdded` (час сервера). Інакше:
  - SEND сіра, натискання — deny;
  - напис «You can send feedback after 5 minutes in game» і таймер «Available in 3:12»;
  - коли час минув, кнопка стає зеленою.
- **Вік акаунта:** `Player.AccountAge` не менше 3 днів. Інакше SEND сіра і напис «Your account must be at least 3 days old» (червоний).
- **Відповідь сервера:** `SendFeedback` повертає `{ok:false, error:"session", wait}` або `{ok:false, error:"account"}`.
- **Атрибути гравця для вікна:** `FeedbackReadyAt` (час сервера, з якого можна), `FeedbackBlock` (`""` або `"account"`), `FeedbackMinSession`, `FeedbackMinAccountDays`.
- **Тест лише в Studio** — атрибути на `BackendService`, за замовчуванням не задані:
  - `FeedbackTestBypass = true` — без обмежень;
  - `FeedbackTestMinSession` (секунди) — підміна порогу сесії;
  - `FeedbackTestAccountAge` (дні) — підміна віку акаунта.

![[fcu_feedback_gate.jpg]]

## Бекенд (сервер)

`ServerScriptService/BackendService`, старт з `NicheBoot`. Remote — `ReplicatedStorage/Remotes/BackendAction` (RemoteFunction): `GetUpdates`, `SeenUpdates`, `Redeem`, `SendFeedback`.

- **Налаштування:** `ServerStorage/BackendConfig` (ModuleScript), поля `URL` (адреса Web App `…/exec`), `SECRET`, `VERSION`. Атрибути з тими ж іменами на ньому мають перевагу.
  - Поки `URL` або `SECRET` порожні — бекенд вимкнено (запасні стани вище).
  - Потрібно ввімкнути **Game Settings → Security → Allow HTTP Requests**.
- **HTTP:** `RequestAsync` з `pcall`, 3 спроби. **Підключено 28.10.2026.** `URL` і `SECRET` вписано в `BackendConfig`, HTTP увімкнено.
- **POST→GET через 302:** redeem і feedback теж надсилаються GET-запитом: `URL?action=redeem&key=…&data=<UrlEncode(JSON)>`, так само feedback. Причина — POST давав HTTP 405: Apps Script відповідає 302, і Roblox іде за редиректом тим самим POST.
- **Кеш:** `updates` і `codes` оновлюються при старті й раз на 60 с. Код, якого нема в кеші, — ще одне оновлення (не частіше ніж раз на 10 с).
- **Redeem, по черзі:**
  1. Код → UPPER + trim.
  2. Перевірки за кешем:
     - `active`;
     - `expires` (дата UTC, дійсний до кінця дня);
     - `maxUses`;
     - гравець ще не використовував код (секція DataService `Codes`);
     - для Golem — місце в інвентарі (300, без големів на плотах).
  3. `POST redeem` — атомарний лічильник у таблиці.
  4. Лише після `ok` — нагорода, код записується в секцію, `SaveNow`.
- **Нагороди:**
  - `Diamonds` / `Tickets` / `Money` — атрибути гравця;
  - `Potion` — `Pot_<item>`;
  - `Golem` — `InventoryService.AddGolem` з id `CaveStandService.MaxId + 1`. Формат `item`: `stone`, `stone:carrier`, `stone@3` (мутація після @); `amount` — кількість големів.
- **Анти-спам Redeem:** 1 спроба на 2 с; після 10 невдалих спроб за 5 хв — пауза.
- **Feedback:**
  - текст 10–500 символів;
  - 1 відгук на 120 с;
  - `TextService:FilterStringAsync` — у таблицю йде відфільтрований текст;
  - сервер додає `map` (Stage), `money`, `version` (`BackendConfig.VERSION` або `game.PlaceVersion`), `placeId`, `jobId`.
- **Тест у Studio:** атрибут `Mock = true` на `BackendService` вмикає вбудований макет таблиці. Коди макета: WELCOME, LUCKY, STONE3, OLD (прострочений), FULL (ліміт), OFF (вимкнений).

## Контракт API (Web App)

| Запит | Відповідь |
| --- | --- |
| `GET URL?action=updates&key=…` | `{ok, updates:[{id, version, date, title, titleColor, text, textColor, image, pinned}]}` |
| `GET URL?action=codes&key=…` | `{ok, codes:[{code, reward, amount, item, expires, maxUses, uses, active}]}` |
| `GET ?action=redeem&key&data={action:"redeem", key, code, userId, name}` | `{ok}` або `{ok:false, error:"inactive" \| "expired" \| "limit" \| "notfound" \| "auth"}` |
| `GET ?action=feedback&key&data={action:"feedback", key, userId, name, category, text, map, money, version, placeId, jobId, device}` | `{ok}` або `{ok:false, error:"rate" \| …}` |

## Скрипти

- `StarterPlayerScripts/InfoWindows` — клієнт, три вікна. Хеш 1548374643, 48 361 байт.
- `ServerScriptService/BackendService` — сервер. Хеш 1635102901, 27 353 байти.
- `ServerStorage/BackendConfig` — налаштування. Хеш 1063581644, 1 094 байти.
- `NicheBoot` — додано старт `BackendService`. Хеш 903143669, 1 998 байтів.
- Бекап — `ServerStorage/NicheBackup/Backend_v1` (`NicheBoot`).

Перевірено в Play (28.10.2026):
- **Без конфігу:** Updates показує запасний список, Codes — «Codes are offline», Feedback — «Can't send right now».
- **З макетом (Mock):** коди WELCOME / LUCKY / STONE3 видали нагороди; повторний код — «Already used»; OLD / FULL / OFF — Expired / Limit / Invalid; анти-спам і «Wait» працюють.
- **Збереження:** секція `Codes` збереглась.
- **Одне вікно на екрані:** Inventory / Index / Updates / Codes / Feedback закривають одне одного.
- **Інше:** клік поза вікном закриває; лічильник на кнопці Updates зникає після відкриття.

**Оновлено 28.10.2026 (v2):**
- UPDATES — прибрано напис «Offline · showing saved news».
- Мітки PINNED / NEW — без UIStroke (Miter на заокругленому Frame давав чорний квадрат). Тепер дві плашки з однаковими заокругленнями: темна підкладка + кольорова. Бейдж на кнопці HUD уже був такий.
- Копія `InfoWindows.lua` — хеш 1431437446, 39 584 байти.
- Бекап v1 — `ServerStorage/NicheBackup/Backend_v1/InfoWindows_v1`.

**Оновлено 28.10.2026 (v3):**
- UPDATES — вкладки-версії ліворуч, новини вибраної версії праворуч; велика картинка; червона крапка на непереглянутій версії.
- Копія `InfoWindows.lua` — хеш 1597780111, 45 841 байт.
- Бекап v2 — `ServerStorage/NicheBackup/Backend_v1/InfoWindows_v2`.

**Оновлено 28.10.2026 (підключено, POST→GET через 302):**
- `BackendService`: redeem / feedback — GET з параметром `data` (JSON). Бекап — `NicheBackup/Backend_v1/BackendService_v1`.
- `InfoWindows`: версія з таблиці «0.3» на вкладках і картках показується як «v0.3». Бекап — `NicheBackup/Backend_v1/InfoWindows_v3`.
- **Перевірено в Play з реальною таблицею, без Mock:**
  - Updates показує u3 / u2 / u1 з кольорами; u3 закріплена.
  - Codes бачить RELEASE, GOLEMS і SPEED; невідомий код — «Invalid code».
- Реальні redeem і feedback ще не перевіряли: чекаємо, поки оновлять `Code.gs`.

**Оновлено 28.10.2026 (вимоги до відправника відгуку):**
- Відгук можна надіслати лише після 5 хв у сесії і з акаунтом від 3 днів. Перевіряє сервер; вікно показує сіру SEND і таймер або пояснення.
- **Перевірено в Play:**
  - сесія: таймер іде, сервер відхиляє з `session`;
  - коли поріг минув (тест з `FeedbackTestMinSession = 45`), кнопка стала зеленою;
  - акаунт (тест з `FeedbackTestAccountAge = 1`): напис і відмова сервера `account`.
- Тестові атрибути після перевірки прибрано.
- Бекапи — `NicheBackup/Backend_v1/BackendService_v2`, `InfoWindows_v4`.
