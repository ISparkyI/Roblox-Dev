---
tags: [model, weapon, block-style]
status: in-game
tier: 23
updated: 2026-11-14
---

# Heavy Machine Gun

← [[Weapons]]

*Важкий кулемет у руках: перфорований кожух ствола, рукоятки ззаду, бічний короб зі стрічкою.* Зброя **тіру 23**. Важкі кулі довгою чергою.

![[myw_heavymachinegun_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **23** |
| Отримати | мердж двох тіру 22 · BUY WEAPON з апгрейдом Buy Tier 23 — 15.69T |
| Ціна BUY WEAPON | 784.53B (25 × 3^(тір−1)) |
| Asset ID | `105175292767870` |
| Анімовані деталі | `AmmoBox`, `Belt`, `Handle` (ручка зверху), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_HeavyMachineGun` |
| Атрибути шаблону | `Tier = 23`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 23 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_heavymachinegun.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_heavymachinegun_preview.png` — прев'ю
- `Upload/myw_heavymachinegun.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
