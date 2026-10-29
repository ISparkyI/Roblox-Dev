---
tags: [gdd, place, maps]
status: draft
updated: 2026-10-25
---

# GDD - Maps

← [[My Mining Golems - GDD|GDD]]

Мапи печери (6 світів): назви, вигляд, нова рідкість і руди кожної мапи, ціна переходу, що скидається на новій мапі.

**Детально:** [Niche Stage 1](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FNiche%20Stage%201%2FNiche%20Stage%201)

## Мапи печери

> [!note] Назва
> Раніше — «етапи» (Stage). За рішенням користувача в грі й документах тепер **Map / мапа** (рядок «Map» у плашці множників, «Map 1 · Mossy Grotto» на табличці ніші). Ідентифікатори в коді й даних лишились старі (`Stage`, `NichePrefab_Stage1`, `STAGE_MULTS`, scope `stage`), щоб не зламати збереження; так само назва нотатки локації Niche Stage 1.

7 мап (оновлено 29.10.2026 за моделями руди в Studio). На кожній мапі — 3 нові руди; нові големи — за колонкою «Мапа» в таблиці майнера (GDD - Golems). Руди попередніх мап на новій мапі не спавняться, і навпаки: руду наступної мапи не можна фармити раніше. Частина ніші змінює вигляд через префаб мапи (мапа 1 — [Niche Stage 1](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FNiche%20Stage%201%2FNiche%20Stage%201)).

| Мапа | Назва | Як виглядає | Нові големи | Руди | Ціна переходу (пропозиція) |
| --- | --- | --- | --- | --- | --- |
| 1 | **Mossy Grotto** | вологий камінь, мох, коріння зі стелі, ліхтарі | Common, Uncommon, Rare, Epic, Legendary (Obsidian) | Coal, Copper, Iron | — |
| 2 | **Rusty Mine** | стара шахта: рейки, вагонетки, дерев'яні підпори, іржа | — | Tin, Silver, Gold | 1M |
| 3 | **Crystal Depths** | світні блакитні й фіолетові кристали, відблиски | Legendary (Magmaheart, Ruby) | Quartz, Amethyst, Sapphire | 25M |
| 4 | **Magma Caverns** | ріки лави, чорний базальт, іскри | Mythic | Obsidian, Ruby, Emberite | 625M |
| 5 | **Frozen Abyss** | лід, сніг, бурульки, холодне світло | Divine | Frostite, Platinum, Celestium | 15.62B |
| 6 | **Void Core** | темна порожнеча, левітуючі брили, зорі | Celestial | Voidstone, Starmetal, Eclipsium | 390.62B |
| 7 | **Toxic Wastes** *(пропозиція)* | отруйно-зелене світло, токсичні калюжі, радіоактивні кристали *(пропозиція)* | *(уточнити)* | Toxite, Uranite, Venomite | 9.77T *(×25, пропозиція)* |

**Що скидається при переході на нову мапу:**

| Що | Скидається? |
| --- | --- |
| Money | так |
| Големи | так, **крім Exclusive і збережених у печері збереження** |
| Руда й злитки в інвентарі | так |
| Зілля | ні |
| Прокачка плоту (зони, швидкість спавну, множник, місткість ящиків) | так |
| Кількість місць ролу | так, **крім геймпасів +1 Roll Stand** |
| Forge: голем знову засинає (будити рудою нової мапи), покращення Forge, руда й злитки на піддонах | так (пропозиція) |
| Roll Luck | ні |
| Печера збереження (куплені слоти і големи в них) | ні |
| Index | ні |
| Діаманти, тікети | ні |
| Ребітхи | ні |
| Глобальні множники за Robux / тікети | ні |
| Куплені геймпаси | ні |

Ціни руди й HP на кожній мапі — [Ores and Bars](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Ores%20and%20Bars); множник Money за мапу — [Monetization](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Monetization) (TOTAL MULTI); множник цін покращень — [Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Plots).

## Табло NEXT MAP (у грі, 28.10.2026)
Екран `Upgrade panels/Cave_Upgrade/screen` у ніші (скрипт `StarterPlayerScripts/MapBoard`): банер «NEXT MAP [N%]», шкала прогресу, множник Money мапи (зараз → наступна, `MultiConfig.STAGE_MULTS`), назва наступної мапи, «You will lose» / що лишається, кнопка **MAP N**.
- Прогрес = середнє за картками прокачки плотів, відкритими на цій мапі: (рівень − 1) / (max − 1). Перехід — лише на 100 %.
- Кнопку можна натиснути лише у своїй ніші й стоячи біля табла (≤ 32 стадів); інакше — «Come closer to the board!».
- Табло видно здалеку (прогрузка до 600 стадів).
- **Сам перехід ще не реалізований** (немає префаба мапи 2): на 100 % кнопка пише «Next map is coming soon!».
