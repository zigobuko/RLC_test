@echo off
setlocal

set "owner=zigobuko"
set "repo=RLC_test"
set "filename="

:: Use PowerShell to get the download URL of the latest Windows .exe release
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$r = Invoke-RestMethod -Uri 'https://api.github.com/repos/%owner%/%repo%/releases/latest'; ^
     $asset = $r.assets | Where-Object { $_.name -like '*win*' -and $_.name -like '*.exe' } | Select-Object -First 1; ^
     if (-not $asset) { Write-Output 'ERROR_NO_FILE' } else { Write-Output $asset.browser_download_url }" ^
`) do set "download_url=%%A"

:: Check if PowerShell failed to find the file
if "%download_url%"=="ERROR_NO_FILE" (
    echo No file for Windows found in the latest release.
    goto :EOF
)

:: Extract filename from URL
for %%F in ("%download_url%") do set "filename=%%~nxF"

:: Check if file already exists in Downloads folder
set "dest=%USERPROFILE%\Downloads\%filename%"
if exist "%dest%" (
    echo File %filename% already exists in Downloads. Download was canceled.
    goto :EOF
)

:: Download the file
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%dest%'"

if exist "%dest%" (
    echo File %filename% has been downloaded successfully.
) else (
    echo Failed to download the file.
    goto :EOF
)

:: Run the downloaded file (e.g., self-extracting archive)
start "" "%dest%"

:: Delete this script after launching
cd /d "%~dp0"
del "%~f0"
