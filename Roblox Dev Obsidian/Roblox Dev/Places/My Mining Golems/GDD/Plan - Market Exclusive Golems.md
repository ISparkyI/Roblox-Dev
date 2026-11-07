---
tags: [gdd, plan, exclusive, marketplace]
status: in-progress
updated: 2026-11-05
---

# Plan - Market Exclusive Golems

← [[Plans]]

Три ексклюзивні големи, які продаються **лише на Marketplace** (стенди `Workspace/Marketplace/Floor/Exclusive Golem Stand 2 / 3 / 4`).

## Големи

| Голем | Клас | Сила | Ціна | Ліміт | Стиль | Ексклюзивна анімація |
| --- | --- | --- | --- | --- | --- | --- |
| Cyborg Golem | Miner | **300 %** best | **1999 R$** (Developer Product) | 1 на гравця | кіборг: метал, неонові вставки, око | переливання неону |
| Lamp Miner Golem | Carrier | **250 %** best | **999 🎟**, кожна покупка +500 для наступного (глобально) | 1 на гравця | шахтар у касці з ліхтарем | блимання ліхтаря на касці |
| Spartan Golem | Warrior | **200 %** best | **250 000 💎** | 1 на гравця | спартанець: шолом з гребенем, щит | **спис** + удар уколом |

Сила — частка найкращого звичайного голема гравця свого класу (як [[Plan - Exclusive Case Golems|Exclusive Case]]: `share` / `carrierShare` / `warriorShare`). Кожен — лише один клас.

## Рішення користувача (05.11.2026)
- Lamp Miner: стартова ціна 999 🎟, +500 за кожну покупку.
- Cyborg — **Developer Product**, не геймпас; купити в магазині можна 1 раз на гравця.
- Lamp Miner і Spartan — теж 1 раз на гравця.
- **Мутувати не можна жодних ексклюзивів.**
- Продавати / купувати ці големи на ринку гравців (лоти Marketplace) — **можна**; ліміт «1 на гравця» стосується лише покупки на стенді.

## Що робимо
1. **GolemCatalog** — 3 записи (`rarity = "Exclusive"`, `exclusive = "market"`, `how` = «Marketplace»), у `EXCLUSIVES` → Index: група Exclusive, «300% BEST».
2. **Моделі** (PlotPrefabs, той самий скелет — аніматор працює): CyborgGolem, LampMinerGolem + CarryBox, SpartanGolem + SpartanSpear (замість меча).
3. **Анімації**: неон Cyborg переливається; ліхтар Lamp Miner блимає (неон + PointLight); Spartan б'є уколом списа (плот, арена боса).
4. **Стенди** на маркеті: обертова модель, табличка (назва, «300% BEST MINER», ціна), кнопка BUY → OWNED.
5. **Сервер покупок** (MarketExclusiveService): Developer Product (ProcessReceipt) / Tickets / Diamonds, перевірка ліміту (атрибут `MktExclBought`), видача через GolemRegistry, SaveNow.
6. **Ціна Lamp Miner** — DataStore (UpdateAsync, атомарно): `{ n, list }`; ціна = 999 + 500 × n. **Дошка покупців** біля стенда: поточна ціна + останні покупці «#N Нік — ціна 🎟», оновлення на всіх серверах (MessagingService + опитування).
7. Тест у режимі маркету (Workspace.MarketTest), Index, плот, бій з босом.

## Стан
- [x] каталог / Index
- [x] моделі
- [x] анімації (Spartan: ривок списом уперед, Grip у GolemAnimatorV4 v4.1)
- [x] стенди (кастомні п’єдестали), покупки, дошка покупців у стилі лідерборду
- [x] іконки 256 × 256 + бос для телефонів → atlas_11 (`rbxassetid://114480732424976`)
- [x] тест у режимі маркету
- [x] Developer Product «Cyborg Golem» у Creator Hub: id **3728400769**, 1999 R$, Managed pricing вимкнено, іконка — рендер голема → `MarketExclusiveConfig` productId; тестова покупка в Studio видала 1 голема
