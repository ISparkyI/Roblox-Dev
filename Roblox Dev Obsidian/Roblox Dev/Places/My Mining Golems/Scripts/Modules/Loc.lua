--!nonstrict
-- Loc — явний переклад рядків через стандартну хмарну таблицю локалізації (Creator Hub → Localization), лише на клієнті.
-- Для текстів, які автопереклад Roblox ловить погано: RichText з динамічними числами, текст з бекенду (апдейт-лог).
-- Такі мітки ставлять AutoLocalize = false і пишуть Loc.t("Source") / Loc.f("{1} kinds", n).
-- Loc.t — точний збіг Source з таблиці; немає перекладу або мова англійська — повертає оригінал.
-- Loc.f — те саме, потім {1}, {2}… (або {number1}, {number2}… — як у записах, які створив автозбір Roblox) замінюються аргументами.
--   Так можна брати вже наявний рядок таблиці без нового запису: Loc.f("STAND {number1}", 3) → «СТЕНД 3».
-- Loc.Ready — подія, коли перекладач завантажився.
local LS = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local M = {}
local tr = nil
local readyEv = Instance.new("BindableEvent")
M.Ready = readyEv.Event

-- мова — як у автоперекладу: LocalizationService.RobloxLocaleId (його підміняє й Player Emulator у Studio);
-- англійська або порожньо — запасний варіант GetTranslatorForPlayerAsync. Зміна мови під час гри — новий перекладач і знову Ready.
local loading = 0
local function load()
	loading += 1
	local my = loading
	local plr = Players.LocalPlayer
	if not plr then return end
	for _ = 1, 5 do
		local loc = LS.RobloxLocaleId
		if type(loc) ~= "string" or loc == "" or string.sub(loc, 1, 2) == "en" then loc = plr.LocaleId end
		local ok, t
		if type(loc) == "string" and loc ~= "" and string.sub(loc, 1, 2) ~= "en" then
			ok, t = pcall(LS.GetTranslatorForLocaleAsync, LS, loc)
		else
			ok, t = pcall(LS.GetTranslatorForPlayerAsync, LS, plr)
		end
		if my ~= loading then return end
		if ok and t then
			tr = t
			readyEv:Fire()
			return
		end
		task.wait(3)
	end
end
task.spawn(load)
LS:GetPropertyChangedSignal("RobloxLocaleId"):Connect(function() task.spawn(load) end)
if Players.LocalPlayer then Players.LocalPlayer:GetPropertyChangedSignal("LocaleId"):Connect(function() task.spawn(load) end) end

function M.isReady(): boolean return tr ~= nil end

function M.t(s: string): string
	if tr == nil or type(s) ~= "string" or s == "" then return s end
	local ok, r = pcall(tr.Translate, tr, game, s)
	if ok and type(r) == "string" and r ~= "" then return r end
	return s
end

function M.f(tpl: string, ...): string
	local a = { ... }
	return (string.gsub(M.t(tpl), "{%a*(%d+)}", function(i)
		local v = a[tonumber(i)]
		return v ~= nil and tostring(v) or ""
	end))
end

return M
