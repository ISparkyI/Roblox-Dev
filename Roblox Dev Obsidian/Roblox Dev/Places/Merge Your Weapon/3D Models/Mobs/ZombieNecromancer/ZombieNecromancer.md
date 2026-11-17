---
tags: [model, mob, zombie]
status: in-game
zone: 8
updated: 2026-11-16
---

# Zombie Necromancer

← [[Mobs]] · [[Places/Merge Your Weapon/World/Zone 8/Zone 8|Zone 8]] · [[Zone 8 Mobs]]

*Фіолетова мантія з каптуром і плащем, обличчя-маска з фіолетовими очима і руною на лобі, кістяні наплічники, намисто з кісток і черепом, книга заклинань на поясі, посох з черепом і фіолетовим кристалом.* Роль у зоні: **унікальний (рідший, сильніший)**.

![[myw_zombienecromancer_ingame.jpg]]

## Модель
| Параметр | Значення |
| --- | --- |
| Asset ID | `92286766880112` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieNecromancer` |
| Риг | R6 + `HumanoidRootPart`, решта частин на `WeldConstraint` |
| Розмір | +50% · зріст ≈ 9.8 стадів |
| Матеріали | звичайні (SmoothPlastic / Fabric / Metal / Neon), без стадсів |
| Атрибути | `Mob = ZombieNecromancer`, `Zone = 8`, `AnimSet = Necromancer` |
| Файли | `ZombieNecromancer/*.py` (скрипт збірки bpy), `myw_zombienecromancer.glb` |

## Анімації (`MobAnimations/Necromancer`)
| Що | Asset ID |
| --- | --- |
| Idle | `108629344014203` |
| Walk | `137997567931360` |
| Attack | `92769339991133` |
| Death | `113105026177599` |
| Особлива | Curse (Throw) 115214807810265 |

**Як рухається:** посох рівно, вільна рука плете закляття, легко «пливе»; ковзна хода; прокляття — посох угору, рука до неба, потім посох у землю; удар посохом збоку; смерть — хапається за голову, на коліна, падає набік.

## Стати (`MobConfig.ZombieNecromancer`)
| Стат | Значення |
| --- | --- |
| HP | 147,000 |
| Урон за удар | 5 |
| Гроші за вбивство | 30M (9 монет розлітається) |
| Швидкість | ×0.53125 від базової (16) |
| Шанс сундука | 35.0% → [[Places/Merge Your Weapon/3D Models/Crates/GraveCrate/GraveCrate\|Grave Crate]] |
| Шанс гема | 12.0% |
| Особлива атака | прокляття (виверження з землі) |

Баланс і логіка дропу — `GDD - Mobs and Drops`, сундук — `GDD - Crates`.

## Історія
- 2026-11-16: окрема нотатка + скрін з гри.
