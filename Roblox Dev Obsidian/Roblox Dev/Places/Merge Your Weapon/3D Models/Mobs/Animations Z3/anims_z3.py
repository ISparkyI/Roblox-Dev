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
# ---------------- MINER: heavy, hunched, pickaxe in the right hand ----------------
SETS['Miner']={
 'Idle':(True,0,[
  K(0,  RootJoint=A(-14,0,0),Neck=A(-6,0,4),RS=A(22,0,-4),LS=A(10,0,10),RH=A(4,0,-3),LH=A(-4,0,3)),
  K(1.0,RootJoint=A(-17,0,2,0,-0.12,0),Neck=A(-14,12,-4),RS=A(26,0,-6),LS=A(14,0,12),RH=A(6,0,-3),LH=A(-2,0,3)),
  K(1.8,RootJoint=A(-15,0,-2,0,-0.06,0),Neck=A(0,-16,6),RS=A(20,0,-4),LS=A(6,0,9),RH=A(4,0,-3),LH=A(-4,0,3)),
  K(2.8,RootJoint=A(-14,0,0),Neck=A(-6,0,4),RS=A(22,0,-4),LS=A(10,0,10),RH=A(4,0,-3),LH=A(-4,0,3))]),
 'Walk':(True,1,[  # trudging, bent forward, pickaxe dragged low, big heavy steps
  K(0,   RootJoint=A(-20,6,6,0,0,0),Neck=A(4,-6,-6),RS=A(14,0,-4),LS=A(-26,0,12),RH=A(32),LH=A(-26)),
  K(0.25,RootJoint=A(-22,3,3,0,-0.35,0),Neck=A(0,-3,-3),RS=A(8,0,-4),LS=A(-8,0,12),RH=A(12),LH=A(-8)),
  K(0.6, RootJoint=A(-20,-6,-6,0,0,0),Neck=A(4,6,6),RS=A(-8,0,-6),LS=A(26,0,10),RH=A(-26),LH=A(32)),
  K(0.85,RootJoint=A(-22,-3,-3,0,-0.35,0),Neck=A(0,3,3),RS=A(4,0,-5),LS=A(8,0,11),RH=A(-8),LH=A(12)),
  K(1.2, RootJoint=A(-20,6,6,0,0,0),Neck=A(4,-6,-6),RS=A(14,0,-4),LS=A(-26,0,12),RH=A(32),LH=A(-26))]),
 'Attack':(False,3,[  # pickaxe high over the head, then a heavy strike into the ground
  K(0,   RootJoint=A(-14),Neck=A(-6),RS=A(22,0,-4),LS=A(10,0,10)),
  K(0.4, RootJoint=A(16,12,0,0,0.12,0.15),Neck=A(20),RS=A(185,0,10),LS=A(60,0,-20),RH=A(-12),LH=A(18)),
  K(0.52,RootJoint=A(-40,-6,0,0,-0.55,-0.6),Neck=A(-22),RS=A(30,0,6),LS=A(20,0,-10),RH=A(22),LH=A(-24)),
  K(0.75,RootJoint=A(-36,-4,0,0,-0.5,-0.55),Neck=A(-18),RS=A(26,0,6),LS=A(16,0,-8),RH=A(20),LH=A(-22)),
  K(1.0, RootJoint=A(-14),Neck=A(-6),RS=A(22,0,-4),LS=A(10,0,10))]),
 'Death':(False,3,[  # drops the pickaxe arm, knees give in, falls forward onto it
  K(0,   RootJoint=A(-14),Neck=A(-6),RS=A(22,0,-4),LS=A(10,0,10)),
  K(0.35,RootJoint=A(-10,0,-8,0,-1.3,0),Neck=A(22,0,-10),RS=A(60,0,-20),LS=A(30,0,30),RH=A(90),LH=A(84)),
  K(0.55,RootJoint=A(-6,0,8,0,-1.35,0),Neck=A(30,0,14),RS=A(70,0,-24),LS=A(36,0,34),RH=A(92),LH=A(86)),
  K(0.9, RootJoint=A(-88,0,4,0,-2.5,-1.5),Neck=A(26,0,26),RS=A(150,0,-36),LS=A(170,0,36),RH=A(24),LH=A(20)),
  K(1.1, RootJoint=A(-86,0,4,0,-2.45,-1.5),Neck=A(24,0,28),RS=A(148,0,-38),LS=A(168,0,38),RH=A(22),LH=A(18))]),
}
# ---------------- DYNAMITER: big, swaggering, lit stick in the right hand ----------------
SETS['Dynamiter']={
 'Idle':(True,0,[  # tosses the stick up and catches it, shoulders shake (laughing)
  K(0,   RootJoint=A(-6,0,0),Neck=A(-4,0,0),RS=A(40,0,-8),LS=A(14,0,14),RH=A(2,0,-4),LH=A(-2,0,4)),
  K(0.35,RootJoint=A(-4,0,0,0,0.05,0),Neck=A(-14,0,0),RS=A(75,0,-10),LS=A(14,0,14)),
  K(0.6, RootJoint=A(-7,0,0,0,-0.05,0),Neck=A(6,0,0),RS=A(36,0,-8),LS=A(14,0,14)),
  K(1.0, RootJoint=A(-5,0,4),Neck=A(-8,0,8),RS=A(42,0,-8),LS=A(18,0,16),RH=A(2,0,-4),LH=A(-2,0,4)),
  K(1.15,RootJoint=A(-5,0,-4),Neck=A(-8,0,-8),RS=A(42,0,-8),LS=A(18,0,16)),
  K(1.3, RootJoint=A(-5,0,4),Neck=A(-8,0,8),RS=A(42,0,-8),LS=A(18,0,16)),
  K(1.9, RootJoint=A(-6,0,0),Neck=A(-4,0,0),RS=A(40,0,-8),LS=A(14,0,14),RH=A(2,0,-4),LH=A(-2,0,4))]),
 'Walk':(True,1,[  # wide swagger, rocks side to side, stick held up
  K(0,   RootJoint=A(-8,10,9,0,0,0),Neck=A(-4,-10,-8),RS=A(55,0,-10),LS=A(-24,0,18),RH=A(30,0,-6),LH=A(-24,0,6)),
  K(0.3, RootJoint=A(-10,4,4,0,-0.28,0),Neck=A(-6,-4,-4),RS=A(50,0,-10),LS=A(-6,0,18),RH=A(10,0,-6),LH=A(-8,0,6)),
  K(0.7, RootJoint=A(-8,-10,-9,0,0,0),Neck=A(-4,10,8),RS=A(40,0,-12),LS=A(24,0,16),RH=A(-24,0,-6),LH=A(30,0,6)),
  K(1.0, RootJoint=A(-10,-4,-4,0,-0.28,0),Neck=A(-6,4,4),RS=A(48,0,-11),LS=A(6,0,17),RH=A(-8,0,-6),LH=A(10,0,6)),
  K(1.4, RootJoint=A(-8,10,9,0,0,0),Neck=A(-4,-10,-8),RS=A(55,0,-10),LS=A(-24,0,18),RH=A(30,0,-6),LH=A(-24,0,6))]),
 'Throw':(False,4,[  # left arm points at the target, big wind-up, lob over the head
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(40,0,-8),LS=A(14,0,14)),
  K(0.5, RootJoint=A(12,-26,0,0,0,0.25),Neck=A(-6,26,0),RS=A(195,-10,-24),LS=A(100,10,8),RH=A(-14),LH=A(22)),
  K(0.66,RootJoint=A(-24,24,0,0,-0.2,-0.5),Neck=A(-12,-20,0),RS=A(120,0,6),LS=A(-6,0,26),RH=A(24),LH=A(-20)),
  K(0.85,RootJoint=A(-18,18,0,0,-0.15,-0.4),Neck=A(-8,-14,0),RS=A(60,0,6),LS=A(4,0,24),RH=A(18),LH=A(-14)),
  K(1.15,RootJoint=A(-6),Neck=A(-4),RS=A(40,0,-8),LS=A(14,0,14))]),
 'Attack':(False,3,[  # close range: shoulder charge
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(40,0,-8),LS=A(14,0,14)),
  K(0.3, RootJoint=A(-10,40,0,0,0,0.5),Neck=A(-6,-30,0),RS=A(20,0,-20),LS=A(40,0,40),RH=A(-16),LH=A(20)),
  K(0.42,RootJoint=A(-28,-30,0,0,-0.2,-1.3),Neck=A(-14,24,0),RS=A(30,0,-10),LS=A(70,0,60),RH=A(30),LH=A(-26)),
  K(0.62,RootJoint=A(-22,-20,0,0,-0.15,-1.0),Neck=A(-10,16,0),RS=A(30,0,-10),LS=A(60,0,50),RH=A(24),LH=A(-20)),
  K(0.9, RootJoint=A(-6),Neck=A(-4),RS=A(40,0,-8),LS=A(14,0,14))]),
 'Death':(False,3,[  # the fuse on the belt hisses: he looks down, staggers back, falls on the back
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(40,0,-8),LS=A(14,0,14)),
  K(0.3, RootJoint=A(-14),Neck=A(-40),RS=A(30,0,-30),LS=A(30,0,30),RH=A(-6),LH=A(6)),
  K(0.6, RootJoint=A(12,0,0,0,0,0.6),Neck=A(30),RS=A(150,0,-50),LS=A(150,0,50),RH=A(-30),LH=A(10)),
  K(1.0, RootJoint=A(84,0,4,0,-2.3,1.7),Neck=A(-20,0,10),RS=A(170,0,-60),LS=A(170,0,60),RH=A(-30),LH=A(-20)),
  K(1.2, RootJoint=A(82,0,4,0,-2.25,1.7),Neck=A(-18,0,12),RS=A(168,0,-62),LS=A(168,0,62),RH=A(-28),LH=A(-18))]),
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
out=os.environ.get('OUT','/home/claude/mobs3/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z3_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
