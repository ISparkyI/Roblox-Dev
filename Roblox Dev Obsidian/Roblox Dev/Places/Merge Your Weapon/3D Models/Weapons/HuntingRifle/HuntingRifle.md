---
tags: [model, weapon, block-style]
status: in-game
tier: 14
updated: 2026-11-14
---

# Hunting Rifle

← [[Weapons]]

*Мисливська гвинтівка з дерев'яним ложем і оптичним прицілом.* Зброя **тіру 14**. 🔁 **Вимога Rebirth 2:** знайти цю зброю.

![[myw_huntingrifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **14** |
| Отримати | мердж двох тіру 13 · BUY WEAPON з апгрейдом Buy Tier 14 — 797.16M |
| Ціна BUY WEAPON | 39.86M (25 × 3^(тір−1)) |
| Asset ID | `126552569198992` |
| Анімовані деталі | `Bolt` (рукоятка затвора: вгору й назад), `Scope` (окрема деталь), `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_HuntingRifle` |
| Атрибути шаблону | `Tier = 14`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` (нахил 35°, дуло вгору 22°) |
| Табличка | «Hunting Rifle · Tier 14» над зброєю |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_huntingrifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_huntingrifle_preview.png` — прев'ю
- `Upload/myw_huntingrifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: Ремінь прибрано (виглядав як мотузка), ложе потовщене.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Нова ревізія того самого Asset ID.
