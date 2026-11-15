---
tags: [model, weapon, block-style]
status: in-game
tier: 15
updated: 2026-11-14
---

# Assault Rifle

← [[Weapons]]

*Автомат з оливковою фурнітурою, вигнутим магазином і коліматором.* Зброя **тіру 15**. Баланс швидкості й сили.

![[myw_assaultrifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **15** |
| Отримати | мердж двох тіру 14 · BUY WEAPON з апгрейдом Buy Tier 15 — 2.39B |
| Ціна BUY WEAPON | 119.57M (25 × 3^(тір−1)) |
| Asset ID | `106809030229561` |
| Анімовані деталі | `Mag` (вигнутий магазин), `Bolt` (рукоятка затвора), `Sight` (коліматор), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_AssaultRifle` |
| Атрибути шаблону | `Tier = 15`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Assault Rifle · Tier 15» над зброєю |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_assaultrifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_assaultrifle_preview.png` — прев'ю
- `Upload/myw_assaultrifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: Вигин магазину виправлено (перерізи йдуть перпендикулярно вигину).
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
