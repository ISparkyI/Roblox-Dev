---
tags: [model, weapon, block-style]
status: in-game
tier: 22
updated: 2026-11-14
---

# Anti-Materiel Rifle

← [[Weapons]]

*Великокаліберна снайперка: дуже довгий ствол, величезне дульне гальмо, помаранчеві смуги.* Зброя **тіру 22**. Прошиває кількох мобів.

![[myw_antimaterielrifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **22** |
| Отримати | мердж двох тіру 21 · BUY WEAPON з апгрейдом Buy Tier 22 — 5.23T |
| Ціна BUY WEAPON | 261.51B (25 × 3^(тір−1)) |
| Asset ID | `104326312070106` |
| Анімовані деталі | `Bolt` (рукоятка затвора), `Mag`, `Bipod`, `Scope`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_AntiMaterielRifle` |
| Атрибути шаблону | `Tier = 22`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 22 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_antimaterielrifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_antimaterielrifle_preview.png` — прев'ю
- `Upload/myw_antimaterielrifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
