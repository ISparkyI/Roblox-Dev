---
tags: [gdd, place, golems, stats]
status: draft
updated: 2026-10-25
---

# Golem Stats - Warrior

← [[GDD - Golems]]

Характеристики **воїнів** (підклас, що б'ється з босом на івентах, відкривається з мапи 2). Один рядок — один голем, значення для мутації **Normal**. Решту мутацій код рахує формулами з [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems) («Формули мутацій»).

> [!info] Як заповнювати
> - Порожня клітинка = ще не вирішено. Claude бере в код тільки заповнені рядки.
> - Той самий ID, що й у [майнера](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Miner) і [носія](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Carrier).

## Що означає кожна колонка
| Колонка | Що це | Одиниці |
| --- | --- | --- |
| ID, Назва, Рідкість, Мапа, Шанс ролу, Ціна, Розмір, Модель, Примітка | як у майнера | — |
| Шкода | скільки HP боса знімає один удар | HP |
| HP | скільки шкоди витримує воїн, поки не впаде на арені | HP |
| Швидкість | **один множник на все**: рух і удари. `x1` = 8 стад/с і удар раз на 1,40 с; `x2` = 16 стад/с і удар раз на 0,70 с | множник |

**Похідне (рахує код):** інтервал удару = `1.40 / Швидкість`, DPS = `Шкода × Швидкість / 1.40`. Підпис при ролі: `Speed x{Швидкість}`, `Damage x{Шкода / шкода Wooden}`.

## Таблиця
| ID          | Назва             | Рідкість  | Мапа | Шанс ролу (1 до N) | Ціна         | Шкода | HP     | Швидкість | Розмір | Модель             | Примітка                 |
| ----------- | ----------------- | --------- | ---- | ------------------ | ------------ | ----- | ------ | --------- | ------ | ------------------ | ------------------------ |
| wooden      | Wooden Golem      | Common    | 1    | 1                  | 50           | 1     | 10     | 1         | 1      | ні                 |                          |
| stone       | Stone Golem       | Common    | 1    | 10                 | 200          | 2     | 20     | 1.1       | 1      | ні (меча ще немає) |                          |
| clay        | Clay Golem        | Common    | 1    | 15                 | 610          | 3     | 40     | 0.9       | 1.05   | ні                 | танк                     |
| gravel      | Gravel Golem      | Common    | 1    | 25                 | 960          | 3     | 30     | 1.25      | 0.95   | ні                 |                          |
| mossback    | Mossback Golem    | Common    | 1    | 40                 | 1900         | 5     | 50     | 1.05      | 1.05   | ні                 |                          |
| copperhead  | Copperhead Golem  | Uncommon  | 1    | 75                 | 2500         | 6     | 60     | 1.15      | 1.05   | ні                 |                          |
| flint       | Flint Golem       | Uncommon  | 1    | 120                | 5100         | 7     | 70     | 1.3       | 1      | ні                 |                          |
| rustbolt    | Rustbolt Golem    | Uncommon  | 1    | 200                | 19000        | 10    | 140    | 0.95      | 1.1    | ні                 | танк                     |
| granite     | Granite Golem     | Uncommon  | 1    | 300                | 27000        | 13    | 180    | 1.05      | 1.15   | ні                 | танк                     |
| lantern     | Lantern Golem     | Uncommon  | 1    | 500                | 35000        | 18    | 180    | 1.2       | 1.05   | ні                 |                          |
| ironclad    | Ironclad Golem    | Rare      | 1    | 900                | 58000        | 21    | 290    | 1         | 1.15   | ні                 | танк                     |
| quartzling  | Quartzling Golem  | Rare      | 1    | 1500               | 85000        | 48    | 480    | 1.4       | 0.9    | ні                 |                          |
| lodestone   | Lodestone Golem   | Rare      | 1    | 2000               | 125000       | 67    | 670    | 1.3       | 1.1    | є (меч з полюсами) | 08.11.2026               |
| tinker      | Tinker Golem      | Rare      | 1    | 2500               | 170000       | 86    | 860    | 1.25      | 1      | ні                 |                          |
| silverjaw   | Silverjaw Golem   | Rare      | 1    | 4000               | 320000       | 190   | 1900   | 1.2       | 1.15   | ні                 |                          |
| topaz       | Topaz Golem       | Epic      | 1    | 6000               | 750000       | 245   | 2450   | 1.25      | 1.15   | є (топазовий меч)  | 08.11.2026               |
| geode       | Geode Golem       | Epic      | 1    | 8000               | 1600000      | 260   | 3600   | 1.1       | 1.2    | ні                 | танк                     |
| amethyst    | Amethyst Golem    | Epic      | 1    | 15000              | 3600000      | 530   | 5300   | 1.45      | 1.15   | ні                 |                          |
| sapphire    | Sapphire Golem    | Epic      | 1    | 25000              | 10000000     | 880   | 8800   | 1.3       | 1.2    | ні                 |                          |
| emerald     | Emerald Golem     | Epic      | 1    | 35000              | 22000000     | 940   | 11000  | 1.2       | 1.2    | є (срібний меч)   | 08.11.2026               |
| obsidian    | Obsidian Golem    | Legendary | 1    | 50000              | 50000000     | 1000  | 14000  | 1.1       | 1.35   | ні                 | танк                     |
| moonstone   | Moonstone Golem   | Legendary | 1    | 75000              | 70000000     | 1600  | 18000  | 1.3       | 1.35   | є (місячна шабля) | 08.11.2026               |
| magmaheart  | Magmaheart Golem  | Legendary | 3    | 100000             | 96000000     | 2300  | 23000  | 1.55      | 1.25   | ні                 |                          |
| ruby        | Ruby Golem        | Legendary | 3    | 175000             | 400000000    | 2900  | 41000  | 1.3       | 1.4    | ні                 | танк                     |
| frostforged | Frostforged Golem | Mythic    | 4    | 400000             | 1900000000   | 5000  | 50000  | 1.5       | 1.35   | ні                 |                          |
| platinum    | Platinum Golem    | Mythic    | 4    | 1000000            | 9200000000   | 6400  | 90000  | 1.3       | 1.5    | ні                 | танк                     |
| aurelian    | Aurelian Golem    | Divine    | 5    | 2500000            | 45000000000  | 8700  | 87000  | 1.75      | 1.45   | ні                 |                          |
| astral      | Astral Golem      | Celestial | 6    | 10000000           | 270000000000 | 12000 | 120000 | 2.05      | 1.5    | ні                 |                          |

*Wooden і Stone — значення користувача. Решта — від таблиці [майнера](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Miner) (ID, назва, рідкість, мапа, шанс, розмір — ті самі): ціна ≈ 4⁄3 ціни майнера ± до 25 % (танки дорожчі, швидкі дешевші), швидкість = майнер + 0.05 (у танків — як у майнера), шкода — та сама сила, що в майнера (у танків ×0.85), HP ≈ 10 × шкода (танки 14 ×). Остаточно HP підганяємо під HP боса ([Boss Events](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Boss%20Events)). Claude, 2026-10-25.*

Мутації: шкода й HP `floor(X × 1.35^k)`, швидкість `× 1.05^k`, ціна `floor(Ціна × 1.5^k)`.
