---
tags: [model, weapon, block-style]
status: in-game
tier: 18
updated: 2026-11-14
---

# Light Machine Gun

← [[Weapons]]

*Ручний кулемет: ребристий ствол, сошки, короб зі стрічкою.* Зброя **тіру 18**. Довга черга без перезарядки.

![[myw_lmg_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **18** |
| Отримати | мердж двох тіру 17 · BUY WEAPON з апгрейдом Buy Tier 18 — 64.57B |
| Ціна BUY WEAPON | 3.23B (25 × 3^(тір−1)) |
| Asset ID | `77989216007819` |
| Анімовані деталі | `Bipod` (сошки: складаються), `AmmoBox` (короб), `Belt` (латунна стрічка рухається), `Bolt`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_LMG` |
| Атрибути шаблону | `Tier = 18`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 18 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_lmg.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_lmg_preview.png` — прев'ю
- `Upload/myw_lmg.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
