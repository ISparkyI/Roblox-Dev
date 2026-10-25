--!strict
-- Прості UI-звуки (лежать у SoundService). UISfx.play("BuySound") / UISfx.play("ButtonHover").
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local UISfx = {}

function UISfx.play(name: string)
	local s = SoundService:FindFirstChild(name)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		-- багато файлів починаються з тиші: StartOffset (с) пропускає її, щоб звук був одразу при натисканні
		s.TimePosition = s:GetAttribute("StartOffset") or 0
		s:Play()
	end
end

-- попереднє завантаження, щоб перший звук не запізнювався
task.spawn(function()
	for _, name in { "BuySound", "SellSound" } do
		local s = SoundService:WaitForChild(name, 10)
		if s and s:IsA("Sound") and s.SoundId ~= "" then
			pcall(ContentProvider.PreloadAsync, ContentProvider, { s })
		end
	end
end)

return UISfx
