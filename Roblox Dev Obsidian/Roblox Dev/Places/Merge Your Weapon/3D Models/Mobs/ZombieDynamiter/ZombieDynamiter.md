---
tags: [model, mob, zombie]
status: in-game
zone: 3
updated: 2026-11-16
---

# Zombie Dynamiter

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 3/Zone 3|Zone 3]] · [[Zone 3 Mobs]]

*Шолом з помаранчевим ліхтарем, гоглі на лобі, смугаста сорочка, шкіряний фартух, патронташ з динамітом, сумка з шашками, запалена шашка в руці.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombiedynamiter_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `122111223530028` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieDynamiter` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +50% · зріст ≈ 9.1 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieDynamiter`, `Zone = 3`, `AnimSet = Dynamiter` |
| Файли | `ZombieDynamiter/*.py` (скрипт збірки bpy), `myw_zombiedynamiter.glb` |

## Анімації (`MobAnimations/Dynamiter`)
| Що | Asset ID |
| --- | --- |
| Idle | `109619118005160` |
| Walk | `133698266592038` |
| Attack | `106904691239534` |
| Death | `79229368251411` |
| Особлива | Throw 136869812113679 |

## Стати (`MobConfig.ZombieDynamiter`)
| Стат | Значення |
| --- | --- |
| HP | 1,700 |
| Урон за удар | 3 |
| Гроші за вбивство | 194 (6 монет розлітається) |
| Швидкість | ×0.53125 від базової (16) |
| Шанс сундука | 37.0% → [[Places/Merge Your Weapon/3D Models/Crates/MiningCrate/MiningCrate\|Mining Crate]] |
| Шанс гема | 13.0% |
| Особлива атака | кидок динаміту |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
