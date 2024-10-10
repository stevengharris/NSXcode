#!/bin/sh

# This script is invoked as a post-build action on MyProductCLI.
# Post-build actions are defined in the Scheme editor below "Build".

# Must be run as a post-build action because the MyProductCLI.app has to be
# signed; a "Run script" build step at the end of the build process doesn't work.

# Also note that this script is executed by build-cli.sh,
# because build-cli.sh is invoked to manually build MyProductCLI as a
# post-build action for building MyProductCKLib. This is why this script hard-codes
# MyProductCLI instead of using $EXECUTABLE_NAME

if [[ "$ACTION" == "clean" ]]; then
    echo "Build script skipped for clean"
    exit
fi

set -e
set -x

cd $PROJECT_DIR/MyProductCKNS/.build
rm -f ./MyProductCLI
rm -rf ./MyProductCLI.app
cp -R $TARGET_BUILD_DIR/MyProductCLI.app .
ln -s ./MyProductCLI.app/Contents/MacOS/MyProductCLI
