---
tags: [interactive, monetization]
status: in-game
updated: 2026-11-15
---

# Slot Stand

← [[Places/Merge Your Weapon/Interactive Objects/Interactive Objects|Interactive Objects]]

Стенд геймпаса **+1 WEAPON SLOT** (4-й слот зброї в бою) перед кожним плотом: `Plot<N>/SlotStand`, атрибут `Pass = WeaponSlot`. Продається тут, а не в SHOP.

## Вигляд
- **Низька платформа** (не п'єдестал): `Base` 10 × 0.6 × 10, золотий `Top` 8 × 0.4 × 8, `Glow`, висунута на 4.5 стада ближче до дороги.
- Над нею крутиться золотий `AssaultRifle` (`Weapon`).
- Табличка (`SignAnchor`): «+1 WEAPON SLOT», нижче іконка Robux і «99» рівно по центру (`UIListLayout`), без підкладки. Куплено → «OWNED».

## Як працює
- Ступив на `Pad` → вікно покупки геймпаса `2088315580` (купити можна на будь-якому стенді, пас на акаунт). Вже є → «You already have it!».
- Після покупки — атрибут `PassWeaponSlot = true` (зберігається), слот з'являється одразу.
- Подарувати — Gift +1 Weapon Slot у [Gift Window](obsidian://open?vault=Roblox%20Dev&file=Places%2FMerge%20Your%20Weapon%2F2D%2FGift%20Window%2FGift%20Window).

## Скрипти
`PassService` (сервер: перевірка паса при вході, покупка), `PassStandController` (клієнт: обертання зброї, табличка), конфіг `PassConfig`.
