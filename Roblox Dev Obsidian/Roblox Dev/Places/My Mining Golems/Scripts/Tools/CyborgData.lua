-- Cyborg Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано mkx/gen.py (05.11.2026).
-- Ексклюзив Marketplace. Анімації — GolemAnimator v4 (NicheTools/GolemAnimatorV4): fx spin/sway/bob/pulse/hue/blink, власні пози Idle/Walk/Run/Mine/Carry/Pick.
-- Блоки — компактно в RAW: { ім'я, кістка, колір, x, y, z, rx, ry, rz (градуси, CFrame.Angles), sx, sy, sz, група? } → D.blocks (формат Clay / Astral).
local D = {
 colors={chrome="#e3e9f0",steel="#9aa6b5",gun="#3a4352",dark="#151a21",neon="#22eaff",red="#ff2d4a",light="#f4f8fb",glass="#0b1018",holo="#7ff6ff"},
 neon={holo=true,neon=true,red=true},
 alpha={holo=0.45},
 hue={"#22eaff","#3d7bff","#a24dff","#ff3df2"},
 hueSpeed=1.8,hueWave=0.07,
 poses={
  -- спокій: «сканування» — голова повертається ривками сервоприводів (пауза, швидкий поворот), руки напружені
  Idle=function(p, pose, rot)
   local Y = { 0, 0.38, 0.38, 0, -0.38, -0.38 }
   local x = p / (2 * math.pi) * 6
   local i = math.floor(x)
   local f = math.clamp((x - i - 0.72) / 0.28, 0, 1)
   f = f * f * (3 - 2 * f)
   local yaw = Y[i % 6 + 1] + (Y[(i + 1) % 6 + 1] - Y[i % 6 + 1]) * f
   pose.Head = { r = rot(-0.04, yaw, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.12, 0, 0.14) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(-0.12, 0, -0.14) }
   pose.Forearm_R = { r = rot(-0.45, 0, 0) }
   pose.Forearm_L = { r = rot(-0.45, 0, 0) }
   return pose
  end,
  -- хода робота: руки рубають короткими фіксованими махами, коліна майже не гнуться, корпус рівний
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   local q = math.tanh(4 * s)
   pose.UpperArm_R = { r = rot(0.42 * q, 0, 0.1) }
   pose.UpperArm_L = { r = rot(-0.42 * q, 0, -0.1) }
   pose.Forearm_R = { r = rot(-0.55, 0, 0) }
   pose.Forearm_L = { r = rot(-0.55, 0, 0) }
   pose.Thigh_R = { r = rot(-0.4 * q, 0, 0) }
   pose.Thigh_L = { r = rot(0.4 * q, 0, 0) }
   pose.Shin_R = { r = rot(0.25 * math.max(0, math.cos(p)), 0, 0) }
   pose.Shin_L = { r = rot(0.25 * math.max(0, -math.cos(p)), 0, 0) }
   pose.Torso = { r = rot(0.05, 0, 0) }
   pose.Head = { r = rot(-0.04, 0.08 * math.sin(p * 0.5), 0) }
   return pose
  end,
  -- біг-«форсаж»: корпус низько вперед, руки назад як сопла, ноги підібрані (реактивні п'яти горять)
  Run=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = rot(0.45, 0, 0.05 * s) }
   pose.Head = { r = rot(-0.32, 0, 0) }
   pose.UpperArm_R = { r = rot(1.0, 0, 0.28) }
   pose.UpperArm_L = { r = rot(1.0, 0, -0.28) }
   pose.Forearm_R = { r = rot(-0.12, 0, 0) }
   pose.Forearm_L = { r = rot(-0.12, 0, 0) }
   pose.Thigh_R = { r = rot(-0.45 - 0.3 * s, 0, 0) }
   pose.Thigh_L = { r = rot(-0.45 + 0.3 * s, 0, 0) }
   pose.Shin_R = { r = rot(0.6 + 0.2 * math.max(0, math.cos(p)), 0, 0) }
   pose.Shin_L = { r = rot(0.6 + 0.2 * math.max(0, -math.cos(p)), 0, 0) }
   return pose
  end,
  -- удар: права рука «заряджає» кірку (знизу вгору), після удару корпус і рука вібрують, як відбійний молот
  Mine=function(p, pose, rot)
   local t = p / (2 * math.pi) * 1.4
   if t > 0.15 and t < 0.62 then
    local k = math.sin((t - 0.15) / 0.47 * math.pi)
    local ur = pose.UpperArm_R or {}
    pose.UpperArm_R = { r = (ur.r or CFrame.identity) * rot(-0.7 * k, 0, 0.35 * k) }
    local hd = pose.Head or {}
    pose.Head = { r = (hd.r or CFrame.identity) * rot(-0.15 * k, 0, 0) }
   end
   if t > 0.62 and t < 1.0 then
    local k = 1 - (t - 0.62) / 0.38
    local j = math.sin(t * 150) * 0.06 * k
    local to = pose.Torso or {}
    pose.Torso = { r = (to.r or CFrame.identity) * rot(j, j * 0.7, 0), t = to.t }
    local ul = pose.UpperArm_L or {}
    pose.UpperArm_L = { r = (ul.r or CFrame.identity) * rot(j * 1.6, 0, 0) }
   end
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
  {kind="hue",parts={"Cheek_R","Cheek_L","Visor","EarCore_R","EarCore_L","JawVent1","JawVent2","JawVent3","ShinStripe_R","ShinStripe_L","KneeLight_R","KneeLight_L","ThighVent_R","ThighVent_L","BeltCore","RibVent1_R","RibVent1_L","RibVent2_R","RibVent2_L","RibVent3_R","RibVent3_L","ChestTrim","SpineLight1","SpineLight2","SpineLight3","SpineLight4","PauldronTrim_R","PauldronTrim_L","FanCore_R","FanCore_L","UpperPlateLine_R","UpperPlateLine_L","ElbowLight_R","ElbowLight_L","ForearmStripe_R","ForearmStripe_L"},axis=Vector3.new(0.0,0.0,1.0),speed=1.8,amp=0.07},
  {kind="spin",parts={"ReactorSeg1","ReactorSeg2","ReactorSeg3","ReactorSeg4","ReactorSeg5","ReactorSeg6","ReactorSeg7","ReactorSeg8"},pivot=Vector3.new(0.0,7.6,1.92),axis=Vector3.new(0.0,0.0,1.0),speed=2.4,states={Mine=2,Run=1.8}},
  {kind="pulse",parts={"ReactorCore"},axis=Vector3.new(0.0,0.0,1.0),speed=4.0,amp=0.14,states={Mine=1.6}},
  {kind="spin",parts={"EyeRing1","EyeRing2","EyeRing3","EyeRing4"},pivot=Vector3.new(0.85,11.4,2.32),axis=Vector3.new(0.0,0.0,1.0),speed=-1.6},
  {kind="spin",parts={"EarRotorA_R","EarRotorB_R"},pivot=Vector3.new(2.12,11.2,0.5),axis=Vector3.new(1.0,0.0,0.0),speed=6.0,states={Run=1.8}},
  {kind="spin",parts={"EarRotorA_L","EarRotorB_L"},pivot=Vector3.new(-2.12,11.2,0.5),axis=Vector3.new(-1.0,0.0,0.0),speed=6.0,states={Run=1.8}},
  {kind="spin",parts={"FanBladeA_R","FanBladeB_R"},pivot=Vector3.new(5.95,11.4,-0.6),axis=Vector3.new(0.0,1.0,0.0),speed=7.0,states={Run=1.7,Mine=1.4}},
  {kind="spin",parts={"FanBladeA_L","FanBladeB_L"},pivot=Vector3.new(-5.95,11.4,-0.6),axis=Vector3.new(0.0,-1.0,0.0),speed=7.0,states={Run=1.7,Mine=1.4}},
  {kind="pulse",parts={"ThrusterFlame_R","ThrusterFlame_L","HeelFlame_R","HeelFlame_L"},axis=Vector3.new(0.0,0.0,1.0),speed=9.0,amp=0.22,states={Run=1.8,Idle=0.5}},
  {kind="pulse",parts={"FingerTip1_R","FingerTip1_L","FingerTip2_R","FingerTip2_L","FingerTip3_R","FingerTip3_L","FingerTip4_R","FingerTip4_L"},axis=Vector3.new(0.0,0.0,1.0),speed=5.0,amp=0.12,states={Mine=2}},
  {kind="blink",parts={"AntennaTip"},axis=Vector3.new(0.0,0.0,1.0),speed=2.2},
 },
 blocks={},
}
local RAW = {
 {"Foot_R","Shin_R","dark",2.15,0.45,0.15,0,5,0,3,0.9,3.5},
 {"Foot_L","Shin_L","dark",-2.15,0.45,0.15,0,-5,0,3,0.9,3.5},
 {"Shin_R","Shin_R","chrome",2.1,2,-0.2,0,4,0,2.4,2.2,2.4},
 {"Shin_L","Shin_L","chrome",-2.1,2,-0.2,0,-4,0,2.4,2.2,2.4},
 {"Thigh_R","Thigh_R","gun",2,3.85,-0.25,0,-6,0,2.45,1.6,2.45},
 {"Thigh_L","Thigh_L","gun",-2,3.85,-0.25,0,6,0,2.45,1.6,2.45},
 {"Pelvis","Hips","dark",0,5,-0.35,0,0,0,5.8,1.2,3.4},
 {"Belt","Hips","steel",0,5.4,-0.35,0,0,0,6,0.45,3.6},
 {"Torso","Torso","gun",0,7.4,-0.3,0,0,0,6.8,4,4},
 {"Chest","Torso","chrome",0,9.45,-0.4,0,0,0,7.8,1.8,4.6},
 {"Head","Head","steel",0,11.15,0.5014,0,0,0,3.8,2.7,3.4},
 {"Jaw","Head","dark",0,10,0.7,0,0,0,3.4,0.8,2.7},
 {"Shoulder_R","UpperArm_R","gun",5.7,10.025,-0.3,0,0,4,2.2,1.35,3.2},
 {"Shoulder_L","UpperArm_L","gun",-5.7,10.025,-0.3,0,0,-4,2.2,1.35,3.2},
 {"UpperArm_R","UpperArm_R","dark",5.35,8.15,-0.3,0,4,0,2,2.6,2.1},
 {"UpperArm_L","UpperArm_L","dark",-5.35,8.15,-0.3,0,-4,0,2,2.6,2.1},
 {"Forearm_R","Forearm_R","chrome",5.55,5.55,0,0,-6,0,2.6,2.5,2.7},
 {"Forearm_L","Forearm_L","chrome",-5.55,5.55,0,0,6,0,2.6,2.5,2.7},
 {"Fist_R","Forearm_R","dark",5.65,3.4,0.1014,0,6.875,0,3.2,1.9,3.2},
 {"Fist_L","Forearm_L","dark",-5.65,3.4,0.1014,0,-6.875,0,3.2,1.9,3.2},
 {"EyeWhite_L","Eye_L","light",-0.85,11.4,2.1764,0,0,0,1.2,1.25,0.25},
 {"EyeWhite_R","Eye_R","glass",0.85,11.4,2.1764,0,0,0,1.2,1.25,0.25},
 {"Pupil_L","Pupil_L","dark",-0.78,11.29,2.2764,0,0,0,0.66,0.83,0.25},
 {"Pupil_R","Pupil_R","red",0.78,11.29,2.2764,0,0,0,0.62,0.62,0.25},
 {"EyeShine_R","Pupil_R","light",0.64,11.523,2.3764,0,0,0,0.18,0.105,0.25},
 {"EyeShine_L","Pupil_L","light",-0.64,11.523,2.3764,0,0,0,0.18,0.165,0.25},
 {"Brow_L","Brow_L","dark",-0.9,12.2,2.24,0,0,6,1.2,0.3,0.3},
 {"Brow_R","Brow_R","gun",0.9,12.2,2.24,0,0,-6,1.2,0.3,0.3},
 {"Cheek_R","Head","neon",1.5375,10.75,2.2764,0,0,0,0.5,0.14,0.2},
 {"Cheek_L","Head","neon",-1.5375,10.75,2.2764,0,0,0,0.5,0.14,0.2},
 {"Mouth","Mouth","dark",0,10.46,2.3014,0,0,0,1.1,0.28,0.3},
 {"MouthCorner_R","MouthCorner_R","dark",0.65,10.6,2.3014,0,0,0,0.3,0.26,0.5},
 {"MouthCorner_L","MouthCorner_L","dark",-0.65,10.6,2.3014,0,0,0,0.3,0.26,0.5},
 {"EyeRing1","Head","chrome",1.4298,11.9798,2.32,0,0,135,0.42,0.16,0.2},
 {"EyeRing2","Head","chrome",0.2702,11.9798,2.32,0,0,-135,0.42,0.16,0.2},
 {"EyeRing3","Head","chrome",0.2702,10.8202,2.32,0,0,-45,0.42,0.16,0.12},
 {"EyeRing4","Head","chrome",1.4298,10.8202,2.32,0,0,45,0.42,0.16,0.17},
 {"Helmet","Head","dark",0,12.62,0.5,0,0,0,4,0.45,3.6},
 {"HelmetRidge","Head","chrome",0,12.98,0.35,0,0,0,0.7,0.4,3.1},
 {"Visor","Head","neon",0,12.62,2.31,0,0,0,3.4,0.2,0.12},
 {"AntennaBase","Head","gun",-2.05,12.1,0.1,0,0,0,0.45,0.9,0.9},
 {"Antenna","Head","steel",-2.2,13.5,-0.1,0,0,8,0.15,2.4,0.15},
 {"AntennaTip","Head","red",-2.37,14.75,-0.1,45,45,0,0.36,0.36,0.36},
 {"EarDisc_R","Head","gun",1.98,11.2,0.5,0,0,0,0.22,1.35,1.35},
 {"EarDisc_L","Head","gun",-1.98,11.2,0.5,0,0,0,0.22,1.35,1.35},
 {"EarRotorA_R","Head","steel",2.12,11.2,0.5,0,0,0,0.1,1.25,0.26},
 {"EarRotorA_L","Head","steel",-2.12,11.2,0.5,0,0,0,0.1,1.25,0.26},
 {"EarRotorB_R","Head","steel",2.12,11.2,0.5,0,0,0,0.15,0.26,1.25},
 {"EarRotorB_L","Head","steel",-2.12,11.2,0.5,0,0,0,0.15,0.26,1.25},
 {"EarCore_R","Head","neon",2.2,11.2,0.5,0,0,0,0.1,0.42,0.42},
 {"EarCore_L","Head","neon",-2.2,11.2,0.5,0,0,0,0.1,0.42,0.42},
 {"JawVent1","Head","neon",-0.85,9.98,2.07,0,0,0,0.5,0.12,0.1},
 {"JawVent2","Head","neon",0,9.98,2.07,0,0,0,0.5,0.12,0.1},
 {"JawVent3","Head","neon",0.85,9.98,2.07,0,0,0,0.5,0.12,0.1},
 {"ToeCap_R","Shin_R","chrome",2.2,0.62,1.78,0,5,0,2.7,0.5,0.45},
 {"ToeCap_L","Shin_L","chrome",-2.2,0.62,1.78,0,-5,0,2.7,0.5,0.45},
 {"HeelJet_R","Shin_R","gun",2.1,0.62,-1.7,0,0,0,1.5,0.75,0.5},
 {"HeelJet_L","Shin_L","gun",-2.1,0.62,-1.7,0,0,0,1.5,0.75,0.5},
 {"HeelFlame_R","Shin_R","neon",2.1,0.62,-2.05,0,0,0,0.95,0.42,0.3},
 {"HeelFlame_L","Shin_L","neon",-2.1,0.62,-2.05,0,0,0,0.95,0.42,0.3},
 {"AnkleJoint_R","Shin_R","gun",2.12,1.15,-0.1,0,0,0,1.6,0.55,1.6},
 {"AnkleJoint_L","Shin_L","gun",-2.12,1.15,-0.1,0,0,0,1.6,0.55,1.6},
 {"ShinStripe_R","Shin_R","neon",2.18,2,1.07,0,4,0,0.36,1,0.12},
 {"ShinStripe_L","Shin_L","neon",-2.18,2,1.07,0,-4,0,0.36,1,0.12},
 {"ShinPlate_R","Shin_R","steel",2,2,-1.5,0,4,0,1.9,1.6,0.2},
 {"ShinPlate_L","Shin_L","steel",-2,2,-1.5,0,-4,0,1.9,1.6,0.2},
 {"ElbowCap_R","Forearm_R","gun",5.5,6.9,-0.15,0,0,0,2.3,0.85,2.35},
 {"ElbowCap_L","Forearm_L","gun",-5.5,6.9,-0.15,0,0,0,2.3,0.85,2.35},
 {"KneeCap_R","Shin_R","gun",2.1,3.12,-0.2,0,0,0,2.55,0.7,2.55},
 {"KneeCap_L","Shin_L","gun",-2.1,3.12,-0.2,0,0,0,2.55,0.7,2.55},
 {"HipRing_R","Thigh_R","dark",2,4.62,-0.25,0,0,0,2.6,0.34,2.6},
 {"HipRing_L","Thigh_L","dark",-2,4.62,-0.25,0,0,0,2.6,0.34,2.6},
 {"KneeLight_R","Shin_R","neon",2.1,3.12,1.1,0,0,0,0.6,0.3,0.12},
 {"KneeLight_L","Shin_L","neon",-2.1,3.12,1.1,0,0,0,0.6,0.3,0.12},
 {"ThighRod_R","Thigh_R","steel",3.38,3.85,-0.25,0,0,0,0.26,1.35,0.36},
 {"ThighRod_L","Thigh_L","steel",-3.38,3.85,-0.25,0,0,0,0.26,1.35,0.36},
 {"ThighVent_R","Thigh_R","neon",2,3.85,1.06,0,-6,0,1.3,0.16,0.1},
 {"ThighVent_L","Thigh_L","neon",-2,3.85,1.06,0,6,0,1.3,0.16,0.1},
 {"BeltPlate","Hips","chrome",0,5.4,1.47,0,0,0,1.8,0.62,0.1},
 {"BeltCore","Hips","neon",0,5.4,1.54,0,0,0,1,0.3,0.1},
 {"HipPlate_R","Hips","chrome",2.95,4.95,-0.35,0,0,0,0.4,1.15,2.9},
 {"HipPlate_L","Hips","chrome",-2.95,4.95,-0.35,0,0,0,0.4,1.15,2.9},
 {"ReactorHousing","Torso","dark",0,7.6,1.76,0,0,0,2.3,2.3,0.2},
 {"ReactorHousing2","Torso","dark",0,7.6,1.77,0,0,45,2.3,2.3,0.1},
 {"ReactorRim","Torso","chrome",0,7.6,1.8,0,0,22.5,1.75,1.75,0.3},
 {"ReactorSeg1","Torso","neon",0.68,7.6,1.92,0,0,90,0.42,0.17,0.12},
 {"ReactorSeg2","Torso","neon",0.4808,8.0808,1.92,0,0,135,0.42,0.17,0.12},
 {"ReactorSeg3","Torso","neon",0,8.28,1.92,0,0,180,0.42,0.17,0.12},
 {"ReactorSeg4","Torso","neon",-0.4808,8.0808,1.92,0,0,-135,0.42,0.17,0.12},
 {"ReactorSeg5","Torso","neon",-0.68,7.6,1.92,0,0,-90,0.42,0.17,0.12},
 {"ReactorSeg6","Torso","neon",-0.4808,7.1192,1.92,0,0,-45,0.42,0.17,0.12},
 {"ReactorSeg7","Torso","neon",0,6.92,1.92,0,0,0,0.42,0.17,0.12},
 {"ReactorSeg8","Torso","neon",0.4808,7.1192,1.92,0,0,45,0.42,0.17,0.12},
 {"ReactorCore","Torso","light",0,7.6,1.93,0,0,45,0.62,0.62,0.16},
 {"Ab_R","Torso","steel",0.85,6.05,1.74,0,0,0,1.3,0.6,0.22},
 {"Ab_L","Torso","steel",-0.85,6.05,1.74,0,0,0,1.3,0.6,0.22},
 {"RibVent1_R","Torso","neon",3.43,6.6,-0.3,0,0,0,0.1,0.16,1.7},
 {"RibVent1_L","Torso","neon",-3.43,6.6,-0.3,0,0,0,0.1,0.16,1.7},
 {"RibVent2_R","Torso","neon",3.43,7.2,-0.3,0,0,0,0.1,0.16,1.7},
 {"RibVent2_L","Torso","neon",-3.43,7.2,-0.3,0,0,0,0.1,0.16,1.7},
 {"RibVent3_R","Torso","neon",3.43,7.8,-0.3,0,0,0,0.1,0.16,1.7},
 {"RibVent3_L","Torso","neon",-3.43,7.8,-0.3,0,0,0,0.1,0.16,1.7},
 {"Collar","Torso","dark",0,10.45,-0.4,0,0,0,4.1,0.4,3.3},
 {"ChestTrim","Torso","neon",0,9.45,2.02,0,0,0,5.8,0.16,0.1},
 {"Thruster_R","Torso","gun",1.3,7.8,-2.85,0,0,0,1.15,2.6,1.15},
 {"Thruster_L","Torso","gun",-1.3,7.8,-2.85,0,0,0,1.15,2.6,1.15},
 {"ThrusterRing_R","Torso","steel",1.3,6.45,-2.85,0,0,0,1.35,0.32,1.35},
 {"ThrusterRing_L","Torso","steel",-1.3,6.45,-2.85,0,0,0,1.35,0.32,1.35},
 {"ThrusterFlame_R","Torso","neon",1.3,6,-2.85,0,0,0,0.75,0.6,0.75},
 {"ThrusterFlame_L","Torso","neon",-1.3,6,-2.85,0,0,0,0.75,0.6,0.75},
 {"Spine1","Torso","dark",0,6.3,-2.42,0,0,0,0.7,0.5,0.3},
 {"SpineLight1","Torso","neon",0,6.3,-2.6,0,0,0,0.3,0.2,0.1},
 {"Spine2","Torso","dark",0,7.25,-2.42,0,0,0,0.7,0.5,0.3},
 {"SpineLight2","Torso","neon",0,7.25,-2.6,0,0,0,0.3,0.2,0.1},
 {"Spine3","Torso","dark",0,8.2,-2.42,0,0,0,0.7,0.5,0.3},
 {"SpineLight3","Torso","neon",0,8.2,-2.6,0,0,0,0.3,0.2,0.1},
 {"Spine4","Torso","dark",0,9.15,-2.42,0,0,0,0.7,0.44,0.3},
 {"SpineLight4","Torso","neon",0,9.15,-2.6,0,0,0,0.3,0.2,0.1},
 {"BackFin_R","Torso","chrome",2.1,9.6,-2.7,0,0,-18,0.25,1.7,1.2},
 {"BackFin_L","Torso","chrome",-2.1,9.6,-2.7,0,0,18,0.25,1.7,1.2},
 {"ShoulderJoint_R","UpperArm_R","dark",4.25,9.9,-0.3,0,0,0,0.95,0.95,0.95},
 {"ShoulderJoint_L","UpperArm_L","dark",-4.25,9.9,-0.3,0,0,0,0.95,0.95,0.95},
 {"Pauldron_R","UpperArm_R","chrome",5.8,10.95,-0.3,0,0,6,2.8,0.45,3.5},
 {"Pauldron_L","UpperArm_L","chrome",-5.8,10.95,-0.3,0,0,-6,2.8,0.45,3.5},
 {"PauldronTrim_R","UpperArm_R","neon",5.8,10.86,1.48,0,0,6,2.5,0.16,0.12},
 {"PauldronTrim_L","UpperArm_L","neon",-5.8,10.86,1.48,0,0,-6,2.5,0.16,0.12},
 {"FanHub_R","UpperArm_R","gun",5.95,11.36,-0.6,0,0,0,0.55,0.28,0.55},
 {"FanHub_L","UpperArm_L","gun",-5.95,11.36,-0.6,0,0,0,0.55,0.28,0.55},
 {"FanBladeA_R","UpperArm_R","steel",5.95,11.4,-0.6,0,0,0,1.7,0.1,0.32},
 {"FanBladeA_L","UpperArm_L","steel",-5.95,11.4,-0.6,0,0,0,1.7,0.1,0.32},
 {"FanBladeB_R","UpperArm_R","steel",5.95,11.4,-0.6,0,0,0,0.32,0.15,1.7},
 {"FanBladeB_L","UpperArm_L","steel",-5.95,11.4,-0.6,0,0,0,0.32,0.15,1.7},
 {"FanCore_R","UpperArm_R","neon",5.95,11.47,-0.6,0,0,0,0.24,0.16,0.24},
 {"FanCore_L","UpperArm_L","neon",-5.95,11.47,-0.6,0,0,0,0.24,0.16,0.24},
 {"UpperPlate_R","UpperArm_R","chrome",6.42,8.2,-0.3,0,4,0,0.3,2.1,1.9},
 {"UpperPlate_L","UpperArm_L","chrome",-6.42,8.2,-0.3,0,-4,0,0.3,2.1,1.9},
 {"UpperPlateLine_R","UpperArm_R","neon",6.6,8.2,-0.3,0,4,0,0.08,1.6,0.26},
 {"UpperPlateLine_L","UpperArm_L","neon",-6.6,8.2,-0.3,0,-4,0,0.08,1.6,0.26},
 {"UpperFront_R","UpperArm_R","gun",5.38,8.3,0.86,0,4,0,1.6,1.9,0.3},
 {"UpperFront_L","UpperArm_L","gun",-5.38,8.3,0.86,0,-4,0,1.6,1.9,0.3},
 {"ArmCable_R","UpperArm_R","steel",4.42,8.1,-1.1,0,0,10,0.26,1.9,0.26},
 {"ArmCable_L","UpperArm_L","steel",-4.42,8.1,-1.1,0,0,-10,0.26,1.9,0.26},
 {"ElbowLight_R","Forearm_R","neon",5.5,6.9,1.06,0,0,0,0.7,0.3,0.12},
 {"ElbowLight_L","Forearm_L","neon",-5.5,6.9,1.06,0,0,0,0.7,0.3,0.12},
 {"ForearmStripe_R","Forearm_R","neon",5.7,5.6,1.42,0,-6,0,0.32,1.6,0.12},
 {"ForearmStripe_L","Forearm_L","neon",-5.7,5.6,1.42,0,6,0,0.32,1.6,0.12},
 {"ForearmPanel_R","Forearm_R","steel",6.92,5.6,-0.15,0,-6,0,0.12,1.7,2.2},
 {"ForearmPanel_L","Forearm_L","steel",-6.92,5.6,-0.15,0,6,0,0.12,1.7,2.2},
 {"ForearmVent1_R","Forearm_R","dark",5.5,5.1,-1.43,0,-6,0,1.8,0.16,0.12},
 {"ForearmVent1_L","Forearm_L","dark",-5.5,5.1,-1.43,0,6,0,1.8,0.16,0.12},
 {"ForearmVent2_R","Forearm_R","dark",5.5,5.55,-1.43,0,-6,0,1.8,0.16,0.12},
 {"ForearmVent2_L","Forearm_L","dark",-5.5,5.55,-1.43,0,6,0,1.8,0.16,0.12},
 {"ForearmVent3_R","Forearm_R","dark",5.5,6,-1.43,0,-6,0,1.8,0.16,0.12},
 {"ForearmVent3_L","Forearm_L","dark",-5.5,6,-1.43,0,6,0,1.8,0.16,0.12},
 {"WristCuff_R","Forearm_R","gun",5.6,4.4,0.05,0,0,0,2.85,0.4,2.95},
 {"WristCuff_L","Forearm_L","gun",-5.6,4.4,0.05,0,0,0,2.85,0.4,2.95},
 {"Finger1_R","Forearm_R","steel",4.8206,3.15,1.9943,0,6.875,0,0.55,1.35,0.45},
 {"Finger1_L","Forearm_L","steel",-4.8206,3.15,1.9943,0,-6.875,0,0.55,1.35,0.45},
 {"FingerTip1_R","Forearm_R","neon",4.8505,2.6,2.2425,0,6.875,0,0.42,0.16,0.1},
 {"FingerTip1_L","Forearm_L","neon",-4.8505,2.6,2.2425,0,-6.875,0,0.42,0.16,0.1},
 {"Finger2_R","Forearm_R","steel",5.5156,3.15,1.9105,0,6.875,0,0.55,1.35,0.45},
 {"Finger2_L","Forearm_L","steel",-5.5156,3.15,1.9105,0,-6.875,0,0.55,1.35,0.45},
 {"FingerTip2_R","Forearm_R","neon",5.5455,2.6,2.1587,0,6.875,0,0.42,0.16,0.1},
 {"FingerTip2_L","Forearm_L","neon",-5.5455,2.6,2.1587,0,-6.875,0,0.42,0.16,0.1},
 {"Finger3_R","Forearm_R","steel",6.2106,3.15,1.8267,0,6.875,0,0.55,1.35,0.45},
 {"Finger3_L","Forearm_L","steel",-6.2106,3.15,1.8267,0,-6.875,0,0.55,1.35,0.45},
 {"FingerTip3_R","Forearm_R","neon",6.2405,2.6,2.0749,0,6.875,0,0.42,0.16,0.1},
 {"FingerTip3_L","Forearm_L","neon",-6.2405,2.6,2.0749,0,-6.875,0,0.42,0.16,0.1},
 {"Finger4_R","Forearm_R","steel",6.9055,3.15,1.7429,0,6.875,0,0.55,1.35,0.45},
 {"Finger4_L","Forearm_L","steel",-6.9055,3.15,1.7429,0,-6.875,0,0.55,1.35,0.45},
 {"FingerTip4_R","Forearm_R","neon",6.9354,2.6,1.9911,0,6.875,0,0.42,0.16,0.1},
 {"FingerTip4_L","Forearm_L","neon",-6.9354,2.6,1.9911,0,-6.875,0,0.42,0.16,0.1},
 {"Thumb_R","Forearm_R","steel",4.0381,3.5,1.1015,0,6.875,0,0.45,1,0.6},
 {"Thumb_L","Forearm_L","steel",-4.0381,3.5,1.1015,0,-6.875,0,0.45,1,0.6},
 {"Handle","Forearm_L","dark",-5.65,3.5701,1.4896,83.02,0,0,0.6,5.6,0.6,"Pickaxe"},
 {"Cell1","Forearm_L","neon",-5.65,3.4851,0.7948,83.02,0,0,0.74,0.42,0.74,"Pickaxe"},
 {"Cell2","Forearm_L","neon",-5.65,3.6309,1.9859,83.02,0,0,0.74,0.42,0.74,"Pickaxe"},
 {"Cell3","Forearm_L","neon",-5.65,3.7767,3.177,83.02,0,0,0.74,0.42,0.74,"Pickaxe"},
 {"Grip","Forearm_L","steel",-5.65,3.3453,-0.3467,83.02,0,0,0.86,1.7,0.86,"Pickaxe"},
 {"Pommel","Forearm_L","chrome",-5.65,3.2116,-1.4385,83.02,0,0,0.98,0.5,0.98,"Pickaxe"},
 {"PommelGem","Forearm_L","red",-5.65,3.1691,-1.7859,83.02,45,0,0.46,0.3,0.46,"Pickaxe"},
 {"Collar","Forearm_L","chrome",-5.65,3.9408,4.517,83.02,0,0,0.92,0.42,0.92,"Pickaxe"},
 {"Halo1","Forearm_L","holo",-5.65,4.0441,5.3607,83.02,0,0,1.9,0.08,0.12,"Pickaxe"},
 {"Halo2","Forearm_L","holo",-5.65,4.0441,5.3607,83.02,0,0,0.12,0.13,1.9,"Pickaxe"},
 {"Head","Forearm_L","gun",-5.65,4.36,7.9415,83.02,0,0,1.25,1.35,1.6,"Pickaxe"},
 {"HeadCore","Forearm_L","neon",-5.65,4.36,7.9415,83.02,0,0,1.31,0.42,1,"Pickaxe"},
 {"Gear","Forearm_L","steel",-6.43,4.36,7.9415,83.02,0,0,0.16,1.35,1.35,"Pickaxe"},
 {"Gear2","Forearm_L","steel",-6.43,4.36,7.9415,128.02,0,0,0.1,1.35,1.35,"Pickaxe"},
 {"GearHub","Forearm_L","neon",-6.53,4.36,7.9415,83.02,0,0,0.12,0.48,0.48,"Pickaxe"},
 {"Pick1","Forearm_L","chrome",-5.65,3.112,7.8712,93.224,0,0,0.38,1.15,1.3,"Pickaxe"},
 {"Pick2","Forearm_L","chrome",-5.65,1.9638,7.8065,93.224,0,0,0.3,0.95,1.2,"Pickaxe"},
 {"Pick3","Forearm_L","chrome",-5.65,0.9155,7.7474,93.224,0,0,0.24,0.75,1,"Pickaxe"},
 {"Pick4","Forearm_L","neon",-5.65,0.0169,7.6968,93.224,0,0,0.3,0.42,0.85,"Pickaxe"},
 {"PickEdge1","Forearm_L","neon",-5.65,2.6945,7.2956,93.224,0,0,0.47,0.14,1.5,"Pickaxe"},
 {"PickEdge2","Forearm_L","neon",-5.65,1.4099,7.3317,93.224,0,0,0.36,0.12,1.1,"Pickaxe"},
 {"Spike1","Forearm_L","chrome",-5.65,5.4969,8.1147,-81.3378,0,-180,0.42,0.9,1,"Pickaxe"},
 {"Spike2","Forearm_L","chrome",-5.65,6.2384,8.2276,-81.3378,0,-180,0.3,0.6,0.8,"Pickaxe"},
 {"SpikeTip","Forearm_L","neon",-5.65,6.8315,8.318,-81.3378,0,-180,0.2,0.3,0.5,"Pickaxe"},
 {"SwordGrip","Forearm_L","dark",-5.65,3.4243,0.2985,83.02,0,0,0.7,3.4,0.7,"Sword"},
 {"SwordPommel","Forearm_L","chrome",-5.65,3.1934,-1.5874,83.02,0,0,0.95,0.5,0.95,"Sword"},
 {"SwordGuard","Forearm_L","chrome",-5.65,3.6491,2.1348,83.02,0,0,2,0.4,0.55,"Sword"},
 {"SwordBlade","Forearm_L","neon",-5.65,4.0805,5.6585,83.02,0,0,0.26,6.7,0.75,"Sword"},
 {"SwordTip","Forearm_L","neon",-5.65,4.5059,9.1326,128.02,0,0,0.16,0.55,0.55,"Sword"},
}
local rad = math.rad
for _, r in RAW do
	table.insert(D.blocks, { name = r[1], group = r[13], bone = r[2], col = r[3], cf = CFrame.new(r[4], r[5], r[6]) * CFrame.Angles(rad(r[7]), rad(r[8]), rad(r[9])), s = Vector3.new(r[10], r[11], r[12]) })
end
return D
