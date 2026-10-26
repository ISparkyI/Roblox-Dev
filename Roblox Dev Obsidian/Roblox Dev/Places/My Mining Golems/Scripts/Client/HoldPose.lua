--!strict
-- HoldPose — поза «предмет на долоні» для персонажів, що тримають предмет (свій і чужі): плече внизу біля тулуба,
--   лікоть зігнутий під 90°, передпліччя вперед, долоня вгору (як тримають тацю чи фігурку). Права рука не махає, ноги йдуть як звичайно.
-- Де: StarterPlayer/StarterPlayerScripts/HoldPose (LocalScript).
-- Як: сервер (HeldItemService) ставить персонажу атрибут HoldPose = true, поки в руці є модель. Кожний клієнт для таких
--   персонажів щокадру після анімацій (PreSimulation) переписує Transform суглобів правої руки (R15: RightShoulder,
--   RightElbow, RightWrist; суглоб — Motor6D або AnimationConstraint у нових аватарах). Анімації Роблокса не зупиняються — просто рука стоїть у своїй позі. R6 (без ліктя) — без пози.
-- Підгонка кутів — таблиця POSE (градуси). Предмет приварений до RightHand на сервері з розрахунку на цю позу
--   (долоня — грань −X руки — дивиться вгору), тому кути міняти разом із HeldItemService.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local R = math.rad
-- кути суглобів (градуси): X — вперед / назад, Y — крутіння вздовж руки, Z — від тулуба / до тулуба
local POSE = {
	shoulder = CFrame.Angles(R(12), 0, R(4)),   -- плече внизу, трохи вперед і назовні
	elbow = CFrame.Angles(R(80), 0, 0),          -- передпліччя вперед (разом з плечем ≈ горизонтально)
	wrist = CFrame.Angles(0, R(-90), 0),         -- долоня вгору
}

type Rig = { shoulder: any, elbow: any, wrist: any }
local rigs: { [Model]: Rig } = {}

-- суглоб: Motor6D (старі риги) або AnimationConstraint (нові аватари) — в обох є Transform
local function find(char: Model, name: string): any
	for _, d in char:GetDescendants() do
		if d.Name == name and (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) then return d end
	end
	return nil
end

local function watch(char: Model)
	local function upd()
		if char:GetAttribute("HoldPose") == true and char.Parent then
			rigs[char] = { shoulder = find(char, "RightShoulder"), elbow = find(char, "RightElbow"), wrist = find(char, "RightWrist") }
		else
			rigs[char] = nil
		end
	end
	char:GetAttributeChangedSignal("HoldPose"):Connect(upd)
	char.AncestryChanged:Connect(function() if not char.Parent then rigs[char] = nil end end)
	upd()
end

local function onPlayer(p: Player)
	p.CharacterAdded:Connect(watch)
	if p.Character then watch(p.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end

-- після анімацій кадру: рука з предметом у своїй позі
RunService.PreSimulation:Connect(function()
	for char, r in rigs do
		if r.shoulder then r.shoulder.Transform = POSE.shoulder end
		if r.elbow then r.elbow.Transform = POSE.elbow end
		if r.wrist then r.wrist.Transform = POSE.wrist end
	end
end)
