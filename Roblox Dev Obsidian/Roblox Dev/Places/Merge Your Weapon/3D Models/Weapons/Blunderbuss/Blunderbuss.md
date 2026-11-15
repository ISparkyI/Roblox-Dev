---
tags: [model, weapon, block-style]
status: in-game
tier: 8
updated: 2026-11-14
---

# Blunderbuss

← [[Weapons]]

*Мушкетон з латунним розтрубом.* Зброя **тіру 8**.

![[myw_blunderbuss_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **8** |
| Отримати | мердж двох тіру 7 · BUY WEAPON з апгрейдом Buy Tier 8 — 1.09M |
| Ціна BUY WEAPON | 54.67K (25 × 3^(тір−1)) |
| Asset ID | `103321633260912` (rev 2) |
| Анімовані деталі | `Hammer`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Blunderbuss` |
| Атрибути шаблону | `Tier = 8`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Blunderbuss · Tier 8» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_blunderbuss.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_blunderbuss_preview.png` — прев'ю
- `Upload/myw_blunderbuss.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- rev 2: виправлені вивернуті нормалі
