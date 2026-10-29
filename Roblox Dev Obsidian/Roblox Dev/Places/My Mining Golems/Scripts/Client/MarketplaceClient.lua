-- MarketplaceClient — коло Marketplace у центрі зали (Workspace/Cave/Hub/Marketplace): відлік і телепорт, перелив таблички.
-- Де: StarterPlayer/StarterPlayerScripts/MarketplaceClient (LocalScript). Сервер — ServerScriptService/MarketplaceTeleport.
-- Став у коло — відлік у стилі адмін-оголошення на рівні тостів (UIEvents/Countdown): напис «TELEPORTING TO MARKETPLACE IN»
-- і велика цифра під ним 3 → 2 → 1 → «...»,
-- потім Remotes/MarketplaceTP. Вийшов з кола — відлік скасовується (банер ховається). Після спроби — треба вийти з кола,
-- щоб відлік почався знову. Місця ще немає (HubConfig.MARKETPLACE_PLACE_ID = 0) — тост «Marketplace is coming soon!».
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("HubConfig"))
local player = Players.LocalPlayer

local TAG = "mkt"
local function ui(name: string): BindableEvent?
	local f = RS:FindFirstChild("UIEvents")
	local b = f and f:FindFirstChild(name)
	return (b and b:IsA("BindableEvent")) and b or nil
end
local TITLE = "TELEPORTING TO MARKETPLACE IN"
-- один рядок: text = "" — напис TITLE, інакше велика цифра (замінює напис)
local function banner(text: string, sound: string?)
	local b = ui("Countdown")
	if b then b:Fire(TITLE, text, "yellow", sound) end
end
local TITLE_SEC = 1.2 -- скільки висить напис перед цифрами
local function hide()
	local b = ui("CountdownHide")
	if b then b:Fire() end
end
local function toast(text: string, color: string, sound: string?)
	local b = ui("Toast")
	if b then b:Fire(text, color, sound) end
end

local function center(): BasePart?
	local cave = workspace:FindFirstChild("Cave")
	local hub = cave and cave:FindFirstChild("Hub")
	local m = hub and hub:FindFirstChild("Marketplace")
	local c = m and m:FindFirstChild("RingCenter", true)
	return (c and c:IsA("BasePart")) and c or nil
end
local function inRing(): boolean
	local c = center()
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not (c and hrp and hum and hum.Health > 0) then return false end
	local d = hrp.Position - c.Position
	return Vector2.new(d.X, d.Z).Magnitude <= Cfg.MARKET_RING_R and d.Y > -2 and d.Y < 8
end

-- стан: idle → counting (у колі) → done (спроба була, чекаємо виходу з кола)
local state, t0, shown = "idle", 0, -1
local invoking = false
local function attempt()
	invoking = true
	banner("...", "")
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("MarketplaceTP")
	local ok, res = false, nil
	if rf then ok, res = pcall(function() return rf:InvokeServer() end) end
	invoking = false
	if ok and type(res) == "table" and res.ok then return end -- телепорт йде (екран завантаження Roblox)
	hide()
	local reason = ok and type(res) == "table" and res.reason or "fail"
	if reason == "soon" then toast("Marketplace is coming soon!", "yellow", "deny")
	elseif reason == "far" then toast("Stand inside the circle!", "red", "deny")
	else toast("Teleport failed, try again", "red", "deny") end
end

RunService.Heartbeat:Connect(function()
	local inside = inRing()
	if state == "idle" then
		if inside then state = "counting"; t0 = os.clock(); shown = -1 end
	elseif state == "counting" then
		if not inside then
			state = "idle"; hide()
			return
		end
		local el = os.clock() - t0
		if el < TITLE_SEC then
			if shown ~= 0 then shown = 0; banner("", "claim") end -- спершу напис
			return
		end
		local left = Cfg.MARKET_COUNTDOWN - (el - TITLE_SEC)
		if left <= 0 then
			state = "done"
			task.spawn(attempt)
			return
		end
		local n = math.ceil(left)
		if n ~= shown then
			shown = n
			banner(tostring(n), "tap")
		end
	elseif state == "done" then
		if not inside and not invoking then state = "idle"; hide() end
	end
end)

-- ===== табличка «MARKETPLACE»: золотий перелив + білий відблиск (як SELL / WORKSHOP) =====
do
	local PAL = { Color3.fromHex("fff3b0"), Color3.fromHex("ffd23a"), Color3.fromHex("ff9a1f"), Color3.fromHex("ffd23a") }
	local function sample(u)
		local x = (u % 1) * #PAL
		local k = math.floor(x)
		local t = x - k
		t = t * t * (3 - 2 * t)
		return PAL[k + 1]:Lerp(PAL[(k + 1) % #PAL + 1], t)
	end
	local SHINE_T = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) })
	local title, grad, tw, nextAt = nil, nil, nil, 0
	local function hook()
		local c = center()
		local sign = c and c.Parent and c.Parent:FindFirstChild("MarketSign", true)
		local t = sign and sign:FindFirstChild("Title")
		if not (t and t:IsA("TextLabel")) or t == title then return end
		title = t
		grad = t:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", t)
		grad.Rotation = 0
		for _, o in t.Parent:GetChildren() do if o.Name == "TitleShine" then o:Destroy() end end
		local sh = t:Clone()
		sh.Name = "TitleShine"; sh.TextColor3 = Color3.new(1, 1, 1); sh.ZIndex = t.ZIndex + 1
		for _, ch in sh:GetChildren() do ch:Destroy() end
		local sg = Instance.new("UIGradient"); sg.Rotation = 25; sg.Transparency = SHINE_T; sg.Offset = Vector2.new(-1.3, 0); sg.Parent = sh
		sh.Parent = t.Parent
		tw = TweenService:Create(sg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
		tw.Completed:Connect(function() sg.Offset = Vector2.new(-1.3, 0) end)
		nextAt = os.clock() + 1
	end
	task.spawn(function() while true do hook(); task.wait(2) end end)
	RunService.Heartbeat:Connect(function()
		if not (title and title.Parent and grad) then return end
		local phase = -(os.clock() / 4)
		local ks = {}
		for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phase)) end
		grad.Color = ColorSequence.new(ks)
		if tw and os.clock() >= nextAt then nextAt = os.clock() + 4 + math.random() * 3; tw:Play() end
	end)
end
