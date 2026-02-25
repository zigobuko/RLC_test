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
if errorlevel 1 (
    echo ERROR: Download failed.
    del "!target_file!" 2>nul
    rd /s /q "%temp_dir%"
    exit /b 1
)
if not exist "!target_file!" (
    echo ERROR: Downloaded file not found.
    rd /s /q "%temp_dir%"
    exit /b 1
)

:: ---------------------------------------------------
set "sevenzip_path="

for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\7-Zip" /v Path 2^>nul') do (
    set "sevenzip_path=%%B"
)

if defined sevenzip_path set "sevenzip_path=%sevenzip_path%\7z.exe"

if not exist "%sevenzip_path%" set "sevenzip_path="
:: ---------------------------------------------------

:: Check and process
if exist "!target_file!" (
    echo Downloaded successfully.

    if exist "!sevenzip_path!" (
        echo 7-Zip found at: !sevenzip_path!
        echo Extracting archive...
    
        :: Create extraction folder based on archive name (without extension)
        for %%F in ("!filename!") do set "archive_name=%%~nF"
        set "extract_dir=%downloads_dir%\!archive_name!"
        mkdir "!extract_dir!" >nul 2>&1
    
        :: Extract archive into that folder
        if defined archive_password (
            "!sevenzip_path!" x "!target_file!" -p"!archive_password!" -o"!extract_dir!" -y -bso0
        ) else (
            "!sevenzip_path!" x "!target_file!" -o"!extract_dir!" -y
        )
    
        if errorlevel 1 (
            echo ERROR: Extraction failed. Possible causes: wrong password or corrupt archive.
            rd /s /q "%extract_dir%"
            rd /s /q "%temp_dir%"
            exit /b 1
        )
    
        echo Extraction complete.
    
        :: Detect the only top-level folder inside extract_dir
        set "main_folder="
        for /f "delims=" %%D in ('dir "!extract_dir!" /ad /b 2^>nul') do (
            if not defined main_folder set "main_folder=%%D"
        )
        if not defined main_folder (
            echo ERROR: No folder found inside archive.
            rd /s /q "!extract_dir!"
            rd /s /q "%temp_dir%"
            exit /b 1
        )
    
        :: Update Date Modified to current time
        powershell -command "(Get-Item '!extract_dir!\!main_folder!').LastWriteTime = Get-Date"
    
        :: Move folder to Downloads
        move "!extract_dir!\!main_folder!" "!downloads_dir!\" >nul
        if errorlevel 1 (
            echo ERROR: Failed to move folder.
            rd /s /q "!extract_dir!"
            rd /s /q "%temp_dir%"
            exit /b 1
        )
    
        :: Delete temporary extraction folder
        rd /s /q "!extract_dir!"

        :: Delete the downloaded archive (optional message)
        del "!target_file!" >nul 2>&1

    ) else (
        :: 7-Zip not found → run SFX
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

echo Done.

:: Self-delete this script
start "" cmd /c del "%~f0"

exit /b










