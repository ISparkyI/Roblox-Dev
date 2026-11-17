---
tags: [model, mob, zombie]
status: in-game
zone: 4
updated: 2026-11-16
---

# Zombie Ice Brute

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 4/Zone 4|Zone 4]] · [[Zone 4 Mobs]]

*Величезний, сіра безрукавка з мотузкою, крижані наростання на плечах і руках, світні очі.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombieicebrute_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `103977268459552` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieIceBrute` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +50% · зріст ≈ 9.2 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieIceBrute`, `Zone = 4`, `AnimSet = Brute` |
| Файли | `ZombieIceBrute/*.py` (скрипт збірки bpy), `myw_zombieicebrute.glb` |

## Анімації (`MobAnimations/Brute`)
| Що | Asset ID |
| --- | --- |
| Idle | `76900137478670` |
| Walk | `93007525638406` |
| Attack | `86115859026493` |
| Death | `127692669108621` |
| Особлива | Slam 119382697663990 |

## Стати (`MobConfig.ZombieIceBrute`)
| Стат | Значення |
| --- | --- |
| HP | 3,400 |
| Урон за удар | 3 |
| Гроші за вбивство | 810 (8 монет розлітається) |
| Швидкість | ×0.5 від базової (16) |
| Шанс сундука | 23.0% → [[Places/Merge Your Weapon/3D Models/Crates/FrostCrate/FrostCrate\|Frost Crate]] |
| Шанс гема | 12.0% |
| Особлива атака | Slam — удар об землю (chill) |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
