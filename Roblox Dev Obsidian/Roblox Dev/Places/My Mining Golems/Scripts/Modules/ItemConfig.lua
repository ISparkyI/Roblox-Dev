--!strict
-- ItemConfig — предмети інвентаря гравця (спільний для сервера й клієнта): руда й злитки (з ForgeConfig), зілля, големи, іконки.
-- Де: ReplicatedStorage/Shared/ItemConfig. Інвентар — 2D/Inventory (GDD 22). Іконки — власні PNG (2D/Inventory/Roblox/Import, inv_*).
--
-- Ключі предметів (атрибути гравця й записи в хотбарі / замках):
--   Ore_<руда>, Bars_<руда> — кількість (атрибут гравця, стак);
--   Pot_<зілля>            — кількість (атрибут гравця, стак);
--   Golem_<id>             — один голем (не стакається), список — атрибут InvGolems (JSON: { { id, kind, cls } }, cls = "miner" | "carrier").
-- ЗІЛЛЯ ТА ГОЛЕМИ В ІНВЕНТАРІ ПОКИ ТЕСТОВІ: справжніх джерел ще немає (TEST_* нижче — лише в Studio). Ефекти зіль — пропозиція.

local RS = game:GetService("ReplicatedStorage")
local Forge = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))

local Config = {}

Config.ICONS = {
	tab_golems = "rbxassetid://125478992512505",
	tab_orebars = "rbxassetid://97817560625726",
	tab_potions = "rbxassetid://91234342811407",
	trash = "rbxassetid://79551145743198",
	lock = "rbxassetid://122986621331664",
}
-- іконки руди й злитків — ті самі, що у вікнах Forge / Sell (StyleA.ASSETS forge_*_v2 і старі ID злитків); їх бере клієнт

Config.RARITY = {
	Common = Color3.fromHex("9aa3ad"), Rare = Color3.fromHex("3aa6ff"), Epic = Color3.fromHex("c86bff"), Legendary = Color3.fromHex("ffc531"),
}

Config.GOLEMS = {
	stone = { name = "Stone Golem", rarity = "Common", icon = "rbxassetid://97975821667403", rate = "1.0" },
	wood = { name = "Wooden Golem", rarity = "Common", icon = "rbxassetid://118736528199973", rate = "0.8" },
	iron = { name = "Iron Golem", rarity = "Rare", icon = "rbxassetid://133852237833502", rate = "1.6" },
	gold = { name = "Gold Golem", rarity = "Epic", icon = "rbxassetid://85164603125451", rate = "2.4" },
	crystal = { name = "Crystal Golem", rarity = "Legendary", icon = "rbxassetid://125678918437751", rate = "4.0" },
}

Config.POTIONS = {
	{ key = "Luck", name = "Luck Potion", icon = "rbxassetid://77111033032321", tone = Color3.fromHex("7ef05a"), desc = "+25% roll luck · 5 min" },
	{ key = "Speed", name = "Speed Potion", icon = "rbxassetid://122021343930732", tone = Color3.fromHex("5cc8ff"), desc = "Golems mine 2× faster · 5 min" },
	{ key = "Money", name = "Money Potion", icon = "rbxassetid://119643786018694", tone = Color3.fromHex("ffd23a"), desc = "×2 Money · 10 min" },
	{ key = "Strength", name = "Strength Potion", icon = "rbxassetid://132897787342374", tone = Color3.fromHex("ff5c6e"), desc = "+50% damage to ore · 5 min" },
}

Config.ORE_TONE = { Coal = Color3.fromHex("6d737c"), Copper = Color3.fromHex("e0743c"), Iron = Color3.fromHex("d9b08a") }
Config.HOTBAR = 9
Config.MAX_GOLEMS = 40

-- ТЕСТ (лише Studio, лише коли в збереженні ще немає секції Inventory): зілля й големи для перевірки вкладок
Config.TEST_POTIONS = { Luck = 2, Speed = 1, Money = 3, Strength = 1 }
-- запис "вид" або "вид:carrier" — клас голема (майнер за замовчуванням; GDD 4.1, плоти — GDD 5)
Config.TEST_GOLEMS = { "stone", "stone", "wood", "wood:carrier", "wood", "iron", "iron:carrier", "gold", "crystal", "stone:carrier", "iron", "wood", "gold" }

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

return Config
