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
# ---------------- SKELETON: light, rattly, fast; rusty sword ----------------
SETS['Skeleton']={
 'Idle':(True,0,[  # sways loosely, jaw-head rattles, sword point down
  K(0,   RootJoint=A(-6,0,4),Neck=A(-6,0,-8),RS=A(20,0,-10),LS=A(6,0,10),RH=A(0,0,-4),LH=A(0,0,4)),
  K(0.6, RootJoint=A(-8,0,-4),Neck=A(-10,10,8),RS=A(24,0,-10),LS=A(10,0,12)),
  K(0.9, RootJoint=A(-8,0,-4),Neck=A(-4,-14,4),RS=A(24,0,-10),LS=A(10,0,12)),
  K(1.0, RootJoint=A(-8,0,-4),Neck=A(-12,12,4),RS=A(24,0,-10),LS=A(10,0,12)),
  K(1.1, RootJoint=A(-8,0,-4),Neck=A(-4,-12,4),RS=A(24,0,-10),LS=A(10,0,12)),
  K(1.8, RootJoint=A(-6,0,4),Neck=A(-6,0,-8),RS=A(20,0,-10),LS=A(6,0,10),RH=A(0,0,-4),LH=A(0,0,4))]),
 'Walk':(True,1,[  # fast jerky jog, arms flopping
  K(0,   RootJoint=A(-16,10,0),Neck=A(-2,-10,6),RS=A(46,0,-10),LS=A(-34,0,14),RH=A(36),LH=A(-30)),
  K(0.2, RootJoint=A(-18,0,0,0,-0.2,0),Neck=A(-4,0,-6),RS=A(20,0,-14),LS=A(4,0,20),RH=A(4),LH=A(8)),
  K(0.4, RootJoint=A(-16,-10,0),Neck=A(-2,10,6),RS=A(-20,0,-10),LS=A(40,0,14),RH=A(-30),LH=A(36)),
  K(0.6, RootJoint=A(-18,0,0,0,-0.2,0),Neck=A(-4,0,-6),RS=A(20,0,-14),LS=A(4,0,20),RH=A(8),LH=A(4)),
  K(0.8, RootJoint=A(-16,10,0),Neck=A(-2,-10,6),RS=A(46,0,-10),LS=A(-34,0,14),RH=A(36),LH=A(-30))]),
 'Attack':(False,3,[  # quick diagonal slash: sword back over the left shoulder, cut down to the right
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(20,0,-10),LS=A(6,0,10)),
  K(0.18,RootJoint=A(-4,30,0),Neck=A(-4,-24,0),RS=A(150,0,40),LS=A(20,0,30),RH=A(-8,0,-4),LH=A(12)),
  K(0.3, RootJoint=A(-20,-34,0,0,-0.1,-0.4),Neck=A(-10,24,0),RS=A(40,0,-60),LS=A(-10,0,20),RH=A(20),LH=A(-16)),
  K(0.5, RootJoint=A(-14,-20,0,0,-0.05,-0.3),Neck=A(-8,14,0),RS=A(30,0,-40),LS=A(0,0,16)),
  K(0.7, RootJoint=A(-6),Neck=A(-6),RS=A(20,0,-10),LS=A(6,0,10))]),
 'Death':(False,3,[  # bones give way: falls apart straight down into a heap
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(20,0,-10),LS=A(6,0,10)),
  K(0.15,RootJoint=A(4,0,10),Neck=A(20,0,-30),RS=A(60,0,-60),LS=A(50,0,60),RH=A(0,0,-10),LH=A(0,0,10)),
  K(0.45,RootJoint=A(-20,0,-8,0,-1.6,0),Neck=A(40,0,30),RS=A(10,0,-90),LS=A(10,0,90),RH=A(100,0,-30),LH=A(100,0,30)),
  K(0.75,RootJoint=A(-70,0,10,0,-2.6,-0.6),Neck=A(50,30,40,0,-0.4,0),RS=A(-20,0,-100),LS=A(-10,0,100),RH=A(120,0,-40),LH=A(110,0,40)),
  K(0.9, RootJoint=A(-72,0,10,0,-2.65,-0.6),Neck=A(52,30,44,0,-0.45,0),RS=A(-20,0,-102),LS=A(-10,0,102),RH=A(118,0,-40),LH=A(108,0,40))]),
}
# ---------------- GRAVEDIGGER: hunched worker, shovel + clumps of grave mud ----------------
SETS['Gravedigger']={
 'Idle':(True,0,[  # leans on the shovel, scratches the neck with the free hand
  K(0,   RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10),RH=A(4,0,-4),LH=A(-4,0,6)),
  K(1.0, RootJoint=A(-14,-6,0,0,-0.1,0),Neck=A(10,6,0),RS=A(48,0,-14),LS=A(8,0,10)),
  K(1.6, RootJoint=A(-12,-6,0),Neck=A(-6,-10,10),RS=A(50,0,-14),LS=A(150,0,-30)),
  K(1.8, RootJoint=A(-12,-6,0),Neck=A(-6,-10,10),RS=A(50,0,-14),LS=A(140,0,-20)),
  K(2.0, RootJoint=A(-12,-6,0),Neck=A(-6,-10,10),RS=A(50,0,-14),LS=A(150,0,-30)),
  K(2.6, RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10),RH=A(4,0,-4),LH=A(-4,0,6))]),
 'Walk':(True,1,[  # slow trudge, shovel over the shoulder
  K(0,   RootJoint=A(-14,6,0),Neck=A(6,-6,0),RS=A(150,0,10),LS=A(-22,0,10),RH=A(26),LH=A(-20)),
  K(0.36,RootJoint=A(-16,0,0,0,-0.2,0),Neck=A(4),RS=A(146,0,10),LS=A(2,0,10),RH=A(4),LH=A(2)),
  K(0.72,RootJoint=A(-14,-6,0),Neck=A(6,6,0),RS=A(150,0,10),LS=A(26,0,10),RH=A(-20),LH=A(26)),
  K(1.08,RootJoint=A(-16,0,0,0,-0.2,0),Neck=A(4),RS=A(146,0,10),LS=A(2,0,10),RH=A(2),LH=A(4)),
  K(1.44,RootJoint=A(-14,6,0),Neck=A(6,-6,0),RS=A(150,0,10),LS=A(-22,0,10),RH=A(26),LH=A(-20))]),
 'Throw':(False,4,[  # = MUD: scoops a clump from the ground with the left hand and hurls it overhand
  K(0,   RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10)),
  K(0.3, RootJoint=A(-40,20,0,0,-0.6,0),Neck=A(20,-10,0),RS=A(40,0,-20),LS=A(40,0,10),RH=A(40,0,-6),LH=A(30,0,6)),
  K(0.5, RootJoint=A(0,30,0,0,0,0.3),Neck=A(-6,-20,0),RS=A(30,0,-30),LS=A(190,0,-20),RH=A(-6),LH=A(10)),
  K(0.62,RootJoint=A(-18,-24,0,0,-0.1,-0.4),Neck=A(-8,16,0),RS=A(20,0,-20),LS=A(70,0,-10),RH=A(16),LH=A(-12)),
  K(0.9, RootJoint=A(-14,-10,0),Neck=A(0,6,0),RS=A(40,0,-14),LS=A(20,0,10)),
  K(1.2, RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10))]),
 'Attack':(False,3,[  # flat shovel smash from above (both hands)
  K(0,   RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10)),
  K(0.3, RootJoint=A(10,0,0,0,0,0.3),Neck=A(-10),RS=A(190,0,-10),LS=A(180,0,30),RH=A(-6),LH=A(6)),
  K(0.44,RootJoint=A(-30,0,0,0,-0.3,-0.6),Neck=A(-10),RS=A(60,0,-10),LS=A(60,0,30),RH=A(20),LH=A(-16)),
  K(0.7, RootJoint=A(-24,0,0,0,-0.2,-0.4),Neck=A(-6),RS=A(54,0,-10),LS=A(50,0,26),RH=A(14),LH=A(-10)),
  K(1.0, RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10))]),
 'Death':(False,3,[  # stumbles back, falls flat on the back
  K(0,   RootJoint=A(-12,-6,0),Neck=A(6,6,0),RS=A(50,0,-14),LS=A(6,0,10)),
  K(0.3, RootJoint=A(14,0,0,0,0,0.4),Neck=A(-20),RS=A(90,0,-30),LS=A(70,0,30),RH=A(-20),LH=A(10)),
  K(0.6, RootJoint=A(40,0,0,0,-0.8,1.0),Neck=A(-14),RS=A(120,0,-40),LS=A(110,0,40),RH=A(-30),LH=A(20)),
  K(0.95,RootJoint=A(86,0,-4,0,-2.4,1.8),Neck=A(-10,20,0),RS=A(160,0,-60),LS=A(150,0,60),RH=A(10),LH=A(20)),
  K(1.1, RootJoint=A(84,0,-4,0,-2.35,1.8),Neck=A(-8,22,0),RS=A(158,0,-62),LS=A(148,0,62),RH=A(8),LH=A(18))]),
}
# ---------------- NECROMANCER: tall, glides, casts with the staff ----------------
SETS['Necromancer']={
 'Idle':(True,0,[  # staff upright, free hand weaves a spell, slow floaty bob
  K(0,   RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24),RH=A(0,0,-3),LH=A(0,0,3)),
  K(1.0, RootJoint=A(-4,0,0,0,0.12,0),Neck=A(-10,10,0),RS=A(30,0,-6),LS=A(70,0,40)),
  K(1.6, RootJoint=A(-4,0,0,0,0.05,0),Neck=A(-10,-10,0),RS=A(30,0,-6),LS=A(60,30,10)),
  K(2.4, RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24),RH=A(0,0,-3),LH=A(0,0,3))]),
 'Walk':(True,1,[  # gliding steps under the robe, almost no arm swing
  K(0,   RootJoint=A(-6,4,0),Neck=A(-6,-4,0),RS=A(32,0,-6),LS=A(36,0,22),RH=A(16),LH=A(-14)),
  K(0.45,RootJoint=A(-6,0,0,0,0.1,0),Neck=A(-6),RS=A(30,0,-6),LS=A(38,0,22),RH=A(2),LH=A(2)),
  K(0.9, RootJoint=A(-6,-4,0),Neck=A(-6,4,0),RS=A(32,0,-6),LS=A(36,0,22),RH=A(-14),LH=A(16)),
  K(1.35,RootJoint=A(-6,0,0,0,0.1,0),Neck=A(-6),RS=A(30,0,-6),LS=A(38,0,22),RH=A(2),LH=A(2)),
  K(1.8, RootJoint=A(-6,4,0),Neck=A(-6,-4,0),RS=A(32,0,-6),LS=A(36,0,22),RH=A(16),LH=A(-14))]),
 'Throw':(False,4,[  # = CURSE: lifts the staff high, free hand to the sky, then drives the staff into the ground
  K(0,   RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24)),
  K(0.45,RootJoint=A(12,0,0,0,0.3,0),Neck=A(-30),RS=A(170,0,-10),LS=A(160,0,40),RH=A(-6,0,-6),LH=A(6,0,6)),
  K(0.6, RootJoint=A(14,0,0,0,0.35,0),Neck=A(-34),RS=A(176,0,-10),LS=A(166,0,44)),
  K(0.78,RootJoint=A(-24,0,0,0,-0.4,-0.3),Neck=A(10),RS=A(80,0,-6),LS=A(30,0,60),RH=A(-20),LH=A(40)),
  K(1.3, RootJoint=A(-22,0,0,0,-0.4,-0.3),Neck=A(8),RS=A(78,0,-6),LS=A(30,0,62),RH=A(-20),LH=A(40)),
  K(1.7, RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24))]),
 'Attack':(False,3,[  # swings the staff head sideways like a mace
  K(0,   RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24)),
  K(0.28,RootJoint=A(0,-36,0),Neck=A(0,26,0),RS=A(90,0,-90),LS=A(30,0,30),RH=A(-6),LH=A(8)),
  K(0.42,RootJoint=A(-14,34,0,0,-0.1,-0.3),Neck=A(-6,-20,0),RS=A(90,0,40),LS=A(20,0,30),RH=A(10),LH=A(-10)),
  K(0.7, RootJoint=A(-10,20,0),Neck=A(-6,-10,0),RS=A(60,0,20),LS=A(30,0,26)),
  K(1.0, RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24))]),
 'Death':(False,3,[  # staff falls, clutches the head, kneels and topples to the side
  K(0,   RootJoint=A(-4),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,24)),
  K(0.35,RootJoint=A(8),Neck=A(-30,0,10),RS=A(150,0,-50),LS=A(150,0,50),RH=A(-6),LH=A(6)),
  K(0.7, RootJoint=A(-10,0,0,0,-1.5,0),Neck=A(24),RS=A(140,0,-60),LS=A(140,0,60),RH=A(95),LH=A(90)),
  K(1.1, RootJoint=A(-10,30,80,-1.4,-2.3,0),Neck=A(10,0,10),RS=A(100,0,-40),LS=A(60,0,60),RH=A(60),LH=A(70)),
  K(1.25,RootJoint=A(-10,30,78,-1.35,-2.25,0),Neck=A(10,0,12),RS=A(98,0,-40),LS=A(58,0,58),RH=A(58),LH=A(68))]),
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
out=os.environ.get('OUT','/home/claude/mobs8/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z8_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
