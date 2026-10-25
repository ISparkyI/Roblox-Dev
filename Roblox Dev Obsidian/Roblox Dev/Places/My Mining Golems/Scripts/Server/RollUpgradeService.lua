--!strict
-- RollUpgradeService — покращення ролу (табло Roll Upgrades) і підставки ролу в нішах.
-- Де: ServerScriptService/RollUpgradeService (ModuleScript). Запускає ServerScriptService/NicheBoot.
--
-- Покупки: RemoteEvent ReplicatedStorage/Remotes/RollUpgrade, аргумент "Luck" або "Stands".
--   Сервер рахує ціну (Shared/RollConfig), перевіряє гроші (атрибут Money), списує їх і піднімає рівень.
--   Захист: покупка змінює лише дані того, хто надіслав запит (його гроші, його рівні, його ніша);
--   працює лише для власника ніші і лише коли табло його ніші опущене (тобто він стоїть біля важеля).
--   Чужа ніша чи чуже табло нічого не дають: екран з кнопками будується тільки у своїй ніші.
-- Дані гравця (атрибути; зберігає DataService): RollLuckLvl (старт 1), RollLuck (%), RollStands (старт 1), Stage (1).
-- Підставки: у ніші стоїть стільки підставок, скільки їх у власника (вільна ніша — 1).
--   Шаблон ReplicatedStorage/Prefabs/RollStand ставиться в точку RollSystem/StandPoints/Point<i>
--   (сітка з кроком 10 стадів; порядок: 1 центр заднього ряду, 2 ліворуч, 3 праворуч,
--   4 і 5 обабіч важеля) у папку RollSystem/Stands як Stand<i>. Нова (куплена) підставка ставиться одразу на місце
--   з атрибутом SpawnAt = час сервера; анімацію появи програє клієнт (StarterPlayerScripts/RollStandFX).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local RollConfig = require(RS:WaitForChild("Shared"):WaitForChild("RollConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local RollUpgradeService = {}

local function ownerOf(NicheService, niche: Model): Player?
	return NicheService.GetOwner(niche)
end

local function syncStands(NicheService, niche: Model, animate: boolean)
	local rollSystem = niche:FindFirstChild("RollSystem")
	local points = rollSystem and rollSystem:FindFirstChild("StandPoints")
	if not points then return end
	local holder = rollSystem:FindFirstChild("Stands")
	if not holder then
		holder = Instance.new("Folder"); holder.Name = "Stands"; holder.Parent = rollSystem
	end
	local owner = ownerOf(NicheService, niche)
	local count = owner and (owner:GetAttribute("RollStands") or 1) or 1
	local template = RS:WaitForChild("Prefabs"):WaitForChild("RollStand")
	for i = 1, RollConfig.STANDS_MAX do
		local pt = points:FindFirstChild("Point" .. i) :: BasePart?
		local stand = holder:FindFirstChild("Stand" .. i)
		if i <= count and not stand and pt then
			local s = template:Clone()
			s.Name = "Stand" .. i
			s:SetAttribute("Index", i)
			s:PivotTo(pt.CFrame)
			if animate then s:SetAttribute("SpawnAt", workspace:GetServerTimeNow()) end -- клієнт програє появу
			s.Parent = holder
		elseif i > count and stand then
			stand:Destroy()
		end
	end
end

function RollUpgradeService.Start()
	local NicheService = require(script.Parent:WaitForChild("NicheService")) :: any
	local niches = workspace:WaitForChild("Niches")
	local remote = RS:WaitForChild("Remotes"):WaitForChild("RollUpgrade") :: RemoteEvent

	local function nicheOf(p: Player): Model?
		return NicheService.GetNiche(p)
	end

	local function initPlayer(p: Player)
		if not DataService.WaitLoaded(p) then return end -- рівні беремо зі збережених даних
		if p:GetAttribute("RollLuckLvl") == nil then p:SetAttribute("RollLuckLvl", 1) end
		if p:GetAttribute("RollStands") == nil then p:SetAttribute("RollStands", 1) end
		p:SetAttribute("RollLuck", RollConfig.luckPercent(p:GetAttribute("RollLuckLvl")))
		p:GetAttributeChangedSignal("RollStands"):Connect(function()
			local n = nicheOf(p)
			if n then syncStands(NicheService, n, true) end
		end)
	end
	for _, p in Players:GetPlayers() do task.spawn(initPlayer, p) end
	Players.PlayerAdded:Connect(function(p) task.spawn(initPlayer, p) end)

	-- ніші: підставки після збірки, клейму і звільнення
	for _, n in niches:GetChildren() do if n:IsA("Model") then syncStands(NicheService, n, false) end end
	niches.ChildAdded:Connect(function(n)
		if n:IsA("Model") then task.defer(syncStands, NicheService, n, false) end
	end)
	NicheService.Claimed.Event:Connect(function(_, n) task.defer(syncStands, NicheService, n, false) end)
	NicheService.Released.Event:Connect(function(_, n) if n and n.Parent then task.defer(syncStands, NicheService, n, false) end end)

	local last: { [Player]: number } = {}
	remote.OnServerEvent:Connect(function(p: Player, what: any)
		if last[p] and os.clock() - last[p] < 0.15 then return end
		last[p] = os.clock()
		local niche = nicheOf(p)
		local screen = niche and niche:FindFirstChild("RollUpgradeScreen")
		if not (screen and screen:GetAttribute("Open") == true) then return end -- лише власник біля свого опущеного табла
		local money = p:GetAttribute("Money") or 0
		if what == "Luck" then
			local lvl = p:GetAttribute("RollLuckLvl") or 1
			local price = RollConfig.luckPrice(lvl)
			if money < price then return end
			p:SetAttribute("Money", money - price)
			p:SetAttribute("RollLuckLvl", lvl + 1)
			p:SetAttribute("RollLuck", RollConfig.luckPercent(lvl + 1))
		elseif what == "Stands" then
			local count = p:GetAttribute("RollStands") or 1
			local price = RollConfig.standPrice(count, p:GetAttribute("Stage") or 1)
			if not price or money < price then return end
			p:SetAttribute("Money", money - price)
			p:SetAttribute("RollStands", count + 1)
		end
	end)
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end

return RollUpgradeService
