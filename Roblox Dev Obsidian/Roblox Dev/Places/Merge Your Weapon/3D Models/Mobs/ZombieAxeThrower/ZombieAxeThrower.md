---
tags: [model, mob, zombie]
status: in-game
zone: 2
updated: 2026-11-15
---

# Zombie Axe Thrower (unique)

← [[Mobs]]

*Унікальний зомбі Zone 2: широкий, сірий светр + відкритий шкіряний жилет, патронташ, 3 сокири в кріпленні за спиною, червона бандана з вузлом, шрам зі швами, оранжеві очі світяться (Neon), важка щелепа, бинт на правому передпліччі, шкіряні наручі, наколінники. У правій руці — сокира для кидка (частини з атрибутом `HandAxe`: ховаються на кидку і повертаються).* Без крові — одяг пошарпаний. Де: 1 з 8 мобів Zone 2 (точка 8, позаду).

![[myw_zombieaxethrower_preview.png]]

| Параметр | Значення |
| --- | --- |
| Asset ID | `113015023440698` |
| Шаблон | `ReplicatedStorage/MobModels/ZombieAxeThrower` |
| Риг | R6: `Torso`, `Head`, `Left/Right Arm`, `Left/Right Leg` + `HumanoidRootPart`; суглоби на справжніх плечах / стегнах / шиї; решта частин приварені `WeldConstraint`; в руці: HandAxe |
| Масштаб | 1.3× (зріст ≈ 7.5) |
| Матеріали | одяг — `Fabric`, шкіра й решта — `SmoothPlastic`, метал — `Metal`, очі — `Neon` |
| Атрибути | `Mob = ZombieAxeThrower`, `Zone = 2`, `AnimSet = AxeThrower` |
| Стати | `MobConfig.ZombieAxeThrower` (див. GDD - Mobs and Drops) |

## Файли
- `myw_zombieaxethrower.blend`, `myw_zombieaxethrower_preview.png`, `Upload/myw_zombieaxethrower.glb`; скрипт збірки — `../Zone2_build_src/`

## Історія
- 2026-11-15: перша версія.
