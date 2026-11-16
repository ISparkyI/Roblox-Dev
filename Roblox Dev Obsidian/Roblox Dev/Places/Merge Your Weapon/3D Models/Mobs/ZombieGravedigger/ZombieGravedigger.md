---
tags: [model, mob, zombie]
status: in-game
zone: 8
updated: 2026-11-16
---

# Zombie Gravedigger

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 8/Zone 8|Zone 8]] · [[Zone 8 Mobs]]

*Брудна сорочка, коричневий комбінезон з лямками, широкий капелюх, ліхтар на спині (світиться), багнюка на одязі, лопата, грудка багнюки в лівій руці.* Роль у зоні: **звичайний**.

![[myw_zombiegravedigger_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `127623024392479` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieGravedigger` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +15% · зріст ≈ 7.4 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieGravedigger`, `Zone = 8`, `AnimSet = Gravedigger` |
| Файли | `ZombieGravedigger/*.py` (скрипт збірки bpy), `myw_zombiegravedigger.glb` |

## Анімації (`MobAnimations/Gravedigger`)
| Що | Asset ID |
| --- | --- |
| Idle | `115756615192286` |
| Walk | `90586176787489` |
| Attack | `113260868980338` |
| Death | `99947822732034` |
| Особлива | Mud (Throw) 89663118489437 |

**Як рухається:** спирається на лопату, чухає шию; бреде з лопатою на плечі; зачерпує багнюку з землі й кидає лівою рукою; удар лопатою згори двома руками; смерть — заточується і падає на спину.

## Стати (`MobConfig.ZombieGravedigger`)
| Стат | Значення |
| --- | --- |
| HP | 30,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 7.5M (7 монет розлітається) |
| Швидкість | ×0.625 від базової (16) |
| Шанс сундука | 6.0% → [[Places/Merge Your Weapon/3D Models/Crates/GraveCrate/GraveCrate\|Grave Crate]] |
| Шанс гема | 2.5% |
| Особлива атака | кидок багнюки |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
