---
tags: [model, weapon, block-style]
status: in-game
tier: 20
updated: 2026-11-14
---

# Grenade Launcher

← [[Weapons]]

*Барабанний гранатомет на 6 гранат з оливковим барабаном і жовтими смугами.* Зброя **тіру 20**. Граната б'є по площі.

![[myw_grenadelauncher_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **20** |
| Отримати | мердж двох тіру 19 · BUY WEAPON з апгрейдом Buy Tier 20 — 581.13B |
| Ціна BUY WEAPON | 29.06B (25 × 3^(тір−1)) |
| Asset ID | `71321601892950` |
| Анімовані деталі | `Cylinder` (барабан обертається), `Sight` (відкидний приціл), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_GrenadeLauncher` |
| Атрибути шаблону | `Tier = 20`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 20 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_grenadelauncher.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_grenadelauncher_preview.png` — прев'ю
- `Upload/myw_grenadelauncher.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія. Граната в дулі прибрана — виглядала дивно.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
