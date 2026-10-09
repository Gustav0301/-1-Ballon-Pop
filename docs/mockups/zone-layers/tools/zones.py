"""Zone layer settings for 1+ Ballon Pop. One source -> ZoneLayerConfig.lua (game) + zones.json (preview)."""
import json

ZONES = [
    dict(Id="MeadowSky", Name="MEADOW SKY", From=0, To=500,
         Sky=dict(Brightness=3.0, ClockTime=13.6, Exposure=0.0, Ambient="7680A0", OutdoorAmbient="98A6C0",
                  SkyTop="3FA9F5", Horizon="D4F0FF", Sun="FFF6C9",
                  AtmosColor="D4F0FF", AtmosDecay="6EAEE8", AtmosDensity=0.2, AtmosHaze=0.5, AtmosGlare=0.3, AtmosOffset=0.2,
                  Tint="FFFBF4", Saturation=0.18, Contrast=0.06, CCBrightness=0.02, SunSize=14,
                  CloudCover=0.52, CloudDensity=0.45, CloudColor="FFFFFF"),
         Clouds=dict(Kind="Puffy", Count=24, MinY=90, MaxY=430, Ring=[120, 520], Drift=[3.0, 0, 0.6],
                     Top="FFFFFF", Side="F2F7FF", Bottom="BCD0EA"),
         Near=dict(Petals=1.0, Pollen=1.0, Mist=0.0, Dust=0.0,
                   PetalColors=["FF8FB8", "FFE066", "FFFFFF", "FFB0D0"]),
         ),
    dict(Id="CloudShelf", Name="CLOUD SHELF", From=500, To=1500,
         Sky=dict(Brightness=3.5, ClockTime=14.2, Exposure=0.05, Ambient="8C7E70", OutdoorAmbient="C0A68C",
                  SkyTop="1F6FD1", Horizon="FFD9A0", Sun="FFE08A",
                  AtmosColor="FFD9A0", AtmosDecay="3F7FD6", AtmosDensity=0.24, AtmosHaze=1.0, AtmosGlare=0.75, AtmosOffset=0.12,
                  Tint="FFF0DA", Saturation=0.24, Contrast=0.08, CCBrightness=0.03, SunSize=19,
                  CloudCover=0.25, CloudDensity=0.3, CloudColor="FFF2DC"),
         Clouds=dict(Kind="Cloudlets", Count=30, MinY=560, MaxY=1450, Ring=[90, 420], Drift=[1.6, 0, 0.4],
                     Top="FFF4DE", Side="FFFFFF", Bottom="E9D7C0"),
         Near=dict(Petals=0.0, Pollen=0.0, Mist=1.0, Dust=1.0, PetalColors=[]),
         ),
]

# the cloud deck between the two zones: a ceiling from below, a floor from above
DECK = dict(Y=500, Thickness=40, Tile=64, Radius=448, ActiveRange=800, BuildPerFrame=10, Coverage=0.88, IslandHole=26, IslandBand=60,
            Top="FFFFFF", TopGold="FFF0D2", Side="F6F9FF", Bottom="CFDCF0", Seed=7,
            # flat cloud sea beyond the tiles, out to the horizon (a frame of thin parts, max part size 2048)
            SeaY=512, SeaOuter=2048, Sea="FFF8EE")
# tall cloud towers standing on the deck, far away (Cloud Shelf "far" layer)
TOWERS = dict(Count=7, Distance=[1100, 1700], Height=[180, 420], Width=[90, 160])
# how values blend at a zone boundary: starts BlendBelow studs under it, done BlendAbove over it
BLEND = dict(Below=100, Above=30)
# the punch-through: inside the deck the mist closes in, then it opens up
PUNCH = dict(MistDensity=0.62, FlashBrightness=0.18, FlashTime=0.5, Whoosh="Launch", WhooshPitch=0.75)
# stud texture on the tops of clouds (Gustav's stud picture); set On=False to turn off
STUDS = dict(On=True, Texture="rbxassetid://6927295847", Tile=4, Transparency=0.55)
# how many near bits (petals, pollen, mist, dust) can exist at once
NEAR = dict(Max=40)
# workspace folders with island models (holes in the deck, clouds keep away); IslandConfig is the fallback
ISLANDS = dict(Folders=["SkyIslands"], Margin=6)

def lua_val(v, ind):
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (int, float)): return repr(v)
    if isinstance(v, str):
        if len(v) == 6 and all(c in "0123456789ABCDEF" for c in v): return f'Color3.fromHex("{v}")'
        return f'"{v}"'
    if isinstance(v, list):
        if len(v) == 3 and all(isinstance(x, (int, float)) for x in v): return f"Vector3.new({v[0]}, {v[1]}, {v[2]})"
        return "{ " + ", ".join(lua_val(x, ind) for x in v) + " }"
    if isinstance(v, dict):
        pad = "\t" * (ind + 1)
        return "{\n" + "".join(f"{pad}{k} = {lua_val(x, ind + 1)},\n" for k, x in v.items()) + "\t" * ind + "}"
    raise TypeError(v)

lua = ["--!strict",
       "-- ZoneLayerConfig: how every sky zone looks. One entry per zone; a new zone just adds an entry.",
       "-- Made from tools/zones/zones.py (the preview uses the same numbers). Colours are hex like in the plan.",
       "-- Sky: Lighting + Atmosphere + ColorCorrection + Terrain clouds. Clouds: stud clouds around you.",
       "-- Near: small bits that fly past you (0 = off, 1 = normal). Weather plays on top of this.",
       "", "local ZoneLayerConfig = {}", "",
       "ZoneLayerConfig.Zones = " + lua_val(ZONES, 0), "",
       "-- The cloud deck between Meadow Sky and Cloud Shelf (Y is its middle). No collision: you fly through it.",
       "ZoneLayerConfig.Deck = " + lua_val(DECK, 0), "",
       "ZoneLayerConfig.Towers = " + lua_val(TOWERS, 0), "",
       "ZoneLayerConfig.Blend = " + lua_val(BLEND, 0), "",
       "ZoneLayerConfig.Punch = " + lua_val(PUNCH, 0), "",
       "ZoneLayerConfig.Studs = " + lua_val(STUDS, 0), "",
       "ZoneLayerConfig.Near = " + lua_val(NEAR, 0), "",
       "ZoneLayerConfig.Islands = " + lua_val(ISLANDS, 0), "",
       "return ZoneLayerConfig", ""]
open("ZoneLayerConfig.lua", "w").write("\n".join(lua))
json.dump(dict(zones=ZONES, deck=DECK, towers=TOWERS, blend=BLEND, punch=PUNCH, studs=STUDS, near=NEAR, islands=ISLANDS), open("zones.json", "w"))
print("ok")
