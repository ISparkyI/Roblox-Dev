---
tags: [gdd, place, admin]
status: active
updated: 2026-10-28
---

# GDD - Admin Panel

← [[My Mining Golems - GDD|GDD]]

Адмін-панель (F2), ролі адмінів, глобальні івенти (Roll Luck, Mutation Luck, Money) з чергою, оголошення.

## Ролі
| Роль | Хто | Що може |
| --- | --- | --- |
| owner | `ServerStorage/AdminConfig.ADMINS` (UserId 3696478279) | усе, вкладка ADMINS (видати / забрати роль) |
| admin | видає owner (DataStore `AdminRoles`, ключ `roles`) | усе, крім керування ролями й Shutdown |
| mod | видає owner | Kick, Ban лише 1–24 год, Freeze, Teleport / Bring, перегляд |

- Роль гравця — атрибут `AdminRole`. Права на кожну дію — таблиця `PERM` в `AdminService`; сервер перевіряє кожен запит.
- У Studio `STUDIO_ALL = true` — усі мають доступ (тільки для тестів).

## Вікно (F2)
Розмір 980×528, стиль гри. Вкладки:
- **PLAYERS** — список гравців на всіх серверах; картка гравця: Give (додати / встановити) Money, діаманти, тікети, зілля, Roll Luck рівні, голем через **пікер з картинками** (модалка), Kick, Ban / Unban, історія банів, DM, Teleport, Bring, Freeze.
- **GOLEMS** — пошук голема за UID (власник, історія).
- **GLOBAL** — оголошення на всі сервери, видача всім (GrantAll), **івенти**.
- **ME** — швидкі дії на себе.
- **SERVERS** — список серверів, Shutdown.
- **LOGS** — журнал дій адмінів.
- **ADMINS** — тільки owner: ролі.

Правила UI: менше полів вводу — степери, пресети, чипи; текст `U.fit` (TextScaled з обмеженням), відступи в скролерах, нічого не обрізається.
Ліміт видачі: `MAX_AMOUNT = 1e60`.

## Івенти
| Тип | Атрибут Workspace | На що діє |
| --- | --- | --- |
| ROLL LUCK | `EventLuck` | шанс рідкості голема |
| MUTATION LUCK | `EventMutLuck` | шанс мутації |
| MONEY | `EventMoney` | `TotalMulti` (MultiService), разом максимум x1000 |

- Множник: чипи (x2, x5, x10…) або **свій x** у полі; хвилини — чипи. Для удачі ліміту немає (технічна стеля 1e15).
- **Черга:** сегменти `{m, startT, untilT}`. Діє найбільший множник; менший чекає й продовжується після нього. Той самий множник подовжує час. `applyEvents` раз на 1 с; стан — MemoryStore `AdminState("events")`.
- Формула з Roll Luck: `luck = ((1 + RollLuck/100) × EventLuck − 1) × 100` (так само для мутацій з `EventMutLuck`). Деталі — [[GDD - Roll]].

## Повідомлення гравцям
`AdminBroadcastClient`: банер (ADMIN ABUSE тощо), тости «+N Money!», плашки активних івентів (до 3). Текст без підкладки: градієнт, чорна обводка й тінь `#14161a`, під ним чорна тінь 50% з фейдом в обидва боки від центру.

## Як влаштовано
- Між серверами — MessagingService, топік `MMG_Admin` (у Studio `_Studio`). Свої ж повідомлення не обробляються двічі (`Local`).
- MemoryStore: `AdminPresence` (хто де), `AdminReplies`, `AdminGrants`, `AdminState`.
- Офлайн-видача — DataStore `AdminMail`, забирається при вході. Кожна видача має tx-id, список виконаних — секція профілю `AdminTx` (без дублів).
- Секретні ключі бекенду **не зберігаються в цьому сховищі** — лише в Studio (`ServerStorage/BackendConfig`).

**Скрипти:** `AdminService.lua`, `AdminConfig.lua` (Server), `AdminPanel.lua`, `AdminBroadcastClient.lua` (Client).
