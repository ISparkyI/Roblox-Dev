# Cloud Golem (Exclusive, тижнева нагорода — 28-й день Daily, Miner 150 % best; рівень Mushroom, найбільший із тижневих):
# пухка хмаринка. Тіло з хмарних блоків різного розміру, блакитний пояс, рожеві щічки; на спині — веселка з 5 вкладених дуг ∩
# (приглушені кольори, без хреста); дві маленькі хмаринки-сателіти ширяють поруч (bob). Кірка з голівкою-хмаринкою,
# меч із небесним лезом і хмаринками на гарді; ящик — блакитна скриня з хмаринками й ручками-хмаринками. Без Neon. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(cloud="#e6ecf6", cloudShade="#bccbe2", sky="#7fb6ff", skyDark="#4f86d1",
               red="#e07a74", orange="#ee a85e".replace(" ", ""), yellow="#efd36e", green="#80c47c", blue="#72a9e3",
               light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))

# ---------- ноги ----------
a("Foot_R","Shin_R","cloudShade",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","cloud",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinPuff_R","Shin_R","cloud",(2.25,2.6,0.2),(2.9,1.0,2.4),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","cloud",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","cloudShade",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","sky",(0,5.45,-0.3),(6.6,0.5,3.9))
# ---------- корпус: пухкі хмарні виступи ----------
a("Torso","Torso","cloud",(0,7.5,-0.3),(7.4,4.2,4.2))
a("BellyPuff","Torso","cloud",(0.4,7.1,-0.3),(5.6,2.6,4.9))
a("SidePuff_R","Torso","cloud",(3.0,8.1,-0.4),(2.0,2.2,3.6),mirror=True)
a("BellyDot","Torso","cloudShade",(-1.3,6.6,2.17),(1.2,0.9,0.24))
a("Chest","Torso","cloud",(0,9.6,-0.35),(8.6,1.6,4.7))
# ---------- веселка на спині: 5 вкладених дуг ∩ ----------
RB = ("red", "orange", "yellow", "green", "blue")
for i, col in enumerate(RB):
    hw, top = 2.6 - 0.3 * i, 13.6 - 0.3 * i
    h = top - 10.4
    a(f"Rainbow{i+1}PostR","Torso",col,(hw - 0.15, 10.4 + h / 2, -2.55),(0.3, h, 0.4))
    a(f"Rainbow{i+1}PostL","Torso",col,(-hw + 0.15, 10.4 + h / 2, -2.55),(0.3, h, 0.4))
    a(f"Rainbow{i+1}Top","Torso",col,(0, top - 0.15, -2.55),(2 * hw - 0.6, 0.3, 0.4))
a("RainbowCloudR","Torso","cloud",(2.3,10.8,-2.55),(1.6,0.7,0.9))   # хмаринки біля основи веселки
a("RainbowCloudL","Torso","cloud",(-2.3,10.8,-2.55),(1.6,0.7,0.9))
# ---------- голова: хмарні пухирці зверху ----------
a("Head","Head","cloud",(0,11.15,0.5014),(4.0,2.7,3.4))
a("HeadPuffA","Head","cloud",(-0.8,12.75,0.3),(2.0,0.9,2.6))
a("HeadPuffB","Head","cloud",(0.9,12.95,0.4),(1.6,1.2,2.2))
a("HeadPuffC","Head","cloudShade",(0.05,13.05,0.1),(1.0,0.7,1.4))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","skyDark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)   # рівні підняті брови + усмішка
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: хмарні плечі ----------
a("Shoulder_R","UpperArm_R","cloud",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("ShoulderPuff_R","UpperArm_R","cloud",(5.3,11.1,-0.5),(2.4,0.7,2.8),eul(rz=3),mirror=True)
a("UpperArm_R","UpperArm_R","cloudShade",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","cloud",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","sky",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","cloud",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","cloudShade",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"Thumb_R","cloud",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(3)
# ---------- хмаринки-сателіти (ширяють) ----------
SAT1 = [a("MiniCloudA","Torso","cloud",(-8.4,6.8,-1.6),(1.5,0.7,1.1)), a("MiniCloudA2","Torso","cloud",(-8.1,7.25,-1.6),(0.8,0.5,0.8))]
SAT2 = [a("MiniCloudB","Torso","cloud",(6.8,12.9,-1.6),(1.4,0.66,1.0)), a("MiniCloudB2","Torso","cloud",(7.05,13.3,-1.6),(0.7,0.46,0.7))]
SAT1 = [b["name"] for b in SAT1]; SAT2 = [b["name"] for b in SAT2]
g.free_parts = tuple(SAT1 + SAT2)
g.fx.append(dict(kind="bob", parts=SAT1, axis=(0, 1, 0), amp=0.25, speed=1.4))
g.fx.append(dict(kind="bob", parts=SAT2, axis=(0, 1, 0), amp=0.22, speed=1.7, phase=2.0))
g.fx.append(dict(kind="sway", parts=SAT1 + SAT2, pivot=(0, 10, -0.3), axis=(0, 1, 0), amp=0.12, speed=0.9, states={"Walk": 1.4, "Run": 1.8}))

# ---------- кірка: голова-хмаринка, небесні леза ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","skyDark"); P("Grip","cloud"); P("Band","yellow"); P("Pommel","cloud")
HD = P("Head","cloud"); P("HeadRound","cloudShade")
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"sky")
P("Back1","cloud"); P("Back2","cloud"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"HeadPuff{nm}", "cloud", (0.9*side, 0.3, -0.35), (0.24, 0.8, 0.9))
    sub(HD, f"HeadStripe{nm}", "sky", (0.88*side, -0.55, 0.3), (0.18, 0.3, 1.0))
# ---------- меч: небесне лезо, хмаринки на гарді ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","cloud"); S("SwordPommelTop","yellow"); S("SwordGrip","skyDark")
S("SwordCoil1","cloud"); S("SwordCoil2","cloud")
G = S("SwordGuard","cloudShade")
sub(G,"GuardCloudR","cloud",(0,0,1.2),(0.8,0.8,0.9))
sub(G,"GuardCloudL","cloud",(0,0,-1.2),(0.8,0.8,0.9))
S("SwordBlade","sky"); S("SwordEdge","light"); S("SwordFuller","skyDark"); S("SwordTip","sky")

# ---------- ящик: блакитна скриня з хмаринками (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","skyDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","skyDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","sky",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","sky",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","sky",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","sky",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","cloud",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","cloud",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","cloud",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","cloud",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "skyDark", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
B("CloudBigB","cloud",(-0.6,0.95,-1.2),(1.4,0.6,0.14)); B("CloudTopB","cloud",(-0.75,1.35,-1.23),(0.7,0.3,0.14))
B("CloudSmallB","cloud",(0.85,0.6,-1.2),(0.9,0.4,0.14))
B("CloudBigF","cloud",(0.4,0.95,1.2),(1.2,0.5,0.14))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-хмаринки
    B("HandlePost"+nm,"skyDark",(2.2*sx,1.2,0),(0.5,0.26,0.4))
    B("HandleCloud"+nm,"cloud",(2.6*sx,1.25,0),(0.4,0.6,1.1))
    B("HandlePuff"+nm,"cloud",(2.6*sx,1.6,0.15),(0.36,0.32,0.6))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/cloud/CloudGolemData.lua"
    g.export(out, [
        "-- Cloud Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано cloud_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). fx — хмаринки-сателіти ширяють (bob + sway). Веселка — 5 дуг ∩ на спині. Box — блакитна скриня в стадах."])
