@echo off
setlocal

set "owner=zigobuko"
set "repo=RLC_test"

powershell -NoProfile -Command " $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/%owner%/%repo%/releases/latest'; $asset = $r.assets | Where-Object { $_.name -like '*win*' -and $_.name -like '*.exe' } | Select-Object -First 1; if (-not $asset) { Write-Host 'No file for Windows found in the latest release.'; exit 0 }; $url = $asset.browser_download_url; $filename = [System.IO.Path]::GetFileName($url); $dest = Join-Path $env:USERPROFILE 'Downloads' | Join-Path -ChildPath $filename; if (Test-Path $dest) { Write-Host \"File already exists: $filename. Download canceled.\"; exit 0 }; Invoke-WebRequest -Uri $url -OutFile $dest; if (Test-Path $dest) { Write-Host \"Downloaded: $filename\"; Start-Process $dest } else { Write-Host \"Download failed.\" }"

:: Delete this script
del "%~f0"
