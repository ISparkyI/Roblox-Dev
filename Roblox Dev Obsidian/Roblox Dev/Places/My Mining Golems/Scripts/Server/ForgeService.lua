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
-- руда кузні — руда мапи її ніші (атрибут ніші Stage; 29.10.2026)
local function oresOf(f: Instance): { any }
	local n = f.Parent
	return Cfg.oresFor(n and n:GetAttribute("Stage") or 1)
end
local function stageOf(f: Instance): number
	local n = f.Parent
	return tonumber(n and n:GetAttribute("Stage")) or 1
end
local function wakeOf(f: Instance): any
	local n = f.Parent
	return Cfg.wakeFor(n and n:GetAttribute("Stage") or 1)
end
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
	local ORE = oresOf(f)
	local v = 0
	for _, o in ORE do v += attr(f, "Pal_" .. o.key) * o.price end
	return v
end
local function palCount(f: Model): number
	local ORE = oresOf(f)
	local c = 0
	for _, o in ORE do c += attr(f, "Pal_" .. o.key) end
	return c
end

-- 05.11.2026: префаби руди / продукції бувають складені (ChunkEmberite — Crust, ChunkEclipsium — Corona…): дочірні частини
--   масштабуються й ставляться разом із основною, а видимість на піддоні перемикається для всіх (T0 — власна прозорість частини)
local function fitSubs(g: BasePart, tpl: BasePart, k: number)
	local tsubs, gsubs = {}, {}
	for _, d in tpl:GetDescendants() do if d:IsA("BasePart") then table.insert(tsubs, d) end end
	for _, d in g:GetDescendants() do if d:IsA("BasePart") then table.insert(gsubs, d) end end
	for i, d in gsubs do
		local src = tsubs[i]
		if src then
			local rel = tpl.CFrame:ToObjectSpace(src.CFrame)
			d.Size = src.Size * k
			d.CFrame = g.CFrame * (rel - rel.Position + rel.Position * k)
		end
		d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		d:SetAttribute("T0", src and src.Transparency or d.Transparency)
		d.Transparency = 1
	end
end
local function setVis(p: BasePart, on: boolean)
	p.Transparency = on and ((p:GetAttribute("T0") :: number?) or 0) or 1
	for _, d in p:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency = on and ((d:GetAttribute("T0") :: number?) or 0) or 1 end
	end
end

-- ===== вигляд: табличка над колом, табло, піддони =====
local function refresh(f: Model)
	local ORE = oresOf(f)
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
				if t then setVis(c, (c:GetAttribute("Slot") :: number) <= attr(f, "Pal_" .. ORE[t].key)) end
			end
		end
		local s = forges[f]
		if pout and s then
			-- 05.11.2026: на піддоні — згруповано за типом (знизу вгору), а не впереміш у порядку виготовлення
			--   коли продукції більше, ніж місць, кожен тип отримує свою частку місць (по черзі), щоб було видно всі
			local cap, left, disp = 0, {}, {}
			for _, b in pout:GetChildren() do local k = b:GetAttribute("BarSlot") :: number?; if k and k > cap then cap = k end end
			for _, t in s.bars do left[t] = (left[t] or 0) + 1 end
			while #disp < cap do
				local added = false
				for t = 1, #ORE do if (left[t] or 0) > 0 and #disp < cap then table.insert(disp, t); left[t] -= 1; added = true end end
				if not added then break end
			end
			table.sort(disp)
			for _, b in pout:GetChildren() do
				local k = b:GetAttribute("BarSlot") :: number?
				if k then
					local t = disp[k]
					local bt = b:GetAttribute("BarType") :: number?
					if bt then -- на кожному місці по Union-злитку кожного типу (мідь / залізо): видно той, що збігається
						setVis(b, t == bt)
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
		local l = attr(f, "CapLvl"); local price = Cfg.capPrice(l, stageOf(f))
		if Cfg.capMax(l) or invGet(p, "Money") < price then return end
		invAdd(p, "Money", -price); f:SetAttribute("CapLvl", l + 1)
	elseif which == "Spd" then
		local l = attr(f, "SpdLvl"); local price = Cfg.spdPrice(l, stageOf(f))
		if Cfg.spdMax(l) or invGet(p, "Money") < price then return end
		invAdd(p, "Money", -price); f:SetAttribute("SpdLvl", l + 1)
	elseif which == "Oph" then
		local l = math.max(1, attr(f, "OphLvl")); local price = Cfg.ophPrice(l, stageOf(f))
		if Cfg.ophMax(l) or invGet(p, "Money") < price then return end
		invAdd(p, "Money", -price); f:SetAttribute("OphLvl", l + 1)
	elseif which == "Auto" then -- Auto Workshop: куплено / геймпас — перемикач ON / OFF; інакше покупка (з мапи AUTO_MIN_STAGE)
		if Cfg.autoOwned(p, f) then
			p:SetAttribute("Set_AutoWorkshop", p:GetAttribute("Set_AutoWorkshop") == false)
		else
			local ap = Cfg.autoPrice(stageOf(f)) -- × множник цін мапи (03.11.2026)
			if stageOf(f) < Cfg.AUTO_MIN_STAGE or invGet(p, "Money") < ap then return end
			invAdd(p, "Money", -ap); f:SetAttribute("AutoLvl", 2)
			p:SetAttribute("Set_AutoWorkshop", true)
		end
	end
	refresh(f)
end

local function init(f: Model)
	if forges[f] then return end
	forges[f] = { timer = 0, rr = 1, bars = {}, flying = 0 }
	local ORE = oresOf(f)
	-- піддони: кубики руди й злитки фарбуються в руду мапи цієї ніші (префаби мап — копії мапи 1)
	local pal = f:FindFirstChild("Pallets")
	if pal then
		for _, d in pal:GetDescendants() do
			if d:IsA("BasePart") then
				local t = d:GetAttribute("Ore") :: number?
				local bt = d:GetAttribute("BarType") :: number?
				if t and ORE[t] then d.Color = ORE[t].color; if d:IsA("UnionOperation") then d.UsePartColor = true end end -- кубики руди — Union: без UsePartColor лишались кольори мапи 1
				if bt and ORE[bt] then d.Color = ORE[bt].bar; if d:IsA("UnionOperation") then d.UsePartColor = true end end
			end
		end
		-- 05.11.2026: сира руда на піддоні Raw Ores — моделі Prefabs/ForgeProps/Chunk<Руда> (та сама руда, що випадає), а не перефарбовані кубики мапи 1
		local pin0 = pal:FindFirstChild("PalletOre")
		local fp0 = RS:FindFirstChild("Prefabs") and RS.Prefabs:FindFirstChild("ForgeProps")
		if pin0 and fp0 then
			for _, c in pin0:GetChildren() do
				local t = c:GetAttribute("Ore") :: number?
				local tpl = t and ORE[t] and fp0:FindFirstChild("Chunk" .. ORE[t].key)
				if c:IsA("BasePart") and tpl and tpl:IsA("BasePart") then
					local cs, gs = c.Size, tpl.Size
					-- розмір: найбільший вимір брили ~L (крупно, як кубики-заглушки), висота — не більше H
					local L, H = 1.4, 1.1
					local tall = gs.Y > math.max(gs.X, gs.Z) -- висока брила лежить на боці
					local k = math.min(L / math.max(gs.X, gs.Y, gs.Z), H / (tall and gs.X or gs.Y))
					local h = (tall and gs.X or gs.Y) * k
					local g = tpl:Clone()
					g.Size = gs * k
					g.CFrame = c.CFrame * CFrame.new(0, -cs.Y / 2 + h / 2, 0) * (tall and CFrame.Angles(0, 0, math.rad(90)) or CFrame.identity)
					fitSubs(g, tpl, k)
					g.Anchored = true; g.CanCollide = false; g.CanQuery = false; g.CanTouch = false
					g.Name = c.Name
					for k2, v in c:GetAttributes() do g:SetAttribute(k2, v) end
					g:SetAttribute("T0", tpl.Transparency)
					g.Transparency = 1
					g.Parent = pin0
					c:Destroy()
				end
			end
		end
		-- 05.11.2026: у префабі піддона є злитки лише типів 2 і 3 — продукт першої руди мапи не з'являвся; додаємо тип 1 (копія типу 2)
		local pb0 = pal:FindFirstChild("PalletBars")
		if pb0 and ORE[1] then
			local has1 = {}
			for _, b in pb0:GetChildren() do if b:GetAttribute("BarType") == 1 then has1[b:GetAttribute("BarSlot") or 0] = true end end
			for _, b in pb0:GetChildren() do
				local k = b:GetAttribute("BarSlot")
				if b:IsA("BasePart") and b:GetAttribute("BarType") == 2 and k and not has1[k] then
					has1[k] = true
					local c = b:Clone(); c:SetAttribute("BarType", 1); c.Color = ORE[1].bar; c.Transparency = 1; c.Parent = pb0
				end
			end
		end
		-- 05.11.2026: руда з product = "Cut" — на піддоні лежать огранені кристали (Prefabs/ForgeProps/Cut<Руда>), а не злитки:
		--   кожне місце злитка цього типу замінюємо моделлю кристала (лежить у межах злитка; найбільший масштаб із двох положень)
		local pout = pal:FindFirstChild("PalletBars")
		local fp = RS:FindFirstChild("Prefabs") and RS.Prefabs:FindFirstChild("ForgeProps")
		if pout and fp then
			for _, b in pout:GetChildren() do
				local bt = b:GetAttribute("BarType") :: number?
				local o = bt and ORE[bt]
				local tpl = o and fp:FindFirstChild(Cfg.productModel(o.key)) -- Cut<Руда> або Bar<Руда> (злиток мапи)
				if b:IsA("BasePart") and tpl and tpl:IsA("BasePart") then
					-- рівна укладка в межах злитка (довга вісь злитка — X): видовжений кристал лежить на боці уздовж злитка (1 шт.),
					--   круглий / приземистий самоцвіт стоїть рівно — 2 шт. у ряд
					local bs, gs = b.Size, tpl.Size
					local cut = Cfg.productOf(o.key) == "Cut"
					local long = cut and gs.Y > 1.3 * math.max(gs.X, gs.Z)
					local k, rot, h, offs
					if not cut then -- злиток із префабів (Prefabs/ForgeProps/Bar<Руда>) — точно на місці злитка, свої кольори
						k = math.min(bs.X / gs.X, bs.Y / gs.Y, bs.Z / gs.Z); rot = CFrame.identity; h = gs.Y * k; offs = { Vector3.zero }
					elseif long then
						k = math.min(bs.X / gs.Y, bs.Y / gs.X, bs.Z / gs.Z) * 0.92
						rot = CFrame.Angles(0, 0, math.rad(90)); h = gs.X * k
						-- тонкий кристал (обсидіан, кварц…) — два поруч поперек злитка, щоб шар був щільним
						offs = gs.Z * k * 2.1 <= bs.Z and { Vector3.new(0, 0, -bs.Z / 4), Vector3.new(0, 0, bs.Z / 4) } or { Vector3.zero }
					else
						k = math.min(bs.X / 2 / gs.X, bs.Y / gs.Y, bs.Z / gs.Z) * 0.92
						rot = CFrame.identity; h = gs.Y * k; offs = { Vector3.new(-bs.X / 4, 0, 0), Vector3.new(bs.X / 4, 0, 0) }
					end
					for _, o in offs do
						local g = tpl:Clone()
						g.Size = gs * k
						g.CFrame = b.CFrame * CFrame.new(o.X, -bs.Y / 2 + h / 2, o.Z) * rot
						fitSubs(g, tpl, k)
						g.Anchored = true; g.CanCollide = false; g.CanQuery = false; g.CanTouch = false
						g.Name = b.Name
						for k2, v in b:GetAttributes() do g:SetAttribute(k2, v) end
						g:SetAttribute("T0", tpl.Transparency)
						g.Transparency = 1
						g.Parent = pout
					end
					b:Destroy()
				end
			end
		end
	end
	f:SetAttribute("State", "Asleep"); f:SetAttribute("StateTime", now())
	for _, o in ORE do f:SetAttribute("Wake_" .. o.key, 0); f:SetAttribute("Pal_" .. o.key, 0); f:SetAttribute("Bars_" .. o.key, 0) end
	f:SetAttribute("CapLvl", 1); f:SetAttribute("SpdLvl", 1); f:SetAttribute("OphLvl", 1); f:SetAttribute("AutoLvl", 1); f:SetAttribute("Busy", false)
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
	if p:GetAttribute("TutStep") ~= nil then return end -- 06.11.2026: під час навчання (TutorialService) майстерня заблокована
	if action == "Upgrade" then -- клік по екрану табла (табло стоїть окремо від кола, тому без перевірки кола)
		local f = forgeOf(p)
		if f and (arg == "Cap" or arg == "Spd" or arg == "Oph" or arg == "Auto") then upgrade(f, p, arg) end
		return
	end
	if action == "TestOre" then -- ТЕСТ: +10 руди, як від големів (60 / 30 / 10%)
		local fo = forgeOf(p)
		local ORE = fo and oresOf(fo) or Cfg.oresFor(1)
		for _ = 1, 10 do local r = math.random(); invAdd(p, "Ore_" .. ORE[r < 0.6 and 1 or r < 0.9 and 2 or 3].key, 1) end
		return
	end
	local f = forgeOf(p)
	if not f or not inRing(p, f) then return end
	local st = f:GetAttribute("State")
	local locked = lockedSet(p)
	local ORE = oresOf(f)
	local WAKE = wakeOf(f)
	if action == "Give" and st == "Asleep" then
		for i, o in ORE do
			local need = WAKE.req[i] - attr(f, "Wake_" .. o.key)
			local k = math.min(invFree(p, "Ore_" .. o.key, locked), need)
			if k > 0 then invAdd(p, "Ore_" .. o.key, -k); f:SetAttribute("Wake_" .. o.key, attr(f, "Wake_" .. o.key) + k) end
		end
	elseif action == "Wake" and st == "Asleep" then
		for i, o in ORE do if attr(f, "Wake_" .. o.key) < WAKE.req[i] then return end end
		local wm = WAKE.money or 0
		if wm > 0 then
			if invGet(p, "Money") < wm then return end
			invAdd(p, "Money", -wm)
		end
		setState(f, "Waking")
		task.delay(Cfg.WAKE_TIME, function() if f.Parent and f:GetAttribute("State") == "Waking" then setState(f, "Working") end end)
	elseif action == "Put" and st == "Working" then
		local room = Cfg.capOf(attr(f, "CapLvl"), stageOf(f)) - palValue(f)
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
				local room = Cfg.capOf(attr(f, "CapLvl"), stageOf(f)) - palValue(f)
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
			local ORE = oresOf(f)
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
					-- 05.11.2026: огранований продукт (ForgeConfig product = "Cut") — анімація огранювання (CutSeq / CutType, нижні руки
					--   й різак), а не піч і ковадло (SmeltSeq)
					if Cfg.productOf(ORE[taken[1]].key) == "Cut" then
						f:SetAttribute("CutType", taken[1])
						f:SetAttribute("CutSeq", attr(f, "CutSeq") + 1)
					else
						f:SetAttribute("SmeltSeq", attr(f, "SmeltSeq") + 1)
					end
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
	local ORE = oresOf(f)
	local sec: any = {
		stage = (f.Parent and f.Parent:GetAttribute("Stage")) or 1,
		awake = (st == "Working" or st == "Waking"),
		CapLvl = attr(f, "CapLvl"), SpdLvl = attr(f, "SpdLvl"), OphLvl = math.max(1, attr(f, "OphLvl")),
		AutoLvl = math.max(1, attr(f, "AutoLvl")), -- Auto Workshop за Money (скидається разом із секцією на новій мапі)
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
	local ORE = oresOf(f)
	if (sec.stage or 1) ~= ((f.Parent and f.Parent:GetAttribute("Stage")) or 1) then return end -- дані іншого етапу
	f:SetAttribute("CapLvl", math.max(1, sec.CapLvl or 1))
	f:SetAttribute("SpdLvl", math.max(1, sec.SpdLvl or 1))
	f:SetAttribute("OphLvl", math.clamp(sec.OphLvl or 1, 1, Cfg.OPH_MAX))
	f:SetAttribute("AutoLvl", math.clamp(sec.AutoLvl or 1, 1, 2))
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

	local function onPlayer(p: Player) -- стартові значення (тільки якщо у збережених даних їх немає); тестову стартову руду прибрано
		if not DataService.WaitLoaded(p) then return end
		if p:GetAttribute("Money") == nil then p:SetAttribute("Money", Cfg.TEST_START.Money) end
		if p:GetAttribute("TotalMulti") == nil then p:SetAttribute("TotalMulti", 1) end
		for _, o in Cfg.ALL_ORES do
			if p:GetAttribute("Ore_" .. o.key) == nil then p:SetAttribute("Ore_" .. o.key, 0) end
			if p:GetAttribute("Bars_" .. o.key) == nil then p:SetAttribute("Bars_" .. o.key, 0) end
		end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end

	RunService.Heartbeat:Connect(step)

	-- Auto Workshop (29.10.2026): раз на секунду для кожної кузні, де власник має Auto Workshop (картка або геймпас) і перемикач
	-- не вимкнено: руда мапи з інвентаря → на піддон (спершу найдорожча, до місткості), готові злитки → в інвентар
	-- (далі їх може продати Auto Sell). Атрибут гравця AutoWorkshopOn — для AutoSellService (руду для переплавки той не продає).
	task.spawn(function()
		while true do
			task.wait(1)
			for f in forges do
				local ok, err = pcall(function()
					local p = f.Parent and NicheService.GetOwner(f.Parent)
					if not p or not DataService.IsLoaded(p) then return end
					local owned = Cfg.autoOwned(p, f)
					if p:GetAttribute("AutoWorkshopOwned") ~= owned then p:SetAttribute("AutoWorkshopOwned", owned) end -- для SETTINGS (SettingsWindow / SettingsService)
					local on = owned and p:GetAttribute("Set_AutoWorkshop") ~= false
					if p:GetAttribute("AutoWorkshopOn") ~= on then p:SetAttribute("AutoWorkshopOn", on) end
					if not on or f:GetAttribute("State") ~= "Working" then return end
					local ORE = oresOf(f)
					local locked = lockedSet(p)
					local room = Cfg.capOf(attr(f, "CapLvl"), stageOf(f)) - palValue(f)
					for i = #ORE, 1, -1 do
						local o = ORE[i]
						local k = Cfg.canSmelt(o) and math.min(invFree(p, "Ore_" .. o.key, locked), math.floor(room / o.price)) or 0
						if k > 0 then invAdd(p, "Ore_" .. o.key, -k); f:SetAttribute("Pal_" .. o.key, attr(f, "Pal_" .. o.key) + k); room -= k * o.price end
					end
					local took = false
					for _, o in ORE do
						local k = attr(f, "Bars_" .. o.key)
						if k > 0 then invAdd(p, "Bars_" .. o.key, k); questAdd(p, "Smelt", k); f:SetAttribute("Bars_" .. o.key, 0); took = true end
					end
					if took and forges[f] then table.clear(forges[f].bars) end
					refresh(f)
				end)
				if not ok then warn("ForgeService auto: " .. tostring(err)) end
			end
		end
	end)
end

return ForgeService
