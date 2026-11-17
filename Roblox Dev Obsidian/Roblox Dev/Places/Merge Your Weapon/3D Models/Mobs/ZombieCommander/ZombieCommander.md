---
tags: [model, mob, zombie]
status: in-game
zone: 5
updated: 2026-11-16
---

# Zombie Commander

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 5/Zone 5|Zone 5]] · [[Zone 5 Mobs]]

*Кашкет з червоним околом і кокардою, шинель із золотими гудзиками, епалети, ордени, червона стрічка, сигара, червоні очі, граната в руці, гранати на поясі.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombiecommander_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `118271998769802` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieCommander` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +35% · зріст ≈ 8.3 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieCommander`, `Zone = 5`, `AnimSet = Commander` |
| Файли | `ZombieCommander/*.py` (скрипт збірки bpy), `myw_zombiecommander.glb` |

## Анімації (`MobAnimations/Commander`)
| Що | Asset ID |
| --- | --- |
| Idle | `97607311620673` |
| Walk | `124081324667267` |
| Attack | `86711939422922` |
| Death | `77952779713856` |
| Особлива | Throw 95220533665550 |

**Як рухається:** груди вперед, рука за спиною, вказує вперед; парадний крок з високими колінами; кидок — висмикує чеку, кидок з-за голови; ляпас; смерть — останнє віддання честі і падає «дошкою» на спину.

## Стати (`MobConfig.ZombieCommander`)
| Стат | Значення |
| --- | --- |
| HP | 8,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 18K (8 монет розлітається) |
| Швидкість | ×0.5625 від базової (16) |
| Шанс сундука | 30.0% → [[Places/Merge Your Weapon/3D Models/Crates/MilitaryCrate/MilitaryCrate\|Military Crate]] |
| Шанс гема | 12.0% |
| Особлива атака | кидок гранати |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
