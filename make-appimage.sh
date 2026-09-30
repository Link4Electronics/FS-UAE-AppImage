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
export STARTUPWMCLASS=

# Deploy dependencies
quick-sharun  ./AppDir/bin/* /usr/bin/fs-uae /usr/bin/fs-uae-device-helper /usr/lib/libopenal.so*
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}/bin' >> ./AppDir/.env

# ---------------------------------------------------------------------------
# AppDir layout fixes (quick-sharun relocates the launcher, the app does not
# expect that, so the following is required for the AppImage to actually run)
# ---------------------------------------------------------------------------

# 1) FS-UAE Launcher resolves its data files (the Resources/*.zip archives with
#    all icons/images) through Application.data_dirs(), whose first candidate is
#    executable_dir()/../../Resources. executable_dir() is the directory of the
#    real PyInstaller binary, which quick-sharun moves to AppDir/shared/bin, so
#    the lookup ends up at AppDir/Resources while the tarball ships the
#    archives in AppDir/bin/Resources. Without this link every image lookup
#    raises LookupError: Cannot find resource 'res/32/main-menu.png' and the
#    launcher refuses to start.
rm -f ./AppDir/Resources
ln -s bin/Resources ./AppDir/Resources

# 2) quick-sharun deploys the system Qt6 libraries (qt6-base) into shared/lib,
#    but the platform plugins bundled with the launcher (PyQt6/Qt6/plugins) are
#    built against the Qt version shipped inside the launcher tarball
#    (PyQt6/Qt6/lib). Qt only accepts plugins built for the exact same version,
#    so the mismatch kills the app with
#    "qt.qpa.plugin: Could not find the Qt platform plugin xcb in ''".
#    Remove the duplicates so the dynamic loader finds PyQt6's matching set
#    first (shared/lib/PyQt6/Qt6/lib is on the RPATH).
rm -f ./AppDir/shared/lib/libQt6*.so*

# 3) quick-sharun keeps the libGLU.so -> libGLU.so.1 link but drops the
#    libGLU.so.1 link itself, leaving libGLU.so dangling (PyOpenGL dlopens
#    "libGLU.so" during startup).
if [ -L ./AppDir/shared/lib/libGLU.so ] && [ ! -e ./AppDir/shared/lib/libGLU.so.1 ]; then
    glu=$(ls ./AppDir/shared/lib/libGLU.so.* 2>/dev/null | head -n 1 || true)
    if [ -n "$glu" ]; then
        ln -sfn "$(basename "$glu")" ./AppDir/shared/lib/libGLU.so.1
    fi
fi

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
