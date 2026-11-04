--!nonstrict
-- TextFitGuard — текст у вікнах і HUD завжди влазить у свою рамку (04.11.2026, телефони). Лише клієнт.
-- Де: StarterPlayer/StarterPlayerScripts/TextFitGuard (LocalScript).
-- Навіщо: написи з фіксованим TextSize підібрані на ПК; на телефоні все множиться на малий UIScale, а шрифт округлюється до
--   цілих пікселів і на малих розмірах ширший відносно рамки — «Golems» обрізалось до «Gole», назви големів вилазили за картку.
-- TextScaled, що не влазить через UITextSizeConstraint.MinTextSize, — мінімум опускаємо до 6.
-- Як: для кожного TextLabel / TextButton / TextBox у ScreenGui (не TextScaled, не AutomaticSize) — якщо рушій каже, що текст
--   не влазить (TextFits = false) і напис зараз видно, зменшуємо TextSize кроками (до MIN_K від початкового), поки не влізе.
--   Змінився текст — повертаємо початковий розмір і підбираємо знову. Свій TextSize від скрипта вікна — стає новим «початковим».
--   На ПК майже нічого не робить (там текст і так влазить).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MIN_K = 0.55
local base: { [Instance]: number } = {}   -- початковий TextSize
local ours: { [Instance]: number } = {}   -- TextSize, який поставили ми
local busy: { [Instance]: boolean } = {}

local function shown(t: GuiObject): boolean
	local x: Instance? = t
	while x do
		if x:IsA("GuiObject") then
			if not x.Visible then return false end
		elseif x:IsA("LayerCollector") then
			return x.Enabled and x:IsA("ScreenGui")
		end
		x = x.Parent
	end
	return false
end

local function fit(t)
	if busy[t] or not t.Parent then return end
	if t.Text == "" or t.AutomaticSize ~= Enum.AutomaticSize.None then return end
	if t.TextFits then return end
	if t.TextScaled then
		-- TextScaled не влазить лише через UITextSizeConstraint.MinTextSize (діє в пікселях екрана: на телефоні 12 px — забагато)
		local c = t:FindFirstChildOfClass("UITextSizeConstraint")
		if c and c.MinTextSize > 6 and shown(t) then c.MinTextSize = 6 end
		return
	end
	if t.AbsoluteSize.X < 4 or t.AbsoluteSize.Y < 4 or not shown(t) then return end
	local b = base[t] or t.TextSize
	base[t] = b
	local minS = math.max(6, math.floor(b * MIN_K))
	busy[t] = true
	task.spawn(function()
		for _ = 1, 16 do
			if not t.Parent or t.TextFits or t.TextSize <= minS then break end
			local s = math.max(minS, t.TextSize - math.max(1, math.floor(t.TextSize * 0.07)))
			ours[t] = s
			t.TextSize = s
			RunService.Heartbeat:Wait()
		end
		busy[t] = nil
	end)
end

local function track(t: Instance)
	if not (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) or base[t] then return end
	if not t:FindFirstAncestorWhichIsA("ScreenGui") then return end
	base[t] = t.TextSize
	t:GetPropertyChangedSignal("TextFits"):Connect(function() if not t.TextFits then fit(t) end end)
	t:GetPropertyChangedSignal("Text"):Connect(function()
		local b = base[t]
		if b and t.TextSize ~= b and ours[t] == t.TextSize then ours[t] = nil; t.TextSize = b end
		task.defer(fit, t)
	end)
	t:GetPropertyChangedSignal("TextSize"):Connect(function()
		if ours[t] ~= t.TextSize then base[t] = t.TextSize; ours[t] = nil end -- скрипт вікна сам поставив розмір
	end)
	t:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if not t.TextFits then task.defer(fit, t) end end)
	t.AncestryChanged:Connect(function()
		if not t:IsDescendantOf(game) then base[t] = nil; ours[t] = nil; busy[t] = nil end
	end)
	task.defer(fit, t)
end

local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
for _, d in pg:GetDescendants() do track(d) end
pg.DescendantAdded:Connect(function(d)
	if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then task.defer(track, d) end
end)
-- вікна відкриваються (Visible = true) — TextFits міг не змінитись, тож раз на 1 с перевіряємо видимі, що не влазять
task.spawn(function()
	while true do
		task.wait(1)
		for t in base do
			if t.Parent and not t.TextFits and not busy[t] then pcall(fit, t) end
		end
	end
end)
