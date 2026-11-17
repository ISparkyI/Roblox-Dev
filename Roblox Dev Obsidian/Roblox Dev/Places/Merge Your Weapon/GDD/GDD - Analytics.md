---
tags: [gdd, analytics]
status: done
updated: 2026-11-15
---

# GDD - Analytics

← [[Merge Your Weapon - GDD|GDD]] · [[GDD - Roadmap|Roadmap]] п. 6

Дивитися: Creator Hub → гра → **Analytics → Funnels**. У Studio дані не пишуться (тільки в живій грі), але виклики безпечні (`pcall`).

## Воронки
| Воронка | Тип | Кроки |
| --- | --- | --- |
| Onboarding | туторіал (раз на гравця) | 1 Buy first weapon · 2 Press FIGHT · 3 Walk into the arena · 4 Collect the cash · 5 Buy second weapon · 6 Merge · 7 Second fight · 8 Supply Shop: free Turret · 9 Turret into a slot · 10 Fight with the Turret · 11 Use the Turret · 12 Tutorial complete |
| Zones | одноразова | крок N = «Zone N cleared» (перша зачистка, `ServerStorage.ZoneCleared`) |
| RobuxPurchase | повторна (сесія = візит у Shop) | 1 Shop opened · 2 Prompt: pass/product ID (вікно покупки закрили) · 3 Purchased |
| SupplyShop | повторна (сесія = візит у Supply Shop) | 1 Supply Shop opened · 2 Bought <id> |

Покупка зі стенда (Auto Merge) чи кнопки HUD без відкриття Shop — своя сесія, починається з кроку 2.

## Код
- `ServerScriptService.AnalyticsFunnels` — усі воронки; створює `Remotes.Analytics`.
- `StarterPlayerScripts.AnalyticsClient` — шле «open» при відкритті вікон `Shop` / `SupplyShop` (`UIOpen`).

## Ще не зроблено
- ребьорти 1…6 як воронка;
- економіка: `LogEconomyEvent` (гроші й геми: джерела / витрати).
