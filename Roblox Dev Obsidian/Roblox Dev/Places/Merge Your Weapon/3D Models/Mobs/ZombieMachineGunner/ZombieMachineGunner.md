---
tags: [model, mob, zombie]
status: in-game
zone: 5
updated: 2026-11-16
---

# Zombie Machine Gunner

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 5/Zone 5|Zone 5]] · [[Zone 5 Mobs]]

*Каска з гоглами, червона бандана, пов'язка на оці, бронежилет, кулеметна стрічка через груди, ящик з набоями на спині, ручний кулемет.* Роль у зоні: **звичайний**.

![[myw_zombiemachinegunner_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `131654561743961` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieMachineGunner` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +25% · зріст ≈ 7.5 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieMachineGunner`, `Zone = 5`, `AnimSet = Gunner` |
| Файли | `ZombieMachineGunner/*.py` (скрипт збірки bpy), `myw_zombiemachinegunner.glb` |

## Анімації (`MobAnimations/Gunner`)
| Що | Asset ID |
| --- | --- |
| Idle | `88604139643507` |
| Walk | `133804211330763` |
| Attack | `84751955981602` |
| Death | `74364676830654` |
| Особлива | Fire (Throw) 139909301006822 |

**Як рухається:** кулемет біля стегна, оглядається; важка перевальцем хода; Fire — упирається і трясеться під час черги; удар кулеметом збоку; смерть — на коліна, потім обличчям уперед.

## Стати (`MobConfig.ZombieMachineGunner`)
| Стат | Значення |
| --- | --- |
| HP | 3,500 |
| Урон за удар | 3 |
| Гроші за вбивство | 6K (7 монет розлітається) |
| Швидкість | ×0.53125 від базової (16) |
| Шанс сундука | 10.0% → [[Places/Merge Your Weapon/3D Models/Crates/MilitaryCrate/MilitaryCrate\|Military Crate]] |
| Шанс гема | 4.0% |
| Особлива атака | кулеметна черга |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
