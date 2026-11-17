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
# ---------------- POLICE: pistol, cop stance ----------------
SETS['Police']={
 'Idle':(True,0,[  # hand near the holster, looks around, adjusts the cap
  K(0,   RootJoint=A(-4),Neck=A(-4,0,0),RS=A(16,0,-6),LS=A(10,0,8),RH=A(0,0,-4),LH=A(0,0,4)),
  K(0.8, RootJoint=A(-4,10,0),Neck=A(-4,20,0),RS=A(16,0,-6),LS=A(10,0,8)),
  K(1.4, RootJoint=A(-4,-10,0),Neck=A(-6,-24,0),RS=A(16,0,-6),LS=A(10,0,8)),
  K(1.9, RootJoint=A(-4),Neck=A(-8,0,0),RS=A(16,0,-6),LS=A(160,0,30)),
  K(2.3, RootJoint=A(-4),Neck=A(-8,0,0),RS=A(16,0,-6),LS=A(150,0,30)),
  K(2.8, RootJoint=A(-4),Neck=A(-4,0,0),RS=A(16,0,-6),LS=A(10,0,8),RH=A(0,0,-4),LH=A(0,0,4))]),
 'Walk':(True,1,[  # zombie patrol walk, pistol low
  K(0,   RootJoint=A(-10,6,0),Neck=A(-4,-6,0),RS=A(30,0,-6),LS=A(-26,0,8),RH=A(28),LH=A(-24)),
  K(0.28,RootJoint=A(-12,0,0,0,-0.25,0),Neck=A(-6),RS=A(14,0,-6),LS=A(0,0,8),RH=A(4),LH=A(4)),
  K(0.56,RootJoint=A(-10,-6,0),Neck=A(-4,6,0),RS=A(0,0,-6),LS=A(28,0,8),RH=A(-24),LH=A(28)),
  K(0.84,RootJoint=A(-12,0,0,0,-0.25,0),Neck=A(-6),RS=A(14,0,-6),LS=A(0,0,8),RH=A(4),LH=A(4)),
  K(1.12,RootJoint=A(-10,6,0),Neck=A(-4,-6,0),RS=A(30,0,-6),LS=A(-26,0,8),RH=A(28),LH=A(-24))]),
 'Throw':(False,4,[  # = SHOOT: two-handed aim, three shots with recoil
  K(0,   RootJoint=A(-4),Neck=A(-4),RS=A(16,0,-6),LS=A(10,0,8)),
  K(0.4, RootJoint=A(-6,-10,0),Neck=A(-2,8,0),RS=A(90,0,-2),LS=A(85,0,40),RH=A(-6,0,-6),LH=A(10,0,6)),
  K(0.62,RootJoint=A(-6,-10,0),Neck=A(-2,8,0),RS=A(90,0,-2),LS=A(85,0,40)),
  K(0.68,RootJoint=A(-2,-10,0),Neck=A(2,8,0),RS=A(104,0,-2),LS=A(98,0,40)),
  K(0.78,RootJoint=A(-6,-10,0),Neck=A(-2,8,0),RS=A(90,0,-2),LS=A(85,0,40)),
  K(0.84,RootJoint=A(-2,-10,0),Neck=A(2,8,0),RS=A(104,0,-2),LS=A(98,0,40)),
  K(0.94,RootJoint=A(-6,-10,0),Neck=A(-2,8,0),RS=A(90,0,-2),LS=A(85,0,40)),
  K(1.0, RootJoint=A(-2,-10,0),Neck=A(2,8,0),RS=A(104,0,-2),LS=A(98,0,40)),
  K(1.1, RootJoint=A(-6,-10,0),Neck=A(-2,8,0),RS=A(90,0,-2),LS=A(85,0,40)),
  K(1.4, RootJoint=A(-4),Neck=A(-4),RS=A(16,0,-6),LS=A(10,0,8))]),
 'Attack':(False,3,[  # pistol whip
  K(0,   RootJoint=A(-4),Neck=A(-4),RS=A(16,0,-6),LS=A(10,0,8)),
  K(0.26,RootJoint=A(0,-26,0),Neck=A(0,20,0),RS=A(120,0,-50),LS=A(30,0,20),RH=A(-6),LH=A(8)),
  K(0.38,RootJoint=A(-18,24,0,0,-0.1,-0.25),Neck=A(-8,-16,0),RS=A(60,0,30),LS=A(20,0,20),RH=A(12),LH=A(-10)),
  K(0.6, RootJoint=A(-12,14,0),Neck=A(-6,-8,0),RS=A(40,0,10),LS=A(14,0,12)),
  K(0.85,RootJoint=A(-4),Neck=A(-4),RS=A(16,0,-6),LS=A(10,0,8))]),
 'Death':(False,3,[  # hit, spins and falls on the side
  K(0,   RootJoint=A(-4),Neck=A(-4),RS=A(16,0,-6),LS=A(10,0,8)),
  K(0.25,RootJoint=A(6,-60,0,0,0,0.2),Neck=A(14,20,0),RS=A(60,0,-50),LS=A(40,0,60),RH=A(-10),LH=A(10)),
  K(0.5, RootJoint=A(10,-120,-20,0,-0.5,0.3),Neck=A(20),RS=A(90,0,-60),LS=A(60,0,70),RH=A(10),LH=A(20)),
  K(0.95,RootJoint=A(0,-140,-86,1.6,-2.2,0),Neck=A(10,0,-10),RS=A(100,0,-40),LS=A(40,0,60),RH=A(20),LH=A(30)),
  K(1.1, RootJoint=A(0,-140,-84,1.55,-2.15,0),Neck=A(10,0,-10),RS=A(98,0,-40),LS=A(40,0,58),RH=A(18),LH=A(28))]),
}
# ---------------- FIREFIGHTER: heavy coat, hose ----------------
SETS['Firefighter']={
 'Idle':(True,0,[  # nozzle held low, wipes soot off the face, breathes heavily
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30),RH=A(2,0,-5),LH=A(-2,0,5)),
  K(0.9, RootJoint=A(-8,0,0,0,-0.08,0),Neck=A(-8),RS=A(34,0,-8),LS=A(42,0,30)),
  K(1.5, RootJoint=A(-6),Neck=A(-10,10,0),RS=A(36,0,-8),LS=A(150,0,10)),
  K(1.8, RootJoint=A(-6),Neck=A(-10,-10,0),RS=A(36,0,-8),LS=A(140,0,30)),
  K(2.2, RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30)),
  K(3.0, RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30),RH=A(2,0,-5),LH=A(-2,0,5))]),
 'Walk':(True,1,[  # heavy boots stomp
  K(0,   RootJoint=A(-10,0,6),Neck=A(-4,0,-6),RS=A(40,0,-8),LS=A(44,0,30),RH=A(28,0,-4),LH=A(-22,0,4)),
  K(0.34,RootJoint=A(-12,0,0,0,-0.3,0),Neck=A(-6),RS=A(34,0,-8),LS=A(38,0,30),RH=A(6,0,-4),LH=A(4,0,4)),
  K(0.68,RootJoint=A(-10,0,-6),Neck=A(-4,0,6),RS=A(40,0,-8),LS=A(44,0,30),RH=A(-22,0,-4),LH=A(28,0,4)),
  K(1.02,RootJoint=A(-12,0,0,0,-0.3,0),Neck=A(-6),RS=A(34,0,-8),LS=A(38,0,30),RH=A(4,0,-4),LH=A(6,0,4)),
  K(1.36,RootJoint=A(-10,0,6),Neck=A(-4,0,-6),RS=A(40,0,-8),LS=A(44,0,30),RH=A(28,0,-4),LH=A(-22,0,4))]),
 'Throw':(False,4,[  # = HOSE: braces, both hands on the nozzle, the jet shakes him back
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30)),
  K(0.5, RootJoint=A(-16,0,0,0,-0.3,0),Neck=A(-8),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-14,0,-12),LH=A(24,0,12)),
  K(0.7, RootJoint=A(-12,0,0,0,-0.3,0.1),Neck=A(-6),RS=A(88,0,-4),LS=A(84,0,40),RH=A(-14,0,-12),LH=A(24,0,12)),
  K(0.9, RootJoint=A(-16,0,0,0,-0.3,0),Neck=A(-8),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-14,0,-12),LH=A(24,0,12)),
  K(1.1, RootJoint=A(-12,0,0,0,-0.3,0.1),Neck=A(-6),RS=A(88,0,-4),LS=A(84,0,40),RH=A(-14,0,-12),LH=A(24,0,12)),
  K(1.3, RootJoint=A(-16,0,0,0,-0.3,0),Neck=A(-8),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-14,0,-12),LH=A(24,0,12)),
  K(1.7, RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30))]),
 'Attack':(False,3,[  # shoulder bash
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30)),
  K(0.3, RootJoint=A(4,30,0,0,0,0.3),Neck=A(0,-20,0),RS=A(20,0,-10),LS=A(20,0,20),RH=A(-10),LH=A(14)),
  K(0.42,RootJoint=A(-20,-20,0,0,-0.15,-0.8),Neck=A(-10,10,0),RS=A(30,0,-30),LS=A(30,0,10),RH=A(24),LH=A(-20)),
  K(0.65,RootJoint=A(-16,-12,0,0,-0.1,-0.6),Neck=A(-8,6,0),RS=A(30,0,-20),LS=A(30,0,20),RH=A(18),LH=A(-14)),
  K(0.95,RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30))]),
 'Death':(False,3,[  # drops to the knees, tank pulls him onto the back
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(36,0,-8),LS=A(40,0,30)),
  K(0.4, RootJoint=A(-6,0,0,0,-1.5,0),Neck=A(18),RS=A(20,0,-20),LS=A(20,0,20),RH=A(95),LH=A(90)),
  K(0.8, RootJoint=A(30,0,0,0,-1.6,0.6),Neck=A(-10),RS=A(60,0,-40),LS=A(60,0,40),RH=A(95),LH=A(90)),
  K(1.15,RootJoint=A(84,0,4,0,-2.3,1.6),Neck=A(-14),RS=A(150,0,-50),LS=A(150,0,50),RH=A(40),LH=A(36)),
  K(1.3, RootJoint=A(82,0,4,0,-2.25,1.6),Neck=A(-12),RS=A(148,0,-52),LS=A(148,0,52),RH=A(38),LH=A(34))]),
}
# ---------------- MUTANT: huge, knuckle-walks, leaps ----------------
SETS['Mutant']={
 'Idle':(True,0,[  # hunched, heavy breathing, big arm twitches
  K(0,   RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12),RH=A(14,0,-8),LH=A(10,0,8)),
  K(0.8, RootJoint=A(-26,0,0,0,-0.15,0),Neck=A(20),RS=A(22,0,-16),LS=A(22,0,16),RH=A(16,0,-8),LH=A(12,0,8)),
  K(1.2, RootJoint=A(-24,0,0,0,-0.1,0),Neck=A(10,0,10),RS=A(40,0,-30),LS=A(20,0,14)),
  K(1.35,RootJoint=A(-24,0,0,0,-0.1,0),Neck=A(18,0,-6),RS=A(14,0,-10),LS=A(20,0,14)),
  K(2.0, RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12),RH=A(14,0,-8),LH=A(10,0,8))]),
 'Walk':(True,1,[  # lumbering knuckle walk
  K(0,   RootJoint=A(-30,12,10),Neck=A(22,-10,-8),RS=A(40,0,-14),LS=A(-6,0,14),RH=A(30,0,-6),LH=A(-12,0,6)),
  K(0.4, RootJoint=A(-32,4,4,0,-0.5,0),Neck=A(24,-4,-4),RS=A(20,0,-14),LS=A(10,0,14),RH=A(16,0,-6),LH=A(4,0,6)),
  K(0.8, RootJoint=A(-30,-12,-10),Neck=A(22,10,8),RS=A(-6,0,-14),LS=A(40,0,14),RH=A(-12,0,-6),LH=A(30,0,6)),
  K(1.2, RootJoint=A(-32,-4,-4,0,-0.5,0),Neck=A(24,4,4),RS=A(10,0,-14),LS=A(20,0,14),RH=A(4,0,-6),LH=A(16,0,6)),
  K(1.6, RootJoint=A(-30,12,10),Neck=A(22,-10,-8),RS=A(40,0,-14),LS=A(-6,0,14),RH=A(30,0,-6),LH=A(-12,0,6))]),
 'Throw':(False,4,[  # = LEAP: deep crouch, flies with the arms up, smashes the ground with both fists
  K(0,   RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12)),
  K(0.45,RootJoint=A(-40,0,0,0,-1.2,0),Neck=A(30),RS=A(-30,0,-20),LS=A(-30,0,20),RH=A(80),LH=A(80)),
  K(0.6, RootJoint=A(10,0,0,0,0.2,0),Neck=A(-10),RS=A(170,0,-20),LS=A(170,0,20),RH=A(-20),LH=A(-20)),
  K(1.1, RootJoint=A(0,0,0,0,0,0),Neck=A(0),RS=A(190,0,-14),LS=A(190,0,14),RH=A(30),LH=A(20)),
  K(1.3, RootJoint=A(-50,0,0,0,-1.2,-0.8),Neck=A(-20),RS=A(60,0,-14),LS=A(60,0,14),RH=A(60),LH=A(60)),
  K(1.6, RootJoint=A(-46,0,0,0,-1.1,-0.7),Neck=A(-16),RS=A(56,0,-14),LS=A(56,0,14),RH=A(56),LH=A(56)),
  K(2.0, RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12))]),
 'Attack':(False,3,[  # big arm swipe
  K(0,   RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12)),
  K(0.3, RootJoint=A(-10,-40,0),Neck=A(10,30,0),RS=A(100,0,-80),LS=A(20,0,20),RH=A(-8),LH=A(10)),
  K(0.44,RootJoint=A(-30,40,0,0,-0.2,-0.3),Neck=A(4,-24,0),RS=A(80,0,50),LS=A(14,0,26),RH=A(16),LH=A(-12)),
  K(0.7, RootJoint=A(-26,24,0),Neck=A(8,-12,0),RS=A(60,0,30),LS=A(16,0,20)),
  K(1.0, RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12))]),
 'Death':(False,3,[  # roars at the sky, beats the chest, collapses forward
  K(0,   RootJoint=A(-22),Neck=A(14),RS=A(16,0,-12),LS=A(18,0,12)),
  K(0.4, RootJoint=A(14),Neck=A(-40),RS=A(150,0,-40),LS=A(150,0,40),RH=A(-6),LH=A(6)),
  K(0.6, RootJoint=A(10),Neck=A(-30),RS=A(80,0,30),LS=A(80,0,-30)),
  K(0.75,RootJoint=A(14),Neck=A(-40),RS=A(150,0,-40),LS=A(150,0,40)),
  K(1.1, RootJoint=A(-10,0,0,0,-1.4,0),Neck=A(20),RS=A(40,0,-20),LS=A(40,0,20),RH=A(90),LH=A(90)),
  K(1.45,RootJoint=A(-88,0,0,0,-2.6,-1.5),Neck=A(26,0,20),RS=A(160,0,-30),LS=A(160,0,30),RH=A(20),LH=A(16)),
  K(1.6, RootJoint=A(-86,0,0,0,-2.55,-1.5),Neck=A(24,0,22),RS=A(158,0,-32),LS=A(158,0,32),RH=A(18),LH=A(14))]),
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
out=os.environ.get('OUT','/home/claude/mobs7/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z7_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
