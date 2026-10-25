-- Гучність кроків = 75% від стандартної (стандартне Running = 0.65 → 0.4875).
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local DEFAULT = 0.65
local FACTOR = 0.75
local TARGET = DEFAULT * FACTOR

local function hook(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	-- звук «Running» створює стандартний RbxCharacterSounds
	local running = hrp:WaitForChild("Running", 10)
	if not (running and running:IsA("Sound")) then return end
	running.Volume = TARGET
	-- якщо стандартний скрипт поверне гучність, виставляємо знову
	running:GetPropertyChangedSignal("Volume"):Connect(function()
		if math.abs(running.Volume - TARGET) > 0.001 then running.Volume = TARGET end
	end)
end

if player.Character then task.spawn(hook, player.Character) end
player.CharacterAdded:Connect(hook)
