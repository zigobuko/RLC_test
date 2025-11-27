#!/bin/bash

# Define GitHub repository owner and name
owner="zigobuko"
repo="RLC_test"
pass=$1

# Detect architecture (Silicon / Intel)
if [[ "$(uname -m)" == "arm64" ]]; then
    arch_name="mac-silicon"
    echo "Downloading mac-silicon version."
else
    arch_name="mac-intel"
    echo "Downloading mac-intel version."
fi

# Create temp folder
temp_folder=$(mktemp -d)

# Get the latest release information
release_info=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest")

# Extract download URL for the DMG file containing desired architecture in its name
download_url=$(echo "$release_info" \
  | grep '"browser_download_url":' \
  | grep "$arch_name" \
  | grep ".dmg" \
  | cut -d '"' -f 4)

# Check if download URL is empty (i.e., if no matching DMG file was found)
if [ -z "$download_url" ]; then
    echo "No DMG file for '$arch_name' found in the latest release."
    exit 1
fi

# Extract file name from the download URL
filename=$(basename "$download_url")

# Download the DMG file to the temp folder
curl -sSL "$download_url" -o "$temp_folder/$filename"

# Mount the password-protected DMG (no Finder window)
mount_point="$temp_folder/mount"
mkdir -p "$mount_point"
if ! echo -n "$pass" | hdiutil attach "$temp_folder/$filename" -stdinpass -nobrowse -mountpoint "$mount_point" >/dev/null; then
    echo "Failed to mount DMG. Check password or file integrity."
    rm -rf "$temp_folder"
    exit 1
fi

# Find the .app file inside the mounted DMG
app_file=$(find "$mount_point" -type d -name "*.app" | head -n 1)

if [ -z "$app_file" ]; then
    echo "No .app file found in the mounted DMG."
    hdiutil detach "$mount_point" >/dev/null
    rm -rf "$temp_folder"
    exit 1
fi

# Check if the same file exists in the Downloads folder
if [ -e ~/Downloads/"$(basename "$app_file")" ]; then
    echo "File $(basename "$app_file") already exists in Downloads."
else
    # Copy the .app file to Downloads
    cp -R "$app_file" ~/Downloads/
fi

# Unmount the DMG
hdiutil detach "$mount_point" >/dev/null

# Delete the temp folder
rm -rf "$temp_folder"

echo "Downloaded and extracted successfully."
