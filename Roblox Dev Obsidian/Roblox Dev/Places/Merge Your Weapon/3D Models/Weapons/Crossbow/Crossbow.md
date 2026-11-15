---
tags: [model, weapon, block-style]
status: in-game
tier: 5
updated: 2026-11-14
---

# Crossbow

← [[Weapons]]

*Арбалет зі стременем.* Зброя **тіру 5**. Дається в STARTER PACK (SHOP).

![[myw_crossbow_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **5** |
| Отримати | мердж двох тіру 4 · BUY WEAPON з апгрейдом Buy Tier 5 — 40.5K |
| Ціна BUY WEAPON | 2.02K (25 × 3^(тір−1)) |
| Asset ID | `102111378868758` (rev 2) |
| Анімовані деталі | `String_L`, `String_R` (сходяться на замку), `Bolt` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Crossbow` |
| Атрибути шаблону | `Tier = 5`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Crossbow · Tier 5» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_crossbow.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_crossbow_preview.png` — прев'ю
- `Upload/myw_crossbow.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- rev 2: стремено підтягнуте до ложа
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
