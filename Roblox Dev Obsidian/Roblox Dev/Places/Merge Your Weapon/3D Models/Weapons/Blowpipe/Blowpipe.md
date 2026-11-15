---
tags: [model, weapon, block-style]
status: in-game
tier: 3
updated: 2026-11-14
---

# Blowpipe

← [[Weapons]]

*Бамбукова трубка з дротиком.* Зброя **тіру 3**.

![[myw_blowpipe_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **3** |
| Отримати | мердж двох тіру 2 · BUY WEAPON з апгрейдом Buy Tier 3 — 4.5K |
| Ціна BUY WEAPON | 225 (25 × 3^(тір−1)) |
| Asset ID | `73255290966099` |
| Анімовані деталі | `Dart` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Blowpipe` |
| Атрибути шаблону | `Tier = 3`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Blowpipe · Tier 3» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_blowpipe.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_blowpipe_preview.png` — прев'ю
- `Upload/myw_blowpipe.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
