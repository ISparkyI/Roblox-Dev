--!strict
-- RobuxStandConfig — стенд големів за Robux у ніші (збоку від ролу), 10.11.2026.
-- Де: ReplicatedStorage/Shared/RobuxStandConfig. Стенд — NichePrefabs/NichePrefab_Stage1..6/RollSystem/RobuxStand
-- (копія Prefabs/RollStand + RobuxBuyAnchor/RobuxBuyPrompt). Клієнт — StarterPlayerScripts/RobuxStandClient,
-- видача після оплати — ServerScriptService/RobuxStandService (викликає MonetizationService з ProcessReceipt).
--
-- На стенді големи змінюються по колу кожні ROTATE с. Поточний — за часом сервера (у всіх гравців однаковий).
-- Клас купленого — завжди майнер, без мутації.
-- product — id Developer Product у Creator Hub; 0 — ще не підключено (кнопка пише «SOON»).
-- 10.11.2026: створено 7 продуктів («<Назва> Golem (Epic|Legendary)», опис «Epic / Legendary miner golem.», Managed pricing вимкнено).

local M = {}

M.ROTATE = 8 -- секунд на одного голема
M.CLS = "miner"
M.ROBUX_ICON = "rbxassetid://139687766069559" -- той самий значок, що біля x2 Money (MainHUD)

-- порядок як в Index: Epic 1–5, Legendary 1–2
M.OFFERS = {
	{ kind = "topaz",    robux = 79,  product = 3730249841 },
	{ kind = "geode",    robux = 99,  product = 3730249898 },
	{ kind = "amethyst", robux = 119, product = 3730250052 },
	{ kind = "sapphire", robux = 139, product = 3730250180 },
	{ kind = "emerald",  robux = 159, product = 3730250254 },
	{ kind = "obsidian", robux = 249, product = 3730250332 },
	{ kind = "moonstone", robux = 279, product = 3730250398 },
}

-- поточна пропозиція за часом сервера (workspace:GetServerTimeNow())
function M.indexAt(t: number): number
	return math.floor(t / M.ROTATE) % #M.OFFERS + 1
end

function M.byProduct(id: number): any
	if type(id) ~= "number" or id == 0 then return nil end
	for _, o in M.OFFERS do if o.product == id then return o end end
	return nil
end

return M
