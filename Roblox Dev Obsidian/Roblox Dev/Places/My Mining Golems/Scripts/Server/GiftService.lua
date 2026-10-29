--!nonstrict
-- GiftService — подарунки іншим гравцям за Robux (кнопка з подарунком на кожній картці SHOP). 28–29.10.2026.
-- Де: ServerScriptService/GiftService (ModuleScript). Запуск: NicheBoot (після MonetizationService).
-- Потік: клієнт Remotes/GiftAction ("Select", giftKey, targetUserId) → сервер перевіряє (гравець на сервері, не сам, ще не має,
--   продукт існує), запам'ятовує ціль і productId і повертає id; клієнт відкриває оплату цього продукту.
--   giftKey: ключ геймпаса (Passes; з етапами — наступний етап цілі, продукт GiftProducts[етап]) | "MoneyTier" (наступний ступінь цілі,
--   MoneyTierProducts) | ключ MonetizationConfig.Products (бандли, Lucky Rolls, скіпи, діаманти) | "T<i>" (пакет тікетів).
--   Геймпаси — окремі продукти GiftProducts; Developer Products — ТОЙ САМИЙ продукт, що й для себе (ціль діє GIFT_TTL с;
--   ("Clear") — звичайна покупка для себе скасовує ціль; відмова від оплати теж).
--   ProcessReceipt (MonetizationService → ExtraGrant) → ціль на сервері — видаємо одразу; ні — у скриньку GiftInbox (DataStore),
--   видається при наступному вході. Ціль геймпаса загубилась — геймпас отримує сам покупець.
--   Статистика: Stat_RobuxGifted покупця += витрачені Robux (лідерборд TOP GIFTERS). Тости обом — Remotes/AdminBroadcast "toast".
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local NF = require(RS:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))

local GiftService = {}
-- buyerId → { [productId] = { key, pid, pass (ключ геймпаса або nil), to, name, label, t } } — окремо для кожного продукту
-- (29.10.2026: було одне місце на покупця — подарунок підряд іншого товару міг загубити ціль)
local pending: { [number]: { [number]: any } } = {}
local function pendOf(uid: number, pid: number): any
	local m = pending[uid]
	local e = m and m[pid]
	if e and os.clock() - e.t > (MonCfg.GIFT_TTL or 600) then m[pid] = nil; return nil end
	return e
end
local function dropPend(uid: number, pid: number?)
	local m = pending[uid]
	if not m then return end
	if pid then m[pid] = nil else pending[uid] = nil end
end
local STORE = RunService:IsStudio() and "GiftInbox_Studio" or "GiftInbox"
local useMemory = false
local memory: { [string]: { any } } = {}

local function toast(p: Player?, text: string, color: string)
	if not (p and p.Parent) then return end
	local r = RS:FindFirstChild("Remotes")
	local ev = r and r:FindFirstChild("AdminBroadcast")
	if ev then ev:FireClient(p, "toast", { text = text, color = color }) end
end
local function passName(key: string): string
	local d = MonCfg.Passes[key]
	return d and d.name or key
end

local function inbox(userId: number, fn: (list: { any }) -> { any })
	local key = tostring(userId)
	if not useMemory then
		local ok, err = pcall(function()
			DataStoreService:GetDataStore(STORE):UpdateAsync(key, function(old) return fn(type(old) == "table" and old or {}) end)
		end)
		if ok then return true end
		-- без доступу до DataStore (Studio / Team Test без API Access) — скринька в пам'яті сервера
		if tostring(err):lower():find("studio") or tostring(err):lower():find("api") then useMemory = true else warn("GiftService: ", err); return false end
	end
	memory[key] = fn(memory[key] or {})
	return true
end

-- налагодження в Studio / Team Test: рядки «[Gift] …» у консоль усіх клієнтів (вивід сервера Team Test не видно)
local function dbg(...)
	MonetizationService.Debug("[Gift]", ...)
end
local function givePass(target: Player, key: string, fromName: string)
	target:SetAttribute("Pass_" .. key, true)
	target:SetAttribute("PassOff_" .. key, nil)
	task.spawn(function() pcall(DataService.SaveNow, target) end)
	toast(target, fromName .. " gifted you " .. passName(key) .. "!", "purple")
end
-- Developer Product цілі: ступінь Money Boost — наступний ступінь цілі на момент видачі; решта — ефект продукту
local function giveProduct(target: Player, pid: number, label: string, fromName: string): boolean
	local ok
	local isTier = false
	for _, id in MonCfg.MoneyTierProducts do if id == pid then isTier = true end end
	if isTier then
		local nxt = (tonumber(target:GetAttribute("DonateTier")) or 0) + 1
		if not MultiCfg.DONATE_TIERS[nxt] then return false end
		MonetizationService.GrantMoneyTier(target, nxt)
		ok = true
	else
		ok = MonetizationService.GrantById(target, pid)
	end
	if ok then
		task.spawn(function() pcall(DataService.SaveNow, target) end)
		toast(target, fromName .. " gifted you " .. label .. "!", "purple")
	end
	return ok
end

-- назва подарунка для тостів і перевірка «вже має» (target) → pid, label, pass | nil, err
local function resolveReal(key: string, t: Player): (number?, string?, string?)
	local def = MonCfg.Passes[key]
	if def and not def.hidden then
		local stage = key
		if def.stages then
			stage = nil
			for _, k in def.stages do if t:GetAttribute("Pass_" .. k) ~= true then stage = k; break end end
			if not stage then return nil, "owned" end
		elseif t:GetAttribute("Pass_" .. key) == true then return nil, "owned" end
		local pid = MonCfg.GiftProducts[stage]
		if pid == nil then return nil, "pass" end
		if pid == 0 then return nil, "soon" end
		return pid, passName(stage), stage
	end
	if key == "MoneyTier" then
		local nxt = (tonumber(t:GetAttribute("DonateTier")) or 0) + 1
		if not MultiCfg.DONATE_TIERS[nxt] then return nil, "owned" end
		local pid = MonCfg.MoneyTierProducts[nxt]
		if not pid or pid == 0 then return nil, "soon" end
		return pid, NF.mult(MultiCfg.donateMult(nxt)) .. " Money Boost", nil
	end
	local i = tonumber(string.match(key, "^T(%d+)$"))
	if i and MonCfg.TicketProducts[i] then
		local tp = MonCfg.TicketProducts[i]
		if tp.id == 0 then return nil, "soon" end
		return tp.id, NF.full(tp.tickets) .. " Tickets"
	end
	local d = MonCfg.Products[key]
	if d then
		if d.id == 0 then return nil, "soon" end
		if d.once and t:GetAttribute("Pass_" .. key) == true then return nil, "owned" end
		local label = key
		if d.diamonds then label = NF.full(d.diamonds) .. " Diamonds"
		elseif d.skipMin then label = (d.skipMin < 60 and (d.skipMin .. " Min") or ((d.skipMin / 60) .. "h")) .. " Time Skip"
		elseif d.luckRoll then label = "x" .. d.luckRoll .. " Lucky Roll"
		elseif key == "StarterPack" then label = "Starter Pack"
		elseif key == "PotionPack" then label = "Potion Pack"
		elseif key == "ExtraStorage" then label = "Extra Storage" end
		return d.id, label
	end
	return nil, "pass"
end

-- (29.10.2026) кожен товар дарується ОКРЕМИМ продуктом «Gift: …»: геймпаси — GiftProducts[ключ],
-- Developer Products — GiftDevProducts[productId товару] (MonetizationConfig). Повертає giftPid, label, pass, realPid
local function resolve(key: string, t: Player): (number?, string?, string?, number?)
	local pid, label, pass = resolveReal(key, t)
	if not pid then return nil, label end
	if pass then return pid, label, pass, nil end
	local g = MonCfg.GiftDevProducts and MonCfg.GiftDevProducts[pid]
	if not g or g == 0 then return nil, "soon" end
	return g, label, nil, pid
end

-- обробка покупки (викликає MonetizationService.ProcessReceipt)
local function onGrant(buyer: Player, productId: number, info: any): boolean?
	local giftPass = MonCfg.giftPassOf(productId)
	local real = MonCfg.giftRealOf and MonCfg.giftRealOf(productId) or nil
	if not giftPass and not real then return nil end -- звичайна покупка (не подарунок)
	local pend = pendOf(buyer.UserId, productId)
	dbg("receipt", buyer.Name, productId, "pass", giftPass, "real", real, "target", pend and pend.name)
	dropPend(buyer.UserId, productId)
	local spent = info and tonumber(info.CurrencySpent) or 0
	if spent <= 0 and giftPass then spent = (MonCfg.Passes[giftPass] and MonCfg.Passes[giftPass].robux) or 0 end
	buyer:SetAttribute("Stat_RobuxGifted", (tonumber(buyer:GetAttribute("Stat_RobuxGifted")) or 0) + spent)
	if not pend then
		-- ціль загубилась: товар — покупцеві (геймпас, якого ще немає, або сам продукт)
		warn(("GiftService: gift %s from %s has no target"):format(tostring(giftPass or real), buyer.Name))
		if giftPass then
			if buyer:GetAttribute("Pass_" .. giftPass) ~= true then givePass(buyer, giftPass, "You")
			else toast(buyer, "Gift target was lost. Contact support!", "red") end
		else
			giveProduct(buyer, real, "your gift", "You")
		end
		return true
	end
	local target = Players:GetPlayerByUserId(pend.to)
	dbg("give", pend.label, "to", pend.name, "online", target ~= nil)
	if target and DataService.IsLoaded(target) then
		if giftPass then givePass(target, giftPass, buyer.Name)
		elseif not giveProduct(target, real, pend.label, buyer.Name) then return false end
	else
		local entry = giftPass and { pass = giftPass, from = buyer.Name } or { pid = real, label = pend.label, from = buyer.Name }
		if not inbox(pend.to, function(list) table.insert(list, entry); return list end) then return false end
	end
	toast(buyer, pend.label .. " gifted to " .. pend.name .. "!", "purple")
	return true
end

local function onAction(p: Player, action: any, key: any, targetId: any): any
	if action == "Clear" then return { ok = true } end -- (застаріле: подарунки тепер окремими продуктами, ціль не плутається з покупкою для себе)
	dbg("action", p.Name, action, key, targetId)
	if action ~= "Select" or type(key) ~= "string" or type(targetId) ~= "number" then return { ok = false } end
	local t = Players:GetPlayerByUserId(targetId)
	if not t or t == p then return { ok = false, err = "player" } end
	if not DataService.IsLoaded(t) then return { ok = false, err = "player" } end
	local pid, label, pass, real = resolve(key, t)
	dbg("select", p.Name, key, "->", t.Name, "gift", pid, label, real)
	if not pid then return { ok = false, err = label } end
	pending[p.UserId] = pending[p.UserId] or {}
	pending[p.UserId][pid] = { key = key, pid = pid, pass = pass, real = real, to = t.UserId, name = t.Name, label = label, t = os.clock() }
	return { ok = true, id = pid }
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local got = {}
	inbox(p.UserId, function(list)
		for _, g in list do table.insert(got, g) end
		return {}
	end)
	for _, g in got do
		if type(g) == "table" then
			local from = tostring(g.from or "Someone")
			if type(g.pass) == "string" and MonCfg.Passes[g.pass] then givePass(p, g.pass, from)
			elseif type(g.pid) == "number" then giveProduct(p, g.pid, tostring(g.label or "a gift"), from) end
		end
	end
end

function GiftService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("GiftAction") or Instance.new("RemoteFunction")
	rf.Name = "GiftAction"; rf.Parent = remotes
	rf.OnServerInvoke = onAction
	MonetizationService.ExtraGrant = onGrant
	-- відмова від оплати — ціль скасовується (наступна покупка цього продукту — для себе)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
		-- (29.10.2026) ціль НЕ скидаємо: у Studio подія може прийти з purchased = false до ProcessReceipt; ціль живе GIFT_TTL
		dbg("finished", userId, productId, tostring(purchased))
	end)
	Players.PlayerRemoving:Connect(function(p) task.delay(60, function() if not p.Parent then dropPend(p.UserId) end end) end)
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return GiftService
