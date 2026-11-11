# Трейлер v3 — зміни 11.11.2026

Доповнення до `My Mining Golems - Trailer.md`. Старі версії скриптів — у `old_0711/`.

## Як запустити

1. У Studio (Edit): `workspace.TrailerMode = true`, скрипти `ServerScriptService/TrailerServer` і `StarterPlayerScripts/TrailerDirector` (з дочірнім `TrailerBoss`) на місці.
2. Play → **F6** — повний трейлер (прогрів на чорному, 3-2-1, далі кадри). **F7** — лише підготовка, **1…9** — один кадр, **F8** — стоп.
3. Порядок кадрів: 1 Roll → 2 Mine → 3 Earn → 4 Worlds → 5 Mutation → 8 Cave → 9 Market → 6 Boss → 7 Victory.

## Кадри й підписи

| № | Кадр | Підпис | Тривалість |
|---|---|---|---|
| 1 | Рол (новий важіль) | ROLL RARE GOLEMS | як було |
| 2 | Шахтарі | MINE ORE | як було |
| 3 | Носії | EARN MONEY | як було |
| 4 | Проліт мапами 3 → 5 → 6 | UNLOCK NEW WORLDS | 3,9 с |
| 5 | Мутація | MUTATE YOUR GOLEMS | ≈ 7 с |
| 8 | Cave стенди | SAVE YOUR BEST GOLEMS | 4,6 с |
| 9 | Marketplace | TRADE GOLEMS | 4,2 с |
| 6 | Бос | DEFEAT BOSSES | 6,0 с |
| 7 | Фінал | BUILD YOUR ARMY | 4,5 с |

Підписи: шрифт Luckiest Guy, жовто-помаранчевий перелив, темна обводка; поява 0,4 с, зникнення 0,4 с перед кінцем кадру.

## Що змінено

- **Кадр 5 (мутація):** готовий райдужний голем виходить із машини з іскрами, спалахом і написом «RAINBOW!»; камера переходить на крупний план виходу.
- **Кадр 4 (світи):** табло «NEXT MAP» на кожній мапі показує свою мапу (множник, назва наступної мапи, кнопка MAP N). Будує `MapBoard` через `_G.TrailerMapBoard(model, stage)` — гачок у кінці `StarterPlayerScripts/MapBoard`, працює лише в Studio.
- **Кадр 6 (бос):** 6 секунд. Армія вбігає (до 1,5 с) → бос б'є кулаком (1,85 с) → останній ряд із 8 големів застрибує на боса (2,15–3,4 с) → останній удар, бос падає (3,45 с) → нагорода (5,7 с). Камера: низько за армією → повз неї до боса → збоку на стрибки → відліт угору. Константи на початку блоку кадру: `JUMP0`, `JUMP_GAP`, `JUMP_LEN`, `FALL_T`.
- **Арена боса:** `ServerStorage/BossArenas/Arena_GolemGoblin` зсунули на (-4000, 0, -4000). `TrailerServer` копіює атрибут `MovedBy`, режисер додає його до центру арени.
- **Кадри 8 і 9:** нові (Cave зі стендами з `ServerStorage/CaveInsideTemplate` → `TrailerSets/CaveSet`; Marketplace у `Workspace.Cave.Hub.Marketplace`).
- Свій персонаж і всі ігрові вікна (зокрема `RollRolePanel`) ховаються щокадру, поки трейлер активний.
- Шок-обличчя Bacon: запасна пластина `ServerStorage/TrailerFacePlate`.

## Прибрати після запису

- `workspace.TrailerMode` (атрибут / значення).
- `ServerScriptService/TrailerServer`, `StarterPlayerScripts/TrailerDirector`.
- `ReplicatedStorage/Shared/GolemAnimRunner` ← відновити з `ServerStorage/NicheBackup/GolemAnimRunner_pre_trailer`.
- `StarterPlayerScripts/MapBoard` ← відновити з `ServerStorage/NicheBackup/MapBoard_pre_trailer` (прибрати блок TRAILER HOOK).
- `ServerStorage/TrailerFacePlate`.

## Як занести великий скрипт у Studio без вставки тексту

Покласти файл у сховище, у командному рядку Studio виконати `StudioService:PromptImportFiles({"lua"})` у `task.spawn`, вибрати файл і прочитати `file:GetBinaryContents()`.
