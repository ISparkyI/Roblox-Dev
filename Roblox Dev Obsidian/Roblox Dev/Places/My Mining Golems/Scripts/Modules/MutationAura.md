---
tags: [script, module, golems, vfx]
status: in-game
updated: 2026-10-27
---

# MutationAura

← [[My Mining Golems - Modules|Modules]]

`ReplicatedStorage/Shared/MutationAura` (ModuleScript, лише клієнт). Копія коду — `MutationAura.lua` у цій папці. Вмикає його `StarterPlayerScripts/MutationAuraClient` (копія — `Scripts/Client/MutationAuraClient.lua`). Опис для гравця — [GDD - Golems](obsidian://open?vault=Roblox%20Dev&file=Places%2FMy%20Mining%20Golems%2FGDD%2FGDD%20-%20Golems), розділ «Ефекти мутацій (аури)».

**Версія v5** (27.10.2026): комети лише в Secret; Secret — чорно-біла (шлейф білий → графіт, майже чорні ромбики з білою гранню, темні осколки на орбіті, рідкі білі зірки-спалахи); Silver — світле срібло з блакитним (`SILVER_MAIN` cfdbe8 / `SILVER_LIGHT` f4f8ff, лише в аурі). Бекапи: v4-A — `ServerStorage/NicheBackup/MutationAura_v4`; v2 — `MutationAura_v3`; v1 — `MutationAura_v2_glow`.

## API
- `apply(model, mut, opts?)` — аура на модель голема (`Root` або `PrimaryPart`). `opts.scale` — масштаб (1 = голем ≈ 7 стадів); без нього — атрибут `AuraScale` (підставка ролу) або висота рамки / 7. Мала модель (фігурка) — менше й рідше (Rate × clamp(scale, 0,35, 1), не більше 3 комет).
- `clear(model)`, `count()`; таблиця `TEX` (ID текстур).
- Хто ставить `Mut`: `PlotService`, `HeldItemService`, `CaveStandService`, `RollRevealClient` (+ `AuraScale`). Слоти інвентаря — ViewportFrame поза workspace, без аур.

## Як влаштовано
- На голема — одна невидима заякорена деталь-якір у `Workspace/MutationAuraFx` (поза моделлю). Її розмір — циліндр навколо тіла: на ній два ParticleEmitter:
  - **Sparks** — 4-променева зірочка з темним контуром, Shape Cylinder Surface, Speed 0, Size 0→S→0, LightEmission 0; Rate (5 + 1,2k) × 1,3 (Secret 9 × 1,3), Size 0,9 (Secret 0,7).
  - **Embers** — двотонний ромбик (Secret — графітовий з білою гранню), Shape Cylinder Volume, Acceleration +Y, Lifetime 2,4–3; Rate (9 + 2k) × 0,45 (Secret 16 × 0,45). (k = 0 Bronze … 6 Secret.)
- **Комети** (лише Secret, 5; фігурка — 3): кулі-деталі (Ball, Neon — єдине світіння) у якорі; у кожній два Attachment і **Trail** (FaceCamera, Color білий → графіт, LightEmission 0, WidthScale 1→0). Шлейф фізично лишається позаду (перевірено в Play). Орбіти: нижня (радіус R, 0,47 висоти, нахил 0,14, 1,6 рад/с) і верхня (0,86 R, 0,79 висоти, нахил −0,12, −1,9 рад/с).
- **Secret, додатково:** `Shards` — темні ромбики (rhombDark), Shape Cylinder Surface, LockedToPart, Lifetime 4–5, Rate 2,4; якір Secret обертається (`SPIN_SECRET` 0,6 рад/с), тож осколки кружляють. `Flash` — велика біла зірочка, `Emit(1)` раз на 1,6–2,6 с.
- Один спільний `Heartbeat`: `BulkMoveTo` якорів і куль-комет; Rainbow — перелив 15 разів/с.
- **LOD:** далі 80 стадів — емітери й шлейфи вимкнені, кулі сховані. Понад 10 аур поруч — Rate × 10 / N (не нижче 40 %).

## Текстури (mg_aura4_*, власні, alpha bleed)
Ескізи — папка `MutationAura/Textures_v4`.

| Текстура | Image ID | Decal |
| --- | --- | --- |
| star (зірочка з контуром) | 89825351264086 | 103251156230517 |
| rhomb (ромбик два тони) | 71794116629222 | 115208808634761 |
| rhombDark (графітовий ромбик, Secret) | 115218568152883 | 90992627698278 |
| trail (смуга шлейфу) | 121383551573029 | 112671822166899 |
| comet (куля з ореолом, запас — у грі голова = Neon-куля) | 85324709623968 | 104697808668305 |

**Застарілі, не використовуються:** текстури v2 `mg_aura_*` (полум'я, дим, куля, руна, блискавка тощо; ID 133166392991012, 70746809773001, 74802224190918, 138051345792444, 84475070868000, 118138572048247, 123688810849058, 86471549008180, 76514429458980, 100414004940083, 92078405716091), папки `MutationAura/Textures` і `MutationAura/Preview` (скріни v2), а також `fx_*.png` v1.

## Скріни v5 (27.10.2026)
![[aura_v5_overview.jpg]]
![[aura_v5_secret_vs_silver.jpg]]
![[aura_v5_held_secret.jpg]]
![[aura_v5_roll_bronze.jpg]]

## v5.1 (27.10.2026): баг «частинки літають по карті»
Причина: розмір аури брався з `Model:GetBoundingBox()` у момент появи моделі. У щойно створеного носія на плоті (реплікація / ящичок ще не на місці) рамка була ≈ 625 стадів завширшки — циліндр-емітер іскор і ромбиків накривав пів карти, і поодинокі частинки з'являлись будь-де (біля SELL, у ніші, біля камери; Rainbow-ромби — зелені). Виправлення: рамка рахується лише з видимих деталей у межах 12 стадів від Root (`nearBounds`), висота ≤ 24, радіус 0,6–0,8 висоти. Перевірено в Play (плот, фігурка в руці, 3 роли): усі якорі 1,6–7 стадів. Бекап v5 — `ServerStorage/NicheBackup/MutationAura_v5`. Копія — хеш 762247444, 17 054 байти.
