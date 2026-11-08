--!strict
-- AnalyticsFunnels — події для Creator Hub → Analytics (Funnels). 08.11.2026.
-- Де: ServerScriptService/AnalyticsFunnels (Script). Сам по собі: лише слухає атрибути гравця, нічого не змінює.
-- Onboarding funnel (Funnels → Onboarding): навчання (TutorialService, атрибут TutStep 1..10) + крок 11 «Tutorial complete».
--   Крок k = гравець ДІЙШОВ до кроку навчання k (тобто виконав k − 1). Видно, на якому кроці новачки виходять з гри.
--   Пропустив навчання (Skip) — Custom event "TutorialSkipped" (значення — крок, на якому пропустив).
-- Progression (Funnels → Progression): шлях "Map" — почав / пройшов мапу N (атрибут Stage), шлях "Rebirth" — зробив N-й ребітх.
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local DataService = require(script.Parent:WaitForChild("DataService"))

local STEPS = { "Roll a Miner", "Buy the Miner", "Select Carrier", "Roll a Carrier", "Buy the Carrier", "Place golems",
	"Mine tutorial ore", "Collect ore", "Sell ore", "Buy plot upgrades" }
local DONE_STEP = #STEPS + 1

local function log(fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then warn("AnalyticsFunnels: " .. tostring(err)) end
end

local function onPlayer(p: Player)
	if not DataService.WaitLoaded(p) or p.Parent ~= Players then return end

	-- ===== навчання =====
	local logged: { [number]: boolean } = {}
	local lastStep: number? = nil -- бачили навчання в цій сесії (старим гравцям TutorialService одразу ставить TutorialDone)
	local function onboard(k: number)
		for i = 1, k do
			if not logged[i] then
				logged[i] = true
				local name = if i == DONE_STEP then "Tutorial complete" else STEPS[i]
				log(function() AnalyticsService:LogOnboardingFunnelStepEvent(p, i, name) end)
			end
		end
	end
	local function tut()
		local s = tonumber(p:GetAttribute("TutStep"))
		if not s then return end
		lastStep = math.clamp(math.floor(s), 1, #STEPS)
		onboard(lastStep :: number)
	end
	p:GetAttributeChangedSignal("TutStep"):Connect(tut)
	tut()
	p:GetAttributeChangedSignal("TutorialDone"):Connect(function()
		if p:GetAttribute("TutorialDone") ~= true or lastStep == nil then return end
		local at = lastStep
		lastStep = nil
		if p:GetAttribute("TutReward") ~= nil then
			onboard(DONE_STEP)
		else
			log(function() AnalyticsService:LogCustomEvent(p, "TutorialSkipped", at) end)
		end
	end)

	-- ===== мапи й ребітхи =====
	local stage = tonumber(p:GetAttribute("Stage")) or 1
	p:GetAttributeChangedSignal("Stage"):Connect(function()
		local s = tonumber(p:GetAttribute("Stage")) or 1
		if s > stage then
			for lv = stage + 1, s do
				log(function() AnalyticsService:LogProgressionCompleteEvent(p, "Map", lv - 1, "Map " .. (lv - 1)) end)
				log(function() AnalyticsService:LogProgressionStartEvent(p, "Map", lv, "Map " .. lv) end)
			end
		end
		stage = s
	end)
	local reb = tonumber(p:GetAttribute("Rebirths")) or 0
	p:GetAttributeChangedSignal("Rebirths"):Connect(function()
		local r = tonumber(p:GetAttribute("Rebirths")) or 0
		if r > reb then
			for n = reb + 1, r do
				log(function() AnalyticsService:LogProgressionCompleteEvent(p, "Rebirth", n, "Rebirth " .. n) end)
			end
		end
		reb = r
	end)
end

Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end

-- ===== 08.11.2026: проміжні підказки → Funnels (custom funnels Hint_Workshop / Hint_Crate) =====
-- Remotes/HintAction (RemoteEvent): клієнт → ("Step", hint, n) — дійшов до кроку n; ("Done", hint) — підказку пройдено
--   (атрибут гравця WsHintDone / CrateHintDone, зберігає DataService — більше не покажеться).
--   "Workshop" (WorkshopHintClient + ForgeWindow): 1 Hint shown · 2 Reached workshop · 3 Gave ore · 4 Woke golem (сервер сам: майстерня прокинулась)
--   "Crate" (CrateHintClient): 1 Hint shown · 2 Collected
-- LogFunnelStepEvent: funnelSessionId = UserId (підказка разова — одна «сесія» на гравця); кожен крок — раз за сесію сервера.
do
	local RS = game:GetService("ReplicatedStorage")
	local HINTS = {
		Workshop = { attr = "WsHintDone", steps = { "Hint shown", "Reached workshop", "Gave ore", "Woke golem" } },
		Crate = { attr = "CrateHintDone", steps = { "Hint shown", "Collected" } },
	}
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("HintAction") or Instance.new("RemoteEvent")
	ev.Name = "HintAction"; ev.Parent = remotes
	local seen: { [Player]: { [string]: boolean } } = {}
	local rate: { [Player]: number } = {}
	local function step(p: Player, name: string, n: number)
		local h = HINTS[name]
		if not h or not h.steps[n] then return end
		seen[p] = seen[p] or {}
		if seen[p][name .. n] then return end
		seen[p][name .. n] = true
		log(function() AnalyticsService:LogFunnelStepEvent(p, "Hint_" .. name, tostring(p.UserId), n, h.steps[n]) end)
	end
	ev.OnServerEvent:Connect(function(p: Player, action: any, name: any, n: any)
		local t = os.clock()
		if rate[p] and t - rate[p] < 0.2 then return end
		rate[p] = t
		if type(name) ~= "string" or not HINTS[name] then return end
		if action == "Step" and type(n) == "number" and n == n then
			step(p, name, math.floor(n))
		elseif action == "Done" then
			if p:GetAttribute(HINTS[name].attr) == true then return end
			p:SetAttribute(HINTS[name].attr, true)
			if name == "Crate" then step(p, name, 2); return end
			step(p, name, 3)
			-- крок 4: майстерня цього гравця прокинулась у цій сесії
			local okN, NS = pcall(require, script.Parent:FindFirstChild("NicheService"))
			local niche = okN and NS and NS.GetNiche and NS.GetNiche(p)
			local f = niche and niche:FindFirstChild("Forge")
			if not f then return end
			local conn: RBXScriptConnection? = nil
			conn = f:GetAttributeChangedSignal("State"):Connect(function()
				local st = f:GetAttribute("State")
				if st == "Waking" or st == "Working" then
					step(p, name, 4)
					if conn then conn:Disconnect() end
				end
			end)
			task.delay(3600, function() if conn then conn:Disconnect() end end)
		end
	end)
	Players.PlayerRemoving:Connect(function(p) seen[p] = nil; rate[p] = nil end)
end
