-- ShopActions — дії кнопок HUD, пов'язані з покупками за Robux.
-- Де: StarterPlayer/StarterPlayerScripts/ShopActions (LocalScript).
-- X2Money (з ReplicatedStorage/UIEvents/HUDButton) → вікно покупки Developer Product наступного ступеня x2 Money.
-- ProductId ступеня — в ReplicatedStorage/Shared/MonetizationConfig.MoneyTierProducts; якщо ще немає (0) — лише підказка в Output.
-- Саме нарахування робить сервер (MonetizationService.ProcessReceipt).
-- Звук успішної покупки (UISounds "purchase" = SoundService/PurchaseSuccess) — лише коли покупку справді видано:
--   x2 / x4 Money — атрибут DonateTier зрос (сервер обробив чек) після вікна покупки (завантаження даних
--   при вході не звучить); геймпаси — PromptGamePassPurchaseFinished з purchased = true.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds"))
local player = Players.LocalPlayer

-- ===== звук успішної покупки =====
local PENDING_FOR = 600 -- с: скільки чекаємо видачі після вікна покупки
local pendingUntil = 0
local lastTier = (player:GetAttribute("DonateTier") :: number?) or 0
player:GetAttributeChangedSignal("DonateTier"):Connect(function()
	local t = (player:GetAttribute("DonateTier") :: number?) or 0
	if t > lastTier and os.clock() < pendingUntil then
		pendingUntil = 0
		UISounds.play("purchase")
	end
	lastTier = t
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _productId, isPurchased)
	if userId == player.UserId and not isPurchased then pendingUntil = 0 end -- скасував — звуку не буде
end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, _passId, purchased)
	if p == player and purchased then UISounds.play("purchase") end
end)

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
	pendingUntil = os.clock() + PENDING_FOR
	MarketplaceService:PromptProductPurchase(player, id)
end)
