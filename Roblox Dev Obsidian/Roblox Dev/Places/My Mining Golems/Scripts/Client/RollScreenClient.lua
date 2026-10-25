-- RollScreenClient — анімація екрана Roll Upgrades у всіх нішах.
-- Де: StarterPlayer/StarterPlayerScripts/RollScreenClient (LocalScript). Стан ставить сервер (RollScreenService):
-- атрибут Open на моделі Niches/<ніша>/RollUpgradeScreen.
--
-- Відкриття: зі щілини жолоба сиплеться пил, табличка падає з прискоренням (0.85 с) → ланцюги різко
-- натягуються: табличка провисає й пружно вертається, гойдається вперед-назад і трохи вбік
-- (згасає за ~2 с), з-під жолоба знову сиплеться пил, камера ледь здригається. Підсвітки екрана немає.
-- Закриття: табличка плавно піднімається в жолоб і ховається (LocalTransparencyModifier).
--
-- У префабі табличка стоїть у позі «опущено» (так зручно редагувати). Клієнт запам'ятовує цю позу
-- і рухає всі деталі відносно точки підвісу (центр щілини на висоті AnchorY).
-- Атрибути моделі: AnchorY, ShownTop (верх планки в опущеному стані), HiddenTop (в схованому).

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local T_FALL, T_CATCH, T_UP = 0.85, 2.2, 1.2
local PITCH = 0.95 -- крок ланок

local camera = workspace.CurrentCamera
local shake = 0

-- Звук «навпаки» для підйому. Roblox не вміє грати звук задом наперед (PlaybackSpeed < 0 стає 0),
-- тому граємо його короткими шматками від кінця до початку з коротким перехрестям: кожен шматок звучить
-- уперед, але загальна огинаюча (наростання → згасання) йде у зворотний бік.
local REV_CHUNK, REV_FADE = 0.08, 0.025
local function stopReversed(S)
	S.revId = (S.revId or 0) + 1
	if S.revPair then for _, s in S.revPair do s:Stop() end end
end
local function playReversed(S, snd: Sound)
	stopReversed(S)
	local id = S.revId
	task.spawn(function()
		local len = snd.TimeLength
		if len <= 0 then snd.TimePosition = 0; snd:Play() return end -- ще не завантажився: граємо як є
		if not S.revPair then
			S.revPair = {}
			for k = 1, 2 do
				local c = snd:Clone(); c.Name = snd.Name .. "_Rev" .. k; c.Parent = snd.Parent
				S.revPair[k] = c
			end
		end
		local vol, t, k, prev = snd.Volume, len, 0, nil
		while t > 0 and S.revId == id do
			local from = math.max(0, t - REV_CHUNK)
			k += 1
			local s = S.revPair[k % 2 + 1]
			s.Volume = 0; s.TimePosition = from; s:Play()
			TweenService:Create(s, TweenInfo.new(REV_FADE), { Volume = vol }):Play()
			if prev then
				local p = prev
				TweenService:Create(p, TweenInfo.new(REV_FADE), { Volume = 0 }):Play()
				task.delay(REV_FADE, function() if p.Volume <= 0.001 then p:Stop() end end)
			end
			prev = s
			task.wait(t - from)
			t = from
		end
		if prev and S.revId == id then
			TweenService:Create(prev, TweenInfo.new(REV_FADE), { Volume = 0 }):Play()
			task.delay(REV_FADE, function() prev:Stop() end)
		end
	end)
end

local function easeInOut(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end

local screens = {}

local function setup(screen: Model)
	if screens[screen] then return end
	local board = screen:FindFirstChild("Board")
	if not board then return end
	local anchorY = screen:GetAttribute("AnchorY")
	local shownTop = screen:GetAttribute("ShownTop")
	local hiddenTop = screen:GetAttribute("HiddenTop")
	local bcf = board:GetBoundingBox()
	local pivot = CFrame.new(bcf.Position.X, anchorY, bcf.Position.Z)
	local root0 = CFrame.new(bcf.Position.X, shownTop, bcf.Position.Z)

	local S = { screen = screen, parts = {}, rels = {}, links = {}, mode = "hidden", t = 0, y = hiddenTop, y0 = hiddenTop,
		swing = 0, roll = 0, pivot = pivot, shownTop = shownTop, hiddenTop = hiddenTop }
	for _, d in board:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(S.parts, d); table.insert(S.rels, root0:ToObjectSpace(d.CFrame))
		end
	end
	local eyes = board:FindFirstChild("Eyelets")
	S.chains = {}
	for i = 1, 2 do
		local f = screen:FindFirstChild("Chain" .. i)
		local eye = eyes and eyes:FindFirstChild("Eyelet" .. i)
		if f and eye then
			local links = {}
			for _, l in f:GetChildren() do links[tonumber(l.Name:match("%d+")) or 0] = l end
			table.insert(S.chains, {
				links = links, n = #links,
				top = Vector3.new(bcf.Position.X, anchorY, eye.Position.Z),
				eyeRel = root0:ToObjectSpace(eye.CFrame) * CFrame.new(0, eye.Size.Y / 2, 0),
			})
		end
	end
	local dust = screen:FindFirstChild("DustEmitter")
	S.dust = dust and dust:FindFirstChild("Dust")
	-- звуки в DustEmitter (у щілині жолоба): Snd_Lower — бряжчання ланцюгів при спуску, Snd_Raise — підйом (якщо додано)
	S.sndLower = dust and dust:FindFirstChild("Snd_Lower")
	S.sndRaise = dust and dust:FindFirstChild("Snd_Raise") -- грає «навпаки» (playReversed)
	S.center = bcf.Position
	screens[screen] = S

	screen:GetAttributeChangedSignal("Open"):Connect(function()
		local open = screen:GetAttribute("Open") == true
		if open and (S.mode == "hidden" or S.mode == "rising") then
			S.mode = "falling"; S.t = 0; S.y0 = S.y
			if S.dust then S.dust:Emit(30) end
			stopReversed(S)
			if S.sndLower then S.sndLower.TimePosition = 0; S.sndLower:Play() end
			if (camera.CFrame.Position - S.center).Magnitude < 160 then shake = math.max(shake, 0.12) end
		elseif not open and S.mode ~= "hidden" and S.mode ~= "rising" then
			S.mode = "rising"; S.t = 0; S.y0 = S.y
			if S.sndLower then S.sndLower:Stop() end
			if S.sndRaise then playReversed(S, S.sndRaise) end
		end
	end)
	screen.Destroying:Connect(function() screens[screen] = nil end)
	screen.AncestryChanged:Connect(function(_, parent) if not parent then screens[screen] = nil end end)

	if screen:GetAttribute("Open") == true then
		S.mode = "shown"; S.y = shownTop
	end
	S.dirty = true
end

-- поставити табличку і ланцюги в поточну позу
local function apply(S)
	local L = S.pivot.Y - S.y
	local root = S.pivot * CFrame.Angles(S.roll, 0, S.swing) * CFrame.new(0, -L, 0)
	local visible = S.mode ~= "hidden"
	local cfs = table.create(#S.parts)
	for i, rel in S.rels do cfs[i] = root * rel end
	workspace:BulkMoveTo(S.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	local ltm = visible and 0 or 1
	if S.ltm ~= ltm then
		for _, p in S.parts do p.LocalTransparencyModifier = ltm end
		S.ltm = ltm
	end
	-- ланцюги: від щілини до вушка; ланки нижче вушка ховаються
	for _, c in S.chains do
		local bot = (root * c.eyeRel).Position
		local v = c.top - bot
		local len = v.Magnitude
		local up = len > 0.01 and v.Unit or Vector3.yAxis
		local base = CFrame.lookAt(Vector3.zero, up, Vector3.xAxis) * CFrame.Angles(-math.pi / 2, 0, 0)
		local parts, frames = {}, {}
		for k = 1, c.n do
			local l = c.links[k]
			if l then
				local d = (k - 0.5) * PITCH
				local show = visible and (bot.Y < c.top.Y) and d <= len
				l.LocalTransparencyModifier = show and 0 or 1
				if show then
					table.insert(parts, l)
					table.insert(frames, (CFrame.new(c.top - up * d) * base) * CFrame.Angles(0, (k % 2 == 0) and math.pi / 2 or 0, 0))
				end
			end
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged) end
	end
end

local function step(S, dt)
	S.t += dt
	local t = S.t
	if S.mode == "falling" then
		local k = math.min(1, t / T_FALL)
		S.y = S.y0 + (S.shownTop - S.y0) * k * k -- вільне падіння
		if k >= 1 then
			S.mode = "catch"; S.t = 0
			if S.dust then S.dust:Emit(25) end
			if (camera.CFrame.Position - S.center).Magnitude < 160 then shake = math.max(shake, 0.3) end
		end
	elseif S.mode == "catch" then
		-- ланцюги натяглись: провисання з пружиною, гойдання вперед-назад і вбік
		S.y = S.shownTop - 1.3 * math.exp(-4.2 * t) * math.sin(13 * t)
		S.swing = 0.05 * math.exp(-1.0 * t) * math.sin(2.7 * t + 0.4) + 0.02 * math.exp(-3 * t)
		S.roll = 0.025 * math.exp(-1.6 * t) * math.sin(5.1 * t)
		if t >= T_CATCH then S.mode = "shown"; S.t = 0; S.y = S.shownTop; S.roll = 0 end
	elseif S.mode == "shown" then
		S.swing = 0.004 * math.sin(t * 1.3) -- ледь помітне погойдування
	elseif S.mode == "rising" then
		local k = math.clamp(t / T_UP, 0, 1)
		S.y = S.y0 + (S.hiddenTop - S.y0) * easeInOut(k)
		S.swing *= 0.9; S.roll *= 0.9
		if k >= 1 then S.mode = "hidden"; S.swing = 0; S.roll = 0 end
	end
end

local function scan(root)
	for _, d in root:GetDescendants() do
		if d.Name == "RollUpgradeScreen" and d:IsA("Model") then task.defer(setup, d) end
	end
end
local niches = workspace:WaitForChild("Niches")
scan(niches)
niches.DescendantAdded:Connect(function(d)
	if d.Name == "RollUpgradeScreen" and d:IsA("Model") then task.defer(setup, d) end
end)

RunService.RenderStepped:Connect(function(dt)
	for _, S in screens do
		if S.mode ~= "hidden" or S.dirty then
			local near = (camera.CFrame.Position - S.center).Magnitude < 250
			if S.mode ~= "shown" or near or S.dirty then
				step(S, dt)
				apply(S)
			end
			S.dirty = false
		end
	end
end)

-- ледь помітне трусіння камери (після стандартної камери)
RunService:BindToRenderStep("RollScreenShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake > 0 then
		camera.CFrame *= CFrame.new((math.random() - 0.5) * shake, (math.random() - 0.5) * shake, 0)
		shake = math.max(0, shake - dt * 0.9)
	end
end)
