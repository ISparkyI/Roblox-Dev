---
tags: [world, zone]
status: in-game
zone: 2
theme: Zombie Lumber Camp
updated: 2026-11-16
---

# Zone 2 — Zombie Lumber Camp

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 1/Zone 1|Zone 1]] ← → [[Places/Merge Your Weapon/World/Zone 3/Zone 3|Zone 3]]

*Галявина в лісі: табір з наметами і вогнищем, пилорама, хатинка, колоди.*

![[myw_zone2_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone2` (атрибути `Zone = 2`, `Theme = Zombie Lumber Camp`) |
| Розмір | 170 × 170 стадів (центр ≈ z 560) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/LumberCrate/LumberCrate\|Lumber Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieLumberjack/ZombieLumberjack\|Zombie Lumberjack]] | звичайний | 130 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieTourist/ZombieTourist\|Zombie Tourist]] | звичайний | 130 HP | спалах фотоапарата |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieAxeThrower/ZombieAxeThrower\|Zombie Axe Thrower]] | унікальний (рідший, сильніший) | 390 HP | кидок сокири |

## Декор (`Zones/Zone2/Decor`)
| Модель | Що це |
| --- | --- |
| `Sawmill` | пилорама під навісом |
| `Cabin` | дерев'яна хатинка з освітленим вікном |
| `Camp` | наметовий табір з вогнищем |
| `CampSign` | табличка табору |
| `FelledTree` | повалене дерево |
| `LogPile ×3` | штабелі колод |
| `Stumps` | пеньки |
| `Pines` | ялини |
| `Props` | дрібні пропси (сокири, колоди) |
| `WallTopDecor` | ялини на гребенях стін |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
