---
tags: [gdd, place, boards]
status: draft
updated: 2026-10-29
---

# GDD - Leaderboards

← [[My Mining Golems - GDD|GDD]]

Лідерборди в центрі печери й особистий борд гравця в ніші.

## Лідерборди й борди
- **У центрі печери:** топ донатерів; топ 1–100 за Money; топ 1–100 за кількістю роллів.
- **Біля кожної ніші:** особистий борд гравця (SurfaceGui), великі числа через NumberFormat:

| Рядок | Що показує |
| --- | --- |
| Money | поточні Money |
| Total | усі Money, зароблені за весь час |
| Income/s | поточний дохід за секунду з усіма множниками |
| Gems | діаманти |
| World | поточна мапа (номер і назва) |
| Rebirths | кількість ребітхів |
| Rolls | кількість ролів за весь час |
| Playtime | час у грі за весь час |
| Quests Done | виконані квести |
| Golems Found | відкриті записи Index |
| Golems Owned | големи в інвентарі зараз |
| Working | големи, що зараз стоять у зонах фарму (наш аналог On Road) |
| R$ Spent | витрачено Robux у грі |
| R$ Gifted | подаровано Robux іншим гравцям |

## У грі (29.10.2026)
- **Лідерборди в центрі зали** — `Workspace/Cave/Hub/Leaderboards/<key>` (Money, Income, Rolls, BestRoll, Donators, Gifters, Playtime, Bosses): екрани `LeaderboardClient`, дані й статуї топ-1 — `StatsService`, набір і кольори — `Shared/HubConfig.BOARDS`. Статуя топ-1 стоїть з головою на місці (R6 і R15) і має свою процедурну анімацію для кожного табла (`StatueAnimator`, 8 анімацій).
- **Особисте табло біля ніші** — модель `PlotStats` у шаблоні ніші (`NichePrefab_Stage1`), у правому куті біля входу, екраном назовні: як лідерборд, але простіше — шапка з аватаром, ім'ям і «PLAYER STATS · PLOT N», прокручуваний список 14 рядків. Вільна ніша — напис EMPTY PLOT. Код — `PlotStatsClient`.
