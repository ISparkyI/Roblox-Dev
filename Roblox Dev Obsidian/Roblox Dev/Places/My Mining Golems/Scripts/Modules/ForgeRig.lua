--!strict
-- ForgeRig — скелет голема-коваля Forge: суглоби, пози, удар молотом.
-- Де: ReplicatedStorage/Shared/ForgeRig. Користуються ForgeClient (анімація) і будівельний скрипт (поза сну в шаблоні).
--
-- Координати сцени Forge («веб-координати») рахуються від деталі Forge/ForgeOrigin:
--   +X — до передньої стіни ніші, +Z — до центру ніші, +Y — вгору, 0 = рівень підлоги ніші.
-- Голем побудований з деталей Stone Golem (одиниці моделі), масштаб SC.
-- Уся сцена збільшена в S разів: пози й точки нижче — у «веб-одиницях», у стади їх множить rootCF.
-- Кожна деталь голема має атрибути Joint (назва суглоба) і Off (CFrame відносно суглоба).

local Rig = {}
local V = Vector3.new
local D = math.rad
local S = 1.8 -- масштаб сцени Forge (веб-одиниця → стади)
Rig.S = S
local SC = 1.35 * S
Rig.SC = SC

local PIV = {
	root = V(0, 0, 0),
	legL = V(0.9, 2.55, 0.03), legR = V(-0.9, 2.55, 0.03),
	skirt = V(0, 3.05, -1.02), -- верх фартуха на поясі; висить від тулуба
	upper = V(0, 2.6, 0.03),
	head = V(0, 5.05, -0.25),
	armR = V(-2.45, 4.75, 0.03), armL = V(2.45, 4.75, 0.03),
	wrist = V(-2.65, 1.85, -0.17),
}
Rig.PIV = PIV

-- [name, sx, sy, sz, x, y, z, rx, ry, rz, hex] — деталі Workspace/StoneGolem (без рота й брів: їх замінено)
Rig.PARTS = {
	{"BackPlateLow",1.50,0.70,0.30,0.00,3.20,1.13,-175.4,-0.2,177.1,"66717e"},{"BackPlateUp",2.20,1.30,0.30,0.00,4.30,1.18,174.3,-0.2,-177.7,"66717e"},
	{"CrystalShine",0.17,0.17,0.10,0.16,3.85,-1.42,-180.0,-0.0,-135.0,"f1f5f8"},{"Head",1.80,1.40,1.65,-0.00,5.75,-0.30,-180.0,-0.0,-180.0,"8b96a3"},
	{"BackShardS",0.25,0.65,0.25,0.00,5.00,1.18,-149.7,-30.6,-163.4,"6fd3e0"},{"BackShard_L",0.35,0.95,0.35,0.55,4.65,1.28,-153.6,24.6,-170.7,"6fd3e0"},
	{"BackShard_R",0.35,0.95,0.35,-0.55,4.65,1.28,-153.6,-24.6,170.7,"6fd3e0"},{"Pelvis",2.70,0.80,1.60,0.00,2.60,0.03,-180.0,-0.0,-180.0,"8b96a3"},
	{"Thigh_L",1.20,0.90,1.20,0.90,2.10,0.03,-180.0,-5.7,-180.0,"8b96a3"},{"Thigh_R",1.20,0.90,1.20,-0.90,2.10,0.03,-180.0,5.7,-180.0,"8b96a3"},
	{"KneePlate_L",0.80,0.60,0.25,0.98,1.30,-0.52,-167.4,3.4,179.2,"66717e"},{"Crystal",0.65,0.65,0.30,-0.00,3.85,-1.22,-180.0,-0.0,-135.0,"6fd3e0"},
	{"CorePlate",1.50,1.20,0.30,-0.00,3.80,-1.07,-180.0,-0.0,-180.0,"66717e"},{"Chest",4.00,0.80,2.35,0.00,4.80,0.10,-180.0,-0.0,-180.0,"8b96a3"},
	{"Torso",3.50,2.00,2.10,0.00,3.90,0.03,-180.0,-0.0,-180.0,"8b96a3"},{"Fist_L",1.60,1.20,1.60,2.65,1.85,-0.17,-180.0,6.9,-180.0,"8b96a3"},
	{"Foot_L",1.40,0.50,1.80,0.95,0.25,-0.17,-180.0,5.7,-180.0,"66717e"},{"Knuckles_R",1.30,0.60,0.20,-2.75,1.95,-1.02,-180.0,-6.9,-180.0,"66717e"},
	{"Toe_R",0.95,0.40,0.95,-1.04,0.22,-1.04,-180.0,-50.7,-180.0,"66717e"},{"Knuckles_L",1.30,0.60,0.20,2.75,1.95,-1.02,-180.0,6.9,-180.0,"66717e"},
	{"EyeShine_L",0.08,0.06,0.15,0.31,5.91,-1.20,-180.0,-0.0,-180.0,"f1f5f8"},{"EyeShine_R",0.08,0.06,0.15,-0.31,5.91,-1.20,-180.0,-0.0,-180.0,"f1f5f8"},
	{"Foot_R",1.40,0.50,1.80,-0.95,0.25,-0.17,-180.0,-5.7,-180.0,"66717e"},{"Forearm_L",1.30,1.20,1.40,2.60,2.95,-0.12,-180.0,-5.7,-180.0,"8b96a3"},
	{"Shin_L",1.10,1.30,1.10,0.95,1.10,0.03,-180.0,3.4,-180.0,"8b96a3"},{"UpperArm_L",1.10,1.30,1.20,2.45,4.10,0.03,-180.0,4.6,-180.0,"8b96a3"},
	{"ElbowPlate_R",0.25,0.80,0.90,-3.27,3.10,-0.19,-180.0,5.7,171.4,"66717e"},{"UpperArm_R",1.10,1.30,1.20,-2.45,4.10,0.03,-180.0,-4.6,-180.0,"8b96a3"},
	{"KneePlate_R",0.80,0.60,0.25,-0.98,1.30,-0.52,-167.4,-3.4,-179.2,"66717e"},{"ElbowPlate_L",0.25,0.80,0.90,3.27,3.10,-0.19,-180.0,-5.7,-171.4,"66717e"},
	{"Toe_L",0.95,0.40,0.95,1.04,0.22,-1.04,-180.0,50.7,-180.0,"66717e"},{"Cheek_L",0.24,0.12,0.12,0.73,5.50,-1.11,-180.0,-0.0,-180.0,"f2a0b4"},
	{"Fist_R",1.60,1.20,1.60,-2.65,1.85,-0.17,-180.0,-6.9,-180.0,"8b96a3"},{"Cheek_R",0.24,0.12,0.12,-0.73,5.50,-1.11,-180.0,-0.0,-180.0,"f2a0b4"},
	{"Shin_R",1.10,1.30,1.10,-0.95,1.10,0.03,-180.0,-3.4,-180.0,"8b96a3"},{"ShoulderTop_L",0.80,0.25,1.00,2.52,5.28,0.14,173.2,27.9,-165.7,"8b96a3"},
	{"ShoulderShard_R",0.25,0.70,0.25,-2.70,5.43,0.39,-164.5,-15.0,144.1,"6fd3e0"},{"Jaw",1.60,0.45,1.40,-0.00,5.18,-0.47,-180.0,-0.0,-180.0,"8b96a3"},
	{"ShoulderShard_L",0.25,0.70,0.25,2.70,5.43,0.39,-164.5,15.0,-144.1,"6fd3e0"},{"BrowRidge",1.70,0.30,0.40,-0.00,6.38,-0.97,-180.0,-0.0,-180.0,"8b96a3"},
	{"Forearm_R",1.30,1.20,1.40,-2.60,2.95,-0.12,-180.0,5.7,-180.0,"8b96a3"},{"HeadCap",1.30,0.35,1.10,0.10,6.43,0.08,-177.9,-19.9,-173.9,"66717e"},
	{"Pupil_L",0.30,0.34,0.15,0.37,5.82,-1.15,-180.0,-0.0,-180.0,"1c2836"},{"Shoulder_R",1.40,0.70,1.60,-2.30,4.95,0.03,179.4,-2.8,167.4,"66717e"},
	{"Pupil_R",0.30,0.34,0.15,-0.38,5.82,-1.15,-180.0,-0.0,-180.0,"1c2836"},{"Shoulder_L",1.40,0.70,1.60,2.30,4.95,0.03,179.4,2.8,-167.4,"66717e"},
	{"EyeWhite_L",0.55,0.55,0.15,0.42,5.88,-1.10,-180.0,-0.0,-180.0,"f1f5f8"},{"ShoulderTop_R",0.80,0.25,1.00,-2.52,5.28,0.14,173.2,-27.9,165.7,"8b96a3"},
	{"EyeWhite_R",0.55,0.55,0.15,-0.43,5.88,-1.10,-180.0,-0.0,-180.0,"f1f5f8"},
	-- нейтральне обличчя: рівні брови, рівний рот
	{"Brow_L",0.62,0.14,0.15,0.43,6.25,-1.12,0,0,-3,"66717e"},{"Brow_R",0.62,0.14,0.15,-0.43,6.25,-1.12,0,0,3,"66717e"},
	{"Mouth",0.66,0.11,0.15,0,5.38,-1.15,0,0,0,"1c2836"},
	-- шкіряний фартух
	-- спідниця фартуха: висить від пояса з нахилом 8° до ніг (низ майже торкається колін)
	{"ApronSkirt",2.9,2.25,0.16,0,1.93,-0.95,-8,0,0,"6b4430"},{"ApronHem",2.95,0.22,0.2,0,0.86,-0.83,-8,0,0,"4e3122"},
	{"ApronSplit",0.06,1.1,0.18,0,1.42,-0.90,-8,0,0,"4e3122"},{"ApronPocket",1.1,0.75,0.12,0.55,2.2,-1.11,-8,0,0,"4e3122"},
	{"ApronRivet",0.1,0.1,0.06,0.08,2.52,-1.15,-8,0,0,"a3adb8"},{"ApronRivet",0.1,0.1,0.06,1.02,2.52,-1.15,-8,0,0,"a3adb8"},
	{"BeltFront",3.75,0.36,0.2,0,3.12,-1.12,0,0,0,"3d2a1d"},{"BeltSide",0.2,0.36,2.3,1.85,3.12,0.03,0,0,0,"3d2a1d"},{"BeltSide",0.2,0.36,2.3,-1.85,3.12,0.03,0,0,0,"3d2a1d"},
	{"BeltBack",3.75,0.36,0.2,0,3.12,1.2,0,0,0,"3d2a1d"},{"Buckle",0.6,0.5,0.12,-1.0,3.12,-1.25,0,0,0,"a3adb8"},{"BuckleIn",0.3,0.26,0.14,-1.0,3.12,-1.28,0,0,0,"3d2a1d"},
	{"BeltKnot",0.5,0.35,0.3,0.3,3.12,1.4,0,0,25,"4e3122"},
	{"Bib",0.55,1.5,0.14,-0.83,3.95,-1.27,0,0,0,"6b4430"},{"Bib",0.55,1.5,0.14,0.83,3.95,-1.27,0,0,0,"6b4430"},
	{"BibTop",1.12,0.32,0.14,0,4.54,-1.27,0,0,0,"6b4430"},{"BibLow",1.12,0.12,0.14,0,3.32,-1.27,0,0,0,"6b4430"},
	{"BibRim",1.24,0.1,0.16,0,4.36,-1.28,0,0,0,"4e3122"},{"BibRim",0.1,1.06,0.16,-0.57,3.83,-1.28,0,0,0,"4e3122"},{"BibRim",0.1,1.06,0.16,0.57,3.83,-1.28,0,0,0,"4e3122"},
	{"BibRivet",0.12,0.12,0.06,-1.0,4.6,-1.36,0,0,0,"a3adb8"},{"BibRivet",0.12,0.12,0.06,1.0,4.6,-1.36,0,0,0,"a3adb8"},
	{"BibRivet",0.12,0.12,0.06,-1.0,3.35,-1.36,0,0,0,"a3adb8"},{"BibRivet",0.12,0.12,0.06,1.0,3.35,-1.36,0,0,0,"a3adb8"},
	{"Strap",0.3,0.62,0.12,-0.92,4.92,-1.19,0,0,0,"4e3122"},{"Strap",0.3,0.62,0.12,0.92,4.92,-1.19,0,0,0,"4e3122"},
	{"StrapTop",0.3,0.12,2.5,-0.92,5.26,0.1,0,0,0,"4e3122"},{"StrapTop",0.3,0.12,2.5,0.92,5.26,0.1,0,0,0,"4e3122"},
	{"StrapBack",0.3,2.1,0.12,-0.92,4.15,1.42,0,0,14,"4e3122"},{"StrapBack",0.3,2.1,0.12,0.92,4.15,1.42,0,0,-14,"4e3122"},
}

-- молот у правому кулаці: позиції відносно точки кулака (FIST_R), одиниці моделі
Rig.HAMMER = {
	{"Handle",0.32,0.32,2.6,0,0,-0.9,"a8754a"},{"Grip",0.42,0.42,0.9,0,0,0.25,"7a5233"},
	{"HammerHead",0.85,1.45,0.85,0,0,-2.3,"6e7884"},{"HammerCap",0.98,0.26,0.98,0,-0.73,-2.3,"a3adb8"},
	{"HammerCap",0.98,0.26,0.98,0,0.73,-2.3,"a3adb8"},{"HammerBand",0.92,0.28,0.92,0,0,-2.3,"5b6470"},
}
Rig.STRIKE_FACE = V(0, -0.87, -2.3) -- низ голівки молота, відносно кулака

-- повіки: точка повороту (верх повіки) у моделі, розмір пластини
-- повіка лежить на обличчі (задня грань = передня грань голови, z -1.125) і накриває білок і зіницю;
-- відблиски й зіниці клієнт ховає, коли око закривається, тому повіка не стирчить перед обличчям
Rig.LIDS = { { side = "L", pivot = V(0.425, 6.17, -1.185) }, { side = "R", pivot = V(-0.425, 6.17, -1.185) } }
Rig.LID_SIZE = V(0.6, 0.6, 0.12)
Rig.LASH_DEPTH = 0.22 -- вія товща за повіку, щоб її край було видно (правило 0.1)

local LEG_L = { Thigh_L = true, Shin_L = true, Foot_L = true, Toe_L = true, KneePlate_L = true }
local LEG_R = { Thigh_R = true, Shin_R = true, Foot_R = true, Toe_R = true, KneePlate_R = true }
local ARM = { UpperArm = true, Forearm = true, Fist = true, Knuckles = true, ElbowPlate = true, Shoulder = true, ShoulderTop = true, ShoulderShard = true }
local HEAD = { Head = true, Jaw = true, BrowRidge = true, HeadCap = true, EyeWhite_L = true, EyeWhite_R = true, Pupil_L = true, Pupil_R = true,
	EyeShine_L = true, EyeShine_R = true, Cheek_L = true, Cheek_R = true, Brow_L = true, Brow_R = true, Mouth = true }
local SKIRT = { ApronSkirt = true, ApronHem = true, ApronSplit = true, ApronPocket = true, ApronRivet = true }

function Rig.jointOf(name: string): string
	if name == "Pelvis" then return "root" end
	if LEG_L[name] then return "legL" end
	if LEG_R[name] then return "legR" end
	if SKIRT[name] then return "skirt" end
	if HEAD[name] then return "head" end
	local base, side = string.match(name, "^(%a+)_([LR])$")
	if base and ARM[base] then return side == "R" and "armR" or "armL" end
	return "upper"
end

-- зсув деталі відносно її суглоба
function Rig.offset(joint: string, pos: Vector3, rx: number, ry: number, rz: number): CFrame
	return CFrame.new((pos - PIV[joint]) * SC) * CFrame.Angles(D(rx), D(ry), D(rz))
end

-- пози (світ сцени Forge). Місце роботи — за ковадлом під навісом, сон — спиною до стіни.
local SMITHY = CFrame.new(-7.4, 0, -7.5) * CFrame.Angles(0, D(13), 0) * CFrame.new(7.4, 0, 7.5)
Rig.SMITHY = SMITHY
local WP = SMITHY * V(-9.6, 0, -9.8)
local WYAW, SYAW = math.pi + D(19), math.pi + D(13)
local SP = SMITHY * V(-8.5, 0, -10.0) -- сон: спиною до дощатої стінки навісу (підібрано так, щоб нічого не перетинав)
Rig.WYAW = WYAW
local function P(t) return t end
Rig.POSE = {
	work   = P{ x = WP.X, y = 0, z = WP.Z, yaw = WYAW, legL = 0, legR = 0, spread = 0, lean = 2, headX = 0, headZ = 0, armR = 78, wrist = -40, armRz = 0, armL = 14, armLz = 0 },
	idleW  = P{ x = WP.X, y = 0, z = WP.Z, yaw = WYAW, legL = 0, legR = 0, spread = 0, lean = 1, headX = 0, headZ = 0, armR = 20, wrist = -72, armRz = 0, armL = 10, armLz = 0 },
	standW = P{ x = WP.X, y = 0, z = WP.Z, yaw = WYAW, legL = 0, legR = 0, spread = 0, lean = 1, headX = 0, headZ = 0, armR = 6, wrist = -10, armRz = 0, armL = 6, armLz = 0 },
	standS = P{ x = SP.X, y = 0, z = SP.Z, yaw = SYAW, legL = 0, legR = 0, spread = 0, lean = 1, headX = 0, headZ = 0, armR = 6, wrist = -10, armRz = 0, armL = 6, armLz = 0 },
	sleep  = P{ x = SP.X, y = -1.8, z = SP.Z, yaw = SYAW, legL = 84, legR = 78, spread = 12, lean = -15, headX = -20, headZ = 9, armR = 34, wrist = -10, armRz = -10, armL = 30, armLz = 10 },
}

function Rig.blend(a, b, t: number)
	local o = {}
	for k, v in a do o[k] = v + (b[k] - v) * t end
	return o
end

function Rig.walk(a, b, u: number, ph: number)
	local p = Rig.blend(a, b, u)
	local s = math.sin(ph)
	p.legL = s * 24; p.legR = -s * 24; p.armL = 8 - s * 14; p.armR = 6 + s * 14; p.y = math.abs(math.cos(ph)) * 0.15
	return p
end

-- удар молотом, цикл 1.9 с; HIT — момент удару
local function eio(t) return -(math.cos(math.pi * t) - 1) / 2 end
Rig.PH = {
	{ t0 = 0.00, t1 = 0.62, a = { 78, 150 }, w = { -40, 18 }, l = { 2, -3 }, e = eio },
	{ t0 = 0.62, t1 = 0.76, a = { 150, 152 }, w = { 18, 22 }, l = { -3, -4 }, e = function(t) return t end },
	{ t0 = 0.76, t1 = 0.92, a = { 152, 52 }, w = { 22, -52 }, l = { -4, 6 }, e = function(t) return t * t * t end },
	{ t0 = 0.92, t1 = 1.10, a = { 52, 60 }, w = { -52, -44 }, l = { 6, 4 }, e = function(t) return 1 - (1 - t) * (1 - t) end },
	{ t0 = 1.10, t1 = 1.90, a = { 60, 78 }, w = { -44, -40 }, l = { 4, 2 }, e = function(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end },
}
Rig.CYCLE, Rig.HIT = 1.9, 0.92
Rig.STRIKE_ARM = 52 -- кут руки (і -кут кисті) у момент удару; під цю позу ставиться ковадло
function Rig.strikeAt(t: number)
	for i, p in Rig.PH do
		if t <= p.t1 then
			local u = p.e(math.clamp((t - p.t0) / (p.t1 - p.t0), 0, 1))
			return i, p.a[1] + (p.a[2] - p.a[1]) * u, p.w[1] + (p.w[2] - p.w[1]) * u, p.l[1] + (p.l[2] - p.l[1]) * u
		end
	end
	return 0, 78, -40, 2
end

function Rig.rootCF(origin: CFrame, p): CFrame
	-- +0.1 стада: ступні стоять НА підлозі, а не в ній
	return origin * CFrame.new(p.x * S, p.y * S + 0.1, p.z * S) * CFrame.Angles(0, p.yaw, 0)
end

-- світові CFrame суглобів для пози p
function Rig.solve(root: CFrame, p)
	local J = { root = root }
	local function at(par: string, j: string, rot: CFrame) J[j] = J[par] * CFrame.new((PIV[j] - PIV[par]) * SC) * rot end
	at("root", "legL", CFrame.Angles(D(p.legL), 0, D(p.spread)))
	at("root", "legR", CFrame.Angles(D(p.legR), 0, D(-p.spread)))
	at("root", "upper", CFrame.Angles(D(-p.lean), 0, 0))
	-- фартух кріпиться до тулуба (рухається з ним), але висить прямо й відходить, коли піднімаються коліна
	at("upper", "skirt", CFrame.Angles(D(p.lean + math.max(0, math.max(p.legL, p.legR) - 6) * 0.85), 0, 0))
	at("upper", "head", CFrame.Angles(D(p.headX), 0, D(p.headZ)))
	at("upper", "armR", CFrame.Angles(0, 0, D(-8 + p.armRz)) * CFrame.Angles(D(p.armR), 0, 0))
	at("upper", "armL", CFrame.Angles(0, 0, D(8 + p.armLz)) * CFrame.Angles(D(p.armL), 0, 0))
	at("armR", "wrist", CFrame.Angles(D(p.wrist), 0, 0))
	return J
end

return Rig
