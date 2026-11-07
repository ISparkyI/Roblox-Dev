-- Фонова музика (локально в кожного гравця). 04.11.2026 v2:
--   • лобі — плейлист: SoundService/LobbyMusic/* (Lobby1 — колишня BackgroundMusic); перемішуються без повтору підряд,
--     між треками — плавний кросфейд (XF_LOBBY с);
--   • бій з босом (атрибут гравця InBossArena) — SoundService/BossMusic, зациклена на BOSS_LOOP с з кросфейдом у початок
--     (два екземпляри, перехід BOSS_XF с — кратно долі, щоб ритм не збивався); лобі-трек ставиться на паузу й потім
--     продовжується з того ж місця;
--   • гучність кожного треку = Volume на самому Sound (вирівняно за гучністю), загальна — повзунок Music (MusicGroup).
-- Старт — лише коли загрузочний екран ставить SoundService.LoadingMusicOK = true (або тайм-аут 30 с).
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local WAIT_MAX, FADE_IN = 30, 1
local XF_LOBBY = 2.5 -- кросфейд між лобі-треками
local BOSS_LOOP, BOSS_XF = 80, 2 -- бос-музика: точка петлі (с) і тривалість переходу в початок
local started = os.clock()

local folder = SoundService:WaitForChild("LobbyMusic")
local bossA = SoundService:WaitForChild("BossMusic", 10) :: Sound?

local lobby: { Sound } = {}
if folder then
	local extra = folder:GetChildren()
	table.sort(extra, function(a, b) return a.Name < b.Name end)
	for _, s in extra do
		if s:IsA("Sound") and s.SoundId ~= "" then table.insert(lobby, s) end
	end
end
if #lobby == 0 then return end

local target: { [Sound]: number } = {}
local tweens: { [Sound]: Tween } = {}
local function prep(s: Sound)
	target[s] = s.Volume
	s:SetAttribute("Music", true)
	s.Looped = false
	s.Volume = 0
	s:Stop()
end
for _, s in lobby do prep(s) end
local bossB: Sound? = nil
if bossA then
	prep(bossA)
	bossB = bossA:Clone()
	bossB.Name = "BossMusicB"
	bossB.Parent = SoundService
	target[bossB] = target[bossA]
end

local function fade(s: Sound, to: number, t: number, thenStop: boolean?, thenPause: boolean?)
	if tweens[s] then tweens[s]:Cancel() end
	local tw = TweenService:Create(s, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Volume = to })
	tweens[s] = tw
	tw.Completed:Connect(function(st)
		if st ~= Enum.PlaybackState.Completed then return end
		if tweens[s] == tw then tweens[s] = nil end
		if thenStop then s:Stop() elseif thenPause then s:Pause() end
	end)
	tw:Play()
end

-- перемішаний порядок без повтору того самого треку підряд
local order: { Sound } = {}
local last: Sound? = nil
local function nextTrack(): Sound
	if #order == 0 then
		for _, s in lobby do table.insert(order, s) end
		for i = #order, 2, -1 do local j = math.random(1, i); order[i], order[j] = order[j], order[i] end
		if #order > 1 and order[1] == last then order[1], order[2] = order[2], order[1] end
	end
	local s = table.remove(order, 1) :: Sound
	last = s
	return s
end

pcall(ContentProvider.PreloadAsync, ContentProvider, { lobby[1] })
while not SoundService:GetAttribute("LoadingMusicOK") and os.clock() - started < WAIT_MAX do
	task.wait(0.1)
end
task.spawn(function()
	local rest = {}
	for i = 2, #lobby do table.insert(rest, lobby[i]) end
	if bossA then table.insert(rest, bossA) end
	pcall(ContentProvider.PreloadAsync, ContentProvider, rest)
end)

local cur: Sound? = nil -- поточний лобі-трек
local mode = "lobby"
local bossCur: Sound? = nil

local function startLobby(s: Sound, fromPos: number?, fadeT: number)
	cur = s
	s.TimePosition = fromPos or 0
	s.Volume = 0
	if fromPos and fromPos > 0 then s:Resume() else s:Play() end
	fade(s, target[s], fadeT)
end

local function enterBoss()
	if mode == "boss" or not bossA then return end
	mode = "boss"
	if cur then fade(cur, 0, 1.2, false, true) end
	bossCur = bossA
	bossA.TimePosition = 0
	bossA.Volume = 0
	bossA:Play()
	fade(bossA, target[bossA], 1)
end
local function leaveBoss()
	if mode ~= "boss" then return end
	mode = "lobby"
	for _, s in { bossA, bossB } do if s and s.IsPlaying then fade(s, 0, 1.5, true) end end
	bossCur = nil
	local s = cur or nextTrack()
	local pos = s.TimePosition
	if pos > s.TimeLength - XF_LOBBY - 3 then s, pos = nextTrack(), 0 end
	startLobby(s, pos, 2)
end

startLobby(nextTrack(), 0, FADE_IN)

local function onArena()
	if player:GetAttribute("InBossArena") == true then enterBoss() else leaveBoss() end
end
player:GetAttributeChangedSignal("InBossArena"):Connect(onArena)
onArena()

RunService.Heartbeat:Connect(function()
	if mode == "lobby" then
		local s = cur
		if s and s.TimeLength > 0 and s.IsPlaying and s.TimePosition >= s.TimeLength - XF_LOBBY then
			fade(s, 0, XF_LOBBY, true)
			local n = nextTrack()
			if n == s and #lobby > 1 then n = nextTrack() end
			startLobby(n, 0, XF_LOBBY)
		elseif s and not s.IsPlaying and not tweens[s] then
			startLobby(nextTrack(), 0, 1) -- трек закінчився сам (напр. короткий)
		end
	elseif mode == "boss" and bossCur and bossB then
		local s = bossCur
		local loopAt = math.min(BOSS_LOOP, (s.TimeLength > 0 and s.TimeLength or BOSS_LOOP) - 0.1)
		if s.TimePosition >= loopAt - BOSS_XF then
			local o = (s == bossA) and bossB or bossA :: Sound
			fade(s, 0, BOSS_XF, true)
			o.TimePosition = 0
			o.Volume = 0
			o:Play()
			fade(o, target[o], BOSS_XF * 0.6)
			bossCur = o
		end
	end
end)
