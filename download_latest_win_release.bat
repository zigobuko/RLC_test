@echo off
setlocal enabledelayedexpansion

:: GitHub repo
set "owner=zigobuko"
set "repo=RLC_test"

echo Fetching latest release info...

:: Get latest release info via PowerShell and extract the download URL
for /f "usebackq delims=" %%A in (`powershell -Command ^
    "$r = Invoke-RestMethod -Uri 'https://api.github.com/repos/%owner%/%repo%/releases/latest'; ^
    $url = $r.assets | Where-Object { $_.name -like '*win*' -and $_.name -like '*.exe' } | Select-Object -ExpandProperty browser_download_url; ^
    if (!$url) { Write-Output 'ERROR' } else { Write-Output $url }"`) do (
    set "download_url=%%A"
)

if "%download_url%"=="ERROR" (
    echo No file for Windows found in the latest release.
    exit /b 1
)

:: Get the filename
for %%F in ("%download_url%") do set "filename=%%~nxF"
set "target_path=%USERPROFILE%\Downloads\%filename%"

:: Check if file already exists
if exist "%target_path%" (
    echo File %filename% already exists in Downloads. Download was canceled.
    exit /b 0
)

echo Downloading %filename%...

:: Download the file using PowerShell
powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%target_path%'"

if not exist "%target_path%" (
    echo Failed to download the file.
    exit /b 1
)

echo File %filename% has been downloaded successfully.

:: Run the downloaded .exe (password will be entered manually by user)
start "" "%target_path%"

:: Delete this script
del "%~f0"
