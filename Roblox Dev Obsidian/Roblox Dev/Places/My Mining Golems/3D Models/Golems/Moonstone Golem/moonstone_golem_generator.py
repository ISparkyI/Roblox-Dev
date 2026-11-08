# Moonstone Golem (Legendary, рол 1 до 75000, мапа 1, між Obsidian і Magmaheart) — місячний вартовий.
# Перламутрово-блакитний місячний камінь і темно-синій «нічний» камінь у суглобах. На грудях — нічне небо (восьмикутник)
# зі світним півмісяцем і зорями, на голові срібний обруч із короною-півмісяцем і світною перлиною, на плечах
# світні блакитні кристали, на спині — нічна пластина із зорями. Анімації стандартні (без fx). Neon — `glow`.
# Інструменти власної форми: кірка з обухом-півмісяцем, «місячна» шабля з гардою-півмісяцем; нічна скриня з півмісяцем.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(moon="#c3cfe9", moonShade="#a3b1d1", night="#27315a", nightDark="#1a2142", silver="#b8c2d4",
               star="#e3ecff", glow="#5f9dff", light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def prism(name, bone, base, h, w, rx=0, rz=0, col="glow", tip="star", mirror=False, R0=None):
    R = (R0 if R0 is not None else np.eye(3)) @ eul(rx=rx, rz=rz) @ eul(ry=45); up = R[:, 1]; base = np.array(base)
    sfx = "_R" if mirror else ""
    a(name + sfx, bone, col, tuple(base + up * h / 2), (w, h, w), R, mirror=mirror)
    a(name + "Tip" + sfx, bone, tip, tuple(base + up * (h + 0.12)), (w * 0.6, 0.5, w * 0.6), R, mirror=mirror)
D45 = eul(rz=45)
OCTA = eul(rx=35.264) @ eul(rz=45)

# ---------- ноги ----------
a("Foot_R","Shin_R","nightDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","moon",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","silver",(2.15,3.0,-0.2),(2.86,0.36,2.86),eul(ry=4),mirror=True)
a("KneeStar_R","Shin_R","glow",(2.25,2.2,1.2),(0.6,0.6,0.3),eul(ry=4)@D45,mirror=True)
a("Thigh_R","Thigh_R","night",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","nightDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","silver",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Buckle","Hips","night",(0,5.45,1.68),(1.1,0.8,0.3))
a("BuckleMoon","Hips","glow",(-0.12,5.45,1.86),(0.22,0.5,0.2))
a("BuckleMoonT","Hips","glow",(0.08,5.66,1.9),(0.2,0.24,0.2),eul(rz=-50))
a("BuckleMoonB","Hips","glow",(0.08,5.24,1.9),(0.2,0.24,0.2),eul(rz=50))
# ---------- корпус: нічне небо з півмісяцем і зорями ----------
a("Torso","Torso","moon",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","moon",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ChestBand","Torso","moonShade",(0,8.95,-0.3),(7.6,0.4,4.4))
SC = 7.25
a("SkyA","Torso","night",(0,SC,1.95),(2.8,2.8,0.3))
a("SkyB","Torso","night",(0,SC,1.95),(2.8,2.8,0.2),D45)
a("SkyRim","Torso","silver",(0,SC,1.84),(3.1,3.1,0.2),D45)
a("CresMid","Torso","glow",(-0.62,SC,2.17),(0.42,1.3,0.22))
a("CresTop","Torso","glow",(-0.32,SC+0.82,2.23),(0.4,0.75,0.24),eul(rz=-50))
a("CresBot","Torso","glow",(-0.32,SC-0.82,2.23),(0.4,0.75,0.24),eul(rz=50))
a("CresTipT","Torso","glow",(0.12,SC+1.08,2.29),(0.26,0.42,0.18),eul(rz=-78))
a("CresTipB","Torso","glow",(0.12,SC-1.08,2.29),(0.26,0.42,0.18),eul(rz=78))
for i, (x, y, s) in enumerate(((0.55, 0.45, 0.3), (0.85, -0.35, 0.24), (0.3, -0.6, 0.2))):
    a(f"Star{i}","Torso","star",(x,SC+y,2.16),(s,s,0.2),D45)
# спина: нічна пластина із зорями
a("BackPlate","Torso","night",(0,7.6,-2.45),(4.4,3.4,0.3))
a("BackMoon","Torso","moonShade",(0,8.0,-2.65),(1.6,1.6,0.2),D45)
a("BackMoonGlow","Torso","glow",(0,8.0,-2.78),(0.8,0.8,0.12),D45)
for i, (x, y) in enumerate(((-1.4, 6.6), (1.3, 6.8), (-1.5, 8.7), (1.5, 8.9))):
    a(f"BackStar{i}","Torso","star",(x,y,-2.66),(0.3,0.3,0.2),D45)
# ---------- голова: срібний обруч, корона-півмісяць зі світною перлиною ----------
a("Head","Head","moon",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Circlet","Head","silver",(0,12.5,0.45),(4.2,0.4,3.6))
a("CircletGem","Head","glow",(0,12.5,2.3),(0.5,0.5,0.25),D45)
a("HornBase_R","Head","silver",(0.55,13.1,0.3),(0.42,1.3,0.42),eul(rz=-25),mirror=True)
a("HornTip_R","Head","moon",(0.98,13.86,0.3),(0.32,0.7,0.32),eul(rz=20),mirror=True)
a("CrownPearl","Head","glow",(0,13.12,0.3),(0.6,0.6,0.6),OCTA)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","night",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","star",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.0,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: нічні наплічники зі світними кристалами ----------
r3 = eul(rz=3)
a("Shoulder_R","UpperArm_R","moon",(5.0,9.85,-0.3),(3.4,1.9,3.6),r3,mirror=True)
a("Pauldron_R","UpperArm_R","night",(5.05,10.9,-0.3),(3.1,0.3,3.3),r3,mirror=True)
prism("ShXtalA","UpperArm_R",(5.1,10.95,-0.3),1.3,0.7,R0=r3,mirror=True)
prism("ShXtalB","UpperArm_R",(5.95,10.95,0.3),0.8,0.5,rz=-25,R0=r3,mirror=True)
prism("ShXtalC","UpperArm_R",(4.35,10.95,-0.95),0.7,0.45,rx=-20,rz=15,R0=r3,mirror=True)
a("UpperArm_R","UpperArm_R","night",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","moon",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","silver",(5.55,6.4,0.0014),(3.1,0.7,3.2),eul(ry=-6),mirror=True)
a("BracerGem_R","Forearm_R","glow",(5.39,6.4,1.62),(0.5,0.5,0.25),eul(ry=-6)@D45,mirror=True)
fist = a("Fist_R","Forearm_R","moon",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","silver",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"FistGem_R","glow",(1.88,0.3,0.3),(0.4,0.7,0.7),eul(rx=45))
sub(fist,"Thumb_R","moon",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- кірка: обух — півмісяць (два роги зі світними кінчиками), лезо від нічного до зоряного ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","night"); P("Grip","moonShade"); P("Band","silver")
PM = P("Pommel","silver")
sub(PM,"PommelGem","glow",(0,-0.6,0),(0.5,0.5,0.5),OCTA)
sub(HN,"Ring1","silver",(0,1.5,0),(0.82,0.28,0.82))
sub(HN,"RingMoon","moon",(0,2.05,0),(0.76,0.5,0.76),eul(ry=45))
sub(HN,"Ring2","silver",(0,2.6,0),(0.82,0.28,0.82))
HD = P("Head","silver"); P("HeadRound","night")
P1 = P("Pick1","night"); P("Pick2","moonShade"); P("Pick3","moon"); P("Pick4","star"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"HeadStar{nm}", "glow", (0.88*side, 0, 0.1), (0.2, 0.7, 0.7), eul(rx=45))
    sub(P1, f"BladeLine{nm}", "glow", (0.55*side, 0.1, 0), (0.1, 0.25, 1.5))
sub(HD,"CresBase","moon",(0,0,-1.27),(0.46,1.0,0.66))   # заходить у голову (задня грань голови z −1.0)
sub(HD,"CresArmU","moon",(0,0.8,-1.85),(0.4,1.0,0.44),eul(rx=-32))
sub(HD,"CresArmD","moon",(0,-0.8,-1.85),(0.4,1.0,0.44),eul(rx=32))
sub(HD,"CresTipU","glow",(0,1.27,-2.18),(0.32,0.6,0.32),eul(rx=-60))
sub(HD,"CresTipD","glow",(0,-1.27,-2.18),(0.32,0.6,0.32),eul(rx=60))
sub(HD,"CresInner","glow",(0,0,-1.68),(0.3,0.6,0.12))
# ---------- меч: місячна шабля — гарда-півмісяць, світний дол, зорі на клинку ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","silver"); S("SwordPommelTop","night"); S("SwordGrip","night")
sub(SP,"PommelMoon","moon",(0,-0.55,0),(0.6,0.6,0.6),OCTA)
sub(SP,"PommelGlow","glow",(0,-0.55,0),(0.44,0.44,0.44),eul(ry=45))
S("SwordCoil1","silver"); S("SwordCoil2","silver")
G = S("SwordGuard","silver",(0.8,0.6,2.6))
sub(G,"GuardOrb","glow",(0,0.1,0),(0.6,0.6,0.6),OCTA)
for sz, nm in ((1,"R"),(-1,"L")):
    R = eul(rx=-25*sz); up = R[:,1]; c = np.array((0,0.6,1.0*sz))   # роги стоять на гарді й торкаються кромки клинка
    sub(G,f"Horn{nm}","moon",tuple(c),(0.5,1.1,0.45),R)
    sub(G,f"HornTip{nm}","glow",tuple(c+up*0.7),(0.4,0.42,0.34),eul(rx=-40*sz))
BL = S("SwordBlade","moon"); S("SwordEdge","star"); S("SwordFuller","glow"); S("SwordTip","moon")
sub(BL,"Ricasso","silver",(0,-2.95,0),(0.6,0.5,1.7))
for i, (y, sz) in enumerate(((2.2, 1), (2.6, -1), (2.95, 1))):
    sub(BL,f"BladeStar{i}","night",(0,y,0.45*sz),(0.52,0.26,0.26),eul(rx=45))

# ---------- ящик: нічна скриня з півмісяцем і зорями (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","nightDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","nightDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","night",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","night",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","night",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","night",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","silver",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","silver",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","silver",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","silver",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "moonShade", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
# зовні: світний півмісяць і зорі
# зовні (−Z): місячний ромб у срібній рамці, світний півмісяць — дзеркально до грудей голема (опуклістю ліворуч для глядача)
B("BoxRim","silver",(0,0.98,-1.2),(1.25,1.25,0.1),D45)
B("BoxPanel","nightDark",(0,0.98,-1.26),(1.0,1.0,0.1),D45)
B("BoxCresMid","glow",(0.24,0.98,-1.32),(0.22,0.62,0.12))
B("BoxCresTop","glow",(0.08,1.36,-1.35),(0.2,0.38,0.14),eul(rz=50))
B("BoxCresBot","glow",(0.08,0.6,-1.35),(0.2,0.38,0.14),eul(rz=-50))
for i, (x, y, s) in enumerate(((-0.22, 1.12, 0.16), (-0.35, 0.8, 0.13), (-1.15, 1.35, 0.22), (-1.4, 0.6, 0.18), (1.2, 1.3, 0.2), (1.35, 0.55, 0.16))):
    B(f"BoxStar{i}","star" if abs(x) > 1 else "glow",(x,y,-1.2 if abs(x) > 1 else -1.33),(s,s,0.12),D45)
B("BoxMoonIn","moonShade",(0,1.0,1.2),(0.5,0.5,0.12),D45)
for sx in (1, -1):        # на кутах — срібні підставки зі світними зорями-октаедрами
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("StarBase" + t, "silver", (1.87*sx, 2.02, 1.06*sz), (0.46, 0.35, 0.46))
        B("StarTop" + t, "glow", (1.87*sx, 2.4, 1.06*sz), (0.36, 0.36, 0.36), OCTA)
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки: дві срібні стійки + місячна перекладина зі світною зіркою
    B("HandlePostA"+nm,"silver",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("HandlePostB"+nm,"silver",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("HandleBar"+nm,"moon",(2.5*sx,1.25,0),(0.24,0.3,1.06))
    B("HandleStar"+nm,"glow",(2.6*sx,1.25,0),(0.12,0.22,0.22),eul(rx=45))

if __name__ == "__main__":
    out = "/home/claude/moonstone/MoonstoneGolemData.lua"
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export(out, [
        "-- Moonstone Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано moonstone_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). Анімації стандартні (без fx). neon — glow (півмісяці, кристали, зорі-світла). Pickaxe / Sword — у кулаці Fist_L. Box — нічна скриня в стадах."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n bones={", 1); open(out, "w").write(s)
