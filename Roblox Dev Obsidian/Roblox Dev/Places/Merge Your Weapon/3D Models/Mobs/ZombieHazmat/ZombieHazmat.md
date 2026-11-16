---
tags: [model, mob, zombie]
status: in-game
zone: 6
updated: 2026-11-16
---

# Zombie Hazmat

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 6/Zone 6|Zone 6]] · [[Zone 6 Mobs]]

*Жовтий костюм хімзахисту з чорною стрічкою, капюшон з темним візором і світними очима, фільтр, 2 балони на спині, знак небезпеки, розпилювач зі шлангом.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombiehazmat_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `89325733446313` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieHazmat` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +40% · зріст ≈ 8.7 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieHazmat`, `Zone = 6`, `AnimSet = Hazmat` |
| Файли | `ZombieHazmat/*.py` (скрипт збірки bpy), `myw_zombiehazmat.glb` |

## Анімації (`MobAnimations/Hazmat`)
| Що | Asset ID |
| --- | --- |
| Idle | `82987301352624` |
| Walk | `83781383441751` |
| Attack | `80785503002203` |
| Death | `80365915358479` |
| Особлива | Spray (Throw) 81134196503214 |

**Як рухається:** важко дихає в костюмі; важка хода з розгойдуванням; Spray — піднімає розпилювач, упирається і водить газом вліво-вправо; штовхає; смерть — на коліна, потім обличчям уперед.

## Стати (`MobConfig.ZombieHazmat`)
| Стат | Значення |
| --- | --- |
| HP | 19,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 155K (8 монет розлітається) |
| Швидкість | ×0.5 від базової (16) |
| Шанс сундука | 30.0% → [[Places/Merge Your Weapon/3D Models/Crates/ToxicCrate/ToxicCrate\|Toxic Crate]] |
| Шанс гема | 11.0% |
| Особлива атака | газ із розпилювача (отрута) |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
