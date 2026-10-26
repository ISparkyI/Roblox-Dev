# Перефарбування контуру #040435 → #14161a (INK) з плавною маскою (антиаліасинг і альфа зберігаються) + alpha bleed.
# Той самий алгоритм виконувався в браузері перед завантаженням у Roblox.
import sys, math
from PIL import Image
N, T, D = (4, 4, 53), (20, 22, 26), 90
def recolor(src, dst, size=None):
    im = Image.open(src).convert('RGBA')
    if size: im = im.resize((size, size), Image.LANCZOS)
    W, H = im.size; px = im.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0: continue
            t = max(0.0, min(1.0, 1 - math.dist((r, g, b), N) / D))
            if t > 0: px[x, y] = (round(r + t*(T[0]-N[0])), round(g + t*(T[1]-N[1])), round(b + t*(T[2]-N[2])), a)
    solid = [[px[x, y][3] >= 24 for x in range(W)] for y in range(H)]
    for _ in range(6):
        nxt = [row[:] for row in solid]
        for y in range(H):
            for x in range(W):
                if solid[y][x]: continue
                acc = [0, 0, 0]; c = 0
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        xx, yy = x+dx, y+dy
                        if 0 <= xx < W and 0 <= yy < H and solid[yy][xx]:
                            p = px[xx, yy]; acc[0] += p[0]; acc[1] += p[1]; acc[2] += p[2]; c += 1
                if c: px[x, y] = (acc[0]//c, acc[1]//c, acc[2]//c, px[x, y][3]); nxt[y][x] = True
        solid = nxt
    im.save(dst)
if __name__ == "__main__":
    recolor(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else None)
