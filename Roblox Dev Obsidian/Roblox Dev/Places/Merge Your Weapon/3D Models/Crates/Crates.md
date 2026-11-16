---
tags: [model-class, crate]
status: in-game
updated: 2026-11-16
---

# Crates

← [[Merge Your Weapon - 3D Models|3D Models]] · `GDD - Crates`

10 сундуків — по одному на зону. Падають з мобів, лежать у рюкзаку, відкриваються кліком (анімація `CratePopController`). Логіка — `CrateService`, таблиці — `ReplicatedStorage/CrateConfig`.

| Зона | Сундук | Зброя (35 / 20 / 7%) | Вигляд |
| --- | --- | --- | --- |
| 1 | [[Places/Merge Your Weapon/3D Models/Crates/FarmCrate/FarmCrate\|Farm Crate]] | Slingshot T2 · Blowpipe T3 · Bow T4 | ![[myw_crate1_ingame.jpg\|120]] |
| 2 | [[Places/Merge Your Weapon/3D Models/Crates/LumberCrate/LumberCrate\|Lumber Crate]] | Crossbow T5 · Flintlock T6 · Musket T7 | ![[myw_crate2_ingame.jpg\|120]] |
| 3 | [[Places/Merge Your Weapon/3D Models/Crates/MiningCrate/MiningCrate\|Mining Crate]] | Blunderbuss T8 · Revolver T9 · Lever Rifle T10 | ![[myw_crate3_ingame.jpg\|120]] |
| 4 | [[Places/Merge Your Weapon/3D Models/Crates/FrostCrate/FrostCrate\|Frost Crate]] | Double Barrel T11 · Pump Shotgun T12 · SMG T13 | ![[myw_crate4_ingame.jpg\|120]] |
| 5 | [[Places/Merge Your Weapon/3D Models/Crates/MilitaryCrate/MilitaryCrate\|Military Crate]] | Hunting Rifle T14 · Assault Rifle T15 · Auto Shotgun T16 | ![[myw_crate5_ingame.jpg\|120]] |
| 6 | [[Places/Merge Your Weapon/3D Models/Crates/ToxicCrate/ToxicCrate\|Toxic Crate]] | Battle Rifle T17 · LMG T18 · Sniper Rifle T19 | ![[myw_crate6_ingame.jpg\|120]] |
| 7 | [[Places/Merge Your Weapon/3D Models/Crates/CityCrate/CityCrate\|City Crate]] | Grenade Launcher T20 · Minigun T21 · Anti-Materiel Rifle T22 | ![[myw_crate7_ingame.jpg\|120]] |
| 8 | [[Places/Merge Your Weapon/3D Models/Crates/GraveCrate/GraveCrate\|Grave Crate]] | Heavy Machine Gun T23 · Rocket Launcher T24 · Recoilless Rifle T25 | ![[myw_crate8_ingame.jpg\|120]] |
| 9 | [[Places/Merge Your Weapon/3D Models/Crates/LavaCrate/LavaCrate\|Lava Crate]] | Twin MG T26 · Quad Rocket T27 · Gatling Shotgun T28 | ![[myw_crate9_ingame.jpg\|120]] |
| 10 | [[Places/Merge Your Weapon/3D Models/Crates/LabCrate/LabCrate\|Lab Crate]] | Missile Launcher T29 · Heavy Minigun T30 · Grenade Gatling T31 | ![[myw_crate10_ingame.jpg\|120]] |

Решта шансу — гроші (30%) і геми (8%), суми ростуть із зоною. Моделі — `ReplicatedStorage/DropModels/Crate1…10`, 2D-іконки — `2D/Crate Icons`.
