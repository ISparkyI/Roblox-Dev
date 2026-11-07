# Trailer

← [[My Mining Golems - Scripts|Scripts]]

Трейлер гри (запис 07.11.2026): скрипти, щоб відтворити його 1 в 1.

Трейлер ~33 с, 16:9, 7 кадрів. Працює **лише в Studio** і лише коли `workspace.TrailerMode = true`; у живій грі скрипти одразу виходять.
Після запису все прибрано з гри — тут лежить усе потрібне, щоб повернути.

## Файли
| Файл | Куди в Studio | Тип |
|---|---|---|
| `TrailerDirector.lua` | StarterPlayer/StarterPlayerScripts/**TrailerDirector** | LocalScript |
| `gen_TrailerBoss.lua` | запустити в командному рядку (Edit) — створить ModuleScript **TrailerBoss** всередині TrailerDirector (копія анімацій/VFX боса з BossArenaClient) | скрипт для командного рядка |
| `TrailerServer.lua` | ServerScriptService/**TrailerServer** | Script |
| `patch_GolemAnimRunner.lua` | запустити в командному рядку (Edit) — латка Shared/GolemAnimRunner (големи трейлера анімуються щокадру); бекап сам кладе в NicheBackup | скрипт для командного рядка |
| `ThumbTools.lua` (у [[My Mining Golems - Modules|Modules]]) | ServerStorage/**ThumbTools** (ModuleScript) — TrailerServer бере з нього Bacon (`T.bacon`) | ModuleScript |

Також потрібно: `Workspace/ThumbStudio/Bacon/FacePlate` (шоковане обличчя Bacon) — лежить на полігоні превʼю. Якщо полігону немає — Bacon буде без шоку (лише Smile).

## Порядок
1. Вставити TrailerServer, TrailerDirector (Source = файл), ThumbTools.
2. Командний рядок: `gen_TrailerBoss.lua`, потім `patch_GolemAnimRunner.lua`.
3. Workspace → атрибут `TrailerMode` (bool) = true.
4. Play → F6 (весь трейлер: ~10–15 с чорний прогрів, 3-2-1, кадри), 1…7 — окремий кадр, F8 — стоп.

## Кадри
1. **Рол (6 с)** — Bacon тягне ричаг, 6 фейків на стенді (сповільнення), спалах, Secret-Аурелиан, Bacon розвертається й стрибає.
2. **Шахтарі (4 с)** — головний шахтар біля камери (звук кірки на кожен удар), відліт над 6 плотами Stage1.
3. **Носильщики (3 с)** — 6 carrier-ів ідуть на камеру, гроші +$K.
4. **Світи (3,9 с)** — безперервний проліт: Crystal → Frozen → Void (ніші підміняються під камерою).
5. **Мутація (5,2 с)** — 3 Ruby заходять у Machine1 (лобі), спалах, виходить Void-Ruby.
6. **Бос (7 с)** — 24 воїни біжать по дузі й оточують Gobking, удари (−K), Slam, смерть, лут +$2.4T.
7. **Фінал (4,5 с)** — Bacon застрибує, 44 воїни шеренгами, кран угору.

## Звуки
Лише ігрові: SoundService (LeverPull, ButtonHover, ClaimReward, BuySound, PurchaseSuccess, SellSound), BossSfx, MutationSfx, PlotAssets/PickaxeHit.
`SFX_MASTER = 0.45` (ефекти фоном), `MUSIC_BOOST = 1.8` (музика гри голосніше) — на початку TrailerDirector.

## Що створюється в Play (саме прибирається після Stop)
Workspace/TrailerSets (копії Stage1..6 + BossArena на +9000 X), Workspace/TrailerLive, TrailerFx, ReplicatedStorage/TrailerAssets.
