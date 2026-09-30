#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm 	\
    fs-uae   	   			\
	gettext					\
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
	qt6ct

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
if ! command -v uv > /dev/null 2>&1; then
	pacman -S --noconfirm --needed uv || true
fi
if ! command -v uv > /dev/null 2>&1; then
	echo "uv is not packaged on this system, installing the standalone uv..."
	curl -LsSf https://astral.sh/uv/install.sh | sh
	PATH="$HOME/.local/bin:$PATH"
	export PATH
fi

echo "Building FS-UAE Launcher..."
echo "---------------------------------------------------------------"
REPO=https://github.com/FrodeSolheim/fs-uae-launcher
# stable tags only, prereleases are tagged like v4.0.97-master / v4.0.53-dev
VERSION="${LAUNCHER_VERSION:-$(git ls-remote --tags --sort=-v:refname "$REPO" \
	| sed 's|.*refs/tags/||; s/\^{}//' \
	| grep -E '^v[0-9]+(\.[0-9]+)+$' \
	| head -n1)}"
VERSION="${VERSION#v}"
echo "Checking out fs-uae-launcher v$VERSION"
rm -rf ./fs-uae-launcher
git clone --branch "v$VERSION" --single-branch --depth 1 "$REPO" ./fs-uae-launcher

cd ./fs-uae-launcher
# uv installs the pinned toolchain (Python 3.12, PyQt6, PyInstaller) from uv.lock
uv sync
# python -m build all -> bootstrap, make (translations), PyInstaller, bundle, tar.xz
uv run python -m build all
cd ..

echo "Installing FS-UAE Launcher into AppDir..."
echo "---------------------------------------------------------------"
case "$ARCH" in
	x86_64)  launcher_arch=x86-64;;
	aarch64) launcher_arch=ARM64;;
	*) echo "ERROR: unsupported architecture: $ARCH"; exit 1;;
esac
BUNDLE=./fs-uae-launcher/build/_build/FS-UAE-Launcher

rm -rf ./AppDir/bin ./AppDir/Resources ./AppDir/Locale ./AppDir/shared/bin
mkdir -p ./AppDir/bin ./AppDir/shared/bin

# quick-sharun copies the launcher binary to AppDir/shared/bin and hardlinks a
# sharun wrapper over AppDir/bin/fs-uae-launcher, so at runtime the launcher
# resolves its files relative to AppDir/shared/bin:
#   resources    -> <exedir>/../../Resources  -> AppDir/Resources
#   translations -> <exedir>/../../Locale     -> AppDir/Locale
cp -a "$BUNDLE/Linux/$launcher_arch/fs-uae-launcher" ./AppDir/bin/
cp -a "$BUNDLE/Resources" ./AppDir/Resources
cp -a "$BUNDLE/Locale"    ./AppDir/Locale

# The PyInstaller bootloader dlopens <exedir>/_internal/libpython*.so, so
# AppDir/shared/bin/_internal has to point at the bundled _internal directory.
# The directory itself stays inside AppDir/bin so that quick-sharun (which is
# given ./AppDir/bin/*) scans the bundled libraries and deploys everything
# they need on the system side.
cp -a "$BUNDLE/Linux/$launcher_arch/_internal" ./AppDir/bin/
ln -sfn ../../bin/_internal ./AppDir/shared/bin/_internal
