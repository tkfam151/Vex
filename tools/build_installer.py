#!/usr/bin/env python3
"""
Builds Installer.lua: one script you paste into Roblox Studio's Command Bar
(View > Command Bar) that creates every game script in the right place.

Run from the repo root:   python3 tools/build_installer.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (source file, class, service, sub-container, name)
FILES = [
    ("src/ReplicatedStorage/Config.lua", "ModuleScript", "ReplicatedStorage", None, "Config"),
    ("src/ServerScriptService/DataManager.lua", "ModuleScript", "ServerScriptService", None, "DataManager"),
    ("src/ReplicatedStorage/RobotBuilder.lua", "ModuleScript", "ReplicatedStorage", None, "RobotBuilder"),
    ("src/ServerScriptService/WorldBuilder.lua", "ModuleScript", "ServerScriptService", None, "WorldBuilder"),
    ("src/ServerScriptService/TycoonServer.server.lua", "Script", "ServerScriptService", None, "TycoonServer"),
    ("src/ServerScriptService/ArenaServer.server.lua", "Script", "ServerScriptService", None, "ArenaServer"),
    ("src/ServerScriptService/SimServer.server.lua", "Script", "ServerScriptService", None, "SimServer"),
    ("src/StarterPlayerScripts/MainUI.client.lua", "LocalScript", "StarterPlayer", "StarterPlayerScripts", "MainUI"),
    ("src/StarterPlayerScripts/DriveClient.client.lua", "LocalScript", "StarterPlayer", "StarterPlayerScripts", "DriveClient"),
]


def long_bracket(text: str) -> tuple[str, str]:
    level = 1
    while ("]" + "=" * level + "]") in text:
        level += 1
    return "[" + "=" * level + "[", "]" + "=" * level + "]"


def main() -> None:
    out = [
        "-- VEX Robotics Tycoon installer",
        "-- Paste ALL of this into Roblox Studio > View > Command Bar and press Enter.",
        "-- It creates (or replaces) every game script. Undo with Ctrl+Z.",
        'local ChangeHistoryService = game:GetService("ChangeHistoryService")',
        'ChangeHistoryService:SetWaypoint("Before VEX Tycoon install")',
        "-- remove scripts from older versions that moved",
        'local oldBuilder = game:GetService("ServerScriptService"):FindFirstChild("RobotBuilder")',
        "if oldBuilder then",
        "\toldBuilder:Destroy()",
        "end",
        "local files = {}",
    ]
    for path, cls, service, sub, name in FILES:
        source = (ROOT / path).read_text(encoding="utf-8")
        open_b, close_b = long_bracket(source)
        sub_lua = f'"{sub}"' if sub else "nil"
        out.append(
            f'table.insert(files, {{ Class = "{cls}", Service = "{service}", Sub = {sub_lua}, Name = "{name}", Source = {open_b}\n{source}{close_b} }})'
        )
    out += [
        "for _, f in ipairs(files) do",
        "\tlocal parent = game:GetService(f.Service)",
        "\tif f.Sub then",
        "\t\tparent = parent:WaitForChild(f.Sub)",
        "\tend",
        "\tlocal old = parent:FindFirstChild(f.Name)",
        "\tif old then",
        "\t\told:Destroy()",
        "\tend",
        "\tlocal s = Instance.new(f.Class)",
        "\ts.Name = f.Name",
        "\ts.Source = f.Source",
        "\ts.Parent = parent",
        "end",
        'ChangeHistoryService:SetWaypoint("Installed VEX Tycoon")',
        'print("VEX Robotics Tycoon installed! " .. #files .. " scripts created. Press Play to test.")',
        "",
    ]
    (ROOT / "Installer.lua").write_text("\n".join(out), encoding="utf-8")
    print(f"Wrote Installer.lua ({len(FILES)} scripts)")


if __name__ == "__main__":
    main()
