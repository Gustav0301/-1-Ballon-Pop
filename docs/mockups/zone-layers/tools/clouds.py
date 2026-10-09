"""Stud cloud generators: the same math as the preview (src.html) and ZoneLayerController.lua.

Writes build/CloudModels.rbxmx (sample clouds to look at in Studio) and checks that no two parts
overlap (the build rule). Run: python3 clouds.py zones.json OUT.rbxmx
"""
import json, math, sys

CFG = json.load(open(sys.argv[1]))
OUT = sys.argv[2]
Z0, Z1 = CFG["zones"]
DECK, TOW = CFG["deck"], CFG["towers"]


def rng(seed):
    s = [int(math.floor(seed)) % 2147483646 + 1]
    def r():
        s[0] = (s[0] * 16807) % 2147483647
        return (s[0] - 1) / 2147483646
    return r


def tile_seed(ix, iz):
    return ix * 7349 + iz * 9157 + DECK["Seed"] * 101


def dome(out, cx, base_y, cz, w, d, h, layers, direction, col_of):
    lh = h / layers
    y = base_y
    for i in range(layers):
        k = 1 - i * 0.26
        out.append([cx, y + direction * lh / 2, cz, w * k, lh, d * k, col_of(i, layers)])
        y += direction * lh


def cloud_boxes(r, cx, cy, cz, size, c):
    out = []
    w = size * (1.2 + r() * 0.6); d = size * (0.7 + r() * 0.3); hb = size * 0.2
    out.append([cx, cy, cz, w, hb, d, c["Side"]])
    nx = 2 + (1 if r() < 0.5 else 0); nz = 2 if d > size * 0.85 else 1
    cw, cd = w / nx, d / nz
    for i in range(nx):
        for j in range(nz):
            if r() > 0.85:
                continue
            pw = cw * (0.7 + r() * 0.3); pd = cd * (0.7 + r() * 0.3); ph = size * (0.25 + r() * 0.35)
            layers = 2 + math.floor(r() * 2)
            px = cx - w / 2 + cw * (i + 0.5) + (cw - pw) / 2 * (r() * 2 - 1)
            pz = cz - d / 2 + cd * (j + 0.5) + (cd - pd) / 2 * (r() * 2 - 1)
            dome(out, px, cy + hb / 2, pz, pw, pd, ph, layers, 1, lambda k, n: c["Top"])
    out.append([cx, cy - hb / 2 - size * 0.05, cz, w * 0.82, size * 0.1, d * 0.8, c["Bottom"]])
    return out


def deck_tile(ix, iz, islands=()):
    r = rng(tile_seed(ix, iz)); t = DECK["Tile"]; out = []
    cx, cz = (ix + 0.5) * t, (iz + 0.5) * t
    if r() > DECK["Coverage"]:
        return out
    for (x, y, z, rad) in islands:
        if abs(y - DECK["Y"]) < DECK["Thickness"] / 2 + DECK["IslandBand"] and math.hypot(cx - x, cz - z) < rad + DECK["IslandHole"]:
            return out
    thick = DECK["Thickness"] * (0.6 + r() * 0.2); sy = DECK["Y"] + (r() - 0.5) * 6; c = t / 2
    out.append([cx, sy, cz, t, thick, t, DECK["Side"]])
    for i in range(2):
        for j in range(2):
            if r() > 0.75:
                continue
            pw = 14 + r() * 16; pd = 14 + r() * 16; h = 6 + r() * 10; layers = 2 + math.floor(r() * 2); gold = r() < 0.3
            px = cx - c / 2 + c * i + (c - pw) / 2 * (r() * 2 - 1)
            pz = cz - c / 2 + c * j + (c - pd) / 2 * (r() * 2 - 1)
            dome(out, px, sy + thick / 2, pz, pw, pd, h, layers, 1,
                 lambda k, n, g=gold: DECK["TopGold"] if (g and k == n - 1) else DECK["Top"])
    for i in range(2):
        for j in range(2):
            if r() > 0.55:
                continue
            pw = 12 + r() * 18; pd = 12 + r() * 18; h = 4 + r() * 6
            px = cx - c / 2 + c * i + (c - pw) / 2 * (r() * 2 - 1)
            pz = cz - c / 2 + c * j + (c - pd) / 2 * (r() * 2 - 1)
            dome(out, px, sy - thick / 2, pz, pw, pd, h, 2, -1, lambda k, n: DECK["Bottom"])
    return out


def tower(r, x, z, base_y):
    out = []
    H = TOW["Height"][0] + r() * (TOW["Height"][1] - TOW["Height"][0])
    W = TOW["Width"][0] + r() * (TOW["Width"][1] - TOW["Width"][0])
    y, w = base_y, W
    steps = 5 + math.floor(r() * 3)
    for k in range(steps):
        h = H / steps * (1.1 - k * 0.05)
        out.append([x, y + h / 2, z, w, h, w, DECK["TopGold"] if k == steps - 1 else (DECK["Top"] if k % 2 else DECK["Side"])])
        if k < steps - 1:
            for sx in (-1, 1):
                for sz in (-1, 1):
                    if r() < 0.4:
                        continue
                    bw = w * 0.08; bh = h * (0.15 + r() * 0.2)
                    out.append([x + sx * (w / 2 - bw / 2), y + h + bh / 2, z + sz * (w / 2 - bw / 2), bw, bh, bw, DECK["Top"]])
        y += h; w *= 0.8
    return out


def overlaps(boxes, eps=0.01):
    bad = 0
    for i in range(len(boxes)):
        a = boxes[i]
        for j in range(i + 1, len(boxes)):
            b = boxes[j]
            if all(abs(a[k] - b[k]) < (a[k + 3] + b[k + 3]) / 2 - eps for k in range(3)):
                bad += 1
    return bad


# ---------- samples ----------
groups = {}
r = rng(11)
groups["PuffyCloud"] = [cloud_boxes(r, i * 110, 0, 0, 26 + r() * 26, Z0["Clouds"]) for i in range(4)]
r = rng(23)
groups["Cloudlet"] = [cloud_boxes(r, i * 60, 0, 0, 14 + r() * 14, Z1["Clouds"]) for i in range(4)]
patch = []
for ix in range(-2, 2):
    for iz in range(-2, 2):
        patch += deck_tile(ix, iz)
groups["DeckPatch"] = [[[b[0], b[1] - DECK["Y"], b[2]] + b[3:] for b in patch]]
r = rng(31)
groups["CloudTower"] = [tower(r, 0, 0, 0)]

# overlap check on every sample + a large deck area
total_bad = 0
for name, lst in groups.items():
    for boxes in lst:
        total_bad += overlaps(boxes)
big = []
for ix in range(-9, 9):
    for iz in range(-9, 9):
        big += deck_tile(ix, iz)
n_tiles_parts = len(big)
# neighbours only: compare within a tile and against the next tiles (cheap enough)
total_bad += overlaps(big[:4000])
print("deck parts in 18x18 tiles:", n_tiles_parts, "| overlaps:", total_bad)
for name, lst in groups.items():
    print(name, [len(b) for b in lst])

# ---------- rbxmx ----------
_r = [0]
def ref():
    _r[0] += 1
    return f"RBXC{_r[0]:07X}"

def fmt(n):
    return f"{n:.3f}".rstrip("0").rstrip(".") if abs(n) >= 1e-6 else "0"

def c3(hexs):
    v = int(hexs, 16)
    return 0xFF000000 | v

def part_xml(name, b):
    x, y, z, sx, sy, sz, col = b
    cf = (f'<CoordinateFrame name="CFrame"><X>{fmt(x)}</X><Y>{fmt(y)}</Y><Z>{fmt(z)}</Z>'
          '<R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>')
    return (f'<Item class="Part" referent="{ref()}"><Properties><string name="Name">{name}</string>{cf}'
            f'<Vector3 name="size"><X>{fmt(sx)}</X><Y>{fmt(sy)}</Y><Z>{fmt(sz)}</Z></Vector3>'
            f'<Color3uint8 name="Color3uint8">{c3(col)}</Color3uint8><token name="Material">272</token>'
            '<bool name="Anchored">true</bool><bool name="CanCollide">false</bool><bool name="CanQuery">false</bool>'
            '<bool name="CanTouch">false</bool><bool name="CastShadow">false</bool>'
            '<token name="TopSurface">0</token><token name="BottomSurface">0</token></Properties></Item>')

items = []
offset = {"PuffyCloud": (0, 60, 0), "Cloudlet": (0, 130, 0), "DeckPatch": (0, 200, 0), "CloudTower": (420, 0, 0)}
for name, lst in groups.items():
    for n, boxes in enumerate(lst, 1):
        ox, oy, oz = offset[name]
        xs = [b[0] for b in boxes]; cxm = (min(xs) + max(xs)) / 2 if name != "DeckPatch" else 0
        ps = "".join(part_xml("Puff" if i else "Base", [b[0] + ox, b[1] + oy, b[2] + oz] + b[3:]) for i, b in enumerate(boxes))
        items.append(f'<Item class="Model" referent="{ref()}"><Properties><string name="Name">{name}{n if len(lst) > 1 else ""}</string></Properties>{ps}</Item>')
xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">'
       f'<Item class="Model" referent="{ref()}"><Properties><string name="Name">CloudModels</string></Properties>'
       + "".join(items) + "</Item></roblox>")
open(OUT, "w").write(xml)
print("wrote", OUT, len(xml))
