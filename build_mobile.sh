#!/bin/bash

set -e

echo "=== Building UniFFI Library for Mobile Platforms ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directories
mkdir -p flutter_uniffi_demo/android/src/main/jniLibs/arm64-v8a
mkdir -p flutter_uniffi_demo/android/src/main/jniLibs/armeabi-v7a
mkdir -p flutter_uniffi_demo/android/src/main/jniLibs/x86_64
mkdir -p flutter_uniffi_demo/ios/Frameworks

echo -e "${YELLOW}1. Building for Android targets...${NC}"

# Build for Android ARM64
echo "Building for Android ARM64..."
cargo ndk -t arm64-v8a build --release
cp target/aarch64-linux-android/release/libuniffi_callback_demo.so flutter_uniffi_demo/android/src/main/jniLibs/arm64-v8a/

# Build for Android ARM7
echo "Building for Android ARM7..."
cargo ndk -t armeabi-v7a build --release
cp target/armv7-linux-androideabi/release/libuniffi_callback_demo.so flutter_uniffi_demo/android/src/main/jniLibs/armeabi-v7a/

# Build for Android x86_64 (emulator)
echo "Building for Android x86_64..."
cargo ndk -t x86_64 build --release
cp target/x86_64-linux-android/release/libuniffi_callback_demo.so flutter_uniffi_demo/android/src/main/jniLibs/x86_64/

echo -e "${YELLOW}2. Building for iOS targets...${NC}"

# Build for iOS ARM64 (device)
echo "Building for iOS ARM64..."
cargo build --target aarch64-apple-ios --release

# Build for iOS x86_64 (simulator)
echo "Building for iOS x86_64 simulator..."
cargo build --target x86_64-apple-ios --release

# Copy separate libraries for iOS (no universal library to avoid linker conflicts)
echo "Copying iOS libraries..."
cp target/aarch64-apple-ios/release/libuniffi_callback_demo.dylib flutter_uniffi_demo/ios/Frameworks/libuniffi_callback_demo_device.dylib
cp target/x86_64-apple-ios/release/libuniffi_callback_demo.dylib flutter_uniffi_demo/ios/Frameworks/libuniffi_callback_demo_simulator.dylib

echo -e "${YELLOW}3. Copying bindings...${NC}"

# Copy Kotlin bindings to Android plugin
mkdir -p flutter_uniffi_demo/android/src/main/kotlin/com/example/flutter_uniffi_demo
cp bindings/kotlin/uniffi/uniffi_callback_demo/uniffi_callback_demo.kt flutter_uniffi_demo/android/src/main/kotlin/com/example/flutter_uniffi_demo/

# Copy Swift bindings to iOS plugin
cp bindings/swift/uniffi_callback_demo.swift flutter_uniffi_demo/ios/Classes/
cp bindings/swift/uniffi_callback_demoFFI.h flutter_uniffi_demo/ios/Classes/

echo -e "${GREEN}✅ Mobile build completed successfully!${NC}"
echo ""
echo "Generated files:"
echo "  Android: flutter_uniffi_demo/android/src/main/jniLibs/"
echo "  iOS: flutter_uniffi_demo/ios/Frameworks/"
echo "    - libuniffi_callback_demo_device.dylib (for iOS devices)"
echo "    - libuniffi_callback_demo_simulator.dylib (for iOS simulator)"
echo "  Bindings copied to respective platform directories" 