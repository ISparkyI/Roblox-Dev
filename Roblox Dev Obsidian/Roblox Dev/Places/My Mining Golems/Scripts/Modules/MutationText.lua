--!strict
-- MutationText — анімовані назви мутацій: градієнт за GolemCatalog.MUTATIONS[].gradient, що повільно переливається вздовж тексту
-- (Rainbow — веселка, Secret — металевий з білим і бліком, що біжить). Лише клієнт (UIGradient на TextLabel / TextButton).
-- Де: ReplicatedStorage/Shared/MutationText (ModuleScript).
--
-- MutationText.apply(label, mut) — mut 0..7 (або ключ мутації). Normal — без градієнта (суцільний колір мутації).
--   Мітка отримує TextColor3 = білий і UIGradient "MutationGradient"; повторний apply міняє мутацію на тій самій мітці.
-- MutationText.clear(label) — прибрати градієнт.
-- Анімація — ОДИН спільний Heartbeat на всі мітки (≈30 оновлень/с), лише поки є живі мітки; мітка, що вийшла з DataModel
-- (знищена), або прихована — пропускається / сама відписується (без витоків).
-- Серверні таблички (BillboardGui над големом у руці й на стенді печери): сервер ставить мітці атрибут MutationText = mut і базовий
-- колір; клієнтський скрипт StarterPlayerScripts/MutationTextClient знаходить такі мітки й викликає apply.

local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))

local MutationText = {}

local N = 19          -- відрізків ColorSequence (20 точок — максимум Roblox), рівномірно по ширині мітки
local REPEAT = 1.1    -- скільки періодів візерунка видно на мітці
local STEP = 1 / 30   -- оновлення не частіше
local WHITE = Color3.new(1, 1, 1)

type Entry = { label: GuiObject, grad: UIGradient, pal: { Color3 }, speed: number, shine: boolean, phase: number }
local active: { [GuiObject]: Entry } = {}
local conn: RBXScriptConnection? = nil
local clock, acc = 0, 0

local function mutDef(mut: any): any
	if type(mut) == "string" then
		for _, u in Catalog.MUTATIONS do if u.key == mut then return u end end
		return Catalog.MUTATIONS[1]
	end
	return Catalog.mutation(mut)
end

-- колір циклічного візерунка в точці u (період 1), плавно між сусідніми кольорами
local function sample(pal: { Color3 }, u: number): Color3
	local n = #pal
	local x = (u % 1) * n
	local i = math.floor(x)
	local t = x - i
	t = t * t * (3 - 2 * t)
	return pal[i + 1]:Lerp(pal[(i + 1) % n + 1], t)
end

local function build(e: Entry)
	local ph = clock * e.speed + e.phase
	local ks = table.create(N + 1)
	-- блиск (Secret): біла смуга, що пробігає зліва направо раз на ~2,4 с, з паузою
	local sx = e.shine and ((clock % 2.4) - 0.3) or -9
	for k = 0, N do
		local x = k / N
		local c = sample(e.pal, x * REPEAT - ph)
		if e.shine then
			local d = (x - sx) / 0.12
			local a = math.exp(-d * d)
			if a > 0.01 then c = c:Lerp(WHITE, a * 0.9) end
		end
		ks[k + 1] = ColorSequenceKeypoint.new(x, c)
	end
	e.grad.Color = ColorSequence.new(ks)
end

local function step(dt: number)
	clock += dt
	acc += dt
	if acc < STEP then return end
	acc = 0
	for label, e in active do
		if not label:IsDescendantOf(game) or e.grad.Parent ~= label then
			active[label] = nil -- знищена мітка або градієнт прибрали — відписка
		elseif label.Visible then
			build(e)
		end
	end
	if next(active) == nil and conn then conn:Disconnect(); conn = nil end
end

-- обводка мітки: мутація з полем stroke (Secret — світлий текст з графітово-чорною обводкою, v24) має свою обводку;
-- власний колір обводки зберігається в атрибуті MutStroke0 і повертається для інших мутацій. Мітка без UIStroke отримує
-- тимчасову обводку "MutationStroke" (1,5 px), щоб світлий текст Secret читався і на світлому фоні; clear її прибирає.
local function setStroke(label: GuiObject, col: Color3?)
	local own = label:FindFirstChild("MutationStroke")
	if col and not label:FindFirstChildOfClass("UIStroke") then
		local s = Instance.new("UIStroke")
		s.Name = "MutationStroke"
		s.Thickness = 1.5
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		s.Color = col
		s.Parent = label
		return
	elseif not col and own then
		own:Destroy()
	end
	for _, st in label:GetChildren() do
		if st:IsA("UIStroke") then
			local orig = st:GetAttribute("MutStroke0")
			if col then
				if orig == nil then st:SetAttribute("MutStroke0", st.Color) end
				st.Color = col
			elseif typeof(orig) == "Color3" then
				st.Color = orig
			end
		end
	end
end

function MutationText.clear(label: GuiObject)
	active[label] = nil
	setStroke(label, nil)
	local g = label:FindFirstChild("MutationGradient")
	if g then g:Destroy() end
end

function MutationText.apply(label: GuiObject, mut: any)
	local u = mutDef(mut)
	if not u or not u.gradient then
		MutationText.clear(label)
		pcall(function() (label :: any).TextColor3 = u and u.color or WHITE end)
		return
	end
	setStroke(label, u.stroke and Color3.fromHex(u.stroke) or nil)
	local pal = {}
	for _, h in u.gradient do table.insert(pal, Color3.fromHex(h)) end
	-- градієнт множиться на колір тексту (і обводки); textColor — темний текст зі світлою обводкою (Secret)
	pcall(function() (label :: any).TextColor3 = u.textColor and Color3.fromHex(u.textColor) or WHITE end)
	local g = label:FindFirstChild("MutationGradient") :: UIGradient?
	if not g then
		g = Instance.new("UIGradient")
		g.Name = "MutationGradient"
		g.Parent = label
	end
	local e: Entry = { label = label, grad = g :: UIGradient, pal = pal, speed = u.speed or 0.3, shine = u.shine == true, phase = math.random() }
	active[label] = e
	build(e)
	if not conn then conn = RunService.Heartbeat:Connect(step) end
end

return MutationText
