---
tags: [world, zone]
status: in-game
zone: 9
theme: Zombie Volcano
updated: 2026-11-16
---

# Zone 9 — Zombie Volcano

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 8/Zone 8|Zone 8]] ← → [[Places/Merge Your Weapon/World/Zone 10/Zone 10|Zone 10]]

*Вулканічне плато з базальту: лавопад, лавові озера й тріщини, пара, табір вулканологів.*

![[myw_zone9_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone9` (атрибути `Zone = 9`, `Theme = Zombie Volcano`) |
| Розмір | 170 × 170 стадів (центр ≈ z 1750) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/LavaCrate/LavaCrate\|Lava Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieCharred/ZombieCharred\|Zombie Charred]] | звичайний | 45 000 HP | удар з отрутою + горіння |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieVolcanologist/ZombieVolcanologist\|Zombie Volcanologist]] | звичайний | 60 000 HP | кидок магми |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieLavaGolem/ZombieLavaGolem\|Zombie Lava Golem]] | унікальний (рідший, сильніший) | 205 000 HP | виверження — лавові бомби |

## Декор (`Zones/Zone9/Decor`)
| Модель | Що це |
| --- | --- |
| `Volcano` | вулкан на фоні зі світною лавою |
| `LavaFall` | лавопад на стіні |
| `LavaPools` | лавові озера |
| `LavaCracks` | лавові тріщини в землі |
| `SteamVents` | парові гейзери |
| `BasaltSpires` | базальтові шпилі |
| `Obsidian` | обсидіанові брили |
| `Boulders` | валуни |
| `CharredTrees` | обвуглені дерева |
| `ResearchCamp` | табір вулканологів |
| `VolcanoSign` | табличка вулкана |
| `WallTopDecor` | шпилі й жарини на стінах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
