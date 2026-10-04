#!/usr/bin/env bash
# Antivirus Survivors 2003 - Restaurer le Jeu Original (Linux)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if command -v python3 &> /dev/null; then
    python3 patch.py --restore
elif command -v python &> /dev/null; then
    python patch.py --restore
else
    echo "[ERREUR] Python 3 n'est pas installe."
    exit 1
fi
