# Rustbolt Golem: старе клепане залізо в іржі, болти в шиї й плечах, величезні кулаки. Скелет Clay (21 кістка).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(iron="#5b5450", rust="#a4532a", steel="#a9adb0", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"Brow_R": (0.9,12.1,2.2014), "Brow_L": (-0.9,12.1,2.2014),
                 "Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.6,10.6,2.3014), "MouthCorner_L": (-0.6,10.38,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
# ---------- ноги ----------
a("Foot_R","Shin_R","iron",(2.25,0.55,0.2),(3.4,1.1,3.9),eul(ry=5),mirror=True)
a("ToeRust_R","Shin_R","rust",(2.35,0.7,2.0),(2.2,0.7,0.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","iron",(2.15,2.3,-0.2),(2.8,2.3,2.8),eul(ry=4),mirror=True)
a("ShinRust_R","Shin_R","rust",(3.6,2.0,-0.2),(0.2,1.4,1.2),eul(ry=4),mirror=True)
a("KneeBolt_R","Shin_R","steel",(2.3,3.3,1.3),(0.7,0.7,0.4),eul(rz=45),mirror=True)
a("Thigh_R","Thigh_R","iron",(2.0,4.0,-0.25),(2.9,1.7,2.9),eul(ry=-6),mirror=True)
a("Pelvis","Hips","iron",(0,4.85,-0.3),(6.4,1.6,3.6))
# ---------- корпус ----------
a("Torso","Torso","iron",(0,7.4,-0.3),(7.4,4.0,4.2))
a("Chest","Torso","iron",(0,9.45,-0.4),(8.6,1.8,4.8))
cp = a("ChestPlate","Torso","iron",(-1.6,8.15,1.95),(2.6,2.4,0.4))
for i, x in enumerate([-0.9, 0.0, 0.9], 1):
    sub(cp, f"Rivet{i}", "steel", (x, 0.85, 0.27), (0.3, 0.3, 0.2))
a("LoosePlate","Torso","rust",(1.7,7.6,1.95),(2.2,2.0,0.3),eul(rx=10,rz=-18))
a("RustStreak","Torso","rust",(-0.6,6.4,1.88),(0.4,1.6,0.2))
a("BackPlate","Torso","iron",(0,8.0,-2.6),(5.0,3.2,0.5))
a("BackBolt1","Torso","steel",(1.6,8.9,-2.9),(0.6,0.6,0.4),eul(rz=45))
a("BackBolt2","Torso","steel",(-1.6,8.9,-2.9),(0.6,0.6,0.4),eul(rz=45))
a("BackRust","Torso","rust",(0.4,6.8,-2.88),(2.4,0.9,0.2),eul(rz=6))
# ---------- голова-каска ----------
a("Head","Head","iron",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Jaw","Head","iron",(0,10.05,0.75),(3.6,0.7,2.7))
a("Visor","Head","iron",(0,12.55,1.05),(4.3,0.45,2.8))
a("RustTop","Head","rust",(-0.9,12.6,-0.3),(1.6,0.3,1.4))
a("NeckBolt_R","Head","steel",(2.3,10.6,0.3),(1.0,0.4,0.4),mirror=True)
a("NeckBoltHead_R","Head","steel",(2.85,10.6,0.3),(0.3,0.75,0.75),eul(rx=45),mirror=True)
a("BoltRust_R","Head","rust",(2.07,9.9,0.3),(0.2,0.8,0.5),mirror=True)
# обличчя: козирок, примружене праве око, бурчливий рот
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.48,2.3764),(0.18,0.165,0.25),mirror=True)
a("Lid_R","Head","iron",(0.85,11.9,2.35),(1.32,0.35,0.25))
a("Brow_R","Brow_R","dark",(0.9,12.1,2.24),(1.3,0.3,0.3),eul(rz=12))
a("Brow_L","Brow_L","dark",(-0.9,12.1,2.24),(1.3,0.3,0.3),eul(rz=-12))
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.26,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.6,10.6,2.3014),(0.3,0.3,0.5))
a("MouthCorner_L","MouthCorner_L","dark",(-0.6,10.38,2.3014),(0.3,0.3,0.5))
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","iron",(5.1,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("ShoulderBolt_R","UpperArm_R","steel",(5.4,10.95,-0.3),(0.8,0.4,0.8),eul(ry=45),mirror=True)
a("ShoulderRust_R","UpperArm_R","rust",(7.0,9.6,-0.3),(0.2,1.2,1.6),eul(rz=3),mirror=True)
a("UpperArm_R","UpperArm_R","iron",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","iron",(5.6,5.8,0.0014),(3.0,2.5,3.1),eul(ry=-6),mirror=True)
a("ForearmBand_R","Forearm_R","rust",(5.6,6.75,0.0014),(3.2,0.5,3.3),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","iron",(5.65,3.45,0.1014),(3.6,2.8,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","steel",(0.15,0.3,1.82),(3.0,1.0,0.4))
sub(fist,"FistRust_R","rust",(1.82,-0.2,0),(0.2,1.4,2.0))
sub(fist,"Thumb_R","iron",(-1.9,0.1,1.1),(0.55,1.2,1.0),eul(rz=-6)); mir(4)

# ---------- кірка ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","iron"); P("Grip","rust"); P("Pommel","steel"); P("Band","steel")
HD = P("Head","iron"); P("HeadRound","rust")
sub(HD,"HeadBolt1","steel",(-1.0,0,0),(0.3,0.8,0.8),eul(rx=45))
sub(HD,"HeadBolt2","steel",(1.0,0,0),(0.3,0.8,0.8),eul(rx=45))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"steel")
P("Back1","iron"); P("Back2","rust"); P("PickGlint","light"); P("Chip","rust")
# ---------- меч ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","steel"); S("SwordPommelTop","rust"); S("SwordGrip","iron")
S("SwordCoil1","rust"); S("SwordCoil2","rust")
G = S("SwordGuard","iron")
sub(G,"GuardBolt1","steel",(-0.5,0,1.0),(0.2,0.35,0.35))
sub(G,"GuardBolt2","steel",(-0.5,0,-1.0),(0.2,0.35,0.35))
BL = S("SwordBlade","iron",(0.5,6.6,1.7)); S("SwordEdge","steel",(0.32,6.1,2.05)); S("SwordFuller","rust",(0.7,4.2,0.4))
for i, y in enumerate([-1.2, 1.4], 1):
    sub(BL, f"Notch{i}", "rust", (0, y, 1.05), (0.42, 0.4, 0.3))
S("SwordTip","steel",(0.4,0.95,0.85))

if __name__ == "__main__":
    g.report()
    g.export("/home/claude/rustbolt/RustboltGolemData.lua", [
        "-- Rustbolt Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано rustbolt_golem_generator.py.",
        "-- Скелет = Clay … Flint (21 кістка). Pickaxe / Sword — у кулаці Fist_L."])
