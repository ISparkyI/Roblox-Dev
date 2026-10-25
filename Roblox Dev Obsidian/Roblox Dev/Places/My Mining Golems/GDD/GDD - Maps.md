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

6 мап. На кожній мапі відкривається нова рідкість големів і 3 нові руди. Руди попередніх мап на новій мапі не спавняться, і навпаки: руду наступної мапи не можна фармити раніше. Частина ніші змінює вигляд через префаб мапи (мапа 1 — [Niche Stage 1](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FLocations%2FNiche%20Stage%201%2FNiche%20Stage%201)).

| Мапа | Назва | Як виглядає | Нова рідкість | Руди | Ціна переходу (пропозиція) |
| --- | --- | --- | --- | --- | --- |
| 1 | **Mossy Grotto** | вологий камінь, мох, коріння зі стелі, ліхтарі | Common, Uncommon | Coal, Copper, Iron | — |
| 2 | **Rusty Mine** | стара шахта: рейки, вагонетки, дерев'яні підпори, іржа | Rare | Tin, Silver, Gold | 1M |
| 3 | **Crystal Depths** | світні блакитні й фіолетові кристали, відблиски | Epic | Quartz, Amethyst, Sapphire | 25M |
| 4 | **Magma Caverns** | ріки лави, чорний базальт, іскри | Legendary | Obsidian, Ruby, Emberite | 625M |
| 5 | **Frozen Abyss** | лід, сніг, бурульки, холодне світло | Mythic | Frostite, Platinum, Diamond | 15.62B |
| 6 | **Void Core** | темна порожнеча, левітуючі брили, зорі | Divine, Celestial | Voidstone, Starmetal, Celestium | 390.62B |

**Що скидається при переході на нову мапу:**

| Що | Скидається? |
| --- | --- |
| Money | так |
| Големи | так, **крім Exclusive і збережених у печері збереження** |
| Прокачка плоту (зони, швидкість спавну, множник, місткість ящиків) | так |
| Кількість місць ролу | так |
| Forge: голем знову засинає (будити рудою нової мапи), покращення Forge, руда й злитки на піддонах | так (пропозиція) |
| Roll Luck | ні |
| Печера збереження (слоти і големи в них) | ні |
| Index | ні |
| Діаманти, тікети | ні |
| Ребітхи | ні |
| Глобальні множники за Robux / тікети | ні |
| Куплені геймпаси | ні |

Ціни руди й HP на кожній мапі — [Ores and Bars](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Ores%20and%20Bars); множник Money за мапу — [Monetization](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Monetization) (TOTAL MULTI); множник цін покращень — [Plots](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Plots).
