-- KeyHint — бейджі клавіш (E, R ...) на кнопках у світі й на екрані видно ЛИШЕ з клавіатурою (04.11.2026).
-- Де: ReplicatedStorage/Shared/KeyHint (ModuleScript, клієнт).
-- v2 (04.11.2026): у симуляторі телефона PreferredInput на мить перемикався на KeyboardAndMouse від руху мишки — бейджі блимали.
--   Тепер так:
--   • пристрій без сенсорного екрана — бейджі є (крім геймпада: PreferredInput = Gamepad — немає);
--   • сенсорний екран (телефон, планшет, симулятор) — бейджів немає, доки гравець не натисне справжню КЛАВІШУ клавіатури
--     (підключена клавіатура); дотик знову ховає. Рух і кліки мишки нічого не змінюють.
-- KeyHint.bind(label) — показує / ховає label за режимом і стежить за змінами. KeyHint.show() — чи показувати зараз.
local UIS = game:GetService("UserInputService")
local KeyHint = {}

local kbOnTouch = false -- на сенсорному пристрої натиснули справжню клавішу

local function gamepad(): boolean
	local ok, v = pcall(function() return UIS.PreferredInput end)
	return ok and v == Enum.PreferredInput.Gamepad
end

function KeyHint.show(): boolean
	if gamepad() then return false end
	if UIS.TouchEnabled then return kbOnTouch end
	return true
end

local labels: { [GuiObject]: boolean } = {}
local lastShown: boolean? = nil
local function apply()
	local s = KeyHint.show()
	if s == lastShown then return end
	lastShown = s
	for l in labels do
		if l.Parent then l.Visible = s else labels[l] = nil end
	end
end
pcall(function() UIS:GetPropertyChangedSignal("PreferredInput"):Connect(apply) end)
UIS.InputBegan:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.Keyboard and io.KeyCode ~= Enum.KeyCode.Unknown then
		if not kbOnTouch then kbOnTouch = true; apply() end
	elseif io.UserInputType == Enum.UserInputType.Touch then
		if kbOnTouch then kbOnTouch = false; apply() end
	end
end)

function KeyHint.bind(label: GuiObject)
	labels[label] = true
	label.Visible = KeyHint.show()
	label.Destroying:Connect(function() labels[label] = nil end)
end

return KeyHint
