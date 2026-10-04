@echo off
title Antivirus Survivors 2003 - Restaurer le Jeu Original
cd /d "%~dp0"

echo ========================================================
echo  Restauration du jeu original (Desinstallation du mod)
echo ========================================================
echo.

where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    python patch.py --restore
    pause
    exit /b
)

where py >nul 2>nul
if %ERRORLEVEL% equ 0 (
    py patch.py --restore
    pause
    exit /b
)

echo [ERREUR] Python 3 est requis.
pause
