#!/bin/bash

# Define GitHub repository owner and name
owner="zigobuko"
repo="RLC_test"
os_arch="macos-silicon"
pass=$1

# Create temp folder
temp_folder=$(mktemp -d)

# Get the latest release information
release_info=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest")

# Extract download URL for the zip file containing "macos-silicon" in its name
download_url=$(echo "$release_info" | grep -o '"browser_download_url": ".*$os_arch.*\.zip"' | cut -d '"' -f 4)

# Check if download URL is empty (i.e., if no matching zip file was found)
if [ -z "$download_url" ]; then
    echo "No zip file containing '$os_arch' in its name found in the latest release."
    exit 1
fi

# Extract file name from the download URL
filename=$(basename "$download_url")

# Download the zip file to the temp folder within the Downloads folder
curl -sSL "$download_url" -o "$temp_folder/$filename"

# Unzip the downloaded file to the temp folder
unzip -q -P $1 -d "$temp_folder" "$temp_folder/$filename"

# Remove the downloaded zip file
rm "$temp_folder/$filename"

# Find the file with ".app" extension in the temp folder
app_file=$(find "$temp_folder" -type d -name "*.app")

if [ -z "$app_file" ]; then
    echo "No .app file found in the downloaded zip."
    rm -rf "$temp_folder"
    exit 1
fi

# Check if the same file exists in the Downloads folder
if [ -e ~/Downloads/"$(basename "$app_file")" ]; then
    echo "File $(basename "$app_file") already exists in Downloads."
    # Delete the temp folder
    rm -rf "$temp_folder"
    exit
else
    # Move the .app file from temp folder to Downloads folder
    mv "$app_file" ~/Downloads/
fi

# Delete the temp folder
rm -rf "$temp_folder"

echo "Downloaded and extracted successfully."
