#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q fs-uae | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_QT=1
export QT_DIR=qt6
export DEPLOY_SYS_PYTHON=1

# Deploy dependencies
case "${ARCH:-$(uname -m)}" in
    x86_64)  xz_arch="x86-64" ;;
    aarch64) xz_arch="ARM64" ;;
esac
quick-sharun ./AppDir/bin/Linux/${xz_arch}/fs-uae-launcher /usr/bin/fs-uae /usr/bin/fs-uae-device-helper
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}/bin' >> ./AppDir/.env

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
