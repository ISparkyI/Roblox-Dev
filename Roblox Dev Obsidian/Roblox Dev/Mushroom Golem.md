---
tags: [model, golem, block-style, exclusive, group, weekly]
status: in-game
version: 1
updated: 2026-11-04
style: "GDD - Блоковий стиль моделей"
---

# Mushroom Golem

← [[Golems]] · [[Plan - Weekly Reward Golems]] · [[Honey Golem]] · [[Snow Golem]]

*Голем-мухомор.* Перший **ексклюзивний** голем гри (ID `mushroom`, рідкість **Exclusive**, `size = 1.05`, мапа 1). Еталон деталізації для всіх ексклюзивів — нотатки інших тижневих големів пишуть «рівень Mushroom».

## Як отримати
| Клас | Як | Сила |
| --- | --- | --- |
| **Майнер** | вступ у групу 996441586 — стенд для новачків у центрі зали (`GroupGolemService`, вікно GROUP REWARD) | **50 %** шкоди найкращого звичайного майнера гравця (`dynamic = "bestMiner"`, `share = 0.5`); над големом напис «+50% BEST» |
| **Носій** | тижнева нагорода Daily — день 7 (і далі по колу) | **75 %** місткості найкращого звичайного носія (`carrierShare = 0.75`) |
| **Воїн** | Boss Shop (ще не працює — «Coming soon» в Index) | — |

- Груповий майнер **не продається** на маркеті (`HubConfig.MARKET_BLOCKED["mushroom:miner"]`), носія продавати можна.
- Ексклюзив **не мутує** (MutationService) і **не згоряє** при переході на нову мапу (у печеру-сховище не ставиться).
- В Index — група Exclusive в кінці сторінки Normal кожного класу; замість шансу — «Group» / «Weekly» / «Boss Shop».
- Нагорода за перший запис в Index — 100 діамантів (`GolemCatalog.EXCLUSIVE_INDEX_REWARD`).

## Модель
| Параметр | Значення |
| --- | --- |
| Блоків | 106 (тіло) + 14 кірки + 11 меча + 28 ящика |
| Розмір | ≈ 7.5 × 8 × 4 стади |
| Кістки | як у Clay Golem (Root, Hips, Torso, Head, руки й ноги з двох частин, очі) |
| Генератор | `mushroom golem gen.py` (29.10.2026) |

**Маси:**
1. **Ніжка-тіло** кольору гриба (`#eadcbc` / тінь `#cbb48c`), пластинки під капелюхом (`#e6cfa3`).
2. **Капелюх мухомора** — червоний (`#d93a2f` / темний `#a8241f`) з білими плямами (`#fff8ec`).
3. **Обличчя** — темні зіниці (`#1c2836`), світлі відблиски, рожеві щічки (`#f2a0b4`).
4. **Біля ніг** — земля (`#7a4f33`) і мох (`#6fae4a`).

## Інструменти й ящик
Перефарбовані копії глиняних: `MushroomPickaxe`, `MushroomSword`, ящичок носія `MushroomCarryBox` (у тонах гриба й дерева `#c98a4a` / `#6b4426`).

## Палітра
| Роль | HEX |
| --- | --- |
| Ніжка / тінь | `#eadcbc` / `#cbb48c` |
| Капелюх / темний | `#d93a2f` / `#a8241f` |
| Плями | `#fff8ec` |
| Пластинки | `#e6cfa3` |
| Земля / мох | `#7a4f33` / `#6fae4a` |
| Дерево / темне | `#c98a4a` / `#6b4426` |
| Очі / світлий / щічки | `#1c2836` / `#f1f5f8` / `#f2a0b4` |

## Roblox
| Що | Де |
| --- | --- |
| Префаби | `Workspace/PlotPrefabs/MushroomGolem` (з `GolemData`), `MushroomPickaxe`, `MushroomSword`, `MushroomCarryBox` — за кейсом, x −1163 |
| Каталог | `GolemCatalog.GOLEMS.mushroom`: `exclusive = "group"`, `dynamic = "bestMiner"`, `share = 0.5`, `carrierShare = 0.75`; у `M.EXCLUSIVES` перший |
| Груповий стенд | `ServerScriptService/GroupGolemService` + `StarterPlayerScripts/GroupStandClient` (`Workspace/Cave/Hub/GroupStands`) |
| Daily | `DailyConfig.WEEKLY` — день 7: `{ key = "mushroom", cls = "carrier" }` |
| Іконки | `IconAtlas`: `GolemVP:mushroom:miner / carrier / warrior` (атлас 5) |

## Історія
- **29.10.2026** — створено як нагорода за групу (майнер), стенд для новачків.
- **02.11.2026** — носій став тижневою нагородою (`how.carrier` = «Weekly reward»).
- **03.11.2026** — воїни-ексклюзиви — з Boss Shop.
- **04.11.2026** — нотатку створено (була порожня).

> [!todo] Перенести
> Ця нотатка лежить у корені бази. Перетягни її в Obsidian у `Places/My Mining Golems/3D Models/Golems/Mushroom Golem/` (як інші големи) — посилання оновляться самі.
