--!strict
-- UISounds — спільні звуки інтерфейсу (клієнт). Де: ReplicatedStorage/Shared/UISounds.
-- Звуки лежать у SoundService (їх додав користувач): Tap — натискання будь-якої кнопки, ClaimReward — отримання нагороди,
-- LeverPull — важіль ролу (гучність 0,25), ButtonHover — наведення на кнопку / картку / слот,
-- PurchaseSuccess — успішна покупка за Robux (x2 / x4 Money тощо), Deny — глухий звук відмови: натиснули сіру / недоступну кнопку
-- (копія Tap з PlaybackSpeed 0,6; грає StyleA.shake / StyleA.deny).
-- Використання: require(UISounds).play("tap" | "claim" | "lever" | "hover" | "purchase" | "deny", minGap?, speed?).
-- tap грає наприкінці кадру (task.defer): якщо той самий клік скінчився відмовою (deny за ±0,12 с), tap не звучить — лише deny.
-- speed (необов'язково) — множник PlaybackSpeed копії (висота тону), напр. 1,08 — ледь вище (автоповтор +/− у Sell).
-- Кожен play — копія звуку (PlayOnRemove), тож швидкі повтори не обривають один одного.
-- Поки йде завантаження (_G.LoadingMute = true ставить ReplicatedFirst/OrekoLoadingScreen) — тиша:
-- наприклад ClaimReward від Auto Collect, коли големи кладуть руду в ящик.

local SoundService = game:GetService("SoundService")

local M = {}
local NAMES = { tap = "Tap", claim = "ClaimReward", lever = "LeverPull", hover = "ButtonHover", purchase = "PurchaseSuccess", deny = "Deny" }
local last: { [string]: number } = {}
local denyAt = -math.huge -- коли востаннє грав deny

local function emit(s: Sound, speed: number?)
	local c = s:Clone()
	if speed then c.PlaybackSpeed = s.PlaybackSpeed * speed end
	c.Parent = SoundService
	c.PlayOnRemove = true
	c:Destroy()
end

function M.play(kind: string, minGap: number?, speed: number?)
	if _G.LoadingMute then return end
	local name = NAMES[kind] or kind
	local s = SoundService:FindFirstChild(name)
	if not s or not s:IsA("Sound") or s.SoundId == "" then return end
	local t = os.clock()
	if minGap and last[name] and t - last[name] < minGap then return end
	last[name] = t
	if name == "Deny" then
		denyAt = t
	elseif name == "Tap" then
		-- відмова в тому ж кліку (до чи після tap) скасовує tap: недоступна кнопка — лише deny
		task.defer(function() if denyAt < t - 0.12 then emit(s :: Sound, speed) end end)
		return
	end
	emit(s :: Sound, speed)
end

return M
