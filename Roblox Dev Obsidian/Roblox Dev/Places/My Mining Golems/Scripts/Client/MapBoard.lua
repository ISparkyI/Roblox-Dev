-- MapBoard — табло «наступна мапа» на Niche*/Upgrade panels/Cave_Upgrade/screen (v1, 28.10.2026).
-- Де: StarterPlayer/StarterPlayerScripts/MapBoard (LocalScript). Стиль — як табло плотів (PlotBoard): SurfaceGui у PlayerGui з Adornee
--   на screen, сіра підкладка зі studs; референс — «Next Map Upgrade» (банер з %, множник, «You will lose», кнопка MAP N).
-- Умова переходу: 100 % прокачки плотів — середнє за картками PlotConfig.CARDS, відкритими на цій мапі
--   ((рівень − 1) / (max − 1)); рівні — атрибут власника ніші PlotLv (JSON), мапа — атрибут Stage.
-- Кнопка MAP N: лише своя ніша і лише в зоні перед екраном (ZONE_*: майданчик між стовпами); далеко — тост «Come closer».
--   САМ ПЕРЕХІД ЩЕ НЕ РЕАЛІЗОВАНИЙ (немає префаба другої мапи): на 100 % кнопка пише «Coming soon».
-- Екран будується, коли камера ближче BUILD_AT стадів (великий екран — видно з усієї ніші), прибирається далі DROP_AT. Грань — screen.ScreenFace (за замовчуванням Front).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("PlotConfig"))
local MultiCfg = require(RS.Shared:WaitForChild("MultiConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local StyleA = require(RS.Shared:WaitForChild("StyleA"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local LIME = C("d4ff3e")
local PINK = C("ff4fa8")
local GOLD = C("ffd23a")
local PH = 1000
-- зона натискання MAP N: прямокутник перед екраном (весь майданчик між стовпами табла)
local ZONE_DEPTH = 48 -- стадів від екрана вперед
local ZONE_HALF = 42 -- стадів вліво / вправо від центру екрана (екран 65 завширшки)
local ZONE_UP = 40 -- допуск по висоті
local BUILD_AT, DROP_AT = 600, 700 -- дальність прогрузки табла (від ролів і плотів теж видно)
-- назви мап (GDD - Maps)
local MAP_NAMES = { "Mossy Grotto", "Rusty Mine", "Crystal Depths", "Magma Caverns", "Frozen Abyss", "Void Core" }

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
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 6 }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, true) end
	return t
end
-- напис з переливом зверху вниз (як заголовки вікон)
local function gradText(t, top, bottom) new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(top), C(bottom)) }, t); return t end
local function stud(parent, x, y, cell, fill, shade, edge)
	local s = math.floor(cell * 0.62)
	local o = (cell - s) / 2
	local d = math.max(2, math.floor(s * 0.12 + 0.5))
	local r = math.max(3, math.floor(s * 0.16))
	local sh = frame(parent, x + o - d / 2, y + o + d / 2, s, s, shade); corner(sh, r)
	local st = frame(parent, x + o + d / 2, y + o - d / 2, s, s, fill); corner(st, r)
	if edge then stroke(st, edge, 2) end
end

-- рівні карток власника (PlotLv — JSON)
local function levelsOf(owner: Player?): { [string]: number }
	local raw = owner and owner:GetAttribute("PlotLv")
	if type(raw) == "string" then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(t) == "table" then return t end
	end
	return {}
end
-- прогрес прокачки плотів 0..1: середнє за відкритими картками
local function progressOf(owner: Player?): number
	if not owner then return 0 end
	local lv = levelsOf(owner)
	local stage = tonumber(owner:GetAttribute("Stage")) or 1
	local sum, n = 0, 0
	for _, key in Cfg.CARD_ORDER do
		local def = Cfg.CARDS[key]
		if def and Cfg.cardOpen(key, stage) and def.max > 1 and not def.optional then -- Auto Sell (optional) не рахується
			local l = math.clamp(math.floor(tonumber(lv[key]) or 1), 1, def.max)
			sum += (l - 1) / (def.max - 1); n += 1
		end
	end
	return n > 0 and sum / n or 0
end
local function multText(m: number): string
	if m >= 1e5 then return "x" .. NF.short(m) end
	return "x" .. (m == math.floor(m) and NF.full(m) or string.format("%g", math.floor(m * 100 + 0.5) / 100)) -- x1.5
end

local function buildPanel(niche: Model, screen: BasePart, ownerId: number)
	local mine = ownerId == player.UserId
	local PW = math.floor(PH * screen.Size.X / screen.Size.Y + 0.5)
	local g = new("SurfaceGui", { Name = "MapBoard_" .. niche.Name, Adornee = screen,
		Face = Enum.NormalId[screen:GetAttribute("ScreenFace") or "Front"], SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = PW / screen.Size.X, LightInfluence = 0, Brightness = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false, ClipsDescendants = true, MaxDistance = DROP_AT + 100 }, playerGui)
	local root = frame(g, 0, 0, PW, PH, C("8e939a"), { ClipsDescendants = true, Active = true })
	local PC = 56
	StyleA.studTile(root, 0, 0, PW, PH, PC, C("979ca3")) -- 03.11.2026: одна картинка-плитка замість сотень Frame-студів (StyleA.studTile)
	local shade = frame(root, 0, 0, PW, PH, WHITE, { ZIndex = 2, Active = false })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(BLACK),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.08, 1), NumberSequenceKeypoint.new(0.9, 1), NumberSequenceKeypoint.new(1, 0.8) }) }, shade)
	local pb = frame(root, 0, 0, PW, PH, nil, { BackgroundTransparency = 1, ZIndex = 20, Active = false }); stroke(pb, INK, 6)

	local X0, X1 = 150, PW - 150 -- робоча ширина
	local W = X1 - X0
	-- банер «NEXT MAP [N%]» — він же шкала прогресу (прокачка плотів): темна основа, жовто-помаранчеве заповнення зліва
	local BY, BH = 90, 170
	frame(root, X0, BY + 12, W, BH, BLACK, { BackgroundTransparency = 0.6, ZIndex = 3 })
	local banner = frame(root, X0, BY, W, BH, C("2a2e35"), { ZIndex = 4, ClipsDescendants = true })
	stroke(banner, INK, 8)
	local clip = frame(banner, 0, 0, 0, BH, nil, { BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5 })
	local fill = frame(clip, 0, 0, W, BH, WHITE, { ZIndex = 5 })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ffe066" }, { 0.55, "ffb21e" }, { 1, "ff7a1a" } }) }, fill)
	local A = StyleA.ASSETS or {}
	new("ImageLabel", { BackgroundTransparency = 1, Image = A.stylea_tile_yellow or A.stylea_tile_orange or "", ImageTransparency = 0.2,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(96, 96), Size = UDim2.fromScale(1, 1), ZIndex = 5 }, fill)
	frame(fill, 0, 8, W, 16, WHITE, { BackgroundTransparency = 0.65, ZIndex = 5 })
	local title = gradText(label(root, X0, BY, W, BH, 100, "NEXT MAP [0%]", WHITE, 9, { ZIndex = 7 }), "f4ffb0", "7ef05a")

	-- ліворуч під банером (03.11.2026): мала шкала ребітхів мапи — для переходу треба всі (MultiConfig.rebirthLimit), рожева як вікно REBIRTH
	local LW = 880
	local RBY, RBH = 286, 64
	frame(root, X0, RBY + 8, LW, RBH, BLACK, { BackgroundTransparency = 0.6, ZIndex = 3 })
	local rbar = frame(root, X0, RBY, LW, RBH, C("2a2e35"), { ZIndex = 4, ClipsDescendants = true })
	stroke(rbar, INK, 6)
	local rclip = frame(rbar, 0, 0, 0, RBH, nil, { BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5 })
	local rfill = frame(rclip, 0, 0, LW, RBH, WHITE, { ZIndex = 5 })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "ff9fd0" }, { 0.55, "ff4fa8" }, { 1, "d42a85" } }) }, rfill)
	frame(rfill, 0, 5, LW, 8, WHITE, { BackgroundTransparency = 0.65, ZIndex = 5 })
	local rbText = label(rbar, 0, 0, LW, RBH, 46, "REBIRTHS 0 / 5", WHITE, 6, { ZIndex = 7 })
	-- множник грошей мапи (зсунуто нижче під шкалу ребітхів)
	gradText(label(root, X0, 372, LW, 76, 66, "Money Multiplier", WHITE, 7, { TextXAlignment = Enum.TextXAlignment.Left }), "f4ffb0", "9be83a")
	-- текст у Roblox — не більше 100 px (навіть TextScaled), тому великий множник — напис 100 у рамці з UIScale
	local MK = 1.9
	local mbox = frame(root, X0, 440, LW / MK, 200 / MK, nil, { BackgroundTransparency = 1, ZIndex = 6 })
	new("UIScale", { Scale = MK }, mbox)
	local mult = gradText(label(mbox, 0, 0, LW / MK, 200 / MK, 100, "x1 → x2", WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left }), "f4ffb0", "7ef05a")
	local mapName = label(root, X0, 650, LW, 64, 52, "", WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left })
	local reqText = label(root, X0, 714, LW, 56, 40, "Max ALL plot upgrades & rebirths to unlock", C("e9edf1"), 5, { TextXAlignment = Enum.TextXAlignment.Left })

	-- праворуч: що втрачаємо (GDD - Maps)
	local RX = X0 + LW + 60
	local RW = X1 - RX
	gradText(label(root, RX, 280, RW, 90, 80, "You will lose:", WHITE, 7, { TextXAlignment = Enum.TextXAlignment.Left }), "ffc4e4", "ff3d9a")
	-- що НЕ втрачаємо (GDD - Maps): на табличці лише Exclusive големи й големи в Cave (зілля, Cave слоти, геймпас-стенди теж лишаються, але не пишемо)
	gradText(label(root, RX, 652, RW, 44, 38, "Exclusive & Cave golems are not deleted", WHITE, 4, { TextXAlignment = Enum.TextXAlignment.Left }), "fff1b8", "ffb21e")
	local LOSE = { "- All Money", "- All ores & bars", "- Golems not saved in the Cave", "- Plot & Workshop upgrades", "- Roll stands bought with Money" } -- геймпаси +1 Roll Stand і куплені Cave слоти лишаються
	for i, s in LOSE do
		gradText(label(root, RX, 366 + (i - 1) * 56, RW, 54, 46, s, WHITE, 6, { TextXAlignment = Enum.TextXAlignment.Left }), "ffc4e4", "ff3d9a")
	end
	-- кнопка MAP N (праворуч внизу)
	local bw, bh = 520, 130
	local bx, by = X1 - bw, 766
	local upLbl = label(root, bx - 40, by - 50, bw + 40, 48, 38, "Upgrade to Map 2", WHITE, 5)
	local shadow = frame(root, bx, by + 12, bw, bh, BLACK, { BackgroundTransparency = 0.65, ZIndex = 5 })
	local sa = StyleA.new(root, { size = Vector2.new(bw, bh), position = Vector2.new(bx, by), color = "gray", text = "MAP 2", textSize = 92, clickable = true, zIndex = 6 })
	StyleA.follow(sa, shadow)
	local hint = label(root, RX, by + 20, bx - RX - 30, bh - 40, 42, "", WHITE, 5, { TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = true })

	local pn = { gui = g, screen = screen, ownerId = ownerId, pct = 0, last = nil }
	local hintUntil = 0
	local function say(text: string, color: Color3?)
		hint.Text = text; hint.TextColor3 = color or WHITE
		hintUntil = os.clock() + 2.5
	end
	-- тост на екрані (як від адмін-панелі): AdminBroadcastClient слухає UIEvents/Toast
	local toastAt = 0
	local function screenToast(text: string, color: string, sound: string?)
		if os.clock() - toastAt < 1 then return end
		toastAt = os.clock()
		local ui = RS:FindFirstChild("UIEvents")
		local b = ui and ui:FindFirstChild("Toast")
		if b then b:Fire(text, color, sound) end
	end
	local function near(): boolean
		local ch = player.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end
		-- у системі екрана: вперед — нормаль грані з написом, вбік — X, вгору — Y
		local rel = screen.CFrame:PointToObjectSpace(hrp.Position)
		local face = Enum.NormalId[screen:GetAttribute("ScreenFace") or "Front"]
		local depth = rel:Dot(Vector3.FromNormalId(face))
		return depth > -4 and depth <= ZONE_DEPTH and math.abs(rel.X) <= ZONE_HALF and math.abs(rel.Y) <= ZONE_UP
	end
	if mine then
		StyleA.bind(sa, { hoverAlways = true, canClick = function() return pn.pct >= 1 and pn.rebOk == true and near() end, onClick = function()
			-- перехід на наступну мапу (сервер MapService перевіряє умови й скидає дані за GDD)
			local r = RS:FindFirstChild("Remotes")
			local ev = r and r:FindFirstChild("MapAction")
			if ev then ev:FireServer("Next") end
		end })
		sa.button.Activated:Connect(function()
			if not near() then screenToast("Come a bit closer to the board!", "red", "deny")
			elseif pn.pct < 1 then screenToast("Max all plot upgrades first!", "red", "deny")
			elseif not pn.rebOk then screenToast("Do all rebirths of this map first!", "red", "deny") end
		end)
	else
		sa.button.Active = false
		pcall(function() sa.button.Interactable = false end)
	end

	function pn.update(owner: Player?)
		local pct = progressOf(owner)
		pn.pct = pct
		local stage = owner and tonumber(owner:GetAttribute("Stage")) or 1
		local nextStage = stage + 1
		local p100 = math.floor(pct * 100 + 1e-6)
		title.Text = "NEXT MAP [" .. p100 .. "%]"
		clip.Size = UDim2.fromOffset(W * pct, BH)
		mult.Text = multText(MultiCfg.stageMult(stage)) .. " → " .. multText(MultiCfg.stageMult(nextStage))
		mapName.Text = "Map " .. nextStage .. " · " .. (MAP_NAMES[nextStage] or "???")
		upLbl.Text = "Upgrade to Map " .. nextStage
		sa:setText("MAP " .. nextStage)
		-- ребітхи цієї мапи: зроблено / ліміт (шкала — лише ребітхи цієї мапи: 0..5 на мапі 1, 5..8 на мапі 2 …)
		local reb = owner and (tonumber(owner:GetAttribute("Rebirths")) or 0) or 0
		local lim = MultiCfg.rebirthLimit(stage)
		local from = stage > 1 and MultiCfg.rebirthLimit(stage - 1) or 0
		local rp = math.clamp((reb - from) / math.max(1, lim - from), 0, 1)
		rclip.Size = UDim2.fromOffset(LW * rp, RBH)
		pn.rebOk = reb >= lim
		rbText.Text = (pn.rebOk and "✓ " or "") .. "REBIRTHS " .. math.min(reb, lim) .. " / " .. lim
		local ready = pct >= 1 and pn.rebOk
		reqText.Text = ready and "All upgrades & rebirths done!" or (pct >= 1 and "Do ALL rebirths of this map to unlock" or "Max ALL plot upgrades & rebirths to unlock")
		reqText.TextColor3 = ready and LIME or C("e9edf1")
		local close = mine and near()
		local col = (mine and ready and close) and "green" or "gray"
		if col ~= pn.last then sa:setColor(col); pn.last = col end
		if os.clock() > hintUntil then
			if not mine then hint.Text = owner and ("@" .. owner.Name .. "'s mine") or ""
			elseif ready and not close then hint.Text = "Come closer to the board!"; hint.TextColor3 = WHITE
			else hint.Text = "" end
		end
	end
	return pn
end

-- відповідь сервера на MAP N
task.spawn(function()
	local r = RS:WaitForChild("Remotes", 60)
	local ev = r and r:WaitForChild("MapAction", 60)
	if not ev then return end
	ev.OnClientEvent:Connect(function(kind, arg)
		local ui = RS:FindFirstChild("UIEvents")
		local b = ui and ui:FindFirstChild("Toast")
		if not b then return end
		if kind == "Done" then
			b:Fire("Welcome to Map " .. tostring(arg) .. " · " .. (MAP_NAMES[tonumber(arg) or 0] or "") .. "!", "green", "purchase")
		elseif kind == "Deny" then
			local t = arg == "soon" and "Next map is coming soon!" or arg == "plots" and "Max all plot upgrades first!"
				or arg == "rebirths" and "Do all rebirths of this map first!"
				or arg == "far" and "Come a bit closer to the board!" or "Can't move to the next map right now"
			b:Fire(t, arg == "soon" and "yellow" or "red", "deny")
		end
	end)
end)

local panels = {} -- [niche] = pn
local function refresh()
	local niches = workspace:FindFirstChild("Niches")
	if not niches then return end
	local camPos = camera.CFrame.Position
	for n, pn in panels do
		if not n:IsDescendantOf(workspace) or not pn.screen:IsDescendantOf(workspace) then pn.gui:Destroy(); panels[n] = nil end
	end
	for _, n in niches:GetChildren() do
		local ups = n:FindFirstChild("Upgrade panels")
		local board = ups and ups:FindFirstChild("Cave_Upgrade")
		local screen = board and board:FindFirstChild("screen")
		local ownerId = (n:GetAttribute("OwnerUserId") :: number?) or 0
		local dist = screen and (screen.Position - camPos).Magnitude or math.huge
		local pn = panels[n]
		local near = n:GetAttribute("LODNear") ~= false -- NicheLOD (03.11.2026): далека ніша — табло не будується й прибирається
		if pn and (not near or dist > DROP_AT or pn.ownerId ~= ownerId or pn.screen ~= screen) then pn.gui:Destroy(); panels[n] = nil; pn = nil end
		if not pn and near and screen and screen:IsA("BasePart") and dist < BUILD_AT then pn = buildPanel(n, screen, ownerId); panels[n] = pn end
		if pn then pn.update(ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil) end
	end
end

task.spawn(function()
	while true do
		local ok, err = pcall(refresh)
		if not ok then warn("MapBoard: " .. tostring(err)) end
		task.wait(0.3)
	end
end)
