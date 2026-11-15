---
tags: [model, weapon, block-style]
status: in-game
tier: 1
updated: 2026-11-14
---

# Stick

← [[Weapons]]

*Природна гілка з листками.* Зброя **тіру 1**. Перша зброя: BUY WEAPON дає її безкоштовно.

![[myw_stick_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **1** |
| Отримати | BUY WEAPON (безкоштовно) |
| Ціна BUY WEAPON | безкоштовно |
| Asset ID | `138811546156806` (rev 3) |
| Анімовані деталі | листки `Leaf_*` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Stick` |
| Атрибути шаблону | `Tier = 1`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Stick · Tier 1» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_stick.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_stick_preview.png` — прев'ю
- `Upload/myw_stick.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- rev 3: студси більші (UV ×4)
