#!/usr/bin/env python3
"""
Low-poly forge props for "My Mining Golems" (Roblox).

Generates:
  ingot.obj  - beveled trapezoid ingot with a shallow stamp on top
  ore_a.obj, ore_b.obj, ore_c.obj - chunky faceted ore chunks (3 variations)
  *.glb      - same meshes as glTF binary (if trimesh is installed)
  meshes.json - raw triangle data; also injected into preview.html

Units: 1 unit = 1 stud, Y up, origin = bounding-box center.
Flat shading: every triangle has its own 3 vertices and a face normal.
Deterministic: fixed seeds.

Run:  python3 gen_models.py
"""
import json
import os
import re

import numpy as np
from scipy.spatial import ConvexHull, HalfspaceIntersection

OUT = os.path.dirname(os.path.abspath(__file__))


# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------
def tri_normals(tris):
    n = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    ln[ln == 0] = 1
    return n / ln


def drop_degenerate(tris, eps=1e-9):
    a = np.linalg.norm(np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0]), axis=1)
    return tris[a > eps]


def convex_tris(points):
    """Convex hull of points -> outward-oriented triangles (T,3,3)."""
    hull = ConvexHull(points)
    c = points[hull.vertices].mean(axis=0)
    tris = []
    for s, eq in zip(hull.simplices, hull.equations):
        t = points[s]
        n = np.cross(t[1] - t[0], t[2] - t[0])
        if np.dot(n, eq[:3]) < 0:
            t = t[[0, 2, 1]]
        tris.append(t)
    return np.array(tris)


def halfspace_solid(normals, dists):
    """Intersection of half-spaces n.x <= d (all d > 0) -> convex triangles."""
    normals = np.asarray(normals, float)
    normals /= np.linalg.norm(normals, axis=1, keepdims=True)
    hs = np.hstack([normals, -np.asarray(dists, float)[:, None]])
    hsi = HalfspaceIntersection(hs, np.zeros(3))
    pts = hsi.intersections
    # merge near-duplicate vertices (where >3 planes meet)
    merged = []
    for p in pts:
        if not any(np.linalg.norm(p - q) < 1e-6 for q in merged):
            merged.append(p)
    return convex_tris(np.array(merged))


def signed_volume(tris):
    return np.einsum("ij,ij->i", tris[:, 0], np.cross(tris[:, 1], tris[:, 2])).sum() / 6.0


def bbox(tris):
    v = tris.reshape(-1, 3)
    return v.min(0), v.max(0)


def center_bbox(tris):
    lo, hi = bbox(tris)
    return tris - (lo + hi) / 2


def check_closed(tris, name):
    """Every undirected edge must be used exactly twice, once per direction."""
    v = np.round(tris.reshape(-1, 3), 6)
    keys = {}
    idx = []
    for p in map(tuple, v):
        idx.append(keys.setdefault(p, len(keys)))
    idx = np.array(idx).reshape(-1, 3)
    directed = {}
    for a, b, c in idx:
        for e in ((a, b), (b, c), (c, a)):
            directed[e] = directed.get(e, 0) + 1
    bad = [e for e, k in directed.items() if k != 1 or directed.get((e[1], e[0]), 0) != 1]
    vol = signed_volume(tris)
    status = "OK" if not bad and vol > 0 else "PROBLEM"
    print(f"  {name:8s} closed/oriented: {status}  (bad edges {len(bad)}, volume {vol:.3f})")
    return not bad and vol > 0


# ----------------------------------------------------------------------------
# ingot
# ----------------------------------------------------------------------------
def rounded_rect(hx, hz, r, segs=2):
    """Ring of points (CCW by angle atan2(z,x)) for a rounded rectangle."""
    r = min(r, hx * 0.99, hz * 0.99)
    pts = []
    corners = [(hx - r, hz - r, 0.0), (-(hx - r), hz - r, 90.0),
               (-(hx - r), -(hz - r), 180.0), (hx - r, -(hz - r), 270.0)]
    # order by angle: start at corner (+,+) arc 0..90
    for cx, cz, a0 in corners:
        for k in range(segs + 1):
            a = np.radians(a0 + 90.0 * k / segs)
            pts.append((cx + r * np.cos(a), cz + r * np.sin(a)))
    return np.array(pts)


def ring3(xz, y):
    return np.column_stack([xz[:, 0], np.full(len(xz), y), xz[:, 1]])


def loft(rings):
    """rings: list of (N,3) arrays or single (3,) points (pole), ordered along the
    profile from bottom center, up the sides, over the top to top center."""
    tris = []
    for lo, hi in zip(rings[:-1], rings[1:]):
        lo_pole = lo.ndim == 1
        hi_pole = hi.ndim == 1
        n = len(hi) if lo_pole else len(lo)
        for j in range(n):
            k = (j + 1) % n
            if lo_pole:
                tris.append([lo, hi[j], hi[k]])
            elif hi_pole:
                tris.append([lo[j], hi, lo[k]])
            else:
                tris.append([lo[j], hi[j], hi[k]])
                tris.append([lo[j], hi[k], lo[k]])
    return drop_degenerate(np.array(tris, float))


def make_ingot(W=0.95, H=0.80, L=1.90):
    b = 0.075          # edge bevel size (top & bottom horizontal edges)
    r = 0.10           # vertical-edge corner radius
    hx0, hz0 = 0.475, 0.95   # half size at the widest (bottom, y=b)
    hx1, hz1 = 0.345, 0.79   # half size at the top shoulder (y=H-b)
    stamp_d = 0.06

    def side(y):
        t = (y - b) / (H - 2 * b)
        return hx0 + (hx1 - hx0) * t, hz0 + (hz1 - hz0) * t

    rings = [np.array([0.0, 0.0, 0.0])]
    # bottom bevel (quarter arc, 2 segments): inset b -> 0
    for th in (90, 45, 0):
        a = np.radians(th)
        inset = b * (1 - np.cos(a))
        y = b * (1 - np.sin(a))
        sx, sz = side(b)
        rings.append(ring3(rounded_rect(sx - inset, sz - inset, r - 0.45 * inset), y))
    # top bevel: 0 -> inset b
    for th in (0, 45, 90):
        a = np.radians(th)
        inset = b * (1 - np.cos(a))
        y = H - b * (1 - np.sin(a))
        sx, sz = side(H - b)
        rings.append(ring3(rounded_rect(sx - inset, sz - inset, r - 0.45 * inset), y))
    # stamp: shallow inset rectangle on the top face
    tx, tz = side(H - b)
    tx -= b
    tz -= b
    sx, sz = tx - 0.07, tz - 0.10
    rings.append(ring3(rounded_rect(sx, sz, 0.06), H))
    rings.append(ring3(rounded_rect(sx - 0.05, sz - 0.05, 0.03), H - stamp_d))
    rings.append(np.array([0.0, H - stamp_d, 0.0]))

    tris = loft(rings)
    lo, hi = bbox(tris)
    size = hi - lo
    tris = center_bbox(tris) * (np.array([W, H, L]) / size)
    return tris


# ----------------------------------------------------------------------------
# ore chunks
# ----------------------------------------------------------------------------
def unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def rock_planes(rng, half=(0.5, 0.42, 0.5), chips=10, chip_depth=(0.80, 0.92),
                tilt=0.18, bottom=0.36):
    """Chunky chipped block: 5 perturbed box faces + flat bottom + corner/edge chips."""
    normals, dists = [], []
    hx, hy, hz = half
    # box faces (except bottom), slightly tilted for an irregular look
    for n, d in (((1, 0, 0), hx), ((-1, 0, 0), hx), ((0, 0, 1), hz), ((0, 0, -1), hz), ((0, 1, 0), hy)):
        nn = unit(np.array(n, float) + rng.normal(0, tilt, 3) * (1 - np.abs(n)))
        normals.append(nn)
        dists.append(d * rng.uniform(0.9, 1.04))
    # flat bottom
    normals.append((0, -1, 0))
    dists.append(bottom)
    # chips near corners / edges, cut fairly deep so they make big facets
    dirs = []
    for sx in (-1, 1):
        for sz in (-1, 1):
            dirs.append((sx, 1, sz))          # top corners
            dirs.append((sx, -0.55, sz))      # lower corners (bevel to the bottom)
    for s in (-1, 1):
        dirs += [(s, 1, 0), (0, 1, s), (s, 0, 1), (s, 0, -1)]  # top edges + vertical edges
    dirs = np.array(dirs, float)
    pick = rng.choice(len(dirs), size=min(chips, len(dirs)), replace=False)
    for i in pick:
        d = dirs[i] + rng.normal(0, 0.22, 3)
        n = unit(d)
        # support of the box in direction n
        support = abs(n[0]) * hx + abs(n[2]) * hz + (n[1] * hy if n[1] > 0 else -n[1] * bottom)
        normals.append(n)
        dists.append(support * rng.uniform(*chip_depth))
    return np.array(normals), np.array(dists)


def crystal(base, axis, radius, length, sides, twist, tip=0.45, sink=0.22):
    """Faceted crystal: prism + short pyramid tip, base buried inside the rock."""
    axis = unit(axis)
    ref = np.array([0, 0, 1.0]) if abs(axis[1]) > 0.9 else np.array([0, 1.0, 0])
    u = unit(np.cross(axis, ref))
    v = np.cross(axis, u)
    p0 = base - axis * sink
    p1 = base + axis * (length * (1 - tip))
    p2 = base + axis * length
    pts = []
    for k in range(sides):
        a = twist + 2 * np.pi * k / sides
        off = (np.cos(a) * u + np.sin(a) * v) * radius
        pts.append(p0 + off * 0.85)
        pts.append(p1 + off)
    pts.append(p2)
    return convex_tris(np.array(pts))


def surface_point(normals, dists, direction):
    """Point on the convex solid's surface along a ray from origin."""
    direction = unit(direction)
    t = min(d / np.dot(n, direction) for n, d in zip(normals, dists) if np.dot(n, direction) > 1e-6)
    return direction * t


def make_ore(seed, crystals, target=1.12, **kw):
    rng = np.random.default_rng(seed)
    normals, dists = rock_planes(rng, **kw)
    parts = [halfspace_solid(normals, dists)]
    for (dx, dy, dz), rad, ln, count in crystals:
        # druse-like cluster: all crystals grow from one root buried inside the rock
        d = unit(np.array([dx, dy, dz]))
        p = surface_point(normals, dists, d)
        root = p * 0.72
        main = unit(d + np.array([0, 0.3, 0]))
        w1 = unit(np.cross(main, [0, 1, 0]))
        w2 = unit(np.cross(main, w1))
        fan = [(0.0, 0.0, 1.0), (0.7, 0.2, 0.75), (-0.6, -0.45, 0.68)]
        for c in range(count):
            a, b, k = fan[c]
            ax = unit(main + w1 * a + w2 * b)
            reach = np.linalg.norm(p - root) + ln * k   # stick out ~ln*k beyond the surface
            parts.append(crystal(root, ax, rad * (0.75 + 0.25 * k), reach, 6, rng.uniform(0, np.pi),
                                 tip=0.3, sink=0.0))
    tris = np.concatenate(parts)
    # put the flat bottom on y=0 conceptually, then center the bbox
    lo, hi = bbox(tris)
    s = target / max(hi - lo)
    return center_bbox(tris) * s, parts


# ----------------------------------------------------------------------------
# writers
# ----------------------------------------------------------------------------
def write_obj(path, name, tris):
    n = tri_normals(tris)
    with open(path, "w") as f:
        f.write(f"# {name} - My Mining Golems forge prop. 1 unit = 1 stud, Y up, flat shaded\n")
        f.write(f"o {name}\n")
        for t in tris:
            for p in t:
                f.write(f"v {p[0]:.5f} {p[1]:.5f} {p[2]:.5f}\n")
        for nn in n:
            f.write(f"vn {nn[0]:.5f} {nn[1]:.5f} {nn[2]:.5f}\n")
        f.write("s off\n")
        for i in range(len(tris)):
            a = 3 * i + 1
            f.write(f"f {a}//{i+1} {a+1}//{i+1} {a+2}//{i+1}\n")


def write_glb(path, tris):
    try:
        import trimesh
    except ImportError:
        return False
    v = tris.reshape(-1, 3)
    f = np.arange(len(v)).reshape(-1, 3)
    m = trimesh.Trimesh(vertices=v, faces=f, process=False)
    m.vertex_normals = np.repeat(tri_normals(tris), 3, axis=0)
    m.export(path, include_normals=True)
    return True


def inject_preview(data):
    path = os.path.join(OUT, "preview.html")
    if not os.path.exists(path):
        return
    html = open(path, encoding="utf-8").read()
    blob = "/*MESHDATA_BEGIN*/" + json.dumps(data, separators=(",", ":")) + "/*MESHDATA_END*/"
    html = re.sub(r"/\*MESHDATA_BEGIN\*/.*?/\*MESHDATA_END\*/", lambda m: blob, html, flags=re.S)
    open(path, "w", encoding="utf-8").write(html)
    print("  injected mesh data into preview.html")


# ----------------------------------------------------------------------------
def main():
    meshes = {}
    meshes["ingot"] = make_ingot()

    # (direction from center, radius, length, sides)
    # crystal clusters: (direction from center, radius, length, crystals in cluster)
    meshes["ore_a"], pa = make_ore(11, crystals=[((0.62, 0.55, 0.45), 0.115, 0.42, 3)])
    meshes["ore_b"], pb = make_ore(23, crystals=[], half=(0.52, 0.44, 0.48), chips=15,
                                   chip_depth=(0.74, 0.88))
    meshes["ore_c"], pc = make_ore(37, crystals=[((-0.5, 0.75, -0.45), 0.125, 0.44, 2)],
                                   half=(0.5, 0.42, 0.52), chips=10)

    print("Checking shells:")
    check_closed(meshes["ingot"], "ingot")
    for name, parts in (("ore_a", pa), ("ore_b", pb), ("ore_c", pc)):
        for i, p in enumerate(parts):
            check_closed(p, f"{name}.{i}")

    data = {}
    print("\nmesh      tris   bbox X x Y x Z (studs)")
    for name, tris in meshes.items():
        tris = np.round(tris, 5)
        write_obj(os.path.join(OUT, f"{name}.obj"), name, tris)
        glb = write_glb(os.path.join(OUT, f"{name}.glb"), tris)
        lo, hi = bbox(tris)
        sz = hi - lo
        print(f"{name:8s} {len(tris):5d}   {sz[0]:.3f} x {sz[1]:.3f} x {sz[2]:.3f}" + ("  (+glb)" if glb else ""))
        data[name] = [round(float(x), 4) for x in tris.reshape(-1)]

    with open(os.path.join(OUT, "meshes.json"), "w") as f:
        json.dump(data, f, separators=(",", ":"))
    inject_preview(data)


if __name__ == "__main__":
    main()
