import numpy as np, math, os
def Rx(a): c,s=math.cos(a),math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c,s=math.cos(a),math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c,s=math.cos(a),math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def ang(x,y,z): return Rx(x)@Ry(y)@Rz(z)
r=math.radians
JR={'RootJoint':ang(-math.pi/2,0,math.pi),'Neck':ang(-math.pi/2,0,math.pi),'RS':Ry(math.pi/2),'LS':Ry(-math.pi/2),'RH':Ry(math.pi/2),'LH':Ry(-math.pi/2)}
POSE={'RootJoint':'Torso','Neck':'Head','RS':'Right Arm','LS':'Left Arm','RH':'Right Leg','LH':'Left Leg'}
def A(x=0,y=0,z=0,ox=0,oy=0,oz=0): return (ang(r(x),r(y),r(z)),np.array([ox,oy,oz]))
def K(t, **j):
    d=dict(RootJoint=A(),Neck=A(),RS=A(),LS=A(),RH=A(),LH=A()); d.update(j); return (t,d)

SETS={}
# ---------------- POLAR EXPLORER: fast, hunched forward, ice axe ----------------
SETS['Explorer']={
 'Idle':(True,0,[  # shivers, stamps the feet, rubs the free arm
  K(0,   RootJoint=A(-10,0,0),Neck=A(-6,0,0),RS=A(30,0,-6),LS=A(40,0,30),RH=A(2,0,-3),LH=A(-2,0,3)),
  K(0.12,RootJoint=A(-10,0,2),Neck=A(-6,0,3),RS=A(31,0,-6),LS=A(44,0,34)),
  K(0.24,RootJoint=A(-10,0,-2),Neck=A(-6,0,-3),RS=A(29,0,-6),LS=A(38,0,28)),
  K(0.36,RootJoint=A(-10,0,2),Neck=A(-6,0,3),RS=A(31,0,-6),LS=A(44,0,34)),
  K(0.9, RootJoint=A(-12,0,0,0,-0.05,0),Neck=A(-14,20,0),RS=A(30,0,-6),LS=A(40,0,30),RH=A(10),LH=A(-2)),
  K(1.3, RootJoint=A(-12,0,0,0,-0.05,0),Neck=A(-14,-20,0),RS=A(30,0,-6),LS=A(40,0,30),RH=A(-2),LH=A(10)),
  K(1.8, RootJoint=A(-10,0,0),Neck=A(-6,0,0),RS=A(30,0,-6),LS=A(40,0,30),RH=A(2,0,-3),LH=A(-2,0,3))]),
 'Walk':(True,1,[  # fast lean-forward run, arms pumping
  K(0,   RootJoint=A(-24,6,4),Neck=A(10,-6,-4),RS=A(50,0,-6),LS=A(-40,0,8),RH=A(-36),LH=A(40)),
  K(0.18,RootJoint=A(-26,0,0,0,-0.35,0),Neck=A(12),RS=A(10,0,-6),LS=A(0,0,8),RH=A(0),LH=A(10)),
  K(0.36,RootJoint=A(-24,-6,-4),Neck=A(10,6,4),RS=A(-40,0,-8),LS=A(50,0,6),RH=A(40),LH=A(-36)),
  K(0.54,RootJoint=A(-26,0,0,0,-0.35,0),Neck=A(12),RS=A(0,0,-8),LS=A(10,0,6),RH=A(10),LH=A(0)),
  K(0.72,RootJoint=A(-24,6,4),Neck=A(10,-6,-4),RS=A(50,0,-6),LS=A(-40,0,8),RH=A(-36),LH=A(40))]),
 'Attack':(False,3,[  # two quick swipes with the ice axe
  K(0,   RootJoint=A(-10),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,30)),
  K(0.16,RootJoint=A(-4,-20,0),Neck=A(-4,16,0),RS=A(150,0,-30),LS=A(30,0,30)),
  K(0.26,RootJoint=A(-20,20,0,0,-0.1,-0.2),Neck=A(-12,-14,0),RS=A(40,0,20),LS=A(20,0,30),RH=A(10),LH=A(-8)),
  K(0.4, RootJoint=A(-4,-24,0),Neck=A(-4,18,0),RS=A(160,0,-20),LS=A(30,0,30)),
  K(0.5, RootJoint=A(-24,22,0,0,-0.15,-0.3),Neck=A(-14,-16,0),RS=A(30,0,24),LS=A(16,0,30),RH=A(14),LH=A(-10)),
  K(0.75,RootJoint=A(-10),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,30))]),
 'Death':(False,3,[  # drops to the knees, freezes, tips over
  K(0,   RootJoint=A(-10),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,30)),
  K(0.35,RootJoint=A(-6,0,0,0,-1.5,0),Neck=A(20),RS=A(60,0,-20),LS=A(70,0,30),RH=A(95),LH=A(90)),
  K(0.8, RootJoint=A(-4,0,0,0,-1.5,0),Neck=A(24),RS=A(62,0,-20),LS=A(72,0,30),RH=A(95),LH=A(90)),
  K(1.1, RootJoint=A(-4,0,-80,-1.4,-2.2,0),Neck=A(24),RS=A(62,0,-20),LS=A(72,0,30),RH=A(95),LH=A(90))]),
}
# ---------------- RADIO OPERATOR: stiff, talks into the mic, throws ice chunks ----------------
SETS['Operator']={
 'Idle':(True,0,[  # hand to the headset, listens, looks around
  K(0,   RootJoint=A(-6),Neck=A(-4,0,10),RS=A(30,0,-8),LS=A(150,30,40),RH=A(0,0,-3),LH=A(0,0,3)),
  K(0.8, RootJoint=A(-6),Neck=A(-8,20,14),RS=A(34,0,-8),LS=A(152,30,42)),
  K(1.6, RootJoint=A(-6),Neck=A(0,-20,8),RS=A(26,0,-8),LS=A(148,30,38)),
  K(2.4, RootJoint=A(-6),Neck=A(-4,0,10),RS=A(30,0,-8),LS=A(150,30,40),RH=A(0,0,-3),LH=A(0,0,3))]),
 'Walk':(True,1,[  # stiff zombie march, ice chunk held
  K(0,   RootJoint=A(-8,8,0),Neck=A(-4,-8,0),RS=A(40,0,-8),LS=A(-24,0,10),RH=A(28),LH=A(-24)),
  K(0.3, RootJoint=A(-10,0,0,0,-0.25,0),Neck=A(-6),RS=A(30,0,-8),LS=A(0,0,10),RH=A(6),LH=A(4)),
  K(0.6, RootJoint=A(-8,-8,0),Neck=A(-4,8,0),RS=A(20,0,-8),LS=A(24,0,10),RH=A(-24),LH=A(28)),
  K(0.9, RootJoint=A(-10,0,0,0,-0.25,0),Neck=A(-6),RS=A(30,0,-8),LS=A(0,0,10),RH=A(4),LH=A(6)),
  K(1.2, RootJoint=A(-8,8,0),Neck=A(-4,-8,0),RS=A(40,0,-8),LS=A(-24,0,10),RH=A(28),LH=A(-24))]),
 'Throw':(False,4,[  # big overhead wind-up, hurls the chunk
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-8),LS=A(20,0,14)),
  K(0.45,RootJoint=A(14,-24,0,0,0,0.25),Neck=A(-8,24,0),RS=A(190,-10,-20),LS=A(90,10,10),RH=A(-14),LH=A(20)),
  K(0.6, RootJoint=A(-26,24,0,0,-0.2,-0.5),Neck=A(-12,-20,0),RS=A(100,0,6),LS=A(-6,0,24),RH=A(22),LH=A(-20)),
  K(0.8, RootJoint=A(-18,18,0,0,-0.15,-0.4),Neck=A(-8,-14,0),RS=A(50,0,6),LS=A(4,0,22),RH=A(16),LH=A(-14)),
  K(1.05,RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-8),LS=A(20,0,14))]),
 'Attack':(False,3,[  # clubs with the radio sideways
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-8),LS=A(20,0,14)),
  K(0.28,RootJoint=A(0,-30,0),Neck=A(0,24,0),RS=A(100,0,-70),LS=A(20,0,30),RH=A(-6),LH=A(8)),
  K(0.4, RootJoint=A(-14,34,0,0,-0.1,-0.2),Neck=A(-8,-18,0),RS=A(80,0,45),LS=A(14,0,36),RH=A(12),LH=A(-10)),
  K(0.6, RootJoint=A(-10,20,0),Neck=A(-6),RS=A(60,0,30),LS=A(16,0,20)),
  K(0.8, RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-8),LS=A(20,0,14))]),
 'Death':(False,3,[  # sparks: twitches, falls on the back
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-8),LS=A(20,0,14)),
  K(0.15,RootJoint=A(4,0,8),Neck=A(14,0,20),RS=A(80,0,-40),LS=A(80,0,40)),
  K(0.3, RootJoint=A(-4,0,-8),Neck=A(-10,0,-20),RS=A(40,0,-60),LS=A(40,0,60)),
  K(0.45,RootJoint=A(4,0,8),Neck=A(14,0,20),RS=A(80,0,-40),LS=A(80,0,40)),
  K(0.95,RootJoint=A(84,0,4,0,-2.3,1.6),Neck=A(-20,0,10),RS=A(170,0,-50),LS=A(160,0,50),RH=A(-20),LH=A(-10)),
  K(1.15,RootJoint=A(82,0,4,0,-2.25,1.6),Neck=A(-18,0,12),RS=A(168,0,-52),LS=A(158,0,52),RH=A(-18),LH=A(-8))]),
}
# ---------------- ICE BRUTE: huge, slow, heavy arms ----------------
SETS['Brute']={
 'Idle':(True,0,[  # heavy breathing, knuckles low, rolls the shoulders
  K(0,   RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10),RH=A(4,0,-6),LH=A(-4,0,6)),
  K(1.0, RootJoint=A(-18,0,0,0,-0.18,0),Neck=A(6),RS=A(18,0,-16),LS=A(18,0,16),RH=A(6,0,-6),LH=A(-2,0,6)),
  K(2.0, RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10),RH=A(4,0,-6),LH=A(-4,0,6))]),
 'Walk':(True,1,[  # gorilla stomp, arms swing wide
  K(0,   RootJoint=A(-18,10,8),Neck=A(-2,-10,-8),RS=A(30,0,-14),LS=A(-10,0,14),RH=A(26,0,-6),LH=A(-22,0,6)),
  K(0.35,RootJoint=A(-20,4,4,0,-0.4,0),Neck=A(-4,-4,-4),RS=A(20,0,-14),LS=A(4,0,14),RH=A(6,0,-6),LH=A(-6,0,6)),
  K(0.75,RootJoint=A(-18,-10,-8),Neck=A(-2,10,8),RS=A(-10,0,-14),LS=A(30,0,14),RH=A(-22,0,-6),LH=A(26,0,6)),
  K(1.1, RootJoint=A(-20,-4,-4,0,-0.4,0),Neck=A(-4,4,4),RS=A(4,0,-14),LS=A(20,0,14),RH=A(-6,0,-6),LH=A(6,0,6)),
  K(1.5, RootJoint=A(-18,10,8),Neck=A(-2,-10,-8),RS=A(30,0,-14),LS=A(-10,0,14),RH=A(26,0,-6),LH=A(-22,0,6))]),
 'Slam':(False,4,[  # both fists high over the head, then into the ground
  K(0,   RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10)),
  K(0.5, RootJoint=A(14,0,0,0,0.3,0.2),Neck=A(24),RS=A(185,0,-10),LS=A(185,0,10),RH=A(-10),LH=A(-10)),
  K(0.62,RootJoint=A(-48,0,0,0,-1.0,-0.6),Neck=A(-24),RS=A(60,0,-10),LS=A(60,0,10),RH=A(40),LH=A(40)),
  K(0.95,RootJoint=A(-44,0,0,0,-0.95,-0.55),Neck=A(-20),RS=A(56,0,-10),LS=A(56,0,10),RH=A(38),LH=A(38)),
  K(1.3, RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10))]),
 'Attack':(False,3,[  # close: big hook punch
  K(0,   RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10)),
  K(0.3, RootJoint=A(-6,-34,0),Neck=A(0,26,0),RS=A(80,0,-60),LS=A(20,0,20),RH=A(-6),LH=A(8)),
  K(0.42,RootJoint=A(-22,30,0,0,-0.2,-0.3),Neck=A(-10,-20,0),RS=A(90,0,40),LS=A(10,0,26),RH=A(14),LH=A(-12)),
  K(0.65,RootJoint=A(-18,20,0),Neck=A(-6,-10,0),RS=A(70,0,30),LS=A(10,0,20)),
  K(0.9, RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10))]),
 'Death':(False,3,[  # roars to the sky, falls forward on the face
  K(0,   RootJoint=A(-14),Neck=A(-4),RS=A(12,0,-10),LS=A(12,0,10)),
  K(0.4, RootJoint=A(10),Neck=A(40),RS=A(120,0,-40),LS=A(120,0,40),RH=A(-6),LH=A(6)),
  K(0.7, RootJoint=A(-10,0,0,0,-1.4,0),Neck=A(20),RS=A(40,0,-20),LS=A(40,0,20),RH=A(90),LH=A(90)),
  K(1.05,RootJoint=A(-88,0,0,0,-2.6,-1.5),Neck=A(26,0,20),RS=A(160,0,-30),LS=A(160,0,30),RH=A(20),LH=A(16)),
  K(1.25,RootJoint=A(-86,0,0,0,-2.55,-1.5),Neck=A(24,0,22),RS=A(158,0,-32),LS=A(158,0,32),RH=A(18),LH=A(14))]),
}
def T(j,R):
    Rm,o=R; J=JR[j]
    return J.T@Rm@J, J.T@o
def cf(name,m,p):
    return (f'<CoordinateFrame name="{name}"><X>{p[0]:.5f}</X><Y>{p[1]:.5f}</Y><Z>{p[2]:.5f}</Z>'
     f'<R00>{m[0,0]:.6f}</R00><R01>{m[0,1]:.6f}</R01><R02>{m[0,2]:.6f}</R02><R10>{m[1,0]:.6f}</R10><R11>{m[1,1]:.6f}</R11><R12>{m[1,2]:.6f}</R12>'
     f'<R20>{m[2,0]:.6f}</R20><R21>{m[2,1]:.6f}</R21><R22>{m[2,2]:.6f}</R22></CoordinateFrame>')
I=np.eye(3);Z=np.zeros(3)
def pose(name,m,p,w,children=""):
    return (f'<Item class="Pose"><Properties><string name="Name">{name}</string>{cf("CFrame",m,p)}'
            f'<token name="EasingDirection">2</token><token name="EasingStyle">0</token><float name="Weight">{w}</float></Properties>{children}</Item>')
out=os.environ.get('OUT','/home/claude/mobs4/out'); os.makedirs(out,exist_ok=True)
for setname,anims in SETS.items():
  for name,(loop,prio,keys) in anims.items():
    ks=""
    for t,joints in keys:
        limbs="".join(pose(POSE[j],*T(j,joints[j]),1) for j in ['Neck','RS','LS','RH','LH'])
        torso=pose('Torso',*T('RootJoint',joints['RootJoint']),1,limbs)
        root=pose('HumanoidRootPart',I,Z,0,torso)
        ks+=f'<Item class="Keyframe"><Properties><string name="Name">Keyframe</string><float name="Time">{t}</float></Properties>{root}</Item>'
    xml=(f'<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4">'
         f'<Item class="KeyframeSequence"><Properties><string name="Name">Zombie{setname}_{name}</string><bool name="Loop">{"true" if loop else "false"}</bool>'
         f'<token name="Priority">{prio}</token></Properties>{ks}</Item></roblox>')
    open(f'{out}/z4_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
