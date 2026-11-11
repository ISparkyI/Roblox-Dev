# Трейлер v3 — як відновити в грі

11.11.2026 трейлер прибрали з гри перед публікацією. Усе потрібне, щоб зібрати його знову, лежить у цій папці (`Scripts\Trailer\`). Що змінювалось у самому трейлері — у `Trailer v3 - зміни 11.11.2026.md`.

## Файли

| Файл | Куди в Studio | Що це |
|---|---|---|
| `TrailerDirector.lua` | `StarterPlayer/StarterPlayerScripts/TrailerDirector` (LocalScript) | режисер: 9 кадрів, камера, підписи, F6 / 1…9 / F8 |
| `TrailerServer.lua` | `ServerScriptService/TrailerServer` (Script) | будує `Workspace/TrailerSets` (6 мап, арена боса, CaveSet) і `ReplicatedStorage/TrailerAssets` |
| `gen_TrailerBoss.lua` | виконати в командному рядку Studio | генерує ModuleScript `TrailerDirector/TrailerBoss` з `BossArenaClient` |
| `GolemAnimRunner_trailer.lua` | `ReplicatedStorage/Shared/GolemAnimRunner` | версія з трейлерним режимом (големи `Workspace/TrailerLive` щокадру, без бюджету) |
| `patch_GolemAnimRunner.lua` | командний рядок Studio | те саме, але як латка поверх поточного `GolemAnimRunner` |
| `MapBoard_trailer.lua` | `StarterPlayer/StarterPlayerScripts/MapBoard` | версія з блоком `TRAILER HOOK` (`_G.TrailerMapBoard`): табло NEXT MAP на кожній мапі кадру 4 |

## Порядок відновлення (у режимі Edit)

1. Зберегти поточні `GolemAnimRunner` і `MapBoard` у `ServerStorage/NicheBackup` (щоб потім повернути).
2. Вставити `TrailerServer` і `TrailerDirector`. Великі файли — через `StudioService:PromptImportFiles({"lua"})` у `task.spawn`, читати `file:GetBinaryContents()`.
3. Виконати `gen_TrailerBoss.lua` — з'явиться `TrailerDirector/TrailerBoss`. Якщо `BossArenaClient` змінився і маркер не знайдено, assert скаже який.
4. `GolemAnimRunner`: або вставити `GolemAnimRunner_trailer.lua` цілком (якщо скрипт відтоді не мінявся), або виконати `patch_GolemAnimRunner.lua`.
5. `MapBoard`: перенести блок `TRAILER HOOK` з `MapBoard_trailer.lua` перед рядком `local panels = {} -- [niche] = pn`.
6. Шок-обличчя Bacon: скопіювати `Workspace/ThumbStudio/Bacon/FacePlate` у `ServerStorage` під назвою `TrailerFacePlate` (NicheBoot прибирає `ThumbStudio` на старті гри).
7. Атрибут `workspace:SetAttribute("TrailerMode", true)`.
8. Play → F6 — увесь трейлер, 1…9 — один кадр, F8 — стоп. Порядок кадрів: 1 2 3 4 5 8 9 6 7.

## Запис

OBS: записувати **вікно Roblox Studio** («Захоплення вікна»), а не весь екран — тоді підсвітка й інші вікна в кадр не потрапляють. Мікрофон вимкнений (Налаштування → Аудіо). Вікно гри розгорнути на весь екран перед F6.

## Після запису прибрати

`TrailerServer`, `TrailerDirector`, `ServerStorage/TrailerFacePlate`, атрибут `TrailerMode`; повернути `GolemAnimRunner` і `MapBoard` з копій.
