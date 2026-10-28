--!nonstrict
-- GolemRegistry — унікальні ID големів (UID), їхній життєвий цикл, глобальний індекс цінних големів і журнал подій.
-- Де: ServerScriptService/GolemRegistry (ModuleScript). Лише сервер. Підключають InventoryService, CaveStandService, AdminService.
--
-- UID — 26 символів Crockford base32 (як ULID): 10 символів — час мінту в мс (48 біт), 16 — випадкові 80 біт
--   (HttpService:GenerateGUID XOR Random). Приклад: 01JBK3Q7M8X4V2N6T5R0ZC1HYA. Простір 2^80 на кожну мілісекунду —
--   навіть 4·10^11 големів (10^9 гравців × 400) не дадуть колізії. За UID видно час створення (TimeOf).
-- Де живе голем: ЛИШЕ в профілі власника (DataService: секції Inventory / Cave), поле uid у записі { id, uid, kind, cls, mut }.
--   id — локальний номер у профілі (ключ Golem_<id> для інтерфейсу), uid — глобальний.
-- Життєвий цикл:
--   * рол — UID НЕМАЄ (результат на підставці — лише { kind, cls, mut }); BUY / код / видача адміном → Mint (новий UID);
--   * плот, стенд печери, передача — UID той самий (передача — Move, наступний етап з трейдами);
--   * справжнє видалення (Delete в інвентарі, адмін) → Burn: UID зникає назавжди (з індексу теж), у журналі — рядок burn.
-- Глобальний індекс (DataStore GolemIndex, ключ = UID): лише цінні (mut ≥ INDEX_MUT — Void, Rainbow, Secret), видані адміном
--   і передані. Запис { o = власник, k, c, m, t = час мінту, s = джерело, h = останні події }. У записі голема — ix = 1.
--   Так індекс не росте до мільярдів записів, а дюп ловиться там, де він можливий (цінні й передані големи).
-- Журнал (DataStore GolemLog): лише важливі події, пачками раз на FLUSH_SEC; ключ L_<РРРРММДД>_<сервер>_<n>, ≤ LOG_PER_KEY подій.
--   Подія { t, e, u, g?, k?, m?, r?, x? }: e — mint | burn | legacy | dupe | move | admin | grant; u — userId; g — UID; r — причина.
-- Studio без доступу до API — індекс і журнал у пам'яті (як DataService).
--
-- API:
--   NewUid() → string;  IsUid(s) → bool;  TimeOf(uid) → секунди Unix
--   Mint(player | userId, rec, reason) → rec (ставить rec.uid, пише mint; цінний / admin — в індекс)
--   Ensure(player, rec, where) → bool (рекорд без UID — дати UID «legacy»; true, якщо змінився)
--   Burn(player | userId, rec, reason)  (видалення назавжди)
--   Move(fromUserId, toUserId, rec, reason)  (передача; запис потрапляє в індекс)
--   Lookup(uid) → запис індексу | nil  (yield)
--   Log(event)  (довільна подія в журнал; e обов'язкове)
--   RecentLogs(n) → список останніх подій цього сервера (для адмін-панелі)
--   History(day РРРРММДД, max?) → усі події дня з усіх серверів (журнал + буфер цього сервера), новіші першими

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local GolemRegistry = {}

local STUDIO = RunService:IsStudio()
local INDEX_NAME = STUDIO and "GolemIndex_Studio" or "GolemIndex"
local LOG_NAME = STUDIO and "GolemLog_Studio" or "GolemLog"
GolemRegistry.INDEX_MUT = 5   -- Void і вище — у глобальний індекс
local HISTORY_MAX = 12        -- подій в історії запису індексу
local FLUSH_SEC = 60
local LOG_PER_KEY = 4000
local RECENT_MAX = 300
local JOB = (game.JobId ~= "" and string.sub(game.JobId, 1, 8)) or "studio"

local ALPH = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
local rng = Random.new()

-- ===== UID =====
local function b32(n: number, len: number): string
	local t = table.create(len)
	for i = len, 1, -1 do
		local d = n % 32
		t[i] = string.sub(ALPH, d + 1, d + 1)
		n = (n - d) / 32
	end
	return table.concat(t)
end

function GolemRegistry.NewUid(): string
	local ms = DateTime.now().UnixTimestampMillis
	local g = string.gsub(HttpService:GenerateGUID(false), "-", "")
	local parts = { b32(ms, 10) }
	for i = 0, 3 do -- 4 × 20 біт = 80 біт випадковості
		local chunk = tonumber(string.sub(g, i * 5 + 1, i * 5 + 5), 16) or 0
		chunk = bit32.bxor(chunk, rng:NextInteger(0, 0xFFFFF))
		table.insert(parts, b32(chunk, 4))
	end
	return table.concat(parts)
end

function GolemRegistry.IsUid(s: any): boolean
	return type(s) == "string" and #s == 26 and string.find(s, "[^0-9A-HJKMNP-TV-Z]") == nil
end

function GolemRegistry.TimeOf(uid: string): number?
	if not GolemRegistry.IsUid(uid) then return nil end
	local n = 0
	for i = 1, 10 do
		local c = string.sub(uid, i, i)
		n = n * 32 + (string.find(ALPH, c, 1, true) :: number) - 1
	end
	return n / 1000
end

-- ===== сховища (DataStore або пам'ять у Studio) =====
local useMemory = false
local mem = { index = {}, log = {} }
local indexStore, logStore = nil, nil
local function fallback(err: any): boolean
	if useMemory then return true end
	if STUDIO and string.find(string.lower(tostring(err)), "studio") then
		useMemory = true
		warn("GolemRegistry: DataStore недоступний у Studio — індекс і журнал у пам'яті.")
		return true
	end
	return false
end
local function idx()
	if not indexStore then indexStore = DataStoreService:GetDataStore(INDEX_NAME) end
	return indexStore
end
local function logs()
	if not logStore then logStore = DataStoreService:GetDataStore(LOG_NAME) end
	return logStore
end

local function updateIndex(uid: string, fn: (any) -> any)
	for attempt = 1, 3 do
		if useMemory then mem.index[uid] = fn(mem.index[uid]); return true end
		local ok, err = pcall(function() idx():UpdateAsync(uid, fn) end)
		if ok then return true end
		if not fallback(err) then
			warn("GolemRegistry: індекс " .. uid .. ": " .. tostring(err))
			task.wait(attempt * 2)
		end
	end
	return false
end
local function removeIndex(uid: string)
	if useMemory then mem.index[uid] = nil; return end
	local ok, err = pcall(function() idx():RemoveAsync(uid) end)
	if not ok and not fallback(err) then warn("GolemRegistry: видалення з індексу " .. uid .. ": " .. tostring(err)) end
	if useMemory then mem.index[uid] = nil end
end

function GolemRegistry.Lookup(uid: string): any
	if not GolemRegistry.IsUid(uid) then return nil end
	if useMemory then return mem.index[uid] end
	local ok, res = pcall(function() return idx():GetAsync(uid) end)
	if ok then return res end
	if fallback(res) then return mem.index[uid] end
	warn("GolemRegistry: Lookup " .. uid .. ": " .. tostring(res))
	return nil
end

-- ===== журнал =====
local buffer = {}
local recent = {}
function GolemRegistry.Log(ev: any)
	if type(ev) ~= "table" or type(ev.e) ~= "string" then return end
	ev.t = ev.t or os.time()
	table.insert(buffer, ev)
	table.insert(recent, ev)
	if #recent > RECENT_MAX then table.remove(recent, 1) end
end
function GolemRegistry.RecentLogs(n: number?): { any }
	n = math.clamp(n or 100, 1, RECENT_MAX)
	local out = {}
	for i = #recent, math.max(1, #recent - n + 1), -1 do table.insert(out, recent[i]) end
	return out
end

-- увесь журнал за день UTC з усіх серверів (ключі L_<день>_*, ListKeysAsync за префіксом) + ще не записані події цього
-- сервера; новіші — першими, не більше max. Кеш на день — HISTORY_CACHE_SEC (щоб кнопки не били DataStore).
local HISTORY_CACHE_SEC = 20
local HISTORY_KEYS_MAX = 60
local histCache: { [string]: { t: number, list: { any } } } = {}
function GolemRegistry.History(day: string, max: number?): { any }
	max = max or 2000
	local out = {}
	local c = histCache[day]
	if c and os.clock() - c.t < HISTORY_CACHE_SEC then
		out = table.clone(c.list)
	elseif useMemory then
		for _, e in mem.log do if os.date("!%Y%m%d", e.t or 0) == day then table.insert(out, e) end end
	else
		local ok, pages = pcall(function() return logs():ListKeysAsync("L_" .. day .. "_", 50) end)
		if ok then
			local n = 0
			while n < HISTORY_KEYS_MAX do
				for _, k in pages:GetCurrentPage() do
					n += 1
					if n > HISTORY_KEYS_MAX then break end
					local okG, v = pcall(function() return logs():GetAsync(k.KeyName) end)
					if okG and type(v) == "table" then for _, e in v do table.insert(out, e) end end
				end
				if pages.IsFinished or n >= HISTORY_KEYS_MAX then break end
				local okA = pcall(function() pages:AdvanceToNextPageAsync() end)
				if not okA then break end
			end
		elseif fallback(pages) then
			for _, e in mem.log do if os.date("!%Y%m%d", e.t or 0) == day then table.insert(out, e) end end
		else
			warn("GolemRegistry: History " .. day .. ": " .. tostring(pages))
		end
		histCache[day] = { t = os.clock(), list = table.clone(out) }
	end
	for _, e in buffer do if os.date("!%Y%m%d", e.t or 0) == day then table.insert(out, e) end end
	table.sort(out, function(a, b) return (a.t or 0) > (b.t or 0) end)
	while #out > max do table.remove(out) end
	return out
end

local keyN = 1
local function flush()
	if #buffer == 0 then return end
	local batch = buffer
	buffer = {}
	if useMemory then for _, e in batch do table.insert(mem.log, e) end; return end
	local day = os.date("!%Y%m%d")
	for _ = 1, 4 do
		local key = "L_" .. day .. "_" .. JOB .. "_" .. keyN
		local full = false
		local ok, err = pcall(function()
			logs():UpdateAsync(key, function(old)
				old = old or {}
				if #old + #batch > LOG_PER_KEY then full = true; return nil end
				for _, e in batch do table.insert(old, e) end
				return old
			end)
		end)
		if ok and not full then return end
		if ok and full then keyN += 1; continue end
		if fallback(err) then for _, e in batch do table.insert(mem.log, e) end; return end
		warn("GolemRegistry: журнал: " .. tostring(err))
		break
	end
	-- не вдалося — повертаємо події в буфер (наступна спроба), без безмежного росту
	for i = #batch, 1, -1 do table.insert(buffer, 1, batch[i]) end
	while #buffer > LOG_PER_KEY do table.remove(buffer, 1) end
end

-- ===== життєвий цикл =====
local function userIdOf(who: any): number
	if typeof(who) == "Instance" and who:IsA("Player") then return who.UserId end
	return tonumber(who) or 0
end

local function needsIndex(rec: any, reason: string): boolean
	return (tonumber(rec.mut) or 0) >= GolemRegistry.INDEX_MUT or string.sub(reason, 1, 5) == "admin"
end

local function pushHistory(entry: any, ev: any)
	entry.h = entry.h or {}
	table.insert(entry.h, ev)
	while #entry.h > HISTORY_MAX do table.remove(entry.h, 1) end
end

local function indexSet(uid: string, ownerId: number, rec: any, reason: string, ev: string)
	rec.ix = 1
	task.spawn(updateIndex, uid, function(old)
		local e = old or { t = GolemRegistry.TimeOf(uid), s = reason }
		e.o = ownerId; e.k = rec.kind; e.c = rec.cls; e.m = rec.mut
		pushHistory(e, { e = ev, t = os.time(), u = ownerId, r = reason })
		return e
	end)
end

function GolemRegistry.Mint(who: any, rec: any, reason: string?): any
	reason = reason or "buy"
	local uid = GolemRegistry.NewUid()
	rec.uid = uid
	local u = userIdOf(who)
	GolemRegistry.Log({ e = "mint", u = u, g = uid, k = rec.kind, m = rec.mut, c = rec.cls, r = reason })
	if needsIndex(rec, reason :: string) then indexSet(uid, u, rec, reason :: string, "mint") end
	return rec
end

function GolemRegistry.Ensure(who: any, rec: any, where: string?): boolean
	if type(rec) ~= "table" then return false end
	if GolemRegistry.IsUid(rec.uid) then return false end
	local uid = GolemRegistry.NewUid()
	rec.uid = uid
	local u = userIdOf(who)
	GolemRegistry.Log({ e = "legacy", u = u, g = uid, k = rec.kind, m = rec.mut, c = rec.cls, r = where or "inv" })
	if (tonumber(rec.mut) or 0) >= GolemRegistry.INDEX_MUT then indexSet(uid, u, rec, "legacy", "legacy") end
	return true
end

function GolemRegistry.Burn(who: any, rec: any, reason: string?)
	if type(rec) ~= "table" then return end
	local u = userIdOf(who)
	GolemRegistry.Log({ e = "burn", u = u, g = rec.uid, k = rec.kind, m = rec.mut, c = rec.cls, r = reason or "delete" })
	if rec.ix and GolemRegistry.IsUid(rec.uid) then task.spawn(removeIndex, rec.uid) end
end

function GolemRegistry.Move(fromId: number, toId: number, rec: any, reason: string?)
	if type(rec) ~= "table" or not GolemRegistry.IsUid(rec.uid) then return end
	GolemRegistry.Log({ e = "move", u = fromId, g = rec.uid, k = rec.kind, m = rec.mut, r = reason or "trade", x = toId })
	indexSet(rec.uid, toId, rec, reason or "trade", "move")
end

-- дублікати в межах одного профілю: той самий UID двічі → лишаємо перший, решту прибираємо (журнал dupe)
-- list — масив записів; seen — спільна таблиця uid → true (інвентар + печера). Повертає (новий список, скільки прибрано)
function GolemRegistry.Dedupe(who: any, list: { any }, seen: { [string]: boolean }, where: string): ({ any }, number)
	local out, n = {}, 0
	local u = userIdOf(who)
	for _, g in list do
		if type(g) == "table" and GolemRegistry.IsUid(g.uid) then
			if seen[g.uid] then
				n += 1
				GolemRegistry.Log({ e = "dupe", u = u, g = g.uid, k = g.kind, m = g.mut, r = where })
				continue
			end
			seen[g.uid] = true
		end
		table.insert(out, g)
	end
	return out, n
end

-- перевірка цінних (індексованих) големів при вході: власник в індексі ≠ цей гравець → підозра (журнал foreign).
-- Не більше CHECK_MAX запитів на вхід. Нічого не видаляє — рішення за адміном.
local CHECK_MAX = 15
function GolemRegistry.CheckOwnership(p: Player, list: { any })
	task.spawn(function()
		local n = 0
		for _, g in list do
			if n >= CHECK_MAX or p.Parent ~= Players then return end
			if type(g) == "table" and g.ix and GolemRegistry.IsUid(g.uid) then
				n += 1
				local e = GolemRegistry.Lookup(g.uid)
				if e == nil then
					indexSet(g.uid, p.UserId, g, "relink", "relink")
				elseif e.o ~= p.UserId then
					GolemRegistry.Log({ e = "foreign", u = p.UserId, g = g.uid, k = g.kind, m = g.mut, x = e.o })
					p:SetAttribute("SuspectDupe", true)
				end
				task.wait(0.5)
			end
		end
	end)
end

-- ===== запуск =====
local started = false
function GolemRegistry.Start()
	if started then return end
	started = true
	task.spawn(function()
		while true do
			task.wait(FLUSH_SEC)
			flush()
		end
	end)
	game:BindToClose(function() flush() end)
end

GolemRegistry._internal = { mem = mem, flush = flush }

return GolemRegistry
