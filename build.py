#!/usr/bin/env python3
"""
Antivirus Survivors 2003 - Developer Build Script
Compiles modified GDScript files in src/ into bytecode (.gdc) in mod_files/
and automatically patches the game if installed.
"""

import os
import sys
import shutil
import subprocess
import urllib.request
import zipfile

REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, REPO_ROOT)

from installer.pck_patcher import Godot4PckPatcher, Colors, PCK_NAME

BYTECODE_VERSION = "ebc36a7" # Godot 4.5.0-stable bytecode (Godot 4.7.1 game engine)

FILES_TO_COMPILE = [
    {
        "src": os.path.join(REPO_ROOT, "src", "scenes", "ui", "debug_menu", "debug_menu.gd"),
        "out_dir": os.path.join(REPO_ROOT, "mod_files", "scenes", "ui", "debug_menu"),
        "gdc": os.path.join(REPO_ROOT, "mod_files", "scenes", "ui", "debug_menu", "debug_menu.gdc"),
    },
    {
        "src": os.path.join(REPO_ROOT, "src", "scenes", "main", "main.gd"),
        "out_dir": os.path.join(REPO_ROOT, "mod_files", "scenes", "main"),
        "gdc": os.path.join(REPO_ROOT, "mod_files", "scenes", "main", "main.gdc"),
    },
    {
        "src": os.path.join(REPO_ROOT, "src", "scenes", "autoload", "game_events.gd"),
        "out_dir": os.path.join(REPO_ROOT, "mod_files", "scenes", "autoload"),
        "gdc": os.path.join(REPO_ROOT, "mod_files", "scenes", "autoload", "game_events.gdc"),
    },
    {
        "src": os.path.join(REPO_ROOT, "src", "scenes", "component", "health_component.gd"),
        "out_dir": os.path.join(REPO_ROOT, "mod_files", "scenes", "component"),
        "gdc": os.path.join(REPO_ROOT, "mod_files", "scenes", "component", "health_component.gdc"),
    }
]

def find_gdre_tools() -> str:
    """Finds or hints gdre_tools executable."""
    tools_dir = os.path.join(REPO_ROOT, "tools")
    os.makedirs(tools_dir, exist_ok=True)
    
    exe_name = "gdre_tools.exe" if sys.platform == "win32" else "gdre_tools.x86_64"
    local_path = os.path.join(tools_dir, exe_name)
    if os.path.isfile(local_path):
        return local_path
    
    # Check PATH
    which_cmd = shutil.which("gdre_tools") or shutil.which(exe_name)
    if which_cmd:
        return which_cmd

    # Check steam directory tools folder as fallback
    game_dir = Godot4PckPatcher.find_game_directory()
    if game_dir:
        steam_tools_exe = os.path.join(game_dir, "tools", exe_name)
        if os.path.isfile(steam_tools_exe):
            return steam_tools_exe

    return ""

def compile_scripts(gdre_exe: str) -> bool:
    print(f"{Colors.CYAN}[*] Compilation des scripts src/ en bytecode (.gdc)...{Colors.RESET}")
    for item in FILES_TO_COMPILE:
        src = item["src"]
        out_dir = item["out_dir"]
        os.makedirs(out_dir, exist_ok=True)
        
        cmd = [
            gdre_exe,
            "--headless",
            f"--compile={src}",
            f"--output={out_dir}",
            f"--bytecode={BYTECODE_VERSION}"
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"{Colors.RED}[-] Erreur de compilation pour {src} :{Colors.RESET}\n{res.stderr}")
            return False
        print(f"    {Colors.GREEN}[OK]{Colors.RESET} {os.path.basename(src)} -> {os.path.basename(item['gdc'])}")
    return True

def main():
    print(f"{Colors.CYAN}{Colors.BOLD}======================================================")
    print(" Antivirus Survivors 2003 - Developer Build Pipeline")
    print(f"======================================================{Colors.RESET}\n")

    gdre = find_gdre_tools()
    if not gdre:
        print(f"{Colors.YELLOW}[!] gdre_tools introuvable localement.{Colors.RESET}")
        print("Pour recompiler les fichiers .gd en .gdc, téléchargez Godot RE Tools depuis :")
        print("https://github.com/godot-re-tools/godot-re-tools/releases")
        print(f"et placez l'executable dans le dossier : {os.path.join(REPO_ROOT, 'tools')}\n")
        print("Note : Les fichiers precompiles dans mod_files/ sont deja a jour !")
        sys.exit(1)

    if not compile_scripts(gdre):
        sys.exit(1)

    print(f"\n{Colors.GREEN}[+] Compilation terminee avec succes dans mod_files/ !{Colors.RESET}")

    # Auto patch local game if installed
    game_dir = Godot4PckPatcher.find_game_directory()
    if game_dir and os.path.isfile(os.path.join(game_dir, PCK_NAME)):
        print(f"\n{Colors.CYAN}[*] Installation automatique dans le jeu detecte :{Colors.RESET} {game_dir}")
        Godot4PckPatcher.install(game_dir, os.path.join(REPO_ROOT, "mod_files"))
    else:
        print(f"\n{Colors.DIM}[*] Jeu non detecte automatiquement. Executez 'python patch.py' pour l'installer.{Colors.RESET}")

if __name__ == "__main__":
    main()
