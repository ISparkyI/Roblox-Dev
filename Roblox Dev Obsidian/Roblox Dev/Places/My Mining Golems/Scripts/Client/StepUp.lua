-- StepUp — гравець сам заходить на невисокі уступи (до MAX_STEP стадів), не стрибаючи. 11.11.2026.
-- Де: StarterPlayer/StarterCharacterScripts/StepUp (LocalScript; персонаж належить клієнту, тож рух плавний і без сервера).
-- Навіщо: у маленьких аватарів мала HipHeight — рушій не піднімає їх навіть на 1 стад, вони впираються й застрягають.
-- Як: щокадру, коли гравець іде по землі, — промінь уперед на рівні стоп. Уперся в стіну → промінь згори вниз трохи далі
--   знаходить верх уступу. Якщо висота 0.15…MAX_STEP, зверху рівна поверхня й над нею є місце для персонажа —
--   підіймаємо HumanoidRootPart на висоту уступу (+ трошки вперед). Похилі поверхні (схили) не чіпаємо — по них рушій і так іде.
local RunService = game:GetService("RunService")

local MAX_STEP = 2.2   -- найвищий уступ, на який заходимо без стрибка (стади)
local MIN_STEP = 0.15  -- нижче — рушій сам
local COOLDOWN = 0.12  -- с між підйомами (сходи — по черзі)

local char = script.Parent
local hum = char:WaitForChild("Humanoid") :: Humanoid
local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true -- лише тверді деталі (не стенди без колізії, не ефекти)

local last = 0
local SKIP = {
	[Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Climbing] = true, [Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Seated] = true, [Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true, [Enum.HumanoidStateType.Physics] = true,
}

RunService.Heartbeat:Connect(function()
	if hum.Health <= 0 or hum.FloorMaterial == Enum.Material.Air or SKIP[hum:GetState()] then return end
	if hrp.Anchored then return end
	local md = hum.MoveDirection
	local flat = Vector3.new(md.X, 0, md.Z)
	if flat.Magnitude < 0.1 then return end
	local now = os.clock()
	if now - last < COOLDOWN then return end
	local dir = flat.Unit
	-- інші гравці й свій персонаж — не перешкода
	local ex = {}
	for _, p in game:GetService("Players"):GetPlayers() do if p.Character then table.insert(ex, p.Character) end end
	params.FilterDescendantsInstances = ex
	local feetY = hrp.Position.Y - hrp.Size.Y / 2 - hum.HipHeight
	local reach = hrp.Size.X / 2 + 0.9
	local base = Vector3.new(hrp.Position.X, feetY, hrp.Position.Z)
	local hit = workspace:Raycast(base + Vector3.new(0, MIN_STEP, 0), dir * reach, params)
	if not hit or hit.Normal.Y > 0.5 then return end -- немає стіни або це схил
	-- верх уступу: згори вниз, трохи за точкою удару
	local px = hit.Position + dir * 0.4
	local top = workspace:Raycast(Vector3.new(px.X, feetY + MAX_STEP + 0.3, px.Z), Vector3.new(0, -(MAX_STEP + 0.3), 0), params)
	if not top or top.Normal.Y < 0.7 then return end
	local h = top.Position.Y - feetY
	if h < MIN_STEP or h > MAX_STEP then return end
	-- місце для персонажа над уступом
	local tall = hum.HipHeight + hrp.Size.Y + 1.2
	if workspace:Raycast(top.Position + Vector3.new(0, 0.05, 0), Vector3.new(0, tall, 0), params) then return end
	-- і над головою зараз (щоб не втиснути в стелю)
	if workspace:Raycast(hrp.Position, Vector3.new(0, hrp.Size.Y / 2 + h + 0.6, 0), params) then return end
	last = now
	hrp.CFrame = hrp.CFrame + Vector3.new(0, h + 0.08, 0) + dir * 0.25
	local v = hrp.AssemblyLinearVelocity
	if v.Y < 0 then hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z) end
end)
