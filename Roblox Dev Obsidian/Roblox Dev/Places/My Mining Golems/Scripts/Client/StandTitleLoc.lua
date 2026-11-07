--!nonstrict
-- StandTitleLoc — переклад табличок стендів у печерах (Workspace.Caves.*.Stands.Golem_Stand_N.PriceBoard.PriceGui.Title = «STAND N»).
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
	local n = string.match(src, "^STAND%s+(%d+)$")
	if not n then return end
	local out = Loc.f("STAND {number1}", n)
	lbl:SetAttribute("LocOut", out)
	if lbl.Text ~= out then lbl.Text = out end
end

local function hook(d: Instance)
	if not d:IsA("TextLabel") or d.Name ~= "Title" or tracked[d] then return end
	local gui = d.Parent
	if not (gui and gui.Name == "PriceGui" and gui.Parent and gui.Parent.Name == "PriceBoard") then return end
	tracked[d] = true
	d.AutoLocalize = false
	apply(d)
	d:GetPropertyChangedSignal("Text"):Connect(function() apply(d) end)
	d.Destroying:Connect(function() tracked[d] = nil end)
end

local caves = workspace:WaitForChild("Caves", 60)
if caves then
	for _, d in caves:GetDescendants() do hook(d) end
	caves.DescendantAdded:Connect(hook)
end
-- перекладач вантажиться асинхронно: коли готовий — переписати всі таблички
Loc.Ready:Connect(function()
	for lbl in tracked do apply(lbl) end
end)
