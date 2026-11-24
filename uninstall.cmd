@echo off
rem Fallout 1 (Steam) - undo the Chinese + hi-res patch install.
rem Restores the files that install.cmd overwrote (from backup\) and removes the
rem files it added.  Use -KeepShortcuts to leave the desktop shortcuts alone.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\uninstall.ps1" %*
echo.
pause
