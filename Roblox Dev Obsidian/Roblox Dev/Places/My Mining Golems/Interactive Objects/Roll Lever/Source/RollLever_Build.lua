--!strict
-- Roll Lever — збирає важіль ролу в Roblox Studio (через MCP execute_luau або Command Bar).
-- Використання:
--   local build = <цей код як ModuleScript або вставити функцію>
--   build(workspace, CFrame.lookAt(pos, pos + towardsPlayer))   -- див. "Точка встановлення"
--
-- Точка встановлення (origin):
--   * позиція  — підлога під віссю важеля (низ плити),
--   * +Z       — бік гравця (звідки він підходить; до нього палиця відтягується),
--   * X        — напрям осі (палиця гойдається в площині Y-Z).
--   Найпростіше: origin = CFrame.lookAt(pos, pos - towardsPlayer)  -- LookVector дивиться ВІД гравця, тож +Z = до гравця.
--
-- Studs: на деталях з MaterialVariant "Studs" пупочки дає матеріал (MaterialService/Studs від Resurface).
--        На палиці й кільцях — Texture з асетами Resurface (10509831729 / 10509831753), StudsPerTile 0.488.
--        Якщо в плейсі немає MaterialVariant "Studs" — створи його логікою Resurface (див. нотатку Resurface).

local V = Vector3.new
local PARTS = {
	-- статика (Anchored): основа зі стійками
	{name="2", size=V(3.902, 0.61, 2.683),  pos=V(0, 0.305, 0),    rot=V(0, -90, 0), color="424242", mat="Plastic", mv="Studs"},
	{name="1", size=V(2.927, 1.585, 0.976), pos=V(-0.832, 1.28, 0), rot=V(0, -90, 0), color="535353", mat="Plastic", mv="Studs"},
	{name="1", size=V(2.927, 1.585, 0.976), pos=V(0.832, 1.28, 0),  rot=V(0, -90, 0), color="535353", mat="Plastic", mv="Studs"},
	{name="1", size=V(2.195, 0.366, 0.976), pos=V(0.832, 2.256, 0), rot=V(0, -90, 0), color="535353", mat="Plastic", mv="Studs"},
	{name="1", size=V(2.195, 0.366, 0.976), pos=V(-0.832, 2.256, 0),rot=V(0, -90, 0), color="535353", mat="Plastic", mv="Studs"},
}
local MOVING = {
	-- рухоме (Anchored = false, WeldConstraint до Hinge)
	{name="Ring",  size=V(0.812, 0.683, 0.537), pos=V(0.038, 1.373, 0), color="5b5f64", mat="SmoothPlastic", mv="",      studs=0.488},
	{name="Stick", size=V(0.39, 2.927, 0.39),   pos=V(0, 3.105, 0),     color="6f4828", mat="Plastic",       mv="",      studs=0.488},
	{name="Ring",  size=V(0.537, 0.195, 0.537), pos=V(0, 2.227, 0),     color="5b5f64", mat="SmoothPlastic", mv="",      studs=0.488},
	{name="Ring",  size=V(0.537, 0.195, 0.537), pos=V(0, 3.885, 0),     color="5b5f64", mat="SmoothPlastic", mv="",      studs=0.488},
	{name="Knob",  size=V(1, 1, 1),             pos=V(0, 4.861, 0),     color="d63a2f", mat="Plastic",       mv="Studs", glow=true},
}
local HINGE_Y = 1.641 -- висота осі над origin

local SCRIPT_SOURCE = [==[
-- Важіль ролу: E -> відтяг до гравця -> постріл вперед з прискоренням -> удар -> повернення вгору.
-- У момент удару стріляє BindableEvent "Pulled" (player) — сюди підключається система ролу.
-- Потрібні тільки Hinge (з RollPrompt) і приварені до нього деталі палиці.
local TS = game:GetService("TweenService")
local lever  = script.Parent
local hinge  = lever:WaitForChild("Hinge")
local prompt = hinge:WaitForChild("RollPrompt")
local knob   = lever:FindFirstChild("Knob")
local glow   = knob and knob:FindFirstChild("Glow")
local pulled = lever:FindFirstChild("Pulled")
local rest   = hinge.CFrame -- палиця вгору; +кут = верх палиці до гравця

local function at(deg) return rest * CFrame.Angles(math.rad(deg), 0, 0) end
local function step(deg, t, style, dir)
	local tw = TS:Create(hinge, TweenInfo.new(t, style, dir), {CFrame = at(deg)})
	tw:Play()
	tw.Completed:Wait()
end

local busy = false
prompt.Triggered:Connect(function(player)
	if busy then return end
	busy = true
	prompt.Enabled = false
	step( 28, 0.28, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut) -- відтяг до себе
	step( 31, 0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)   -- напруга
	step(-72, 0.14, Enum.EasingStyle.Cubic,  Enum.EasingDirection.In)    -- постріл вперед
	if glow then glow.Brightness = 6 TS:Create(glow, TweenInfo.new(0.35), {Brightness = 0}):Play() end
	if pulled then pulled:Fire(player) end
	step(-63, 0.08, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)   -- відскок
	step(-68, 0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.InOut) -- осідання
	task.wait(0.15)
	step(  0, 0.60, Enum.EasingStyle.Back,   Enum.EasingDirection.Out)   -- назад вгору
	prompt.Enabled = true -- коли буде система ролу: вмикати після анімації ролу
	busy = false
end)
]==]

local CM = Content.fromUri("rbxassetid://10509831729")
local NM = Content.fromUri("rbxassetid://10509831753")

local function makePart(d, cf: CFrame, anchored: boolean, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = d.name
	p.Size = d.size
	p.CFrame = cf
	p.Color = Color3.fromHex(d.color)
	p.Material = Enum.Material[d.mat]
	p.MaterialVariant = d.mv
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = anchored
	p.CanCollide = false
	p.CanTouch = false
	if d.studs then
		for _, f in Enum.NormalId:GetEnumItems() do
			local t = Instance.new("Texture")
			t.Name = "Studs"; t.Face = f
			t.ColorMapContent = CM; t.NormalMapContent = NM
			t.StudsPerTileU = d.studs; t.StudsPerTileV = d.studs
			t.Transparency = 0.2; t.Color3 = p.Color
			t.Parent = p
		end
	end
	p.Parent = parent
	return p
end

local function build(parent: Instance, origin: CFrame): Model
	local lever = Instance.new("Model")
	lever.Name = "Lever"
	for _, d in PARTS do
		local cf = origin * CFrame.new(d.pos) * CFrame.Angles(math.rad(d.rot.X), math.rad(d.rot.Y), math.rad(d.rot.Z))
		makePart(d, cf, true, lever)
	end
	local roll = Instance.new("Model")
	roll.Name = "RollLever"
	local hinge = Instance.new("Part")
	hinge.Name = "Hinge"; hinge.Size = V(0.293, 0.293, 0.293); hinge.Transparency = 1
	hinge.Anchored = true; hinge.CanCollide = false; hinge.CanQuery = false; hinge.CanTouch = false
	hinge.CFrame = origin * CFrame.new(0, HINGE_Y, 0)
	hinge.Parent = roll
	for _, d in MOVING do
		local p = makePart(d, origin * CFrame.new(d.pos), false, roll)
		p.Massless = true
		local w = Instance.new("WeldConstraint"); w.Part0 = hinge; w.Part1 = p; w.Parent = p
		if d.glow then
			local l = Instance.new("PointLight"); l.Name = "Glow"; l.Color = Color3.fromHex("ff6a3d"); l.Range = 6; l.Brightness = 0; l.Parent = p
		end
	end
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "RollPrompt"; pr.ActionText = "Roll"; pr.ObjectText = "Roll Lever"
	pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0
	pr.MaxActivationDistance = 6; pr.RequiresLineOfSight = false
	pr.Parent = hinge
	local ev = Instance.new("BindableEvent"); ev.Name = "Pulled"; ev.Parent = roll
	local sc = Instance.new("Script"); sc.Name = "LeverScript"; sc.Source = SCRIPT_SOURCE; sc.Parent = roll
	roll.Parent = lever
	lever.PrimaryPart = lever:FindFirstChild("2") :: BasePart
	lever.Parent = parent
	return lever
end

return build
