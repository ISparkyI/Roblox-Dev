---
tags: [model, weapon, block-style]
status: in-game
tier: 10
updated: 2026-11-14
---

# Lever Rifle

← [[Weapons]]

*Гвинтівка з латунною ствольною коробкою.* Зброя **тіру 10**. Відкривається після Rebirth 1.

![[myw_leverrifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **10** |
| Отримати | мердж двох тіру 9 · BUY WEAPON з апгрейдом Buy Tier 10 — 9.84M |
| Ціна BUY WEAPON | 492.07K (25 × 3^(тір−1)) |
| Asset ID | `105364300033618` |
| Анімовані деталі | `Lever` (скоба), `Hammer`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_LeverRifle` |
| Атрибути шаблону | `Tier = 10`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Lever Rifle · Tier 10» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_leverrifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_leverrifle_preview.png` — прев'ю
- `Upload/myw_leverrifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- Розвернута в Roblox (pivot flip), щоб дуло дивилось у той самий бік, що в інших
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
