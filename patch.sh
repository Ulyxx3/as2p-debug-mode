#!/usr/bin/env bash
# Antivirus Survivors 2003 - Debug Mode Installer (Linux / Steam Deck)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================================"
echo " Antivirus Survivors 2003 - Debug Mode Installer (Linux)"
echo " Compatible Native & Proton / SteamOS / Steam Deck"
echo "========================================================"
echo ""

if command -v python3 &> /dev/null; then
    python3 patch.py "$@"
elif command -v python &> /dev/null; then
    python patch.py "$@"
else
    echo "[ERREUR] Python 3 n'est pas installe sur ce systeme."
    echo "Installez python3 via votre gestionnaire de paquets (ex: sudo apt install python3 ou sudo pacman -S python)."
    exit 1
fi
