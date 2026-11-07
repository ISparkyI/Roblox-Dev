--!nonstrict
-- AutoSellService — Auto Sell (29.10.2026): усе, що потрапляє в інвентар (руда Ore_*, злитки Bars_* усіх мап), одразу продається за ціною
--   лавки SELL × TotalMulti (MultiService.Apply). Де: ServerScriptService/AutoSellService (Script, стартує сам).
-- Увімкнено, якщо є Auto Sell (PlotConfig.autoSellOwned: геймпас Pass_AutoSell або куплена картка на табло плоту) і головний
--   перемикач не вимкнено (Set_AutoSell ~= false). Не продається: вимкнене в налаштуваннях (Set_AutoSellOff — JSON-список
--   ключів), заблоковане замком в інвентарі (InvLocks), а також руда, яку забирає Auto Workshop (плавиться в злитки).
-- Продається лише НОВЕ (приріст атрибута), пачками раз на FLUSH с. Атрибути для клієнта: AutoSoldGain / AutoSoldT.
-- Remotes/AutoSellAction (RemoteEvent): ("Master", bool) — увімк. / вимк.; ("Item", ключ, bool) — продавати цей предмет чи ні.
--   ("All", bool) — SELL ALL / KEEP ALL (05.11.2026).
--   Set_* зберігає DataService (префікс Set_). Вікно налаштувань — StarterPlayerScripts/AutoSellWindow (кнопка SETTINGS на картці).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local SSS = game:GetService("ServerScriptService")

local Shared = RS:WaitForChild("Shared")
local Forge = require(Shared:WaitForChild("ForgeConfig"))
local PlotCfg = require(Shared:WaitForChild("PlotConfig"))
local DataService = require(SSS:WaitForChild("DataService"))
local MultiService = require(SSS:WaitForChild("MultiService"))

local FLUSH = 0.5

-- предмети, які можна продавати: ключ → { price, ore }
local ITEMS = {}
for _, o in Forge.ALL_ORES do
	ITEMS["Ore_" .. o.key] = { price = o.price, ore = o, bar = false }
	if Forge.canSmelt(o) then ITEMS["Bars_" .. o.key] = { price = o.price * Forge.BAR_MULT, ore = o, bar = true } end
end

local function decodeList(raw: any): { [string]: boolean }
	local set = {}
	if type(raw) ~= "string" or raw == "" then return set end
	local ok, l = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(l) == "table" then for _, k in l do if type(k) == "string" then set[k] = true end end end
	return set
end
local function active(p: Player): boolean
	return p:GetAttribute("Set_AutoSell") ~= false and PlotCfg.autoSellOwned(p)
end
-- руду поточної мапи, яка плавиться, забирає Auto Workshop (атрибут гравця AutoWorkshopOn ставить ForgeService)
local function heldForWorkshop(p: Player, it: any): boolean
	if it.bar or not Forge.canSmelt(it.ore) then return false end
	if p:GetAttribute("AutoWorkshopOn") ~= true then return false end
	return it.ore.stage == (tonumber(p:GetAttribute("Stage")) or 1)
end

local last: { [Player]: { [string]: number } } = {}
local queue: { [Player]: { [string]: number } } = {}

local function track(p: Player)
	if not DataService.WaitLoaded(p) then return end
	local l, q = {}, {}
	for k in ITEMS do l[k] = tonumber(p:GetAttribute(k)) or 0 end
	last[p], queue[p] = l, q
	p.AttributeChanged:Connect(function(name)
		if not ITEMS[name] or not last[p] then return end
		local v = tonumber(p:GetAttribute(name)) or 0
		local d = v - (l[name] or 0)
		l[name] = v
		if d > 0 then q[name] = (q[name] or 0) + d end
	end)
end

local function questAdd(p: Player, n: number)
	local ok, QS = pcall(require, SSS:FindFirstChild("QuestService"))
	if ok and QS and QS.Add then pcall(QS.Add, p, "Sell", n) end
end

local function flush(p: Player)
	local q = queue[p]
	if not q or next(q) == nil then return end
	if not active(p) then table.clear(q); return end
	local off = decodeList(p:GetAttribute("Set_AutoSellOff"))
	local locked = decodeList(p:GetAttribute("InvLocks"))
	local base, units = 0, 0
	for key, n in q do
		local it = ITEMS[key]
		if it and not off[key] and not locked[key] and not heldForWorkshop(p, it) then
			local have = tonumber(p:GetAttribute(key)) or 0
			local k = math.min(n, have)
			if k > 0 then
				p:SetAttribute(key, have - k)
				base += k * it.price
				units += k
			end
		end
	end
	table.clear(q)
	if base <= 0 then return end
	local amount = MultiService.Apply(p, base)
	p:SetAttribute("Money", (tonumber(p:GetAttribute("Money")) or 0) + amount)
	p:SetAttribute("AutoSoldGain", amount)
	p:SetAttribute("AutoSoldT", os.clock())
	questAdd(p, units)
end

-- налаштування з вікна
local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"; remotes.Parent = RS
local ev = remotes:FindFirstChild("AutoSellAction") or Instance.new("RemoteEvent")
ev.Name = "AutoSellAction"; ev.Parent = remotes
ev.OnServerEvent:Connect(function(p: Player, action: any, a: any, b: any)
	if not DataService.IsLoaded(p) then return end
	if action == "Master" then
		p:SetAttribute("Set_AutoSell", a == true)
	elseif action == "All" then -- 05.11.2026: SELL ALL (a = true) / KEEP ALL (a = false)
		local list = {}
		if a ~= true then for k in ITEMS do table.insert(list, k) end; table.sort(list) end
		p:SetAttribute("Set_AutoSellOff", HttpService:JSONEncode(list))
	elseif action == "Item" and type(a) == "string" and ITEMS[a] then
		local off = decodeList(p:GetAttribute("Set_AutoSellOff"))
		off[a] = (b ~= true) or nil
		local list = {}
		for k in off do table.insert(list, k) end
		table.sort(list)
		p:SetAttribute("Set_AutoSellOff", HttpService:JSONEncode(list))
	end
end)

Players.PlayerAdded:Connect(function(p) task.spawn(track, p) end)
for _, p in Players:GetPlayers() do task.spawn(track, p) end
Players.PlayerRemoving:Connect(function(p) last[p] = nil; queue[p] = nil end)

while true do
	task.wait(FLUSH)
	for p in queue do
		if p.Parent then local ok, err = pcall(flush, p); if not ok then warn("AutoSellService: " .. tostring(err)) end end
	end
end
