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
# ---------------- WORKER: tired, coughing, big wrench ----------------
SETS['Worker']={
 'Idle':(True,0,[  # slumped, taps the wrench into the palm, coughs
  K(0,   RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20),RH=A(2,0,-3),LH=A(-2,0,3)),
  K(0.4, RootJoint=A(-12),Neck=A(-10),RS=A(50,0,10),LS=A(40,0,30)),
  K(0.6, RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20)),
  K(1.0, RootJoint=A(-12),Neck=A(-10),RS=A(50,0,10),LS=A(40,0,30)),
  K(1.2, RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20)),
  K(1.6, RootJoint=A(-22,0,0,0,-0.1,0),Neck=A(-24),RS=A(30,0,-10),LS=A(70,0,40)),
  K(1.75,RootJoint=A(-8),Neck=A(6),RS=A(36,0,-10),LS=A(60,0,40)),
  K(1.9, RootJoint=A(-22,0,0,0,-0.1,0),Neck=A(-24),RS=A(30,0,-10),LS=A(70,0,40)),
  K(2.4, RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20),RH=A(2,0,-3),LH=A(-2,0,3))]),
 'Walk':(True,1,[  # tired shuffle, wrench drags
  K(0,   RootJoint=A(-14,6,3),Neck=A(-10,-6,0),RS=A(16,0,-8),LS=A(-20,0,8),RH=A(24),LH=A(-18)),
  K(0.32,RootJoint=A(-16,0,0,0,-0.22,0),Neck=A(-12),RS=A(6,0,-8),LS=A(0,0,8),RH=A(4),LH=A(2)),
  K(0.64,RootJoint=A(-14,-6,-3),Neck=A(-10,6,0),RS=A(-8,0,-8),LS=A(22,0,8),RH=A(-18),LH=A(24)),
  K(0.96,RootJoint=A(-16,0,0,0,-0.22,0),Neck=A(-12),RS=A(6,0,-8),LS=A(0,0,8),RH=A(2),LH=A(4)),
  K(1.28,RootJoint=A(-14,6,3),Neck=A(-10,-6,0),RS=A(16,0,-8),LS=A(-20,0,8),RH=A(24),LH=A(-18))]),
 'Attack':(False,3,[  # big overhead wrench whack
  K(0,   RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20)),
  K(0.3, RootJoint=A(8,-10,0),Neck=A(4,10,0),RS=A(175,0,-14),LS=A(60,0,20),RH=A(-8),LH=A(10)),
  K(0.42,RootJoint=A(-30,10,0,0,-0.2,-0.4),Neck=A(-16,-6,0),RS=A(40,0,-4),LS=A(20,0,20),RH=A(20),LH=A(-16)),
  K(0.62,RootJoint=A(-26,6,0,0,-0.15,-0.3),Neck=A(-14),RS=A(30,0,-4),LS=A(20,0,20),RH=A(16),LH=A(-12)),
  K(0.9, RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20))]),
 'Death':(False,3,[  # clutches the chest, coughs, keels over sideways
  K(0,   RootJoint=A(-12),Neck=A(-10),RS=A(34,0,-10),LS=A(30,0,20)),
  K(0.3, RootJoint=A(-24,0,0,0,-0.2,0),Neck=A(-26),RS=A(60,0,40),LS=A(70,0,40),RH=A(10),LH=A(-6)),
  K(0.5, RootJoint=A(-14),Neck=A(4),RS=A(60,0,40),LS=A(70,0,40)),
  K(0.7, RootJoint=A(-28,0,0,0,-0.3,0),Neck=A(-30),RS=A(60,0,40),LS=A(70,0,40),RH=A(20),LH=A(10)),
  K(1.15,RootJoint=A(-20,0,-85,1.6,-2.2,0),Neck=A(-20,0,-10),RS=A(90,0,30),LS=A(60,0,40),RH=A(30),LH=A(10)),
  K(1.3, RootJoint=A(-18,0,-83,1.55,-2.15,0),Neck=A(-18,0,-10),RS=A(88,0,30),LS=A(58,0,40),RH=A(28),LH=A(10))]),
}
# ---------------- CHEMIST: twitchy, hunched, shakes the flask ----------------
SETS['Chemist']={
 'Idle':(True,0,[  # holds the flask up, shakes it, tilts the head, giggles
  K(0,   RootJoint=A(-10),Neck=A(-6,0,0),RS=A(80,0,-14),LS=A(20,0,10),RH=A(0,0,-3),LH=A(0,0,3)),
  K(0.15,RootJoint=A(-10),Neck=A(-6,0,12),RS=A(86,6,-18),LS=A(20,0,10)),
  K(0.3, RootJoint=A(-10),Neck=A(-6,0,12),RS=A(76,-6,-10),LS=A(20,0,10)),
  K(0.45,RootJoint=A(-10),Neck=A(-6,0,12),RS=A(86,6,-18),LS=A(20,0,10)),
  K(0.6, RootJoint=A(-10),Neck=A(-6,0,-6),RS=A(80,0,-14),LS=A(20,0,10)),
  K(1.2, RootJoint=A(-14,0,0,0,-0.08,0),Neck=A(-14,0,-14),RS=A(70,0,-14),LS=A(30,0,20)),
  K(1.35,RootJoint=A(-6,0,0),Neck=A(4,0,-10),RS=A(74,0,-14),LS=A(26,0,20)),
  K(1.5, RootJoint=A(-14,0,0,0,-0.08,0),Neck=A(-14,0,-14),RS=A(70,0,-14),LS=A(30,0,20)),
  K(2.2, RootJoint=A(-10),Neck=A(-6,0,0),RS=A(80,0,-14),LS=A(20,0,10),RH=A(0,0,-3),LH=A(0,0,3))]),
 'Walk':(True,1,[  # quick hunched scurry, flask held high, free arm flaps
  K(0,   RootJoint=A(-26,8,0),Neck=A(14,-8,0),RS=A(100,0,-10),LS=A(40,0,30),RH=A(-34),LH=A(36)),
  K(0.18,RootJoint=A(-28,0,0,0,-0.3,0),Neck=A(16),RS=A(96,0,-10),LS=A(10,0,40),RH=A(0),LH=A(10)),
  K(0.36,RootJoint=A(-26,-8,0),Neck=A(14,8,0),RS=A(100,0,-10),LS=A(-10,0,30),RH=A(36),LH=A(-34)),
  K(0.54,RootJoint=A(-28,0,0,0,-0.3,0),Neck=A(16),RS=A(96,0,-10),LS=A(10,0,40),RH=A(10),LH=A(0)),
  K(0.72,RootJoint=A(-26,8,0),Neck=A(14,-8,0),RS=A(100,0,-10),LS=A(40,0,30),RH=A(-34),LH=A(36))]),
 'Throw':(False,4,[  # wind-up behind the back, sidearm flick toss
  K(0,   RootJoint=A(-10),Neck=A(-6),RS=A(80,0,-14),LS=A(20,0,10)),
  K(0.35,RootJoint=A(0,-34,0,0,0,0.2),Neck=A(-4,28,0),RS=A(40,0,-80),LS=A(50,0,40),RH=A(-10),LH=A(16)),
  K(0.5, RootJoint=A(-20,30,0,0,-0.15,-0.4),Neck=A(-10,-20,0),RS=A(110,0,30),LS=A(20,0,20),RH=A(20),LH=A(-16)),
  K(0.7, RootJoint=A(-14,20,0,0,-0.1,-0.3),Neck=A(-8,-12,0),RS=A(90,0,20),LS=A(20,0,20),RH=A(14),LH=A(-10)),
  K(1.0, RootJoint=A(-10),Neck=A(-6),RS=A(80,0,-14),LS=A(20,0,10))]),
 'Attack':(False,3,[  # close: jabs with the flask and slaps
  K(0,   RootJoint=A(-10),Neck=A(-6),RS=A(80,0,-14),LS=A(20,0,10)),
  K(0.22,RootJoint=A(-4,24,0),Neck=A(0,-18,0),RS=A(80,0,-14),LS=A(100,0,-60),RH=A(-6),LH=A(8)),
  K(0.34,RootJoint=A(-18,-26,0,0,-0.1,-0.25),Neck=A(-8,18,0),RS=A(80,0,-14),LS=A(80,0,40),RH=A(12),LH=A(-10)),
  K(0.55,RootJoint=A(-14,-14,0),Neck=A(-6,8,0),RS=A(80,0,-14),LS=A(50,0,30)),
  K(0.8, RootJoint=A(-10),Neck=A(-6),RS=A(80,0,-14),LS=A(20,0,10))]),
 'Death':(False,3,[  # spins half around, arms fly out, falls on the back
  K(0,   RootJoint=A(-10),Neck=A(-6),RS=A(80,0,-14),LS=A(20,0,10)),
  K(0.3, RootJoint=A(0,90,0,0,0.1,0),Neck=A(10,0,0),RS=A(100,0,-70),LS=A(100,0,70),RH=A(-10),LH=A(10)),
  K(0.55,RootJoint=A(20,160,0,0,-0.4,0.4),Neck=A(20),RS=A(130,0,-80),LS=A(130,0,80),RH=A(-20),LH=A(-10)),
  K(0.95,RootJoint=A(86,180,0,0,-2.3,1.6),Neck=A(-10),RS=A(160,0,-70),LS=A(160,0,70),RH=A(-20),LH=A(-30)),
  K(1.1, RootJoint=A(84,180,0,0,-2.25,1.6),Neck=A(-8),RS=A(158,0,-72),LS=A(158,0,72),RH=A(-18),LH=A(-28))]),
}
# ---------------- HAZMAT: heavy suit, slow, sprays toxic gas ----------------
SETS['Hazmat']={
 'Idle':(True,0,[  # heavy breathing in the suit, sprayer pointing down, shifts weight
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34),RH=A(2,0,-5),LH=A(-2,0,5)),
  K(0.9, RootJoint=A(-9,0,0,0,-0.12,0),Neck=A(-10),RS=A(26,0,-8),LS=A(36,0,36),RH=A(4,0,-5),LH=A(0,0,5)),
  K(1.8, RootJoint=A(-6,6,0),Neck=A(-4,10,0),RS=A(30,0,-6),LS=A(40,0,34),RH=A(2,0,-5),LH=A(-2,0,5)),
  K(2.7, RootJoint=A(-9,0,0,0,-0.12,0),Neck=A(-10,-8,0),RS=A(26,0,-8),LS=A(36,0,36),RH=A(4,0,-5),LH=A(0,0,5)),
  K(3.6, RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34),RH=A(2,0,-5),LH=A(-2,0,5))]),
 'Walk':(True,1,[  # stiff heavy stomp, the body sways side to side
  K(0,   RootJoint=A(-8,0,8),Neck=A(-4,0,-8),RS=A(36,0,-6),LS=A(46,0,34),RH=A(26,0,-4),LH=A(-20,0,4)),
  K(0.4, RootJoint=A(-10,0,0,0,-0.35,0),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,34),RH=A(6,0,-4),LH=A(2,0,4)),
  K(0.8, RootJoint=A(-8,0,-8),Neck=A(-4,0,8),RS=A(36,0,-6),LS=A(46,0,34),RH=A(-20,0,-4),LH=A(26,0,4)),
  K(1.2, RootJoint=A(-10,0,0,0,-0.35,0),Neck=A(-6),RS=A(30,0,-6),LS=A(40,0,34),RH=A(2,0,-4),LH=A(6,0,4)),
  K(1.6, RootJoint=A(-8,0,8),Neck=A(-4,0,-8),RS=A(36,0,-6),LS=A(46,0,34),RH=A(26,0,-4),LH=A(-20,0,4))]),
 'Throw':(False,4,[  # = SPRAY: raises the nozzle, braces, sweeps the gas left-right
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34)),
  K(0.45,RootJoint=A(-14,0,0,0,-0.25,0),Neck=A(-8),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-12,0,-10),LH=A(20,0,10)),
  K(0.85,RootJoint=A(-14,-18,0,0,-0.25,0),Neck=A(-8,-10,0),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-12,0,-10),LH=A(20,0,10)),
  K(1.3, RootJoint=A(-14,18,0,0,-0.25,0),Neck=A(-8,10,0),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-12,0,-10),LH=A(20,0,10)),
  K(1.7, RootJoint=A(-14,0,0,0,-0.25,0),Neck=A(-8),RS=A(84,0,-4),LS=A(80,0,40),RH=A(-12,0,-10),LH=A(20,0,10)),
  K(2.0, RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34))]),
 'Attack':(False,3,[  # close: shoves with both hands / the sprayer body
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34)),
  K(0.3, RootJoint=A(6,0,0,0,0,0.3),Neck=A(4),RS=A(70,0,-10),LS=A(70,0,10),RH=A(-10),LH=A(10)),
  K(0.42,RootJoint=A(-24,0,0,0,-0.15,-0.6),Neck=A(-10),RS=A(95,0,-4),LS=A(95,0,4),RH=A(20),LH=A(-16)),
  K(0.65,RootJoint=A(-20,0,0,0,-0.1,-0.5),Neck=A(-8),RS=A(85,0,-4),LS=A(85,0,4),RH=A(16),LH=A(-12)),
  K(0.95,RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34))]),
 'Death':(False,3,[  # suit leaks, drops to the knees, falls forward on the tanks... and the face
  K(0,   RootJoint=A(-6),Neck=A(-4),RS=A(30,0,-6),LS=A(40,0,34)),
  K(0.35,RootJoint=A(-4),Neck=A(20),RS=A(40,0,-30),LS=A(40,0,30),RH=A(0),LH=A(0)),
  K(0.75,RootJoint=A(-10,0,0,0,-1.5,0),Neck=A(14),RS=A(20,0,-20),LS=A(20,0,20),RH=A(95),LH=A(90)),
  K(1.15,RootJoint=A(-86,0,0,0,-2.6,-1.5),Neck=A(24,0,20),RS=A(150,0,-30),LS=A(150,0,30),RH=A(30),LH=A(26)),
  K(1.35,RootJoint=A(-84,0,0,0,-2.55,-1.5),Neck=A(22,0,22),RS=A(148,0,-32),LS=A(148,0,32),RH=A(28),LH=A(24))]),
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
out=os.environ.get('OUT','/home/claude/mobs6/out'); os.makedirs(out,exist_ok=True)
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
    open(f'{out}/z6_{setname.lower()}_{name.lower()}.rbxmx','w').write(xml)
print(sorted(os.listdir(out)))
