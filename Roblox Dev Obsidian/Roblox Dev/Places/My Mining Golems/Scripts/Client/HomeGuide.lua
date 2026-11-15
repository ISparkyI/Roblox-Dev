--!nonstrict
-- HomeGuide — мітка «дім» над входом у свою нішу (11.11.2026, v2 без стрілок).
-- Де: StarterPlayer/StarterPlayerScripts/HomeGuide (LocalScript).
-- Над своїм PlotSpawn висить іконка будиночка й відстань до нього («42m», стади по прямій); видно крізь стіни (AlwaysOnTop).
-- Ховається (плавно, FADE с): гравець у своїй ніші (промінь вниз влучає в її деталь) або ближче HIDE_R стадів до входу;
--   а також у печері (InCave), на арені боса (InBossArena), під час навчань (TutStep / BossTut / CaveTut) і на маркеті.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local okH, Hub = pcall(require, RS:WaitForChild("Shared"):WaitForChild("HubConfig"))
if okH and Hub and Hub.isMarket and Hub.isMarket() then return end -- на маркеті ніш немає

local HOME_ICON = "rbxassetid://85359661011827" -- Free Icon Pack «Green House 2nd Outline 64px» (група OSIRIUS, 11.11.2026)
local GREEN = Color3.fromHex("5af078")
local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local HIDE_R = 20   -- ближче до входу — мітки немає
local FADE = 1      -- с: поява / зникнення
local HEIGHT = 7    -- стадів над PlotSpawn

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function myNiche(): Model?
	local f = workspace:FindFirstChild("Niches")
	if not f then return nil end
	for _, m in f:GetChildren() do
		if m:GetAttribute("OwnerUserId") == player.UserId then return m end
	end
	return nil
end

-- ===== мітка =====
local bb = new("BillboardGui", { Name = "HomeMark", Size = UDim2.fromOffset(170, 52), AlwaysOnTop = true, LightInfluence = 0,
	MaxDistance = 2000, ResetOnSpawn = false, Enabled = false, StudsOffsetWorldSpace = Vector3.new(0, HEIGHT, 0) }, player:WaitForChild("PlayerGui"))
local group = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1 }, bb)
local row = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 52),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 }, group)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
if HOME_ICON ~= "" then
	new("ImageLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Image = HOME_ICON, ScaleType = Enum.ScaleType.Fit }, row)
else
	new("TextLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Text = "🏠", TextScaled = true, FontFace = HEAVY,
		TextColor3 = GREEN, AutoLocalize = false }, row)
end
local dist = new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 44), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
	Text = "", TextSize = 36, FontFace = HEAVY, TextColor3 = GREEN, AutoLocalize = false }, row)
new("UIStroke", { Color = INK, Thickness = 3.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }, dist)

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.RespectCanCollide = true
local function atHome(hrp: BasePart, niche: Model): boolean
	rp.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), rp)
	return hit ~= nil and hit.Instance:IsDescendantOf(niche)
end
local function blocked(): boolean
	if player:GetAttribute("InCave") == true or player:GetAttribute("InBossArena") == true then return true end
	if player:GetAttribute("TutStep") ~= nil or player:GetAttribute("BossTut") ~= nil or player:GetAttribute("CaveTut") ~= nil then return true end
	return false
end

local alpha = 0       -- 0 — схована, 1 — видно
local homeAt, homeNow = 0, true
RunService.RenderStepped:Connect(function(dt)
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	local niche = myNiche()
	local sp = niche and niche:FindFirstChild("PlotSpawn") :: BasePart?
	local want = false
	if hrp and sp and not blocked() then
		local now = os.clock()
		if now - homeAt > 0.25 then homeAt = now; homeNow = atHome(hrp, niche :: Model) end
		local d = (sp.Position - hrp.Position).Magnitude
		want = not homeNow and d > HIDE_R
		if bb.Adornee ~= sp then bb.Adornee = sp end
		dist.Text = tostring(math.floor(d + 0.5)) .. "m"
	end
	alpha = math.clamp(alpha + (want and 1 or -1) * dt / FADE, 0, 1)
	group.GroupTransparency = 1 - alpha
	bb.Enabled = alpha > 0
end)
