---
tags: [model, mob, zombie]
status: in-game
zone: 9
updated: 2026-11-16
---

# Zombie Lava Golem

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 9/Zone 9|Zone 9]] · [[Zone 9 Mobs]]

*Величезний базальтовий голем: пластини на грудях, розплавлене ядро, лавові тріщини, корона з кам'яних шипів, кулаки-брили; у грі світиться й сипле іскрами.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombielavagolem_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `75373126189148` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieLavaGolem` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +80% · зріст ≈ 10.8 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieLavaGolem`, `Zone = 9`, `AnimSet = LavaGolem` |
| Файли | `ZombieLavaGolem/*.py` (скрипт збірки bpy), `myw_zombielavagolem.glb` |

## Анімації (`MobAnimations/LavaGolem`)
| Що | Asset ID |
| --- | --- |
| Idle | `139855088845080` |
| Walk | `114523458006789` |
| Attack | `92805831809215` |
| Death | `129435165407738` |
| Особлива | Eruption (Throw) 137746791782083 |

**Як рухається:** важко дихає, перекочується з ноги на ногу; повільні тупі кроки з розгойдуванням; виверження — обидва кулаки вгору, удар об землю й лишається зігнутим, поки падає лава; хук правою + удар лівою; смерть — тріскається, холоне, на коліна й валиться назад.

## Стати (`MobConfig.ZombieLavaGolem`)
| Стат | Значення |
| --- | --- |
| HP | 205,000 |
| Урон за удар | 5 |
| Гроші за вбивство | 720M (9 монет розлітається) |
| Швидкість | ×0.46875 від базової (16) |
| Шанс сундука | 35.0% → [[Places/Merge Your Weapon/3D Models/Crates/LavaCrate/LavaCrate\|Lava Crate]] |
| Шанс гема | 12.0% |
| Особлива атака | виверження — лавові бомби |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
