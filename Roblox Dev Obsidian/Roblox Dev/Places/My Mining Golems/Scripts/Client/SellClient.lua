-- SellClient — клієнт лавки SELL: анімація голема-продавця Наґґета, ваги, дзвоник, рахівниця, вагонетка, табличка SELL.
-- Де: StarterPlayer/StarterPlayerScripts/SellClient (LocalScript). Модель — Niche*/Sell (будується з веб-макета ui/sell_shop).
-- Деталі голема й рухомі речі на прилавку анкеровані й мають атрибути Bone (кістка) і Off (зсув від кістки в позі спокою);
-- тут їм щокадру ставиться CFrame (тільки на клієнті). Координати лавки — «веб-одиниці» від SellOrigin (x уздовж прилавка,
-- y вгору, z вперед — до кола).
--
-- Анімації чисто косметичні й нікого не тримають:
--   • спокій: стоїть і дихає; раз на 3–5 с — особлива дія (монета, рахівниця, озирається, потирає руки);
--   • власник ніші зайшов у коло → дзвоник і вітання, далі чекає й стежить очима (раз на 3–5 с стукає пальцями / потирає руки);
--   • продаж — коли сервер збільшує атрибут Sell.SellSeq (SellAmount — сума для спливного «+$»): руда на вагах, «$» в очах,
--     неохоче платить, згрібає руду у вагонетку. Новий продаж посеред анімації — не перезапускає її (лише нові монети);
--   • власник вийшов з кола → одразу (з плавним переходом 0,35 с) прощання циліндром, хоч би що голем робив.
--   Гравця ніщо не зупиняє: вікно продажу й рух гравця від анімацій не залежать.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Rig = require(RS:WaitForChild("Shared"):WaitForChild("SellRig"))
local Cfg = require(RS.Shared:WaitForChild("ForgeConfig"))
local NF = require(RS.Shared:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer
local V, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)

local function lerp(a, b, t) return a + (b - a) * t end
local function ss(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end

-- ===== кістки: батько і місце в позі спокою (без обертань) =====
local BONES = {
	R = { "O", V(0, 1.3, 0.5) }, SP = { "R", V(0, 3.1, 0) }, H = { "SP", V(0, 4.1, 0.2) }, HT = { "H", V(0, 2.6, -0.1) },
	Beard = { "H", V(0, 0, 0) }, Mouth = { "H", V(0, 0.3, 1.37) }, MustN = { "H", V(-0.12, 0.58, 1.55) }, MustP = { "H", V(0.12, 0.58, 1.55) },
	EyeN = { "H", V(-0.76, 1.62, 1.36) }, EyeP = { "H", V(0.76, 1.62, 1.36) },
	AS = { "SP", V(2.95, 3.55, 0) }, BS = { "SP", V(-2.95, 3.55, 0) },
	BellDome = { "O", V(3.65, 4.75, 3.15) }, ScaleBase = { "O", V(-6.6, 4.6, 3.7) },
}
local CART_TOP = V(16.5, 3.2, 1.0)   -- верх вагонетки (веб-одиниці)
local ORE_COL = { Color3.fromHex("2b2e33"), Color3.fromHex("c8643a"), Color3.fromHex("d08a55") }

-- ===== анімації: розгортаємо ключові кадри в повні пози =====
local ANIMS = {}
for name, a in Rig.ANIMS do
	local keys, cur = {}, table.clone(Rig.BASE)
	for _, k in a.keys do
		cur = table.clone(cur)
		for f, v in k[2] do cur[f] = v end
		table.insert(keys, { k[1], cur })
	end
	ANIMS[name] = { len = a.len, loop = a.loop, next = a.next, keys = keys }
end
local function mix(a, b, k)
	local o = {}
	for f, va in a do
		local vb = b[f]
		if type(va) == "table" then o[f] = { lerp(va[1], vb[1], k), lerp(va[2], vb[2], k), lerp(va[3], vb[3], k) }
		else o[f] = lerp(va, vb, k) end
	end
	return o
end
local function samp(keys, t)
	if t <= keys[1][1] then return keys[1][2] end
	for i = 1, #keys - 1 do
		local t0, t1 = keys[i][1], keys[i + 1][1]
		if t <= t1 then return mix(keys[i][2], keys[i + 1][2], ss((t - t0) / math.max(1e-6, t1 - t0))) end
	end
	return keys[#keys][2]
end
local FOLLOW = { waitRest = true, tap = true, rubW = true, greet = true }

-- найкоротший поворот від a до b (одиничні вектори)
local DOWN = V(0, -1, 0)
local function fromTo(a: Vector3, b: Vector3): CFrame
	local d = math.clamp(a:Dot(b), -1, 1)
	if d > 0.99999 then return CFrame.identity end
	local ax = a:Cross(b)
	if ax.Magnitude < 1e-6 then return CFrame.fromAxisAngle(V(1, 0, 0), math.pi) end
	return CFrame.fromAxisAngle(ax.Unit, math.acos(d))
end
-- IK руки: S — плече (світ), T — ціль кулака, pole — куди дивиться лікоть. Повертає оберти плеча й ліктя (світ).
local function solveArm(S: Vector3, T: Vector3, pole: Vector3)
	local L1, L2 = Rig.L1, Rig.L2
	local d = T - S
	local len = math.clamp(d.Magnitude, 0.3, L1 + L2 - 0.02)
	local dir = d.Unit
	local cosA = math.clamp((L1 * L1 + len * len - L2 * L2) / (2 * L1 * len), -1, 1)
	local ang = math.acos(cosA)
	local P = pole - S
	local pn = P - dir * P:Dot(dir)
	pn = pn.Magnitude > 1e-6 and pn.Unit or V(0, 0, 1)
	local E = S + dir * (math.cos(ang) * L1) + pn * (math.sin(ang) * L1)
	local Tc = S + dir * len
	return fromTo(DOWN, (E - S).Unit), fromTo(DOWN, (Tc - E).Unit), E
end

-- ===== тимчасові клієнтські деталі й написи =====
local fxFolder = Instance.new("Folder")
fxFolder.Name = "SellFX"
fxFolder.Parent = workspace
local function fxPart(size: Vector3, color: Color3, shape)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Size = size; p.Color = color; p.Shape = shape or Enum.PartType.Block
	p.Material = Enum.Material.Plastic; p.MaterialVariant = "Studs"
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = fxFolder
	return p
end
local flyers = {}
local function fly(p: BasePart, from: Vector3, to: () -> Vector3, dur: number, h: number, onDone)
	p.CFrame = CF(from)
	table.insert(flyers, { p = p, from = from, to = to, t0 = os.clock(), dur = dur, h = h, done = onDone, spin = V(math.random() * 8, math.random() * 6, 0) })
end
local sparks = {}
local function sparkle(at: Vector3, n: number, color: Color3)
	for _ = 1, n do
		local p = fxPart(V(0.18, 0.18, 0.18), color)
		p.Material = Enum.Material.Neon; p.MaterialVariant = ""
		p.CFrame = CF(at)
		table.insert(sparks, { p = p, v = V((math.random() - 0.5) * 3, 1.5 + math.random() * 2.5, (math.random() - 0.5) * 3), t0 = os.clock(), life = 0.7 + math.random() * 0.4 })
	end
end
-- спливний напис над точкою (як у макеті): піднімається й згасає
local function popText(adornee: Instance, offset: Vector3, text: string, color: string, stroke: string, size: number, dur: number)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(size * 6, size * 1.6); bb.StudsOffsetWorldSpace = offset; bb.AlwaysOnTop = true; bb.LightInfluence = 0
	bb.MaxDistance = 120; bb.Adornee = adornee
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.FontFace = HEAVY; t.TextScaled = true; t.Text = text
	t.TextColor3 = Color3.fromHex(color); t.Parent = bb
	local st = Instance.new("UIStroke"); st.Color = Color3.fromHex(stroke); st.Thickness = math.max(2, size / 7); st.LineJoinMode = Enum.LineJoinMode.Round; st.Parent = t
	bb.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(bb, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = offset + V(0, 2.5, 0) }):Play()
	task.delay(dur * 0.7, function()
		TweenService:Create(t, TweenInfo.new(dur * 0.3), { TextTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(dur * 0.3), { Transparency = 1 }):Play()
	end)
	task.delay(dur, function() bb:Destroy() end)
end

-- ===== збір лавки =====
local recs = {}
local function setup(sell: Model)
	if recs[sell] or not sell:FindFirstChild("SellOrigin") then return end
	local r = {
		sell = sell, O = sell.SellOrigin.CFrame, parts = {}, special = {}, heap = {}, stack = {}, pay = {}, beads = {},
		anim = "rest", at0 = os.clock(), prev = nil, blendT = 1, pose = Rig.BASE, nextSpecial = os.clock() + 3 + math.random() * 2, lastSpecial = "",
		inRing = false, seq = sell:GetAttribute("SellSeq") or 0, fx = {}, tilt = 0, bellT = -99, blinkNext = os.clock() + 2.5, blinkT = -99,
		beadRight = { 1, 2, 0 }, heapCount = 16, panOre = {},
	}
	for _, p in sell:GetDescendants() do
		if p:IsA("BasePart") then
			local bone = p:GetAttribute("Bone")
			if bone then
				local e = { p = p, bone = bone, off = p:GetAttribute("Off"), size = p.Size }
				for _, k in { "Lid", "Pupil", "Brow", "EyeDollar", "MouthDark", "Tooth", "Tooth2", "MouthC", "HandCoin", "PayCoin", "Heart", "PanDish" } do
					local v = p:GetAttribute(k)
					if v ~= nil then e.tag = k; e.val = v end
				end
				table.insert(r.parts, e)
				if e.tag == "PayCoin" then table.insert(r.pay, p) end
				if e.tag == "HandCoin" then r.handCoin = p end
				if e.tag == "PanDish" and e.val == -1 then r.panDish = e end
				if e.tag == "Heart" then r.heartLight = p:FindFirstChildOfClass("PointLight") end
				if e.tag == "EyeDollar" then r.dollars = r.dollars or {}; table.insert(r.dollars, p:FindFirstChildOfClass("SurfaceGui")) end
			end
			local h = p:GetAttribute("Heap"); if h then r.heap[h] = p end
			local sc = p:GetAttribute("StackCoin"); if sc then r.stack[sc] = p end
			if p:GetAttribute("BeadR") ~= nil then
				local lc = r.O:ToObjectSpace(p.CFrame)
				table.insert(r.beads, { p = p, r = p:GetAttribute("BeadR"), b = p:GetAttribute("BeadB"), lc = lc, x = lc.X })
			end
			if p:GetAttribute("LampGlass") then r.lampLight = p:FindFirstChildOfClass("PointLight") end
			if p.Name == "BellDome" or (bone == "BellDome") then r.bellPart = r.bellPart or p end
		end
	end
	-- звук дзвінка (Stall/BellDome/Snd_Bell)
	r.bellSnd = sell:FindFirstChild("Snd_Bell", true) -- шукаємо у всій лавці: порядок GetDescendants між клонами не гарантований
	if r.bellSnd and r.bellSnd.SoundId ~= "" then
		task.spawn(function() pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), { r.bellSnd }) end)
	end
	local ring = sell:FindFirstChild("Ring")
	r.ringCenter = ring and ring:FindFirstChild("RingCenter")
	r.count = #sell:GetDescendants()
	recs[sell] = r
	r.teardown = function() if recs[sell] == r then recs[sell] = nil end end
	sell.AncestryChanged:Connect(function() if not sell:IsDescendantOf(workspace) then r.teardown() end end)
end

local function play(r, name: string)
	r.prev = r.pose; r.blendT = 0; r.anim = name; r.at0 = os.clock(); r.fx = {}
	if Rig.SPECIAL[name] then r.nextSpecial = os.clock() + 3 + math.random() * 2 end
end

local function ownerHRP(sell: Model): BasePart?
	-- лавки в кінці зали (Workspace/Cave/Shops, атрибут Shop): «власник» — будь-який гравець, тобто сам локальний гравець
	if sell:GetAttribute("Shop") then
		local ch = player.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		return hrp and hrp:IsA("BasePart") and hrp or nil
	end
	local niche = sell.Parent
	local uid = niche and niche:GetAttribute("OwnerUserId")
	if not uid or uid == 0 then return nil end
	local pl = Players:GetPlayerByUserId(uid)
	local ch = pl and pl.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	return hrp and hrp:IsA("BasePart") and hrp or nil
end

-- ===== один кадр лавки =====
local function step(r, now: number, dt: number)
	local O = r.O
	local hrp = ownerHRP(r.sell)
	-- коло: вхід / вихід власника
	local inside = false
	if hrp and r.ringCenter then
		local d = r.ringCenter.CFrame:PointToObjectSpace(hrp.Position)
		inside = Vector2.new(d.X, d.Z).Magnitude <= Rig.RING_R + (r.inRing and 0.5 or 0)
	end
	if inside ~= r.inRing then
		r.inRing = inside
		if inside then play(r, "greet") else play(r, "bye") end
	end
	-- продаж (сервер збільшує SellSeq)
	local seq = r.sell:GetAttribute("SellSeq") or 0
	if seq ~= r.seq then
		r.seq = seq
		local t = now - r.at0
		if r.anim == "sell" and t < 5.0 then
			r.fx.extraPay = true -- уже платить: просто ще одна жменя монет
		else
			play(r, "sell")
		end
		r.amount = r.sell:GetAttribute("SellAmount") or 0
	end
	-- покупка в лавці Diamonds Shop (сервер збільшує BuySeq) — голем-продавець радіє монеті
	local bseq = r.sell:GetAttribute("BuySeq")
	if bseq and bseq ~= r.bseq then
		if r.bseq ~= nil and ANIMS.coin then play(r, "coin") end
		r.bseq = bseq
	end
	-- вибір анімації
	local A = ANIMS[r.anim]
	local t = now - r.at0
	if Rig.SPECIAL[r.anim] and now > r.nextSpecial then
		local list = {}
		for _, n in Rig.SPECIAL[r.anim] do if n ~= r.lastSpecial then table.insert(list, n) end end
		local pick = list[math.random(1, #list)]
		r.lastSpecial = pick
		play(r, pick); A = ANIMS[pick]; t = 0
	end
	if t > A.len then
		if A.loop then r.at0 += A.len * math.floor(t / A.len); t = now - r.at0
		else
			local nx = A.next
			if (nx == "waitRest") and not r.inRing then nx = "rest" end
			play(r, nx); A = ANIMS[nx]; t = 0
		end
	end
	local p = samp(A.keys, t)
	if r.prev and r.blendT < 1 then r.blendT = math.min(1, r.blendT + dt / 0.35); p = mix(r.prev, p, ss(r.blendT)) end
	r.pose = p
	local anim = r.anim

	-- ===== кістки =====
	local breath = math.sin(now * 1.6) * 0.03
	local R = O * CF(0, 1.3, 0.5)
	local SP = R * CF(0, 3.1, 0) * ANG(p.lean + breath * 0.5, p.twist, 0)
	local follow = 0
	if hrp and r.inRing and FOLLOW[anim] then
		local gl = R:PointToObjectSpace(hrp.Position)
		follow = math.clamp(math.atan2(gl.X, gl.Z), -0.6, 0.6)
	end
	local H = SP * CF(0, 4.1, 0.2) * ANG(p.hp, p.hy + follow, p.hr)
	local B = {}
	B.R, B.SP, B.H = R, SP, H
	B.HT = H * CF(0, 2.6 + p.hat * 0.9, -0.1) * ANG(-p.hat * 0.3, 0, -0.1 + p.hat * 0.25)
	B.Beard = H * ANG(-p.mOpen * 0.12, 0, 0)
	B.Mouth = H * CF(0, 0.3, 1.37)
	B.MustN = H * CF(-0.12, 0.58, 1.55) * ANG(0, 0, -0.18 - p.mCurve * 0.08)
	B.MustP = H * CF(0.12, 0.58, 1.55) * ANG(0, 0, 0.18 + p.mCurve * 0.08)
	B.EyeN = H * CF(-0.76, 1.62, 1.36)
	B.EyeP = H * CF(0.76, 1.62, 1.36)
	-- руки (IK): потирання, постукування, тремтіння
	local rub, rubY = math.sin(now * 26) * 0.28 * p.rub, math.cos(now * 26) * 0.12 * p.rub
	local tap, trem = math.max(0, math.sin(now * 14)) * 0.28 * p.tap, math.sin(now * 45) * 0.06 * p.trem
	local handRot = R.Rotation
	for _, side in { { "A", 1, V(p.A[1] + rub + trem, p.A[2] + rubY + tap, p.A[3]), Rig.POLE.A },
		{ "B", -1, V(p.B[1] - rub, p.B[2] - rubY, p.B[3]), Rig.POLE.B } } do
		local key, s = side[1], side[2]
		local S = (SP * CF(s * 2.95, 3.55, 0)).Position
		local shR, elR, E = solveArm(S, R * side[3], R * side[4])
		local sh = CF(S) * shR
		local el = CF(E) * elR
		local hand = CF((el * CF(0, -1.8, 0)).Position) * handRot * ANG(0.25, s * 0.15, 0)
		B[key .. "S"], B[key .. "E"], B[key .. "H"] = sh, el, hand
	end
	-- дзвоник
	if anim == "greet" and t > 0.55 and not r.fx.ding then
		r.fx.ding = true; r.bellT = now
		-- звук: продавець натискає — dome провалюється на 0.06 с (уся провал 0.12 с), туди ж має потрапити пік «дзінь» у файлі (HitOffset)
		local bs = r.bellSnd
		if bs and bs.SoundId ~= "" then
			local d = math.max(0, 0.06 - (bs:GetAttribute("HitOffset") or 0))
			if d > 0 then
				task.delay(d, function() bs.TimePosition = 0; bs:Play() end)
			else
				bs.TimePosition = 0; bs:Play()
			end
		end
		if r.bellPart then sparkle(r.bellPart.Position + V(0, 1, 0), 6, Color3.fromHex("ffe27a")); popText(r.bellPart, V(0, 1.6, 0), "DING!", "ffe27a", "5a3a00", 20, 1.0) end
	end
	local bt = now - r.bellT
	local bz = bt < 0.8 and math.sin(bt * 40) * 0.25 * (1 - bt / 0.8) or 0
	local dip = bt < 0.12 and math.sin(bt / 0.12 * math.pi) * 0.15 or 0
	B.BellDome = O * CF(3.65, 4.75 - dip, 3.15) * ANG(0, 0, bz)
	-- ваги: шалька з рудою опускається на час продажу
	local tiltTarget = (anim == "sell" and t > 0.9 and t < 6.35) and 0.32 or 0
	r.tilt = lerp(r.tilt, tiltTarget, 1 - 0.002 ^ dt)
	local SB = O * CF(-6.6, 4.6, 3.7)
	B.ScaleBase = SB
	B.Beam = SB * CF(0, 3, 0) * ANG(0, 0, r.tilt)
	B.PanN = SB * CF(-Rig.SB * math.cos(r.tilt), 3 - Rig.SB * math.sin(r.tilt), 0)
	B.PanP = SB * CF(Rig.SB * math.cos(r.tilt), 3 + Rig.SB * math.sin(r.tilt), 0)

	-- ===== обличчя =====
	if now > r.blinkNext then r.blinkT = now; r.blinkNext = now + 2.5 + math.random() * 3 end
	local bk = now - r.blinkT
	local blink = bk < 0.14 and math.sin(bk / 0.14 * math.pi) or 0
	local lid = math.clamp(math.max(p.lid, blink), 0, 1)
	local sy = 1 + p.mOpen * 2.2
	local showTooth = p.mCurve > 0.55 or p.mOpen > 0.25

	-- ===== розстановка деталей =====
	local parts, cfs = {}, {}
	for _, e in r.parts do
		local bw = B[e.bone]
		if bw then
			local cf = bw * e.off
			local tag = e.tag
			if tag then
				local eyeS = e.bone == "EyeN" and -1 or 1
				if tag == "Lid" then
					local h = 0.42 * (0.4 + lid * 1.15)
					local sz = V(e.size.X, h, e.size.Z); if e.p.Size ~= sz then e.p.Size = sz end
					cf = bw * CF(0, 0.3 - lid * 0.27, 0.06)
				elseif tag == "Pupil" then
					cf = bw * CF(p.ex * 0.12, -0.03 + p.ey * 0.05, 0.04)
					local tr = p.dollar >= 0.5 and 1 or 0; if e.p.Transparency ~= tr then e.p.Transparency = tr end
				elseif tag == "Brow" then
					local b = p.brow
					cf = bw * CF(0, 0.55 + math.max(0, b - 1) * 0.25 - math.max(0, -b) * 0.03, 0.14) * ANG(0, 0, eyeS * (-0.35 * math.clamp(b, -1, 1)))
				elseif tag == "MouthDark" then
					local sz = V(1.25 * p.mWide, 0.3 * sy, 0.12); if e.p.Size ~= sz then e.p.Size = sz end
				elseif tag == "Tooth" or tag == "Tooth2" then
					local x0, y0, w0, h0 = 0.26, 0.03, 0.26, 0.22
					if tag == "Tooth2" then x0, y0, w0, h0 = -0.16, 0.04, 0.24, 0.2 end
					cf = bw * CF(x0 * p.mWide, y0 * sy, 0.05)
					local sz = V(w0 * p.mWide, h0 * sy, 0.1); if e.p.Size ~= sz then e.p.Size = sz end
					local tr = showTooth and 0 or 1; if e.p.Transparency ~= tr then e.p.Transparency = tr end
				elseif tag == "MouthC" then
					local s = e.val
					cf = bw * CF(s * 0.72 * p.mWide, (0.05 + p.mCurve * 0.13) * sy, 0) * ANG(0, 0, s * p.mCurve * 0.5)
					local sz = V(0.32 * p.mWide, 0.22 * sy, 0.12); if e.p.Size ~= sz then e.p.Size = sz end
				end
			end
			table.insert(parts, e.p); table.insert(cfs, cf)
		end
	end
	-- кісточки рахівниці: кожне клацання переводить одну кісточку ряду праворуч; повний ряд — усі назад ліворуч
	if anim == "abacus" then
		for k, tt in { 0.8, 1.3, 1.8 } do
			if t >= tt and not r.fx["ab" .. k] then
				r.fx["ab" .. k] = true
				local row = 3 - k
				r.beadRight[row + 1] += 1
				if r.beadRight[row + 1] > 5 then r.beadRight[row + 1] = 0 end
			end
		end
	end
	for _, b in r.beads do
		local k = r.beadRight[b.r + 1]
		local tx = b.b >= 5 - k and (-2.3 + 0.99 - (4 - b.b) * 0.34) or b.x
		local cur = r.O:ToObjectSpace(b.p.CFrame).X
		local nx = lerp(cur, tx, 1 - 0.0005 ^ dt)
		if math.abs(nx - cur) > 1e-3 then
			table.insert(parts, b.p); table.insert(cfs, O * CF(nx, b.lc.Y, b.lc.Z) * b.lc.Rotation)
		end
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

	-- монета (кусає й ховає), стоси, плата
	local coinOn = anim == "coin" and t > 1.0 and t < 3.75
	if r.handCoin then local tr = coinOn and 0 or 1; if r.handCoin.Transparency ~= tr then r.handCoin.Transparency = tr end end
	if anim == "coin" and t > 2.05 and not r.fx.bit and r.handCoin then r.fx.bit = true; sparkle(r.handCoin.Position, 5, Color3.fromHex("ffe27a")) end
	for i, c in r.stack do
		local hide = (anim == "coin" and i == 9 and t > 1.0) or (anim == "sell" and i >= 7 and t > 3.6)
		local tr = hide and 1 or 0; if c.Transparency ~= tr then c.Transparency = tr end
	end
	local payOn = anim == "sell" and t > 3.6 and t < 5.0
	for _, c in r.pay do local tr = payOn and 0 or 1; if c.Transparency ~= tr then c.Transparency = tr end end
	-- «$» в очах, серце-самородок, ліхтар
	if r.dollars then for _, g in r.dollars do if g then local on = p.dollar >= 0.5; if g.Enabled ~= on then g.Enabled = on end end end end
	if r.heartLight then r.heartLight.Brightness = 0.9 + math.sin(now * 3) * 0.4 + p.dollar * 1.5 end
	if r.lampLight then r.lampLight.Brightness = 1.35 + math.sin(now * 7.3) * 0.12 end

	-- ===== ефекти продажу =====
	if anim == "sell" then
		if t > 0.15 and not r.fx.ore and hrp and r.panDish then
			r.fx.ore = true
			for i = 1, 3 do
				local ore = fxPart(V(0.55, 0.5, 0.55), ORE_COL[i])
				local from = (hrp.CFrame * CF((i - 2) * 0.5, 0.6, -1.4)).Position
				local slot = V((i - 2) * 0.42, 0.35 + (i == 2 and 0.3 or 0), (i % 2) * 0.2 - 0.1)
				local function target()
					local dish = B.PanN and (r.pose and B.PanN * CF(0, -1.62, 0)) or O
					return (dish * CF(slot)).Position
				end
				fly(ore, from, target, 0.75 + i * 0.12, 4.5, function() table.insert(r.panOre, { p = ore, slot = slot }) end)
			end
		end
		if (t > 5.0 and not r.fx.paid) then
			r.fx.paid = true
			local from = r.pay[1] and r.pay[1].Position or (O * V(2, 5, 3))
			local n = r.fx.extraPay and 6 or 3
			for i = 1, n do
				local c = fxPart(V(0.12, 0.68, 0.68), Color3.fromHex("f2c14b"), Enum.PartType.Cylinder)
				c.Material = Enum.Material.SmoothPlastic; c.MaterialVariant = ""
				fly(c, from + V(0, i * 0.12, 0), function() local h = ownerHRP(r.sell); return h and (h.Position + V(0, 1.5, 0)) or from end, 0.8 + i * 0.08, 5,
					function() c:Destroy(); local h = ownerHRP(r.sell); if h then sparkle(h.Position + V(0, 1.5, 0), 3, Color3.fromHex("c8ff6a")) end end)
			end
			task.delay(0.7, function()
				local h = ownerHRP(r.sell)
				if h and (r.amount or 0) > 0 then popText(h, V(0, 3.5, 0), "+" .. NF.money(r.amount), "c8ff6a", "0b3a14", 30, 1.4) end
			end)
		end
		if t > 6.2 and not r.fx.swept then
			r.fx.swept = true
			for i, o in r.panOre do
				local from = o.p.Position
				fly(o.p, from, function() return (O * CF(CART_TOP + V((i - 2) * 0.6, 0, (i % 2) * 0.4))).Position end, 0.65 + i * 0.08, 3.5, function()
					o.p:Destroy()
					if r.heapCount < #r.heap then r.heapCount += 1; local hp = r.heap[r.heapCount]; if hp then hp.Transparency = 0 end end
				end)
			end
			r.panOre = {}
		end
	elseif #r.panOre > 0 then
		for _, o in r.panOre do o.p:Destroy() end -- продаж перервано прощанням: руду з ваг прибираємо
		r.panOre = {}
	end
	-- руда, що лежить на шальці, їде разом із нею
	if #r.panOre > 0 then
		local dish = B.PanN * CF(0, -1.62, 0)
		for _, o in r.panOre do o.p.CFrame = dish * CF(o.slot) end
	end
end

-- ===== головний цикл =====
local last = os.clock()
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local dt = math.min(0.05, now - last)
	last = now
	local cam = workspace.CurrentCamera
	for sell, r in recs do
		if not sell.Parent then recs[sell] = nil continue end
		if cam and (cam.CFrame.Position - r.O.Position).Magnitude > 170 and not r.inRing then continue end
		local ok, err = pcall(step, r, now, dt)
		if not ok then warn("SellClient: " .. tostring(err)) end
	end
	for i = #flyers, 1, -1 do
		local f = flyers[i]
		local k = math.clamp((now - f.t0) / f.dur, 0, 1)
		local to = f.to()
		local pos = f.from:Lerp(to, k) + V(0, math.sin(k * math.pi) * f.h, 0)
		f.p.CFrame = CF(pos) * ANG(f.spin.X * k * 2, f.spin.Y * k * 2, 0)
		if k >= 1 then table.remove(flyers, i); if f.done then f.done() else f.p:Destroy() end end
	end
	for i = #sparks, 1, -1 do
		local s = sparks[i]
		local a = (now - s.t0) / s.life
		s.v -= V(0, 9 * dt, 0)
		s.p.Position += s.v * dt
		local k = math.max(0.01, 1 - a); s.p.Size = V(0.18, 0.18, 0.18) * k
		if a >= 1 then s.p:Destroy(); table.remove(sparks, i) end
	end
end)

-- лавки шукаємо періодично (ніші перебудовуються, модель стрімиться цілком — Atomic)
task.spawn(function()
	while true do
		for sell, r in recs do
			if not sell:IsDescendantOf(workspace) or #sell:GetDescendants() ~= r.count then r.teardown() end
		end
		local niches = workspace:FindFirstChild("Niches")
		if niches then
			for _, n in niches:GetChildren() do
				local s = n:FindFirstChild("Sell")
				if s and not recs[s] and s:FindFirstChild("Golem") and s:FindFirstChild("SellOrigin") then
					local ok, err = pcall(setup, s) if not ok then warn("SellClient: " .. tostring(err)) end
				end
			end
		end
		-- лавки Diamonds / Events у кінці зали — ті самі анімації голема-продавця (вітання, монета при покупці)
		local shops = workspace:FindFirstChild("Cave") and workspace.Cave:FindFirstChild("Shops")
		if shops then
			for _, s in shops:GetChildren() do
				if not recs[s] and s:FindFirstChild("Golem") and s:FindFirstChild("SellOrigin") then
					local ok, err = pcall(setup, s) if not ok then warn("SellClient: " .. tostring(err)) end
				end
			end
		end
		task.wait(1)
	end
end)

-- ===== дошка цін: руда й ціни поточного етапу з ForgeConfig (ORES — руда етапу; при новому етапі зміниться конфіг) =====
task.spawn(function()
	while true do
		local niches = workspace:FindFirstChild("Niches")
		if niches then
			for _, n in niches:GetChildren() do
				local s = n:FindFirstChild("Sell")
				local board = s and s:FindFirstChild("PriceBoard", true)
				if board then
					for i = 1, 3 do
						local row = board:FindFirstChild("Row" .. i)
						local o = Cfg.ORES[i]
						if row then
							row.Visible = o ~= nil
							if o then
								if row.Ore.Text ~= o.key then row.Ore.Text = o.key end
								local pr = NF.money(o.price)
								if row.Price.Text ~= pr then row.Price.Text = pr end
							end
						end
					end
					local bars = board:FindFirstChild("Bars")
					if bars then bars.Text = "Bars  ×" .. tostring(Cfg.BAR_MULT) end
				end
			end
		end
		task.wait(2)
	end
end)

-- ===== табличка «SELL» над колом: зелений градієнт, що переливається, + білий відблиск (як FORGE) =====
do
	local SIGN_P = { Color3.fromHex("e6ffb0"), Color3.fromHex("8cf04a"), Color3.fromHex("22a838"), Color3.fromHex("8cf04a") }
	local function sample(u)
		local x = (u % 1) * #SIGN_P
		local k = math.floor(x)
		local t = x - k
		t = t * t * (3 - 2 * t)
		return SIGN_P[k + 1]:Lerp(SIGN_P[(k + 1) % #SIGN_P + 1], t)
	end
	local SHINE_T = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.32, 1), NumberSequenceKeypoint.new(0.40, 0.2),
		NumberSequenceKeypoint.new(0.48, 1), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(1, 1) })
	local signs = {}
	local function hook(sign: Instance)
		local t = sign:FindFirstChild("Title")
		if not (t and t:IsA("TextLabel")) or signs[t] then return end
		local grad = t:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", t)
		grad.Rotation = 0
		for _, old in t.Parent:GetChildren() do if old.Name == "TitleShine" then old:Destroy() end end
		local sh = t:Clone()
		sh.Name = "TitleShine"; sh.TextColor3 = Color3.new(1, 1, 1); sh.ZIndex = t.ZIndex + 1
		for _, c in sh:GetChildren() do c:Destroy() end
		local sg = Instance.new("UIGradient"); sg.Rotation = 25; sg.Transparency = SHINE_T; sg.Offset = Vector2.new(-1.3, 0); sg.Parent = sh
		sh.Parent = t.Parent
		local tw = TweenService:Create(sg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.3, 0) })
		tw.Completed:Connect(function() sg.Offset = Vector2.new(-1.3, 0) end)
		signs[t] = { grad = grad, tween = tw, nextAt = os.clock() + 1 + math.random() * 3 }
	end
	task.spawn(function()
		while true do
			local niches = workspace:FindFirstChild("Niches")
			if niches then for _, d in niches:GetDescendants() do if d.Name == "SellSign" and d:IsA("BillboardGui") then hook(d) end end end
			task.wait(2)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local ks
		for t, s in signs do
			if not t.Parent then signs[t] = nil continue end
			if not ks then
				ks = {}
				for k = 0, 18 do ks[#ks + 1] = ColorSequenceKeypoint.new(k / 18, sample(k / 18 * 2 - now / 4)) end
				ks = ColorSequence.new(ks)
			end
			s.grad.Color = ks
			if now >= s.nextAt then s.tween:Play(); s.nextAt = now + 3 + math.random() * 3 end
		end
	end)
end
