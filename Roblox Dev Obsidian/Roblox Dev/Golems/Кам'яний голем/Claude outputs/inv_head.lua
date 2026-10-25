-- InventoryUI — інвентар гравця: хотбар унизу (9 слотів «C · Сяйво») і вікно INVENTORY (кнопка рюкзака в HUD або клавіша B).
-- Де: StarterPlayer/StarterPlayerScripts/InventoryUI (LocalScript). Інтерфейс будується кодом (ScreenGui Hotbar і InventoryWindow).
-- Макет: 2D/Inventory (веб-макет v3, затверджений). Стиль — як вікна Forge / Sell (studs, «стиль A», квадратне).
--
-- Хотбар: 1–9 або клік — взяти предмет у руку (лаймова рамка, слот піднімається, над хотбаром «Coal ×25 · in hand»), ще раз — прибрати.
--   Порожній слот — лише слабке біле сяйво в центрі. Нові руда / злитки / зілля самі стають у вільний слот (сервер).
--   Стандартний рюкзак Roblox вимкнено (StarterGui Backpack).
-- Вікно: вкладки Golems / Ores·Bars / Potions (власні іконки), сітка слотів 5 у ряд (гортається колесом, перетягуванням і повзунком),
--   клік по предмету — картка внизу (Hold / Put Away, Hotbar / Unpin). Внизу ліворуч: червона кнопка з кошиком — режим видалення,
--   жовта із замком — режим блокування. У режимі інші вкладки ховаються, з'являються Select All (на все — Deselect All) і
--   Delete (N) → вікно підтвердження / Lock (N) або Unlock (N). Заблоковане не видаляється (притемнене, «LOCKED»), але його можна
--   брати в руку. Cancel або Esc — вихід з режиму.
-- Наведення на слот: ×1,025 і нахил до 1,5° (нахиляється лише картка слота), натискання 0,96. Звук наведення слота —
--   SoundService/SlotHover (порожній SoundId — тиша; спільний з вікном Sell).
-- Дані: атрибути гравця Ore_*, Bars_*, Pot_*, InvGolems, InvLocks, InvHotbar, InvHeld (ставить сервер InventoryService);
--   дії — Remotes/InventoryAction ("Delete", "Lock", "Hotbar", "Hold"). Предмети — Shared/ItemConfig.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local CAS = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local Forge = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local Action = RS:WaitForChild("Remotes"):WaitForChild("InventoryAction")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- стандартний рюкзак Roblox — вимкнено (свій хотбар)
task.spawn(function()
	for _ = 1, 20 do
		if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) then break end
		task.wait(0.5)
	end
end)

local ICON_ORE = { Coal = StyleA.ASSETS.forge_ore_coal_v2, Copper = StyleA.ASSETS.forge_ore_copper_v2, Iron = StyleA.ASSETS.forge_ore_iron_v2 }
local ICON_BAR = { Coal = "rbxassetid://101473380326305", Copper = "rbxassetid://106483042191242", Iron = StyleA.ASSETS.forge_bar_iron_v2 }

-- ===== константи макета (одиниці дизайну) =====
local CANVAS_W, CANVAS_H = 1080, 640
local WX, WY, WW, WH = 50, 74, 980, 528 -- вікно
local TX, TW, TH = 40, 222, 92          -- вкладки
local GX, GY, GW, GH = 288, 106, 636, 278 -- сітка
local GS, GG, GCOLS, GP = 102, 24, 5, 12
local HS, HG = 74, 8                    -- хотбар
local HB_W = Items.HOTBAR * HS + (Items.HOTBAR - 1) * HG
local GLOW_N = 16
