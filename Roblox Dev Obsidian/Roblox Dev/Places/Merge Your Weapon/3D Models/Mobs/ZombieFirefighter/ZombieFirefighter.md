---
tags: [model, mob, zombie]
status: in-game
zone: 7
updated: 2026-11-16
---

# Zombie Firefighter

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 7/Zone 7|Zone 7]] · [[Zone 7 Mobs]]

*Пісочна куртка й штани зі світловідбивними смугами, червоний шолом з емблемою, балон на спині, маска збоку, кіптява, брандспойт зі шлангом.* Роль у зоні: **звичайний**.

![[myw_zombiefirefighter_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `109729079034959` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieFirefighter` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +10% · зріст ≈ 6.8 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieFirefighter`, `Zone = 7`, `AnimSet = Firefighter` |
| Файли | `ZombieFirefighter/*.py` (скрипт збірки bpy), `myw_zombiefirefighter.glb` |

## Анімації (`MobAnimations/Firefighter`)
| Що | Asset ID |
| --- | --- |
| Idle | `92508986953920` |
| Walk | `89164492813872` |
| Attack | `73617667605144` |
| Death | `87853711830274` |
| Особлива | Hose (Throw) 103198313445451 |

**Як рухається:** брандспойт донизу, витирає кіптяву з обличчя; важкі кроки; брандспойт двома руками, струмінь його трясе; таран плечем; смерть — на коліна, балон тягне на спину.

## Стати (`MobConfig.ZombieFirefighter`)
| Стат | Значення |
| --- | --- |
| HP | 11,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 750K (6 монет розлітається) |
| Швидкість | ×0.59375 від базової (16) |
| Шанс сундука | 6.0% → [[Places/Merge Your Weapon/3D Models/Crates/CityCrate/CityCrate\|City Crate]] |
| Шанс гема | 2.5% |
| Особлива атака | струмінь води з брандспойта |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
