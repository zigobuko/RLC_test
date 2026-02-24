param(
    [string]$archive_password
)

$owner = "zigobuko"
$repo = "RLC_test"

# Temp folder
$temp_dir = "$env:TEMP\myAppDownload_$((Get-Random))"
New-Item -ItemType Directory -Path $temp_dir -Force | Out-Null

# Download latest release metadata
$releaseJsonPath = "$temp_dir\release.json"
Invoke-WebRequest -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" `
    -OutFile $releaseJsonPath

# Parse JSON
$release = Get-Content $releaseJsonPath -Raw | ConvertFrom-Json

# Find first Windows EXE containing "win"
$download_url = ($release.assets |
    Where-Object { $_.browser_download_url -match "win.*\.exe" } |
    Select-Object -First 1).browser_download_url

Remove-Item $releaseJsonPath -Force -ErrorAction SilentlyContinue

if (-not $download_url) {
    Write-Host "No Windows EXE found in latest release."
    Remove-Item $temp_dir -Recurse -Force
    exit 1
}

# Filename + download path
$filename = [System.IO.Path]::GetFileName($download_url)
$downloads_dir = "$env:USERPROFILE\Downloads"
$target_file = Join-Path $downloads_dir $filename

# Check if file exists
if (Test-Path $target_file) {
    Write-Host "File already exists in Downloads: $filename"
    Remove-Item $temp_dir -Recurse -Force
    exit 0
}

# Download EXE
Write-Host "Downloading $filename..."
Invoke-WebRequest -Uri $download_url -OutFile $target_file

# Detect 7-Zip path
$sevenzip_path = $null

$reg_paths = @(
    "HKLM:\SOFTWARE\7-Zip",
    "HKLM:\SOFTWARE\WOW6432Node\7-Zip"
)

foreach ($path in $reg_paths) {
    try {
        $reg = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        if ($reg.Path) {
            $sevenzip_path = Join-Path $reg.Path "7z.exe"
            break
        }
    } catch {}
}

# Process file
if (Test-Path $target_file) {
    Write-Host "Downloaded successfully."

    if ($sevenzip_path -and (Test-Path $sevenzip_path)) {

        Write-Host "7-Zip found at: $sevenzip_path"
        Write-Host "Extracting archive..."

        if ($archive_password) {
            & $sevenzip_path x $target_file `
                -p$archive_password `
                -o$downloads_dir -y -bso0
        }
        else {
            & $sevenzip_path x $target_file `
                -o$downloads_dir -y
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extraction complete."
        }
        else {
            Write-Host "ERROR: Extraction failed. Possible incorrect password or corrupted archive."
            Remove-Item $temp_dir -Recurse -Force
            exit 1
        }

    }
    else {
        Write-Host "7-Zip not found. Launching SFX normally..."
        Start-Process $target_file
    }
}
else {
    Write-Host "Download failed."
}

# Cleanup
Remove-Item $temp_dir -Recurse -Force

# Self-delete (PowerShell trick)
$scriptPath = $MyInvocation.MyCommand.Path

Start-Process powershell -ArgumentList @"
-Command Start-Sleep 2; Remove-Item '$scriptPath'
"@ -WindowStyle Hidden
