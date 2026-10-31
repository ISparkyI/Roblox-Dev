# Lantern Golem: закіптюжений камінь з латунною рамою, у грудях світний ліхтар (Neon), шапка-кришка ліхтаря з кільцем.
# Інструменти унікальні: кірка з ліхтарем-кліткою замість обуха, меч зі світним долом і гардою-ліхтариком. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(bones={"Brow_R": (0.9,12.2,2.2014), "Brow_L": (-0.9,12.2,2.2014)}, colors=dict(soot="#3d3a40", brass="#c9a24a", glow="#ffb347", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4",
               iron="#5a5660"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
# ---------- ноги ----------
a("Foot_R","Shin_R","soot",(2.15,0.5,0.15),(3.0,1.0,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","soot",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","brass",(2.1,2.8,-0.2),(2.7,0.35,2.7),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","soot",(2.0,3.95,-0.25),(2.7,1.7,2.7),eul(ry=-6),mirror=True)
a("Pelvis","Hips","soot",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","brass",(0,5.3,-0.35),(6.0,0.4,3.6))
a("Buckle","Hips","glow",(0,5.3,1.58),(0.8,0.5,0.3))
a("HipLantern","Hips","glow",(3.2,4.4,0.85),(0.7,0.9,0.7))
a("HipLanternCap","Hips","brass",(3.2,4.95,0.85),(0.9,0.25,0.9))
a("HipLanternBase","Hips","brass",(3.2,3.88,0.85),(0.8,0.2,0.8))
# ---------- корпус з ліхтарем у грудях ----------
a("Torso","Torso","soot",(0,7.4,-0.3),(7.0,4.0,4.0))
a("Chest","Torso","soot",(0,9.45,-0.4),(7.8,1.8,4.6))
a("LanternGlow","Torso","glow",(0,7.35,1.55),(3.2,2.2,0.6))
for i, x in enumerate([-1.1, 0.0, 1.1], 1):
    a(f"Bar{i}","Torso","brass",(x,7.35,1.95),(0.3,2.8,0.3))
a("BarTop","Torso","brass",(0,8.65,2.0),(3.8,0.3,0.36))
a("BarBottom","Torso","brass",(0,6.05,2.0),(3.8,0.3,0.36))
a("BackGlow","Torso","glow",(0,7.6,-2.25),(2.0,1.4,0.3))
a("BackBar1","Torso","brass",(-0.5,7.6,-2.45),(0.25,1.6,0.25))
a("BackBar2","Torso","brass",(0.5,7.6,-2.45),(0.25,1.6,0.25))
# ---------- голова — кришка ліхтаря з кільцем ----------
a("Head","Head","soot",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","soot",(0,10.0,0.7),(3.4,0.8,2.7))
a("Cap1","Head","brass",(0,12.78,0.45),(4.2,0.5,3.7))
a("Cap2","Head","brass",(0,13.2,0.45),(2.6,0.4,2.4))
a("RingPost_R","Head","brass",(0.65,13.75,0.45),(0.3,0.8,0.35),mirror=True)
a("RingTop","Head","brass",(0,14.25,0.45),(1.7,0.3,0.4))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.2,2.24),(1.3,0.32,0.3),eul(rz=-8),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","soot",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("ShoulderCap_R","UpperArm_R","brass",(5.1,10.9,-0.3),(3.4,0.45,3.6),eul(rz=4),mirror=True)
a("UpperArm_R","UpperArm_R","soot",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","soot",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","brass",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","soot",(5.65,3.45,0.1014),(3.2,2.5,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","brass",(0.15,0.3,1.72),(2.6,0.9,0.4))
sub(fist,"Thumb_R","soot",(-1.7,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6)); mir(3)

# ---------- кірка: ліхтар-клітка замість обуха, світна смуга на лезі ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","soot"); P("Grip","brass"); P("Pommel","glow",(0.8,0.6,0.8)); P("Band","brass")
HD = P("Head","brass",(1.4,1.6,1.8))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"iron")
P("PickGlint","glow")
sub(HD,"CageCore","glow",(0,0,-1.9),(1.0,1.0,1.0))
for i, (x, y) in enumerate([(0.6,0.6),(-0.6,0.6),(0.6,-0.6),(-0.6,-0.6)], 1):
    sub(HD, f"CagePost{i}", "brass", (x, y, -1.9), (0.25, 0.25, 1.5))
sub(HD,"CageCap","brass",(0,0,-2.75),(1.5,1.5,0.3))
sub(HD,"CageBase","brass",(0,0,-1.05),(1.5,1.5,0.25))
sub(HD,"CageRing","brass",(0,0,-3.15),(0.6,0.3,0.4))
# ---------- меч: світний дол, гарда-ліхтарик, полум'я на вістрі ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","glow",(0.85,0.66,0.85)); S("SwordPommelTop","brass"); S("SwordGrip","soot")
S("SwordCoil1","brass"); S("SwordCoil2","brass")
G = S("SwordGuard","brass",(0.5,0.5,3.2))
sub(G,"GuardCore","glow",(0,0,0),(0.85,0.85,0.85))
for i, (x, z) in enumerate([(0.48,0.48),(-0.48,0.48),(0.48,-0.48),(-0.48,-0.48)], 1):
    sub(G, f"GuardPost{i}", "brass", (x, 0, z), (0.22, 1.1, 0.22))
sub(G,"GuardCap","brass",(0,0.62,0),(1.25,0.22,1.25))
S("SwordBlade","iron",(0.45,6.6,1.5)); S("SwordEdge","light",(0.3,6.1,1.85)); S("SwordFuller","glow",(0.55,4.6,0.35))
TP = S("SwordTip","iron")
sub(TP,"TipFlame","glow",(0,0.55,0),(0.42,0.5,0.45),eul(rx=45))

if __name__ == "__main__":
    g.report()
    out = "/home/claude/lantern/LanternGolemData.lua"
    g.export(out, [
        "-- Lantern Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано lantern_golem_generator.py.",
        "-- Скелет = Clay … Granite (21 кістка). neon — кольори, що будуються з Material = Neon (світло ліхтаря). Pickaxe / Sword — у кулаці Fist_L."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n bones={", 1)
    open(out, "w").write(s)
