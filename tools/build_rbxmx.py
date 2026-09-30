#!/usr/bin/env python3
"""Builds build/HazardPack.rbxmx: a drag-and-drop Roblox model containing the whole
hazard system (same source files as the Rojo project, byte for byte).

Drop it anywhere in Studio (it lands in Workspace). On Play, its Start script moves:
  Shared  -> ReplicatedStorage.HazardShared
  Server  -> ServerScriptService.HazardServer
  Client  -> ReplicatedStorage.HazardClient (and enables the client runner)
then starts HazardService in demo mode.

Usage: python3 tools/build_rbxmx.py
"""
import os
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "HazardPack.rbxmx")

START = """-- 1+ Ballon Pop pack: installs itself on Play, applies the festival sky and starts the hazards.
-- Set DEMO = false once FlightService gives players real balloons.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DEMO = true

local pack = script.Parent
local shared = pack:WaitForChild("Shared")
shared.Name = "HazardShared"
shared.Parent = ReplicatedStorage

local server = pack:WaitForChild("Server")
server.Name = "HazardServer"
server.Parent = ServerScriptService

local client = pack:WaitForChild("Client")
client.Name = "HazardClient"
client.Parent = ReplicatedStorage
local run = client:WaitForChild("Run") :: Script
run.Enabled = true

require(server:WaitForChild("WorldLook")).Apply()

require(server:WaitForChild("HazardService")).Start({
	Shared = shared,
	RemoteParent = ReplicatedStorage,
	Demo = DEMO,
})
"""

RUN = """-- Client runner for the hazard pack (enabled by the pack's Start script).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(script.Parent:WaitForChild("HazardFXController")).Start({
	Shared = ReplicatedStorage:WaitForChild("HazardShared"),
	RemoteParent = ReplicatedStorage,
})
"""

_ref = [0]


def ref():
    _ref[0] += 1
    return f"RBX{_ref[0]:08X}"


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        src = f.read()
    assert "]]>" not in src, path
    return src


def folder(name, children):
    return f'<Item class="Folder" referent="{ref()}"><Properties><string name="Name">{escape(name)}</string></Properties>{"".join(children)}</Item>'


def module(name, source):
    return (f'<Item class="ModuleScript" referent="{ref()}"><Properties><string name="Name">{escape(name)}</string>'
            f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString></Properties></Item>')


def script(name, source, run_context, disabled=False):
    # RunContext: 0 Legacy, 1 Server, 2 Client
    return (f'<Item class="Script" referent="{ref()}"><Properties><string name="Name">{escape(name)}</string>'
            f'<bool name="Disabled">{"true" if disabled else "false"}</bool>'
            f'<token name="RunContext">{run_context}</token>'
            f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString></Properties></Item>')


def tree(path):
    """Folder of ModuleScripts mirroring a src directory."""
    items = []
    full = os.path.join(ROOT, path)
    for entry in sorted(os.listdir(full)):
        p = os.path.join(path, entry)
        if os.path.isdir(os.path.join(ROOT, p)):
            items.append(folder(entry, tree(p)))
        elif entry.endswith(".lua") and not entry.endswith((".server.lua", ".client.lua")):
            items.append(module(entry[:-4], read(p)))
    return items


def main():
    pack = folder("HazardPack", [
        folder("Shared", tree("src/shared")),
        folder("Server", tree("src/server/Services")),
        folder("Client", [
            module("HazardFXController", read("src/client/Controllers/HazardFXController.lua")),
            script("Run", RUN, 2, disabled=True),
        ]),
        script("Start", START, 1),
    ])
    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
           '<External>null</External><External>nil</External>' + pack + '</roblox>\n')
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(xml)
    print("wrote", os.path.relpath(OUT, ROOT), f"({len(xml) // 1024} KB)")


if __name__ == "__main__":
    main()
