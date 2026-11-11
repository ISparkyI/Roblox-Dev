--!strict
-- RobuxStandService — видача голема зі стенду за Robux (10.11.2026). Викликає MonetizationService (baseGrant) з ProcessReceipt.
-- GrantProduct(p, productId) -> true (видано) / false (ще не можна — Roblox повторить) / nil (не наш продукт).
-- Платна покупка — без ліміту інвентаря (force), як у MarketExclusiveService. Клас — RobuxStandConfig.CLS (майнер).
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Cfg = require(RS:WaitForChild("Shared"):WaitForChild("RobuxStandConfig"))
local Catalog = require(RS.Shared:WaitForChild("GolemCatalog"))

local M = {}

local function notify(p: Player, text: string, color: string)
	local r = RS:FindFirstChild("Remotes")
	local ev = r and r:FindFirstChild("AdminBroadcast")
	if ev and ev:IsA("RemoteEvent") then ev:FireClient(p, "toast", { text = text, color = color }) end
end

local function decode(p: Player, a: string): any
	local s = p:GetAttribute(a)
	if type(s) ~= "string" or s == "" then return {} end
	local ok, v = pcall(HttpService.JSONDecode, HttpService, s)
	return (ok and type(v) == "table") and v or {}
end

function M.Grant(p: Player, kind: string): boolean
	local okI, Inv = pcall(require, script.Parent:FindFirstChild("InventoryService"))
	local okC, Cave = pcall(require, script.Parent:FindFirstChild("CaveStandService"))
	if not (okI and Inv) then return false end
	if p:GetAttribute("InvReady") ~= true then return false end
	local id = 0
	if okC and Cave and Cave.MaxId then local okM, mx = pcall(Cave.MaxId, p); if okM and type(mx) == "number" then id = mx end end
	for _, g in decode(p, "InvGolems") do if type(g) == "table" and type(g.id) == "number" then id = math.max(id, g.id) end end
	id += 1
	if not Inv.AddGolem(p, id, kind, Cfg.CLS, 0, "robuxstand:" .. kind, true) then return false end
	if Inv.Pin then pcall(Inv.Pin, p, "Golem_" .. id) end
	local def = Catalog.get(kind)
	notify(p, (def and def.name or kind) .. " added to your backpack!", "green")
	return true
end

function M.GrantProduct(p: Player, productId: number): boolean?
	local o = Cfg.byProduct(productId)
	if not o then return nil end
	return M.Grant(p, o.kind)
end

return M
