--!nonstrict
-- MonetizationConfig — ID геймпасів і Developer Products (спільний для сервера й клієнта).
-- Де: ReplicatedStorage/Shared/MonetizationConfig.
-- ID = 0 — ще не створено в Creator Hub (кнопка не працює, у Studio виводиться підказка).

local Config = {}

-- геймпаси (купуються один раз, атрибут гравця Pass_<ім'я> = true)
Config.Passes = {
	VIP = { id = 0 },        -- x2 Money (MultiConfig.VIP_MULT)
	MoreCrates = { id = 0 }, -- нести всі 6 ящиків (GDD 15.1)
}

-- Developer Products для ступенів x2 Money: [ступінь] = ProductId (номер ступеня = рядок MultiConfig.DONATE_TIERS).
-- Ціна ступеня — у MultiConfig.DONATE_TIERS; у Creator Hub стоїть та сама ціна (Managed pricing вимкнено).
-- Продукти створені в Creator Hub 24.10.2026 (назва «xN Money», іконка — пачка грошей).
Config.MoneyTierProducts = {
	[1] = 3721927655,  -- x2 Money
	[2] = 3721927921,  -- x3 Money
	[3] = 3721928105,  -- x4 Money
	[4] = 3721928351,  -- x8 Money
	[5] = 3721928373,  -- x16 Money
	[6] = 3721928644,  -- x32 Money
	[7] = 3721928802,  -- x64 Money
	[8] = 3721928838,  -- x128 Money
	[9] = 3721928868,  -- x256 Money
	[10] = 3721929008, -- x512 Money
	[11] = 3721929046, -- x1,024 Money
	[12] = 3721929082, -- x2,048 Money
	[13] = 3721929746, -- x4,096 Money
	[14] = 3721930194, -- x8,192 Money
	[15] = 3721930045, -- x16,384 Money
	[16] = 3721930321, -- x32,768 Money
	[17] = 3721930359, -- x65,536 Money
	[18] = 3721930510, -- x131,072 Money
	[19] = 3721930572, -- x262,144 Money
	[20] = 3721930680, -- x524,288 Money
	[21] = 3721930724, -- x1,048,576 Money
}

return Config
