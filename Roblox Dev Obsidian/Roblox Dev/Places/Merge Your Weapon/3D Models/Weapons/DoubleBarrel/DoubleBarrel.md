---
tags: [model, weapon, block-style]
status: in-game
tier: 11
updated: 2026-11-14
---

# Double Barrel

← [[Weapons]]

*Двостволка.* Зброя **тіру 11**. Відкривається після Rebirth 1.

![[myw_doublebarrel_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **11** |
| Отримати | мердж двох тіру 10 · BUY WEAPON з апгрейдом Buy Tier 11 — 29.52M |
| Ціна BUY WEAPON | 1.48M (25 × 3^(тір−1)) |
| Asset ID | `91329475325494` |
| Анімовані деталі | `Barrels` (переламується разом із цівкою), `Hammer_L`, `Hammer_R`, `Triggers` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_DoubleBarrel` |
| Атрибути шаблону | `Tier = 11`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Double Barrel · Tier 11» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_doublebarrel.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_doublebarrel_preview.png` — прев'ю
- `Upload/myw_doublebarrel.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
