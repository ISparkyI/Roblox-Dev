-- ShopActions — дії кнопок HUD, пов'язані з покупками за Robux.
-- Де: StarterPlayer/StarterPlayerScripts/ShopActions (LocalScript).
-- X2Money (з ReplicatedStorage/UIEvents/HUDButton) → вікно покупки Developer Product наступного ступеня x2 Money.
-- ProductId ступеня — в ReplicatedStorage/Shared/MonetizationConfig.MoneyTierProducts; якщо ще немає (0) — лише підказка в Output.
-- Саме нарахування робить сервер (MonetizationService.ProcessReceipt).
-- Звук успішної покупки (UISounds "purchase" = SoundService/PurchaseSuccess) — лише коли покупку справді видано:
--   10.11.2026: усі Developer Products (x2 Money, паки, тікети, скіпи, стенд Robux…) — RemoteEvent Remotes/PurchaseDone,
--   який сервер шле після видачі чека (MonetizationService.ProcessReceipt); геймпаси — PromptGamePassPurchaseFinished з purchased = true.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local MultiCfg = require(RS:WaitForChild("Shared"):WaitForChild("MultiConfig"))
local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))
local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds"))
local player = Players.LocalPlayer

-- ===== звук успішної покупки =====
task.spawn(function()
	local ev = RS:WaitForChild("Remotes"):WaitForChild("PurchaseDone", 60)
	if ev and ev:IsA("RemoteEvent") then
		ev.OnClientEvent:Connect(function() UISounds.play("purchase", 0.3) end)
	end
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
	MarketplaceService:PromptProductPurchase(player, id)
end)
