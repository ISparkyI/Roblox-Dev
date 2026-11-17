---
tags: [world, zone]
status: in-game
zone: 8
theme: Zombie Haunted Graveyard
updated: 2026-11-16
---

# Zone 8 — Zombie Haunted Graveyard

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 7/Zone 7|Zone 7]] ← → [[Places/Merge Your Weapon/World/Zone 9/Zone 9|Zone 9]]

*Нічний цвинтар: склеп, надгробки, розриті могили, мертві дерева, ліхтарі.*

![[myw_zone8_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone8` (атрибути `Zone = 8`, `Theme = Zombie Haunted Graveyard`) |
| Розмір | 170 × 170 стадів (центр ≈ z 1580) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/GraveCrate/GraveCrate\|Grave Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieSkeleton/ZombieSkeleton\|Zombie Skeleton]] | звичайний | 22 000 HP | — |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieGravedigger/ZombieGravedigger\|Zombie Gravedigger]] | звичайний | 30 000 HP | кидок багнюки |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieNecromancer/ZombieNecromancer\|Zombie Necromancer]] | унікальний (рідший, сильніший) | 147 000 HP | прокляття (виверження з землі) |

## Декор (`Zones/Zone8/Decor`)
| Модель | Що це |
| --- | --- |
| `Mausoleum` | склеп |
| `Tombstones` | надгробки |
| `OpenGraves` | розриті могили |
| `IronFences` | кований паркан |
| `DeadTrees` | мертві дерева |
| `Lanterns` | ліхтарі зі світлом |
| `Statue` | кам'яна статуя |
| `Bones` | кістки |
| `Pumpkins` | гарбузи зі свічками |
| `GraveyardSign` | табличка цвинтаря |
| `WallTopDecor` | ліхтарі й ворони на стінах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
