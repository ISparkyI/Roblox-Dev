--!strict
-- TutorialService — інтерактивне навчання новачка (05.11.2026, GDD/Plan - Tutorial). Де: ServerScriptService/TutorialService. Запуск: NicheBoot.
-- Сервер лише стежить за подіями гри й перемикає крок; руку, підказки й ховання UI робить клієнт (TutorialClient).
-- Атрибути гравця (зберігає DataService): TutorialDone (true — пройшов / пропустив), TutStep (поточний крок, 1..10).
-- Службові (не зберігаються): TutRig — RollService дає першого голема каталогу (Wooden, безкоштовний, Normal);
--   TutOre — PlotService: лише навчальна руда (Coal, потім Iron з 1 HP) на першому плоті.
-- 05.11.2026 v2: крок 10 — 3 покупки на табло плоту (TutBuys 0..3), потім кінець.
-- Кроки: 1 рол майнера · 2 купити · 3 вибрати Carrier на екрані · 4 рол носія · 5 купити · 6 поставити (EQUIP BEST) ·
--   7 навчальна руда (майнер ламає, носій несе в ящик) · 8 COLLECT · 9 продати в Sell · 10 купити картку прокачки плоту →
--   кінець: TutorialDone = true, +REWARD діамантів. Remotes/TutorialAction ("Skip") — пропустити без нагороди.
-- Хто бачить: TutorialDone == nil і гравець новий (немає големів, Stage 1, 0 ребітхів); інакше одразу TutorialDone = true.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataService = require(script.Parent:WaitForChild("DataService"))

local TutorialService = {}
TutorialService.REWARD = 100
local BUYS = 3 -- скільки карток прокачки плоту купити на останньому кроці

local active: { [Player]: { base: number, money: number, lv: string, miss: number? } } = {}

local function decode(p: Player, attr: string): any
	local raw = p:GetAttribute(attr)
	local ok, v = pcall(HttpService.JSONDecode, HttpService, type(raw) == "string" and raw or "")
	return ok and v or nil
end
local function golems(p: Player): { any }
	local t = decode(p, "InvGolems")
	return type(t) == "table" and t or {}
end
local function oreTotal(p: Player): number
	local n = 0
	for k, v in p:GetAttributes() do
		if (string.sub(k, 1, 4) == "Ore_" or string.sub(k, 1, 5) == "Bars_") and type(v) == "number" then n += v end
	end
	return n
end
local function hasClass(p: Player, cls: string): boolean
	for _, g in golems(p) do if type(g) == "table" and g.cls == cls then return true end end
	return false
end
local function pendingHas(p: Player, cls: string): boolean
	local pend = decode(p, "RollPending")
	if type(pend) == "table" then
		for _, r in pend do if type(r) == "table" and r.cls == cls then return true end end
	end
	return false
end
local function plot1(p: Player): Model?
	local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
	local niche = okN and NS and NS.GetNiche(p)
	local plots = niche and niche:FindFirstChild("Plots")
	return plots and plots:FindFirstChild("Plot1") :: Model?
end
local function placedOnPlot1(p: Player): boolean
	local a = decode(p, "PlotAssign")
	local e = type(a) == "table" and (a["1"] or a[1])
	return type(e) == "table" and type(e.m) == "table" and #e.m > 0 and e.c ~= nil
end

local function finish(p: Player, skipped: boolean)
	active[p] = nil
	p:SetAttribute("TutRig", nil)
	p:SetAttribute("TutOre", nil)
	p:SetAttribute("TutBuys", nil)
	if not skipped then
		p:SetAttribute("Diamonds", (tonumber(p:GetAttribute("Diamonds")) or 0) + TutorialService.REWARD)
		p:SetAttribute("TutReward", os.clock()) -- клієнт: фінальна анімація (ставимо ДО TutorialDone)
		p:SetAttribute("BossTutWant", true) -- 10.11.2026: пройшов до кінця — через 2 хв навчання «бос» (BossTutorialService); SKIP — без нього
	end
	p:SetAttribute("TutStep", nil)
	p:SetAttribute("TutorialDone", true)
	task.spawn(function() pcall(DataService.SaveNow, p) end)
end

local function setStep(p: Player, n: number)
	local st = active[p]
	if not st then return end
	st.base = #golems(p)
	st.money = tonumber(p:GetAttribute("Money")) or 0
	st.lv = tostring(p:GetAttribute("PlotLv"))
	st.miss = nil
	p:SetAttribute("TutStep", n)
	p:SetAttribute("TutRig", (n >= 1 and n <= 5) or nil)
	if n == 3 or n == 1 then
		-- крок 1 — рол майнера (роль Miner); 3 — гравець сам перемикає на Carrier
		if n == 1 and p:GetAttribute("RollRole") ~= "Miner" then p:SetAttribute("RollRole", "Miner") end
	end
	if n <= 6 then p:SetAttribute("TutOre", "hold")
	elseif n == 7 then p:SetAttribute("TutOre", "run")
	elseif n >= 9 then p:SetAttribute("TutOre", nil) end
end

-- перевірка переходу (раз на 0,3 с)
local function check(p: Player)
	local st = active[p]
	if not st then return end
	local n = tonumber(p:GetAttribute("TutStep")) or 1
	-- 06.11.2026: далі ведемо, лише коли в інвентарі є потрібний клас (на кроці 5 — і майнер, і носій). Якщо гравець не купив
	--   випавшого голема, а ролить знов (рол замінив результат), через 1,5 с повертаємо на крок рола (2 → 1, 5 → 3 / 4).
	if n == 1 or n == 4 then
		local want = n == 1 and "miner" or "carrier"
		if hasClass(p, "miner") and hasClass(p, "carrier") then setStep(p, 6); return end -- обидва вже є
		if n == 1 and hasClass(p, "miner") then setStep(p, 3); return end
		if pendingHas(p, want) then setStep(p, n + 1) end
	elseif n == 2 or n == 5 then
		local want = n == 2 and "miner" or "carrier"
		if n == 2 and hasClass(p, "miner") then setStep(p, 3); return end
		if n == 5 and hasClass(p, "miner") and hasClass(p, "carrier") then setStep(p, 6); return end
		if n == 5 and not hasClass(p, "miner") and not pendingHas(p, "carrier") and hasClass(p, "carrier") then
			-- носія купив, а майнера немає (продав / віддав) — повертаємо на рол майнера
			setStep(p, 1); return
		end
		if pendingHas(p, want) then
			st.miss = nil
		else
			st.miss = st.miss or os.clock()
			if os.clock() - (st.miss :: number) > 1.5 then
				if n == 2 then setStep(p, 1)
				elseif p:GetAttribute("RollRole") == "Carrier" then setStep(p, 4)
				else setStep(p, 3) end
			end
		end
	elseif n == 3 then
		if p:GetAttribute("RollRole") == "Carrier" then setStep(p, 4) end
	elseif n == 6 then
		if placedOnPlot1(p) then setStep(p, 7) end
	elseif n == 7 then
		if p:GetAttribute("TutOre") == "mined" then
			local pl = plot1(p)
			local drops = pl and pl:FindFirstChild("Drops")
			local left = drops and #drops:GetChildren() or 0
			if left == 0 then setStep(p, 8) end
		end
	elseif n == 8 then
		local pl = plot1(p)
		local crate = pl and tonumber(pl:GetAttribute("CrateCount")) or 0
		if crate <= 0 and oreTotal(p) > 0 then setStep(p, 9) end
	elseif n == 9 then
		if oreTotal(p) == 0 and (tonumber(p:GetAttribute("Money")) or 0) > st.money then setStep(p, 10) end
	elseif n == 10 then
		-- 3 покупки на табло плоту (05.11.2026 v2); грошей уже не вистачає на жодну картку — теж кінець
		local lv = tostring(p:GetAttribute("PlotLv"))
		if lv ~= st.lv then
			st.lv = lv
			local k = (tonumber(p:GetAttribute("TutBuys")) or 0) + 1
			p:SetAttribute("TutBuys", k)
			if k >= BUYS then finish(p, false); return end
		end
		if (tonumber(p:GetAttribute("TutBuys")) or 0) >= 1 and (tonumber(p:GetAttribute("Money")) or 0) < 14 then finish(p, false) end
	end
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) or p.Parent ~= Players then return end
	if p:GetAttribute("TutorialDone") == true then return end
	local t0 = os.clock()
	while p.Parent == Players and p:GetAttribute("InvReady") ~= true and os.clock() - t0 < 30 do task.wait(0.2) end
	if p.Parent ~= Players then return end
	local fresh = #golems(p) == 0 and (tonumber(p:GetAttribute("Stage")) or 1) <= 1 and (tonumber(p:GetAttribute("Rebirths")) or 0) == 0
	local step = tonumber(p:GetAttribute("TutStep"))
	if not fresh and not step then
		p:SetAttribute("TutorialDone", true) -- старий гравець: навчання не показуємо
		return
	end
	active[p] = { base = 0, money = 0, lv = "" }
	step = step or 1
	-- повернувся посеред навчання: крок, що вже виконано, перевірить check()
	setStep(p, step)
end

local function onAction(p: Player, action: any): any
	if action == "Skip" and active[p] then finish(p, true); return { ok = true } end
	return { ok = false }
end

function TutorialService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local rf = remotes:FindFirstChild("TutorialAction") or Instance.new("RemoteFunction")
	rf.Name = "TutorialAction"; rf.Parent = remotes
	;(rf :: RemoteFunction).OnServerInvoke = onAction
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(p) active[p] = nil end)
	task.spawn(function()
		while true do
			task.wait(0.3)
			for p in active do pcall(check, p) end
		end
	end)
end

-- для тестів з адмінки / Studio: почати навчання заново
function TutorialService.Restart(p: Player)
	p:SetAttribute("TutorialDone", nil)
	p:SetAttribute("TutStep", 1)
	active[p] = { base = 0, money = 0, lv = "" }
	setStep(p, 1)
end

return TutorialService
