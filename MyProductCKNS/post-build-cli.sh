#!/bin/sh

# This script is invoked as a post-build action on MyProductCLI.
# Post-build actions are defined in the Scheme editor below "Build".

# Must be run as a post-build action because the $EXECUTABLE_NAME.app has to be
# signed; a "Run script" build step at the end of the build process doesn't work.

# Also note that the same copying actions done here are done by build-cli.sh,
# because that script is invoked to manually build MyProductCLI as a post-build
# action for building MyProductCKLib.

if [[ "$ACTION" == "clean" ]]; then
    echo "Build script skipped for clean"
    exit
fi

set -e
set -x

cd $PROJECT_DIR/MyProductCKNS/.build
rm -f ./$EXECUTABLE_NAME
rm -rf ./$EXECUTABLE_NAME.app
cp -R $TARGET_BUILD_DIR/$EXECUTABLE_NAME.app .
ln -s ./$EXECUTABLE_NAME.app/Contents/MacOS/MyProductCLI
