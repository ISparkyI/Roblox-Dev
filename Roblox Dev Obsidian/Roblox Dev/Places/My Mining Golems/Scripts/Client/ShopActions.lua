-- ShopActions — дії кнопок HUD, пов'язані з покупками за Robux.
-- Де: StarterPlayer/StarterPlayerScripts/ShopActions (LocalScript).
-- X2Money (з ReplicatedStorage/UIEvents/HUDButton) → вікно покупки Developer Product наступного ступеня x2 Money.
-- ProductId ступеня — в ReplicatedStorage/Shared/MonetizationConfig.MoneyTierProducts; якщо ще немає (0) — лише підказка в Output.
-- Саме нарахування робить сервер (MonetizationService.ProcessReceipt).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local player = Players.LocalPlayer

local uiEvents = RS:WaitForChild("UIEvents")
local hudEvent = uiEvents:WaitForChild("HUDButton")

hudEvent.Event:Connect(function(key)
	if key ~= "X2Money" then return end
	local tier = (player:GetAttribute("DonateTier") or 0) + 1
	if not MultiCfg.nextDonatePrice(tier - 1) then return end -- все вже куплено
	local id = MonCfg.MoneyTierProducts[tier]
	if not id or id == 0 then
		warn(("ShopActions: немає ProductId для ступеня %d (x%d, %d R$). Створіть Developer Product і впишіть ID в MonetizationConfig.MoneyTierProducts[%d]."):format(
			tier, MultiCfg.donateMult(tier), MultiCfg.nextDonatePrice(tier - 1), tier))
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end)
