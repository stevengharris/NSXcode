#!/bin/sh

# A script to copy the Module.node and libNodeAPI.dylib from within the
# .build directory into the $EXECUTABLE.app and properly codesign everything.

if [[ "$ACTION" == "clean" ]]; then
    echo "Post build script skipped for clean"
    exit
fi

set -e
set -x

# MODE is either debug or release
MODE=$(echo "$CONFIGURATION" | tr '[:upper:]' '[:lower:]')

# The .build directory contains what we just built using node-swift
pushd .build

# Start by cleaning up any existing work we did before
rm -rf ./$EXECUTABLE_NAME.app

# Copy the app bundle we just built into the .build directory as $EXECUTABLE_NAME.app
cp -R "$TARGET_BUILD_DIR/$EXECUTABLE_NAME.app" ./$EXECUTABLE_NAME.app

# Get the codesign requirements used to generate .$EXECUTABLE_NAME.app
REQUIREMENTS=$(codesign --display -r- ./$EXECUTABLE_NAME.app)
# Looks like... 'designated => anchor apple generic and identifier "com.stevengharris.NSXCode" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "<Your team ID")'

# Copy the dereferenced ./$MODE/Module.node directory into the $EXECUTABLE_NAME.app's MacOS directory
# Note that ./$MODE/Module.node is a symlink pointing inside of ./Module.framework
cp -LRf ./$MODE/Module.node ./$EXECUTABLE_NAME.app/Contents/MacOS/Module.node

# Remove the old placeholder executable
rm ./$EXECUTABLE_NAME.app/Contents/MacOS/$EXECUTABLE_NAME

# Make a Frameworks directory in Contents and copy the dereferenced libNodeAPI.dylib into it
mkdir -p ./$EXECUTABLE_NAME.app/Contents/Frameworks
cp -L ./$MODE/libNodeAPI.dylib ./$EXECUTABLE_NAME.app/Contents/Frameworks

# Modify the Info.plist to identify the new executable, Module.node
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Module.node" ./$EXECUTABLE_NAME.app/Contents/Info.plist

# Reset the @rpath in Module.node to point to the new Frameworks directory
# Note this produces a warning that Module.node's signature will be invalid
install_name_tool -add_rpath "@loader_path/../Frameworks" ./$EXECUTABLE_NAME.app/Contents/MacOS/Module.node

# IMPORTANT: Use the same cert ID in this script as was used to in Signing & Capabilities.
# For archiving/notarizing, use the same "Developer ID Application" certificate here
# and in Signing & Capabilities

CERT_ID="Apple Development: Steven Harris (77AW2CW22Z)"
#CERT_ID="Developer ID Application: Steven Harris (7XXG4VJQ59)"

# Use the entitlements created in the temp directory, but delete com.app.security.get-task-allow
ENTITLEMENTS_XCENT="${TARGET_TEMP_DIR}/${FULL_PRODUCT_NAME}.xcent"

# Delete get-task-allow if it exists in the entitlements (it won't in a release build)
if $(/usr/libexec/PlistBuddy -c "Print :com.apple.security.get-task-allow" $ENTITLEMENTS_XCENT); then
    /usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" $ENTITLEMENTS_XCENT
fi

# Just in case, make sure there's nothing wrong with the modified entitlements
plutil -lint $ENTITLEMENTS_XCENT

# Sign the libNodeAPI.dylib, otherwise signing Module.node will complain; however, signing
# with entitlements causes node to complain that libNodeAPI.dylib's signature is invalid.
/usr/bin/codesign --force --sign "$CERT_ID" -o runtime --requirements "=$REQUIREMENTS" --generate-entitlement-der --timestamp ./$EXECUTABLE_NAME.app/Contents/Frameworks/libNodeAPI.dylib

# Sign the Module.node in MacOS
/usr/bin/codesign --force --sign "$CERT_ID" -o runtime --entitlements $ENTITLEMENTS_XCENT --requirements "=$REQUIREMENTS" --generate-entitlement-der --timestamp ./$EXECUTABLE_NAME.app/Contents/MacOS/Module.node

# Sign the $EXECUTABLE_NAME.app in .build
/usr/bin/codesign --force --sign "$CERT_ID" -o runtime --entitlements $ENTITLEMENTS_XCENT --requirements "=$REQUIREMENTS" --generate-entitlement-der --timestamp ./$EXECUTABLE_NAME.app

# Finally, fix the Module.node in the .build directory.
# This is the non-notarized Module.node that is required from within index.js.
rm ./Module.node
ln -s ./$EXECUTABLE_NAME.app/Contents/MacOS/Module.node
