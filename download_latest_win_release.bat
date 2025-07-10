@echo off
setlocal enabledelayedexpansion

:: Define GitHub repository
set "owner=user_name"
set "repo=repo_name"

:: Create temp folder
set "temp_dir=%TEMP%\myAppDownload_%RANDOM%"
mkdir "%temp_dir%" >nul 2>&1

:: Get latest release JSON
curl -s https://api.github.com/repos/%owner%/%repo%/releases/latest > "%temp_dir%\release.json"

:: Extract download URL containing "win"
set "download_url="
for /f "usebackq tokens=*" %%A in ("%temp_dir%\release.json") do (
    echo %%A | findstr /C:"\"browser_download_url\"" | findstr /I "win" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:" %%B in ("%%A") do (
            set "line=%%B"
            set "line=!line:~1!"
            set "download_url=!line:\"",=!"
            goto :got_url
        )
    )
)

:got_url

:: Clean up JSON file
del "%temp_dir%\release.json"

:: Check if download URL was found
if not defined download_url (
    echo No file for Windows found in the latest release.
    rd /s /q "%temp_dir%"
    exit /b 1
)

:: Extract filename
for %%F in ("!download_url!") do set "filename=%%~nxF"

:: Check if file already exists in Downloads
set "downloads_dir=%USERPROFILE%\Downloads"
if exist "%downloads_dir%\%filename%" (
    echo File %filename% already exists in Downloads. Download was canceled.
    rd /s /q "%temp_dir%"
    exit /b 0
)

:: Download the file
echo Downloading %filename%...
curl -sSL "!download_url!" -o "%downloads_dir%\%filename%"

if exist "%downloads_dir%\%filename%" (
    echo File %filename% has been downloaded successfully.
    echo Launching...
    start "" "%downloads_dir%\%filename%"
) else (
    echo Download failed.
)

:: Cleanup
rd /s /q "%temp_dir%"

:: Self-delete the script
start "" cmd /c del "%~f0"

exit /b
