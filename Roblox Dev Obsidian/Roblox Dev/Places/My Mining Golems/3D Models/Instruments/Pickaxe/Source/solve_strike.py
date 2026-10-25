import json, math, numpy as np
from scipy.optimize import minimize
def Rx(a): c,s=math.cos(a),math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c,s=math.cos(a),math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c,s=math.cos(a),math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def E(x=0,y=0,z=0): return Rz(z)@Ry(y)@Rx(x)
BP={"Root":(None,(0,0,-0.175)),"Hips":("Root",(0,5.2,-0.175)),"Torso":("Hips",(0,6.0,-0.175)),
    "Head":("Torso",(0,10.2,0.425)),"UpperArm_L":("Torso",(-4.9,9.5,-0.175)),"Forearm_L":("UpperArm_L",(-5.2,7.0,0.125))}
def fk(pose):
    W={}
    for n in ["Root","Hips","Torso","Head","UpperArm_L","Forearm_L"]:
        par,pos=BP[n]; pos=np.array(pos,float)
        r,t=pose.get(n,((0,0,0),(0,0,0)))
        R=E(*r); t=np.array(t,float)
        if par is None: W[n]=(R,pos+t)
        else:
            PR,PP=W[par]; rest=pos-np.array(BP[par][1],float)
            W[n]=(PR@R, PP+PR@(rest+t))
    return W
P=json.load(open("pickaxe_blocks.json"))
TIP=np.array(P["tip"]); G=np.array([-5.3,3.7,0.225])
def grip_R(g): return Rx(math.pi/2+g)
def tip_world(pose,g):
    W=fk(pose); R,O=W["Forearm_L"]; fpos=np.array(BP["Forearm_L"][1])
    prest=G+grip_R(g)@TIP
    return O+R@(prest-fpos)
def blade_dir(pose,g):
    W=fk(pose); R,_=W["Forearm_L"]
    return R@grip_R(g)@np.array([0,0,1.0])
def head_world(pose,g):
    W=fk(pose); R,O=W["Forearm_L"]; fpos=np.array(BP["Forearm_L"][1])
    return O+R@(G+grip_R(g)@np.array([0,7.9,0])-fpos)
# --- idle: grip tilt so the head rests just above ground
for g in np.arange(0.2,0.7,0.05):
    pose={"Forearm_L":((-0.12,0,0),(0,0,0))}
    tw=tip_world(pose,g); hw=head_world(pose,g)
    print(f"g={g:.2f} idle tip y={tw[1]:.2f} z={tw[2]:.2f} head y={hw[1]:.2f} z={hw[2]:.2f}")

T=np.array([-1.4,3.3,13.7]); D=np.array([0,-0.45,1.0]); D/=np.linalg.norm(D)
def strike_pose(v):
    lean,twist,ua_x,ua_z,fa_x,drop,g=v
    return {"Hips":((0,0,0),(0,-drop,0)),"Torso":((lean,twist,0),(0,0,0)),
            "UpperArm_L":((ua_x,0,ua_z),(0,0,0)),"Forearm_L":((fa_x,0,0),(0,0,0))},g
def cost(v):
    pose,g=strike_pose(v)
    tw=tip_world(pose,g); bd=blade_dir(pose,g)
    idle_tip=tip_world({"Forearm_L":((-0.12,0,0),(0,0,0))},g)
    c=np.sum((tw-T)**2)+4*(1-bd@D)**2
    c+=10*max(0,0.3-idle_tip[1])**2
    # prefer modest lean/twist/drop
    c+=0.3*(v[0]**2+v[1]**2)+0.5*v[5]**2+0.1*v[3]**2
    return c
bounds=[(0,0.45),(-0.45,0.45),(-2.2,0.2),(-0.35,0.35),(-1.4,-0.05),(0,0.6),(-0.8,0.6)]
best=None
for s in range(40):
    rng=np.random.default_rng(s); x0=[rng.uniform(a,b) for a,b in bounds]
    r=minimize(cost,x0,bounds=bounds,method="L-BFGS-B")
    if best is None or r.fun<best.fun: best=r
v=best.x; pose,g=strike_pose(v)
print("best",np.round(v,3),"cost",best.fun)
print("tip",np.round(tip_world(pose,g),2),"blade",np.round(blade_dir(pose,g),2))
print("idle tip",np.round(tip_world({"Forearm_L":((-0.12,0,0),(0,0,0))},g),2),"idle head",np.round(head_world({"Forearm_L":((-0.12,0,0),(0,0,0))},g),2))
# windup check
for ua in (-2.4,-2.7,-3.0):
    wp={"Torso":((-0.12,-0.2,0),(0,0,0)),"UpperArm_L":((ua,0,-0.15),(0,0,0)),"Forearm_L":((-0.7,0,0),(0,0,0))}
    print("windup ua",ua,"head",np.round(head_world(wp,g),2),"tip",np.round(tip_world(wp,g),2))
