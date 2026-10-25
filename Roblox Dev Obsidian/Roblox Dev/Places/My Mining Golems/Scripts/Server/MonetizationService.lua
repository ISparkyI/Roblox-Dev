--!nonstrict
-- MonetizationService — покупки за Robux: Developer Products (ступені x2 Money) і геймпаси (VIP і т.д.).
-- Де: ServerScriptService/MonetizationService (ModuleScript). Запуск: NicheBoot (після DataService).
--
-- Ступені x2 Money: кожна покупка = наступний ступінь (атрибут DonateTier). ProductId ступеня — у MonetizationConfig.MoneyTierProducts.
-- ProcessReceipt: дублікати відсікаються по PurchaseId (в профілі останні 200), перед PurchaseGranted дані зберігаються (SaveNow).
-- Геймпаси: при вході перевіряємо власність (UserOwnsGamePassAsync) → атрибут Pass_<ім'я>; при покупці в грі — теж.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local MonetizationService = {}
local MAX_RECEIPTS = 200

-- видати ступінь x2 Money (для покупок і тестів); повертає новий ступінь
function MonetizationService.GrantMoneyTier(p: Player, tier: number): number
	local cur = (p:GetAttribute("DonateTier") :: number?) or 0
	if tier > cur then
		p:SetAttribute("DonateTier", math.min(tier, MultiCfg.maxDonateTier()))
	else
		warn(("MonetizationService: %s купив ступінь %d, який вже є (%d)"):format(p.Name, tier, cur))
	end
	return p:GetAttribute("DonateTier")
end

local function tierOfProduct(productId: number): number?
	for tier, id in MonCfg.MoneyTierProducts do
		if id ~= 0 and id == productId then return tier end
	end
	return nil
end

local function checkPasses(p: Player)
	for name, def in MonCfg.Passes do
		if def.id ~= 0 then
			local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(p.UserId, def.id) end)
			if ok and owns then p:SetAttribute("Pass_" .. name, true) end
		end
	end
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = function(info)
		local p = Players:GetPlayerByUserId(info.PlayerId)
		if not p or not DataService.WaitLoaded(p) then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local data = DataService.GetData(p)
		if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local id = tostring(info.PurchaseId)
		if not table.find(data.receipts, id) then
			local tier = tierOfProduct(info.ProductId)
			if not tier then
				warn("MonetizationService: невідомий ProductId " .. tostring(info.ProductId))
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			MonetizationService.GrantMoneyTier(p, tier)
			table.insert(data.receipts, id)
			while #data.receipts > MAX_RECEIPTS do table.remove(data.receipts, 1) end
		end
		if DataService.SaveNow(p) then return Enum.ProductPurchaseDecision.PurchaseGranted end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
		if not purchased then return end
		for name, def in MonCfg.Passes do
			if def.id ~= 0 and def.id == passId then
				p:SetAttribute("Pass_" .. name, true)
				task.spawn(DataService.SaveNow, p)
			end
		end
	end)

	local function onPlayer(p: Player)
		if DataService.WaitLoaded(p) then checkPasses(p) end
	end
	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayer, p) end)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
end

return MonetizationService
