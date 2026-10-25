"""Блики в стилі Free Icon Pack: білий «зубець» у вершині, де сходяться ребра граней.
Дивись нотатку GDD - Блики іконок.  Використання:

    V   = (128, 148)                                  # вершина стику ребер
    big = glint(V, [along(V, (127, 85), 40),          # кінець руки 1 — на ребрі V→(127,85)
                    along(V, (16, 113), 38)])         # кінець руки 2 — на ребрі V→(16,113)
    # big — готовий <path>; додати ПІСЛЯ заливки граней і ОБРІЗАТИ по силуету (clip-path).
"""

def PP(pts):
    return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + "Z"

def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)

def dist(a, b):
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** .5

def along(V, to, d):
    """точка на ребрі V→to на відстані d від V (кінець руки блика)"""
    return lerp(V, to, min(1.0, d / dist(V, to)))

def glint(V, tips, k=.17, fill="#fff"):
    """V — вершина; tips — 2 або 3 кінці рук (кожен на своєму ребрі);
    k — глибина «гострого кута» (0,15–0,2): внутрішня точка = V + Σ(tip−V)·k.
    Контур — лише прямі відрізки: tip → I → tip → … ; для двох рук ще V."""
    n = len(tips)
    if n == 2:
        t1, t2 = tips
        I = (V[0] + (t1[0] - V[0] + t2[0] - V[0]) * k, V[1] + (t1[1] - V[1] + t2[1] - V[1]) * k)
        pts = [t1, I, t2, V]
    else:
        pts = []
        for i, t in enumerate(tips):
            nx = tips[(i + 1) % n]
            pts.append(t)
            pts.append((V[0] + (t[0] - V[0] + nx[0] - V[0]) * k, V[1] + (t[1] - V[1] + nx[1] - V[1]) * k))
    return f'<path d="{PP(pts)}" fill="{fill}"/>'

def clip_group(shape_path, inner, cid):
    """обрізати блики по силуету, щоб не виходили на контур"""
    return f'<clipPath id="{cid}"><path d="{shape_path}"/></clipPath><g clip-path="url(#{cid})">{inner}</g>'

if __name__ == "__main__":
    V = (128, 148)
    print(glint(V, [along(V, (127, 85), 40), along(V, (16, 113), 38)]))
