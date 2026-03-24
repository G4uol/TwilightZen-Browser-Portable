#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- DEPENDENCY CHECK ---
deps=("curl" "jq" "tar" "xz" "zip")
for dep in "${deps[@]}"; do
    if ! command_exists "$dep"; then
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y "$dep"
        fi
    fi
done

# --- PLATFORM CHOICE ---
# If GITHUB_ACTIONS exists, we default to '3' (Both). Otherwise, we ask you.
if [ "$GITHUB_ACTIONS" == "true" ]; then
    platform_choice="3"
    echo "Running in GitHub Actions: Defaulting to 'Both' (Linux & Windows)"
else
    echo "Select the platform(s) for the portable build:"
    echo "1) Linux"
    echo "2) Windows"
    echo "3) Both"
    read -p "Enter choice (1, 2, or 3): " platform_choice
fi

# Set the directory name
case $platform_choice in
    1) output_dir="zen-linux-portable" ;;
    2) output_dir="zen-windows-portable" ;;
    *) output_dir="zen-portable" ;;
esac

# --- BUILD LOGIC ---
mkdir -p "$output_dir/data"
for i in {1..5}; do mkdir -p "$output_dir/data/profile$i"; done
BASE_DIR=$(pwd)
cd "$output_dir"

# Handle Linux
if [ "$platform_choice" == "1" ] || [ "$platform_choice" == "3" ]; then
    mkdir -p app/lin
    curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r '.assets[] | select(.name | contains("linux-x86_64.tar.xz")) | .browser_download_url' | xargs curl -LO
    tar -xJvf zen.linux-x86_64.tar.xz -C app/lin --strip-components=1
    cat <<EOF > Zen-Portable-Linux.sh
#!/bin/bash
DIR="\$(dirname "\$(readlink -f "\$0")")"
"\$DIR/app/lin/zen" --profile "\$DIR/data/profile1" --no-remote
EOF
    chmod +x Zen-Portable-Linux.sh app/lin/zen
fi

# Handle Windows
if [ "$platform_choice" == "2" ] || [ "$platform_choice" == "3" ]; then
    mkdir -p app/win
    curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r '.assets[] | select(.name == "zen.installer.exe") | .browser_download_url' | xargs curl -LO
    7z x zen.installer.exe -oapp/win/temp
    mv app/win/temp/core/* app/win/
    rm -rf app/win/temp
    cat <<EOF > Zen-Portable-Windows.bat
@echo off
set "ROOT=%~dp0"
start "" "%ROOT%app\win\zen.exe" -profile "%ROOT%data\profile1" -no-remote
EOF
fi

# --- CLEANUP & ZIP ---
rm -f zen.installer.exe zen.linux-x86_64.tar.xz
cd "$BASE_DIR"
zip -r "$output_dir.zip" "$output_dir"
echo "Build Complete: $output_dir.zip"
