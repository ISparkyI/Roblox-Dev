# Sapphire Golem (Epic): королівський сапфіровий голем — глибокий синій сапфір у темно-синьому камені й золотих оправах.
# Фірмове: золотий німб-кільце за спиною (восьмикутник) зі світним сапфіром у центрі, корона з самоцвітами,
# наплічники — великі гранені сапфіри-ромби в золотих оправах, самоцвіт-ромб у грудях. Скелет Clay.
# Унікальні: кірка-скіпетр (золота голова з самоцвітом, сапфірові леза, сапфірова «держава»-октаедр замість обуха),
# меч-корона (золота гарда-півмісяць із самоцвітом, сапфірове лезо зі світним долом і золотою кромкою),
# ящик — королівська скриня (золоті оправи, самоцвіти, кути з камінцями).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(sapph="#1f5fd6", navy="#14244f", gold="#e8c25a", glow="#4aa8ff", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)   # куб, поставлений на ребро — гранений «діамант»
# ---------- ноги ----------
a("Foot_R","Shin_R","navy",(2.15,0.5,0.15),(3.0,1.0,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","sapph",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","gold",(2.1,2.85,-0.2),(2.7,0.34,2.7),eul(ry=4),mirror=True)
a("KneeGem_R","Shin_R","glow",(2.2,2.85,1.42),(0.5,0.5,0.24),eul(rz=45),mirror=True)
a("Thigh_R","Thigh_R","navy",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","navy",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","gold",(0,5.4,-0.35),(6.0,0.45,3.6))
a("Buckle","Hips","sapph",(0,5.4,1.5),(0.8,0.8,0.26),eul(rz=45))
# ---------- корпус ----------
a("Torso","Torso","sapph",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","navy",(0,9.45,-0.4),(7.8,1.8,4.6))
a("Collar","Torso","gold",(0,10.25,-0.4),(4.6,0.4,3.6))
a("GemMount","Torso","gold",(0,7.6,1.82),(2.3,2.3,0.36),eul(rz=45))
a("ChestGem","Torso","glow",(0,7.6,2.08),(1.7,1.7,0.3),eul(rz=45))
a("ChestGemCore","Torso","light",(0,7.6,2.27),(0.5,0.5,0.14),eul(rz=45))
a("Sash_R","Torso","gold",(1.95,7.4,1.72),(0.4,3.6,0.3),eul(rz=20),mirror=True)
# ---------- спина: золотий німб-восьмикутник ----------
a("HaloArm","Torso","gold",(0,9.0,-2.6),(0.6,0.6,0.9))
HC = np.array((0, 9.6, -3.15)); r = 2.3
for k in range(8):
    ang = k * 45 + 22.5
    c = HC + np.array((r*np.cos(np.radians(ang)), r*np.sin(np.radians(ang)), 0))
    a(f"Halo{k+1}","Torso","gold",tuple(c),(0.42, 2*r*np.tan(np.radians(22.5)) + 0.42, 0.36 + 0.04*(k % 2)),eul(rz=ang))
a("HaloGem","Torso","glow",tuple(HC),(1.1,1.1,0.4),eul(rz=45))
a("HaloGemB","Torso","sapph",tuple(HC + np.array((0,0,0.08))),(1.3,1.3,0.32))
# ---------- голова з короною ----------
a("Head","Head","sapph",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","navy",(0,10.0,0.7),(3.4,0.8,2.7))
a("CrownBand","Head","gold",(0,12.7,0.45),(4.0,0.6,3.6))
for i, (x, z, h) in enumerate([(0,1.95,1.1),(1.55,1.4,0.8),(-1.55,1.4,0.8),(1.55,-0.55,0.7),(-1.55,-0.55,0.7)], 1):
    a(f"CrownPt{i}","Head","gold",(x,12.95+h/2,z),(0.5,h,0.5),eul(ry=45))
a("CrownGem","Head","glow",(0,12.75,2.28),(0.56,0.56,0.2),eul(rz=45))
a("CrownGemTop","Head","sapph",(0,13.0+1.1+0.22,1.95),(0.42,0.42,0.42),OCTA)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.3,2.24),(1.2,0.3,0.3),eul(rz=-4),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: наплічники-сапфіри ----------
a("Shoulder_R","UpperArm_R","navy",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("PauldronMount_R","UpperArm_R","gold",(5.1,10.9,-0.3),(3.0,0.4,3.2),eul(rz=4),mirror=True)
a("PauldronGem_R","UpperArm_R","sapph",(5.15,11.75,-0.3),(1.6,1.6,1.6),OCTA,mirror=True)
a("PauldronCore_R","UpperArm_R","glow",(5.15,11.75,-0.3),(1.25,1.25,1.25),eul(ry=45),mirror=True)
a("UpperArm_R","UpperArm_R","navy",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","sapph",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","gold",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
a("CuffGem_R","Forearm_R","glow",(6.95,6.0,0.0),(0.24,0.6,0.6),eul(rx=45),mirror=True)
fist = a("Fist_R","Forearm_R","navy",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","gold",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"Ring_R","sapph",(0.15,0.3,1.9),(0.5,0.5,0.24),eul(rz=45))
sub(fist,"Thumb_R","navy",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- кірка-скіпетр ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","navy"); P("Grip","gold"); P("Band","gold")
PM = P("Pommel","gold",(0.95,0.7,0.95))
sub(PM,"PommelGem","sapph",(0,-0.6,0),(0.5,0.5,0.5),OCTA)
sub(HN,"Ring1","gold",(0,1.2,0),(0.85,0.3,0.85))
sub(HN,"Ring2","gold",(0,2.4,0),(0.85,0.3,0.85),eul(ry=45))
HD = P("Head","gold",(1.6,1.8,1.9))
sub(HD,"HeadGemR","glow",(0.92,0,0),(0.16,0.85,0.85),eul(rx=45))
sub(HD,"HeadGemL","glow",(-0.92,0,0),(0.16,0.85,0.85),eul(rx=45))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"sapph")
P("PickGlint","glow")
sub(HD,"OrbCollar","gold",(0,0,-1.27),(1.1,1.1,0.5),eul(rz=45))
sub(HD,"Orb","sapph",(0,0,-2.15),(1.2,1.2,1.2),OCTA)
sub(HD,"OrbCore","glow",(0,0,-2.15),(0.95,0.95,0.95),eul(rz=45))
sub(HD,"OrbCross","gold",(0,0,-3.05),(0.22,0.22,0.6))
# ---------- меч-корона ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","gold"); S("SwordGrip","navy"); S("SwordCoil1","gold"); S("SwordCoil2","gold")
S("SwordPommelTop","sapph")
G = S("SwordGuard","gold",(0.7,0.55,1.4))
sub(G,"CrescentR","gold",(0,0.45,1.2),(0.6,0.5,1.4),eul(rx=-30))
sub(G,"CrescentL","gold",(0,0.45,-1.2),(0.6,0.5,1.4),eul(rx=30))
sub(G,"GuardGem","glow",(0,0.15,0),(0.9,0.9,0.9),eul(ry=45))
sub(G,"CrescentGemR","sapph",(0,0.85,1.75),(0.42,0.42,0.42),eul(ry=45))
sub(G,"CrescentGemL","sapph",(0,0.85,-1.75),(0.42,0.42,0.42),eul(ry=45))
S("SwordBlade","sapph",(0.45,6.6,1.5)); S("SwordEdge","gold",(0.3,6.1,1.85)); S("SwordFuller","glow",(0.6,4.4,0.38))
S("SwordTip","sapph")

# ---------- ящик — королівська скриня (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","navy",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","navy",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","sapph",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","sapph",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","sapph",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","sapph",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","gold",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","gold",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","gold",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","gold",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Post" + t, "gold", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("PostGem" + t, "glow", (1.87*sx, 2.12, 1.13*sz), (0.34, 0.34, 0.34), OCTA)
for i, x in enumerate((-0.95, 0.95), 1):
    B(f"BandF{i}","gold",(x,0.975,1.19),(0.24,1.55,0.14)); B(f"BandB{i}","gold",(x,0.975,-1.19),(0.24,1.55,0.14))
B("FrontMount","gold",(0,1.0,-1.22),(0.95,0.95,0.2),eul(rz=45))
B("FrontGem","glow",(0,1.0,-1.32),(0.65,0.65,0.14),eul(rz=45))
B("SideGemL","sapph",(-1.45,1.0,-1.2),(0.36,0.36,0.18),eul(rz=45))
B("SideGemR","sapph",(1.45,1.0,-1.2),(0.36,0.36,0.18),eul(rz=45))
for sx, nm in ((1, "R"), (-1, "L")):
    B("HandlePostA"+nm,"gold",(2.18*sx,1.2,0.35),(0.44,0.2,0.2)); B("HandlePostB"+nm,"gold",(2.18*sx,1.2,-0.35),(0.44,0.2,0.2))
    B("HandleBar"+nm,"gold",(2.45*sx,1.2,0),(0.22,0.28,1.0))

# ---------- унікальні рухи (D.fx, GolemAnimator v3) ----------
HALO_C = (0, 9.6, -3.15)
g.fx.append(dict(kind="spin", parts=[f"Halo{i}" for i in range(1, 9)] + ["HaloGemB"], pivot=HALO_C, axis=(0, 0, 1),
                 speed=0.9, states={"Walk": 1.5, "Run": 2.5, "Mine": 2.2}))   # німб крутиться, швидше в русі й при ударах
g.fx.append(dict(kind="spin", parts=["HaloGem"], pivot=HALO_C, axis=(0, 0, 1), speed=-1.6, states={"Mine": 2}))  # самоцвіт — назустріч

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/sapphire/SapphireGolemData.lua"
    g.export(out, [
        "-- Sapphire Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано sapphire_golem_generator.py.",
        "-- Скелет = Clay … Amethyst (21 кістка). neon — кольори з Material = Neon (світний сапфір). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик у стадах."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n bones={", 1); open(out, "w").write(s)
