---
tags: [model, bar, block-style]
status: in-game
updated: 2026-10-25
style: "GDD - Блоковий стиль моделей"
---

# Copper Bar

← [[Bars]]

*Мідний злиток.* Виходить з переплавки руди в кузні (1 руда → 1 злиток). Ціна **$30** (руда × 1,5).

![[chunks_bars_game.jpg]]

| Параметр | Значення |
| --- | --- |
| Тип | `UnionOperation` з пластин (`UsePartColor = false`) |
| Форма | трапеція: кожна грань свого відтінку (світло падає), нижня грань світліша; без пімпочок зверху |
| Розмір | 1,80 × 0,60 × 0,90 стада |

**Відтінки граней:**

| HEX |
| --- |
| `#ffa066` |
| `#f47f3a` |
| `#e56223` |
| `#e06a2c` |
| `#cc5c24` |
| `#b84f1b` |

## У Roblox
| Що | Де |
| --- | --- |
| Злиток (Union) | `ReplicatedStorage/Prefabs/ForgeProps/BarCopper` |
| Вихідна модель з деталей | `ServerStorage/ForgeChunkSources/BarCopper` |
| На піддоні Bars кузні | Union з атрибутом `BarType = Copper` (видно потрібний тип) |
| 3D-іконка в слотах | `ReplicatedStorage/Shared/ItemViewport` бере цю ж модель |
| Бекап мешів (до v14) | `ServerStorage/NicheBackup/ForgePallets_v2_meshes` |

## Структура папки
- Генератор — спільний для руди й злитків: `ore_chunks_models.js` → `ore_chunks_export.py` → `ore_chunks_build.lua` (папка Source кузні)
- Скрін — `Bars/Preview/chunks_bars_game.jpg`

## Історія
- **v14 кузні (24.10.2026):** злиток з пластин (Union), замість меша-трапеції зі штампом.
- **25.10.2026:** окрема нотатка злитка.
