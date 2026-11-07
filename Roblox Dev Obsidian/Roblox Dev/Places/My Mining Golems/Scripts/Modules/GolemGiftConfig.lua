--!strict
-- GolemGiftConfig — подарунок голема іншому гравцю в лобі (05.11.2026, GDD/Plan - Golem Gifting).
-- Де: ReplicatedStorage/Shared/GolemGiftConfig (сервер і клієнт). Сервер — ServerScriptService/GolemGiftService,
--   клієнт — StarterPlayerScripts/GolemGiftClient.
-- Як дарувати: тримаєш голема в руці (InvHeld = "Golem_<id>") і підходиш до гравця → над ним кнопка GIFT →
--   вікно підтвердження → сервер ще раз перевіряє все і передає голема (той самий UID, GolemRegistry.Move).
-- Правила (check нижче — однакова перевірка на клієнті й сервері; усе з атрибутів гравців, вони реплікуються всім):
--   * лише лобі (не Marketplace, не арена боса);
--   * ексклюзиви (rarity = "Exclusive": груповий, тижневі, кейсові, Marketplace) дарувати не можна — кнопки немає;
--   * раз на COOLDOWN секунд від одного гравця (атрибут GiftCD — час сервера, до якого чекати);
--   * обидва гравці мають награти MIN_PLAYTIME (атрибут Stat_Playtime, StatsService);
--   * голем «з наступної мапи» (GolemCatalog map > Stage отримувача) — не можна: «Player must unlock MAP N»;
--   * повний інвентар отримувача (ItemConfig.invGolemCount ≥ maxGolems) — не можна;
--   * заблокований голем (InvLocks) — спершу розблокувати;
--   * 06.11.2026: налаштування отримувача Set_GiftMode — "none" нікому, "friends" лише друзям;
--   * 06.11.2026: голем переходить лише після ACCEPT отримувача (вікно GIFT FOR YOU!, ACCEPT_TIME с; DECLINE / мовчання — скасовано).
-- TEXT — усі написи (переклад — через стандартну локалізацію Roblox, тексти беруться автоматично).
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local HubCfg = require(Shared:WaitForChild("HubConfig"))

local C = {}

C.COOLDOWN = 30         -- с між подарунками одного гравця
C.MIN_PLAYTIME = 600    -- с гри (10 хв), після яких можна дарувати й отримувати
C.PROMPT_DIST = 10      -- з якої відстані видно кнопку GIFT над гравцем, стад
C.REACH = 18            -- сервер: максимальна відстань між гравцями, стад
C.ACCEPT_TIME = 30      -- 06.11.2026: скільки секунд отримувач має, щоб прийняти подарунок (далі — скасовано)
-- 06.11.2026: хто може дарувати мені — налаштування Set_GiftMode: "all" (за замовчуванням) | "friends" | "none" (SETTINGS → GIFTS FROM)
C.MODES = { "all", "friends", "none" }

C.TEXT = {
	prompt = "GIFT",
	title = "GIFT GOLEM?",
	to = "to %s",
	confirm = "GIFT", cancel = "CANCEL",
	sent = "You gifted %s to %s!",
	got = "%s gifted you %s!",
	errExclusive = "Exclusive golems can't be gifted",
	errNewSender = "Gifting unlocks after 10 min of play (%s left)",
	errNewTarget = "This player can receive gifts after 10 min of play",
	errCooldown = "You can gift again in %ss",
	errMap = "This player must unlock MAP %s first",
	errFull = "Player's inventory is full",
	errLocked = "Unlock this golem to gift it",
	errLobby = "Gifting works only in the lobby",
	errFar = "Get closer to the player",
	errGone = "This golem is no longer in your inventory",
	errBusy = "Try again in a moment",
	-- 06.11.2026: отримувач підтверджує подарунок
	offerTitle = "GIFT FOR YOU!",
	offerFrom = "from %s",
	accept = "ACCEPT", decline = "DECLINE",
	waiting = "Waiting for %s to accept the gift…",
	declined = "%s declined your gift",
	expired = "%s didn't answer your gift",
	errGiftsOff = "This player doesn't accept gifts",
	errFriendsOnly = "This player accepts gifts only from friends",
	errPending = "Wait for the answer to your previous gift",
	errTargetBusy = "This player is deciding on another gift",
}

local function decode(p: Player, a: string): any
	local s = p:GetAttribute(a)
	if type(s) ~= "string" or s == "" then return {} end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or {}
end
C.decode = decode

-- id голема в руці ("Golem_<id>") або nil
function C.heldId(p: Player): number?
	local h = p:GetAttribute("InvHeld")
	if type(h) ~= "string" or string.sub(h, 1, 6) ~= "Golem_" then return nil end
	return tonumber(string.sub(h, 7))
end

-- запис голема з інвентаря (без тих, що на плоті / виставлені на маркеті)
function C.golemOf(p: Player, id: number?): any
	if not id then return nil end
	if table.find(decode(p, "PlotPlaced"), id) then return nil end
	for _, l in decode(p, "MktLots") do if type(l) == "table" and l.id == id then return nil end end
	for _, g in decode(p, "InvGolems") do if type(g) == "table" and g.id == id then return g end end
	return nil
end

-- ексклюзив (не дарується)?
function C.isExclusive(kind: any): boolean
	local def = Catalog.get(kind)
	return def == nil or def.rarity == "Exclusive" or def.exclusive ~= nil
end

local function playtime(p: Player): number return tonumber(p:GetAttribute("Stat_Playtime")) or 0 end

local function mmss(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

-- перевірка подарунка: nil — можна; інакше (код, текст для гравця)
-- friend — чи дружать from і to (сервер — IsFriendsWith; клієнт — кеш, nil = ще невідомо, тоді не блокуємо)
function C.check(from: Player, to: Player, g: any, friend: boolean?): (string?, string?)
	local T = C.TEXT
	if HubCfg.isMarket() or from:GetAttribute("InBossArena") == true or to:GetAttribute("InBossArena") == true then return "lobby", T.errLobby end
	local mode = to:GetAttribute("Set_GiftMode")
	if mode == "none" then return "off", T.errGiftsOff end
	if mode == "friends" and friend == false then return "friends", T.errFriendsOnly end
	if type(g) ~= "table" then return "gone", T.errGone end
	if C.isExclusive(g.kind) then return "exclusive", T.errExclusive end
	if playtime(from) < C.MIN_PLAYTIME then return "newSender", string.format(T.errNewSender, mmss(C.MIN_PLAYTIME - playtime(from))) end
	if playtime(to) < C.MIN_PLAYTIME then return "newTarget", T.errNewTarget end
	local cd = (tonumber(from:GetAttribute("GiftCD")) or 0) - workspace:GetServerTimeNow()
	if cd > 0 then return "cooldown", string.format(T.errCooldown, tostring(math.ceil(cd))) end
	if table.find(decode(from, "InvLocks"), "Golem_" .. tostring(g.id)) then return "locked", T.errLocked end
	local def = Catalog.get(g.kind)
	local need = (def and def.map) or 1
	if need > (tonumber(to:GetAttribute("Stage")) or 1) then return "map", string.format(T.errMap, tostring(need)) end
	if Items.invGolemCount(decode(to, "InvGolems"), decode(to, "PlotPlaced")) >= Items.maxGolems(to) then return "full", T.errFull end
	return nil, nil
end

-- назва голема для повідомлень: «Gold Stone Golem» (мутація, крім Normal)
function C.nameOf(g: any): string
	local def = Catalog.get(g.kind)
	local n = def and def.name or tostring(g.kind)
	local m = Catalog.mutation(g.mut)
	if m and Catalog.mut(g.mut) > 0 then n = m.key .. " " .. n end
	return n
end

return C
