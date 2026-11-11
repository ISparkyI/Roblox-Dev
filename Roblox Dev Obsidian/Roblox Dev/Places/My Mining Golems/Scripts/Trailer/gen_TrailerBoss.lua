-- gen_TrailerBoss — генератор ModuleScript StarterPlayerScripts/TrailerDirector/TrailerBoss (07.11.2026).
-- Запускати в командному рядку Studio (Edit) ПІСЛЯ того, як TrailerDirector вставлено в StarterPlayerScripts.
-- Бере з StarterPlayerScripts/BossArenaClient: звуки (sfx), анімацію боса (A, animInit, пози, атаки, смерть, тряску камери)
--   і VFX (пил, іскри, кільця, спалахи, уламки, тріщини, impact, dieFx) — щоб бос у трейлері рухався 1 в 1 як у грі.
-- Якщо BossArenaClient змінився і маркер не знайдено — assert покаже, який саме.
local c = game.StarterPlayer.StarterPlayerScripts.BossArenaClient.Source
local function find(s, from)
	local i = c:find(s, from or 1, true)
	assert(i, "marker not found: " .. s)
	return i
end
local iA = find("local A = { m = nil")
local iStep = find("local function animStep()")
local iVfx = find("-- ===== VFX ударів")
local iCrys = find("local function crystalSpikes")
local iSfx = find("local SFX = RS:WaitForChild(\"BossSfx\"")
local iSfxFn = find("local function sfx(", iSfx)
local iSfxEnd = c:find("\nend\n", iSfxFn, true)
local sfxChunk = c:sub(iSfx, iSfxEnd + 4)
local chunkA = c:sub(iA, iStep - 1):gsub("\"BossCamShake\"", "\"TrailerBossShake\"")
local stepChunk = c:sub(iStep, iVfx - 1)
local n1
stepChunk, n1 = stepChunk:gsub("local bm = bossMap%(%)\n%s*local m = bm and bm:FindFirstChild%(\"Boss\"%)", "local m = A.target") -- 11.11.2026: BossArenaClient тепер бере арену через bossMap()
assert(n1 == 1, "animStep patch failed")
local chunkB, n2 = c:sub(iVfx, iCrys - 1):gsub("local function nearBoss%(r: number%): boolean", "local function nearBoss(r: number): boolean\n\tdo return A.target ~= nil end")
assert(n2 == 1, "nearBoss patch failed")
local pre = [[
--!nocheck
-- TrailerBoss — анімація і VFX боса GOBKING для трейлера (07.11.2026, лише Studio).
-- ЗГЕНЕРОВАНО з StarterPlayerScripts/BossArenaClient (поза спокою, атаки, смерть, тряска камери, пил/уламки/кільця/спалахи),
--   щоб бос у трейлері рухався точно як у грі. Відмінності: модель задає режисер (M.bind), підлога — M.setFloor,
--   «чи близько гравець» = так, коли бос задано. Використовує StarterPlayerScripts/TrailerDirector.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local C = Color3.fromHex
local WHITE = Color3.new(1, 1, 1)
local fxFolder = workspace:FindFirstChild("TrailerFx") or Instance.new("Folder")
fxFolder.Name = "TrailerFx"
fxFolder.Parent = workspace
local FLOOR_Y = 0
local function floorY(): number return FLOOR_Y end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function zonePart(cf, size, color, tr, neon)
	return new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Size = size, CFrame = cf,
		Color = color, Transparency = tr, Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic }, fxFolder)
end
local function tween(o, t, props, style)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
]]
local post = [[
A.target = nil
local function bossHead(): Vector3?
	local hb = A.hb
	return hb and (hb.Position + Vector3.new(0, hb.Size.Y * 0.4, 0)) or nil
end
]]
local tail = [[

RunService.PreRender:Connect(function()
	local ok, err = pcall(animStep)
	if not ok then warn("[TrailerBoss] " .. tostring(err)) end
end)

local M = {}
function M.setFloor(y: number) FLOOR_Y = y end
function M.bind(m: Model?)
	A.target = m
	A.m = nil
	A.die, A.dieHit, A.dieHit2, A.dieFade, A.atk = nil, nil, nil, nil, nil
	A.lastT, A.pos, A.yaw = nil, nil, nil
end
function M.attack(key: string, warn: number, side: number?)
	A.atk, A.t0, A.warn, A.side = key, os.clock(), warn, side or 0
end
function M.die()
	A.die = os.clock()
	A.dieHit, A.dieHit2, A.dieFade = nil, nil, nil
	if A.hb then dieFx(1, A.hb.Position) end
end
function M.fist(name: string): Vector3?
	local m = A.m
	local p = m and m:FindFirstChild(name)
	return p and p.Position or nil
end
M.impact = impact
M.dust = dust
M.sparks = sparks
M.ring = ring
M.flash = flash
M.debris = debris
M.shake = shake
M.sfx = sfx
function M.fovKick(k: number) fovKick = math.max(fovKick, k) end
return M
]]
local src = pre .. sfxChunk .. "\n" .. chunkA .. "\n" .. post .. stepChunk .. chunkB .. tail
local dir = game.StarterPlayer.StarterPlayerScripts.TrailerDirector
local mod = dir:FindFirstChild("TrailerBoss") or Instance.new("ModuleScript")
mod.Name = "TrailerBoss"
mod.Source = src
mod.Parent = dir
local fn, err = loadstring(src)
return "ok " .. #src .. " compile: " .. tostring(fn ~= nil) .. " " .. tostring(err)
