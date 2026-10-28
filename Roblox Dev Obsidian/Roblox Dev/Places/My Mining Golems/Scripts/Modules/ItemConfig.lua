--!strict
-- ItemConfig — предмети інвентаря гравця (спільний для сервера й клієнта): руда й злитки (з ForgeConfig), зілля, големи, іконки.
-- Де: ReplicatedStorage/Shared/ItemConfig. Інвентар — 2D/Inventory (GDD 22). Іконки — власні PNG (2D/Inventory/Roblox/Import, inv_*).
--
-- Ключі предметів (атрибути гравця й записи в хотбарі / замках):
--   Ore_<руда>, Bars_<руда> — кількість (атрибут гравця, стак);
--   Pot_<зілля>            — кількість (атрибут гравця, стак);
--   Golem_<id>             — один голем (не стакається), список — атрибут InvGolems (JSON: { { id, kind, cls, mut } }, cls = "miner" | "carrier",
--                            kind — ID з Shared/GolemCatalog, mut — мутація 0..7 (Normal … Secret)).
-- ЗІЛЛЯ ТА ГОЛЕМИ В ІНВЕНТАРІ ПОКИ ТЕСТОВІ: справжніх джерел ще немає (TEST_* нижче — лише в Studio). Ефекти зіль — пропозиція.

local RS = game:GetService("ReplicatedStorage")
local Forge = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog"))

local Config = {}

-- v11: іконки вікна інвентаря — з ЧОРНИМ контуром #14161a (було темно-синє #040435); PNG з alpha bleed — 2D/Inventory/Roblox/Import/inv_*_black.png.
-- Старі сині: tab 125478992512505 / 97817560625726 / 91234342811407, trash 79551145743198, class 115946913940598 / 87884014503341 /
-- 123455117137229 / 108036414056048, lock 122986621331664 (лишився в ключі lock — його беруть PlotPlaceUI та ін.; вікно інвентаря — lock_inv).
Config.ICONS = {
	tab_golems = "rbxassetid://132588280251317", -- Decal 87341965770671
	tab_orebars = "rbxassetid://82803716444486", -- Decal 126024652571602
	tab_potions = "rbxassetid://107838701777534", -- Decal 93090014428648
	trash = "rbxassetid://120989908152671", -- Decal 139733127224132
	lock = "rbxassetid://122986621331664", -- синій контур, спільний (PlotPlaceUI)
	lock_inv = "rbxassetid://112378939202920", -- чорний контур, лише вікно інвентаря; Decal 124530810095799
	-- іконки класів големів (фільтр і бейдж класу у вкладці Golems; чорний контур) — Decal 104042371086279 / 126226004587557 / 123113475648368 / 109371183196293
	class_all = "rbxassetid://133379840933307",
	class_miner = "rbxassetid://132282696885007",
	class_carrier = "rbxassetid://113998728310073",
	class_warrior = "rbxassetid://80087764058950",
}
-- іконки руди й злитків — ті самі, що у вікнах Forge / Sell (StyleA.ASSETS forge_*_v2 і старі ID злитків); їх бере клієнт

-- кольори рідкостей і големи — з каталогу (Shared/GolemCatalog). GOLEMS[kind] = { name, rarity, icon } — і для нових ID,
-- і для старих тестових (wood, iron, gold, crystal → LEGACY каталогу).
Config.RARITY = Catalog.RARITY_COLOR
Config.GOLEMS = {}
for id, g in Catalog.GOLEMS do Config.GOLEMS[id] = { id = id, name = g.name, rarity = g.rarity, icon = Catalog.icon(id) } end
for old, id in Catalog.LEGACY do Config.GOLEMS[old] = Config.GOLEMS[id] end

-- іконки зіль — чорний контур (v11; Decal 84992888615631 / 106371858172694 / 137160155648393 / 125716812647925;
-- старі сині 77111033032321 / 122021343930732 / 119643786018694 / 132897787342374)
Config.POTIONS = {
	{ key = "Luck", name = "Luck Potion", icon = "rbxassetid://91725236109491", tone = Color3.fromHex("7ef05a"), dur = 300, desc = "+25% roll luck · 5 min" },
	{ key = "Speed", name = "Speed Potion", icon = "rbxassetid://139490627845083", tone = Color3.fromHex("5cc8ff"), dur = 300, desc = "Golems mine 2× faster · 5 min" },
	{ key = "Money", name = "Money Potion", icon = "rbxassetid://104193388781391", tone = Color3.fromHex("ffd23a"), dur = 600, desc = "×2 Money · 10 min" },
	{ key = "Strength", name = "Strength Potion", icon = "rbxassetid://82686194310657", tone = Color3.fromHex("ff5c6e"), dur = 300, desc = "+50% damage to ore · 5 min" },
}

Config.ORE_TONE = { Coal = Color3.fromHex("6d737c"), Copper = Color3.fromHex("e0743c"), Iron = Color3.fromHex("d9b08a") }
Config.HOTBAR = 9
Config.MAX_GOLEMS = 300
-- ліміт гравця: MAX_GOLEMS + атрибут ExtraSlots (продукт Extra Storage, +50 за покупку, багаторазовий)
function Config.maxGolems(p: Instance?): number
	return Config.MAX_GOLEMS + math.max(0, (p and tonumber(p:GetAttribute("ExtraSlots"))) or 0)
end

-- ТЕСТ (лише Studio, лише коли в збереженні ще немає секції Inventory): зілля й големи для перевірки вкладок
Config.TEST_POTIONS = { Luck = 5, Speed = 5, Money = 5, Strength = 5 }

-- ===== дія зіль (v1, 28.10.2026) =====
-- Випив (InventoryService, дія "Use") → атрибут гравця Boost_<зілля> = час сервера (GetServerTimeNow), коли дія скінчиться.
-- Ще раз — час додається. Час, що лишився, зберігається (секція Inventory, boosts) і йде лише в грі.
-- Ефекти: Luck — Roll Luck ×1,25 (RollService), Speed — майнери б'ють удвічі частіше, Strength — шкода по руді ×1,5 (PlotService),
-- Money — ×2 до TOTAL MULTI (MultiService). Таймери на екрані — StarterPlayerScripts/BoostsHUD.
function Config.potion(key: string): any
	for _, d in Config.POTIONS do if d.key == key then return d end end
	return nil
end
function Config.boostLeft(p: Instance, key: string): number
	local u = tonumber(p:GetAttribute("Boost_" .. key)) or 0
	return math.max(0, u - workspace:GetServerTimeNow())
end
function Config.boostOn(p: Instance, key: string): boolean
	return Config.boostLeft(p, key) > 0
end
-- запис "ID", "ID:carrier", "ID@мутація" (0..7) — клас (майнер за замовчуванням) і мутація (Normal за замовчуванням)
-- (26.10.2026) Stone Golem-майнер на кожну мутацію 0..7 (у Stone є 3D-модель) + носії з мутаціями + різні големи каталогу (25 з 40)
Config.TEST_GOLEMS = { "stone@0", "stone@1", "stone@2", "stone@3", "stone@4", "stone@5", "stone@6", "stone@7",
	"stone:carrier", "stone:carrier@3", "stone:carrier@7", "wooden", "wooden:carrier", "clay", "gravel:carrier", "flint",
	"rustbolt:carrier", "lantern", "ironclad@2", "quartzling", "silverjaw:carrier", "geode@4", "obsidian@5", "aurelian@6", "astral@7" }

-- усі стакові ключі (порядок = порядок у вкладках)
function Config.stackKeys(): { string }
	local t = {}
	for _, o in Forge.ORES do table.insert(t, "Ore_" .. o.key) end
	for _, o in Forge.ORES do if Forge.canSmelt(o) then table.insert(t, "Bars_" .. o.key) end end
	for _, p in Config.POTIONS do table.insert(t, "Pot_" .. p.key) end
	return t
end

function Config.isStack(key: string): boolean
	return string.sub(key, 1, 4) == "Ore_" or string.sub(key, 1, 5) == "Bars_" or string.sub(key, 1, 4) == "Pot_"
end

-- кількість големів В ІНВЕНТАРІ — без тих, що працюють на плотах (PlotPlaced). Нею рахуються ліміт MAX_GOLEMS (купівля на
-- підставці ролу, TAKE зі стенда печери, AddGolem) і лічильник «N / MAX golems» (27.10.2026). Голем, знятий з плоту, повертається
-- завжди — навіть якщо інвентар уже повний (тоді лічильник може бути більшим за MAX, нові големи не додаються, доки не звільниться місце).
function Config.invGolemCount(golems: any, placed: any): number
	local set = {}
	if type(placed) == "table" then for _, id in placed do set[id] = true end end
	local n = 0
	if type(golems) == "table" then for _, g in golems do if type(g) == "table" and not set[g.id] then n += 1 end end end
	return n
end

return Config
