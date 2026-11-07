--!nonstrict
-- TitleNumLoc (був StandTitleLoc) — переклад табличок з номером у світі:
--   стенди печер (…PriceBoard.PriceGui.Title = «STAND N») і плоти (…Plots.PlotN.Label.PlotLabel.Title = «PLOT N»).
--   Плоти давали «Сюжет 3» з тієї ж причини, що й стенди «Стан 1» (старі точні записи автозбору).
-- 05.11.2026: автопереклад Roblox давав «Стан 1», «Стан 2» (старі записи «STAND 1» / «STAND 2» з автозбору мали власний переклад),
--   а решта — «СТЕНД N». Тепер напис ставимо самі: AutoLocalize = false і Shared/Loc за наявним рядком таблиці «STAND {number1}».
local RS = game:GetService("ReplicatedStorage")
local Loc = require(RS:WaitForChild("Shared"):WaitForChild("Loc"))

local tracked = {} -- TextLabel → true

local function apply(lbl: TextLabel)
	local src = lbl:GetAttribute("LocSrc")
	if type(src) ~= "string" or (lbl.Text ~= src and lbl.Text ~= lbl:GetAttribute("LocOut")) then
		src = lbl.Text -- новий текст від гри
		lbl:SetAttribute("LocSrc", src)
	end
	local word, n = string.match(src, "^(%u+)%s+(%d+)$")
	if not (n and (word == "STAND" or word == "PLOT")) then return end
	local out = Loc.f(word .. " {number1}", n)
	lbl:SetAttribute("LocOut", out)
	if lbl.Text ~= out then lbl.Text = out end
end

local function hook(d: Instance)
	if not d:IsA("TextLabel") or d.Name ~= "Title" or tracked[d] then return end
	local gui = d.Parent
	if not (gui and (gui.Name == "PriceGui" or gui.Name == "PlotLabel")) then return end
	tracked[d] = true
	d.AutoLocalize = false
	apply(d)
	d:GetPropertyChangedSignal("Text"):Connect(function() apply(d) end)
	d.Destroying:Connect(function() tracked[d] = nil end)
end

-- печери й ніші з плотами створюються й підвантажуються — слухаємо весь workspace (фільтр дешевий: ім'я Title + батько)
for _, d in workspace:GetDescendants() do hook(d) end
workspace.DescendantAdded:Connect(hook)
-- перекладач вантажиться асинхронно: коли готовий — переписати всі таблички
Loc.Ready:Connect(function()
	for lbl in tracked do apply(lbl) end
end)
