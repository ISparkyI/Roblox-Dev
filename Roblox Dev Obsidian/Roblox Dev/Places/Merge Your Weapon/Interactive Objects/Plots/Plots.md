---
tags: [interactive, plot]
status: in-game
updated: 2026-11-14
---

# Plots

← [[Places/Merge Your Weapon/Interactive Objects/Interactive Objects|Interactive Objects]]

6 плотів на спавні (`Workspace/Spawn/Plots/Plot1..6`). Плот видається гравцю при вході (`PlotService`), атрибут гравця `PlotId`.

## Що на плоті
- **Поле** (`Base/Field`) — тут лежить зброя (`Plot<N>/Weapons`), текстура Textures.
- **Табличка** над плотом: аватар + «Name's Base» одним текстом (два окремих розходились зблизька).
- **Стенди** — Weapon Stands; кути — Watchtower.
- **Слоти:** `PlotSlots` = 20 + апгрейди +Slots.

## Механіка (PlotWeaponService, WeaponClient)
- **Підбір дотиком** (радіус 2.6), без E і без затримок. Зброя в руках — над головою, руки вгору.
- **Мердж:** торкнувся такої ж зброї — обидві злітаються, з'являється тір +1 (апгрейд Lucky Merge — шанс +2).
- Щойно створену / кинуту зброю не підбереш, поки не відійдеш на **4 стади**.
- **DROP** (Q / кнопка) — кладе зброю там, де стоїш.
- **BUY WEAPON** — зброя тіру `BuyTier` за кеш (палиці безкоштовні).
- Швидкість на своєму плоті ÷1.5 (`MovementService`).
