#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    fs-uae          \
    fs-uae-launcher \
    libdecor        \
    python          \
    python-bottle   \
    python-lhafile

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
mkdir -p ./AppDir/bin
mv -v /usr/share/fs-uae-launcher/* ./AppDir/bin
