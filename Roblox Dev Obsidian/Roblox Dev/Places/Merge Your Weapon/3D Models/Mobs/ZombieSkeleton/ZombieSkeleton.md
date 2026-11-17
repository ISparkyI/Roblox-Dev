---
tags: [model, mob, zombie]
status: in-game
zone: 8
updated: 2026-11-16
---

# Zombie Skeleton

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 8/Zone 8|Zone 8]] · [[Zone 8 Mobs]]

*Реберна клітка з темними проміжками, хребет, череп з фіолетовими очима й тріщиною, іржавий шолом зі шпилем, іржавий наплічник, рвана пов'язка, іржавий меч.* Роль у зоні: **звичайний**.

![[myw_zombieskeleton_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `140680532023755` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieSkeleton` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | 1.0 · зріст ≈ 6.3 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieSkeleton`, `Zone = 8`, `AnimSet = Skeleton` |
| Файли | `ZombieSkeleton/*.py` (скрипт збірки bpy), `myw_zombieskeleton.glb` |

## Анімації (`MobAnimations/Skeleton`)
| Що | Asset ID |
| --- | --- |
| Idle | `100003448593768` |
| Walk | `100760405736171` |
| Attack | `132731406797486` |
| Death | `112363185991902` |
| Особлива | — |

**Як рухається:** гойдається, голова «торохтить»; швидкий смиканий біг; діагональний удар мечем з-за плеча; смерть — кістки підкошуються, розсипається донизу.

## Стати (`MobConfig.ZombieSkeleton`)
| Стат | Значення |
| --- | --- |
| HP | 22,000 |
| Урон за удар | 4 |
| Гроші за вбивство | 5.2M (6 монет розлітається) |
| Швидкість | ×0.8125 від базової (16) |
| Шанс сундука | 5.0% → [[Places/Merge Your Weapon/3D Models/Crates/GraveCrate/GraveCrate\|Grave Crate]] |
| Шанс гема | 2.0% |
| Особлива атака | — |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
