---
tags: [model, mob, zombie]
status: in-game
zone: 6
updated: 2026-11-16
---

# Zombie Chemist

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 6/Zone 6|Zone 6]] · [[Zone 6 Mobs]]

*Білий халат у зелених плямах, сорочка з краваткою, гоглі, лисина з розпатланим волоссям, жовті гумові рукавиці, колби на поясі, колба з отрутою в руці.* Роль у зоні: **звичайний**.

![[myw_zombiechemist_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `113051847008558` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieChemist` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +5% · зріст ≈ 6.3 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieChemist`, `Zone = 6`, `AnimSet = Chemist` |
| Файли | `ZombieChemist/*.py` (скрипт збірки bpy), `myw_zombiechemist.glb` |

## Анімації (`MobAnimations/Chemist`)
| Що | Asset ID |
| --- | --- |
| Idle | `105991702190390` |
| Walk | `125656056170747` |
| Attack | `94673227425575` |
| Death | `77593081892906` |
| Особлива | Throw 128851249263452 |

**Як рухається:** трясе колбу, нахиляє голову, «хихоче»; швидке згорблене дріботіння з колбою вгорі; кидок збоку з замахом за спину; тичок колбою + ляпас; смерть — розвертається, руки в сторони, падає на спину.

## Стати (`MobConfig.ZombieChemist`)
| Стат | Значення |
| --- | --- |
| HP | 6,000 |
| Урон за удар | 3 |
| Гроші за вбивство | 40K (6 монет розлітається) |
| Швидкість | ×0.65625 від базової (16) |
| Шанс сундука | 8.0% → [[Places/Merge Your Weapon/3D Models/Crates/ToxicCrate/ToxicCrate\|Toxic Crate]] |
| Шанс гема | 3.5% |
| Особлива атака | кидок колби (отрута) |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
