@echo off
title Antivirus Survivors 2003 - Debug Mode Installer
cd /d "%~dp0"

echo ========================================================
echo  Antivirus Survivors 2003 - Debug Mode Installer (Win)
echo ========================================================
echo.

where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    python patch.py %*
    goto finish
)

where py >nul 2>nul
if %ERRORLEVEL% equ 0 (
    py patch.py %*
    goto finish
)

echo [ERREUR] Python 3 est requis pour executer cet installeur.
echo Veuillez installer Python depuis https://www.python.org/
echo et cocher la case "Add Python to PATH".
echo.
pause
exit /b 1

:finish
if %ERRORLEVEL% neq 0 (
    echo.
    echo L'installation a rencontre une erreur.
    pause
) else (
    echo.
    echo Termine ! Vous pouvez lancer le jeu.
    timeout /t 5 >nul
)
