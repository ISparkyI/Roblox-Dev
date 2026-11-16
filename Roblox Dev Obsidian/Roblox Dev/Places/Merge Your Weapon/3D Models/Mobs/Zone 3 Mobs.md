---
tags: [3d, mobs]
updated: 2026-11-15
---

# Zone 3 Mobs — Zombie Miner / Zombie Dynamiter

← [[Mobs]] · `GDD - Mobs and Drops`

Зроблено в хмарному Blender (bpy, `lib.py` з Zone 2), блоковий стиль як у Zone 2. Прев'ю — `ZombieMiner/preview.png`, `ZombieDynamiter/preview.png`.

| | Zombie Miner | Zombie Dynamiter |
| --- | --- | --- |
| Вигляд | жовта каска зі світним ліхтариком, сорочка, джинсовий комбінезон з латкою, рукавиці, кайло | шолом з помаранчевим ліхтарем, гоглі на лобі, смугаста сорочка, шкіряний фартух, патронташ з динамітом, сумка з шашками, запалена шашка в руці |
| Розмір | +15% від звичайного зомбі | +50% |
| Model asset | 91928451022538 | 122111223530028 |
| Idle | 94249964678744 | 109619118005160 |
| Walk | 116467720800288 | 133698266592038 |
| Attack | 98307405797876 | 106904691239534 |
| Death | 75939675586989 | 79229368251411 |
| Throw | — | 136869812113679 |

- У грі: `ReplicatedStorage/MobModels/ZombieMiner`, `ZombieDynamiter` (R6, `AnimSet` = Miner / Dynamiter), анімації — `MobAnimations/Miner`, `MobAnimations/Dynamiter`.
- Шашка в руці підривника має атрибут `HandAxe` — вона й летить при кидку (`MobClient.throwDynamite`).
- Звуки (з гри): `MobSounds/Explosion` (вибух міни), `MobSounds/Fuse` (тріск вогню — гніт), «дзеньк» кайла — `AxeHit` вище.
- Файли: `ZombieMiner/miner.py`, `ZombieDynamiter/dynamiter.py`, анімації — `Animations Z3/anims_z3.py` + `.rbxmx`.
