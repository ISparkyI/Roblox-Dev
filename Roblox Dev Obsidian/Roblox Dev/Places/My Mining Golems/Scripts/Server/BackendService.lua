--!nonstrict
-- BackendService — зв'язок гри з Google Таблицею (Apps Script Web App): новини Updates, коди Codes, відгуки Feedback.
-- Де: ServerScriptService/BackendService (ModuleScript). Запуск: NicheBoot (після InventoryService і CaveStandService).
-- Клієнт — StarterPlayerScripts/InfoWindows (вікна FEEDBACK / CODES / UPDATES). Нотатка — 2D/Feedback Codes Updates.
--
-- Налаштування: ServerStorage/BackendConfig (ModuleScript, повертає { URL, SECRET, VERSION }; атрибути URL / SECRET / VERSION
--   на ньому, якщо задані, мають перевагу). URL — адреса Web App (…/exec), SECRET — секретний ключ (параметр key).
--   Порожні URL або SECRET — бекенд вимкнено: Updates показує запасний список нижче (FALLBACK_UPDATES), Codes — «Codes are offline»,
--   Feedback — «Can't send right now». Потрібно ввімкнути Game Settings → Security → Allow HTTP Requests.
--
-- API таблиці (контракт):
--   GET  URL?action=updates&key=… → { ok, updates = { { id, version, date, title, titleColor, text, textColor, image, pinned } } }
--   GET  URL?action=codes&key=…   → { ok, codes = { { code, reward, amount, item, expires, maxUses, uses, active } } }
--   redeem   { action = "redeem", key, code, userId, name } → { ok } | { ok = false, error = "inactive" | "expired" | "limit" | "notfound" | "auth" }
--   feedback { action = "feedback", key, userId, name, category, text, map, money, version, placeId, jobId, device } → { ok } | { ok = false, error }
--   adminlog { action = "adminlog", key, placeId, jobId, events = { { t, e = "admin" | "suspect", by, what, data?, name?, n?, job } } } → { ok }
--   redeem, feedback і adminlog надсилаються GET-запитом: URL?action=redeem&key=…&data=<UrlEncode(JSON усіх полів, разом з key)>
--   (підключено 28.10.2026: POST давав HTTP 405 — Apps Script відповідає 302, і Roblox іде за редиректом тим самим POST).
-- Кеш: updates і codes — при старті й раз на REFRESH_SEC (60 с); код, якого нема в кеші, — ще одне оновлення (не частіше ніж раз на 10 с).
--
-- Дії клієнта (RemoteFunction ReplicatedStorage/Remotes/BackendAction, InvokeServer(дія, аргумент)):
--   "GetUpdates"            → { ok, offline, updates = {…} } (закріплені — першими, далі за порядком таблиці);
--   "SeenUpdates", { id… }  → позначити новини переглянутими (атрибут гравця UpdatesSeen — JSON-список id; секція "UpdatesSeen");
--   "Redeem", code          → { ok, reward, amount, item, text } | { ok = false, error = "offline" | "invalid" | "used" | "expired"
--                              | "limit" | "full" | "wait" | "busy" | "error", wait? };
--   "SendFeedback", { category, text, device } → { ok } | { ok = false, error = "offline" | "rate" | "short" | "long" | "filter" | "error", wait? }.
-- Redeem: UPPER + trim → код у кеші (active, expires за датою UTC — дійсний до кінця дня, maxUses) → гравець ще не використав
--   (секція DataService "Codes" — список кодів) → для Golem — місце в інвентарі → POST redeem (атомарний лічильник у таблиці) →
--   лише після ok — нагорода й код у секції (+ SaveNow). Нагороди: Diamonds / Tickets / Money — атрибути гравця (+amount);
--   Potion — Pot_<item> (+amount); Golem — InventoryService.AddGolem (id = CaveStandService.MaxId + 1, item "stone", "stone:carrier",
--   "stone@3" — мутація після @), amount — кількість големів.
-- Анти-спам: Redeem — 1 спроба на 2 с, 10 невдалих за 5 хв → пауза до 5 хв; Feedback — 1 на 120 с, текст 10–500 символів,
--   TextService:FilterStringAsync (у таблицю йде відфільтрований текст).
-- ТЕСТ (лише Studio): атрибут Mock = true на цьому скрипті — замість HTTP відповідає вбудований макет (MOCK нижче).
-- Відправник відгуку (перевірка тут, авторитетно): ≥ FEEDBACK_MIN_SESSION с у цій сесії і AccountAge ≥ FEEDBACK_MIN_ACCOUNT_DAYS,
--   інакше SendFeedback → { ok = false, error = "session", wait } | { ok = false, error = "account" }. Для показу у вікні — атрибути
--   гравця FeedbackReadyAt (час сервера, з якого можна), FeedbackBlock ("" | "account"), FeedbackMinSession, FeedbackMinAccountDays.
--   ТЕСТ (лише Studio, атрибути цього скрипта, за замовчуванням не задані): FeedbackTestBypass = true — без обмежень;
--   FeedbackTestMinSession (с) / FeedbackTestAccountAge (дні) — підміна порогу сесії / віку акаунта.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local Items = require(RS:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local CaveStandService = require(script.Parent:WaitForChild("CaveStandService"))

local BackendService = {}

local REFRESH_SEC = 60
local HTTP_TRIES = 3
local REDEEM_GAP = 2
local FAIL_WINDOW, FAIL_MAX = 300, 10
local FEEDBACK_GAP = 120
local FEEDBACK_MIN_SESSION = 300      -- с у цій сесії (від PlayerAdded, час сервера), перш ніж можна надіслати відгук
local FEEDBACK_MIN_ACCOUNT_DAYS = 3   -- мінімальний вік акаунта Roblox (Player.AccountAge, дні)
local FB_MIN, FB_MAX = 10, 500
local CATEGORIES = { Bug = true, Idea = true, Other = true }
local DEVICES = { Touch = true, Gamepad = true, Keyboard = true }
local REWARDS = { Diamonds = true, Tickets = true, Money = true, Potion = true, Golem = true, Bundle = true } -- 08.11.2026: + Bundle (кілька нагород)

-- запасний список новин (коли таблиця недоступна): коротко про останні оновлення гри
local FALLBACK_UPDATES = {
	{ id = "local-3", version = "v0.3", date = "2026-10-27", title = "One window at a time", titleColor = "#7fd0ff",
		text = "Opening a window now closes the previous one. **B** or **~** opens your inventory, **R** — the plot window.", textColor = "", image = "", pinned = false },
	{ id = "local-2", version = "v0.2", date = "2026-10-27", title = "Mutation auras", titleColor = "#ffd23a",
		text = "Golems with mutations now glow with their own aura. [#e6e9ef]Secret[/] golems leave comet trails!", textColor = "", image = "", pinned = false },
	{ id = "local-1", version = "v0.1", date = "2026-10-25", title = "Welcome to My Mining Golems!", titleColor = "",
		text = "Roll golems, place them on your plot and mine ore. Smelt bars in the **Workshop** and sell them for [#7ef05a]Money[/].", textColor = "", image = "", pinned = true },
}

-- макет таблиці для тестів у Studio (атрибут Mock)
local MOCK = {
	updates = {
		{ id = 102, version = "v0.4", date = "2026-10-28", title = "Codes, Feedback & Updates!", titleColor = "#ffd23a",
			text = "New windows in the top right: **Codes**, **Feedback** and **Updates**. Try code [#7ef05a]WELCOME[/] for free diamonds!", textColor = "", image = "", pinned = false },
		{ id = 101, version = "v0.3", date = "2026-10-27", title = "One window at a time", titleColor = "#7fd0ff",
			text = "Opening a window closes the previous one.\nBugs? Tell us in [#ff9ad9]Feedback[/] <3 & thanks!", textColor = "#e9edf1", image = "rbxassetid://126442692946356", pinned = false },
		{ id = 100, version = "v0.1", date = "2026-10-25", title = "Welcome!", titleColor = "", text = "Pinned post: **read me first**.", textColor = "", image = "", pinned = true },
	},
	codes = {
		{ code = "WELCOME", reward = "Diamonds", amount = 50, item = "", expires = "", maxUses = 0, uses = 0, active = true },
		{ code = "LUCKY", reward = "Potion", amount = 2, item = "Luck", expires = "", maxUses = 0, uses = 0, active = true },
		{ code = "STONE3", reward = "Golem", amount = 1, item = "stone@3", expires = "", maxUses = 0, uses = 0, active = true },
		{ code = "OLD", reward = "Money", amount = 100, item = "", expires = "2020-01-01", maxUses = 0, uses = 0, active = true },
		{ code = "FULL", reward = "Tickets", amount = 5, item = "", expires = "", maxUses = 3, uses = 3, active = true },
		{ code = "OFF", reward = "Tickets", amount = 5, item = "", expires = "", maxUses = 0, uses = 0, active = false },
	},
}

-- ===== налаштування =====
local function config(): any
	local mod = ServerStorage:FindFirstChild("BackendConfig")
	local c = {}
	if mod and mod:IsA("ModuleScript") then
		local ok, res = pcall(require, mod)
		if ok and type(res) == "table" then c = res end
	end
	local function pick(name: string): string
		local a = mod and mod:GetAttribute(name)
		if type(a) == "string" and a ~= "" then return a end
		local v = c[name]
		return type(v) == "string" and v or (v ~= nil and tostring(v) or "")
	end
	return { URL = pick("URL"), SECRET = pick("SECRET"), VERSION = pick("VERSION") }
end
local function mocked(): boolean
	return RunService:IsStudio() and script:GetAttribute("Mock") == true
end
local function online(): boolean
	if mocked() then return true end
	local c = config()
	return c.URL ~= "" and c.SECRET ~= ""
end

-- ===== HTTP =====
-- запит з pcall і повторами; повертає таблицю-відповідь або nil
local function request(method: string, query: string?, body: any?): any?
	if mocked() then
		task.wait(0.3)
		if method == "GET" then
			if query == "updates" then return { ok = true, updates = MOCK.updates } end
			if query == "codes" then return { ok = true, codes = MOCK.codes } end
		elseif body and body.action == "redeem" then
			for _, c in MOCK.codes do
				if c.code == body.code then
					if c.maxUses and c.maxUses > 0 and c.uses >= c.maxUses then return { ok = false, error = "limit" } end
					c.uses += 1
					return { ok = true }
				end
			end
			return { ok = false, error = "notfound" }
		elseif body and body.action == "adminlog" then
			script:SetAttribute("MockLastAdminLog", HttpService:JSONEncode(body))
			return { ok = true }
		elseif body and body.action == "feedback" then
			script:SetAttribute("MockLastFeedback", HttpService:JSONEncode(body))
			return { ok = true }
		end
		return nil
	end
	local c = config()
	if c.URL == "" or c.SECRET == "" then return nil end
	local opts
	if method == "GET" then
		opts = { Url = c.URL .. "?action=" .. HttpService:UrlEncode(query or "") .. "&key=" .. HttpService:UrlEncode(c.SECRET), Method = "GET" }
	else
		-- «POST»-дії (redeem, feedback) — теж GET: тіло JSON у параметрі data (POST після 302 Apps Script дає 405)
		body.key = c.SECRET
		opts = { Url = c.URL .. "?action=" .. HttpService:UrlEncode(tostring(body.action or "")) .. "&key=" .. HttpService:UrlEncode(c.SECRET)
			.. "&data=" .. HttpService:UrlEncode(HttpService:JSONEncode(body)), Method = "GET" }
	end
	for attempt = 1, HTTP_TRIES do
		local ok, res = pcall(HttpService.RequestAsync, HttpService, opts)
		if ok and res and res.Success then
			local okJ, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
			if okJ and type(data) == "table" then return data end
			warn("BackendService: відповідь не JSON (" .. tostring(method) .. " " .. tostring(query or (body and body.action)) .. ")")
			return nil
		end
		local why = ok and (tostring(res and res.StatusCode) .. " " .. tostring(res and res.StatusMessage)) or tostring(res)
		if attempt == HTTP_TRIES then
			warn("BackendService: запит не вдався (" .. tostring(method) .. " " .. tostring(query or (body and body.action)) .. "): " .. why)
		end
		-- redeem / feedback не повторюємо, якщо сервер відповів (лічильник міг уже зрости); повторюємо лише мережеві помилки
		if method == "POST" and ok then return nil end
		task.wait(attempt)
	end
	return nil
end

-- ===== кеш =====
local updatesCache = nil -- { … } або nil
local codesCache = nil   -- { [CODE] = запис } або nil
local codesAt = 0

local function str(v: any): string
	if v == nil then return "" end
	return tostring(v)
end
local function num(v: any): number
	return tonumber(v) or 0
end
local function bool(v: any): boolean
	if type(v) == "boolean" then return v end
	local s = string.lower(str(v))
	return s == "true" or s == "1" or s == "yes" or s == "так"
end
local function normCode(s: any): string
	return string.upper((string.gsub(str(s), "^%s*(.-)%s*$", "%1")))
end
local function normDate(v: any): string
	local s = str(v)
	local y, m, d = string.match(s, "^(%d%d%d%d)%-(%d%d?)%-(%d%d?)")
	if not y then return "" end
	return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
end

local function cleanUpdates(list: any): { any }
	local out, pinned = {}, {}
	if type(list) ~= "table" then return out end
	for i, u in list do
		if type(u) == "table" then
			local rec = { id = str(u.id ~= nil and u.id or i), version = str(u.version), date = normDate(u.date) ~= "" and normDate(u.date) or str(u.date),
				title = str(u.title), titleColor = str(u.titleColor), text = str(u.text), textColor = str(u.textColor),
				image = str(u.image), pinned = bool(u.pinned) }
			table.insert(rec.pinned and pinned or out, rec)
		end
	end
	for i = #pinned, 1, -1 do table.insert(out, 1, pinned[i]) end
	return out
end

local function refreshUpdates()
	local data = request("GET", "updates")
	if data and data.ok and type(data.updates) == "table" then updatesCache = cleanUpdates(data.updates) end
end
local function refreshCodes()
	codesAt = os.clock()
	local data = request("GET", "codes")
	if data and data.ok and type(data.codes) == "table" then
		local t = {}
		for _, c in data.codes do
			if type(c) == "table" and normCode(c.code) ~= "" then
				t[normCode(c.code)] = { code = normCode(c.code), reward = str(c.reward), amount = num(c.amount), item = str(c.item),
					expires = normDate(c.expires), maxUses = num(c.maxUses), uses = num(c.uses), active = c.active == nil or bool(c.active) }
			end
		end
		codesCache = t
	end
end

-- ===== дані гравця =====
local used: { [Player]: { [string]: boolean } } = {}
local seen: { [Player]: { string } } = {}
local lastTry: { [Player]: number } = {}
local fails: { [Player]: { number } } = {}
local lastFeedback: { [Player]: number } = {}
local busy: { [Player]: boolean } = {}
local joinedAt: { [Player]: number } = {}

local function publishSeen(p: Player)
	p:SetAttribute("UpdatesSeen", HttpService:JSONEncode(seen[p] or {}))
end

-- допуск до відгуку: (nil | "session" | "account", секунд до допуску). Тестові атрибути діють лише в Studio
local function studioAttr(name: string): any
	if not RunService:IsStudio() then return nil end
	return script:GetAttribute(name)
end
local function feedbackGate(p: Player): (string?, number)
	if studioAttr("FeedbackTestBypass") == true then return nil, 0 end
	local age = tonumber(studioAttr("FeedbackTestAccountAge")) or p.AccountAge
	if age < FEEDBACK_MIN_ACCOUNT_DAYS then return "account", 0 end
	local minS = tonumber(studioAttr("FeedbackTestMinSession")) or FEEDBACK_MIN_SESSION
	local left = (joinedAt[p] or os.time()) + minS - os.time()
	if left > 0 then return "session", left end
	return nil, 0
end
local function publishGate(p: Player)
	local block, left = feedbackGate(p)
	p:SetAttribute("FeedbackBlock", block == "account" and "account" or "")
	p:SetAttribute("FeedbackReadyAt", os.time() + math.max(0, left))
	p:SetAttribute("FeedbackMinSession", tonumber(studioAttr("FeedbackTestMinSession")) or FEEDBACK_MIN_SESSION)
	p:SetAttribute("FeedbackMinAccountDays", FEEDBACK_MIN_ACCOUNT_DAYS)
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local u = {}
	local sec = DataService.GetSection(p, "Codes")
	if type(sec) == "table" then for _, c in sec do if type(c) == "string" then u[normCode(c)] = true end end end
	used[p] = u
	local s = {}
	local ss = DataService.GetSection(p, "UpdatesSeen")
	if type(ss) == "table" then for _, id in ss do if type(id) == "string" or type(id) == "number" then table.insert(s, tostring(id)) end end end
	seen[p] = s
	publishSeen(p)
end

-- ===== Redeem =====
local function parseGolem(item: string): (string?, string, number)
	local s = string.lower(item)
	local kind, rest = string.match(s, "^([%w_]+)(.*)$")
	if not kind then return nil, "miner", 0 end
	local cls = string.match(rest, ":(%a+)") or "miner"
	local mut = tonumber(string.match(rest, "@(%d+)")) or 0
	local id = Catalog.id(kind)
	if not id then return nil, cls, mut end
	return id, Catalog.cls(cls), Catalog.mut(mut)
end

local function invCount(p: Player): number
	local ok, gl = pcall(HttpService.JSONDecode, HttpService, p:GetAttribute("InvGolems") or "[]")
	if not ok or type(gl) ~= "table" then return 0 end
	if Items.invGolemCount then
		local okP, placed = pcall(HttpService.JSONDecode, HttpService, p:GetAttribute("PlotPlaced") or "[]")
		local okC, n = pcall(Items.invGolemCount, gl, okP and placed or {})
		if okC and type(n) == "number" then return n end
	end
	return #gl
end

-- 08.11.2026: Reward = "Bundle" — кілька нагород одним кодом. Item: "Potion:Money:2, Tickets:2"
--   (Тип:Предмет:Кількість для Potion / Golem, Тип:Кількість для Diamonds / Tickets / Money; частини через кому або ;).
local function bundleParts(c: any): { any }
	local out = {}
	for part in string.gmatch(tostring(c.item or ""), "[^,;]+") do
		local bits = {}
		for b in string.gmatch(part, "[^:]+") do table.insert(bits, (string.gsub(b, "^%s*(.-)%s*$", "%1"))) end
		local r = bits[1]
		if r and REWARDS[r] and r ~= "Bundle" then
			local item, amount = "", tonumber(bits[2]) or 1
			if r == "Potion" or r == "Golem" then item = bits[2] or ""; amount = tonumber(bits[3]) or 1 end
			table.insert(out, { code = c.code, reward = r, item = item, amount = amount })
		end
	end
	return out
end

local function rewardText(c: any): string
	if c.reward == "Bundle" then
		local t = {}
		for _, sub in bundleParts(c) do table.insert(t, (string.gsub(rewardText(sub), "!$", ""))) end
		return table.concat(t, ", ") .. "!"
	end
	if c.reward == "Potion" then
		for _, d in Items.POTIONS do if d.key == c.item then return "+" .. c.amount .. " " .. d.name .. (c.amount > 1 and "s" or "") .. "!" end end
		return "+" .. c.amount .. " " .. c.item .. " Potion!"
	elseif c.reward == "Golem" then
		local id = parseGolem(c.item)
		local g = id and Catalog.GOLEMS[id]
		return "+" .. (c.amount > 1 and (c.amount .. " ") or "") .. ((g and g.name) or "Golem") .. "!"
	end
	return "+" .. c.amount .. " " .. c.reward .. "!"
end

local function grant(p: Player, c: any): boolean
	if c.reward == "Bundle" then
		local okAll = true
		for _, sub in bundleParts(c) do if not grant(p, sub) then okAll = false end end
		return okAll
	end
	local n = math.max(1, math.floor(c.amount))
	if c.reward == "Diamonds" or c.reward == "Tickets" or c.reward == "Money" then
		p:SetAttribute(c.reward, ((p:GetAttribute(c.reward) :: number?) or 0) + n)
		return true
	elseif c.reward == "Potion" then
		p:SetAttribute("Pot_" .. c.item, ((p:GetAttribute("Pot_" .. c.item) :: number?) or 0) + n)
		return true
	elseif c.reward == "Golem" then
		local id, cls, mut = parseGolem(c.item)
		if not id then return false end
		local okAll = true
		for _ = 1, n do
			local newId = CaveStandService.MaxId(p) + 1
			if not InventoryService.AddGolem(p, newId, id, cls, mut, "code:" .. tostring(c.code)) then okAll = false; break end
		end
		return okAll
	end
	return false
end

local function fail(p: Player, err: string): any
	local f = fails[p] or {}
	local now = os.clock()
	table.insert(f, now)
	while f[1] and now - f[1] > FAIL_WINDOW do table.remove(f, 1) end
	fails[p] = f
	return { ok = false, error = err }
end

local function redeem(p: Player, raw: any): any
	if type(raw) ~= "string" or #raw > 64 then return { ok = false, error = "invalid" } end
	if not used[p] then return { ok = false, error = "busy" } end
	if busy[p] then return { ok = false, error = "busy" } end
	local now = os.clock()
	-- пауза після 10 невдалих за 5 хв
	local f = fails[p]
	if f then
		while f[1] and now - f[1] > FAIL_WINDOW do table.remove(f, 1) end
		if #f >= FAIL_MAX then return { ok = false, error = "wait", wait = math.ceil(FAIL_WINDOW - (now - f[1])) } end
	end
	if lastTry[p] and now - lastTry[p] < REDEEM_GAP then return { ok = false, error = "wait", wait = math.ceil(REDEEM_GAP - (now - lastTry[p])) } end
	lastTry[p] = now
	local code = normCode(raw)
	if code == "" then return { ok = false, error = "invalid" } end
	if not online() then return { ok = false, error = "offline" } end
	busy[p] = true
	local res = (function()
		if not codesCache or (not codesCache[code] and os.clock() - codesAt > 10) then refreshCodes() end
		if not codesCache then return { ok = false, error = "offline" } end
		local c = codesCache[code]
		if not c or not REWARDS[c.reward] then return fail(p, "invalid") end
		if used[p][code] then return fail(p, "used") end
		if not c.active then return fail(p, "invalid") end
		if c.expires ~= "" and os.date("!%Y-%m-%d") > c.expires then return fail(p, "expired") end
		if c.maxUses > 0 and c.uses >= c.maxUses then return fail(p, "limit") end
		if c.reward == "Golem" then
			if not parseGolem(c.item) then return fail(p, "invalid") end
			if p:GetAttribute("InvReady") ~= true then return { ok = false, error = "busy" } end
			if invCount(p) + math.max(1, math.floor(c.amount)) > Items.maxGolems(p) then return { ok = false, error = "full" } end
		end
		if c.reward == "Bundle" and #bundleParts(c) == 0 then return fail(p, "invalid") end
		local data = request("POST", nil, { action = "redeem", code = code, userId = p.UserId, name = p.Name })
		if not data then return { ok = false, error = "error" } end
		if data.ok ~= true then
			local e = str(data.error)
			if e == "limit" then c.uses = math.max(c.uses, c.maxUses); return fail(p, "limit") end
			if e == "expired" then return fail(p, "expired") end
			if e == "inactive" or e == "notfound" then return fail(p, "invalid") end
			if e == "used" then used[p][code] = true; return fail(p, "used") end
			return { ok = false, error = "error" }
		end
		c.uses += 1
		used[p][code] = true
		if not grant(p, c) then warn("BackendService: нагорода коду " .. code .. " не видана повністю гравцю " .. p.UserId) end
		task.spawn(DataService.SaveNow, p)
		return { ok = true, reward = c.reward, amount = c.amount, item = c.item, text = rewardText(c) }
	end)()
	busy[p] = nil
	return res
end

-- ===== Feedback =====
local function deviceOf(v: any): string
	return (type(v) == "string" and DEVICES[v]) and v or "Keyboard"
end
local function sendFeedback(p: Player, arg: any): any
	if type(arg) ~= "table" then return { ok = false, error = "error" } end
	local block, left = feedbackGate(p)
	if block == "account" then return { ok = false, error = "account" } end
	if block == "session" then return { ok = false, error = "session", wait = left } end
	local text = type(arg.text) == "string" and string.gsub(arg.text, "^%s*(.-)%s*$", "%1") or ""
	local n = utf8.len(text) or #text
	if n < FB_MIN then return { ok = false, error = "short" } end
	if n > FB_MAX then return { ok = false, error = "long" } end
	local now = os.clock()
	if lastFeedback[p] and now - lastFeedback[p] < FEEDBACK_GAP then
		return { ok = false, error = "rate", wait = math.ceil(FEEDBACK_GAP - (now - lastFeedback[p])) }
	end
	if not online() then return { ok = false, error = "offline" } end
	if busy[p] then return { ok = false, error = "busy" } end
	busy[p] = true
	local filtered
	local okF, err = pcall(function()
		local r = TextService:FilterStringAsync(text, p.UserId, Enum.TextFilterContext.PrivateChat)
		filtered = r:GetNonChatStringForBroadcastAsync()
	end)
	if not okF or type(filtered) ~= "string" then
		busy[p] = nil
		warn("BackendService: фільтр тексту: " .. tostring(err))
		return { ok = false, error = "filter" }
	end
	local cfg = config()
	local data = request("POST", nil, {
		action = "feedback", userId = p.UserId, name = p.Name,
		category = CATEGORIES[arg.category] and arg.category or "Other", text = filtered,
		map = (p:GetAttribute("Stage") :: number?) or 1, money = (p:GetAttribute("Money") :: number?) or 0,
		version = cfg.VERSION ~= "" and cfg.VERSION or tostring(game.PlaceVersion), placeId = game.PlaceId,
		jobId = game.JobId ~= "" and game.JobId or "studio", device = deviceOf(arg.device),
	})
	busy[p] = nil
	if data and data.ok == true then
		lastFeedback[p] = os.clock()
		return { ok = true }
	end
	if data and data.error == "rate" then
		lastFeedback[p] = os.clock()
		return { ok = false, error = "rate", wait = FEEDBACK_GAP }
	end
	return { ok = false, error = "error" }
end

-- ===== дії клієнта =====
local function onInvoke(p: Player, action: any, arg: any): any
	if action == "GetUpdates" then
		if not online() then return { ok = true, offline = true, updates = cleanUpdates(FALLBACK_UPDATES) } end
		if not updatesCache then refreshUpdates() end
		if not updatesCache then return { ok = true, offline = true, updates = cleanUpdates(FALLBACK_UPDATES) } end
		return { ok = true, offline = false, updates = updatesCache }
	elseif action == "SeenUpdates" then
		if type(arg) ~= "table" or not seen[p] then return false end
		local s = seen[p]
		for i, id in arg do
			if i > 200 then break end
			if (type(id) == "string" and #id <= 64) or type(id) == "number" then
				id = tostring(id)
				if not table.find(s, id) then table.insert(s, id) end
			end
		end
		while #s > 300 do table.remove(s, 1) end
		publishSeen(p)
		return true
	elseif action == "Redeem" then
		local ok, res = pcall(redeem, p, arg)
		if not ok then busy[p] = nil; warn("BackendService: Redeem: " .. tostring(res)); return { ok = false, error = "error" } end
		return res
	elseif action == "SendFeedback" then
		local ok, res = pcall(sendFeedback, p, arg)
		if not ok then busy[p] = nil; warn("BackendService: Feedback: " .. tostring(res)); return { ok = false, error = "error" } end
		return res
	end
	return nil
end

local started = false
-- ===== журнал адмінів (аркуш AdminLog у таблиці) =====
-- AdminService кладе сюди важливі дії адмінів (give, grantall, role, ban, unban, kick, event, shutdown) і спроби доступу
-- до панелі без ролі (suspect). Раз на ADMINLOG_SEC пачками по 8 — GET action=adminlog, data = { events = […] }.
-- Apps Script дописує рядки в аркуш AdminLog і на suspect шле лист власнику. Таблиця вимкнена — черга чекає (до 300 подій).
local ADMINLOG_SEC = 20
local adminQueue = {}
function BackendService.AdminLog(ev: any)
	if type(ev) ~= "table" then return end
	if #adminQueue >= 300 then table.remove(adminQueue, 1) end
	table.insert(adminQueue, ev)
end
local function flushAdminLog()
	if #adminQueue == 0 or not online() then return end
	local batch = adminQueue
	adminQueue = {}
	for i = 1, #batch, 8 do
		local part = table.move(batch, i, math.min(i + 7, #batch), 1, {})
		local res = request("POST", nil, { action = "adminlog", placeId = game.PlaceId, jobId = game.JobId, events = part })
		if not (res and res.ok) then
			for k = i, #batch do table.insert(adminQueue, batch[k]) end
			break
		end
	end
end
BackendService._flushAdminLog = flushAdminLog

function BackendService.Start()
	if started then return end
	started = true
	DataService.RegisterSection("Codes", function(p, old)
		local u = used[p]
		if not u then return old end
		local t = {}
		for c in u do table.insert(t, c) end
		table.sort(t)
		return t
	end)
	DataService.RegisterSection("UpdatesSeen", function(p, old)
		return seen[p] or old
	end)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("BackendAction") or Instance.new("RemoteFunction")
	rf.Name = "BackendAction"; rf.Parent = remotes
	rf.OnServerInvoke = onInvoke
	local function joined(p: Player)
		joinedAt[p] = joinedAt[p] or os.time()
		publishGate(p)
		task.spawn(onPlayer, p)
	end
	Players.PlayerAdded:Connect(joined)
	for _, p in Players:GetPlayers() do joined(p) end
	-- тестові атрибути змінили (Studio) — оновити допуск у всіх
	script.AttributeChanged:Connect(function(name)
		if string.sub(name, 1, 12) == "FeedbackTest" then for _, p in Players:GetPlayers() do publishGate(p) end end
	end)
	Players.PlayerRemoving:Connect(function(p)
		task.delay(30, function() -- секції пишуться при виході — даємо DataService зняти знімок
			if p.Parent then return end
			used[p] = nil; seen[p] = nil; lastTry[p] = nil; fails[p] = nil; lastFeedback[p] = nil; busy[p] = nil; joinedAt[p] = nil
		end)
	end)
	-- журнал адмінів у таблицю: раз на ADMINLOG_SEC і при закритті сервера
	task.spawn(function()
		while true do
			task.wait(ADMINLOG_SEC)
			pcall(flushAdminLog)
		end
	end)
	game:BindToClose(function() pcall(flushAdminLog) end)
	-- кеш: при старті й раз на хвилину
	task.spawn(function()
		while true do
			if online() then
				pcall(refreshUpdates)
				pcall(refreshCodes)
			end
			task.wait(REFRESH_SEC)
		end
	end)
end

return BackendService
