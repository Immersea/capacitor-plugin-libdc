#!/bin/bash

# Script to copy necessary files from libdc-swift to the Capacitor plugin

# Source and destination paths
LIBDC_SWIFT_PATH="../libdc-swift-main"
PLUGIN_PATH="./ios/Plugin"

# Create necessary directories if they don't exist
mkdir -p "$PLUGIN_PATH/Sources/Clibdivecomputer/include"
mkdir -p "$PLUGIN_PATH/Sources/LibDCBridge/include"
mkdir -p "$PLUGIN_PATH/Sources/LibDCBridge/src"
mkdir -p "$PLUGIN_PATH/Sources/LibDCSwift"
mkdir -p "$PLUGIN_PATH/Sources/LibDCSwift/Models"
mkdir -p "$PLUGIN_PATH/Sources/LibDCSwift/Parser"
mkdir -p "$PLUGIN_PATH/Sources/LibDCSwift/ViewModels"

# Copy Clibdivecomputer files
cp -R "$LIBDC_SWIFT_PATH/Sources/Clibdivecomputer/include/" "$PLUGIN_PATH/Sources/Clibdivecomputer/include/"
cp "$LIBDC_SWIFT_PATH/Sources/Clibdivecomputer/module.modulemap" "$PLUGIN_PATH/Sources/Clibdivecomputer/"

# Copy libdivecomputer header files
mkdir -p "$PLUGIN_PATH/Sources/Clibdivecomputer/include/libdivecomputer"
cp -R "$LIBDC_SWIFT_PATH/libdivecomputer/include/libdivecomputer/"* "$PLUGIN_PATH/Sources/Clibdivecomputer/include/libdivecomputer/"

# Copy libdivecomputer source files
mkdir -p "$PLUGIN_PATH/Sources/Clibdivecomputer/src"
cp "$LIBDC_SWIFT_PATH/libdivecomputer/src/"*.c "$PLUGIN_PATH/Sources/Clibdivecomputer/src/"
cp "$LIBDC_SWIFT_PATH/libdivecomputer/src/"*.h "$PLUGIN_PATH/Sources/Clibdivecomputer/src/"

# Copy LibDCBridge files
cp -R "$LIBDC_SWIFT_PATH/Sources/LibDCBridge/include/" "$PLUGIN_PATH/Sources/LibDCBridge/include/"
cp -R "$LIBDC_SWIFT_PATH/Sources/LibDCBridge/src/" "$PLUGIN_PATH/Sources/LibDCBridge/src/"

# Copy LibDCSwift files
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/BLEManager.swift" "$PLUGIN_PATH/Sources/LibDCSwift/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/DiveLogRetriever.swift" "$PLUGIN_PATH/Sources/LibDCSwift/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/LibDCSwift.swift" "$PLUGIN_PATH/Sources/LibDCSwift/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Logger.swift" "$PLUGIN_PATH/Sources/LibDCSwift/"

# Copy Models
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Models/DeviceConfiguration.swift" "$PLUGIN_PATH/Sources/LibDCSwift/Models/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Models/DeviceFingerprint.swift" "$PLUGIN_PATH/Sources/LibDCSwift/Models/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Models/DiveData.swift" "$PLUGIN_PATH/Sources/LibDCSwift/Models/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Models/SampleData.swift" "$PLUGIN_PATH/Sources/LibDCSwift/Models/"
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Models/StoredDevice.swift" "$PLUGIN_PATH/Sources/LibDCSwift/Models/"

# Copy Parser
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/Parser/GenericParser.swift" "$PLUGIN_PATH/Sources/LibDCSwift/Parser/"

# Copy ViewModels
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/ViewModels/DiveDataViewModel.swift" "$PLUGIN_PATH/Sources/LibDCSwift/ViewModels/"

# Copy module.modulemap
cp "$LIBDC_SWIFT_PATH/Sources/LibDCSwift/include/module.modulemap" "$PLUGIN_PATH/Sources/LibDCSwift/include/"

echo "Files copied successfully!"