---
tags: [model, weapon, block-style]
status: in-game
tier: 33
updated: 2026-11-15
---

# Triple Minigun

← [[Weapons]]

*Потрійний мінігун: три блоки по 6 стволів трикутником, фіолетова рамка на дулах, бірюзові смуги, великий барабан збоку.* Зброя **тіру 33**. Три мінігуни одночасно.

![[myw_tripleminigun_preview.png]]

| Параметр | Значення |
| --- | --- |
| Тір | **33** |
| Отримати | мердж двох тіру 32 · BUY WEAPON з апгрейдом Buy Tier 33 — 926.51Qa |
| Ціна BUY WEAPON | 46.33Qa (25 × 3^(тір−1)) |
| Asset ID | `101256493930845` (v2; старий `84197011621173` не використовується) |
| Анімовані деталі | `BarrelsA`, `BarrelsB`, `BarrelsC` — кожен блок стволів крутиться окремо; фіолетова рамка `Frame` стоїть |

## У Roblox
| Що | Де |
| --- | --- |
| Шаблон | `ReplicatedStorage/Weapons/MYW_TripleMinigun` |
| Атрибути шаблону | `Tier = 33`, `Kind = Long`, `MuzzleDir = 1`, `DisplayScale` |
| Показ на плоті / в руках | `ReplicatedStorage/WeaponDisplay` |
| Вітрина | `Workspace/PrefabWorkshop` — клітинка 33 |
| Матеріал | `Plastic` + `MaterialVariant = Studs`, матова, Anchored |

## Файли
- `myw_tripleminigun.blend` — модель (Blender 5.3, генератор зі скрипта)
- `myw_tripleminigun_preview.png` — прев'ю
- `Upload/myw_tripleminigun.glb` — для Roblox; `.obj` + `.mtl` (матові, `Ks 0`)

## Історія
- 2026-11-14: перша версія.
- 2026-11-14: v2 — стволи розділено на три окремі об'єкти для окремого обертання.
- 2026-11-15: у шаблоні `ReplicatedStorage/Weapons/MYW_TripleMinigun` зникли стволи (`Barrels_Node`: `Barrels`, `Barrels2`) — в Index силует розпадався. Відновлено з вітрини `PrefabWorkshop/T33_TripleMinigun` у масштабі шаблону (12 частин).
