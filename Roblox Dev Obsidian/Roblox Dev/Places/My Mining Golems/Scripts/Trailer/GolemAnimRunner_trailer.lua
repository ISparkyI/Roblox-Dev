--!strict
-- GolemAnimRunner — спільний «двигун» анімації всіх големів на клієнті (03.11.2026, оптимізація для телефонів).
-- Де: ReplicatedStorage/Shared/GolemAnimRunner. Кожен GolemAnimator (v3.8) реєструє свій крок: Runner.add(model, root, step);
--   тут ОДИН PreRender на всіх замість окремого підключення в кожного голема.
-- LOD (раз на ~0,5 с для кожного голема): відстань = мінімум до камери й до гравця (HumanoidRootPart).
--   поза ViewportFrame/WorldModel (не в workspace) — щокадру (вікна, кейси);
--   ніша з LODNear = false (NicheLOD: далека ніша) — 1 раз на секунду;
--   поза екраном (з запасом) — 2–3 рази на секунду;
--   ближче NEAR — щокадру на ПК, 30 к/с на телефоні; до MID — 30 / 15 к/с; до FAR — 10 / 6 к/с; далі — 3 / 2 к/с.
-- 04.11.2026: ЧУЖІ големи (ніша/печера з OwnerUserId ≠ свій) зовсім не анімуються, поки гравець не підійде ближче FOREIGN_NEAR
--   стадів (персонажем); застигають у поточній позі, при наближенні оживають.
-- 04.11.2026 (2): і СВОЇ големи застигають, коли гравець далі OWN_FAR стадів від голема, поза своєю нішею (LODNear = false)
--   або голем поза екраном; оживають, щойно знову видно / підійшов.
-- 06.11.2026: МАРКЕТ (HubConfig.isMarket) — големи без власника (стенди ексклюзивів, INDEX, HOME) анімуються завжди щокадру, без LOD за відстанню;
--   виставлені големи ІНШИХ гравців (MarketUI: моделі «Lot_<UserId>_<id>») застигають далі FOREIGN_NEAR, свої — як звичайно.
-- 06.11.2026: SETTINGS → ANIMATION DISTANCE (атрибут гравця Set_AnimDist 0–100, лише лоббі) — множник усіх відстаней LOD:
--   0 % → ×0,25 (обрізаємо найсильніше, більше FPS), 50 % (за замовчуванням) → ×1, 100 % → ×4 (анімації далеко).
-- Бюджет кадру: не більше BUDGET големів за кадр (по колу), решта чекає наступного кадру — час кадру не росте з кількістю големів.
-- 07.11.2026: режим трейлера (workspace.TrailerLive, лише Studio) — големи Workspace/TrailerLive щокадру, без бюджету.
-- step(dt, low): dt — скільки часу минуло з попереднього кроку цього голема; low = true — далеко (без міміки обличчя).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local M = {}

local MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local NEAR, MID, FAR = 35, 70, 140
local IV = if MOBILE
	then { near = 1 / 30, mid = 1 / 15, far = 1 / 6, beyond = 0.5, off = 0.5, hidden = 1 }
	else { near = 0, mid = 1 / 30, far = 1 / 10, beyond = 1 / 3, off = 1 / 3, hidden = 1 }
local BUDGET = if MOBILE then 10 else 40
local LOW_DIST = 30 -- далі — без міміки (очі/брови дрібні)
local SCREEN_PAD = 150 -- px запасу за краєм екрана
local FOREIGN_NEAR = 40 -- стадів від персонажа до чужого голема, з яких він оживає
local OWN_FAR = 80 -- стадів від персонажа: далі свій голем теж застигає
local FROZEN = math.huge
local okHub, HubCfg = pcall(function() return require(script.Parent:WaitForChild("HubConfig")) end)
local function isMarket(): boolean
	return okHub and HubCfg and HubCfg.isMarket and HubCfg.isMarket() or false
end

local function distMul(): number
	if isMarket() then return 1 end
	local lp = Players.LocalPlayer
	local v = lp and tonumber(lp:GetAttribute("Set_AnimDist"))
	if not v then return 1 end
	return 2 ^ ((math.clamp(v, 0, 100) - 50) / 25)
end

type E = { model: Model, root: BasePart, step: (number, boolean) -> (), acc: number, iv: number, low: boolean, tierT: number, niche: Instance? | boolean, owner: Instance? | boolean }
local list: { E } = {}
local rr = 1

local function nicheOf(m: Instance): Instance?
	local x = m.Parent
	while x and x ~= workspace do
		if x:GetAttribute("LODNear") ~= nil then return x end
		x = x.Parent
	end
	return nil
end

local function ownerOf(m: Instance): Instance?
	local x = m.Parent
	while x and x ~= workspace do
		if x:GetAttribute("OwnerUserId") ~= nil then return x end
		x = x.Parent
	end
	return nil
end

local function retier(e: E, cam: Camera?, hrp: Vector3?)
	local m = e.model
	if not m:IsDescendantOf(workspace) then e.iv, e.low = 0, false; return end
	-- 07.11.2026: трейлер (лише Studio, StarterPlayerScripts/TrailerDirector ставить workspace.TrailerLive) — свої големи
	--   трейлера (Workspace/TrailerLive) щокадру без LOD; поза екраном — рідко
	if workspace:GetAttribute("TrailerLive") == true and m:IsDescendantOf(workspace:FindFirstChild("TrailerLive") or m) then
		e.low = false
		if cam then
			local v = cam:WorldToViewportPoint(e.root.Position)
			local vs = cam.ViewportSize
			if v.Z < -6 or v.X < -SCREEN_PAD or v.Y < -SCREEN_PAD or v.X > vs.X + SCREEN_PAD or v.Y > vs.Y + SCREEN_PAD then e.iv = IV.off; return end
		end
		e.iv = 0
		return
	end
	local k = distMul()
	if e.owner == nil or e.owner == false then e.owner = ownerOf(m) or false end
	local o = e.owner
	if typeof(o) == "Instance" and o:GetAttribute("OwnerUserId") ~= Players.LocalPlayer.UserId then
		if not hrp or (hrp - e.root.Position).Magnitude > FOREIGN_NEAR * k then e.iv, e.low = FROZEN, true; return end
	elseif typeof(o) == "Instance" then
		if not hrp or (hrp - e.root.Position).Magnitude > OWN_FAR * k then e.iv, e.low = FROZEN, true; return end
	end
	if o == false and isMarket() then
		local uid = tonumber(string.match(m.Name, "^Lot_(%d+)_"))
		if uid == nil then e.iv, e.low = 0, false; return end -- стенди маркету: завжди
		if uid ~= Players.LocalPlayer.UserId and (not hrp or (hrp - e.root.Position).Magnitude > FOREIGN_NEAR) then
			e.iv, e.low = FROZEN, true; return
		end
	end
	if e.niche == nil or e.niche == false then e.niche = nicheOf(m) or false end
	local n = e.niche
	if typeof(n) == "Instance" and n:GetAttribute("LODNear") == false then e.iv, e.low = FROZEN, true; return end
	local p = e.root.Position
	local d = math.huge
	if cam then d = (cam.CFrame.Position - p).Magnitude end
	if hrp then d = math.min(d, (hrp - p).Magnitude) end
	e.low = d > LOW_DIST * k
	if cam and d > 12 then
		local v = cam:WorldToViewportPoint(p)
		local vs = cam.ViewportSize
		if v.Z < -6 or v.X < -SCREEN_PAD or v.Y < -SCREEN_PAD or v.X > vs.X + SCREEN_PAD or v.Y > vs.Y + SCREEN_PAD then
			e.iv = if typeof(e.owner) == "Instance" then FROZEN else IV.off; return
		end
	end
	e.iv = if d <= NEAR * k then IV.near elseif d <= MID * k then IV.mid elseif d <= FAR * k then IV.far else IV.beyond
end

function M.add(model: Model, root: BasePart, step: (number, boolean) -> ())
	table.insert(list, { model = model, root = root, step = step, acc = 1, iv = 0, low = false, tierT = 0, niche = nil, owner = nil })
end

RunService.PreRender:Connect(function(dt)
	local n = #list
	if n == 0 then return end
	local cam = workspace.CurrentCamera
	local ch = Players.LocalPlayer and Players.LocalPlayer.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hp = if hrp and hrp:IsA("BasePart") then hrp.Position else nil
	local trailer = workspace:GetAttribute("TrailerLive") == true
	-- прибрати знищених, накопичити час, оновити LOD (рознесено в часі)
	local i = 1
	while i <= #list do
		local e = list[i]
		if not e.model.Parent or not e.root.Parent then
			list[i] = list[#list]; list[#list] = nil
		else
			e.acc += dt
			e.tierT -= dt
			if e.tierT <= 0 then
				e.tierT = if trailer then 0.05 else 0.4 + math.random() * 0.2
				retier(e, cam, hp)
			end
			i += 1
		end
	end
	n = #list
	if n == 0 then return end
	if rr > n then rr = 1 end
	local budget = if trailer then 100000 else BUDGET
	for k = 0, n - 1 do
		local j = ((rr - 1 + k) % n) + 1
		local e = list[j]
		if e.acc >= e.iv then
			local a = e.acc
			e.acc = 0
			local ok, err = pcall(e.step, a, e.low)
			if not ok then
				warn("[GolemAnimRunner] " .. e.model.Name .. ": " .. tostring(err))
				e.iv, e.tierT = math.huge, math.huge -- зламаний крок більше не викликаємо
			end
			budget -= 1
			if budget <= 0 then rr = j + 1; return end
		end
	end
end)

return M
