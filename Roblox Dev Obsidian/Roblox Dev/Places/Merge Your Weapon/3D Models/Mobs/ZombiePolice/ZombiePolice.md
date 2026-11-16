---
tags: [model, mob, zombie]
status: in-game
zone: 7
updated: 2026-11-16
---

# Zombie Police

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 7/Zone 7|Zone 7]] · [[Zone 7 Mobs]]

*Синя форма з краваткою, жетон, нашивки, кашкет з кокардою, темні окуляри з червоними очима, пояс з рацією й наручниками, кобура, пістолет.* Роль у зоні: **звичайний**.

![[myw_zombiepolice_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `80573442493001` |
| Шаблон | `ReplicatedStorage/MobModels/ZombiePolice` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | 1.0 · зріст ≈ 6.0 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombiePolice`, `Zone = 7`, `AnimSet = Police` |
| Файли | `ZombiePolice/*.py` (скрипт збірки bpy), `myw_zombiepolice.glb` |

## Анімації (`MobAnimations/Police`)
| Що | Asset ID |
| --- | --- |
| Idle | `88580832306224` |
| Walk | `137319035643626` |
| Attack | `104916486551095` |
| Death | `100967312001029` |
| Особлива | Shoot (Throw) 96234325001894 |

**Як рухається:** рука біля кобури, озирається, поправляє кашкет; патрульна хода; стрільба двома руками з віддачею (3 постріли); удар рукояткою; смерть — розворот і падіння набік.

## Стати (`MobConfig.ZombiePolice`)
| Стат | Значення |
| --- | --- |
| HP | 9,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 600K (6 монет розлітається) |
| Швидкість | ×0.6875 від базової (16) |
| Шанс сундука | 5.0% → [[Places/Merge Your Weapon/3D Models/Crates/CityCrate/CityCrate\|City Crate]] |
| Шанс гема | 2.0% |
| Особлива атака | 3 постріли з пістолета |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
