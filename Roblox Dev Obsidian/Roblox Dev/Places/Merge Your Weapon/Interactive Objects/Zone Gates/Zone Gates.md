---
tags: [interactive, gate]
status: in-game
updated: 2026-11-16
---

# Zone Gates

← [[Places/Merge Your Weapon/Interactive Objects/Interactive Objects|Interactive Objects]] · [[Places/Merge Your Weapon/World/World|World]]

Два види воріт: арка входу з лобі і ворота FIGHT між зонами.

## Арка ZONE 1 (спавн)
![[myw_zone_gate.jpg]]

| | |
| --- | --- |
| У грі | `Workspace/Spawn/ZoneGate` (Post ×2, TopBar, `EntrySquare`) |
| Що показує | «ZONE 1 · Recommend: Tier 1-4» (текст перекладається — `LocPatterns` «Recommend») |
| Що робить | прозора стіна-вхід у Zone 1; прохід вільний |

## Ворота FIGHT (між зонами)
![[myw_fight_gate.jpg]]

| | |
| --- | --- |
| У грі | `Zones/Zone<N>/Gates`: `PassageSign` + `NextZoneBlocker` (атрибут `OpensWhenCleared`) |
| Що показує | «FIGHT · CLEAR THE ZONE 0/5» — лічильник убитих мобів зони |
| Що робить | червона стіна, поки зона не зачищена; після зачистки відкривається тільки для цього гравця (`ZoneService`, зони свої в кожного) |
| Вигляд | `ReplicatedStorage/ZoneBlockerVisual` |
