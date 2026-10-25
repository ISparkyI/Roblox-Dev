--!strict
-- ForgeConfig — числа Forge (кузня з големом-ковалем). Спільний для сервера й клієнта.
-- Де: ReplicatedStorage/Shared/ForgeConfig. Усі ціни — етап 1 (пропозиція, див. GDD 7.1).

local Config = {}

Config.ORES = {
	{ key = "Coal",   color = Color3.fromHex("2b2e33"), bar = Color3.fromHex("34373d"), price = 8, smelt = false }, -- вугілля НЕ плавиться (злитків немає) — лише продається
	{ key = "Copper", color = Color3.fromHex("c8643a"), bar = Color3.fromHex("d9733f"), price = 20 },
	{ key = "Iron",   color = Color3.fromHex("d08a55"), bar = Color3.fromHex("e0e4ea"), price = 50 },
}
-- чи можна плавити руду в злитки (вугілля — ні: його кладуть лише для пробудження голема або продають)
function Config.canSmelt(o): boolean return o.smelt ~= false end
Config.BAR_MULT = 1.5          -- злиток = ціна руди × 1.5
Config.WAKE_REQ = { 20, 10, 5 } -- руда етапу, щоб розбудити голема
Config.WAKE_MONEY = 1000       -- і ще гроші (знімаються кнопкою Wake Up; окремий рядок Money у вікні Forge)
Config.VIS_ORE = 16            -- скільки кубиків кожного типу видно на піддоні Ore
Config.VIS_BARS = 24           -- скільки злитків видно на піддоні Bars
Config.RING_R = 8.64           -- радіус кола взаємодії (стади; коло збільшено ще в 1.5 раза)
Config.WAKE_TIME = 4.2         -- тривалість анімації пробудження, с
Config.DOZE_TIME = 4.2         -- тривалість засинання, с
Config.SMELT_FLIGHT = 1.1      -- (застаріле) раніше: руда летить у піч + злиток вилітає, с
Config.WAIT_WORD = "WAITING"     -- стан «кузня працює, але голем нічого не плавить» (табличка над кузнею + чип у вікні); до слова додаються крапки
Config.BAR_DELAY = 2.7         -- через скільки секунд після переплавки злиток зараховується на піддон
                               -- (руда летить у піч → гаряча заготовка на ковадло → удар → політ на піддон)

Config.SPD_MIN = 0.25          -- найшвидший інтервал удару, с (рівень 12; було 0.75 на рівні 10)
Config.OPH_MAX = 10           -- Ore per Hit: максимум руди, яку голем переробляє за один удар

function Config.capOf(l: number): number return 300 * l end
function Config.spdOf(l: number): number return math.max(Config.SPD_MIN, 3 - (l - 1) * 0.25) end
function Config.spdMax(l: number): boolean return Config.spdOf(l) <= Config.SPD_MIN + 1e-6 end
function Config.ophOf(l: number): number return math.clamp(math.floor(l), 1, Config.OPH_MAX) end -- рівень 1 = 1 руда за удар
function Config.ophMax(l: number): boolean return l >= Config.OPH_MAX end
function Config.capPrice(l: number): number return math.floor(250 * 1.6 ^ (l - 1)) end
function Config.spdPrice(l: number): number return math.floor(200 * 1.7 ^ (l - 1)) end
function Config.ophPrice(l: number): number return math.floor(1500 * 3 ^ (l - 1)) end -- пропозиція (GDD 7.1)

-- ТЕСТ: поки немає інвентаря, гравець отримує руду й гроші атрибутами.
Config.TEST_START = { Ore = { 25, 12, 6 }, Money = 10000 }
Config.TEST_SELL_BARS = false -- false: «Забрати злитки» кладе їх в інвентар (Bars_<руда>), продаються в лавці Sell; true — ТЕСТ: одразу продати

return Config
