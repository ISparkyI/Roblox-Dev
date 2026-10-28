--!strict
-- GolemModel — «живий» голем у світі з моделі каталогу: стенди печери (CaveStandService, сервер) і підставки ролу
-- (RollRevealClient, клієнт). Де: ReplicatedStorage/Shared/GolemModel (спільний для сервера й клієнта).
--
-- GolemModel.build(kind, cls) -> Model?  — клон PlotAssets/<GolemCatalog.model> (nil, якщо в голема немає своєї моделі):
--   атрибути Kind / Role / State = "Idle" / AnimSpeed = 1 / Carry (носій); предмет у руці за класом (Catalog.applyClassItems —
--   клон предмета-префаба в кулак); носій — ящичок голема (Catalog.box) з прихованою рудою Load;
--   усе Anchored, без колізій; масштаб × GolemCatalog.size; клієнтський аніматор (GolemAnimator, RunContext Client) увімкнено.
-- GolemModel.footOffset(m) -> number — на скільки півот вище за низ рамки моделі (поставити стопи на поверхню).
-- GolemModel.headTop(m) -> number — верх рамки моделі над Root (для таблички).
-- Винесено з CaveStandService.golemModel (27.10.2026, ролли v1).

local RS = game:GetService("ReplicatedStorage")
local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))

local M = {}

function M.has(kind: any): boolean
	local def = Catalog.get(kind)
	local assets = RS:FindFirstChild("PlotAssets")
	return def ~= nil and def.model ~= nil and assets ~= nil and assets:FindFirstChild(def.model) ~= nil
end

function M.build(kind: any, cls: any): Model?
	local def = Catalog.get(kind)
	local assets = RS:FindFirstChild("PlotAssets")
	local src = def and def.model and assets and assets:FindFirstChild(def.model)
	if not src or not src:IsA("Model") then return nil end
	local c = Catalog.cls(cls)
	local m = src:Clone()
	m:SetAttribute("Kind", def.id); m:SetAttribute("Role", c)
	m:SetAttribute("State", "Idle"); m:SetAttribute("AnimSpeed", 1); m:SetAttribute("Carry", c == "carrier")
	Catalog.applyClassItems(m, c) -- майнер — кірка, воїн — меч (клон префаба PlotAssets/<pickaxe|sword> у кулак)
	if c == "carrier" and assets then
		local box = assets:FindFirstChild(def.box or Catalog.box(def.id)) or assets:FindFirstChild("CarryBox")
		if box and box:IsA("Model") then
			local b = box:Clone()
			b.Name = "CarryBox" -- між кулаками її ставить аніматор (Carry)
			local load = b:FindFirstChild("Load")
			if load then for _, d in load:GetDescendants() do if d:IsA("BasePart") then d.Transparency = 1 end end end
			b.Parent = m
		end
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanTouch = false end
	end
	local size = (def.size :: number?) or 1
	if math.abs(size - 1) > 1e-3 then m:ScaleTo(m:GetScale() * size) end
	local anim = m:FindFirstChild("GolemAnimator")
	if anim and anim:IsA("Script") then anim.Enabled = true end -- клієнтський аніматор: Idle
	return m
end

function M.footOffset(m: Model): number
	local cf, size = m:GetBoundingBox()
	return m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
end

function M.headTop(m: Model): number
	local root = m:FindFirstChild("Root") or m.PrimaryPart
	local cf, size = m:GetBoundingBox()
	local y = root and (root :: BasePart).Position.Y or m:GetPivot().Position.Y
	return cf.Position.Y + size.Y / 2 - y
end

return M
