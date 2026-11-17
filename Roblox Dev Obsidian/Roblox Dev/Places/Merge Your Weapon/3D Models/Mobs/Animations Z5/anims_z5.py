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
# ---------------- SOLDIER: rifle at the ready, zombie march, rifle-butt strike ----------------
SETS['Soldier']={
 'Idle':(True,0,[  # rifle at port arms, sways, head twitches
  K(0,   RootJoint=A(-6),Neck=A(-6,0,0),RS=A(40,0,-8),LS=A(58,0,34),RH=A(0,0,-3),LH=A(0,0,3)),
  K(0.7, RootJoint=A(-8,4,0,0,-0.05,0),Neck=A(-2,10,6),RS=A(42,0,-8),LS=A(60,0,34)),
  K(1.1, RootJoint=A(-8,4,0,0,-0.05,0),Neck=A(-14,-14,-10),RS=A(42,0,-8),LS=A(60,0,34)),
  K(1.25,RootJoint=A(-8,4,0,0,-0.05,0),Neck=A(-10,6,4),RS=A(42,0,-8),LS=A(60,0,34)),
  K(2.0, RootJoint=A(-6),Neck=A(-6,0,0),RS=A(40,0,-8),LS=A(58,0,34),RH=A(0,0,-3),LH=A(0,0,3))]),
 'Walk':(True,1,[  # lurching march, rifle bobs at the chest
  K(0,   RootJoint=A(-12,8,4),Neck=A(-2,-8,-6),RS=A(46,0,-8),LS=A(62,0,34),RH=A(30),LH=A(-26)),
  K(0.25,RootJoint=A(-14,0,0,0,-0.3,0),Neck=A(-6,0,0),RS=A(38,0,-8),LS=A(56,0,34),RH=A(6),LH=A(4)),
  K(0.5, RootJoint=A(-12,-8,-4),Neck=A(-2,8,6),RS=A(46,0,-8),LS=A(62,0,34),RH=A(-26),LH=A(30)),
  K(0.75,RootJoint=A(-14,0,0,0,-0.3,0),Neck=A(-6,0,0),RS=A(38,0,-8),LS=A(56,0,34),RH=A(4),LH=A(6)),
  K(1.0, RootJoint=A(-12,8,4),Neck=A(-2,-8,-6),RS=A(46,0,-8),LS=A(62,0,34),RH=A(30),LH=A(-26))]),
 'Attack':(False,3,[  # pulls the rifle back over the shoulder, smashes the butt forward
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-8),LS=A(58,0,34)),
  K(0.3, RootJoint=A(4,-28,0,0,0,0.2),Neck=A(-4,22,0),RS=A(150,0,-40),LS=A(130,0,40),RH=A(-10),LH=A(14)),
  K(0.42,RootJoint=A(-24,26,0,0,-0.15,-0.45),Neck=A(-14,-18,0),RS=A(70,0,20),LS=A(80,0,50),RH=A(22),LH=A(-18)),
  K(0.62,RootJoint=A(-20,20,0,0,-0.1,-0.35),Neck=A(-10,-14,0),RS=A(60,0,16),LS=A(72,0,46),RH=A(18),LH=A(-14)),
  K(0.9, RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-8),LS=A(58,0,34))]),
 'Death':(False,3,[  # shot back: arms fly up, falls on the back
  K(0,   RootJoint=A(-6),Neck=A(-6),RS=A(40,0,-8),LS=A(58,0,34)),
  K(0.2, RootJoint=A(14,0,0,0,0,0.3),Neck=A(24),RS=A(120,0,-30),LS=A(110,0,30),RH=A(-14),LH=A(6)),
  K(0.45,RootJoint=A(30,0,6,0,-0.6,0.8),Neck=A(20),RS=A(150,0,-50),LS=A(140,0,50),RH=A(-30),LH=A(-10)),
  K(0.8, RootJoint=A(86,0,6,0,-2.3,1.6),Neck=A(-14,10,0),RS=A(170,0,-60),LS=A(160,0,60),RH=A(-14),LH=A(-24)),
  K(1.0, RootJoint=A(84,0,6,0,-2.25,1.6),Neck=A(-12,12,0),RS=A(168,0,-62),LS=A(158,0,62),RH=A(-12),LH=A(-22))]),
}
# ---------------- MACHINE GUNNER: heavy, gun at the hip, braced burst ----------------
SETS['Gunner']={
 'Idle':(True,0,[  # gun at the hip, scans left and right
  K(0,   RootJoint=A(-8),Neck=A(-4,0,0),RS=A(26,0,-6),LS=A(48,0,40),RH=A(4,0,-6),LH=A(-4,0,6)),
  K(1.0, RootJoint=A(-8,-18,0),Neck=A(-6,-16,0),RS=A(28,0,-6),LS=A(50,0,40),RH=A(4,0,-6),LH=A(-4,0,6)),
  K(2.0, RootJoint=A(-8,18,0),Neck=A(-6,16,0),RS=A(28,0,-6),LS=A(50,0,40),RH=A(4,0,-6),LH=A(-4,0,6)),
  K(3.0, RootJoint=A(-8),Neck=A(-4,0,0),RS=A(26,0,-6),LS=A(48,0,40),RH=A(4,0,-6),LH=A(-4,0,6))]),
 'Walk':(True,1,[  # heavy waddle, wide legs
  K(0,   RootJoint=A(-10,6,8),Neck=A(-4,-6,-8),RS=A(30,0,-6),LS=A(52,0,40),RH=A(22,0,-8),LH=A(-18,0,8)),
  K(0.35,RootJoint=A(-12,0,0,0,-0.35,0),Neck=A(-6),RS=A(24,0,-6),LS=A(46,0,40),RH=A(4,0,-8),LH=A(4,0,8)),
  K(0.7, RootJoint=A(-10,-6,-8),Neck=A(-4,6,8),RS=A(30,0,-6),LS=A(52,0,40),RH=A(-18,0,-8),LH=A(22,0,8)),
  K(1.05,RootJoint=A(-12,0,0,0,-0.35,0),Neck=A(-6),RS=A(24,0,-6),LS=A(46,0,40),RH=A(4,0,-8),LH=A(4,0,8)),
  K(1.4, RootJoint=A(-10,6,8),Neck=A(-4,-6,-8),RS=A(30,0,-6),LS=A(52,0,40),RH=A(22,0,-8),LH=A(-18,0,8))]),
 'Throw':(False,4,[  # = FIRE: braces (wide stance, gun level), then a shaking burst
  K(0,   RootJoint=A(-8),Neck=A(-4),RS=A(26,0,-6),LS=A(48,0,40)),
  K(0.35,RootJoint=A(-16,0,0,0,-0.3,0),Neck=A(-10),RS=A(78,0,-4),LS=A(86,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(0.45,RootJoint=A(-14,2,0,0,-0.3,0.1),Neck=A(-8),RS=A(84,0,-4),LS=A(90,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(0.55,RootJoint=A(-16,-2,0,0,-0.3,0),Neck=A(-10),RS=A(78,0,-4),LS=A(86,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(0.65,RootJoint=A(-14,2,0,0,-0.3,0.1),Neck=A(-8),RS=A(84,0,-4),LS=A(90,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(0.75,RootJoint=A(-16,-2,0,0,-0.3,0),Neck=A(-10),RS=A(78,0,-4),LS=A(86,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(0.85,RootJoint=A(-14,2,0,0,-0.3,0.1),Neck=A(-8),RS=A(84,0,-4),LS=A(90,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(0.95,RootJoint=A(-16,-2,0,0,-0.3,0),Neck=A(-10),RS=A(78,0,-4),LS=A(86,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(1.05,RootJoint=A(-14,2,0,0,-0.3,0.1),Neck=A(-8),RS=A(84,0,-4),LS=A(90,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(1.15,RootJoint=A(-16,-2,0,0,-0.3,0),Neck=A(-10),RS=A(78,0,-4),LS=A(86,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(1.25,RootJoint=A(-14,2,0,0,-0.3,0.1),Neck=A(-8),RS=A(84,0,-4),LS=A(90,0,38),RH=A(-14,0,-14),LH=A(24,0,14)),
  K(1.6, RootJoint=A(-8),Neck=A(-4),RS=A(26,0,-6),LS=A(48,0,40))]),
 'Attack':(False,3,[  # close: swings the whole gun sideways
  K(0,   RootJoint=A(-8),Neck=A(-4),RS=A(26,0,-6),LS=A(48,0,40)),
  K(0.32,RootJoint=A(-4,40,0),Neck=A(-2,-30,0),RS=A(70,0,40),LS=A(80,0,60),RH=A(-8),LH=A(10)),
  K(0.46,RootJoint=A(-18,-36,0,0,-0.15,-0.2),Neck=A(-10,26,0),RS=A(80,0,-60),LS=A(70,0,10),RH=A(12),LH=A(-12)),
  K(0.7, RootJoint=A(-14,-24,0),Neck=A(-8,18,0),RS=A(60,0,-40),LS=A(60,0,20)),
  K(1.0, RootJoint=A(-8),Neck=A(-4),RS=A(26,0,-6),LS=A(48,0,40))]),
 'Death':(False,3,[  # drops to the knees, the gun drags him forward onto the face
  K(0,   RootJoint=A(-8),Neck=A(-4),RS=A(26,0,-6),LS=A(48,0,40)),
  K(0.4, RootJoint=A(-10,0,0,0,-1.5,0),Neck=A(16),RS=A(30,0,-10),LS=A(40,0,30),RH=A(95),LH=A(90)),
  K(0.75,RootJoint=A(-16,0,0,0,-1.55,-0.1),Neck=A(24),RS=A(20,0,-10),LS=A(30,0,30),RH=A(95),LH=A(90)),
  K(1.1, RootJoint=A(-86,0,0,0,-2.6,-1.5),Neck=A(26,0,20),RS=A(150,0,-30),LS=A(150,0,30),RH=A(30),LH=A(26)),
  K(1.3, RootJoint=A(-84,0,0,0,-2.55,-1.5),Neck=A(24,0,22),RS=A(148,0,-32),LS=A(148,0,32),RH=A(28),LH=A(24))]),
}
# ---------------- COMMANDER: proud, stiff, orders + grenades ----------------
SETS['Commander']={
 'Idle':(True,0,[  # chest out, left hand behind the back, taps the grenade, points forward
  K(0,   RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20),RH=A(0,0,-4),LH=A(0,0,4)),
  K(0.8, RootJoint=A(4,-6,0),Neck=A(8,8,0),RS=A(22,0,-10),LS=A(-30,0,-20)),
  K(1.4, RootJoint=A(2,10,0),Neck=A(2,-6,0),RS=A(14,0,-6),LS=A(110,-10,6)),
  K(1.9, RootJoint=A(2,10,0),Neck=A(0,-8,0),RS=A(14,0,-6),LS=A(104,-10,6)),
  K(2.6, RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20),RH=A(0,0,-4),LH=A(0,0,4))]),
 'Walk':(True,1,[  # stiff parade march, high knees, chest up
  K(0,   RootJoint=A(2,6,0),Neck=A(6,-6,0),RS=A(30,0,-6),LS=A(-30,0,6),RH=A(-24),LH=A(36)),
  K(0.3, RootJoint=A(2,0,0,0,0.2,0),Neck=A(6),RS=A(10,0,-6),LS=A(-10,0,6),RH=A(0),LH=A(50)),
  K(0.6, RootJoint=A(2,-6,0),Neck=A(6,6,0),RS=A(-30,0,-6),LS=A(30,0,6),RH=A(36),LH=A(-24)),
  K(0.9, RootJoint=A(2,0,0,0,0.2,0),Neck=A(6),RS=A(-10,0,-6),LS=A(10,0,6),RH=A(50),LH=A(0)),
  K(1.2, RootJoint=A(2,6,0),Neck=A(6,-6,0),RS=A(30,0,-6),LS=A(-30,0,6),RH=A(-24),LH=A(36))]),
 'Throw':(False,4,[  # pulls the pin with the left hand, big overhand lob
  K(0,   RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20)),
  K(0.2, RootJoint=A(0),Neck=A(-6),RS=A(70,0,-20),LS=A(80,0,40)),
  K(0.32,RootJoint=A(0),Neck=A(-6),RS=A(70,0,-20),LS=A(60,0,10)),
  K(0.55,RootJoint=A(14,-26,0,0,0,0.3),Neck=A(-8,22,0),RS=A(195,-10,-24),LS=A(70,0,30),RH=A(-14),LH=A(22)),
  K(0.7, RootJoint=A(-24,22,0,0,-0.2,-0.5),Neck=A(-12,-18,0),RS=A(90,0,10),LS=A(-10,0,24),RH=A(24),LH=A(-20)),
  K(0.95,RootJoint=A(-14,14,0,0,-0.1,-0.3),Neck=A(-6,-10,0),RS=A(40,0,6),LS=A(-14,0,20),RH=A(14),LH=A(-12)),
  K(1.25,RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20))]),
 'Attack':(False,3,[  # close: backhand slap with the left hand + boot stomp
  K(0,   RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20)),
  K(0.28,RootJoint=A(0,-30,0),Neck=A(0,24,0),RS=A(20,0,-10),LS=A(100,0,-70),RH=A(-8),LH=A(30)),
  K(0.4, RootJoint=A(-16,30,0,0,-0.15,-0.25),Neck=A(-8,-20,0),RS=A(20,0,-10),LS=A(90,0,50),RH=A(12),LH=A(-10)),
  K(0.6, RootJoint=A(-10,18,0),Neck=A(-4,-10,0),RS=A(16,0,-10),LS=A(60,0,30)),
  K(0.9, RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20))]),
 'Death':(False,3,[  # a last salute, then falls stiff backwards like a plank
  K(0,   RootJoint=A(4),Neck=A(6),RS=A(14,0,-6),LS=A(-30,0,-20)),
  K(0.3, RootJoint=A(6),Neck=A(10),RS=A(150,0,-60),LS=A(0,0,0),RH=A(0),LH=A(0)),
  K(0.75,RootJoint=A(8),Neck=A(10),RS=A(150,0,-60),LS=A(0,0,0)),
  K(1.2, RootJoint=A(88,0,0,0,-2.4,1.7),Neck=A(4),RS=A(150,0,-60),LS=A(0,0,0),RH=A(0),LH=A(0)),
  K(1.35,RootJoint=A(84,0,0,0,-2.3,1.6),Neck=A(-6),RS=A(120,0,-50),LS=A(10,0,10),RH=A(-6),LH=A(-4))]),
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
out=os.environ.get('OUT','/home/claude/mobs5/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z5_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
