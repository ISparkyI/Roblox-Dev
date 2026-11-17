---
tags: [model, mob, zombie]
status: in-game
zone: 4
updated: 2026-11-16
---

# Zombie Polar Explorer

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 4/Zone 4|Zone 4]] · [[Zone 4 Mobs]]

*Помаранчева парка з хутром, капюшон, гоглі, рюкзак, льодоруб.* Роль у зоні: **звичайний**.

![[myw_zombiepolarexplorer_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `99004286534747` |
| Шаблон | `ReplicatedStorage/MobModels/ZombiePolarExplorer` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +10% · зріст ≈ 6.8 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombiePolarExplorer`, `Zone = 4`, `AnimSet = Explorer` |
| Файли | `ZombiePolarExplorer/*.py` (скрипт збірки bpy), `myw_zombiepolarexplorer.glb` |

## Анімації (`MobAnimations/Explorer`)
| Що | Asset ID |
| --- | --- |
| Idle | `123794527721207` |
| Walk | `72989881794101` |
| Attack | `117568211583417` |
| Death | `91413160949835` |
| Особлива | — |

## Стати (`MobConfig.ZombiePolarExplorer`)
| Стат | Значення |
| --- | --- |
| HP | 1,100 |
| Урон за удар | 2 |
| Гроші за вбивство | 330 (6 монет розлітається) |
| Швидкість | ×0.8125 від базової (16) |
| Шанс сундука | 8.0% → [[Places/Merge Your Weapon/3D Models/Crates/FrostCrate/FrostCrate\|Frost Crate]] |
| Шанс гема | 3.0% |
| Особлива атака | — |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
