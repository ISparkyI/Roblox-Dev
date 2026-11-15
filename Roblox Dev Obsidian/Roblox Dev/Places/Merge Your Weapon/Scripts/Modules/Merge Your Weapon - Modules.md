# Modules

← [[Merge Your Weapon - Scripts|Scripts]]

ModuleScript у `ReplicatedStorage`. Оновлено 2026-11-15.

| Модуль | Що там |
| --- | --- |
| `WeaponConfig` | 35 тірів (`MYW_<Name>`): назва, модель, тип стрільби; `price(tier)` — премія за тір + округлення до красивих чисел (палка 10); `START_CASH = 0`, `START_PLOT_SLOTS = 20` |
| `WeaponAttacks` | атаки зброї, таблиця урону `Damage[tier]` — GDD - Balance |
| `WeaponDisplay` | поза й масштаб зброї: `pose`, `applyScale`, `place`, `spawn` |
| `WeaponHold` | хват руками (IK), орбіта зброї в бою |
| `WeaponAnim` | анімації рухомих частин зброї |
| `MobConfig` | зомбі: HP, гроші, шанси сундука й гему, атака, швидкість |
| `CrateConfig` | лут сундуків по зонах; `loot` / `roll` з фільтром Buy Tier і межі ребьорту |
| `UpgradeConfig` | дерево апгрейдів (Buy Tier = 5× ціни, Weapon Slot 2.5K / 2M) — GDD - Upgrades |
| `RebirthConfig` | кроки ребьорту (тір, +100%), `maxTier(rebirths)` |
| `ShopConfig` | паки, геймпаси, набори зброї: ціни, `productId`, `passId`, `giftProductId` |
| `PassConfig` | геймпас +1 Weapon Slot (ID, ціна, атрибут, gift-продукт) |
| `CashBoostConfig` | драбина x2 CASH: множник, ціна, `productId`; `next(current)`, `byProduct(id)` |
| `UIKit` | спільний стиль вікон: `label`, `icon`, `face`, `button`, `bounce`, `makeWindow` |
| `HUDIcons` | ID усіх іконок (+ Cursor) — Icons |
| `SoundConfig` | налаштування звуків зброї |
| `UIOpen` (BindableEvent) | відкрити вікно за назвою |
