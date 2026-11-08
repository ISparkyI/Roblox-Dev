-- SpawnCamera (StarterPlayerScripts, LocalScript)
-- Після появи персонажа сервер (NicheService) переносить і повертає його до своєї ніші (char:PivotTo).
-- Камера Roblox при цьому лишається дивитися в старому напрямку — гравець стоїть спиною до камери
-- лише іноді, а часто камера дивиться йому в бік. Тут: якщо в перші 15 с після появи персонажа
-- його різко перенесло (телепорт), ставимо камеру за спину персонажа на тій самій відстані.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PITCH = math.rad(48) -- 08.11.2026: камера згори під кутом (видно нішу й важіль), було 20°
local SPAWN_DIST = 26 -- 08.11.2026: відстань камери при появі (далі гравець змінює колесом як завжди)
local pinnedZoom = false
local WATCH = 15 -- скільки секунд після появи стежити за телепортом
local JUMP = 4 -- переміщення за 1 кадр більше за це = телепорт (ходьба — < 1 стада за кадр)

local function behind(hrp: BasePart)
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType ~= Enum.CameraType.Custom then return end
	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 1e-3 then return end
	look = look.Unit
	local focus = hrp.Position + Vector3.new(0, 1.5, 0)
	local dist = SPAWN_DIST
	-- зум камери Roblox тримає сам: на мить фіксуємо Min = Max = SPAWN_DIST, потім повертаємо як було
	if not pinnedZoom then
		pinnedZoom = true
		local mn, mx = player.CameraMinZoomDistance, player.CameraMaxZoomDistance
		player.CameraMaxZoomDistance = math.max(mx, dist); player.CameraMinZoomDistance = dist; player.CameraMaxZoomDistance = dist
		task.delay(0.15, function() player.CameraMinZoomDistance = mn; player.CameraMaxZoomDistance = mx; pinnedZoom = false end)
	end
	cam.CFrame = CFrame.lookAt(focus - look * dist * math.cos(PITCH) + Vector3.new(0, dist * math.sin(PITCH), 0), focus)
end

local function onCharacter(char: Model)
	local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hrp then return end
	local name = "SpawnCamera_" .. tostring(char)
	local last = hrp.Position
	local t0 = os.clock()
	local pending = 2 -- одразу після появи теж ставимо камеру за спину (2 кадри, щоб перебити камеру Roblox)
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		if not hrp.Parent or os.clock() - t0 > WATCH then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local p = hrp.Position
		if (p - last).Magnitude > JUMP then pending = 2 end -- телепорт: камера за спину на 2 кадри
		last = p
		if pending > 0 then
			pending -= 1
			behind(hrp)
		end
	end)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end
