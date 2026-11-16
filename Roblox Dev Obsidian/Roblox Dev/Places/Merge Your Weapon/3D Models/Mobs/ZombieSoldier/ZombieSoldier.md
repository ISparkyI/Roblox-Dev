---
tags: [model, mob, zombie]
status: in-game
zone: 5
updated: 2026-11-16
---

# Zombie Soldier

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 5/Zone 5|Zone 5]] · [[Zone 5 Mobs]]

*Камуфляж з латками, каска з сіткою, розгрузка з підсумками, жетон, гвинтівка зі штиком.* Роль у зоні: **звичайний**.

![[myw_zombiesoldier_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `86238412630312` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieSoldier` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +5% · зріст ≈ 6.3 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieSoldier`, `Zone = 5`, `AnimSet = Soldier` |
| Файли | `ZombieSoldier/*.py` (скрипт збірки bpy), `myw_zombiesoldier.glb` |

## Анімації (`MobAnimations/Soldier`)
| Що | Asset ID |
| --- | --- |
| Idle | `103196844993487` |
| Walk | `116693022967094` |
| Attack | `110803763765590` |
| Death | `98586621133332` |
| Особлива | — |

**Як рухається:** гвинтівка напоготові, хода-«марш» з кульганням, удар прикладом з-за плеча, смерть — відкидає на спину.

## Стати (`MobConfig.ZombieSoldier`)
| Стат | Значення |
| --- | --- |
| HP | 2,000 |
| Урон за удар | 3 |
| Гроші за вбивство | 3.6K (6 монет розлітається) |
| Швидкість | ×0.6875 від базової (16) |
| Шанс сундука | 6.0% → [[Places/Merge Your Weapon/3D Models/Crates/MilitaryCrate/MilitaryCrate\|Military Crate]] |
| Шанс гема | 2.5% |
| Особлива атака | — |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
