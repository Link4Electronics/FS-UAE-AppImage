#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q fs-uae | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/FrodeSolheim/fs-uae-launcher/refs/heads/main/share/icons/hicolor/256x256/apps/fs-uae-launcher.png
export DESKTOP=https://raw.githubusercontent.com/FrodeSolheim/fs-uae-launcher/refs/heads/main/share/applications/fs-uae-launcher.desktop
export STARTUPWMCLASS=fs-uae-launcher
export DEPLOY_OPENGL=1

# Deploy dependencies
quick-sharun  ./AppDir/bin/* /usr/bin/fs-uae /usr/bin/fs-uae-device-helper /usr/lib/libopenal.so*
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}/bin' >> ./AppDir/.env

# fs-uae locates its data archive (fs-uae.dat, a zip containing all of the
# built-in GUI graphics) relative to the real executable as
# <exedir>/../share/fs-uae/fs-uae.dat. quick-sharun keeps the binary in
# AppDir/shared/bin but does not create AppDir/shared/share, so fs-uae
# never finds its data archive: the emulation window comes up completely
# black and the log fills with
# "WARNING: Could not find resource sidebar.png / gloss.png / close.png".
if [ ! -e ./AppDir/shared/share ] && [ -d ./AppDir/share ]; then
    ln -sfn ../share ./AppDir/shared/share
fi

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
