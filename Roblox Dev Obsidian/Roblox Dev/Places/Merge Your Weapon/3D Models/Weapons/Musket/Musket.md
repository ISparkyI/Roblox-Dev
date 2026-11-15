---
tags: [model, weapon, block-style]
status: in-game
tier: 7
updated: 2026-11-14
---

# Musket

← [[Weapons]]

*Мушкет з ременем.* Зброя **тіру 7**. Стоїть на стенді **+100 WEAPONS** на плоті.

![[myw_musket_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **7** |
| Отримати | мердж двох тіру 6 · BUY WEAPON з апгрейдом Buy Tier 7 — 364.5K |
| Ціна BUY WEAPON | 18.23K (25 × 3^(тір−1)) |
| Asset ID | `77828217995602` |
| Анімовані деталі | `Hammer`, `Trigger`, `Ramrod` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Musket` |
| Атрибути шаблону | `Tier = 7`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Musket · Tier 7» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_musket.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_musket_preview.png` — прев'ю
- `Upload/myw_musket.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
