#!/bin/sh

if [[ "$ACTION" == "clean" ]]; then
    echo "Build script skipped for clean"
    exit
fi

set -e
set -x

rm -rf $EXECUTABLE_NAME
cp -R "$TARGET_BUILD_DIR/$EXECUTABLE_NAME.app" .
ln -s ./$EXECUTABLE_NAME.app/Contents/MacOS/$EXECUTABLE_NAME
