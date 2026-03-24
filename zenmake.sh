#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install dependencies
echo "Checking for required dependencies..."

deps=("curl" "jq" "tar" "xz" "zip")
for dep in "${deps[@]}"; do
    if ! command_exists "$dep"; then
        echo "$dep not found, installing..."
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y "$dep"
        elif command_exists yum; then
            sudo yum install -y "$dep"
        elif command_exists pacman; then
            sudo pacman -S --noconfirm "$dep"
        else
            echo "Error: Unable to install $dep, please install it manually."
            exit 1
        fi
    fi
done

# Special check for 7z (often named p7zip-full)
if ! command_exists 7z; then
    echo "7z not found, installing..."
    if command_exists apt-get; then
        sudo apt-get install -y p7zip-full
    else
        sudo yum install -y p7zip || sudo pacman -S --noconfirm p7zip
    fi
fi

# Prompt user for platform choice
echo "Select the platform(s) for the portable build:"
echo "1) Linux"
echo "2) Windows"
echo "3) Both"
read -p "Enter choice (1, 2, or 3): " platform_choice

# Set the directory name
case $platform_choice in
    1) output_dir="zen-linux-portable" ;;
    2) output_dir="zen-windows-portable" ;;
    *) output_dir="zen-portable" ;;
esac

# Set up directory structure
mkdir -p "$output_dir/data"
for i in {1..5}; do mkdir -p "$output_dir/data/profile$i"; done

# Change into the output directory
BASE_DIR=$(pwd)
cd "$output_dir"

# Handle Linux Build
if [ "$platform_choice" == "1" ] || [ "$platform_choice" == "3" ]; then
    mkdir -p app/lin
    echo "Downloading Latest Linux release..."
    curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r '.assets[] | select(.name | contains("linux-x86_64.tar.xz")) | .browser_download_url' | xargs curl -LO
    echo "Extracting Linux release..."
    tar -xJvf zen.linux-x86_64.tar.xz -C app/lin --strip-components=1
    
    echo "Creating Linux launcher..."
    cat <<EOF > Zen-Portable-Linux.sh
#!/bin/bash
DIR="\$(dirname "\$(readlink -f "\$0")")"
"\$DIR/app/lin/zen" --profile "\$DIR/data/profile1" --no-remote
EOF
    chmod +x Zen-Portable-Linux.sh app/lin/zen
fi

# Handle Windows Build
if [ "$platform_choice" == "2" ] || [ "$platform_choice" == "3" ]; then
    mkdir -p app/win
    echo "Downloading Latest Windows release..."
    curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r '.assets[] | select(.name == "zen.installer.exe") | .browser_download_url' | xargs curl -LO
    echo "Extracting Windows installer..."
    7z x zen.installer.exe -oapp/win/temp
    
    # Zen installer puts files in a 'core' folder; move them up to keep paths short
    mv app/win/temp/core/* app/win/
    rm -rf app/win/temp
    
    echo "Creating Windows launcher..."
    cat <<EOF > Zen-Portable-Windows.bat
@echo off
set "ROOT=%~dp0"
set "APP=%ROOT%app\win\zen.exe"
set "DATA=%ROOT%data\profile1"

if not exist "%DATA%" mkdir "%DATA%"

start "" "%APP%" -profile "%DATA%" -no-remote
EOF
fi

# Cleanup and Packaging
echo "Cleaning up..."
rm -f zen.installer.exe zen.linux-x86_64.tar.xz
cd "$BASE_DIR"

echo "Creating ZIP archive..."
zip -r "$output_dir.zip" "$output_dir"

# Uncomment the line below if you want the folder deleted after the zip is made
# rm -rf
