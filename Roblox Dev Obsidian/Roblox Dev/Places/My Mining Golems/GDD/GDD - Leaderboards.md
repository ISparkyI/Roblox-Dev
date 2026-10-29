---
tags: [gdd, place, boards]
status: draft
updated: 2026-10-30
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
| Best Income | рекордний дохід за секунду (Stat_BestIncome) |
| Gems | діаманти |
| World | поточна мапа (номер і назва) |
| Rebirths | кількість ребітхів |
| Rolls | кількість ролів за весь час |
| Best Roll | найрідкісніший рол «1 in N» (Stat_BestRoll) |
| Playtime | час у грі за весь час |
| Daily Streak | днів поспіль забирав щоденну нагороду ([[GDD - Daily Rewards]]) |
| Best Streak | рекорд дейлі-стріку (Stat_BestStreak) |
| Quests Done | виконані квести |
| Index | відкриті записи Index / усі записи (напр. 34 / 582: големи, ексклюзиви, руда) |
| Golems Owned | големи в інвентарі зараз |
| Best Golem | найкращий голем: вища рідкість → мутація → сила (інвентар + плоти; ексклюзиви — найнижче) |
| Working | големи, що зараз стоять у зонах фарму (наш аналог On Road) |
| Mutations | успішні мутації (Stat_Mutations) |
| Ores Mined | шматки руди, добуті за весь час (Stat_OresMined) |
| Bosses Killed | убиті боси (Stat_BossKills) |
| Gamepasses | куплені геймпаси / усі геймпаси гри (напр. 3/13) |
| R$ Spent | витрачено Robux у грі |
| R$ Gifted | подаровано Robux іншим гравцям |

## У грі (29.10.2026)
- **Лідерборди в центрі зали** — `Workspace/Cave/Hub/Leaderboards/<key>` (Money, Income, Rolls, BestRoll, Donators, Gifters, Playtime, Bosses): екрани `LeaderboardClient`, дані й статуї топ-1 — `StatsService`, набір і кольори — `Shared/HubConfig.BOARDS`. Статуя топ-1 стоїть з головою на місці (R6 і R15) і має свою процедурну анімацію для кожного табла (`StatueAnimator`, 8 анімацій).
- **Особисте табло біля ніші** — модель `PlotStats` у шаблоні ніші (`NichePrefab_Stage1`), у правому куті біля входу, екраном назовні: як лідерборд, але простіше — шапка з аватаром, ім'ям і «PLAYER STATS · PLOT N», прокручуваний список 23 рядків. Вільна ніша — напис EMPTY PLOT. Код — `PlotStatsClient`.
