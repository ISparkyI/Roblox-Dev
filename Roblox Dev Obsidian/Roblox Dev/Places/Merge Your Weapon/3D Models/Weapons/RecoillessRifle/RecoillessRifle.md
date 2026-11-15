---
tags: [model, weapon, block-style]
status: in-game
tier: 25
updated: 2026-11-14
---

# Recoilless Rifle

← [[Weapons]]

*Безвідкатна труба з плеча: товста оливкова труба з жовтими кільцями, сталеве сопло ззаду, оптика.* Зброя **тіру 25**. Далеко, вибух по лінії.

![[myw_recoillessrifle_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **25** |
| Отримати | мердж двох тіру 24 · BUY WEAPON з апгрейдом Buy Tier 25 — 141.21T |
| Ціна BUY WEAPON | 7.06T (25 × 3^(тір−1)) |
| Asset ID | `128660238045872` |
| Анімовані деталі | `Venturi` (сопло відкидається для перезарядки), `Grips`, `Trigger` |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_RecoillessRifle` |
| Атрибути шаблону | `Tier = 25`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 25 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_recoillessrifle.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_recoillessrifle_preview.png` — прев'ю
- `Upload/myw_recoillessrifle.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: фікс мешу — усі грані назовні (труби більше не вивернуті), відкриті кінці стволів порожнисті. Заглушку каналу ствола зсунуто всередину труби. Нова ревізія того самого Asset ID.
