--!strict
-- BossModelBuilder v2 — блокова модель боса GOBKING (Големо-Гоблін), ~58 студів заввишки (×8 до големів на арені).
-- Де: ServerScriptService/BossModelBuilder (ModuleScript). Готова модель — префаб ServerStorage/BossModels/Gobking
--   (BossFightService клонує префаб; немає префаба — будує цим модулем). Префаб можна правити руками в Studio.
-- Будова: «ноги» в 0, перед — −Z. Hitbox (невидимий, PrimaryPart) — 32 × 56 × 24 по центру (BossConfig.BOSSES.goblin.half).
-- v2 (05.11.2026): кожен великий блок — «кам'яна кладка»: темне ядро + цеглини-плитки на гранях зі швами (зазор 0.25),
--   різні відтінки й товщина, мох на верхніх плитках; деталі (груди, брови, ікла, пряжка, кісточки) кріпляться ЗОВНІ граней
--   впритул — нічого не перетинається видимими гранями й не мерехтить (немає співпадаючих граней).
-- Анімація (клієнт BossArenaClient): атрибут деталі J = суглоб; папка Joints — CFrameValue на суглоб (спокій відносно Hitbox,
--   атрибут Parent). Суглоби: Root (таз) → Torso → Head → Jaw, Torso → ArmL → ForeL, ArmR → ForeR; LegL / LegR — без батька
--   (ступні стоять на землі, коли бос присідає). На кулаках — Attachment + Trail «FistTrail» (вмикає клієнт під час удару).

local M = {}

local HALF = Vector3.new(16, 28, 12)
-- 06.11.2026: модель будується в розмірі ×8 і в кінці масштабується до ×6 (SCALE = 0,75): ScaleTo + суглоби (Joints);
--   атрибут BossScale — клієнт множить зсуви поз (у студах). Хітбокс після масштабу — BossConfig.BOSSES.goblin.half × 2
local SCALE = 0.75

local COL = {
	CORE = "23292f",
	S = { "3e4954", "465260", "39434e", "4f5b69", "424d59" }, -- відтінки каменю
	DARK = "313a44", LIGHT = "5a6775",
	M1 = "4f8a2c", M2 = "63a83a", M3 = "3f7424",
	R1 = "7a4a2a", R2 = "a0703c", R3 = "5e3820",
	BONE = "e2d6b8", CLOTH = "5b4a35", CLOTH2 = "4a3c2b", EYE = "4dff4a", SOCKET = "15181c", MOUTH = "1a1414",
	CRY = "3fdc4f", CRY_L = "b6ffb0",
}

function M.build(): Model
	local rng = Random.new(20261105)
	local m = Instance.new("Model")
	m.Name = "Gobking"
	local hb = Instance.new("Part")
	hb.Name = "Hitbox"; hb.Size = HALF * 2; hb.CFrame = CFrame.new(0, HALF.Y, 0)
	hb.Anchored = true; hb.CanCollide = false; hb.CanQuery = false; hb.CanTouch = false; hb.Transparency = 1
	hb.Parent = m
	m.PrimaryPart = hb

	local joints = Instance.new("Folder")
	joints.Name = "Joints"
	joints.Parent = m
	local function joint(name: string, pivot: Vector3, parent: string?)
		local v = Instance.new("CFrameValue")
		v.Name = name
		v.Value = hb.CFrame:ToObjectSpace(CFrame.new(pivot))
		if parent then v:SetAttribute("Parent", parent) end
		v.Parent = joints
	end
	joint("Root", Vector3.new(0, 14, 1))
	joint("LegL", Vector3.new(-7.5, 13, 1))
	joint("LegR", Vector3.new(7.5, 13, 1))
	joint("Torso", Vector3.new(0, 16, 1), "Root")
	joint("Head", Vector3.new(0, 41, -3), "Torso")
	joint("Jaw", Vector3.new(0, 43.5, -3), "Head")
	joint("ArmL", Vector3.new(-19, 36.5, 0), "Torso")
	joint("ArmR", Vector3.new(19, 36.5, 0), "Torso")
	joint("ForeL", Vector3.new(-20.5, 21, -0.5), "ArmL")
	joint("ForeR", Vector3.new(20.5, 21, -0.5), "ArmR")

	local n = 0
	local function part(j: string, size: Vector3, pos: Vector3, col: string, opt: any?): Part
		opt = opt or {}
		n += 1
		local p = Instance.new("Part")
		p.Name = opt.name or (j .. "_" .. n)
		p.Size = size
		p.CFrame = CFrame.new(pos) * (opt.rot or CFrame.identity)
		p.Color = Color3.fromHex(col)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if opt.neon then
			p.Material = Enum.Material.Neon
		else
			p.Material = Enum.Material.Plastic
			if opt.studs ~= false then p.MaterialVariant = "Studs" end
		end
		p.CastShadow = opt.shadow ~= false
		p:SetAttribute("J", j)
		p.Parent = m
		return p
	end
	local function stone(): string return COL.S[rng:NextInteger(1, #COL.S)] end

	-- «кладка» на прямокутній ділянці грані: u / v — осі в площині, w — нормаль назовні (одиничні вектори),
	--   o — точка нижнього лівого кута ділянки на зовнішній площині ядра, U × V — розмір, t — товщина плиток
	local function tileFace(j: string, o: Vector3, u: Vector3, v: Vector3, w: Vector3, U: number, V: number, t: number, opt: any)
		local G = 0.25
		local rowT = opt.row or 3.4
		local nr = math.max(1, math.floor(V / rowT + 0.5))
		local rh = V / nr
		for r = 0, nr - 1 do
			local bw = (opt.brick or 5.5) * rng:NextNumber(0.85, 1.15)
			local cuts = { 0 }
			local x = (r % 2 == 1) and bw * 0.5 or bw
			while x < U - 1.4 do table.insert(cuts, x); x += bw * rng:NextNumber(0.8, 1.2) end
			table.insert(cuts, U)
			for i = 1, #cuts - 1 do
				local a, b = cuts[i], cuts[i + 1]
				local th = t * rng:NextNumber(0.75, 1)
				local topRow = r == nr - 1
				local mossy = opt.moss and ((opt.top and rng:NextNumber() < opt.moss) or (topRow and not opt.top and rng:NextNumber() < opt.moss * 0.5))
				local col = mossy and (rng:NextNumber() < 0.5 and COL.M1 or COL.M2) or stone()
				local cu, cv = (a + b) / 2, r * rh + rh / 2
				local pos = o + u * cu + v * cv + w * (th / 2)
				local size = u * (b - a - G) + v * (rh - G) + w * th
				part(j, Vector3.new(math.abs(size.X), math.abs(size.Y), math.abs(size.Z)), pos, col)
				-- моховий «підтік» з верхньої плитки вниз по грані (тонка пластина впритул до плитки, назовні)
				if mossy and not opt.top and rng:NextNumber() < 0.5 then
					local len = rh * rng:NextNumber(0.4, 0.9)
					local dw = math.min(b - a - 1, rng:NextNumber(1.2, 2.2))
					part(j, Vector3.new(math.abs((u * dw + v * len + w * 0.3).X), math.abs((u * dw + v * len + w * 0.3).Y), math.abs((u * dw + v * len + w * 0.3).Z)),
						o + u * (cu + rng:NextNumber(-0.25, 0.25) * (b - a - dw)) + v * (cv + rh / 2 - G - len / 2) + w * (th + 0.15), COL.M3)
				end
			end
		end
	end
	-- кам'яний блок: ядро + плитки на 5 гранях (без низу). opt.skip = { front = true, ... }
	local function brickBox(j: string, c: Vector3, s: Vector3, opt: any?): Part
		opt = opt or {}
		local t = opt.t or 1.1
		local skip = opt.skip or {}
		local core = part(j, Vector3.new(s.X - 2 * t, s.Y - t, s.Z - 2 * t), c - Vector3.new(0, t / 2, 0), COL.CORE, { name = opt.name, studs = false })
		local x0, x1, y0, y1, z0, z1 = c.X - s.X / 2, c.X + s.X / 2, c.Y - s.Y / 2, c.Y + s.Y / 2 - t, c.Z - s.Z / 2, c.Z + s.Z / 2
		local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis
		local base = { row = opt.row, brick = opt.brick, moss = opt.moss }
		if not skip.front then tileFace(j, Vector3.new(x0, y0, z0 + t), X, Y, -Z, s.X, y1 - y0, t, base) end
		if not skip.back then tileFace(j, Vector3.new(x1, y0, z1 - t), -X, Y, Z, s.X, y1 - y0, t, base) end
		if not skip.left then tileFace(j, Vector3.new(x0 + t, y0, z1 - t), -Z, Y, -X, s.Z - 2 * t, y1 - y0, t, base) end
		if not skip.right then tileFace(j, Vector3.new(x1 - t, y0, z0 + t), Z, Y, X, s.Z - 2 * t, y1 - y0, t, base) end
		if not skip.top then
			local topOpt = { row = opt.brick or 5.5, brick = opt.brick or 5.5, moss = opt.mossTop or opt.moss, top = true }
			tileFace(j, Vector3.new(x0, y1, z1), X, -Z, Y, s.X, s.Z, t, topOpt)
		end
		return core
	end
	local function mirrorX(v: Vector3): Vector3 return Vector3.new(-v.X, v.Y, v.Z) end
	-- кристал: призма (поворот 45°) + світліша грань + кінчик; основа захована в блоці
	local function crystal(j: string, base: Vector3, h: number, w: number, rx: number, rz: number)
		local rot = CFrame.Angles(rx, 0, rz)
		local b = CFrame.new(base) * rot
		local r45 = CFrame.Angles(0, math.rad(45), 0)
		part(j, Vector3.new(w, h, w), (b * CFrame.new(0, h / 2, 0)).Position, COL.CRY, { neon = true, rot = rot * r45, shadow = false })
		part(j, Vector3.new(w * 0.35, h * 0.8, w * 1.04), (b * CFrame.new(-w * 0.2, h * 0.45, 0)).Position, COL.CRY_L, { neon = true, rot = rot * r45, shadow = false })
		part(j, Vector3.new(w * 0.62, w * 0.75, w * 0.62), (b * CFrame.new(0, h + w * 0.3, 0)).Position, COL.CRY_L, { neon = true, rot = rot * r45, shadow = false })
	end

	-- ===== ноги (без батька — ступні на землі) =====
	for _, sx in { -1, 1 } do
		local jn = sx < 0 and "LegL" or "LegR"
		local cx = 7.5 * sx
		brickBox(jn, Vector3.new(cx, 9, 1), Vector3.new(10, 10, 11), { row = 3.3, brick = 5 })
		part(jn, Vector3.new(12, 4, 14), Vector3.new(cx, 2, -0.5), COL.DARK)                       -- ступня
		part(jn, Vector3.new(12.4, 0.8, 14.4), Vector3.new(cx, 4.4, -0.5), stone())               -- кант ступні
		for _, dx in { -3.6, 0, 3.6 } do
			part(jn, Vector3.new(3, 2.6, 2.6), Vector3.new(cx + dx, 1.3, -8.8), stone())          -- пальці
			part(jn, Vector3.new(2, 1.2, 0.8), Vector3.new(cx + dx, 1.4, -10.5), COL.BONE)          -- кігті
		end
		part(jn, Vector3.new(7, 4.2, 1), Vector3.new(cx, 10, -5), COL.LIGHT)                     -- наколінник
	end

	-- ===== таз: пояс, пряжка, заклепки, пов'язка =====
	part("Root", Vector3.new(24, 7, 15), Vector3.new(0, 15.5, 1), COL.DARK)
	part("Root", Vector3.new(26.4, 4, 17.4), Vector3.new(0, 17.5, 1), COL.R1)
	part("Root", Vector3.new(26.8, 0.8, 17.8), Vector3.new(0, 18.6, 1), COL.R3)                   -- кант пояса (06.11.2026: нижче верху пояса й тулуба — без мерехтіння)
	part("Root", Vector3.new(6.4, 3.4, 1), Vector3.new(0, 17.1, -8.2), COL.R2)                    -- пряжка
	part("Root", Vector3.new(3.4, 2.2, 0.5), Vector3.new(0, 17.2, -8.95), COL.R3)
	part("Root", Vector3.new(0.8, 3, 0.6), Vector3.new(0, 17.2, -9.5), COL.R2)                  -- язичок пряжки
	for _, x in { -11, -6.5, 6.5, 11 } do part("Root", Vector3.new(1, 1, 0.5), Vector3.new(x, 17.5, -7.95), COL.R2) end
	for _, sx in { -1, 1 } do for _, z in { -3, 4 } do part("Root", Vector3.new(0.5, 1, 1), Vector3.new(13.45 * sx, 17.5, z), COL.R2) end end
	part("Root", Vector3.new(11, 8.4, 1), Vector3.new(0, 11.25, -7.2), COL.CLOTH)                     -- пов'язка
	part("Root", Vector3.new(3.2, 2, 1), Vector3.new(-3, 6, -7.2), COL.CLOTH2)
	part("Root", Vector3.new(3.6, 1.6, 1), Vector3.new(2.6, 6.2, -7.2), COL.CLOTH2)
	part("Root", Vector3.new(11, 1, 0.4), Vector3.new(0, 14, -7.9), COL.CLOTH2)                     -- шов
	-- 06.11.2026: «заповнювачі» суглобів — темні блоки, сховані всередині сусідніх деталей у спокої; коли тулуб / руки / голова
	--   повертаються, вони закривають щілини (без «розривів» у тілі)
	part("Root", Vector3.new(21, 5, 11), Vector3.new(0, 21, 1), COL.DARK, { studs = false })            -- таз → у тулуб (менший — грані не збігаються)
	part("Torso", Vector3.new(22, 6, 12), Vector3.new(0, 18.5, 1), COL.DARK, { studs = false })         -- тулуб → у пояс
	part("Head", Vector3.new(14, 5, 10), Vector3.new(0, 40.5, -2), COL.DARK, { studs = false })         -- шия

	-- ===== тулуб: кладка, груди, прес, горб, кристали, мох =====
	brickBox("Torso", Vector3.new(0, 29, 1), Vector3.new(30, 20, 18), { row = 3.4, brick = 6, moss = 0.35, mossTop = 0.55 })
	for _, sx in { -1, 1 } do
		part("Torso", Vector3.new(12, 7, 1.2), Vector3.new(6.6 * sx, 32.5, -8.6), COL.LIGHT)          -- груди
		part("Torso", Vector3.new(11.6, 1, 1.3), Vector3.new(6.6 * sx, 28.6, -8.75), COL.DARK)           -- тінь під грудьми
		for _, y in { 25.6, 21.8 } do part("Torso", Vector3.new(6.4, 3.2, 0.9), Vector3.new(3.8 * sx, y, -8.45), stone()) end -- прес
	end
	part("Torso", Vector3.new(1, 6, 0.3), Vector3.new(10.5, 23.5, -8.15), COL.SOCKET)               -- тріщини
	part("Torso", Vector3.new(3.8, 0.8, 0.24), Vector3.new(8.9, 26.2, -8.15), COL.SOCKET)
	brickBox("Torso", Vector3.new(0, 34, 13.5), Vector3.new(22, 9, 7), { row = 3, brick = 5, moss = 0.4, mossTop = 0.6, skip = { front = true } }) -- горб
	-- 06.11.2026: низ горба — плитки (без них при нахилі тулуба знизу видно порожнє ядро — горб наче «левітує»)
	tileFace("Torso", Vector3.new(-10.95, 30.4, 11.2), Vector3.xAxis, Vector3.zAxis, -Vector3.yAxis, 21.9, 5.75, 1.1, { row = 2.875, brick = 5.5 })
	crystal("Torso", Vector3.new(-5, 37.5, 13), 9, 2.8, -0.4, 0.3)
	crystal("Torso", Vector3.new(-1.5, 37.5, 15), 6.5, 2.2, -0.7, -0.05)
	crystal("Torso", Vector3.new(5, 37.5, 13.5), 8, 2.5, -0.5, -0.35)
	crystal("Torso", Vector3.new(8, 37.5, 11.5), 4.5, 1.7, -0.2, -0.7)

	-- ===== голова: кладка, сердиті брови, очниці, ніс-гачок, вуха сходинками, студи =====
	brickBox("Head", Vector3.new(0, 49, -4), Vector3.new(20, 15, 16), { row = 3, brick = 5, moss = 0.2, mossTop = 0.45 })
	for _, sx in { -1, 1 } do
		part("Head", Vector3.new(8.4, 2.6, 2.4), Vector3.new(5 * sx, 52.4, -13.2), COL.DARK, { rot = CFrame.Angles(0, 0, 0.3 * sx) }) -- брови
		part("Head", Vector3.new(5, 3, 0.36), Vector3.new(4.8 * sx, 49.4, -12.22), COL.SOCKET, { studs = false }) -- очниця
		part("Head", Vector3.new(3.6, 1.8, 0.4), Vector3.new(4.8 * sx, 49.4, -12.6), COL.EYE, { neon = true, shadow = false })
		part("Head", Vector3.new(1.2, 1.2, 0.3), Vector3.new(4.2 * sx, 49.4, -12.95), COL.SOCKET, { studs = false })
		-- вухо: сходинки назовні й угору-назад, внутрішній бік темніший
		local segs = { { 5, 8, 0 }, { 4.5, 6, 0.8 }, { 4.5, 4, 1.8 }, { 3.5, 2.2, 3 } }
		local x = 10
		for i, sg in segs do
			local cx = (x + sg[1] / 2) * sx
			local z = -2.6 + i * 0.8
			part("Head", Vector3.new(sg[1], sg[2], 2.6), Vector3.new(cx, 50 + sg[3], z), i % 2 == 0 and stone() or COL.LIGHT)
			if i < 4 then part("Head", Vector3.new(sg[1] - 0.6, sg[2] * 0.55, 0.4), Vector3.new(cx, 50 + sg[3], z - 1.5), COL.DARK) end
			x += sg[1]
		end
	end
	part("Head", Vector3.new(5, 7, 4.5), Vector3.new(0, 46.5, -14.25), COL.LIGHT)                 -- ніс
	part("Head", Vector3.new(4, 2.6, 2.4), Vector3.new(0, 43.6, -17), stone())                    -- кінчик носа (гачок)
	part("Head", Vector3.new(1.2, 1.2, 0.4), Vector3.new(-1.1, 43.4, -18.4), COL.SOCKET, { studs = false }) -- ніздрі
	part("Head", Vector3.new(1.2, 1.2, 0.4), Vector3.new(1.1, 43.4, -18.4), COL.SOCKET, { studs = false })
	-- 06.11.2026: корона замість студів-блоків на маківці: золотий обідок, зубці з кінчиками, зелені камені спереду
	do
		local G, GD, GL = "f2c230", "b8861c", "ffe27a"
		local y, cz = 58.1, -4
		part("Head", Vector3.new(17, 3.2, 1.4), Vector3.new(0, y, cz - 5.8), G)                       -- обідок: перед
		part("Head", Vector3.new(17, 3.2, 1.4), Vector3.new(0, y, cz + 5.8), G)                       -- зад
		for _, sx in { -1, 1 } do part("Head", Vector3.new(1.4, 3.2, 10.2), Vector3.new(7.8 * sx, y, cz), G) end -- боки
		part("Head", Vector3.new(17.6, 0.8, 1.8), Vector3.new(0, y - 1.7, cz - 5.8), GD, { studs = false }) -- нижній кант
		part("Head", Vector3.new(17.6, 0.8, 1.8), Vector3.new(0, y - 1.7, cz + 5.8), GD, { studs = false })
		for _, sx in { -1, 1 } do part("Head", Vector3.new(1.8, 0.8, 8.6), Vector3.new(7.8 * sx, y - 1.7, cz), GD, { studs = false }) end -- коротші: кути не перекриваються
		-- зубці
		local function spike(x: number, z: number, big: boolean, along: boolean)
			local w, h = big and 2.8 or 2.2, big and 3.6 or 2.6
			local sz = along and Vector3.new(1.4, h, w) or Vector3.new(w, h, 1.4)
			part("Head", sz, Vector3.new(x, y + 1.6 + h / 2, z), G)
			part("Head", along and Vector3.new(1, 1.3, w * 0.45) or Vector3.new(w * 0.45, 1.3, 1), Vector3.new(x, y + 1.6 + h + 0.65, z), GL, { studs = false })
		end
		for _, x in { -5.5, 0, 5.5 } do spike(x, cz - 5.8, x == 0, false); spike(x, cz + 5.8, false, false) end
		for _, sx in { -1, 1 } do spike(7.8 * sx, cz, false, true) end
		-- камені спереду (середній — більший)
		for _, x in { -5.5, 0, 5.5 } do
			local s = x == 0 and 2 or 1.5
			part("Head", Vector3.new(s, s, 0.5), Vector3.new(x, y, cz - 6.75), COL.CRY, { neon = true, shadow = false, rot = CFrame.Angles(0, 0, math.rad(45)) })
		end
	end
	-- щелепа (вистає вперед — нижні ікла)
	part("Jaw", Vector3.new(18, 6, 15), Vector3.new(0, 40.5, -6), COL.DARK)
	part("Jaw", Vector3.new(18.4, 1, 15.4), Vector3.new(0, 38.3, -6), stone())
	part("Jaw", Vector3.new(14, 1.4, 0.4), Vector3.new(0, 42.2, -13.7), COL.MOUTH, { studs = false })
	for _, sx in { -1, 1 } do
		part("Jaw", Vector3.new(2.4, 5, 2.4), Vector3.new(5.6 * sx, 45.3, -14.7), COL.BONE)        -- ікла
		part("Jaw", Vector3.new(1.6, 1.4, 1.6), Vector3.new(5.6 * sx, 48.5, -14.7), "f3ecd8")
		part("Jaw", Vector3.new(1.6, 2, 1.4), Vector3.new(2.2 * sx, 43.8, -14.2), COL.BONE)
	end

	-- ===== руки: наплічник з мохом і кристалами, плече, передпліччя з браслетом, величезний кулак =====
	for _, sx in { -1, 1 } do
		local ja, jf = sx < 0 and "ArmL" or "ArmR", sx < 0 and "ForeL" or "ForeR"
		brickBox(ja, Vector3.new(20 * sx, 37.5, 0), Vector3.new(13, 9, 13), { row = 3, brick = 4.6, moss = 0.35, mossTop = 0.7 })
		brickBox(ja, Vector3.new(20.5 * sx, 27, 0), Vector3.new(9, 13, 9), { row = 3.3, brick = 4.5 })
		part(ja, Vector3.new(8, 7, 7), Vector3.new(14 * sx, 35.5, 0), COL.DARK, { studs = false })      -- 06.11.2026: заповнювач плеча (у тулуб)
		part(jf, Vector3.new(6.6, 6, 6.6), Vector3.new(20.5 * sx, 20.5, -0.25), COL.DARK, { studs = false }) -- заповнювач ліктя
		crystal(ja, Vector3.new(21.5 * sx, 41.5, -2), 9, 2.8, 0.15, 0.4 * -sx)
		crystal(ja, Vector3.new(18 * sx, 41.5, 3), 6.5, 2.2, -0.35, 0.15 * -sx)
		crystal(ja, Vector3.new(24.5 * sx, 41.2, 3.5), 5, 1.8, -0.25, 0.7 * -sx)
		brickBox(jf, Vector3.new(21 * sx, 16, -0.5), Vector3.new(11, 9, 11), { row = 3, brick = 4.5 }) -- 06.11.2026: з верхом (було видно порожнє ядро при згині)
		part(jf, Vector3.new(12.4, 3, 12.4), Vector3.new(21 * sx, 12.8, -0.5), COL.R1)            -- браслет
		part(jf, Vector3.new(12.8, 0.6, 12.8), Vector3.new(21 * sx, 14.6, -0.5), COL.R3)
		for _, dx in { -3.5, 0, 3.5 } do part(jf, Vector3.new(1, 1, 0.5), Vector3.new(21 * sx + dx, 12.8, -6.95), COL.R2) end
		local fist = brickBox(jf, Vector3.new(21.5 * sx, 5.5, -1.5), Vector3.new(15, 11, 15), { row = 3.6, brick = 5, mossTop = 0.3, name = sx < 0 and "FistL" or "FistR" })
		for i, dx in { 19.8, 23.2, 26.6 } do
			part(jf, Vector3.new(3.2, 3.4, 1.6), Vector3.new(dx * sx, 8.4, -9.8), i == 2 and COL.LIGHT or stone()) -- кісточки
			part(jf, Vector3.new(3.2, 1.6, 1.2), Vector3.new(dx * sx, 4.6, -9.6), COL.DARK)               -- зігнуті пальці
		end
		part(jf, Vector3.new(3.6, 4.5, 3.4), Vector3.new(16 * sx, 6.5, -10.7), stone())             -- великий палець
		-- слід кулака під час удару (клієнт вмикає Trail на мить удару)
		local a0 = Instance.new("Attachment"); a0.Name = "TrailTop"; a0.Position = Vector3.new(0, 5, -7); a0.Parent = fist
		local a1 = Instance.new("Attachment"); a1.Name = "TrailBot"; a1.Position = Vector3.new(0, -4.5, -7); a1.Parent = fist
		local tr = Instance.new("Trail")
		tr.Name = "FistTrail"; tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Enabled = false
		tr.Lifetime = 0.22; tr.MinLength = 0.2; tr.FaceCamera = false; tr.LightEmission = 0.3
		tr.Color = ColorSequence.new(Color3.fromHex("e8f0f6"), Color3.fromHex("8a9aa8"))
		tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		tr.Parent = fist
	end
	if SCALE ~= 1 then
		m:ScaleTo(SCALE)
		for _, v in joints:GetChildren() do
			if v:IsA("CFrameValue") then v.Value = CFrame.new(v.Value.Position * SCALE) * v.Value.Rotation end
		end
		m:SetAttribute("BossScale", SCALE)
	end
	return m
end

M.HALF = HALF * SCALE
return M
