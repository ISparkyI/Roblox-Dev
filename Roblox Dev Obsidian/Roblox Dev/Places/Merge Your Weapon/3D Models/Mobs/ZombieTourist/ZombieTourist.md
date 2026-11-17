---
tags: [model, mob, zombie]
status: in-game
zone: 2
updated: 2026-11-15
---

# Zombie Tourist

← [[Mobs]]

*Зомбі-турист: бірюзова гавайська сорочка з квітами поверх футболки, панама з квіткою, червоні окуляри на лобі (одна лінза випала), біла смуга крему на носі, фіолетова бананка, оранжевий рюкзак зі спальником, шорти, на одній нозі сповзла шкарпетка, сандалі, годинник, фотоапарат у правій руці (лінза — `CameraLens`, звідти спалах).* Без крові — одяг пошарпаний. Де: 4 з 8 мобів Zone 2 (точки 1, 2, 5, 6).

![[myw_zombietourist_preview.png]]

| Параметр | Значення |
| --- | --- |
| Asset ID | `130268794092881` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieTourist` |
| Риг | R6: `Torso`, `Head`, `Left/Right Arm`, `Left/Right Leg` + `HumanoidRootPart`; суглоби на справжніх плечах / стегнах / шиї; решта частин приварені `WeldConstraint`; в руці: Camera, CameraLens |
| Масштаб | 1× (зріст ≈ 6.1) |
| Матеріали | одяг — `Fabric`, шкіра й решта — `SmoothPlastic`, метал — `Metal`, очі — `Neon` |
| Атрибути | `Mob = ZombieTourist`, `Zone = 2`, `AnimSet = Tourist` |
| Стати | `MobConfig.ZombieTourist` (див. GDD - Mobs and Drops) |

## Файли
- `myw_zombietourist.blend`, `myw_zombietourist_preview.png`, `Upload/myw_zombietourist.glb`; скрипт збірки — `../Zone2_build_src/`

## Історія
- 2026-11-15: перша версія.
