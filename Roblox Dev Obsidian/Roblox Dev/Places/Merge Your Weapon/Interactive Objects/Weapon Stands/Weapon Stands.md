---
tags: [interactive, monetization]
status: in-game
updated: 2026-11-16
---

# Weapon Stands

← [[Places/Merge Your Weapon/Interactive Objects/Interactive Objects|Interactive Objects]]

![[myw_weapon_stands.jpg]]
*+10 / +100 / +500 WEAPONS — 29 / 199 / 699 R$.*

Три стенди на кожному плоті (`Plot<N>/Stands/Stand1..3`), зліва направо:

| Стенд | Зброя на ньому | Атрибут `Count` | Ціна |
| --- | --- | --- | --- |
| +10 WEAPONS | Slingshot (тір 2) | 10 | 29 R$ |
| +100 WEAPONS · MOST POPULAR | Musket (тір 7) | 100 | 199 R$ |
| +500 WEAPONS · BEST VALUE! | Pump Shotgun (тір 12) | 500 | 699 R$ |

Будова: `Pad`, `Glow` (4 стінки без верху, опущені на 0.35), `Show` (зброя), `SignAnchor` (табличка), `Touch`.

Ступив на свій стенд → вікно покупки Developer Product (ті самі продукти, що +10 / +100 / +500 у SHOP), набір зброї поточного Buy Tier (`ShopService`). Ціна в атрибуті стенда `Price`.
