-- CustomPrompts — власний вигляд підказок E для ProximityPrompt із Style = Custom (як кнопка COLLECT: стиль A, клавіша E в куті).
-- Де: StarterPlayer/StarterPlayerScripts/CustomPrompts (LocalScript).
-- Налаштування — атрибути самого ProximityPrompt:
--   UIText (напис, за замовчуванням ActionText капсом), UIColor (колір StyleA: blue / orange / green ...),
--   UIIcon (rbxassetid іконки ліворуч від напису), UIOffsetY (висота над деталлю-батьком, стади), UIWidth (ширина, стади).
-- Показ / сховування робить сам рушій (PromptShown / PromptHidden): відстань MaxActivationDistance, RequiresLineOfSight —
--   не просвічує крізь стіни, Enabled = false — ховається. Клавіша E працює рушієм; клік мишкою / дотик —
--   InputHoldBegin / InputHoldEnd. Поява — пружне збільшення з центру (Back, 0,22 с), зникнення — 0,14 с.

local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local W, H = 250, 74       -- полотно кнопки (одиниці дизайну StyleA)
local BW, BH = 234, 66     -- сама кнопка

local shown: { [ProximityPrompt]: { gui: BillboardGui, pop: UIScale, tok: number } } = {}

local function build(prompt: ProximityPrompt)
	local widthStuds = (prompt:GetAttribute("UIWidth") :: number?) or 8.8
	local bb = Instance.new("BillboardGui")
	bb.Name = "CustomPrompt"
	bb.Size = UDim2.fromScale(widthStuds, widthStuds * H / W)
	bb.AlwaysOnTop = true
	bb.Active = true -- без Active BillboardGui не пропускає клік і дотик
	bb.ResetOnSpawn = false
	bb.LightInfluence = 0
	bb.Adornee = prompt.Parent :: any
	bb.StudsOffsetWorldSpace = Vector3.new(0, (prompt:GetAttribute("UIOffsetY") :: number?) or 3, 0)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1; holder.Size = UDim2.fromOffset(W, H); holder.Parent = bb
	local fit = Instance.new("UIScale"); fit.Parent = holder
	bb:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fit.Scale = bb.AbsoluteSize.X / W end)
	local anim = Instance.new("Frame")
	anim.BackgroundTransparency = 1; anim.AnchorPoint = Vector2.new(0.5, 0.5)
	anim.Position = UDim2.fromOffset(W / 2, H / 2); anim.Size = UDim2.fromOffset(W, H); anim.Parent = holder
	local pop = Instance.new("UIScale"); pop.Scale = 0; pop.Parent = anim
	local text = (prompt:GetAttribute("UIText") :: string?) or string.upper(prompt.ActionText)
	local icon = prompt:GetAttribute("UIIcon") :: string?
	local btn = StyleA.new(anim, { size = Vector2.new(BW, BH), position = Vector2.new(8, 4), color = (prompt:GetAttribute("UIColor") :: string?) or "green",
		text = text, textSize = #text > 9 and 24 or 28, clickable = true, name = "PromptButton" })
	if icon and icon ~= "" then
		-- іконка ліворуч на грані (трохи вилазить за верхній край, як у стилі пака), напис — у правій частині
		local fx, fy, fw, fh = StyleA.faceRect(BW, BH)
		local s = fh * 0.95 -- іконка в межах грані (раніше 1,45 — завелика)
		local img = Instance.new("ImageLabel")
		img.Name = "PromptIcon"; img.BackgroundTransparency = 1; img.Image = icon; img.ScaleType = Enum.ScaleType.Fit
		img.Size = UDim2.fromOffset(s, s); img.Position = UDim2.fromOffset(fx + 8, fy + fh / 2 - s / 2)
		img.ZIndex = 6; img.Parent = btn.root
		if btn.label then
			btn.label.Position = UDim2.fromOffset(fx + s + 6, btn.label.Position.Y.Offset)
			btn.label.Size = UDim2.fromOffset(fw - s - 14, btn.label.Size.Y.Offset)
		end
	end
	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromOffset(30, 30); key.Position = UDim2.fromOffset(-6, -8); key.BackgroundColor3 = Color3.fromHex("1d2233")
	key.BorderSizePixel = 0; key.FontFace = HEAVY; key.TextScaled = true; key.Text = prompt.KeyboardKeyCode.Name; key.TextColor3 = Color3.new(1, 1, 1); key.ZIndex = 8
	local ks = Instance.new("UIStroke"); ks.Color = INK; ks.Thickness = 2.5; ks.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ks.Parent = key
	key.Parent = anim
	StyleA.bind(btn, { debounce = 0.25, onClick = function()
		if not prompt.Enabled then return end
		prompt:InputHoldBegin()
		task.defer(function() prompt:InputHoldEnd() end)
	end })
	bb.Parent = playerGui
	return bb, pop
end

PPS.PromptShown:Connect(function(prompt: ProximityPrompt)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	local e = shown[prompt]
	if not e then
		local gui, pop = build(prompt)
		e = { gui = gui, pop = pop, tok = 0 }
		shown[prompt] = e
		prompt.Destroying:Connect(function() if shown[prompt] then shown[prompt].gui:Destroy(); shown[prompt] = nil end end)
	end
	e.tok += 1
	e.gui.Enabled = true
	TweenService:Create(e.pop, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

PPS.PromptHidden:Connect(function(prompt: ProximityPrompt)
	local e = shown[prompt]
	if not e then return end
	e.tok += 1
	local my = e.tok
	local tw = TweenService:Create(e.pop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
	tw.Completed:Connect(function() if e.tok == my then e.gui.Enabled = false end end)
	tw:Play()
end)

-- поки місця призначення немає (атрибут ComingSoon) — кнопка хитається, над нею спливає «COMING SOON»
PPS.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if not prompt:GetAttribute("ComingSoon") then return end
	local e = shown[prompt]
	if not e then return end
	local btnRoot = e.gui:FindFirstChild("PromptButton", true)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromOffset(W, 34); t.Position = UDim2.fromOffset(0, -38)
	t.FontFace = HEAVY; t.TextSize = 28; t.Text = "COMING SOON"; t.TextColor3 = Color3.fromHex("ffd34d"); t.ZIndex = 9
	local st = Instance.new("UIStroke"); st.Color = INK; st.Thickness = 3; st.Parent = t
	t.Parent = e.gui:FindFirstChildWhichIsA("Frame")
	TweenService:Create(t, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, -64), TextTransparency = 1 }):Play()
	TweenService:Create(st, TweenInfo.new(1.1), { Transparency = 1 }):Play()
	task.delay(1.15, function() t:Destroy() end)
	if btnRoot then
		local x0 = btnRoot.Position
		for _, dx in { -8, 8, -5, 5, -2, 0 } do btnRoot.Position = x0 + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		btnRoot.Position = x0
	end
end)

-- ===== табличка «CAVE» над колом печери: золотий градієнт, що переливається, + білий відблиск (як SELL / FORGE) =====
do
	local RunService = game:GetService("RunService")
	local P = { Color3.fromHex("fff6b0"), Color3.fromHex("ffd23a"), Color3.fromHex("ff9a1a"), Color3.fromHex("ffd23a") }
	local function sample(u)
		local x = (u % 1) * #P
		local k = math.floor(x)
		local t = x - k
		t = t * t * (3 - 2 * t)
		return P[k + 1]:Lerp(P[(k + 1) % #P + 1], t)
	end
	local SHINE_T = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) })
	local signs = {}
	local function hook(sign: Instance)
		local t = sign:FindFirstChild("Title")
		if not (t and t:IsA("TextLabel")) or signs[t] then return end
		local grad = t:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", t)
		grad.Rotation = 0
		for _, old in t.Parent:GetChildren() do if old.Name == "TitleShine" then old:Destroy() end end
		local sh = t:Clone()
		sh.Name = "TitleShine"; sh.TextColor3 = Color3.new(1, 1, 1); sh.ZIndex = t.ZIndex + 1
		for _, c in sh:GetChildren() do c:Destroy() end
		local sg = Instance.new("UIGradient"); sg.Rotation = 25; sg.Transparency = SHINE_T; sg.Offset = Vector2.new(-1.3, 0); sg.Parent = sh
		sh.Parent = t.Parent
		local tw = TweenService:Create(sg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
		tw.Completed:Connect(function() sg.Offset = Vector2.new(-1.3, 0) end)
		signs[t] = { grad = grad, tween = tw, nextAt = os.clock() + 1 + math.random() * 3 }
	end
	task.spawn(function()
		while true do
			local niches = workspace:FindFirstChild("Niches")
			if niches then for _, d in niches:GetDescendants() do if d.Name == "CaveSign" and d:IsA("BillboardGui") then hook(d) end end end
			task.wait(2)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local ks
		for t, s in signs do
			if not t.Parent then signs[t] = nil continue end
			if not ks then
				ks = {}
				for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 - now / 4)) end
				ks = ColorSequence.new(ks)
			end
			s.grad.Color = ks
			if now >= s.nextAt then s.tween:Play(); s.nextAt = now + 3 + math.random() * 3 end
		end
	end)
end
