-- Фонова музика: грає локально в кожного гравця (SoundService/BackgroundMusic), зациклена.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local music = SoundService:WaitForChild("BackgroundMusic")
if music.SoundId == "" then return end

-- дочекатись завантаження, щоб музика стартувала одразу, а не з обривом
if not music.IsLoaded then
	pcall(ContentProvider.PreloadAsync, ContentProvider, { music })
end
music.Looped = true
music.TimePosition = 0
music:Play()
