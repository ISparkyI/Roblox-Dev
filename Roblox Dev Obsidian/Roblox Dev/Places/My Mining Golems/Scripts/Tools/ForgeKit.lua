-- ForgeKit — допоміжні функції для будівельного скрипта Forge (тільки Edit, у грі не використовується).
local K={}
local CM=Content.fromUri("rbxassetid://10509831729") local NM=Content.fromUri("rbxassetid://10509831753")
local D=math.rad
function K.studs(p,tile)
	for _,f in Enum.NormalId:GetEnumItems() do local t=Instance.new("Texture") t.Name="Studs" t.Face=f t.ColorMapContent=CM t.NormalMapContent=NM
		t.StudsPerTileU=tile t.StudsPerTileV=tile t.Transparency=0.2 t.Color3=p.Color t.Parent=p end
end
-- o: tile(1), noStuds, collide(true), tr, mat, neon
function K.part(parent,name,size,cf,hex,o)
	o=o or {}
	local p=Instance.new("Part") p.Name=name p.Anchored=true p.Size=size p.CFrame=cf
	p.Material=o.mat or (o.neon and Enum.Material.Neon) or Enum.Material.SmoothPlastic
	p.Color=typeof(hex)=="Color3" and hex or Color3.fromHex(hex)
	p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
	p.CanCollide=o.collide~=false p.CanTouch=false p.Transparency=o.tr or 0
	if o.collide==false then p.CanQuery=o.query==true end
	if not o.noStuds and not o.neon then K.studs(p,o.tile or 1) end
	p.Parent=parent return p
end
-- коробка у кадрі frame, кути в градусах (порядок XYZ як у three.js)
function K.box(parent,name,w,h,d,hex,frame,x,y,z,rx,ry,rz,o)
	return K.part(parent,name,Vector3.new(w,h,d),frame*CFrame.new(x,y,z)*CFrame.Angles(D(rx or 0),D(ry or 0),D(rz or 0)),hex,o)
end
-- циліндр з віссю Y (як у three.js)
function K.cyl(parent,name,r,h,hex,frame,x,y,z,rx,ry,rz,o)
	o=o or {} o.noStuds=true
	local p=K.part(parent,name,Vector3.new(h,2*r,2*r),frame*CFrame.new(x,y,z)*CFrame.Angles(D(rx or 0),D(ry or 0),D(rz or 0))*CFrame.Angles(0,0,math.pi/2),hex,o)
	p.Shape=Enum.PartType.Cylinder return p
end
function K.folder(parent,name) local f=parent:FindFirstChild(name) if f then f:Destroy() end f=Instance.new("Model") f.Name=name f.Parent=parent return f end
return K
