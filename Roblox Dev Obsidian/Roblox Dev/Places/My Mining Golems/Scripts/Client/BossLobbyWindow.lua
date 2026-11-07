--!nonstrict
-- BossLobbyWindow — вікно порталу боса (реєстрація на бій). 04.11.2026, Plan - Boss Fight System §4.
-- Де: StarterPlayer/StarterPlayerScripts/BossLobbyWindow (LocalScript). Сервер — BossFightService, конфіг — Shared/BossConfig.
-- Відкривається, коли гравець стоїть у колі порталу (Cave/Hub/BossPortal/Ring/RingCenter), закривається, коли вийшов; хрестик —
--   до наступного входу в коло. Ліворуч — бос (ViewportFrame, крутиться й «дихає»), назва, що падає (зуби, діаманти).
--   Праворуч — статус фази (NEXT BOSS IN / REGISTRATION / FIGHT IN PROGRESS / SERVER FULL / Unlocks on Map 2), список
--   учасників сервера (Workspace.BossLobby: аватар, нік, іконки големів), твої слоти бійців (3 + 2 за геймпас BossSlots),
--   AUTO, JOIN FIGHT / LEAVE. Клік по слоту — вибір воїна з інвентаря (атрибут BossPicks; Remotes/BossAction "Pick").
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = RS:WaitForChild("Shared")
local Cfg = require(Shared:WaitForChild("BossConfig"))
local Catalog = require(Shared:WaitForChild("GolemCatalog"))
local MonCfg = require(Shared:WaitForChild("MonetizationConfig"))
local NF = require(Shared:WaitForChild("NumberFormat"))
local StyleA = require(Shared:WaitForChild("StyleA"))
local WindowFit = require(Shared:WaitForChild("WindowFit"))
local WindowManager = require(Shared:WaitForChild("WindowManager"))
local ItemViewport = require(Shared:WaitForChild("ItemViewport"))
local MutationText = require(Shared:WaitForChild("MutationText"))   -- 05.11.2026: назва мутації — анімований перелив (як в інвентарі)
local MutationSlotFX = require(Shared:WaitForChild("MutationSlotFX")) -- анімований фон слота за мутацією (як в інвентарі)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = RS:WaitForChild("Remotes")

local CANVAS_W, CANVAS_H = 1286, 740 -- 05.11.2026: розмір і місце — як усі вікна (SELL, DIAMONDS SHOP)
local WIN_X, WIN_Y, WIN_W, WIN_H = 40, 60, 1206, 650
local RING_R, EXIT_PAD = 13.8, 0.5
local SKULL = "rbxassetid://137113714883300"
local ROBUX = "rbxassetid://139687766069559"

local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SUB_TXT = C("e9edf1")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local RIM = { { 0, "5d636b" }, { 1, "3c4047" } }

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
local function stroke(o, color, th, tr, contextual)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0,
		LineJoinMode = contextual and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border }, o)
end
local function cseq(keys)
	local ks = {}
	for _, k in keys do table.insert(ks, ColorSequenceKeypoint.new(k[1], C(k[2]))) end
	return ColorSequence.new(ks)
end
local function label(parent, x, y, w, h, size, text, color, sw, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, FontFace = HEAVY,
		TextSize = size, Text = text, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw and sw > 0 then stroke(t, INK, sw, 0, true) end
	return t
end
local function img(parent, x, y, w, h, image, props)
	local i = new("ImageLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Image = image,
		ScaleType = Enum.ScaleType.Fit }, parent)
	if props then for k, v in props do i[k] = v end end
	return i
end
local function tween(o, t, style, dir, props)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end
local function box(parent, x, y, w, h, z, tr)
	local b = frame(parent, x, y, w, h, INK, { BackgroundTransparency = tr or 0.35, ZIndex = z or 4 })
	corner(b, 12); stroke(b, INK, 4)
	return b
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end
local function decode(s, default)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end
local function fmtLeft(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end
local function makeButton(parent, x, y, w, h, opt)
	local sh = frame(parent, x, y + (opt.shadowDy or 7), w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = opt.z })
	local b = StyleA.new(parent, { size = Vector2.new(w, h), position = Vector2.new(x, y), color = opt.color, text = opt.text,
		textSize = opt.textSize, icon = opt.icon, iconPad = opt.iconPad, clickable = true, shine = opt.shine, zIndex = opt.z + 1 })
	b.shadow = sh
	StyleA.follow(b, sh)
	b.onClick = nil
	b.canClick = nil
	StyleA.bind(b, { debounce = 0.25, canClick = function() if b.canClick then return b.canClick() end return true end,
		onClick = function() if b.onClick then b.onClick(b) end end })
	return b
end

-- ===== вікно (05.11.2026 v2: як DIAMONDS SHOP — той самий розмір і рамка, світлі studs, темні заокруглені блоки, картки з візерунком) =====
local gui = new("ScreenGui", { Name = "BossLobbyWindow", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10 }, playerGui)
local backdrop = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0,
	Active = true, Visible = false }, gui)
local modalRoot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, gui)
local fitScale = new("UIScale", {}, modalRoot)
local pop = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H), BackgroundTransparency = 1 }, modalRoot)
local popScale = new("UIScale", {}, pop)

-- рамка стилю A: та сама, що SELL / DIAMONDS SHOP (світлі studs, тінь лише по краях панелі)
frame(pop, WIN_X, WIN_Y + 14, WIN_W, WIN_H, BLACK, { BackgroundTransparency = 0.65, ZIndex = 1 })
local win = frame(pop, WIN_X, WIN_Y, WIN_W, WIN_H, WHITE, { ZIndex = 2 })
new("UIGradient", { Color = cseq(RIM), Rotation = 90 }, win); stroke(win, INK, 5)
stroke(frame(win, 6, 6, WIN_W - 12, WIN_H - 12, nil, { BackgroundTransparency = 1, ZIndex = 1 }), C("6a7078"), 1.5, 0.1)
do
	local pw, ph = WIN_W - 36, WIN_H - 36
	local panel = frame(win, 18, 18, pw, ph, C("a9aeb5"), { ZIndex = 2, ClipsDescendants = true }); stroke(panel, INK, 4)
	local CELL = 40
	local nx, ny = math.floor(pw / CELL), math.floor(ph / CELL)
	StyleA.studTile(frame(panel, 0, 0, pw, ph, nil, { BackgroundTransparency = 1, ZIndex = 1 }), (pw - nx * CELL) / 2, (ph - ny * CELL) / 2, nx * CELL, ny * CELL, CELL, C("b3b8bf"))
	local shade = frame(panel, 0, 0, pw, ph, WHITE, { ZIndex = 2 })
	new("UIGradient", { Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE), ColorSequenceKeypoint.new(1, WHITE) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1), NumberSequenceKeypoint.new(1, 0.82) }) }, shade)
end
local content = frame(win, 0, 0, WIN_W, WIN_H, nil, { BackgroundTransparency = 1, ZIndex = 3 })

-- заголовок: череп (−8°, тінь) + BOSS FIGHT з червоним переливом — метрики як у DIAMONDS SHOP
local TITLE_IS = 150
local TITLE_ICX, TITLE_ICY = 56 + TITLE_IS / 2, 44
local TITLE_X = TITLE_ICX + TITLE_IS / 2 + 8
-- 06.11.2026: іконка-шолом у заголовку — у 1,8 раза більша (текст лишається на місці; шолом виходить за край вікна вліво й угору)
local HEAD_IS = math.floor(TITLE_IS * 1.8)
local HEAD_X, HEAD_Y = TITLE_X - HEAD_IS / 2 + 14, TITLE_ICY - 26
new("ImageLabel", { BackgroundTransparency = 1, Image = SKULL, ImageColor3 = INK, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(HEAD_X, HEAD_Y + 9), Size = UDim2.fromOffset(HEAD_IS, HEAD_IS), Rotation = -8, ZIndex = 3 }, pop)
new("ImageLabel", { BackgroundTransparency = 1, Image = SKULL, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(HEAD_X, HEAD_Y), Size = UDim2.fromOffset(HEAD_IS, HEAD_IS), Rotation = -8, ZIndex = 4 }, pop)
label(pop, TITLE_X, 50 + 9 - 62, 900, 125, 104, "BOSS FIGHT", INK, 11, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
local title = label(pop, TITLE_X, 50 - 62, 900, 125, 104, "BOSS FIGHT", WHITE, 10, { TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
local titleGrad = new("UIGradient", { Rotation = 0 }, title)
local PAL = { C("ffe2e2"), C("ff6b6b"), C("d42a2a"), C("ff6b6b") }
local closeBtn = makeButton(pop, WIN_X + WIN_W - 86, WIN_Y - 42, 103, 103, { shadowDy = 10, color = "red", icon = StyleA.ASSETS.stylea_icon_x, iconPad = -0.05, z = 5 })

-- картка в стилі лотів DIAMONDS SHOP: градієнт кольору, візерунок StyleA, тінь донизу, відблиск зверху, чорна обводка
local function card(parent, x, y, w, h, col, tile, z)
	frame(parent, x, y + 10, w, h, BLACK, { BackgroundTransparency = 0.65, ZIndex = z })
	local c = frame(parent, x, y, w, h, WHITE, { ZIndex = z + 1, ClipsDescendants = true })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, col[1] }, { 1, col[2] } }) }, c); stroke(c, INK, 5)
	local A = StyleA.ASSETS
	new("ImageLabel", { BackgroundTransparency = 1, Image = A["stylea_tile_" .. tile .. "_half"] or A["stylea_tile_" .. tile] or A.stylea_tile_gray_half,
		ImageTransparency = 0.15, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(24, 24), Size = UDim2.fromScale(1, 1), ZIndex = 1 }, c)
	local shade = frame(c, 0, 0, w, h, BLACK, { ZIndex = 1 })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 0.6) }) }, shade)
	local gl = frame(c, 8, 8, w - 16, math.min(110, h * 0.35), WHITE, { ZIndex = 2 })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }) }, gl)
	return c
end

-- слот голема як в інвентарі: темний градієнт, чорна обводка, анімований фон за мутацією (MutationSlotFX)
local function darkSlot(parent, x, y, w, h, z)
	frame(parent, x, y + 6, w, h, BLACK, { BackgroundTransparency = 0.7, ZIndex = z })
	local c = frame(parent, x, y, w, h, WHITE, { ZIndex = z + 1, ClipsDescendants = true })
	new("UIGradient", { Rotation = 90, Color = cseq({ { 0, "2a2f36" }, { 1, "15181c" } }) }, c); stroke(c, INK, 4)
	local fx = MutationSlotFX.new(c, { pos = Vector2.zero, size = Vector2.new(w, h), z = 1 })
	return c, fx
end
local function mutLabel(lbl, mut) -- назва мутації: перелив MutationText; Normal — не пишемо
	local m = Catalog.mut(mut)
	if m > 0 then
		local d = Catalog.mutation(m)
		lbl.Visible = true; lbl.Text = d and string.upper(d.key) or ""
		MutationText.apply(lbl, m)
	else
		lbl.Visible = false; MutationText.clear(lbl)
	end
end

-- ліворуч: картка боса
local BX, BY, BW, BH = 40, 74, 380, 530
local bossBox = card(content, BX, BY, BW, BH, { "d9534f", "6e1a1a" }, "red", 4)
label(bossBox, 0, 10, BW, 34, 26, "WORLD BOSS", WHITE, 3.5, { ZIndex = 7 })
-- вʼюпорт — поверх картки, але не всередині неї (у картці ClipsDescendants)
local vp = new("ViewportFrame", { Position = UDim2.fromOffset(BX, BY + 40), Size = UDim2.fromOffset(BW, 290), BackgroundTransparency = 1, ZIndex = 8,
	Ambient = C("b8bec8"), LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, -0.6) }, content)
local vpCam = new("Camera", { FieldOfView = 34 }, vp)
vp.CurrentCamera = vpCam
local bossName = label(bossBox, 10, 330, BW - 20, 52, 44, tostring(select(2, Cfg.current()).name), C("b8ff8a"), 6, { ZIndex = 7 })
local drops = frame(bossBox, 22, 392, BW - 44, 74, INK, { BackgroundTransparency = 0.35, ZIndex = 6 })
corner(drops, 12); stroke(drops, INK, 4)
label(drops, 18, 0, 120, 74, 28, "DROPS", WHITE, 4, { ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Left })
img(drops, 150, 5, 64, 64, Cfg.ICON_TOOTH, { ZIndex = 7 })
img(drops, 232, 8, 58, 58, Cfg.ICON_DIAMOND, { ZIndex = 7 })
label(bossBox, 10, 474, BW - 20, 26, 21, "Dodge the red zones!", WHITE, 3, { ZIndex = 7 })
label(bossBox, 10, 498, BW - 20, 24, 18, "Only Warrior golems can fight", C("ffd2d2"), 2.5, { ZIndex = 7, FontFace = XBOLD })

-- модель боса для вʼюпорту (та сама блокова заглушка, що на арені)
local vpModel = new("Model", { Name = "BossPreview" }, vp)
do
	local function p(size, pos, col, neon)
		local b = new("Part", { Size = size, CFrame = CFrame.new(pos), Color = C(col), Anchored = true,
			Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic }, vpModel)
		return b
	end
	p(Vector3.new(3.4, 6, 3.4), Vector3.new(-3, 3, 0), "4f6b3a"); p(Vector3.new(3.4, 6, 3.4), Vector3.new(3, 3, 0), "465f33")
	p(Vector3.new(12, 8, 7), Vector3.new(0, 10, 0), "6e8f4b"); p(Vector3.new(8, 4.4, 0.6), Vector3.new(0, 9.6, -3.7), "8a6a44")
	p(Vector3.new(3.4, 8.6, 3.4), Vector3.new(-7.8, 9.6, 0), "5c7a40"); p(Vector3.new(3.4, 8.6, 3.4), Vector3.new(7.8, 9.6, 0), "5c7a40")
	p(Vector3.new(4.4, 3.2, 4.4), Vector3.new(-7.8, 4.4, 0), "7c858f"); p(Vector3.new(4.4, 3.2, 4.4), Vector3.new(7.8, 4.4, 0), "7c858f")
	p(Vector3.new(7, 5.6, 6), Vector3.new(0, 16.8, 0), "7fa456")
	p(Vector3.new(4.4, 1.6, 1.2), Vector3.new(-5.4, 17.6, 0), "7fa456"); p(Vector3.new(4.4, 1.6, 1.2), Vector3.new(5.4, 17.6, 0), "7fa456")
	p(Vector3.new(1.4, 1, 0.4), Vector3.new(-1.5, 17.6, -3.1), "ffd84a", true); p(Vector3.new(1.4, 1, 0.4), Vector3.new(1.5, 17.6, -3.1), "ffd84a", true)
	p(Vector3.new(3.8, 0.9, 0.4), Vector3.new(0, 15.4, -3.1), "3a2a22")
	p(Vector3.new(0.6, 1, 0.5), Vector3.new(-1.2, 16.1, -3.2), "fff4d6"); p(Vector3.new(0.6, 1, 0.5), Vector3.new(1.2, 16.1, -3.2), "fff4d6")
	p(Vector3.new(3.6, 1.4, 4), Vector3.new(-4.6, 14.4, 0), "9aa3ad"); p(Vector3.new(3.6, 1.4, 4), Vector3.new(4.6, 14.4, 0), "9aa3ad")
	p(Vector3.new(1, 1, 0.3), Vector3.new(-2.6, 11.4, -3.6), "ff4f6b", true); p(Vector3.new(1, 1, 0.3), Vector3.new(2.8, 8.2, -3.6), "ff4f6b", true)
	local root = p(Vector3.new(1, 1, 1), Vector3.new(0, 10, 0), "000000"); root.Transparency = 1
	vpModel.PrimaryPart = root
end
vpCam.CFrame = CFrame.lookAt(Vector3.new(0, 13, -46), Vector3.new(0, 10, 0))
-- 06.11.2026: у вʼюпорті — справжній GOBKING (копія префаба: ReplicatedStorage/BossPreview/Gobking); немає копії — заглушка вище
local VP_Y, VP_ROT, VP_B = 10, math.pi, 0.35
do
	local store = RS:FindFirstChild("BossPreview")
	local src = store and store:FindFirstChild("Gobking")
	if src and src:IsA("Model") then
		vpModel:Destroy()
		vpModel = src:Clone()
		for _, d in vpModel:GetDescendants() do if d:IsA("Trail") or d:IsA("LuaSourceContainer") then d:Destroy() end end
		vpModel:PivotTo(CFrame.identity)
		vpModel.Parent = vp
		local bb, size = vpModel:GetBoundingBox()
		local cy = bb.Position.Y
		VP_Y, VP_ROT, VP_B = 0, 0, size.Y * 0.008
		vpCam.CFrame = CFrame.lookAt(Vector3.new(0, cy + size.Y * 0.06, -size.Y * 2.2), Vector3.new(0, cy + size.Y * 0.03, 0)) -- з запасом: корона й ступні не обрізаються
	end
end
-- 05.11.2026: на телефонах (дотик без клавіатури, менша сторона екрана < 600) бос — запечена картинка з IconAtlas.BOSS
--   замість 3D-в’юпорту (атлас ще не завантажено — лишається 3D)
do
	local UIS = game:GetService("UserInputService")
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1000, 1000)
	local phone = UIS.TouchEnabled and not UIS.KeyboardEnabled and math.min(v.X, v.Y) < 600
	local okA, Atlas = pcall(require, RS:WaitForChild("Shared"):WaitForChild("IconAtlas"))
	local b = okA and Atlas.BOSS
	local aid = b and Atlas.ATLAS[b[1]]
	if phone and type(aid) == "string" and aid ~= "" then
		new("ImageLabel", { Name = "BossImage", Position = vp.Position, Size = vp.Size, BackgroundTransparency = 1, ZIndex = 8, Image = aid,
			ImageRectOffset = Vector2.new(b[2], b[3]), ImageRectSize = Vector2.new(b[4], b[5]), ScaleType = Enum.ScaleType.Fit }, content)
		vp.Visible = false
	end
end

-- праворуч: статус, учасники (2 × 3), слоти, кнопки
local RX, RW = 440, WIN_W - 40 - 440
local statusBox = box(content, RX, 74, RW, 64, 4)
img(statusBox, 10, 6, 52, 52, SKULL, { ZIndex = 5 })
-- переклад: статус і FIGHTERS — RichText з таймером, автопереклад їх не ловить → AutoLocalize = false і Shared/Loc
local Loc = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Loc"))
local statusTxt = label(statusBox, 72, 0, RW - 260, 64, 34, "", WHITE, 4, { ZIndex = 5, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, AutoLocalize = false })
local fightersHdr = label(statusBox, RW - 250, 0, 234, 64, 26, "", C("ffd2d2"), 3.5, { ZIndex = 5, TextXAlignment = Enum.TextXAlignment.Right, RichText = true, AutoLocalize = false })

local FB_Y, FB_H = 152, 214
local fightersBox = box(content, RX, FB_Y, RW, FB_H, 4)
local ROW_W, ROW_H, ROW_GX, ROW_GY = (RW - 30) / 2, 60, 10, 8
local rowsHolder = frame(fightersBox, 10, (FB_H - (3 * ROW_H + 2 * ROW_GY)) / 2, RW - 20, 3 * ROW_H + 2 * ROW_GY, nil, { BackgroundTransparency = 1, ZIndex = 5 })
local rows = {}
for i = 1, Cfg.MAX_PLAYERS do
	local col, rowN = (i - 1) % 2, (i - 1) // 2
	local r = frame(rowsHolder, col * (ROW_W + ROW_GX), rowN * (ROW_H + ROW_GY), ROW_W, ROW_H, WHITE, { BackgroundTransparency = 0.88, ZIndex = 5 })
	corner(r, 10); local st = stroke(r, INK, 3)
	local av = img(r, 8, 8, 44, 44, "", { ZIndex = 6, BackgroundTransparency = 0, BackgroundColor3 = C("c98a4a"), Visible = false })
	corner(av, 22); stroke(av, INK, 2.5)
	local nm = label(r, 60, 0, ROW_W - 72, ROW_H, 22, "", WHITE, 3, { ZIndex = 6, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
	local icons = {}
	local IC, IG = 34, 3
	local ix0 = ROW_W - 8 - (Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS) * (IC + IG) + IG
	for k = 1, Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS do
		local cell = frame(r, ix0 + (k - 1) * (IC + IG), (ROW_H - IC) / 2, IC, IC, C("2b2f38"), { ZIndex = 6, Visible = false })
		corner(cell, 8); stroke(cell, INK, 2)
		icons[k] = { cell = cell, im = img(cell, 1, 1, IC - 2, IC - 2, "", { ZIndex = 7 }), key = nil }
	end
	local empty = label(r, 0, 0, ROW_W, ROW_H, 20, "Empty slot", C("f2f4f6"), 2.5, { ZIndex = 6, FontFace = XBOLD, TextTransparency = 0.25 })
	rows[i] = { f = r, st = st, av = av, nm = nm, icons = icons, empty = empty, uid = nil }
end

label(content, RX + 4, 374, 400, 30, 26, "YOUR WARRIORS", WHITE, 4, { ZIndex = 5, TextXAlignment = Enum.TextXAlignment.Left })
label(content, RX + RW - 404, 374, 400, 30, 19, "Tap a slot to choose", C("f2f4f6"), 3, { ZIndex = 5, TextXAlignment = Enum.TextXAlignment.Right, FontFace = XBOLD })
local NS = Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS
local SLOT_GAP = 12
local SLOT_W, SLOT_H = math.floor((RW - (NS - 1) * SLOT_GAP) / NS), 118
local slots = {}
for i = 1, NS do
	local x = RX + (i - 1) * (SLOT_W + SLOT_GAP)
	local c, fx = darkSlot(content, x, 410, SLOT_W, SLOT_H, 4)
	local s = new("ImageButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 9 }, c)
	local ic = img(c, 14, 22, SLOT_W - 28, SLOT_H - 50, "", { ZIndex = 6 })
	local pw = label(c, 0, SLOT_H - 30, SLOT_W, 26, 20, "", C("ffb3b3"), 3, { ZIndex = 7 })
	local plus = label(c, 0, 0, SLOT_W, SLOT_H, 64, "+", WHITE, 5, { ZIndex = 6, TextTransparency = 0.15 })
	local mut = label(c, 0, 3, SLOT_W, 20, 17, "", WHITE, 2.5, { ZIndex = 7, Visible = false })
	local lock = frame(c, 0, 0, SLOT_W, SLOT_H, C("1b1d22"), { ZIndex = 8, BackgroundTransparency = 0.25, Visible = false })
	local lt = label(lock, 0, 14, SLOT_W, 36, 24, "LOCKED", WHITE, 4, { ZIndex = 8 })
	-- 05.11.2026: 4-й слот — за діаманти (Cfg.DIA_SLOT_PRICE), 5-й — геймпас +1 Boss Slot (Robux)
	local dia = i == Cfg.BASE_SLOTS + 1
	local pwid = dia and 124 or 96
	local pr = frame(lock, (SLOT_W - pwid) / 2, 60, pwid, 40, INK, { BackgroundTransparency = 0.3, ZIndex = 8 }); corner(pr, 10)
	img(pr, 8, 5, 30, 30, dia and Cfg.ICON_DIAMOND or ROBUX, { ZIndex = 8 })
	label(pr, 42, 0, pwid - 46, 40, dia and 23 or 26, dia and NF.full(Cfg.DIA_SLOT_PRICE) or tostring(((MonCfg.Passes or {}).BossSlots or {}).robux or 79),
		dia and C("8fe0ff") or WHITE, 3.5, { ZIndex = 8, TextXAlignment = Enum.TextXAlignment.Left })
	slots[i] = { b = s, ic = ic, pw = pw, plus = plus, mut = mut, lock = lock, fx = fx, lt = lt, armed = 0 }
end

local autoBtn = makeButton(content, RX, 540, 220, 70, { color = "gray", text = "AUTO", textSize = 34, z = 6 })
local joinBtn = makeButton(content, RX + 236, 540, RW - 236, 70, { color = "green", text = "JOIN FIGHT", textSize = 38, z = 6 })

-- закрито до мапи 2
-- 05.11.2026: TextButton, а не Frame — перехоплює натискання (раніше кнопки під ним клікались)
-- 05.11.2026 v3: затемнення на всю панель вікна (і картку боса), прямі кути
local LK_W, LK_H = WIN_W - 36, WIN_H - 36
local lockAll = new("TextButton", { Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(LK_W, LK_H), BackgroundColor3 = BLACK, BorderSizePixel = 0,
	BackgroundTransparency = 0.12, ZIndex = 30, Visible = false, Active = true, AutoButtonColor = false, Text = "" }, content)
label(lockAll, 0, 190, LK_W, 110, 96, "LOCKED", WHITE, 10, { ZIndex = 31 })
label(lockAll, 0, 306, LK_W, 50, 40, "Unlocks on Map " .. Cfg.MIN_STAGE, C("ffd2d2"), 5, { ZIndex = 31 })
label(lockAll, 0, 362, LK_W, 40, 28, "Roll Warrior golems to fight the boss", C("e9edf1"), 4, { ZIndex = 31, FontFace = XBOLD })

-- ===== вибір воїна =====
-- 05.11.2026 v3: світла панель зі studs (як саме вікно), заголовок і кнопки — нижче назви вікна (не налазять), хрестик вікна закриває вибір
local PK_W, PK_H = WIN_W - 36, WIN_H - 36
local picker = new("TextButton", { Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(PK_W, PK_H), BackgroundColor3 = C("a9aeb5"), BorderSizePixel = 0,
	ZIndex = 40, Visible = false, Active = true, AutoButtonColor = false, Text = "", ClipsDescendants = true }, content)
do
	local CELL = 40
	local nx, ny = math.floor(PK_W / CELL), math.floor(PK_H / CELL)
	StyleA.studTile(frame(picker, 0, 0, PK_W, PK_H, nil, { BackgroundTransparency = 1, ZIndex = 40 }), (PK_W - nx * CELL) / 2, (PK_H - ny * CELL) / 2, nx * CELL, ny * CELL, CELL, C("b3b8bf"))
	local shade = frame(picker, 0, 0, PK_W, PK_H, WHITE, { ZIndex = 40 })
	new("UIGradient", { Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BLACK), ColorSequenceKeypoint.new(0.5, BLACK), ColorSequenceKeypoint.new(0.501, WHITE), ColorSequenceKeypoint.new(1, WHITE) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.07, 1), NumberSequenceKeypoint.new(0.93, 1), NumberSequenceKeypoint.new(1, 0.82) }) }, shade)
end
local pickHead = box(picker, 22, 56, 680, 64, 41)
label(pickHead, 20, 0, 640, 64, 36, "CHOOSE A WARRIOR", WHITE, 5, { ZIndex = 42, TextXAlignment = Enum.TextXAlignment.Left })
local pickRemove = makeButton(picker, 718, 56, 200, 64, { color = "gray", text = "REMOVE", textSize = 30, z = 42, shadowDy = 6 })
local pickClose = makeButton(picker, 934, 56, 214, 64, { color = "red", text = "BACK", textSize = 30, z = 42, shadowDy = 6 })
local pickScroll = new("ScrollingFrame", { Position = UDim2.fromOffset(22, 136), Size = UDim2.fromOffset(PK_W - 36, PK_H - 150), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = INK, ZIndex = 41, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, picker)
new("UIGridLayout", { CellSize = UDim2.fromOffset(170, 222), CellPadding = UDim2.fromOffset(14, 14), SortOrder = Enum.SortOrder.LayoutOrder }, pickScroll)
new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }, pickScroll)
local pickEmpty = label(picker, 0, 300, PK_W, 60, 36, "You have no Warrior golems yet", WHITE, 5, { ZIndex = 41 })
local pickSlot = 0

-- ===== стан =====
local function picks(): { number }
	local t = decode(player:GetAttribute("BossPicks"), {})
	local out = {}
	for i = 1, Cfg.BASE_SLOTS + Cfg.EXTRA_SLOTS do out[i] = tonumber(t[i]) or 0 end
	return out
end
local function warriors(): { any }
	local inv = decode(player:GetAttribute("InvGolems"), {})
	local placed = decode(player:GetAttribute("PlotPlaced"), {})
	local list = {}
	for _, g in inv do
		if type(g) == "table" and Catalog.cls(g.cls) == "warrior" and Catalog.get(g.kind) and not table.find(placed, g.id) then
			table.insert(list, g)
		end
	end
	table.sort(list, function(a, b) return Catalog.power(a.kind, "warrior", a.mut, player) > Catalog.power(b.kind, "warrior", b.mut, player) end)
	return list
end
local function byId(): { [number]: any }
	local m = {}
	for _, g in warriors() do m[g.id] = g end
	return m
end
local function iconKey(kind, mut) return ItemViewport.golemKey(Catalog.id(kind) or kind, "warrior") end
local setMut = mutLabel

local inLobby = false
local thumbCache = {}
local function thumb(uid: number, im: ImageLabel)
	if thumbCache[uid] then im.Image = thumbCache[uid]; return end
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok and url then thumbCache[uid] = url; im.Image = url end
	end)
end

local function refresh()
	local t = workspace:GetServerTimeNow()
	local ph = workspace:GetAttribute("BossPhase") or "idle"
	local phEnd = tonumber(workspace:GetAttribute("BossPhaseEnd")) or 0
	local at = tonumber(workspace:GetAttribute("BossAt")) or 0
	local lob = decode(workspace:GetAttribute("BossLobby"), {})
	inLobby = false
	for _, e in lob do if e.u == player.UserId then inLobby = true end end
	local full = #lob >= Cfg.MAX_PLAYERS and not inLobby
	if ph == "reg" then
		statusTxt.Text = Loc.t(full and "SERVER FULL" or "REGISTRATION") .. ' <font color="#ff8a8a">' .. fmtLeft(phEnd - t) .. "</font>"
	elseif ph == "fight" then
		statusTxt.Text = Loc.t("FIGHT IN PROGRESS") .. ' <font color="#ff8a8a">' .. fmtLeft(phEnd - t) .. "</font>"
	elseif ph == "results" then
		statusTxt.Text = Loc.t("FIGHT IS ENDING…")
	else
		statusTxt.Text = Loc.t("NEXT BOSS IN") .. ' <font color="#ffd2d2">' .. fmtLeft(at - t) .. "</font>"
	end
	-- учасники
	fightersHdr.Text = Loc.t("FIGHTERS") .. ' <font color="#ffffff">' .. #lob .. " / " .. Cfg.MAX_PLAYERS .. "</font>"
	table.sort(lob, function(a, b) return (a.u == player.UserId) and b.u ~= player.UserId end)
	for i, r in rows do
		local e = lob[i]
		r.empty.Visible = e == nil
		r.av.Visible = e ~= nil
		r.nm.Visible = e ~= nil
		if e == nil then
			r.f.BackgroundColor3 = WHITE; r.f.BackgroundTransparency = 0.88; r.uid = nil
			for _, ic in r.icons do ic.cell.Visible = false end
		else
			local me = e.u == player.UserId
			r.f.BackgroundColor3 = me and C("3cb043") or INK
			r.f.BackgroundTransparency = me and 0.3 or 0.35
			r.nm.Text = me and "You" or tostring(e.n)
			if r.uid ~= e.u then r.uid = e.u; r.av.Image = ""; thumb(e.u, r.av) end
			for _, ic in r.icons do ic.cell.Visible = false end -- 06.11.2026: у рядку лише аватарка й нік (без іконок големів)
		end
	end
	-- слоти
	local pk = picks()
	local inv = byId()
	for i, s in slots do
		local locked = not Cfg.slotOpen(player, i)
		if s.lt then s.lt.Text = (os.clock() - s.armed < 3) and "BUY?" or "LOCKED"; s.lt.TextColor3 = (os.clock() - s.armed < 3) and C("b8ff8a") or WHITE end
		s.lock.Visible = locked
		local g = (not locked) and pk[i] ~= 0 and inv[pk[i]] or nil
		s.plus.Visible = not locked and g == nil
		s.ic.Visible = g ~= nil
		s.pw.Text = ""
		if g then
			local key = iconKey(g.kind, g.mut)
			if s.key ~= key then s.key = key; pcall(ItemViewport.set, s.ic, key, 1.1) end
			local st = Catalog.stats(g.kind, "warrior", g.mut, player)
			s.pw.Text = "⚔ " .. NF.short(st.dmg or 0)
			setMut(s.mut, g.mut)
			s.fx.setMut(Catalog.mut(g.mut)); s.fx.setOn(Catalog.mut(g.mut) > 0)
		else
			s.key = nil; setMut(s.mut, 0); s.fx.setOn(false)
		end
	end
	-- кнопки
	local stageOk = (tonumber(player:GetAttribute("Stage")) or 1) >= Cfg.MIN_STAGE
	lockAll.Visible = not stageOk
	local hasPick = false
	for i = 1, #slots do if Cfg.slotOpen(player, i) and pk[i] ~= 0 and inv[pk[i]] then hasPick = true end end
	if inLobby then
		joinBtn:setColor("red"); joinBtn:setText("LEAVE")
	else
		joinBtn:setColor((ph == "reg" and hasPick and not full) and "green" or "gray"); joinBtn:setText("JOIN FIGHT")
	end
end

local function lockedOut(): boolean -- до мапи 2 нічого не натискається
	if (tonumber(player:GetAttribute("Stage")) or 1) >= Cfg.MIN_STAGE then return false end
	toast("Boss fights unlock on Map " .. Cfg.MIN_STAGE .. "!", "red", "deny")
	return true
end
joinBtn.onClick = function()
	if lockedOut() then return end
	if inLobby then remotes.BossAction:FireServer("Leave"); return end
	local ph = workspace:GetAttribute("BossPhase")
	if ph ~= "reg" then toast(ph == "fight" and "The fight is in progress. Wait for the next boss!" or "Registration opens 1 minute before the boss", "gray"); return end
	local pk, inv, any = picks(), byId(), false
	for i = 1, #slots do if Cfg.slotOpen(player, i) and pk[i] ~= 0 and inv[pk[i]] then any = true end end
	if not any then toast("Choose at least 1 Warrior golem!", "red"); return end
	remotes.BossAction:FireServer("Join")
end
autoBtn.onClick = function()
	if lockedOut() then return end
	if #warriors() == 0 then toast("You have no Warrior golems yet!", "red"); return end
	remotes.BossAction:FireServer("Auto")
end

local function openPicker(i: number)
	pickSlot = i
	for _, c in pickScroll:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	local list = warriors()
	local pk = picks()
	pickEmpty.Visible = #list == 0
	pickRemove.root.Visible = pk[i] ~= 0
	for n, g in list do
		local used = table.find(pk, g.id)
		-- слот як в інвентарі: зверху мутація (перелив), голем, назва, сила й HP; знизу — у якому слоті вже стоїть
		local cell = frame(pickScroll, 0, 0, 170, 222, nil, { BackgroundTransparency = 1, LayoutOrder = n, ZIndex = 41 })
		local card, fx = darkSlot(cell, 0, 0, 170, 214, 41)
		local mu = Catalog.mut(g.mut)
		fx.setMut(mu); fx.setOn(mu > 0)
		if used == i then stroke(frame(cell, -2, -2, 174, 218, nil, { BackgroundTransparency = 1, ZIndex = 48 }), C("c8ff6a"), 4) end
		local btn = new("ImageButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 49 }, card)
		local ml = label(card, 0, 4, 170, 22, 18, "", WHITE, 2.5, { ZIndex = 44, Visible = false })
		mutLabel(ml, g.mut)
		local ic = img(card, 20, 26, 130, 104, "", { ZIndex = 43 })
		pcall(ItemViewport.set, ic, iconKey(g.kind, g.mut), 1.1)
		local def = Catalog.get(g.kind)
		label(card, 6, 132, 158, 26, 20, def and def.name or tostring(g.kind), WHITE, 3, { ZIndex = 43, TextTruncate = Enum.TextTruncate.AtEnd })
		local st = Catalog.stats(g.kind, "warrior", g.mut, player)
		label(card, 6, 158, 158, 24, 19, "⚔ " .. NF.short(st.dmg or 0) .. "   ❤ " .. NF.short(st.hp or 0), C("f2f4f6"), 3, { ZIndex = 43 })
		if used then
			label(card, 6, 184, 158, 24, 18, used == i and "THIS SLOT" or ("IN SLOT " .. used), used == i and C("c8ff6a") or C("ffd84a"), 3, { ZIndex = 44 })
		end
		btn.Activated:Connect(function()
			StyleA.tap()
			remotes.BossAction:FireServer("Pick", pickSlot, g.id)
			picker.Visible = false
		end)
	end
	picker.Visible = true
end
pickClose.onClick = function() picker.Visible = false end
pickRemove.onClick = function() remotes.BossAction:FireServer("Pick", pickSlot, 0); picker.Visible = false end
for i, s in slots do
	s.b.Activated:Connect(function()
		if lockedOut() then return end
		if not Cfg.slotOpen(player, i) and i == Cfg.BASE_SLOTS + 1 then
			-- 4-й слот за діаманти: перший тап — «BUY?», другий (за 3 с) — купити
			local d = tonumber(player:GetAttribute("Diamonds")) or 0
			if d < Cfg.DIA_SLOT_PRICE then toast("Not enough Diamonds! Need " .. NF.full(Cfg.DIA_SLOT_PRICE), "red", "deny"); return end
			if os.clock() - s.armed > 3 then s.armed = os.clock(); StyleA.tap(); refresh(); return end
			s.armed = 0
			remotes.BossAction:FireServer("BuySlot")
			return
		end
		if not Cfg.slotOpen(player, i) then
			local def = (MonCfg.Passes or {}).BossSlots
			if def and def.id and def.id ~= 0 then
				pcall(function() MarketplaceService:PromptGamePassPurchase(player, def.id) end)
			else toast("Coming soon!", "gray") end
			return
		end
		if inLobby and workspace:GetAttribute("BossPhase") ~= "reg" then return end
		StyleA.tap()
		openPicker(i)
	end)
end

-- ===== відкриття / закриття =====
local isOpen, dismissed, animToken = false, false, 0
local function fitWin() WindowFit.place(modalRoot, fitScale, { canvasW = CANVAS_W, canvasH = CANVAS_H, winX = WIN_X, winY = WIN_Y, winW = WIN_W, winH = WIN_H }) end
local camConn
local function bindCamera()
	if camConn then camConn:Disconnect(); camConn = nil end
	local cam = workspace.CurrentCamera
	if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitWin) end
	fitWin()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fitWin) end)
bindCamera()

local function open()
	isOpen = true
	WindowManager.opened("BossLobby")
	animToken += 1
	local my = animToken
	fitWin(); refresh()
	picker.Visible = false
	backdrop.Visible = true; modalRoot.Visible = true
	backdrop.BackgroundTransparency = 1
	popScale.Scale = 0.85
	tween(backdrop, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { BackgroundTransparency = 0.45 })
	tween(popScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1.05 }).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and animToken == my then tween(popScale, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, { Scale = 1 }) end
	end)
end
local function close()
	if not isOpen then return end
	isOpen = false
	animToken += 1
	local my = animToken
	tween(popScale, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.85 })
	tween(backdrop, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 }).Completed:Connect(function()
		if animToken ~= my then return end
		backdrop.Visible = false; modalRoot.Visible = false
	end)
end
closeBtn.onClick = function() if picker.Visible then picker.Visible = false; return end dismissed = true; close() end
WindowManager.register("BossLobby", function() return isOpen end, function() dismissed = true; close() end)
CAS:BindActionAtPriority("BossLobbyEsc", function(_, state)
	if state == Enum.UserInputState.Begin and isOpen then
		if picker.Visible then picker.Visible = false else dismissed = true; close() end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape)

-- анімація: перелив заголовка, бос крутиться й дихає
RunService.RenderStepped:Connect(function()
	if not modalRoot.Visible then return end
	local function sample(u)
		local x = (u % 1) * #PAL
		local i = math.floor(x)
		local k = x - i
		k = k * k * (3 - 2 * k)
		return PAL[i + 1]:Lerp(PAL[(i + 1) % #PAL + 1], k)
	end
	local phs = -(os.clock() / 4)
	local ks = {}
	for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 + phs)) end
	titleGrad.Color = ColorSequence.new(ks)
	local t = os.clock()
	vpModel:PivotTo(CFrame.new(0, VP_Y + math.sin(t * 2) * VP_B, 0) * CFrame.Angles(0, VP_ROT + math.sin(t * 0.6) * 0.5, 0))
end)

player:GetAttributeChangedSignal("BossSlotDia"):Connect(function()
	if player:GetAttribute("BossSlotDia") == true then toast("4th Boss Slot unlocked!", "green", "claim") end
end)

local ringCenter
task.spawn(function()
	local hub = workspace:WaitForChild("Cave"):WaitForChild("Hub")
	local portal = hub:WaitForChild("BossPortal", 60)
	ringCenter = portal and portal:WaitForChild("Ring"):WaitForChild("RingCenter")
end)
while true do
	local ok, err = pcall(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local inside = false
		if ringCenter and hrp and player:GetAttribute("InBossArena") ~= true then
			local d = ringCenter.CFrame:PointToObjectSpace(hrp.Position)
			inside = Vector2.new(d.X, d.Z).Magnitude <= RING_R + ((isOpen or dismissed) and EXIT_PAD or 0) and math.abs(d.Y) < 10
		end
		if not inside then dismissed = false end
		if inside and not dismissed then
			if not isOpen then open() else refresh() end
		elseif isOpen then
			close()
		end
	end)
	if not ok then warn("BossLobbyWindow: " .. tostring(err)) end
	task.wait(0.2)
end
