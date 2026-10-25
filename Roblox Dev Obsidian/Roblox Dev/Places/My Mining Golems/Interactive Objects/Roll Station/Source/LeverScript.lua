-- Важіль станції ролу: E (RollPrompt на фронті пульта) -> відтяг до гравця -> постріл назад -> удар -> повернення.
-- У момент удару стріляє BindableEvent "Pulled" (player, role) — сюди підключиться система ролу.
-- role = атрибут гравця RollRole ("Miner" / "Carrier"), його ставить RollRoleService (картки на екрані станції).
-- Hinge — невидима опора (Anchored); палиця, муфта й руків'я приварені до неї. Шестерня збоку крутиться разом з ривком.
local TS = game:GetService("TweenService")
local lever  = script.Parent
local model  = lever.Parent
local hinge  = lever:WaitForChild("Hinge")
local prompt = model:WaitForChild("PromptAnchor"):WaitForChild("RollPrompt")
-- ефект удару: табло на тумбі спалахує білим і гасне до зеленого + золоті іскри з пазу важеля
local ind    = model:FindFirstChild("Indicator", true)
local indCol = ind and ind.Color
local flash  = ind and ind:FindFirstChild("Flash")
local sparks = hinge:FindFirstChild("Sparks", true)
local pulled = lever:FindFirstChild("Pulled")
local gear   = model:FindFirstChild("Gear")
local hub    = gear and gear:FindFirstChild("GearHub")
local rest   = hinge.CFrame -- палиця відхилена від гравця; +кут = верх палиці до гравця
local hubRest = hub and hub.CFrame

local function at(deg) return rest * CFrame.Angles(math.rad(deg), 0, 0) end
local function step(deg, t, style, dir, gearDeg)
	local tw = TS:Create(hinge, TweenInfo.new(t, style, dir), {CFrame = at(deg)})
	tw:Play()
	if hub and gearDeg then TS:Create(hub, TweenInfo.new(t, style, dir), {CFrame = hubRest * CFrame.Angles(math.rad(gearDeg), 0, 0)}):Play() end
	tw.Completed:Wait()
end

local busy = false
prompt.Triggered:Connect(function(player)
	if busy then return end
	busy = true
	prompt.Enabled = false
	step( 44, 0.28, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut, 90)  -- відтяг до себе
	step( 48, 0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out,   100) -- напруга
	step(-22, 0.14, Enum.EasingStyle.Cubic,  Enum.EasingDirection.In,    -45) -- постріл назад
	if ind then ind.Color = Color3.new(1, 1, 1) TS:Create(ind, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Color = indCol}):Play() end
	if flash then flash.Brightness = 3 TS:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Brightness = 0}):Play() end
	if sparks then sparks:Emit(16) end
	if pulled then pulled:Fire(player, player:GetAttribute("RollRole") or "Miner") end
	step(-14, 0.08, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out,   -30) -- відскок
	step(-18, 0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.InOut, -36) -- осідання
	task.wait(0.15)
	step(  0, 0.60, Enum.EasingStyle.Back,   Enum.EasingDirection.Out,   0)   -- назад у спокій
	prompt.Enabled = true -- потім: вмикати після анімації ролу
	busy = false
end)
