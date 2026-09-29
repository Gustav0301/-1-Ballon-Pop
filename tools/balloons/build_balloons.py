#!/usr/bin/env python3
"""Balloon model pipeline for 1+ Ballon Pop.

Every balloon is designed here as a 1-stud voxel grid plus a few hand-placed detail
parts (wedge spikes, tentacles, wings...). Voxels of the same colour are greedily
merged into as few Parts as possible (the prompt's budget is 40-120 parts per balloon),
then exported to src/shared/Balloons/BalloonModels.lua, which BalloonBuilder turns
into real stud Models in Roblox.

    python3 tools/balloons/build_balloons.py            # export Luau
    python3 tools/balloons/build_balloons.py --preview  # also render docs/balloons/*.png
                                                        # (needs numpy + pillow)

Coordinates are Roblox studs: +Y up, the balloon's front faces -Z.
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_LUA = os.path.join(ROOT, "src", "shared", "Balloons", "BalloonModels.lua")
OUT_PREVIEW = os.path.join(ROOT, "docs", "balloons")

IDENTITY = (1, 0, 0, 0, 1, 0, 0, 0, 1)


# ----------------------------------------------------------------------------- math

def norm(v):
    l = math.sqrt(sum(c * c for c in v))
    return tuple(c / l for c in v)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def basis(up, side=None):
    """Rotation matrix (row-major, like CFrame components) whose local +Y points
    along `up` and local +X along `side` (made perpendicular)."""
    y = norm(up)
    if side is None:
        side = (1, 0, 0) if abs(y[0]) < 0.9 else (0, 0, 1)
    x = norm(tuple(s - dot(side, y) * c for s, c in zip(side, y)))
    z = cross(x, y)
    # columns are the local axes
    return (x[0], y[0], z[0], x[1], y[1], z[1], x[2], y[2], z[2])


def rot_axis(axis, deg):
    a = norm(axis)
    t = math.radians(deg)
    c, s, C = math.cos(t), math.sin(t), 1 - math.cos(t)
    x, y, z = a
    return (c + x * x * C, x * y * C - z * s, x * z * C + y * s,
            y * x * C + z * s, c + y * y * C, y * z * C - x * s,
            z * x * C - y * s, z * y * C + x * s, c + z * z * C)


def matmul(a, b):
    return tuple(sum(a[r * 3 + k] * b[k * 3 + c] for k in range(3)) for r in range(3) for c in range(3))


def apply(m, v):
    return (m[0] * v[0] + m[1] * v[1] + m[2] * v[2],
            m[3] * v[0] + m[4] * v[1] + m[5] * v[2],
            m[6] * v[0] + m[7] * v[1] + m[8] * v[2])


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def scale(v, s):
    return tuple(x * s for x in v)


# ----------------------------------------------------------------------------- model

class Balloon:
    def __init__(self, name):
        self.name = name
        self.vox = {}  # (x, y, z) -> palette key
        self.parts = []  # (shape, key, size, pos, rot)
        self.palette = {}
        self.light = None
        self.knot = (0, -5, 0)

    # palette: key -> (hex, material, transparency). Materials: P plastic (studs),
    # S smooth plastic, N neon, G glass.
    def pal(self, **entries):
        for k, v in entries.items():
            if isinstance(v, str):
                v = (v, "P", 0)
            self.palette[k] = v

    # --- voxel brushes
    def fill(self, pred, key, lo=-12, hi=12):
        for x in range(lo, hi + 1):
            for y in range(lo, hi + 1):
                for z in range(lo, hi + 1):
                    if pred(x, y, z):
                        self.vox[(x, y, z)] = key

    def ellipsoid(self, c, r, key, shell=None):
        rx, ry, rz = r if isinstance(r, tuple) else (r, r, r)

        def inside(x, y, z, k=1.0):
            return ((x - c[0]) / (rx * k)) ** 2 + ((y - c[1]) / (ry * k)) ** 2 + ((z - c[2]) / (rz * k)) ** 2 <= 1

        def pred(x, y, z):
            if not inside(x, y, z):
                return False
            if shell is not None:
                inner = 1 - shell / min(rx, ry, rz)
                return not inside(x, y, z, inner)
            return True
        self.fill(pred, key)

    def box(self, x0, x1, y0, y1, z0, z1, key):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                for z in range(z0, z1 + 1):
                    self.vox[(x, y, z)] = key

    def surface(self):
        out = []
        for (x, y, z) in self.vox:
            for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
                if (x + d[0], y + d[1], z + d[2]) not in self.vox:
                    out.append((x, y, z))
                    break
        return out

    def paint(self, pred, key, surface_only=True, only=None):
        cells = self.surface() if surface_only else list(self.vox)
        for p in cells:
            if (only is None or self.vox[p] in only) and pred(*p):
                self.vox[p] = key

    def front(self, x, y):
        """Frontmost (-Z) voxel of column (x, y)."""
        zs = [p[2] for p in self.vox if p[0] == x and p[1] == y]
        return (x, y, min(zs)) if zs else None

    def emblem(self, cells, key, dy=0):
        for (x, y) in cells:
            p = self.front(x, y + dy)
            if p:
                self.vox[p] = key

    def shine(self, key, key2=None, d1=0.93, d2=0.8, light=(-0.45, 0.55, -0.7), c=(0, 0, 0), only=None):
        L = norm(light)
        for p in self.surface():
            if only is not None and self.vox[p] not in only:
                continue
            v = (p[0] - c[0], p[1] - c[1], p[2] - c[2])
            m = math.sqrt(dot(v, v)) or 1
            d = dot(scale(v, 1 / m), L)
            if d > d1:
                self.vox[p] = key
            elif key2 and d > d2:
                self.vox[p] = key2

    # --- explicit parts
    def block(self, key, size, pos, rot=IDENTITY):
        self.parts.append(("B", key, size, pos, rot))

    def wedge(self, key, size, pos, rot=IDENTITY):
        self.parts.append(("W", key, size, pos, rot))

    def roof(self, key, base, direction, length, width, ridge=None):
        """A two-wedge spike: a triangular prism whose ridge points along `direction`."""
        m = basis(direction, ridge)
        mid = add(base, scale(norm(direction), length / 2))
        # wedge 1: default orientation, sits on the -Z half of the local frame
        w = width
        off1 = apply(m, (0, 0, -w / 4))
        self.wedge(key, (w, length, w / 2), add(mid, off1), m)
        # wedge 2: turned 180 degrees about local Y, on the +Z half
        m2 = matmul(m, rot_axis((0, 1, 0), 180))
        off2 = apply(m, (0, 0, w / 4))
        self.wedge(key, (w, length, w / 2), add(mid, off2), m2)

    def knot_at(self, y, key):
        """Knot under the balloon: a collar block and a downward wedge spike."""
        self.block(key, (1.4, 0.6, 1.4), (0, y - 0.3, 0))
        self.roof(key, (0, y - 0.6, 0), (0, -1, 0), 0.9, 1.0)
        self.knot = (0, y - 1.5, 0)

    # --- greedy meshing
    def mesh(self):
        left = dict(self.vox)
        boxes = []
        for p in sorted(left, key=lambda q: (q[1], q[2], q[0])):
            if p not in left:
                continue
            key = left[p]
            x0, y0, z0 = p
            x1 = x0
            while left.get((x1 + 1, y0, z0)) == key:
                x1 += 1
            z1 = z0
            while all(left.get((x, y0, z1 + 1)) == key for x in range(x0, x1 + 1)):
                z1 += 1
            y1 = y0
            while all(left.get((x, y1 + 1, z)) == key for x in range(x0, x1 + 1) for z in range(z0, z1 + 1)):
                y1 += 1
            for x in range(x0, x1 + 1):
                for y in range(y0, y1 + 1):
                    for z in range(z0, z1 + 1):
                        del left[(x, y, z)]
            size = (x1 - x0 + 1, y1 - y0 + 1, z1 - z0 + 1)
            pos = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
            boxes.append(("B", key, size, pos, IDENTITY))
        return boxes

    def all_parts(self):
        return self.mesh() + self.parts


# ----------------------------------------------------------------------------- designs

def sphere_dir(p):
    m = math.sqrt(dot(p, p)) or 1
    return scale(p, 1 / m)


def gumball():
    b = Balloon("Gumball")
    b.pal(red="FF3B3B", redDark="D9232F", pink="FF9A9A", white=("FFFFFF", "S", 0), silver="C9CED6", silverDark="8E96A3")
    b.ellipsoid((0, 0, 0), 4.4, "red")
    b.paint(lambda x, y, z: y <= -3, "redDark")
    b.shine("white", "pink", d1=0.975, d2=0.92)
    # little gumball-machine stand the balloon sits on
    b.box(-1, 1, -5, -5, -1, 1, "silver")
    b.box(-2, 2, -6, -6, -2, 2, "silverDark")
    b.knot_at(-6.5, "redDark")
    return b


def bubble():
    b = Balloon("Bubble")
    b.pal(glass=("9BEBFF", "G", 0.45), glass2=("B8F3FF", "G", 0.35), shine=("FFFFFF", "N", 0.1),
          pinkSheen=("FFC2F3", "G", 0.35), gold=("FFE38A", "G", 0.35), knot="5AC8FA")
    b.ellipsoid((0, 0, 0), 3.9, "glass", shell=1.2)
    for c, r in (((4, 3, -1), 1.5), ((-4, -2, 1), 1.3), ((3, -3, -2), 1.1), ((-3, 4, -1), 1.2)):
        b.ellipsoid(c, r, "glass2")
    b.shine("shine", None, d1=0.96, only={"glass"})
    b.paint(lambda x, y, z: x > 2 and y < 0 and z < 0, "pinkSheen", only={"glass"})
    b.paint(lambda x, y, z: x < -2 and y > 1 and z > 0, "gold", only={"glass"})
    b.knot_at(-4.4, "knot")
    return b


def ember():
    b = Balloon("Ember")
    b.pal(ember="B8350A", emberDark="7A2206", lava=("FF8A1F", "N", 0), flameO=("FF6A00", "N", 0),
          flameY=("FFD21F", "N", 0), cap="5C1A05")
    b.ellipsoid((0, 0, 0), 4.2, "ember")
    b.paint(lambda x, y, z: y <= -3, "emberDark")
    normals = [norm(n) for n in ((1, 0.3, 0.2), (0.2, 1, -0.4), (-0.5, 0.2, 1))]
    b.paint(lambda x, y, z: any(abs(dot(sphere_dir((x, y, z)), n)) < 0.1 for n in normals) and y > -3, "lava")
    # flame tuft on top
    for y, r in ((4, 1.6), (5, 1.3), (6, 0.9), (7, 0.2)):
        b.fill(lambda x, yy, z, y=y, r=r: yy == y and x * x + z * z <= r * r + 0.01 and (x, yy, z) not in b.vox, "flameO")
    b.box(0, 0, 4, 6, 0, 0, "flameY")
    b.box(-1, 1, 4, 4, -1, 1, "cap")
    b.box(0, 0, 4, 7, 0, 0, "flameY")
    b.light = ("FF8A1F", 1.6, 16)
    b.knot_at(-4.6, "emberDark")
    return b


def spike():
    b = Balloon("Spike")
    b.pal(green="6CCB2F", greenDark="3E8E1C", greenLight="A8F07A", spike=("E9FFD8", "S", 0))
    b.ellipsoid((0, 0, 0), 3.7, "green")
    b.paint(lambda x, y, z: y <= -3, "greenDark")
    b.shine("greenLight", None, d1=0.85)
    dirs = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, 0, 1), (0, 0, -1),
            (1, 1, 1), (-1, 1, 1), (1, 1, -1), (-1, 1, -1),
            (1, 0, 1), (-1, 0, 1), (1, 0, -1), (-1, 0, -1),
            (1, -0.6, 0), (-1, -0.6, 0)]
    for d in dirs:
        n = norm(d)
        b.roof("spike", scale(n, 3.2), n, 2.8, 1.4)
    b.knot_at(-4.1, "greenDark")
    return b


def popcorn():
    b = Balloon("Popcorn")
    b.pal(red="E0282E", white="FFF8EE", rim=("FFFFFF", "S", 0), kernel="FFF1C9", butter="FFD66B",
          kernelW="FFFFFF", gold="FFC21A")

    def hw(y):
        return 2 if y <= -2 else 3

    for y in range(-4, 3):
        h = hw(y)
        for x in range(-h, h + 1):
            for z in range(-h, h + 1):
                edge_x = abs(x) == h
                edge_z = abs(z) == h
                red = (edge_z and x % 2 == 0) or (edge_x and z % 2 == 0)
                b.vox[(x, y, z)] = "red" if red else "white"
    # rim band
    for x in range(-3, 4):
        for z in range(-3, 4):
            if abs(x) == 3 or abs(z) == 3:
                b.vox[(x, 3, z)] = "rim"
    # kernel heap
    heap = {3: 2.9, 4: 3.1, 5: 2.5, 6: 1.6, 7: 0.5}
    for y, r in heap.items():
        for x in range(-3, 4):
            for z in range(-3, 4):
                if x * x + z * z <= r * r + 0.3 and (x, y, z) not in b.vox:
                    b.vox[(x, y, z)] = "kernel"
    b.paint(lambda x, y, z: y >= 4 and (x * 7 + y * 3 + z * 5) % 5 == 0, "butter", only={"kernel"})
    b.paint(lambda x, y, z: y >= 4 and (x * 3 + y * 11 + z * 7) % 7 == 1, "kernelW", only={"kernel"})
    # a few kernels tumbling off the top
    for p in ((2.6, 7.6, -1.4), (-2.4, 7.2, 1.2), (0.6, 8.6, 0.8)):
        b.block("butter", (0.8, 0.8, 0.8), p, rot_axis((1, 1, 0), 30))
    b.block("gold", (2.2, 1.2, 0.2), (0, -1, -3.55))  # little label plate
    b.knot_at(-4.5, "red")
    return b


def jelly():
    b = Balloon("Jelly")
    b.pal(dome=("5AC8FA", "G", 0.3), core=("9FE7FF", "N", 0.2), rim=("3FA9FF", "N", 0), spot=("FF8AE6", "G", 0.2),
          tent=("7FD8FF", "N", 0.1), tent2=("5AC8FA", "G", 0.2), arm=("FFB8F1", "G", 0.25))
    b.fill(lambda x, y, z: y >= 0 and x * x + (y * 1.15) ** 2 + z * z <= 4.4 ** 2
           and not (y >= 1 and x * x + (y * 1.15) ** 2 + z * z <= 3.3 ** 2), "dome")
    b.fill(lambda x, y, z: y == 0 and 3.2 ** 2 <= x * x + z * z <= 4.4 ** 2, "rim")
    b.ellipsoid((0, 1, 0), 1.6, "core")
    b.paint(lambda x, y, z: y >= 2 and (x * 5 + z * 3 + y) % 6 == 0, "spot", only={"dome"})
    for i in range(8):
        a = i / 8 * 2 * math.pi
        r = 3.1
        for k in range(5):
            sway = math.sin(k * 1.1 + i) * 0.45
            p = (math.cos(a) * (r + sway), -0.9 - k * 1.15, math.sin(a) * (r + sway))
            b.block("tent" if (i + k) % 2 == 0 else "tent2", (0.55, 1.2, 0.55), p)
    for i in range(4):
        a = i / 4 * 2 * math.pi + 0.4
        for k in range(3):
            p = (math.cos(a) * 1.2, -1.0 - k * 1.1, math.sin(a) * 1.2)
            b.block("arm", (0.9, 1.1, 0.9), p, rot_axis((0, 1, 0), 45 + k * 20))
    b.light = ("7FD8FF", 1.2, 14)
    b.knot = (0, -0.8, 0)
    return b


def buzz():
    b = Balloon("Buzz")
    b.pal(yellow="FFD21F", black="2A2A2A", eye=("141414", "S", 0), shine=("FFFFFF", "S", 0), cheek="FF9AB8",
          wing=("F4FBFF", "G", 0.4), tip=("FFD21F", "N", 0))
    b.ellipsoid((0, 0, 0), (3.5, 3.9, 3.5), "yellow")
    b.paint(lambda x, y, z: y in (0, -2), "black", surface_only=False)
    for x in (-1, 1):
        p = b.front(x, 2)
        if p:
            b.vox[p] = "eye"
        p = b.front(x, 3)
        if p:
            b.vox[p] = "shine"
    for x in (-2, 2):
        p = b.front(x, 1)
        if p:
            b.vox[p] = "cheek"
    for s in (-1, 1):
        b.block("wing", (0.2, 3.4, 2.4), (s * 2.3, 4.3, 0.9), rot_axis((0, 0, 1), -s * 32))
        b.block("black", (0.3, 2.4, 0.3), (s * 1.0, 4.7, -1.5), matmul(rot_axis((0, 0, 1), -s * 22), rot_axis((1, 0, 0), -18)))
        b.block("tip", (0.7, 0.7, 0.7), (s * 1.5, 5.9, -1.9))
    b.roof("black", (0, -1, 3.6), (0, 0, 1), 1.6, 1.0)
    b.knot_at(-4.3, "black")
    return b


def frost():
    b = Balloon("Frost")
    b.pal(ice="6FCBFF", iceDark="3A9FE0", iceLight="B8EAFF", snow=("FFFFFF", "N", 0), icicle=("C8F4FF", "G", 0.2),
          crystal=("DDF6FF", "N", 0.1))
    b.ellipsoid((0, 0, 0), 4.3, "ice")
    b.paint(lambda x, y, z: y <= -3, "iceDark")
    b.shine("iceLight", None, d1=0.96)
    # snowflake emblem: three crossing Neon bars with little branches, just proud of the surface
    c = (0, 0.6, -4.55)
    for k in range(3):
        m = rot_axis((0, 0, 1), k * 60)
        b.block("snow", (0.45, 5.4, 0.3), c, m)
        for end in (1, -1):
            tip = add(c, apply(m, (0, end * 1.8, 0)))
            for side in (1, -1):
                bm = matmul(m, rot_axis((0, 0, 1), side * end * 45))
                b.block("snow", (0.35, 1.2, 0.3), add(tip, apply(bm, (0, end * 0.45, 0))), bm)
    for i in range(7):
        a = i / 7 * 2 * math.pi
        x, z = math.cos(a) * 2.6, math.sin(a) * 2.6
        long = 2.2 if i % 2 == 0 else 1.5
        b.block("icicle", (0.8, long, 0.8), (x, -3.2 - long / 2, z))
        b.block("icicle", (0.45, 1.0, 0.45), (x, -3.2 - long - 0.5, z))
    for p, a in (((0, 5.2, 0), 0), ((1.6, 4.7, 0.4), 25), ((-1.5, 4.8, -0.3), -20)):
        b.block("crystal", (0.9, 1.6, 0.9), p, matmul(rot_axis((0, 0, 1), a), rot_axis((0, 1, 0), 45)))
    b.light = ("A5E4FF", 0.8, 12)
    b.knot_at(-4.6, "iceDark")
    return b


def volt():
    b = Balloon("Volt")
    b.pal(blue="1F6BFF", blueDark="1440B8", blueLight="7FB2FF", bolt=("FFD21F", "N", 0), spark=("FFF3A0", "N", 0))
    b.ellipsoid((0, 0, 0), 4.3, "blue")
    b.paint(lambda x, y, z: y <= -3, "blueDark")
    b.shine("blueLight", None, d1=0.96)
    bolt = [(1, 4), (2, 4), (0, 3), (1, 3), (-1, 2), (0, 2), (-2, 1), (-1, 1), (0, 1), (1, 1), (2, 1),
            (0, 0), (1, 0), (-1, -1), (0, -1), (-2, -2), (-1, -2), (-2, -3)]
    b.emblem(bolt, "bolt")
    for base, d in (((0, 4.4, 0), (0, 1, 0)), ((3.3, 3, 0.5), (1, 1, 0)), ((-3.2, 2.6, -0.6), (-1, 1, 0.2))):
        n = norm(d)
        side = norm(cross(n, (0, 0, 1))) if abs(n[2]) < 0.9 else (1, 0, 0)
        p = base
        for k in range(3):
            p = add(p, add(scale(n, 0.7), scale(side, 0.45 if k % 2 == 0 else -0.45)))
            b.block("spark", (0.45, 0.9, 0.45), p, basis(add(n, scale(side, 0.6 if k % 2 == 0 else -0.6))))
    b.light = ("FFD21F", 1.0, 12)
    b.knot_at(-4.6, "blueDark")
    return b


def thorn():
    b = Balloon("Thorn")
    b.pal(thorn="2E7D32", vine="1B5E20", tip="8A5A2E", rose="D6204A", roseDark="A3122F", leaf="43A047")
    b.ellipsoid((0, 0, 0), 3.9, "thorn")
    normals = [norm(n) for n in ((1, 0.4, 0.3), (-0.3, 0.5, 1))]
    b.paint(lambda x, y, z: any(abs(dot(sphere_dir((x, y, z)), n)) < 0.12 for n in normals), "vine")
    for d in ((1, 0.2, -0.6), (-1, 0.3, -0.5), (0.6, 0.7, 0.8), (-0.7, 0.6, 0.9), (0.2, 0.3, -1),
              (1, -0.4, 0.4), (-1, -0.3, 0.2), (0.3, 1, -0.3), (-0.4, -0.5, -1), (0.8, -0.5, -0.9)):
        n = norm(d)
        b.roof("tip", scale(n, 3.4), n, 1.8, 0.9)
    b.box(-1, 1, 4, 4, -1, 1, "rose")
    b.box(-1, 1, 5, 5, -1, 1, "roseDark")
    b.box(0, 0, 5, 6, 0, 0, "rose")
    b.box(-2, -2, 4, 4, 0, 0, "roseDark")
    b.box(2, 2, 4, 4, 0, 0, "roseDark")
    for s in (-1, 1):
        b.block("leaf", (2.2, 0.3, 1.2), (s * 1.9, 3.8, 0.8), rot_axis((0, 0, 1), s * 20))
    b.knot_at(-4.4, "vine")
    return b


def clock():
    b = Balloon("Clock")
    b.pal(gold="FFC21A", goldDark="D99A00", glass=("DDF6FF", "G", 0.45), sand="E8C27A", sandDark="C99A4A",
          face=("FFFFFF", "S", 0), hand=("2A2A2A", "S", 0))
    b.box(-3, 3, 5, 5, -3, 3, "gold")
    b.box(-2, 2, 6, 6, -2, 2, "goldDark")
    b.box(0, 0, 7, 7, 0, 0, "gold")
    b.box(-3, 3, -5, -5, -3, 3, "gold")
    b.box(-2, 2, -6, -6, -2, 2, "goldDark")
    for x in (-3, 3):
        for z in (-3, 3):
            b.box(x, x, -4, 4, z, z, "goldDark")
    widths = {4: 2, 3: 2, 2: 1, 1: 1, 0: 0, -1: 1, -2: 1, -3: 2, -4: 2}
    for y, h in widths.items():
        for x in range(-h, h + 1):
            for z in range(-h, h + 1):
                b.vox[(x, y, z)] = "glass"
    b.box(-2, 2, -4, -4, -2, 2, "sand")
    b.box(-1, 1, -3, -3, -1, 1, "sandDark")
    b.box(0, 0, -2, 2, 0, 0, "sand")
    b.box(-1, 1, 3, 3, -1, 1, "sand")
    # clock face on the front of the top plate
    b.block("face", (2.6, 2.6, 0.2), (0, 5, -3.6))
    b.block("hand", (0.25, 1.1, 0.1), (0, 5.45, -3.75))
    b.block("hand", (0.8, 0.25, 0.1), (0.35, 5, -3.75))
    b.knot_at(-6.5, "goldDark")
    return b


def flame():
    b = Balloon("Flame")
    b.pal(red="E0301E", orange="FF6A00", amber=("FF9A1F", "N", 0), yellow=("FFD21F", "N", 0),
          core=("FFF3A0", "N", 0), dark="8A1A0A")
    prof = {-4: 1.8, -3: 3.0, -2: 3.6, -1: 3.9, 0: 3.9, 1: 3.6, 2: 3.2, 3: 2.7, 4: 2.2, 5: 1.6, 6: 1.1, 7: 0.6}
    for y, r in prof.items():
        shift = round(math.sin(y * 0.8) * 0.8) if y >= 2 else 0
        key = "red" if y <= -2 else "orange" if y <= 1 else "amber" if y <= 4 else "yellow"
        for x in range(-5, 6):
            for z in range(-5, 6):
                if (x - shift) ** 2 + z * z <= r * r + 0.2:
                    b.vox[(x, y, z)] = key
    b.paint(lambda x, y, z: y == -4, "dark")
    # hot core window on the front
    b.emblem([(-1, -2), (0, -2), (1, -2), (-1, -1), (0, -1), (1, -1), (0, 0), (1, 0), (0, 1)], "core")
    for p, s in (((3.6, 3.5, 0.5), 1.0), ((-3.4, 2.4, -0.4), 0.9), ((2.2, 6.4, -0.6), 0.7), ((-1.8, 7.2, 0.4), 0.6)):
        b.block("yellow", (s, s * 1.6, s), p, rot_axis((0, 0, 1), 15 if p[0] < 0 else -15))
    b.light = ("FF8A1F", 2.2, 20)
    b.knot_at(-4.6, "dark")
    return b


def whale():
    b = Balloon("Whale")
    b.pal(whale="2C5FD9", whaleDark="1E3F9E", belly="D8E6FF", groove="B9CFF5", eyeW=("FFFFFF", "S", 0),
          eyeB=("141414", "S", 0), mouth="1E3A8A", spout=("8FE9FF", "N", 0.2))
    b.ellipsoid((0, 0, 0), (3.3, 2.9, 5.6), "whale")
    b.paint(lambda x, y, z: y <= -1 and z < 4, "belly", surface_only=False)
    b.paint(lambda x, y, z: y <= -2 and x % 2 == 0 and z < 4, "groove")
    for x in range(-2, 3):
        p = b.front(x, -1)
        if p:
            b.vox[p] = "mouth"
    # tail stock and flukes
    for z, r in ((6, 1.6), (7, 1.1), (8, 0.7)):
        for x in range(-2, 3):
            for y in range(-2, 3):
                if x * x + (y - 0.5) ** 2 <= r * r:
                    b.vox[(x, y, z)] = "whale"
    b.box(-3, 3, 1, 1, 9, 9, "whaleDark")
    b.box(-4, -1, 1, 1, 10, 10, "whaleDark")
    b.box(1, 4, 1, 1, 10, 10, "whaleDark")
    b.paint(lambda x, y, z: y >= 2, "whaleDark", only={"whale"})
    for s in (-1, 1):
        b.block("eyeW", (0.3, 1.2, 1.2), (s * 3.3, 0.2, -3.2))
        b.block("eyeB", (0.3, 0.7, 0.7), (s * 3.45, 0.1, -3.4))
        b.wedge("whaleDark", (0.4, 1.4, 2.8), (s * 3.6, -1.4, -0.6), matmul(rot_axis((0, 0, 1), s * 35), rot_axis((0, 1, 0), 180)))
    for k, p in enumerate(((0, 3.4, -2.6), (0, 4.3, -2.6), (-0.6, 5.0, -2.6), (0.6, 5.0, -2.6), (-1.1, 5.5, -2.6), (1.1, 5.5, -2.6))):
        b.block("spout", (0.6, 0.8, 0.6), p)
    b.knot_at(-3.6, "whaleDark")
    return b


def iron():
    b = Balloon("Iron")
    b.pal(iron="7A808A", ironDark="5A606A", ironLight="A5ABB5", bolt="3A3F47", hot=("FF6A1F", "N", 0))
    b.box(-2, 2, 2, 2, -5, 4, "iron")
    b.box(-2, 2, 3, 3, -5, 4, "ironLight")
    b.box(-1, 1, 2, 3, -7, -6, "iron")
    b.box(0, 0, 2, 3, -8, -8, "iron")
    b.box(-1, 1, -1, 1, -2, 2, "ironDark")
    b.box(-2, 2, 1, 1, -3, 3, "ironDark")
    b.box(-3, 3, -3, -2, -4, 4, "ironDark")
    b.box(-3, 3, -3, -3, -4, 4, "iron")
    b.box(0, 0, 3, 3, 2, 2, "bolt")
    b.wedge("iron", (1, 2, 1.6), (0, 2.5, -9.3), rot_axis((0, 1, 0), 180))
    for x in (-3.55, 3.55):
        for z in (-3, 3):
            b.block("bolt", (0.3, 0.6, 0.6), (x, -2.5, z))
    b.block("hot", (0.4, 0.2, 3.5), (0, 3.6, -2))  # a glowing hammer mark
    b.knot_at(-3.5, "bolt")
    return b


def void():
    b = Balloon("Void")
    b.pal(void="120E1A", voidDark="0A070F", eye=("B266FF", "N", 0), fleck=("6A2BD9", "N", 0.2), ring=("8A3FFF", "N", 0))
    b.ellipsoid((0, 0, 0), 4.3, "void")
    b.paint(lambda x, y, z: y <= -3, "voidDark")
    b.paint(lambda x, y, z: (x * 7 + y * 13 + z * 5) % 11 == 0, "fleck")
    b.emblem([(0, -1), (0, 0), (0, 1), (0, 2)], "eye")
    tilt = rot_axis((1, 0, 0), 22)
    for i in range(20):
        a = i / 20 * 2 * math.pi
        p = apply(tilt, (math.cos(a) * 6.2, 0, math.sin(a) * 6.2))
        b.block("ring" if i % 2 == 0 else "fleck", (0.8, 0.8, 0.8), p, matmul(tilt, rot_axis((0, 1, 0), -math.degrees(a))))
    b.light = ("8A3FFF", 1.4, 16)
    b.knot_at(-4.6, "voidDark")
    return b


def sun():
    b = Balloon("Sun")
    b.pal(sun="FFC21A", sunDark="F29A00", sunLight="FFE36B", ray="FFB000", rayLight="FFD84A", core=("FFF3A0", "N", 0.1))
    b.ellipsoid((0, 0, 0), 3.8, "sun")
    b.paint(lambda x, y, z: y <= -2, "sunDark")
    b.shine("sunLight", None, d1=0.85)
    b.emblem([(x, y) for x in (-1, 0, 1) for y in (-1, 0, 1)], "core", dy=1)
    for k in range(12):
        a = math.radians(k * 30)
        d = (math.cos(a), math.sin(a), 0)
        if d[1] < -0.95:
            continue
        b.roof("ray" if k % 2 == 0 else "rayLight", scale(d, 3.4), d, 2.8 if k % 2 == 0 else 2.0, 1.6, ridge=(0, 0, 1))
    b.light = ("FFC21A", 1.8, 18)
    b.knot_at(-4.2, "sunDark")
    return b


def crown():
    b = Balloon("Crown")
    b.pal(gold="FFC21A", goldDark="D99A00", velvet="7A1FB8", pearl=("FFFFFF", "N", 0.1),
          ruby=("D6204A", "N", 0), sapphire=("1F6BFF", "N", 0), emerald=("2EBE5A", "N", 0))
    b.fill(lambda x, y, z: -2 <= y <= 1 and 3.0 ** 2 <= x * x + z * z <= 4.4 ** 2, "gold")
    b.fill(lambda x, y, z: y == -3 and 2.6 ** 2 <= x * x + z * z <= 4.7 ** 2, "goldDark")
    b.fill(lambda x, y, z: -2 <= y <= 3 and x * x + z * z < 3.0 ** 2 and x * x + z * z + (y + 1) ** 2 <= 4.3 ** 2, "velvet")
    for k in range(8):
        a = k / 8 * 2 * math.pi
        x, z = round(math.cos(a) * 3.7), round(math.sin(a) * 3.7)
        b.box(x, x, 2, 3, z, z, "gold")
        b.block("pearl", (0.8, 0.8, 0.8), (x, 4.1, z), rot_axis((1, 0, 1), 45))
    gems = (("ruby", 0), ("sapphire", 1), ("emerald", 2), ("ruby", 3), ("sapphire", 4), ("emerald", 5))
    for key, k in gems:
        a = -math.pi / 2 + (k - 2.5) * 0.55
        p = (math.cos(a) * 4.5, -0.5, math.sin(a) * 4.5)
        b.block(key, (0.9, 1.3, 0.3), p, basis((0, 1, 0), (-math.sin(a), 0, math.cos(a))))
    b.block("ruby", (1.1, 1.1, 1.1), (0, 5.0, 0), rot_axis((1, 0, 1), 45))
    b.knot_at(-3.5, "goldDark")
    return b


def cluck():
    b = Balloon("Cluck")
    b.pal(white="FFFFFF", shade="E4E6EA", red="D6204A", beak="FFA51F", eye=("141414", "S", 0), leg="FF9A1F")
    b.box(-2, 2, -2, 2, -2, 3, "white")
    for c in ((-2, -2, -2), (2, -2, -2), (-2, -2, 3), (2, -2, 3), (-2, 2, 3), (2, 2, 3)):
        b.vox.pop(c, None)
    b.box(-1, 1, 3, 6, -3, -1, "white")
    b.box(-1, 1, 1, 3, 4, 4, "white")
    b.box(-1, 1, 4, 4, 4, 4, "shade")
    b.box(0, 0, 5, 5, 4, 4, "shade")
    b.box(0, 0, 7, 7, -3, -1, "red")
    b.box(0, 0, 8, 8, -2, -2, "red")
    b.box(0, 0, 3, 3, -4, -4, "red")
    b.paint(lambda x, y, z: y <= -2, "shade")
    b.roof("beak", (0, 4.6, -3.5), (0, 0, -1), 1.4, 1.0)
    for s in (-1, 1):
        b.block("eye", (0.2, 0.7, 0.7), (s * 1.6, 5.2, -2.2))
        b.block("shade", (0.6, 3.0, 4.0), (s * 2.8, 0.2, 0.5), rot_axis((0, 0, 1), s * 10))
        b.block("leg", (0.4, 1.8, 0.4), (s * 1.0, -3.4, 0.5))
        b.block("leg", (1.3, 0.3, 1.6), (s * 1.0, -4.4, 0.1))
    b.knot = (0, -2.6, 1.5)
    b.block("shade", (1.2, 0.5, 1.2), (0, -2.8, 1.5))
    return b


DESIGNS = [gumball, bubble, ember, spike, popcorn, jelly, buzz, frost, volt, thorn,
           clock, flame, whale, iron, void, sun, crown, cluck]


# ----------------------------------------------------------------------------- export

def fmt(n):
    s = f"{n:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def export(balloons):
    lines = [
        "--!nocheck",
        "-- GENERATED by tools/balloons/build_balloons.py - do not edit by hand.",
        "-- Each part: { shape (\"B\" block | \"W\" wedge), paletteKey, sx, sy, sz, x, y, z [, r00..r22] }",
        "-- Palette: key = { hex, material (P plastic, S smooth, N neon, G glass), transparency }",
        "",
        "local BalloonModels: { [string]: any } = {}",
        "",
    ]
    for b in balloons:
        parts = b.all_parts()
        lines.append(f"BalloonModels.{b.name} = {{")
        lines.append("\tPalette = {")
        for k, (hexv, mat, tr) in b.palette.items():
            lines.append(f"\t\t{k} = {{ \"{hexv}\", \"{mat}\", {fmt(tr)} }},")
        lines.append("\t},")
        lines.append(f"\tKnot = {{ {', '.join(fmt(c) for c in b.knot)} }},")
        if b.light:
            lines.append(f"\tLight = {{ \"{b.light[0]}\", {fmt(b.light[1])}, {fmt(b.light[2])} }},")
        lines.append("\tParts = {")
        for shape, key, size, pos, rot in parts:
            nums = list(size) + list(pos)
            if rot != IDENTITY:
                nums += list(rot)
            lines.append(f"\t\t{{ \"{shape}\", \"{key}\", {', '.join(fmt(n) for n in nums)} }},")
        lines.append("\t},")
        lines.append("}")
        lines.append("")
    lines.append("return BalloonModels")
    os.makedirs(os.path.dirname(OUT_LUA), exist_ok=True)
    with open(OUT_LUA, "w") as f:
        f.write("\n".join(lines) + "\n")


# ----------------------------------------------------------------------------- preview

def corners(shape, size, pos, rot):
    sx, sy, sz = (s / 2 for s in size)
    if shape == "B":
        local = [(x, y, z) for x in (-sx, sx) for y in (-sy, sy) for z in (-sz, sz)]
        faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    else:
        # wedge: bottom face, vertical back face at +Z, slope from bottom-front to top-back
        local = [(-sx, -sy, -sz), (sx, -sy, -sz), (-sx, -sy, sz), (sx, -sy, sz), (-sx, sy, sz), (sx, sy, sz)]
        faces = [(0, 2, 3, 1), (2, 4, 5, 3), (0, 1, 5, 4), (0, 4, 2), (1, 3, 5)]
    world = [add(pos, apply(rot, v)) for v in local]
    return world, faces


def render(balloon, size_px=360):
    import numpy as np
    from PIL import Image

    yaw, pitch = math.radians(-30), math.radians(-18)
    cy, sy_ = math.cos(yaw), math.sin(yaw)
    cp, sp = math.cos(pitch), math.sin(pitch)

    def view(v):
        x, y, z = v
        x, z = x * cy + z * sy_, -x * sy_ + z * cy
        y, z = y * cp - z * sp, y * sp + z * cp
        return (x, y, z)

    tris = []
    for shape, key, size, pos, rot in balloon.all_parts():
        hexv, mat, tr = balloon.palette[key]
        col = np.array([int(hexv[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)
        world, faces = corners(shape, size, pos, rot)
        vw = [view(v) for v in world]
        for f in faces:
            pts = [vw[i] for i in f]
            n = norm(cross(tuple(pts[1][k] - pts[0][k] for k in range(3)), tuple(pts[2][k] - pts[0][k] for k in range(3))))
            for i in range(1, len(pts) - 1):
                tris.append((pts[0], pts[i], pts[i + 1], n, col, mat, tr))
    xs = [p[0] for t in tris for p in t[:3]]
    ys = [p[1] for t in tris for p in t[:3]]
    span = max(max(xs) - min(xs), max(ys) - min(ys)) * 1.12
    cx, cyv = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    k = size_px / span
    W = H = size_px
    img = np.zeros((H, W, 3))
    img[:] = (22, 28, 52)
    zb = np.full((H, W), np.inf)
    light = norm((-0.5, 0.8, -0.6))
    for a, b_, c, n, col, mat, tr in tris:
        # faces pointing away from the camera (+z is away) are hidden
        if n[2] > 0.02:
            n = (-n[0], -n[1], -n[2])
        shade = 0.42 + 0.58 * max(0.0, dot(n, light))
        if mat == "N":
            shade = 1.0
        rgb = col * shade
        if mat == "G":
            rgb = rgb * 0.7 + 255 * 0.3 * (1 - tr)
        P = [((p[0] - cx) * k + W / 2, (cyv - p[1]) * k + H / 2, p[2]) for p in (a, b_, c)]
        minx, maxx = int(max(0, math.floor(min(p[0] for p in P)))), int(min(W - 1, math.ceil(max(p[0] for p in P))))
        miny, maxy = int(max(0, math.floor(min(p[1] for p in P)))), int(min(H - 1, math.ceil(max(p[1] for p in P))))
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
    return Image.fromarray(np.clip(img, 0, 255).astype("uint8"))


def preview(balloons):
    from PIL import Image, ImageDraw
    os.makedirs(OUT_PREVIEW, exist_ok=True)
    tiles = []
    for b in balloons:
        im = render(b)
        im.save(os.path.join(OUT_PREVIEW, f"{b.name}.png"))
        tiles.append((b.name, im, len(b.all_parts())))
    cols = 6
    rows = math.ceil(len(tiles) / cols)
    t = 300
    sheet = Image.new("RGB", (cols * t, rows * (t + 34)), (14, 18, 36))
    d = ImageDraw.Draw(sheet)
    for i, (name, im, n) in enumerate(tiles):
        x, y = (i % cols) * t, (i // cols) * (t + 34)
        sheet.paste(im.resize((t, t)), (x, y))
        d.text((x + 12, y + t + 8), f"{name}  ({n} parts)", fill=(235, 238, 255))
    sheet.save(os.path.join(OUT_PREVIEW, "lineup.png"))


def main():
    balloons = [f() for f in DESIGNS]
    export(balloons)
    for b in balloons:
        print(f"{b.name:8s} {len(b.all_parts()):4d} parts")
    if "--preview" in sys.argv:
        preview(balloons)
        print("previews ->", os.path.relpath(OUT_PREVIEW, ROOT))


if __name__ == "__main__":
    main()
