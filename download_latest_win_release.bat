@echo off
setlocal EnableDelayedExpansion

:: Config
set "owner=zigobuko"
set "repo=RLC_test"
set "keyword=win"
set "ext=.exe"

:: Query latest release JSON
curl -s https://api.github.com/repos/%owner%/%repo%/releases/latest > "%TEMP%\release.json"

:: Parse JSON for the download URL of the Windows asset
set "download_url="
for /f "usebackq tokens=2 delims=: " %%A in (`findstr /i "browser_download_url" "%TEMP%\release.json" ^| findstr /i "%keyword%" ^| findstr /i "%ext%"`) do (
    set "line=%%A"
    set "line=!line:~1,-1!"      :: strip leading '"' and trailing '",'
    set "download_url=!line!"
)

:: Check if URL was found
if not defined download_url (
    echo No file for Windows found in the latest release.
    del "%TEMP%\release.json"
    goto :EOF
)

:: Extract filename from URL
for %%F in (!download_url!) do set "filename=%%~nxF"

:: Destination path in Downloads
set "dest=%USERPROFILE%\Downloads\%filename%"

:: If file exists, cancel download
if exist "%dest%" (
    echo File %filename% already exists in Downloads. Download was canceled.
    del "%TEMP%\release.json"
    goto :EOF
)

:: Download the file
echo Downloading %filename%...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '!download_url!' -OutFile '%dest%'"

:: Verify download
if not exist "%dest%" (
    echo Failed to download the file.
    del "%TEMP%\release.json"
    goto :EOF
)

:: Run the file
echo Launching %filename%...
start "" "%dest%"

:: Clean up
del "%TEMP%\release.json"
echo File %filename% has been downloaded successfully.

:: Self-delete this script
echo Deleting this script...
del "%~f0"&exit
exit /b
