---
tags: [model, mob, zombie]
status: in-game
zone: 10
updated: 2026-11-16
---

# Zombie Lab Assistant

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 10/Zone 10|Zone 10]] · [[Zone 10 Mobs]]

*Розстебнутий білий халат, блакитна сорочка з краваткою, бейдж, плями, окуляри-гогли на лобі, планшет у лівій руці, шприц із зеленою рідиною в правій.* Роль у зоні: **звичайний**.

![[myw_zombielabassistant_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `95745919415261` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieLabAssistant` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | 1.0 · зріст ≈ 5.7 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieLabAssistant`, `Zone = 10`, `AnimSet = LabAssistant` |
| Файли | `ZombieLabAssistant/*.py` (скрипт збірки bpy), `myw_zombielabassistant.glb` |

## Анімації (`MobAnimations/LabAssistant`)
| Що | Asset ID |
| --- | --- |
| Idle | `115687428645800` |
| Walk | `70419195758307` |
| Attack | `110062841439306` |
| Death | `71143960188636` |
| Особлива | — |

**Як рухається:** читає планшет, щось чиркає, озирається; швидкий згорблений дріботливий крок зі шприцом угорі; удар шприцом згори; смерть — хапається за груди, крутиться й падає.

## Стати (`MobConfig.ZombieLabAssistant`)
| Стат | Значення |
| --- | --- |
| HP | 120,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 2.4B (6 монет розлітається) |
| Швидкість | ×0.75 від базової (16) |
| Шанс сундука | 5.0% → [[Places/Merge Your Weapon/3D Models/Crates/LabCrate/LabCrate\|Lab Crate]] |
| Шанс гема | 2.0% |
| Особлива атака | удар шприцом з отрутою |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
