---
tags: [interactive, lever, roll]
status: archived
version: 1
updated: 2026-10-25
---

# Roll Lever

← [[Interactive Objects]]

> [!warning] Архів — замінено станцією ролу
> З 25.10.2026 у ніші замість цього важеля стоїть **станція ролу Roll Station** (пульт з екраном вибору типу голема + тумба з важелем; див. Interactive Objects). Старий важіль збережено в `ServerStorage/NicheBackup/RollLeverModel_old_v1`. Нотатка лишається як опис генератора й першої анімації.

*Важіль ролу.* Гравець підходить, з'являється стандартна підказка Roblox **[E] Roll / Roll Lever**, натискає — палиця відтягується до нього, з прискоренням вистрілює вперед, б'ється в упор і пружно повертається вгору. У момент удару стріляє подія `Pulled(player)` — до неї підключається система ролу.

![[roll_lever.jpg]]

Анімацію можна подивитися в браузері: `Preview/roll_lever_animation.html` (ранній варіант дизайну, анімація та сама).

## Де лежить у Roblox
| Що | Де |
| --- | --- |
| Модель | `Workspace/NichePrefabs/NichePrefab_Stage1/Lever` (у префабі ніші, мапа 1) |
| Рухома частина + скрипт | `…/Lever/RollLever` (`Hinge`, `Stick`, `Ring` ×3, `Knob`, `LeverScript`, `Pulled`) |
| Генератор (будь-який плейс) | `Source/RollLever_Build.lua` у цій папці |

## Будова (у стадах, дизайн користувача)
| Деталь | Розмір | Колір | Матеріал | Рух |
| --- | --- | --- | --- | --- |
| Плита `2` | 3,9 × 0,61 × 2,68 | `#424242` | Plastic + `Studs` | — |
| Стійки `1` ×2 | 2,93 × 1,59 × 0,98 | `#535353` | Plastic + `Studs` | — |
| Планки `1` ×2 | 2,2 × 0,37 × 0,98 | `#535353` | Plastic + `Studs` | — |
| `Hinge` (невидимий) | 0,29 | — | — | обертається |
| `Ring` на осі | 0,81 × 0,68 × 0,54 | `#5b5f64` | SmoothPlastic + Texture studs 0,488 | так |
| `Stick` | 0,39 × 2,93 × 0,39 | `#6f4828` | Plastic + Texture studs 0,488 | так |
| `Ring` ×2 на палиці | 0,54 × 0,2 × 0,54 | `#5b5f64` | SmoothPlastic + Texture studs 0,488 | так |
| `Knob` | 1 × 1 × 1 | `#d63a2f` | Plastic + `Studs`, `PointLight Glow` | так |

- Вісь на висоті **1,64** над низом плити. Загальна висота ~5,4.
- Studs — тільки асети Resurface: `MaterialVariant "Studs"` (MaterialService) або `Texture` з `10509831729` / `10509831753`. Свої текстури не робимо.
- Уся модель без колізії (`CanCollide = false`), щоб не заважала підходити.

## Як це працює
- `Hinge` — **Anchored**, у точці осі. Палиця, кільця й ручка — **Unanchored**, `WeldConstraint` до `Hinge`, `Massless`. Анімація твінить тільки `Hinge.CFrame`, решта рухається разом.
- Орієнтація: `Hinge` **+Z = бік гравця**, вісь — X. `+кут` = верх палиці до гравця.
- `RollPrompt` (на `Hinge`): `ActionText "Roll"`, `ObjectText "Roll Lever"`, `E`, `HoldDuration 0`, `MaxActivationDistance 5,85`, `RequiresLineOfSight false`.
- Поки йде анімація, підказка вимкнена (рол без кулдауну, тільки після анімації). Зараз вмикається одразу після повернення; коли буде система ролу — вмикати після анімації ролу.

## Анімація (1,45 с)
| Фаза | Тривалість | Кут | Easing |
| --- | --- | --- | --- |
| Відтяг до себе | 0,28 с | 0° → +28° | Sine InOut |
| Напруга | 0,08 с | → +31° | Linear |
| Постріл вперед | 0,14 с | → −72° | Cubic In (прискорення) |
| **Удар**: спалах ручки, `Pulled:Fire(player)` | — | — | — |
| Відскок | 0,08 с | → −63° | Quad Out |
| Осідання | 0,12 с | → −68° | Quad InOut |
| Пауза | 0,15 с | −68° | — |
| Повернення вгору | 0,60 с | → 0° | Back Out (перескок) |

Іскри при ударі прибрано (рішення користувача).

## Як поставити в іншому місці / плейсі
1. Перевір, що в `MaterialService` є MaterialVariant **`Studs`** (логіка Resurface).
2. Встав код `Source/RollLever_Build.lua` як ModuleScript (або виконай через MCP) і виклич:
   ```lua
   local build = require(path.to.RollLever_Build)
   -- pos — точка на підлозі під віссю; towardsPlayer — напрям, звідки підходить гравець
   build(workspace, CFrame.lookAt(pos, pos - towardsPlayer))
   ```
   `LookVector` дивиться **від** гравця, тому +Z важеля — до гравця.
3. Система ролу підписується на `Lever.RollLever.Pulled.Event:Connect(function(player) … end)`.
4. Альтернатива — просто скопіювати модель `Lever` з `NichePrefab_Stage1`.

Генератор перевірено: зібрана ним модель збігається з моделлю в Studio (позиції ≤ 0,001, повороти 0°).

## Структура папки
- `Source/RollLever_Build.lua` — генератор моделі + `LeverScript`
- `Preview/roll_lever.jpg` — знімок зі Studio
- `Preview/roll_lever_animation.html` — веб-прев'ю анімації

## Історія
- **v1:** перший дизайн Claude (цоколь, корпус, упор, іскри) → користувач спростив корпус до плити зі стійками, зменшив модель ~в 2 рази, прибрав іскри. Скрипт переписано, щоб не залежав від корпусу (впав, коли видалили `Bumper`).
