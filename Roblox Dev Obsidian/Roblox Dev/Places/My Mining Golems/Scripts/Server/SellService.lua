--!strict
-- SellService — серверна логіка лавки SELL (голем-продавець Наґґет) у кожній ніші.
-- Де: ServerScriptService/SellService (ModuleScript). Запуск: NicheBoot після NicheService.
--
-- Дія гравця (RemoteEvent ReplicatedStorage/Remotes/SellAction):
--   "Sell", { ["Ore_Coal"] = 5, ["Bars_Iron"] = 2, ... } — продати вибране у вікні SellWindow.
--   Сервер сам перевіряє: власник ніші, стоїть у колі лавки (Niche*/Sell/Ring/RingCenter, радіус SellRig.RING_R + 2,5),
--   кількість — ціле від 0 до того, що є в інвентарі (атрибути гравця Ore_<руда> / Bars_<руда>).
-- Ціна: руда — ForgeConfig.ORES[i].price, злиток — price × BAR_MULT; сума × TotalMulti (MultiService.Apply) → Money.
-- Анімація продажу: Sell.SellSeq += 1, Sell.SellAmount = сума (клієнт SellClient показує ваги, монети, «+$»).
-- ТЕСТ: інвентар — атрибути гравця (як у ForgeService). Коли з'явиться справжній інвентар — замінити invGet / invAdd.

local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("ForgeConfig"))
local Rig = require(RS.Shared:WaitForChild("SellRig"))
local NicheService = require(script.Parent:WaitForChild("NicheService"))
local MultiService = require(script.Parent:WaitForChild("MultiService"))

local SellService = {}
local GAP = 0.3 -- секунд між продажами одного гравця (захист від спаму)
local lastSell: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function invGet(p: Player, key: string): number return (p:GetAttribute(key) :: number?) or 0 end
-- заблоковане в інвентарі (замок, атрибут InvLocks — JSON-список ключів) не продається
local function lockedSet(p: Player): { [string]: boolean }
	local set = {}
	local ok, l = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), (p:GetAttribute("InvLocks") :: string?) or "[]")
	if ok and type(l) == "table" then for _, k in l do if type(k) == "string" then set[k] = true end end end
	return set
end
local function invAdd(p: Player, key: string, n: number) p:SetAttribute(key, invGet(p, key) + n) end

local function sellOf(p: Player): Model?
	local niche = NicheService.GetNiche(p)
	local s = niche and niche:FindFirstChild("Sell")
	return s and s:IsA("Model") and s or nil
end

local function inRing(p: Player, s: Model): boolean
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local ring = s:FindFirstChild("Ring")
	local rc = ring and ring:FindFirstChild("RingCenter") :: BasePart?
	if not hrp or not rc then return false end
	local d = rc.CFrame:PointToObjectSpace(hrp.Position)
	return Vector2.new(d.X, d.Z).Magnitude <= Rig.RING_R + 2.5
end

local function onAction(p: Player, action: any, arg: any)
	if action ~= "Sell" or type(arg) ~= "table" then return end
	local t = os.clock()
	if t - (lastSell[p] or 0) < GAP then return end
	local s = sellOf(p)
	if not s or not inRing(p, s) then return end
	lastSell[p] = t
	local base = 0
	local locked = lockedSet(p)
	for _, o in Cfg.ORES do
		for _, kind in { "Ore_", "Bars_" } do
			local key = kind .. o.key
			local n = arg[key]
			if type(n) == "number" and n == n and not locked[key] then
				n = math.clamp(math.floor(n), 0, invGet(p, key))
				if n > 0 then
					invAdd(p, key, -n)
					base += n * o.price * (kind == "Bars_" and Cfg.BAR_MULT or 1)
				end
			end
		end
	end
	if base <= 0 then return end
	local amount = MultiService.Apply(p, base)
	invAdd(p, "Money", amount)
	s:SetAttribute("SellAmount", amount)
	s:SetAttribute("SellSeq", ((s:GetAttribute("SellSeq") :: number?) or 0) + 1)
end

function SellService.Start()
	local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"; remotes.Parent = RS
	local ev = remotes:FindFirstChild("SellAction") or Instance.new("RemoteEvent")
	ev.Name = "SellAction"; ev.Parent = remotes
	ev.OnServerEvent:Connect(onAction)
end

return SellService
