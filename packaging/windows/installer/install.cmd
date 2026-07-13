@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-MNAnimat3D.ps1"
exit /b %errorlevel%
