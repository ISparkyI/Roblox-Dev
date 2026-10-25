-- CaveEntrance — підказка E «ENTER CAVE» біля печери в ніші (Niche*/GolemCave/PromptAnchor/CavePrompt).
-- Телепорт у печеру-сховище големів: точка Workspace/.../GolemCaveSpawn (BasePart). Поки печери немає —
-- на підказці атрибут ComingSoon = true, і клієнт (CustomPrompts) показує «COMING SOON».
local PPS = game:GetService("ProximityPromptService")
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CavePrompt" then return end
	local spawn = workspace:FindFirstChild("GolemCaveSpawn", true)
	if not spawn or not spawn:IsA("BasePart") then return end
	local char = player.Character
	if char and char.PrimaryPart then char:PivotTo(spawn.CFrame + Vector3.new(0, 3, 0)) end
end)
