# GDD - Admin Panel

Адмін-панель Merge Your Weapon. Ідея та сама, що в My Mining Golems, але під нашу гру: зброя, крейти, сапплаї, пропуски, буст, ребьорти, зони та портал.

## Як відкрити
- Тільки **F2**. Кнопки в HUD немає.
- GUI панелі лежить у `ServerStorage/AdminUI/AdminPanelGui`. `AdminService` клонує його **лише** в PlayerGui стаффу, тож звичайні гравці не отримують навіть код панелі.

## Ролі
| Роль | Ранг | Що може |
|---|---|---|
| owner | 3 | усе, включно з Shutdown і керуванням ролями |
| admin | 2 | видача, Unban, ClearZone, God, GrantAll, івенти |
| mod | 1 | гравці, інфо, TP, Bring, Freeze, Kick, бан на 1–24 год, логи, оголошення |

- `ServerStorage/AdminConfig`: `OWNERS`, `ADMINS`, `GROUP_ID = 996441586`.
  - Ранг групи 255 = owner, 254+ = admin.
  - `STUDIO_ALL = true`: у Studio кожен гравець owner.
- Видані ролі зберігаються в DataStore `MYW_AdminRoles` (вкладка ADMINS, доступна лише owner).
- Сервер перевіряє кожен запит. Якщо запит прийшов від гравця без ролі, він потрапляє в лог як **SUSPECT**; після 3 таких спроб гравця кікає.
- Ліміт: 15 запитів за 3 секунди.

## Вкладки
- **PLAYERS**
  - Список гравців з усіх серверів (аватар, сервер, роль) і пошук.
  - Гравця можна завантажити за ніком або ID, навіть якщо він офлайн.
  - Картка гравця: аватар, бейджі (сервер, роль, GOD, FROZEN, BANNED) і плитки статів (cash, gems, ребьорти, буст, зброя / топ-тір, найкраща зона, де зараз, HP).
  - Секції картки:
    - CASH / GEMS: ADD / TAKE / SET і швидкі суми.
    - WEAPON: сітка з 35 тірів і кількість.
    - CRATES: 10 іконок з кількістю на руках, ALL ZONES.
    - SUPPLIES.
    - GAME PASSES: видати або забрати, GIVE ALL / TAKE ALL.
    - BOOST & REBIRTHS: x1…x1024, 0–6.
    - ACTIONS: TP TO, BRING, HEAL, GOD, FREEZE, CLEAR ZONE, SEND TO Z1–Z10 / PORTAL, KICK, BAN 1H / 24H / 7D / 30D / FOREVER, UNBAN.
- **ME**
  - Швидка видача собі: кеш, геми, 5 крейтів кожної зони, 10 кожного сапплаю, усі пропуски, зброя.
  - GOD, HEAL, CLEAR MY ZONE.
  - FLY: WASD, Space — вгору, Q — вниз, Shift — швидше.
  - Телепорт у зони та портал.
- **GLOBAL**
  - Оголошення на всі сервери (колір, тривалість).
  - Видача всім онлайн: кеш, геми, крейт.
  - Івенти **ADMIN ABUSE**: MONEY / CRATE LUCK / GEM LUCK, множник x2 / x3 / x5 / x10 на 5–60 хв, START / STOP.
- **BANS**: активні бани та UNBAN.
- **SERVERS**: список серверів, SHUTDOWN THIS / ALL (потрібне подвійне натискання).
- **LOGS**: лог цього сервера або історія по днях (UTC). Фільтри: GIVES / BANS / EVENTS / SUSPECT.
- **ADMINS**: MAKE ADMIN / MAKE MOD / REMOVE.

## Як це працює
- **Remotes**:
  - `Remotes/AdminAction` (RemoteFunction).
  - `Remotes/AdminBroadcast` (RemoteEvent): `ann` — банер, `toast` — коротке повідомлення.
- **Між серверами**: MessagingService `MYW_Admin` (give, kick, ann, grantall, events, roles, shutdown).
- **MemoryStore**:
  - `MYW_AdminPresence`: хто на якому сервері.
  - `MYW_AdminState`: які івенти активні.
- **Офлайн-видача**: DataStore `MYW_AdminMail`, доставляється після `DataLoaded`. Кожна видача має tx-id (атрибут `AdminTx`), тому двічі не нарахується.
- **Бани**: DataStore `MYW_AdminBans` (ключі `B_<id>` і `list`). Перевірка бану при вході на сервер.
- **Лог**: DataStore `MYW_AdminLog`, ключ `L_YYYY-MM-DD`.
- **Івенти**: атрибути workspace `EventMoney` / `EventCrate` / `EventGem` (+ `…Until`).
  - `DropService` множить кеш, шанс крейту й шанс гема.
  - `CashDropController` показує той самий кеш.
  - `AdminBroadcastClient` показує плашки «x2 MONEY 4:33» угорі екрана.
- **GOD / FREEZE** тримаються після респауну.

## Файли
- `ServerScriptService/AdminService` (Script)
- `ServerStorage/AdminConfig` (ModuleScript)
- `ServerStorage/AdminUI/AdminPanelGui/AdminPanel` (LocalScript)
- `StarterPlayerScripts/AdminBroadcastClient` (LocalScript)
- Хуки: `DropService` (value, crate, gem) і `CashDropController` (+cash над дропом).

## Примітка
У Studio вимкнений доступ до API (DataStore), тому бани, ролі, пошта й історія логів запрацюють лише на живому сервері. Решта перевірена в Play.
