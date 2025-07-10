@echo off
setlocal

rem ** Configuration: GitHub repo owner and name **
set "owner=zigobuko"
set "repo=RLC_test"

rem ** Use PowerShell to get and download the latest Windows .exe release **
powershell -NoProfile -Command ^
  "$r = Invoke-RestMethod -Uri 'https://api.github.com/repos/%owner%/%repo%/releases/latest'; ^
   $asset = $r.assets | Where-Object { $_.name -like '*win*' -and $_.name -like '*.exe' } | Select-Object -First 1; ^
   if (-not $asset) { Write-Host 'No file for Windows found in the latest release.'; exit 0 } ^
   $download_url = $asset.browser_download_url; ^
   $filename = [System.IO.Path]::GetFileName($download_url); ^
   $dest = $env:USERPROFILE + '\\Downloads\\' + $filename; ^
   if (Test-Path $dest) { Write-Host ('File ' + $filename + ' already exists in Downloads. Download was canceled.'); exit 0 } ^
   Invoke-WebRequest -Uri $download_url -OutFile $dest; ^
   if (Test-Path $dest) { Write-Host ('File ' + $filename + ' has been downloaded successfully.'); Start-Process $dest }"
