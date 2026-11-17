---
tags: [model, mob, zombie]
status: in-game
zone: 9
updated: 2026-11-16
---

# Zombie Charred

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 9/Zone 9|Zone 9]] · [[Zone 9 Mobs]]

*Обвуглена шкіра з помаранчевими тріщинами, що світяться, палаючі очі й рот, обгорілі лахміття, кігті; у грі тліє (дим + жарини).* Роль у зоні: **звичайний**.

![[myw_zombiecharred_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `76134284742871` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieCharred` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +5% · зріст ≈ 6.1 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieCharred`, `Zone = 9`, `AnimSet = Charred` |
| Файли | `ZombieCharred/*.py` (скрипт збірки bpy), `myw_zombiecharred.glb` |

## Анімації (`MobAnimations/Charred`)
| Що | Asset ID |
| --- | --- |
| Idle | `130745161555526` |
| Walk | `134167979711363` |
| Attack | `117082887218802` |
| Death | `131629032344112` |
| Особлива | — |

**Як рухається:** згорблений, смикає головою, струшує жарини з руки; хиткий ривковий крок з руками вперед; подвійний удар кігтями згори; смерть — спалахує, падає на коліна й лицем у попіл.

## Стати (`MobConfig.ZombieCharred`)
| Стат | Значення |
| --- | --- |
| HP | 45,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 120M (6 монет розлітається) |
| Швидкість | ×0.75 від базової (16) |
| Шанс сундука | 5.0% → [[Places/Merge Your Weapon/3D Models/Crates/LavaCrate/LavaCrate\|Lava Crate]] |
| Шанс гема | 2.0% |
| Особлива атака | удар з отрутою + горіння |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
