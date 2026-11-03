# Спільні помічники генераторів големів (формат GolemData Clay / Gravel / Mossback, 1 од. = 0,5 стада).
import numpy as np, itertools
from shapely.geometry import Polygon

D = np.pi / 180
def Rx(a): c, s = np.cos(a), np.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = np.cos(a), np.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = np.cos(a), np.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def eul(rx=0, ry=0, rz=0): return Ry(ry*D) @ Rx(rx*D) @ Rz(rz*D)
def R9(*r): return np.array(r, float).reshape(3,3)
M = np.diag([-1., 1, 1])

# скелет Clay (21 кістка); обличчя можна перевизначити
BASE_BONES = [
 ("Root",None,(0,0,-0.2986)),("Hips","Root",(0,4.85,-0.2986)),("Torso","Hips",(0,5.6,-0.2986)),
 ("Head","Torso",(0,9.9,0.4514)),("UpperArm_R","Torso",(5.2,9.4,-0.2986)),("Forearm_R","UpperArm_R",(5.5,6.9,0.0014)),
 ("UpperArm_L","Torso",(-5.2,9.4,-0.2986)),("Forearm_L","UpperArm_L",(-5.5,6.9,0.0014)),
 ("Thigh_R","Hips",(2,4.6,-0.2986)),("Shin_R","Thigh_R",(2.1,3.15,-0.2986)),
 ("Thigh_L","Hips",(-2,4.6,-0.2986)),("Shin_L","Thigh_L",(-2.1,3.15,-0.2986)),
 ("Eye_R","Head",(0.85,11.4,2.1764)),("Pupil_R","Eye_R",(0.78,11.29,2.2764)),("Brow_R","Head",(0.9,12.3,2.2014)),
 ("Eye_L","Head",(-0.85,11.4,2.1764)),("Pupil_L","Eye_L",(-0.78,11.29,2.2764)),("Brow_L","Head",(-0.9,12.3,2.2014)),
 ("Mouth","Head",(0,10.46,2.3014)),("MouthCorner_R","Head",(0.65,10.6,2.3014)),("MouthCorner_L","Head",(-0.65,10.6,2.3014)),
]

class Golem:
    def __init__(self, colors, bones=None):
        self.colors = colors; self.blocks = []
        self.fx = []  # унікальні рухи деталей: dict(kind, parts, pivot?, axis, speed, amp?, phase?, states?)
        self.bones = [list(b) for b in BASE_BONES]
        for n, pos in (bones or {}).items():
            for b in self.bones:
                if b[0] == n: b[2] = pos
    def add(self, name, bone, col, pos, size, R=None, group=None, mirror=False):
        R = np.eye(3) if R is None else R
        b = dict(name=name, bone=bone, col=col, pos=np.array(pos, float), R=R, s=np.array(size, float), group=group)
        self.blocks.append(b)
        if mirror:
            self.blocks.append(dict(name=name[:-2] + "_L", bone=bone[:-2] + "_L" if bone.endswith("_R") else bone, col=col,
                               pos=np.array([-pos[0], pos[1], pos[2]], float), R=M @ R @ M, s=np.array(size, float), group=group))
        return b
    def sub(self, parent, name, col, local, size, Rl=None, mirror=False, bone=None, group=None):
        Rl = np.eye(3) if Rl is None else Rl
        p = parent["pos"] + parent["R"] @ np.array(local, float)
        return self.add(name, bone or parent["bone"], col, tuple(p), size, parent["R"] @ Rl, group=group or parent["group"], mirror=mirror)
    def item(self, name, grp, col, pos, R, s): return self.add(name, "Forearm_L", col, pos, s, R, group=grp)


    # ---------- без щілин (з 01.11.2026, після відгуку: рукоять не досунута, дірки в ящику) ----------
    def _find(self, grp, name):
        for b in self.blocks:
            if b["group"] == grp and b["name"] == name: return b
    @staticmethod
    def _slab(b, o, d):
        lo = b["R"].T @ (o - b["pos"]); ld = b["R"].T @ d; h = b["s"] / 2; t0, t1 = -1e9, 1e9
        for i in range(3):
            if abs(ld[i]) < 1e-9:
                if abs(lo[i]) > h[i]: return None
            else:
                a, c = sorted(((-h[i] - lo[i]) / ld[i], (h[i] - lo[i]) / ld[i])); t0, t1 = max(t0, a), min(t1, c)
        return (t0, t1) if t0 <= t1 else None
    def _grow(self, b, sgn, amt):  # подовжити блок уздовж його локальної Y на кінці sgn
        b["s"] = b["s"] + np.array([0, amt, 0]); b["pos"] = b["pos"] + b["R"][:, 1] * sgn * amt / 2
    def _unplane(self, E, others, keep=1, tol=0.02, inset=0.022):
        """Після подовження: грані E, що лягли в одну площину з гранями сусідів (і перекриваються), зсуваємо всередину E."""
        changed = True; n = 0
        while changed and n < 12:
            changed = False; n += 1
            for O in others:
                if O is E: continue
                for k in range(3):
                    e = E["R"][:, k]
                    if not np.isclose(np.abs(O["R"].T @ e).max(), 1, atol=1e-3): continue
                    ho = (np.abs(O["R"].T @ e) * O["s"]).sum() / 2; co = e @ (O["pos"] - E["pos"]); he = E["s"][k] / 2
                    for sg in (1, -1):
                        if min(abs(sg * he - (co + ho)), abs(sg * he - (co - ho))) < tol:
                            # перекриття в площині? — перевіряємо checkом пари
                            if any(set(h) == {E["name"], O["name"]} for h in self._pair_check(E, O)):
                                E["s"] = E["s"] - np.eye(3)[k] * inset; E["pos"] = E["pos"] - e * sg * inset / 2; changed = True
                                he = E["s"][k] / 2
    def _pair_check(self, b1, b2):
        hits = []
        for n1, c1, q1 in self._faces(b1):
            for n2, c2, q2 in self._faces(b2):
                if abs(n1 @ n2 - 1) > 1e-4 or abs(n1 @ (c2 - c1)) > 0.02: continue
                a = np.array([1,0,0]) if abs(n1[0]) < 0.9 else np.array([0,1,0])
                u = np.cross(n1, a); u /= np.linalg.norm(u); v = np.cross(n1, u)
                if Polygon([(p @ u, p @ v) for p in q1]).intersection(Polygon([(p @ u, p @ v) for p in q2])).area > 1e-3:
                    hits.append((b1["name"], b2["name"]))
        return hits
    def seat_sword(self, grp="Sword", log=True):
        """Руків'я заходить до центру гарди й навершя, лезо — до центру гарди (у грі не видно щілин)."""
        g, guard, pom, blade = (self._find(grp, n) for n in ("SwordGrip", "SwordGuard", "SwordPommel", "SwordBlade"))
        out = []
        # руків'я — до центру гарди й навершя (+ зсув граней, що лягли врівень); лезо — лише до дотику з гардою
        for part, tgt, sgn, touch, tag in ((g, guard, 1, False, "grip→guard"), (g, pom, -1, False, "grip→pommel"), (blade, guard, -1, True, "blade→guard")):
            if part is None or tgt is None: continue
            d = part["R"][:, 1]; L = part["s"][1] / 2; iv = self._slab(tgt, part["pos"], d)
            if iv is None: continue
            mid = (iv[0] + iv[1]) / 2
            if touch: need = (iv[0] - L) if sgn > 0 else (-L - iv[1])
            else: need = (mid + 0.026 - L) if sgn > 0 else (-L - (mid - 0.034))
            if need > 0.001:
                self._grow(part, sgn, need); out.append(f"{tag} +{need:.2f}")
                if not touch: self._unplane(part, [b for b in self.blocks if b["group"] == grp])
        if log and out: print(grp, "seated:", ", ".join(out))
        return out
    def close_gaps(self, grp="Box", max_gap=0.15, depth=0.07, log=True):
        """Щілини між вирівняними блоками (≤ max_gap), не закриті іншим блоком (≥ 20 % перерізу відкрито), закриваються:
        менший за перерізом блок подовжується рівно до дотику з сусідом. Якщо подовження проходить крізь інший блок
        і кладе грані врівень (видимі площини, що перекриваються) — такий блок пропускаємо."""
        bs = [b for b in self.blocks if b["group"] == grp]
        def aligned(b): return np.all(np.isclose(np.abs(b["R"]).max(0), 1, atol=1e-3))
        def ext(b): return np.abs(b["R"]) @ b["s"]
        def inside(b, pt): return np.all(np.abs(b["R"].T @ (pt - b["pos"])) <= b["s"] / 2 + 0.003)
        fixes = []
        for _ in range(200):
            done = False
            for A, B in itertools.combinations([b for b in bs if aligned(b)], 2):
                ea, eb = ext(A), ext(B); la, ha, lb, hb = A["pos"] - ea/2, A["pos"] + ea/2, B["pos"] - eb/2, B["pos"] + eb/2
                g = np.maximum(la - hb, lb - ha); gx = [i for i in range(3) if g[i] > 0.001]
                if len(gx) != 1 or g[gx[0]] > max_gap: continue
                ax = gx[0]; o = [i for i in range(3) if i != ax]
                if any(-g[i] < 0.04 for i in o): continue
                first = ha[ax] < lb[ax]; gm = (ha[ax] + lb[ax]) / 2 if first else (hb[ax] + la[ax]) / 2
                l1, h1 = max(la[o[0]], lb[o[0]]), min(ha[o[0]], hb[o[0]]); l2, h2 = max(la[o[1]], lb[o[1]]), min(ha[o[1]], hb[o[1]])
                unc = 0
                for u in np.linspace(0.02, 0.98, 7):
                    for v in np.linspace(0.02, 0.98, 7):
                        pt = np.zeros(3); pt[ax] = gm; pt[o[0]] = l1 + (h1 - l1) * u; pt[o[1]] = l2 + (h2 - l2) * v
                        if not any(inside(c, pt) for c in bs if c is not A and c is not B): unc += 1
                if unc < 10: continue  # < 20 % відкрито — щілину закриває інший блок
                E, O, sg = (A, B, 1 if first else -1) if ea[o[0]] * ea[o[1]] <= eb[o[0]] * eb[o[1]] else (B, A, -1 if first else 1)
                amt = g[ax]; li = int(np.argmax(np.abs(E["R"][ax, :])))  # рівно до дотику (грані «лоб у лоб» сховані)
                E["s"] = E["s"] + np.eye(3)[li] * amt; E["pos"] = E["pos"] + np.eye(3)[ax] * sg * amt / 2
                fixes.append(f"{E['name']}→{O['name']} {'XYZ'[ax]} {g[ax]:.2f}"); done = True; break
            if not done: break
        if log and fixes: print(grp, "gaps closed:", ", ".join(fixes))
        return fixes

    # ---------- правило 0,1 ----------
    @staticmethod
    def _faces(b):
        out = []
        for ax in range(3):
            n = b["R"][:, ax]
            for sg in (-1, 1):
                c = b["pos"] + sg * n * b["s"][ax] / 2
                o = [i for i in range(3) if i != ax]
                u, v = b["R"][:, o[0]] * b["s"][o[0]] / 2, b["R"][:, o[1]] * b["s"][o[1]] / 2
                out.append((sg * n, c, [c + a * u + bb * v for a, bb in ((1,1),(1,-1),(-1,-1),(-1,1))]))
        return out
    def check(self, group):
        bs = [b for b in self.blocks if b["group"] == group]; hits = []
        for b1, b2 in itertools.combinations(bs, 2):
            for n1, c1, q1 in self._faces(b1):
                for n2, c2, q2 in self._faces(b2):
                    # лише грані врівень в один бік (n1·n2 = +1): «лоб у лоб» (−1) — дотик, грані сховані
                    if abs(n1 @ n2 - 1) > 1e-4 or abs(n1 @ (c2 - c1)) > 0.02: continue
                    a = np.array([1,0,0]) if abs(n1[0]) < 0.9 else np.array([0,1,0])
                    u = np.cross(n1, a); u /= np.linalg.norm(u); v = np.cross(n1, u)
                    P1 = Polygon([(p @ u, p @ v) for p in q1]); P2 = Polygon([(p @ u, p @ v) for p in q2])
                    if P1.intersection(P2).area > 1e-3: hits.append((b1["name"], b2["name"]))
        return sorted(set(hits))
    @staticmethod
    def _obb_touch(b1, b2, tol=0.01):
        """SAT: чи перетинаються / торкаються два блоки (з допуском tol)."""
        A, B = b1["R"], b2["R"]; ea, eb = b1["s"] / 2, b2["s"] / 2; t = b2["pos"] - b1["pos"]
        axes = [A[:, i] for i in range(3)] + [B[:, i] for i in range(3)]
        for i in range(3):
            for j in range(3):
                c = np.cross(A[:, i], B[:, j])
                if np.linalg.norm(c) > 1e-6: axes.append(c / np.linalg.norm(c))
        for L in axes:
            ra = sum(ea[k] * abs(A[:, k] @ L) for k in range(3)); rb = sum(eb[k] * abs(B[:, k] @ L) for k in range(3))
            if abs(t @ L) > ra + rb + tol: return False
        return True
    def floating(self, group, allow=()):
        """Блоки групи, що не торкаються жодного іншого блока тієї ж групи (висять у повітрі). allow — навмисно вільні."""
        bs = [b for b in self.blocks if b["group"] == group]
        return [b["name"] for b in bs if b["name"] not in allow and not any(self._obb_touch(b, c) for c in bs if c is not b)]
    def visible_coplanar(self, group):
        """Як check(), але лише ті збіги граней, ділянку яких не ховає третій блок (видимий z-fighting)."""
        bs = [b for b in self.blocks if b["group"] == group]; out = []
        def inside(b, pt): return np.all(np.abs(b["R"].T @ (pt - b["pos"])) < b["s"] / 2 - 0.002)
        for b1, b2 in itertools.combinations(bs, 2):
            hit = False
            for n1, c1, q1 in self._faces(b1):
                for n2, c2, q2 in self._faces(b2):
                    if hit or abs(n1 @ n2 - 1) > 1e-4 or abs(n1 @ (c2 - c1)) > 0.02: continue
                    a = np.array([1,0,0]) if abs(n1[0]) < 0.9 else np.array([0,1,0])
                    u = np.cross(n1, a); u /= np.linalg.norm(u); v = np.cross(n1, u)
                    I = Polygon([(p @ u, p @ v) for p in q1]).intersection(Polygon([(p @ u, p @ v) for p in q2]))
                    if I.area <= 1e-3: continue
                    x0, y0, x1, y1 = I.bounds; h = n1 @ c1
                    for xu in np.linspace(x0, x1, 6):
                        for yv in np.linspace(y0, y1, 6):
                            from shapely.geometry import Point
                            if not I.buffer(1e-6).contains(Point(xu, yv)): continue
                            pt = xu * u + yv * v + h * n1
                            if not any(inside(c, pt) for c in bs if c is not b1 and c is not b2): hit = True
            if hit: out.append((b1["name"], b2["name"]))
        return out
    def report(self):
        for g in (None, "Pickaxe", "Sword"):
            print(g or "Body", len([b for b in self.blocks if b["group"] == g]), "blocks; coplanar:", self.check(g))
        print("body colors", sorted({b["col"] for b in self.blocks if b["group"] is None}))
        allb = [b for b in self.blocks if b["group"] is None]
        lo = np.min([b["pos"] - np.abs(b["R"]) @ b["s"] / 2 for b in allb], 0); hi = np.max([b["pos"] + np.abs(b["R"]) @ b["s"] / 2 for b in allb], 0)
        print("bounds", lo.round(2), hi.round(2), "size", (hi - lo).round(2), "tris", 12 * len(allb))
    def export(self, path, header):
        # автоматично: руків'я / лезо досунуті, у ящику без щілин
        if any(b["group"] == "Sword" for b in self.blocks): self.seat_sword()
        if any(b["group"] == "Box" for b in self.blocks): self.close_gaps("Box")
        for grp in ("Pickaxe", "Sword", "Box", None):
            if any(b["group"] == grp for b in self.blocks):
                fl = self.floating(grp, getattr(self, "free_parts", ()))
                if fl: print("WARNING", grp or "Body", "floating (not attached):", fl)
        for grp in ("Sword", "Box"):
            if any(b["group"] == grp for b in self.blocks):
                c = self.visible_coplanar(grp)
                if c: print("WARNING", grp, "visible coplanar after gap fix:", c)
        f = lambda x: f"{x:.5g}"
        L = list(header) + ["return {", " colors={" + ",".join(f'{k}="{v}"' for k, v in self.colors.items()) + "},", " bones={"]
        for n, p, pos in self.bones:
            L.append(f'  {{name="{n}",parent={"nil" if p is None else chr(34)+p+chr(34)},pos=Vector3.new({",".join(f(x) for x in pos)})}},')
        L += [" },"]
        if self.fx:
            vec = lambda v: "Vector3.new(" + ",".join(f(x) for x in v) + ")"
            L.append(" fx={")
            for x in self.fx:
                kv = [f'kind="{x.get("kind","spin")}"', "parts={" + ",".join(f'"{n}"' for n in x["parts"]) + "}"]
                if "pivot" in x: kv.append("pivot=" + vec(x["pivot"]))
                kv.append("axis=" + vec(x.get("axis", (0, 0, 1))))
                kv.append("speed=" + f(x.get("speed", 1)))
                for k in ("amp", "phase"):
                    if k in x: kv.append(f"{k}=" + f(x[k]))
                if "states" in x: kv.append("states={" + ",".join(f"{k}={f(v)}" for k, v in x["states"].items()) + "}")
                L.append("  {" + ",".join(kv) + "},")
            L.append(" },")
        L += [" blocks={"]
        for b in self.blocks:
            cf = ",".join(f(x) for x in list(b["pos"]) + list(b["R"].flatten()))
            g = f'group="{b["group"]}",' if b["group"] else ""
            L.append(f'  {{name="{b["name"]}",{g}bone="{b["bone"]}",col="{b["col"]}",cf=CFrame.new({cf}),s=Vector3.new({",".join(f(x) for x in b["s"])})}},')
        L += [" },", "}"]
        open(path, "w").write("\n".join(L) + "\n")

# предмети в кулаці Fist_L — спільні хвати й базові CFrame (Clay)
A = R9(1,0,0,0,0.1215,-0.99259,0,0.99259,0.1215)
R45 = R9(0.70739,0,0.70683,0.70159,0.1215,-0.70215,-0.08588,0.99259,0.08594)
PICK = {
 "Handle": ((-5.65,3.8388,3.2777), A, (0.65,9.2,0.65)),
 "Grip": ((-5.65,3.4257,-0.0971), R9(0.98007,0,0.19867,0.1972,0.1215,-0.97281,-0.02414,0.99259,0.11907), (0.85,2.45,0.85)),
 "Pommel": ((-5.65,3.2495,-1.5364), R9(0.71091,0,0.70328,0.69807,0.1215,-0.70565,-0.08545,0.99259,0.08637), (1.05,0.65,1.05)),
 "Band": ((-5.65,3.8874,3.6747), R9(0.85252,0,0.52269,0.51882,0.1215,-0.84621,-0.0635,0.99259,0.10358), (0.8,0.4,0.8)),
 "Head": ((-5.65,4.4098,7.9429), A, (1.6,1.8,2.0)),
 "HeadRound": ((-5.65,4.4159,7.9925), R45, (1.2,2.2,1.2)),
 "Pick1": ((-5.65,2.8156,8.0876), R9(1,0,0,0,0.02179,-0.99976,0,0.99976,0.02179), (1.05,1.1,1.9)),
 "Pick2": ((-5.65,1.3159,8.1203), R9(1,0,0,0,-0.19691,-0.98042,0,0.98042,-0.19691), (0.85,0.85,1.6)),
 "Pick3": ((-5.65,0.1394,7.884), R9(1,0,0,0,-0.41524,-0.90971,0,0.90971,-0.41524), (0.62,0.62,1.3)),
 "Pick4": ((-5.65,-0.6338,7.5311), R9(1,0,0,0,-0.6274,-0.7787,0,0.7787,-0.6274), (0.42,0.42,0.9)),
 "Back1": ((-5.65,5.7437,7.7292), R9(1,0,0,0,0.21998,-0.9755,0,0.9755,0.21998), (1.05,1.05,1.4)),
 "Back2": ((-5.65,6.6705,7.5202), R9(1,0,0,0,0.49844,-0.86693,0,0.86693,0.49844), (0.85,0.75,1)),
 "PickGlint": ((-5.65,2.8247,8.5075), R9(1,0,0,0,0.02179,-0.99976,0,0.99976,0.02179), (1.1,0.22,0.45)),
 "Chip": ((-5.65,1.2273,8.5615), R9(1,0,0,0,-0.19691,-0.98042,0,0.98042,-0.19691), (0.7,0.2,0.5)),
}
SWORD = {
 "SwordPommel": ((-5.65,3.1523,-2.3305), R45, (1,0.7,1)),
 "SwordPommelTop": ((-5.65,3.207,-1.8838), R9(0.95534,0,0.29552,0.29333,0.1215,-0.94826,-0.0359,0.99259,0.11607), (0.75,0.34,0.75)),
 "SwordGrip": ((-5.65,3.4075,-0.246), A, (0.7,3.6,0.7)),
 "SwordCoil1": ((-5.65,3.3164,-0.9905), R9(0.93768,-0.05996,0.34228,0.3472,0.12128,-0.92992,0.01425,0.99081,0.13454), (0.88,0.32,0.88)),
 "SwordCoil2": ((-5.65,3.5047,0.548), R9(0.95362,0.05996,-0.29499,-0.30029,0.12128,-0.94611,-0.02096,0.99081,0.13366), (0.88,0.32,0.88)),
 "SwordGuard": ((-5.65,3.6869,2.0369), R9(1,0,0,0,0.06176,-0.99809,0,0.99809,0.06176), (0.9,0.75,3)),
 "SwordBlade": ((-5.65,4.1304,5.6599), A, (0.45,6.6,1.5)),
 "SwordEdge": ((-5.65,4.1486,5.8088), A, (0.3,6.1,1.85)),
 "SwordFuller": ((-5.65,4.0818,5.2629), A, (0.65,4.2,0.4)),
 "SwordTip": ((-5.65,4.5738,9.2829), A, (0.36,0.95,0.85)),
}
def std_item(g, grp, table, name, col, size=None):
    pos, R, s = table[name]
    return g.item(name, grp, col, pos, R, size or s)
