--!strict
-- MutationSlotFX — анімований фон слота за мутацією голема (наведення / вибраний слот). Лише клієнт.
-- Де: ReplicatedStorage/Shared/MutationSlotFX (ModuleScript). Макет — 2D/Inventory/Preview/mutation_slots.html (погоджено 26.10.2026).
--
-- local fx = MutationSlotFX.new(parent, { pos = Vector2, size = Vector2, z = number, aura = bool? })
--   parent — контейнер слота (у InventoryUI — card, нахиляється разом зі слотом); pos/size — рамка слота в parent (без обводки);
--   z — ZIndex шару ефекту (над фоном слота, під іконкою); аура (лише Secret) — окремо під фоном (z − 2).
-- fx.setMut(mut | nil) — 0 Normal … 7 Secret; nil — без ефекту (порожній слот).
-- fx.setOn(on) — показати / сховати (плавно, FADE с). Анімація йде лише поки слот увімкнений або згасає.
-- fx.destroy()
--
-- Стилі (як у макеті): Normal — світліший сірий з білим верхом і тонким блиском; Bronze / Silver / Gold / Diamond — металевий
-- перелив палітри + блиск, що пробігає (Gold / Diamond — іскри); Void — те саме в фіолетових тонах (до 26.10.2026 були
-- кулі й частинки); Rainbow — яскрава насичена веселка, що рухається (лише легке затемнення країв);
-- Secret (v23) — чорно-графітовий перелив + біло-сірий блиск, білі іскри, біло-сіра пульсуюча рамка, легка біла аура (опис нижче — старий); Secret — чорний обсидіан, голографічний хром (білий / блідо-ціан / блідо-рожевий),
-- яскравий блиск раз на ~2,2 с, білі іскри, світна рамка, що пульсує, і аура навколо слота.
-- Без CanvasGroup: прозорість кожного елемента = 1 − (базова непрозорість × пульс × fade).
-- Один спільний Heartbeat (≈30 оновлень/с) на всі увімкнені слоти; знищений слот відписується сам.

local RunService = game:GetService("RunService")

local M = {}

M.SPARK = "rbxassetid://103166730261377" -- іскра (4-кутна зірка, біла з alpha; Decal 78342739855690)
M.GLOW9 = "rbxassetid://100291177927012" -- сяйво 9-slice 128 (центр 32..96 прозорий; Decal 139623808943768)
M.FADE = 0.15

local STEP = 1 / 30
local C = Color3.fromHex
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local function pal(t: { string }): { Color3 }
	local o = {}
	for _, h in t do table.insert(o, C(h)) end
	return o
end
-- палітри фону (з макету)
local METAL = {
	[1] = pal({ "8f4a1f", "e0874a", "ffc08a", "b5612c", "e0874a" }),
	[2] = pal({ "8b96a3", "d6dde4", "ffffff", "9aa6b2", "e8edf2" }),
	[3] = pal({ "b8860b", "ffd23a", "fff3a8", "e0a51c", "ffe066" }),
	[4] = pal({ "2f8fe8", "6fe8ff", "e6fdff", "3fa9ff", "b5f4ff" }),
	-- Void (26.10.2026): як інші метали — перелив темно-фіолетовий → фіолетовий → бузковий відблиск (без куль і частинок)
	[5] = pal({ "3d1478", "7a2fd6", "a24bff", "d9b8ff", "5a1fb0" }),
	-- Rainbow (26.10.2026): чисті насичені кольори веселки
	[6] = pal({ "ff2a2a", "ff8a00", "ffe600", "22e04a", "00c8ff", "2a5cff", "b02aff" }),
}
-- Secret: чорний → графіт → світло-сірий відблиск (обсидіан)
local OBSIDIAN = pal({ "060607", "1c1d21", "3a3d43", "8a9099", "2a2c31", "0e0e10" })
local SPARKS = { [3] = 3, [4] = 6, [6] = 3, [7] = 8 }

local function sample(p: { Color3 }, u: number): Color3
	local n = #p
	local x = (u % 1) * n
	local i = math.floor(x)
	local t = x - i
	t = t * t * (3 - 2 * t)
	return p[i + 1]:Lerp(p[(i + 1) % n + 1], t)
end
local function flowSeq(p: { Color3 }, ph: number, rep: number): ColorSequence
	local ks = table.create(12)
	for k = 0, 11 do
		local x = k / 11
		ks[k + 1] = ColorSequenceKeypoint.new(x, sample(p, x * rep - ph))
	end
	return ColorSequence.new(ks)
end
local function seq(list: { { number } }): NumberSequence
	local ks = {}
	for _, v in list do table.insert(ks, NumberSequenceKeypoint.new(v[1], v[2])) end
	return NumberSequence.new(ks)
end
local function cseq(list: { { any } }): ColorSequence
	local ks = {}
	for _, v in list do table.insert(ks, ColorSequenceKeypoint.new(v[1], C(v[2]))) end
	return ColorSequence.new(ks)
end
local function new(class: string, props: any, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do (o :: any)[k] = v end
	o.Parent = parent
	return o
end

type El = { inst: Instance, prop: string, op: number, dyn: ((t: number) -> number)? }

local active: { [any]: boolean } = {}
local conn: RBXScriptConnection? = nil
local clock, acc = 0, 0

local function step(dt: number)
	clock += dt
	acc += dt
	if acc < STEP then return end
	local d = acc
	acc = 0
	for fx in active do
		if not fx.box.Parent or not fx.box:IsDescendantOf(game) then
			active[fx] = nil
		else
			-- fade
			local target = fx.on and 1 or 0
			local k = d / M.FADE
			if fx.f < target then fx.f = math.min(target, fx.f + k) elseif fx.f > target then fx.f = math.max(target, fx.f - k) end
			fx.update(clock)
			if fx.f <= 0 and not fx.on then
				fx.box.Visible = false
				if fx.auraBox then fx.auraBox.Visible = false end
				active[fx] = nil
			end
		end
	end
	if next(active) == nil and conn then conn:Disconnect(); conn = nil end
end
local function wake(fx)
	active[fx] = true
	if not conn then conn = RunService.Heartbeat:Connect(step) end
end

function M.new(parent: GuiObject, opt: any): any
	local W, H = opt.size.X, opt.size.Y
	local z = opt.z or 3
	local box = new("Frame", { Name = "MutFx", BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		Position = UDim2.fromOffset(opt.pos.X, opt.pos.Y), Size = UDim2.fromOffset(W, H), ZIndex = z, Visible = false }, parent)
	local auraBox = (opt.aura ~= false) and new("Frame", { Name = "MutAura", BackgroundTransparency = 1, Position = UDim2.fromOffset(opt.pos.X, opt.pos.Y),
		Size = UDim2.fromOffset(W, H), ZIndex = math.max(1, z - 2), Visible = false }, parent) or nil
	local fx: any = { box = box, auraBox = auraBox, f = 0, on = false, mut = -1 }
	local els: { El } = {}
	local updaters: { (t: number) -> () } = {}
	local rnd = Random.new(opt.seed or math.random(1, 1e6))

	local function add(inst: Instance, prop: string, op: number, dyn: ((t: number) -> number)?)
		table.insert(els, { inst = inst, prop = prop, op = op, dyn = dyn })
		return inst
	end
	local function layer(name: string, color: Color3, zi: number): Frame
		return new("Frame", { Name = name, BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = zi, BackgroundTransparency = 1 }, box)
	end
	-- затемнення країв (віньєтка з 4 смуг)
	local function vignette(a: number, zi: number)
		local w = math.floor(math.min(W, H) * 0.32)
		for i, d in { { 0, 0, 1, 0, 90 }, { 0, 1, 1, 0, -90 }, { 0, 0, 0, 1, 0 }, { 1, 0, 0, 1, 180 } } do
			local horiz = d[3] == 1
			local f = new("Frame", { BackgroundColor3 = BLACK, BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = zi,
				AnchorPoint = Vector2.new(d[1], d[2]), Position = UDim2.fromScale(d[1], d[2]),
				Size = horiz and UDim2.new(1, 0, 0, w) or UDim2.new(0, w, 1, 0) }, box)
			new("UIGradient", { Rotation = d[5], Transparency = seq({ { 0, 0 }, { 1, 1 } }) }, f)
			add(f, "BackgroundTransparency", a)
		end
	end
	local function topLight(a: number, zi: number)
		local f = new("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.5, 0), ZIndex = zi }, box)
		new("UIGradient", { Rotation = 90, Transparency = seq({ { 0, 0 }, { 1, 1 } }) }, f)
		add(f, "BackgroundTransparency", a)
	end
	local function shine(a: number, period: number, zi: number, cyan: boolean?)
		local f = layer("Shine", WHITE, zi)
		local g = new("UIGradient", { Rotation = 20, Transparency = seq({ { 0, 1 }, { 0.42, 1 }, { 0.5, 0 }, { 0.58, 1 }, { 1, 1 } }),
			Color = cyan and cseq({ { 0, "ffffff" }, { 0.48, "ffffff" }, { 0.56, "bff6ff" }, { 1, "bff6ff" } }) or nil }, f)
		add(f, "BackgroundTransparency", a)
		local ph = rnd:NextNumber()
		table.insert(updaters, function(t)
			local u = ((t / period + ph) % 1) / 0.45 -- прохід за 45 % періоду, далі пауза
			g.Offset = Vector2.new(-1.2 + math.min(u, 1) * 2.4, 0)
		end)
	end
	local function sparks(n: number, zi: number, glow: boolean?)
		for _ = 1, n do
			local sz = rnd:NextNumber(0.09, 0.17) * W
			local img = new("ImageLabel", { BackgroundTransparency = 1, Image = M.SPARK, ImageTransparency = 1, ZIndex = zi, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(rnd:NextNumber(0.1, 0.9), rnd:NextNumber(0.1, 0.9)), Size = UDim2.fromOffset(sz, sz),
				ImageColor3 = glow and C("eafcff") or WHITE }, box)
			local per, ph = rnd:NextNumber(1.4, 2.6), rnd:NextNumber()
			add(img, "ImageTransparency", 1, function(t)
				local u = (t / per + ph) % 1
				local a = u < 0.45 and u / 0.45 or (u < 0.7 and 1 - (u - 0.45) / 0.25 or 0)
				img.Size = UDim2.fromOffset(sz * (0.3 + 0.7 * a), sz * (0.3 + 0.7 * a))
				img.Rotation = u * 90
				return a
			end)
		end
	end

	local function build(k: number)
		for _, c in box:GetChildren() do c:Destroy() end
		if auraBox then for _, c in auraBox:GetChildren() do c:Destroy() end end
		table.clear(els); table.clear(updaters)
		if k == 0 then -- Normal
			local b = layer("Base", WHITE, 1)
			new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "3d444d" }, { 1, "262b31" } }) }, b)
			add(b, "BackgroundTransparency", 1)
			topLight(0.16, 2)
			shine(0.28, 3.2, 3)
		elseif METAL[k] then -- Bronze, Silver, Gold, Diamond, Void, Rainbow
			local p, rep, spd = METAL[k], k == 6 and 1.0 or 1.3, k == 6 and 0.22 or 0.16
			local b = layer("Base", WHITE, 1)
			local g = new("UIGradient", { Rotation = k == 6 and 20 or 30 }, b)
			add(b, "BackgroundTransparency", 1)
			local ph = rnd:NextNumber()
			table.insert(updaters, function(t) g.Color = flowSeq(p, t * spd + ph, rep) end)
			vignette(k == 6 and 0.22 or 0.38, 3) -- Rainbow — лише легке затемнення країв (яскрава веселка)
			topLight(0.14, 4)
			shine(0.55, 3.2, 5)
			if SPARKS[k] then sparks(SPARKS[k], 6) end
		elseif k == 7 then -- Secret
			-- (26.10.2026, v23) чорно-графітовий перелив (обсидіан) + яскравий біло-сірий блиск, білі іскри, біло-сіра рамка; без кольору
			local b = layer("Base", WHITE, 1)
			local bg = new("UIGradient", { Rotation = 30 }, b)
			add(b, "BackgroundTransparency", 1)
			local ph = rnd:NextNumber()
			table.insert(updaters, function(t) bg.Color = flowSeq(OBSIDIAN, t * 0.14 + ph, 1.2) end)
			vignette(0.3, 3)
			shine(1, 2.2, 4)
			sparks(SPARKS[7], 5)
			-- світна рамка, що пульсує
			local pulse = function(t) return 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t / 1.6 * math.pi * 2)) end
			local e = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), ZIndex = 6 }, box)
			local st = new("UIStroke", { Color = WHITE, Thickness = math.max(1.5, W * 0.02), Transparency = 1 }, e)
			add(st, "Transparency", 0.95, pulse)
			local iw = math.floor(math.min(W, H) * 0.14)
			for _, d in { { 0, 0, 1, 0, 90 }, { 0, 1, 1, 0, -90 }, { 0, 0, 0, 1, 0 }, { 1, 0, 0, 1, 180 } } do
				local horiz = d[3] == 1
				local f = new("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 6,
					AnchorPoint = Vector2.new(d[1], d[2]), Position = UDim2.fromScale(d[1], d[2]), Size = horiz and UDim2.new(1, 0, 0, iw) or UDim2.new(0, iw, 1, 0) }, box)
				new("UIGradient", { Rotation = d[5], Transparency = seq({ { 0, 0 }, { 1, 1 } }),
					Color = cseq({ { 0, "ffffff" }, { 1, "9aa0a8" } }) }, f)
				add(f, "BackgroundTransparency", 0.45, pulse)
			end
			-- дуже легка біло-сіра аура навколо слота (без кольору)
			if auraBox then
				for i, d in { { "ffffff", 0.12, 0.35 } } do
					local o = math.floor(W * d[2])
					local img = new("ImageLabel", { BackgroundTransparency = 1, Image = M.GLOW9, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(32, 32, 96, 96),
						SliceScale = o / 32, ImageColor3 = C(d[1]), ImageTransparency = 1, Position = UDim2.fromOffset(-o, -o), Size = UDim2.new(1, 2 * o, 1, 2 * o), ZIndex = 3 - i }, auraBox)
					add(img, "ImageTransparency", d[3], pulse)
				end
			end
		end
	end

	function fx.update(t: number)
		for _, u in updaters do u(t) end
		for _, e in els do
			local o = e.op * fx.f
			if e.dyn then o *= e.dyn(t) end
			(e.inst :: any)[e.prop] = 1 - o
		end
	end
	function fx.setMut(m: number?)
		local k = m and math.clamp(math.floor(m), 0, 7) or -1
		if k == fx.mut then return end
		fx.mut = k
		if k < 0 then
			fx.on = false; fx.f = 0
			box.Visible = false; if auraBox then auraBox.Visible = false end
			for _, c in box:GetChildren() do c:Destroy() end
			if auraBox then for _, c in auraBox:GetChildren() do c:Destroy() end end
			table.clear(els); table.clear(updaters)
			return
		end
		build(k)
		fx.update(clock)
	end
	function fx.setOn(on: boolean)
		if fx.mut < 0 then on = false end
		if on == fx.on and (not on or box.Visible) then return end
		fx.on = on
		if on then box.Visible = true; if auraBox then auraBox.Visible = true end end
		wake(fx)
	end
	function fx.destroy()
		active[fx] = nil
		box:Destroy(); if auraBox then auraBox:Destroy() end
	end
	return fx
end

return M
