-- ShortDirector — камера для TikTok-ролика «Same 3 Golems» (13.11.2026). ТИМЧАСОВО, прибрати після зйомки.
-- Де: StarterPlayer/StarterPlayerScripts/ShortDirector. Працює лише коли workspace.ShortMode = true (сцену будує ShortServer).
-- Клавіші: 1…6 — кадр (DUR с: HOLD нерухомо → рух MOVE с → HOLD), F6 — усі 6 підряд, F8 — стоп. HUD і персонаж сховані.
-- _G.ShortPose(i, u) — поставити камеру кадру i у фазу u (0…1) без анімації (для стоп-кадрів розкадровки).
if workspace:GetAttribute("ShortMode") ~= true then return end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

local HOLD, MOVE = 0.75, 3.5
local DUR = HOLD * 2 + MOVE
local O = workspace:GetAttribute("ShortOrigin") :: Vector3
local STEP = workspace:GetAttribute("ShortStep") :: number
while not O do task.wait(0.2); O = workspace:GetAttribute("ShortOrigin"); STEP = workspace:GetAttribute("ShortStep") end

local function center(i: number): Vector3
	local set = workspace:FindFirstChild("ShortSet")
	local g = set and set:FindFirstChild("ShortGolem" .. i)
	if g and g:IsA("Model") then local cf, sz = g:GetBoundingBox(); return cf.Position, sz.Y end
	return O + Vector3.new((i - 1) * STEP, 4, 0), 7
end
local function ease(t: number): number return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end

-- камера кадру i у фазі u (0…1 по руху): обліт 15°, у 3/6 — ще й наїзд
local cur = { i = 1, u = 0 } -- що тримати щокадру (PlayerModule інакше повертає камеру)
local cache = {}
local function frameOf(i: number)
	if cache[i] then return cache[i] end
	local set = workspace:FindFirstChild("ShortSet")
	local g = set and set:FindFirstChild("ShortGolem" .. i)
	if not (g and g:IsA("Model")) then return nil end
	local cf, sz = g:GetBoundingBox()
	local mt = g:FindFirstChild("MineTarget", true)
	local ore = mt and mt.Value
	local oc = (ore and ore:IsA("Model")) and ore:GetBoundingBox().Position or cf.Position
	local f = g:GetPivot().LookVector; f = Vector3.new(f.X, 0, f.Z).Unit
	cache[i] = { look = cf.Position:Lerp(oc, 0.45), h = sz.Y, fwd = f }
	return cache[i]
end
-- 13.11.2026: вертикальний кадр 9:16 — камера спереду-збоку голема (руда нижче голема в кадрі), обліт 30°→18°, у 3/6 наїзд
local function pose(i: number, u: number)
	local F = frameOf(i); if not F then return end
	local k = ease(math.clamp(u, 0, 1))
	local d = CFrame.Angles(0, math.rad(14 - 12 * k), 0):VectorToWorldSpace(F.fwd)
	local r = F.h * (2.4 - 0.3 * k)
	local pos = F.look + d * r + Vector3.new(0, F.h * 1.0, 0)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 50
	cam.CFrame = CFrame.lookAt(pos, F.look)
end
-- темна коробка навколо сету (лише на клієнті), щоб не було неба на фоні
do
	local C = O + Vector3.new(175, 0, 0); local S = 900
	local box = Instance.new("Folder"); box.Name = "ShortBox"
	local function w(p: Vector3, sz: Vector3)
		local q = Instance.new("Part"); q.Anchored = true; q.CanCollide = false; q.CanQuery = false; q.CastShadow = false
		q.Material = Enum.Material.SmoothPlastic; q.Color = Color3.fromRGB(14, 14, 20); q.Size = sz; q.Position = p; q.Parent = box
	end
	w(C + Vector3.new(S / 2, 0, 0), Vector3.new(2, S, S)); w(C - Vector3.new(S / 2, 0, 0), Vector3.new(2, S, S))
	w(C + Vector3.new(0, 0, S / 2), Vector3.new(S, S, 2)); w(C - Vector3.new(0, 0, S / 2), Vector3.new(S, S, 2))
	w(C + Vector3.new(0, S / 2, 0), Vector3.new(S, 2, S))
	box.Parent = workspace
end
function _G.ShortPose(i: number, u: number) cur.i, cur.u = i, u end
-- з плагіна / консолі: атрибут гравця ShortPose = "i,u" (стоп-кадри розкадровки)
player:GetAttributeChangedSignal("ShortPose"):Connect(function()
	local s = tostring(player:GetAttribute("ShortPose") or "")
	local a, b = s:match("^(%d+),([%d%.%-]+)$")
	if a then cur.i, cur.u = tonumber(a) :: number, tonumber(b) :: number end
end)
RunService:BindToRenderStep("ShortCam", Enum.RenderPriority.Camera.Value + 10, function() pose(cur.i, cur.u) end)

-- HUD і персонаж — сховати (щокадру: інші скрипти можуть увімкнути)
local mine = {}
RunService.RenderStepped:Connect(function()
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and not mine[g] then g.Enabled = false end
		if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then if g.Enabled then g.Enabled = false end end
	end
	local ch = player.Character
	if ch then for _, d in ch:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end end
end)
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)

-- чорна шторка між кадрами (0,5 с) — за нею монтаж ріже один довгий запис на кадри (ffmpeg blackdetect)
local blackGui = Instance.new("ScreenGui"); blackGui.Name = "ShortBlack"; blackGui.IgnoreGuiInset = true; blackGui.DisplayOrder = 1000; blackGui.ResetOnSpawn = false
local blackF = Instance.new("Frame"); blackF.Size = UDim2.fromScale(1, 1); blackF.BackgroundColor3 = Color3.new(0, 0, 0); blackF.BorderSizePixel = 0; blackF.Visible = false; blackF.Parent = blackGui
mine[blackGui] = true; blackGui.Parent = player.PlayerGui
local token = 0
local function play(i: number, keep: boolean?)
	if not keep then token += 1 end
	local my = token
	local t0 = os.clock()
	while my == token do
		local t = os.clock() - t0
		if t > DUR then break end
		_G.ShortPose(i, (t - HOLD) / MOVE)
		RunService.RenderStepped:Wait()
	end
end
-- запис усіх кадрів: шторка 0,6 с → кадр → … → шторка (атрибут гравця ShortPlay = "all", або клавіша F6)
local function playAll()
	local my0 = token + 1
	for i = 1, (workspace:GetAttribute("ShortCount") or 6) do
		token = my0 + i - 1
		blackF.Visible = true; _G.ShortPose(i, 0)
		task.wait(0.6)
		blackF.Visible = false
		play(i, true)
	end
	blackF.Visible = true; task.wait(0.6); blackF.Visible = false
end
player:GetAttributeChangedSignal("ShortPlay"):Connect(function()
	local v = player:GetAttribute("ShortPlay")
	if v == "all" then task.spawn(playAll) elseif tonumber(v) then task.spawn(play, tonumber(v) :: number) end
end)
UIS.InputBegan:Connect(function(io, gp)
	if gp then return end
	local n = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6 })[io.KeyCode]
	if n then task.spawn(play, n)
	elseif io.KeyCode == Enum.KeyCode.F6 then task.spawn(playAll)
	elseif io.KeyCode == Enum.KeyCode.F8 then token += 1 end
end)
task.wait(1)
_G.ShortPose(1, 0)
