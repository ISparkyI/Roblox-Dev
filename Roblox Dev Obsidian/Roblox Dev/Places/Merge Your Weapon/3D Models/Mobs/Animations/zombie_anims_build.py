import numpy as np, math
def Rx(a): c,s=math.cos(a),math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c,s=math.cos(a),math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c,s=math.cos(a),math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def ang(x,y,z): return Rx(x)@Ry(y)@Rz(z)
r=math.radians
JR={'RootJoint':ang(-math.pi/2,0,math.pi),'Neck':ang(-math.pi/2,0,math.pi),'RS':Ry(math.pi/2),'LS':Ry(-math.pi/2),'RH':Ry(math.pi/2),'LH':Ry(-math.pi/2)}
POSE={'RootJoint':'Torso','Neck':'Head','RS':'Right Arm','LS':'Left Arm','RH':'Right Leg','LH':'Left Leg'}
def A(x=0,y=0,z=0,ox=0,oy=0,oz=0): return (ang(r(x),r(y),r(z)),np.array([ox,oy,oz]))
ANIMS={
 'Walk':(True,1,[
  (0,   dict(RootJoint=A(-8,6,4),Neck=A(-6,0,10),RS=A(80,0,-4),LS=A(92,0,4),RH=A(26),LH=A(-22))),
  (0.25,dict(RootJoint=A(-10,0,0,0,-0.18,0),Neck=A(-8),RS=A(86,0,-2),LS=A(86,0,2),RH=A(0),LH=A(0))),
  (0.5, dict(RootJoint=A(-8,-6,-4),Neck=A(-6,0,-10),RS=A(92,0,-4),LS=A(80,0,4),RH=A(-22),LH=A(26))),
  (0.75,dict(RootJoint=A(-10,0,0,0,-0.18,0),Neck=A(-8),RS=A(86,0,-2),LS=A(86,0,2),RH=A(0),LH=A(0))),
  (1.0, dict(RootJoint=A(-8,6,4),Neck=A(-6,0,10),RS=A(80,0,-4),LS=A(92,0,4),RH=A(26),LH=A(-22)))]),
 'Idle':(True,0,[
  (0,  dict(RootJoint=A(-5,0,3),Neck=A(-4,0,12),RS=A(72,0,-3),LS=A(78,0,3),RH=A(0),LH=A(0))),
  (1.2,dict(RootJoint=A(-7,0,-3,0,-0.08,0),Neck=A(-8,0,-8),RS=A(78,0,-5),LS=A(70,0,5),RH=A(-3),LH=A(3))),
  (2.4,dict(RootJoint=A(-5,0,3),Neck=A(-4,0,12),RS=A(72,0,-3),LS=A(78,0,3),RH=A(0),LH=A(0)))]),
 'Attack':(False,3,[
  (0,   dict(RootJoint=A(-8),Neck=A(-6),RS=A(86),LS=A(86),RH=A(0),LH=A(0))),
  (0.22,dict(RootJoint=A(6),Neck=A(10),RS=A(160,0,-8),LS=A(160,0,8),RH=A(-6),LH=A(6))),
  (0.34,dict(RootJoint=A(-22,0,0,0,-0.2,-0.3),Neck=A(-14),RS=A(45,0,-4),LS=A(45,0,4),RH=A(10),LH=A(-12))),
  (0.6, dict(RootJoint=A(-8),Neck=A(-6),RS=A(86),LS=A(86),RH=A(0),LH=A(0)))]),
 'Death':(False,3,[
  (0,   dict(RootJoint=A(-8),Neck=A(-6),RS=A(86),LS=A(86),RH=A(0),LH=A(0))),
  (0.25,dict(RootJoint=A(10,0,8,0,-0.3,0.3),Neck=A(20,0,15),RS=A(150,0,-20),LS=A(140,0,25),RH=A(-15),LH=A(10))),
  (0.8, dict(RootJoint=A(88,0,10,0,-2.6,2.2),Neck=A(15,0,25),RS=A(170,0,-35),LS=A(165,0,40),RH=A(-10,0,8),LH=A(15,0,-8))),
  (1.0, dict(RootJoint=A(84,0,10,0,-2.5,2.2),Neck=A(12,0,25),RS=A(172,0,-38),LS=A(168,0,42),RH=A(-8,0,8),LH=A(12,0,-8)))]),
}
def T(j,R):
    Rm,o=R; J=JR[j]
    return J.T@Rm@J, J.T@o
# sanity vs Studio: Walk 0 LS -> -0.03490,0.99696,-0.06971,...
m,p=T('LS',ANIMS['Walk'][2][0][1]['LS']); print(np.round(m.flatten(),5))
m,p=T('RootJoint',ANIMS['Death'][2][2][1]['RootJoint']); print(np.round(p,3),np.round(m.flatten(),4))
def cf(name,m,p):
    return (f'<CoordinateFrame name="{name}"><X>{p[0]:.5f}</X><Y>{p[1]:.5f}</Y><Z>{p[2]:.5f}</Z>'
     f'<R00>{m[0,0]:.6f}</R00><R01>{m[0,1]:.6f}</R01><R02>{m[0,2]:.6f}</R02><R10>{m[1,0]:.6f}</R10><R11>{m[1,1]:.6f}</R11><R12>{m[1,2]:.6f}</R12>'
     f'<R20>{m[2,0]:.6f}</R20><R21>{m[2,1]:.6f}</R21><R22>{m[2,2]:.6f}</R22></CoordinateFrame>')
I=np.eye(3);Z=np.zeros(3)
def pose(name,m,p,w,children=""):
    return (f'<Item class="Pose"><Properties><string name="Name">{name}</string>{cf("CFrame",m,p)}'
            f'<token name="EasingDirection">2</token><token name="EasingStyle">0</token><float name="Weight">{w}</float></Properties>{children}</Item>')
for name,(loop,prio,keys) in ANIMS.items():
    ks=""
    for t,joints in keys:
        limbs="".join(pose(POSE[j],*T(j,joints[j]),1) for j in ['Neck','RS','LS','RH','LH'])
        torso=pose('Torso',*T('RootJoint',joints['RootJoint']),1,limbs)
        root=pose('HumanoidRootPart',I,Z,0,torso)
        ks+=f'<Item class="Keyframe"><Properties><string name="Name">Keyframe</string><float name="Time">{t}</float></Properties>{root}</Item>'
    xml=(f'<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4">'
         f'<Item class="KeyframeSequence"><Properties><string name="Name">ZombieFarmer_{name}</string><bool name="Loop">{"true" if loop else "false"}</bool>'
         f'<token name="Priority">{prio}</token></Properties>{ks}</Item></roblox>')
    open(f'/mnt/user-data/outputs/zombie_{name.lower()}.rbxmx','w').write(xml)
print("ok")
