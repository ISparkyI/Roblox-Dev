---
tags: [model, weapon, block-style]
status: in-game
tier: 9
updated: 2026-11-14
---

# Revolver

← [[Weapons]]

*Шестизарядний револьвер.* Зброя **тіру 9**. 🔁 **Вимога Rebirth 1:** знайти цю зброю. Дається в EPIC PACK.

![[myw_revolver_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **9** |
| Отримати | мердж двох тіру 8 · BUY WEAPON з апгрейдом Buy Tier 9 — 3.28M |
| Ціна BUY WEAPON | 164.03K (25 × 3^(тір−1)) |
| Asset ID | `93100312022032` (rev 2) |
| Анімовані деталі | `Cylinder` (обертається), `Hammer`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_Revolver` |
| Атрибути шаблону | `Tier = 9`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Revolver · Tier 9» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_revolver.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_revolver_preview.png` — прев'ю
- `Upload/myw_revolver.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- rev 2: нова форма (стара «покемон» не сподобалась)
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
