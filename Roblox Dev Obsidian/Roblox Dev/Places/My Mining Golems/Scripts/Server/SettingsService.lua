--!strict
-- SettingsService — налаштування гравця (вікно SETTINGS, клієнт — StarterPlayerScripts/SettingsWindow).
-- Де: ServerScriptService/SettingsService (ModuleScript), запускає NicheBoot. RemoteEvent Remotes/SettingsAction: (ключ, значення).
-- Сервер перевіряє ключ і тип, пише атрибут гравця Set_<ключ>; DataService зберігає всі Set_* (префікс, scope global).
-- Ключі: Music, Sfx — 0..100 (гучність, %); Auras, HidePlayers, LowGfx — true / false. Значення за замовчуванням — у клієнта.
-- Tag — ключ неймтегу ("" — без тегу) з MonetizationConfig.TAGS, лише власний (VIP — Pass_VIP); тег — BillboardGui над головою.
-- AutoEquip — лише з геймпасом Pass_AutoEquip; атрибут AutoEquipBest (читає PlotService) = Pass_AutoEquip і Set_AutoEquip ~= false.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MonCfg = require(RS:WaitForChild("Shared"):WaitForChild("MonetizationConfig"))

-- неймтег над головою (Set_Tag): BillboardGui "Nametag" на голові персонажа, видно всім
local INK = Color3.fromHex("14161a")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local function tagDef(key: string): any
	for _, t in MonCfg.TAGS do if t.key == key then return t end end
	return nil
end
local function applyTag(p: Player)
	local ch = p.Character
	local head = ch and ch:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("Nametag")
	if old then old:Destroy() end
	local key = p:GetAttribute("Set_Tag")
	if type(key) ~= "string" or key == "" or not MonCfg.ownsTag(p, key) then return end
	local t = tagDef(key)
	if not t then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Nametag"
	bb.Size = UDim2.fromScale(4, 1)
	bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.FontFace = HEAVY
	lbl.TextScaled = true
	lbl.Text = t.text
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Parent = bb
	local st = Instance.new("UIStroke"); st.Color = INK; st.Thickness = 2.5; st.LineJoinMode = Enum.LineJoinMode.Round; st.Parent = lbl
	local g = Instance.new("UIGradient"); g.Rotation = 90
	g.Color = ColorSequence.new(Color3.fromHex(t.c1), Color3.fromHex(t.c2)); g.Parent = lbl
	bb.Parent = head
end

local SettingsService = {}

local KEYS = {
	Music = "percent",
	Sfx = "percent",
	Auras = "bool",
	HidePlayers = "bool",
	LowGfx = "bool",
	AutoEquip = "bool",
	AutoRoll = "bool", -- лише з Pass_AutoRoll (RollService читає Set_AutoRoll ~= false)
	AutoBuy = "bool", -- лише з Pass_AutoBuy
	FastRoll = "bool", -- лише з Pass_FastRoll (RollService / LeverScript читають Set_FastRoll ~= false)
	AutoCollect = "bool", -- лише з Pass_AutoCollect (PlotService читає Set_AutoCollect ~= false)
	RollMuts = "mask", -- фільтр AUTO ROLL: біти мутацій 0..7 (RollService.wanted)
	RollRars = "mask", -- фільтр AUTO ROLL: біти рідкостей (Catalog.RARITIES)
	RollMinDmg = "num", -- фільтр AUTO ROLL: мінімум шкоди (носій — місткість)
	Tag = "tag",
}
local RATE = 20 -- максимум змін за 5 с
local hits: { [Player]: { number } } = {}

local function allowed(p: Player): boolean
	local t = os.clock()
	local list = hits[p] or {}
	local keep = {}
	for _, x in list do if t - x < 5 then table.insert(keep, x) end end
	if #keep >= RATE then hits[p] = keep; return false end
	table.insert(keep, t)
	hits[p] = keep
	return true
end

local function onSet(p: Player, key: any, v: any)
	if type(key) ~= "string" then return end
	local kind = KEYS[key]
	if not kind or not allowed(p) then return end
	if key == "AutoEquip" and p:GetAttribute("Pass_AutoEquip") ~= true then return end
	if key == "AutoRoll" and p:GetAttribute("Pass_AutoRoll") ~= true then return end
	if key == "AutoBuy" and p:GetAttribute("Pass_AutoBuy") ~= true then return end
	if key == "FastRoll" and p:GetAttribute("Pass_FastRoll") ~= true then return end
	if key == "AutoCollect" and p:GetAttribute("Pass_AutoCollect") ~= true then return end
	if kind == "percent" then
		if type(v) ~= "number" or v ~= v then return end
		v = math.clamp(math.floor(v + 0.5), 0, 100)
	elseif kind == "bool" then
		if type(v) ~= "boolean" then return end
	elseif kind == "mask" then
		if type(v) ~= "number" or v ~= v then return end
		v = math.clamp(math.floor(v), 0, 255)
	elseif kind == "num" then
		if type(v) ~= "number" or v ~= v then return end
		v = math.clamp(math.floor(v), 0, 1e15)
	elseif kind == "tag" then
		if type(v) ~= "string" or (v ~= "" and not MonCfg.ownsTag(p, v)) then return end
	end
	p:SetAttribute("Set_" .. key, v)
end

-- тег без власності (забрали геймпас) — знімаємо
local function checkTag(p: Player)
	local k = p:GetAttribute("Set_Tag")
	if type(k) == "string" and k ~= "" and not MonCfg.ownsTag(p, k) then p:SetAttribute("Set_Tag", "") end
	applyTag(p)
end
local function syncAuto(p: Player)
	p:SetAttribute("AutoEquipBest", p:GetAttribute("Pass_AutoEquip") == true and p:GetAttribute("Set_AutoEquip") ~= false)
end

function SettingsService.Start()
	local function watch(p: Player)
		p:GetAttributeChangedSignal("Pass_AutoEquip"):Connect(function() syncAuto(p) end)
		p:GetAttributeChangedSignal("Set_AutoEquip"):Connect(function() syncAuto(p) end)
		syncAuto(p)
		p:GetAttributeChangedSignal("Set_Tag"):Connect(function() applyTag(p) end)
		p.AttributeChanged:Connect(function(a) if string.sub(a, 1, 5) == "Pass_" then checkTag(p) end end)
		p.CharacterAdded:Connect(function(ch) ch:WaitForChild("Head", 10); applyTag(p) end)
		if p.Character then task.spawn(applyTag, p) end
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do watch(p) end
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("SettingsAction") or Instance.new("RemoteEvent")
	ev.Name = "SettingsAction"; ev.Parent = remotes
	;(ev :: RemoteEvent).OnServerEvent:Connect(onSet)
	Players.PlayerRemoving:Connect(function(p) hits[p] = nil end)
end

return SettingsService
