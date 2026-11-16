---
tags: [world, zone]
status: in-game
zone: 4
theme: Zombie Frozen Outpost
updated: 2026-11-16
---

# Zone 4 — Zombie Frozen Outpost

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 3/Zone 3|Zone 3]] ← → [[Places/Merge Your Weapon/World/Zone 5/Zone 5|Zone 5]]

*Засніжена полярна станція: радар, контейнери, снігохід, ліхтарі вздовж дороги.*

![[myw_zone4_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone4` (атрибути `Zone = 4`, `Theme = Zombie Frozen Outpost`) |
| Розмір | 170 × 170 стадів (центр ≈ z 900) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/FrostCrate/FrostCrate\|Frost Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombiePolarExplorer/ZombiePolarExplorer\|Zombie Polar Explorer]] | звичайний | 1 100 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieRadioOperator/ZombieRadioOperator\|Zombie Radio Operator]] | звичайний | 1 200 HP | кидок брили льоду (chill) |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieIceBrute/ZombieIceBrute\|Zombie Ice Brute]] | унікальний (рідший, сильніший) | 3 400 HP | Slam — удар об землю (chill) |

## Декор (`Zones/Zone4/Decor`)
| Модель | Що це |
| --- | --- |
| `StationHut` | будка полярної станції |
| `RadarTower` | радарна вежа |
| `Generator` | генератор |
| `Container ×3` | кольорові контейнери |
| `FrozenSnowcat` | замерзлий снігохід |
| `Sled` | сани |
| `Lamps` | ліхтарі вздовж дороги |
| `SnowDrifts` | кучугури |
| `SnowRocks` | засніжене каміння |
| `Pines` | засніжені ялини |
| `OutpostSign` | табличка форпосту |
| `WallTopDecor` | ялини й сніг на стінах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
