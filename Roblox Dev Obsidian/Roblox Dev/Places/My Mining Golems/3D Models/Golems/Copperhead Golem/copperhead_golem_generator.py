# Copperhead Golem: темна порода з мідною жилою, голова — мідний самородок-«шолом» з патиною. Скелет Clay (21 кістка).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(rock="#4b4440", copper="#d9822b", patina="#4fb3a0", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4",
               coppL="#f0a85a"),
          bones={"Brow_R": (0.9,12.45,2.2014), "Brow_L": (-0.9,12.3,2.2014),
                 "Mouth": (0,10.53,2.3014), "MouthCorner_R": (0.8,10.62,2.3014), "MouthCorner_L": (-0.8,10.62,2.3014)})
a = g.add
# ---------- ноги ----------
a("Foot_R","Shin_R","rock",(2.15,0.5,0.15),(3.0,1.0,3.5),eul(ry=5),mirror=True)
a("ToeCap_R","Shin_R","copper",(2.3,0.62,1.85),(2.0,0.8,0.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","rock",(2.1,2.1,-0.2),(2.5,2.4,2.5),eul(ry=4),mirror=True)
a("ShinPlate_R","Shin_R","copper",(2.2,2.2,1.1),(1.6,1.6,0.3),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","rock",(2.0,3.95,-0.25),(2.7,1.7,2.7),eul(ry=-6),mirror=True)
a("KneeNugget_R","Shin_R","copper",(2.6,3.3,1.05),(0.7,0.6,0.5),eul(ry=20,rz=-15),mirror=True)
a("Pelvis","Hips","rock",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","copper",(0,5.25,-0.35),(6.0,0.4,3.6))
# ---------- корпус ----------
a("Torso","Torso","rock",(0,7.4,-0.3),(7.0,4.0,4.0))
a("Chest","Torso","rock",(0,9.45,-0.4),(8.0,1.8,4.6))
a("Vein1","Torso","copper",(-1.2,8.2,1.75),(0.35,2.6,0.2),eul(rz=25))
a("Vein2","Torso","copper",(-0.3,7.0,1.82),(1.8,0.35,0.2),eul(rz=-15))
a("Vein3","Torso","copper",(1.5,8.4,1.75),(0.35,1.8,0.2),eul(rz=-30))
a("ChestNugget","Torso","patina",(1.9,6.6,1.85),(1.0,0.8,0.5),eul(rz=15))
a("ChestNugget2","Torso","copper",(-2.3,9.3,2.0),(0.9,0.7,0.5),eul(rz=-10))
a("BackNugget1","Torso","copper",(1.4,9.0,-2.5),(1.4,1.1,0.7),eul(ry=-8,rz=12))
a("BackNugget2","Torso","patina",(-1.5,7.5,-2.45),(1.2,0.9,0.6),eul(rz=-15))
a("BackNugget3","Torso","copper",(-0.4,10.25,-2.55),(1.0,0.8,0.6),eul(rz=30))
a("BackVein","Torso","copper",(0.3,6.6,-2.38),(2.4,0.3,0.2),eul(rz=8))
# ---------- голова: мідний «шолом» ----------
a("Head","Head","copper",(0,11.3,0.4014),(4.4,3.0,3.6))
a("Jaw","Head","copper",(0,10.0,0.7),(4.0,0.9,3.2))
a("HeadTop","Head","copper",(0,12.95,0.4),(4.0,0.5,3.2))
a("Crest","Head","coppL" if False else "copper",(0,13.1,0.2),(1.2,0.7,3.0))
a("PatinaSide","Head","patina",(2.25,11.6,0.6),(0.2,0.9,1.4))
a("PatinaTop","Head","patina",(-1.0,13.25,0.9),(1.2,0.2,1.0))
a("PatinaBack","Head","patina",(0.8,11.7,-1.45),(1.4,0.8,0.2))
# обличчя
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.45,2.2514),(1.3,0.32,0.3),eul(rz=-8))
a("Brow_L","Brow_L","dark",(-0.9,12.3,2.2514),(1.3,0.32,0.3),eul(rz=-12))
a("Cheek_R","Head","pink",(1.6,10.85,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.53,2.3014),(1.4,0.26,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.8,10.62,2.3014),(0.3,0.26,0.5))
a("MouthCorner_L","MouthCorner_L","dark",(-0.8,10.62,2.3014),(0.3,0.26,0.5))
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","rock",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
pl = a("ShoulderPlate_R","UpperArm_R","copper",(5.1,10.9,-0.3),(3.4,0.5,3.6),eul(rz=4))
g.sub(pl,"RivetA_R","patina",(-1.2,0.3,1.3),(0.3,0.2,0.3))
g.sub(pl,"RivetB_R","patina",(1.2,0.3,1.3),(0.3,0.2,0.3))
for b in list(g.blocks[-3:]):
    g.blocks.append(dict(b, name=b["name"][:-2]+"_L", bone="UpperArm_L", pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
a("ShoulderNugget_R","UpperArm_R","copper",(5.6,11.45,-0.6),(1.0,0.7,1.0),eul(ry=30,rz=-10),mirror=True)
a("UpperArm_R","UpperArm_R","rock",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("ArmVein_R","UpperArm_R","copper",(6.44,8.1,-0.2),(0.2,2.0,0.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","rock",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","copper",(5.55,5.3,0.0014),(2.9,0.8,3.0),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","rock",(5.65,3.45,0.1014),(3.2,2.5,3.2),eul(ry=6.875))
g.sub(fist,"Knuckles_R","copper",(0.15,0.35,1.72),(2.6,0.9,0.4))
g.sub(fist,"Thumb_R","rock",(-1.7,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6))
for b in list(g.blocks[-3:]):
    g.blocks.append(dict(b, name=b["name"][:-2]+"_L", bone="Forearm_L", pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))

# ---------- кірка ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
H = P("Handle","rock"); P("Grip","rock"); P("Pommel","copper"); P("Band","copper")
for i, y in enumerate([-3.6, -2.9, 0.6, 2.4], 1):
    g.sub(H, f"Wire{i}", "copper", (0, y, 0), (0.8, 0.22, 0.8), eul(ry=45))
HD = P("Head","copper"); P("HeadRound","copper")
g.sub(HD, "HeadPatina", "patina", (-0.86, 0.3, -0.3), (0.3, 0.8, 0.9))
g.sub(HD, "HeadPatina2", "patina", (0.3, -0.4, 1.06), (0.7, 0.5, 0.3))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n, "coppL")
P("Back1","copper"); P("Back2","copper"); P("PickGlint","light"); P("Chip","patina")
# ---------- меч ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","copper"); S("SwordPommelTop","patina"); S("SwordGrip","rock")
S("SwordCoil1","copper"); S("SwordCoil2","copper")
G = S("SwordGuard","copper")
g.sub(G, "GuardRivet1", "coppL", (-0.5, 0, 1.0), (0.2, 0.3, 0.3))
g.sub(G, "GuardRivet2", "coppL", (-0.5, 0, -1.0), (0.2, 0.3, 0.3))
BL = S("SwordBlade","copper", (0.45,6.6,1.55)); S("SwordEdge","coppL", (0.3,6.1,1.9)); S("SwordFuller","rock")
g.sub(BL, "BladePatina1", "patina", (0, -1.2, 0.45), (0.55, 0.8, 0.4))
g.sub(BL, "BladePatina2", "patina", (0, 1.6, -0.5), (0.55, 0.6, 0.35))
S("SwordTip","coppL")

if __name__ == "__main__":
    g.report()
    g.export("/home/claude/copperhead/CopperheadGolemData.lua", [
        "-- Copperhead Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано copperhead_golem_generator.py.",
        "-- Скелет = Clay / Gravel / Mossback (21 кістка; обличчя зсунуте: широка усмішка, права брова вище). Pickaxe / Sword — у кулаці Fist_L."])
