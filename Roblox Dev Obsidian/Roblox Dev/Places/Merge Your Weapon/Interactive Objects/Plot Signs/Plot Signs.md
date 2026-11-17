---
tags: [interactive, plot]
status: in-game
updated: 2026-11-16
---

# Plot Signs

← [[Places/Merge Your Weapon/Interactive Objects/Interactive Objects|Interactive Objects]] · [[Places/Merge Your Weapon/Interactive Objects/Plots/Plots|Plots]]

Таблички на кожному плоті (поставлені в редакторі). Реагує лише кнопка на табличці. Сервер — `PlotStandService`, вигляд — `PlotStandController`.

![[myw_group_stand.jpg]]

| Табличка | Де | Що робить |
| --- | --- | --- |
| `AutoBuyStand` | ліва стіна плоту | AUTO BUY ON / OFF — автоматично купує зброю (потрібен геймпас Auto Buy) |
| `AutoMergeStand` | ліва стіна плоту | AUTO MERGE ON / OFF — сам мерджить однакову зброю (геймпас Auto Merge) |
| `GroupStand` | біля входу на плот | приєднатися до групи → нагорода (`GroupConfig`, стандартне вікно Roblox `GroupPromptController`) |

Над табличками — 3D-іконка, що крутиться. На кожен плот — свій `PlotNAutoBuyStand` / `AutoMergeStand` / `GroupStand` у PlayerGui (SurfaceGui).
