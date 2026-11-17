---
tags: [3d, mobs]
updated: 2026-11-15
---

# Zone 4 Mobs — Polar Explorer / Radio Operator / Ice Brute

← [[Mobs]] · `GDD - Mobs and Drops`

Зроблено в хмарному Blender (bpy, `lib.py`), блоковий стиль. Матеріали — звичайні (без стадсів, як усі зомбі). Прев'ю — `Animations Z4/zone4_mobs_preview.png`.

| | Polar Explorer | Radio Operator | Ice Brute |
| --- | --- | --- | --- |
| Вигляд | помаранчева парка з хутром, капюшон, гоглі, рюкзак, льодоруб | синя куртка, червоний шарф, шапка з навушниками й мікрофоном, рація на спині з антеною, брила льоду в руці | величезний, сіра безрукавка з мотузкою, крижані наростання на плечах і руках, світні очі |
| Розмір | +10% | 1.0 | +50% |
| Model asset | 99004286534747 | 93064257070775 | 103977268459552 |
| Idle | 123794527721207 | 73116862822380 | 76900137478670 |
| Walk | 72989881794101 | 102496067898754 | 93007525638406 |
| Attack | 117568211583417 | 132544549477560 | 86115859026493 |
| Death | 91413160949835 | 82814377341346 | 127692669108621 |
| Особлива | — | Throw 98030665470766 | Slam 119382697663990 |

- У грі: `ReplicatedStorage/MobModels/…` (R6, `AnimSet` = Explorer / Operator / Brute), анімації — `MobAnimations/<AnimSet>`.
- Брила льоду радиста має атрибут `HandAxe` — вона летить при кидку (`MobClient.throwDynamite`, kind "ice"). Удар громили — `MobClient.slamAttack`.
- Файли: `ZombiePolarExplorer/explorer.py`, `ZombieRadioOperator/radioop.py`, `ZombieIceBrute/brute.py`, анімації — `Animations Z4/anims_z4.py`. Сундук — `Crates/FrostCrate`.
