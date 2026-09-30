#!/usr/bin/env python3
"""Start map generator for 1+ Ballon Pop: the "Balloon Festival" grass plaza.

Builds the whole start map from docs/reference/start-map-festival.webp out of classic
stud Parts (section 14 of the game prompt) and writes build/StartMap.rbxmx: a static,
script-free Model you drag into Studio and can edit by hand afterwards.

    python3 tools/map/build_start_map.py            # write build/StartMap.rbxmx
    python3 tools/map/build_start_map.py --preview  # also render docs/map/*.png (numpy + pillow)

Layout (studs, +Y up): the plaza centre is the origin and the grass top is y = 0
(HazardConfig.GroundY). North (-Z) is the golden-arch terrace, south (+Z) the path, the
river and the bridge. The Shop is west, the Index hall east, the Upgrades workshop north-east.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools", "balloons"))
import build_balloons as BB  # noqa: E402  (reuse balloon designs + math helpers)

OUT = os.path.join(ROOT, "build", "StartMap.rbxmx")
PREVIEW = os.path.join(ROOT, "docs", "map")

I3 = BB.IDENTITY
rng = random.Random(1)


# ----------------------------------------------------------------------------- palette

C = {
    "grass": "62BE4A", "grass2": "58B343", "dirt": "8A5A2E", "stone": "A3A2A5", "stoneDark": "7B7A80",
    "cream": "EAD9AE", "creamDark": "D6C08C", "sand": "E3CE9E", "tan": "D9C08C", "tanDark": "C9AC72",
    "yellow": "F5CD30", "gold": "FFC21A", "goldDark": "D99A00", "blue": "3BA5FF", "blueDark": "2C7BD9",
    "sky": "8AD1FF", "cyan": "39D2E6", "white": "F4F0E6", "red": "D6283A", "redDark": "A3122F",
    "wood": "8B5A2B", "woodLight": "A8703C", "woodDark": "6E4520", "leaf": "3DAA4A", "leaf2": "2F9E44",
    "leaf3": "4CC766", "pine": "1E7A3A", "pine2": "28904A", "water": "3B8FF0", "waterLight": "5AB0FF",
    "black": "2A2A2A", "silver": "C9CED6", "lantern": "FFE08A", "pink": "FF7AB6", "purple": "8A4FD8",
    "orange": "FF8A1F", "lily": "3FBF4F", "flowerY": "FFD21F",
}
MATS = {"P": 256, "S": 272, "N": 288, "G": 1568, "W": 512}


# ----------------------------------------------------------------------------- scene

class Scene:
    def __init__(self):
        self.groups = {}  # name -> list of part dicts
        self.lights = []

    def add(self, group, shape, color, size, pos, rot=I3, mat="P", tr=0.0, collide=True, name=None, light=None, cls=None):
        if min(size) <= 0.01:
            return
        self.groups.setdefault(group, []).append({
            "shape": shape, "color": color, "size": tuple(size), "pos": tuple(pos), "rot": rot, "mat": mat,
            "tr": tr, "collide": collide, "name": name, "light": light, "cls": cls,
        })

    def count(self):
        return sum(len(v) for v in self.groups.values())


class T:
    """A placement frame: position + rotation + uniform scale. Builders work in local units."""

    def __init__(self, pos=(0, 0, 0), m=I3, s=1.0):
        self.pos = pos
        self.m = m
        self.s = s

    def p(self, v):
        return BB.add(self.pos, BB.apply(self.m, BB.scale(v, self.s)))

    def r(self, m):
        return BB.matmul(self.m, m)

    def at(self, v, m=I3):
        return T(self.p(v), self.r(m), self.s)


def facing(pos, target=(0, 0, 0), s=1.0):
    """Frame at `pos` whose local -Z (front) looks at `target` (level), scaled by `s`."""
    z = BB.norm((pos[0] - target[0], 0, pos[2] - target[2]))
    y = (0, 1, 0)
    x = BB.cross(y, z)
    return T(pos, (x[0], y[0], z[0], x[1], y[1], z[1], x[2], y[2], z[2]), s)


def yaw(deg):
    return BB.rot_axis((0, 1, 0), deg)


S = Scene()


def box(g, t, color, size, center, rot=I3, mat="P", tr=0.0, collide=True, name=None):
    S.add(g, "B", color, BB.scale(size, t.s), t.p(center), t.r(rot), mat, tr, collide, name)


def wedge(g, t, color, size, center, rot=I3, mat="P", collide=True):
    S.add(g, "W", color, BB.scale(size, t.s), t.p(center), t.r(rot), mat, 0.0, collide)


def span(g, t, color, x0, x1, y0, y1, z0, z1, mat="P", tr=0.0, collide=True):
    box(g, t, color, (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat=mat, tr=tr, collide=collide)


def light(g, t, pos, color="FFD98A", brightness=1.4, rng_=16):
    S.add(g, "L", color, (0.2, 0.2, 0.2), t.p(pos), I3, "P", 1.0, False, "Light", (color, brightness, rng_))


def roof_prism(g, t, color, base, direction, length, width, depth, ridge):
    """Two wedges forming a triangular prism (flags, spikes) in frame t."""
    m = BB.basis(direction, ridge)
    mid = BB.add(base, BB.scale(BB.norm(direction), length / 2))
    wedge(g, t, color, (depth, length, width / 2), BB.add(mid, BB.apply(m, (0, 0, -width / 4))), m, collide=False)
    m2 = BB.matmul(m, BB.rot_axis((0, 1, 0), 180))
    wedge(g, t, color, (depth, length, width / 2), BB.add(mid, BB.apply(m, (0, 0, width / 4))), m2, collide=False)


def voxels(g, t, vox, unit=1.0, offset=(0, 0, 0), mats=None, collide=True):
    """Greedy-merge a {(x,y,z): color} grid into boxes."""
    b = BB.Balloon("tmp")
    b.vox = dict(vox)
    for shape, key, size, pos, rot in b.mesh():
        s = tuple(v * unit for v in size)
        p = tuple(offset[i] + pos[i] * unit for i in range(3))
        box(g, t, key, s, p, mat=(mats or {}).get(key, "P"), collide=collide)


def balloon_model(g, t, kind, center, scale_=0.4, recolor=None, spin=0):
    """Place one of the real balloon designs (from build_balloons) as static parts."""
    maker = {f.__name__: f for f in BB.DESIGNS}[kind.lower()]
    b = maker()
    rot = yaw(spin)
    for shape, key, size, pos, prot in b.all_parts():
        hexv, mat, tr = b.palette[key]
        if recolor:
            hexv = recolor(key, pos, hexv)
        p = BB.add(center, BB.apply(rot, BB.scale(pos, scale_)))
        S.add(g, shape, hexv, tuple(v * scale_ * t.s for v in size), t.p(p), t.r(BB.matmul(rot, prot)), mat, tr, False)
    # string down to the pedestal
    knot = BB.add(center, BB.apply(rot, BB.scale(b.knot, scale_)))
    return knot


# ----------------------------------------------------------------------------- pixel text

FONT = {
    "S": ["###", "#..", "###", "..#", "###"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "O": ["###", "#.#", "#.#", "#.#", "###"], "P": ["###", "#.#", "###", "#..", "#.."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"], "G": ["###", "#..", "#.#", "#.#", "###"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"], "A": ["###", "#.#", "###", "#.#", "#.#"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."], "E": ["###", "#..", "##.", "#..", "###"],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"], "W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"],
    "L": ["#..", "#..", "#..", "#..", "###"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."], "C": ["###", "#..", "#..", "#..", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
}


def text(g, t, s, center, px, color, depth=0.4):
    """Block letters in the XY plane of t, centred at `center`, facing -Z (readable from the front)."""
    widths = [len(FONT[ch][0]) for ch in s]
    total = sum(widths) + (len(s) - 1)
    x = -total / 2
    for ch, w in zip(s, widths):
        for row, line in enumerate(FONT[ch]):
            col = 0
            while col < w:
                if line[col] == "#":
                    start = col
                    while col < w and line[col] == "#":
                        col += 1
                    run = col - start
                    cx = -(x + start + run / 2) * px  # facing -Z, the viewer's right is -X
                    cy = (2 - row) * px
                    box(g, t, color, (run * px, px, depth), BB.add(center, (cx, cy, 0)), mat="S", collide=False)
                else:
                    col += 1
        x += w + 1


# ----------------------------------------------------------------------------- props

def tree(g, x, z, y=0, h=6, big=1.0):
    t = T((x, y, z), yaw(rng.uniform(0, 90)))
    box(g, t, C["wood"], (2 * big, h, 2 * big), (0, h / 2, 0))
    greens = [C["leaf"], C["leaf2"], C["leaf3"]]
    rng.shuffle(greens)
    s = big
    box(g, t, greens[0], (8 * s, 3 * s, 8 * s), (0, h + 1.5 * s, 0))
    box(g, t, greens[1], (6 * s, 3 * s, 6 * s), (0.5 * s, h + 4.5 * s, -0.5 * s))
    box(g, t, greens[2], (4 * s, 2 * s, 4 * s), (-0.5 * s, h + 7 * s, 0.5 * s))
    for _ in range(3):
        box(g, t, greens[rng.randrange(3)], (2 * s, 2 * s, 2 * s),
            (rng.choice([-4.5, 4.5]) * s, h + rng.uniform(0.5, 3) * s, rng.uniform(-3, 3) * s))


def pine(g, x, z, y=0, s=1.0):
    t = T((x, y, z))
    box(g, t, C["woodDark"], (1.5 * s, 3 * s, 1.5 * s), (0, 1.5 * s, 0))
    for k, w in enumerate((7, 5, 3, 1.4)):
        box(g, t, C["pine"] if k % 2 == 0 else C["pine2"], (w * s, 2.2 * s, w * s), (0, (3 + 1.1 + k * 2.2) * s, 0))


def flower(g, x, z, y=0):
    t = T((x, y, z))
    kind = rng.choice(["daisy", "red", "yellow", "pink", "daisy"])
    box(g, t, C["leaf2"], (0.3, 1.1, 0.3), (0, 0.55, 0), collide=False)
    if kind == "daisy":
        box(g, t, "FFFFFF", (1.2, 0.3, 1.2), (0, 1.2, 0), rot=yaw(45), collide=False)
        box(g, t, C["flowerY"], (0.5, 0.4, 0.5), (0, 1.3, 0), collide=False)
    else:
        col = {"red": "E0303A", "yellow": C["flowerY"], "pink": C["pink"]}[kind]
        box(g, t, col, (0.8, 0.8, 0.8), (0, 1.4, 0), collide=False)


def lamp(g, x, z, y=0, face=0):
    t = T((x, y, z), yaw(face))
    box(g, t, C["woodDark"], (0.8, 7, 0.8), (0, 3.5, 0))
    box(g, t, C["woodDark"], (0.6, 0.6, 2.2), (0, 6.8, -0.9))
    box(g, t, C["black"], (1.3, 1.5, 1.3), (0, 5.8, -1.8), mat="S", collide=False)
    box(g, t, C["lantern"], (0.9, 1.1, 0.9), (0, 5.8, -1.8), mat="N", collide=False)
    light(g, t, (0, 5.8, -1.8))
    return t.p((0, 6.9, 0))


def bunting(g, p0, p1, sag=1.2):
    """A string between two points with triangle pennants hanging from it."""
    colors = [C["red"], C["yellow"], C["blue"], C["white"], "3FBF4F", C["pink"]]
    d = BB.add(p1, BB.scale(p0, -1))
    L = math.sqrt(BB.dot(d, d))
    if L < 1:
        return
    n = max(2, int(L / 1.8))
    side = BB.norm((-d[2], 0, d[0])) if abs(d[0]) + abs(d[2]) > 0.01 else (1, 0, 0)
    prev = p0
    for i in range(1, n + 1):
        f = i / n
        p = BB.add(BB.add(p0, BB.scale(d, f)), (0, -sag * 4 * f * (1 - f), 0))
        seg = BB.add(p, BB.scale(prev, -1))
        sl = math.sqrt(BB.dot(seg, seg))
        mid = BB.scale(BB.add(p, prev), 0.5)
        S.add(g, "B", "F4F6FF", (0.12, sl, 0.12), mid, BB.basis(seg), "S", 0, False)
        if i < n:
            roof_prism(g, T(), colors[i % len(colors)], p, (0, -1, 0), 1.1, 0.9, 0.08, side)
        prev = p


def fence(g, p0, p1, y=0, step=4.0):
    d = (p1[0] - p0[0], 0, p1[1] - p0[1])
    L = math.hypot(d[0], d[2])
    n = max(1, int(L / step))
    ang = math.degrees(math.atan2(d[0], d[2]))
    for i in range(n + 1):
        f = i / n
        x, z = p0[0] + d[0] * f, p0[1] + d[2] * f
        box(g, T((x, y, z)), C["wood"], (0.9, 3.2, 0.9), (0, 1.6, 0))
        box(g, T((x, y, z)), C["woodLight"], (1.0, 0.4, 1.0), (0, 3.4, 0))
    for h in (1.2, 2.5):
        box(g, T(((p0[0] + p1[0]) / 2, y, (p0[1] + p1[1]) / 2), yaw(ang)), C["woodLight"], (0.4, 0.5, L), (0, h, 0))


def rock(g, x, z, y=0, s=1.0):
    t = T((x, y, z), yaw(rng.uniform(0, 90)))
    box(g, t, C["stone"], (2.4 * s, 1.6 * s, 2 * s), (0, 0.8 * s, 0))
    box(g, t, C["stoneDark"], (1.4 * s, 1.2 * s, 1.4 * s), (1.2 * s, 0.6 * s, 0.6 * s))
    box(g, t, C["stone"], (1.2 * s, 1.0 * s, 1.0 * s), (-0.8 * s, 1.9 * s, -0.2 * s))


def crate(g, t, pos, s=2.0):
    box(g, t, C["woodLight"], (s, s, s), BB.add(pos, (0, s / 2, 0)))
    box(g, t, C["woodDark"], (s + 0.1, 0.25, s + 0.1), BB.add(pos, (0, s - 0.15, 0)))
    box(g, t, C["woodDark"], (s + 0.1, 0.25, s + 0.1), BB.add(pos, (0, 0.15, 0)))


def pedestal(g, t, pos, h=3.0, color=None):
    box(g, t, color or "FFFFFF", (2.6, h, 2.6), BB.add(pos, (0, h / 2, 0)), mat="S")
    box(g, t, C["gold"], (3.0, 0.4, 3.0), BB.add(pos, (0, h + 0.2, 0)))
    return BB.add(pos, (0, h + 0.4, 0))


def string_between(g, t, a, b):
    d = BB.add(b, BB.scale(a, -1))
    L = math.sqrt(BB.dot(d, d))
    if L > 0.05:
        S.add(g, "B", "F4F6FF", (0.1, L * t.s, 0.1), t.p(BB.scale(BB.add(a, b), 0.5)), t.r(BB.basis(d)), "S", 0, False)


# ----------------------------------------------------------------------------- terrain

RIVER_W = 9.0


def river_z(x):
    return 104 + 7 * math.sin(x / 28)


def build_ground():
    g = "Ground"
    for x0 in range(-160, 160, 4):
        xc = x0 + 2
        za = round(river_z(xc) - RIVER_W)
        zb = round(river_z(xc) + RIVER_W)
        shade = C["grass"] if (x0 // 8) % 2 == 0 else C["grass2"]
        span(g, T(), shade, x0, x0 + 4, -4, 0, -160, za)
        span(g, T(), shade, x0, x0 + 4, -4, 0, zb, 160)
        # river bed + water
        span("River", T(), C["sand"], x0, x0 + 4, -4, -2.6, za, zb)
        span("River", T(), C["water"], x0, x0 + 4, -2.6, -1.1, za, zb, tr=0.15, collide=False)
        # stone banks cover the trench walls
        span("River", T(), C["stone"] if x0 % 8 else C["stoneDark"], x0, x0 + 4, -2.6, 0.3, za - 0.01, za + 0.9)
        span("River", T(), C["stoneDark"] if x0 % 8 else C["stone"], x0, x0 + 4, -2.6, 0.3, zb - 0.9, zb + 0.01)
    # lily pads + rocks in the water
    for _ in range(26):
        x = rng.uniform(-150, 150)
        if abs(x) < 10:
            continue
        z = river_z(x) + rng.uniform(-5, 5)
        box("River", T((x, -1.05, z), yaw(rng.uniform(0, 90))), C["lily"], (2.2, 0.2, 2.2), (0, 0, 0), collide=False)
    for _ in range(8):
        x = rng.uniform(-150, 150)
        if abs(x) < 12:
            continue
        rock("River", x, river_z(x) + rng.choice([-7.5, 7.5]), y=-1.2, s=0.9)


def build_terrace():
    g = "Terrace"
    # raised back terrace (y 0..6) with a stair gap, then higher hills behind it
    for x0 in range(-160, 160, 16):
        x1 = x0 + 16
        span(g, T(), C["stone"], x0, x1, 0, 5, -160, -80)
        span(g, T(), C["grass"], x0, x1, 5, 6, -160, -80)
    # cliff texture on the front face
    for x in range(-156, 157, 3):
        if abs(x) < 12:
            continue
        for y in (1, 3):
            if rng.random() < 0.45:
                box(g, T((x + rng.uniform(-0.5, 0.5), y + rng.uniform(0, 1), -79.8)), C["stoneDark"], (2.2, 1.2, 0.6), (0, 0, 0))
    # grand stairs up to the arch
    for k in range(1, 7):
        span(g, T(), C["cream"] if k % 2 else C["creamDark"], -12, 12, 0, k, -80, -80 + 2 * (7 - k))
    for s in (-1, 1):
        span(g, T(), C["creamDark"], s * 12 - 1, s * 12 + 1, 0, 7, -80, -66)
        lamp(g, s * 13.5, -67, y=7, face=180)
    # fence along the terrace edge
    fence(g, (-150, -81), (-14, -81), y=6)
    fence(g, (14, -81), (150, -81), y=6)
    # back hills
    for x0 in range(-160, 160, 20):
        h = 12 + (x0 // 20) % 3 * 2
        span("Hills", T(), C["stone"], x0, x0 + 20, 6, h - 1, -160, -128)
        span("Hills", T(), C["grass2"], x0, x0 + 20, h - 1, h, -160, -128)
    for z0 in range(-128, 160, 24):
        for side in (-1, 1):
            h = 7 + (z0 // 24) % 2 * 2
            x0, x1 = (136, 160) if side > 0 else (-160, -136)
            base = 6 if z0 < -80 else 0
            if base == 0 and river_z(x0) - RIVER_W - 1 < z0 + 24 and z0 < river_z(x0) + RIVER_W + 1:
                continue
            span("Hills", T(), C["stone"], x0, x1, base, base + h - 1, z0, z0 + 24)
            span("Hills", T(), C["grass2"], x0, x1, base + h - 1, base + h, z0, z0 + 24)


# ----------------------------------------------------------------------------- plaza

def ring_rows(r_out, r_in, step=2.0):
    """Row strips of an annulus in the XZ plane: (x0, x1, z0, z1)."""
    out = []
    z = -r_out
    while z < r_out - 1e-6:
        zc = z + step / 2
        wo = math.sqrt(max(0.0, r_out ** 2 - zc ** 2))
        wi = math.sqrt(max(0.0, r_in ** 2 - zc ** 2)) if abs(zc) < r_in else 0
        wo = round(wo)
        wi = round(wi)
        if wo > 0:
            if wi > 0:
                out.append((-wo, -wi, z, z + step))
                out.append((wi, wo, z, z + step))
            else:
                out.append((-wo, wo, z, z + step))
        z += step
    return out


def build_plaza():
    g = "Plaza"
    tiers = [(40, 1.2), (34, 2.4), (28, 3.6)]
    for r, top in tiers:
        for x0, x1, z0, z1 in ring_rows(r, r - 2.5):
            span(g, T(), C["yellow"], x0, x1, 0, top, z0, z1)
        for x0, x1, z0, z1 in ring_rows(r - 2.5, 0):
            span(g, T(), C["cream"], x0, x1, 0, top - 0.01, z0, z1)
    # sun mosaic on top: a 1-stud tile grid, greedy merged
    mosaic = {}
    for x in range(-27, 28):
        for z in range(-27, 28):
            r = math.hypot(x, z)
            if r > 25.5:
                continue
            a = math.atan2(z, x)
            col = C["cream"]
            k = (a / (math.pi / 4)) % 1
            longRay = round(a / (math.pi / 2)) * (math.pi / 2)
            ray = abs(math.remainder(a, math.pi / 4)) * r
            is_long = abs(math.remainder(a - longRay, 2 * math.pi)) < math.pi / 8
            reach = 23 if is_long else 16
            if r <= 1.6:
                col = C["blueDark"]
            elif r <= 3.2:
                col = "FFFFFF"
            elif r <= 5:
                col = C["cyan"]
            elif r <= 10:
                col = C["yellow"] if r > 8.6 else C["sand"]
            elif r <= reach and ray < (reach - r) * 0.33 + 0.4:
                col = C["blue"] if r < reach - 4 else C["sky"]
            elif 24 <= r <= 25.5:
                col = C["yellow"]
            if col:
                mosaic[(x, 0, z)] = col
            _ = k
    voxels(g, T(), mosaic, unit=1.0, offset=(0, 3.3, 0))
    # stairs on four sides
    for ang in (0, 90, 180, 270):
        t = T((0, 0, 0), yaw(ang))
        for r, top in tiers:
            span(g, t, C["creamDark"], -6, 6, 0, top - 0.6, r - 0.5, r + 1.4)
    # lamp posts + bunting around the rim
    posts = []
    for i in range(8):
        a = math.radians(22.5 + 45 * i)
        x, z = math.cos(a) * 38.2, math.sin(a) * 38.2
        posts.append(lamp(g, x, z, y=1.2, face=-math.degrees(a) - 90))
    for i in range(8):
        bunting("Decor", posts[i], posts[(i + 1) % 8], sag=1.6)
    # spawn on the target
    S.add(g, "B", C["cyan"], (6, 0.2, 6), (0, 3.95, 0), I3, "P", 1.0, True, "SpawnLocation", cls="SpawnLocation")


def build_paths():
    g = "Paths"

    def cobble(x0, x1, z0, z1, y=0.15):
        for z in range(int(z0), int(z1), 2):
            if z0 <= z < z1:
                # skip the river
                if river_z((x0 + x1) / 2) - RIVER_W - 2 < z + 2 and z < river_z((x0 + x1) / 2) + RIVER_W + 2:
                    continue
                row = []
                x = x0
                while x < x1:
                    col = C["tan"] if rng.random() > 0.3 else rng.choice([C["tanDark"], C["sand"]])
                    row.append((x, col))
                    x += 2
                i = 0
                while i < len(row):
                    j = i
                    while j + 1 < len(row) and row[j + 1][1] == row[i][1]:
                        j += 1
                    span(g, T(), row[i][1], row[i][0], row[j][0] + 2, -0.3, y, z, z + 2)
                    i = j + 1

    cobble(-6, 6, 42, 160)
    cobble(-6, 6, -66, -40)
    cobble(-62, -42, -6, 6)  # to the shop
    cobble(42, 70, -6, 6)  # to the index
    # to the upgrades workshop (diagonal-ish, as steps)
    for i in range(8):
        span(g, T(), C["tan"] if i % 2 else C["tanDark"], 22 + i * 2.4, 30 + i * 2.4, -0.3, 0.15, -28 - i * 2.8, -22 - i * 2.8)
    # main bridge over the river
    zc = river_z(0)
    za, zb = zc - RIVER_W - 2, zc + RIVER_W + 2
    z = za
    k = 0
    while z < zb:
        span(g, T(), C["wood"] if k % 2 else C["woodLight"], -7, 7, -0.2, 0.5, z, z + 1.8)
        z += 1.8
        k += 1
    for s in (-1, 1):
        fence(g, (s * 7.5, za), (s * 7.5, zb), y=0.5, step=3)
    # small wooden bridge on the west
    xb = -92
    zc = river_z(xb)
    for k, z in enumerate(range(int(zc - RIVER_W - 2), int(zc + RIVER_W + 2), 2)):
        span(g, T(), C["woodLight"] if k % 2 else C["wood"], xb - 3.5, xb + 3.5, -0.1, 0.6, z, z + 1.9)
    for s in (-1, 1):
        fence(g, (xb + s * 3.8, zc - RIVER_W - 2), (xb + s * 3.8, zc + RIVER_W + 2), y=0.6, step=3)
    # fences + lamps along the south path
    for s in (-1, 1):
        fence(g, (s * 8, 60), (s * 8, zc if False else river_z(0) - RIVER_W - 3), step=4)
        lamp("Decor", s * 9, 58, face=90 * s)
        lamp("Decor", s * 9, 128, face=90 * s)
    bunting("Decor", (-9, 6.9, 58), (9, 6.9, 58), sag=1.0)
    bunting("Decor", (-9, 6.9, 128), (9, 6.9, 128), sag=1.0)


# ----------------------------------------------------------------------------- buildings

def build_shop():
    g = "Shop"
    t = facing((-84, 0, -6), s=1.5)
    # platform + steps
    span(g, t, C["cream"], -17, 17, 0, 1, -12, 12)
    span(g, t, C["creamDark"], -7, 7, 0, 0.66, -13.5, -12)
    span(g, t, C["creamDark"], -7, 7, 0, 0.33, -15, -13.5)
    # striped walls
    for i, x in enumerate(range(-15, 15, 2)):
        col = C["red"] if i % 2 == 0 else C["white"]
        span(g, t, col, x, x + 2, 1, 12, 9, 10)
    for s in (-1, 1):
        for i, z in enumerate(range(-8, 10, 2)):
            col = C["red"] if i % 2 == 0 else C["white"]
            xs = (15, 16) if s > 0 else (-16, -15)
            span(g, t, col, xs[0], xs[1], 1, 12, z, z + 2)
    # floor, counter, shelves
    span(g, t, C["woodLight"], -15, 15, 1, 1.2, -8, 9)
    span(g, t, "FFFFFF", -12, 12, 1, 3.6, -3.5, -2)
    span(g, t, C["red"], -12.3, 12.3, 3.6, 4.0, -3.8, -1.7)
    for x in (-10, -4, 4, 10):
        crate(g, t, (x, 1.2, 6), s=2.2)
        crate(g, t, (x + 0.2, 3.4, 6), s=1.8)
    # pillars
    for x in (-15, -5, 5, 15):
        for k, y0 in enumerate(range(1, 12, 2)):
            span(g, t, C["red"] if k % 2 == 0 else C["white"], x - 1, x + 1, y0, y0 + 2, -9, -7)
    # sign with block letters
    span(g, t, C["red"], -9, 9, 9.6, 14.6, -9.4, -8.6)
    span(g, t, "FFFFFF", -9.4, 9.4, 9.3, 9.7, -9.5, -8.5)
    text(g, t, "SHOP", (0, 12.0, -9.6), 0.8, "FFFFFF")
    # striped awning over the storefront
    for i, x in enumerate(range(-15, 15, 2)):
        wedge(g, t, C["red"] if i % 2 == 0 else C["white"], (2, 1.6, 4.4), (x + 1, 8.4, -10.8))
    for i, x in enumerate(range(-15, 15, 2)):
        box(g, t, C["red"] if i % 2 == 0 else C["white"], (2, 0.6, 0.4), (x + 1, 7.3, -13.0))
    # display pedestals with balloons
    for x, kind in ((-8, "Gumball"), (0, "Volt"), (8, "Sun")):
        top = pedestal(g, t, (x, 1.2, -6), h=1.8)
        center = (x, top[1] + 3.6, -6)
        knot = balloon_model(g, t, kind, center, scale_=0.36, spin=20)
        string_between(g, t, top, knot)
    # roof + gumball dome
    span(g, t, "FFFFFF", -16, 16, 12, 12.8, -9, 10)
    span(g, t, C["red"], -16.3, 16.3, 12.8, 13.4, -9.3, 10.3)
    dome = {}
    R = 4.6
    for i in range(-5, 6):
        for j in range(0, 10):
            for k in range(-5, 6):
                if i * i + (j - 4.5) ** 2 + k * k <= R * R:
                    dome[(i, j, k)] = C["red"] if (i + j + k) % 2 == 0 else "FFFFFF"
    voxels(g, t, dome, unit=2.0, offset=(0, 13.4 + 1, 0.5))
    span(g, t, C["redDark"], -5, 5, 13.4, 14.4, -4.5, 5.5)
    box(g, t, C["redDark"], (2, 2, 2), (0, 33.5, 0.5))
    # restock clock board
    ct = t.at((19.5, 0, -10), yaw(-20))
    box(g, ct, C["woodDark"], (0.4, 5, 0.4), (-1.6, 2.5, 0.6))
    box(g, ct, C["woodDark"], (0.4, 5, 0.4), (1.6, 2.5, 0.6))
    box(g, ct, C["black"], (4.4, 4.4, 0.4), (0, 4.4, 0), mat="S")
    clock = {}
    for i in range(-3, 4):
        for j in range(-3, 4):
            if i * i + j * j <= 9.5:
                clock[(i, j, 0)] = "FFFFFF"
    voxels(g, ct, clock, unit=0.5, offset=(0, 4.4, -0.3))
    box(g, ct, C["black"], (0.2, 1.3, 0.2), (0, 4.9, -0.6))
    box(g, ct, C["red"], (0.9, 0.2, 0.2), (0.4, 4.4, -0.6))
    # crates outside + lanterns + bunting
    for p in ((-19.5, 0, -4), (-19.5, 0, -1.5), (-19.3, 2, -2.8), (-20, 0, 1)):
        crate(g, t, p, s=2.2)
    for x in (-15, 15):
        box(g, t, C["black"], (1.2, 1.4, 1.2), (x, 6.6, -10.3), mat="S", collide=False)
        box(g, t, C["lantern"], (0.8, 1.0, 0.8), (x, 6.6, -10.3), mat="N", collide=False)
        light(g, t, (x, 6.6, -10.3))
    bunting("Decor", t.p((-16, 12, -9.5)), t.p((-25, 7, -16)), sag=0.8)


def build_index():
    g = "Index"
    t = facing((94, 0, 8), s=1.45)
    span(g, t, C["cream"], -20, 20, 0, 1, -13, 12)
    for k in range(3):
        span(g, t, C["creamDark"], -9, 9, 0, 1 - k * 0.33, -13 - 1.5 * (k + 1), -13 - 1.5 * k)
    # walls
    span(g, t, C["blue"], -18, 18, 1, 10, 9, 10)
    span(g, t, C["blue"], -18, -17, 1, 10, -8, 10)
    span(g, t, C["blue"], 17, 18, 1, 10, -8, 10)
    span(g, t, "FFFFFF", -18.3, 18.3, 1, 1.8, -8.3, 10.3)
    span(g, t, "FFFFFF", -18.3, 18.3, 9.2, 10, -8.3, 10.3)
    # display bays
    for x in (-18, -9, 0, 9, 18):
        span(g, t, "FFFFFF", x - 1, x + 1, 1, 10, -9, -7)
    kinds = [("Gumball", None), ("Gumball", "rainbow"), ("Frost", None), ("Void", None)]
    rainbow = ["FF3B3B", "FF8A1F", "FFD21F", "3FBF4F", "3BA5FF", "8A4FD8"]
    for n, x in enumerate((-13.5, -4.5, 4.5, 13.5)):
        span(g, t, C["blueDark"], x - 3.5, x + 3.5, 1.8, 9.2, -3.5, -3)
        span(g, t, C["sky"], x - 3.5, x + 3.5, 1, 1.4, -7, -3)
        # stepped arch
        for k, w in enumerate((3.5, 2.5, 1.5)):
            span(g, t, "FFFFFF", x - 3.5, x - w, 9.2 - (k + 1) * 0.7, 9.2 - k * 0.7, -8.6, -7.4)
            span(g, t, "FFFFFF", x + w, x + 3.5, 9.2 - (k + 1) * 0.7, 9.2 - k * 0.7, -8.6, -7.4)
        top = pedestal(g, t, (x, 1.4, -5), h=2.4)
        kind, recolor = kinds[n]
        rc = None
        if recolor == "rainbow":
            def rc(key, pos, hexv):
                if key in ("white", "pink", "silver", "silverDark"):
                    return hexv
                return rainbow[int(min(5, max(0, (pos[1] + 4.5) / 1.5)))]
        knot = balloon_model(g, t, kind, (x, top[1] + 3.2, -5), scale_=0.33, recolor=rc, spin=-15)
        string_between(g, t, top, knot)
    # stepped pyramid roof
    for k in range(6):
        w, d = 20 - k * 2.2, 11 - k * 1.6
        span(g, t, C["blue"] if k % 2 == 0 else "FFFFFF", -w, w, 10 + k * 1.2, 11.2 + k * 1.2, -9 + k * 0.3 - (1 if k == 0 else 0), d)
    # sign
    span(g, t, "FFFFFF", -8, 8, 10.4, 15, -10.4, -9.6)
    text(g, t, "INDEX", (0, 12.7, -10.6), 0.7, C["blueDark"])
    bunting("Decor", t.p((-18, 10, -8.5)), t.p((-26, 6.5, -16)), sag=0.8)


def build_upgrades():
    g = "Upgrades"
    t = facing((54, 0, -58), s=1.35)
    span(g, t, C["stone"], -13, 13, 0, 1, -10, 9)
    span(g, t, C["stoneDark"], -5, 5, 0, 0.5, -11.5, -10)
    # plank walls
    for k, y0 in enumerate(range(1, 10, 1)):
        col = C["wood"] if k % 2 == 0 else C["woodLight"]
        span(g, t, col, -12, 12, y0, y0 + 1, 7, 8)
        span(g, t, col, -12, -11, y0, y0 + 1, -8, 7)
        span(g, t, col, 11, 12, y0, y0 + 1, -8, 7)
    for x in (-12, 12):
        span(g, t, C["woodDark"], x - 0.6, x + 0.6, 1, 10, -8.6, -7.4)
    # gable ends (stepped)
    for k in range(5):
        w = 12 - k * 2.4
        span(g, t, C["woodLight"], -w, w, 10 + k, 11 + k, 7, 8)
    # blue gable roof
    for i, x in enumerate(range(-14, 14, 4)):
        col = C["blue"] if i % 2 == 0 else C["blueDark"]
        wedge(g, t, col, (4, 5.2, 9.5), (x + 2, 12.6, -3.2))
        wedge(g, t, col, (4, 5.2, 9.5), (x + 2, 12.6, 5.6), rot=yaw(180))
    # workbench + tools + an anvil
    span(g, t, C["woodDark"], -9, 3, 1, 3.4, 2, 4.5)
    span(g, t, C["woodLight"], -9.3, 3.3, 3.4, 3.8, 1.8, 4.7)
    for x in (-7, -4.5, -2):
        box(g, t, C["silver"], (0.8, 0.8, 1.6), (x, 4.2, 3), collide=False)
    balloon_model(g, t, "Iron", (7, 3.4, 2), scale_=0.3, spin=90)
    # sign with a gear
    span(g, t, C["woodDark"], -10, 10, 10.2, 13.8, -9.2, -8.4)
    text(g, t, "UPGRADES", (0, 12, -9.4), 0.55, C["yellow"])
    gear = {}
    for i in range(-4, 5):
        for j in range(-4, 5):
            r = math.hypot(i, j)
            tooth = (abs(i) <= 1 or abs(j) <= 1 or abs(abs(i) - abs(j)) <= 0) and r <= 4.6
            if (1.2 < r <= 3.2) or (3.2 < r and tooth):
                gear[(i, j, 0)] = C["yellow"]
    voxels(g, t, gear, unit=0.45, offset=(0, 16.2, -8.8))
    span(g, t, C["woodDark"], -2.4, 2.4, 13.8, 18.6, -8.6, -8.2)
    # giant balloon pump
    pt = t.at((17.5, 0, 1))
    span(g, pt, C["black"], -4, 4, 0, 1, -3.5, 3.5)
    span(g, pt, C["black"], -5.5, -2, 0, 0.6, -1, 1)
    span(g, pt, C["black"], 2, 5.5, 0, 0.6, -1, 1)
    for k, y0 in enumerate(range(1, 19, 3)):
        span(g, pt, C["red"] if k % 3 else C["redDark"], -2.5, 2.5, y0, y0 + 3, -2.5, 2.5)
    span(g, pt, "FFFFFF", -2.6, 2.6, 9, 9.6, -2.6, 2.6)
    span(g, pt, C["black"], -3, 3, 19, 20.5, -3, 3)
    span(g, pt, C["silver"], -0.5, 0.5, 20.5, 24, -0.5, 0.5)
    span(g, pt, C["black"], -6, 6, 24, 25.5, -0.75, 0.75)
    span(g, pt, C["black"], -6.8, -5.4, 23.6, 25.9, -1, 1)
    span(g, pt, C["black"], 5.4, 6.8, 23.6, 25.9, -1, 1)
    gauge = {}
    for i in range(-2, 3):
        for j in range(-2, 3):
            if i * i + j * j <= 5:
                gauge[(i, j, 0)] = "FFFFFF"
    voxels(g, pt, gauge, unit=0.5, offset=(0, 14, -2.7))
    box(g, pt, C["red"], (0.15, 1.0, 0.15), (0.25, 14.2, -3.0), rot=BB.rot_axis((0, 0, 1), -35), collide=False)
    # hose into the workshop
    hose = [(-3, 0.6, 0), (-5, 0.6, 1), (-7, 0.6, 2.5), (-9, 0.9, 3.5), (-10.5, 1.4, 4.5)]
    for a, b in zip(hose, hose[1:]):
        d = BB.add(b, BB.scale(a, -1))
        L = math.sqrt(BB.dot(d, d))
        box(g, pt, C["black"], (0.8, L + 0.6, 0.8), BB.scale(BB.add(a, b), 0.5), rot=BB.basis(d), collide=False)
    bunting("Decor", t.p((-12, 10, -8)), t.p((12, 10, -8)), sag=1.4)


def build_arch():
    g = "Arch"
    t = T((0, 6, -98))
    for s in (-1, 1):
        x = s * 9
        span(g, t, C["goldDark"], x - 2.6, x + 2.6, 0, 1, -2.6, 2.6)
        span(g, t, C["cream"], x - 2, x + 2, 1, 13, -2, 2)
        span(g, t, C["gold"], x - 2.4, x + 2.4, 12, 13, -2.4, 2.4)
        for y in (4, 8):
            span(g, t, C["creamDark"], x - 2.1, x + 2.1, y, y + 0.5, -2.1, 2.1)
        box(g, t, C["black"], (1.3, 1.5, 1.3), (x, 7, -2.8), mat="S", collide=False)
        box(g, t, C["lantern"], (0.9, 1.1, 0.9), (x, 7, -2.8), mat="N", collide=False)
        light(g, t, (x, 7, -2.8))
    span(g, t, C["cream"], -12, 12, 13, 16, -2.5, 2.5)
    span(g, t, C["gold"], -12.4, 12.4, 16, 16.8, -2.8, 2.8)
    span(g, t, C["gold"], -12.4, 12.4, 12.6, 13.2, -2.8, 2.8)
    # giant gold coin
    coin = {}
    for i in range(-7, 8):
        for j in range(-7, 8):
            r = math.hypot(i, j)
            if r <= 6.8:
                col = C["goldDark"] if r > 5.8 else C["gold"]
                # the square "logo" in the middle
                u = i * math.cos(0.26) - j * math.sin(0.26)
                v = i * math.sin(0.26) + j * math.cos(0.26)
                if 2.0 <= max(abs(u), abs(v)) <= 3.2:
                    col = C["goldDark"]
                coin[(i, j, 0)] = col
    voxels(g, t, coin, unit=1.0, offset=(0, 24.5, 0))
    span(g, t, C["goldDark"], -1, 1, 16.8, 18, -0.6, 0.6)
    # path on the terrace + coin piles
    span("Paths", T(), C["tan"], -6, 6, 6, 6.2, -96, -80)
    for _ in range(12):
        x = rng.choice([-1, 1]) * rng.uniform(13, 24)
        z = rng.uniform(-104, -86)
        h = rng.randint(1, 4)
        for k in range(h):
            box(g, T((x, 6, z), yaw(rng.uniform(0, 90))), C["gold"] if k % 2 == 0 else C["goldDark"], (1.8, 0.5, 1.8), (0, 0.25 + k * 0.5, 0))


# ----------------------------------------------------------------------------- border

def build_border():
    """Mountains around the map, grassland out to the horizon, far hills and clouds,
    so nobody sees the void at the edge or from high in the sky."""
    g = "Border"
    cell = 16
    for cx in range(-224, 224, cell):
        for cz in range(-224, 224, cell):
            ring = max(abs(cx + cell / 2), abs(cz + cell / 2)) - 160
            if ring < 0:
                continue
            n = math.sin(cx * 0.051 + 1.3) * math.cos(cz * 0.043 - 0.7) + math.sin((cx + cz) * 0.027)
            h = 18 + ring * 0.7 + n * 9 + rng.uniform(-3, 3)
            h = max(14, min(72, round(h / 2) * 2))
            stone = C["stone"] if (cx // cell + cz // cell) % 2 else C["stoneDark"]
            span(g, T(), stone, cx, cx + cell, 0, h - 2, cz, cz + cell)
            if h >= 52:
                span(g, T(), "F4F8FF", cx, cx + cell, h - 2, h, cz, cz + cell)
            else:
                span(g, T(), C["grass2"], cx, cx + cell, h - 2, h, cz, cz + cell)
                # a stepped ledge on some cells makes the range look carved
                if rng.random() < 0.45:
                    lx, lz = cx + rng.choice([0, 8]), cz + rng.choice([0, 8])
                    span(g, T(), stone, lx, lx + 8, h, h + 4, lz, lz + 8)
                    span(g, T(), C["grass"], lx, lx + 8, h + 4, h + 5, lz, lz + 8)
                elif rng.random() < 0.5:
                    pine("Trees", cx + cell / 2 + rng.uniform(-4, 4), cz + cell / 2 + rng.uniform(-4, 4), y=h, s=rng.uniform(0.9, 1.3))
    # invisible walls so nobody walks out over the mountains (flight limits come with FlightService)
    for x0, x1, z0, z1 in ((-163, -161, -163, 163), (161, 163, -163, 163), (-163, 163, -163, -161), (-163, 163, 161, 163)):
        S.add("Boundary", "B", "FFFFFF", (x1 - x0, 120, z1 - z0), ((x0 + x1) / 2, 60, (z0 + z1) / 2), I3, "S", 1.0, True, "InvisibleWall")
    # grassland to the horizon (max Part size is 2048)
    far = "Horizon"
    for x0, x1, z0, z1 in ((-2048, 0, -2048, -224), (0, 2048, -2048, -224), (-2048, 0, 224, 2048), (0, 2048, 224, 2048),
                           (-2048, -224, -224, 224), (224, 2048, -224, 224)):
        span(far, T(), "5AAE45", x0, x1, -4, 0, z0, z1)
    # distant stepped hills
    for i in range(26):
        a = i / 26 * 2 * math.pi + rng.uniform(-0.1, 0.1)
        r = rng.uniform(380, 900)
        x, z = math.cos(a) * r, math.sin(a) * r
        w = rng.uniform(60, 140)
        h = rng.uniform(30, 110)
        for k, (fw, fh) in enumerate(((1.0, 0.45), (0.7, 0.35), (0.42, 0.2))):
            base = h * sum(f for _, f in ((1.0, 0.45), (0.7, 0.35), (0.42, 0.2))[:k])
            col = ("4E9E3C", "5AAE45", "F4F8FF" if h > 90 else "6CBF55")[k]
            box(far, T(), col, (w * fw, h * fh, w * fw * rng.uniform(0.8, 1.2)), (x, base + h * fh / 2, z))
    # stud clouds around the sky
    for i in range(30):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(260, 1100)
        x, z = math.cos(a) * r, math.sin(a) * r
        y = rng.uniform(90, 420)
        s = rng.uniform(1.0, 2.6)
        for bx, by, bz, w, hh, d in ((0, 0, 0, 40, 10, 24), (-12, 7, 2, 18, 10, 16), (10, 8, -2, 22, 12, 18), (24, 2, 3, 14, 8, 12)):
            box("Clouds", T(), "FFFFFF", (w * s, hh * s, d * s), (x + bx * s, y + by * s, z + bz * s), mat="S", collide=False)


# ----------------------------------------------------------------------------- scatter

OCCUPIED = [
    (-46, 46, -46, 46),  # plaza
    (-118, -52, -40, 30),  # shop
    (60, 130, -30, 46),  # index
    (26, 90, -86, -34),  # upgrades
    (-9, 9, 40, 160),  # path
    (-160, 160, -160, -79),  # terrace
    (62, 138, 60, 90),  # demo balloon gallery field
]


def free(x, z, pad=2):
    for x0, x1, z0, z1 in OCCUPIED:
        if x0 - pad <= x <= x1 + pad and z0 - pad <= z <= z1 + pad:
            return False
    if abs(z - river_z(x)) < RIVER_W + 2:
        return False
    return abs(x) < 134 and abs(z) < 156


def build_scatter():
    trees = [(-60, 50), (-100, 36), (-122, -12), (-126, 60), (-60, 72), (-30, 60), (40, 58), (60, 124),
             (-40, 132), (-78, 140), (-120, 132), (120, 140), (30, 140), (-124, -60), (-110, -70), (120, -40),
             (126, 10), (-20, -62), (96, -64), (-56, -64)]
    for x, z in trees:
        if free(x, z, pad=0):
            tree("Trees", x, z, h=rng.uniform(5, 7), big=rng.uniform(0.9, 1.25))
    for x in range(-150, 151, 13):
        for z in (-110, -140):
            pine("Trees", x + rng.uniform(-3, 3), z + rng.uniform(-4, 4), y=6 if z == -110 else 13, s=rng.uniform(0.9, 1.3))
    for z in range(-70, 150, 16):
        for side in (-1, 1):
            if abs(z - river_z(side * 148)) < RIVER_W + 4:
                continue
            pine("Trees", side * 148, z, y=8 if z > -80 else 14, s=1.1)
    for x, z in ((-40, -110), (40, -112), (-70, -100), (75, -100)):
        tree("Trees", x, z, y=6, h=6, big=1.1)
    placed = 0
    while placed < 120:
        x, z = rng.uniform(-130, 130), rng.uniform(-76, 150)
        if free(x, z):
            flower("Flowers", x, z)
            placed += 1
    confetti = ["E0303A", C["flowerY"], C["blue"], "3FBF4F", "FFFFFF", C["pink"], C["orange"]]
    placed = 0
    while placed < 150:
        x, z = rng.uniform(-80, 80), rng.uniform(-70, 90)
        if free(x, z, pad=-2) or (46 < math.hypot(x, z) < 70):
            box("Confetti", T((x, 0, z), yaw(rng.uniform(0, 90))), rng.choice(confetti), (1, 0.35, 1), (0, 0.17, 0), collide=False)
            placed += 1
    for _ in range(14):
        x, z = rng.uniform(-130, 130), rng.uniform(-70, 150)
        if free(x, z):
            rock("Rocks", x, z, s=rng.uniform(0.8, 1.4))
    # picnic table
    pt = T((34, 0, 74), yaw(15))
    for i in range(3):
        for j in range(2):
            box("Decor", pt, C["red"] if (i + j) % 2 == 0 else "FFFFFF", (2, 0.4, 2), (-2 + i * 2, 3, -1 + j * 2), mat="S")
    for sx in (-2.4, 2.4):
        box("Decor", pt, C["woodDark"], (0.5, 3, 3), (sx, 1.5, 0))
    for sz in (-3.2, 3.2):
        box("Decor", pt, C["wood"], (7, 0.5, 1.4), (0, 1.8, sz))
        box("Decor", pt, C["woodDark"], (0.5, 1.8, 1), (-2.8, 0.9, sz))
        box("Decor", pt, C["woodDark"], (0.5, 1.8, 1), (2.8, 0.9, sz))
    # signpost
    st = T((-14, 0, 72), yaw(-10))
    box("Decor", st, C["wood"], (1, 7, 1), (0, 3.5, 0))
    box("Decor", st, C["woodLight"], (5, 1.2, 0.4), (2.2, 5.6, 0))
    wedge("Decor", st, C["woodLight"], (0.4, 1.2, 1.2), (5.2, 5.6, 0), rot=yaw(-90))
    box("Decor", st, C["woodLight"], (5, 1.2, 0.4), (-2.2, 4.0, 0))
    wedge("Decor", st, C["woodLight"], (0.4, 1.2, 1.2), (-5.2, 4.0, 0), rot=yaw(90))
    # treasure chest by the plaza
    ch = T((-30, 0, -44), yaw(30))
    box("Decor", ch, C["blue"], (4, 2.4, 2.8), (0, 1.2, 0))
    box("Decor", ch, C["blueDark"], (4.2, 1.2, 3), (0, 3.0, 0))
    box("Decor", ch, C["gold"], (0.6, 3.8, 3.1), (-1.3, 1.9, 0))
    box("Decor", ch, C["gold"], (0.6, 3.8, 3.1), (1.3, 1.9, 0))
    box("Decor", ch, C["gold"], (0.8, 0.8, 0.3), (0, 2.4, -1.6), mat="N")
    # gallery anchor (demo mode balloon gallery lays out here)
    S.add("Decor", "B", "FFFFFF", (4, 1, 4), (100, 0.5, 68), I3, "P", 1.0, False, "GalleryAnchor")


# ----------------------------------------------------------------------------- export

def color_int(hexv):
    return 0xFF000000 | int(hexv, 16)


def fmt(n):
    return f"{n:.4f}".rstrip("0").rstrip(".") if abs(n) >= 1e-6 else "0"


_ref = [0]


def ref():
    _ref[0] += 1
    return f"RBX{_ref[0]:08X}"


def part_xml(p):
    x, y, z = p["pos"]
    r = p["rot"]
    cls = p["cls"] or ("WedgePart" if p["shape"] == "W" else "Part")
    mat = MATS.get(p["mat"], 256)
    studs = p["mat"] == "P"
    props = [
        f'<string name="Name">{p["name"] or ("Wedge" if p["shape"] == "W" else "Part")}</string>',
        '<bool name="Anchored">true</bool>',
        f'<CoordinateFrame name="CFrame"><X>{fmt(x)}</X><Y>{fmt(y)}</Y><Z>{fmt(z)}</Z>'
        + "".join(f"<R{i // 3}{i % 3}>{fmt(v)}</R{i // 3}{i % 3}>" for i, v in enumerate(r)) + "</CoordinateFrame>",
        f'<Color3uint8 name="Color3uint8">{color_int(p["color"])}</Color3uint8>',
        f'<token name="Material">{mat}</token>',
        f'<Vector3 name="size"><X>{fmt(p["size"][0])}</X><Y>{fmt(p["size"][1])}</Y><Z>{fmt(p["size"][2])}</Z></Vector3>',
        f'<token name="TopSurface">{3 if studs else 0}</token>',
        f'<token name="BottomSurface">{4 if studs else 0}</token>',
        f'<float name="Transparency">{fmt(p["tr"])}</float>',
        f'<bool name="CanCollide">{"true" if p["collide"] else "false"}</bool>',
        f'<bool name="CastShadow">{"true" if p["tr"] < 0.5 else "false"}</bool>',
    ]
    if cls == "Part":
        props.append('<token name="shape">1</token>')
    if cls == "SpawnLocation":
        props += ['<bool name="Neutral">true</bool>', '<int name="Duration">0</int>', '<bool name="Enabled">true</bool>',
                  '<token name="shape">1</token>']
    children = ""
    if p["light"]:
        col, bright, rng_ = p["light"]
        rgb = [int(col[i:i + 2], 16) / 255 for i in (0, 2, 4)]
        children = (f'<Item class="PointLight" referent="{ref()}"><Properties><string name="Name">Glow</string>'
                    f'<float name="Brightness">{fmt(bright)}</float><float name="Range">{fmt(rng_)}</float>'
                    f'<Color3 name="Color"><R>{fmt(rgb[0])}</R><G>{fmt(rgb[1])}</G><B>{fmt(rgb[2])}</B></Color3>'
                    '<bool name="Shadows">false</bool></Properties></Item>')
    return f'<Item class="{cls}" referent="{ref()}"><Properties>{"".join(props)}</Properties>{children}</Item>'


def export(name="StartMap", out=None):
    out = out or OUT
    groups = []
    for name, parts in S.groups.items():
        items = "".join(part_xml(p) for p in parts)
        groups.append(f'<Item class="Model" referent="{ref()}"><Properties><string name="Name">{name}</string></Properties>{items}</Item>')
    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4"><External>null</External><External>nil</External>'
           f'<Item class="Model" referent="{ref()}"><Properties><string name="Name">{name}</string></Properties>{"".join(groups)}</Item></roblox>\n')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        f.write(xml)
    return len(xml)


# ----------------------------------------------------------------------------- preview

def render(view, W, H, out, focus=None, radius=0.0):
    import numpy as np
    from PIL import Image

    yaw_, pitch = view
    cy_, sy_ = math.cos(math.radians(yaw_)), math.sin(math.radians(yaw_))
    cp, sp = math.cos(math.radians(pitch)), math.sin(math.radians(pitch))

    def vw(v):
        x, y, z = v
        x, z = x * cy_ + z * sy_, -x * sy_ + z * cy_
        y, z = y * cp - z * sp, y * sp + z * cp
        return (x, y, z)

    tris = []
    for parts in S.groups.values():
        for p in parts:
            if p["shape"] == "L" or p["tr"] >= 0.99:
                continue
            if focus and math.hypot(p["pos"][0] - focus[0], p["pos"][2] - focus[1]) > radius:
                continue
            col = np.array([int(p["color"][i:i + 2], 16) for i in (0, 2, 4)], dtype=float)
            world, faces = BB.corners(p["shape"], p["size"], p["pos"], p["rot"])
            v = [vw(q) for q in world]
            for f in faces:
                pts = [v[i] for i in f]
                n = BB.cross(tuple(pts[1][k] - pts[0][k] for k in range(3)), tuple(pts[2][k] - pts[0][k] for k in range(3)))
                ln = math.sqrt(BB.dot(n, n)) or 1
                n = tuple(c / ln for c in n)
                for i in range(1, len(pts) - 1):
                    tris.append((pts[0], pts[i], pts[i + 1], n, col, p["mat"], p["tr"]))
    xs = [q[0] for t in tris for q in t[:3]]
    ys = [q[1] for t in tris for q in t[:3]]
    k = min(W / (max(xs) - min(xs)), H / (max(ys) - min(ys))) * 0.98
    cx, cyv = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    img = np.zeros((H, W, 3))
    img[:] = (150, 205, 250)
    zb = np.full((H, W), np.inf)
    L = BB.norm((-0.4, 0.85, -0.35))
    for a, b, c, n, col, mat, tr in tris:
        if n[2] > 0.02:
            n = (-n[0], -n[1], -n[2])
        shade = 1.0 if mat == "N" else 0.5 + 0.5 * max(0.0, BB.dot(n, L))
        rgb = col * shade
        if tr > 0:
            rgb = rgb * (1 - tr * 0.5) + np.array([150, 205, 250]) * tr * 0.5
        P = [((cx - q[0]) * k + W / 2, (cyv - q[1]) * k + H / 2, q[2]) for q in (a, b, c)]  # camera looks along +z: screen right is -x
        minx, maxx = max(0, int(min(q[0] for q in P))), min(W - 1, int(max(q[0] for q in P)) + 1)
        miny, maxy = max(0, int(min(q[1] for q in P))), min(H - 1, int(max(q[1] for q in P)) + 1)
        if minx > maxx or miny > maxy:
            continue
        gx, gy = np.meshgrid(np.arange(minx, maxx + 1) + 0.5, np.arange(miny, maxy + 1) + 0.5)
        (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = P
        den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
        if abs(den) < 1e-9:
            continue
        w0 = ((y1 - y2) * (gx - x2) + (x2 - x1) * (gy - y2)) / den
        w1 = ((y2 - y0) * (gx - x2) + (x0 - x2) * (gy - y2)) / den
        w2 = 1 - w0 - w1
        inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        z = w0 * z0 + w1 * z1 + w2 * z2
        sub = zb[miny:maxy + 1, minx:maxx + 1]
        m = inside & (z < sub)
        sub[m] = z[m]
        img[miny:maxy + 1, minx:maxx + 1][m] = rgb
    os.makedirs(PREVIEW, exist_ok=True)
    Image.fromarray(np.clip(img, 0, 255).astype("uint8")).save(os.path.join(PREVIEW, out))


def main():
    build_ground()
    build_terrace()
    build_plaza()
    build_paths()
    build_shop()
    build_index()
    build_upgrades()
    build_arch()
    build_border()
    build_scatter()
    size = export()
    print(f"StartMap: {S.count()} parts in {len(S.groups)} groups -> {os.path.relpath(OUT, ROOT)} ({size // 1024} KB)")
    for gname, parts in sorted(S.groups.items(), key=lambda kv: -len(kv[1])):
        print(f"  {gname:10s} {len(parts)}")
    if "--preview" in sys.argv:
        render((200, -32), 1800, 1100, "overview.png", focus=(0, 0), radius=235)
        render((0, -89.9), 1400, 1400, "topdown.png", focus=(0, 0), radius=235)
        render((200, -20), 1800, 900, "horizon.png", focus=(0, 0), radius=1800)
        render((75, -10), 1000, 640, "shop-front.png", focus=(-84, -6), radius=34)
        render((255, -14), 1000, 640, "index-front.png", focus=(94, 8), radius=34)
        render((215, -14), 1000, 640, "upgrades-front.png", focus=(58, -60), radius=40)
        render((180, -18), 1200, 800, "arch.png", focus=(0, -96), radius=34)
        print("previews -> docs/map/")


if __name__ == "__main__":
    main()
