local M={}
local PP=workspace.PlotPrefabs
local PA=game.ReplicatedStorage.PlotAssets
local Cat=require(game.ReplicatedStorage.Shared.GolemCatalog)
local NICHE=...
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include
function M.setNiche(n) rp.FilterDescendantsInstances={n} end
function M.ground(x,z) local h=workspace:Raycast(Vector3.new(x,140,z),Vector3.new(0,-80,0),rp) return h and h.Position.Y or 102.9 end
local FLIP=CFrame.Angles(0,math.pi,0)
local function rot(r) r=r or {0,0,0} return CFrame.Angles(0,0,r[3])*CFrame.Angles(0,r[2],0)*CFrame.Angles(r[1],0,0) end
M.P={}
M.P.READY={Hips={t={0,-0.10,0}},Torso={r={0.12,0.10,0}},Head={r={0.12,0,0}},UpperArm_L={r={-0.60,0,-0.15}},Forearm_L={r={-0.50,0,0}},UpperArm_R={r={0.05,0,0.08}},Forearm_R={r={-0.25,0,0}},Thigh_R={r={-0.08,0,0}},Thigh_L={r={-0.08,0,0}},Shin_R={r={0.12,0,0}},Shin_L={r={0.12,0,0}}}
M.P.WINDUP={Torso={r={-0.12,-0.18,0}},Head={r={-0.15,0.05,0}},UpperArm_L={r={-2.70,0,-0.20}},Forearm_L={r={-0.70,0,0}},UpperArm_R={r={-0.25,0,0.18}},Forearm_R={r={-0.35,0,0}},Thigh_R={r={-0.04,0,0}},Thigh_L={r={-0.04,0,0}},Shin_R={r={0.06,0,0}},Shin_L={r={0.06,0,0}}}
M.P.IMPACT={Hips={t={0,-0.15,0}},Torso={r={0.45,0.30,0}},Head={r={0.30,-0.10,0}},UpperArm_L={r={-0.864,0,-0.35}},Forearm_L={r={-0.05,0,0}},UpperArm_R={r={0.30,0,0.12}},Forearm_R={r={-0.45,0,0}},Thigh_R={r={-0.15,0,0}},Thigh_L={r={-0.15,0,0}},Shin_R={r={0.22,0,0}},Shin_L={r={0.22,0,0}}}
M.P.HIGH={Hips={t={0,0.05,0}},Torso={r={-0.18,-0.25,0}},Head={r={-0.2,0.1,0}},UpperArm_L={r={-3.0,0,-0.15}},Forearm_L={r={-0.45,0,0}},UpperArm_R={r={-0.4,0,0.3}},Forearm_R={r={-0.5,0,0}},Thigh_R={r={0.15,0,0}},Thigh_L={r={-0.2,0,0}},Shin_R={r={0.05,0,0}},Shin_L={r={0.2,0,0}}}
local HOLD={UpperArm_R={r={-0.95,0,0.32}},UpperArm_L={r={-0.95,0,-0.32}},Forearm_R={r={-0.55,0,0}},Forearm_L={r={-0.55,0,0}}}
function M.walk(ph, carry)
  local p={Hips={t={0,-0.05,0}},Torso={r={0.06,0.08*ph,0}},Head={r={-0.05,-0.06*ph,0}},
    Thigh_R={r={-0.5*ph,0,0}},Thigh_L={r={0.5*ph,0,0}},Shin_R={r={0.25+0.25*math.max(ph,0),0,0}},Shin_L={r={0.25+0.25*math.max(-ph,0),0,0}}}
  if carry then for k,v in pairs(HOLD) do p[k]=v end else p.UpperArm_R={r={0.45*ph,0,0.1}} p.UpperArm_L={r={-0.45*ph,0,-0.1}} p.Forearm_R={r={-0.3,0,0}} p.Forearm_L={r={-0.3,0,0}} end
  return p
end
function M.pose(model, pose)
  local D=require(model.GolemData:Clone())
  local root=model.Root local k=model:GetScale() local S=0.5*k
  local base=root.CFrame*FLIP
  local by={} for _,b in D.bones do by[b.name]=b end
  local cache={}
  local function bcf(n) if cache[n] then return cache[n] end local b=by[n] local pz=pose[n] local r=rot(pz and pz.r) local t=pz and pz.t and Vector3.new(unpack(pz.t))*S or Vector3.zero
    local cf if b.parent and by[b.parent] then cf=bcf(b.parent)*CFrame.new((b.pos-by[b.parent].pos)*S+t)*r else cf=CFrame.new(b.pos*S+t)*r end cache[n]=cf return cf end
  for _,blk in D.blocks do if not blk.group and by[blk.bone] then local part=model:FindFirstChild(blk.name)
    if part and part:IsA("BasePart") then local pos=blk.cf and blk.cf.Position or blk.c local r=blk.cf and blk.cf.Rotation or CFrame.Angles(0,0,blk.rz or 0)
      part.CFrame=base*bcf(blk.bone)*CFrame.new((pos-by[blk.bone].pos)*S)*r end end end
  local pk=model:FindFirstChild("Pickaxe") local fist=model:FindFirstChild("Fist_L")
  if pk and fist then for _,d in ipairs(pk:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("FistRel") then d.CFrame=fist.CFrame*d:GetAttribute("FistRel") end end end
  local box=model:FindFirstChild("Box")
  if box then local fl,fr=model.Fist_L,model.Fist_R local mid=(fl.Position+fr.Position)/2 local ctr=box:GetAttribute("CenterY") or 0.575
    box:PivotTo(CFrame.new(mid)*root.CFrame.Rotation*CFrame.new(0,-(ctr+0.75)*k,0)) end
end
function M.golem(kind, cls, pos, target, pose, parent)
  local g=Cat.get(kind) local mn=g.model or Cat.get("stone").model local src=PP:FindFirstChild(mn) or PA:FindFirstChild(mn) local m=src:Clone()
  for _,s in ipairs(m:GetDescendants()) do if s:IsA("Script") then s:Destroy() end end
  local sc=g.size or 1 if math.abs(m:GetScale()-sc)>1e-4 then m:ScaleTo(sc) end
  local gy=M.ground(pos.X,pos.Z)-0.12
  m:PivotTo(CFrame.lookAt(Vector3.new(pos.X,gy,pos.Z),Vector3.new(target.X,gy,target.Z)))
  m.Parent=parent
  if cls=="miner" then local pn=g.pickaxe or Cat.get("stone").pickaxe local it=(PP:FindFirstChild(pn) or PA:FindFirstChild(pn)):Clone() if math.abs(it:GetScale()-sc)>1e-4 then it:ScaleTo(sc) end
    local fist=m.Fist_L it:PivotTo(fist.CFrame) it.Name="Pickaxe" for _,d in ipairs(it:GetDescendants()) do if d:IsA("BasePart") then d.Anchored=true d:SetAttribute("FistRel",fist.CFrame:ToObjectSpace(d.CFrame)) end end it.Parent=m
  elseif cls=="carrier" then local b=(g.box and PP:FindFirstChild(g.box)) or PA.CarryBox local it=b:Clone() if math.abs(it:GetScale()-sc)>1e-4 then it:ScaleTo(sc) end it.Name="Box" it.Parent=m end
  M.pose(m,pose)
  return m
end
function M.ore(name,pos,ry,parent)
  local o=workspace.OrePrefabs.OrePlot:FindFirstChild(name):Clone() local cf,sz=o:GetBoundingBox()
  local dy=o:GetPivot().Y-(cf.Y-sz.Y/2)
  o:PivotTo(CFrame.new(pos.X,M.ground(pos.X,pos.Z)-0.15+dy,pos.Z)*CFrame.Angles(0,math.rad(ry or 0),0)) o.Parent=parent return o
end
function M.chunk(name,pos,ry,parent,tilt,y)
  local o=PA.Chunks:FindFirstChild(name):Clone()
  local cf,sz=o:GetBoundingBox() local dy=o:GetPivot().Y-(cf.Y-sz.Y/2)
  o:PivotTo(CFrame.new(pos.X,(y or (M.ground(pos.X,pos.Z)-0.05))+dy,pos.Z)*CFrame.Angles(0,math.rad(ry or 0),0)*CFrame.Angles(tilt or 0,0,0))
  for _,d in ipairs(o:GetDescendants()) do if d:IsA("BasePart") then d.Anchored=true end end
  o.Parent=parent return o
end
return M
