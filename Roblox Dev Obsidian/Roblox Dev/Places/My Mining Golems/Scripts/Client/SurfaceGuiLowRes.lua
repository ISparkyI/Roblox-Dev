--!nonstrict
-- SurfaceGuiLowRes — табла (SurfaceGui) на телефонах малюються в половинній роздільності (04.11.2026). Лише клієнт.
-- Де: StarterPlayer/StarterPlayerScripts/SurfaceGuiLowRes (LocalScript).
-- Навіщо: текст на таблах растеризується в пікселях полотна (PixelsPerStud): MapBoard, TimeSkips, PlotUpgrades тощо мають
--   шрифти до 100 px, разом це ~95 % місця в атласі шрифтів. На телефоні атлас малий — він переповнюється, і рушій
--   викидає гліфи інших написів: у HUD під цифрою грошей зникає обводка або вся цифра, навіть коли число не змінюється.
--   Удвічі менше полотно → гліфи вчетверо менші за площею → атлас не переповнюється. На екрані телефона різниці майже не видно.
-- Як: PixelsPerStud × K (полотно в K разів менше). Якщо в табла один корінний Frame розміром з полотно (офсети, як у всіх
--   наших табел) — йому UIScale × K, тож розкладка та сама. Якщо діти лише в частках (Scale) — нічого більше не треба
--   (TextScaled сам зменшиться). Інший склад — табло не чіпаємо.
-- Лише на сенсорних пристроях без клавіатури (телефон / планшет). Для перевірки на ПК: атрибут workspace ForceLowResGui = true.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local K = 0.5
local MOBILE = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or workspace:GetAttribute("ForceLowResGui") == true
if not MOBILE then return end

local done: { [Instance]: number } = {} -- SurfaceGui → PixelsPerStud, який поставили ми

local function scaleOnly(g: SurfaceGui): boolean
	for _, c in g:GetChildren() do
		if c:IsA("GuiObject") and (c.Size.X.Offset ~= 0 or c.Size.Y.Offset ~= 0 or c.Position.X.Offset ~= 0 or c.Position.Y.Offset ~= 0) then return false end
	end
	return true
end

local function rootFrame(g: SurfaceGui): GuiObject?
	local root: GuiObject? = nil
	for _, c in g:GetChildren() do
		if c:IsA("GuiObject") then
			if root then return nil end
			root = c
		end
	end
	if root and root.Size.X.Scale == 0 and root.Size.Y.Scale == 0 and root.Position == UDim2.new() and root.AnchorPoint == Vector2.zero then
		return root
	end
	return nil
end

local function apply(g: SurfaceGui)
	if g.SizingMode ~= Enum.SurfaceGuiSizingMode.PixelsPerStud then return end
	if done[g] and math.abs(g.PixelsPerStud - done[g]) < 1e-3 then return end -- уже наше
	local root = rootFrame(g)
	if root then
		local sc = root:FindFirstChild("LowResScale")
		if not sc then
			sc = Instance.new("UIScale"); sc.Name = "LowResScale"; sc.Scale = K; sc.Parent = root
		end
	elseif not scaleOnly(g) then
		return -- невідомий склад — не ризикуємо
	end
	local pps = g.PixelsPerStud * K
	done[g] = pps
	g.PixelsPerStud = pps
end

local function watch(g: Instance)
	if not g:IsA("SurfaceGui") or done[g] ~= nil then return end
	done[g] = -1
	-- діти табла часто з'являються пізніше (скрипти будують табло) — перевіряємо при кожній зміні складу
	local function try() if g.Parent then apply(g :: SurfaceGui) end end
	task.defer(try)
	g.ChildAdded:Connect(function() task.defer(try) end)
	g:GetPropertyChangedSignal("PixelsPerStud"):Connect(function()
		local mine = done[g]
		if mine and mine > 0 and math.abs(g.PixelsPerStud - mine) > 1e-3 then done[g] = -1; task.defer(try) end -- скрипт табла переставив
	end)
	g.AncestryChanged:Connect(function() if not g:IsDescendantOf(game) then done[g] = nil end end)
end

for _, root in { workspace, Players.LocalPlayer:WaitForChild("PlayerGui") } do
	for _, d in root:GetDescendants() do if d:IsA("SurfaceGui") then watch(d) end end
	root.DescendantAdded:Connect(function(d) if d:IsA("SurfaceGui") then watch(d) end end)
end
