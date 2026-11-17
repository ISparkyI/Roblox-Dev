---
tags: [world, zone]
status: in-game
zone: 7
theme: Zombie Ruined City
updated: 2026-11-16
---

# Zone 7 — Zombie Ruined City

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 6/Zone 6|Zone 6]] ← → [[Places/Merge Your Weapon/World/Zone 8/Zone 8|Zone 8]]

*Зруйноване місто: вулиця з розміткою, розбиті будинки, перекинутий автобус, поліцейська машина.*

![[myw_zone7_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone7` (атрибути `Zone = 7`, `Theme = Zombie Ruined City`) |
| Розмір | 170 × 170 стадів (центр ≈ z 1410) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/CityCrate/CityCrate\|City Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombiePolice/ZombiePolice\|Zombie Police]] | звичайний | 9 000 HP | 3 постріли з пістолета |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieFirefighter/ZombieFirefighter\|Zombie Firefighter]] | звичайний | 11 000 HP | струмінь води з брандспойта |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieMutant/ZombieMutant\|Zombie Mutant]] | унікальний (рідший, сильніший) | 53 000 HP | стрибок з ударом об землю |

## Декор (`Zones/Zone7/Decor`)
| Модель | Що це |
| --- | --- |
| `Street` | дорога з розміткою |
| `RuinedBuildingE / W` | зруйновані будинки обабіч |
| `Skyline` | хмарочоси на фоні |
| `TippedBus` | перекинутий шкільний автобус |
| `PoliceCar` | поліцейська машина |
| `Taxi` | таксі |
| `BurningCar` | палаюче авто |
| `TrafficLight` | світлофор |
| `StreetLamps` | ліхтарі |
| `Hydrant` | гідрант |
| `Barricades` | барикади |
| `Craters` | вирви |
| `CitySign` | табличка міста |
| `WallTopDecor` | антени й кондиціонери на дахах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
