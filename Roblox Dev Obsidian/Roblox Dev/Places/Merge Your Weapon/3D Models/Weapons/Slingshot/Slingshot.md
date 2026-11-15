---
tags: [model, weapon, block-style]
status: in-game
tier: 2
updated: 2026-11-14
---

# Slingshot

← [[Weapons]]

*Рогатка з розвилки.* Зброя **тіру 2**. Стоїть на стенді **+10 WEAPONS** на плоті.

![[myw_slingshot_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **2** |
| Отримати | мердж двох тіру 1 · BUY WEAPON з апгрейдом Buy Tier 2 — 1.5K |
| Ціна BUY WEAPON | 75 (25 × 3^(тір−1)) |
| Asset ID | `110535062261440` |
| Анімовані деталі | `Band_L`, `Band_R`, `Pouch`, `Stone` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Slingshot` |
| Атрибути шаблону | `Tier = 2`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Slingshot · Tier 2» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_slingshot.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_slingshot_preview.png` — прев'ю
- `Upload/myw_slingshot.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
