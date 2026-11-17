---
tags: [ui]
status: in-game
updated: 2026-11-16
---

# Settings Window

← [[Merge Your Weapon - 2D|2D]]

![[myw_settingswindow_ingame.jpg]]
*Скрін з гри. Налаштування зберігаються (`SettingsService`, атрибути `Set_*`).*

Вікно **SETTINGS** (`SettingsController`). Перемикачі:

| Перемикач | Що робить |
| --- | --- |
| MUSIC | глушить музику (звуки з атрибутом `IsMusic`, ставить `LobbyMusicPlayer`) |
| SOUND EFFECTS | глушить решту звуків |
| WEAPON NAMES | атрибут `HideWeaponNames` — ховає таблички «Name · Tier N» |
| LOW FX | атрибут `LowFX` — менше ефектів |
