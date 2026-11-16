---
tags: [world, zone]
status: in-game
zone: 5
theme: Zombie Military Base
updated: 2026-11-16
---

# Zone 5 — Zombie Military Base

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 4/Zone 4|Zone 4]] ← → [[Places/Merge Your Weapon/World/Zone 6/Zone 6|Zone 6]]

*Військова база в оливкових тонах: бункер, танк, вантажівка, вежа з прожектором, гелікоптерний майданчик.*

![[myw_zone5_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone5` (атрибути `Zone = 5`, `Theme = Zombie Military Base`) |
| Розмір | 170 × 170 стадів (центр ≈ z 1070) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/MilitaryCrate/MilitaryCrate\|Military Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieSoldier/ZombieSoldier\|Zombie Soldier]] | звичайний | 2 000 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieMachineGunner/ZombieMachineGunner\|Zombie Machine Gunner]] | звичайний | 3 500 HP | кулеметна черга |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieCommander/ZombieCommander\|Zombie Commander]] | унікальний (рідший, сильніший) | 8 000 HP | кидок гранати |

## Декор (`Zones/Zone5/Decor`)
| Модель | Що це |
| --- | --- |
| `Bunker` | бетонний бункер |
| `WatchTower` | сторожова вежа з прожектором |
| `Tank` | танк |
| `Truck` | вантажівка |
| `Helipad` | вертолітний майданчик |
| `Tent ×2` | армійські намети |
| `CamoNet` | маскувальна сітка |
| `Emplacements` | укріплення з мішків |
| `Hedgehogs` | протитанкові їжаки |
| `Barriers` | бар'єри |
| `AmmoCrates` | ящики з набоями |
| `Barrels` | бочки |
| `Floodlights` | прожектори |
| `Flagpole` | флагшток |
| `BaseSign` | табличка бази |
| `WallTopDecor` | паркан і ящики на стінах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
