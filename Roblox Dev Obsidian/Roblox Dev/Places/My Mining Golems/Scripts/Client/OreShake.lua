--!strict
-- IronOre: здригання при ударі + частинки HitChips (клієнтський). Реагує на атрибут HitTime, який ставить аніматор голема.
-- Налаштування атрибутами моделі: ShakeTime (с), ShakeAmount (стади), ShakeAngle (рад).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitChips = require(ReplicatedStorage:WaitForChild("Effects"):WaitForChild("HitChips"))
local model = script.Parent :: Model

local basePivot: CFrame? = nil
local hitAt = -math.huge
local seed = 0

model:GetAttributeChangedSignal("HitTime"):Connect(function()
	if not basePivot then basePivot = model:GetPivot() end
	hitAt = os.clock()
	seed += 1
	-- частинки: маленькі блоки кольору руди вилітають з точки удару
	local p = model:GetAttribute("HitPoint")
	if typeof(p) == "Vector3" then
		HitChips.spawn(model, p)
	end
end)

RunService.PreRender:Connect(function()
	local base = basePivot
	if not base then return end
	local dur = (model:GetAttribute("ShakeTime") :: number?) or 0.35
	local amount = (model:GetAttribute("ShakeAmount") :: number?) or 0.08
	local angle = (model:GetAttribute("ShakeAngle") :: number?) or 0.035
	local e = os.clock() - hitAt
	if e >= dur then
		model:PivotTo(base)
		basePivot = nil
		return
	end
	local k = 1 - e / dur
	local decay = k * k
	local w = e * 55 + seed * 1.7
	-- короткий «удар» униз і швидке затухаюче тремтіння
	local squash = -amount * 0.6 * math.max(0, 1 - e / 0.08)
	local off = Vector3.new(math.sin(w) * amount, squash, math.cos(w * 1.3) * amount * 0.6) * decay
	local r = CFrame.Angles(math.sin(w * 0.9) * angle * decay, 0, math.cos(w * 1.1) * angle * decay)
	model:PivotTo(base * CFrame.new(off) * r)
end)
