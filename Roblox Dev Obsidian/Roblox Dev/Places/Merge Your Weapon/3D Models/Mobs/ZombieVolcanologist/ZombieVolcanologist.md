---
tags: [model, mob, zombie]
status: in-game
zone: 9
updated: 2026-11-16
---

# Zombie Volcanologist

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 9/Zone 9|Zone 9]] · [[Zone 9 Mobs]]

*Сріблястий стьобаний термокостюм, каптур із золотим візором, червоний балон на спині, рукавиці, щипці з розпеченим лавовим каменем (світиться).* Роль у зоні: **звичайний**.

![[myw_zombievolcanologist_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `95324063833027` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieVolcanologist` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +10% · зріст ≈ 6.7 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieVolcanologist`, `Zone = 9`, `AnimSet = Volcanologist` |
| Файли | `ZombieVolcanologist/*.py` (скрипт збірки bpy), `myw_zombievolcanologist.glb` |

## Анімації (`MobAnimations/Volcanologist`)
| Що | Asset ID |
| --- | --- |
| Idle | `95127140617631` |
| Walk | `137856925008428` |
| Attack | `123860654780726` |
| Death | `83626722943614` |
| Особлива | Magma (Throw) 135287239753306 |

**Як рухається:** тримає щипці, роздивляється камінь, витирає візор; скутий крок у важкому костюмі; кидок знизу щипцями високою дугою; тичок щипцями; смерть — костюм перегрівся, хитається, сідає й падає на спину.

## Стати (`MobConfig.ZombieVolcanologist`)
| Стат | Значення |
| --- | --- |
| HP | 60,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 160M (7 монет розлітається) |
| Швидкість | ×0.59375 від базової (16) |
| Шанс сундука | 6.0% → [[Places/Merge Your Weapon/3D Models/Crates/LavaCrate/LavaCrate\|Lava Crate]] |
| Шанс гема | 2.5% |
| Особлива атака | кидок магми |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
