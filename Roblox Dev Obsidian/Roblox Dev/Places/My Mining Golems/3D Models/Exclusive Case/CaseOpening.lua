-- CaseOpening (ReplicatedStorage/Shared/CaseOpening): анімація відкриття Exclusive Case. Клієнтська, детермінована:
--   local anim = CaseOpening.new(caseModel, rewardModel?, opts?) -- caseModel — клон PlotAssets/ExclusiveCase у workspace
--   anim:pose(t)          -- поставити кадр на момент t (с) — можна «прокручувати» для скрінів/тестів
--   anim:play(onDone?)    -- програти від 0 до кінця (Heartbeat); повертає одразу
--   anim:destroy()
-- Фази (с): 0–1.4 заряд (тремтить, кристали розганяються й стягуються, світло росте),
--           1.4–1.75 вибух (кришка відлітає на шарнірі, спалах, промінь, хвиля, іскри),
--           1.75–3.4 нагорода підіймається з кейсу, росте й крутиться, кристали розлітаються,
--           3.4–4.5 нагорода ширяє над кейсом.
-- rewardModel — модель голема (скрипти з неї прибираються); opts.rewardScale — кінцевий масштаб (за замовчуванням 1).
local RunService = game:GetService("RunService")

local CaseOpening = {}
CaseOpening.__index = CaseOpening
CaseOpening.DURATION = 4.5
CaseOpening.BURST = 1.4

local function clamp01(x: number): number return math.clamp(x, 0, 1) end
local function easeOut(x: number): number x = clamp01(x); return 1 - (1 - x) ^ 3 end
local function easeOutBack(x: number): number
	x = clamp01(x); local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

type Rec = { part: BasePart, rel: CFrame }

function CaseOpening.new(case: Model, reward: Model?, opts: any?)
	local self = setmetatable({}, CaseOpening) :: any
	opts = opts or {}
	self.case = case
	self.S = (case:GetAttribute("Scale") :: number?) or 1
	self.base = case:GetPivot()
	self.hinge = (case:GetAttribute("Hinge") :: Vector3?) or Vector3.zero
	self.top = (case:GetAttribute("Top") :: number?) or 3
	local lid, orbits = case:FindFirstChild("Lid"), case:FindFirstChild("Orbits")
	self.body, self.lid, self.orbs = {} :: { Rec }, {} :: { Rec }, {} :: { any }
	local hingeCF = self.base * CFrame.new(self.hinge)
	for _, d in case:GetDescendants() do
		if d:IsA("BasePart") then
			if lid and d:IsDescendantOf(lid) then
				table.insert(self.lid, { part = d, rel = hingeCF:ToObjectSpace(d.CFrame) })
			elseif orbits and d:IsDescendantOf(orbits) then
				local rel = self.base:ToObjectSpace(d.CFrame)
				local p = rel.Position
				table.insert(self.orbs, { part = d, r = Vector2.new(p.X, p.Z).Magnitude, a0 = math.atan2(p.X, p.Z), y = p.Y, rot = rel.Rotation, size = d.Size })
			else
				table.insert(self.body, { part = d, rel = self.base:ToObjectSpace(d.CFrame) })
			end
		end
	end
	local glow = case:FindFirstChild("InnerGlow", true) :: BasePart?
	self.glow = glow
	self.light = glow and glow:FindFirstChild("CaseLight") :: PointLight?
	self.burstFx = glow and glow:FindFirstChild("Burst") :: ParticleEmitter?
	self.glowColor = glow and glow.Color or Color3.new(1, 0.35, 0.35)

	-- промінь і хвиля (створюються тут, ховаються до вибуху)
	local S = self.S
	local function fxPart(name: string, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.Neon; p.Color = Color3.fromHex("#ff7a8c"); p.Transparency = 1
		if shape then p.Shape = shape end
		p.Size = Vector3.new(1, 1, 1); p.Parent = case
		return p
	end
	self.beam = fxPart("FxBeam")
	self.shock = fxPart("FxShock", Enum.PartType.Cylinder)
	self.shock.Color = Color3.fromHex("#ffd1dc")

	-- нагорода
	if reward then
		for _, d in reward:GetDescendants() do
			if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
		end
		self.reward = reward
		self.rewardScale = (opts.rewardScale :: number?) or reward:GetScale()
		self.rewardParent = opts.parent or case.Parent
		reward.Parent = nil
	end
	self.burstDone = false
	return self
end

function CaseOpening:pose(t: number)
	local S, B = self.S, self.BURST or CaseOpening.BURST
	-- тремтіння корпусу до вибуху (наростає), після — легка віддача
	local caseCF = self.base
	if t < B then
		local k = (t / B) ^ 2
		local hop = math.abs(math.sin(t * 22)) * 0.12 * S * k
		caseCF = self.base * CFrame.new(0, hop, 0) * CFrame.Angles(0.035 * k * math.sin(t * 37), 0, 0.05 * k * math.sin(t * 43))
	elseif t < B + 0.4 then
		local k = 1 - (t - B) / 0.4
		caseCF = self.base * CFrame.new(0, -0.15 * S * k, 0)
	end
	local parts, cfs = {}, {}
	for _, r in self.body do table.insert(parts, r.part); table.insert(cfs, caseCF * r.rel) end
	-- кришка: на шарнірі відкидається назад на 115° з перельотом
	local open = t < B and 0 or easeOutBack((t - B) / 0.35)
	local hingeCF = caseCF * CFrame.new(self.hinge) * CFrame.Angles(-math.rad(115) * open, 0, 0)
	for _, r in self.lid do table.insert(parts, r.part); table.insert(cfs, hingeCF * r.rel) end
	-- кристали: розганяються й стягуються до кейсу, після вибуху розлітаються вгору й зникають
	for _, o in self.orbs do
		local ang, r, y, tr = 0, o.r, o.y, 0
		if t < B then
			ang = o.a0 + 1.2 * t + 2.2 * t ^ 3
			r = o.r * (1 - 0.35 * (t / B) ^ 2)
			y = o.y + 0.6 * S * (t / B)
		else
			local u = clamp01((t - B) / 1.2)
			ang = o.a0 + 1.2 * B + 2.2 * B ^ 3 + 6 * (t - B)
			r = o.r * (0.65 + 1.6 * easeOut(u))
			y = o.y + 0.6 * S + 6 * S * easeOut(u)
			tr = u
		end
		table.insert(parts, o.part)
		table.insert(cfs, self.base * CFrame.new(r * math.sin(ang), y, r * math.cos(ang)) * CFrame.Angles(0, ang * 2, 0) * o.rot)
		o.part.Transparency = tr
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

	-- світло всередині: росте під час заряду, спалах при вибуху, далі рівне сяйво
	local bright
	if t < B then bright = 1.2 * (t / B) ^ 2 + 0.3 * math.sin(t * 18) * (t / B)
	elseif t < B + 0.6 then bright = 1.2 + 4 * (1 - (t - B) / 0.6)
	else bright = 1.2 end
	if self.light then self.light.Brightness = math.max(0, bright) end
	if self.glow then
		local w = t < B and 0.15 * (t / B) * (0.5 + 0.5 * math.sin(t * 24)) or 0.2 * math.max(0, 1 - (t - B) / 0.8)
		self.glow.Color = self.glowColor:Lerp(Color3.new(1, 1, 1), w)
	end

	-- промінь: з'являється на вибуху, виростає вгору, згасає до 3.6 с
	local topCF = caseCF * CFrame.new(0, self.top, 0)
	if t >= B and t < 3.6 then
		local u = (t - B) / (3.6 - B)
		local h = (2 + 16 * easeOut(u * 3)) * S
		local w = (2.6 * (1 - 0.6 * u)) * S
		self.beam.Size = Vector3.new(w, h, w * 0.66)
		self.beam.CFrame = topCF * CFrame.new(0, h / 2, 0)
		self.beam.Transparency = 0.5 + 0.5 * u
	else
		self.beam.Transparency = 1
	end
	-- хвиля: плоский диск розходиться від кейсу за 0.55 с
	if t >= B and t < B + 0.55 then
		local u = (t - B) / 0.55
		local d = (3 + 14 * easeOut(u)) * S
		self.shock.Size = Vector3.new(0.12 * S, d, d)
		self.shock.CFrame = topCF * CFrame.Angles(0, 0, math.rad(90))
		self.shock.Transparency = 0.6 + 0.4 * u
	else
		self.shock.Transparency = 1
	end
	-- іскри — один раз на вибуху
	if t >= B and not self.burstDone then
		self.burstDone = true
		if self.burstFx then self.burstFx:Emit(70) end
	elseif t < B then
		self.burstDone = false
	end

	-- нагорода: підіймається з кейсу, росте й робить 2 оберти, потім ширяє
	local rw = self.reward
	if rw then
		local T0 = B + 0.35
		if t < T0 then
			rw.Parent = nil
		else
			local u = easeOut((t - T0) / (3.4 - T0))
			local y = self.top * (0.4 + 1.15 * u) + (t > 3.4 and 0.25 * S * math.sin((t - 3.4) * 3) or 0)
			local spin = 4 * math.pi * (1 - u)
			rw:ScaleTo(self.rewardScale * (0.15 + 0.85 * u))
			rw:PivotTo(self.base * CFrame.new(0, y, 0) * CFrame.Angles(0, spin, 0))
			rw.Parent = self.rewardParent
		end
	end
end

function CaseOpening:play(onDone: (() -> ())?)
	local t0 = os.clock()
	self.conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		self:pose(math.min(t, CaseOpening.DURATION))
		if t >= CaseOpening.DURATION then
			self.conn:Disconnect(); self.conn = nil
			if onDone then onDone() end
		end
	end)
end

function CaseOpening:destroy()
	if self.conn then self.conn:Disconnect() end
	self.beam:Destroy(); self.shock:Destroy()
	if self.reward then self.reward:Destroy() end
end

return CaseOpening
