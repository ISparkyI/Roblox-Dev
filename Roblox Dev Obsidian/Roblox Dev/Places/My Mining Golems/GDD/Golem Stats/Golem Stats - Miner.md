---
tags: [gdd, place, golems, stats]
status: draft
updated: 2026-10-25
---

# Golem Stats - Miner

← [[GDD - Golems]]

Характеристики **майнерів** (підклас, що ламає руду кіркою). Один рядок — один голем, значення для мутації **Normal**. Решту мутацій код рахує формулами з [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems) («Формули мутацій»).

> [!info] Як заповнювати
> - Порожня клітинка = ще не вирішено. Claude бере в код тільки заповнені рядки.
> - Числа пиши як є: `1000`, `1.25`, `1 to 400` → у «Шанс» просто `400`.
> - Новий голем → новий рядок. ID — латиницею, маленькими, без пробілів (`wooden`, `stone`), він же ключ у коді й назва моделі.
> - Голем має бути в усіх трьох таблицях (майнер, [носій](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Carrier), [воїн](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGolem%20Stats%2FGolem%20Stats%20-%20Warrior)) з тим самим ID. Рідкість, мапа й шанс ролу зазвичай однакові в усіх трьох; ціну й силу можна робити різною.

## Що означає кожна колонка
| Колонка | Що це | Одиниці |
| --- | --- | --- |
| ID | ключ голема в коді | текст |
| Назва | як бачить гравець | текст |
| Рідкість | Common … Celestial / Exclusive | — |
| Мапа | на якій мапі з'являється в ролі (1–6) | число |
| Шанс ролу | «1 до N» — пишемо N (`1` = базовий, випадає, коли не випало нічого рідшого; Exclusive — `—`) | N |
| Ціна | скільки коштує купити після ролу | Money (`0` = безкоштовний) |
| Шкода | скільки HP руди знімає один удар | HP |
| Швидкість | **один множник на все**: рух і удари. `x1` = 8 стад/с і удар раз на 1,40 с; `x2` = 16 стад/с і удар раз на 0,70 с (анімації теж ×2) | множник |
| Розмір | масштаб моделі (`1` = як Stone Golem зараз) | множник |
| Модель | чи є 3D-модель у грі | є / ні |
| Примітка | будь-що | текст |

**Похідне (рахує код, не заповнювати):** інтервал удару = `1.40 / Швидкість`, рух = `8 × Швидкість` стад/с, DPS = `Шкода × Швидкість / 1.40`. Підпис над големом при ролі: `Speed x{Швидкість}`, `Damage x{Шкода / 5}` (еталон — Wooden Golem Normal).

## Таблиця
| ID          | Назва             | Рідкість  | Мапа | Шанс ролу (1 до N) | Ціна         | Шкода | Швидкість | Розмір | Модель             | Примітка                                        |
| ----------- | ----------------- | --------- | ---- | ------------------ | ------------ | ----- | --------- | ------ | ------------------ | ----------------------------------------------- |
| wooden      | Wooden Golem      | Common    | 1    | 1                  | 0            | 1     | 1         | 1      | ні                 | перший голем, безкоштовний на будь-якій мутації |
| stone       | Stone Golem       | Common    | 1    | 10                 | 150          | 2     | 1.05      | 1      | є (Stone Golem v2) |                                                 |
| clay        | Clay Golem        | Common    | 1    | 15                 | 400          | 3     | 0.9       | 1.05   | ні                 | важкий, повільний                               |
| gravel      | Gravel Golem      | Common    | 1    | 25                 | 850          | 3     | 1.2       | 0.95   | є (Gravel Golem v1) | легкий, швидкий                                 |
| mossback    | Mossback Golem    | Common    | 1    | 40                 | 1400         | 5     | 1         | 1.05   | є (Mossback Golem v1) |                                                 |
| copperhead  | Copperhead Golem  | Uncommon  | 1    | 75                 | 2100         | 6     | 1.1       | 1.05   | є (Copperhead Golem v1) |                                                 |
| flint       | Flint Golem       | Uncommon  | 1    | 120                | 4000         | 7     | 1.25      | 1      | є (Flint Golem v1) | швидкий                                         |
| rustbolt    | Rustbolt Golem    | Uncommon  | 1    | 200                | 12000        | 12    | 0.95      | 1.1    | є (Rustbolt Golem v1) | важкий                                          |
| granite     | Granite Golem     | Uncommon  | 1    | 300                | 18500        | 15    | 1.05      | 1.15   | є (Granite Golem v1) |                                                 |
| lantern     | Lantern Golem     | Uncommon  | 1    | 500                | 29500        | 19    | 1.15      | 1.05   | є (Lantern Golem v1) | світиться (Neon)                                |
| ironclad    | Ironclad Golem    | Rare      | 1    | 900                | 36000        | 25    | 1         | 1.15   | є (Ironclad Golem v1) | власний ящик-фортеця                         |
| quartzling  | Quartzling Golem  | Rare      | 1    | 1500               | 75000        | 50    | 1.35      | 0.9    | є (Quartzling Golem v1) | ящик-жеода                               |
| lodestone   | Lodestone Golem   | Rare      | 1    | 2000               | 95000        | 70    | 1.25      | 1.1    | є (Lodestone Golem v1) | голем-магніт, скринька з магнітом        |
| tinker      | Tinker Golem      | Rare      | 1    | 2500               | 120000       | 90    | 1.2       | 1      | є (Tinker Golem v2) | скринька механіка                           |
| silverjaw   | Silverjaw Golem   | Rare      | 1    | 4000               | 250000       | 200   | 1.15      | 1.15   | є (Silverjaw Golem v2) | ящик-паща                              |
| topaz       | Topaz Golem       | Epic      | 1    | 6000               | 550000       | 255   | 1.2       | 1.15   | є (Topaz Golem v1) | огранений топаз, 2 деталі Neon            |
| geode       | Geode Golem       | Epic      | 1    | 8000               | 1000000      | 310   | 1.1       | 1.2    | є (Geode Golem v1) | світні кристали (Neon)                       |
| amethyst    | Amethyst Golem    | Epic      | 1    | 15000              | 3000000      | 550   | 1.4       | 1.15   | є (Amethyst Golem v1) | кристалічні крила (Neon)                  |
| sapphire    | Sapphire Golem    | Epic      | 1    | 25000              | 7500000      | 920   | 1.25      | 1.2    | є (Sapphire Golem v2) | німб крутиться, самоцвіти (Neon)            |
| emerald     | Emerald Golem     | Epic      | 1    | 35000              | 15000000     | 1050  | 1.2       | 1.2    | є (Emerald Golem v1) | смарагдовий раджа, світні кристали (Neon), меч-талвар |
| obsidian    | Obsidian Golem    | Legendary | 1    | 50000              | 30000000     | 1200  | 1.1       | 1.35   | є (Obsidian Golem v1) | орбіта уламків, власні анімації (Neon)    |
| moonstone   | Moonstone Golem   | Legendary | 1    | 75000              | 50000000     | 1800  | 1.25      | 1.35   | є (Moonstone Golem v1) | місячний вартовий, стандартні анімації, без обмеження мапи (Neon) |
| magmaheart  | Magmaheart Golem  | Legendary | 3    | 100000             | 80000000     | 2400  | 1.5       | 1.25   | є (Magmaheart Golem v1) | серце пульсує, кратер, лава (Neon)       |
| ruby        | Ruby Golem        | Legendary | 3    | 175000             | 250000000    | 3400  | 1.3       | 1.4    | є (Ruby Golem v1) | рапіра й мотика, шпилі «резонують» (Neon)    |
| frostforged | Frostforged Golem | Mythic    | 4    | 400000             | 1500000000   | 5200  | 1.45      | 1.35   | є (Frostforged Golem v1) | шабля й льодоруб, сніг падає, горн пульсує (Neon) |
| prismatic   | Prismatic Golem   | Mythic    | 4    | 650000             | 3000000000   | 6300  | 1.4       | 1.4    | є (Prismatic Golem v1) | діамантова призма над головою крутиться, веселкові промені пульсують (Neon) |
| platinum    | Platinum Golem    | Mythic    | 4    | 1000000            | 6000000000   | 7500  | 1.3       | 1.5    | є (Platinum Golem v1) | фламберг і бур, гіроскоп навхрест (Neon) |
| aurelian    | Aurelian Golem    | Divine    | 5    | 2500000            | 40000000000  | 9000  | 1.7       | 1.45   | є (Aurelian Golem v1) | хопеш і сонцекайло, справжнє світло й іскри, сонячний диск (Neon) |
| astral      | Astral Golem      | Celestial | 6    | 10000000           | 200000000000 | 12000 | 2         | 1.5    | є (Astral Golem v1) | кінцівки на магічних суглобах, кільце Сатурна, осколковий клинок (Neon) |
| coral       | Coral Golem       | Exclusive | 1    | Exclusive Case 88,9 % | 0         | 65 % best | 1.2    | 1.15   | є (Coral Golem v1) | ексклюзив кейсу #1: шкода = 0,65 × BestMinerDmg (носій і воїн теж 65 %), завжди Normal |
| jade        | Jade Golem        | Exclusive | 1    | Exclusive Case 8 % | 0            | 100 % best | 1.35  | 1.2    | є (Jade Golem v1) | ексклюзив кейсу #2: шкода = 1,0 × BestMinerDmg (носій і воїн теж 100 %), диск «бі» обертається (Neon) |
| storm       | Storm Golem       | Exclusive | 1    | Exclusive Case 2 % | 0            | 125 % best | 1.5   | 1.35   | є (Storm Golem v1) | ексклюзив кейсу #3: 1,25 × best для всіх класів, катана й молот-кайло, блискавки (Neon) |
| phantom     | Phantom Golem     | Exclusive | 1    | Exclusive Case 1 % | 0            | 160 % best | 1.75  | 1.45   | є (Phantom Golem v1) | ексклюзив кейсу #4: 1,6 × best, напівпрозорі примарні деталі (fade), клеймор і коса |
| chrono      | Chrono Golem      | Exclusive | 1    | Exclusive Case 0,1 % | 0          | 200 % best | 2.0   | 1.5    | є (Chrono Golem v1) | ексклюзив кейсу #5 (фінальний): 2,0 × best, «тіні часу» (echo), меч-стрілка й кірка-шестерня, аура ChronoAura |
| honey       | Honey Golem       | Exclusive | 1    | Daily, день 14 (Miner) | 0       | 65 % best  | 1.15  | 1.05   | є (Honey Golem v1) | тижнева нагорода: 0,65 × best для всіх класів, бджілка ширяє (bob + sway) |
| snow        | Snow Golem        | Exclusive | 1    | Daily, день 21 (Carrier) | 0     | 90 % best  | 1.2   | 1.1    | є (Snow Golem v1) | тижнева нагорода: 0,9 × best для всіх класів, шарф хитається (sway) |
| cloud       | Cloud Golem       | Exclusive | 1    | Daily, день 28 (Miner) | 0       | 150 % best | 1.3   | 1.15   | є (Cloud Golem v1) | тижнева нагорода: 1,5 × best для всіх класів, веселка на спині, хмаринки-сателіти (bob + sway) |

*Таблицю правив користувач 2026-10-25 (ціни, шкода, швидкість, мапи) — це джерело правди. Таблиці носія й воїна рахуються від неї. У коді — модуль [GolemCatalog](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FScripts%2FModules%2FGolemCatalog). Як побудована прогресія — у [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems) («Прогресія каталогу»).*

## Приклад: Stone Golem за мутаціями (рахує код)
Множник сили M (27.10.2026): ціна і шкода × M, швидкість без змін (x1.05, інтервал 1.33 с, рух 8.4 стад/с), тому DPS теж × M.

| Мутація | M | Ціна | Шкода | Швидкість | DPS |
| ------- | --- | ---- | ----- | --------- | --- |
| Normal | 1 | 150 | 2 | x1.05 | 1.50 |
| Bronze | 1,25 | 188 | 2.5 | x1.05 | 1.88 |
| Silver | 1,5 | 225 | 3 | x1.05 | 2.25 |
| Gold | 2 | 300 | 4 | x1.05 | 3.00 |
| Diamond | 3 | 450 | 6 | x1.05 | 4.50 |
| Void | 5 | 750 | 10 | x1.05 | 7.50 |
| Rainbow | 10 | 1500 | 20 | x1.05 | 15.00 |
| Secret | 25 | 3750 | 50 | x1.05 | 37.50 |
