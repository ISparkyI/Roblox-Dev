# Granite Golem: полірований рожево-сірий граніт з чорно-білими вкрапленнями, монументальний вартовий-статуя. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(gran="#b59a93", granD="#7d6a66", polish="#d8c3bb", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"MouthCorner_R": (0.6,10.52,2.3014), "MouthCorner_L": (-0.6,10.52,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
F = (0.3, 0.3, 0.2)   # вкраплення
# ---------- ноги ----------
a("Foot_R","Shin_R","granD",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","gran",(2.15,2.3,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","polish",(2.15,2.9,-0.2),(2.9,0.4,2.9),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","gran",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("FleckShin_R","Shin_R","light",(2.0,1.8,1.2),F)
a("FleckShin_L","Shin_L","dark",(-2.3,2.2,1.2),F)
a("Pelvis","Hips","granD",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","polish",(0,5.45,-0.3),(6.6,0.5,3.9))
# ---------- корпус ----------
a("Torso","Torso","gran",(0,7.5,-0.3),(7.2,4.2,4.2))
a("Chest","Torso","gran",(0,9.6,-0.35),(8.4,1.6,4.6))
a("ChestPlate","Torso","polish",(0,8.0,1.9),(4.0,2.6,0.4))
a("Emblem","Torso","granD",(0,8.0,2.15),(1.2,1.2,0.3),eul(rz=45))
a("BackSlab","Torso","granD",(0,8.0,-2.55),(5.4,3.6,0.6))
for i, (x, y, z, c) in enumerate([(-2.6,6.0,1.85,"dark"),(2.7,6.4,1.85,"light"),(2.3,5.75,1.85,"dark"),
                                   (-3.2,9.7,2.0,"light"),(3.0,10.0,2.0,"dark"),(0.4,10.1,2.0,"dark"),
                                   (-1.5,7.0,-2.9,"light"),(1.8,9.0,-2.9,"dark"),(0.2,8.3,-2.9,"light")], 1):
    a(f"Fleck{i}","Torso",c,(x,y,z),F if abs(z) < 2.5 else (0.3,0.3,0.2))
# ---------- голова ----------
a("Head","Head","gran",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Jaw","Head","granD",(0,9.98,0.7),(3.4,0.7,2.7))
a("Crown","Head","polish",(0,12.78,0.4),(4.4,0.5,3.6))
a("CrownTop","Head","gran",(0,13.18,0.4),(3.4,0.4,2.8))
a("FleckHead1","Head","dark",(2.05,11.6,0.0),(0.2,0.3,0.3))
a("FleckHead2","Head","light",(-2.05,11.0,1.0),(0.2,0.3,0.3))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","granD",(0.9,12.3,2.2514),(1.3,0.32,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.26,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.6,10.52,2.3014),(0.3,0.3,0.5),mirror=True)
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","granD",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","polish",(5.1,10.95,-0.3),(3.6,0.4,3.8),eul(rz=3),mirror=True)
a("UpperArm_R","UpperArm_R","gran",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("FleckArm_R","UpperArm_R","dark",(5.3,8.3,0.95),F)
a("FleckArm_L","UpperArm_L","light",(-5.1,7.6,0.95),F)
a("Forearm_R","Forearm_R","gran",(5.55,5.75,0.0014),(2.8,2.4,2.9),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","polish",(5.55,6.6,0.0014),(3.0,0.4,3.1),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","granD",(5.65,3.45,0.1014),(3.4,2.6,3.4),eul(ry=6.875))
sub(fist,"Knuckles_R","gran",(0.15,0.3,1.72),(2.8,0.9,0.4))
sub(fist,"Thumb_R","granD",(-1.8,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6))
sub(fist,"FistBand_R","polish",(0,1.35,0),(3.0,0.3,3.0)); mir(4)

# ---------- кірка ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","granD"); P("Grip","gran"); P("Pommel","polish"); P("Band","polish")
HD = P("Head","gran"); P("HeadRound","granD")
sub(HD,"HeadFleck1","dark",(-0.92,0.3,-0.4),(0.2,0.35,0.35))
sub(HD,"HeadFleck2","light",(0.92,-0.3,0.4),(0.2,0.35,0.35))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"polish")
P("Back1","gran"); P("Back2","granD"); P("PickGlint","light"); P("Chip","dark")
# ---------- меч ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","polish"); S("SwordPommelTop","granD"); S("SwordGrip","granD")
S("SwordCoil1","polish"); S("SwordCoil2","polish")
G = S("SwordGuard","granD")
sub(G,"GuardBand","polish",(0,0.45,0),(1.0,0.3,2.6))
BL = S("SwordBlade","gran",(0.45,6.6,1.55)); S("SwordEdge","polish",(0.3,6.1,1.9)); S("SwordFuller","granD")
for i, (y, c) in enumerate([(-1.8,"dark"),(-0.3,"light"),(1.5,"dark")], 1):
    sub(BL, f"BladeFleck{i}", c, (0, y, 0.45 * (-1) ** i), (0.55, 0.3, 0.3))
S("SwordTip","polish")

if __name__ == "__main__":
    g.report()
    g.export("/home/claude/granite/GraniteGolemData.lua", [
        "-- Granite Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано granite_golem_generator.py.",
        "-- Скелет = Clay … Rustbolt (21 кістка). Pickaxe / Sword — у кулаці Fist_L."])
