---
tags: [interactive, cave, teleport]
status: in-game (печери ще немає)
version: 1
updated: 2026-10-25
---

# Cave Entrance

← [[Interactive Objects]]

*Вхід у печеру големів* у ніші гравця. Через нього гравець потраплятиме в печеру-сховище, де на стендах можна зберігати големів. Біля входу лежить жовте коло з написом **CAVE**, а в колі з'являється синя кнопка **E · ENTER CAVE**. Самої печери ще немає, тому кнопка показує «COMING SOON».

![[cave_entrance_game.jpg]]

## Будова (блоковий стиль, як карта)
| Частина | Що там |
| --- | --- |
| `Body` | горб з валунів (маса + округлювач, Plastic + `Studs`), мох-шапочки, дерев'яне кріплення шахти (стійки й балка), два ліхтарі (Neon + `PointLight` `#ffc860`), сходинка-поріг |
| Прохід | темний (`SmoothPlastic`, без studs, `Dark`), у глибину темнішає (`#1a1c20` → `#050506`), щоб здавалося, що прохід іде вглиб |
| `Ring` | копія кола Sell (`ScaleTo(0.62)`), **суцільне** жовте `#ffd21e`, частинки `#ffe27a` |
| Напис `CAVE` | `Ring/SignAnchor/CaveSign` — копія напису SELL, золотий градієнт (`#fff6b0` → `#ffd23a` → `#ff9a1a`), темний контур `#4a2a06`. Градієнт переливається, час від часу пробігає блиск (анімує `CustomPrompts`) |
| Кнопка E | `PromptAnchor/CavePrompt` під написом CAVE |

Правило 0,5 між гранями карти (GDD будівництва карт) перевіряє генератор (`check.js`) перед збіркою. У моделі 130 деталей разом із колом.

## У Roblox
| Що | Де |
| --- | --- |
| Модель | `NichePrefab_Stage1/GolemCave`, база `CFrame.new(-787, 1.2, 357) · rotY 134°`; копії в `Niches/Niche1..6` (клонування відносно півота ніші) |
| Підказка | `CavePrompt`: `Style = Custom`, `UIText "ENTER CAVE"`, `UIColor "blue"`, `UIIcon rbxassetid://135564008543327` (іконка печери), `UIOffsetY −1.4` (під написом CAVE), `ComingSoon = true`; `MaxActivationDistance 10`, `RequiresLineOfSight = true` |
| Телепорт | `ServerScriptService/CaveEntrance`: `CavePrompt` → телепорт на `GolemCaveSpawn` (будь-де у Workspace). Точки ще немає, тож нічого не відбувається |
| Вигляд кнопки | `StarterPlayerScripts/CustomPrompts`: при `ComingSoon` кнопка трясеться і з'являється напис «COMING SOON» |

Іконки підказок (власні, у стилі пака; Asset Manager):

| Іконка | Image id | Decal id |
| --- | --- | --- |
| Печера (кнопка ENTER CAVE) | `rbxassetid://135564008543327` | 119359559834315 |
| Важіль (кнопка ROLL станції ролу) | `rbxassetid://138189299084398` | 123391512628348 |

## Підказки E у грі (`CustomPrompts`)
Власний вигляд для будь-якого `ProximityPrompt` зі `Style = Custom`: кнопка «стиль A» (як COLLECT), темна клавіша **E** у куті, іконка ліворуч від напису. Налаштування задаються атрибутами самого prompt:

| Атрибут | Що задає |
| --- | --- |
| `UIText` | напис (за замовчуванням `ActionText` великими літерами) |
| `UIColor` | колір StyleA: `blue`, `orange`, `green`… |
| `UIIcon` | rbxassetid іконки (висота 0,95 від грані кнопки) |
| `UIOffsetY` | висота над деталлю-батьком, стади |
| `UIWidth` | ширина, стади |
| `ComingSoon` | кнопка трясеться і показує «COMING SOON», дії немає |

Показує й ховає підказку рушій Roblox (відстань, лінія видимості — крізь стіни не видно). Клавіша E працює через рушій, клік мишкою або дотик — через `InputHoldBegin` / `InputHoldEnd`.

## Структура папки
- `Source/CaveEntrance_Build.lua` — збірка моделі в шаблоні ніші (дані деталей + код); генератор моделі — `cave_model.js`
- `Source/gen_cave_icons.py` — іконки печери й важеля; `Roblox/icon_cave.png`, `icon_lever.png`
- `Preview/cave_entrance_mock.html` — затверджений веб-макет (варіанти кнопок A–C, іконки A/B); `cave_entrance_mock.png` — кадр
- `Preview/cave_entrance_game.jpg` — скрін з гри

## Далі
1. Сама печера-сховище (`GolemCaveSpawn`), стенди для збереження големів.
2. Зняти `ComingSoon`, коли печера буде готова.

## Історія
- **v1 (24.10.2026):** референс користувача → веб-макет (горб, темний прохід, кріплення шахти, ліхтарі) → правки: без таблички, суцільне жовте коло як у SELL, CAVE з градієнтом, що переливається, кнопка ENTER CAVE під написом, менші іконки. Кнопку ROLL важеля теж зроблено своєю (помаранчева, іконка важеля).
