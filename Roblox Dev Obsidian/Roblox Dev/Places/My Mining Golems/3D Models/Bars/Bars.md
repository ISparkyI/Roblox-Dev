---
tags: [models, bar]
updated: 2026-10-25
---

# Bars

← [[My Mining Golems - 3D Models|3D Models]]

Клас злитків: те, що виходить з переплавки руди. Злиток лежить на піддоні Bars кузні, летить з ковадла, лежить в інвентарі й показаний 3D-іконкою в слотах вікон (Inventory, Sell). Злитків вугілля немає — вугілля не плавиться.

![[chunks_bars_game.jpg]]

*Шматки вугілля, міді й заліза та злитки міді й заліза (Studio, ×3).*

| Злиток | Колір | Модель |
| --- | --- | --- |
| [[Copper Bar]] | мідно-помаранчевий | `ReplicatedStorage/Prefabs/ForgeProps/BarCopper` |
| [[Iron Bar]] | світло-сірий сталевий | `ReplicatedStorage/Prefabs/ForgeProps/BarIron` |

Ціна злитка = ціна руди × 1,5 ([GDD - Ores and Bars](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Ores%20and%20Bars)).

**Як додати злиток:** папка `<Name> Bar/` з нотаткою (`← [[Bars]]`), вихідна модель у `ServerStorage/ForgeChunkSources/Bar<Name>`, Union у `Prefabs/ForgeProps/Bar<Name>`.
