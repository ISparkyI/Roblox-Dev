--!strict
-- CaveStandsClient — кнопки стендів у печері-сховищі (клієнт): напис, колір і сірий стан кнопки StandPrompt.
-- Де: StarterPlayer/StarterPlayerScripts/CaveStandsClient (LocalScript). Сервер — ServerScriptService/CaveStandService.
-- Кнопку малює CustomPrompts (вигляд COLLECT, клавіша E, затиск 0,5 с з тінню-заповненням); тут лише атрибути:
--   UIText («BUY $1,000», «LOCKED», «PLACE», «TAKE», «INVENTORY FULL», «NO MODEL YET», «ON PLOT», «HOLD A GOLEM»), UIColor,
--   UIDisabled (сіра: затиск не працює — HoldDuration дуже великий, кнопка хитається з глухим звуком).
-- Кнопки бачить лише власник печери, поки він у ній (атрибут InCave); гість — нічого (лише дивиться на стенди й големів).
-- Стан стенда — атрибути моделі стенда (Bought, GolemId, SlotIndex, Price) і печери (StandsBought, OwnerUserId);
--   гравця — Money, InvHeld, InvGolems, PlotPlaced. Купівля вдалась (зросла кількість у CaveStands) — звук BuySound.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Catalog = require(RS:WaitForChild("Shared"):WaitForChild("GolemCatalog"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local UISfx = require(RS.Shared:WaitForChild("UISfx"))
local Items = require(RS.Shared:WaitForChild("ItemConfig"))

local player = Players.LocalPlayer
local HOLD = 0.5
local NEVER = 1e6 -- сіра кнопка: затиск ніколи не дійде до кінця
local ENTER_GRACE = 1.2 -- щойно зайшов у печеру (E ще затиснута після ENTER CAVE) — кнопки стендів ще не показуємо
local enteredAt = -math.huge

local prompts: { [ProximityPrompt]: boolean } = {}

local function decode(attr: string, default: any): any
	local s = player:GetAttribute(attr)
	if type(s) ~= "string" or s == "" then return default end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return ok and type(v) == "table" and v or default
end

-- (видно?, напис, колір, сіра?)
local function stateOf(prompt: ProximityPrompt): (boolean, string, string, boolean)
	local stand = prompt.Parent and prompt.Parent.Parent
	local caves = workspace:FindFirstChild("Caves")
	local cave: Instance? = stand
	while cave and cave.Parent ~= caves do cave = cave.Parent end
	if not (stand and cave) then return false, "", "gray", true end
	if cave:GetAttribute("OwnerUserId") ~= player.UserId or player:GetAttribute("InCave") ~= true then
		return false, "", "gray", true
	end
	if os.clock() - enteredAt < ENTER_GRACE then return false, "", "gray", true end
	local slot = (stand:GetAttribute("SlotIndex") :: number?) or 0
	if stand:GetAttribute("Bought") ~= true then
		if slot ~= ((cave:GetAttribute("StandsBought") :: number?) or 0) + 1 then return true, "LOCKED", "gray", true end
		local price = (stand:GetAttribute("Price") :: number?) or 0
		local ok = ((player:GetAttribute("Money") :: number?) or 0) >= price
		return true, "BUY " .. NF.money(price), ok and "green" or "gray", not ok
	end
	if stand:GetAttribute("GolemId") ~= nil then
		if Items.invGolemCount(decode("InvGolems", {}), decode("PlotPlaced", {})) >= Items.maxGolems(player) then return true, "INVENTORY FULL", "gray", true end
		return true, "TAKE", "blue", false
	end
	local held = player:GetAttribute("InvHeld")
	if type(held) == "string" and string.sub(held, 1, 6) == "Golem_" then
		local id = tonumber(string.sub(held, 7))
		local g = nil
		for _, e in decode("InvGolems", {}) do if type(e) == "table" and e.id == id then g = e end end
		local def = g and Catalog.get(g.kind)
		if not def then return true, "HOLD A GOLEM", "gray", true end
		if table.find(decode("PlotPlaced", {}), id) then return true, "ON PLOT", "gray", true end
		if not def.model then return true, "NO MODEL YET", "gray", true end
		if def.exclusive then return true, "EXCLUSIVE", "gray", true end -- ексклюзиви в печеру не ставляться (їх і так не втратити)
		return true, "PLACE", "green", false
	end
	return true, "HOLD A GOLEM", "gray", true
end

local function apply(prompt: ProximityPrompt)
	if not prompt.Parent then prompts[prompt] = nil; return end
	local vis, text, color, dis = stateOf(prompt)
	if prompt.Enabled ~= vis then prompt.Enabled = vis end
	local hold = dis and NEVER or HOLD
	if prompt.HoldDuration ~= hold then prompt.HoldDuration = hold end
	if prompt:GetAttribute("UIText") ~= text then prompt:SetAttribute("UIText", text) end
	if prompt:GetAttribute("UIColor") ~= color then prompt:SetAttribute("UIColor", color) end
	if prompt:GetAttribute("UIDisabled") ~= dis then prompt:SetAttribute("UIDisabled", dis) end
end

local pending = false
local function refreshAll()
	if pending then return end
	pending = true
	task.defer(function()
		pending = false
		for pr in prompts do apply(pr) end
	end)
end

local function track(d: Instance)
	if d:IsA("ProximityPrompt") and d.Name == "StandPrompt" then
		prompts[d] = true
		apply(d)
		local stand = d.Parent and d.Parent.Parent
		if stand then stand.AttributeChanged:Connect(refreshAll) end
		d.AncestryChanged:Connect(function() if not d:IsDescendantOf(workspace) then prompts[d] = nil end end)
	elseif d:IsA("Model") and d.Parent and d.Parent.Name == "Caves" then
		d:GetAttributeChangedSignal("StandsBought"):Connect(refreshAll)
	end
end

local function hookCaves(f: Instance)
	for _, d in f:GetDescendants() do track(d) end
	f.DescendantAdded:Connect(track) -- StreamingEnabled: частини печери приходять поступово
end
task.spawn(function()
	local f = workspace:WaitForChild("Caves", 60)
	if f then hookCaves(f) end
end)

local WATCH = { Money = true, InvHeld = true, InvGolems = true, PlotPlaced = true, InCave = true, CaveStands = true, CaveStandGolems = true }
local boughtN = #decode("CaveStands", {})
player.AttributeChanged:Connect(function(name)
	if name == "CaveStands" then
		local n = #decode("CaveStands", {})
		if n > boughtN and player:GetAttribute("InCave") == true then UISfx.play("BuySound") end -- купівля стенда
		boughtN = n
	end
	if name == "InCave" and player:GetAttribute("InCave") == true then
		enteredAt = os.clock()
		task.delay(ENTER_GRACE + 0.05, refreshAll)
	end
	if WATCH[name] then refreshAll() end
end)
