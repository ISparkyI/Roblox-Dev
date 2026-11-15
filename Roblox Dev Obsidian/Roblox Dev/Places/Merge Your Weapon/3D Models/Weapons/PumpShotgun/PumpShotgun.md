---
tags: [model, weapon, block-style]
status: in-game
tier: 12
updated: 2026-11-14
---

# Pump Shotgun

← [[Weapons]]

*Помпова рушниця.* Зброя **тіру 12**. Стоїть на стенді **+500 WEAPONS**. Дається в SUPER PACK. Остання модель на зараз.

![[myw_pumpshotgun_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **12** |
| Отримати | мердж двох тіру 11 · BUY WEAPON з апгрейдом Buy Tier 12 — 88.57M |
| Ціна BUY WEAPON | 4.43M (25 × 3^(тір−1)) |
| Asset ID | `83810662062512` |
| Анімовані деталі | `Pump` (цівка ковзає вздовж ствола), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_PumpShotgun` |
| Атрибути шаблону | `Tier = 12`, `Kind` (Long / Upright), `MuzzleDir`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Pump Shotgun · Tier 12» над зброєю (PlotWeaponService) |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_pumpshotgun.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_pumpshotgun_preview.png` — прев'ю
- `Upload/myw_pumpshotgun.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-13: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
