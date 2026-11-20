@echo off
chcp 65001 >nul
cd /d "%~dp0"
where python >nul 2>&1
if %errorlevel%==0 (
    echo Starting IGA Story Studio live sync server...
    python tools\story_studio\server.py
) else (
    echo Python not found. Opening offline Story Studio in default browser...
    start "" "tools\story_studio\index.html"
)
