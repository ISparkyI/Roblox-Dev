---
tags: [plugin, studio, studs, surfaces]
status: installed
updated: 2026-10-22
---

# Resurface

← [[Plugins]]

> [!summary] Коротко
> Плагін Roblox Studio від **@cxmeel**, який повертає старий Surface Tool. Він накладає на деталі класичні поверхні Roblox: **Studs** (лего-пупочки), Inlet, Universal, Glue, Weld, Smooth. **Це наш основний інструмент для будь-якого «studs / лего / класичного Roblox» вигляду.** Власні PNG-текстури з пупочками не малюємо.

- Creator Store: <https://create.roblox.com/store/asset/5070921519>
- Вихідний код: <https://github.com/cxmeel/resurface-plugin>
- DevForum: <https://devforum.roblox.com/t/1226536>
- Встановлено в Studio: так (панель **Plugins → Resurface**).

## Коли використовувати
- Користувач просить «studs», «лего», «пупочки», «класичний Roblox-стиль», «текстуру в studs стилі».
- Треба зробити поверхні Inlet, Universal, Glue або Weld.
- Треба прибрати поверхні (Smooth / SmoothNoOutlines).

## Як він накладає поверхні
Плагін працює двома способами. Спосіб залежить від того, скільки граней обрано.

| Режим | Що робить з деталлю | Колір деталі | Підходить для |
| --- | --- | --- | --- |
| **Одна грань** (All Faces вимкнено) | Ставить `TopSurface`/`FrontSurface`/… = `Studs`. Якщо увімкнено **Set Plastic**, ставить `Material = Plastic`. | не змінюється | Part, WedgePart. На MeshPart і Union не працює. |
| **Усі грані + MaterialVariants** (налаштування за замовчуванням) | Скидає всі `*Surface` на `Smooth`, ставить `Material = Plastic` і `MaterialVariant = "Studs"`. Сам `MaterialVariant` створює в `MaterialService` (`StudsPerTile = 1`). | ColorMap множиться на `Color` деталі, тому колір лишається, а пупочки дають об'єм | Будь-які деталі, також MeshPart і Union |
| **Усі грані без MaterialVariants** | Ставить усі 6 `*Surface` = `Studs` | не змінюється | Тільки Part |

> [!important] Особливості
> - Класичні SurfaceType видно **лише на матеріалі Plastic**. Тому плагін змінює `Material` на `Plastic`, навіть якщо деталь була SmoothPlastic.
> - Розмір пупочки завжди **1 стад** (`StudsPerTile = 1`). Щоб вони були менші або більші, треба змінити `StudsPerTile` у MaterialVariant у `MaterialService`. Тоді це зміниться **для всіх деталей** з цим варіантом.
> - У плейсі вже є MaterialVariant **`Studs`** (`MaterialService/Studs`). Плагін бере існуючий варіант і не створює дублікат.

### Асети, які використовує плагін (MaterialVariants)
| Поверхня | ColorMap | NormalMap | StudsPerTile |
| --- | --- | --- | --- |
| Studs | `rbxassetid://10509831729` | `rbxassetid://10509831753` | 1 |
| Inlet | `rbxassetid://10509827175` | `rbxassetid://10509827228` | 1 |
| Universal | `rbxassetid://10509840768` | `rbxassetid://10509840812` | 2 |
| Glue | `rbxassetid://10509635556` | `rbxassetid://10509645465` | 1 |
| Weld | `rbxassetid://10509843977` | `rbxassetid://10509844001` | 2 |

## Як користуватися (вручну)
1. **Plugins → Resurface**: плагін активується, зверху в в'юпорті з'являється панель.
2. На панелі: **поверхня** (за замовчуванням Studs), **All Faces**, **Set Plastic**, ⚙ налаштування. Під нею кнопки **MaterialVariants** і **Selection**.
3. Вибір поверхні: клік по назві або клавіша **B** відкриває Surface Picker (сітка або список, є пошук).
4. Нанести:
   - **на одну грань**: вимкни All Faces і клікни по грані деталі;
   - **на всі грані однієї деталі**: увімкни All Faces і клікни по деталі. Утримуючи **Ctrl**, можна тимчасово перемкнути All Faces;
   - **на всю модель або виділення**: виділи модель, папку чи деталі в Explorer і натисни **Selection** (з'являється при All Faces). Плагін пройде всі BasePart усередині.
5. **Esc** закриває пікер, а повторний Esc вимикає плагін.
6. Усе записується в історію змін, тому **Ctrl+Z** відміняє.

Налаштування (⚙): Use MaterialVariants, Force MaterialVariants for Meshes and Unions, Set to Plastic, Close After Operation, Classic Menu on Launch, Auto-focus Search, Bounce Animations, Reduce Motion, Reduce Transparency. Гарячу клавішу можна задати в *File → Advanced → Customize Shortcuts → «Surface Tool (Action)»*.

## Як Claude застосовує Resurface через MCP
Кнопки плагіна з `execute_luau` натиснути не можна. Тому Claude повторює **ту саму логіку**, що й `ResurfaceApi.apply` з вихідного коду плагіна, з тими самими асетами. Результат такий самий, як після кліку **Selection** у плагіні з налаштуваннями за замовчуванням, і його можна відмінити через Ctrl+Z.

```lua
-- Resurface: Studs на всі грані (як кнопка "Selection" з MaterialVariants = on)
local CHS = game:GetService("ChangeHistoryService")
local MS = game:GetService("MaterialService")
local target = workspace.MyModel -- що обробляємо (Model / Folder / BasePart)
local SKIP = {} -- імена деталей без пупочок, напр. { EyeWhite = true }

local mv
for _, v in MS:GetDescendants() do
	if v:IsA("MaterialVariant") and v.ColorMap == "rbxassetid://10509831729" and v.StudsPerTile == 1 then mv = v break end
end
if not mv then
	mv = Instance.new("MaterialVariant"); mv.Name = "Studs"; mv.BaseMaterial = Enum.Material.Plastic
	mv.ColorMap = "rbxassetid://10509831729"; mv.NormalMap = "rbxassetid://10509831753"; mv.StudsPerTile = 1
	mv.Parent = MS
end

local rec = CHS:TryBeginRecording("Resurface: Studs")
local parts = if target:IsA("BasePart") then { target } else target:GetDescendants()
for _, p in parts do
	if p:IsA("BasePart") and not SKIP[p.Name] then
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = mv.Name
		for _, s in { "Top", "Bottom", "Left", "Right", "Front", "Back" } do p[s .. "Surface"] = Enum.SurfaceType.Smooth end
	end
end
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
```

Для пупочок тільки зверху, як у справжньої лего-цеглинки, використовуй режим «одна грань»: `p.Material = Plastic`, `p.TopSurface = Enum.SurfaceType.Studs`. Для пазів знизу додай `p.BottomSurface = Enum.SurfaceType.Inlet`.

## Тонкі studs (прозоріші й дрібніші)
`MaterialVariant` не має прозорості, а `StudsPerTile` у ньому один на всі деталі. Тому, коли studs треба зробити **слабшими** або **дрібнішими** на конкретній моделі, ті самі асети Resurface накладаємо через `Texture` на кожну грань:

| Параметр | Значення | Що дає |
| --- | --- | --- |
| `ColorMapContent` | `rbxassetid://10509831729` | малюнок studs від Resurface |
| `NormalMapContent` | `rbxassetid://10509831753` | об'єм studs |
| `StudsPerTileU/V` | 1 = як у плагіна (стандарт для карт і великих поверхонь); 0.25 = у 4 рази дрібніше (стандарт для моделей) | розмір пупочки |
| `Transparency` | 0.2 = видно на 80% (стандарт); 0.75 = на 25% (слабко) | сила ефекту |
| `Color3` | = `Part.Color` | колір деталі не змінюється |
| `Part.Material` | `SmoothPlastic`, `MaterialVariant = ""` | рівна заливка за GDD |

```lua
for _, p in model:GetDescendants() do
	if p:IsA("BasePart") and not p.Name:find("Glint") then
		p.MaterialVariant = ""; p.Material = Enum.Material.SmoothPlastic
		for _, face in Enum.NormalId:GetEnumItems() do
			local t = Instance.new("Texture"); t.Name = "Studs"; t.Face = face
			t.ColorMapContent = Content.fromUri("rbxassetid://10509831729")
			t.NormalMapContent = Content.fromUri("rbxassetid://10509831753")
			t.StudsPerTileU = 0.25; t.StudsPerTileV = 0.25
			t.Transparency = 0.2; t.Color3 = p.Color
			t.Parent = p
		end
	end
end
```

Це наш **стиль studs за замовчуванням** для моделей у блоковому стилі: видно на 80% (`Transparency 0.2`), у 4 рази дрібніше (`StudsPerTile 0.25`). Без studs лишаються деталі обличчя та блиски.

## Клітчата варіація studs

> [!tip] Коли користувач каже «клітчата studs-текстура», «клітчаті стюдси», «як на підлозі в клітинку» — робимо саме так.

Пупочки дає сам матеріал (MaterialVariant від Resurface), а **поверх лежить напівпрозора чорна клітинка**, яка ділить поверхню на великі квадрати. Виглядає як плитка з пупочками, але це **одна деталь без швів**.

![[checker_studs_floor.png]]

| Що | Значення |
| --- | --- |
| `Part.Material` | `Plastic` |
| `Part.MaterialVariant` | `Universal` (дрібні квадратні пупочки, `StudsPerTile 2`) або `Studs` (круглі, `StudsPerTile 1`) — обидва з `MaterialService` |
| `Part.Color` | колір зони (наприклад, світлий сіро-блакитний `#9fa1ac`, землистий `#71675a`) |
| `Texture.Face` | `Top` (або та грань, яку видно) |
| `Texture.ColorMapContent` / `Texture` | `rbxassetid://6372755229` — клітинка (асет, який обрав користувач) |
| `Texture.Color3` | `#000000` |
| `Texture.Transparency` | `0.9` (клітинка ледь помітна, темніша за основу на 10%) |
| `Texture.StudsPerTileU/V` | `8` (клітинка 8 × 8 стадів) |

```lua
-- клітчата варіація studs на деталі p
p.Material = Enum.Material.Plastic
p.MaterialVariant = "Universal" -- або "Studs"
for _, t in p:GetChildren() do if t:IsA("Texture") then t:Destroy() end end
local t = Instance.new("Texture")
t.Face = Enum.NormalId.Top
t.Texture = "rbxassetid://6372755229"
t.Color3 = Color3.new(0, 0, 0)
t.Transparency = 0.9
t.StudsPerTileU, t.StudsPerTileV = 8, 8
t.Parent = p
```

- Асет клітинки `6372755229` обрав користувач. Claude використовує саме його і **не шукає** інших у Creator Store (див. правила безпеки).
- Наші `Texture` зі studs (видно на 80%) на таких деталях **не потрібні**: пупочки вже є в MaterialVariant.
- Розмір клітинки міняємо через `StudsPerTile` текстури (4 — дрібніше, 16 — крупніше), силу — через `Transparency`.

## Досвід і рішення
- **2026-10-22.** Claude спершу намалював власну PNG-текстуру пупочки (`lego_stud.png`, asset `113154723835043`). Підхід **відхилено**: для studs-стилю використовуємо Resurface.
- Для дрібних деталей обличчя (очі, зіниці, брови, рот, щічки) пупочки не ставимо, бо обличчя втрачає читабельність.
