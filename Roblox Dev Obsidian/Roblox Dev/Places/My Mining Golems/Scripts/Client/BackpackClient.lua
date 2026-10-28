--!strict
-- BackpackClient — стандартний рюкзак Roblox (CoreGui Backpack) поверх нашого інвентаря.
-- Де: StarterPlayer/StarterPlayerScripts/BackpackClient (LocalScript). Сервер — ServerScriptService/BackpackSync (Tools = наш інвентар).
--
-- «~» (KeyCode.Backquote): відкрити / закрити вікно рюкзака Roblox. Поки вікно закрите, CoreGui Backpack вимкнений
--   (ні хотбара Roblox знизу, ні його клавіш 1–9 — працює лише наш хотбар). Відкриття: вмикаємо CoreGui Backpack і
--   відкриваємо вікно інвентаря (StarterGui:SetCore — немає, тож вікно відкриває сам рюкзак Roblox на тій самій «~»).
--   Закриття «~» / Esc — вікно закривається, CoreGui Backpack знову вимикаємо (хотбар Roblox зникає).
--   Обмеження Roblox: показати вікно рюкзака без його хотбара неможливо — поки вікно відкрите, хотбар Roblox видно знизу.
-- Екіп Tool у рюкзаку Roblox → наш Hold: InventoryAction "Hold" (ключ з атрибута InvKey); зняття (Tool повернувся в Backpack,
--   у руках нічого) → "Hold" "". Знищений Tool (закінчився стак, смерть) — не зняття. Hold шлемо лише коли ключ ≠ InvHeld (без циклів).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Action = RS:WaitForChild("Remotes"):WaitForChild("InventoryAction") :: RemoteEvent
local KEY_ATTR = "InvKey"

-- ===== екіп Tool → наш Hold =====
local function heldKey(): string
	local h = player:GetAttribute("InvHeld")
	return type(h) == "string" and h or ""
end

local function watchChar(char: Model)
	char.ChildAdded:Connect(function(c)
		if not c:IsA("Tool") then return end
		local key = c:GetAttribute(KEY_ATTR)
		if type(key) == "string" and heldKey() ~= key then Action:FireServer("Hold", key) end
	end)
	char.ChildRemoved:Connect(function(c)
		if not c:IsA("Tool") then return end
		local key = c:GetAttribute(KEY_ATTR)
		if type(key) ~= "string" then return end
		task.defer(function()
			if c.Parent ~= player:FindFirstChildOfClass("Backpack") then return end -- знищений (стак 0 / смерть) — не зняття
			if char:FindFirstChildOfClass("Tool") then return end -- заміна на інший предмет: Hold уже пішов з ChildAdded
			if heldKey() == key then Action:FireServer("Hold", "") end
		end)
	end)
end
if player.Character then watchChar(player.Character) end
player.CharacterAdded:Connect(watchChar)

-- ===== «~» =====
-- (v25, 27.10.2026, за рішенням користувача) рюкзак Roblox на «~» прибрано повністю: CoreGui Backpack вимкнений завжди,
-- «~» відкриває / закриває наш інвентар (StarterPlayerScripts/InventoryUI, як B). Тут лишається лише синхронізація екіпу Tool → Hold.
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
local _ = UIS
