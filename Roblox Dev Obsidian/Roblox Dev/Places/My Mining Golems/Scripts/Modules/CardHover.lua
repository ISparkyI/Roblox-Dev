--!strict
-- CardHover — наведення на картки покращень: картка трохи збільшується і нахиляється в той бік, де мишка.
-- Де: ReplicatedStorage/Shared/CardHover (ModuleScript). Клієнтський модуль.
--
-- Використання (картка будується всередині «тримача»):
--   local holder, inner = CardHover.holder(parent, x, y, w, h, extraBottom)  -- CanvasGroup з центром у середині картки
--   ... малюємо тінь і картку в holder зі зсувом inner (Vector2) ...
--   CardHover.attach(holder, hitFrame, enabled?, base?)                      -- hitFrame — сама картка; base — базовий масштаб (1)
--
-- Чому CanvasGroup: Roblox вимикає ClipsDescendants у повернутих елементах, а в кнопках стилю A візерунок
-- обрізається гранню. CanvasGroup малює вміст без повороту у свою текстуру, обрізання працює, повертається вже картинка.
-- Тримач має запас PAD з усіх боків, щоб обводка й тінь картки не обрізались краєм CanvasGroup.
--
-- Параметри: масштаб 1.05, нахил до 3° (мишка біля правого краю → нахил праворуч, біля лівого → ліворуч),
-- згладжування експонентою (~0.12 с), повернення в спокій після відведення мишки.

local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local UIHover = require(script.Parent:WaitForChild("UIHover"))

-- звук наведення: спільний з усіма кнопками (Shared/UIHover → SoundService/ButtonHover). Грає один раз при вході мишки на картку.
local function playHover()
	UIHover.play()
end

-- де мишка на полотні SurfaceGui (пікселі полотна по X): промінь з камери → площина грані деталі.
-- Правий напрям полотна для граней: Front → −X, Back → +X, Left → +Z, Right → −Z (для Top/Bottom — не рахуємо).
local FACE = {
	[Enum.NormalId.Front] = { n = Vector3.new(0, 0, -1), r = Vector3.new(-1, 0, 0) },
	[Enum.NormalId.Back] = { n = Vector3.new(0, 0, 1), r = Vector3.new(1, 0, 0) },
	[Enum.NormalId.Left] = { n = Vector3.new(-1, 0, 0), r = Vector3.new(0, 0, 1) },
	[Enum.NormalId.Right] = { n = Vector3.new(1, 0, 0), r = Vector3.new(0, 0, -1) },
}
-- at — точка в координатах вьюпорта (як GetMouseLocation); без неї — мишка
local function surfaceX(gui: SurfaceGui, at: Vector2?): number?
	local part = gui.Adornee or gui.Parent
	local f = FACE[gui.Face]
	local cam = workspace.CurrentCamera
	if not (part and part:IsA("BasePart") and f and cam) then return nil end
	local m = at or UIS:GetMouseLocation()
	local ray = cam:ViewportPointToRay(m.X, m.Y)
	local cf, size = part.CFrame, part.Size
	local n = cf:VectorToWorldSpace(f.n)
	local p0 = cf:PointToWorldSpace(f.n * size / 2)
	local den = ray.Direction:Dot(n)
	if math.abs(den) < 1e-6 then return nil end
	local t = (p0 - ray.Origin):Dot(n) / den
	local hit = cf:PointToObjectSpace(ray.Origin + ray.Direction * t)
	local ext = math.abs(f.r:Dot(size))
	return (hit:Dot(f.r) + ext / 2) / ext * gui.AbsoluteSize.X
end

local CardHover = {}

CardHover.surfaceX = surfaceX -- також для перетягування повзунка й карток на таблі кузні (ForgeClient)
CardHover.PAD = 16
CardHover.SCALE = 1.05
CardHover.TILT = 3 -- градусів
local SPEED = 14

type State = { holder: GuiObject, scale: UIScale, hover: boolean, rel: number, s: number, r: number, base: number, noTilt: boolean }
local active: { [State]: boolean } = {}
local loop: RBXScriptConnection? = nil

local function step(dt: number)
	local a = 1 - math.exp(-SPEED * dt)
	for st in active do
		if not st.holder.Parent then active[st] = nil; continue end
		local ts = (st.hover and CardHover.SCALE or 1) * st.base
		local tr = (st.hover and not st.noTilt) and st.rel * CardHover.TILT or 0
		st.s += (ts - st.s) * a
		st.r += (tr - st.r) * a
		if not st.hover and math.abs(st.s - st.base) < 0.0005 and math.abs(st.r) < 0.02 then
			st.s, st.r = st.base, 0
			active[st] = nil
		end
		st.scale.Scale = st.s
		st.holder.Rotation = st.r
	end
	if next(active) == nil and loop then loop:Disconnect(); loop = nil end
end

local function wake(st: State)
	active[st] = true
	if not loop then loop = RunService.RenderStepped:Connect(step) end
end

-- тримач картки з AnchorPoint у центрі; повертає його і зсув, з якого малювати картку.
-- У ScreenGui — CanvasGroup (масштаб + нахил). У SurfaceGui (табла в світі) — звичайний Frame і БЕЗ нахилу:
-- у CanvasGroup є ліміт відеопам'яті, і на слабких пристроях / низькій графіці великі картки табел взагалі не малювались
-- (порожнє табло зі studs), поки пам'ять не звільнялась (~10 с).
function CardHover.holder(parent: Instance, x: number, y: number, w: number, h: number, extraBottom: number?): (GuiObject, Vector2)
	local P, eb = CardHover.PAD, extraBottom or 0
	local inWorld = parent:FindFirstAncestorWhichIsA("SurfaceGui") ~= nil or parent:IsA("SurfaceGui")
	local g = Instance.new(inWorld and "Frame" or "CanvasGroup")
	if inWorld then g:SetAttribute("NoTilt", true) end
	g.Name = "CardHolder"
	g.BackgroundTransparency = 1
	g.BorderSizePixel = 0
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Size = UDim2.fromOffset(w + 2 * P, h + eb + 2 * P)
	g.Position = UDim2.fromOffset(x + w / 2, y + (h + eb) / 2)
	g.Parent = parent
	return g, Vector2.new(P, P)
end

-- увімкнути наведення: holder — що масштабувати й повертати, hit — де ловити мишку (за замовчуванням holder),
-- enabled — необов'язкова перевірка (напр. картки під затемненням не реагують),
-- base — базовий масштаб картки в спокої (наведення множить його на SCALE)
function CardHover.attach(holder: GuiObject, hit: GuiObject?, enabled: (() -> boolean)?, base: number?): { RBXScriptConnection }
	local target = hit or holder
	local scale = holder:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = holder
	local b = base or 1
	target:SetAttribute("HoverSoundBy", "CardHover") -- автозвук кнопок (UIHoverAuto) пропускає картку, щоб не грало двічі
	;(scale :: UIScale).Scale = b
	-- без нахилу для звичайного Frame: Roblox вимикає обрізання в повернутих елементах (візерунок кнопок стилю A виліз би)
	local st: State = { holder = holder, scale = scale :: UIScale, hover = false, rel = 0, s = b, r = 0, base = b,
		noTilt = holder:GetAttribute("NoTilt") == true or not holder:IsA("CanvasGroup") }
	local sg = holder:FindFirstAncestorWhichIsA("SurfaceGui")
	local function aim(x: number)
		-- у SurfaceGui координату мишки на полотні рахуємо самі (променем), у ScreenGui — x з події
		if sg then x = surfaceX(sg) or x end
		-- центр тримача не зсувається від масштабу; без повороту — AbsolutePosition/AbsoluteSize тримача
		local c = holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2
		local half = math.max(1, holder.AbsoluteSize.X / 2)
		st.rel = math.clamp((x - c) / half, -1, 1)
	end
	local conns = {
		target.MouseEnter:Connect(function(x, _)
			if UIS:GetLastInputType() == Enum.UserInputType.Touch then return end -- 11.11.2026: на телефоні дотик не «наводить» (картка смикалась на старті свайпу)
			local on = enabled == nil or enabled()
			if on and not st.hover then playHover() end
			st.hover = on; aim(x); wake(st)
		end),
		target.MouseMoved:Connect(function(x, _)
			if UIS:GetLastInputType() == Enum.UserInputType.Touch then return end -- 11.11.2026: на телефоні дотик не «наводить» (картка смикалась на старті свайпу)
			local on = enabled == nil or enabled()
			if on and not st.hover then playHover() end
			st.hover = on; aim(x); wake(st)
		end),
		target.MouseLeave:Connect(function() st.hover = false; wake(st) end),
	}
	holder.Destroying:Connect(function()
		active[st] = nil
		for _, c in conns do c:Disconnect() end
	end)
	return conns
end

return CardHover
