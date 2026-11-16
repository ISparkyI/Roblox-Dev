---
tags: [model, mob, zombie]
status: in-game
zone: 7
updated: 2026-11-16
---

# Zombie Mutant

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 7/Zone 7|Zone 7]] · [[Zone 7 Mobs]]

*Величезний фіолетовий, права рука більша з кістяними шипами, кістки на спині й голові, світні рожеві вени, рвані джинси, босі ноги з кігтями.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombiemutant_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `106029320186624` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieMutant` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +60% · зріст ≈ 9.4 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieMutant`, `Zone = 7`, `AnimSet = Mutant` |
| Файли | `ZombieMutant/*.py` (скрипт збірки bpy), `myw_zombiemutant.glb` |

## Анімації (`MobAnimations/Mutant`)
| Що | Asset ID |
| --- | --- |
| Idle | `71141148480691` |
| Walk | `136951175412039` |
| Attack | `87439973735393` |
| Death | `117520973900668` |
| Особлива | Leap (Throw) 133822893874765 |

**Як рухається:** згорблений, важко дихає, смикає рукою; хода на кулаках; стрибок — присідає, летить з руками вгору, б'є кулаками в землю; удар рукою; смерть — реве в небо, б'є себе в груди, падає вперед.

## Стати (`MobConfig.ZombieMutant`)
| Стат | Значення |
| --- | --- |
| HP | 53,000 |
| Урон за удар | 5 |
| Гроші за вбивство | 3.2M (9 монет розлітається) |
| Швидкість | ×0.5625 від базової (16) |
| Шанс сундука | 35.0% → [[Places/Merge Your Weapon/3D Models/Crates/CityCrate/CityCrate\|City Crate]] |
| Шанс гема | 13.0% |
| Особлива атака | стрибок з ударом об землю |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
