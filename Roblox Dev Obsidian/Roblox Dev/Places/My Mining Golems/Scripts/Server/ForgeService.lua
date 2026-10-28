--!strict
-- ForgeService — серверна логіка Forge (кузня з големом-ковалем) у кожній ніші.
-- Де: ServerScriptService/ForgeService (ModuleScript). Запуск: NicheBoot після NicheService.Start().
--
-- Стан кузні — атрибути моделі Niche*/Forge (їх читає клієнт ForgeClient):
--   State = Asleep | Waking | Working | Dozing, StateTime (час сервера, коли почався стан)
--   Wake_<Ore> — скільки руди вже віддано для пробудження
--   Pal_<Ore>  — руда на піддоні Ore;  Bars_<Ore> — злитки на піддоні Bars
--   CapLvl, SpdLvl, OphLvl — рівні покращень (OphLvl — Ore per Hit: скільки руди за один удар);  Busy — зараз щось переплавляється
--   SmeltSeq / SmeltType / SmeltCount — лічильник ударів, руда першого злитка і скільки руди переплавлено цим ударом
-- Дії гравця (RemoteEvent ReplicatedStorage/Remotes/ForgeAction): Give, Wake, Put (вся руда, що влізе), PutOre ({ore, n} — одна руда в потрібній кількості), Take, TestOre, Upgrade.
-- Покращення — кнопки на екрані табла UpgradePanel (клік мишкою; SurfaceGui робить ForgeClient): Upgrade + "Cap" | "Spd" | "Oph".
--
-- ТЕСТ: інвентаря ще немає, тому руда, злитки й гроші — атрибути гравця
--   Ore_<Ore>, Bars_<Ore>, Money. Коли з'явиться інвентар — замінити функції inv*/money*.

-- квести (QuestService): лічильник дій гравця; require ліниво — без циклів між модулями
local function questAdd(p: Player, stat: string, n: number?)
	local okQ, QS = pcall(require, script.Parent:FindFirstChild("QuestService"))
	if okQ and QS and QS.Add then QS.Add(p, stat, n) end
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local NicheService = require(script.Parent:WaitForChild("NicheService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MultiService = require(script.Parent:WaitForChild("MultiService"))

local ForgeService = {}
local ORE = Cfg.ORES
local forges: { [Model]: { timer: number, rr: number, bars: { number }, flying: number } } = {}

-- ===== тестовий «інвентар» на атрибутах гравця =====
local function invGet(p: Player, key: string): number return (p:GetAttribute(key) :: number?) or 0 end
local function invAdd(p: Player, key: string, n: number) p:SetAttribute(key, invGet(p, key) + n) end
-- заблоковані в інвентарі предмети (InvLocks — JSON-список ключів) у кузню не віддаються й не кладуться на піддон
local function lockedSet(p: Player): { [string]: boolean }
	local set = {}
	local HS = game:GetService("HttpService")
	local ok, l = pcall(HS.JSONDecode, HS, (p:GetAttribute("InvLocks") :: string?) or "[]")
	if ok and type(l) == "table" then for _, k in l do if type(k) == "string" then set[k] = true end end end
	return set
end
local function invFree(p: Player, key: string, locked: { [string]: boolean }): number return locked[key] and 0 or invGet(p, key) end

local function now() return workspace:GetServerTimeNow() end
local function attr(f: Model, k: string): number return (f:GetAttribute(k) :: number?) or 0 end
local function palValue(f: Model): number
	local v = 0
	for _, o in ORE do v += attr(f, "Pal_" .. o.key) * o.price end
	return v
end
local function palCount(f: Model): number
	local c = 0
	for _, o in ORE do c += attr(f, "Pal_" .. o.key) end
	return c
end

-- ===== вигляд: табличка над колом, табло, піддони =====
local function refresh(f: Model)
	local st = f:GetAttribute("State")
	local sign = f:FindFirstChild("Ring") and f.Ring:FindFirstChild("SignAnchor")
	if sign and sign:FindFirstChild("ForgeSign") then
		local txt = st == "Asleep" and "ASLEEP" or st == "Waking" and "WAKING UP..." or st == "Dozing" and "FALLING ASLEEP..."
			or ((palCount(f) > 0 or f:GetAttribute("Busy")) and "SMELTING" or (Cfg.WAIT_WORD .. "...")) -- статуси на табличці — КАПСОМ (GDD); крапки анімує клієнт (ForgeClient)
		sign.ForgeSign.State.Text = txt
	end
	local pal = f:FindFirstChild("Pallets")
	if pal then
		local pin, pout = pal:FindFirstChild("PalletOre"), pal:FindFirstChild("PalletBars")
		if pin then
			for _, c in pin:GetChildren() do
				local t = c:GetAttribute("Ore") :: number?
				if t then c.Transparency = (c:GetAttribute("Slot") :: number) <= attr(f, "Pal_" .. ORE[t].key) and 0 or 1 end
			end
		end
		local s = forges[f]
		if pout and s then
			for _, b in pout:GetChildren() do
				local k = b:GetAttribute("BarSlot") :: number?
				if k then
					local t = s.bars[k]
					local bt = b:GetAttribute("BarType") :: number?
					if bt then -- на кожному місці по Union-злитку кожного типу (мідь / залізо): видно той, що збігається
						b.Transparency = t == bt and 0 or 1
					else
						b.Transparency = t and 0 or 1
						if t then b.Color = ORE[t].bar end
					end
				end
			end
		end
	end
end

local function setState(f: Model, s: string)
	f:SetAttribute("State", s)
	f:SetAttribute("StateTime", now())
	refresh(f)
end

local function ownerOf(f: Model): Player?
	local niche = f.Parent
	return niche and niche:IsA("Model") and NicheService.GetOwner(niche) or nil
end

local function upgrade(f: Model, p: Player, which: string)
	if ownerOf(f) ~= p or f:GetAttribute("State") ~= "Working" then return end
	if which == "Cap" then
		local l = attr(f, "CapLvl"); local price = Cfg.capPrice(l)
		if invGet(p, "Money") < price then return end
		invAdd(p, "Money", -price); f:SetAttribute("CapLvl", l + 1)
	elseif which == "Spd" then
		local l = attr(f, "SpdLvl"); local price = Cfg.spdPrice(l)
		if Cfg.spdMax(l) or invGet(p, "Money") < price then return end
		invAdd(p, "Money", -price); f:SetAttribute("SpdLvl", l + 1)
	elseif which == "Oph" then
		local l = math.max(1, attr(f, "OphLvl")); local price = Cfg.ophPrice(l)
		if Cfg.ophMax(l) or invGet(p, "Money") < price then return end
		invAdd(p, "Money", -price); f:SetAttribute("OphLvl", l + 1)
	end
	refresh(f)
end

local function init(f: Model)
	if forges[f] then return end
	forges[f] = { timer = 0, rr = 1, bars = {}, flying = 0 }
	f:SetAttribute("State", "Asleep"); f:SetAttribute("StateTime", now())
	for _, o in ORE do f:SetAttribute("Wake_" .. o.key, 0); f:SetAttribute("Pal_" .. o.key, 0); f:SetAttribute("Bars_" .. o.key, 0) end
	f:SetAttribute("CapLvl", 1); f:SetAttribute("SpdLvl", 1); f:SetAttribute("OphLvl", 1); f:SetAttribute("Busy", false)
	f:SetAttribute("SmeltSeq", 0); f:SetAttribute("SmeltType", 1); f:SetAttribute("SmeltCount", 1)
	f.AncestryChanged:Connect(function() if not f:IsDescendantOf(workspace) then forges[f] = nil end end)
	refresh(f)
end

local function forgeOf(p: Player): Model?
	local niche = NicheService.GetNiche(p)
	local f = niche and niche:FindFirstChild("Forge")
	return f and f:IsA("Model") and f or nil
end

local function inRing(p: Player, f: Model): boolean
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local rc = f:FindFirstChild("Ring") and f.Ring:FindFirstChild("RingCenter") :: BasePart?
	if not hrp or not rc then return false end
	local d = rc.CFrame:PointToObjectSpace(hrp.Position)
	return Vector2.new(d.X, d.Z).Magnitude <= Cfg.RING_R + 2.5
end

local function onAction(p: Player, action: any, arg: any)
	if action == "Upgrade" then -- клік по екрану табла (табло стоїть окремо від кола, тому без перевірки кола)
		local f = forgeOf(p)
		if f and (arg == "Cap" or arg == "Spd" or arg == "Oph") then upgrade(f, p, arg) end
		return
	end
	if action == "TestOre" then -- ТЕСТ: +10 руди, як від големів (60 / 30 / 10%)
		for _ = 1, 10 do local r = math.random(); invAdd(p, "Ore_" .. ORE[r < 0.6 and 1 or r < 0.9 and 2 or 3].key, 1) end
		return
	end
	local f = forgeOf(p)
	if not f or not inRing(p, f) then return end
	local st = f:GetAttribute("State")
	local locked = lockedSet(p)
	if action == "Give" and st == "Asleep" then
		for i, o in ORE do
			local need = Cfg.WAKE_REQ[i] - attr(f, "Wake_" .. o.key)
			local k = math.min(invFree(p, "Ore_" .. o.key, locked), need)
			if k > 0 then invAdd(p, "Ore_" .. o.key, -k); f:SetAttribute("Wake_" .. o.key, attr(f, "Wake_" .. o.key) + k) end
		end
	elseif action == "Wake" and st == "Asleep" then
		for i, o in ORE do if attr(f, "Wake_" .. o.key) < Cfg.WAKE_REQ[i] then return end end
		local wm = Cfg.WAKE_MONEY or 0
		if wm > 0 then
			if invGet(p, "Money") < wm then return end
			invAdd(p, "Money", -wm)
		end
		setState(f, "Waking")
		task.delay(Cfg.WAKE_TIME, function() if f.Parent and f:GetAttribute("State") == "Waking" then setState(f, "Working") end end)
	elseif action == "Put" and st == "Working" then
		local room = Cfg.capOf(attr(f, "CapLvl")) - palValue(f)
		for i = #ORE, 1, -1 do -- спершу найдорожча руда
			local o = ORE[i]
			local k = Cfg.canSmelt(o) and math.min(invFree(p, "Ore_" .. o.key, locked), math.floor(room / o.price)) or 0 -- вугілля на піддон не кладемо
			if k > 0 then invAdd(p, "Ore_" .. o.key, -k); f:SetAttribute("Pal_" .. o.key, attr(f, "Pal_" .. o.key) + k); room -= k * o.price end
		end
	elseif action == "PutOre" and st == "Working" then -- одна руда: arg = { ore = "Coal", n = 7 }; n обмежується запасом гравця й місцем на піддоні ($)
		if type(arg) ~= "table" or type(arg.ore) ~= "string" or type(arg.n) ~= "number" or arg.n ~= arg.n then return end
		local want = math.floor(arg.n)
		for _, o in ORE do
			if o.key == arg.ore and Cfg.canSmelt(o) then
				local room = Cfg.capOf(attr(f, "CapLvl")) - palValue(f)
				local k = math.min(want, invFree(p, "Ore_" .. o.key, locked), math.floor(room / o.price))
				if k > 0 then invAdd(p, "Ore_" .. o.key, -k); f:SetAttribute("Pal_" .. o.key, attr(f, "Pal_" .. o.key) + k) end
				break
			end
		end
	elseif action == "Take" and st == "Working" then
		local s = forges[f]
		for _, o in ORE do
			local k = attr(f, "Bars_" .. o.key)
			if k > 0 then
				-- ТЕСТ (поки немає магазину): злитки одразу продаються, гроші йдуть на лічильник MoneyHUD
				if Cfg.TEST_SELL_BARS then invAdd(p, "Money", MultiService.Apply(p, k * o.price * Cfg.BAR_MULT)) else invAdd(p, "Bars_" .. o.key, k) end
				questAdd(p, "Smelt", k)
				f:SetAttribute("Bars_" .. o.key, 0)
			end
		end
		if s then table.clear(s.bars) end
	end
	refresh(f)
end

-- геймпас Fast Forge (Pass_FastForge власника ніші): переплавка вдвічі швидша
local function fastForge(f: Instance): boolean
	local niches = workspace:FindFirstChild("Niches")
	local n: Instance? = f
	while n and n.Parent ~= niches do n = n.Parent end
	if not n then return false end
	local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
	local owner = okN and NS and NS.GetOwner(n)
	return owner ~= nil and owner:GetAttribute("Pass_FastForge") == true
end
local function spdFor(f: Instance): number
	local d = Cfg.spdOf(attr(f, "SpdLvl"))
	if fastForge(f) then d *= 0.5 end
	return d
end

-- переплавка: один удар за spdOf(SpdLvl) с; за удар — до ophOf(OphLvl) руди (по черзі з усіх типів на піддоні).
-- Злитки зараховуються в кінці інтервалу (SmeltStart + SmeltDur).
local function step(dt: number)
	for f, s in forges do
		if f:GetAttribute("State") == "Working" then
			s.timer += dt
			if palCount(f) > 0 and s.timer >= spdFor(f) then
				s.timer = 0
				local taken: { number } = {}
				for _ = 1, Cfg.ophOf(math.max(1, attr(f, "OphLvl"))) do
					local t
					for k = 0, #ORE - 1 do
						local i = (s.rr + k - 1) % #ORE + 1
						if attr(f, "Pal_" .. ORE[i].key) > 0 then t = i; break end
					end
					if not t then break end
					s.rr = t % #ORE + 1
					f:SetAttribute("Pal_" .. ORE[t].key, attr(f, "Pal_" .. ORE[t].key) - 1)
					table.insert(taken, t)
				end
				if #taken > 0 then
					s.flying += 1
					f:SetAttribute("Busy", true)
					local dur = spdFor(f)
					f:SetAttribute("SmeltType", taken[1])
					f:SetAttribute("SmeltCount", #taken)
					f:SetAttribute("SmeltStart", now()) -- вікно кузні заповнює рядок цієї руди від SmeltStart за SmeltDur
					f:SetAttribute("SmeltDur", dur)
					f:SetAttribute("SmeltSeq", attr(f, "SmeltSeq") + 1)
					refresh(f)
					task.delay(dur, function() -- злитки — у кінці інтервалу переплавки (прив'язано до швидкості)
						if not f.Parent then return end
						for _, t in taken do
							table.insert(s.bars, t)
							f:SetAttribute("Bars_" .. ORE[t].key, attr(f, "Bars_" .. ORE[t].key) + 1)
						end
						s.flying -= 1
						f:SetAttribute("Busy", s.flying > 0)
						refresh(f)
					end)
				end
			end
		end
	end
end

-- ===== збереження кузні (секція "Forge" в DataService) =====
-- Зберігаємо: етап ніші, рівні покращень, чи голем прокинувся, прогрес пробудження, руду на піддонах і злитки.
local function forgeSection(p: Player, old: any): any
	local f = forgeOf(p)
	if not f or not forges[f] then return old end -- ніша вже зібрана заново / ще не готова — лишаємо попереднє
	local st = f:GetAttribute("State")
	local sec: any = {
		stage = (f.Parent and f.Parent:GetAttribute("Stage")) or 1,
		awake = (st == "Working" or st == "Waking"),
		CapLvl = attr(f, "CapLvl"), SpdLvl = attr(f, "SpdLvl"), OphLvl = math.max(1, attr(f, "OphLvl")),
	}
	for _, o in ORE do
		sec["Wake_" .. o.key] = attr(f, "Wake_" .. o.key)
		sec["Pal_" .. o.key] = attr(f, "Pal_" .. o.key)
		sec["Bars_" .. o.key] = attr(f, "Bars_" .. o.key)
	end
	return sec
end

local function applyForgeSection(f: Model, sec: any)
	local s = forges[f]
	if not s or type(sec) ~= "table" then return end
	if (sec.stage or 1) ~= ((f.Parent and f.Parent:GetAttribute("Stage")) or 1) then return end -- дані іншого етапу
	f:SetAttribute("CapLvl", math.max(1, sec.CapLvl or 1))
	f:SetAttribute("SpdLvl", math.max(1, sec.SpdLvl or 1))
	f:SetAttribute("OphLvl", math.clamp(sec.OphLvl or 1, 1, Cfg.OPH_MAX))
	table.clear(s.bars)
	for t, o in ORE do
		f:SetAttribute("Wake_" .. o.key, math.max(0, sec["Wake_" .. o.key] or 0))
		f:SetAttribute("Pal_" .. o.key, math.max(0, sec["Pal_" .. o.key] or 0))
		local bars = math.max(0, sec["Bars_" .. o.key] or 0)
		f:SetAttribute("Bars_" .. o.key, bars)
		for _ = 1, math.min(bars, 1000) do table.insert(s.bars, t) end
	end
	if sec.awake then -- голем уже працює: без повторної анімації пробудження
		f:SetAttribute("State", "Working")
		f:SetAttribute("StateTime", now() - Cfg.WAKE_TIME - 10)
	end
	refresh(f)
end

function ForgeService.Start()
	DataService.RegisterSection("Forge", forgeSection)
	NicheService.Claimed.Event:Connect(function(p: Player, niche: Model)
		local sec = DataService.GetSection(p, "Forge")
		if not sec then return end
		task.spawn(function()
			local f = niche:FindFirstChild("Forge")
			local t0 = os.clock()
			while f and not forges[f] and f.Parent and os.clock() - t0 < 5 do task.wait() end
			if f and forges[f] and NicheService.GetNiche(p) == niche then applyForgeSection(f :: Model, sec) end
		end)
	end)
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("ForgeAction") or Instance.new("RemoteEvent")
	ev.Name = "ForgeAction"; ev.Parent = remotes
	ev.OnServerEvent:Connect(onAction)

	local function watchNiche(n: Instance)
		local f = n:WaitForChild("Forge", 5)
		if f and f:IsA("Model") then init(f) end
	end
	local niches = workspace:WaitForChild("Niches")
	niches.ChildAdded:Connect(watchNiche)
	for _, n in niches:GetChildren() do task.spawn(watchNiche, n) end

	local function onPlayer(p: Player) -- ТЕСТ: стартова руда й гроші (тільки якщо у збережених даних їх немає)
		if not DataService.WaitLoaded(p) then return end
		if p:GetAttribute("Money") == nil then p:SetAttribute("Money", Cfg.TEST_START.Money) end
		if p:GetAttribute("TotalMulti") == nil then p:SetAttribute("TotalMulti", 1) end
		for i, o in ORE do
			if p:GetAttribute("Ore_" .. o.key) == nil then p:SetAttribute("Ore_" .. o.key, Cfg.TEST_START.Ore[i]) end
			if p:GetAttribute("Bars_" .. o.key) == nil then p:SetAttribute("Bars_" .. o.key, 0) end
		end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end

	RunService.Heartbeat:Connect(step)
end

return ForgeService
