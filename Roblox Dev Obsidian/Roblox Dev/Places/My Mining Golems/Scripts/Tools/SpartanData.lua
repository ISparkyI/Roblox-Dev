-- Spartan Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано mkx/gen.py (05.11.2026).
-- Ексклюзив Marketplace. Анімації — GolemAnimator v4 (NicheTools/GolemAnimatorV4): fx spin/sway/bob/pulse/hue/blink, власні пози Idle/Walk/Run/Mine/Carry/Pick.
-- Блоки — компактно в RAW: { ім'я, кістка, колір, x, y, z, rx, ry, rz (градуси, CFrame.Angles), sx, sy, sz, група? } → D.blocks (формат Clay / Astral).
local D = {
 colors={marble="#e3dccf",marble2="#c8bfb1",bronze="#c88f3a",bronze2="#e8bd62",bronzeD="#8a5d21",red="#b51f2b",red2="#7a1420",leather="#6a4426",leather2="#3f2716",dark="#1c1816",gold="#ffd36a",light="#f4f2ea",wood="#7a5232",pink="#f2a0b4"},
 neon={gold=true},
 hue={"#ffd36a","#fff3c4","#ffb23a","#fff3c4"},
 hueSpeed=2.2,hueWave=0.05,
 poses={
  -- спокій: стійка фаланги — щит перед грудьми, спис вертикально, дихає
  Idle=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = rot(0.03 * s, -0.08, 0) }
   pose.Head = { r = rot(-0.02 * s, 0.1 * math.sin(p * 0.5), 0) }
   pose.UpperArm_R = { r = rot(-0.95, 0.25, 0.1) }
   pose.Forearm_R = { r = rot(-0.85, 0, 0) }
   pose.UpperArm_L = { r = rot(-0.2, 0, -0.18) }
   pose.Forearm_L = { r = rot(-1.45 + 0.03 * s, 0, 0) }
   pose.Thigh_R = { r = rot(-0.12, 0, 0.05) }
   pose.Thigh_L = { r = rot(0.12, 0, -0.05) }
   return pose
  end,
  -- марш: високе коліно, щит і спис нерухомі (строй)
  Walk=function(p, pose, rot)
   local s, c = math.sin(p), math.cos(p)
   pose.Thigh_R = { r = rot(-0.7 * math.max(0, s) + 0.25 * math.max(0, -s), 0, 0) }
   pose.Thigh_L = { r = rot(-0.7 * math.max(0, -s) + 0.25 * math.max(0, s), 0, 0) }
   pose.Shin_R = { r = rot(1.1 * math.max(0, s), 0, 0) }
   pose.Shin_L = { r = rot(1.1 * math.max(0, -s), 0, 0) }
   pose.Torso = { r = rot(0.04, -0.08, 0) }
   pose.Head = { r = rot(-0.04, 0, 0.03 * s) }
   pose.UpperArm_R = { r = rot(-0.95, 0.25, 0.1) }
   pose.Forearm_R = { r = rot(-0.85, 0, 0) }
   pose.UpperArm_L = { r = rot(-0.2, 0, -0.18) }
   pose.Forearm_L = { r = rot(-1.45, 0, 0) }
   return pose
  end,
  -- атака бігом: корпус уперед, спис опущений вістрям уперед, щит виставлений
  Run=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = rot(0.38, 0.12, 0) }
   pose.Head = { r = rot(-0.28, 0, 0) }
   pose.UpperArm_R = { r = rot(-1.05, 0.3, 0.12) }
   pose.Forearm_R = { r = rot(-0.6, 0, 0) }
   pose.UpperArm_L = { r = rot(-0.5 + 0.05 * s, 0, -0.1) }
   pose.Forearm_L = { r = rot(-0.12, 0, 0) }
   return pose
  end,
  -- удар списом (v3): спис перехоплюється вздовж руки (pose.Grip, аніматор v4.1), рука відводиться назад до плеча,
  -- різкий ривок — рука повністю випрямляється вперед разом із випадом корпусу й лівої ноги (удар — 0,62 с, як у всіх),
  -- коротка фіксація й плавне повернення в стійку. Спис горизонтальний: напрям передпліччя T + U + F ≈ −1,57.
  Mine=function(p, pose, rot)
   local t = p / (2 * math.pi) * 1.4
   local K = {
    { 0.00, { 0, 0, 0 }, { 0.05, 0.03, 0 }, { -0.3, 0, -0.08 }, { -1.32, 0, 0 }, { -0.1, 0, 0 }, { 0.1, 0, 0 } },
    { 0.42, { 0, -0.15, -1.0 }, { -0.1, 0.12, 0 }, { 0.4, 0, -0.1 }, { -1.87, 0, 0 }, { 0.15, 0, 0 }, { -0.15, 0, 0 } },
    { 0.62, { 0, -0.45, 3.0 }, { 0.2, -0.05, 0 }, { -1.6, 0, -0.04 }, { -0.12, 0, 0 }, { -0.85, 0, 0 }, { 0.5, 0, 0 } },
    { 0.86, { 0, -0.4, 2.8 }, { 0.18, -0.04, 0 }, { -1.55, 0, -0.04 }, { -0.15, 0, 0 }, { -0.8, 0, 0 }, { 0.48, 0, 0 } },
    { 1.40, { 0, 0, 0 }, { 0.05, 0.03, 0 }, { -0.3, 0, -0.08 }, { -1.32, 0, 0 }, { -0.1, 0, 0 }, { 0.1, 0, 0 } },
   }
   local i = 1
   while i < #K - 1 and t >= K[i + 1][1] do i += 1 end
   local a, b = K[i], K[i + 1]
   local x = math.clamp((t - a[1]) / (b[1] - a[1]), 0, 1)
   -- відведення — плавно; ривок — різкий старт і гальмування (ease-out³); фіксація й повернення — плавно
   if i == 2 then x = 1 - (1 - x) ^ 3 else x = x * x * (3 - 2 * x) end
   local function L(j) local u, v = a[j], b[j] return u[1] + (v[1] - u[1]) * x, u[2] + (v[2] - u[2]) * x, u[3] + (v[3] - u[3]) * x end
   local hx, hy, hz = L(2)
   local hp = pose.Hips or {}
   pose.Hips = { t = Vector3.new(hx, hy, hz), r = hp.r }
   pose.Torso = { r = rot(L(3)) }
   pose.UpperArm_L = { r = rot(L(4)) }
   pose.Forearm_L = { r = rot(L(5)) }
   pose.Thigh_L = { r = rot(L(6)) }
   pose.Shin_L = { r = rot(math.max(0, -select(1, L(6))) * 0.9, 0, 0) }
   pose.Thigh_R = { r = rot(L(7)) }
   pose.Shin_R = { r = rot(math.max(0, select(1, L(7))) * 0.5, 0, 0) }
   pose.UpperArm_R = { r = rot(-0.95, 0.25, 0.1) }
   pose.Forearm_R = { r = rot(-0.85, 0, 0) }
   pose.Head = { r = rot(-0.1, 0, 0) }
   pose.Grip = { r = rot(1.69, 0, 0) } -- спис уздовж передпліччя (вістрям від кулака)
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
  {kind="hue",parts={"HelmGem","Emblem","CapeClasp_R","CapeClasp_L","LambdaA","LambdaB"},axis=Vector3.new(0.0,0.0,1.0),speed=2.2,amp=0.05},
  {kind="sway",parts={"CapeTop","CapeMid","CapeLow","CapeHem"},pivot=Vector3.new(0.0,10.2,-2.9),axis=Vector3.new(1.0,0.0,0.0),speed=2.2,amp=0.09,states={Run=2.6,Walk=1.6,Mine=1.8}},
  {kind="sway",parts={"CrestHolder","Crest1","CrestTip1","Crest2","CrestTip2","Crest3","CrestTip3","Crest4","CrestTip4","Crest5","CrestTip5","Crest6","CrestTip6","Crest7","CrestTip7","Crest8","CrestTip8","Crest9","CrestTip9"},pivot=Vector3.new(0.0,13.0,0.4),axis=Vector3.new(0.0,0.0,1.0),speed=2.4,amp=0.05,states={Run=2.2,Walk=1.5,Mine=2}},
  {kind="sway",parts={"Pteryx1","Pteryx1Tip","Pteryx2","Pteryx2Tip","Pteryx3","Pteryx3Tip","Pteryx4","Pteryx4Tip"},pivot=Vector3.new(0.0,5.1,1.5),axis=Vector3.new(1.0,0.0,0.0),speed=4.0,amp=0.1,states={Run=2,Walk=1.5,Idle=0.4}},
  {kind="sway",parts={"PteryxSide1_R","PteryxSide1_L","PteryxSide2_R","PteryxSide2_L"},pivot=Vector3.new(0.0,5.1,0.0),axis=Vector3.new(0.0,0.0,1.0),speed=4.0,amp=0.06,phase=1.0,states={Run=2,Walk=1.5,Idle=0.4}},
 },
 blocks={},
}
local RAW = {
 {"Foot_R","Shin_R","leather2",2.15,0.45,0.15,0,5,0,3,0.9,3.5},
 {"Foot_L","Shin_L","leather2",-2.15,0.45,0.15,0,-5,0,3,0.9,3.5},
 {"Shin_R","Shin_R","bronze",2.1,2,-0.2,0,4,0,2.4,2.2,2.4},
 {"Shin_L","Shin_L","bronze",-2.1,2,-0.2,0,-4,0,2.4,2.2,2.4},
 {"Thigh_R","Thigh_R","marble",2,3.85,-0.25,0,-6,0,2.45,1.6,2.45},
 {"Thigh_L","Thigh_L","marble",-2,3.85,-0.25,0,6,0,2.45,1.6,2.45},
 {"Pelvis","Hips","red",0,5,-0.35,0,0,0,5.8,1.2,3.4},
 {"Belt","Hips","bronze",0,5.4,-0.35,0,0,0,6,0.45,3.6},
 {"Torso","Torso","bronze",0,7.4,-0.3,0,0,0,6.8,4,4},
 {"Chest","Torso","bronze",0,9.45,-0.4,0,0,0,7.8,1.8,4.6},
 {"Head","Head","marble",0,11.15,0.5014,0,0,0,3.8,2.7,3.4},
 {"Jaw","Head","marble",0,10,0.7,0,0,0,3.4,0.8,2.7},
 {"Shoulder_R","UpperArm_R","bronze",5.7,10.025,-0.3,0,0,4,2.2,1.35,3.2},
 {"Shoulder_L","UpperArm_L","bronze",-5.7,10.025,-0.3,0,0,-4,2.2,1.35,3.2},
 {"UpperArm_R","UpperArm_R","marble",5.35,8.15,-0.3,0,4,0,2,2.6,2.1},
 {"UpperArm_L","UpperArm_L","marble",-5.35,8.15,-0.3,0,-4,0,2,2.6,2.1},
 {"Forearm_R","Forearm_R","marble",5.55,5.55,0,0,-6,0,2.6,2.5,2.7},
 {"Forearm_L","Forearm_L","marble",-5.55,5.55,0,0,6,0,2.6,2.5,2.7},
 {"Fist_R","Forearm_R","marble2",5.65,3.4,0.1014,0,6.875,0,3.2,1.9,3.2},
 {"Fist_L","Forearm_L","marble2",-5.65,3.4,0.1014,0,-6.875,0,3.2,1.9,3.2},
 {"Knuckles_R","Forearm_R","marble",5.9928,3.7,1.6918,0,6.875,0,2.6,0.8,0.4},
 {"Knuckles_L","Forearm_L","marble",-5.9928,3.7,1.6918,0,-6.875,0,2.6,0.8,0.4},
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
 {"HelmTop","Head","bronze",0,12.72,0.45,0,0,0,4.15,0.6,3.85},
 {"HelmBack","Head","bronze",0,11.3,-1.38,0,0,0,4.09,2.7,0.45},
 {"HelmSide_R","Head","bronze",2,11.5,0.3,0,0,0,0.32,2.24,3.4},
 {"HelmSide_L","Head","bronze",-2,11.5,0.3,0,0,0,0.32,2.24,3.4},
 {"CheekGuard_R","Head","bronze",1.78,10.8,1.75,0,-12,0,0.5,1.8,1.2},
 {"CheekGuard_L","Head","bronze",-1.78,10.8,1.75,0,12,0,0.5,1.8,1.2},
 {"HelmBrow","Head","bronze2",0,12.6,2.2,0,0,0,4.05,0.26,0.5},
 {"NoseGuard","Head","bronze",0,11.75,2.32,0,0,0,0.42,1.25,0.2},
 {"HelmGem","Head","gold",0,12.62,2.43,0,0,45,0.42,0.42,0.14},
 {"CrestHolder","Head","bronze2",0,13.12,0.4,0,0,0,0.55,0.4,3.3},
 {"Crest1","Head","red",0,13.4515,2.6008,78,0,0,0.62,0.95,0.95},
 {"CrestTip1","Head","red2",0,13.5554,3.0899,78,0,0,0.5,0.4,0.7},
 {"Crest2","Head","red",0,13.9076,2.3184,58.5,0,0,0.72,0.95,0.95},
 {"CrestTip2","Head","red2",0,14.1689,2.7448,58.5,0,0,0.4,0.4,0.7},
 {"Crest3","Head","red",0,14.2769,1.816,39,0,0,0.56,0.95,0.95},
 {"CrestTip3","Head","red2",0,14.6654,2.1306,39,0,0,0.5,0.4,0.7},
 {"Crest4","Head","red",0,14.5168,1.1511,19.5,0,0,0.72,0.95,0.95},
 {"CrestTip4","Head","red2",0,14.9882,1.318,19.5,0,0,0.4,0.4,0.7},
 {"Crest5","Head","red",0,14.6,0.4,0,0,0,0.62,0.95,0.95},
 {"CrestTip5","Head","red2",0,15.1,0.4,0,0,0,0.5,0.4,0.7},
 {"Crest6","Head","red",0,14.5168,-0.3511,-19.5,0,0,0.72,0.95,0.95},
 {"CrestTip6","Head","red2",0,14.9882,-0.518,-19.5,0,0,0.4,0.4,0.7},
 {"Crest7","Head","red",0,14.2769,-1.016,-39,0,0,0.62,0.95,0.95},
 {"CrestTip7","Head","red2",0,14.6654,-1.3306,-39,0,0,0.5,0.4,0.7},
 {"Crest8","Head","red",0,13.9076,-1.5184,-58.5,0,0,0.72,0.95,0.95},
 {"CrestTip8","Head","red2",0,14.1689,-1.9448,-58.5,0,0,0.4,0.4,0.7},
 {"Crest9","Head","red",0,13.4515,-1.8008,-78,0,0,0.56,0.95,0.95},
 {"CrestTip9","Head","red2",0,13.5554,-2.2899,-78,0,0,0.5,0.4,0.7},
 {"Pec_R","Torso","bronze2",1.3,9.05,1.95,0,0,-6,2.3,1.05,0.14},
 {"Pec_L","Torso","bronze2",-1.3,9.05,1.95,0,0,6,2.3,1.05,0.14},
 {"Ab1_R","Torso","bronze2",0.72,7.55,1.76,0,0,0,1.15,0.55,0.12},
 {"Ab1_L","Torso","bronze2",-0.72,7.55,1.76,0,0,0,1.15,0.55,0.12},
 {"Ab2_R","Torso","bronze2",0.72,6.85,1.76,0,0,0,1.15,0.55,0.12},
 {"Ab2_L","Torso","bronze2",-0.72,6.85,1.76,0,0,0,1.15,0.55,0.12},
 {"Ab3_R","Torso","bronze2",0.72,6.15,1.76,0,0,0,1.15,0.55,0.12},
 {"Ab3_L","Torso","bronze2",-0.72,6.15,1.76,0,0,0,1.15,0.55,0.12},
 {"CuirassRim","Torso","bronzeD",0,5.55,-0.3,0,0,0,7,0.2,4.2},
 {"Collar","Torso","bronzeD",0,10.45,-0.4,0,0,0,4.4,0.4,3.3},
 {"Emblem","Torso","gold",0,8.25,1.78,0,0,45,0.5,0.5,0.12},
 {"CapeClasp_R","Torso","gold",2.45,10.1,-2.78,0,0,45,0.6,0.6,0.2},
 {"CapeClasp_L","Torso","gold",-2.45,10.1,-2.78,0,0,-45,0.6,0.6,0.2},
 {"CapeTop","Torso","red",0,8.95,-2.95,0,0,0,6.4,2.5,0.25},
 {"CapeMid","Torso","red",0,6.6,-3.18,-6,0,0,6.8,2.4,0.25},
 {"CapeLow","Torso","red",0,4.25,-3.48,-9,0,0,7.1,2.4,0.25},
 {"CapeHem","Torso","red2",0,3.02,-3.66,-9,0,0,7.2,0.3,0.3},
 {"TunicHem","Hips","red",0,4.3,-0.35,0,0,0,5.6,0.9,3.25},
 {"Pteryx1","Hips","leather",-1.65,4.25,1.5,0,0,0,0.95,1.55,0.15},
 {"Pteryx1Tip","Hips","bronze2",-1.65,3.42,1.52,0,0,0,0.89,0.18,0.27},
 {"Pteryx2","Hips","leather",-0.55,4.25,1.5,0,0,0,0.95,1.55,0.15},
 {"Pteryx2Tip","Hips","bronze2",-0.55,3.42,1.52,0,0,0,0.89,0.18,0.27},
 {"Pteryx3","Hips","leather",0.55,4.25,1.5,0,0,0,0.95,1.55,0.15},
 {"Pteryx3Tip","Hips","bronze2",0.55,3.42,1.52,0,0,0,0.89,0.18,0.27},
 {"Pteryx4","Hips","leather",1.65,4.25,1.5,0,0,0,0.95,1.55,0.15},
 {"Pteryx4Tip","Hips","bronze2",1.65,3.42,1.52,0,0,0,0.89,0.18,0.27},
 {"PteryxSide1_R","Hips","leather",2.98,4.25,0.45,0,0,0,0.15,1.55,1.05},
 {"PteryxSide1_L","Hips","leather",-2.98,4.25,0.45,0,0,0,0.15,1.55,1.05},
 {"PteryxSide2_R","Hips","leather",2.98,4.25,-0.85,0,0,0,0.15,1.55,1.05},
 {"PteryxSide2_L","Hips","leather",-2.98,4.25,-0.85,0,0,0,0.15,1.55,1.05},
 {"BeltBoss","Hips","bronze2",0,5.4,1.5,0,0,0,0.9,0.6,0.12},
 {"Sandal_R","Shin_R","leather",2.15,0.95,0.15,0,5,0,2.4,0.18,2.6},
 {"Sandal_L","Shin_L","leather",-2.15,0.95,0.15,0,-5,0,2.4,0.18,2.6},
 {"SandalStrap_R","Shin_R","leather",2.15,0.5,1.2,0,5,0,2.9,0.16,0.25},
 {"SandalStrap_L","Shin_L","leather",-2.15,0.5,1.2,0,-5,0,2.9,0.16,0.25},
 {"Ankle_R","Shin_R","leather2",2.12,1.15,-0.1,0,0,0,1.75,0.65,1.75},
 {"Ankle_L","Shin_L","leather2",-2.12,1.15,-0.1,0,0,0,1.75,0.65,1.75},
 {"GreaveRidge_R","Shin_R","bronze2",2.18,2,1.08,0,4,0,0.3,1.2,0.12},
 {"GreaveRidge_L","Shin_L","bronze2",-2.18,2,1.08,0,-4,0,0.3,1.2,0.12},
 {"ElbowCap_R","Forearm_R","marble2",5.5,6.9,-0.15,0,0,0,2.3,0.85,2.35},
 {"ElbowCap_L","Forearm_L","marble2",-5.5,6.9,-0.15,0,0,0,2.3,0.85,2.35},
 {"KneeCap_R","Shin_R","marble2",2.1,3.12,-0.2,0,0,0,2.55,0.7,2.55},
 {"KneeCap_L","Shin_L","marble2",-2.1,3.12,-0.2,0,0,0,2.55,0.7,2.55},
 {"HipRing_R","Thigh_R","marble2",2,4.62,-0.25,0,0,0,2.6,0.34,2.6},
 {"HipRing_L","Thigh_L","marble2",-2,4.62,-0.25,0,0,0,2.6,0.34,2.6},
 {"KneeGuard_R","Shin_R","bronze2",2.1,3,0.3,0,0,0,1.85,1.1,2.2},
 {"KneeGuard_L","Shin_L","bronze2",-2.1,3,0.3,0,0,0,1.85,1.1,2.2},
 {"ShoulderJoint_R","UpperArm_R","marble2",4.25,9.9,-0.3,0,0,0,0.95,0.95,0.95},
 {"ShoulderJoint_L","UpperArm_L","marble2",-4.25,9.9,-0.3,0,0,0,0.95,0.95,0.95},
 {"Pauldron_R","UpperArm_R","bronze",5.85,10.95,-0.3,0,0,8,2.9,0.45,3.55},
 {"Pauldron_L","UpperArm_L","bronze",-5.85,10.95,-0.3,0,0,-8,2.9,0.45,3.55},
 {"Pauldron2_R","UpperArm_R","bronze2",6.15,10.4,-0.3,0,0,20,2.5,0.38,3.3},
 {"Pauldron2_L","UpperArm_L","bronze2",-6.15,10.4,-0.3,0,0,-20,2.5,0.38,3.3},
 {"Bicep_R","UpperArm_R","marble",5.38,8,0.93,0,4,0,1.5,1.3,0.45},
 {"Bicep_L","UpperArm_L","marble",-5.38,8,0.93,0,-4,0,1.5,1.3,0.45},
 {"ArmRing_R","UpperArm_R","bronze2",5.35,9,-0.3,0,4,0,2.25,0.3,2.35},
 {"ArmRing_L","UpperArm_L","bronze2",-5.35,9,-0.3,0,-4,0,2.25,0.3,2.35},
 {"Bracer_R","Forearm_R","leather",5.55,5.35,0,0,-6,0,2.85,1.9,2.95},
 {"Bracer_L","Forearm_L","leather",-5.55,5.35,0,0,6,0,2.85,1.9,2.95},
 {"BracerBand_R","Forearm_R","bronze2",5.55,6.35,0,0,-6,0,2.95,0.22,3.05},
 {"BracerBand_L","Forearm_L","bronze2",-5.55,6.35,0,0,6,0,2.95,0.22,3.05},
 {"BracerBand2_R","Forearm_R","bronze2",5.55,4.42,0,0,-6,0,2.95,0.16,3.05},
 {"BracerBand2_L","Forearm_L","bronze2",-5.55,4.42,0,0,6,0,2.95,0.16,3.05},
 {"BracerStud1_R","Forearm_R","bronze2",5.7,4.95,1.5,0,-6,45,0.3,0.3,0.12},
 {"BracerStud1_L","Forearm_L","bronze2",-5.7,4.95,1.5,0,6,-45,0.3,0.3,0.12},
 {"BracerStud2_R","Forearm_R","bronze2",5.7,5.35,1.5,0,-6,45,0.3,0.3,0.17},
 {"BracerStud2_L","Forearm_L","bronze2",-5.7,5.35,1.5,0,6,-45,0.3,0.3,0.17},
 {"BracerStud3_R","Forearm_R","bronze2",5.7,5.75,1.5,0,-6,45,0.3,0.3,0.11},
 {"BracerStud3_L","Forearm_L","bronze2",-5.7,5.75,1.5,0,6,-45,0.3,0.3,0.11},
 {"HandWrap_R","Forearm_R","leather",5.65,3.85,0.1014,0,6.875,0,3.3,0.22,3.3},
 {"HandWrap_L","Forearm_L","leather",-5.65,3.85,0.1014,0,-6.875,0,3.3,0.22,3.3},
 {"HandWrap2_R","Forearm_R","leather",5.65,3.05,0.1014,0,6.875,0,3.3,0.22,3.3},
 {"HandWrap2_L","Forearm_L","leather",-5.65,3.05,0.1014,0,-6.875,0,3.3,0.22,3.3},
 {"Shield","Forearm_R","bronze",7.25,5.4,0.3,0,0,0,0.36,4.4,4.4},
 {"Shield2","Forearm_R","bronze",7.25,5.4,0.3,45,0,0,0.3,4.4,4.4},
 {"ShieldRim","Forearm_R","bronze2",7.31,5.4,0.3,22.5,0,0,0.36,4.7,4.7},
 {"ShieldRim2","Forearm_R","bronze2",7.31,5.4,0.3,67.5,0,0,0.3,4.7,4.7},
 {"ShieldField","Forearm_R","red",7.47,5.4,0.3,22.5,0,0,0.12,3.4,3.4},
 {"ShieldField2","Forearm_R","red",7.47,5.4,0.3,67.5,0,0,0.18,3.4,3.4},
 {"LambdaA","Forearm_R","gold",7.55,5.4,-0.12,22,0,0,0.1,2.5,0.36},
 {"LambdaB","Forearm_R","gold",7.55,5.4,0.72,-22,0,0,0.18,2.5,0.36},
 {"ShieldBoss","Forearm_R","bronze2",7.58,6.95,0.3,45,0,0,0.2,0.4,0.4},
 {"SwordGrip","Forearm_L","leather",-5.65,3.4,0.1,83.02,0,0,0.55,1.6,0.55,"Sword"},
 {"Shaft","Forearm_L","wood",-5.65,3.7646,3.0778,83.02,0,0,0.42,13,0.42,"Sword"},
 {"ShaftBand1","Forearm_L","bronze",-5.65,3.5398,1.2415,83.02,0,0,0.56,0.3,0.56,"Sword"},
 {"ShaftBand2","Forearm_L","bronze",-5.65,3.2602,-1.0415,83.02,0,0,0.56,0.3,0.56,"Sword"},
 {"Socket","Forearm_L","bronze",-5.65,4.5848,9.7777,83.02,0,0,0.62,0.9,0.62,"Sword"},
 {"Blade1","Forearm_L","bronze2",-5.65,4.7064,10.7703,83.02,0,0,0.22,1.4,1.15,"Sword"},
 {"Blade2","Forearm_L","bronze2",-5.65,4.84,11.8622,83.02,0,0,0.14,1.2,0.8,"Sword"},
 {"SwordTip","Forearm_L","bronze2",-5.65,4.9494,12.7555,83.02,0,0,0.22,0.75,0.42,"Sword"},
 {"BladeEdge","Forearm_L","gold",-5.65,4.7975,11.5148,83.02,0,0,0.31,2.6,0.14,"Sword"},
 {"BladeEdgeTip","Forearm_L","gold",-5.65,4.9616,12.8548,83.02,0,0,0.16,0.5,0.26,"Sword"},
 {"Ribbon1","Forearm_L","red",-5.65,4.0835,9.3858,83.02,0,0,0.08,0.28,0.95,"Sword"},
 {"Ribbon2","Forearm_L","red2",-5.65,3.4636,9.2602,83.02,0,0,0.13,0.24,0.75,"Sword"},
 {"ButtSpike","Forearm_L","bronze",-5.65,2.9261,-3.7711,83.02,0,0,0.52,0.9,0.52,"Sword"},
 {"ButtTip","Forearm_L","bronze2",-5.65,2.8531,-4.3666,83.02,0,0,0.3,0.4,0.3,"Sword"},
 {"Handle","Forearm_L","wood",-5.65,3.5701,1.4896,83.02,0,0,0.6,5.8,0.6,"Pickaxe"},
 {"Head","Forearm_L","bronze",-5.65,4.36,7.9415,83.02,0,0,1,1,1.3,"Pickaxe"},
 {"Pick1","Forearm_L","bronze2",-5.65,3.1427,7.8729,93.224,0,0,0.34,0.9,1.2,"Pickaxe"},
 {"Pick2","Forearm_L","bronze2",-5.65,2.0268,7.81,93.224,0,0,0.28,0.75,1.1,"Pickaxe"},
 {"Pick3","Forearm_L","bronze2",-5.65,1.0123,7.7529,93.224,0,0,0.22,0.6,0.9,"Pickaxe"},
 {"Pick4","Forearm_L","bronze2",-5.65,0.2007,7.7072,93.224,0,0,0.2,0.4,0.7,"Pickaxe"},
}
local rad = math.rad
for _, r in RAW do
	table.insert(D.blocks, { name = r[1], group = r[13], bone = r[2], col = r[3], cf = CFrame.new(r[4], r[5], r[6]) * CFrame.Angles(rad(r[7]), rad(r[8]), rad(r[9])), s = Vector3.new(r[10], r[11], r[12]) })
end
return D
