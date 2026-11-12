--!strict
-- TrailerServer — підготовка сетів для трейлера (07.11.2026). Лише Studio і лише коли workspace.TrailerMode = true
--   (у живій грі не запускається взагалі). Пара до StarterPlayerScripts/TrailerDirector (режисер, камера, події).
-- Що робить на старті Play:
--   * Workspace/TrailerSets: копії ніш Stage1..6 (з ServerStorage/NichePrefabs, куди їх переносить NicheService) і арена боса,
--     зсунуті на OFF (далеко від гри), ModelStreamingMode = Persistent (клієнт бачить їх цілком), скрипти й кнопки вимкнено.
--   * ReplicatedStorage/TrailerAssets: модель боса Gobking, Bacon (ThumbTools.bacon + шоковане обличчя з ThumbStudio),
--     RemoteEvent Focus — клієнт просить перенести невидимого персонажа до місця кадру (щоб довантажилось оточення).
local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("TrailerMode") ~= true then return end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local OFF = Vector3.new(9000, 0, 0)

local assets = Instance.new("Folder")
assets.Name = "TrailerAssets"
local focus = Instance.new("RemoteEvent")
focus.Name = "Focus"
focus.Parent = assets

local sets = Instance.new("Folder")
sets.Name = "TrailerSets"

local function clean(m: Instance)
	for _, d in m:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then
			(d :: any).Enabled = false
		elseif d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		end
	end
end

-- ніші
local np = SS:WaitForChild("NichePrefabs", 60)
for i = 1, 6 do
	local src = np and np:FindFirstChild("NichePrefab_Stage" .. i)
	if src and src:IsA("Model") then
		local m = src:Clone()
		m.Name = "Stage" .. i
		m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		m:SetAttribute("LODNear", nil)
		m:SetAttribute("OwnerUserId", nil)
		clean(m)
		m:PivotTo(m:GetPivot() + OFF)
		m.Parent = sets
		task.wait()
	end
end

-- арена боса
local arenaSrc = SS:FindFirstChild("BossArenas") and SS.BossArenas:FindFirstChild("Arena_GolemGoblin")
if arenaSrc then
	local arena = Instance.new("Model")
	arena.Name = "BossArena"
	for _, c in arenaSrc:GetChildren() do c:Clone().Parent = arena end
	clean(arena)
	arena.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	arena:PivotTo(arena:GetPivot() + OFF)
	arena:SetAttribute("MovedBy", arenaSrc:GetAttribute("MovedBy")) -- 11.11.2026: арену в ServerStorage зсунули (-4000, 0, -4000) — режисер рахує центр із цим зсувом
	arena.Parent = sets
end
-- печера зі стендами (11.11.2026, кадр Cave): шаблон CaveService (ServerStorage/CaveInsideTemplate)
local caveSrc = SS:WaitForChild("CaveInsideTemplate", 30)
if caveSrc and caveSrc:IsA("Model") then
	local c = caveSrc:Clone()
	c.Name = "CaveSet"
	clean(c)
	c.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	c:PivotTo(c:GetPivot() + OFF)
	c.Parent = sets
end
sets.Parent = workspace

-- бос
local boss = SS:FindFirstChild("BossModels") and SS.BossModels:FindFirstChild("Gobking")
if boss then
	local b = boss:Clone()
	clean(b)
	b.Parent = assets
end

-- Bacon (звичайний скін Roblox): Smile + окрема пластина «шок» (вимкнена, вмикає клієнт)
local okT, T = pcall(require, SS:FindFirstChild("ThumbTools"))
if okT and T and T.bacon then
	local ok, b = pcall(T.bacon, assets, CFrame.new(0, 500, 0))
	if ok and b then
		b.Name = "Bacon"
		local hum = b:FindFirstChildOfClass("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		local ts = workspace:FindFirstChild("ThumbStudio")
		local plate = ts and ts:FindFirstChild("Bacon") and ts.Bacon:FindFirstChild("FacePlate")
		-- 11.11.2026: NicheBoot прибирає Workspace/ThumbStudio на старті — запасна копія пластини в ServerStorage/TrailerFacePlate
		plate = plate or SS:FindFirstChild("TrailerFacePlate")
		local head = b:FindFirstChild("ClassicHead")
		if plate and head and head:IsA("BasePart") then
			local p = plate:Clone()
			p.Name = "ShockFace"
			p.CFrame = head.CFrame * CFrame.new(0, 0, -0.62)
			local sg = p:FindFirstChildOfClass("SurfaceGui")
			if sg then sg.Enabled = false end
			p.Parent = b
		end
		for _, d in b:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
		end
	else
		warn("TrailerServer: Bacon", b)
	end
end
assets.Parent = RS

-- невидимий персонаж у місці кадру
local hidden: { [Player]: boolean } = {}
focus.OnServerEvent:Connect(function(p: Player, pos: any)
	if typeof(pos) ~= "Vector3" then return end
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not (ch and hrp and hrp:IsA("BasePart")) then return end
	if not hidden[p] then
		hidden[p] = true
		for _, d in ch:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then (d :: any).Transparency = 1
			elseif d:IsA("BillboardGui") then d.Enabled = false end
		end
	end
	hrp.Anchored = true
	ch:PivotTo(CFrame.new(pos))
end)
Players.PlayerRemoving:Connect(function(p) hidden[p] = nil end)
