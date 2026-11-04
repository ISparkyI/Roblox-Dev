--!strict
-- CaseOpenClient — анімація відкриття кейса з інвентаря / хотбара (02.11.2026). Де: StarterPlayer/StarterPlayerScripts/CaseOpenClient.
-- Сервер — ServerScriptService/CaseService (рол і видача), сюди приходить Remotes/CaseResult { ok, case, kind, cls, mut, fakes }.
-- Таймлайн (лише в цього гравця):
--   1) кейс (клон PlotAssets/ExclusiveCase × CASE_K) падає з неба перед гравцем (FRONT стадів), вдаряється й підстрибує, пил на землі;
--   2) Shared/CaseOpening: заряд (тремтить, кристали стягуються) → вибух (кришка відлітає, промінь, хвиля, іскри);
--   3) «рулетка» як у ролі: над кейсом по черзі з'являються й зникають големи кейсу (fakes) з назвою,
--      дедалі повільніше, звук щоразу вище; останній — результат: спалах, кубики, табличка (рідкість, назва, клас, шанс);
--   4) через SHOW с голем зменшується й летить до гравця (в інвентар), кейс зникає.
-- Поки йде анімація, атрибут LocalPlayer.CaseOpening = true (лише клієнт): InventoryUI не відкриває наступний.
-- Відмова сервера — тост (UIEvents/Toast): інвентар повний / немає кейсів.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local GolemModel = require(Shared:WaitForChild("GolemModel"))
local CaseOpening = require(Shared:WaitForChild("CaseOpening"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local FRONT = 10        -- стадів перед гравцем
local CASE_K = 0.5      -- кейс у світі — вдвічі менший за префаб біля кейсу (Scale 1.5 → 0.75)
local GOLEM_K = 0.5     -- големи над кейсом
local DROP_H, DROP_T = 16, 0.55
local ROLL_T0 = CaseOpening.BURST + 0.35 -- рулетка починається, коли кришка відкрилась
local FIRST, GROW = 0.1, 1.17 -- тривалість першого фейка й сповільнення
local SHOW = 3.6
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local INK = Color3.fromHex("14161a")
local CLASS_NAME = { miner = "Miner", carrier = "Carrier", warrior = "Warrior" }

local function backOut(x: number): number
	x = math.clamp(x, 0, 1)
	local c1, c3 = 1.9, 2.9
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function toast(text: string)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t and t:IsA("BindableEvent") then t:Fire(text, "red", "deny") end
end

local function fxFolder(): Folder
	local f = workspace:FindFirstChild("CaseOpenFx")
	if not f then f = Instance.new("Folder"); f.Name = "CaseOpenFx"; f.Parent = workspace end
	return f :: Folder
end

local function cubes(at: Vector3, color: Color3, n: number, spread: number)
	for i = 1, n do
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.Neon; p.Color = color
		p.Size = Vector3.one * (0.25 + math.random() * 0.3)
		local a = (i / n) * math.pi * 2 + math.random() * 0.4
		p.CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 0.6, 0.3, math.sin(a) * 0.6))
		p.Parent = fxFolder()
		local goal = p.CFrame + Vector3.new(math.cos(a) * spread, 1.5 + math.random() * 2, math.sin(a) * spread)
		TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = goal * CFrame.Angles(math.random() * 3, math.random() * 3, 0), Size = Vector3.one * 0.05, Transparency = 0.7 }):Play()
		task.delay(0.65, function() p:Destroy() end)
	end
end

local function textLabel(parent: Instance, order: number, h: number, str: string, color: Color3, font: Font): TextLabel
	local t = Instance.new("TextLabel")
	t.LayoutOrder = order; t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, h)
	t.FontFace = font; t.TextScaled = true; t.Text = str; t.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Color = INK; s.Thickness = 2.4; s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	t.Parent = parent
	return t
end

-- табличка над големом: фейк — лише назва; результат — рідкість, назва, клас, шанс
local function board(root: BasePart, top: number, kind: string, cls: string?, final: boolean): BillboardGui
	local def = Catalog.get(kind)
	local bb = Instance.new("BillboardGui")
	bb.Name = "CaseInfo"; bb.Adornee = root; bb.LightInfluence = 0; bb.AlwaysOnTop = false; bb.MaxDistance = 80
	bb.Size = final and UDim2.fromScale(6, 3.6) or UDim2.fromScale(5, 0.9)
	bb.StudsOffsetWorldSpace = Vector3.new(0, top + (final and 2 or 0.9), 0)
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder; list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = bb
	local scale = Instance.new("UIScale"); scale.Scale = final and 0 or 1; scale.Parent = bb
	if final then
		textLabel(bb, 1, 0.16, "YOU GOT!", Color3.fromHex("ffd23a"), HEAVY)
		local bt = Catalog.bestText and Catalog.bestText(kind, cls)
		if bt then textLabel(bb, 2, 0.14, bt, Catalog.BEST_COLOR, HEAVY) end -- «65% BEST» над рідкістю
		textLabel(bb, 3, 0.15, def and def.rarity or "", Catalog.rarityColor(def and def.rarity), XBOLD)
		textLabel(bb, 4, 0.24, def and def.name or kind, Color3.new(1, 1, 1), HEAVY)
		local ch = def and tonumber(def.caseChance) or nil
		local chTxt = ch and ((ch * 100 >= 1 and string.format("%g", math.floor(ch * 1000 + 0.5) / 10) or string.format("%g", ch * 100)) .. "%") or ""
		textLabel(bb, 5, 0.16, (CLASS_NAME[cls or "miner"] or "Miner") .. (chTxt ~= "" and (" · " .. chTxt .. " chance") or ""), Color3.fromHex("7dff3a"), HEAVY)
	else
		textLabel(bb, 1, 1, def and def.name or kind, Color3.new(1, 1, 1), HEAVY)
	end
	bb.Parent = root
	if final then TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end
	return bb
end

type G = { m: Model, base: number, foot: number }
local function spawnGolem(kind: string, cls: string): G?
	local m = GolemModel.build(kind, cls)
	if not m then return nil end
	m.Name = "CaseGolem"
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.CanQuery = false; d.CanCollide = false; d.CanTouch = false end end
	m:ScaleTo(m:GetScale() * GOLEM_K)
	return { m = m, base = m:GetScale(), foot = GolemModel.footOffset(m) }
end
local function poseGolem(g: G, at: Vector3, face: Vector3, k: number, yaw: number)
	local kk = math.max(0.02, k)
	if math.abs(g.m:GetScale() - g.base * kk) > 1e-4 then g.m:ScaleTo(g.base * kk) end
	local pos = at + Vector3.new(0, g.foot * kk, 0)
	g.m:PivotTo(CFrame.lookAt(pos, Vector3.new(face.X, pos.Y, face.Z)) * CFrame.Angles(0, yaw, 0))
end

local function groundAt(pos: Vector3, ignore: { Instance }): Vector3
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignore
	local r = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), rp)
	return r and r.Position or pos - Vector3.new(0, 3, 0)
end

local function play(res: any)
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	local assets = RS:FindFirstChild("PlotAssets")
	local src = assets and assets:FindFirstChild("ExclusiveCase")
	if not hrp or not src then return end
	-- місце: FRONT стадів перед гравцем, на землі; кейс дивиться на гравця (лицем — −Z)
	local look = hrp.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local me = hrp.Position
	local ground = groundAt(me + look * FRONT, { ch :: Instance, fxFolder() })
	local case = (src :: Model):Clone()
	for _, d in case:GetDescendants() do
		if d:IsA("LuaSourceContainer") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
	end
	local S0 = (case:GetAttribute("Scale") :: number?) or 1
	local hinge = (case:GetAttribute("Hinge") :: Vector3?) or Vector3.zero
	local top = (case:GetAttribute("Top") :: number?) or 3
	case:ScaleTo(case:GetScale() * CASE_K)
	case:SetAttribute("Scale", S0 * CASE_K); case:SetAttribute("Hinge", hinge * CASE_K); case:SetAttribute("Top", top * CASE_K)
	-- низ кейса (плінт) — на землю: зсув півота відносно найнижчої деталі корпусу
	case:PivotTo(CFrame.new())
	local minY = math.huge
	for _, d in case:GetDescendants() do
		if d:IsA("BasePart") and not (case:FindFirstChild("Orbits") and d:IsDescendantOf(case.Orbits :: Instance)) then
			minY = math.min(minY, d.Position.Y - d.Size.Y / 2)
		end
	end
	local lift = -minY
	-- лице кейса (емблема) — +Z моделі, шарнір кришки — −Z: розвертаємо на 180°, щоб кейс стояв лицем до гравця
	local baseCF = CFrame.lookAt(ground + Vector3.new(0, lift, 0), Vector3.new(me.X, ground.Y + lift, me.Z)) * CFrame.Angles(0, math.pi, 0)
	case:PivotTo(baseCF + Vector3.new(0, DROP_H, 0))
	case.Name = "OpeningCase"
	case.Parent = fxFolder()
	player:SetAttribute("CaseOpening", true)
	-- для тестів / скрінів: LocalPlayer.CaseAnimSpeed (0,05–1; за замовчуванням 1)
	local spd = math.clamp(tonumber(player:GetAttribute("CaseAnimSpeed")) or 1, 0.05, 1)

	-- 1) падіння з неба + підскок
	local t0 = os.clock()
	while true do
		local t = (os.clock() - t0) * spd
		local y
		if t < DROP_T then
			local u = t / DROP_T
			y = DROP_H * (1 - u * u)
		elseif t < DROP_T + 0.3 then
			local u = (t - DROP_T) / 0.3
			y = 1.1 * 4 * u * (1 - u)
		else
			break
		end
		case:PivotTo(baseCF * CFrame.new(0, y, 0) * CFrame.Angles(0, (1 - math.min(1, t / DROP_T)) * 1.2, 0))
		RunService.RenderStepped:Wait()
		if t >= DROP_T and not case:GetAttribute("Landed") then
			case:SetAttribute("Landed", true)
			cubes(ground, Color3.fromHex("cfc6b8"), 14, 3)
			UISounds.play("tap", 0, 0.7)
		end
	end
	case:PivotTo(baseCF)
	task.wait(0.15)

	-- 2) + 3) відкриття і рулетка
	local anim = CaseOpening.new(case, nil)
	local topPos = (baseCF * CFrame.new(0, (top * CASE_K) + 0.8, 0)).Position -- голем ширяє над відкритим кейсом
	local fakes = type(res.fakes) == "table" and res.fakes or {}
	local seq = {}
	local at = ROLL_T0
	local d = FIRST
	for _, k in fakes do table.insert(seq, { k = k, t = at, d = d }); at += d; d *= GROW end
	local finalT = at
	local cur: G? = nil
	local curI = 0
	local final: G? = nil
	local startT = os.clock()
	local done = false
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - startT) * spd
		anim:pose(math.min(t, CaseOpening.DURATION))
		if t < ROLL_T0 then return end
		if t < finalT then
			local i = curI
			while i < #seq and t >= seq[i + 1].t do i += 1 end
			if i ~= curI then
				if cur then cur.m:Destroy() end
				curI = i
				cur = spawnGolem(seq[i].k, res.cls or "miner")
				if cur then
					cur.m.Parent = fxFolder()
					local root = cur.m:FindFirstChild("Root") :: BasePart?
					if root then board(root, GolemModel.headTop(cur.m), seq[i].k, nil, false) end
				end
				UISounds.play("hover", 0, 0.9 + 0.05 * i)
			end
			if cur then
				local s = seq[curI]
				local u = (t - s.t) / math.max(0.05, s.d)
				local k = u < 0.45 and backOut(u / 0.45) or (u > 0.85 and (1 - (u - 0.85) / 0.15 * 0.5) or 1)
				poseGolem(cur, topPos, me, k, 0)
			end
			return
		end
		-- результат
		if not final then
			if cur then cur.m:Destroy(); cur = nil end
			final = spawnGolem(res.kind, res.cls or "miner")
			if final then
				final.m.Parent = fxFolder()
				local def = Catalog.get(res.kind)
				local color = Catalog.rarityColor(def and def.rarity)
				local h = Instance.new("Highlight")
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.FillColor = Color3.new(1, 1, 1); h.FillTransparency = 0.05; h.OutlineColor = color; h.OutlineTransparency = 0
				h.Parent = final.m
				TweenService:Create(h, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 1, OutlineTransparency = 0.6 }):Play()
				local rare = def and (tonumber(def.caseChance) or 1) <= 0.02
				cubes(topPos, color, rare and 28 or 14, rare and 5 or 3)
				if rare then cubes(topPos, Color3.fromHex("ffd23a"), 18, 6) end
				UISounds.play("claim", 0)
				local root = final.m:FindFirstChild("Root") :: BasePart?
				if root then
					local l = Instance.new("PointLight")
					l.Color = color; l.Range = 14; l.Brightness = 3; l.Shadows = false; l.Parent = root
					TweenService:Create(l, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0.6 }):Play()
					board(root, GolemModel.headTop(final.m), res.kind, res.cls, true)
				end
			end
		end
		if final then
			local u = (t - finalT) / 0.35
			poseGolem(final, topPos + Vector3.new(0, 0.15 * math.sin((t - finalT) * 2.4), 0), me, backOut(u), 0)
		end
		if t >= finalT + SHOW then done = true end
	end)
	while not done and case.Parent do task.wait(0.05) end
	conn:Disconnect()

	-- 4) голем летить до гравця, кейс зникає
	local info = final and final.m:FindFirstChild("CaseInfo", true)
	if info then info:Destroy() end
	local parts = {}
	for _, p in case:GetDescendants() do if p:IsA("BasePart") and p.Transparency < 1 then table.insert(parts, { p = p, tr = p.Transparency }) end end
	local e0 = os.clock()
	while true do
		local a = math.clamp((os.clock() - e0) * spd / 0.45, 0, 1)
		if final and final.m.Parent then
			local hr = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) :: BasePart?
			local dest = hr and hr.Position or me
			poseGolem(final, topPos:Lerp(dest, a * a), me, 1 - a * 0.95, a * math.pi * 2)
		end
		for _, r in parts do r.p.Transparency = r.tr + (1 - r.tr) * a end
		if a >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	if final then final.m:Destroy() end
	anim:destroy()
	case:Destroy()
	UISounds.play("BuySound", 0)
	player:SetAttribute("CaseOpening", nil)
end

local queue = {}
local busy = false
local function pump()
	if busy then return end
	busy = true
	while #queue > 0 do
		local r = table.remove(queue, 1)
		local ok, err = pcall(play, r)
		if not ok then
			warn("[CaseOpenClient] " .. tostring(err))
			player:SetAttribute("CaseOpening", nil)
			fxFolder():ClearAllChildren() -- не лишати кейс / голема у світі після помилки
		end
	end
	busy = false
end

(Remotes:WaitForChild("CaseResult") :: RemoteEvent).OnClientEvent:Connect(function(res: any)
	if type(res) ~= "table" then return end
	if not res.ok then
		if res.why == "full" then toast("Inventory full! Free a slot to open the case")
		elseif res.why == "none" then toast("No cases left") end
		return
	end
	-- одне вікно на екрані: інвентар / інші вікна закриваються, щоб було видно кейс
	pcall(function() require(Shared:WaitForChild("WindowManager")).opened("CaseOpen") end)
	table.insert(queue, res)
	task.spawn(pump)
end)
