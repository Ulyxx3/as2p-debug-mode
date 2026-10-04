#!/usr/bin/env python3
"""
Godot 4 PCK Patcher (Cross-Platform: Windows, Linux, macOS, SteamOS)
Pure Python 3 implementation with zero external dependencies.
Capable of reading, backing up, and atomically patching Godot 4 (.pck) packages.
"""

import os
import sys
import struct
import hashlib
import shutil
import re
from typing import Dict, List, Optional

GAME_NAME = "Antivirus Survivors 2003 Professional"
PCK_NAME = "AVS03Pro.pck"
BAK_NAME = "AVS03Pro.pck.bak"

class Colors:
    GREEN = '\033[92m'
    CYAN = '\033[96m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    DIM = '\033[2m'
    RESET = '\033[0m'

    @classmethod
    def disable(cls):
        cls.GREEN = cls.CYAN = cls.YELLOW = cls.RED = cls.BOLD = cls.DIM = cls.RESET = ''

if sys.platform == 'win32':
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        Colors.disable()


class Godot4PckPatcher:
    """Handles parsing, backing up and patching of Godot 4 unencrypted PCK files."""

    @staticmethod
    def inspect_pck(pck_path: str) -> Dict:
        """Reads and parses header & file directory of a Godot 4 PCK file."""
        with open(pck_path, 'rb') as f:
            header = bytearray(f.read(128))
            if len(header) < 128 or header[:4] != b'GDPC':
                raise ValueError(f"'{pck_path}' is not a valid Godot PCK file (magic != GDPC).")
            
            format_ver = struct.unpack('<I', header[4:8])[0]
            major, minor, patch = struct.unpack('<III', header[8:20])
            flags = struct.unpack('<I', header[20:24])[0]
            file_base = struct.unpack('<Q', header[24:32])[0]
            dir_offset = struct.unpack('<Q', header[32:40])[0]

            f.seek(dir_offset)
            count_data = f.read(4)
            if len(count_data) < 4:
                raise ValueError("Unexpected end of file while reading PCK directory index.")
            file_count = struct.unpack('<I', count_data)[0]

            files = []
            file_map = {}
            for _ in range(file_count):
                plen = struct.unpack('<I', f.read(4))[0]
                padded_len = (plen + 3) & ~3
                raw_path = f.read(padded_len)
                path_str = raw_path[:plen].rstrip(b'\x00').decode('utf-8', errors='replace')
                off, sz = struct.unpack('<QQ', f.read(16))
                md5 = f.read(16)
                fl = struct.unpack('<I', f.read(4))[0]

                entry = {
                    'path': path_str,
                    'plen': plen,
                    'raw_path': raw_path,
                    'offset': off,
                    'size': sz,
                    'md5': md5,
                    'flags': fl
                }
                files.append(entry)
                file_map[path_str] = entry
                if path_str.startswith('res://'):
                    file_map[path_str[6:]] = entry
                else:
                    file_map['res://' + path_str] = entry

            return {
                'header': header,
                'format': format_ver,
                'godot_version': f"{major}.{minor}.{patch}",
                'file_base': file_base,
                'dir_offset': dir_offset,
                'file_count': file_count,
                'files': files,
                'file_map': file_map
            }

    @staticmethod
    def patch_pck(src_pck: str, out_pck: str, replacements: Dict[str, bytes]) -> int:
        """
        Creates a new patched PCK file with replaced or newly injected files.
        Returns the number of files updated/injected.
        """
        info = Godot4PckPatcher.inspect_pck(src_pck)
        header = bytearray(info['header'])
        file_base = info['file_base']
        old_dir_offset = info['dir_offset']
        files = info['files']
        file_map = info['file_map']

        updated_count = 0

        with open(src_pck, 'rb') as f_in, open(out_pck, 'wb') as f_out:
            # 1. Write original 128-byte header as placeholder
            f_out.write(header)

            # 2. Stream existing file data block (offset 128 to old_dir_offset)
            f_in.seek(128)
            remaining = old_dir_offset - 128
            chunk_size = 2 * 1024 * 1024 # 2MB buffer
            while remaining > 0:
                to_read = min(remaining, chunk_size)
                buf = f_in.read(to_read)
                if not buf:
                    break
                f_out.write(buf)
                remaining -= len(buf)

            # 3. Append replaced or new files to the data section
            for target_res, file_bytes in replacements.items():
                curr_pos = f_out.tell()
                # 64-byte alignment
                align_pad = (64 - (curr_pos % 64)) % 64
                if align_pad > 0:
                    f_out.write(b'\x00' * align_pad)
                    curr_pos += align_pad

                new_offset = curr_pos - file_base
                new_size = len(file_bytes)
                new_md5 = hashlib.md5(file_bytes).digest()
                f_out.write(file_bytes)

                norm_key = target_res[6:] if target_res.startswith('res://') else target_res
                target_entry = file_map.get(norm_key) or file_map.get('res://' + norm_key)
                if target_entry:
                    target_entry['offset'] = new_offset
                    target_entry['size'] = new_size
                    target_entry['md5'] = new_md5
                else:
                    raw_p = norm_key.encode('utf-8')
                    padded_p = raw_p + b'\x00' * ((4 - (len(raw_p) % 4)) % 4)
                    new_entry = {
                        'path': norm_key,
                        'plen': len(raw_p),
                        'raw_path': padded_p,
                        'offset': new_offset,
                        'size': new_size,
                        'md5': new_md5,
                        'flags': 0
                    }
                    files.append(new_entry)
                updated_count += 1

            # 4. Write new directory table
            new_dir_offset = f_out.tell()
            f_out.write(struct.pack('<I', len(files)))
            for entry in files:
                f_out.write(struct.pack('<I', entry['plen']))
                f_out.write(entry['raw_path'])
                f_out.write(struct.pack('<QQ', entry['offset'], entry['size']))
                f_out.write(entry['md5'])
                f_out.write(struct.pack('<I', entry['flags']))

            # 5. Write Godot 4 trailing marker (24 zeros + GDPC)
            f_out.write(b'\x00' * 24 + b'GDPC')

            # 6. Update header at byte 32 with new_dir_offset
            f_out.seek(32)
            f_out.write(struct.pack('<Q', new_dir_offset))

        return updated_count

    @staticmethod
    def find_game_directory() -> Optional[str]:
        """Automatically discovers the Steam installation directory on Windows or Linux."""
        candidates = []

        # Current working directory or parent check
        cwd = os.path.abspath(os.getcwd())
        for path in [cwd, os.path.dirname(cwd), os.path.join(cwd, "game")]:
            if os.path.isfile(os.path.join(path, PCK_NAME)):
                return path

        if sys.platform == 'win32':
            # Windows default Steam locations
            win_steam_roots = [
                r"C:\Program Files (x86)\Steam",
                r"C:\Program Files\Steam",
                r"D:\Steam",
                r"E:\Steam",
                r"D:\SteamLibrary",
                r"E:\SteamLibrary"
            ]
            for root in win_steam_roots:
                direct_path = os.path.join(root, "steamapps", "common", GAME_NAME)
                if os.path.isdir(direct_path) and os.path.isfile(os.path.join(direct_path, PCK_NAME)):
                    return direct_path
                vdf_path = os.path.join(root, "steamapps", "libraryfolders.vdf")
                if os.path.isfile(vdf_path):
                    candidates.extend(Godot4PckPatcher._parse_vdf_libraries(vdf_path))
        else:
            # Linux / Steam Deck default Steam locations
            home = os.path.expanduser("~")
            linux_steam_roots = [
                os.path.join(home, ".local/share/Steam"),
                os.path.join(home, ".steam/steam"),
                os.path.join(home, ".steam/root"),
                os.path.join(home, ".var/app/com.valvesoftware.Steam/.local/share/Steam"),
                os.path.join(home, ".var/app/com.valvesoftware.Steam/.steam/steam"),
            ]
            for root in linux_steam_roots:
                direct_path = os.path.join(root, "steamapps", "common", GAME_NAME)
                if os.path.isdir(direct_path) and os.path.isfile(os.path.join(direct_path, PCK_NAME)):
                    return direct_path
                vdf_path = os.path.join(root, "steamapps", "libraryfolders.vdf")
                if os.path.isfile(vdf_path):
                    candidates.extend(Godot4PckPatcher._parse_vdf_libraries(vdf_path))

        # Check any custom library folders found via VDF
        for lib in candidates:
            path = os.path.join(lib, "steamapps", "common", GAME_NAME)
            if os.path.isdir(path) and os.path.isfile(os.path.join(path, PCK_NAME)):
                return path

        return None

    @staticmethod
    def _parse_vdf_libraries(vdf_path: str) -> List[str]:
        """Parses Steam libraryfolders.vdf to find additional drive/mount library paths."""
        libraries = []
        try:
            with open(vdf_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                matches = re.findall(r'"path"\s+"([^"]+)"', content)
                for m in matches:
                    norm = os.path.normpath(m.replace('\\\\', '\\'))
                    if os.path.isdir(norm):
                        libraries.append(norm)
        except Exception:
            pass
        return libraries

    @staticmethod
    def install(game_dir: str, mod_files_dir: str) -> bool:
        """Backs up and installs the mod into the specified game directory."""
        pck_path = os.path.join(game_dir, PCK_NAME)
        bak_path = os.path.join(game_dir, BAK_NAME)
        tmp_path = os.path.join(game_dir, PCK_NAME + ".tmp")

        if not os.path.isfile(pck_path):
            print(f"{Colors.RED}[!] Fichier introuvable : {pck_path}{Colors.RESET}")
            return False

        # Backup creation
        if not os.path.isfile(bak_path):
            print(f"{Colors.CYAN}[+] Creation de la sauvegarde du jeu original...{Colors.RESET}")
            print(f"    -> {bak_path}")
            shutil.copy2(pck_path, bak_path)
        else:
            print(f"{Colors.DIM}[*] Sauvegarde d'origine deja presente : {bak_path}{Colors.RESET}")

        # Collect replacements
        replacements = {}
        for root, _, files in os.walk(mod_files_dir):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, mod_files_dir).replace('\\', '/')
                with open(full_path, 'rb') as f_in:
                    replacements[rel_path] = f_in.read()

        if not replacements:
            print(f"{Colors.RED}[!] Aucun fichier modde trouve dans {mod_files_dir}!{Colors.RESET}")
            return False

        print(f"{Colors.CYAN}[*] Application du patch dans le fichier PCK ({len(replacements)} fichiers)...{Colors.RESET}")
        for r in replacements:
            print(f"    [+] {r}")

        base_src = bak_path if os.path.isfile(bak_path) else pck_path

        try:
            Godot4PckPatcher.patch_pck(base_src, tmp_path, replacements)
            # Atomic replace
            shutil.move(tmp_path, pck_path)
            print(f"\n{Colors.GREEN}{Colors.BOLD}[SUCCES] Le mod Debug Menu a ete installe avec succes !{Colors.RESET}")
            print(f"{Colors.YELLOW}[*] Raccourcis en jeu : Appuyez sur [F1], [F3] ou [~] pour ouvrir le menu.{Colors.RESET}")
            return True
        except Exception as e:
            if os.path.isfile(tmp_path):
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass
            print(f"{Colors.RED}[-] Erreur lors du patch : {e}{Colors.RESET}")
            return False

    @staticmethod
    def restore(game_dir: str) -> bool:
        """Restores the original game PCK from backup."""
        pck_path = os.path.join(game_dir, PCK_NAME)
        bak_path = os.path.join(game_dir, BAK_NAME)

        if not os.path.isfile(bak_path):
            print(f"{Colors.RED}[!] Aucune sauvegarde originale trouvee ({bak_path}). Restauration impossible.{Colors.RESET}")
            return False

        print(f"{Colors.CYAN}[*] Restauration du fichier original depuis {bak_path}...{Colors.RESET}")
        shutil.copy2(bak_path, pck_path)
        print(f"{Colors.GREEN}{Colors.BOLD}[SUCCES] Le jeu original a ete restaure avec succes !{Colors.RESET}")
        return True
