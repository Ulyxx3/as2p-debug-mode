@echo off
title Antivirus Survivors 2003 - Debug Mode Installer
cd /d "%~dp0"

echo ========================================================
echo  Antivirus Survivors 2003 - Debug Mode Installer (Win)
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

if not defined PYTHON_CMD (
    echo [ERREUR] Python 3 est requis pour executer cet installeur.
    echo Veuillez installer Python depuis https://www.python.org/
    echo et penser a cocher la case "Add Python to PATH".
    echo.
    pause
    exit /b 1
)

"%PYTHON_CMD%" patch.py %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo L'installation a rencontre une erreur.
    pause
) else (
    echo.
    echo Termine ! Vous pouvez lancer le jeu.
    pause
)
