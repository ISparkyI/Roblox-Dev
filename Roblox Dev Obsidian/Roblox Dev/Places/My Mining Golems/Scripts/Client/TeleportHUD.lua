--!nonstrict
-- TeleportHUD — 3 кнопки телепорту зверху по центру екрана (в один ряд з кнопками Roblox і верхнім рядом MainHUD). 29.10.2026.
-- Де: StarterPlayer/StarterPlayerScripts/TeleportHUD (LocalScript). Сервер — StallShopService (Remotes/StallShopAction "Teleport", ціль):
--   SHOP   (синя)   — у коло лавки DIAMONDS SHOP (вікно лавки відкривається саме);
--   HOME   (зелена, найбільша) — додому, на PlotSpawn своєї ніші;
--   MARKET (жовта)   — у центр кола Marketplace трохи в повітрі (одразу стартує відлік переходу).
-- Стиль — кнопки StyleA (візерунок studs), чорна тінь, текст Montserrat Heavy з обводкою #14161a.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Shared = RS:WaitForChild("Shared")
local StyleA = require(Shared:WaitForChild("StyleA"))
local UISounds = require(Shared:WaitForChild("UISounds"))
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local C = Color3.fromHex
local INK = C("14161a")
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)

local ITEMS = {
	-- s — множник розміру кнопки (v3, 29.10.2026: усі ×1,15, HOME ×1,25 — головна); MARKET — жовта
	{ key = "shop", text = "SHOP", color = "blue", s = 1.15 },
	{ key = "home", text = "HOME", color = "green", s = 1.25 },
	{ key = "market", text = "MARKET", color = "yellow", s = 1.15 },
}
local W, H, GAP, CY = 176, 52, 14, 42 -- базовий розмір (× s), реальні пікселі; CY — центр ряду по вертикалі

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function toast(text: string, color: string, sound: string?)
	local ui = RS:FindFirstChild("UIEvents")
	local t = ui and ui:FindFirstChild("Toast")
	if t then t:Fire(text, color, sound) end
end

local old = pg:FindFirstChild("TeleportHUD"); if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "TeleportHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4 }, pg)
local total, maxH = (#ITEMS - 1) * GAP, 0
for _, it in ITEMS do total += math.floor(W * it.s); maxH = math.max(maxH, math.floor(H * it.s)) end
local row = new("Frame", { Name = "Row", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, CY),
	Size = UDim2.fromOffset(total, maxH) }, gui)

local busy = false
local function go(key: string)
	if busy then return end
	local rf = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("StallShopAction")
	if not rf then return end
	busy = true
	local ok, res = pcall(rf.InvokeServer, rf, "Teleport", key)
	busy = false
	if ok and type(res) == "table" and res.ok then
		UISounds.play("claim", 0.1)
	elseif not (ok and type(res) == "table" and res.err == "busy") then
		toast("Can't teleport right now", "red", "deny")
	end
end

local x = 0
for _, it in ITEMS do
	local W, H = math.floor(W * it.s), math.floor(H * it.s)
	local holder = new("Frame", { Name = it.text, BackgroundTransparency = 1, Position = UDim2.fromOffset(x, (maxH - H) / 2), Size = UDim2.fromOffset(W, H + 4) }, row)
	x += W + GAP
	local sh = new("Frame", { Name = "Shadow", BackgroundColor3 = BLACK, BackgroundTransparency = 0.7, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(W, H), ZIndex = 1 }, holder)
	local b = StyleA.new(holder, { size = Vector2.new(W, H), position = Vector2.new(0, 0), color = it.color, clickable = true, zIndex = 2 })
	StyleA.follow(b, sh)
	local t = new("TextLabel", { Name = "Label", BackgroundTransparency = 1, FontFace = HEAVY, TextSize = math.floor(28 * it.s), TextColor3 = WHITE, Text = it.text,
		Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(W, H - 4), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7 }, b.root)
	new("UIStroke", { Color = INK, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	StyleA.bind(b, { debounce = 0.4, onClick = function() go(it.key) end })
end
