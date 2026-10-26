--!strict
-- UISounds — спільні звуки інтерфейсу (клієнт). Де: ReplicatedStorage/Shared/UISounds.
-- Звуки лежать у SoundService (їх додав користувач): Tap — натискання будь-якої кнопки, ClaimReward — отримання нагороди,
-- LeverPull — важіль ролу (гучність 0,25), ButtonHover — наведення на кнопку / картку / слот,
-- PurchaseSuccess — успішна покупка за Robux (x2 / x4 Money тощо).
-- Використання: require(UISounds).play("tap" | "claim" | "lever" | "hover" | "purchase", minGap?, speed?).
-- speed (необов'язково) — множник PlaybackSpeed копії (висота тону), напр. 1,08 — ледь вище (автоповтор +/− у Sell).
-- Кожен play — копія звуку (PlayOnRemove), тож швидкі повтори не обривають один одного.

local SoundService = game:GetService("SoundService")

local M = {}
local NAMES = { tap = "Tap", claim = "ClaimReward", lever = "LeverPull", hover = "ButtonHover", purchase = "PurchaseSuccess" }
local last: { [string]: number } = {}

function M.play(kind: string, minGap: number?, speed: number?)
	local name = NAMES[kind] or kind
	local s = SoundService:FindFirstChild(name)
	if not s or not s:IsA("Sound") or s.SoundId == "" then return end
	local t = os.clock()
	if minGap and last[name] and t - last[name] < minGap then return end
	last[name] = t
	local c = s:Clone()
	if speed then c.PlaybackSpeed = s.PlaybackSpeed * speed end
	c.Parent = SoundService
	c.PlayOnRemove = true
	c:Destroy()
end

return M
