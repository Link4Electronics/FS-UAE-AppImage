#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    fs-uae   \
    libdecor

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
mkdir -p ./AppDir/bin
echo "Geting FS-UAE Launcher..."
echo "---------------------------------------------------------------"
case "$ARCH" in # they use x86-64 and ARM64 for the deb links
	x86_64)  xz_arch=x86-64;;
	aarch64) xz_arch=ARM64;;
esac
wget https://github.com/FrodeSolheim/fs-uae-launcher/releases/download/v3.2.35/FS-UAE-Launcher_3.2.35_Linux_${xz_arch}.tar.xz

mv -v /usr/share/fs-uae-launcher/* ./AppDir/bin
