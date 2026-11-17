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
# ---------------- LAB ASSISTANT: nervous, twitchy, clipboard + syringe ----------------
SETS['LabAssistant']={
 'Idle':(True,0,[  # reads the clipboard, scribbles, glances around
  K(0,   RootJoint=A(-6),Neck=A(14),RS=A(40,0,-14),LS=A(60,0,30),RH=A(0,0,-3),LH=A(0,0,3)),
  K(0.4, RootJoint=A(-6),Neck=A(16),RS=A(50,0,-6),LS=A(60,0,30)),
  K(0.55,RootJoint=A(-6),Neck=A(16),RS=A(46,0,-10),LS=A(60,0,30)),
  K(0.7, RootJoint=A(-6),Neck=A(16),RS=A(50,0,-6),LS=A(60,0,30)),
  K(1.3, RootJoint=A(-4,10,0),Neck=A(-4,30,0),RS=A(30,0,-14),LS=A(50,0,26)),
  K(1.6, RootJoint=A(-4,-8,0),Neck=A(-4,-30,0),RS=A(30,0,-14),LS=A(50,0,26)),
  K(2.2, RootJoint=A(-6),Neck=A(14),RS=A(40,0,-14),LS=A(60,0,30),RH=A(0,0,-3),LH=A(0,0,3))]),
 'Walk':(True,1,[  # quick hunched shuffle, syringe raised
  K(0,   RootJoint=A(-14,6,0),Neck=A(6,-6,0),RS=A(70,0,-10),LS=A(30,0,20),RH=A(30),LH=A(-26)),
  K(0.22,RootJoint=A(-16,0,0,0,-0.2,0),Neck=A(8),RS=A(66,0,-10),LS=A(36,0,20),RH=A(4),LH=A(4)),
  K(0.44,RootJoint=A(-14,-6,0),Neck=A(6,6,0),RS=A(70,0,-10),LS=A(30,0,20),RH=A(-26),LH=A(30)),
  K(0.66,RootJoint=A(-16,0,0,0,-0.2,0),Neck=A(8),RS=A(66,0,-10),LS=A(36,0,20),RH=A(4),LH=A(4)),
  K(0.88,RootJoint=A(-14,6,0),Neck=A(6,-6,0),RS=A(70,0,-10),LS=A(30,0,20),RH=A(30),LH=A(-26))]),
 'Attack':(False,3,[  # overhead syringe stab
  K(0,   RootJoint=A(-6),Neck=A(10),RS=A(60,0,-10),LS=A(40,0,20)),
  K(0.18,RootJoint=A(6,10,0),Neck=A(-6),RS=A(170,0,-20),LS=A(30,0,30),RH=A(-6),LH=A(6)),
  K(0.3, RootJoint=A(-26,-10,0,0,-0.1,-0.4),Neck=A(10),RS=A(60,0,10),LS=A(20,0,20),RH=A(16),LH=A(-12)),
  K(0.5, RootJoint=A(-18,-6,0,0,-0.05,-0.3),Neck=A(8),RS=A(50,0,0),LS=A(30,0,20)),
  K(0.7, RootJoint=A(-6),Neck=A(10),RS=A(60,0,-10),LS=A(40,0,20))]),
 'Death':(False,3,[  # drops the clipboard, clutches the chest, spins and falls
  K(0,   RootJoint=A(-6),Neck=A(10),RS=A(60,0,-10),LS=A(40,0,20)),
  K(0.3, RootJoint=A(10,30,0),Neck=A(-20),RS=A(80,0,40),LS=A(80,0,-40),RH=A(-10),LH=A(10)),
  K(0.6, RootJoint=A(10,90,-20,0,-0.6,0.2),Neck=A(-10),RS=A(100,0,30),LS=A(100,0,-30),RH=A(30),LH=A(10)),
  K(0.95,RootJoint=A(-84,120,0,0,-2.5,-1.4),Neck=A(20,0,20),RS=A(160,0,-20),LS=A(150,0,40),RH=A(20),LH=A(16)),
  K(1.1, RootJoint=A(-82,120,0,0,-2.45,-1.4),Neck=A(18,0,22),RS=A(158,0,-22),LS=A(148,0,42),RH=A(18),LH=A(14))]),
}
# ---------------- CYBORG: mechanical, stiff, arm cannon ----------------
SETS['Cyborg']={
 'Idle':(True,0,[  # scanning: head turns in steps, cannon arm twitches, servo jerks
  K(0,   RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8),RH=A(0,0,-4),LH=A(0,0,4)),
  K(0.5, RootJoint=A(-2),Neck=A(0,25,0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(0.7, RootJoint=A(-2),Neck=A(0,25,0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(1.2, RootJoint=A(-2),Neck=A(0,-25,0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(1.4, RootJoint=A(-2),Neck=A(0,-25,0),RS=A(50,0,-8),LS=A(6,0,8)),
  K(1.6, RootJoint=A(-2),Neck=A(0,-25,0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(2.2, RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8),RH=A(0,0,-4),LH=A(0,0,4))]),
 'Walk':(True,1,[  # heavy uneven march: metal leg stomps, flesh leg drags
  K(0,   RootJoint=A(-6,0,6),Neck=A(-2,0,-4),RS=A(40,0,-8),LS=A(-20,0,8),RH=A(30,0,-3),LH=A(-14,0,3)),
  K(0.35,RootJoint=A(-8,0,0,0,-0.3,0),Neck=A(-2),RS=A(34,0,-8),LS=A(4,0,8),RH=A(4),LH=A(2)),
  K(0.7, RootJoint=A(-6,0,-4),Neck=A(-2,0,4),RS=A(30,0,-8),LS=A(20,0,8),RH=A(-20,0,-3),LH=A(16,0,3)),
  K(1.05,RootJoint=A(-8,0,0,0,-0.15,0),Neck=A(-2),RS=A(34,0,-8),LS=A(4,0,8),RH=A(2),LH=A(4)),
  K(1.4, RootJoint=A(-6,0,6),Neck=A(-2,0,-4),RS=A(40,0,-8),LS=A(-20,0,8),RH=A(30,0,-3),LH=A(-14,0,3))]),
 'Throw':(False,4,[  # = LASER: braces with the left hand on the arm, cannon aimed, recoil per shot
  K(0,   RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(0.4, RootJoint=A(-4,-14,0),Neck=A(0,10,0),RS=A(90,0,0),LS=A(80,0,50),RH=A(-6,0,-6),LH=A(10,0,6)),
  K(0.6, RootJoint=A(-4,-14,0),Neck=A(0,10,0),RS=A(90,0,0),LS=A(80,0,50)),
  K(0.66,RootJoint=A(0,-14,0,0,0,0.1),Neck=A(2,10,0),RS=A(100,0,0),LS=A(88,0,50)),
  K(0.76,RootJoint=A(-4,-14,0),Neck=A(0,10,0),RS=A(90,0,0),LS=A(80,0,50)),
  K(0.82,RootJoint=A(0,-14,0,0,0,0.1),Neck=A(2,10,0),RS=A(100,0,0),LS=A(88,0,50)),
  K(0.92,RootJoint=A(-4,-14,0),Neck=A(0,10,0),RS=A(90,0,0),LS=A(80,0,50)),
  K(0.98,RootJoint=A(0,-14,0,0,0,0.1),Neck=A(2,10,0),RS=A(100,0,0),LS=A(88,0,50)),
  K(1.08,RootJoint=A(-4,-14,0),Neck=A(0,10,0),RS=A(90,0,0),LS=A(80,0,50)),
  K(1.4, RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8))]),
 'Attack':(False,3,[  # backhand swing with the heavy cannon arm
  K(0,   RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(0.28,RootJoint=A(0,-30,0),Neck=A(0,24,0),RS=A(90,0,60),LS=A(20,0,20),RH=A(-6),LH=A(8)),
  K(0.4, RootJoint=A(-14,30,0,0,-0.1,-0.3),Neck=A(-4,-20,0),RS=A(90,0,-60),LS=A(10,0,20),RH=A(12),LH=A(-10)),
  K(0.65,RootJoint=A(-8,16,0),Neck=A(-2,-10,0),RS=A(60,0,-40),LS=A(10,0,14)),
  K(0.9, RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8))]),
 'Death':(False,3,[  # sparks, systems fail: jerks, locks up, falls stiff forward
  K(0,   RootJoint=A(-2),Neck=A(0),RS=A(30,0,-8),LS=A(6,0,8)),
  K(0.15,RootJoint=A(4,10,0),Neck=A(20,30,0),RS=A(60,0,-30),LS=A(20,0,40)),
  K(0.3, RootJoint=A(-4,-10,0),Neck=A(-20,-30,0),RS=A(10,0,20),LS=A(50,0,-10)),
  K(0.45,RootJoint=A(4,10,0),Neck=A(30,10,0),RS=A(80,0,-20),LS=A(10,0,30)),
  K(1.0, RootJoint=A(-88,0,0,0,-2.6,-1.6),Neck=A(30),RS=A(80,0,-20),LS=A(10,0,30),RH=A(0),LH=A(0)),
  K(1.15,RootJoint=A(-86,0,0,0,-2.55,-1.6),Neck=A(28),RS=A(78,0,-22),LS=A(10,0,32),RH=A(0),LH=A(0))]),
}
# ---------------- EXPERIMENT: huge, unstable, chest beam ----------------
SETS['Experiment']={
 'Idle':(True,0,[  # pained breathing, the restrained arm strains against its braces, head twitches
  K(0,   RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14),RH=A(6,0,-6),LH=A(6,0,6)),
  K(0.8, RootJoint=A(-14,0,0,0,-0.12,0),Neck=A(16,0,8),RS=A(20,0,-20),LS=A(12,0,14)),
  K(1.1, RootJoint=A(-12),Neck=A(4,0,-12),RS=A(40,0,-30),LS=A(12,0,14)),
  K(1.25,RootJoint=A(-12),Neck=A(14,0,10),RS=A(30,0,-26),LS=A(12,0,14)),
  K(2.0, RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14),RH=A(6,0,-6),LH=A(6,0,6))]),
 'Walk':(True,1,[  # lurching heavy steps, big arm swings low
  K(0,   RootJoint=A(-16,10,8),Neck=A(10,-8,-6),RS=A(36,0,-16),LS=A(-14,0,14),RH=A(30,0,-6),LH=A(-18,0,6)),
  K(0.45,RootJoint=A(-18,0,0,0,-0.4,0),Neck=A(14),RS=A(16,0,-16),LS=A(8,0,14),RH=A(4,0,-6),LH=A(4,0,6)),
  K(0.9, RootJoint=A(-16,-10,-8),Neck=A(10,8,6),RS=A(-10,0,-16),LS=A(30,0,14),RH=A(-18,0,-6),LH=A(30,0,6)),
  K(1.35,RootJoint=A(-18,0,0,0,-0.4,0),Neck=A(14),RS=A(16,0,-16),LS=A(8,0,14),RH=A(4,0,-6),LH=A(4,0,6)),
  K(1.8, RootJoint=A(-16,10,8),Neck=A(10,-8,-6),RS=A(36,0,-16),LS=A(-14,0,14),RH=A(30,0,-6),LH=A(-18,0,6))]),
 'Throw':(False,4,[  # = BEAM: rears back, arms wide, chest thrust out while the beam sweeps, then sags
  K(0,   RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14)),
  K(0.6, RootJoint=A(14,0,0,0,0.2,0.3),Neck=A(-34),RS=A(60,0,-90),LS=A(60,0,90),RH=A(-10,0,-8),LH=A(-10,0,8)),
  K(0.9, RootJoint=A(10,-25,0,0,0.15,0.2),Neck=A(-20,10,0),RS=A(50,0,-100),LS=A(50,0,100),RH=A(-6,0,-8),LH=A(-6,0,8)),
  K(1.5, RootJoint=A(10,25,0,0,0.15,0.2),Neck=A(-20,-10,0),RS=A(50,0,-100),LS=A(50,0,100),RH=A(-6,0,-8),LH=A(-6,0,8)),
  K(1.9, RootJoint=A(-20,0,0,0,-0.2,0),Neck=A(20),RS=A(20,0,-20),LS=A(20,0,20)),
  K(2.3, RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14))]),
 'Attack':(False,3,[  # hammer blow with the braced arm
  K(0,   RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14)),
  K(0.32,RootJoint=A(6,-10,0,0,0,0.2),Neck=A(-10),RS=A(180,0,-10),LS=A(30,0,30),RH=A(-6),LH=A(8)),
  K(0.46,RootJoint=A(-34,10,0,0,-0.3,-0.5),Neck=A(14),RS=A(50,0,0),LS=A(20,0,20),RH=A(20),LH=A(-14)),
  K(0.75,RootJoint=A(-26,6,0,0,-0.2,-0.4),Neck=A(12),RS=A(40,0,-6),LS=A(16,0,16)),
  K(1.05,RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14))]),
 'Death':(False,3,[  # the core overloads: convulses, kneels, falls onto the back
  K(0,   RootJoint=A(-12),Neck=A(10),RS=A(14,0,-14),LS=A(10,0,14)),
  K(0.3, RootJoint=A(16),Neck=A(-40),RS=A(70,0,-90),LS=A(70,0,90),RH=A(-6),LH=A(6)),
  K(0.5, RootJoint=A(6),Neck=A(-20,0,20),RS=A(40,0,-60),LS=A(90,0,60)),
  K(0.7, RootJoint=A(16),Neck=A(-40,0,-20),RS=A(80,0,-70),LS=A(60,0,80)),
  K(1.1, RootJoint=A(-6,0,0,0,-1.6,0),Neck=A(24),RS=A(20,0,-30),LS=A(20,0,30),RH=A(95),LH=A(95)),
  K(1.6, RootJoint=A(82,0,-6,0,-2.8,1.5),Neck=A(-10),RS=A(160,0,-40),LS=A(160,0,40),RH=A(50),LH=A(50)),
  K(1.75,RootJoint=A(80,0,-6,0,-2.75,1.5),Neck=A(-8),RS=A(158,0,-42),LS=A(158,0,42),RH=A(48),LH=A(48))]),
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
out=os.environ.get('OUT','/home/claude/mobs10/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z10_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
