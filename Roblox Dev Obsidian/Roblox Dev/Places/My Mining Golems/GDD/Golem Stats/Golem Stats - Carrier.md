---
tags: [gdd, place, golems, stats]
status: draft
updated: 2026-10-25
---

# Golem Stats - Carrier

← [[GDD - Golems]]

Характеристики **носіїв** (підклас, що збирає шматки руди з підлоги у свій ящичок і висипає в ящик плоту). Один рядок — один голем, значення для мутації **Normal**. Решту мутацій код рахує формулами з [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems) («Формули мутацій»).

> [!info] Як заповнювати
> - Порожня клітинка = ще не вирішено. Claude бере в код тільки заповнені рядки.
> - Той самий ID, що й у [майнера](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Miner) і [воїна](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Warrior).

## Що означає кожна колонка
| Колонка | Що це | Одиниці |
| --- | --- | --- |
| ID, Назва, Рідкість, Мапа, Шанс ролу, Ціна, Розмір, Модель, Примітка | як у майнера | — |
| Місткість | скільки шматків руди несе за одну ходку | шт. |
| Швидкість | **один множник на все**: рух, підбирання й висипання. `x1` = 8 стад/с і звичайна швидкість анімацій PickUp / Drop; `x2` = 16 стад/с і анімації ×2 | множник |

**Похідне (рахує код):** рух = `8 × Швидкість` стад/с. Підпис при ролі: `Speed x{Швидкість}`, `Capacity x{Місткість / 2}` (еталон — Wooden Golem Normal).

## Таблиця
| ID          | Назва             | Рідкість  | Мапа | Шанс ролу (1 до N) | Ціна         | Місткість | Швидкість | Розмір | Модель                        | Примітка           |
| ----------- | ----------------- | --------- | ---- | ------------------ | ------------ | --------- | --------- | ------ | ----------------------------- | ------------------ |
| wooden      | Wooden Golem      | Common    | 1    | 1                  | 0            | 1         | 1         | 1      | ні                            | безкоштовний       |
| stone       | Stone Golem       | Common    | 1    | 10                 | 100          | 2         | 1.125     | 1      | є (носій з ящичком на плотах) |                    |
| clay        | Clay Golem        | Common    | 1    | 15                 | 230          | 3         | 0.95      | 1.05   | ні                            |                    |
| gravel      | Gravel Golem      | Common    | 1    | 25                 | 650          | 2         | 1.25      | 0.95   | ні                            |                    |
| mossback    | Mossback Golem    | Common    | 1    | 40                 | 890          | 3         | 1.05      | 1.05   | ні                            |                    |
| copperhead  | Copperhead Golem  | Uncommon  | 1    | 75                 | 1500         | 4         | 1.15      | 1.05   | ні                            |                    |
| flint       | Flint Golem       | Uncommon  | 1    | 120                | 3200         | 4         | 1.3       | 1      | ні                            |                    |
| rustbolt    | Rustbolt Golem    | Uncommon  | 1    | 200                | 6400         | 6         | 1         | 1.1    | ні                            |                    |
| granite     | Granite Golem     | Uncommon  | 1    | 300                | 11000        | 7         | 1.1       | 1.15   | ні                            |                    |
| lantern     | Lantern Golem     | Uncommon  | 1    | 500                | 22000        | 7         | 1.2       | 1.05   | ні                            |                    |
| ironclad    | Ironclad Golem    | Rare      | 1    | 900                | 20000        | 9         | 1.05      | 1.15   | ні                            |                    |
| quartzling  | Quartzling Golem  | Rare      | 1    | 1500               | 60000        | 11        | 1.4       | 0.9    | ні                            |                    |
| lodestone   | Lodestone Golem   | Rare      | 1    | 2000               | 70000        | 14        | 1.3       | 1.1    | є (залізна скринька з магнітом) | 08.11.2026         |
| tinker      | Tinker Golem      | Rare      | 1    | 2500               | 80000        | 17        | 1.25      | 1      | ні                            |                    |
| silverjaw   | Silverjaw Golem   | Rare      | 1    | 4000               | 150000       | 25        | 1.2       | 1.15   | ні                            |                    |
| topaz       | Topaz Golem       | Epic      | 1    | 6000               | 330000       | 32        | 1.25      | 1.15   | є (сланцева скриня з топазом) | 08.11.2026         |
| geode       | Geode Golem       | Epic      | 1    | 8000               | 570000       | 40        | 1.15      | 1.2    | ні                            |                    |
| amethyst    | Amethyst Golem    | Epic      | 1    | 15000              | 2300000      | 40        | 1.45      | 1.15   | ні                            |                    |
| sapphire    | Sapphire Golem    | Epic      | 1    | 25000              | 5200000      | 60        | 1.3       | 1.2    | ні                            |                    |
| emerald     | Emerald Golem     | Epic      | 1    | 35000              | 9000000      | 70        | 1.25      | 1.2    | є (скриня раджі)             | 08.11.2026         |
| obsidian    | Obsidian Golem    | Legendary | 1    | 50000              | 16000000     | 80        | 1.15      | 1.35   | ні                            |                    |
| moonstone   | Moonstone Golem   | Legendary | 1    | 75000              | 35000000     | 85        | 1.3       | 1.35   | є (нічна скриня)            | 08.11.2026         |
| magmaheart  | Magmaheart Golem  | Legendary | 3    | 100000             | 64000000     | 90        | 1.55      | 1.25   | ні                            |                    |
| ruby        | Ruby Golem        | Legendary | 3    | 175000             | 150000000    | 140       | 1.35      | 1.4    | ні                            |                    |
| frostforged | Frostforged Golem | Mythic    | 4    | 400000             | 1100000000   | 140       | 1.5       | 1.35   | ні                            |                    |
| platinum    | Platinum Golem    | Mythic    | 4    | 1000000            | 3400000000   | 220       | 1.35      | 1.5    | ні                            |                    |
| aurelian    | Aurelian Golem    | Divine    | 5    | 2500000            | 31000000000  | 190       | 1.75      | 1.45   | ні                            |                    |
| astral      | Astral Golem      | Celestial | 6    | 10000000           | 130000000000 | 245       | 2.05      | 1.5    | ні                            |                    |

*Wooden і Stone — значення користувача. Решта — від таблиці [майнера](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Miner) (ID, назва, рідкість, мапа, шанс, розмір — ті самі): ціна ≈ ⅔ ціни майнера ± до 25 % (швидкі носії дорожчі, важкі дешевші), швидкість = майнер + 0.05, місткість ≈ `1.4 × Шкода_майнера^0.55` (важкі +15 %, швидкі −10 %). Claude, 2026-10-25.*

Мутації: місткість `max(1, floor(Місткість × 1.25^k))`, швидкість `× 1.05^k`, ціна `floor(Ціна × 1.5^k)`.
