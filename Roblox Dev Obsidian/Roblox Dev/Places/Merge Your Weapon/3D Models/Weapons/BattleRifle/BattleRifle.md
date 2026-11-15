---
tags: [model, weapon, block-style]
status: in-game
tier: 17
updated: 2026-11-14
---

# Battle Rifle

← [[Weapons]]

*Важка штурмова гвинтівка з пісочною фурнітурою і коротким прицілом.* Зброя **тіру 17**. Сильніші кулі, ніж в автомата.

![[myw_battlerifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **17** |
| Отримати | мердж двох тіру 16 · BUY WEAPON з апгрейдом Buy Tier 17 — 21.52B |
| Ціна BUY WEAPON | 1.08B (25 × 3^(тір−1)) |
| Asset ID | `117299042083452` |
| Анімовані деталі | `Mag` (магазин), `Bolt` (червона рукоятка), `Scope`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_BattleRifle` |
| Атрибути шаблону | `Tier = 17`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 17 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_battlerifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_battlerifle_preview.png` — прев'ю
- `Upload/myw_battlerifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
