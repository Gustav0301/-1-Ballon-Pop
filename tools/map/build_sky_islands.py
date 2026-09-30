#!/usr/bin/env python3
"""Sky islands for Meadow Sky and Cloud Shelf (Phase 1), in the style of
docs/reference/sky-islands.webp. Writes build/SkyIslands.rbxmx (static stud Parts)
and src/shared/Config/IslandConfig.lua (names, zones, landing pads) for FlightService.

    python3 tools/map/build_sky_islands.py            # write rbxmx + IslandConfig
    python3 tools/map/build_sky_islands.py --preview  # also render docs/map/islands*.png

Placement rules (see docs/MAP.md): never above the launch plaza, one island per map
corner ~90 studs out so a straight rise plus a short steer reaches it, no two islands
overlapping in XZ, and heights chosen by which balloon can reach them
(Gumball max ~630 studs reaches the first Cloud Shelf island at 560).
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_start_map as M  # noqa: E402  (stud toolkit: frames, boxes, props, export, render)

BB = M.BB
C = M.C
ROOT = M.ROOT
OUT = os.path.join(ROOT, "build", "SkyIslands.rbxmx")
CONFIG = os.path.join(ROOT, "src", "shared", "Config", "IslandConfig.lua")

rng = random.Random(7)
M.rng = rng
M.S = M.Scene()
S = M.S
T = M.T
span, box, voxels = M.span, M.box, M.voxels

ISLANDS = [
    # name, zone, top centre (x, y, z), radius, style
    ("MeadowRest", "MeadowSky", (-70, 150, -56), 30, "meadow"),
    ("WindmillHill", "MeadowSky", (72, 350, -48), 32, "windmill"),
    ("RainbowShelf", "CloudShelf", (-66, 560, 62), 34, "rainbow"),
    ("SummitCloud", "CloudShelf", (70, 1100, 62), 36, "summit"),
]


# ----------------------------------------------------------------------------- bodies

def disc(g, t, color, r, y0, y1, step=2.0, jag=0.0):
    for x0, x1, z0, z1 in M.ring_rows(r, 0, step):
        e = rng.uniform(0, jag) if jag else 0
        span(g, t, color, x0 - e, x1 + e, y0, y1, z0, z1)


def grass_body(g, t, r):
    """Grass top, dirt band and a stepped, jagged rock cone underneath (top at local y=0)."""
    disc(g, t, C["grass"], r, -1, 0)
    disc(g, t, C["dirt"], r - 0.5, -3, -1)
    levels = 7
    y = -3
    for k in range(levels):
        rk = r * (1 - (k + 1) / (levels + 1)) ** 0.75
        h = 3 + k * 0.6
        col = C["stone"] if k % 2 == 0 else C["stoneDark"]
        disc(g, t, col, rk, y - h, y, step=4, jag=2.5)
        y -= h
    box(g, t, C["stoneDark"], (3, 5, 3), (rng.uniform(-2, 2), y - 2.5, rng.uniform(-2, 2)))


def cloud_body(g, t, r):
    """White stud cloud island: grass top ringed by puffy cloud blocks, cloud underside."""
    disc(g, t, C["grass"], r - 5, -1, 0)
    disc(g, t, "FFFFFF", r, -4, -1)
    y = -4
    for k in range(5):
        rk = r * (1 - (k + 1) / 6.5)
        disc(g, t, "F2F6FF" if k % 2 == 0 else "E2EAF8", rk, y - 3, y, step=4, jag=3)
        y -= 3
    # puffy cloud rim sticking up around the grass
    for i in range(14):
        a = i / 14 * 2 * math.pi + rng.uniform(-0.1, 0.1)
        rr = r - rng.uniform(1.5, 3.5)
        w = rng.uniform(5, 8)
        box(g, t, "FFFFFF", (w, rng.uniform(2, 4), w), (math.cos(a) * rr, rng.uniform(0, 1), math.sin(a) * rr))


def landing_pad(g, t, pos, name):
    """A gold coin pad (the landing spot) plus an invisible 'LandingPad' part FlightService reads."""
    coin = {}
    for i in range(-6, 7):
        for j in range(-6, 7):
            rr = math.hypot(i, j)
            if rr <= 6.3:
                col = C["goldDark"] if rr > 5.2 else C["gold"]
                u = i * math.cos(0.26) - j * math.sin(0.26)
                v = i * math.sin(0.26) + j * math.cos(0.26)
                if 1.8 <= max(abs(u), abs(v)) <= 2.8:
                    col = C["goldDark"]
                coin[(i, 0, j)] = col
    voxels(g, t, coin, unit=1.0, offset=BB.add(pos, (0, 0.2, 0)))
    S.add(g, "B", "FFFFFF", (13, 1, 13), t.p(BB.add(pos, (0, 1.2, 0))), I, "S", 1.0, False, "LandingPad")
    for a in (45, 135, 225, 315):
        x, z = math.cos(math.radians(a)) * 7.5, math.sin(math.radians(a)) * 7.5
        box(g, t, C["woodDark"], (0.6, 3, 0.6), BB.add(pos, (x, 1.5, z)))
        box(g, t, C["lantern"], (0.9, 0.9, 0.9), BB.add(pos, (x, 3.4, z)), mat="N", collide=False)
    M.light(g, t, BB.add(pos, (0, 4, 0)), color="FFE08A", brightness=1.2, rng_=20)


I = BB.IDENTITY


def waterfall(g, t, pos, outward, length=60):
    """A pond on the rim spilling over the edge."""
    ox, oz = outward
    ang = math.degrees(math.atan2(ox, oz))
    ft = t.at(pos, M.yaw(ang))
    span(g, ft, C["water"], -3, 3, -0.8, -0.2, -3, 2, tr=0.1)
    span(g, ft, C["stone"], -4, 4, -1, 0.4, 2, 3)
    span(g, ft, C["waterLight"], -2.5, 2.5, -length, -0.2, 3, 4.2, tr=0.25)
    for k in range(4):
        box(g, ft, "FFFFFF", (1.2, 1.2, 1.2), (rng.uniform(-2, 2), -length * (0.3 + 0.2 * k), 4.6), mat="S", collide=False)


def island_sign(g, t, pos, text, color):
    st = t.at(pos, M.yaw(180))
    box(g, st, C["woodDark"], (0.8, 5, 0.8), (-4.5, 2.5, 0))
    box(g, st, C["woodDark"], (0.8, 5, 0.8), (4.5, 2.5, 0))
    box(g, st, C["woodLight"], (11, 3.2, 0.5), (0, 4.4, 0))
    M.text(g, st, text, (0, 4.4, -0.35), 0.5, color)


# ----------------------------------------------------------------------------- islands

def meadow_rest(t, r):
    g = "MeadowRest"
    grass_body(g, t, r)
    landing_pad(g, t, (0, 0, 4), g)
    for x, z in ((-14, -12), (13, -14), (-18, 10)):
        M.tree(g, *t.p((x, 0, z))[::2], y=t.pos[1], h=5, big=0.9)
    M.pine(g, *t.p((17, 0, 12))[::2], y=t.pos[1], s=1.0)
    for _ in range(26):
        a, rr = rng.uniform(0, 2 * math.pi), rng.uniform(8, r - 4)
        x, z = math.cos(a) * rr, math.sin(a) * rr
        if math.hypot(x, z - 4) > 9:
            M.flower(g, *t.p((x, 0, z))[::2], y=t.pos[1])
    # bench + lamp
    bt = t.at((-6, 0, -18), M.yaw(10))
    box(g, bt, C["wood"], (6, 0.5, 1.6), (0, 1.4, 0))
    box(g, bt, C["wood"], (6, 1.6, 0.4), (0, 2.4, 0.7))
    for sx in (-2.6, 2.6):
        box(g, bt, C["woodDark"], (0.5, 1.4, 1.4), (sx, 0.7, 0))
    M.lamp(g, *t.p((8, 0, -18))[::2], y=t.pos[1])
    waterfall(g, t, (0, 0, -r + 3), (0, -1), length=45)
    island_sign(g, t, (0, 0, 16), "MEADOW", C["woodDark"])


def windmill_hill(t, r):
    g = "WindmillHill"
    grass_body(g, t, r)
    landing_pad(g, t, (-8, 0, 8), g)
    # windmill
    wt = t.at((10, 0, -10))
    for k, w in enumerate((8, 7, 6, 5)):
        span(g, wt, "F4E3C1" if k % 2 == 0 else "E8D4A8", -w / 2, w / 2, k * 4, k * 4 + 4, -w / 2, w / 2)
    span(g, wt, C["woodDark"], -1.2, 1.2, 0, 3.4, -4.2, -3.9)
    for k in range(4):
        w = 6 - k * 1.5
        span(g, wt, C["red"] if k % 2 == 0 else C["redDark"], -w / 2, w / 2, 16 + k * 1.5, 17.5 + k * 1.5, -w / 2, w / 2)
    box(g, wt, C["woodDark"], (1.2, 1.2, 2.5), (0, 14, -3.4))
    hub = (0, 14, -4.8)
    for k in range(4):
        m = BB.rot_axis((0, 0, 1), 45 + k * 90)
        tip = BB.add(hub, BB.apply(m, (0, 6, 0)))
        box(g, wt, C["woodLight"], (0.6, 11, 0.4), BB.scale(BB.add(hub, tip), 0.5), rot=m)
        box(g, wt, C["orange"] if k % 2 == 0 else "FFFFFF", (2.4, 7, 0.2), BB.add(BB.scale(BB.add(hub, tip), 0.5), BB.apply(m, (1.4, 1, 0))), rot=m)
    box(g, wt, C["gold"], (1.4, 1.4, 1), hub)
    for x, z in ((-18, -8), (-14, -18), (18, 12), (4, 20)):
        M.pine(g, *t.p((x, 0, z))[::2], y=t.pos[1], s=1.1)
    for x, z in ((-20, 6), (-2, -20)):
        hb = t.at((x, 0, z), M.yaw(rng.uniform(0, 90)))
        box(g, hb, C["yellow"], (3, 2.2, 2.2), (0, 1.1, 0))
        box(g, hb, "E0B020", (3.1, 0.4, 2.3), (0, 1.1, 0))
    M.fence(g, t.p((-26, 0, -6))[::2], t.p((-14, 0, -22))[::2], y=t.pos[1])
    waterfall(g, t, (-r + 3, 0, -4), (-1, 0), length=60)
    waterfall(g, t, (r - 4, 0, 6), (1, 0), length=50)
    island_sign(g, t, (-8, 0, 20), "WINDMILL", C["woodDark"])


def rainbow_shelf(t, r):
    g = "RainbowShelf"
    cloud_body(g, t, r)
    landing_pad(g, t, (6, 0, 6), g)
    # rainbow arch (voxel bands in the XY plane)
    bands = ["FF3B3B", "FF8A1F", "FFD21F", "3FBF4F", "3BA5FF", "8A4FD8"]
    rainbow = {}
    for i in range(-14, 15):
        for j in range(0, 15):
            rr = math.hypot(i, j)
            if 8 <= rr < 14:
                rainbow[(i, j, 0)] = bands[min(5, int(rr - 8))]
    voxels(g, t, rainbow, unit=1.0, offset=(-4, 0.5, -16))
    for x in (-18, 10):
        for k in range(3):
            box(g, t, "FFFFFF", (6 - k, 3, 5 - k), (x + rng.uniform(-1, 1), 1 + k * 2, -16))
    # Cloud Shelf balloon shop stall (Spike + Popcorn are sold here)
    st = t.at((-16, 0, 8), M.yaw(-60))
    span(g, st, C["cream"], -6, 6, 0, 0.6, -4, 4)
    span(g, st, "FFFFFF", -5, 5, 0.6, 3, -1, 1)
    span(g, st, C["blue"], -5.2, 5.2, 3, 3.4, -1.2, 1.2)
    for x in (-5.5, 5.5):
        span(g, st, C["woodDark"], x - 0.4, x + 0.4, 0.6, 8, -3.5, -2.7)
        span(g, st, C["woodDark"], x - 0.4, x + 0.4, 0.6, 8, 2.7, 3.5)
    for i, x in enumerate(range(-6, 6, 2)):
        M.wedge(g, st, C["blue"] if i % 2 == 0 else "FFFFFF", (2, 1.6, 4.5), (x + 1, 8.6, -1.6))
        M.wedge(g, st, C["blue"] if i % 2 == 0 else "FFFFFF", (2, 1.6, 4.5), (x + 1, 8.6, 2.6), rot=M.yaw(180))
    for x, kind in ((-2.5, "Spike"), (2.5, "Popcorn")):
        top = M.pedestal(g, st, (x, 0.6, -2.4), h=1.6)
        knot = M.balloon_model(g, st, kind, (x, top[1] + 2.9, -2.4), scale_=0.3, spin=15)
        M.string_between(g, st, top, knot)
    M.text(g, st, "SHOP", (0, 9.9, -4.0), 0.4, C["blueDark"])
    for _ in range(24):
        a, rr = rng.uniform(0, 2 * math.pi), rng.uniform(6, r - 8)
        x, z = math.cos(a) * rr, math.sin(a) * rr
        if math.hypot(x - 6, z - 6) > 9 and math.hypot(x + 16, z - 8) > 8:
            M.flower(g, *t.p((x, 0, z))[::2], y=t.pos[1])
    for x, z in ((16, -10), (-6, 22)):
        M.tree(g, *t.p((x, 0, z))[::2], y=t.pos[1], h=4, big=0.85)
    island_sign(g, t, (6, 0, 20), "RAINBOW", C["blueDark"])


def summit_cloud(t, r):
    g = "SummitCloud"
    cloud_body(g, t, r)
    landing_pad(g, t, (0, 0, 8), g)
    # lookout tower with a telescope and banners
    lt = t.at((-12, 0, -12))
    for k, w in enumerate((9, 8, 7)):
        span(g, lt, "FFFFFF" if k % 2 == 0 else C["sky"], -w / 2, w / 2, k * 3, k * 3 + 3, -w / 2, w / 2)
    span(g, lt, C["gold"], -5, 5, 9, 9.6, -5, 5)
    for x in (-4.4, 4.4):
        for z in (-4.4, 4.4):
            span(g, lt, C["gold"], x - 0.3, x + 0.3, 9.6, 11, z - 0.3, z + 0.3)
    box(g, lt, C["woodDark"], (0.4, 2.2, 0.4), (1.5, 10.7, 1.5))
    box(g, lt, C["gold"], (0.8, 0.8, 3.6), (1.5, 12, 0.6), rot=BB.rot_axis((1, 0, 0), 20))
    for x in (-3.8, 3.8):
        box(g, lt, C["woodDark"], (0.3, 7, 0.3), (x, 13, -3.8))
        M.roof_prism(g, lt, C["blue"] if x < 0 else C["gold"], (x, 16.2, -3.8), (0, -1, 0), 3, 2.4, 0.1, (0, 0, 1))
    # cloud towers
    for x, z, h in ((20, -8, 12), (16, 16, 8), (-22, 14, 10)):
        for k in range(int(h / 3)):
            w = 7 - k
            box(g, t, "FFFFFF" if k % 2 == 0 else "EEF3FF", (w, 3, w), (x + rng.uniform(-0.6, 0.6), 1.5 + k * 3, z + rng.uniform(-0.6, 0.6)))
    # gold lanterns ring
    for i in range(6):
        a = i / 6 * 2 * math.pi + 0.3
        M.lamp(g, *t.p((math.cos(a) * (r - 9), 0, math.sin(a) * (r - 9)))[::2], y=t.pos[1], face=-math.degrees(a) - 90)
    for _ in range(18):
        a, rr = rng.uniform(0, 2 * math.pi), rng.uniform(6, r - 9)
        x, z = math.cos(a) * rr, math.sin(a) * rr
        if math.hypot(x, z - 8) > 9 and math.hypot(x + 12, z + 12) > 7:
            M.flower(g, *t.p((x, 0, z))[::2], y=t.pos[1])
    island_sign(g, t, (0, 0, 22), "SUMMIT", C["blueDark"])


BUILDERS = {"meadow": meadow_rest, "windmill": windmill_hill, "rainbow": rainbow_shelf, "summit": summit_cloud}


# ----------------------------------------------------------------------------- config

PADS = {"meadow": (0, 0, 4), "windmill": (-8, 0, 8), "rainbow": (6, 0, 6), "summit": (0, 0, 8)}


def write_config():
    lines = [
        "--!strict",
        "-- GENERATED by tools/map/build_sky_islands.py - do not edit by hand.",
        "-- Landing islands for FlightService: top-centre position, radius, zone and the landing pad",
        "-- (each island Model in workspace.SkyIslands also has an invisible 'LandingPad' part).",
        "",
        "export type Island = { Name: string, Zone: string, Top: Vector3, Radius: number, Pad: Vector3 }",
        "",
        "local IslandConfig: { Islands: { Island } } = {",
        "\tIslands = {",
    ]
    for name, zone, top, r, style in ISLANDS:
        pad = BB.add(top, PADS[style])
        lines.append(f'\t\t{{ Name = "{name}", Zone = "{zone}", Top = Vector3.new({top[0]}, {top[1]}, {top[2]}), '
                     f"Radius = {r}, Pad = Vector3.new({pad[0]:g}, {pad[1]:g}, {pad[2]:g}) }},")
    lines += ["\t},", "}", "", "return IslandConfig", ""]
    with open(CONFIG, "w") as f:
        f.write("\n".join(lines))


def main():
    for name, zone, top, r, style in ISLANDS:
        BUILDERS[style](T(top), r)
    size = M.export("SkyIslands", OUT)
    write_config()
    print(f"SkyIslands: {S.count()} parts -> {os.path.relpath(OUT, ROOT)} ({size // 1024} KB)")
    for gname, parts in S.groups.items():
        print(f"  {gname:13s} {len(parts)}")
    if "--preview" in sys.argv:
        M.S = S
        M.render((200, -20), 1600, 1100, "islands.png")
        for name, zone, top, r, style in ISLANDS:
            M.render((200, -22), 900, 700, f"island-{name}.png", focus=(top[0], top[2]), radius=r + 10)


if __name__ == "__main__":
    main()
