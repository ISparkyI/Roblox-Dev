---
tags: [world, zone]
status: in-game
zone: 1
theme: Zombie Farm
updated: 2026-11-16
---

# Zone 1 — Zombie Farm

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Spawn/Spawn|Spawn]] ← → [[Places/Merge Your Weapon/World/Zone 2/Zone 2|Zone 2]]

*Зелена ферма: дорога через поле, амбар, силос, вітряк, трактор, грядки.*

![[myw_zone1_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone1` (атрибути `Zone = 1`, `Theme = Zombie Farm`) |
| Розмір | 170 × 170 стадів (центр ≈ z 384) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/FarmCrate/FarmCrate\|Farm Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieFarmer/ZombieFarmer\|Zombie Farmer]] | звичайний | 60 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieFarmerBoss/ZombieFarmerBoss\|Zombie Farmer Boss]] | унікальний (рідший, сильніший) | 180 HP | удар вилами з випадом |

## Декор (`Zones/Zone1/Decor`)
| Модель | Що це |
| --- | --- |
| `Barn` | червоний амбар з білими рамами |
| `Silo` | силос у червоно-білу смугу |
| `Windmill` | вітряк, лопаті крутяться (`WindmillAnimator`) |
| `Tractor` | зелений трактор |
| `WheatField` | пшеничне поле за парканом |
| `CabbageField` | грядки капусти з опудалом |
| `PumpkinPatch` | гарбузи |
| `HayBales` | тюки сіна |
| `ChickenCoop` | курник |
| `Well` | криниця |
| `Trough` | корито |
| `Barrel ×4` | бочки |
| `Crate ×5` | ящики |
| `Bush ×5, Rocks ×2, Flowers, LeafyTree` | рослинність і каміння |
| `WallTopDecor` | декор на гребенях стін |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
