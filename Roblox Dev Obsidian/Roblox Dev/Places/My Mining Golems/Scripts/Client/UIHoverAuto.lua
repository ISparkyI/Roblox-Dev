-- UIHoverAuto — звук наведення (SoundService/ButtonHover) на ВСІ кнопки в PlayerGui: наявні й ті, що з'являться пізніше.
-- Де: StarterPlayer/StarterPlayerScripts/UIHoverAuto (LocalScript). Логіка і винятки — у ReplicatedStorage/Shared/UIHover.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local UIHover = require(RS:WaitForChild("Shared"):WaitForChild("UIHover"))
UIHover.auto(Players.LocalPlayer:WaitForChild("PlayerGui"))
