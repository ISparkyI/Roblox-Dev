---
tags: [script, module, ui, sound]
status: active
updated: 2026-10-24
---

# UI Hover

← [[Scripts]]

> [!summary] Коротко
> Клієнтський ModuleScript: **один звук наведення на всі кнопки й картки в грі**. Кнопки підключаються **автоматично** (наявні й ті, що з'являться пізніше), тож для нової кнопки нічого додавати не треба. Звук лежить в одному місці, і змінюємо його тільки там.

- **Код:** `UIHover.lua` (у цій папці).
- **У Roblox:** модуль `ReplicatedStorage/Shared/UIHover`, звук `SoundService/ButtonHover` (`Sound`, тихий плаский UI-звук, гучність 0,05), LocalScript `StarterPlayerScripts/UIHoverAuto` викликає `UIHover.auto(PlayerGui)`.

## Правила
- **Кожна кнопка** (`TextButton` / `ImageButton`) у `PlayerGui` грає звук при вході мишки — автоматично.
- **Кожна картка** з власною анімацією наведення (де наведення ловить не кнопка, а звичайний `Frame`) має сама викликати `UIHover.play()` один раз при вході мишки **і** поставити на свій об'єкт атрибут `HoverSoundBy` (будь-яке значення), щоб автозвук кнопок не зіграв удруге.
- **Без звуку** — атрибут `NoHoverSound = true` на кнопці.
- Не-кнопку (наприклад, `Frame` з `MouseEnter`) озвучуємо через `UIHover.hook(об'єкт)`.
- Звук лише для миші; на тачі `MouseEnter` не спрацьовує, тож нічого додатково робити не треба.
- Мінімальний інтервал між звуками — 0,05 с (накладені кнопки не грають двічі).
- Інші звуки (клік, покупка) — окремо, цей модуль лише для наведення.

## API
```lua
local UIHover = require(game:GetService("ReplicatedStorage").Shared.UIHover)

UIHover.play()              -- зіграти звук наведення вручну
UIHover.hook(guiObject)     -- звук на MouseEnter будь-якого GuiObject (один раз на об'єкт)
UIHover.auto(root)          -- усі кнопки всередині root, наявні й майбутні (викликає UIHoverAuto)
```

## Як підключити в новому плейсі
1. Скопіювати модуль у `ReplicatedStorage/Shared/UIHover`.
2. Покласти звук у `SoundService` з іменем `ButtonHover` (`SoundId` не порожній).
3. LocalScript у `StarterPlayerScripts`: `require(...UIHover).auto(Players.LocalPlayer:WaitForChild("PlayerGui"))`.

## Перевірка
У Studio перевірено, що модуль підключається без помилок і в `PlayerGui` хук отримують усі кнопки (37 шт. у HUD). На слух (один звук на вхід, картки без дубля, лічильники без звуку) перевіряє користувач.
