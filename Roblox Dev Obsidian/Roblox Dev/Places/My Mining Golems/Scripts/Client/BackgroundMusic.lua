-- Фонова музика: грає локально в кожного гравця (SoundService/BackgroundMusic), зациклена.
-- Стартує лише коли загрузочний екран (ReplicatedFirst/OrekoLoadingScreen) ставить SoundService атрибут
-- LoadingMusicOK = true (шкала дійшла до 50 % або екран закрився); тайм-аут 30 с — щоб музика заграла будь-що.
-- Вхід — плавний fade-in за FADE_IN с до гучності, яка стоїть на самому Sound.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local WAIT_MAX, FADE_IN = 30, 1
local started = os.clock()

local music = SoundService:WaitForChild("BackgroundMusic")
if music.SoundId == "" then return end

-- дочекатись завантаження, щоб музика стартувала одразу, а не з обривом
if not music.IsLoaded then
	pcall(ContentProvider.PreloadAsync, ContentProvider, { music })
end
-- чекаємо дозволу від загрузочного екрана (або тайм-ауту)
while not SoundService:GetAttribute("LoadingMusicOK") and os.clock() - started < WAIT_MAX do
	task.wait(0.1)
end
local target = music.Volume
music.Looped = true
music.TimePosition = 0
music.Volume = 0
music:Play()
TweenService:Create(music, TweenInfo.new(FADE_IN, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Volume = target }):Play()
