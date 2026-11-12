---
tags: [ui, shop, monetization]
status: in-game
version: 1
updated: 2026-11-10
---

# Starter Pack (SHOP)

← [[My Mining Golems - 2D]]

Пропозиція новачкам за 19 R$: +$50K Money, 3 Luck Potions і Diamond Stone Golem, один раз на гравця.

## Де в магазині
- Окремий розділ **~ STARTER PACK ~** одразу під MONEY MULTIPLIER, над GAMEPASSES. Справа від заголовка — жовтий таймер «Ends in 59:27».
- З BUNDLES картку прибрано, там лишились Potion Pack і Extra Storage.
- **Після Starter Pack — Mega Pack (10.11.2026):** коли Starter куплено або його час вийшов, на тому ж місці з’являється «~ MEGA PACK ~» (399 R$).
  - У Mega Pack немає таймера, він один раз на гравця. Куплено (`Pass_MegaPack`) — розділ зникає.
  - З BUNDLES Mega Pack прибрано.
  - Обидві картки побудовані в одному місці, `spSet` перемикає їх Visible і текст заголовка.
  - Перевірено в Play: час вийшов → «~ MEGA PACK ~» і картка Mega Pack; `Pass_MegaPack` → розділ зник, GAMEPASSES на y 274.

## Таймер — 1 година гри
- Рахується **лише онлайн**. Поки гравця немає в грі, час стоїть.
- Сервер (`MonetizationService.Start`, `startStarter`) після завантаження даних ставить атрибут `StarterEndsAt` = час сервера + залишок. Залишок береться із секції даних `StarterOffer { left }`, новачок отримує 3600 с.
- Під час збереження (`DataService.RegisterSection("StarterOffer")`) залишок рахується як `StarterEndsAt − зараз`.
- Куплено (`Pass_StarterPack`) або час вийшов → `StarterEndsAt = 0`.
- Клієнт (`ShopWindow`) раз на 0,5 с оновлює таймер. Коли пак куплено або час вийшов, розділ зникає, а все нижче підтягується вгору: позиції, `SECTION_Y` закладок, `CanvasSize`.
- Сервер не продає пак за тікети після кінця часу (`BuyProduct` → `expired`). Пак і так лише за Robux.
- Гравці, які грали до цієї зміни, теж отримують годину від першого входу після оновлення, бо секції `StarterOffer` у них ще немає.

## Перевірка в Play (10.11.2026)
- Розділ стоїть між MONEY MULTIPLIER і GAMEPASSES, таймер «Ends in 59:27».
- `StarterEndsAt` = зараз + 3 с → через 4,5 с розділ зник. GAMEPASSES піднявся з y 510 на 274, BUNDLES — з 2754 на 2518.

## Звук покупки за Robux (10.11.2026)
- Раніше звук "purchase" грав лише на геймпасах і на x2 Money з кнопки HUD. На паках, x2 Money з магазину та інших продуктах звуку не було.
- Тепер `MonetizationService.ProcessReceipt` після видачі нового чека шле клієнту `Remotes/PurchaseDone`, а `ShopActions` грає "purchase". Так звук є на **всіх** Developer Products: паки, x2 Money, тікети, діаманти, скіпи, кейси, стенд Robux.
- Геймпаси — як і раніше (`PromptGamePassPurchaseFinished`). Старий тригер за `DonateTier` прибрано, щоб звук не грав двічі.
- Бекап — `NicheBackup/ShopActions_pre_buysound`.

Бекапи — `NicheBackup/ShopWindow_pre_starter`, `MonetizationService_pre_starter`.
