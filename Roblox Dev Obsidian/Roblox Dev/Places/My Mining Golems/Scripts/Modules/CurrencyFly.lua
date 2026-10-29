-- CurrencyFly — іконки валюти летять до лічильника в HUD (MainHUD/Counter_<attr>/Icon): покупка тікетів / діамантів, нагороди квестів.
-- Де: ReplicatedStorage/Shared/CurrencyFly (ModuleScript, лише клієнт). 28.10.2026.
-- CurrencyFly.fly("Tickets" | "Diamonds", from: GuiObject | Vector2 | nil, amount)
--   from — елемент, з центру якого вилітають іконки (або точка екрана; nil — центр екрана).
-- Картинка — та сама, що в лічильнику. Ціль перераховується щокадру, на прильоті іконка лічильника «попає».
-- Координати — відносно AbsolutePosition шару польоту (як у IndexUI.flyDiamonds), тому відступ топбара не зсуває політ.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local M = {}
local gui, layer

local function ensure()
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	if gui and gui.Parent == pg then return true end
	gui = Instance.new("ScreenGui")
	gui.Name = "CurrencyFly"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layer = Instance.new("Frame")
	layer.Name = "Layer"; layer.BackgroundTransparency = 1; layer.Size = UDim2.fromOffset(0, 0)
	layer.Parent = gui
	gui.Parent = pg
	return true
end

local function pop(sc: UIScale?)
	if not sc then return end
	local up = TweenService:Create(sc, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.2 })
	up.Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed then
			TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end)
	up:Play()
end

function M.fly(attr: string, from: any, amount: number?)
	if not ensure() then return end
	local hud = Players.LocalPlayer.PlayerGui:FindFirstChild("MainHUD")
	local plate = hud and hud:FindFirstChild("Counter_" .. attr, true)
	local target = plate and plate:FindFirstChild("Icon")
	if not (target and target:IsA("ImageLabel")) then return end
	local tScale = target:FindFirstChildOfClass("UIScale")
	local function targetRect(): (Vector2, Vector2)
		local k = tScale and tScale.Scale or 1
		return target.AbsolutePosition + target.AbsoluteSize / 2 - layer.AbsolutePosition, target.AbsoluteSize / math.max(0.01, k)
	end
	local a
	if typeof(from) == "Instance" and from:IsA("GuiObject") then
		a = from.AbsolutePosition + from.AbsoluteSize / 2 - layer.AbsolutePosition
	elseif typeof(from) == "Vector2" then
		a = from
	else
		a = gui.AbsoluteSize / 2
	end
	local px = math.max(22, math.floor(34 * gui.AbsoluteSize.Y / 720 + 0.5))
	local _, ts = targetRect()
	local asp = ts.Y > 0 and ts.X / ts.Y or 1
	local s0 = Vector2.new(px * asp, px)
	local n = math.clamp(math.floor(math.log10((amount or 10) + 1) * 2) + 2, 4, 10)
	for i = 1, n do
		task.delay((i - 1) * 0.06, function()
			local p0 = a + Vector2.new(math.random(-28, 28), math.random(-16, 16))
			local b0 = targetRect()
			local bend = Vector2.new(math.random(-90, 90), -math.random(80, 160))
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1; img.Image = target.Image; img.ScaleType = Enum.ScaleType.Fit
			img.AnchorPoint = Vector2.new(0.5, 0.5); img.ZIndex = 50
			img.Position = UDim2.fromOffset(p0.X, p0.Y); img.Size = UDim2.fromOffset(s0.X, s0.Y)
			img.Rotation = math.random(-15, 15)
			img.Parent = layer
			local nv = Instance.new("NumberValue")
			nv.Parent = img
			nv.Changed:Connect(function(t)
				local b, bs = targetRect()
				local mid = (p0 + b0) / 2 + bend
				local q = (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * mid + t * t * b
				local sz = s0:Lerp(bs, t)
				img.Position = UDim2.fromOffset(q.X, q.Y)
				img.Size = UDim2.fromOffset(sz.X, sz.Y)
			end)
			local tw = TweenService:Create(nv, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 1 })
			tw.Completed:Connect(function() pop(tScale); img:Destroy() end)
			tw:Play()
		end)
	end
end

return M
