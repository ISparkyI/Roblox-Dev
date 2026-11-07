--!strict
-- PlayerNoCollide — гравці не штовхають і не блокують одне одного (06.11.2026). Де: ServerScriptService/PlayerNoCollide (Script).
-- Група зіткнень "Players" (PhysicsService): Players ↔ Players — без зіткнень; зі світом, големами й рештою — як звичайно.
-- Кожна деталь персонажа (і все, що з'являється в ньому пізніше — аксесуари, інструменти) отримує CollisionGroup = "Players".
-- Працює і в лобі, і на Marketplace (той самий файл плейсу).
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local GROUP = "Players"
pcall(function() PhysicsService:RegisterCollisionGroup(GROUP) end)
PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)

local function setPart(d: Instance)
	if d:IsA("BasePart") then d.CollisionGroup = GROUP end
end

local function onCharacter(ch: Model)
	for _, d in ch:GetDescendants() do setPart(d) end
	ch.DescendantAdded:Connect(setPart)
end

local function onPlayer(p: Player)
	p.CharacterAdded:Connect(onCharacter)
	if p.Character then onCharacter(p.Character) end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end
