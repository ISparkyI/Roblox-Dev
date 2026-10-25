--!strict
-- NumberFormat: короткий запис великих чисел (короткая шкала, як у більшості Roblox-симуляторів).
--   NumberFormat.short(999999)        --> "999,999"      (до мільйона — повне число з комами)
--   NumberFormat.short(1000000)       --> "1M"
--   NumberFormat.short(1234567)       --> "1.23M"        (округлення завжди вниз, 2 знаки, зайві нулі прибираються)
--   NumberFormat.short(9.99999e11)    --> "999.99B"
--   NumberFormat.short(1.5e21)        --> "1.5Sx"
--   NumberFormat.short(-2500000)      --> "-2.5M"
--   NumberFormat.money(1234567)       --> "$1.23M"
--   NumberFormat.full(1234567)        --> "1,234,567"
--   NumberFormat.mult(2.5)            --> "x2.5"
--   NumberFormat.mult(262144)         --> "x262,144"
-- Після найбільшого суфікса (Vg = 10^63) — науковий запис: "1.23e66".
local NumberFormat = {}

-- 10^6, 10^9, 10^12 ...
local SUFFIXES = {
	"M",   -- 10^6   million
	"B",   -- 10^9   billion
	"T",   -- 10^12  trillion
	"Qa",  -- 10^15  quadrillion
	"Qi",  -- 10^18  quintillion
	"Sx",  -- 10^21  sextillion
	"Sp",  -- 10^24  septillion
	"Oc",  -- 10^27  octillion
	"No",  -- 10^30  nonillion
	"Dc",  -- 10^33  decillion
	"Ud",  -- 10^36  undecillion
	"Dd",  -- 10^39  duodecillion
	"Td",  -- 10^42  tredecillion
	"Qad", -- 10^45  quattuordecillion
	"Qid", -- 10^48  quindecillion
	"Sxd", -- 10^51  sexdecillion
	"Spd", -- 10^54  septendecillion
	"Ocd", -- 10^57  octodecillion
	"Nvd", -- 10^60  novemdecillion
	"Vg",  -- 10^63  vigintillion
}
NumberFormat.SUFFIXES = SUFFIXES

local DECIMALS = 2

-- округлення вниз до `decimals` знаків (для від'ємних — до нуля), без хвоста нулів
local function floorTo(x: number, decimals: number): string
	local p = 10 ^ decimals
	local v = math.floor(math.abs(x) * p * (1 + 1e-12)) / p
	local s = string.format("%." .. decimals .. "f", v)
	s = s:gsub("0+$", ""):gsub("%.$", "")
	return s
end

-- 1234567 -> "1,234,567" (ціла частина, вниз)
function NumberFormat.full(n: number): string
	if n ~= n then return "NaN" end
	if n == math.huge then return "∞" end
	if n == -math.huge then return "-∞" end
	local neg = n < 0
	local int = math.floor(math.abs(n) + 1e-9)
	local s = string.format("%.0f", int)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	out = out:gsub("^,", "")
	return (if neg then "-" else "") .. out
end

-- головна функція: до 999,999 — повне число, далі M / B / T ...
function NumberFormat.short(n: number, decimals: number?): string
	local d = decimals or DECIMALS
	if n ~= n then return "NaN" end
	if math.abs(n) == math.huge then return if n > 0 then "∞" else "-∞" end
	local a = math.abs(n)
	if a < 1e6 then
		return NumberFormat.full(n)
	end
	local sign = if n < 0 then "-" else ""
	-- порядок рахуємо порівнянням, а не log10, щоб не було похибок на межах (999,999,999 -> 999.99M)
	local tier = 2 -- 2 = мільйони, 3 = мільярди...
	while tier - 1 < #SUFFIXES and a >= 10 ^ ((tier + 1) * 3) do
		tier += 1
	end
	local index = tier - 1
	if a >= 10 ^ ((#SUFFIXES + 2) * 3) then -- більше за 999.99Vg -> науковий запис
		local exp = 0
		while a >= 10 ^ (exp + 1) do exp += 1 end
		return sign .. floorTo(a / 10 ^ exp, d) .. "e" .. exp
	end
	local value = a / 10 ^ (tier * 3)
	return sign .. floorTo(value, d) .. SUFFIXES[index]
end

function NumberFormat.money(n: number): string
	if n < 0 then return "-$" .. NumberFormat.short(-n) end
	return "$" .. NumberFormat.short(n)
end

-- до мільйона — з комами в цілій частині: 262144 -> "x262,144", 2.5 -> "x2.5"
function NumberFormat.mult(n: number): string
	if math.abs(n) >= 1e6 then return "x" .. NumberFormat.short(n) end
	local s = floorTo(n, DECIMALS)
	local int, frac = s:match("^(%d+)(.*)$")
	if not int then return "x" .. s end
	return "x" .. NumberFormat.full(tonumber(int) :: number) .. frac
end

-- секунди -> "1h 05m", "4m 30s", "45s"
function NumberFormat.time(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local h, m, sec = s // 3600, (s % 3600) // 60, s % 60
	if h > 0 then return string.format("%dh %02dm", h, m) end
	if m > 0 then return string.format("%dm %02ds", m, sec) end
	return string.format("%ds", sec)
end

return NumberFormat
