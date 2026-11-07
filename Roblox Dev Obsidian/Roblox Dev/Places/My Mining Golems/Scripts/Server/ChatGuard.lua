--!nonstrict
-- ChatGuard — антибот / антиспам у чаті (05.11.2026, пункт 3). Де: ServerScriptService/ChatGuard (Script).
-- Стандартний TextChatService: кожному TextChannel (RBXGeneral, RBXSystem, приватні RBXWhisper:…) ставимо ShouldDeliverCallback.
--   Вердикт рахуємо ОДИН раз на повідомлення (кеш за MessageId; колбек викликається для кожного одержувача).
--   Заблоковане не бачить ніхто; автору — системне повідомлення (Remotes/ChatGuardNotice → StarterPlayerScripts/ChatGuardClient).
-- Правила (CFG нижче):
--   • не частіше ніж раз на MIN_GAP с; перші NEW_SECS с у грі — раз на NEW_GAP с (просто блок, без штрафу);
--   • флуд: більше MAX_IN_WINDOW за WINDOW с — штраф;
--   • повтор того самого тексту за DUP_WINDOW с — штраф;
--   • посилання / «free robux» тощо (SCAM) — два штрафи; довгий повтор одного символу / задовге — штраф;
--   • штрафи → мут MUTES[штрафи] (3-й — 1 хв, 4-й — 5 хв, 5+ — 30 хв); штрафи згорають через STRIKE_DECAY с без порушень.
-- 06.11.2026: правила діють для ВСІХ (раніше власник і AdminRole були винятком — а в Studio AdminService дає owner усім,
--   тож антиспам у тестах не працював). Виняток — лише команди чату («/…»). Стандартний фільтр Roblox працює як є.
local Players = game:GetService("Players")
local TCS = game:GetService("TextChatService")
local RS = game:GetService("ReplicatedStorage")

local CFG = {
	MIN_GAP = 0.8,
	NEW_SECS = 120, NEW_GAP = 5,
	WINDOW = 10, MAX_IN_WINDOW = 5,
	DUP_WINDOW = 30,
	MAX_LEN = 180, MAX_RUN = 12,
	STRIKE_DECAY = 600,
	MUTES = { 0, 0, 60, 300, 1800 },
}
-- шукаємо в тексті без пробілів і розділових знаків («f r e e  r o b u x» теж ловиться)
local SCAM_FLAT = { "freerobux", "robuxfree", "robuxgenerator", "getrobux", "claimrobux", "freerbx", "discordgg", "bitly", "tinyurl" }
-- у звичайному (нижній регістр) тексті
local SCAM_PAT = { "https?://", "www%.", "%w%.com%f[%W]", "%w%.gg%f[%W]", "%w%.ru%f[%W]", "%w%.xyz%f[%W]", "%w%.io%f[%W]", "%w%.net%f[%W]" }

local remotes = RS:WaitForChild("Remotes")
local notice = remotes:FindFirstChild("ChatGuardNotice") or Instance.new("RemoteEvent")
notice.Name = "ChatGuardNotice"
notice.Parent = remotes

local state = {} -- [userId] = { joined, times = {}, last = 0, hist = { {t, norm} }, strikes, lastStrike, muteUntil, lastNotice }
local verdicts = {} -- [MessageId] = { ok, t }

local function st(uid: number)
	local s = state[uid]
	if not s then
		s = { joined = os.clock(), times = {}, last = 0, hist = {}, strikes = 0, lastStrike = 0, muteUntil = 0, lastNotice = 0 }
		state[uid] = s
	end
	return s
end
Players.PlayerAdded:Connect(function(p) st(p.UserId).joined = os.clock() end)
for _, p in Players:GetPlayers() do st(p.UserId) end
Players.PlayerRemoving:Connect(function(p) state[p.UserId] = nil end)

local function exempt(p: Player?): boolean
	return false -- 06.11.2026: без винятків (див. шапку)
end

local function tell(p: Player?, s, code: string, n: number?)
	if not p then return end
	local now = os.clock()
	if now - s.lastNotice < 1 then return end -- не засипати чат попередженнями
	s.lastNotice = now
	notice:FireClient(p, code, n)
end

local function strike(p: Player?, s, k: number)
	local now = os.clock()
	if now - s.lastStrike > CFG.STRIKE_DECAY then s.strikes = 0 end
	s.strikes += k
	s.lastStrike = now
	local m = CFG.MUTES[math.min(s.strikes, #CFG.MUTES)] or 0
	if m > 0 then
		s.muteUntil = now + m
		tell(p, s, "muted", math.ceil(m / 60))
		return true
	end
	return false
end

-- найдовший повтор одного символу (UTF-8, без урахування пробілів)
local function longestRun(text: string): number
	local best, run, prev = 0, 0, nil
	local ok = pcall(function()
		for _, c in utf8.codes(text) do
			if c ~= 32 then
				if c == prev then run += 1 else run = 1; prev = c end
				if run > best then best = run end
			end
		end
	end)
	return ok and best or 0
end

local function judge(msg: TextChatMessage): boolean
	local src = msg.TextSource
	if not src then return true end -- системні
	local p = Players:GetPlayerByUserId(src.UserId)
	if exempt(p) then return true end
	local s = st(src.UserId)
	local now = os.clock()
	local text = msg.Text or ""
	if text:sub(1, 1) == "/" then return true end -- команди чату
	-- мут
	if now < s.muteUntil then
		tell(p, s, "muted", math.ceil((s.muteUntil - now) / 60))
		return false
	end
	-- темп: новачок / загальний мінімальний інтервал (без штрафу)
	local isNew = now - s.joined < CFG.NEW_SECS
	local gap = isNew and CFG.NEW_GAP or CFG.MIN_GAP
	if now - s.last < gap then
		tell(p, s, isNew and "newbie" or "slow", math.ceil(gap - (now - s.last)))
		return false
	end
	-- флуд
	local keep = {}
	for _, t in s.times do if now - t < CFG.WINDOW then table.insert(keep, t) end end
	s.times = keep
	if #keep >= CFG.MAX_IN_WINDOW then
		if not strike(p, s, 1) then tell(p, s, "slow", math.ceil(CFG.WINDOW - (now - keep[1]))) end
		return false
	end
	local low = string.lower(text)
	local flat = string.gsub(low, "[%s%p_]", "")
	-- посилання й «free robux»
	for _, w in SCAM_FLAT do
		if string.find(flat, w, 1, true) then
			if not strike(p, s, 2) then tell(p, s, "link") end
			return false
		end
	end
	for _, pat in SCAM_PAT do
		if string.find(low, pat) then
			if not strike(p, s, 2) then tell(p, s, "link") end
			return false
		end
	end
	-- спам символами / задовге
	if (utf8.len(text) or #text) > CFG.MAX_LEN or longestRun(text) >= CFG.MAX_RUN then
		if not strike(p, s, 1) then tell(p, s, "spam") end
		return false
	end
	-- повтор того самого
	local hist = {}
	for _, h in s.hist do if now - h[1] < CFG.DUP_WINDOW then table.insert(hist, h) end end
	s.hist = hist
	if #flat >= 3 then -- короткі «ok», «gg» можна повторювати
		for _, h in hist do
			if h[2] == flat then
				if not strike(p, s, 1) then tell(p, s, "dup") end
				return false
			end
		end
	end
	-- пройшло
	s.last = now
	table.insert(s.times, now)
	table.insert(s.hist, { now, flat })
	if #s.hist > 6 then table.remove(s.hist, 1) end
	return true
end

local function deliver(msg: TextChatMessage, _target: TextSource): boolean
	local id = msg.MessageId
	local v = verdicts[id]
	if v == nil then
		local ok, res = pcall(judge, msg)
		v = { ok = (not ok) or res, t = os.clock() } -- помилка в перевірці — не блокуємо чат
		if not ok then warn("ChatGuard: " .. tostring(res)) end
		verdicts[id] = v
	end
	return v.ok
end

local function hook(ch: Instance)
	if ch:IsA("TextChannel") then ch.ShouldDeliverCallback = deliver end
end
for _, d in TCS:GetDescendants() do hook(d) end
TCS.DescendantAdded:Connect(hook)

-- чистка кешу вердиктів
task.spawn(function()
	while true do
		task.wait(60)
		local now = os.clock()
		for id, v in verdicts do if now - v.t > 60 then verdicts[id] = nil end end
	end
end)
