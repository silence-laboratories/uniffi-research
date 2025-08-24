#!/bin/bash

set -e

echo "=== UniFFI Callback Demo Build Script ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}1. Building Rust library...${NC}"
cargo build --release

echo -e "${YELLOW}2. Running tests...${NC}"
cargo test

echo -e "${YELLOW}3. Creating binding directories...${NC}"
mkdir -p bindings/kotlin
mkdir -p bindings/swift

echo -e "${YELLOW}4. Generating Kotlin bindings...${NC}"
cargo run --bin uniffi-bindgen generate \
    --library target/release/libuniffi_callback_demo.dylib \
    --language kotlin \
    --out-dir bindings/kotlin

echo -e "${YELLOW}5. Generating Swift bindings...${NC}"
cargo run --bin uniffi-bindgen generate \
    --library target/release/libuniffi_callback_demo.dylib \
    --language swift \
    --out-dir bindings/swift

echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""
echo "Generated files:"
echo "  Kotlin: bindings/kotlin/uniffi/uniffi_callback_demo/"
echo "  Swift:  bindings/swift/"
echo ""
echo "Example usage:"
echo "  Kotlin: examples/kotlin/KotlinExample.kt"
echo "  Swift:  examples/swift/SwiftExample.swift"
echo ""
echo -e "${YELLOW}Note: To run examples, you may need to install Kotlin and Swift compilers.${NC}" 