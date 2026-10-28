-- DraftDriver — ТЕСТ чернетки Workshop (лише Studio): по колу перемикає стани голема-майстра, як це робитиме сервер:
--   Asleep 6 с → Waking → Working (8 переплавок по 2.2 с, потім 5 с без руди) → Dozing → знову Asleep.
-- Атрибут StageOverride на Workshop (тест карти): >= 3 — кристали відкриті, кожна друга переплавка ще й шле кристал (CutSeq / CutType).
-- Де: Workspace/WorkshopDraft/DraftDriver. Прибрати разом із чернеткою, коли Workshop замінить Forge.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Cfg = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local f = script.Parent:WaitForChild("Workshop")
f:SetAttribute("SpdLvl", 1); f:SetAttribute("CapLvl", 1); f:SetAttribute("OphLvl", 1)
local function set(st) f:SetAttribute("State", st); f:SetAttribute("StateTime", workspace:GetServerTimeNow()) end
while true do
	set("Asleep"); task.wait(6)
	set("Waking"); task.wait(Cfg.WAKE_TIME + 0.2)
	set("Working")
	for i = 1, 8 do
		f:SetAttribute("SmeltType", (i % 2) + 2)
		f:SetAttribute("SmeltSeq", (f:GetAttribute("SmeltSeq") or 0) + 1)
		f:SetAttribute("Busy", true)
		if (f:GetAttribute("StageOverride") or 1) >= 3 and i % 2 == 1 then
			f:SetAttribute("CutType", ((i - 1) / 2) % 3 + 1)
			f:SetAttribute("CutSeq", (f:GetAttribute("CutSeq") or 0) + 1)
		end
		task.wait(2.2)
	end
	f:SetAttribute("Busy", false); task.wait(5)
	set("Dozing"); task.wait(4.5)
end
