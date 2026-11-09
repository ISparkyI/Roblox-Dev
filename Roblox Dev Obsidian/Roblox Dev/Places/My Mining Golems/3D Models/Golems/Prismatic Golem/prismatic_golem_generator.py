# Prismatic Golem (Mythic, мапа 4, рол 1 до 650000, між Frostforged і Platinum) — призматичний алмаз.
# Графітовий «кімберліт» із гранованими алмазами; на грудях діамант огранки «брильянт» у срібній оправі з чотирма
# променями веселки (рожевий, жовтий, бірюзовий, фіалковий — Neon), на плечах і спині — алмазні кристали з
# райдужними іскрами, над головою — трикутна призма з іскрою всередині.
# Унікальні анімації (Mythic): призма над головою обертається (spin), промені на грудях пульсують (pulse),
# іскри на кристалах плечей мерехтять не в такт (pulse з фазою). Скелет Clay.
# Інструменти власної форми: кірка з діамантом на обусі, кришталевий меч із веселковим долом; скриня ювеліра.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(diamond="#e3eef9", diamondShade="#b7c9de", kimber="#3a3f4f", kimberDark="#262a36", silver="#c9d1dc",
               rose="#ff4f9a", sun="#ffc21a", aqua="#21d4c8", violet="#9b5cff", spark="#e6f6ff",
               light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def prism(name, bone, base, h, w, rx=0, rz=0, col="diamond", tip="spark", mirror=False, R0=None):
    R = (R0 if R0 is not None else np.eye(3)) @ eul(rx=rx, rz=rz) @ eul(ry=45); up = R[:, 1]; base = np.array(base)
    sfx = "_R" if mirror else ""
    a(name + sfx, bone, col, tuple(base + up * h / 2), (w, h, w), R, mirror=mirror)
    a(name + "Tip" + sfx, bone, tip, tuple(base + up * (h + 0.12)), (w * 0.6, 0.5, w * 0.6), R, mirror=mirror)
D45 = eul(rz=45)
OCTA = eul(rx=35.264) @ eul(rz=45)
RAINBOW = ("rose", "sun", "aqua", "violet")

# ---------- ноги ----------
a("Foot_R","Shin_R","kimberDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","kimber",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","silver",(2.15,3.0,-0.2),(2.86,0.36,2.86),eul(ry=4),mirror=True)
a("KneeGem_R","Shin_R","diamond",(2.25,2.2,1.25),(0.62,0.62,0.62),eul(ry=4)@OCTA,mirror=True)
a("Thigh_R","Thigh_R","kimberDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","kimberDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","silver",(0,5.45,-0.3),(6.6,0.5,3.9))
a("BeltGem","Hips","diamond",(0,5.45,1.7),(0.6,0.6,0.6),OCTA)
# ---------- корпус: брильянт у срібній оправі з променями веселки ----------
a("Torso","Torso","kimber",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","diamondShade",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ChestBand","Torso","silver",(0,8.95,-0.3),(7.6,0.4,4.4))
GC = 7.25
a("SetA","Torso","silver",(0,GC,1.95),(2.6,2.6,0.3))
a("SetB","Torso","silver",(0,GC,1.96),(2.6,2.6,0.24),D45)
a("GemA","Torso","diamondShade",(0,GC,2.2),(2.0,2.0,0.24))
a("GemB","Torso","diamondShade",(0,GC,2.24),(2.0,2.0,0.26),D45)
a("GemC","Torso","diamond",(0,GC,2.36),(1.3,1.3,0.2),D45)
a("GemTable","Torso","spark",(0,GC,2.48),(0.7,0.7,0.12))
RAYS = []
for i, (sx, sy) in enumerate(((1, 1), (1, -1), (-1, -1), (-1, 1))):   # промені навскіс від кутів оправи
    n = f"Ray{i}"; RAYS.append(n)
    a(n,"Torso",RAINBOW[i],(1.45*sx,GC+1.45*sy,2.05),(0.3,1.3,0.16),eul(rz=-45*sx*sy))
# спина: друза алмазних кристалів у кімберліті
a("BackPlate","Torso","kimberDark",(0,7.7,-2.45),(3.8,3.0,0.3))
prism("BackXtal1","Torso",(0,7.9,-2.45),2.2,0.9,rx=-55,col="violet")
prism("BackXtal2","Torso",(0.95,7.2,-2.45),1.6,0.7,rx=-50,rz=-28,col="aqua")
prism("BackXtal3","Torso",(-0.95,7.3,-2.45),1.4,0.62,rx=-58,rz=26,col="rose")
# ---------- голова: срібний обруч із діамантами, призма над головою ----------
a("Head","Head","kimber",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Circlet","Head","silver",(0,12.5,0.45),(4.2,0.4,3.6))
for i, x in enumerate((-1.2, 0.0, 1.2)):
    a(f"CircletGem{i}","Head","diamond" if i != 1 else "spark",(x,12.6,2.32),(0.42,0.42,0.42),OCTA)
prism("CrownXtal","Head",(0,12.65,0.3),0.9,0.55,tip="violet")
PC = np.array((0, 15.25, 0.35))                  # центр призми над головою (вільно ширяє, обертається)
PRISM = []
for nm, off, size, R in (("PrismL",(-0.42,0,0),(0.24,1.3,0.5),eul(rz=-30)), ("PrismR",(0.42,0,0),(0.24,1.3,0.5),eul(rz=30)),
                         ("PrismBase",(0,-0.55,0),(1.3,0.24,0.56),None)):
    a(nm,"Head","diamond",tuple(PC+np.array(off)),size,R); PRISM.append(nm)
a("PrismCore","Head","spark",tuple(PC+np.array((0,-0.12,0))),(0.36,0.36,0.36),OCTA); PRISM.append("PrismCore")
g.free_parts = tuple(PRISM)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","spark",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.0,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: срібні наплічники з алмазами й райдужними іскрами ----------
r3 = eul(rz=3)
a("Shoulder_R","UpperArm_R","kimber",(5.0,9.85,-0.3),(3.4,1.9,3.6),r3,mirror=True)
a("Pauldron_R","UpperArm_R","silver",(5.05,10.9,-0.3),(3.1,0.3,3.3),r3,mirror=True)
prism("ShXtalA","UpperArm_R",(5.1,10.95,-0.3),1.3,0.7,R0=r3,mirror=True,col="rose")
prism("ShXtalB","UpperArm_R",(5.95,10.95,0.3),0.8,0.5,rz=-25,R0=r3,mirror=True,col="sun")
prism("ShXtalC","UpperArm_R",(4.35,10.95,-0.95),0.7,0.45,rx=-20,rz=15,R0=r3,mirror=True,col="aqua")
a("UpperArm_R","UpperArm_R","kimberDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","kimber",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","silver",(5.55,6.4,0.0014),(3.1,0.7,3.2),eul(ry=-6),mirror=True)
a("BracerGem_R","Forearm_R","diamond",(5.39,6.4,1.68),(0.5,0.5,0.5),eul(ry=-6)@OCTA,mirror=True)
fist = a("Fist_R","Forearm_R","kimber",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","diamondShade",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"FistGem_R","diamond",(1.88,0.3,0.3),(0.4,0.75,0.75),eul(rx=45))
sub(fist,"Thumb_R","kimber",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- унікальні анімації ----------
g.fx.append(dict(kind="spin", parts=PRISM, pivot=tuple(PC), axis=(0, 1, 0), speed=0.9, states={"Walk": 1.4, "Run": 2.0, "Mine": 1.8}))
g.fx.append(dict(kind="pulse", parts=RAYS, amp=0.22, speed=2.2, states={"Mine": 1.6}))
for k, (nm, ph) in enumerate((("ShXtalATip", 0.0), ("ShXtalBTip", 2.1), ("ShXtalCTip", 4.2))):
    g.fx.append(dict(kind="pulse", parts=[nm + "_R", nm + "_L"], amp=0.3, speed=3.0, phase=ph))

# ---------- допоміжне для предметів (площина x = -5.65 кулака) ----------
X = np.array([1.0, 0, 0])
def frameY(d):
    d = d / np.linalg.norm(d); z = np.cross(X, d); z /= np.linalg.norm(z)
    return np.column_stack([X, d, z])
def seg(grp, name, col, p0, p1, w, t=None, extra=0.0, off=0.0):
    p0, p1 = np.array(p0, float), np.array(p1, float); R = frameY(p1 - p0)
    L = np.linalg.norm(p1 - p0) + extra; c = (p0 + p1) / 2 + R[:, 2] * off; t = w if t is None else t
    return g.item(name, grp, col, c, R, (w, L, t))
u = np.array([0, 0.1215, 0.99259]); wv = np.array([0, -0.99259, 0.1215])
A = PICK["Handle"][1]
INPLANE45 = eul(rx=45)          # ромб, видимий збоку (поворот у площині предмета)

# ---------- кірка — «призма-розщеплювач»: на обусі тригранна призма, з неї віялом виходить веселка; кришталеве лезо з веселковою кромкою ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","kimberDark"); P("Grip","kimber")
PM = P("Pommel","silver")
sub(PM,"PommelGem","diamond",(0,-0.62,0),(0.62,0.62,0.62),OCTA)
sub(PM,"PommelTip","violet",(0,-1.05,0),(0.26,0.5,0.26),eul(ry=45))
sub(HN,"Ring1","silver",(0,0.87,0),(0.86,0.3,0.86))
for i in range(4):              # спектр на руків'ї
    sub(HN,f"Spectrum{i}",RAINBOW[i],(0,1.2 + 0.36*i,0),(0.74,0.36,0.74))
sub(HN,"Ring2","silver",(0,2.61,0),(0.86,0.3,0.86))
sub(HN,"Neck","silver",(0,3.45,0),(0.8,0.9,0.8),eul(ry=45))
H = np.array(PICK["Head"][0])
def ph(a_, b_=0.0): return H + u * a_ + wv * b_
HD = g.item("Head","Pickaxe","silver",tuple(H),A,(1.0,1.3,1.6))
sub(HD,"HeadBand","kimber",(0,0,0),(1.12,0.56,1.7))
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD,f"HeadGem{nm}","diamond",(0.6*side,0,0),(0.2,0.8,0.8),INPLANE45)
    sub(HD,f"HeadSpark{nm}","aqua" if side > 0 else "rose",(0.68*side,0,0),(0.14,0.34,0.34),INPLANE45)
# обух: тригранна призма (вісь — убік), усередині світне ядро
c0, c1, ap = ph(-0.9,-0.9), ph(0.9,-0.9), ph(0,-2.45)
seg("Pickaxe","PkPrismBase","diamondShade",ph(-1.0,-0.9),ph(1.0,-0.9),1.24,0.28)
seg("Pickaxe","PkPrismL","diamond",c0,ap,1.2,0.26,extra=0.24)
seg("Pickaxe","PkPrismR","diamond",c1,ap,1.12,0.26,extra=0.24)
g.item("PkPrismCore","Pickaxe","spark",tuple(ph(0,-1.42)),A @ OCTA,(0.6,0.6,0.6))
g.item("PkPrismApex","Pickaxe","silver",tuple(ap + (-wv) * 0.12),A @ INPLANE45,(1.32,0.42,0.42))
for i in range(4):                                                                       # веселка виходить віялом
    p0 = ph(0.42,-1.62); ang = np.radians(-28 + 19*i)
    dirv = u * np.cos(ang) + (-wv) * np.sin(ang)
    seg("Pickaxe",f"PkRay{i}",RAINBOW[i],p0,p0 + dirv * (1.7 + 0.15*(i % 2)),0.18 + 0.06*i,0.22,extra=0.1)
# лезо: три кришталеві сегменти, срібний хребет зсередини, веселкова кромка ззовні
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv * 0.75; M1 = np.array((-5.65, 2.3, 8.35)); M2 = np.array((-5.65, 0.75, 8.1))
pts = (S0, M1, M2, p4back); ws = (0.5, 0.42, 0.32); ts = (1.0, 0.82, 0.62)
for i in range(3):
    seg("Pickaxe",f"Pick{i+1}",("diamond","diamondShade","diamond")[i],pts[i],pts[i+1],ws[i],ts[i],extra=0.3)
    seg("Pickaxe",f"Spine{i+1}","silver",pts[i],pts[i+1],ws[i] + 0.16,0.2,extra=0.18 if i else 0.0,off=(ts[i]/2 - 0.02))
    seg("Pickaxe",f"Edge{i+1}",("rose","sun","aqua")[i],pts[i],pts[i+1],ws[i] - 0.14,0.18,extra=0.08,off=-(ts[i]/2 + 0.04))
g.item("Pick4","Pickaxe","spark",tuple(p4c),p4R,p4s)
for i, (pp, L, w) in enumerate(((M1, 0.95, 0.2), (M2, 0.7, 0.22)), 1):   # кристалічні шипи ззовні
    d = pts[i+1] - pts[i-1]; d /= np.linalg.norm(d); n = -np.cross(X, d)
    tip = pp + n * (ts[i-1]/2 + L) + d * 0.35
    seg("Pickaxe",f"Shard{i}","diamond",pp + n * 0.1,tip,w,w,extra=0.1)
    g.item(f"ShardTip{i}","Pickaxe","violet",tuple(tip),frameY(tip - pp) @ eul(ry=45),(w*0.62,0.36,w*0.62))

# ---------- меч — «спектральний клинок»: широке ромбоподібне кришталеве лезо з променем-серцевиною, веселкові грані, гарда-призма з крилами ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordGrip","kimberDark"); S("SwordCoil1","silver"); S("SwordCoil2","silver")
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordPommel","Sword","silver",tuple(at(-2.15)),A,(0.86,0.56,0.86))
g.item("PommelGem","Sword","diamond",tuple(at(-2.75)),A @ OCTA,(0.72,0.72,0.72))
g.item("PommelTip","Sword","sun",tuple(at(-3.2)),A @ eul(ry=45),(0.28,0.5,0.28))
# гарда: срібна поперечина, у центрі діамант, на кінцях кристалічні крила з веселковими кінчиками
g.item("SwordGuard","Sword","silver",tuple(at(2.25)),A,(0.46,0.46,2.5))
g.item("GuardGem","Sword","diamond",tuple(at(2.3)),A @ OCTA,(0.9,0.9,0.9))
g.item("GuardCore","Sword","spark",tuple(at(2.3)),A @ eul(ry=45),(0.5,0.5,1.04))
for sb, nm, cA, cB in ((1, "R", "rose", "sun"), (-1, "L", "aqua", "violet")):
    e = at(2.25, 1.15*sb)
    g.item(f"GuardEnd{nm}","Sword","diamondShade",tuple(e),A @ INPLANE45,(0.58,0.62,0.62))
    t1 = at(3.55, 2.0*sb); t2 = at(1.95, 2.45*sb)
    seg("Sword",f"WingA{nm}","diamond",e,t1,0.3,0.34,extra=0.1)
    seg("Sword",f"WingB{nm}","diamond",e,t2,0.26,0.3,extra=0.1)
    g.item(f"WingTipA{nm}","Sword",cA,tuple(t1),frameY(t1 - e) @ eul(ry=45),(0.22,0.4,0.22))
    g.item(f"WingTipB{nm}","Sword",cB,tuple(t2),frameY(t2 - e) @ eul(ry=45),(0.2,0.36,0.2))
# лезо: розширюється до середини, звужується до вістря; світліші фаски, світна серцевина
bp = [at(2.45), at(4.3), at(6.5), at(8.5), at(9.9)]
widths = (1.0, 1.4, 1.15, 0.74); thick = (0.38, 0.32, 0.26, 0.2)
for i in range(4):
    seg("Sword","SwordBlade" if i == 0 else f"Blade{i+1}","diamond",bp[i],bp[i+1],thick[i],widths[i],extra=0.18)
    seg("Sword",f"Bevel{i+1}","diamondShade",bp[i],bp[i+1],thick[i] - 0.16,widths[i] + 0.3,extra=0.1)
g.item("SwordTip","Sword","diamond",tuple(at(10.25)),A @ INPLANE45,(0.28,0.78,0.78))
seg("Sword","Core","silver",at(2.6),at(9.5),0.46,0.14)
for i, aa in enumerate((3.55, 5.0, 6.45, 7.9)):      # веселкові грані обабіч серцевини
    for sb, nm in ((1, "R"), (-1, "L")):
        g.item(f"Facet{i}{nm}","Sword",RAINBOW[i],tuple(at(aa, 0.36*sb)),A @ INPLANE45,(0.47 + 0.02*(sb>0),0.3,0.3))
for i, (aa, L) in enumerate(((4.3, 0.75), (6.5, 0.6)), 1):   # кристалічні шипи з кромок
    for sb, nm in ((1, "R"), (-1, "L")):
        w0 = widths[i]/2 if i == 1 else widths[2]/2
        p0 = at(aa, (w0 + 0.05)*sb); p1 = at(aa + 0.7, (w0 + 0.05 + L)*sb)
        seg("Sword",f"Spike{i}{nm}","diamond",at(aa - 0.1, (w0 - 0.2)*sb),p1,(0.27,0.21)[i-1],0.24,extra=0.05)
g.item("Ricasso","Sword","silver",tuple(at(2.68)),A,(0.54,0.5,1.24))

# ---------- ящик: скриня ювеліра з брильянтом і райдужними променями (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","kimberDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","kimberDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","kimber",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","kimber",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","kimber",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","kimber",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","silver",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","silver",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","silver",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","silver",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "silver", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("CornerXtal" + t, "diamond", (1.87*sx, 2.25, 1.06*sz), (0.3, 0.7, 0.3), eul(ry=45))
        B("CornerTip" + t, "spark", (1.87*sx, 2.68, 1.06*sz), (0.18, 0.3, 0.18), eul(ry=45))
B("BoxSet","silver",(0,0.98,-1.2),(1.2,1.2,0.1),D45)
B("BoxGemA","diamondShade",(0,0.98,-1.26),(0.9,0.9,0.1))
B("BoxGemB","diamond",(0,0.98,-1.31),(0.62,0.62,0.12),D45)
B("BoxTable","spark",(0,0.98,-1.37),(0.3,0.3,0.1))
for i, (sx, sy) in enumerate(((1, 1), (1, -1), (-1, -1), (-1, 1))):
    B(f"BoxRay{i}",RAINBOW[i],(0.78*sx,0.98+0.5*sy,-1.2),(0.12,0.42,0.12),eul(rz=-45*sx*sy))
B("BoxGemIn","diamond",(0,1.05,1.2),(0.4,0.4,0.12),D45)
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки: дві срібні стійки + алмазна перекладина з фіалковою іскрою
    B("HandlePostA"+nm,"silver",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("HandlePostB"+nm,"silver",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("HandleBar"+nm,"diamond",(2.5*sx,1.25,0),(0.24,0.3,1.06))
    B("HandleSpark"+nm,"violet",(2.6*sx,1.25,0),(0.12,0.22,0.22),eul(rx=45))

if __name__ == "__main__":
    out = "/home/claude/prismatic/PrismaticGolemData.lua"
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export(out, [
        "-- Prismatic Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано prismatic_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). fx: spin призми, pulse променів і іскор. neon — веселка (rose, sun, aqua, violet) і spark. Pickaxe / Sword — у кулаці Fist_L."])
    s = open(out).read().replace(" bones={", " neon={rose=true,sun=true,aqua=true,violet=true,spark=true},\n bones={", 1); open(out, "w").write(s)
