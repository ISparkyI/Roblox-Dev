---
tags: [model, weapon, block-style]
status: in-game
tier: 19
updated: 2026-11-14
---

# Sniper Rifle

← [[Weapons]]

*Снайперська гвинтівка: скелетний приклад, великий приціл, сині акценти, сошки.* Зброя **тіру 19**. 🔁 **Вимога Rebirth 3:** знайти цю зброю. Прошиває всю лінію.

![[myw_sniperrifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **19** |
| Отримати | мердж двох тіру 18 · BUY WEAPON з апгрейдом Buy Tier 19 — 193.71B |
| Ціна BUY WEAPON | 9.69B (25 × 3^(тір−1)) |
| Asset ID | `125286367637957` |
| Анімовані деталі | `Bolt` (рукоятка затвора), `Bipod`, `Mag`, `Scope`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_SniperRifle` |
| Атрибути шаблону | `Tier = 19`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 19 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_sniperrifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_sniperrifle_preview.png` — прев'ю
- `Upload/myw_sniperrifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Сошки на окремому кріпленні під стволом — прибрано мерехтіння (накладені грані). Нова ревізія того самого Asset ID.
