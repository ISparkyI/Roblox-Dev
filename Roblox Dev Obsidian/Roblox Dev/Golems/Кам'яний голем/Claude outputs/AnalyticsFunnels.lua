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
