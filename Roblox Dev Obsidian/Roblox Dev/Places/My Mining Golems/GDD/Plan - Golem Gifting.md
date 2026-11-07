---
tags: [gdd, plan, gifting, index]
status: done
updated: 2026-11-05
---

# Plan - Golem Gifting

← [[Plans]]

Подарунок голема іншому гравцю в лобі + плашки **MAP N** в Index.

## Як дарувати
1. Береш голема в руку (хотбар).
2. Підходиш до гравця (до 10 стад) — над ним фіолетова кнопка **GIFT**.
3. Натискаєш — вікно **GIFT GOLEM?**: 3D-іконка, назва (колір рідкості), мутація, клас, «to Нік»; **GIFT** / **CANCEL**.
4. Сервер ще раз перевіряє все і передає голема: той самий UID, новий id у отримувача, журнал і глобальний індекс (GolemRegistry.Move), збереження обох. Тости обом: «You gifted …» / «… gifted you …».

## Обмеження
| Умова | Що бачить гравець |
| --- | --- |
| Ексклюзив (груповий, тижневі, кейсові, Marketplace) | кнопки GIFT немає |
| Дарувальник награв < 10 хв | сіра кнопка, «Gifting unlocks after 10 min of play (m:ss left)» |
| Отримувач награв < 10 хв | «This player can receive gifts after 10 min of play» |
| Кулдаун 30 с після подарунка | «You can gift again in Ns» |
| Голем з наступної мапи (`map` у GolemCatalog > `Stage` отримувача) | «This player must unlock MAP N first» |
| Повний інвентар отримувача | «Player's inventory is full» |
| Заблокований голем | «Unlock this golem to gift it» |
| Marketplace, арена боса | не працює |
| Голем на плоті / виставлений на маркеті | його не можна взяти в руку |

Отримувач нічого не підтверджує. Час гри — атрибут `Stat_Playtime` (StatsService), кулдаун — атрибут `GiftCD`.

## Index: MAP N
Голем, що починає випадати на пізнішій мапі, ніж поточна мапа гравця (`map` > `Stage`), — помаранчева плашка **MAP N** поверх картки; у картці внизу — «Drops from MAP N». Після переходу на нову мапу плашки оновлюються самі.

| Мапа | Големи |
| --- | --- |
| 1 | Wooden … Obsidian |
| 3 | Magmaheart, Ruby |
| 4 | Frostforged, Platinum |
| 5 | Aurelian |
| 6 | Astral |

## Скрипти
- `Shared/GolemGiftConfig` — правила (`check` — однаково на клієнті й сервері), тексти `TEXT`.
- `ServerScriptService/GolemGiftService` — Remotes/GolemGift, передача.
- `StarterPlayerScripts/GolemGiftClient` — кнопки GIFT над гравцями, вікно підтвердження.
- `StarterPlayerScripts/IndexUI` — плашки MAP N.
- `NicheBoot` — старт GolemGiftService (лобі).

## Стан
- [x] правила й передача — перевірено в Play (новачок, кулдаун, ексклюзив, MAP 3, повний інвентар, замок, успішна передача)
- [x] Index MAP N — перевірено в Play
- [ ] тест з двома гравцями (Test → Clients and Servers, 2 гравці)
