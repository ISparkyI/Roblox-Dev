---
tags: [place, interactive, monetization, roll]
status: in-game
version: 1
updated: 2026-11-10
---

# Robux Stand

← [[Interactive Objects]] · [[Roll Station]]

Стенд у ніші біля бортика плоту, збоку від ролу. На ньому по колу змінюються големи, яких можна купити за Robux. Сам стенд стоїть рівно, а голем на ньому повернутий діагонально до важеля, щоб ті, хто ролить, його бачили.

## Як працює
- Голем змінюється кожні **8 с** (`RobuxStandConfig.ROTATE`). Поточний визначається за часом сервера, тож у всіх гравців однаковий.
- Голем — клієнтська модель, масштаб ×0,5, як на стендах ролу.
  - Він з'являється з невеликим перескоком і повільно гойдається вліво-вправо: ±14°, цикл ≈ 9 с. Гойдається лише поблизу камери (90 стадів).
  - Напрям голема задає атрибут стенду `FaceDirLocal` — вектор у просторі стенду, бо ніші праворуч розвернуті.
- Табличка над головою така сама, як після ролу: рідкість, назва, ціна (значок Robux, як біля x2 Money, і жовте число), Speed і Damage відносно Wooden.
- Кнопка **BUY** (зелена, `CustomPrompts`) відкриває вікно оплати Developer Product поточного голема. Поки `product = 0`, над табличкою на 2 с з'являється «COMING SOON».
- Гравець отримує **майнера** без мутації. Ліміт інвентаря не діє, бо покупка платна. Голем закріплюється в хотбарі, а гравець бачить повідомлення «… added to your backpack!».

## Пропозиції
| # | Голем | Рідкість | Robux |
| --- | --- | --- | --- |
| 1 | Topaz | Epic | 79 |
| 2 | Geode | Epic | 99 |
| 3 | Amethyst | Epic | 119 |
| 4 | Sapphire | Epic | 139 |
| 5 | Emerald | Epic | 159 |
| 6 | Obsidian | Legendary | 249 |
| 7 | Moonstone | Legendary | 279 |

**Підключити продукти:** створити 7 Developer Products у Creator Hub і вписати їхні id у поле `product` у `ReplicatedStorage/Shared/RobuxStandConfig`.

## Де що
| Що | Де |
| --- | --- |
| Стенд | `NichePrefabs/NichePrefab_Stage1…6/RollSystem/RobuxStand`: копія `Prefabs/RollStand`, `RobuxBuyAnchor/RobuxBuyPrompt`. У Stage1 стоїть на (−788,5; 278) біля бортика Plot 2 |
| Конфіг | `ReplicatedStorage/Shared/RobuxStandConfig` (`OFFERS`, `ROTATE`, `CLS`, `ROBUX_ICON`, `indexAt`, `byProduct`) |
| Клієнт | `StarterPlayerScripts/RobuxStandClient` |
| Видача | `ServerScriptService/RobuxStandService` (`GrantProduct`, `Grant`); викликається з `MonetizationService.baseGrant` |
| Бекап | `NicheBackup/MonetizationService_pre_robuxstand` |

## Перевірка в Play (10.11.2026)
- Стенд є в усіх 6 нішах. Голем змінюється кожні 8 с і в кожній ніші дивиться на важіль (dot 0,98–0,99), а стенд стоїть рівно.
- Табличка: «Epic · Amethyst Golem · [Robux] 119 · Speed x1.4 · Damage x550».
- BUY з `product = 0` показує «COMING SOON».
- Видача через `MonetizationService.GrantById` з тестовим id: +1 голем Topaz-майнер.
- Помилок скриптів немає.

## Історія
- **10.11.2026 (+10 %):**
  - Стенд ×1,1 (ScaleTo, низ на підлозі, ≈ 7 × 7 стадів), голем ×0,55 замість ×0,5, табличка 5,28 × 3,19 замість 4,8 × 2,9.
  - BUY — на 3,2 стада вперед і 1,3 вгору.
  - Перевірено в Play: Obsidian стоїть на плиті (низ 2,64), табличка над головою.
