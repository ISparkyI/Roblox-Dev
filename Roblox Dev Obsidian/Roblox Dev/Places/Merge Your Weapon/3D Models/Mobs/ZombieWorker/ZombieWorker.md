---
tags: [model, mob, zombie]
status: in-game
zone: 6
updated: 2026-11-16
---

# Zombie Worker

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 6/Zone 6|Zone 6]] · [[Zone 6 Mobs]]

*Сіро-синій комбінезон, помаранчевий світловідбивний жилет, респіратор з червоними фільтрами, жовті навушники, рукавиці, гайковий ключ.* Роль у зоні: **звичайний**.

![[myw_zombieworker_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `101650381731236` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieWorker` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | 1.0 · зріст ≈ 5.7 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieWorker`, `Zone = 6`, `AnimSet = Worker` |
| Файли | `ZombieWorker/*.py` (скрипт збірки bpy), `myw_zombieworker.glb` |

## Анімації (`MobAnimations/Worker`)
| Що | Asset ID |
| --- | --- |
| Idle | `102057863922118` |
| Walk | `72448882432060` |
| Attack | `89854288613639` |
| Death | `120535229754623` |
| Особлива | — |

**Як рухається:** згорблений, стукає ключем по долоні, кашляє; втомлене човгання; удар ключем згори; смерть — хапається за груди, кашляє, падає набік.

## Стати (`MobConfig.ZombieWorker`)
| Стат | Значення |
| --- | --- |
| HP | 4,500 |
| Урон за удар | 3 |
| Гроші за вбивство | 30K (6 монет розлітається) |
| Швидкість | ×0.6875 від базової (16) |
| Шанс сундука | 5.0% → [[Places/Merge Your Weapon/3D Models/Crates/ToxicCrate/ToxicCrate\|Toxic Crate]] |
| Шанс гема | 2.0% |
| Особлива атака | — |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
