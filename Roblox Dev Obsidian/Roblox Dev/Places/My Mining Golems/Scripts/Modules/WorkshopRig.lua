--!strict
-- WorkshopRig — скелет 6-рукого голема-майстра Workshop (заміна голема-коваля Forge; чернетка 28.10.2026).
-- Де: ReplicatedStorage/Shared/WorkshopRig. Користуються WorkshopClient (анімація) і будівельний скрипт (поза в шаблоні).
-- Основа — ForgeRig (ті самі деталі, суглоби, координати сцени від ForgeOrigin, масштаб S і SC). Додано дві пари рук:
--   середні (armMR / armML) — з боків котла під верхніми руками, з ліктем (elMR / elML); подають руду в піч і знімають заготовку;
--   нижні (armBR / armBL) — спереду на поясі, з ліктем (elBR / elBL); огранюють кристал (різець справа, кристал зліва).
-- Верхні руки — як у коваля: права з молотом (суглоб wrist), ліва — кліщі.
-- Кожна деталь має атрибути Joint і Off (CFrame відносно суглоба), як у ForgeRig.
-- Без перетинів рук: середні рухаються лише по шляхах Rig.MPATH (вузли перевірено GetPartsInPart при всіх фазах удару);
--   коли верхні руки опущені (сон, вставання) — середні складені (REST). Нижні — bR 30…95 (уві сні 110 — кисті на колінах).
--   Перевірено в Play (WorkshopClient + DraftDriver, 28.10.2026): сон, пробудження, робота, засинання — 0 кадрів з перетином.
-- Пози: поля ForgeRig.POSE + mR, mRz, mRy, mRe, mL, mLz, mLy, mLe (середні: плече + лікоть), bR, bRz, bRy, bRe, bL, bLz, bLy, bLe
--   (нижні), tong (кут кліщів лівої верхньої).

local ForgeRig = require(script.Parent:WaitForChild("ForgeRig"))
local Rig = {}
local V = Vector3.new
local D = math.rad
local S, SC = ForgeRig.S, ForgeRig.SC
Rig.S, Rig.SC = S, SC
Rig.Base = ForgeRig

local PIV = table.clone(ForgeRig.PIV)
-- суглоби нових рук (одиниці моделі, як PIV ForgeRig)
PIV.armMR = V(-1.6, 3.75, 0.45); PIV.armML = V(1.6, 3.75, 0.45)   -- з боків котла під верхніми руками
PIV.armBR = V(-1.15, 3.0, -1.15); PIV.armBL = V(1.15, 3.0, -1.15) -- спереду на поясі
-- лікті (у позі спокою руки звисають прямо вниз): середні — плече 1.5 + передпліччя з клешнею 2.1, нижні — 1.04 + 1.04 (+15 % 28.10)
PIV.elMR = V(-1.6, 2.255, 0.45); PIV.elML = V(1.6, 2.255, 0.45)
PIV.elBR = V(-1.15, 1.965, -1.15); PIV.elBL = V(1.15, 1.965, -1.15)
Rig.PIV = PIV
Rig.K = { M = 0.8, B = 0.66 } -- масштаб середніх і нижніх рук відносно верхніх
-- деталі верхньої руки, які копіюються для нових рук (без наплічних кристалів — вони лише на верхніх)
Rig.ARM_PARTS = { "Shoulder", "UpperArm", "ElbowPlate", "Forearm", "Fist", "Knuckles" }
Rig.EXTRA = {
	{ joint = "armMR", side = "R", tier = "M" }, { joint = "armML", side = "L", tier = "M" },
	{ joint = "armBR", side = "R", tier = "B" }, { joint = "armBL", side = "L", tier = "B" },
}

-- розмір і зсув деталі нової руки: з деталі верхньої руки (ForgeRig.PARTS) у масштабі k
local PDEF: { [string]: any } = {}
for _, d in ForgeRig.PARTS do if not PDEF[d[1]] then PDEF[d[1]] = d end end
function Rig.extraPart(base: string, ex): (Vector3, CFrame)
	local d = PDEF[base .. "_" .. ex.side]
	local k = Rig.K[ex.tier]
	local top = PIV[ex.side == "R" and "armR" or "armL"]
	local pos = V(d[5], d[6], d[7])
	local size = V(d[2], d[3], d[4]) * SC * k
	local off = CFrame.new((pos - top) * SC * k) * CFrame.Angles(D(d[8]), D(d[9]), D(d[10]))
	return size, off
end

-- точка кулака нової руки відносно її суглоба (для предметів у руці)
function Rig.fistOffset(ex): CFrame
	local _, off = Rig.extraPart("Fist", ex)
	return CFrame.new(off.Position)
end

function Rig.jointOf(name: string): string
	local base, tag = string.match(name, "^(%a+)_([MB][RL])$")
	if base and tag then return "arm" .. tag end
	return ForgeRig.jointOf(name)
end

local function P(t)
	-- значення за замовчуванням для нових рук: середні трохи вбік, нижні вперед (не перетинають верхні)
	local d = { mR = -40, mRz = -10, mRy = 0, mRe = 40, mL = -40, mLz = 10, mLy = 0, mLe = 40, bR = 55, bRz = -6, bRy = 0, bRe = 20, bL = 55, bLz = 6, bLy = 0, bLe = 20, tong = 0 }
	for k, v in t do d[k] = v end
	return d
end
Rig.POSE = {}
for k, p in ForgeRig.POSE do Rig.POSE[k] = P(p) end
-- сон: усі руки звисають і лежать на колінах
for k, v in { mR = -8, mRz = -18, mRe = 25, mL = -8, mLz = 18, mLe = 25, bR = 110, bRz = -10, bRe = 0, bL = 110, bLz = 10, bLe = 0 } do Rig.POSE.sleep[k] = v end -- нижні — на колінах
-- очікування з молотом: ліва верхня піднята (як у роботі) — так середні руки мають місце (шляхи MPATH перевірено при armL = 40)
Rig.POSE.idleW.armL = 40
-- робота: верхні — молот і кліщі, середні — розкладені вбік (REACH), нижні — огранюють кристал перед собою
for k, v in { armL = 40, mR = -15, mRz = -60, mRe = 40, mL = 15, mLz = 60, mLe = 20, bR = 45, bRz = 8, bRe = 45, bL = 45, bLz = -8, bLe = 45 } do Rig.POSE.work[k] = v end

-- ===== шляхи середніх рук без перетинів =====
-- Знайдено пошуком по сітці кутів (крок 15° / 20°): у кожному вузлі жодна деталь середньої руки не торкається верхніх рук,
-- нижніх рук і тіла — при верхній правій руці в усіх фазах удару (armR 20…150) і armL = 40. Рух — лише по цих вузлах.
-- Вузол { a, z, e } = (кут плеча вперед, відведення вбік, згин ліктя); для лівої руки відведення дзеркальне (mLz = -z).
--   REST  — складені за верхніми руками; REACH — розкладені вбік (видно з боків); LOW — клешня внизу спереду-збоку (бере руду / злиток).
Rig.MPATH = {
	R = {
		restReach = { { -45, -15, 40 }, { -30, -15, 40 }, { -15, -15, 40 }, { -15, -30, 40 }, { -15, -45, 40 }, { -15, -60, 40 } },
		reachLow = { { -15, -60, 40 }, { -15, -45, 40 }, { -15, -30, 40 }, { -15, -15, 40 }, { -15, -15, 20 }, { 0, -15, 20 }, { 0, -15, 0 }, { 15, -15, 0 } },
		lowRest = { { 15, -15, 0 }, { 0, -15, 0 }, { -15, -15, 0 }, { -30, -15, 0 }, { -45, -15, 0 }, { -45, -15, 20 }, { -45, -15, 40 } },
	},
	L = {
		restReach = { { -45, -15, 40 }, { -30, -15, 40 }, { -15, -15, 40 }, { 0, -15, 40 }, { 15, -15, 40 }, { 15, -15, 20 }, { 15, -30, 20 }, { 15, -45, 20 }, { 15, -60, 20 } },
		reachLow = { { 15, -60, 20 }, { 15, -45, 20 }, { 15, -30, 20 }, { 15, -15, 20 }, { 15, -15, 40 } },
		lowRest = { { 15, -15, 40 }, { 0, -15, 40 }, { -15, -15, 40 }, { -30, -15, 40 }, { -45, -15, 40 } },
	},
}
-- точка на шляху (u 0…1, рівномірно по вузлах, плавно всередині відрізка); rev — у зворотному напрямку
function Rig.pathAt(list, u: number, rev: boolean?): (number, number, number)
	u = math.clamp(u, 0, 1)
	if rev then u = 1 - u end
	local n = #list - 1
	local x = u * n
	local i = math.min(n, math.floor(x)) + 1
	local t = x - (i - 1)
	t = t * t * (3 - 2 * t)
	local a, b = list[i], list[math.min(#list, i + 1)]
	return a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t
end
-- поставити середню руку side ("R" | "L") у позу p з вузла шляху
function Rig.setMid(p, side: string, a: number, z: number, e: number)
	if side == "R" then p.mR, p.mRz, p.mRe = a, z, e else p.mL, p.mLz, p.mLe = a, -z, e end
end

function Rig.blend(a, b, t: number)
	local o = {}
	for k, v in a do o[k] = v + ((b[k] or v) - v) * t end
	return o
end
function Rig.walk(a, b, u: number, ph: number)
	local p = Rig.blend(a, b, u)
	local s = math.sin(ph)
	p.legL = s * 24; p.legR = -s * 24; p.armL = 8 - s * 14; p.armR = 6 + s * 14; p.y = math.abs(math.cos(ph)) * 0.15
	p.mR = -20 + s * 8; p.mL = -20 - s * 8; p.bR = 55 - s * 6; p.bL = 55 + s * 6
	return p
end
Rig.rootCF = ForgeRig.rootCF
Rig.strikeAt = ForgeRig.strikeAt
Rig.CYCLE, Rig.HIT, Rig.STRIKE_ARM = ForgeRig.CYCLE, ForgeRig.HIT, ForgeRig.STRIKE_ARM
Rig.PH, Rig.SMITHY, Rig.WYAW, Rig.PARTS = ForgeRig.PH, ForgeRig.SMITHY, ForgeRig.WYAW, ForgeRig.PARTS
Rig.offset = ForgeRig.offset
Rig.HAMMER, Rig.STRIKE_FACE, Rig.LIDS, Rig.LID_SIZE = ForgeRig.HAMMER, ForgeRig.STRIKE_FACE, ForgeRig.LIDS, ForgeRig.LID_SIZE

-- світові CFrame усіх суглобів для пози p
function Rig.solve(root: CFrame, p)
	local J = ForgeRig.solve(root, p)
	local function at(j: string, rot: CFrame) J[j] = J.upper * CFrame.new((PIV[j] - PIV.upper) * SC) * rot end
	at("armMR", CFrame.Angles(0, D(p.mRy or 0), D(p.mRz or 0)) * CFrame.Angles(D(p.mR or 0), 0, 0))
	at("armML", CFrame.Angles(0, D(p.mLy or 0), D(p.mLz or 0)) * CFrame.Angles(D(p.mL or 0), 0, 0))
	at("armBR", CFrame.Angles(0, D(p.bRy or 0), D(p.bRz or 0)) * CFrame.Angles(D(p.bR or 0), 0, 0))
	at("armBL", CFrame.Angles(0, D(p.bLy or 0), D(p.bLz or 0)) * CFrame.Angles(D(p.bL or 0), 0, 0))
	-- лікті: згин уперед (додатний кут)
	local function el(j: string, parent: string, a: number?) J[j] = J[parent] * CFrame.new((PIV[j] - PIV[parent]) * SC) * CFrame.Angles(D(a or 0), 0, 0) end
	el("elMR", "armMR", p.mRe); el("elML", "armML", p.mLe); el("elBR", "armBR", p.bRe); el("elBL", "armBL", p.bLe)
	return J
end

return Rig
