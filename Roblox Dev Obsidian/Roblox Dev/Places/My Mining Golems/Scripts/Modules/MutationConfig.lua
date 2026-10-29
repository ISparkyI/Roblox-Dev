--!strict
-- MutationConfig — Mutation Machine (GDD - Mutation Machine): 3 однакових голема → 1 з наступною мутацією.
-- Де: ReplicatedStorage/Shared/MutationConfig (спільний для сервера й клієнта).
-- Машини — Workspace/Cave/Hub/MutationMachines/Machine1..2 (по 3 слоти + ядро + пульт швидкості); стан у кожного гравця свій
--   (атрибут гравця MutMachines, сервер — ServerScriptService/MutationService, вигляд — StarterPlayerScripts/MutationMachineClient).
-- «Однакові» = та сама назва (kind), той самий клас (cls) і та сама мутація (mut). Secret (7) — найвища, далі не мутує.
-- Час — від мутації, ДО якої йде покращення (GDD): Normal → Bronze 15 хв … Rainbow → Secret 120 год.
-- Таймер іде й офлайн (від часу старту). Прискорення Fast Mutations (MutSpeedTier, MonetizationConfig.MUT_SPEED_TIERS):
--   час ділиться на множник; купівля під час мутації прискорює решту часу.

local M = {}

M.MACHINES = 2
M.SLOTS = 3
M.MAX_MUT = 7

-- [мутація-ціль] = секунди (базово, без прискорення)
M.TIME = {
	[1] = 15 * 60,      -- Normal  → Bronze
	[2] = 30 * 60,      -- Bronze  → Silver
	[3] = 2 * 3600,     -- Silver  → Gold
	[4] = 8 * 3600,     -- Gold    → Diamond
	[5] = 20 * 3600,    -- Diamond → Void
	[6] = 60 * 3600,    -- Void    → Rainbow
	[7] = 120 * 3600,   -- Rainbow → Secret
}

function M.duration(fromMut: number): number
	return M.TIME[math.floor(fromMut) + 1] or math.huge
end

-- job = { dur = базові секунди, done = базові секунди, вже пройдені до t0, t0 = час сервера (GetServerTimeNow), mult = множник }
function M.left(job: any, now: number): number
	if type(job) ~= "table" then return math.huge end
	local mult = math.max(1, tonumber(job.mult) or 1)
	local base = (tonumber(job.done) or 0) + math.max(0, now - (tonumber(job.t0) or now)) * mult
	return math.max(0, ((tonumber(job.dur) or 0) - base) / mult)
end
function M.progress(job: any, now: number): number
	if type(job) ~= "table" then return 0 end
	local dur = math.max(1, tonumber(job.dur) or 1)
	local mult = math.max(1, tonumber(job.mult) or 1)
	local base = (tonumber(job.done) or 0) + math.max(0, now - (tonumber(job.t0) or now)) * mult
	return math.clamp(base / dur, 0, 1)
end

-- 1:05:09 / 12:04 / 0:09
function M.fmt(sec: number): string
	sec = math.max(0, math.ceil(sec))
	local h = math.floor(sec / 3600)
	local m = math.floor(sec % 3600 / 60)
	local s = sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

-- ті самі големи? (kind, cls, mut)
function M.same(a: any, b: any): boolean
	return type(a) == "table" and type(b) == "table" and a.kind == b.kind and a.cls == b.cls and a.mut == b.mut
end

return M
