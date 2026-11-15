---
tags: [model, weapon, block-style]
status: in-game
tier: 4
updated: 2026-11-14
---

# Bow

← [[Weapons]]

*Рекурсивний лук.* Зброя **тіру 4**.

![[myw_bow_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **4** |
| Отримати | мердж двох тіру 3 · BUY WEAPON з апгрейдом Buy Tier 4 — 13.5K |
| Ціна BUY WEAPON | 675 (25 × 3^(тір−1)) |
| Asset ID | `79541376926793` |
| Анімовані деталі | `String_Top`, `String_Bottom` (сходяться в точці натягу), `Arrow` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Bow` |
| Атрибути шаблону | `Tier = 4`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Bow · Tier 4» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_bow.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_bow_preview.png` — прев'ю
- `Upload/myw_bow.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
