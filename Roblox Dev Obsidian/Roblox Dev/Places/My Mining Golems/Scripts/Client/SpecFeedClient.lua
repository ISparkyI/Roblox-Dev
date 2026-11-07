-- SpecFeedClient — що бачить адмін у SPECTATE (07.11.2026). Де: StarterPlayer/StarterPlayerScripts/SpecFeedClient (LocalScript).
-- Працює ЛИШЕ поки сервер (AdminService.SpecStart) поставив гравцеві атрибут Spectated = true; інакше нічого не шле.
-- Шле в Remotes/SpecFeed: 8 разів на секунду — камеру (позиція + напрям), курсор (частка екрана), відкриті вікна (WindowManager.openList);
--   при кожному кліку / тапі — що натиснуто (текст кнопки й вікно) і де. Сервер пересилає це лише адмінам, що стежать.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local WM = require(RS:WaitForChild("Shared"):WaitForChild("WindowManager"))
local ev = RS:WaitForChild("Remotes"):WaitForChild("SpecFeed", 120)
if not ev then return end

local function on() return player:GetAttribute("Spectated") == true end
local function vsize(): Vector2
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

-- опис натиснутого: текст кнопки (або першого напису в ній) + назва вікна (ScreenGui)
local function describe(objs: { GuiObject }): string?
	for _, o in objs do
		local b: Instance? = o
		while b and not b:IsA("GuiButton") do
			b = b.Parent
			if b and b:IsA("LayerCollector") then b = nil end
		end
		if b then
			local text = (b:IsA("TextButton") and b.Text ~= "") and b.Text or nil
			if not text then
				local holder = b.Parent or b
				for _, d in holder:GetDescendants() do
					if d:IsA("TextLabel") and d.Visible and d.Text ~= "" and #d.Text < 40 then text = d.Text; break end
				end
			end
			local sg = b:FindFirstAncestorWhichIsA("LayerCollector")
			local where = sg and sg.Name or ""
			return (text or b.Name) .. (where ~= "" and ("  [" .. where .. "]") or "")
		end
	end
	return nil
end

UIS.InputBegan:Connect(function(input, gp)
	if not on() then return end
	local t = input.UserInputType
	if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
	local inset = GuiService:GetGuiInset()
	local loc = (t == Enum.UserInputType.Touch) and Vector2.new(input.Position.X, input.Position.Y + inset.Y) or UIS:GetMouseLocation()
	local objs = pg:GetGuiObjectsAtPosition(loc.X - inset.X, loc.Y - inset.Y)
	local text = describe(objs) or (gp and "UI" or "world")
	local vs = vsize()
	ev:FireServer({ click = { text = string.sub(text, 1, 48), x = loc.X / vs.X, y = loc.Y / vs.Y } })
end)

task.spawn(function()
	while true do
		task.wait(0.125)
		if on() then
			local cam = workspace.CurrentCamera
			if cam then
				local cf = cam.CFrame
				local p, l = cf.Position, cf.LookVector
				local m = UIS:GetMouseLocation()
				local vs = vsize()
				local ok, wins = pcall(WM.openList)
				ev:FireServer({ cam = { p.X, p.Y, p.Z, l.X, l.Y, l.Z }, m = { m.X / vs.X, m.Y / vs.Y }, win = ok and wins or {} })
			end
		end
	end
end)
