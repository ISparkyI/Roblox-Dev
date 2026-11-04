--!nonstrict
-- MutationMachineClient — вигляд Mutation Machines для локального гравця (у кожного свої слоти). 29.10.2026.
-- Де: StarterPlayer/StarterPlayerScripts/MutationMachineClient (LocalScript). Сервер — MutationService, конфіг — Shared/MutationConfig.
-- Стан — атрибут гравця MutMachines (сервер). Тут:
--   * големи на підставках (Shared/GolemModel, атрибут Mut — аура MutationAuraClient) і таблички над ними (мутація + назва);
--   * колір підставок і екранів камери (чекає / мутує / готово);
--   * панель над машиною (BillboardGui у PlayerGui): назва, статус (ADD 3 GOLEMS … READY!), що додано, таймер,
--     смуга прогресу, кнопка прискорення xN TIME (Developer Product наступного ступеня MUT_SPEED_TIERS, лише Robux);
--   * написи кнопок E (CustomPrompts): PLACE / TAKE / CLAIM / HOLD A GOLEM / NOT THE SAME / MAX MUTATION / ON PLOT / INVENTORY FULL.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Shared = RS:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local GolemModel = require(Shared:WaitForChild("GolemModel"))
local MutCfg = require(Shared:WaitForChild("MutationConfig"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local Items = require(Shared:WaitForChild("ItemConfig"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local MutationText = require(Shared:WaitForChild("MutationText"))
local UISfx = require(Shared:WaitForChild("UISfx"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }
local HOLD = 0.35
local NEVER = 1e6
local PAD_EMPTY = C("8a8f9e")
local SCREEN_IDLE = C("9d92c9")
local GOLEM_H = 6.5   -- найбільша висота голема на підставці, стад
local GOLEM_W = 4.6   -- найбільша ширина

local function now(): number return workspace:GetServerTimeNow() end
local function decode(attr: string, default: any): any
	local s = player:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function frame(parent, x, y, w, h, color, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or WHITE, BorderSizePixel = 0 }, parent)
	if props then for k, v in props do f[k] = v end end
	return f
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, color, th, contextual)
	return new("UIStroke", { Color = color, Thickness = th, LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, true) end
	return t
end
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function stud(parent, x, y, cell, fill, shade)
	local s = cell * 0.62
	local o = (cell - s) / 2
	local d = s * 0.12
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade, { ZIndex = 1 }); corner(sh, s * 0.16)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill, { ZIndex = 2 }); corner(st, s * 0.16)
end
local function fmtLong(sec: number): string
	sec = math.max(0, math.ceil(sec))
	local h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
	if h > 0 then return string.format("%dh %dm %ds", h, m, s) end
	if m > 0 then return string.format("%dm %ds", m, s) end
	return string.format("%ds", s)
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end
local function golemName(r): string
	local def = Catalog.get(r.kind)
	return (def and def.name or tostring(r.kind))
end
local function mutKey(m: number): string
	local d = Catalog.mutation(m)
	return d and d.key or "?"
end
local function mutColor(m: number): Color3
	local d = Catalog.mutation(m)
	return d and d.color or WHITE
end

-- ===== стан =====
local function stateOf(): any
	local st = decode("MutMachines", {})
	for i = 1, MutCfg.MACHINES do
		local m = st[tostring(i)]
		if type(m) ~= "table" then st[tostring(i)] = { slots = {} } elseif type(m.slots) ~= "table" then m.slots = {} end
	end
	return st
end
local function firstRec(m)
	for s = 1, MutCfg.SLOTS do local r = m.slots[tostring(s)]; if type(r) == "table" then return r end end
	return nil
end
local function count(m)
	local n = 0
	for s = 1, MutCfg.SLOTS do if type(m.slots[tostring(s)]) == "table" then n += 1 end end
	return n
end
local function isDone(m) return type(m.job) == "table" and MutCfg.left(m.job, now()) <= 0 end
local function invFull(): boolean
	return Items.invGolemCount(decode("InvGolems", {}), decode("PlotPlaced", {})) + 1 > Items.maxGolems(player)
end

-- ===== панель над машиною: SurfaceGui на невидимій дошці PanelBoard (обидва боки) =====
-- Фіксована роздільність (PixelsPerStud) — текст не «підганяється» під відстань камери і не смикається.
local CW, CH = 1100, 360
local remote = RS:WaitForChild("Remotes"):WaitForChild("MutationAction")
local function buildPanel(board: BasePart, face: Enum.NormalId, index: number)
	local sg = new("SurfaceGui", { Name = "MutationPanel" .. index .. face.Name, Adornee = board, Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = CW / board.Size.Z, LightInfluence = 0,
		MaxDistance = 160, AlwaysOnTop = false, ResetOnSpawn = false, ClipsDescendants = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
	local canvas = new("Frame", { Size = UDim2.fromOffset(CW, CH), BackgroundTransparency = 1 }, sg)
	frame(canvas, 0, 12, CW, CH - 12, BLACK, { BackgroundTransparency = 0.65 })
	local win = frame(canvas, 0, 0, CW, CH - 12, WHITE, { ZIndex = 1 })
	new("UIGradient", { Color = cseq(RIM), Rotation = 90 }, win); stroke(win, INK, 6)
	local pw, ph = CW - 32, CH - 12 - 32
	local panel = frame(win, 16, 16, pw, ph, C("a9aeb5"), { ZIndex = 2, ClipsDescendants = true }); stroke(panel, INK, 4)
	local CELL = 40
	local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
	local ox, oy = (pw - nx * CELL) / 2, (ph - ny * CELL) / 2
	local studs = frame(panel, 0, 0, pw, ph, nil, { BackgroundTransparency = 1, ZIndex = 1 })
	StyleA.studTile(studs, ox, oy, nx * CELL, ny * CELL, CELL, C("b3b8bf")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
	local shade = frame(panel, 0, 0, pw, ph, BLACK, { ZIndex = 2, BackgroundTransparency = 0.35 })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.25) }) }, shade)
	local ct = frame(win, 16, 16, pw, ph, nil, { BackgroundTransparency = 1, ZIndex = 3 })
	local title = label(ct, 28, 8, 640, 70, 56, "MUTATION MACHINE " .. index, WHITE, 6, { ZIndex = 4 })
	local tg = new("UIGradient", { Rotation = 0 }, title)
	local status = label(ct, pw - 28 - 440, 8, 440, 70, 44, "", WHITE, 5, { ZIndex = 4, TextXAlignment = Enum.TextXAlignment.Right })
	local added = label(ct, 30, 82, pw - 60, 40, 30, "", WHITE, 4, { ZIndex = 4, RichText = true })
	local timer = label(ct, 26, 120, 640, 120, 104, "", WHITE, 9, { ZIndex = 4 })
	local timerGrad = new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "e6fdff" }, { 1, "6fd2ff" } }) }, timer)
	local barBack = frame(ct, 30, 250, 620, 30, C("2b2f38"), { ZIndex = 4 }); corner(barBack, 8); stroke(barBack, INK, 4)
	local bar = frame(barBack, 0, 0, 0, 30, WHITE, { ZIndex = 5 }); corner(bar, 8)
	local barGrad = new("UIGradient", { Rotation = 90 }, bar)
	local pct = label(barBack, 0, 0, 620, 30, 22, "", WHITE, 3, { ZIndex = 6, TextXAlignment = Enum.TextXAlignment.Center })
	-- START (3 однакових покладено, мутація ще не йде) — на місці смуги прогресу
	local startSh = frame(ct, 30, 236, 380, 76, BLACK, { BackgroundTransparency = 0.7, ZIndex = 4, Visible = false })
	local startBtn = StyleA.new(ct, { size = Vector2.new(380, 76), position = Vector2.new(30, 228), color = "green", text = "START", textSize = 40,
		clickable = true, zIndex = 5 })
	StyleA.follow(startBtn, startSh)
	startBtn.root.Visible = false
	-- CANCEL (мутація йде) — на місці START, смуга прогресу тоді праворуч від неї
	local cancelSh = frame(ct, 30, 236, 220, 76, BLACK, { BackgroundTransparency = 0.7, ZIndex = 4, Visible = false })
	local cancelBtn = StyleA.new(ct, { size = Vector2.new(220, 76), position = Vector2.new(30, 228), color = "red", text = "CANCEL", textSize = 34,
		clickable = true, zIndex = 5 })
	StyleA.follow(cancelBtn, cancelSh)
	cancelBtn.root.Visible = false
	local fromL = label(ct, 690, 112, 160, 50, 34, "", WHITE, 4, { ZIndex = 4, TextXAlignment = Enum.TextXAlignment.Right })
	local arrow = label(ct, 852, 112, 50, 50, 34, "→", WHITE, 4, { ZIndex = 4, TextXAlignment = Enum.TextXAlignment.Center })
	local toL = label(ct, 904, 112, 160, 50, 34, "", WHITE, 4, { ZIndex = 4 })
	local speedCur = label(ct, 700, 168, 350, 34, 26, "", C("e9edf1"), 3, { ZIndex = 4, TextXAlignment = Enum.TextXAlignment.Center })
	local btnSh = frame(ct, 720, 214, 310, 84, BLACK, { BackgroundTransparency = 0.7, ZIndex = 4 })
	local btn = StyleA.new(ct, { size = Vector2.new(310, 84), position = Vector2.new(720, 206), color = "purple", text = "x2 TIME", textSize = 38,
		clickable = true, zIndex = 5 })
	StyleA.follow(btn, btnSh)
	local P = {
		sg = sg, title = title, tg = tg, status = status, added = added, timer = timer, timerGrad = timerGrad, barBack = barBack, bar = bar,
		barGrad = barGrad, pct = pct, fromL = fromL, toL = toL, arrow = arrow, speedCur = speedCur, btn = btn, startBtn = startBtn, startSh = startSh, cancelBtn = cancelBtn, cancelSh = cancelSh,
	}
	StyleA.bind(btn, { debounce = 0.5, canClick = function() return P.canBuy == true end, onClick = function()
		local tier = (tonumber(player:GetAttribute("MutSpeedTier")) or 0) + 1
		local t = MonCfg.MUT_SPEED_TIERS[tier]
		if not t then return end
		if t.id == 0 then toast("Fast Mutations are coming soon!", "gray"); return end
		MarketplaceService:PromptProductPurchase(player, t.id)
	end })
	StyleA.bind(cancelBtn, { debounce = 0.6, canClick = function() return P.canCancel == true end, onClick = function()
		remote:FireServer("Cancel", index)
	end })
	StyleA.bind(startBtn, { debounce = 0.6, canClick = function() return P.canStart == true end, onClick = function()
		remote:FireServer("Start", index)
	end })
	return P
end

-- ===== машини =====
local machines = {} -- [index] = { model, slots = { [s] = { slot, pad, prompt, golem, sig } }, core, screens, claim, panel }

local function golemOnPad(entry, rec)
	local sig = rec and (tostring(rec.uid) .. ":" .. tostring(rec.kind) .. ":" .. tostring(rec.cls) .. ":" .. tostring(rec.mut)) or nil
	if entry.sig == sig then return end
	entry.sig = sig
	if entry.golem then entry.golem:Destroy(); entry.golem = nil end
	if not rec then return end
	local m = GolemModel.build(rec.kind, rec.cls)
	if not m then return end
	m.Name = "MutGolem"
	local _, size = m:GetBoundingBox()
	local k = math.min(1, GOLEM_H / math.max(0.1, size.Y), GOLEM_W / math.max(0.1, math.max(size.X, size.Z)))
	if k < 0.999 then m:ScaleTo(m:GetScale() * k) end
	local pad = entry.pad
	local top = pad.Position + Vector3.new(0, pad.Size.Y / 2, 0)
	local side = entry.machine:GetPivot().RightVector
	local up = GolemModel.footOffset(m)
	local pos = top + Vector3.new(0, up, 0)
	-- обличчям уздовж конвеєра: големи на слотах дивляться на камеру, готовий на виході — далі по ходу (від камери)
	local look = side
	if entry.center then
		local d = Vector3.new(entry.center.X - pos.X, 0, entry.center.Z - pos.Z)
		if entry.outward then d = -d end
		if d.Magnitude > 0.05 then look = d.Unit end
	end
	m:PivotTo(CFrame.lookAt(pos, pos + look))
	m:SetAttribute("Mut", rec.mut)
	-- табличка: мутація і назва
	local root = m:FindFirstChild("Root") or m.PrimaryPart
	if root then
		local ht = GolemModel.headTop(m)
		local tag = new("BillboardGui", { Name = "MutTag", Size = UDim2.fromScale(5, 1.6), StudsOffsetWorldSpace = Vector3.new(0, ht + 1.1, 0),
			LightInfluence = 0, MaxDistance = 60, AlwaysOnTop = false }, root)
		local ml = new("TextLabel", { Size = UDim2.fromScale(1, 0.45), BackgroundTransparency = 1, FontFace = HEAVY, TextScaled = true,
			Text = mutKey(rec.mut), TextColor3 = mutColor(rec.mut) }, tag)
		stroke(ml, INK, 2, true)
		MutationText.apply(ml, rec.mut)
		local nl = new("TextLabel", { Position = UDim2.fromScale(0, 0.45), Size = UDim2.fromScale(1, 0.55), BackgroundTransparency = 1, FontFace = HEAVY,
			TextScaled = true, Text = golemName(rec), TextColor3 = WHITE }, tag)
		stroke(nl, INK, 2.5, true)
	end
	m.Parent = entry.machine
	entry.golem = m
end

local function setPrompt(pr: ProximityPrompt, vis: boolean, text: string, color: string, dis: boolean)
	if pr.Enabled ~= vis then pr.Enabled = vis end
	local hold = dis and NEVER or HOLD
	if pr.HoldDuration ~= hold then pr.HoldDuration = hold end
	if pr:GetAttribute("UIText") ~= text then pr:SetAttribute("UIText", text) end
	if pr:GetAttribute("UIColor") ~= color then pr:SetAttribute("UIColor", color) end
	if pr:GetAttribute("UIDisabled") ~= dis then pr:SetAttribute("UIDisabled", dis) end
end

local function heldGolem()
	local held = player:GetAttribute("InvHeld")
	if type(held) ~= "string" or string.sub(held, 1, 6) ~= "Golem_" then return nil, nil end
	local id = tonumber(string.sub(held, 7))
	for _, e in decode("InvGolems", {}) do if type(e) == "table" and e.id == id then return e, id end end
	return nil, id
end

local function applyPrompts(M, m)
	local ready = player:GetAttribute("MutReady") == true
	local done = isDone(m)
	local full = invFull()
	local other = firstRec(m)
	local g, gid = heldGolem()
	for s, e in M.slots do
		local rec = m.slots[tostring(s)]
		if not ready then setPrompt(e.prompt, false, "", "gray", true)
		elseif done then setPrompt(e.prompt, true, full and "INVENTORY FULL" or "CLAIM", full and "gray" or "green", full)
		elseif m.job then setPrompt(e.prompt, false, "", "gray", true) -- големи в камері (CANCEL — на панелі)
		elseif type(rec) == "table" then setPrompt(e.prompt, true, full and "INVENTORY FULL" or "TAKE", full and "gray" or "blue", full)
		elseif g then
			if table.find(decode("PlotPlaced", {}), gid) then setPrompt(e.prompt, true, "ON PLOT", "gray", true)
			elseif table.find(Catalog.EXCLUSIVES or {}, Catalog.id(g.kind) or g.kind) then setPrompt(e.prompt, true, "EXCLUSIVE", "gray", true) -- ексклюзиви не мутуються
			elseif Catalog.mut(g.mut) >= MutCfg.MAX_MUT then setPrompt(e.prompt, true, "MAX MUTATION", "gray", true)
			elseif other and not MutCfg.same(other, { kind = Catalog.id(g.kind) or g.kind, cls = Catalog.cls(g.cls), mut = Catalog.mut(g.mut) }) then
				setPrompt(e.prompt, true, "NOT THE SAME", "gray", true)
			else setPrompt(e.prompt, true, "PLACE", "green", false) end
		else
			setPrompt(e.prompt, true, "HOLD A GOLEM", "gray", true)
		end
	end
	if M.start then
		if ready and not m.job and count(m) == MutCfg.SLOTS then setPrompt(M.start, true, "START", "green", false)
		else setPrompt(M.start, false, "", "gray", true) end
	end
	if M.claim then
		if ready and done then setPrompt(M.claim, true, full and "INVENTORY FULL" or "CLAIM", full and "gray" or "green", full)
		else setPrompt(M.claim, false, "", "gray", true) end
	end
end

-- ===== заїзд у камеру (START) і виїзд назад (CANCEL) =====
local RIDE_SPEED = 7 -- стад/с
local function ride(g: Model, from: Vector3, to: Vector3)
	local dir = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if dir.Magnitude < 0.01 then return end
	local dur = math.max(0.4, dir.Magnitude / RIDE_SPEED)
	g:SetAttribute("State", "Walk")
	local t0 = os.clock()
	while g.Parent do
		local k = math.min(1, (os.clock() - t0) / dur)
		local e = k * k * (3 - 2 * k)
		local p = from:Lerp(to, e)
		g:PivotTo(CFrame.lookAt(p, p + dir))
		if k >= 1 then break end
		RunService.Heartbeat:Wait()
	end
	g:SetAttribute("State", "Idle")
end
local function chamberPoint(M, y: number): Vector3
	local c = M.center or M.model:GetPivot().Position
	return Vector3.new(c.X, y, c.Z)
end
local refreshAll
-- по черзі: найближчий до камери перший, доїжджає в центр і зникає
local function animIn(M)
	M.anim = true
	for s = MutCfg.SLOTS, 1, -1 do
		local e = M.slots[s]
		local g = e and e.golem
		if g then
			local from = g:GetPivot().Position
			ride(g, from, chamberPoint(M, from.Y))
			g:Destroy()
			e.golem = nil; e.sig = nil
			task.wait(0.12)
		end
	end
	M.anim = false
	refreshAll()
end
-- CANCEL: з камери по черзі виїжджають на свої слоти (спершу найдальший)
local function animOut(M, m)
	M.anim = true
	for s = 1, MutCfg.SLOTS do
		local e = M.slots[s]
		local rec = e and m.slots[tostring(s)]
		if type(rec) == "table" then
			golemOnPad(e, rec)
			local g = e.golem
			if g then
				local final = g:GetPivot()
				local start = chamberPoint(M, final.Position.Y)
				g:PivotTo(CFrame.new(start))
				ride(g, start, final.Position)
				-- плавно розвернутись обличчям уздовж конвеєра (як після постановки)
				local from = g.Parent and g:GetPivot()
				if from then
					local t0 = os.clock()
					while g.Parent do
						local k = math.min(1, (os.clock() - t0) / 0.3)
						g:PivotTo(from:Lerp(final, k * k * (3 - 2 * k)))
						if k >= 1 then break end
						RunService.Heartbeat:Wait()
					end
				end
				if g.Parent then g:PivotTo(final) end
			end
			task.wait(0.12)
		end
	end
	M.anim = false
	refreshAll()
end

local function applyMachine(M, m)
	local doneNow = isDone(m)
	local running = m.job ~= nil and not doneNow
	if not M.anim then
		if M.lastRun == false and running then task.spawn(animIn, M)
		elseif M.lastRun == true and m.job == nil and count(m) == MutCfg.SLOTS then task.spawn(animOut, M, m) end
	end
	M.lastRun = running
	for s, e in M.slots do
		local rec = m.slots[tostring(s)]
		if doneNow or m.job then rec = nil end -- големи в камері / вже злилися в одного на виході
		if not M.anim then golemOnPad(e, type(rec) == "table" and rec or nil) end
		local col = type(rec) == "table" and mutColor(rec.mut):Lerp(C("8a8f9e"), 0.35) or PAD_EMPTY
		if e.pad.Color ~= col then e.pad.Color = col end
	end
	-- вихід: мутація готова — на підставці голем з наступною мутацією
	if M.out then
		local r = firstRec(m)
		local res = (r and isDone(m)) and { uid = "out" .. tostring(r.uid), kind = r.kind, cls = r.cls, mut = math.min(MutCfg.MAX_MUT, r.mut + 1) } or nil
		golemOnPad(M.out, res)
		local col = res and mutColor(res.mut):Lerp(C("8a8f9e"), 0.35) or PAD_EMPTY
		if M.out.pad.Color ~= col then M.out.pad.Color = col end
	end
	applyPrompts(M, m)
end

local function setup(machine: Model)
	local index = machine:GetAttribute("MachineIndex")
	if type(index) ~= "number" or machines[index] then return end
	local M = { model = machine, slots = {}, screens = {} }
	for _, c in machine:GetChildren() do
		local si = c:GetAttribute("SlotIndex")
		if type(si) == "number" then
			local pad = c:WaitForChild("Pad", 10)
			local btn = c:WaitForChild("SlotButton", 10)
			local pr = btn and btn:WaitForChild("MutSlotPrompt", 10)
			if pad and pr then M.slots[si] = { machine = machine, slot = c, pad = pad, prompt = pr } end
		end
	end
	local core = machine:WaitForChild("Core", 10)
	if core then
		for _, d in core:GetChildren() do if d.Name == "Screen" then table.insert(M.screens, d) end end
		local tc = core:WaitForChild("TunnelCeil", 10)
		M.center = tc and tc.Position
	end
	for _, e in M.slots do e.center = M.center end -- напрям конвеєра для големів на слотах
	-- вихід: готовий голем стоїть тут, CLAIM
	local outM = machine:WaitForChild("Output", 10)
	if outM then
		local pad = outM:WaitForChild("Pad", 10)
		local cb = outM:WaitForChild("ClaimButton", 10)
		M.claim = cb and cb:WaitForChild("MutClaimPrompt", 10)
		if pad then M.out = { machine = machine, slot = outM, pad = pad, center = M.center, outward = true } end
	end
	local board = machine:WaitForChild("PanelBoard", 10)
	M.panels = board and { buildPanel(board, Enum.NormalId.Right, index), buildPanel(board, Enum.NormalId.Left, index) } or {}
	M.orb = machine:FindFirstChild("ReactorOrb", true)
	M.antenna = machine:FindFirstChild("AntennaTip", true)
	M.tips = {}
	for _, d in machine:GetDescendants() do if d.Name == "CoilTip" then table.insert(M.tips, d) end end
	if M.orb then
		M.fx = new("ParticleEmitter", { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 0, Lifetime = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(0.35, 0), LightEmission = 0.3,
			Color = ColorSequence.new(C("c58bff")), Transparency = NumberSequence.new(0.1, 1) }, M.orb)
	end
	M.nextBolt = os.clock() + math.random() * 2
	-- звуки котушки: тихі й тільки поблизу (3D-звук на антені реактора)
	local sfx = RS:WaitForChild("MutationSfx", 10)
	local host = M.antenna or M.orb
	if sfx and host then
		local function mk(name) local t = sfx:FindFirstChild(name); if t then local s = t:Clone(); s.Parent = host; return s end end
		M.hum = mk("Hum"); M.zapS = mk("ZapSmall"); M.zapB = mk("ZapBig")
	end
	machines[index] = M
end

function refreshAll()
	local st = stateOf()
	for i, M in machines do applyMachine(M, st[tostring(i)]) end
end

task.spawn(function()
	local hub = workspace:WaitForChild("Cave"):WaitForChild("Hub")
	local f = hub:WaitForChild("MutationMachines", 60)
	if not f then return end
	local function add(c) if c:IsA("Model") then task.spawn(function() setup(c); refreshAll() end) end end
	for _, c in f:GetChildren() do add(c) end
	f.ChildAdded:Connect(add)
end)

local WATCH = { MutMachines = true, InvHeld = true, InvGolems = true, PlotPlaced = true, MutReady = true, ExtraSlots = true, MutSpeedTier = true }
player.AttributeChanged:Connect(function(name)
	if name == "MutClaimT" then UISfx.play("BuySound") end
	if WATCH[name] then refreshAll() end
end)

-- ===== блискавки: від котушок до антени реактора (фіолетові, час від часу; під час мутації частіше) =====
local boltFolder = new("Folder", { Name = "MutationBolts" }, workspace)
local BOLT_COL = C("b46bff")
local function bolt(from: Vector3, to: Vector3)
	local parts = {}
	local n = 7
	local dir = to - from
	local side = dir:Cross(Vector3.new(0, 1, 0)); if side.Magnitude < 0.01 then side = Vector3.new(1, 0, 0) end
	side = side.Unit
	local up = side:Cross(dir).Unit
	local prev = from
	for k = 1, n do
		local u = k / n
		local p = from + dir * u
		if k < n then p += side * (math.random() - 0.5) * 1.2 + up * (math.random() - 0.5) * 1.2 + Vector3.new(0, math.sin(u * math.pi) * 1.2, 0) end
		local seg = Instance.new("Part")
		seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false; seg.CastShadow = false
		seg.Material = Enum.Material.Neon; seg.Color = BOLT_COL
		local len = (p - prev).Magnitude
		seg.Size = Vector3.new(0.12, 0.12, len + 0.06)
		seg.CFrame = CFrame.lookAt((prev + p) / 2, p)
		seg.Parent = boltFolder
		table.insert(parts, seg)
		prev = p
	end
	task.spawn(function()
		task.wait(0.1)
		for _, q in parts do q.Transparency = 0.7 end
		task.wait(0.05)
		for _, q in parts do q.Transparency = 0 end
		task.wait(0.12)
		for _, q in parts do q:Destroy() end
	end)
end

-- ===== панелі: таймер, статус, екрани (кожні 0,2 с) =====
local TITLE_PAL = { C("f2e6ff"), C("c58bff"), C("7a3cff"), C("c58bff") }
local function sample(P, u)
	local x = (u % 1) * #P
	local i = math.floor(x)
	local t = x - i
	t = t * t * (3 - 2 * t)
	return P[i + 1]:Lerp(P[(i + 1) % #P + 1], t)
end
local lastDone = {}
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	local clock = os.clock()
	local phase = -(clock / 4)
	local ks = {}
	for k = 0, 12 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 12, sample(TITLE_PAL, k / 12 * 2 + phase)) end
	local tseq = ColorSequence.new(ks)
	local st = stateOf()
	for i, M in machines do
		for _, P in M.panels do P.tg.Color = tseq end
		-- блискавки (лише поблизу камери)
		local cam = workspace.CurrentCamera
		if M.antenna and #M.tips > 0 and cam and (cam.CFrame.Position - M.antenna.Position).Magnitude < 150 and clock >= M.nextBolt then
			local m = st[tostring(i)]
			local busy = m and m.job ~= nil
			local tip = M.tips[math.random(1, #M.tips)]
			bolt(tip.Position, M.antenna.Position)
			if busy and math.random() < 0.5 then
				local tip2 = M.tips[math.random(1, #M.tips)]
				task.delay(0.08, function() bolt(tip2.Position, M.antenna.Position) end)
				if M.zapB then M.zapB.PlaybackSpeed = 0.92 + math.random() * 0.16; M.zapB:Play() end   -- великий розряд
			elseif M.zapS then
				M.zapS.PlaybackSpeed = 0.9 + math.random() * 0.2; M.zapS:Play()                         -- мала блискавка
			end
			M.nextBolt = clock + (busy and (0.4 + math.random() * 1.2) or (1.5 + math.random() * 3))
		end
	end
	acc += dt
	if acc < 0.2 then return end
	acc = 0
	local t = now()
	local tier = tonumber(player:GetAttribute("MutSpeedTier")) or 0
	local mult = MonCfg.mutSpeedMult(tier)
	local nextT = MonCfg.MUT_SPEED_TIERS[tier + 1]
	for i, M in machines do
		local m = st[tostring(i)]
		-- сталий гул — тільки поки йде мутація (скасування або завершення його зупиняють)
		if M.hum then
			local running = m and m.job ~= nil and MutCfg.progress(m.job, t) < 1
			if running and not M.hum.IsPlaying then M.hum:Play() elseif not running and M.hum.IsPlaying then M.hum:Stop() end
		end
		local r = firstRec(m)
		local n = count(m)
		local done = isDone(m)
		if lastDone[i] ~= nil and lastDone[i] ~= done then applyMachine(M, m) end
		lastDone[i] = done
		local canStart = (not m.job) and n == MutCfg.SLOTS
		local left, prog
		if m.job then
			-- таймер у часі машини: прискорення змушує цифри бігти швидше, а не обрізає час стрибком
			left = MutCfg.machineLeft(m.job, t); prog = MutCfg.progress(m.job, t)
		elseif r then
			left = MutCfg.duration(r.mut); prog = 0
		else
			left = nil; prog = 0
		end
		local bc = r and mutColor(math.min(MutCfg.MAX_MUT, r.mut + 1)) or C("6fd2ff")
		for _, P in M.panels do
			if done then
				P.status.Text = "READY!"; P.status.TextColor3 = C("7ef05a")
			elseif m.job then
				P.status.Text = "MUTATING..."; P.status.TextColor3 = C("c58bff")
			elseif canStart then
				P.status.Text = "PRESS START!"; P.status.TextColor3 = C("7ef05a")
			else
				local need = MutCfg.SLOTS - n
				P.status.Text = need == 1 and "ADD 1 MORE GOLEM" or ("ADD " .. need .. (n == 0 and " GOLEMS" or " MORE GOLEMS"))
				P.status.TextColor3 = WHITE
			end
			if r then
				local mk = mutKey(r.mut)
				P.added.Text = string.format('Added: %s · <font color="#%s">%s</font>  <font color="#e9edf1">[%d/%d]</font>',
					golemName(r), mutColor(r.mut):ToHex(), mk, n, MutCfg.SLOTS)
				local to = math.min(MutCfg.MAX_MUT, r.mut + 1)
				P.fromL.Text = mk; P.toL.Text = mutKey(to)
				-- назви мутацій — з тим самим переливом, що в інвентарі (Rainbow — веселка, Secret — блиск)
				if P.fromMut ~= r.mut then
					P.fromMut = r.mut
					MutationText.apply(P.fromL, r.mut)
					MutationText.apply(P.toL, to)
				end
				P.arrow.Visible = true
			else
				P.added.Text = "Put 3 same golems in the slots to get a better one!"
				P.fromL.Text = ""; P.toL.Text = ""; P.arrow.Visible = false
				if P.fromMut ~= nil then MutationText.clear(P.fromL); MutationText.clear(P.toL); P.fromMut = nil end
			end
			if done then
				P.timer.Text = "DONE!"; P.timerGrad.Color = cseq({ { 0, "e9ffd9" }, { 1, "7ef05a" } })
			elseif left then
				P.timer.Text = fmtLong(left)
				P.timerGrad.Color = m.job and cseq({ { 0, "e6fdff" }, { 1, "6fd2ff" } }) or cseq({ { 0, "ffffff" }, { 1, "c9ced5" } })
			else
				P.timer.Text = "--"; P.timerGrad.Color = cseq({ { 0, "ffffff" }, { 1, "c9ced5" } })
			end
			P.canStart = canStart
			P.startBtn.root.Visible = canStart; P.startSh.Visible = canStart
			P.barBack.Visible = not canStart
			local canCancel = m.job ~= nil and not done
			P.canCancel = canCancel
			P.cancelBtn.root.Visible = canCancel; P.cancelSh.Visible = canCancel
			if canCancel then
				P.barBack.Position = UDim2.fromOffset(270, 250); P.barBack.Size = UDim2.fromOffset(380, 30)
			else
				P.barBack.Position = UDim2.fromOffset(30, 250); P.barBack.Size = UDim2.fromOffset(620, 30)
			end
			P.pct.Size = UDim2.fromScale(1, 1)
			P.bar.Size = UDim2.fromScale(done and 1 or prog, 1)
			P.barGrad.Color = ColorSequence.new(bc:Lerp(WHITE, 0.35), bc)
			P.pct.Text = m.job and string.format("%d%%", math.floor((done and 1 or prog) * 100)) or ""
			P.speedCur.Text = nextT and ("SPEED x" .. mult .. "  •  " .. nextT.robux .. " R$") or ("SPEED x" .. mult)
			if nextT then
				P.canBuy = true
				P.btn:setText("x" .. nextT.mult .. " TIME")
				if P.btn.color ~= "purple" then P.btn:setColor("purple") end
			else
				P.canBuy = false
				P.btn:setText("MAX SPEED")
				if P.btn.color ~= "gray" then P.btn:setColor("gray") end
			end
		end
		-- екрани камери, реактор, частинки
		local sc
		if done then
			sc = bc:Lerp(WHITE, 0.25 + 0.25 * math.sin(os.clock() * 4))
		elseif m.job then
			sc = bc:Lerp(SCREEN_IDLE, 0.45 + 0.35 * math.sin(os.clock() * 2.5))
		else
			sc = SCREEN_IDLE
		end
		for _, s in M.screens do s.Color = sc end
		if M.orb then M.orb.Color = (m.job and bc or C("a24bff")):Lerp(C("2a1450"), 0.5 + 0.15 * math.sin(os.clock() * 3)) end
		if M.fx then M.fx.Rate = (m.job and not done) and 14 or 0 end
	end
end)
