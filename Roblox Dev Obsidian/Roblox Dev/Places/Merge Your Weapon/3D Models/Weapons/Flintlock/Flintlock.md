---
tags: [model, weapon, block-style]
status: in-game
tier: 6
updated: 2026-11-14
---

# Flintlock Pistol

← [[Weapons]]

*Кременевий пістоль.* Зброя **тіру 6**.

![[myw_flintlock_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **6** |
| Отримати | мердж двох тіру 5 · BUY WEAPON з апгрейдом Buy Tier 6 — 121.5K |
| Ціна BUY WEAPON | 6.08K (25 × 3^(тір−1)) |
| Asset ID | `84740160493249` |
| Анімовані деталі | `Hammer` (курок з кременем), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Flintlock` |
| Атрибути шаблону | `Tier = 6`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Flintlock · Tier 6» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_flintlock.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_flintlock_preview.png` — прев'ю
- `Upload/myw_flintlock.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
