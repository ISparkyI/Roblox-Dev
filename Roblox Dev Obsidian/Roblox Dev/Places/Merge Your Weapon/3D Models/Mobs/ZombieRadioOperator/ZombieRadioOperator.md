---
tags: [model, mob, zombie]
status: in-game
zone: 4
updated: 2026-11-16
---

# Zombie Radio Operator

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 4/Zone 4|Zone 4]] · [[Zone 4 Mobs]]

*Синя куртка, червоний шарф, шапка з навушниками й мікрофоном, рація на спині з антеною, брила льоду в руці.* Роль у зоні: **звичайний**.

![[myw_zombieradiooperator_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `93064257070775` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieRadioOperator` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | 1.0 · зріст ≈ 6.2 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieRadioOperator`, `Zone = 4`, `AnimSet = Operator` |
| Файли | `ZombieRadioOperator/*.py` (скрипт збірки bpy), `myw_zombieradiooperator.glb` |

## Анімації (`MobAnimations/Operator`)
| Що | Asset ID |
| --- | --- |
| Idle | `73116862822380` |
| Walk | `102496067898754` |
| Attack | `132544549477560` |
| Death | `82814377341346` |
| Особлива | Throw 98030665470766 |

## Стати (`MobConfig.ZombieRadioOperator`)
| Стат | Значення |
| --- | --- |
| HP | 1,200 |
| Урон за удар | 2 |
| Гроші за вбивство | 360 (6 монет розлітається) |
| Швидкість | ×0.625 від базової (16) |
| Шанс сундука | 9.0% → [[Places/Merge Your Weapon/3D Models/Crates/FrostCrate/FrostCrate\|Frost Crate]] |
| Шанс гема | 4.0% |
| Особлива атака | кидок брили льоду (chill) |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
