--!nonstrict
-- UIHover — єдиний звук наведення на кнопки і картки (клієнтський модуль).
-- Де: ReplicatedStorage/Shared/UIHover. Звук — SoundService/ButtonHover (один на всю гру; змінюємо тільки там).
--
-- Всі кнопки (TextButton / ImageButton) у PlayerGui підключаються АВТОМАТИЧНО скриптом StarterPlayerScripts/UIHoverAuto
-- (і наявні, і ті, що з'являться пізніше), тобто нова кнопка має звук без додаткового коду.
--   * Картки (із CardHover.attach) грають звук самі (ідентичний) — вони позначені атрибутом HoverSoundBy, автомат їх пропускає.
--   * Щоб кнопка була без звуку — атрибут NoHoverSound = true.
--   * Не-кнопка (Frame / ImageLabel), яку треба озвучити: UIHover.hook(guiObject).
-- Виклик вручну: UIHover.play().

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local UIHover = {}

local MIN_GAP = 0.05 -- с, щоб накладені одна на одну кнопки не грали двічі
local last = 0
local hooked = setmetatable({}, { __mode = "k" })

task.spawn(function()
	local s = SoundService:WaitForChild("ButtonHover", 10)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		pcall(ContentProvider.PreloadAsync, ContentProvider, { s })
	end
end)

function UIHover.play()
	local t = os.clock()
	if t - last < MIN_GAP then return end
	last = t
	local s = SoundService:FindFirstChild("ButtonHover")
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		s.TimePosition = 0
		s:Play()
	end
end

-- звук на MouseEnter будь-якого GuiObject (один раз на об'єкт)
function UIHover.hook(obj: GuiObject)
	if hooked[obj] then return end
	hooked[obj] = true
	obj.MouseEnter:Connect(function()
		if obj:GetAttribute("NoHoverSound") or obj:GetAttribute("HoverSoundBy") then return end
		if obj:IsA("GuiButton") and not obj.Interactable then return end
		UIHover.play()
	end)
end

-- усі кнопки всередині root, існуючі та майбутні
function UIHover.auto(root: Instance)
	local function consider(d: Instance)
		if d:IsA("GuiButton") then UIHover.hook(d) end
	end
	for _, d in root:GetDescendants() do consider(d) end
	root.DescendantAdded:Connect(consider)
end

return UIHover
