---
tags: [model, mob, zombie]
status: in-game
zone: 2
updated: 2026-11-15
---

# Zombie Lumberjack

← [[Mobs]]

*Звичайний зомбі-лісоруб: червоно-чорна картата фланель, підтяжки, руда борода, в'язана шапка з помпоном, джинси з латкою на коліні, робочі черевики, сокира з червоним лезом у правій руці. Ліве плече — рваний рукав.* Без крові — одяг пошарпаний. Де: 3 з 8 мобів Zone 2 (точки 3, 4, 7).

![[myw_zombielumberjack_preview.png]]

| Параметр | Значення |
| --- | --- |
| Asset ID | `93205046752998` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieLumberjack` |
| Риг | R6: `Torso`, `Head`, `Left/Right Arm`, `Left/Right Leg` + `HumanoidRootPart`; суглоби на справжніх плечах / стегнах / шиї; решта частин приварені `WeldConstraint`; в руці: Axe |
| Масштаб | 1× (зріст ≈ 6.2) |
| Матеріали | одяг — `Fabric`, шкіра й решта — `SmoothPlastic`, метал — `Metal`, очі — `Neon` |
| Атрибути | `Mob = ZombieLumberjack`, `Zone = 2`, `AnimSet = Lumberjack` |
| Стати | `MobConfig.ZombieLumberjack` (див. GDD - Mobs and Drops) |

## Файли
- `myw_zombielumberjack.blend`, `myw_zombielumberjack_preview.png`, `Upload/myw_zombielumberjack.glb`; скрипт збірки — `../Zone2_build_src/`

## Історія
- 2026-11-15: перша версія.
