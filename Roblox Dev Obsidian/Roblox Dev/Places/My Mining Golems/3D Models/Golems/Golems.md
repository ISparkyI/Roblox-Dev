# Golems

← [[My Mining Golems - 3D Models|3D Models]]

Клас персонажів-големів. Кожен голем — окрема модель зі своїм скелетом і анімаціями.

- [[Stone Golem]] — кам'яний голем (v2, основний персонаж)
- [[Wooden Golem]] — дерев'яний голем (перший голем гравця; колишній Forest Golem), у грі як `WoodenGolem`
- [[Clay Golem]] — глиняний голем (Common, рол 1 до 15), у грі як `ClayGolem`
- [[Gravel Golem]] — гравійний голем (Common, рол 1 до 25, легкий і швидкий), у грі як `GravelGolem`
- [[Mossback Golem]] — мохоспин (Common, рол 1 до 40, моховий горб, сонний), у грі як `MossbackGolem`
- [[Copperhead Golem]] — мідноголовий (Uncommon, рол 1 до 75, перший металевий), у грі як `CopperheadGolem`
- [[Flint Golem]] — кремінний (Uncommon, рол 1 до 120, найшвидший на мапі 1), у грі як `FlintGolem`
- [[Rustbolt Golem]] — іржавий болт (Uncommon, рол 1 до 200, важкий, великі кулаки), у грі як `RustboltGolem`
- [[Granite Golem]] — гранітний вартовий (Uncommon, рол 1 до 300, статуя з вкрапленнями), у грі як `GraniteGolem`
- [[Lantern Golem]] — шахтарський ліхтар (Uncommon, рол 1 до 500, світні деталі Neon, кірка й меч з ліхтарями), у грі як `LanternGolem`

**Генератори:** `golemgen.py` у цій папці — спільний модуль (скелет Clay, перевірка правила 0,1, експорт `GolemData`, базові хвати кірки й меча); з Copperhead генератори големів його імпортують. У Studio з Granite големів збирає модуль `ServerStorage/NicheTools/GolemBuilder` (`build(name, kind, x, src, boxCols)`); з Lantern він підтримує `neon = {колір = true}` у `GolemData` — такі деталі будуються з Material Neon.

**Шаблон:** [[Golem Reference GDD]] — універсальний GDD референс-картки й анімацій для будь-якого голема.
