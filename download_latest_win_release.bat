@echo off
setlocal enabledelayedexpansion

:: Define GitHub repository
set "owner=zigobuko"
set "repo=RLC_test"

:: Create temp folder
set "temp_dir=%TEMP%\myAppDownload_%RANDOM%"
mkdir "%temp_dir%" >nul 2>&1

:: Download latest release info
curl -s https://api.github.com/repos/%owner%/%repo%/releases/latest > "%temp_dir%\release.json"

:: Find first .exe containing "win"
set "download_url="
for /f "delims=" %%A in ('findstr /i "browser_download_url.*win.*\.exe" "%temp_dir%\release.json"') do (
    set "line=%%A"
    set "line=!line:*https://=https://!"
    set "download_url=!line:"=!"
    goto found_url
)

:found_url

:: Clean up JSON
del "%temp_dir%\release.json"

:: Check if download URL was found
if not defined download_url (
    echo No Windows EXE found in latest release.
    rd /s /q "%temp_dir%"
    exit /b 1
)

:: Extract filename
for %%F in ("!download_url!") do set "filename=%%~nxF"

:: Target path
set "downloads_dir=%USERPROFILE%\Downloads"
set "target_file=%downloads_dir%\%filename%"

:: Check if file exists
if exist "!target_file!" (
    echo File already exists in Downloads: !filename!
    rd /s /q "%temp_dir%"
    exit /b 0
)

:: Download EXE
echo Downloading !filename!...
curl -sSL "!download_url!" -o "!target_file!"

:: Check and launch
if exist "!target_file!" (
    echo Downloaded successfully.
    echo Launching...
    pushd "%downloads_dir%"
    start "" "%filename%"
    popd
) else (
    echo Download failed.
)

:: Cleanup
rd /s /q "%temp_dir%"

:: Self-delete this script
start "" cmd /c del "%~f0"

exit /b
