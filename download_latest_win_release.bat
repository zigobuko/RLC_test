@echo off
setlocal enabledelayedexpansion

:: ---------------------------------------------------
:: Get password from first argument (for SFX extraction)
set "archive_password=%~1"
:: ---------------------------------------------------

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

:: ---------------------------------------------------
:: Detect 7-Zip installation path (Windows 10/11)
set "sevenzip_path="

:: Check 64-bit registry
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\7-Zip" /v Path 2^>nul') do (
    set "sevenzip_path=%%B\7z.exe"
)

:: If not found, check 32-bit 7-Zip on 64-bit Windows
if not defined sevenzip_path (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\7-Zip" /v Path 2^>nul') do (
        set "sevenzip_path=%%B\7z.exe"
    )
)

:: ---------------------------------------------------

:: Check and process
if exist "!target_file!" (
    echo Downloaded successfully.

    if defined sevenzip_path (

        echo 7-Zip found at: !sevenzip_path!
        echo Detecting main folder inside archive...

        :: ---------------------------------------------------
        :: Detect main folder inside archive BEFORE extraction
        set "main_folder="

        if defined archive_password (
            for /f "usebackq delims=" %%A in (`!sevenzip_path! l -slt -p"!archive_password!" "!target_file!" ^| findstr /i "Path ="`) do (
                if not defined main_folder (
                    set "line=%%A"
                    set "line=!line:*Path =!"
                    for /f "delims=\ tokens=1" %%B in ("!line!") do set "main_folder=%%B"
                )
            )
        ) else (
            for /f "usebackq delims=" %%A in (`!sevenzip_path! l -slt "!target_file!" ^| findstr /i "Path ="`) do (
                if not defined main_folder (
                    set "line=%%A"
                    set "line=!line:*Path =!"
                    for /f "delims=\ tokens=1" %%B in ("!line!") do set "main_folder=%%B"
                )
            )
        )
        :: ---------------------------------------------------

        echo Extracting archive...

        if defined archive_password (
            "!sevenzip_path!" x "!target_file!" -p"!archive_password!" -o"%downloads_dir%" -y -bso0
        ) else (
            "!sevenzip_path!" x "!target_file!" -o"%downloads_dir%" -y
        )

        if !ERRORLEVEL! equ 0 (
            echo Extraction complete.

            if defined main_folder (
                powershell -Command "(Get-Item '%downloads_dir%\!main_folder!').LastWriteTime = Get-Date"
            )

        ) else (
            echo ERROR: Extraction failed.
            rd /s /q "%temp_dir%"
            exit /b 1
        )

    ) else (
        echo 7-Zip not found. Launching SFX normally...
        pushd "%downloads_dir%"
        start "" "%filename%"
        popd
    )
) else (
    echo Download failed.
)

:: Cleanup
rd /s /q "%temp_dir%"

:: Self-delete this script
start "" cmd /c del "%~f0"

exit /b






