#!/bin/sh

# A script run from the MyProductLib target to build Module.node and libNodeAPI.dylib

# IMPORTANT:
#
# 1. The script depends on the build settings from MyProductLib.
# 2. The script should be run from the directory containing the .build directory, MyProductNS.
# 3. Install node-swift as a dependency in this directory ($TARGET_BUILD_DIR) once by
#    running 'npm install <relative path to node-swift directory>'.
# 4. To use in a VSCode extension, this directory needs to installed as a dependency once by
#    running 'npm install <relative path to $TARGET_BUILD_DIR>'.

# Note: Here $EXECUTABLE_NAME is the target in Xcode, also a directory within the project.

if [[ "$ACTION" == "clean" ]]; then
    echo "Build script skipped for clean"
    exit 
fi

set -e
set -x

# MODE is either debug or release
MODE=$(echo "$CONFIGURATION" | tr '[:upper:]' '[:lower:]')

# If modifying node-swift itself, build that first; else can avoid this step
# If installing for the very first time (typically already done once in node-swift directly),
# will take a very long time to build thanks to swift-syntax; else, is a cheap call
echo "Building node-swift itself in ./node_modules/node-swift..."
pushd ./node_modules/node-swift
npm run build
popd

# Build Module.framework and libNodeAPI.dylib
echo "Building $MODE version of Module.node..."
if [[ "$MODE" == "debug" ]]; then
    BUILDSCRIPT="builddebug"
else
    BUILDSCRIPT="build"
fi

rm -rf ./.build/$MODE           # Remove the previous build
npm run $BUILDSCRIPT
