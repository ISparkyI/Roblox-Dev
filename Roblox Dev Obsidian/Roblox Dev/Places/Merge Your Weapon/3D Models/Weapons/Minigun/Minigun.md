---
tags: [model, weapon, block-style]
status: in-game
tier: 21
updated: 2026-11-14
---

# Minigun

← [[Weapons]]

*Мінігун: 6 обертових стволів, кожух мотора з червоною смугою, короб зі стрічкою.* Зброя **тіру 21**. Розкручується: чим довше стріляє, тим швидше.

![[myw_minigun_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **21** |
| Отримати | мердж двох тіру 20 · BUY WEAPON з апгрейдом Buy Tier 21 — 1.74T |
| Ціна BUY WEAPON | 87.17B (25 × 3^(тір−1)) |
| Asset ID | `76171761220654` |
| Анімовані деталі | `Barrels` (блок стволів крутиться), `AmmoBox`, `Belt` (стрічка рухається), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Minigun` |
| Атрибути шаблону | `Tier = 21`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 21 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_minigun.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_minigun_preview.png` — прев'ю
- `Upload/myw_minigun.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Передню ручку посаджено на хомут навколо стволів (не висить). Нова ревізія того самого Asset ID.
