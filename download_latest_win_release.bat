@echo off
setlocal EnableDelayedExpansion

:: Config
set "owner=zigobuko"
set "repo=RLC_test"

:: Get architecture-specific filename (if needed, adjust this logic)
set "keyword=win"
set "ext=.exe"

:: Query latest release info
curl -s https://api.github.com/repos/%owner%/%repo%/releases/latest > "%TEMP%\release.json"

:: Parse the download URL
set "download_url="
for /f "usebackq tokens=2 delims=: " %%A in (`findstr /i "browser_download_url" "%TEMP%\release.json" ^| findstr /i "%keyword%" ^| findstr /i "%ext%"`) do (
    set "line=%%A"
    set "line=!line:~1,-1!"  :: strip quotes and comma
    set "download_url=!line!"
)

:: Check if URL was found
if not defined download_url (
    echo No file for Windows found in the latest release.
    del "%TEMP%\release.json"
    goto :eof
)

:: Extract filename from URL
for %%F in (!download_url!) do set "filename=%%~nxF"

:: Check if file already exists in Downloads
set "dest=%USERPROFILE%\Downloads\%filename%"
if exist "%dest%" (
    echo File %filename% already exists in Downloads. Download was canceled.
    del "%TEMP%\release.json"
    goto :eof
)

:: Download the file
echo Downloading %filename%...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '!download_url!' -OutFile '%dest%'"

:: Check if download succeeded
if not exist "%dest%" (
    echo Failed to download the file.
    del "%TEMP%\release.json"
    goto :eof
)

:: Run the file
echo Launching %filename%...
start "" "%dest%"

:: Clean up
del "%TEMP%\release.json"
echo File %filename% has been downloaded successfully.

:: Self-delete the script
echo Deleting this script...
start "" cmd /c del "%~f0"
exit /b
