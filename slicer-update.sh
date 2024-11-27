# slicer script downloads the requested version of the slicer binary from the website and installs it in the specified directory
# versions: "stable" or "latest"
# directory: the directory where the slicer binary will be installed
# Example: slicer-update.sh stable /opt/slicer

# how to get the download link for the slicer binary:
# https://download.slicer.org/download?os=<OS>&stability=<stability>
# <OS> can be macosx, win, linux
# <stability> can be release or nightly

#!/bin/bash

set -e

VERSION=$1
if [ "$VERSION" == "stable" ]; then
    VERSION="release"
fi
INSTALL_DIR=$2
INSTALL_DIR=${INSTALL_DIR%/}

if [[ -z "$VERSION" || -z "$INSTALL_DIR" ]]; then
    echo "Usage: $0 <stable|nightly> <install_directory>"
    exit 1
fi

OS=$(uname | tr '[:upper:]' '[:lower:]')

URL="https://download.slicer.org/download?os=${OS}&stability=${VERSION}"
echo "Downloading Slicer from $URL"

download_and_install_linux() {
    # first check if the user has write access to the install dir
    if [ ! -w "$INSTALL_DIR" ]; then
        echo "You do not have write access to $INSTALL_DIR. Start the installer with sudo."
        exit 1
    fi

    # dont download if a file with the expected checksum already exists
    if [ -f "slicer-$VERSION.tar.gz" ]; then
        if [ "$(sha512sum "slicer-$VERSION.tar.gz" | cut -d ' ' -f1)" == "$CHECKSUM" ]; then
            echo "Slicer already downloaded"
        fi
    else    
        wget -O slicer-$VERSION.tar.gz "$URL"
    fi

    #check the downloaded file
    FILECHECKSUM=$(sha512sum "slicer-$VERSION.tar.gz" | cut -d ' ' -f1)
    if [ "$(sha512sum "slicer-$VERSION.tar.gz" | cut -d ' ' -f1)" != "$CHECKSUM" ]; then
        echo "Checksums do not match !"
        echo "    Downloaded: $FILECHECKSUM"
        echo "    Expected:   $CHECKSUM"
        echo "What should we do? Retry/Abord/Ignore [r/a/i]"
        read -r response
        case $response in
            r)
                rm slicer-$VERSION.tar.gz
                download_and_install_linux
                ;;
            a)
                exit 1
                ;;
            i)
                echo "Ignoring checksum mismatch"
                ;;
        esac
    fi
    
    SLICER_DIR=$(tar -tf slicer-$VERSION.tar.gz | head -1 | cut -f1 -d"/")
    

    mkdir -p "$INSTALL_DIR"
    tar -xzf slicer-$VERSION.tar.gz -C "$INSTALL_DIR"
    ln -sf "$INSTALL_DIR/$SLICER_DIR/Slicer" "$INSTALL_DIR/Slicer"
    if [ $(id -u) == 0 ]; then
        mkdir -p "$INSTALL_DIR/$SLICER_DIR/slicer.org/Extensions-32448"
        chmod -R 777 "$INSTALL_DIR/$SLICER_DIR/slicer.org"
    fi
    echo "Slicer installed successfully in $INSTALL_DIR,"
    echo "    binary symlinked to $INSTALL_DIR/Slicer"
    echo "Do you want to delete the downloaded archive? [y/n]"
    read -r response
    if [ "$response" != "n" ]; then
        rm slicer-$VERSION.tar.gz
    fi
    echo "Do you want to create a desktop file? [y/n]"
    read -r response
    if [ "$response" != "n" ]; then
        create_desktop_file_linux
    fi
    
}

download_and_install_macosx() {
    # !! UNTESTED !!
    # dont download if a file with the expected checksum already exists
    if [ -f "slicer.dmg" ]; then
        if [ "$(sha512sum "slicer.dmg" | cut -d ' ' -f1)" == "$CHECKSUM" ]; then
            echo "Slicer already downloaded"
            return
        fi
    fi
    curl -L -o slicer.dmg "$URL"
    #check the downloaded file
    if [ "$(sha512sum "slicer.dmg" | cut -d ' ' -f1)" != "$CHECKSUM" ]; then
        echo "Checksum mismatch"
        exit 1
    fi
    hdiutil attach slicer.dmg -mountpoint /Volumes/Slicer
    cp -R /Volumes/Slicer/Slicer.app "$INSTALL_DIR"
    ln -sf "$INSTALL_DIR/Slicer.app/Contents/MacOS/Slicer" "$INSTALL_DIR/Slicer"
    hdiutil detach /Volumes/Slicer
    rm slicer.dmg
}

download_and_install_win() {
    echo "Windows installation is not supported by this script."
    exit 1
}

# get the checksum from the website (https://download.slicer.org/#checksums)
# see https://regex101.com/r/DOwjcB/1 for example (2024-10-03) and regex
get_checksum() {
    case "$VERSION" in
        release)
            CHANNEL="//" # this is a bit a trick. The channel is empty for the rease version, so we look for //
            ;;
        nightly)
            CHANNEL="preview"
            ;;
        *)
            echo "Unsupported version: $VERSION"
            exit 1
            ;;
    esac
    CHECKSUM=$( curl -s https://download.slicer.org/#checksums |\
                python -c "import sys,re;print('\n'.join(['/'.join(i) for i in re.findall(r'(?P<platform>Linux|macOS|Windows) ?(?:\((?P<channel>\w+)\))?[\/td\W]+>(?P<checksum>[a-f0-9]+)', sys.stdin.read())]))"|\
                grep $(uname) | grep $CHANNEL | cut -d '/' -f3)
    echo $CHECKSUM
}

create_desktop_file_linux() {
    if [ ! -f "/opt/slicer/3D-Slicer-Mark.svg" ]; then
        wget https://raw.githubusercontent.com/Slicer/Slicer/refs/heads/main/Docs/_static/images/3D-Slicer-Mark.svg -O /opt/slicer/3D-Slicer-Mark.svg
    fi
    cat <<EOF > /usr/share/applications/Slicer-${VERSION}.desktop
[Desktop Entry]

# The type as listed above
Type=Application

# The version of the desktop entry specification to which this file complies
Version=5.3.0

# The name of the application
Name=3D Slicer (${VERSION})

# A comment which can/will be used as a tooltip
Comment=Medical Image processing/visualization platform

# The path to the folder in which the executable is run
Path=/home

# The executable of the application, possibly with arguments.
Exec=$INSTALL_DIR/$SLICER_DIR/Slicer

# The name of the icon that will be used to display this entry
Icon=/opt/slicer/3D-Slicer-Mark.svg

# Describes whether this application needs to be run in a terminal or not
Terminal=false

# Describes the categories in which this entry should be shown
Categories=Education;Science;
EOF
}

CHECKSUM=$(get_checksum)

case "$OS" in
    linux)
        download_and_install_linux
        ;;
    darwin)
        download_and_install_macosx
        ;;
    msys*|cygwin*|mingw*)
        download_and_install_win
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac
echo "Done"