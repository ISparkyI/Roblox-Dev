-- Важіль станції ролу: E (RollPrompt на фронті пульта) -> відтяг до гравця -> постріл назад -> удар -> повернення.
-- У момент удару стріляє BindableEvent "Pulled" (player, role) — сюди підключиться система ролу.
-- role = атрибут гравця RollRole ("Miner" / "Carrier"), його ставить RollRoleService (картки на екрані станції).
-- v3 (27.10.2026, ролли v1): тягнути може лише власник ніші (атрибут ніші OwnerUserId); після удару підказка
-- вмикається, лише коли скінчиться анімація ролу на підставках (атрибут ніші RollBusyUntil = час сервера, ставить RollService).
-- v4 (27.10.2026): RollPrompt.Exclusivity = OneGlobally (разом із RollBuyPrompt на тій самій E видно лише одну, найближчу);
-- рол не стартує, якщо гравець щойно (0,4 с) купив голема (RollBuyT), і ставить ніші RollPullT (блок покупки на 0,6 с).
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

-- ніша, у якій стоїть важіль (модель у Workspace/Niches)
local function nicheOf(): Instance?
	local n: Instance? = model
	while n and n.Parent and n.Parent.Name ~= "Niches" do n = n.Parent end
	return n and n.Parent and n or nil
end

local busy = false
prompt.Triggered:Connect(function(player)
	if busy then return end
	local niche = nicheOf()
	if not niche or niche:GetAttribute("OwnerUserId") ~= player.UserId then return end -- лише власник
	local untilT = niche:GetAttribute("RollBusyUntil")
	if type(untilT) == "number" and workspace:GetServerTimeNow() < untilT then return end -- рол ще йде
	-- одне натискання E — одна дія: щойно була покупка на підставці (RollService, атрибут гравця RollBuyT) — не ролимо
	local buyT = player:GetAttribute("RollBuyT")
	if type(buyT) == "number" and workspace:GetServerTimeNow() - buyT < 0.4 then return end
	niche:SetAttribute("RollPullT", workspace:GetServerTimeNow()) -- RollService не дасть купити в цей момент
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
	-- чекаємо кінця анімації ролу (RollService ставить RollBusyUntil у момент удару)
	while true do
		local t = niche:GetAttribute("RollBusyUntil")
		if type(t) ~= "number" or workspace:GetServerTimeNow() >= t or not niche.Parent then break end
		task.wait(0.05)
	end
	prompt.Enabled = true
	busy = false
end)
