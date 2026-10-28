--!strict
-- WorkshopGolem — модель голема-майстра Workshop «Брасс» (латунь і мідь, топка в грудях, лупа на оці, вуса, кепка,
--   димар на спині, 6 рук). Чернетка 28.10.2026.
-- Де: ReplicatedStorage/Shared/WorkshopGolem. Скелет і пози — WorkshopRig (ті самі суглоби, що в коваля Forge).
-- Розмір — не більший за голема-коваля (рішення користувача): усі деталі в «одиницях моделі» ForgeRig, верх кепки ≈ 6.6.
-- Деталь: { name, joint, shape, sx, sy, sz, x, y, z, rx, ry, rz, color, mat? }
--   shape: "B" — блок, "C" — циліндр (вісь X; для вертикального rz = 90, «вперед» ry = 90), "S" — куля.
--   x, y, z — позиція в позі спокою (одиниці моделі), обличчя дивиться в -Z.
-- Build(parent) створює деталі з атрибутами Joint і Off (як у ForgeRig) — WorkshopClient ставить їм CFrame щокадру.

local Rig = require(script.Parent:WaitForChild("WorkshopRig"))
local M = {}
local V = Vector3.new
local D = math.rad

-- палітра
local BRASS, BRASS_L, BRASS_D = "c39a4c", "d8b46a", "8f6d2e"
local COPPER, COPPER_D = "b0683f", "7a4630"
local IRON, IRON_D = "5b6470", "3a3f47"
local LEATHER, LEATHER_D = "6b4430", "4e3122"
local INK = "1c2836"
local WHITE = "f1f5f8"
local FIRE = "ff6a1a"

local P = {}
local function add(t) table.insert(P, t) end
local function mirror(t)
	local m = table.clone(t)
	m[1] = string.gsub(t[1], "_R$", "_L"); m[1] = string.gsub(m[1], "_MR$", "_ML"); m[1] = string.gsub(m[1], "_BR$", "_BL")
	m[2] = string.gsub(t[2], "R$", "L")
	m[7] = -t[7]; m[11] = -t[11]; m[12] = -t[12]
	return m
end
local function pair(t) add(t); add(mirror(t)) end

-- ===== тулуб: котел-бочка, обручі, ярмо плечей, топка з вогнем =====
add({ "Pelvis", "root", "B", 2.6, 0.8, 1.6, 0, 2.6, 0.03, 0, 0, 0, COPPER_D })
add({ "Boiler", "upper", "C", 2.15, 3.0, 3.0, 0, 3.82, 0.05, 0, 0, 90, BRASS })
add({ "BoilerBandTop", "upper", "C", 0.22, 3.12, 3.12, 0, 4.78, 0.05, 0, 0, 90, COPPER })
add({ "BoilerBandLow", "upper", "C", 0.16, 3.08, 3.08, 0, 3.28, 0.05, 0, 0, 90, BRASS_D })
add({ "Yoke", "upper", "B", 3.7, 0.36, 1.8, 0, 4.98, 0.15, 0, 0, 0, COPPER_D })
add({ "Collar", "upper", "C", 0.22, 1.5, 1.5, 0, 5.12, -0.2, 0, 0, 90, IRON_D })
add({ "FireboxRim", "upper", "C", 0.3, 1.45, 1.45, 0, 3.85, -1.42, 0, 90, 0, IRON })
add({ "FireboxGlow", "upper", "C", 0.1, 1.12, 1.12, 0, 3.85, -1.55, 0, 90, 0, FIRE, "Neon" })
for i, x in { -0.3, 0, 0.3 } do add({ "FireboxBar" .. i, "upper", "B", 0.09, 1.05, 0.08, x, 3.85, -1.62, 0, 0, 0, IRON_D }) end
add({ "FireboxDoorHinge", "upper", "B", 0.16, 0.5, 0.16, -0.75, 3.85, -1.5, 0, 0, 0, IRON_D })
-- заклепки на верхньому обручі (по колу радіуса 1.56 спереду)
for _, a in { -60, -30, 0, 30, 60 } do
	add({ "Rivet", "upper", "S", 0.16, 0.16, 0.16, math.sin(D(a)) * 1.58, 4.78, 0.05 - math.cos(D(a)) * 1.58, 0, 0, 0, BRASS_L })
end
-- спина: бак і димар з парою
add({ "BackTank", "upper", "B", 1.6, 1.4, 0.5, 0, 4.15, 1.5, 0, 0, 0, COPPER })
add({ "Chimney", "upper", "C", 1.3, 0.55, 0.55, 0.62, 5.55, 1.25, 0, 0, 90, IRON })
add({ "ChimneyCap", "upper", "C", 0.18, 0.78, 0.78, 0.62, 6.25, 1.25, 0, 0, 90, IRON_D })
-- пояс-патронташ з інструментами
add({ "Belt", "upper", "C", 0.42, 3.22, 3.22, 0, 2.95, 0.05, 0, 0, 90, LEATHER_D })
add({ "Buckle", "upper", "B", 0.6, 0.5, 0.12, -0.95, 2.95, -1.55, 0, 0, 0, BRASS_L })
add({ "Pouch", "upper", "B", 0.5, 0.55, 0.3, 0.95, 2.85, -1.42, 0, 0, 0, LEATHER })
add({ "PouchFlap", "upper", "B", 0.54, 0.18, 0.34, 0.95, 3.07, -1.43, 0, 0, 0, LEATHER_D })
add({ "BeltWrench", "upper", "B", 0.14, 0.8, 0.1, 1.42, 2.7, -0.95, 0, 0, -15, IRON })
add({ "BeltFile", "upper", "B", 0.12, 0.7, 0.08, -1.48, 2.7, -0.85, 0, 0, 12, IRON_D })

-- ===== фартух (суглоб skirt) =====
add({ "ApronSkirt", "skirt", "B", 2.8, 2.1, 0.16, 0, 1.95, -1.05, -8, 0, 0, LEATHER })
add({ "ApronHem", "skirt", "B", 2.85, 0.22, 0.2, 0, 0.92, -0.92, -8, 0, 0, LEATHER_D })
add({ "ApronPocket", "skirt", "B", 1.0, 0.7, 0.12, -0.6, 2.15, -1.2, -8, 0, 0, LEATHER_D })
add({ "ApronRivet", "skirt", "B", 0.1, 0.1, 0.06, -1.02, 2.47, -1.25, -8, 0, 0, BRASS_L })
add({ "ApronRivet", "skirt", "B", 0.1, 0.1, 0.06, -0.18, 2.47, -1.25, -8, 0, 0, BRASS_L })

-- ===== голова: кругляш з латуні, кепка, лупа на правому оці, вуса, ніс-клепка =====
add({ "Head", "head", "B", 2.0, 1.4, 1.75, 0, 5.78, -0.3, 0, 0, 0, BRASS_L })
add({ "HeadSide_L", "head", "B", 0.12, 1.1, 1.4, 1.04, 5.78, -0.3, 0, 0, 0, BRASS_D })
add({ "HeadSide_R", "head", "B", 0.12, 1.1, 1.4, -1.04, 5.78, -0.3, 0, 0, 0, BRASS_D })
add({ "Jaw", "head", "B", 1.7, 0.36, 1.5, 0, 5.2, -0.42, 0, 0, 0, BRASS })
add({ "CapCrown", "head", "B", 2.04, 0.2, 1.8, 0, 6.55, -0.28, 0, 0, 0, LEATHER_D })
add({ "CapBrim", "head", "B", 1.8, 0.1, 0.6, 0, 6.47, -1.4, -6, 0, 0, LEATHER_D })
add({ "CapButton", "head", "B", 0.3, 0.06, 0.3, 0, 6.66, -0.28, 0, 0, 0, BRASS_L })
add({ "EarBolt_R", "head", "C", 0.22, 0.5, 0.5, -1.14, 5.8, -0.3, 0, 0, 0, COPPER })
add({ "EarBolt_L", "head", "C", 0.22, 0.5, 0.5, 1.14, 5.8, -0.3, 0, 0, 0, COPPER })
-- око (ліве — звичайне)
add({ "EyeWhite_L", "head", "B", 0.5, 0.5, 0.15, 0.42, 5.96, -1.18, 0, 0, 0, WHITE })
add({ "Pupil_L", "head", "B", 0.26, 0.3, 0.15, 0.4, 5.92, -1.23, 0, 0, 0, INK })
add({ "EyeShine_L", "head", "B", 0.08, 0.06, 0.15, 0.33, 6.00, -1.28, 0, 0, 0, WHITE })
-- праве око під лупою (збільшене)
add({ "EyeWhite_R", "head", "B", 0.56, 0.56, 0.05, -0.43, 5.96, -1.565, 0, 0, 0, WHITE })
add({ "Pupil_R", "head", "B", 0.34, 0.38, 0.04, -0.43, 5.93, -1.6, 0, 0, 0, INK })
add({ "EyeShine_R", "head", "B", 0.1, 0.08, 0.03, -0.53, 6.03, -1.625, 0, 0, 0, WHITE })
add({ "LoupeRim", "head", "C", 0.32, 0.8, 0.8, -0.43, 5.96, -1.38, 0, 90, 0, BRASS_D })
add({ "LoupeLens", "head", "C", 0.03, 0.66, 0.66, -0.43, 5.96, -1.66, 0, 90, 0, "bfefff", "Glass" })
add({ "LoupeShine", "head", "B", 0.16, 0.08, 0.02, -0.58, 6.12, -1.68, 0, 0, 35, WHITE })
add({ "LoupeStrap", "head", "B", 2.02, 0.14, 1.78, 0, 6.18, -0.3, 0, 0, 0, LEATHER_D })
add({ "Brow_L", "head", "B", 0.58, 0.14, 0.15, 0.43, 6.33, -1.18, 0, 0, -4, IRON_D })
add({ "Brow_R", "head", "B", 0.58, 0.14, 0.15, -0.43, 6.35, -1.18, 0, 0, 8, IRON_D })
add({ "Nose", "head", "B", 0.36, 0.34, 0.28, 0, 5.62, -1.26, 0, 0, 0, COPPER })
add({ "Mustache_L", "head", "B", 0.78, 0.3, 0.3, 0.4, 5.40, -1.26, 0, 0, -14, IRON_D })
add({ "Mustache_R", "head", "B", 0.78, 0.3, 0.3, -0.4, 5.40, -1.26, 0, 0, 14, IRON_D })
add({ "MustacheTip_L", "head", "B", 0.3, 0.22, 0.26, 0.86, 5.54, -1.24, 0, 0, 30, IRON_D })
add({ "MustacheTip_R", "head", "B", 0.3, 0.22, 0.26, -0.86, 5.54, -1.24, 0, 0, -30, IRON_D })

-- ===== ноги =====
pair({ "Thigh_R", "legR", "B", 1.15, 0.9, 1.15, -0.9, 2.1, 0.03, 0, 0, 0, COPPER_D })
pair({ "Shin_R", "legR", "B", 1.05, 1.3, 1.05, -0.95, 1.1, 0.03, 0, 0, 0, BRASS })
pair({ "KneePlate_R", "legR", "C", 0.22, 0.7, 0.7, -0.98, 1.4, -0.55, 0, 90, 0, COPPER })
pair({ "Foot_R", "legR", "B", 1.4, 0.5, 1.8, -0.95, 0.25, -0.17, 0, 0, 0, IRON })
pair({ "Toe_R", "legR", "B", 1.0, 0.36, 0.45, -0.95, 0.2, -1.05, 0, 0, 0, IRON_D })

-- ===== верхні руки (масивні: молот у правій, ліва вільна) =====
pair({ "Shoulder_R", "armR", "C", 0.7, 1.5, 1.5, -2.35, 4.85, 0.03, 0, 0, 0, COPPER })
pair({ "UpperArm_R", "armR", "B", 1.05, 1.3, 1.15, -2.45, 4.1, 0.03, 0, 0, 0, BRASS })
pair({ "ElbowPlate_R", "armR", "C", 0.3, 0.9, 0.9, -3.05, 3.2, -0.12, 0, 0, 0, COPPER_D })
pair({ "Forearm_R", "armR", "B", 1.25, 1.2, 1.35, -2.6, 2.95, -0.12, 0, 0, 0, BRASS_L })
pair({ "Cuff_R", "armR", "B", 1.35, 0.22, 1.45, -2.62, 2.42, -0.15, 0, 0, 0, COPPER })
pair({ "Fist_R", "armR", "B", 1.5, 1.15, 1.5, -2.65, 1.85, -0.17, 0, 0, 0, IRON })
pair({ "Knuckles_R", "armR", "B", 1.25, 0.55, 0.2, -2.75, 1.95, -0.98, 0, 0, 0, IRON_D })

-- ===== середні руки (механічні, з ліктем): з боків котла під верхніми руками, працюють спереду на рівні пояса; плече (armMR) + передпліччя з клешнею (elMR) =====
pair({ "Socket_MR", "armMR", "S", 0.56, 0.56, 0.56, -1.6, 3.75, 0.45, 0, 0, 0, COPPER_D })
pair({ "Sleeve_MR", "armMR", "C", 0.92, 0.5, 0.5, -1.6, 3.233, 0.45, 0, 0, 90, COPPER })
pair({ "UpperRod_MR", "armMR", "C", 1.035, 0.36, 0.36, -1.6, 2.6, 0.45, 0, 0, 90, IRON })
pair({ "Hose_MR", "armMR", "C", 1.15, 0.14, 0.14, -1.6, 2.888, 0.72, 0, 0, 90, "2b2f35" })
pair({ "Elbow_MR", "elMR", "S", 0.6, 0.6, 0.6, -1.6, 2.255, 0.45, 0, 0, 0, COPPER_D })
pair({ "ElbowPin_MR", "elMR", "C", 0.5, 0.22, 0.22, -1.6, 2.255, 0.45, 0, 0, 0, BRASS_L })
pair({ "PistonRing_MR", "elMR", "C", 0.115, 0.58, 0.58, -1.6, 1.887, 0.45, 0, 0, 90, BRASS_L })
pair({ "Piston_MR", "elMR", "C", 1.265, 0.46, 0.46, -1.6, 1.393, 0.45, 0, 0, 90, IRON })
pair({ "ClawBase_MR", "elMR", "B", 0.82, 0.32, 0.82, -1.6, 0.645, 0.45, 0, 0, 0, IRON_D })
pair({ "ClawA_MR", "elMR", "B", 0.22, 0.805, 0.26, -1.6, 0.208, 0.18, 18, 0, 0, BRASS_D })
pair({ "ClawB_MR", "elMR", "B", 0.22, 0.805, 0.26, -1.6, 0.208, 0.72, -18, 0, 0, BRASS_D })
pair({ "ClawC_MR", "elMR", "B", 0.22, 0.805, 0.26, -1.87, 0.208, 0.45, 0, 0, -18, BRASS_D })
-- ===== нижні руки (тонкі, точні, з ліктем): спереду на поясі; різець справа, кристал зліва =====
pair({ "Socket_BR", "armBR", "S", 0.56, 0.56, 0.56, -1.15, 3, -1.15, 0, 0, 0, COPPER_D })
pair({ "Rod_BR", "armBR", "C", 0.92, 0.34, 0.34, -1.15, 2.483, -1.15, 0, 0, 90, BRASS_L })
pair({ "Elbow_BR", "elBR", "S", 0.44, 0.44, 0.44, -1.15, 1.965, -1.15, 0, 0, 0, COPPER_D })
pair({ "RodRing_BR", "elBR", "C", 0.092, 0.4, 0.4, -1.15, 1.712, -1.15, 0, 0, 90, COPPER_D })
pair({ "Fore_BR", "elBR", "C", 0.92, 0.3, 0.3, -1.15, 1.39, -1.15, 0, 0, 90, BRASS_L })
pair({ "Grip_BR", "elBR", "B", 0.42, 0.34, 0.42, -1.15, 0.838, -1.15, 0, 0, 0, IRON })
-- нижні руки: інструменти (дисковий різак, кристал, кристал середньої лівої) — у M.Tools (зсуви в стадах простору ліктя)

-- ===== деталі (v2): шви й заклепки котла, манометр, вентиль, труби, заклепки голови, пальці, болти =====
add({ "BoilerSeam", "upper", "B", 0.14, 1.7, 0.06, -1.172, 3.95, -0.933, 0, 50, 0, BRASS_D })
add({ "SeamRivet", "upper", "S", 0.13, 0.13, 0.13, -1.21, 3.35, -0.966, 0, 0, 0, BRASS_L })
add({ "SeamRivet", "upper", "S", 0.13, 0.13, 0.13, -1.21, 3.95, -0.966, 0, 0, 0, BRASS_L })
add({ "SeamRivet", "upper", "S", 0.13, 0.13, 0.13, -1.21, 4.55, -0.966, 0, 0, 0, BRASS_L })
add({ "BoilerSeam", "upper", "B", 0.14, 1.7, 0.06, 1.172, 3.95, -0.933, 0, -50, 0, BRASS_D })
add({ "SeamRivet", "upper", "S", 0.13, 0.13, 0.13, 1.21, 3.35, -0.966, 0, 0, 0, BRASS_L })
add({ "SeamRivet", "upper", "S", 0.13, 0.13, 0.13, 1.21, 3.95, -0.966, 0, 0, 0, BRASS_L })
add({ "SeamRivet", "upper", "S", 0.13, 0.13, 0.13, 1.21, 4.55, -0.966, 0, 0, 0, BRASS_L })
add({ "Rivet", "upper", "S", 0.13, 0.13, 0.13, -1.003, 3.28, -1.145, 0, 0, 0, BRASS_L })
add({ "Rivet", "upper", "S", 0.13, 0.13, 0.13, -0.404, 3.28, -1.457, 0, 0, 0, BRASS_L })
add({ "Rivet", "upper", "S", 0.13, 0.13, 0.13, 0.404, 3.28, -1.457, 0, 0, 0, BRASS_L })
add({ "Rivet", "upper", "S", 0.13, 0.13, 0.13, 1.003, 3.28, -1.145, 0, 0, 0, BRASS_L })
add({ "GaugeBody", "upper", "C", 0.16, 0.56, 0.56, -0.91, 4.38, -1.205, 0, -54, 0, IRON_D })
add({ "GaugeFace", "upper", "C", 0.03, 0.44, 0.44, -0.95, 4.38, -1.26, 0, -54, 0, "f4efe2" })
add({ "GaugeNeedle", "upper", "B", 0.04, 0.2, 0.02, -0.97, 4.41, -1.285, 0, 36, -35, "d23b2b" })
add({ "ValvePipe", "upper", "C", 0.3, 0.2, 0.2, 1.6, 4.15, 0.25, 0, 0, 0, COPPER_D })
add({ "ValveWheel", "upper", "C", 0.08, 0.62, 0.62, 1.78, 4.15, 0.25, 0, 0, 0, "c8412f" })
add({ "ValveHub", "upper", "C", 0.12, 0.18, 0.18, 1.8, 4.15, 0.25, 0, 0, 0, IRON_D })
add({ "PipeBack", "upper", "C", 1.2, 0.24, 0.24, -0.6, 4.75, 1.42, 0, 0, 90, COPPER })
add({ "PipeElbow", "upper", "S", 0.3, 0.3, 0.3, -0.6, 5.35, 1.42, 0, 0, 0, COPPER_D })
add({ "TankRivet", "upper", "S", 0.12, 0.12, 0.12, -0.6, 4.7, 1.76, 0, 0, 0, BRASS_L })
add({ "TankRivet", "upper", "S", 0.12, 0.12, 0.12, 0.6, 4.7, 1.76, 0, 0, 0, BRASS_L })
add({ "TankRivet", "upper", "S", 0.12, 0.12, 0.12, -0.6, 3.6, 1.76, 0, 0, 0, BRASS_L })
add({ "TankRivet", "upper", "S", 0.12, 0.12, 0.12, 0.6, 3.6, 1.76, 0, 0, 0, BRASS_L })
add({ "ChimneySoot", "upper", "C", 0.1, 0.6, 0.6, 0.62, 6.36, 1.25, 0, 0, 90, "1f1f22" })
add({ "FireboxHandle", "upper", "B", 0.12, 0.3, 0.12, 0.74, 3.85, -1.56, 0, 0, 0, BRASS_L })
add({ "HeadRivet", "head", "S", 0.12, 0.12, 0.12, -0.86, 5.2, -1.19, 0, 0, 0, BRASS_D })
add({ "HeadRivet", "head", "S", 0.12, 0.12, 0.12, -0.86, 6.3, -1.19, 0, 0, 0, BRASS_D })
add({ "HeadRivet", "head", "S", 0.12, 0.12, 0.12, 0.86, 5.2, -1.19, 0, 0, 0, BRASS_D })
add({ "HeadRivet", "head", "S", 0.12, 0.12, 0.12, 0.86, 6.3, -1.19, 0, 0, 0, BRASS_D })
add({ "Mouth", "head", "B", 0.5, 0.1, 0.05, 0, 5.22, -1.2, 0, 0, 0, INK })
add({ "CapBand", "head", "B", 2.06, 0.06, 1.82, 0, 6.47, -0.28, 0, 0, 0, BRASS })
add({ "StrapBuckle", "head", "B", 0.08, 0.24, 0.3, 1.03, 6.18, -0.65, 0, 0, 0, BRASS_L })
add({ "Cheek_L", "head", "B", 0.24, 0.12, 0.05, 0.62, 5.66, -1.19, 0, 0, 0, "e08a5a" })
pair({ "ArmRivet_R", "armR", "S", 0.13, 0.13, 0.13, -2.45, 4.4, -0.6, 0, 0, 0, BRASS_L })
pair({ "ArmRivetB_R", "armR", "S", 0.13, 0.13, 0.13, -2.45, 3.85, -0.6, 0, 0, 0, BRASS_L })
pair({ "BicepBand_R", "armR", "B", 1.12, 0.16, 1.22, -2.47, 3.62, 0, 0, 0, 0, COPPER })
pair({ "ElbowBolt_R", "armR", "C", 0.12, 0.3, 0.3, -3.24, 3.2, -0.12, 0, 0, 0, BRASS_L })
pair({ "Vent1_R", "armR", "B", 0.04, 0.08, 0.8, -3.24, 3.05, -0.12, 0, 0, 0, IRON_D })
pair({ "Vent2_R", "armR", "B", 0.04, 0.08, 0.8, -3.24, 2.85, -0.12, 0, 0, 0, IRON_D })
pair({ "FingerA_R", "armR", "B", 0.34, 0.48, 0.3, -2.25, 1.6, -0.98, 0, 0, 0, IRON })
pair({ "FingerB_R", "armR", "B", 0.34, 0.48, 0.3, -2.65, 1.6, -0.98, 0, 0, 0, IRON })
pair({ "FingerC_R", "armR", "B", 0.34, 0.48, 0.3, -3.05, 1.6, -0.98, 0, 0, 0, IRON })
pair({ "Thumb_R", "armR", "B", 0.3, 0.45, 0.42, -1.85, 1.95, -0.6, 0, 0, -12, IRON })
pair({ "BootCuff_R", "legR", "B", 1.15, 0.2, 1.15, -0.95, 0.58, 0.03, 0, 0, 0, COPPER })
pair({ "KneeBolt_R", "legR", "S", 0.18, 0.18, 0.18, -0.98, 1.4, -0.68, 0, 0, 0, BRASS_L })
pair({ "ShinRivet_R", "legR", "S", 0.12, 0.12, 0.12, -0.95, 0.95, -0.54, 0, 0, 0, BRASS_L })
pair({ "BootLace_R", "legR", "B", 0.6, 0.08, 0.04, -0.95, 0.42, -1.08, 0, 0, 0, LEATHER_D })
pair({ "ToeCapRivet_R", "legR", "S", 0.12, 0.12, 0.12, -0.95, 0.3, -1.29, 0, 0, 0, BRASS_L })

-- повіки (сон і кліпання; клієнт масштабує висоту від верхнього краю — атрибут LidOff, як у голема-коваля)
-- повіка стоїть ПЕРЕД зіницею й відблиском (вони не протикають її, коли око закрите)
M.LIDS = { { name = "Lid_L", pivot = V(0.42, 6.22, -1.37), w = 0.56 }, { name = "Lid_R", pivot = V(-0.43, 6.25, -1.64), w = 0.62 } }
M.PARTS = P

local STUDS_VARIANT = "Studs" -- MaterialService/Studs (Roblox Studs: колір + normal map), база Plastic
local SHAPE = { B = Enum.PartType.Block, C = Enum.PartType.Cylinder, S = Enum.PartType.Ball }

-- зсув деталі відносно суглоба (як ForgeRig.offset)
function M.offset(d): CFrame
	return CFrame.new((V(d[7], d[8], d[9]) - Rig.PIV[d[2]]) * Rig.SC) * CFrame.Angles(D(d[10]), D(d[11]), D(d[12]))
end

-- створює деталі в parent (Model); повертає кількість
function M.Build(parent: Instance): number
	for _, d in P do
		local p = Instance.new("Part")
		p.Name = d[1]
		p.Shape = SHAPE[d[3]]
		p.Size = V(d[4], d[5], d[6]) * Rig.SC
		p.Color = Color3.fromHex(d[13])
		p.Material = d[14] and Enum.Material[d[14]] or Enum.Material.SmoothPlastic
		if d[14] == "Glass" then p.Transparency = 0.55 end
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = d[14] ~= "Neon"
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		-- studs — матеріал Roblox (MaterialVariant «Studs» на Plastic) на всіх деталях, крім неону й скла; без накладних Texture
		if not d[14] then
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = STUDS_VARIANT
		end
		if d[1] == "FireboxGlow" then
			local l = Instance.new("PointLight"); l.Name = "FireLight"; l.Color = Color3.fromHex("ff9a4a"); l.Range = 10; l.Brightness = 1.6; l.Parent = p
		end
		p:SetAttribute("Joint", d[2])
		p:SetAttribute("Off", M.offset(d))
		p.Parent = parent
	end
	for _, l in M.LIDS do
		local p = Instance.new("Part")
		p.Name = l.name; p.Size = V(l.w, 0.6, 0.08) * Rig.SC; p.Color = Color3.fromHex(BRASS_D); p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p:SetAttribute("LidOff", CFrame.new((l.pivot - Rig.PIV.head) * Rig.SC))
		p.Parent = parent
		-- вії: темна смужка по нижньому краю повіки (видно лише коли око закрите)
		local lash = Instance.new("Part")
		lash.Name = string.gsub(l.name, "^Lid", "Lash"); lash.Size = V(l.w + 0.04, 0.09, 0.1) * Rig.SC; lash.Color = Color3.fromHex(INK)
		lash.Material = Enum.Material.SmoothPlastic; lash.Transparency = 1
		lash.Anchored = true; lash.CanCollide = false; lash.CanQuery = false; lash.CanTouch = false
		lash:SetAttribute("LidOff", CFrame.new((l.pivot - Rig.PIV.head) * Rig.SC))
		lash.Parent = parent
	end
	M.Tools(parent)
	return #P
end

-- Інструменти рук (28.10.2026): дисковий різак на нижній правій (диск і прорізи крутить WorkshopClient за SpinC),
-- кристал у нижній лівій (CrystalPart; видно лише під час огранювання, з 3-ї карти) і кристал у клешні середньої лівої
-- (GrindCrystal; ховається до 3-ї карти). Зсуви Off — у стадах простору суглоба (elBR / elBL / elML).
function M.Tools(parent: Instance)
	local R = math.rad
	local Z90 = CFrame.Angles(0, 0, R(90))
	local function mk(name: string, joint: string, shape: string, size: Vector3, off: CFrame, hex: string, mat: Enum.Material?, attrs: { [string]: any }?)
		local p = shape == "Wedge" and Instance.new("WedgePart") or Instance.new("Part")
		p.Name = name
		if shape ~= "Wedge" then (p :: Part).Shape = Enum.PartType[shape] end
		p.Size = size; p.Color = Color3.fromHex(hex)
		if mat then p.Material = mat else p.Material = Enum.Material.Plastic; p.MaterialVariant = "StudsMedium" end
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p:SetAttribute("Joint", joint); p:SetAttribute("Off", off)
		for k, v in attrs or {} do p:SetAttribute(k, v) end
		p.Parent = parent
		return p
	end
	mk("CutterBody_BR", "elBR", "Cylinder", V(1.0, 0.66, 0.66), CFrame.new(0, -3.3, 0) * Z90, "c39a4c", nil, { Cutter = true })
	mk("CutterBand_BR", "elBR", "Cylinder", V(0.14, 0.74, 0.74), CFrame.new(0, -3.05, 0) * Z90, "3d434b", nil, { Cutter = true })
	mk("CutterNose_BR", "elBR", "Cylinder", V(0.4, 0.34, 0.34), CFrame.new(0, -3.95, 0) * Z90, "3d434b", nil, { Cutter = true })
	mk("CutterGuard_BR", "elBR", "Block", V(0.3, 0.12, 1.0), CFrame.new(0, -4.12, -0.35), "b0683f", nil, { Cutter = true })
	local DC = V(0, -4.35, 0)
	local SM = Enum.Material.SmoothPlastic
	mk("CutterRim_BR", "elBR", "Cylinder", V(0.08, 1.5, 1.5), CFrame.new(DC), "7b8590", SM, { Cutter = true, SpinC = DC })
	mk("CutterDisc_BR", "elBR", "Cylinder", V(0.12, 1.22, 1.22), CFrame.new(DC), "c9ced5", SM, { Cutter = true, SpinC = DC })
	mk("CutterHub_BR", "elBR", "Cylinder", V(0.2, 0.36, 0.36), CFrame.new(DC), "c39a4c", SM, { Cutter = true, SpinC = DC })
	for i = 0, 3 do
		mk("CutterSlot_BR", "elBR", "Cylinder", V(0.14, 0.12, 0.3), CFrame.new(DC) * CFrame.Angles(i * math.pi / 2, 0, 0) * CFrame.new(0, 0.42, 0), "3d434b", SM, { Cutter = true, SpinC = DC })
	end
	local CC = CFrame.new(0, -3.55, 0) * CFrame.Angles(0, R(45), 0)
	local G, NE = Enum.Material.Glass, Enum.Material.Neon
	local b = mk("CrystalBody_BL", "elBL", "Block", V(0.62, 1.0, 0.62), CC, "9a5cd6", G, { CrystalPart = "body" })
	local c = mk("CrystalCore_BL", "elBL", "Block", V(0.28, 0.85, 0.28), CC, "c99bff", NE, { CrystalPart = "core" })
	local ta = mk("CrystalTipA_BL", "elBL", "Wedge", V(0.62, 0.5, 0.31), CC * CFrame.new(0, -0.75, -0.155) * CFrame.Angles(R(180), 0, 0), "9a5cd6", G, { CrystalPart = "body" })
	local tb = mk("CrystalTipB_BL", "elBL", "Wedge", V(0.62, 0.5, 0.31), CC * CFrame.new(0, -0.75, 0.155) * CFrame.Angles(R(180), R(180), 0), "9a5cd6", G, { CrystalPart = "body" })
	for _, p in { b, c, ta, tb } do p.Transparency = 1 end
	local gc = mk("GrindCrystal", "elML", "Block", V(0.55, 1.6, 0.55), CFrame.new(0, -6.0, 0), "9a5cd6", G)
	gc.Transparency = 0.2
	local gcc = mk("GrindCrystalCore", "elML", "Block", V(0.28, 1.35, 0.28), CFrame.new(0, -6.0, 0), "c99bff", NE)
	gcc.Transparency = 0.25
end

return M
