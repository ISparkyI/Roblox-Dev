---
tags: [world, zone]
status: in-game
zone: 6
theme: Zombie Toxic Factory
updated: 2026-11-16
---

# Zone 6 — Zombie Toxic Factory

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 5/Zone 5|Zone 5]] ← → [[Places/Merge Your Weapon/World/Zone 7/Zone 7|Zone 7]]

*Сірий завод: цех, цистерни, конвеєр, світні зелені калюжі й басейн з отрутою.*

![[myw_zone6_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone6` (атрибути `Zone = 6`, `Theme = Zombie Toxic Factory`) |
| Розмір | 170 × 170 стадів (центр ≈ z 1240) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/ToxicCrate/ToxicCrate\|Toxic Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieWorker/ZombieWorker\|Zombie Worker]] | звичайний | 4 500 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieChemist/ZombieChemist\|Zombie Chemist]] | звичайний | 6 000 HP | кидок колби (отрута) |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieHazmat/ZombieHazmat\|Zombie Hazmat]] | унікальний (рідший, сильніший) | 19 000 HP | газ із розпилювача (отрута) |

## Декор (`Zones/Zone6/Decor`)
| Модель | Що це |
| --- | --- |
| `FactoryHall` | цех з вентиляцією |
| `ChemTanks` | хімічні цистерни |
| `Conveyor` | конвеєр |
| `ToxicPool` | світний токсичний басейн |
| `ToxicPuddle ×4, Puddles` | токсичні калюжі |
| `ToxicBarrels` | бочки з отрутою |
| `HazardFences` | огорожі з попередженнями |
| `WallPipes` | труби на стінах |
| `Lamps` | ліхтарі |
| `FactorySign` | табличка заводу |
| `WallTopDecor` | труби й бочки на стінах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
