--!strict
-- CaveLighting — «печерний» профіль освітлення на клієнті, поки гравець у печері-сховищі (атрибут InCave).
-- Де: StarterPlayer/StarterPlayerScripts/CaveLighting (LocalScript).
-- Чому: печера стоїть під нішею; сонце світить крізь стелю, а деталі ніші й карти над нею кидали на підлогу проходу
--   різкі плями тіні. У печері сонце не потрібне: вимикаємо його внесок (Brightness 0) і робимо темнішим навколишнє
--   світло — печеру освітлюють лише її ліхтарі (32 PointLight із м'якими тінями, Shadows = true у шаблоні Cave_Inside).
--   Виходить темна затишна печера з м'якими тінями. GlobalShadows не чіпаємо.
-- Профіль діє лише в цього гравця й лише поки він у печері (ніш у цей час не видно); при виході за 0,3 с
--   повертаються значення, які були на старті. Ніші й інші гравці не зачеплені.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- печерний профіль (підібрано скрінами від EXIT по проходу)
local CAVE = {
	Brightness = 0,                                   -- сонце не світить крізь стелю
	Ambient = Color3.fromRGB(80, 80, 92),            -- темніше, ніж у ніші
	OutdoorAmbient = Color3.fromRGB(95, 95, 110),
	EnvironmentDiffuseScale = 0.2,
	EnvironmentSpecularScale = 0.3,
}
-- як налаштовано в плейсі (знімаємо на старті)
local original = {
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}

local tween: Tween? = nil
local function apply()
	local goal = if player:GetAttribute("InCave") == true then CAVE else original
	if tween then tween:Cancel() end
	tween = TweenService:Create(Lighting, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal :: any)
	;(tween :: Tween):Play()
end

player:GetAttributeChangedSignal("InCave"):Connect(apply)
if player:GetAttribute("InCave") == true then apply() end
