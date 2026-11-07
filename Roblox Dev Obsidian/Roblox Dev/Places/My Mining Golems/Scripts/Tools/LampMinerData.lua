-- Lamp Miner Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано mkx/gen.py (05.11.2026).
-- Ексклюзив Marketplace. Анімації — GolemAnimator v4 (NicheTools/GolemAnimatorV4): fx spin/sway/bob/pulse/hue/blink, власні пози Idle/Walk/Run/Mine/Carry/Pick.
-- Блоки — компактно в RAW: { ім'я, кістка, колір, x, y, z, rx, ry, rz (градуси, CFrame.Angles), sx, sy, sz, група? } → D.blocks (формат Clay / Astral).
local D = {
 colors={stone="#a39686",stone2="#857868",denim="#3b6aa3",denim2="#5c89c0",flannel="#c2402c",flannel2="#7e2418",helmet="#f4c430",helmet2="#d79d17",leather="#6e452a",leather2="#45291a",brass="#d6aa52",iron="#4c5056",lamp="#fff3c0",beam="#fff6d2",ember="#ffb347",light="#f4f2ea",dark="#2a2420",pink="#f2a0b4",stache="#5b3a20",canvas="#6f7a4a",bandana="#e0402f",wood="#8b5a32",wood2="#6b4222"},
 neon={beam=true,ember=true,lamp=true},
 alpha={beam=0.86},
 poses={
  -- спокій: великі пальці за лямками комбінезона, гойдається з п'ят на носки, озирається
  Idle=function(p, pose, rot)
   local s, c = math.sin(p), math.cos(p)
   local hp = pose.Hips or {}
   pose.Hips = { t = (hp.t or Vector3.zero) + Vector3.new(0, 0.06 * c, 0.12 * s), r = rot(0.04 * s, 0, 0) }
   pose.Torso = { r = rot(-0.05 * s, 0, 0) }
   pose.Head = { r = rot(0.04 * s, 0.25 * math.sin(p + 0.8), 0) }
   pose.UpperArm_R = { r = rot(-0.55, 0, 0.32) }
   pose.UpperArm_L = { r = rot(-0.55, 0, -0.32) }
   pose.Forearm_R = { r = rot(-1.55, 0, 0) }
   pose.Forearm_L = { r = rot(-1.55, 0, 0) }
   return pose
  end,
  -- хода трудяги: перевалюється з боку на бік, голова кивує в такт
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   local hp = pose.Hips or {}
   pose.Hips = { t = hp.t, r = (hp.r or CFrame.identity) * rot(0, 0, 0.09 * s) }
   local to = pose.Torso or {}
   pose.Torso = { r = (to.r or CFrame.identity) * rot(0.06, 0, -0.12 * s) }
   pose.Head = { r = rot(0.06 * math.abs(s), 0, 0.06 * s) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0, 0, 0.12) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0, 0, -0.12) }
   return pose
  end,
  -- біг-поспіх: дрібні часті кроки, лікті зігнуті, каска з ліхтарем підскакує
  Run=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = rot(0.3, 0.1 * s, 0) }
   pose.Head = { r = rot(-0.18 + 0.1 * math.abs(math.cos(p)), 0, 0) }
   pose.UpperArm_R = { r = rot(0.7 * s, 0, 0.15) }
   pose.UpperArm_L = { r = rot(-0.7 * s, 0, -0.15) }
   pose.Forearm_R = { r = rot(-1.35, 0, 0) }
   pose.Forearm_L = { r = rot(-1.35, 0, 0) }
   return pose
  end,
  -- з вантажем: корпус трохи назад (важко), похитується, ящик підстрибує в такт
  Carry=function(p, pose, rot, state)
   local s = math.sin(p)
   local to = pose.Torso or {}
   pose.Torso = { r = (to.r or CFrame.identity) * rot(-0.1, 0, 0.06 * s) }
   local hd = pose.Head or {}
   pose.Head = { r = (hd.r or CFrame.identity) * rot(-0.08, 0, 0) }
   return pose
  end,
  -- підбір: присідає, нахиляється й загрібає руду обома руками
  Pick=function(k, pose, rot)
   local e = math.sin(math.pi * k)
   local hp = pose.Hips or {}
   pose.Hips = { t = (hp.t or Vector3.zero) + Vector3.new(0, -0.9 * e, 0), r = hp.r }
   pose.Torso = { r = rot(0.65 * e, 0, 0) }
   pose.Head = { r = rot(-0.35 * e, 0, 0) }
   pose.Thigh_R = { r = rot(-0.75 * e, 0, 0) }
   pose.Thigh_L = { r = rot(-0.75 * e, 0, 0) }
   pose.Shin_R = { r = rot(1.1 * e, 0, 0) }
   pose.Shin_L = { r = rot(1.1 * e, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.35 * e, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(-0.35 * e, 0, 0) }
   return pose
  end,
 },
 bones={
  {name="Root",parent=nil,pos=Vector3.new(0,0,-0.2986)},
  {name="Hips",parent="Root",pos=Vector3.new(0,4.85,-0.2986)},
  {name="Torso",parent="Hips",pos=Vector3.new(0,5.6,-0.2986)},
  {name="Head",parent="Torso",pos=Vector3.new(0,9.9,0.4514)},
  {name="UpperArm_R",parent="Torso",pos=Vector3.new(5.2,9.4,-0.2986)},
  {name="Forearm_R",parent="UpperArm_R",pos=Vector3.new(5.5,6.9,0.0014)},
  {name="UpperArm_L",parent="Torso",pos=Vector3.new(-5.2,9.4,-0.2986)},
  {name="Forearm_L",parent="UpperArm_L",pos=Vector3.new(-5.5,6.9,0.0014)},
  {name="Thigh_R",parent="Hips",pos=Vector3.new(2,4.6,-0.2986)},
  {name="Shin_R",parent="Thigh_R",pos=Vector3.new(2.1,3.15,-0.2986)},
  {name="Thigh_L",parent="Hips",pos=Vector3.new(-2,4.6,-0.2986)},
  {name="Shin_L",parent="Thigh_L",pos=Vector3.new(-2.1,3.15,-0.2986)},
  {name="Eye_R",parent="Head",pos=Vector3.new(0.85,11.4,2.1764)},
  {name="Pupil_R",parent="Eye_R",pos=Vector3.new(0.78,11.29,2.2764)},
  {name="Brow_R",parent="Head",pos=Vector3.new(0.9,12.3,2.2014)},
  {name="Eye_L",parent="Head",pos=Vector3.new(-0.85,11.4,2.1764)},
  {name="Pupil_L",parent="Eye_L",pos=Vector3.new(-0.78,11.29,2.2764)},
  {name="Brow_L",parent="Head",pos=Vector3.new(-0.9,12.3,2.2014)},
  {name="Mouth",parent="Head",pos=Vector3.new(0,10.46,2.3014)},
  {name="MouthCorner_R",parent="Head",pos=Vector3.new(0.65,10.6,2.3014)},
  {name="MouthCorner_L",parent="Head",pos=Vector3.new(-0.65,10.6,2.3014)},
 },
 fx={
  {kind="blink",parts={"LampLens"},axis=Vector3.new(0.0,0.0,1.0),speed=1.5},
  {kind="blink",parts={"LampBeam"},axis=Vector3.new(0.0,0.0,1.0),speed=1.5},
  {kind="blink",parts={"LanternGlass"},axis=Vector3.new(0.0,0.0,1.0),speed=1.1,phase=2.0},
  {kind="sway",parts={"BandanaTail1","BandanaTail2"},pivot=Vector3.new(0.0,10.05,2.12),axis=Vector3.new(1.0,0.0,0.0),speed=4.0,amp=0.22,states={Run=2.2,Walk=1.5,Idle=0.6}},
  {kind="sway",parts={"HammerHandle","HammerHead"},pivot=Vector3.new(-3.25,5.2,0.5),axis=Vector3.new(1.0,0.0,0.0),speed=5.0,amp=0.3,states={Run=1.8,Walk=1.2,Idle=0.3}},
  {kind="sway",parts={"WrenchBar","WrenchJaw"},pivot=Vector3.new(3.3,5.15,0.6),axis=Vector3.new(1.0,0.0,0.0),speed=5.0,amp=0.3,phase=1.3,states={Run=1.8,Walk=1.2,Idle=0.3}},
  {kind="bob",parts={"Mustache","MustacheTip_R","MustacheTip_L"},axis=Vector3.new(0.0,1.0,0.0),speed=3.0,amp=0.05},
 },
 blocks={},
}
local RAW = {
 {"Foot_R","Shin_R","leather2",2.15,0.45,0.15,0,5,0,3,0.9,3.5},
 {"Foot_L","Shin_L","leather2",-2.15,0.45,0.15,0,-5,0,3,0.9,3.5},
 {"Shin_R","Shin_R","denim",2.1,2,-0.2,0,4,0,2.4,2.2,2.4},
 {"Shin_L","Shin_L","denim",-2.1,2,-0.2,0,-4,0,2.4,2.2,2.4},
 {"Thigh_R","Thigh_R","denim",2,3.85,-0.25,0,-6,0,2.45,1.6,2.45},
 {"Thigh_L","Thigh_L","denim",-2,3.85,-0.25,0,6,0,2.45,1.6,2.45},
 {"Pelvis","Hips","denim",0,5,-0.35,0,0,0,5.8,1.2,3.4},
 {"Belt","Hips","leather",0,5.4,-0.35,0,0,0,6,0.45,3.6},
 {"Torso","Torso","flannel",0,7.4,-0.3,0,0,0,6.8,4,4},
 {"Chest","Torso","flannel",0,9.45,-0.4,0,0,0,7.8,1.8,4.6},
 {"Head","Head","stone",0,11.15,0.5014,0,0,0,3.8,2.7,3.4},
 {"Jaw","Head","stone2",0,10,0.7,0,0,0,3.4,0.8,2.7},
 {"Shoulder_R","UpperArm_R","flannel",5.7,10.025,-0.3,0,0,4,2.2,1.35,3.2},
 {"Shoulder_L","UpperArm_L","flannel",-5.7,10.025,-0.3,0,0,-4,2.2,1.35,3.2},
 {"UpperArm_R","UpperArm_R","flannel",5.35,8.15,-0.3,0,4,0,2,2.6,2.1},
 {"UpperArm_L","UpperArm_L","flannel",-5.35,8.15,-0.3,0,-4,0,2,2.6,2.1},
 {"Forearm_R","Forearm_R","stone",5.55,5.55,0,0,-6,0,2.6,2.5,2.7},
 {"Forearm_L","Forearm_L","stone",-5.55,5.55,0,0,6,0,2.6,2.5,2.7},
 {"Fist_R","Forearm_R","leather",5.65,3.4,0.1014,0,6.875,0,3.2,1.9,3.2},
 {"Fist_L","Forearm_L","leather",-5.65,3.4,0.1014,0,-6.875,0,3.2,1.9,3.2},
 {"Knuckles_R","Forearm_R","leather2",5.9928,3.7,1.6918,0,6.875,0,2.6,0.8,0.4},
 {"Knuckles_L","Forearm_L","leather2",-5.9928,3.7,1.6918,0,-6.875,0,2.6,0.8,0.4},
 {"EyeWhite_R","Eye_R","light",0.85,11.4,2.1764,0,0,0,1.2,1.25,0.25},
 {"EyeWhite_L","Eye_L","light",-0.85,11.4,2.1764,0,0,0,1.2,1.25,0.25},
 {"Pupil_R","Pupil_R","dark",0.78,11.29,2.2764,0,0,0,0.66,0.83,0.25},
 {"Pupil_L","Pupil_L","dark",-0.78,11.29,2.2764,0,0,0,0.66,0.83,0.25},
 {"EyeShine_R","Pupil_R","light",0.64,11.523,2.3764,0,0,0,0.18,0.165,0.25},
 {"EyeShine_L","Pupil_L","light",-0.64,11.523,2.3764,0,0,0,0.18,0.165,0.25},
 {"Brow_R","Brow_R","dark",0.9,12.2,2.24,0,0,-6,1.2,0.3,0.3},
 {"Brow_L","Brow_L","dark",-0.9,12.2,2.24,0,0,6,1.2,0.3,0.3},
 {"Cheek_R","Head","pink",1.5375,10.75,2.2764,0,0,0,0.525,0.26,0.25},
 {"Cheek_L","Head","pink",-1.5375,10.75,2.2764,0,0,0,0.525,0.26,0.25},
 {"Mouth","Mouth","dark",0,10.46,2.3014,0,0,0,1.1,0.28,0.3},
 {"MouthCorner_R","MouthCorner_R","dark",0.65,10.6,2.3014,0,0,0,0.3,0.26,0.5},
 {"MouthCorner_L","MouthCorner_L","dark",-0.65,10.6,2.3014,0,0,0,0.3,0.26,0.5},
 {"Mustache","Head","stache",0,10.85,2.42,0,0,0,2.3,0.48,0.32},
 {"MustacheTip_R","Head","stache",1.25,10.62,2.38,0,0,-28,0.75,0.42,0.3},
 {"MustacheTip_L","Head","stache",-1.25,10.62,2.38,0,0,28,0.75,0.42,0.3},
 {"HatBrim","Head","helmet",0,12.45,0.6,0,0,0,4.7,0.22,4.5},
 {"HatBand","Head","leather",0,12.68,0.45,0,0,0,4,0.44,3.8},
 {"HatDome","Head","helmet",0,13,0.45,0,0,0,3.9,0.9,3.7},
 {"HatTop","Head","helmet",0,13.55,0.4,0,0,0,3.1,0.45,3},
 {"HatRidge","Head","helmet2",0,13.68,0.4,0,0,0,0.5,0.42,3.5},
 {"HatRib_R","Head","helmet2",1.2,13.2,0.42,0,0,0,0.3,0.6,3.5},
 {"HatRib_L","Head","helmet2",-1.2,13.2,0.42,0,0,0,0.3,0.6,3.5},
 {"LampMount","Head","leather",0,12.95,2.36,0,0,0,1.35,0.9,0.2},
 {"LampHousing","Head","brass",0,12.95,2.6,0,0,0,1,1,0.44},
 {"LampRim","Head","iron",0,12.95,2.88,0,0,0,1.1,1.1,0.12},
 {"LampRim2","Head","iron",0,12.95,2.89,0,0,45,1.1,1.1,0.22},
 {"LampLens","Head","lamp",0,12.95,2.97,0,0,0,0.78,0.78,0.16},
 {"LampBeam","Head","beam",0,12.75,5,-6,0,0,1.5,1.4,4},
 {"Bandana","Torso","bandana",0,10.38,0.55,0,0,0,4.3,0.55,3.55},
 {"BandanaKnot","Torso","bandana",0,10.12,2.12,0,0,45,0.65,0.5,0.34},
 {"BandanaTail1","Torso","bandana",0.32,9.55,2.15,0,0,16,0.38,0.95,0.17},
 {"BandanaTail2","Torso","bandana",-0.32,9.6,2.16,0,0,-16,0.38,0.85,0.17},
 {"Bib","Torso","denim",0,7.75,1.76,0,0,0,4.5,2.6,0.14},
 {"BibPocket","Torso","denim2",0,7.95,1.86,0,0,0,1.8,1,0.1},
 {"Pencil","Torso","helmet",0.55,8.55,1.92,0,0,0,0.13,0.6,0.13},
 {"Strap_R","Torso","denim",1.65,9.4,1.98,0,0,0,0.6,2.06,0.2},
 {"Strap_L","Torso","denim",-1.65,9.4,1.98,0,0,0,0.6,2.06,0.2},
 {"Button_R","Torso","brass",1.65,8.65,2.06,0,0,45,0.36,0.36,0.1},
 {"Button_L","Torso","brass",-1.65,8.65,2.06,0,0,-45,0.36,0.36,0.1},
 {"StrapBackA","Torso","denim",0,8.1,-2.38,0,0,32,0.6,4.2,0.1},
 {"StrapBackB","Torso","denim",0,8.1,-2.39,0,0,-32,0.6,4.2,0.2},
 {"PlaidV_R","Torso","flannel2",2.75,7.4,1.72,0,0,0,0.18,3.94,0.1},
 {"PlaidV_L","Torso","flannel2",-2.75,7.4,1.72,0,0,0,0.18,3.94,0.1},
 {"PlaidH_R","Torso","flannel2",3.42,7,-0.3,0,0,0,0.1,0.18,3.94},
 {"PlaidH_L","Torso","flannel2",-3.42,7,-0.3,0,0,0,0.1,0.18,3.94},
 {"BeltBuckle","Hips","brass",0,5.4,1.48,0,0,0,1,0.55,0.12},
 {"ToolPouch_R","Hips","leather",2.45,4.75,1.4,0,0,0,1.05,1.1,0.6},
 {"ToolPouch_L","Hips","leather",-2.45,4.75,1.4,0,0,0,1.05,1.1,0.6},
 {"PouchFlap_R","Hips","leather2",2.45,5.15,1.72,0,0,0,1.1,0.4,0.1},
 {"PouchFlap_L","Hips","leather2",-2.45,5.15,1.72,0,0,0,1.1,0.4,0.1},
 {"HammerHandle","Hips","wood",-3.3,4.35,0.5,0,0,8,0.24,1.7,0.24},
 {"HammerHead","Hips","iron",-3.4,3.55,0.5,0,0,0,0.85,0.38,0.38},
 {"WrenchBar","Hips","iron",3.35,4.4,0.6,0,0,-6,0.2,1.5,0.14},
 {"WrenchJaw","Hips","iron",3.4,3.62,0.6,0,0,0,0.55,0.32,0.08},
 {"BootToe_R","Shin_R","iron",2.2,0.62,1.78,0,5,0,2.7,0.45,0.5},
 {"BootToe_L","Shin_L","iron",-2.2,0.62,1.78,0,-5,0,2.7,0.45,0.5},
 {"BootCuff_R","Shin_R","leather2",2.12,1.15,-0.1,0,0,0,2.35,0.55,2.35},
 {"BootCuff_L","Shin_L","leather2",-2.12,1.15,-0.1,0,0,0,2.35,0.55,2.35},
 {"BootLace_R","Shin_R","light",2.2,0.98,1.62,0,5,0,0.9,0.12,0.1},
 {"BootLace_L","Shin_L","light",-2.2,0.98,1.62,0,-5,0,0.9,0.12,0.1},
 {"PantCuff_R","Shin_R","denim2",2.1,1.52,-0.2,0,0,0,2.75,0.36,2.75},
 {"PantCuff_L","Shin_L","denim2",-2.1,1.52,-0.2,0,0,0,2.75,0.36,2.75},
 {"ElbowCap_R","Forearm_R","stone2",5.5,6.9,-0.15,0,0,0,2.3,0.85,2.35},
 {"ElbowCap_L","Forearm_L","stone2",-5.5,6.9,-0.15,0,0,0,2.3,0.85,2.35},
 {"KneeCap_R","Shin_R","denim",2.1,3.12,-0.2,0,0,0,2.55,0.7,2.55},
 {"KneeCap_L","Shin_L","denim",-2.1,3.12,-0.2,0,0,0,2.55,0.7,2.55},
 {"HipRing_R","Thigh_R","denim",2,4.62,-0.25,0,0,0,2.6,0.34,2.6},
 {"HipRing_L","Thigh_L","denim",-2,4.62,-0.25,0,0,0,2.6,0.34,2.6},
 {"KneePatch_R","Shin_R","leather",2.15,2.55,1.05,0,4,0,1.2,0.8,0.1},
 {"KneePatch_L","Shin_L","leather",-2.15,2.55,1.05,0,-4,0,1.2,0.8,0.1},
 {"ThighPocket_R","Thigh_R","denim2",3.31,3.75,-0.1,0,0,0,0.25,0.8,1},
 {"ThighPocket_L","Thigh_L","denim2",-3.31,3.75,-0.1,0,0,0,0.25,0.85,1},
 {"ShoulderJoint_R","UpperArm_R","flannel2",4.25,9.9,-0.3,0,0,0,0.95,0.95,0.95},
 {"ShoulderJoint_L","UpperArm_L","flannel2",-4.25,9.9,-0.3,0,0,0,0.95,0.95,0.95},
 {"SleeveRoll_R","UpperArm_R","flannel2",5.35,7.1,-0.3,0,4,0,2.4,0.55,2.5},
 {"SleeveRoll_L","UpperArm_L","flannel2",-5.35,7.1,-0.3,0,-4,0,2.4,0.55,2.5},
 {"SleevePlaid_R","UpperArm_R","flannel2",5.35,8.4,0.83,0,4,0,0.18,1.9,0.1},
 {"SleevePlaid_L","UpperArm_L","flannel2",-5.35,8.4,0.83,0,-4,0,0.18,1.9,0.1},
 {"ForearmBulk_R","Forearm_R","stone",5.55,5.95,0,0,-6,0,2.95,1.3,3.05},
 {"ForearmBulk_L","Forearm_L","stone",-5.55,5.95,0,0,6,0,2.95,1.3,3.05},
 {"Tattoo_R","Forearm_R","denim",7.04,5.95,-0.15,45,-6,0,0.06,0.55,0.55},
 {"Tattoo_L","Forearm_L","denim",-7.04,5.95,-0.15,45,6,0,0.06,0.55,0.55},
 {"GloveCuff_R","Forearm_R","leather2",5.6,4.42,0.05,0,0,0,3.1,0.55,3.2},
 {"GloveCuff_L","Forearm_L","leather2",-5.6,4.42,0.05,0,0,0,3.1,0.55,3.2},
 {"GloveSeam_R","Forearm_R","leather2",5.4549,3.4,-1.5169,0,6.875,0,1.8,0.14,0.1},
 {"GloveSeam_L","Forearm_L","leather2",-5.4549,3.4,-1.5169,0,-6.875,0,1.8,0.14,0.1},
 {"GloveThumb_R","Forearm_R","leather",4.0381,3.5,1.1015,0,6.875,0,0.5,1.1,0.7},
 {"GloveThumb_L","Forearm_L","leather",-4.0381,3.5,1.1015,0,-6.875,0,0.5,1.1,0.7},
 {"Pack","Torso","leather",0,7.6,-2.95,0,0,0,3.6,3.2,1.4},
 {"PackFlap","Torso","leather2",0,8.95,-3.05,0,0,0,3.7,0.72,1.67},
 {"PackBuckle","Torso","brass",0,8.5,-3.72,0,0,0,0.42,0.42,0.11},
 {"Bedroll","Torso","canvas",0,9.75,-2.95,0,0,0,4.4,0.95,0.95},
 {"BedrollStrap_R","Torso","leather",1.25,9.75,-2.95,0,0,0,0.22,1.05,1.05},
 {"BedrollStrap_L","Torso","leather",-1.25,9.75,-2.95,0,0,0,0.22,1.05,1.05},
 {"LanternHook","Torso","iron",2.15,8.55,-3.2,0,0,0,0.16,0.65,0.16},
 {"LanternTop","Torso","iron",2.15,8.12,-3.2,0,0,0,0.72,0.26,0.72},
 {"LanternGlass","Torso","ember",2.15,7.62,-3.2,0,0,0,0.55,0.75,0.55},
 {"LanternBarA","Torso","iron",2.15,7.62,-3.2,0,0,0,0.64,0.81,0.08},
 {"LanternBarB","Torso","iron",2.15,7.62,-3.2,0,0,0,0.08,0.69,0.64},
 {"LanternBase","Torso","iron",2.15,7.12,-3.2,0,0,0,0.72,0.22,0.72},
 {"Handle","Forearm_L","wood",-5.65,3.5701,1.4896,83.02,0,0,0.6,5.8,0.6,"Pickaxe"},
 {"Grip","Forearm_L","leather",-5.65,3.3514,-0.297,83.02,0,0,0.78,1.6,0.78,"Pickaxe"},
 {"Head","Forearm_L","iron",-5.65,4.36,7.9415,83.02,0,0,1,1,1.3,"Pickaxe"},
 {"Pick1","Forearm_L","iron",-5.65,3.1427,7.8729,93.224,0,0,0.34,0.9,1.2,"Pickaxe"},
 {"Pick2","Forearm_L","iron",-5.65,2.0268,7.81,93.224,0,0,0.28,0.75,1.1,"Pickaxe"},
 {"Pick3","Forearm_L","iron",-5.65,1.0123,7.7529,93.224,0,0,0.22,0.6,0.9,"Pickaxe"},
 {"Pick4","Forearm_L","iron",-5.65,0.2007,7.7072,93.224,0,0,0.2,0.4,0.7,"Pickaxe"},
 {"SwordGrip","Forearm_L","wood",-5.65,3.4243,0.2985,83.02,0,0,0.6,3,0.6,"Sword"},
 {"SwordBlade","Forearm_L","iron",-5.65,3.959,4.6659,83.02,0,0,0.22,5.6,0.7,"Sword"},
 {"Bottom","Box","wood2",0,0,0,0,0,0,4.2,0.3,2.4,"Box"},
 {"FloorRaised","Box","wood2",0,0.6,0,0,0,0,3.5,1,1.8,"Box"},
 {"WallF","Box","wood",0,0.95,1.08,0,0,0,3.9,1.6,0.25,"Box"},
 {"WallB","Box","wood",0,0.95,-1.08,0,0,0,3.9,1.6,0.25,"Box"},
 {"WallR","Box","wood",1.92,0.95,0,0,0,0,0.25,1.54,2.15,"Box"},
 {"WallL","Box","wood",-1.92,0.95,0,0,0,0,0.25,1.54,2.15,"Box"},
 {"PlankF1","Box","wood2",0,0.55,1.22,0,0,0,3.84,0.07,0.1,"Box"},
 {"PlankF2","Box","wood2",0,1.15,1.22,0,0,0,3.84,0.07,0.1,"Box"},
 {"BandF1","Box","iron",1.15,0.95,1.22,0,0,0,0.26,1.7,0.22,"Box"},
 {"BandF2","Box","iron",-1.15,0.95,1.22,0,0,0,0.26,1.7,0.22,"Box"},
 {"PlankB1","Box","wood2",0,0.55,-1.22,0,0,0,3.84,0.07,0.1,"Box"},
 {"PlankB2","Box","wood2",0,1.15,-1.22,0,0,0,3.84,0.07,0.1,"Box"},
 {"BandB1","Box","iron",1.15,0.95,-1.22,0,0,0,0.26,1.7,0.22,"Box"},
 {"BandB2","Box","iron",-1.15,0.95,-1.22,0,0,0,0.26,1.7,0.22,"Box"},
 {"RimF","Box","iron",0,1.82,1.1,0,0,0,4.25,0.2,0.41,"Box"},
 {"RimB","Box","iron",0,1.82,-1.1,0,0,0,4.25,0.2,0.41,"Box"},
 {"RimR","Box","iron",1.95,1.82,0,0,0,0,0.3,0.14,2,"Box"},
 {"RimL","Box","iron",-1.95,1.82,0,0,0,0,0.3,0.14,2,"Box"},
 {"CornerRF","Box","brass",1.97,1.82,1.12,0,0,0,0.47,0.3,0.52,"Box"},
 {"WheelRF","Box","iron",1.4184,0.18,1.3216,0,90,0,0.24,0.72,0.72,"Box"},
 {"HubRF","Box","brass",1.4184,0.18,1.3888,0,0,0,0.26,0.26,0.2,"Box"},
 {"CornerRB","Box","brass",1.97,1.82,-1.12,0,0,0,0.47,0.3,0.52,"Box"},
 {"WheelRB","Box","iron",1.4184,0.18,-1.3216,0,90,0,0.24,0.72,0.72,"Box"},
 {"HubRB","Box","brass",1.4184,0.18,-1.3888,0,0,0,0.26,0.26,0.2,"Box"},
 {"CornerLF","Box","brass",-1.97,1.82,1.12,0,0,0,0.47,0.3,0.52,"Box"},
 {"WheelLF","Box","iron",-1.4184,0.18,1.3216,0,90,0,0.24,0.72,0.72,"Box"},
 {"HubLF","Box","brass",-1.4184,0.18,1.3888,0,0,0,0.26,0.26,0.2,"Box"},
 {"CornerLB","Box","brass",-1.97,1.82,-1.12,0,0,0,0.47,0.3,0.52,"Box"},
 {"WheelLB","Box","iron",-1.4184,0.18,-1.3216,0,90,0,0.24,0.72,0.72,"Box"},
 {"HubLB","Box","brass",-1.4184,0.18,-1.3888,0,0,0,0.26,0.26,0.2,"Box"},
 {"CartPole","Box","iron",1.75,2.15,0.85,0,0,0,0.1,0.5,0.1,"Box"},
 {"CartLanternTop","Box","iron",1.75,2.75,0.85,0,0,0,0.5,0.15,0.5,"Box"},
 {"CartLanternGlass","Box","ember",1.75,2.45,0.85,0,0,0,0.38,0.45,0.38,"Box"},
 {"CartLanternBase","Box","iron",1.75,2.18,0.85,0,0,0,0.5,0.1,0.5,"Box"},
 {"Nugget1","Box","brass",-1.3,1.98,0.6,20,30,10,0.35,0.3,0.35,"Box"},
 {"Nugget2","Box","brass",-0.9,1.98,0.85,10,60,25,0.25,0.22,0.25,"Box"},
}
local rad = math.rad
for _, r in RAW do
	table.insert(D.blocks, { name = r[1], group = r[13], bone = r[2], col = r[3], cf = CFrame.new(r[4], r[5], r[6]) * CFrame.Angles(rad(r[7]), rad(r[8]), rad(r[9])), s = Vector3.new(r[10], r[11], r[12]) })
end
return D
