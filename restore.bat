@echo off
title Antivirus Survivors 2003 - Restaurer le Jeu Original
cd /d "%~dp0"

echo ========================================================
echo  Restauration du jeu original (Desinstallation du mod)
echo ========================================================
echo.

set "PYTHON_CMD="

:: 1. Recuperer le chemin absolu de python via where.exe
for /f "delims=" %%I in ('where python 2^>nul') do (
    if exist "%%I" if not defined PYTHON_CMD set "PYTHON_CMD=%%I"
)
for /f "delims=" %%I in ('where py 2^>nul') do (
    if exist "%%I" if not defined PYTHON_CMD set "PYTHON_CMD=%%I"
)

:: 2. Verifier les dossiers d'installation Python de l'utilisateur
if not defined PYTHON_CMD (
    if exist "%LOCALAPPDATA%\Python\bin\python.exe" set "PYTHON_CMD=%LOCALAPPDATA%\Python\bin\python.exe"
)
if not defined PYTHON_CMD (
    for /d %%D in ("%LOCALAPPDATA%\Python\pythoncore-*") do (
        if exist "%%D\python.exe" set "PYTHON_CMD=%%D\python.exe"
    )
)
if not defined PYTHON_CMD (
    for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python*") do (
        if exist "%%D\python.exe" set "PYTHON_CMD=%%D\python.exe"
    )
)
if not defined PYTHON_CMD (
    for /d %%D in ("%ProgramFiles%\Python*") do (
        if exist "%%D\python.exe" set "PYTHON_CMD=%%D\python.exe"
    )
)
if not defined PYTHON_CMD (
    for /d %%D in ("%ProgramFiles(x86)%\Python*") do (
        if exist "%%D\python.exe" set "PYTHON_CMD=%%D\python.exe"
    )
)

:: Si Python est trouve, executer patch.py --restore
if defined PYTHON_CMD (
    "%PYTHON_CMD%" patch.py --restore
    echo.
    pause
    exit /b %ERRORLEVEL%
)

:: Solution de secours directe : restauration sans Python (copie directe du .bak)
echo [*] Python non detecte dans le PATH, restauration directe via sauvegarde .bak...
set "DEFAULT_PCK=C:\Program Files (x86)\Steam\steamapps\common\Antivirus Survivors 2003 Professional\AVS03Pro.pck"
set "DEFAULT_BAK=C:\Program Files (x86)\Steam\steamapps\common\Antivirus Survivors 2003 Professional\AVS03Pro.pck.bak"

if exist "%DEFAULT_BAK%" (
    echo [+] Sauvegarde detectee : %DEFAULT_BAK%
    echo [*] Copie de la sauvegarde vers AVS03Pro.pck...
    copy /y "%DEFAULT_BAK%" "%DEFAULT_PCK%" >nul
    if %ERRORLEVEL% equ 0 (
        echo.
        echo [SUCCES] Le jeu original a ete restaure avec succes !
    ) else (
        echo.
        echo [ERREUR] Impossible d'ecraser le fichier PCK. Assurez-vous que le jeu est ferme.
    )
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [ERREUR] Impossible de restaurer automatiquement le jeu.
echo Vous pouvez verifier l'integrite des fichiers du jeu via Steam :
echo (Clic droit sur le jeu dans Steam ^> Proprietes ^> Fichiers installes ^> Verifier l'integrite).
echo.
pause
exit /b 1
