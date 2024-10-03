#!/bin/sh

# When we archive, we want to archive the Module.app we created using the ,
# post-build-app script, not the placeholder app created originally by the build target.

set -e
set -x

# The .build directory contains what we just built
pushd .build

# Remove the placeholder app bundle built from main.swift
rm -R "$TARGET_BUILD_DIR/$EXECUTABLE_NAME.app"

# Copy the app bundle containing Module.node into the target build directory as $EXECUTABLE_NAME.app
# so that it will be archived using all the settings for the original.
cp -R ./$EXECUTABLE_NAME.app "$TARGET_BUILD_DIR/$EXECUTABLE_NAME.app"
