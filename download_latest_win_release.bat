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

:: Extract download URL for Windows (.exe containing "win")
set "download_url="
for /f "tokens=2 delims=:," %%A in ('findstr /C:"\"browser_download_url\":" "%temp_dir%\release.json" ^| findstr /I "win"') do (
    set "url=%%~A"
    set "url=!url:~1,-1!" 
    set "download_url=!url!"
)

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

exit /b
