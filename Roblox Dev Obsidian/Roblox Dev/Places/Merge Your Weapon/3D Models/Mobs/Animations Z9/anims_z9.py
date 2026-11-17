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
# ---------------- CHARRED: burnt, twitchy, smoulders; claws ----------------
SETS['Charred']={
 'Idle':(True,0,[  # hunched, flicks embers off the arm, jerky head twitches
  K(0,   RootJoint=A(-14),Neck=A(10,0,6),RS=A(14,0,-10),LS=A(18,0,12),RH=A(6,0,-4),LH=A(-2,0,4)),
  K(0.5, RootJoint=A(-16,0,0,0,-0.08,0),Neck=A(14,0,-10),RS=A(16,0,-10),LS=A(20,0,12)),
  K(0.6, RootJoint=A(-16,0,0,0,-0.08,0),Neck=A(4,20,10),RS=A(16,0,-10),LS=A(20,0,12)),
  K(1.1, RootJoint=A(-14),Neck=A(10,0,6),RS=A(60,0,30),LS=A(40,0,-20)),
  K(1.25,RootJoint=A(-14),Neck=A(10,0,6),RS=A(50,0,40),LS=A(40,0,-20)),
  K(1.4, RootJoint=A(-14),Neck=A(10,0,6),RS=A(60,0,30),LS=A(40,0,-20)),
  K(2.0, RootJoint=A(-14),Neck=A(10,0,6),RS=A(14,0,-10),LS=A(18,0,12),RH=A(6,0,-4),LH=A(-2,0,4))]),
 'Walk':(True,1,[  # staggering lurch, arms reaching forward
  K(0,   RootJoint=A(-18,8,8),Neck=A(8,-6,-8),RS=A(70,0,-6),LS=A(54,0,6),RH=A(30),LH=A(-20)),
  K(0.3, RootJoint=A(-20,0,0,0,-0.25,0),Neck=A(12,0,4),RS=A(64,0,-6),LS=A(62,0,6),RH=A(6),LH=A(4)),
  K(0.6, RootJoint=A(-18,-8,-8),Neck=A(8,6,8),RS=A(54,0,-6),LS=A(70,0,6),RH=A(-20),LH=A(30)),
  K(0.9, RootJoint=A(-20,0,0,0,-0.25,0),Neck=A(12,0,-4),RS=A(62,0,-6),LS=A(64,0,6),RH=A(4),LH=A(6)),
  K(1.2, RootJoint=A(-18,8,8),Neck=A(8,-6,-8),RS=A(70,0,-6),LS=A(54,0,6),RH=A(30),LH=A(-20))]),
 'Attack':(False,3,[  # double claw rake downward
  K(0,   RootJoint=A(-14),Neck=A(10),RS=A(14,0,-10),LS=A(18,0,12)),
  K(0.24,RootJoint=A(8,0,0,0,0,0.2),Neck=A(-10),RS=A(170,0,-30),LS=A(170,0,30),RH=A(-6),LH=A(6)),
  K(0.36,RootJoint=A(-30,0,0,0,-0.2,-0.4),Neck=A(14),RS=A(30,0,20),LS=A(30,0,-20),RH=A(16),LH=A(-12)),
  K(0.6, RootJoint=A(-22,0,0,0,-0.1,-0.3),Neck=A(12),RS=A(30,0,6),LS=A(30,0,-6)),
  K(0.85,RootJoint=A(-14),Neck=A(10),RS=A(14,0,-10),LS=A(18,0,12))]),
 'Death':(False,3,[  # flares up, crumbles to the knees, falls forward into ash
  K(0,   RootJoint=A(-14),Neck=A(10),RS=A(14,0,-10),LS=A(18,0,12)),
  K(0.3, RootJoint=A(10),Neck=A(-30),RS=A(120,0,-60),LS=A(120,0,60),RH=A(-6),LH=A(6)),
  K(0.65,RootJoint=A(-10,0,0,0,-1.5,0),Neck=A(20),RS=A(30,0,-30),LS=A(30,0,30),RH=A(95),LH=A(90)),
  K(1.0, RootJoint=A(-86,0,6,0,-2.6,-1.4),Neck=A(30,10,0),RS=A(170,0,-20),LS=A(150,0,30),RH=A(30),LH=A(26)),
  K(1.15,RootJoint=A(-84,0,6,0,-2.55,-1.4),Neck=A(28,10,0),RS=A(168,0,-22),LS=A(148,0,32),RH=A(28),LH=A(24))]),
}
# ---------------- VOLCANOLOGIST: heat suit, tongs with a glowing lava rock ----------------
SETS['Volcanologist']={
 'Idle':(True,0,[  # holds the tongs out, checks the rock, wipes the visor
  K(0,   RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10),RH=A(0,0,-4),LH=A(0,0,4)),
  K(0.9, RootJoint=A(-6,10,0),Neck=A(10,14,0),RS=A(50,0,-14),LS=A(12,0,10)),
  K(1.6, RootJoint=A(-4),Neck=A(-6),RS=A(40,0,-10),LS=A(150,0,-10)),
  K(1.8, RootJoint=A(-4),Neck=A(-6),RS=A(40,0,-10),LS=A(150,0,10)),
  K(2.0, RootJoint=A(-4),Neck=A(-6),RS=A(40,0,-10),LS=A(150,0,-10)),
  K(2.6, RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10),RH=A(0,0,-4),LH=A(0,0,4))]),
 'Walk':(True,1,[  # stiff heavy-suit walk, tongs ahead
  K(0,   RootJoint=A(-8,0,6),Neck=A(-2,0,-6),RS=A(42,0,-10),LS=A(-20,0,10),RH=A(26,0,-3),LH=A(-22,0,3)),
  K(0.35,RootJoint=A(-10,0,0,0,-0.2,0),Neck=A(-4),RS=A(38,0,-10),LS=A(4,0,10),RH=A(4),LH=A(4)),
  K(0.7, RootJoint=A(-8,0,-6),Neck=A(-2,0,6),RS=A(42,0,-10),LS=A(24,0,10),RH=A(-22,0,-3),LH=A(26,0,3)),
  K(1.05,RootJoint=A(-10,0,0,0,-0.2,0),Neck=A(-4),RS=A(38,0,-10),LS=A(4,0,10),RH=A(4),LH=A(4)),
  K(1.4, RootJoint=A(-8,0,6),Neck=A(-2,0,-6),RS=A(42,0,-10),LS=A(-20,0,10),RH=A(26,0,-3),LH=A(-22,0,3))]),
 'Throw':(False,4,[  # = MAGMA: swings the tongs back low, flings the lava rock underhand in a high arc
  K(0,   RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10)),
  K(0.35,RootJoint=A(-20,-20,0,0,-0.4,0),Neck=A(6,14,0),RS=A(-50,0,-20),LS=A(40,0,30),RH=A(30,0,-6),LH=A(-10,0,6)),
  K(0.55,RootJoint=A(6,20,0,0,0,0.3),Neck=A(-10,-14,0),RS=A(150,0,-10),LS=A(-10,0,20),RH=A(-10),LH=A(14)),
  K(0.8, RootJoint=A(-6,10,0),Neck=A(-4),RS=A(110,0,-10),LS=A(10,0,14)),
  K(1.1, RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10))]),
 'Attack':(False,3,[  # jabs forward with the hot tongs
  K(0,   RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10)),
  K(0.26,RootJoint=A(0,24,0,0,0,0.3),Neck=A(0,-16,0),RS=A(70,0,-40),LS=A(30,0,20),RH=A(-8),LH=A(10)),
  K(0.38,RootJoint=A(-16,-20,0,0,-0.1,-0.5),Neck=A(-6,14,0),RS=A(95,0,10),LS=A(10,0,20),RH=A(16),LH=A(-12)),
  K(0.6, RootJoint=A(-10,-10,0),Neck=A(-4,6,0),RS=A(80,0,0),LS=A(10,0,16)),
  K(0.85,RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10))]),
 'Death':(False,3,[  # the suit overheats: staggers around, sits down, falls back
  K(0,   RootJoint=A(-4),Neck=A(-2),RS=A(40,0,-10),LS=A(12,0,10)),
  K(0.3, RootJoint=A(6,40,10),Neck=A(-20,-10,0),RS=A(80,0,-50),LS=A(90,0,50),RH=A(-10),LH=A(10)),
  K(0.6, RootJoint=A(0,70,-10,0,-1.2,0),Neck=A(-10),RS=A(60,0,-30),LS=A(60,0,30),RH=A(80),LH=A(80)),
  K(0.95,RootJoint=A(84,70,0,0,-2.4,1.6),Neck=A(-14),RS=A(150,0,-50),LS=A(140,0,50),RH=A(10),LH=A(20)),
  K(1.1, RootJoint=A(82,70,0,0,-2.35,1.6),Neck=A(-12),RS=A(148,0,-52),LS=A(138,0,52),RH=A(8),LH=A(18))]),
}
# ---------------- LAVA GOLEM: huge, slow, heavy fists ----------------
SETS['LavaGolem']={
 'Idle':(True,0,[  # slow heavy breathing, fists flex, ground-shaking shift of weight
  K(0,   RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14),RH=A(4,0,-6),LH=A(4,0,6)),
  K(1.0, RootJoint=A(-10,0,4,0,-0.12,0),Neck=A(10),RS=A(14,0,-18),LS=A(8,0,12)),
  K(2.0, RootJoint=A(-10,0,-4,0,-0.12,0),Neck=A(10),RS=A(8,0,-12),LS=A(14,0,18)),
  K(3.0, RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14),RH=A(4,0,-6),LH=A(4,0,6))]),
 'Walk':(True,1,[  # slow stomping, body sways side to side
  K(0,   RootJoint=A(-10,0,10),Neck=A(6,0,-8),RS=A(30,0,-16),LS=A(-14,0,16),RH=A(30,0,-6),LH=A(-20,0,6)),
  K(0.5, RootJoint=A(-12,0,0,0,-0.35,0),Neck=A(8),RS=A(10,0,-16),LS=A(10,0,16),RH=A(4,0,-6),LH=A(4,0,6)),
  K(1.0, RootJoint=A(-10,0,-10),Neck=A(6,0,8),RS=A(-14,0,-16),LS=A(30,0,16),RH=A(-20,0,-6),LH=A(30,0,6)),
  K(1.5, RootJoint=A(-12,0,0,0,-0.35,0),Neck=A(8),RS=A(10,0,-16),LS=A(10,0,16),RH=A(4,0,-6),LH=A(4,0,6)),
  K(2.0, RootJoint=A(-10,0,10),Neck=A(6,0,-8),RS=A(30,0,-16),LS=A(-14,0,16),RH=A(30,0,-6),LH=A(-20,0,6))]),
 'Throw':(False,4,[  # = ERUPTION: rears back with both fists up, slams the ground, stays bent while the lava rains
  K(0,   RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14)),
  K(0.5, RootJoint=A(16,0,0,0,0.3,0.3),Neck=A(-30),RS=A(170,0,-30),LS=A(170,0,30),RH=A(-10,0,-6),LH=A(-10,0,6)),
  K(0.65,RootJoint=A(18,0,0,0,0.35,0.35),Neck=A(-34),RS=A(176,0,-30),LS=A(176,0,30)),
  K(0.8, RootJoint=A(-46,0,0,0,-1.2,-0.6),Neck=A(20),RS=A(70,0,-10),LS=A(70,0,10),RH=A(60),LH=A(60)),
  K(1.5, RootJoint=A(-42,0,0,0,-1.1,-0.5),Neck=A(-10),RS=A(66,0,-10),LS=A(66,0,10),RH=A(56),LH=A(56)),
  K(2.0, RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14))]),
 'Attack':(False,3,[  # uppercut-hook with the right fist, then the left follows
  K(0,   RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14)),
  K(0.3, RootJoint=A(-4,-30,0),Neck=A(4,24,0),RS=A(40,0,-60),LS=A(30,0,20),RH=A(-6),LH=A(8)),
  K(0.44,RootJoint=A(-20,30,0,0,-0.1,-0.4),Neck=A(-4,-20,0),RS=A(130,0,20),LS=A(30,0,30),RH=A(14),LH=A(-12)),
  K(0.6, RootJoint=A(-16,-10,0,0,-0.1,-0.3),Neck=A(0,6,0),RS=A(80,0,0),LS=A(100,0,-10)),
  K(1.0, RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14))]),
 'Death':(False,3,[  # cracks open, cools down to the knees and topples over backward
  K(0,   RootJoint=A(-8),Neck=A(6),RS=A(10,0,-14),LS=A(10,0,14)),
  K(0.5, RootJoint=A(10,0,0,0,0.1,0),Neck=A(-40),RS=A(90,0,-80),LS=A(90,0,80),RH=A(-6),LH=A(6)),
  K(1.0, RootJoint=A(-6,0,0,0,-1.6,0),Neck=A(30),RS=A(20,0,-30),LS=A(20,0,30),RH=A(95),LH=A(95)),
  K(1.5, RootJoint=A(80,0,-6,0,-2.8,1.4),Neck=A(-10),RS=A(160,0,-40),LS=A(160,0,40),RH=A(50),LH=A(50)),
  K(1.65,RootJoint=A(78,0,-6,0,-2.75,1.4),Neck=A(-8),RS=A(158,0,-42),LS=A(158,0,42),RH=A(48),LH=A(48))]),
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
out=os.environ.get('OUT','/home/claude/mobs9/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z9_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
