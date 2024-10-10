#!/bin/sh

# A script to programmatically build the MyProductCLI scheme, which is invoked
# as a post-build action in after building MyProductCKLib. Since our ability to
# invoke Swift code that requires entitlements requires us to build a CLI that
# is embedded into an app bundle, and the MyProductCKLib isn't complete without
# that functionality, we re-build the CLI every time we build MyProductCKLib.

if [[ "$ACTION" == "clean" ]]; then
    echo "Build script skipped for clean"
    exit
fi

set -e
set -x

# No idea why these need to be unset, but they cause conflicts in xcodebuild
# if they're not unset before building
unset IPHONEOS_DEPLOYMENT_TARGET
unset WATCHOS_DEPLOYMENT_TARGET
unset TVOS_DEPLOYMENT_TARGET
unset XROS_DEPLOYMENT_TARGET
unset DRIVERKIT_DEPLOYMENT_TARGET

cd $PROJECT_DIR
xcodebuild build -scheme MyProductCLI -destination "platform=macOS,arch=x86_64"

cd $PROJECT_DIR/MyProductCKNS
sh ./post-build-cli.sh
