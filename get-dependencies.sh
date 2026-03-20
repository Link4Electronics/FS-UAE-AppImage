#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm 	\
    fs-uae   	   			\
	glu		       			\
	kvantum       			\
	libwebp		   			\
    lxqt-qtplugin 			\
	openal 	       			\
    python-pillow  			\
    python-pyqt6   			\
	qt6-multimedia 			\
	qt6-svg		   			\
	qt6-wayland    		    \
	qt6-xcb-private-headers \
	qt6ct					\
	uv

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

echo "Building FS-UAE Launcher..."
echo "---------------------------------------------------------------"
REPO=https://github.com/FrodeSolheim/fs-uae-launcher
VERSION="${LAUNCHER_VERSION:-$(git ls-remote --tags --sort=-v:refname "$REPO" \
	| sed 's|.*refs/tags/||; s/\^{}//' \
	| grep -E '^v[0-9]+(\.[0-9]+)+$' \
	| head -n1)}"
VERSION="${VERSION#v}"
git clone --branch "v$VERSION" --single-branch --depth 1 "$REPO" ./fs-uae-launcher

mkdir -p ./AppDir/bin ./AppDir/shared/bin
cd ./fs-uae-launcher
# python -m build all -> bootstrap, make (translations), PyInstaller, bundle, tar.xz
uv run python -m build all

case "$ARCH" in
	x86_64)  launcher_arch=x86-64;;
	aarch64) launcher_arch=ARM64;;
esac

mv -v ./build/_build/FS-UAE-Launcher/Linux/$launcher_arch/fs-uae-launcher \
	./build/_build/FS-UAE-Launcher/Linux/$launcher_arch/_internal ../AppDir/bin
mv -v ./build/_build/FS-UAE-Launcher/Resources \
	./build/_build/FS-UAE-Launcher/Locale ../AppDir
cd ../
ln -sfn ../../bin/_internal ./AppDir/shared/bin/_internal
