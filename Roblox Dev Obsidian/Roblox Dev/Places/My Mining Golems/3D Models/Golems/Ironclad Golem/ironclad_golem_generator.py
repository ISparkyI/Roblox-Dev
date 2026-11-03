# Ironclad Golem (Rare): лицар у сталевих латах — полірована сталь, темне залізо, кобальтова накидка й плюмаж.
# Унікальні: кірка-клевець (молот замість обуха, лангети, рондель), лицарський меч (хрестовина з вусами, самоцвіт, рікассо)
# і власний ящик-фортеця (вежі по кутах, зубці, щит на фасаді, кільця-ручки, прапорець). Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(steel="#a7b0ba", iron="#4b5059", cobalt="#2f5fb3", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
# ---------- ноги ----------
a("Foot_R","Shin_R","iron",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("ToeCap_R","Shin_R","steel",(2.35,0.8,1.65),(2.6,0.75,0.9),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","steel",(2.15,2.3,-0.2),(2.8,2.3,2.8),eul(ry=4),mirror=True)
a("Knee_R","Shin_R","iron",(2.2,3.3,1.15),(1.7,1.0,0.6),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","iron",(2.0,4.0,-0.25),(2.7,1.7,2.7),eul(ry=-6),mirror=True)
a("Pelvis","Hips","iron",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","steel",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Tabard","Hips","cobalt",(0,4.35,1.55),(2.6,2.3,0.4))
a("Buckle","Hips","iron",(0,5.45,1.75),(0.9,0.62,0.3))
# ---------- корпус: кіраса, накидка ----------
a("Torso","Torso","steel",(0,7.5,-0.3),(7.2,4.2,4.2))
a("Chest","Torso","steel",(0,9.6,-0.35),(8.4,1.6,4.6))
a("ChestCloth","Torso","cobalt",(0,7.3,1.95),(4.0,3.2,0.4))
a("Emblem","Torso","steel",(0,7.75,2.2),(1.5,1.5,0.3))
a("EmblemTip","Torso","steel",(0,6.95,2.2),(1.05,1.05,0.26),eul(rz=45))
for i, (x, z) in enumerate([(-3.3,1.95),(3.3,1.95),(-2.45,1.95),(2.45,1.95)], 1):
    a(f"Rivet{i}","Torso","iron",(x,9.55,z),(0.38,0.38,0.38))
a("Cape","Torso","cobalt",(0,6.9,-2.6),(5.6,5.4,0.35))
a("CapeClasp_R","Torso","iron",(2.5,9.6,-2.75),(0.7,0.7,0.3),mirror=True)
# ---------- голова: шолом з піднятим забралом і плюмажем ----------
a("Head","Head","steel",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Jaw","Head","iron",(0,9.98,0.7),(3.4,0.7,2.7))
a("HelmTop","Head","steel",(0,12.75,0.35),(4.4,0.6,3.8))
a("Visor","Head","iron",(0,13.2,1.75),(3.9,0.45,0.9),eul(rx=-25))
a("Plume","Head","cobalt",(0,13.65,-0.2),(0.7,1.1,3.0))
a("PlumeTail","Head","cobalt",(0,13.05,-1.95),(0.6,1.2,0.8),eul(rx=25))
a("CheekGuard_R","Head","iron",(2.15,10.9,0.9),(0.42,2.0,2.4),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.3,2.2514),(1.3,0.32,0.3),eul(rz=6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: наплічники з ламелями, наручі, латні рукавиці ----------
a("Shoulder_R","UpperArm_R","steel",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","iron",(5.15,10.95,-0.3),(3.7,0.45,3.9),eul(rz=3),mirror=True)
a("Lame_R","UpperArm_R","steel",(5.55,8.95,-0.3),(3.0,0.42,3.8),eul(rz=10),mirror=True)
a("UpperArm_R","UpperArm_R","iron",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","steel",(5.55,5.75,0.0014),(2.8,2.4,2.9),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","iron",(5.55,6.62,0.0014),(3.0,0.4,3.1),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","steel",(5.65,3.45,0.1014),(3.4,2.6,3.4),eul(ry=6.875))
sub(fist,"Knuckles_R","iron",(0.15,0.3,1.72),(2.8,0.9,0.4))
sub(fist,"Thumb_R","steel",(-1.8,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6))
sub(fist,"FistBand_R","cobalt",(0,1.35,0),(3.0,0.3,3.0)); mir(4)

# ---------- кірка-клевець: молот замість обуха, лангети, рондель ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","iron"); P("Grip","cobalt"); P("Pommel","steel"); P("Band","steel")
sub(HN,"Langet1","steel",(0.36,3.0,0),(0.14,1.7,0.5))
sub(HN,"Langet2","steel",(-0.36,3.0,0),(0.14,1.7,0.5))
sub(HN,"Rondel","cobalt",(0,-1.7,0),(1.15,0.2,1.15),eul(ry=45))
HD = P("Head","steel",(1.6,1.8,2.0))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"steel")
P("PickGlint","light")
sub(HD,"Hammer","iron",(0,0,-1.5),(1.4,1.4,1.1))
sub(HD,"HammerBand","cobalt",(0,0,-1.25),(1.55,1.55,0.3))
sub(HD,"HammerFace","steel",(0,0,-2.15),(1.65,1.65,0.32))
# ---------- лицарський меч: хрестовина з вусами, самоцвіт, рікассо ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","cobalt"); S("SwordPommelTop","steel"); S("SwordGrip","cobalt")
S("SwordCoil1","steel"); S("SwordCoil2","steel")
G = S("SwordGuard","steel",(0.8,0.6,3.8))
sub(G,"QuillonR","steel",(0,0.42,2.05),(0.7,0.95,0.55))
sub(G,"QuillonL","steel",(0,0.42,-2.05),(0.7,0.95,0.55))
sub(G,"GuardGem","cobalt",(0,0,0),(1.0,0.75,0.75),eul(ry=45))
BL = S("SwordBlade","steel",(0.45,6.6,1.5)); S("SwordEdge","light",(0.3,6.1,1.85)); S("SwordFuller","iron",(0.6,4.4,0.3))
sub(BL,"Ricasso","iron",(0,-2.95,0),(0.62,0.6,1.1))
S("SwordTip","steel")

# ---------- ящик-фортеця (у стадах, півот = центр дна; X — довжина, як у ClayCarryBox) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","iron",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","iron",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","steel",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","steel",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","steel",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","steel",(-1.85,0.98,0),(0.3,1.7,1.66))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Tower" + t, "iron", (2.0*sx, 1.15, 1.05*sz), (0.8, 2.3, 0.8))
        B("TowerCap" + t, "steel", (2.0*sx, 2.4, 1.05*sz), (0.95, 0.25, 0.95))
for i, x in enumerate((-0.9, 0.0, 0.9), 1):
    B(f"MerlonF{i}", "steel", (x, 2.0, 1.0), (0.5, 0.4, 0.34))
    B(f"MerlonB{i}", "steel", (x, 2.0, -1.0), (0.5, 0.4, 0.34))
B("MerlonR","steel",(1.85,2.0,0),(0.34,0.4,0.5)); B("MerlonL","steel",(-1.85,2.0,0),(0.34,0.4,0.5))
for i, x in enumerate((-1.25, 1.25), 1):
    B(f"StrapF{i}","iron",(x,0.975,1.19),(0.26,1.55,0.14)); B(f"StrapB{i}","iron",(x,0.975,-1.19),(0.26,1.55,0.14))
    for j, y in enumerate((0.5, 1.45), 1):
        B(f"RivetF{i}{j}","steel",(x,y,1.29),(0.16,0.16,0.1))
B("Shield","cobalt",(0,1.15,1.2),(0.9,0.85,0.16))
B("ShieldTip","cobalt",(0,0.72,1.155),(0.6,0.6,0.14),eul(rz=45))
B("ShieldBarV","steel",(0,1.0,1.31),(0.14,0.9,0.1)); B("ShieldBarH","steel",(0,1.25,1.31),(0.6,0.14,0.16))
for sx, nm in ((1,"R"),(-1,"L")):
    B("Mount"+nm,"iron",(2.43*sx,1.3,0),(0.1,0.25,0.9))
    B("RingPostA"+nm,"iron",(2.52*sx,1.1,0.3),(0.12,0.55,0.12)); B("RingPostB"+nm,"iron",(2.52*sx,1.1,-0.3),(0.12,0.55,0.12))
    B("RingBottom"+nm,"iron",(2.52*sx,0.83,0),(0.2,0.12,0.84))
B("FlagPole","steel",(2.0,2.8,1.05),(0.1,0.6,0.1))
B("Flag","cobalt",(1.68,2.92,1.05),(0.5,0.32,0.06))
# щит, заклепки й прапорець — на зовнішньому боці (у руках носія +Z дивиться на голема)
for b in g.blocks:
    if b["group"] == "Box" and b["name"].startswith(("Shield", "RivetF", "Flag")):
        b["pos"] = b["pos"] * np.array([1, 1, -1])

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export("/home/claude/ironclad/IroncladGolemData.lua", [
        "-- Ironclad Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано ironclad_golem_generator.py.",
        "-- Скелет = Clay … Lantern (21 кістка). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик носія в стадах (півот = центр дна), не перефарбований ClayCarryBox."])
