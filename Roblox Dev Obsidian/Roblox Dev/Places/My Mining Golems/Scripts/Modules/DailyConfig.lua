--!nonstrict
-- DailyConfig — щоденні нагороди (DAILY REWARDS, 29.10.2026). Спільний для сервера (DailyService) і клієнта (DailyWindow).
-- День для всіх однаковий: скидається о 08:00 за Києвом (Europe/Kyiv: UTC+2 взимку, UTC+3 влітку — правила ЄС: остання неділя
--   березня … остання неділя жовтня, о 01:00 UTC).
-- Нагороди — безкінечний ряд, свій у кожного гравця (детерміновано з DailySeed гравця і номера n):
--   n = 1 — усім однаково: 1 Money Potion; n кратне 7 — голем (поки Mushroom Golem-носій, 75 % BEST Carrier);
--   решта — випадково з пулу POOL (ваги w): тайм-скіпи, діаманти, тікети, зілля 1–3, рідко Potion Pack і x10 Lucky Roll,
--   дуже рідко x99 Lucky Roll. Календар відкриває лише VISIBLE (7) наступних нагород, решта — закриті «?».
-- Скіп дня за Robux: наступна нагорода одразу (по черзі), 19 R$, 7-й день — 69 R$ (Developer Products нижче).
local Config = {}

Config.RESET_HOUR = 8 -- 08:00 за Києвом
Config.SHOW = 31     -- скільки плиток у календарі (від наступної)
Config.VISIBLE = 7   -- скільки з них відкрито (решта — «?»)
Config.SKIP = { id = 3723667163, robux = 19 }      -- Developer Product «Daily Skip»
Config.SKIP7 = { id = 3723667305, robux = 69 }     -- «Daily Skip (Day 7)» — коли наступна нагорода день 7, 14, 21 …
Config.ICON = "rbxassetid://80819332588445"       -- календар (Calendar 1st Outline 256px, Decal 116565676365269)

-- ===== час =====
-- чи діє літній час у Києві в момент t (UTC, с): від останньої неділі березня 01:00 UTC до останньої неділі жовтня 01:00 UTC
local function lastSunday(year: number, month: number): number
	local t = DateTime.fromUniversalTime(year, month + 1, 1, 1, 0, 0).UnixTimestamp -- 1-ше число наступного місяця, 01:00 UTC
	t -= 86400
	while os.date("!*t", t).wday ~= 1 do t -= 86400 end
	return t
end
function Config.kyivOffset(t: number): number
	local y = os.date("!*t", t).year
	local s, e = lastSunday(y, 3), lastSunday(y, 10)
	return (t >= s and t < e) and 3 * 3600 or 2 * 3600
end
-- номер «дня дейліків» (змінюється о 08:00 за Києвом)
function Config.dayIndex(t: number): number
	return math.floor((t + Config.kyivOffset(t) - Config.RESET_HOUR * 3600) / 86400)
end
-- коли наступне скидання (UTC, с)
function Config.nextReset(t: number): number
	local d = Config.dayIndex(t) + 1
	local r = d * 86400 + Config.RESET_HOUR * 3600 - Config.kyivOffset(t)
	if r <= t then r += 86400 end
	return r
end

-- ===== нагороди =====
-- kind: "skip" (key = продукт TS*), "diamonds" / "tickets" (n), "potion" (key = Luck|Speed|Money|Strength, n), "potionpack",
--   "luckroll" (x10 Lucky Roll), "luckroll99" (x99 Lucky Roll), "golem" (key = ID голема, cls)
local function pick(r: Random, list: { any }): any
	local total = 0
	for _, e in list do total += e.w end
	local x = r:NextNumber() * total
	for _, e in list do
		x -= e.w
		if x <= 0 then return e end
	end
	return list[#list]
end
Config.SKIPS = { { key = "TS5", w = 30 }, { key = "TS15", w = 25 }, { key = "TS30", w = 18 }, { key = "TS60", w = 12 }, { key = "TS120", w = 7 },
	{ key = "TS360", w = 4 }, { key = "TS720", w = 2 }, { key = "TS1440", w = 1.5 }, { key = "TS2880", w = 0.5 } }
Config.DIAMONDS = { { n = 15, w = 30 }, { n = 25, w = 25 }, { n = 50, w = 20 }, { n = 100, w = 12 }, { n = 250, w = 7 }, { n = 500, w = 4 }, { n = 1000, w = 2 } }
Config.TICKETS = { { n = 5, w = 50 }, { n = 10, w = 35 }, { n = 15, w = 15 } }
Config.POTIONS = { "Luck", "Speed", "Money", "Strength" }
Config.POTION_N = { { n = 1, w = 55 }, { n = 2, w = 30 }, { n = 3, w = 15 } }
Config.POOL = {
	{ kind = "skip", w = 24 },
	{ kind = "diamonds", w = 23 },
	{ kind = "tickets", w = 24 },
	{ kind = "potion", w = 22 },
	{ kind = "potionpack", w = 3 },   -- малий шанс
	{ kind = "luckroll", w = 3 },     -- x10 Lucky Roll, малий шанс
	{ kind = "luckroll99", w = 1 },   -- x99 Lucky Roll, дуже малий шанс
}
Config.GOLEM7 = { kind = "golem", key = "mushroom", cls = "carrier" } -- запасний (якщо голема циклу ще немає в каталозі)
-- тижневий цикл (03.11.2026): дні 7 / 14 / … / 49 — 7 големів, далі по колу (56 — знову Mushroom Carrier).
-- Лише Miner і Carrier; воїнів — в Boss Shop (пізніше). GDD — Plan - Weekly Reward Golems.
Config.WEEKLY = {
	{ key = "mushroom", cls = "carrier" }, -- день 7
	{ key = "honey", cls = "miner" },      -- 14
	{ key = "snow", cls = "carrier" },     -- 21
	{ key = "cloud", cls = "miner" },      -- 28
	{ key = "honey", cls = "carrier" },    -- 35
	{ key = "snow", cls = "miner" },       -- 42
	{ key = "cloud", cls = "carrier" },    -- 49
}
function Config.weekly(n: number): any
	local e = Config.WEEKLY[((math.floor(n / 7) - 1) % #Config.WEEKLY) + 1]
	local okC, Catalog = pcall(require, game:GetService("ReplicatedStorage").Shared.GolemCatalog)
	if not e or not (okC and Catalog.GOLEMS[e.key]) then return table.clone(Config.GOLEM7) end
	return { kind = "golem", key = e.key, cls = e.cls }
end

function Config.isSeventh(n: number): boolean return n % 7 == 0 end
function Config.reward(seed: number, n: number): any
	if n == 1 then return { kind = "potion", key = "Money", n = 1 } end
	if Config.isSeventh(n) then return Config.weekly(n) end
	local r = Random.new((math.floor(seed) * 7919 + n * 104729) % 2147483647)
	local e = pick(r, Config.POOL)
	if e.kind == "skip" then return { kind = "skip", key = pick(r, Config.SKIPS).key } end
	if e.kind == "diamonds" then return { kind = "diamonds", n = pick(r, Config.DIAMONDS).n } end
	if e.kind == "tickets" then return { kind = "tickets", n = pick(r, Config.TICKETS).n } end
	if e.kind == "potion" then
		return { kind = "potion", key = Config.POTIONS[r:NextInteger(1, #Config.POTIONS)], n = pick(r, Config.POTION_N).n }
	end
	return { kind = e.kind }
end
function Config.skipProduct(n: number): any return Config.isSeventh(n) and Config.SKIP7 or Config.SKIP end

-- текст нагороди для UI
local function minText(m: number): string
	if m < 60 then return m .. " Min" end
	local h = m / 60
	return h .. (h == 1 and " Hour" or " Hours")
end
function Config.label(rw: any, MonCfg: any?): string
	if rw.kind == "skip" then
		local d = MonCfg and MonCfg.Products[rw.key]
		return (d and minText(d.skipMin) or "Time") .. " Skip"
	end
	if rw.kind == "diamonds" then return rw.n .. " Diamonds" end
	if rw.kind == "tickets" then return rw.n .. " Tickets" end
	if rw.kind == "potion" then return "x" .. rw.n .. " " .. rw.key .. " Potion" end
	if rw.kind == "potionpack" then return "Potion Pack" end
	if rw.kind == "luckroll" then return "x10 Lucky Roll" end
	if rw.kind == "luckroll99" then return "x99 Lucky Roll" end
	if rw.kind == "golem" then
		local okC, Catalog = pcall(require, game:GetService("ReplicatedStorage").Shared.GolemCatalog)
		local g = okC and Catalog.GOLEMS[rw.key]
		return (g and g.name) or "Golem"
	end
	return "?"
end

return Config
