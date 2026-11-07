---
tags:
  - gdd
  - art-style
  - ui
  - icons
  - prompts
status: active
updated: 2026-11-06
---

# GDD: Промпт для генерації іконок

← [[Style]] · [[GDD - 2D іконки]] · [[GDD - Блики іконок]]

> [!summary] Навіщо
> Універсальний промпт для Nano Banana (Gemini), який дає іконки в нашому стилі: плоский вектор, товстий чорний контур, 2–3 тони на матеріал, гострі геометричні блики, без м'яких тіней. Перевірено на іконці боса — шолом з рогами (`Style/Roblox/boss_helmet_256_v2.png`, `rbxassetid://137113714883300`).

## Як користуватися

1. Скопіюй промпт нижче.
2. Заміни `[назва вашого предмета]` на предмет **англійською** з коротким описом деталей (матеріал, форма, 1–2 ключові елементи).
3. Генеруй. Фон буде чистим зеленим — модель не вміє PNG з прозорістю.
4. Скинь картинку Claude: він прибере зелений фон (разом із зеленою облямівкою на краях), обріже по силуету, зробить PNG 256×256 і, якщо треба, товщу обводку, завантажить у Roblox через Asset Manager і поставить ID у гру.

## Універсальний промпт

```
Flat vector game icon of [назва вашого предмета], for a casual Roblox game. Clean, simple, sticker-like vector illustration — not a 3D render. Front view, perfectly centered and symmetrical, fills ~85% of the canvas. Rendering style: completely flat vector shapes with only 2–3 tones per material — one bright base color, and one simple hard-edged lighter shape as a sharp, elongated geometric highlight that fits perfectly along the edges and ridges where the light hits. No gradients, no soft shading, no volumetric shadows, no glossy reflections, no texture, no realistic lighting. Thick uniform black outline (~6% of icon width) around the whole silhouette and slightly thinner inner lines for structural details. Shapes are bold, smooth and slightly rounded, like a clean mobile-game vector icon. Background: solid flat pure chroma-key green (#00FF00), perfectly uniform. No frame, crisp edges, the silhouette must read clearly at 64x64 px.
```

## Приклад: банка джему

```
Flat vector game icon of a chunky glass jar of red strawberry jam with a simple screw lid, for a casual Roblox game. Clean, simple, sticker-like vector illustration — not a 3D render. Front view, perfectly centered and symmetrical, fills ~85% of the canvas. Rendering style: completely flat vector shapes with only 2–3 tones per material — one bright base color, and one simple hard-edged lighter shape as a sharp, elongated geometric highlight that fits perfectly along the edges and ridges where the light hits. No gradients, no soft shading, no volumetric shadows, no glossy reflections, no texture, no realistic lighting. Thick uniform black outline (~6% of icon width) around the whole silhouette and slightly thinner inner lines for structural details. Shapes are bold, smooth and slightly rounded, like a clean mobile-game vector icon. Background: solid flat pure chroma-key green (#00FF00), perfectly uniform. No frame, crisp edges, the silhouette must read clearly at 64x64 px.
```

## Чому працює

| Фраза | Що дає |
|---|---|
| `casual Roblox game`, `mobile-game vector icon` | спрощений «ігровий» тон |
| `sharp, elongated geometric highlight … along the edges` | довгі гострі блики вздовж граней (див. [[GDD - Блики іконок]]) |
| `no volumetric shadows`, `no gradients` | без брудних м'яких тіней і переливів |
| `Thick uniform black outline (~6%)` | наш товстий контур, читається на 64 px |
| `pure chroma-key green (#00FF00)` | чисте тло — легко вирізати |

## Поради

- **У предметі не має бути зеленого** (або має бути інший відтінок, не `#00FF00`) — інакше він виріжеться разом із фоном. Для зелених предметів можна попросити фон `pure magenta (#FF00FF)`.
- Якщо модель малює зайві деталі, додай у кінець: `No tiny details, no scratches, no text.`
- Якщо силует виходить «круглим і милим», а треба грізніше — опиши форму прямо: `angular`, `sharp edges`, `heavy`.
- Генератори погано розуміють «без X» — краще описати, **що є** (наприклад, «the lowest thing in the picture is …»), ніж «no …».
- Для фіксованих кольорів додай рядок `Colors: …` з hex-кодами.
