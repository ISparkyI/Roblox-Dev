-- GapFixer (Claude, 01.11.2026): закриває щілини в префабах предметів і ящиків.
--   fixSword(model): SwordGrip заходить до центру SwordGuard і SwordPommel, SwordBlade (якщо є щілина) дотягується до SwordGuard.
--   fixBox(model):   щілини ≤ 0,15 стада між вирівняними деталями, які не закриває інша деталь, закриваються:
--                    менша за перерізом деталь подовжується рівно до дотику з сусідом.
--   Після кожного подовження грані, що через нього лягли в одну площину з іншими (правило 0,1), зсуваються на 0,022 всередину.
local G = {}
local TOL, INSET = 0.02, 0.022

local function axes(p: BasePart) return { p.CFrame.XVector, p.CFrame.YVector, p.CFrame.ZVector }, { p.Size.X, p.Size.Y, p.Size.Z } end -- ZVector = +Z (LookVector — це −Z)
local function unit(k) return Vector3.new(k == 1 and 1 or 0, k == 2 and 1 or 0, k == 3 and 1 or 0) end
local function vis(p) return p:IsA("BasePart") and p.Transparency < 0.99 end

local function coplanar(E: BasePart, parts: { BasePart }): { [string]: { O: BasePart, k: number, sg: number, q: number } }
	local out = {}
	local eA, eS = axes(E)
	for _, O in parts do
		if O ~= E then
			local oA, oS = axes(O)
			local rel = O.Position - E.Position
			for k = 1, 3 do
				local par = false
				for i = 1, 3 do if math.abs(math.abs(oA[i]:Dot(eA[k])) - 1) < 1e-3 then par = true end end
				if par then
					local ho = {}
					local co = {}
					for j = 1, 3 do
						local h = 0
						for i = 1, 3 do h += math.abs(oA[i]:Dot(eA[j])) * oS[i] / 2 end
						ho[j] = h; co[j] = rel:Dot(eA[j])
					end
					local inplane = true
					for j = 1, 3 do if j ~= k then
						local lo, hi = math.max(-eS[j] / 2, co[j] - ho[j]), math.min(eS[j] / 2, co[j] + ho[j])
						if hi - lo < 1e-3 then inplane = false end
					end end
					if inplane then
						for _, sg in { 1, -1 } do
							local f = sg * eS[k] / 2
							for qi, q in { co[k] + ho[k], co[k] - ho[k] } do
								-- flush: грань O дивиться туди ж, куди грань E (з одного боку); інакше — стик «лоб у лоб»
								local flush = (sg > 0 and qi == 1) or (sg < 0 and qi == 2)
								if math.abs(f - q) < TOL then out[O:GetFullName() .. "|" .. k .. "|" .. sg] = { O = O, k = k, sg = sg, q = q, flush = flush } end
							end
						end
					end
				end
			end
		end
	end
	return out
end

local function unplane(E: BasePart, parts: { BasePart }, before: { [string]: any }, log: { string })
	for _ = 1, 8 do
		local now = coplanar(E, parts)
		local fixed = false
		for key, c in now do
			if not before[key] then
				local eA, eS = axes(E)
				local f = c.sg * eS[c.k] / 2
				-- flush — грань E ховаємо всередину (зменшуємо E); стик — заводимо грань E в O (щілина не відкривається)
				local shrink = if c.flush then c.sg * (f - c.q) + INSET else -(c.sg * (c.q - f) + INSET)
				if math.abs(shrink) < eS[c.k] * 0.5 then
					local cf = E.CFrame
					E.Size -= unit(c.k) * shrink
					E.CFrame = cf * CFrame.new(unit(c.k) * (-c.sg * shrink / 2))
					table.insert(log, ("%s∥%s %s%s"):format(E.Name, c.O.Name, ("XYZ"):sub(c.k, c.k), c.sg > 0 and "+" or "-"))
					fixed = true
					break
				end
			end
		end
		if not fixed then return end
	end
end

local function slab(p: BasePart, o: Vector3, d: Vector3)
	local lo = p.CFrame:PointToObjectSpace(o); local ld = p.CFrame:VectorToObjectSpace(d); local h = p.Size / 2
	local t0, t1 = -math.huge, math.huge
	for _, ax in { "X", "Y", "Z" } do
		local oo, dd, hh = lo[ax], ld[ax], h[ax]
		if math.abs(dd) < 1e-6 then if math.abs(oo) > hh then return nil end
		else local a, b = (-hh - oo) / dd, (hh - oo) / dd; if a > b then a, b = b, a end; t0 = math.max(t0, a); t1 = math.min(t1, b) end
	end
	if t0 > t1 then return nil end
	return t0, t1
end

function G.fixSword(m: Model): { string }
	local log = {}
	local parts = {}
	for _, p in m:GetChildren() do if vis(p) then table.insert(parts, p) end end
	local g, guard, pom, blade = m:FindFirstChild("SwordGrip"), m:FindFirstChild("SwordGuard"), m:FindFirstChild("SwordPommel"), m:FindFirstChild("SwordBlade")
	for _, job in { { g, guard, 1, 0.013, "grip→guard" }, { g, pom, -1, 0.017, "grip→pommel" }, { blade, guard, -1, nil, "blade→guard" } } do
		local part, tgt, sgn, off, tag = job[1], job[2], job[3], job[4], job[5]
		if part and tgt and part:IsA("BasePart") and tgt:IsA("BasePart") then
			local L = part.Size.Y / 2
			local a, b = slab(tgt, part.Position, part.CFrame.UpVector)
			if a then
				local mid = (a + b) / 2
				-- off = nil: лише дотик (лезо до гарди), без заходу всередину
				local need = if off == nil then (if sgn > 0 then a - L else -L - b) elseif sgn > 0 then mid + off - L else -L - (mid - off)
				if need > 0 then
					local before = coplanar(part, parts)
					local cf = part.CFrame
					part.Size += Vector3.new(0, need, 0)
					part.CFrame = cf * CFrame.new(0, sgn * need / 2, 0)
					table.insert(log, ("%s +%.2f"):format(tag, need))
					if off ~= nil then unplane(part, parts, before, log) end
				end
			end
		end
	end
	return log
end

function G.fixBox(m: Model, maxGap: number?): { string }
	maxGap = maxGap or 0.15
	local log = {}
	local piv = m:GetPivot()
	local all = {}
	for _, p in m:GetChildren() do if vis(p) then table.insert(all, p) end end
	local AX = { "X", "Y", "Z" }
	local function inside(p, pt) local l = p.CFrame:PointToObjectSpace(pt); local h = p.Size / 2 + Vector3.new(0.003, 0.003, 0.003); return math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z end
	local function info(p)
		local cf = piv:ToObjectSpace(p.CFrame); local R = cf.Rotation
		local cols = { R.RightVector, R.UpVector, R.LookVector }
		local map, ext = {}, {}
		for _, ax in AX do
			local best, bi = 0, 0
			for j = 1, 3 do local v = math.abs(cols[j][ax]); if v > best then best, bi = v, j end end
			if best < 0.999 then return nil end
			map[ax] = bi; ext[ax] = ({ p.Size.X, p.Size.Y, p.Size.Z })[bi]
		end
		local c = cf.Position
		return { p = p, map = map, ext = ext, lo = { X = c.X - ext.X / 2, Y = c.Y - ext.Y / 2, Z = c.Z - ext.Z / 2 }, hi = { X = c.X + ext.X / 2, Y = c.Y + ext.Y / 2, Z = c.Z + ext.Z / 2 } }
	end
	for _ = 1, 150 do
		local P = {}
		for _, p in all do local i = info(p); if i then table.insert(P, i) end end
		local done = false
		for i = 1, #P do
			for j = i + 1, #P do
				local A, B = P[i], P[j]
				local gax, gap, ok = nil, 0, true
				for _, ax in AX do
					local g = math.max(A.lo[ax] - B.hi[ax], B.lo[ax] - A.hi[ax])
					if g > 0.001 then if gax then ok = false else gax, gap = ax, g end elseif -g < 0.04 then ok = false end
				end
				if ok and gax and gap <= maxGap then
					local o = {}
					for _, ax in AX do if ax ~= gax then table.insert(o, ax) end end
					local a1, a2 = o[1], o[2]
					local l1, h1 = math.max(A.lo[a1], B.lo[a1]), math.min(A.hi[a1], B.hi[a1])
					local l2, h2 = math.max(A.lo[a2], B.lo[a2]), math.min(A.hi[a2], B.hi[a2])
					local first = A.hi[gax] < B.lo[gax]
					local gm = if first then (A.hi[gax] + B.lo[gax]) / 2 else (B.hi[gax] + A.lo[gax]) / 2
					local unc = 0 -- відкритих точок з 49; щілина «відкрита», якщо ≥ 10 (≈ 20 % перерізу)
					for u = 0, 6 do for v = 0, 6 do
						local pt = {}; pt[gax] = gm; pt[a1] = l1 + (h1 - l1) * (0.02 + 0.96 * u / 6); pt[a2] = l2 + (h2 - l2) * (0.02 + 0.96 * v / 6)
						local w = piv * Vector3.new(pt.X, pt.Y, pt.Z)
						local cov = false
						for _, q in all do if q ~= A.p and q ~= B.p and inside(q, w) then cov = true; break end end
						if not cov then unc += 1 end
					end end
					if unc >= 10 then
						local E, O, sg
						if A.ext[a1] * A.ext[a2] <= B.ext[a1] * B.ext[a2] then E, O, sg = A, B, (first and 1 or -1) else E, O, sg = B, A, (first and -1 or 1) end
						local amt = gap -- рівно до дотику: грані «лоб у лоб» сховані, площин, що перекриваються, не з'являється
						local li = E.map[gax]
						E.p.Size += unit(li) * amt
						local sh = Vector3.new(gax == "X" and sg * amt / 2 or 0, gax == "Y" and sg * amt / 2 or 0, gax == "Z" and sg * amt / 2 or 0)
						E.p.CFrame = (piv * CFrame.new(sh) * piv:Inverse()) * E.p.CFrame
						table.insert(log, ("%s→%s %s %.2f"):format(E.p.Name, O.p.Name, gax, gap))
						done = true
						break
					end
				end
			end
			if done then break end
		end
		if not done then break end
	end
	return log
end

return G
