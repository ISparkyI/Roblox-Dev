local N={}
N.ND, N.NW, N.H = 142.5, 54, 56      -- depth (wall plane -> back face), half width, ceiling height above niche floor
N.FL = 0.5                           -- niche floor top above the hall floor (rule 0.5)
N.TOPY = 78                          -- top of the front wall
N.ENV = {{-45,18},{-43.8,23},{-42.5,30},{-41.5,35},{-40.5,37.8},{-38,39.4},{-30.1,39.5},{-28.5,43.3},{-26,50.4},{-22.3,53.5},{-18.6,55.9},{-14,57.3},{-3.3,56.5},{-0.8,57.5},{2.5,57.3},{10.7,55.1},{12.8,52},{16.5,48.8},{24.4,44.5},{33,43.5},{37.6,40.9},{39.2,35.4},{39.6,31.5},{40.9,24.4},{43.8,21.7},{45,17.3}}
function N.top(w) -- opening height at lateral w (outline drawn by the user), 0 = solid wall
	local s=-w
	if s<-45 or s>45 then return 0 end
	local E=N.ENV
	if s<=E[1][1] then return E[1][2] end
	for i=1,#E-1 do local a,b=E[i],E[i+1] if s<=b[1] then return a[2]+(b[2]-a[2])*(s-a[1])/(b[1]-a[1]) end end
	return E[#E][2]
end
local ROCK={"6e7378","666b71","777c81","6a6e73"}
local ROCK_D={"575c62","5b5f64","52575c"}
local cm=Content.fromUri("rbxassetid://10509831729") local nm=Content.fromUri("rbxassetid://10509831753")
function N.build(A, seed)
	local rng=Random.new(seed or 7)
	local function pick(t) return t[rng:NextInteger(1,#t)] end
	local function R(a,b) return a+rng:NextNumber()*(b-a) end
	local model=Instance.new("Model") model.Name="NichePrefab_Stage1"
	local folders={}
	local function F(name) if not folders[name] then local f=Instance.new("Folder") f.Name=name f.Parent=model folders[name]=f end return folders[name] end
	-- box in niche space: u (depth) u0..u1, y y0..y1, w w0..w1
	local function box(folder,u0,u1,y0,y1,w0,w1,hex,name,noStuds)
		local p=Instance.new("Part") p.Anchored=true p.Material=Enum.Material.SmoothPlastic
		p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.CanTouch=false
		p.Size=Vector3.new(w1-w0,y1-y0,u1-u0)
		p.CFrame=A*CFrame.new((w0+w1)/2,(y0+y1)/2,-(u0+u1)/2)
		p.Color=Color3.fromHex(hex) p.Name=name or "Rock"
		if not noStuds then for _,f in Enum.NormalId:GetEnumItems() do local t=Instance.new("Texture") t.Name="Studs" t.Face=f t.ColorMapContent=cm t.NormalMapContent=nm t.StudsPerTileU=1 t.StudsPerTileV=1 t.Transparency=0.2 t.Color3=p.Color t.Parent=p end end
		p.Parent=F(folder) return p
	end
	local ND,NW,H,FL=N.ND,N.NW,N.H,N.FL
	local HT=FL+H -- ceiling plane (above hall floor)
	-- anchor (pivot): wall plane, hall floor level, centre of the entrance
	local anc=Instance.new("Part") anc.Name="Anchor" anc.Anchored=true anc.CanCollide=false anc.CanQuery=false anc.CanTouch=false anc.Transparency=1 anc.Size=Vector3.new(2,2,2) anc.CFrame=A anc.Parent=model
	model.PrimaryPart=anc
	-- 1. shell (solid, hole-proof)
	box("Shell",ND,ND+10,-1,HT+10,-(NW+10),NW+10,pick(ROCK_D),"Back")
	for _,s in {-1,1} do local a,b=s*NW,s*(NW+10) box("Shell",8,ND+10,-1,HT+10,math.min(a,b),math.max(a,b),pick(ROCK_D),"Back") end
	box("Shell",8,ND+10,HT,HT+10,-(NW+10),NW+10,pick(ROCK_D),"Back")
	-- 2. floor: one plane, checker variation of studs
	local fl=box("Floor",-0.5,ND+1,FL-2,FL,-(NW+1),NW+1,"71675a","NicheFloor",true)
	fl.Material=Enum.Material.Plastic fl.MaterialVariant="Studs"
	local ct=Instance.new("Texture") ct.Face=Enum.NormalId.Top ct.Texture="rbxassetid://6372755229" ct.Color3=Color3.new(0,0,0) ct.Transparency=0.9 ct.StudsPerTileU=8 ct.StudsPerTileV=8 ct.Parent=fl
	-- 3. front wall core: 3-stud columns following the drawn outline
	local w=-(NW+3)
	while w<NW+3 do
		local w1=math.min(w+3,NW+3)
		local t=math.max(N.top(w),N.top(w1),N.top((w+w1)/2))
		if math.abs((w+w1)/2)>45 then t=0 end
		box("FrontWall",0.6,11.5,(t>0 and t or -1),N.TOPY,w,w1,pick(ROCK),"Rock")
		w=w1
	end
	-- 4. hall-side facade above the entrance (stepped, like the reference)
	local DEP={-1.0,-2.0,-3.0}
	w=-49
	while w<49 do
		local ww=rng:NextInteger(2,3)*3
		local w1=math.min(w+ww,49)
		local tmax=0 for x=w,w1,1 do tmax=math.max(tmax,N.top(x)) end
		local y=tmax+(tmax>0 and 0.6 or 0)
		while y<N.TOPY-2 do
			local h=math.min(rng:NextInteger(2,4)*3,N.TOPY-y)
			box("Facade",DEP[rng:NextInteger(1,#DEP)],3,y,y+h,w,w1,pick(ROCK),"Rock")
			y+=h
		end
		w=w1
	end
	-- 5. terraced wall tiles inside (axis aligned, stepped protrusion 1/2/3/4)
	local PRO={1,2,3,4}
	local function wallTiles(len0,len1,mk)
		local a=len0
		while a<len1-0.01 do
			local L=math.min(rng:NextInteger(3,6)*3,len1-a)
			local y=FL-0.5
			local first=true
			while y<HT do
				local h=first and R(3,4) or rng:NextInteger(2,4)*3
				h=math.min(h,HT+1-y)
				local d=first and 5 or PRO[rng:NextInteger(1,#PRO)]
				mk(a,a+L,y,y+h,d)
				y+=h first=false
			end
			a+=L
		end
	end
	-- side walls (u 11.5..ND)
	for _,s in {-1,1} do
		wallTiles(11.5,ND,function(a,b,y0,y1,d)
			local wa,wb=s*(NW-d),s*(NW+1)
			box("Walls",a,b,y0,y1,math.min(wa,wb),math.max(wa,wb),pick(ROCK),"Rock")
		end)
	end
	-- back wall
	wallTiles(-NW,NW,function(a,b,y0,y1,d) box("Walls",ND-d,ND+1,y0,y1,a,b,pick(ROCK),"Rock") end)
	-- inner face of the front wall beside the entrance (|w| 47..NW) and above the opening
	for _,s in {-1,1} do
		wallTiles(0,1,function() end)
		local y=FL-0.5 local first=true
		while y<HT do
			local h=first and R(3,4) or rng:NextInteger(2,4)*3 h=math.min(h,HT+1-y)
			local d=first and 5 or PRO[rng:NextInteger(1,#PRO)]
			local wa,wb=s*46.5,s*(NW-0.01)
			box("Walls",10.5,11.5+d,y0 or y,y+h,math.min(wa,wb),math.max(wa,wb),pick(ROCK),"Rock")
			y+=h first=false
		end
	end
	-- 6. ceiling: cornice steps along the walls + random coffers
	local function cornice(u0,u1,w0,w1) box("Ceiling",u0,u1,HT-3,HT+0.5,w0,w1,pick(ROCK_D),"Ceil") end
	for _,s in {-1,1} do
		local a,b=s*(NW-7),s*(NW+0.5) box("Ceiling",11.5,ND+0.5,HT-3,HT+0.5,math.min(a,b),math.max(a,b),pick(ROCK_D),"Ceil")
		local c,d=s*(NW-3.5),s*(NW+0.5) box("Ceiling",11.5,ND+0.5,HT-6,HT-2.5,math.min(c,d),math.max(c,d),pick(ROCK_D),"Ceil")
	end
	box("Ceiling",ND-7,ND+0.5,HT-3,HT+0.5,-(NW-7),NW-7,pick(ROCK_D),"Ceil")
	box("Ceiling",ND-3.5,ND+0.5,HT-6,HT-2.5,-(NW-3.5),NW-3.5,pick(ROCK_D),"Ceil")
	-- coffers: grid of panels hanging 1.5 / 3 / 4.5 below the ceiling
	local DROP={1.5,3,4.5}
	local u=11.5
	while u<ND-7.01 do
		local du=math.min(rng:NextInteger(2,4)*6,ND-7-u)
		local ww=-(NW-7)
		while ww<NW-7.01 do
			local dw=math.min(rng:NextInteger(2,4)*6,NW-7-ww)
			if rng:NextNumber()<0.7 then box("Ceiling",u,u+du,HT-DROP[rng:NextInteger(1,3)],HT+0.5,ww,ww+dw,pick(ROCK_D),"Ceil") end
			ww+=dw
		end
		u+=du
	end
	-- 7. soft light
	for _,uu in {40,100} do
		local p=Instance.new("Part") p.Name="Light" p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Transparency=1 p.Size=Vector3.new(1,1,1)
		p.CFrame=A*CFrame.new(0,HT-10,-uu) p.Parent=F("Lights")
		local l=Instance.new("PointLight") l.Color=Color3.fromHex("ffd9a0") l.Range=60 l.Brightness=0.8 l.Shadows=true l.Parent=p
	end
	return model
end
return N
