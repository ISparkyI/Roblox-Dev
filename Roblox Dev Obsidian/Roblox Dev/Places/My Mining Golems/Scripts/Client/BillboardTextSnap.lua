--!nonstrict
-- BillboardTextSnap — обводка тексту на білбордах (вивіски SELL / CAVE / WORKSHOP, PLOT N, лічильники над ящиками…). Лише клієнт.
-- Де: StarterPlayer/StarterPlayerScripts/BillboardTextSnap (LocalScript).
-- v2 (04.11.2026, за рішенням користувача): текст на білбордах НЕ чіпаємо — TextScaled, як задумано в префабах, тож напис завжди
--   займає ту саму частку вивіски на будь-якій відстані (v1 округлював розмір шрифту до кроків — напис «стрибав» і обрізався
--   («WORKSHO»), тепер це прибрано, TextScaled повернено).
-- Лишилось одне: обводка (UIStroke) задається в пікселях і сама не масштабується — далеко текст малий, а обводка та сама,
--   і виглядає товстою. Тому товщину обводки ставимо пропорційно висоті тексту: Thickness = базова × висота / STROKE_REF.
--   Оновлення раз на STEP с, лише для ввімкнених білбордів на екрані.
local Players = game:GetService("Players")

local STEP = 0.12
local STROKE_REF = 60 -- базова товщина обводки з префаба відповідає тексту висотою 60 px

type T = { bb: BillboardGui, strokes: { { s: UIStroke, base: number } }, last: number }
local tracked: { [Instance]: T } = {}

local function track(t: Instance)
	if tracked[t] or not (t:IsA("TextLabel") or t:IsA("TextButton")) then return end
	local bb = t:FindFirstAncestorWhichIsA("BillboardGui")
	if not bb then return end
	-- 04.11.2026: кнопки-білборди з власним UIScale (COLLECT / EMPTY над ящиком, підказки CustomPrompts) — обводку вже масштабує
	--   UIScale; друге зменшення робило її ~0,6 px, і білий напис на сірій кнопці EMPTY ставав невидимим. Такі не чіпаємо.
	local x = t.Parent
	while x and x ~= bb do
		if x:FindFirstChildOfClass("UIScale") then return end
		x = x.Parent
	end
	if t:GetAttribute("SnapWasScaled") then (t :: TextLabel).TextScaled = true; t:SetAttribute("SnapWasScaled", nil) end
	local strokes = {}
	for _, k in t:GetChildren() do
		if k:IsA("UIStroke") and k.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual then table.insert(strokes, { s = k, base = k.Thickness }) end
	end
	if #strokes == 0 then return end
	tracked[t] = { bb = bb, strokes = strokes, last = -1 }
end

local function update()
	for t, e in tracked do
		local lab = t :: TextLabel
		if not lab.Parent or not lab:IsDescendantOf(game) then tracked[t] = nil; continue end
		if not e.bb.Enabled or not lab.Visible or lab.Text == "" then continue end
		local h = lab.TextBounds.Y
		if h <= 0 then continue end
		local lines = math.max(1, #string.split(lab.ContentText, "\n"))
		h /= lines
		if math.abs(h - e.last) < 1 then continue end
		e.last = h
		for _, st in e.strokes do
			if st.s.Parent then st.s.Thickness = math.clamp(st.base * h / STROKE_REF, 0.5, st.base * 2) end
		end
	end
end

local function scan(root: Instance)
	for _, d in root:GetDescendants() do track(d) end
	root.DescendantAdded:Connect(function(d)
		if d:IsA("TextLabel") or d:IsA("TextButton") then task.defer(track, d) end
	end)
end
scan(workspace)
scan(Players.LocalPlayer:WaitForChild("PlayerGui"))

task.spawn(function()
	while true do
		local ok, err = pcall(update)
		if not ok then warn("BillboardTextSnap: " .. tostring(err)) end
		task.wait(STEP)
	end
end)
