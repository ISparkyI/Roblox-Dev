# Flint Golem: колотий кремінь — темні грані-сколи, біла крейдяна кірка, гострі уламки, іскри на кулаках (7-й колір — виняток). Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(flint="#3a3f47", facet="#6b7380", chalk="#e8e2d4", spark="#ff9a2e",
               light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.46,2.3014), "MouthCorner_R": (0.6,10.6,2.3014), "MouthCorner_L": (-0.55,10.5,2.3014)})
a, sub = g.add, g.sub
def mir(n):  # дзеркалити останні n блоків (_R -> _L)
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
# ---------- ноги ----------
a("Foot_R","Shin_R","flint",(2.1,0.45,0.3),(2.6,0.9,3.4),eul(ry=5),mirror=True)
a("ToePoint_R","Shin_R","facet",(2.15,0.5,2.05),(1.4,0.7,1.4),eul(ry=45),mirror=True)
sh = a("Shin_R","Shin_R","flint",(2.1,2.15,-0.2),(2.1,2.4,2.1),eul(ry=4))
sub(sh,"CalfCrust_R","chalk",(0,0.2,-1.17),(1.6,1.4,0.3))
sub(sh,"ShinFacet_R","facet",(0.1,0.1,1.17),(1.4,1.6,0.3),eul(rz=10)); mir(3)
a("Thigh_R","Thigh_R","flint",(2.0,3.95,-0.25),(2.3,1.7,2.3),eul(ry=-6),mirror=True)
a("KneeShard_R","Shin_R","facet",(2.4,3.3,1.0),(0.7,1.0,0.5),eul(rx=25,rz=-15),mirror=True)
a("Pelvis","Hips","flint",(0,4.85,-0.3),(4.8,1.5,3.0))
# ---------- корпус (подався вперед) ----------
T = a("Torso","Torso","flint",(0,7.4,-0.1),(6.2,4.0,3.6),eul(rx=6))
C = a("Chest","Torso","flint",(0,9.4,0.15),(7.4,1.8,4.0),eul(rx=6))
sub(T,"ChestFacet1","facet",(-1.5,1.3,1.9),(2.0,1.6,0.4),eul(rz=12))
sub(T,"ChestFacet2","facet",(1.6,-0.2,1.9),(1.8,1.8,0.4),eul(rz=-18))
sub(T,"BellyFacet","facet",(-0.6,-1.4,1.85),(1.5,1.0,0.3),eul(rz=8))
sub(C,"ChestCrust","chalk",(2.0,0.0,2.1),(1.3,0.8,0.4),eul(rz=8))
sub(T,"BackShard1","facet",(0.9,1.0,-1.95),(1.2,2.4,0.8),eul(rx=-30,rz=15))
sub(T,"BackShard2","flint",(-1.1,0.2,-1.95),(1.0,2.0,0.7),eul(rx=-35,rz=-20))
sub(T,"BackShard3","facet",(-0.2,2.0,-2.0),(0.8,1.8,0.6),eul(rx=-40,rz=5))
sub(T,"BackCrust","chalk",(0.3,-1.2,-1.9),(2.0,0.8,0.4),eul(rz=5))
# ---------- голова-наконечник ----------
a("Head","Head","flint",(0,11.15,0.5014),(3.7,2.7,3.4))
a("Jaw","Head","facet",(0,10.08,0.7),(3.0,0.7,2.8))
a("HeadTip","Head","facet",(0,12.7,0.35),(1.9,1.9,3.0),eul(rz=45))
a("HeadCrest","Head","chalk",(0,13.55,0.3),(0.8,0.8,3.15),eul(rz=45))
a("HeadFacet_R","Head","facet",(1.85,11.4,0.2),(0.4,1.8,2.6),eul(ry=8,rz=-12),mirror=True)
# обличчя (як у Gravel: зухвала усмішка набік; брови різко до центру)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.3,2.2514),(1.3,0.32,0.3),eul(rz=16),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0.05,10.46,2.3014),(1.0,0.26,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.6,10.6,2.3014),(0.3,0.26,0.5))
a("MouthCorner_L","MouthCorner_L","dark",(-0.55,10.5,2.3014),(0.3,0.26,0.5))
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","flint",(5.0,9.85,-0.3),(2.8,1.6,3.0),eul(rz=4),mirror=True)
a("ShoulderShard_R","UpperArm_R","facet",(5.6,11.0,-0.8),(0.9,2.4,1.4),eul(rx=-20,rz=-25),mirror=True)
a("ShoulderShard2_R","UpperArm_R","flint",(4.6,10.9,-1.4),(0.7,1.8,1.0),eul(rx=-35,rz=-10),mirror=True)
a("ShoulderCrust_R","UpperArm_R","chalk",(5.0,10.72,0.4),(2.2,0.4,1.4),eul(rz=4),mirror=True)
a("UpperArm_R","UpperArm_R","flint",(5.25,8.0,-0.3),(2.0,2.5,2.1),eul(ry=4),mirror=True)
a("ElbowShard_R","Forearm_R","facet",(6.2,6.9,-1.0),(0.6,1.6,0.8),eul(rx=-40,rz=-20),mirror=True)
a("Forearm_R","Forearm_R","flint",(5.55,5.75,0.0014),(2.4,2.3,2.6),eul(ry=-6),mirror=True)
a("ForearmFacet_R","Forearm_R","facet",(6.82,5.8,0.2),(0.3,1.6,1.8),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","flint",(5.65,3.45,0.1014),(3.0,2.4,3.0),eul(ry=6.875))
sub(fist,"Knuckles_R","facet",(0.15,0.3,1.62),(2.5,0.9,0.4))
sub(fist,"KnuckleEdge_R","chalk",(0.15,0.85,1.62),(2.3,0.25,0.5))
sub(fist,"Thumb_R","flint",(-1.6,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6))
sub(fist,"Spark1_R","spark",(0.9,0.45,1.95),(0.3,0.3,0.3),eul(rz=45))
sub(fist,"Spark2_R","spark",(1.45,1.35,1.55),(0.22,0.22,0.22),eul(rz=45)); mir(6)

# ---------- кірка ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","flint"); P("Grip","flint"); P("Pommel","chalk"); P("Band","facet")
HD = P("Head","flint",(1.5,1.8,2.1)); P("HeadRound","facet")
sub(HD,"HeadCrust","chalk",(0,0.35,0),(1.7,0.5,2.3))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"facet")
P("Back1","flint"); P("Back2","facet"); P("PickGlint","spark"); P("Chip","chalk")
# ---------- меч ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","chalk"); S("SwordPommelTop","facet"); S("SwordGrip","flint")
S("SwordCoil1","facet"); S("SwordCoil2","facet")
G = S("SwordGuard","flint")
sub(G,"GuardCrust","chalk",(0,0.45,0),(1.0,0.3,2.6))
BL = S("SwordBlade","flint",(0.4,6.6,1.5)); S("SwordEdge","facet",(0.3,6.1,1.85)); S("SwordFuller","chalk",(0.6,4.2,0.3))
for i, y in enumerate([-1.6, 0.2, 2.0], 1):
    sub(BL, f"EdgeChip{i}", "facet", (0, y, 0.98), (0.36, 0.7, 0.36), eul(rx=45))
TP = S("SwordTip","facet")
sub(TP,"TipSpark","spark",(0,0.4,0.3),(0.42,0.3,0.3),eul(rx=45))

if __name__ == "__main__":
    g.report()
    g.export("/home/claude/flint/FlintGolemData.lua", [
        "-- Flint Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано flint_golem_generator.py.",
        "-- Скелет = Clay / Gravel / Mossback / Copperhead (21 кістка). 7 кольорів у тілі — виняток: іскри на кулаках. Pickaxe / Sword — у кулаці Fist_L."])
