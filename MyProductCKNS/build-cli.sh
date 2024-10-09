#!/bin/sh

if [[ "$ACTION" == "clean" ]]; then
    echo "Build script skipped for clean"
    exit
fi

set -e
set -x

unset IPHONEOS_DEPLOYMENT_TARGET
unset WATCHOS_DEPLOYMENT_TARGET
unset TVOS_DEPLOYMENT_TARGET
unset XROS_DEPLOYMENT_TARGET
unset DRIVERKIT_DEPLOYMENT_TARGET

cd $PROJECT_DIR
xcodebuild build -scheme MyProductCLI -destination "platform=macOS,arch=x86_64"

cd $PROJECT_DIR/MyProductCKNS/.build
rm -f ./MyProductCLI
rm -rf ./MyProductCLI.app
cp -R $TARGET_BUILD_DIR/MyProductCLI.app .
ln -s ./MyProductCLI.app/Contents/MacOS/MyProductCLI
