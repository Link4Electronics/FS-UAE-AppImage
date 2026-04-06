#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    fs-uae   	 \
    libdecor 	 \
	python	 	 \
	python-pyqt6

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
cd ./AppDir/bin/Linux/${xz_arch}/_internal
rm -rf pillow.libs
KEEP_FILES="base_library.zip libbrotlicommon.so.1 libbrotlidec.so.1 libgmodule-2.0.so.0 libgthread-2.0.so.0 libk5crypto.so.3 libmd.so.0 libpython3.12.so.1.0 lzhlib.cpython-312-x86_64-linux-gnu.so"
for item in *; do
    # Skip directories
    if [ -d "$item" ]; then
        continue
    fi
    if [[ ! " $KEEP_FILES " =~ " $item " ]]; then
        rm "$item"
    fi
done
