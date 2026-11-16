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
# ---------------- LUMBERJACK: heavy, axe in the right hand ----------------
SETS['Lumberjack']={
 'Idle':(True,0,[
  K(0,  RootJoint=A(-10,0,0),Neck=A(-10,0,6),RS=A(28,0,-6),LS=A(6,0,10),RH=A(4,0,-3),LH=A(-4,0,3)),
  K(0.9,RootJoint=A(-14,0,2,0,-0.12,0),Neck=A(-2,10,-4),RS=A(34,0,-8),LS=A(10,0,14),RH=A(6,0,-3),LH=A(-2,0,3)),
  K(1.5,RootJoint=A(-12,0,-1,0,-0.06,0),Neck=A(-14,-14,8),RS=A(26,0,-5),LS=A(4,0,8),RH=A(4,0,-3),LH=A(-4,0,3)),
  K(2.6,RootJoint=A(-10,0,0),Neck=A(-10,0,6),RS=A(28,0,-6),LS=A(6,0,10),RH=A(4,0,-3),LH=A(-4,0,3))]),
 'Walk':(True,1,[  # heavy stomping, rocking side to side, axe swings low
  K(0,   RootJoint=A(-16,8,7,0,0,0),Neck=A(-6,-6,-8),RS=A(40,0,-6),LS=A(-22,0,12),RH=A(30),LH=A(-24)),
  K(0.2, RootJoint=A(-18,4,4,0,-0.3,0),Neck=A(-10,-3,-4),RS=A(30,0,-6),LS=A(-10,0,12),RH=A(14),LH=A(-8)),
  K(0.5, RootJoint=A(-16,-8,-7,0,0,0),Neck=A(-6,6,8),RS=A(4,0,-8),LS=A(24,0,10),RH=A(-24),LH=A(30)),
  K(0.7, RootJoint=A(-18,-4,-4,0,-0.3,0),Neck=A(-10,3,4),RS=A(16,0,-7),LS=A(10,0,11),RH=A(-8),LH=A(14)),
  K(1.0, RootJoint=A(-16,8,7,0,0,0),Neck=A(-6,-6,-8),RS=A(40,0,-6),LS=A(-22,0,12),RH=A(30),LH=A(-24))]),
 'Attack':(False,3,[  # overhead chop with both hands
  K(0,   RootJoint=A(-12),Neck=A(-6),RS=A(28,0,-6),LS=A(6,0,10)),
  K(0.32,RootJoint=A(14,-10,0,0,0.1,0),Neck=A(18),RS=A(175,0,8),LS=A(165,0,-14),RH=A(-10),LH=A(14)),
  K(0.42,RootJoint=A(-34,4,0,0,-0.45,-0.5),Neck=A(-20),RS=A(40,0,10),LS=A(42,0,-16),RH=A(18),LH=A(-20)),
  K(0.6, RootJoint=A(-30,2,0,0,-0.4,-0.45),Neck=A(-16),RS=A(36,0,10),LS=A(38,0,-16),RH=A(16),LH=A(-18)),
  K(0.85,RootJoint=A(-12),Neck=A(-6),RS=A(28,0,-6),LS=A(6,0,10))]),
 'Death':(False,3,[  # knees buckle, falls forward on the face
  K(0,   RootJoint=A(-12),Neck=A(-6),RS=A(28,0,-6),LS=A(6,0,10)),
  K(0.3, RootJoint=A(-20,0,6,0,-1.1,0),Neck=A(20),RS=A(120,0,-30),LS=A(110,0,30),RH=A(80),LH=A(70)),
  K(0.75,RootJoint=A(-88,0,6,0,-2.4,-1.6),Neck=A(30,0,30),RS=A(170,0,-40),LS=A(160,0,30),RH=A(10),LH=A(-6)),
  K(1.0, RootJoint=A(-86,0,6,0,-2.35,-1.6),Neck=A(28,0,32),RS=A(168,0,-42),LS=A(158,0,32),RH=A(6),LH=A(-4))]),
}
# ---------------- TOURIST: limping, flailing, camera in the right hand ----------------
SETS['Tourist']={
 'Idle':(True,0,[  # lost, looks around, raises the camera to the face
  K(0,  RootJoint=A(-6,0,5),Neck=A(-4,30,10),RS=A(30,0,-8),LS=A(14,0,12),RH=A(0,0,-4),LH=A(8,0,6)),
  K(0.8,RootJoint=A(-4,10,2),Neck=A(-2,-35,-6),RS=A(36,0,-8),LS=A(20,0,16),RH=A(0,0,-4),LH=A(8,0,6)),
  K(1.4,RootJoint=A(-2,0,0),Neck=A(-14,0,0),RS=A(120,30,-12),LS=A(14,0,12),RH=A(0,0,-4),LH=A(8,0,6)),
  K(2.0,RootJoint=A(-2,0,0),Neck=A(-12,6,0),RS=A(122,32,-12),LS=A(14,0,12),RH=A(0,0,-4),LH=A(8,0,6)),
  K(2.8,RootJoint=A(-6,0,5),Neck=A(-4,30,10),RS=A(30,0,-8),LS=A(14,0,12),RH=A(0,0,-4),LH=A(8,0,6))]),
 'Walk':(True,1,[  # limp: the left leg stays stiff, body drops on it, arms flop
  K(0,   RootJoint=A(-10,10,-12,0,0,0),Neck=A(-6,0,18),RS=A(50,0,-20),LS=A(-30,0,30),RH=A(34),LH=A(-10,0,4)),
  K(0.3, RootJoint=A(-14,4,-4,0,-0.15,0),Neck=A(-10,0,6),RS=A(30,0,-12),LS=A(10,0,20),RH=A(8),LH=A(-4,0,4)),
  K(0.55,RootJoint=A(-6,-10,16,0,-0.45,0),Neck=A(-2,0,-24),RS=A(-20,0,-30),LS=A(60,0,10),RH=A(-26),LH=A(12,0,4)),
  K(0.8, RootJoint=A(-12,-2,6,0,-0.2,0),Neck=A(-8,0,-8),RS=A(14,0,-16),LS=A(30,0,14),RH=A(-6),LH=A(4,0,4)),
  K(1.1, RootJoint=A(-10,10,-12,0,0,0),Neck=A(-6,0,18),RS=A(50,0,-20),LS=A(-30,0,30),RH=A(34),LH=A(-10,0,4))]),
 'Attack':(False,3,[  # camera up to the face (flash), then clubs with it sideways
  K(0,   RootJoint=A(-8),Neck=A(-4),RS=A(30,0,-8),LS=A(14,0,12)),
  K(0.18,RootJoint=A(2,0,0),Neck=A(-10),RS=A(115,30,-10),LS=A(30,0,20)),
  K(0.3, RootJoint=A(0,-28,0),Neck=A(0,10,0),RS=A(110,0,-70),LS=A(40,0,30),RH=A(-6),LH=A(8)),
  K(0.4, RootJoint=A(-14,34,0,0,-0.1,-0.2),Neck=A(-8,-14,0),RS=A(80,0,45),LS=A(20,0,40),RH=A(12),LH=A(-10)),
  K(0.6, RootJoint=A(-12,20,0),Neck=A(-6),RS=A(60,0,30),LS=A(16,0,20)),
  K(0.8, RootJoint=A(-8),Neck=A(-4),RS=A(30,0,-8),LS=A(14,0,12))]),
 'Death':(False,3,[  # spins and collapses sideways, camera arm up
  K(0,   RootJoint=A(-8),Neck=A(-4),RS=A(30,0,-8),LS=A(14,0,12)),
  K(0.3, RootJoint=A(0,70,20,0,-0.3,0),Neck=A(10,0,30),RS=A(160,0,-20),LS=A(40,0,60),RH=A(30),LH=A(-20)),
  K(0.75,RootJoint=A(0,95,86,-2.2,-2.3,0),Neck=A(0,0,30),RS=A(175,0,-30),LS=A(20,0,70),RH=A(20,0,10),LH=A(-10,0,-10)),
  K(1.0, RootJoint=A(0,95,84,-2.2,-2.25,0),Neck=A(0,0,32),RS=A(172,0,-32),LS=A(22,0,72),RH=A(18,0,10),LH=A(-8,0,-10))]),
}
# ---------------- AXE THROWER: big, upright, stalks, throws ----------------
SETS['AxeThrower']={
 'Idle':(True,0,[  # bounces the axe in the hand, left fist clenched
  K(0,   RootJoint=A(-4,-6,0),Neck=A(-8,6,0),RS=A(40,0,-10),LS=A(10,0,20),RH=A(6,0,-6),LH=A(-6,0,6)),
  K(0.35,RootJoint=A(-4,-6,0,0,-0.05,0),Neck=A(-6,6,0),RS=A(75,0,-10),LS=A(10,0,20),RH=A(6,0,-6),LH=A(-6,0,6)),
  K(0.7, RootJoint=A(-4,-6,0),Neck=A(-8,6,0),RS=A(40,0,-10),LS=A(10,0,20),RH=A(6,0,-6),LH=A(-6,0,6)),
  K(1.6, RootJoint=A(-6,4,0,0,-0.08,0),Neck=A(-10,-12,4),RS=A(36,0,-12),LS=A(14,0,22),RH=A(6,0,-6),LH=A(-6,0,6)),
  K(2.4, RootJoint=A(-4,-6,0),Neck=A(-8,6,0),RS=A(40,0,-10),LS=A(10,0,20),RH=A(6,0,-6),LH=A(-6,0,6))]),
 'Walk':(True,1,[  # stalking: shoulders roll, axe held back ready
  K(0,   RootJoint=A(-8,14,0),Neck=A(-4,-14,0),RS=A(-30,0,-14),LS=A(34,0,14),RH=A(28),LH=A(-26)),
  K(0.25,RootJoint=A(-10,0,0,0,-0.2,0),Neck=A(-6),RS=A(-20,0,-14),LS=A(10,0,14),RH=A(4),LH=A(0)),
  K(0.5, RootJoint=A(-8,-14,0),Neck=A(-4,14,0),RS=A(10,0,-14),LS=A(-24,0,14),RH=A(-26),LH=A(28)),
  K(0.75,RootJoint=A(-10,0,0,0,-0.2,0),Neck=A(-6),RS=A(-20,0,-14),LS=A(10,0,14),RH=A(0),LH=A(4)),
  K(1.0, RootJoint=A(-8,14,0),Neck=A(-4,-14,0),RS=A(-30,0,-14),LS=A(34,0,14),RH=A(28),LH=A(-26))]),
 'Throw':(False,4,[  # aim with the left arm, wind back, hurl
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-10),LS=A(10,0,20)),
  K(0.45,RootJoint=A(10,-30,0,0,0,0.2),Neck=A(-4,30,0),RS=A(170,-20,-20),LS=A(95,10,10),RH=A(-14),LH=A(22)),
  K(0.6, RootJoint=A(-26,28,0,0,-0.2,-0.5),Neck=A(-14,-24,0),RS=A(30,0,8),LS=A(-10,0,26),RH=A(24),LH=A(-20)),
  K(0.8, RootJoint=A(-20,20,0,0,-0.15,-0.4),Neck=A(-10,-18,0),RS=A(20,0,6),LS=A(0,0,24),RH=A(20),LH=A(-16)),
  K(1.05,RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-10),LS=A(10,0,20))]),
 'Attack':(False,3,[  # close range: backhand slash across
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-10),LS=A(10,0,20)),
  K(0.3, RootJoint=A(0,-34,0),Neck=A(0,26,0),RS=A(95,0,-75),LS=A(20,0,30),RH=A(-6),LH=A(8)),
  K(0.42,RootJoint=A(-16,36,0,0,-0.1,-0.25),Neck=A(-8,-20,0),RS=A(90,0,50),LS=A(10,0,40),RH=A(14),LH=A(-12)),
  K(0.62,RootJoint=A(-12,24,0),Neck=A(-6,-10,0),RS=A(70,0,36),LS=A(10,0,30)),
  K(0.85,RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-10),LS=A(10,0,20))]),
 'Death':(False,3,[  # drops to the knees, sways, falls forward
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-10),LS=A(10,0,20)),
  K(0.35,RootJoint=A(-6,0,0,0,-1.5,0),Neck=A(14),RS=A(20,0,-20),LS=A(20,0,20),RH=A(95),LH=A(90)),
  K(0.6, RootJoint=A(4,0,-6,0,-1.5,0),Neck=A(26,0,-10),RS=A(10,0,-30),LS=A(10,0,34),RH=A(95),LH=A(90)),
  K(0.95,RootJoint=A(-86,0,0,0,-2.6,-1.4),Neck=A(30,0,20),RS=A(160,0,-30),LS=A(165,0,30),RH=A(30),LH=A(26)),
  K(1.15,RootJoint=A(-84,0,0,0,-2.55,-1.4),Neck=A(28,0,22),RS=A(158,0,-32),LS=A(163,0,32),RH=A(28),LH=A(24))]),
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
out=os.environ.get('OUT','/home/claude/mobs2/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z2_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
