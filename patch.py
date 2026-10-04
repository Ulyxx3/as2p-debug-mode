#!/usr/bin/env python3
"""
Antivirus Survivors 2003 Professional - Mod Installer / Patcher
Cross-Platform (Windows & Linux / SteamOS / Steam Deck)
"""

import os
import sys
import argparse

# Add repo root to import path
REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, REPO_ROOT)

from installer.pck_patcher import Godot4PckPatcher, Colors, GAME_NAME, PCK_NAME

def main():
    parser = argparse.ArgumentParser(
        description=f"Patch/Install Debug Mode for {GAME_NAME} (Windows & Linux)",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--game-dir",
        type=str,
        default=None,
        help="Chemin vers le repertoire d'installation du jeu (contenant AVS03Pro.pck)"
    )
    parser.add_argument(
        "--restore",
        action="store_true",
        help="Restaurer le fichier original du jeu (desinstaller le mod)"
    )

    args = parser.parse_args()

    print(f"{Colors.CYAN}{Colors.BOLD}")
    print("=" * 65)
    print(f" Antivirus Survivors 2003 Professional - Debug Mode Installer")
    print(f" Compatible : Windows & Linux (Steam / Steam Deck / Proton)")
    print("=" * 65 + f"{Colors.RESET}\n")

    game_dir = args.game_dir
    if not game_dir:
        print(f"{Colors.CYAN}[*] Recherche automatique du dossier du jeu...{Colors.RESET}")
        game_dir = Godot4PckPatcher.find_game_directory()

    while not game_dir or not os.path.isfile(os.path.join(game_dir, PCK_NAME)):
        print(f"{Colors.YELLOW}[!] Dossier du jeu introuvable automatiquement.{Colors.RESET}")
        print("Veuillez entrer ou glisser-deposer le chemin du dossier contenant AVS03Pro.pck :")
        try:
            entered = input("> ").strip().strip('"').strip("'")
            if not entered:
                print("Operation annulee.")
                sys.exit(1)
            if os.path.isfile(entered):
                entered = os.path.dirname(entered)
            game_dir = entered
        except (KeyboardInterrupt, EOFError):
            print("\nOperation annulee.")
            sys.exit(1)

    print(f"{Colors.GREEN}[+] Repertoire du jeu detecte :{Colors.RESET} {game_dir}\n")

    if args.restore:
        success = Godot4PckPatcher.restore(game_dir)
        sys.exit(0 if success else 1)

    mod_files_dir = os.path.join(REPO_ROOT, "mod_files")
    if not os.path.isdir(mod_files_dir):
        print(f"{Colors.RED}[!] Dossier 'mod_files' introuvable dans {REPO_ROOT}!{Colors.RESET}")
        sys.exit(1)

    success = Godot4PckPatcher.install(game_dir, mod_files_dir)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
