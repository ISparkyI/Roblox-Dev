---
tags: [model, weapon, block-style]
status: in-game
tier: 16
updated: 2026-11-14
---

# Auto Shotgun

← [[Weapons]]

*Автоматичний дробовик з барабанним магазином.* Зброя **тіру 16**. Дріб чергою. Червоні й жовті акценти.

![[myw_autoshotgun_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **16** |
| Отримати | мердж двох тіру 15 · BUY WEAPON з апгрейдом Buy Tier 16 — 7.17B |
| Ціна BUY WEAPON | 358.72M (25 × 3^(тір−1)) |
| Asset ID | `100427844770808` |
| Анімовані деталі | `Drum` (барабан: крутиться / падає), `Bolt` (жовта рукоятка), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_AutoShotgun` |
| Атрибути шаблону | `Tier = 16`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Auto Shotgun · Tier 16» над зброєю |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_autoshotgun.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_autoshotgun_preview.png` — прев'ю
- `Upload/myw_autoshotgun.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: Перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
