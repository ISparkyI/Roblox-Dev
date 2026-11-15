---
tags: [model, weapon, block-style]
status: in-game
tier: 13
updated: 2026-11-14
---

# SMG

← [[Weapons]]

*Пістолет-кулемет зі складаним дротяним прикладом.* Зброя **тіру 13**. Перша автоматична зброя: швидка черга, слабкі кулі. Помаранчеві акценти.

![[myw_smg_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **13** |
| Отримати | мердж двох тіру 12 · BUY WEAPON з апгрейдом Buy Tier 13 — 265.72M |
| Ціна BUY WEAPON | 13.29M (25 × 3^(тір−1)) |
| Asset ID | `77028650532310` |
| Анімовані деталі | `Mag` (магазин, падає при перезарядці), `Bolt` (рукоятка затвора), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_SMG` |
| Атрибути шаблону | `Tier = 13`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «SMG · Tier 13» над зброєю |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_smg.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_smg_preview.png` — прев'ю
- `Upload/myw_smg.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: Перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
