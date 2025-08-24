#!/bin/bash

set -e

echo "=== Running Swift Example ==="

# Navigate to the uniffi root directory
cd /Users/dakshgarg/Desktop/uniffi

# Ensure we have the release build
echo "Building release library..."
cargo build --release

# Copy the Swift binding files to a temporary directory for compilation
echo "Preparing Swift files..."
mkdir -p temp_swift
cp bindings/swift/uniffi_callback_demo.swift temp_swift/
cp bindings/swift/uniffi_callback_demoFFI.h temp_swift/
cp bindings/swift/uniffi_callback_demoFFI.modulemap temp_swift/
cp examples/swift/SwiftExample.swift temp_swift/

# Compile the Swift example
echo "Compiling Swift example..."
cd temp_swift

# Create a bridging header
cat > BridgingHeader.h << 'EOF'
#import "uniffi_callback_demoFFI.h"
EOF

# Compile with the bridging header
swiftc -import-objc-header BridgingHeader.h -L ../target/release -luniffi_callback_demo uniffi_callback_demo.swift SwiftExample.swift -o SwiftExample

# Run the example
echo "Running Swift example..."
echo ""
DYLD_LIBRARY_PATH=../target/release ./SwiftExample

# Cleanup
cd ..
rm -rf temp_swift

echo ""
echo "Swift example completed!" 