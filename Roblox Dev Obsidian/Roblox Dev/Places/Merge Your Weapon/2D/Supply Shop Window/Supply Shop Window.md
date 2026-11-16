---
tags: [ui]
status: in-game
updated: 2026-11-15
---

# Supply Shop Window

← [[Merge Your Weapon - 2D|2D]]

Вікно **SUPPLY SHOP** (`SupplyShopController`, `UIKit.makeWindow`, шапка жовто-помаранчева, іконка Shop). Відкривається в червоній зоні перед бункером SHOP, закривається, коли вийшов.

![[myw_supply_shop_window.jpg]]

- **Шапка вікна:** лічильник гемів зліва, «RESTOCK IN mm:ss» справа.
- **Список** — рядок на кожен розхідник, один під одним, скрол справа (за ескізом):
  - смужка кольору рідкості зліва; плитка з 3D-моделлю, що крутиться (`ReplicatedStorage/SupplyModels`);
  - назва, рідкість кольором, що робить;
  - «IN STOCK: 9/10», «OWNED: N»;
  - кнопка з гемом і ціною: зелена — можна купити, помаранчева — не вистачає гемів, сіра «SOLD OUT».
- Покупка: звук, рядок підстрибує.
- Кольори рідкостей: Common `B9C2CF`, Uncommon `6BE040`, Rare `4FA8FF`, Epic `C066FF`, Legendary `FFC93C`.
