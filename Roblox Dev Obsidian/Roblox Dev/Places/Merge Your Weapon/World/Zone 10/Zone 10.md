---
tags: [world, zone]
status: in-game
zone: 10
theme: Zombie Secret Lab
updated: 2026-11-16
---

# Zone 10 — Zombie Secret Lab

← [[Places/Merge Your Weapon/World/World|World]] · [[Places/Merge Your Weapon/World/Zone 9/Zone 9|Zone 9]] ← → [[Portal Island]]

*Біла секретна лабораторія: реактор, капсули, сервери, кабелі, бірюзове світло; за нею портал у World 2.*

![[myw_zone10_overview.jpg]]

| Параметр | Значення |
| --- | --- |
| У грі | `Workspace/Zones/Zone10` (атрибути `Zone = 10`, `Theme = Zombie Secret Lab`) |
| Розмір | 170 × 170 стадів (центр ≈ z 1920) |
| Склад | `Ground`, `Walls`, `Barriers`, `Markers` (точки спавну мобів), `Gates`, `Decor` |
| Вхід | ворота **FIGHT · CLEAR THE ZONE 0/N** — відкриваються, коли зачищено попередню зону ([[Zone Gates]]) |
| Сундук | [[Places/Merge Your Weapon/3D Models/Crates/LabCrate/LabCrate\|Lab Crate]] |
| Стан | свій у кожного гравця (`ZoneService`), зачищена → швидкість 24 і відродження через 20 с |

## Моби
| Моб | Роль | HP | Особлива атака |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieLabAssistant/ZombieLabAssistant\|Zombie Lab Assistant]] | звичайний | 120 000 HP | удар шприцом з отрутою |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieCyborg/ZombieCyborg\|Zombie Cyborg]] | звичайний | 150 000 HP | лазерна черга |
| [[Places/Merge Your Weapon/3D Models/Mobs/ZombieExperiment/ZombieExperiment\|Experiment X]] | унікальний (рідший, сильніший) | 370 000 HP | промінь, що водить по колу |

## Декор (`Zones/Zone10/Decor`)
| Модель | Що це |
| --- | --- |
| `Reactor` | реактор у центрі |
| `ContainmentTubes` | капсули утримання зі світлом |
| `ServerRacks` | серверні стійки |
| `LabTables` | лабораторні столи |
| `SecurityDoors` | броньовані двері |
| `Cables` | кабелі по підлозі |
| `HazardStrips` | чорно-жовті смуги |
| `Sirens` | сирени |
| `Lamps` | бірюзові ліхтарі |
| `Barriers` | бар'єри |
| `LabSign` | табличка лабораторії |
| `WallTopDecor` | антени, сонячні панелі, тарілки на дахах |

Усі пропси зон — Plastic + текстура стадів (світне — Neon), без граней «0 в 0». Дрібна «жива» анімація декору — `ZoneAmbientClient`.
