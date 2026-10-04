@echo off
title Antivirus Survivors 2003 - Dev Build
cd /d "%~dp0"

set "PYTHON_CMD="

for /f "delims=" %%I in ('where python 2^>nul') do (
    if exist "%%I" if not defined PYTHON_CMD set "PYTHON_CMD=%%I"
)
for /f "delims=" %%I in ('where py 2^>nul') do (
    if exist "%%I" if not defined PYTHON_CMD set "PYTHON_CMD=%%I"
)
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
    echo [ERREUR] Python 3 introuvable.
    pause
    exit /b 1
)

"%PYTHON_CMD%" build.py %*
if %ERRORLEVEL% neq 0 pause
