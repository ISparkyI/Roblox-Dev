---
tags: [world, zone]
status: in-game
zone: 3
theme: Zombie Mining Canyon
updated: 2026-11-16
---

# Zone 3 — Zombie Mining Canyon

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 2/Zone 2|Zone 2]] ← → [[Places/Merge Your Weapon/World/Zone 4/Zone 4|Zone 4]]

*Червоний пісковиковий каньйон: шахта з рейками й вагонетками, кактуси, водонапірна вежа.*

![[myw_zone3_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone3` (атрибути `Zone = 3`, `Theme = Zombie Mining Canyon`) |
| Розмір | 170 × 170 стадів (центр ≈ z 730) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/MiningCrate/MiningCrate\|Mining Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieMiner/ZombieMiner\|Zombie Miner]] | звичайний | 600 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieDynamiter/ZombieDynamiter\|Zombie Dynamiter]] | унікальний (рідший, сильніший) | 1 700 HP | кидок динаміту |

## Декор (`Zones/Zone3/Decor`)
| Модель | Що це |
| --- | --- |
| `MineEntrance` | вхід у шахту з ліхтарями |
| `Rails` | рейки через усю зону |
| `Minecart ×3` | вагонетки з рудою |
| `OrePiles` | купи руди |
| `Dynamite` | ящики й шашки динаміту |
| `ToolShack` | сарай з інструментами |
| `WaterTower` | водонапірна вежа |
| `Hoodoos` | скельні стовпи-«худу» |
| `Cacti` | кактуси |
| `Tumbleweeds` | перекотиполе котиться (`TumbleweedClient`) |
| `CanyonSign` | табличка каньйону |
| `Props` | дрібні пропси |
| `WallTopDecor` | кактуси й каміння на стінах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
