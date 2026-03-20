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
# The launcher ships its own Qt inside the PyInstaller _internal directory (the
# bundled platform plugins are built against those exact libraries, Qt only
# accepts plugins built for the same version). Deploying the system Qt on top
# of it makes the app die with
# "qt.qpa.plugin: Could not find the Qt platform plugin xcb in ''".
#export DEPLOY_QT=0

# Deploy dependencies
quick-sharun  ./AppDir/bin/* /usr/bin/fs-uae /usr/bin/fs-uae-device-helper /usr/lib/libopenal.so*
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}/bin' >> ./AppDir/.env

# quick-sharun keeps the libGLU.so -> libGLU.so.1 link but drops the
# libGLU.so.1 link itself, leaving libGLU.so dangling (PyOpenGL dlopens
# "libGLU.so" during startup).
if [ -L ./AppDir/shared/lib/libGLU.so ] && [ ! -e ./AppDir/shared/lib/libGLU.so.1 ]; then
    glu=$(ls ./AppDir/shared/lib/libGLU.so.* 2>/dev/null | head -n 1 || true)
    if [ -n "$glu" ]; then
        ln -sfn "$(basename "$glu")" ./AppDir/shared/lib/libGLU.so.1
    fi
fi

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
