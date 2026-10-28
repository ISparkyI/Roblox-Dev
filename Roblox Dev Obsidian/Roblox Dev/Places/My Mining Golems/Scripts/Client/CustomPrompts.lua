-- CustomPrompts — власний вигляд підказок E для ProximityPrompt із Style = Custom (як кнопка COLLECT: стиль A, клавіша E в куті).
-- Де: StarterPlayer/StarterPlayerScripts/CustomPrompts (LocalScript).
-- Налаштування — атрибути самого ProximityPrompt:
--   UIText (напис, за замовчуванням ActionText капсом), UIColor (колір StyleA: blue / orange / green ...),
--   UIIcon (rbxassetid іконки ліворуч від напису), UIOffsetY (висота над деталлю-батьком, стади), UIWidth (ширина, стади).
-- Показ / сховування робить сам рушій (PromptShown / PromptHidden): відстань MaxActivationDistance, RequiresLineOfSight —
--   не просвічує крізь стіни, Enabled = false — ховається. Клавіша E працює рушієм; клік мишкою / дотик —
--   InputHoldBegin / InputHoldEnd. Поява — пружне збільшення з центру (Back, 0,22 с), зникнення — 0,14 с.
-- Підказка з HoldDuration > 0 (вхід і вихід печери — 0,9 с, важіль ролу RollPrompt — 0,25 с): кнопка в своєму яскравому кольорі, поверх неї —
--   темна напівпрозора «тінь» на всю кнопку разом із зовнішньою обводкою (грань, світла рамка,
--   лінія, нижній бортик, обводка; під іконкою й написом); у спокої вона покриває все це. Треба ТРИМАТИ E / мишку / палець: ліва межа тіні їде вправо і відкриває яскраву
--   кнопку (це й є «заповнення»), відпустив раніше — тінь плавно повертається; дійшло до 100 % —
--   рушій сам запускає Triggered (телепорт робить сервер, CaveEntrance). Блакитної заливки немає.
-- Атрибути UIText / UIColor / UIIcon / UIDisabled можна міняти на льоту (напр. CaveStandsClient — кнопки стендів печери):
--   кнопку перебудовано. UIDisabled = true — сіра кнопка: затиск не заповнюється, кнопка хитається з глухим звуком відмови.

local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local StyleA = require(RS:WaitForChild("Shared"):WaitForChild("StyleA"))
local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds"))
-- Звуки: tap — натискання (E, мишка, дотик; у підказок з утриманням — на початку утримання), lever — важіль ролу
--   (RollPrompt, лише в того, хто тягне). StyleA.bind кнопки підказки — tap = false, щоб не було подвійного звуку.
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local W, H = 250, 74       -- полотно кнопки (одиниці дизайну StyleA)
local BW, BH = 234, 66     -- сама кнопка

local shown: { [ProximityPrompt]: { gui: BillboardGui, pop: UIScale, tok: number, conns: { any } } } = {}

local SHADE = Color3.fromRGB(0, 0, 8)   -- тінь утримання: майже чорна з ледь синім відтінком
local SHADE_T = 0.45                     -- прозорість: грань темнішає приблизно як колись від ImageColor3 (140, 140, 150)
local BACK_SPEED = 2.5                  -- відпустив раніше: тінь повертається зі швидкістю (частка / с)

-- утримання: кнопка яскрава, поверх неї — темна тінь у рамці HoldClip на ВСЮ кнопку, разом із зовнішньою
-- обводкою (рішення користувача: головне — рівно, без щілин; кути прямі, як у стилі A), ClipsDescendants,
-- ZIndex 2 — над гранню й візерунком, під відблиском, написом і іконкою. Правий край тіні прив'язаний
-- до правого краю кнопки, ширина = 1 − p: ліва межа їде вправо і відкриває яскраву кнопку.
local function holdFx(prompt: ProximityPrompt, btn: any, conns: { any })
	local clip = Instance.new("Frame")
	clip.Name = "HoldClip"; clip.BackgroundTransparency = 1; clip.BorderSizePixel = 0; clip.ClipsDescendants = true; clip.Active = false
	clip.Position = UDim2.fromOffset(0, 0); clip.Size = UDim2.fromScale(1, 1); clip.ZIndex = 2; clip.Parent = btn.root -- тінь на всю кнопку, разом з обводкою
	local fill = Instance.new("Frame")
	fill.Name = "HoldShade"; fill.BackgroundColor3 = SHADE; fill.BackgroundTransparency = SHADE_T; fill.BorderSizePixel = 0
	fill.AnchorPoint = Vector2.new(1, 0); fill.Position = UDim2.fromScale(1, 0)
	fill.Size = UDim2.fromScale(1, 1); fill.ZIndex = 1; fill.Active = false; fill.Parent = clip
	local p, holding = 0, false
	local conn: RBXScriptConnection? = nil
	local function step(dt: number)
		if holding then
			p = math.min(1, p + dt / math.max(prompt.HoldDuration, 0.05))
		else
			p = math.max(0, p - dt * BACK_SPEED)
		end
		fill.Size = UDim2.fromScale(1 - p, 1)
		if not holding and p <= 0 and conn then conn:Disconnect(); conn = nil end
	end
	local function run()
		if not conn then conn = game:GetService("RunService").RenderStepped:Connect(step) end
	end
	table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
		if prompt:GetAttribute("UIDisabled") then -- сіра кнопка: тримати марно — хитається, глухий звук відмови
			StyleA.shake(btn) -- звук відмови deny грає StyleA.shake
			return
		end
		holding = true; run(); StyleA.tap()
	end))
	table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function() holding = false; run() end))
	table.insert(conns, prompt.Triggered:Connect(function()
		-- сіра кнопка (UIDisabled): рушій усе одно стріляє Triggered після HoldDuration — жодного візуалу утримання
		-- (до 27.10.2026 тут на мить відкривалась яскрава кнопка і тінь спадала назад); лише shake + deny на початку затиску
		if prompt:GetAttribute("UIDisabled") then holding = false; return end
		-- дійшло до 100 %: кнопка ще мить повністю яскрава, потім тінь повертається
		holding = false; p = 1; fill.Size = UDim2.fromScale(0, 1)
		task.delay(0.25, function() if fill.Parent then run() end end)
	end))
	table.insert(conns, { Disconnect = function() if conn then conn:Disconnect(); conn = nil end end }) -- перебудова: зупинити анімацію
end

-- Масштаб умісту білбордів рахуємо самі щокадру з камери (до рендеру). bb.AbsoluteSize оновлюється із запізненням, і на 1 кадр
-- кнопка могла намалюватись зі старим величезним масштабом на весь екран (поява, різкий рух камери).
-- Камера майже всередині кнопки або позаду — уміст ховаємо.
local fits: { [BillboardGui]: { holder: Frame, fit: UIScale, w: number } } = {}
local function adorneePos(a: Instance?): Vector3?
	if not a then return nil end
	if a:IsA("BasePart") then return a.Position end
	if a:IsA("Attachment") then return a.WorldPosition end
	if a:IsA("Model") then return a:GetPivot().Position end
	return nil
end
game:GetService("RunService"):BindToRenderStep("CustomPromptFit", Enum.RenderPriority.Camera.Value + 2, function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local k = cam.ViewportSize.Y / (2 * math.tan(math.rad(cam.FieldOfView) / 2))
	for bb, f in fits do
		if not bb.Parent then fits[bb] = nil continue end
		if not bb.Enabled then continue end
		local p = adorneePos(bb.Adornee)
		if not p then continue end
		local depth = (p + bb.StudsOffsetWorldSpace - cam.CFrame.Position):Dot(cam.CFrame.LookVector)
		if depth < 2 then f.holder.Visible = false continue end
		f.fit.Scale = math.min(f.w * k / depth / W, 6)
		f.holder.Visible = true
	end
end)

local function build(prompt: ProximityPrompt, conns: { any })
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
	fits[bb] = { holder = holder, fit = fit, w = widthStuds }
	local anim = Instance.new("Frame")
	anim.BackgroundTransparency = 1; anim.AnchorPoint = Vector2.new(0.5, 0.5)
	anim.Position = UDim2.fromOffset(W / 2, H / 2); anim.Size = UDim2.fromOffset(W, H); anim.Parent = holder
	local pop = Instance.new("UIScale"); pop.Scale = 0; pop.Parent = anim
	local text = (prompt:GetAttribute("UIText") :: string?) or string.upper(prompt.ActionText)
	local icon = prompt:GetAttribute("UIIcon") :: string?
	local btn = StyleA.new(anim, { size = Vector2.new(BW, BH), position = Vector2.new(8, 4), color = if prompt:GetAttribute("UIDisabled") then "gray" else (prompt:GetAttribute("UIColor") :: string?) or "green",
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
	-- клавіша E — дитина кнопки (рухається й масштабується разом з нею при наведенні / натисканні); лівий верхній кут кнопки — (8, 4)
	key.Size = UDim2.fromOffset(30, 30); key.Position = UDim2.fromOffset(-6 - 8, -8 - 4); key.BackgroundColor3 = Color3.fromHex("1d2233")
	key.BorderSizePixel = 0; key.FontFace = HEAVY; key.TextScaled = true; key.Text = prompt.KeyboardKeyCode.Name; key.TextColor3 = Color3.new(1, 1, 1); key.ZIndex = 8
	local ks = Instance.new("UIStroke"); ks.Color = INK; ks.Thickness = 2.5; ks.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ks.Parent = key
	key.Parent = btn.root
	if prompt.HoldDuration > 0 then
		-- тримати мишкою / пальцем: натиснув — InputHoldBegin, відпустив або звів курсор — InputHoldEnd
		holdFx(prompt, btn, conns)
		StyleA.bind(btn, { tap = false })
		local down = false
		local function release() if down then down = false; prompt:InputHoldEnd() end end
		btn.button.InputBegan:Connect(function(inp: InputObject)
			if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and prompt.Enabled and not down then
				down = true; prompt:InputHoldBegin()
			end
		end)
		btn.button.InputEnded:Connect(function(inp: InputObject)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then release() end
		end)
		btn.button.MouseLeave:Connect(release)
		table.insert(conns, prompt.PromptHidden:Connect(release))
	else
		StyleA.bind(btn, { debounce = 0.25, tap = false, onClick = function()
			if not prompt.Enabled then return end
			prompt:InputHoldBegin()
			task.defer(function() prompt:InputHoldEnd() end)
		end })
	end
	bb.Parent = playerGui
	return bb, pop
end

PPS.PromptShown:Connect(function(prompt: ProximityPrompt)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	local e = shown[prompt]
	if not e then
		local conns = {}
		local gui, pop = build(prompt, conns)
		local entry = { gui = gui, pop = pop, tok = 0, conns = conns }
		e = entry
		shown[prompt] = entry
		prompt.Destroying:Connect(function()
			local cur = shown[prompt]
			if cur then
				for _, c in cur.conns do c:Disconnect() end
				cur.gui:Destroy(); shown[prompt] = nil
			end
		end)
		-- напис / колір / стан змінили на льоту — перебудувати кнопку (видимість і масштаб появи зберігаються)
		prompt.AttributeChanged:Connect(function(name)
			if name ~= "UIText" and name ~= "UIColor" and name ~= "UIIcon" and name ~= "UIDisabled" then return end
			local cur = shown[prompt]
			if not cur then return end
			for _, c in cur.conns do c:Disconnect() end
			local vis = cur.gui.Enabled
			cur.gui:Destroy()
			local nc = {}
			cur.gui, cur.pop = build(prompt, nc)
			cur.conns = nc
			cur.gui.Enabled = vis; cur.pop.Scale = vis and 1 or 0 -- нова кнопка — одразу в повний розмір (стара анімація появи до неї не дійде)
		end)
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

-- звук спрацювання (лише в того, хто натиснув): важіль ролу — lever, інші власні підказки без утримання — tap
PPS.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if prompt.Name == "RollPrompt" then
		UISounds.play("lever", 0.3)
	elseif prompt.Style == Enum.ProximityPromptStyle.Custom and prompt.HoldDuration <= 0 then
		StyleA.tap()
	end
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
	local GOLD = { Color3.fromHex("fff6b0"), Color3.fromHex("ffd23a"), Color3.fromHex("ff9a1a"), Color3.fromHex("ffd23a") }
	local RED = { Color3.fromHex("ffd6cf"), Color3.fromHex("ff5a4d"), Color3.fromHex("c9181d"), Color3.fromHex("ff5a4d") }   -- EXIT: той самий ефект, червона гама
	local function sample(P, u)
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
	local function hook(sign: Instance, pal)
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
		signs[t] = { grad = grad, tween = tw, nextAt = os.clock() + 1 + math.random() * 3, pal = pal }
	end
	task.spawn(function()
		while true do
			local niches = workspace:FindFirstChild("Niches")
			if niches then for _, d in niches:GetDescendants() do if d.Name == "CaveSign" and d:IsA("BillboardGui") then hook(d, GOLD) end end end
			for _, root in { workspace:FindFirstChild("Cave_Inside"), workspace:FindFirstChild("Caves") } do
				for _, d in root:GetDescendants() do if d.Name == "ExitSign" and d:IsA("BillboardGui") then hook(d, RED) end end
			end
			task.wait(2)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local cache = {}
		for t, s in signs do
			if not t.Parent then signs[t] = nil continue end
			local ks = cache[s.pal]
			if not ks then
				local list = {}
				for k = 0, 18 do list[#list + 1] = ColorSequenceKeypoint.new(k / 18, sample(s.pal, k / 18 * 2 - now / 4)) end
				ks = ColorSequence.new(list)
				cache[s.pal] = ks
			end
			s.grad.Color = ks
			if now >= s.nextAt then s.tween:Play(); s.nextAt = now + 3 + math.random() * 3 end
		end
	end)
end
