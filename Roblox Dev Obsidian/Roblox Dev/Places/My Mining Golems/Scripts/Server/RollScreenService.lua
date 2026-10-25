--!strict
-- RollScreenService — екран Roll Upgrades у ніші: опускається зі стелі (з жолоба Roll_Upgrade_placer),
-- коли власник ніші стоїть біля важеля ролу.
-- Де: ServerScriptService/RollScreenService (ModuleScript). Запускає ServerScriptService/NicheBoot.
--
-- Правило: власник ніші зупинився в радіусі 11 стадів (по горизонталі) від осі важеля і стоїть нерухомо
-- 0,25 с → атрибут RollUpgradeScreen.Open = true. Таймер рахує, лише поки гравець стоїть: будь-який рух
-- (навіть у зоні) його скидає, тож на ходу табло не падає. Вийшов із зони й не повертається 1 с →
-- Open = false. Зона невидима.
-- Радіус і час — атрибути моделі RollUpgradeScreen: ZoneRadius, HoldTime.
-- Колізія: на сервері табло завжди в позі «опущено», тому CanCollide деталей Board = Open (сховане табло
-- нікому не заважає). CanQuery увімкнений постійно — без нього не клікається SurfaceGui екрана.
-- Сервер лише перемикає Open; анімацію (падіння на ланцюгах, гойдання, вмикання) робить
-- StarterPlayerScripts/RollScreenClient у кожного гравця.

local RunService = game:GetService("RunService")

local LEAVE_GRACE = 1 -- скільки секунд поза зоною, перш ніж екран підніметься

local RollScreenService = {}

local function setCollide(screen: Model, on: boolean)
	local board = screen:FindFirstChild("Board")
	if not board then return end
	for _, d in board:GetDescendants() do
		if d:IsA("BasePart") then d.CanCollide = on end
	end
end

type Track = { inT: number, outT: number }
local tracks: { [Model]: Track } = setmetatable({}, { __mode = "k" }) :: any

function RollScreenService.Start()
	local NicheService = require(script.Parent:WaitForChild("NicheService")) :: any
	local niches = workspace:WaitForChild("Niches")

	RunService.Heartbeat:Connect(function(dt: number)
		for _, niche in niches:GetChildren() do
			local screen = niche:FindFirstChild("RollUpgradeScreen") :: Model?
			local rollSystem = niche:FindFirstChild("RollSystem")
			local hinge = rollSystem and rollSystem:FindFirstChild("Hinge", true) :: BasePart?
			if not (screen and hinge) then continue end

			local t = tracks[screen]
			if not t then
				t = { inT = 0, outT = 0 }; tracks[screen] = t
				setCollide(screen, screen:GetAttribute("Open") == true)
			end

			local owner = NicheService.GetOwner(niche)
			local char = owner and owner.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local inZone, still = false, false
			if hrp and hum and hum.Health > 0 then
				local d = hrp.Position - hinge.Position
				inZone = Vector2.new(d.X, d.Z).Magnitude <= (screen:GetAttribute("ZoneRadius") or 11) and math.abs(d.Y) < 15
				local v = hrp.AssemblyLinearVelocity
				still = hum.MoveDirection.Magnitude < 0.05 and Vector2.new(v.X, v.Z).Magnitude < 1.5
			end
			-- таймер рахує, лише поки гравець стоїть у зоні нерухомо; рух його скидає
			if inZone then
				t.outT = 0
				if still then t.inT += dt else t.inT = 0 end
			else
				t.inT = 0; t.outT += dt
			end

			local open = screen:GetAttribute("Open") == true
			if not open and t.inT >= (screen:GetAttribute("HoldTime") or 0.25) then
				screen:SetAttribute("Open", true)
				setCollide(screen, true)
			elseif open and t.outT >= LEAVE_GRACE then
				screen:SetAttribute("Open", false)
				setCollide(screen, false)
			end
		end
	end)
end

return RollScreenService
