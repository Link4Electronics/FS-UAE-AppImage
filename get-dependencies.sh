#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    fs-uae   \
    libdecor \
	python	 \
	qt6-base

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
XZ_LINK=$(wget --retry-connrefused --tries=30 \
	  https://api.github.com/repos/FrodeSolheim/fs-uae-launcher/releases -O - \
      | sed 's/[()",{} ]/\n/g' | grep -o -m 1 "https.*releases.*Linux_$xz_arch.*tar.xz")
wget "$XZ_LINK" -O /tmp/app.tar.xz
tar -xvf /tmp/app.tar.xz -C ./AppDir/bin --strip-components=1
