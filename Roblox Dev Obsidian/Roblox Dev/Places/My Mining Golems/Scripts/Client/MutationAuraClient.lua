--!strict
-- MutationAuraClient — вмикає 3D-ефекти мутацій (Shared/MutationAura) на моделях големів у Workspace (лише на клієнті).
-- Де: StarterPlayer/StarterPlayerScripts/MutationAuraClient (LocalScript). Модель голема = Model з дочірнім Root і атрибутом Mut:
--   плот (PlotService: Miner_* / Carrier_*), фігурка в руці (HeldItemService: Figurine), стенд печери (CaveStandService:
--   StandGolem), підставка ролу (RollRevealClient: фейки й результат; AuraScale = масштаб підставки).
-- Mut = 0 (Normal) — без ефекту. Слоти інвентаря (ViewportFrame) не у Workspace — без ефектів.
local MutationAura = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MutationAura"))

local watched: { [Model]: boolean } = {}

local function refresh(m: Model)
	if not m:IsDescendantOf(workspace) then MutationAura.clear(m); return end
	local mut = tonumber(m:GetAttribute("Mut")) or 0
	if mut > 0 and m:FindFirstChild("Root") then
		MutationAura.apply(m, math.floor(mut))
	else
		MutationAura.clear(m)
	end
end

local function consider(inst: Instance)
	if not inst:IsA("Model") or watched[inst] then return end
	if inst:GetAttribute("Mut") == nil then return end
	watched[inst] = true
	-- деталі моделі (Root) можуть прийти пізніше за саму модель (реплікація) — пробуємо, доки не з'явиться Root
	task.defer(function()
		local t0 = os.clock()
		while inst.Parent and not inst:FindFirstChild("Root") and os.clock() - t0 < 5 do task.wait(0.1) end
		task.wait() -- рамка моделі після першого кадру (аніматор поставив деталі)
		refresh(inst)
	end)
	inst:GetAttributeChangedSignal("Mut"):Connect(function() refresh(inst) end)
	inst.AncestryChanged:Connect(function()
		if not inst:IsDescendantOf(workspace) then
			MutationAura.clear(inst)
			watched[inst] = nil
		end
	end)
end

for _, d in workspace:GetDescendants() do consider(d) end
workspace.DescendantAdded:Connect(consider)
