---
tags: [gdd, place, golems, data]
status: active
updated: 2026-10-28
---

# GDD - Golem UID

← [[My Mining Golems - GDD|GDD]]

Унікальний ID кожного голема і захист від дюпу (етап 1).

## UID
- 26 символів, ULID (Crockford base32): 48 біт часу в мс + 80 випадкових біт. З UID видно час створення (`TimeOf`).
- **Створюється** лише при: купівлі з ролу (`roll`), коді (`code:<код>`), видачі адміном.
- **Знищується** (`Burn`) лише при справжньому видаленні голема.
- **Зберігається** при переміщенні: інвентар ↔ плот ↔ печера, передача.

## Анти-дюп (етап 1)
- При завантаженні: `Ensure` (старим големам без UID видається UID) і `Dedupe` (той самий UID в інвентарі й печері — лишається один).
- Глобальний індекс DataStore `GolemIndex` — лише големи з мутацією ≥ 5 і видані адміном: хто власник. `CheckOwnership` ловить копії між гравцями.
- Журнал DataStore `GolemLog` — денні пакети подій (mint, burn, move).
- Пошук за UID — вкладка GOLEMS в [[GDD - Admin Panel]].

## Далі
- [ ] Етап 2: трейди / маркетплейс через `Move` з перевіркою індексу.

**Скрипти:** `GolemRegistry.lua` (API: `NewUid`, `IsUid`, `TimeOf`, `Mint`, `Ensure`, `Burn`, `Move`, `Lookup`, `Log`, `RecentLogs`, `Dedupe`, `CheckOwnership`), `InventoryService.lua` (`AddGolem(...) → ok, uid`, `FindByUid`, `RemoveByUid`), `CaveStandService.lua` (`FindByUid`, `RemoveByUid`).
