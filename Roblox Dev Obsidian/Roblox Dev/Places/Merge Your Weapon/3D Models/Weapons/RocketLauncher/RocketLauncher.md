---
tags: [model, weapon, block-style]
status: in-game
tier: 24
updated: 2026-11-14
---

# Rocket Launcher

← [[Weapons]]

*Ракетниця з плеча: труба з розтрубом, дерев'яна накладка, червона ракета.* Зброя **тіру 24**. 🔁 **Вимога Rebirth 4:** знайти цю зброю.

![[myw_rocketlauncher_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **24** |
| Отримати | мердж двох тіру 23 · BUY WEAPON з апгрейдом Buy Tier 24 — 47.07T |
| Ціна BUY WEAPON | 2.35T (25 × 3^(тір−1)) |
| Asset ID | `122224324109877` |
| Анімовані деталі | `Rocket` (вилітає й з'являється знову), `Grips` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_RocketLauncher` |
| Атрибути шаблону | `Tier = 24`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 24 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_rocketlauncher.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_rocketlauncher_preview.png` — прев'ю
- `Upload/myw_rocketlauncher.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Заглушки каналу труби зсунуто всередину. Нова ревізія того самого Asset ID.
