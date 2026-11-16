---
tags: [model, mob, zombie]
status: in-game
zone: 3
updated: 2026-11-16
---

# Zombie Miner

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 3/Zone 3|Zone 3]] · [[Zone 3 Mobs]]

*Жовта каска зі світним ліхтариком, сорочка, джинсовий комбінезон з латкою, рукавиці, кайло.* Роль у зоні: **звичайний**.

![[myw_zombieminer_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `91928451022538` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieMiner` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +15% від звичайного зомбі · зріст ≈ 6.9 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieMiner`, `Zone = 3`, `AnimSet = Miner` |
| Файли | `ZombieMiner/*.py` (скрипт збірки bpy), `myw_zombieminer.glb` |

## Анімації (`MobAnimations/Miner`)
| Що | Asset ID |
| --- | --- |
| Idle | `94249964678744` |
| Walk | `116467720800288` |
| Attack | `98307405797876` |
| Death | `75939675586989` |
| Особлива | — |

## Стати (`MobConfig.ZombieMiner`)
| Стат | Значення |
| --- | --- |
| HP | 600 |
| Урон за удар | 2 |
| Гроші за вбивство | 65 (5 монет розлітається) |
| Швидкість | ×0.625 від базової (16) |
| Шанс сундука | 12.0% → [[Places/Merge Your Weapon/3D Models/Crates/MiningCrate/MiningCrate\|Mining Crate]] |
| Шанс гема | 5.0% |
| Особлива атака | — |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
