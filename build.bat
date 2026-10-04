@echo off
title Antivirus Survivors 2003 - Dev Build
cd /d "%~dp0"
python build.py
if %ERRORLEVEL% neq 0 pause
