---
tags: [ui]
status: in-game
updated: 2026-11-15
---

# Shop Window

← [[Merge Your Weapon - 2D|2D]]

Вікно магазину (`ShopController`, дані `ShopConfig`, сервер `ShopService`). Вікно ×0.85, напівпрозоре тіло з розмиттям.

## Розділи (вкладки зліва)
| Розділ | Що там |
| --- | --- |
| **PACKS** | один пак за прогресом: STARTER (49 R$) → EPIC (149) → SUPER (275); зброя + кеш + геми |
| **PASSES** | AUTO MERGE (299), AUTO FIGHT (199), INFINITE STAMINA (149) |
| **WEAPONS** | набори 10 / 25 / 50 / 100 / 250 / 500 зброї поточного Buy Tier: 29 / 65 / 119 / 199 / 449 / 699 R$ |

- На картках наборів — червона плашка «-N%» (градієнт, нахил 10°, всередині картки): -10 / -18 / -31 / -38 / -52%.
- Кнопка **GIFT!** у шапці відкриває [Gift Window](obsidian://open?vault=Roblox%20Dev&file=Places%2FMerge%20Your%20Weapon%2F2D%2FGift%20Window%2FGift%20Window).
- Усі товари — справжні Developer Products / Game Passes (ID — `GDD - Shop and Passes`).
- «Життя» UI: блиски, пульсація (поворот + колір, не масштаб тексту), погойдування; ефект і звук покупки.
