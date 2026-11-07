---
tags: [gdd, plan, localization]
status: draft
updated: 2026-11-05
---

# Plan: Localization (автопереклад Roblox)

← [[Plans]]

> [!summary] Коли
> **У самому кінці, перед релізом.** Поки тексти змінюються, переклад даремно витрачає квоту й засмічує таблицю. Зараз лише пишемо новий UI «під переклад» (правила нижче).

## Як працює
Автопереклад Roblox: **Automatic Text Capture (ATC)** збирає тексти з UI (лише об'єкти з `AutoLocalize = true`), **Automatic Translation** перекладає їх, **Use Translated Content** показує переклад гравцям. Мова оригіналу — English. Квота — посимвольно на кожну мову; ручні переклади автоматика не перезаписує.

## Правила для UI (діють уже зараз)
| Правило | Навіщо |
|---|---|
| Число / сума / таймер / нік — **окремий** `TextLabel` з `AutoLocalize = false` | інакше кожен варіант («$6,000/h», «$6,100/h»…) стає окремим рядком |
| Фразу з числом ділимо на частини в `UIListLayout` (фраза / число / фраза), відступ ≈ пробіл | англійською виглядає так само, текст перекладається |
| Чисто числові написи (баланси, лічильники, «3 / 3 LEFT») — `AutoLocalize = false` | не засмічують таблицю |
| Адмінка, дебаг, тестові написи — `AutoLocalize = false` | не перекладати службове |
| Текст не малювати в картинках, якщо можна зробити `TextLabel` | ATC не читає картинки |
| Не склеювати речення з кусків з різних місць коду | переклад цілої фрази якісніший |

Вже зроблено так: `OfflineWindow` (вікно WELCOME BACK, плашка «Golems mine $N/h even offline»).

## Чекліст перед релізом
- [ ] Пройтись по всіх клієнтських скриптах UI: числа / суми / таймери → окремі написи з `AutoLocalize = false`; склеєні фрази → частини.
  - відомі місця: тости «+$N Money!», «N / M LEFT» і назви скіпів у лавках (StallShopWindow), HUD-лічильники (MainHUD), таймери боса, HP / шкода (BossArenaClient), Index, інвентар, квести, Daily.
- [ ] Адмін-панель і службові GUI → `AutoLocalize = false`.
- [ ] Studio: Window → Localization → **Localization Tools** → **Automatic Text Capture**; пройти всі вікна гри в Play.
- [ ] Creator Hub → гра → **Localization → Settings**: source language English; **Capture text from experience UI while users play**; **Use Translated Content**.
- [ ] **Languages**: увімкнути мови для «Experience Information» і «Experience Strings & Products».
- [ ] Вручну перекласти: назви й описи геймпасів (ATC їх не бере), назву й опис гри.
- [ ] Перевірити: Test → Player Emulator → інша мова; поправити криві переклади й тексти, що не влазять (довгі мови: de, ru, pt).
