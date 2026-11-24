@echo off
rem Fallout 1 (Steam) - Simplified Chinese + hi-res patch installer.
rem Right next to this file is "files\" (what gets copied), "tools\" (the
rem PowerShell scripts) and "backup\" (created on the first install).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install.ps1" %*
echo.
pause
