---
tags: [script, module, ui, format]
status: active
updated: 2026-10-23
---

# Number Format

← [[Scripts]]

> [!summary] Коротко
> ModuleScript для показу великих чисел у UI. До мільйона число пишеться повністю з комами (`999,999`), далі коротко з суфіксом: `1M`, `1.23B`, `4.5T`, `1.5Sx` … Округлення **завжди вниз**, 2 знаки після крапки, зайві нулі прибираються.

- **Код:** `NumberFormat.lua` (у цій папці).
- **У Roblox:** `ReplicatedStorage/Shared/NumberFormat` (працює і на клієнті, і на сервері).

## Суфікси (коротка шкала)
Це загальноприйняті в Roblox-симуляторах скорочення англійських назв чисел (million, billion, trillion, quadrillion …): кожні 3 нулі — новий суфікс.

| Суфікс | Число | Назва |
| --- | --- | --- |
| — | до 999,999 | повне число |
| M | 10^6 | million |
| B | 10^9 | billion |
| T | 10^12 | trillion |
| Qa | 10^15 | quadrillion |
| Qi | 10^18 | quintillion |
| Sx | 10^21 | sextillion |
| Sp | 10^24 | septillion |
| Oc | 10^27 | octillion |
| No | 10^30 | nonillion |
| Dc | 10^33 | decillion |
| Ud | 10^36 | undecillion |
| Dd | 10^39 | duodecillion |
| Td | 10^42 | tredecillion |
| Qad | 10^45 | quattuordecillion |
| Qid | 10^48 | quindecillion |
| Sxd | 10^51 | sexdecillion |
| Spd | 10^54 | septendecillion |
| Ocd | 10^57 | octodecillion |
| Nvd | 10^60 | novemdecillion |
| Vg | 10^63 | vigintillion |
| e | ≥ 10^66 | науковий запис: `1.23e66` |

## API
```lua
local NumberFormat = require(game:GetService("ReplicatedStorage").Shared.NumberFormat)

NumberFormat.short(999999)    --> "999,999"
NumberFormat.short(1234567)   --> "1.23M"
NumberFormat.short(22750000)  --> "22.75M"
NumberFormat.short(999999999) --> "999.99M"   (вниз, не "1B")
NumberFormat.short(1.5e21)    --> "1.5Sx"
NumberFormat.short(-2500000)  --> "-2.5M"
NumberFormat.short(n, 1)      --> 1 знак після крапки замість 2
NumberFormat.full(1234567)    --> "1,234,567"
NumberFormat.money(1234567)   --> "$1.23M"
NumberFormat.mult(2.5)        --> "x2.5"
NumberFormat.time(3900)       --> "1h 05m"   ("4m 30s", "45s")
```

## Правила
- Тільки для **показу**: у даних і розрахунках зберігаємо звичайні числа.
- Округлення вниз, щоб гравець ніколи не бачив більше, ніж має (1,999,999 → `1.99M`, а не `2M`).
- Порядок числа рахується порівнянням, без `log10`, тому на межах (999,999,999) немає похибок.
- Числа Luau (double) точні до ~9×10^15. Для більших значень останні цифри можуть бути неточними, але для показу з 2 знаками цього достатньо.

## Перевірка
Перевірено в Studio: `0`, `999,999`, `1M`, `1.23M`, `22.75M`, `999.99M`, `1B`, `999.99B`, `1T`, `3.33Qa`, `1.5Sx`, `4.2Dc`, `1Vg`, `999Vg`, `1e66`, `-2.5M`, `∞` — усе як очікується.
