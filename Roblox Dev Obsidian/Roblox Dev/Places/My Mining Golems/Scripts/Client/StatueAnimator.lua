--!nonstrict
-- StatueAnimator — анімації статуй топ-1 над лідербордами (Workspace/Cave/Hub/Leaderboards/<key>/Statue). 29.10.2026.
-- Де: StarterPlayer/StarterPlayerScripts/StatueAnimator (LocalScript). Статую ставить сервер (StatsService, анкерована).
-- Без Animation-асетів: процедурна анімація на клієнті — кожен кадр деталі ставляться від HumanoidRootPart по суглобах
--   (Motor6D / Weld / AnimationConstraint / RigidConstraint): Part1 = Part0 · C0 · поворот · C1⁻¹. Поворот задається в осях
--   батьківської деталі (X — вправо, Y — вгору, −Z — вперед), тому та сама поза працює для R6 і R15.
-- Ролі суглобів: neck, waist (R6 — RootJoint), lSh / rSh, lEl / rEl, lHip / rHip, lKnee / rKnee (лікті й коліна — лише R15).
-- Кожне табло — своя анімація (ANIMS[key]): функція часу t → { root = CFrame, [роль] = CFrame }. Оновлюється лише
--   статуя ближче за NEAR стадів до камери.
local RunService = game:GetService("RunService")

local NEAR = 160
local rad = math.rad
local sin, cos, abs = math.sin, math.cos, math.abs
local A = CFrame.Angles
local function pulse(t: number, period: number, len: number): number -- 0…1…0 за len секунд на початку кожного періоду
	local x = t % period
	if x > len then return 0 end
	return sin(x / len * math.pi)
end

local ROLE = {
	Neck = "neck", Waist = "waist", RootJoint = "waist",
	LeftShoulder = "lSh", ["Left Shoulder"] = "lSh", RightShoulder = "rSh", ["Right Shoulder"] = "rSh",
	LeftElbow = "lEl", RightElbow = "rEl",
	LeftHip = "lHip", ["Left Hip"] = "lHip", RightHip = "rHip", ["Right Hip"] = "rHip",
	LeftKnee = "lKnee", RightKnee = "rKnee",
}

-- анімації (градуси в осях батька): плече X+ — рука вперед, праве Z+ / ліве Z− — рука в бік угору;
-- лікоть X+ — згин вперед; шия / пояс Y — поворот, X — кивок, Z — нахил вбік
local ANIMS = {
	-- TOP MONEY: «багатій» — руки в боки (кулаки на поясі), повільний поворот голови, легке гойдання; раз на 4 с — кивок
	Money = function(t)
		local nod = pulse(t, 4, 0.6)
		return {
			root = CFrame.new(0, sin(t * 2) * 0.08, 0),
			neck = A(rad(-12 * nod), sin(t * 0.8) * rad(25), 0),
			waist = A(0, sin(t * 0.8) * rad(6), 0),
			lSh = A(0, 0, rad(-35)), rSh = A(0, 0, rad(35)),
			lEl = A(rad(70), 0, 0), rEl = A(rad(70), 0, 0),
		}
	end,
	-- TOP INCOME / MIN: «туди дивись» — права рука показує вгору-вперед і веде зліва направо, голова слідкує
	Income = function(t)
		local s = sin(t * 1.2)
		return {
			root = CFrame.new(0, sin(t * 2.4) * 0.05, 0),
			rSh = A(rad(125), s * rad(25), 0), rEl = A(rad(8), 0, 0),
			lSh = A(rad(-8), 0, rad(-8)),
			neck = A(rad(8), s * rad(20), 0),
			waist = A(0, s * rad(8), 0),
		}
	end,
	-- TOP ROLLS: «рулетка» — повільно крутиться на місці з розведеними руками, руки хвилею
	Rolls = function(t)
		return {
			root = CFrame.new(0, 0.1 + sin(t * 3) * 0.08, 0) * A(0, t * 1.4, 0),
			lSh = A(0, 0, rad(-80 + sin(t * 3) * 10)), rSh = A(0, 0, rad(80 + sin(t * 3 + 1.5) * 10)),
			neck = A(rad(-10), 0, sin(t * 3) * rad(6)),
		}
	end,
	-- TOP BEST ROLL: «ДЖЕКПОТ» — стрибок з обома руками вгору раз на 2 с, між стрибками — присідання
	BestRoll = function(t)
		local j = pulse(t, 2, 0.7)
		local crouch = pulse(t + 0.35, 2, 0.35)
		return {
			root = CFrame.new(0, j * 1.6 - crouch * 0.3, 0),
			lSh = A(rad(20 * j), 0, rad(-150 * j - 15)), rSh = A(rad(20 * j), 0, rad(150 * j + 15)),
			lHip = A(rad(25 * crouch), 0, 0), rHip = A(rad(25 * crouch), 0, 0),
			lKnee = A(rad(-45 * crouch), 0, 0), rKnee = A(rad(-45 * crouch), 0, 0),
			neck = A(rad(-15 * j), 0, 0),
		}
	end,
	-- TOP DONATORS: «привіт» — махає правою рукою над головою, ліва на поясі
	Donators = function(t)
		local w = sin(t * 7)
		return {
			root = CFrame.new(0, sin(t * 2) * 0.06, 0),
			rSh = A(0, 0, rad(150 + w * 18)), rEl = A(0, 0, rad(w * 25)),
			lSh = A(0, 0, rad(-35)), lEl = A(rad(70), 0, 0),
			neck = A(0, 0, w * rad(5)),
			waist = A(0, 0, rad(-4)),
		}
	end,
	-- TOP GIFTERS: «дарує» — простягає обидві руки вперед і вклоняється, потім випрямляється
	Gifters = function(t)
		local b = (1 - cos(t * 1.6)) / 2
		return {
			root = CFrame.new(0, sin(t * 3.2) * 0.04, 0),
			waist = A(rad(18 * b), 0, 0),
			neck = A(rad(10 * b), 0, 0),
			lSh = A(rad(55 + 25 * b), 0, rad(10)), rSh = A(rad(55 + 25 * b), 0, rad(-10)),
			lEl = A(rad(25), 0, 0), rEl = A(rad(25), 0, 0),
		}
	end,
	-- TOP PLAYTIME: «танець» — хитається з боку в бік, руки по черзі вгору, голова в такт
	Playtime = function(t)
		local s = sin(t * 3)
		local b = abs(sin(t * 3))
		return {
			root = CFrame.new(s * 0.25, b * 0.25, 0) * A(0, 0, -s * rad(6)),
			lSh = A(rad(20), 0, rad(-(40 + 80 * math.max(0, s)))), rSh = A(rad(20), 0, rad(40 + 80 * math.max(0, -s))),
			lEl = A(rad(40), 0, 0), rEl = A(rad(40), 0, 0),
			neck = A(0, 0, s * rad(12)),
			lHip = A(0, 0, rad(-6)), rHip = A(0, 0, rad(6)),
		}
	end,
	-- TOP BOSS SLAYERS: «боєць» — широка стійка, удари кулаками по черзі, потім рука вгору (перемога)
	Bosses = function(t)
		local ph = t % 4
		local pl = ph < 2 and pulse(ph, 1, 0.35) or 0
		local pr = ph < 2 and pulse(ph + 0.5, 1, 0.35) or 0
		local win = ph >= 2.4 and pulse(ph - 2.4, 1.6, 1.6) or 0
		return {
			root = CFrame.new(0, -0.15 + sin(t * 4) * 0.04, 0),
			waist = A(0, rad(20 * (pr - pl)), 0),
			lSh = A(rad(50 + 40 * pl), 0, rad(-10)), lEl = A(rad(100 - 90 * pl), 0, 0),
			rSh = A(rad(50 + 40 * pr + 60 * win), 0, rad(10 + 60 * win)), rEl = A(rad(100 - 90 * math.max(pr, win)), 0, 0),
			lHip = A(0, 0, rad(-12)), rHip = A(0, 0, rad(12)),
			neck = A(rad(-10 * win), 0, 0),
		}
	end,
}

-- ===== статуя: дерево суглобів від HumanoidRootPart =====
local statues = {} -- model → { root, base, order = { { p0, p1, C0, C1, rot0, role } }, anim }
local function build(model: Model, key: string)
	local root = model:FindFirstChild("HumanoidRootPart")
	local anim = ANIMS[key]
	if not (root and anim) then return end
	local joints = {}
	for _, j in model:GetDescendants() do
		if (j:IsA("Motor6D") or j:IsA("Weld")) and j.Part0 and j.Part1 then
			table.insert(joints, { p0 = j.Part0, p1 = j.Part1, C0 = j.C0, C1 = j.C1, role = ROLE[j.Name] })
		elseif (j:IsA("AnimationConstraint") or j:IsA("RigidConstraint")) and j.Attachment0 and j.Attachment1 then
			local a0, a1 = j.Attachment0, j.Attachment1
			if a0.Parent:IsA("BasePart") and a1.Parent:IsA("BasePart") then
				table.insert(joints, { p0 = a0.Parent, p1 = a1.Parent, C0 = a0.CFrame, C1 = a1.CFrame, role = j:IsA("AnimationConstraint") and ROLE[j.Name] or nil })
			end
		end
	end
	-- порядок від кореня (кожна деталь — один раз), напрям суглоба — від вже поставленої деталі
	local done = { [root] = true }
	local order = {}
	local progress = true
	while progress do
		progress = false
		for _, j in joints do
			if not j.used then
				if done[j.p0] and not done[j.p1] then
					j.used = true; done[j.p1] = true; progress = true
					table.insert(order, { j.p0, j.p1, j.C0, j.C1:Inverse(), j.C0.Rotation, j.role, false })
				elseif done[j.p1] and not done[j.p0] then
					j.used = true; done[j.p0] = true; progress = true
					table.insert(order, { j.p1, j.p0, j.C1, j.C0:Inverse(), j.C1.Rotation, j.role, true })
				end
			end
		end
	end
	statues[model] = { root = root, base = root.CFrame, order = order, anim = anim, t0 = math.random() * 10 }
end

local function step()
	local cam = workspace.CurrentCamera
	local cp = cam and cam.CFrame.Position or Vector3.zero
	local now = os.clock()
	for model, s in statues do
		if not model.Parent then statues[model] = nil; continue end
		if (s.base.Position - cp).Magnitude > NEAR then continue end
		local pose = s.anim(now + s.t0)
		s.root.CFrame = s.base * (pose.root or CFrame.identity)
		local parts = {}
		for _, o in s.order do
			local rot = o[6] and pose[o[6]]
			local j = rot and (o[5]:Inverse() * (o[7] and rot:Inverse() or rot) * o[5]) or CFrame.identity
			o[2].CFrame = o[1].CFrame * o[3] * j * o[4]
		end
	end
end
RunService.RenderStepped:Connect(step)

local function watch(board: Instance)
	local function try(ch)
		if ch.Name == "Statue" and ch:IsA("Model") then
			task.defer(function()
				ch:WaitForChild("HumanoidRootPart", 10)
				task.wait(0.5) -- деталі й суглоби дорепліковуються
				if ch.Parent == board then build(ch, board.Name) end
			end)
		end
	end
	board.ChildAdded:Connect(try)
	for _, ch in board:GetChildren() do try(ch) end
end
task.spawn(function()
	local cave = workspace:WaitForChild("Cave", 60)
	local hub = cave and cave:WaitForChild("Hub", 60)
	local lb = hub and hub:WaitForChild("Leaderboards", 60)
	if not lb then return end
	lb.ChildAdded:Connect(watch)
	for _, b in lb:GetChildren() do watch(b) end
end)
