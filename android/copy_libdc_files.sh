#!/bin/bash

# Script to copy necessary files from libdivecomputer-java to the Capacitor plugin

# Source and destination paths
LIBDC_JAVA_PATH="../libdivecomputer-java-master"
PLUGIN_PATH="./android"
CURRENT_DIR=$(pwd)

# Create necessary directories if they don't exist
mkdir -p "$PLUGIN_PATH/libs"
mkdir -p "$PLUGIN_PATH/src/main/jniLibs/arm64-v8a"
mkdir -p "$PLUGIN_PATH/src/main/jniLibs/armeabi-v7a"
mkdir -p "$PLUGIN_PATH/src/main/jniLibs/x86"
mkdir -p "$PLUGIN_PATH/src/main/jniLibs/x86_64"
mkdir -p "$PLUGIN_PATH/src/main/java/org/libdivecomputer"
mkdir -p "$PLUGIN_PATH/src/main/cpp"

# Copy Java classes
cp -R "$LIBDC_JAVA_PATH/org/libdivecomputer/" "$PLUGIN_PATH/src/main/java/org/"

# Create a JAR file from the Java classes
echo "Creating JAR file from Java classes..."
cd "$LIBDC_JAVA_PATH"
javac org/libdivecomputer/*.java
jar cf divecomputer-java.jar org/libdivecomputer/*.class
cp divecomputer-java.jar "$CURRENT_DIR/$PLUGIN_PATH/libs/"
cd "$CURRENT_DIR"

# Copy JNI libraries (if they exist)
if [ -d "$LIBDC_JAVA_PATH/libs/arm64-v8a" ]; then
    cp "$LIBDC_JAVA_PATH/libs/arm64-v8a/libdivecomputer-java.so" "$PLUGIN_PATH/src/main/jniLibs/arm64-v8a/"
fi

if [ -d "$LIBDC_JAVA_PATH/libs/armeabi-v7a" ]; then
    cp "$LIBDC_JAVA_PATH/libs/armeabi-v7a/libdivecomputer-java.so" "$PLUGIN_PATH/src/main/jniLibs/armeabi-v7a/"
fi

if [ -d "$LIBDC_JAVA_PATH/libs/x86" ]; then
    cp "$LIBDC_JAVA_PATH/libs/x86/libdivecomputer-java.so" "$PLUGIN_PATH/src/main/jniLibs/x86/"
fi

if [ -d "$LIBDC_JAVA_PATH/libs/x86_64" ]; then
    cp "$LIBDC_JAVA_PATH/libs/x86_64/libdivecomputer-java.so" "$PLUGIN_PATH/src/main/jniLibs/x86_64/"
fi

# Copy C/C++ files for JNI
cp "$LIBDC_JAVA_PATH/exception.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/exception.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Context.c" "$PLUGIN_PATH/src/main/cpp/"

# Copy libdivecomputer source files
LIBDC_SWIFT_PATH="../libdc-swift-main"
mkdir -p "$PLUGIN_PATH/src/main/cpp/libdivecomputer"
mkdir -p "$PLUGIN_PATH/src/main/cpp/include/libdivecomputer"
cp "$LIBDC_SWIFT_PATH/libdivecomputer/src/"*.c "$PLUGIN_PATH/src/main/cpp/libdivecomputer/"
cp "$LIBDC_SWIFT_PATH/libdivecomputer/src/"*.h "$PLUGIN_PATH/src/main/cpp/libdivecomputer/"
cp "$LIBDC_SWIFT_PATH/libdivecomputer/include/libdivecomputer/"*.h "$PLUGIN_PATH/src/main/cpp/include/libdivecomputer/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Context.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Custom.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Custom.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Descriptor.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Descriptor.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Device.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Device.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_IOStream.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_IOStream.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Parser.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Parser.h" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Serial.c" "$PLUGIN_PATH/src/main/cpp/"
cp "$LIBDC_JAVA_PATH/org_libdivecomputer_Serial.h" "$PLUGIN_PATH/src/main/cpp/"

echo "Files copied successfully!"