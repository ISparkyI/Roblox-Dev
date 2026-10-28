-- MutationTextClient — анімовані градієнти назв мутацій на серверних табличках (BillboardGui над големом у руці й на стенді печери).
-- Де: StarterPlayer/StarterPlayerScripts/MutationTextClient (LocalScript).
-- Сервер (HeldItemService.infoBoard, яку бере й CaveStandService) ставить мітці атрибут MutationText = mut (0..7) і базовий колір;
-- цей скрипт знаходить такі TextLabel у workspace (наявні й нові) і викликає Shared/MutationText.apply.
-- Знищені мітки MutationText відписує сам (один спільний Heartbeat), тут — лише підписка на зміну атрибута (зникає разом із міткою).

local RS = game:GetService("ReplicatedStorage")
local MutationText = require(RS:WaitForChild("Shared"):WaitForChild("MutationText"))

local ATTR = "MutationText"
local seen = setmetatable({}, { __mode = "k" })

local function hook(o: Instance)
	if not (o:IsA("TextLabel") or o:IsA("TextButton")) then return end
	local v = o:GetAttribute(ATTR)
	if v == nil then return end
	MutationText.apply(o :: any, v)
	if seen[o] then return end
	seen[o] = true
	o:GetAttributeChangedSignal(ATTR):Connect(function()
		local nv = o:GetAttribute(ATTR)
		if nv == nil then MutationText.clear(o :: any) else MutationText.apply(o :: any, nv) end
	end)
end

for _, o in workspace:GetDescendants() do hook(o) end
workspace.DescendantAdded:Connect(function(o)
	-- атрибут реплікується разом із міткою; перевірка після кадру — на випадок порядку змін
	hook(o)
	if o:IsA("TextLabel") and o:GetAttribute(ATTR) == nil then
		task.defer(function() if o.Parent then hook(o) end end)
	end
end)
