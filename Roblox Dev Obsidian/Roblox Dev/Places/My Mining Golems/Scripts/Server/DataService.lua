--!nonstrict
-- DataService — глобальне збереження даних гравця (DataStore) з сесійним блокуванням.
-- Де: ServerScriptService/DataService (ModuleScript). Запуск: NicheBoot, ПЕРШИМ (до усіх інших сервісів).
--
-- Як це працює:
--   * Вхід: сервер бере замок запису (UpdateAsync: lock = {job, t}). Якщо замок тримає інший сервер — чекаємо
--     (LOAD_TRIES × LOAD_RETRY_SEC), інакше кікаємо гравця, щоб не затерти дані. Замок протухає через LOCK_TTL с (сервер упав).
--   * Дані після завантаження живуть у АТРИБУТАХ гравця (так працює весь наявний код і HUD) і у СЕКЦІЯХ
--     (сложні дані — Forge, потім големи, квести, Index і т.д.). Хто персиститься — нижче в ATTRS / PREFIXES / RegisterSection.
--   * Збереження: автозбереження кожні AUTOSAVE_SEC, при виході (PlayerRemoving), при закритті сервера (BindToClose),
--     після покупки за Robux (SaveNow). При виході замок знімається.
--   * Studio: якщо доступ до API вимкнено (Game Settings → Security → Enable Studio Access to API Services), працює
--     тимчасове сховище в пам'яті (уся логіка та ж, але дані не переживають закриття Studio).
--
-- API:
--   DataService.Start()
--   DataService.WaitLoaded(player) -> boolean   (true, коли дані завантажені й атрибути виставлені; false, якщо гравець вийшов/кікнутий)
--   DataService.IsLoaded(player) -> boolean
--   DataService.GetData(player) -> table?          (жива таблиця профілю: attrs, sections, stats, receipts)
--   DataService.GetSection(player, name) -> any?   (збережена секція, щойно після входу)
--   DataService.RegisterSection(name, fn(player, old) -> table?)   (постачальник секції; викликається перед кожним збереженням)
--   DataService.SaveNow(player) -> boolean         (зберегти негайно, yield; для покупок)
--   DataService.Capture(player)                     (зняти знімок перед тим, як ніша гравця зруйнується; викликає NicheService.release)
--   DataService.ResetStageScope(player)             (скидання даних етапу при переході на новий етап, GDD 6) + подія DataService.StageReset(player)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local DataService = {}
DataService.StageReset = Instance.new("BindableEvent")

-- у Studio пишемо в окреме сховище, щоб тестові дані не потрапляли куди справжнім гравцям; у опублікованій грі — справжнє
local STORE_NAME = game:GetService("RunService"):IsStudio() and "PlayerData_Studio" or "PlayerData"
local KEY_PREFIX = "P_"
local SCHEMA_VERSION = 1
local AUTOSAVE_SEC = 60
local LOCK_TTL = 90       -- с, після яких неоновлений замок вважається мертвим
local LOAD_TRIES = 8
local LOAD_RETRY_SEC = 4
local SAVE_TRIES = 5
local JOB = (game.JobId ~= "") and game.JobId or "studio"

-- ===== що зберігаємо (атрибути гравця) =====
-- scope: "global" — ніколи не скидається; "stage" — скидається на новому етапі (GDD 6).
-- default — що ставити новому гравцеві (nil = не ставити, нехай вирішить сервіс-власник); reset — значення при скиданні етапу.
local ATTRS = {
	-- не скидаються
	{ name = "Stage", default = 1, scope = "global" },          -- на якому етапі гравець
	{ name = "RollLuckLvl", default = 1, scope = "global" },    -- Roll Luck (ніколи не скидається)
	{ name = "Diamonds", default = 0, scope = "global" },
	{ name = "Tickets", default = 0, scope = "global" },
	{ name = "Rebirths", default = 0, scope = "global" },
	{ name = "DonateTier", default = 0, scope = "global" },     -- ступінь купленого x2 Money (0 = x1), MultiConfig
	{ name = "ExtraSlots", default = 0, scope = "global" },     -- +слоти големів (Extra Storage, MonetizationService)
	{ name = "MutSpeedTier", default = 0, scope = "global" },
	{ name = "RebirthSkips", default = 0, scope = "global" }, -- куплені Skip Rebirth, що чекають на ліміт мапи (RebirthService)
	{ name = "GroupGolem", default = nil, scope = "global" },  -- чи вже забрав групового Mushroom Golem (GroupGolemService)
	{ name = "IncomeRate", default = 0, scope = "global" },     -- останній дохід $/хв (IncomeService; тайм-скіп одразу після входу)
	{ name = "LuckRoll10", default = 0, scope = "global" },     -- Lucky Roll x10: скільки ролів у запасі (MonetizationService, RollService)
	{ name = "LuckRoll99", default = 0, scope = "global" },     -- Lucky Roll x99   -- ступінь Fast Mutations (MonetizationConfig.MUT_SPEED_TIERS)
	{ name = "RollRole", default = "Miner", scope = "global" },
	-- щоденні нагороди (DailyService, 29.10.2026)
	{ name = "DailySeed", default = nil, scope = "global" },
	{ name = "DailyIdx", default = 0, scope = "global" },
	{ name = "DailyLast", default = -1, scope = "global" },
	{ name = "DailyStreak", default = 0, scope = "global" }, -- який тип голема ролить станція (Miner / Carrier), RollRoleService
	-- скидаються на новому етапі
	{ name = "Money", default = nil, scope = "stage", reset = 0 },
	{ name = "RollStands", default = 1, scope = "stage", reset = 1 }, -- місця ролу
}
-- атрибути за префіксом (динамічні ключі)
local PREFIXES = {
	{ prefix = "Ore_", scope = "stage", reset = 0 },   -- руда в інвентарі
	{ prefix = "Bars_", scope = "stage", reset = 0 },  -- злитки в інвентарі
	{ prefix = "Pass_", scope = "global" },            -- куплені геймпаси (Pass_VIP і т.д.)
	{ prefix = "PassOff_", scope = "global" },         -- геймпас знято адміном (MonetizationService.checkPasses не повертає його з UserOwnsGamePassAsync)
	{ prefix = "Set_", scope = "global" },             -- налаштування гравця (SettingsService)
	{ prefix = "Stat_", scope = "global" },            -- статистика за весь час (StatsService): лідерборди й особистий борд
}
-- секції, які скидаються на новому етапі (Forge — GDD 6, пропозиція)
local STAGE_SECTIONS = { Forge = true }

local attrByName = {}
for _, a in ATTRS do attrByName[a.name] = a end

local function persisted(name: string): boolean
	if attrByName[name] then return true end
	for _, p in PREFIXES do
		if string.sub(name, 1, #p.prefix) == p.prefix then return true end
	end
	return false
end

-- ===== сховище (DataStore або пам'ять у Studio) =====
local store = nil
local useMemory = false
local memory: { [string]: string } = {}

local function update(key: string, fn)
	if useMemory then
		-- тестовий хук Studio: атрибут Seed_<ключ> на цьому скрипті — початковий запис; останній запис дзеркалиться в Mem_<ключ>
		if memory[key] == nil then
			local seed = script:GetAttribute("Seed_" .. key)
			if type(seed) == "string" and seed ~= "" then memory[key] = seed end
		end
		local old = memory[key] and HttpService:JSONDecode(memory[key]) or nil
		local new = fn(old)
		if new ~= nil then
			memory[key] = HttpService:JSONEncode(new)
			script:SetAttribute("Mem_" .. key, memory[key])
		end
		return
	end
	if not store then store = DataStoreService:GetDataStore(STORE_NAME) end
	return store:UpdateAsync(key, fn)
end

-- Studio без дозволу на API → перемикаємося на пам'ять (тільки в Studio)
local function maybeFallback(err: any): boolean
	if useMemory then return true end
	if RunService:IsStudio() and tostring(err):lower():find("studio") then
		useMemory = true
		warn("DataService: DataStore недоступний у Studio (ввімкніть Game Settings → Security → Enable Studio Access to API Services). Працює тимчасове сховище в пам'яті — дані не зберігаються між запусками.")
		return true
	end
	return false
end

-- ===== стан гравців =====
local states: { [Player]: any } = {}
local providers: { [string]: any } = {}
local pendingFinals = 0

-- JSON-безпечна копія (без NaN/inf, без функцій і Instance)
local function clean(v: any, depth: number?): any
	depth = depth or 0
	local t = typeof(v)
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then return 0 end
		return v
	elseif t == "string" or t == "boolean" then
		return v
	elseif t == "table" and depth < 12 then
		local out = {}
		for k, x in v do
			local ck = (typeof(k) == "number") and k or tostring(k)
			local cv = clean(x, depth + 1)
			if cv ~= nil then out[ck] = cv end
		end
		return out
	end
	return nil
end

local MIGRATIONS: { [number]: (any) -> () } = {
	-- [2] = function(d) ... end  -- приклад: коли змінимо схему, піднімемо SCHEMA_VERSION і додамо міграцію
}

local function reconcile(rec: any): any
	local d = (rec and rec.data) or {}
	local fromV = (rec and rec.v) or SCHEMA_VERSION
	for v = fromV + 1, SCHEMA_VERSION do
		local m = MIGRATIONS[v]
		if m then m(d) end
	end
	d.attrs = d.attrs or {}
	d.sections = d.sections or {}
	d.stats = d.stats or {}
	d.receipts = d.receipts or {}
	d.stats.joins = (d.stats.joins or 0) + 1
	d.stats.firstJoin = d.stats.firstJoin or os.time()
	d.stats.playSeconds = d.stats.playSeconds or 0
	return d
end

-- ===== запис і читання =====
local function lockedByOther(rec: any): boolean
	return rec ~= nil and rec.lock ~= nil and rec.lock.job ~= JOB and os.time() - (rec.lock.t or 0) < LOCK_TTL
end

-- бере замок і повертає запис: (record | nil, "locked" | "error" | nil)
local function acquire(userId: number): (any, string?)
	local key = KEY_PREFIX .. userId
	for attempt = 1, LOAD_TRIES do
		local result, status = nil, nil
		local ok, err = pcall(update, key, function(old)
			result, status = nil, nil
			if lockedByOther(old) then status = "locked"; return nil end
			old = old or { v = SCHEMA_VERSION }
			old.lock = { job = JOB, t = os.time() }
			result = old
			return old
		end)
		if ok and status == nil then return result or { v = SCHEMA_VERSION }, nil end
		if not ok then
			if maybeFallback(err) then continue end
			warn("DataService: помилка завантаження " .. userId .. ": " .. tostring(err))
		else
			warn("DataService: дані " .. userId .. " ще замкнені іншим сервером, спроба " .. attempt)
		end
		task.wait(LOAD_RETRY_SEC)
	end
	return nil, "locked"
end

-- пише знімок; release=true знімає замок. Повертає (ok, "lock" | "error" | nil)
local function write(userId: number, snap: any, release: boolean): (boolean, string?)
	local key = KEY_PREFIX .. userId
	for attempt = 1, SAVE_TRIES do
		local lost = false
		local ok, err = pcall(update, key, function(old)
			lost = false
			if lockedByOther(old) then lost = true; return nil end
			return { v = SCHEMA_VERSION, lock = (not release) and { job = JOB, t = os.time() } or nil, data = snap }
		end)
		if ok then
			if lost then return false, "lock" end
			return true, nil
		end
		if maybeFallback(err) then continue end
		warn("DataService: помилка запису " .. userId .. " (спроба " .. attempt .. "): " .. tostring(err))
		task.wait(1.5 * attempt)
	end
	return false, "error"
end

-- знімок поточного стану гравця (СИНХРОННО, без yield)
local function snapshot(p: Player): any
	local st = states[p]
	local d = st.data
	local attrs = {}
	for name, val in p:GetAttributes() do
		if persisted(name) then
			local c = clean(val)
			if c ~= nil then attrs[name] = c end
		end
	end
	d.attrs = attrs
	for name, fn in providers do
		local ok, res = pcall(fn, p, d.sections[name])
		if ok then d.sections[name] = res else warn("DataService: секція " .. name .. ": " .. tostring(res)) end
	end
	local nowT = os.time()
	d.stats.playSeconds += math.max(0, nowT - st.lastTick)
	st.lastTick = nowT
	d.stats.lastSeen = nowT
	return clean(d)
end

-- зберегти гравця; preSnap — вже знятий знімок (при виході)
local function saveState(p: Player, release: boolean, preSnap: any?): boolean
	local st = states[p]
	if not st or not st.loaded or st.offline then return true end
	while st.saving do task.wait() end
	st.saving = true
	local snap = preSnap or snapshot(p)
	local ok, why = write(p.UserId, snap, release)
	st.saving = false
	if not ok and why == "lock" and p.Parent then
		st.offline = true
		p:Kick("Сесію перехопив інший сервер. Увійдіть знову.")
	end
	return ok
end

-- ===== API =====
function DataService.IsLoaded(p: Player): boolean
	return p:GetAttribute("DataLoaded") == true
end

function DataService.WaitLoaded(p: Player): boolean
	while p.Parent == Players and p:GetAttribute("DataLoaded") ~= true do task.wait() end
	return p.Parent == Players and p:GetAttribute("DataLoaded") == true
end

function DataService.GetData(p: Player): any?
	local st = states[p]
	return st and st.loaded and st.data or nil
end

function DataService.GetSection(p: Player, name: string): any?
	local st = states[p]
	return st and st.data and st.data.sections[name] or nil
end

function DataService.RegisterSection(name: string, fn)
	providers[name] = fn
end

function DataService.SaveNow(p: Player): boolean
	return saveState(p, false)
end

function DataService.Capture(p: Player)
	local st = states[p]
	if st and st.loaded and not st.captured then st.captured = snapshot(p) end
end

function DataService.ResetStageScope(p: Player)
	local st = states[p]
	if not st or not st.loaded then return end
	for _, a in ATTRS do
		if a.scope == "stage" then p:SetAttribute(a.name, a.reset) end
	end
	for name in p:GetAttributes() do
		for _, pf in PREFIXES do
			if pf.scope == "stage" and string.sub(name, 1, #pf.prefix) == pf.prefix then p:SetAttribute(name, pf.reset) end
		end
	end
	for name in STAGE_SECTIONS do st.data.sections[name] = nil end
	DataService.StageReset:Fire(p)
end

-- ===== вхід / вихід =====
local function applyToPlayer(p: Player, d: any)
	for name, val in d.attrs do
		if persisted(name) then p:SetAttribute(name, val) end
	end
	for _, a in ATTRS do
		if p:GetAttribute(a.name) == nil and a.default ~= nil then p:SetAttribute(a.name, a.default) end
	end
end

local function onJoin(p: Player)
	if states[p] then return end
	local st = { data = nil, loaded = false, saving = false, offline = false, final = false, captured = nil, lastTick = os.time() }
	states[p] = st
	local rec, why = acquire(p.UserId)
	if not rec then
		if p.Parent == Players then
			p:Kick("Не вдалося завантажити ваші дані (" .. tostring(why) .. "). Спробуйте зайти через кілька хвилин.")
		end
		states[p] = nil
		return
	end
	st.data = reconcile(rec)
	st.loaded = true
	if p.Parent ~= Players then -- гравець вийшов під час завантаження: знімаємо замок, дані не міняємо
		write(p.UserId, rec.data or clean(st.data), true)
		states[p] = nil
		return
	end
	applyToPlayer(p, st.data)
	p:SetAttribute("DataLoaded", true)
end

local function finalize(p: Player)
	local st = states[p]
	if not st or st.final then return end
	st.final = true
	pendingFinals += 1
	if st.loaded and not st.offline then
		local snap = st.captured or snapshot(p)
		saveState(p, true, snap)
	end
	states[p] = nil
	pendingFinals -= 1
end

local started = false
function DataService.Start()
	if started then return end
	started = true
	Players.PlayerAdded:Connect(function(p) task.spawn(onJoin, p) end)
	Players.PlayerRemoving:Connect(function(p)
		local st = states[p]
		if st and st.loaded and not st.captured then st.captured = snapshot(p) end -- знімок синхронно, до скидання ніші
		task.spawn(finalize, p)
	end)
	for _, p in Players:GetPlayers() do task.spawn(onJoin, p) end

	-- автозбереження: кожен гравець зі своєю затримкою, щоб не було піку запитів
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SEC)
			for p, st in states do
				if st.loaded and not st.final and not st.offline then
					task.delay(math.random() * 10, function()
						if states[p] and not states[p].final then saveState(p, false) end
					end)
				end
			end
		end
	end)

	game:BindToClose(function()
		for p, st in states do
			if st.loaded and not st.final then task.spawn(finalize, p) end
		end
		local t0 = os.clock()
		while pendingFinals > 0 and os.clock() - t0 < 25 do task.wait() end
	end)
end

-- ПОВНЕ СКИДАННЯ гравця (адмін-панель, 29.10.2026): запис P_<userId> стає як у нового гравця.
-- keep — атрибути, які треба записати в новий профіль (напр. PassOff_* — зняти куплені геймпаси). Список receipts
-- (оброблені покупки за Robux) лишається, щоб стара покупка не видалась вдруге.
-- Гравець на ЦЬОМУ сервері: сесія стає offline (жодне збереження більше не перезапише скидання), запис
-- пишеться без замка, гравця кікає (kickText). Гравець офлайн: запис переписується, якщо його не тримає інший сервер.
-- Повертає (ok, "locked" | "error" | nil).
function DataService.Wipe(userId: number, keep: { [string]: any }?, kickText: string?): (boolean, string?)
	local p = Players:GetPlayerByUserId(userId)
	local st = p and states[p]
	if st then st.offline = true; st.captured = nil end -- від цього моменту saveState для нього нічого не пише
	local key = KEY_PREFIX .. userId
	local status = nil
	local attrs = {}
	for k, v in keep or {} do attrs[k] = clean(v) end
	local ok, err
	for _ = 1, 2 do
		ok, err = pcall(update, key, function(old)
			status = nil
			if not st and lockedByOther(old) then status = "locked"; return nil end
			local receipts = (old and old.data and old.data.receipts) or {}
			return { v = SCHEMA_VERSION, data = { attrs = attrs, sections = {}, stats = {}, receipts = receipts, wiped = os.time() } }
		end)
		if ok or not maybeFallback(err) then break end
	end
	if not ok then
		if st then st.offline = false end
		warn("DataService.Wipe " .. userId .. ": " .. tostring(err))
		return false, "error"
	end
	if status then return false, status end
	if p and p.Parent then p:Kick(kickText or "Your progress was reset. Rejoin to start over.") end
	return true, nil
end

-- для тестів у Studio
DataService._internal = { acquire = acquire, write = write, reconcile = reconcile, clean = clean, setMemory = function(v: boolean) useMemory = v end, memory = memory }

return DataService
