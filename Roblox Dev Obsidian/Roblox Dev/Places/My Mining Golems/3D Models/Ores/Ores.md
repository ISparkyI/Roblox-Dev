---
tags: [models, ore]
updated: 2026-11-04
---

# Ores

← [[My Mining Golems - 3D Models|3D Models]]

Клас руд. Кожна руда — окрема нотатка: **жила** (росте на плоті, у трьох розмірах S / M / L) і **шматок** (падає з жили; той самий шматок лежить на підлозі, у ящику плоту, у ящичку носія, на піддонах кузні й показаний 3D-іконкою в слотах). Кожна руда реагує на удар атрибутами `HitPoint` / `HitTime`.

## Мапа 1 · Mossy Grotto (у грі)
| Руда | Що це | Шанс спавну | HP | Ціна |
| --- | --- | --- | --- | --- |
| [[Coal Ore]] | вугілля: чорні шматки в сірому камені; не плавиться | 1 до 3 | 5 | $8 |
| [[Copper Ore]] | мідь: помаранчеві кристали | 1 до 9 | 15 | $20 |
| [[Iron Ore]] | залізо: бежеві пластини; **прототип**, з якого зроблено жили всіх руд | 1 до 20 | 30 | $50 |

Числа — для довідки; правила, формули й руди всіх мап — [GDD - Ores and Bars](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Ores%20and%20Bars).

## Мапи 2–7 (моделі є, окремих нотаток поки немає)
Жили `PlotAssets/Ores/<Руда>_<S|M|L>` (джерело — `Workspace/OrePrefabs/OrePlot`), шматки `Prefabs/ForgeProps/Chunk<Руда>`, продукт `Bar<Руда>` або `Cut<Руда>` (огранований кристал).

| Мапа | Руди | Продукт | Статус |
| --- | --- | --- | --- |
| 2 Rusty Mine | Tin, Silver, Gold | злитки | у грі |
| 3 Crystal Depths | Quartz, Amethyst, Sapphire | Cut (кристали) | у грі з 04.11.2026 |
| 4 Magma Caverns | Obsidian, Ruby, Emberite | Cut / Cut / злиток | моделі готові |
| 5 Frozen Abyss | Frostite, Platinum, Celestium | Cut / злиток / Cut | моделі готові |
| 6 Void Core | Voidstone, Starmetal, Eclipsium | Cut / злиток / Cut | моделі готові |
| 7 *(приховано)* | Toxite, Uranite, Venomite | Cut / злиток / Cut | моделі готові |

Ціни, HP і шанси — [GDD - Ores and Bars](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Ores%20and%20Bars). Кристали руди мапи 3 також використано як декор ніші — [[Niche Stage 3]].

**Як додати руду:** папка `<Name> Ore/` з нотаткою (`← [[Ores]]`), `Preview/` зі скріном; жили `PlotAssets/Ores/<Name>_<S|M|L>`, шматок `PlotAssets/Chunks/<Name>` і `Prefabs/ForgeProps/Chunk<Name>`; рядок у таблицю вище.
