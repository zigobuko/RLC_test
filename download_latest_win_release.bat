@echo off
setlocal enabledelayedexpansion

:: Set GitHub repository info
set "OWNER=zigobuko"
set "REPO=RLC_test"

:: File for storing JSON response
set "TEMP_FILE=%TEMP%\latest_release.json"

:: Download latest release info
powershell -Command "(Invoke-WebRequest -Uri https://api.github.com/repos/%OWNER%/%REPO%/releases/latest -UseBasicParsing).Content" > "%TEMP_FILE%"

:: Look for the download URL of a Windows .exe (with 'win' in name)
set "download_url="
for /f "tokens=*" %%A in ('findstr /i "browser_download_url" "%TEMP_FILE%" ^| findstr /i "win" ^| findstr /i ".exe"') do (
    set "line=%%A"
    for /f "tokens=2 delims=:" %%B in ("!line!") do (
        set "url_part=%%B"
        set "url=!url_part:~2,-2!"
        set "download_url=!url!"
    )
)

:: Check if download URL was found
if not defined download_url (
    echo No file for Windows found in the latest release.
    del "%TEMP_FILE%" >nul 2>&1
    timeout /t 5 >nul
    exit /b 1
)

:: Extract filename from URL
for %%A in ("%download_url%") do set "filename=%%~nxA"
set "dest=%USERPROFILE%\Downloads\%filename%"

:: Check if file already exists
if exist "%dest%" (
    echo File %filename% already exists in Downloads. Download was canceled.
    del "%TEMP_FILE%" >nul 2>&1
    timeout /t 5 >nul
    exit /b 0
)

:: Download the file
echo Downloading %filename%...
powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%dest%'"

:: Confirm download
if exist "%dest%" (
    echo File %filename% has been downloaded successfully.
) else (
    echo Failed to download the file.
    del "%TEMP_FILE%" >nul 2>&1
    timeout /t 5 >nul
    exit /b 1
)

:: Clean up temp JSON file
del "%TEMP_FILE%" >nul 2>&1

:: Open the downloaded SFX .exe file
start "" "%dest%"

:: Delete this script after short delay to allow start command to execute
timeout /t 2 >nul
del "%~f0"

exit /b 0