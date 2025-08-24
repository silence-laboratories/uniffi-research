#!/bin/bash

set -e

echo "🚀 Running All UniFFI Callback Demo Examples"
echo "============================================="
echo ""

# Build the project first
echo "📦 Building the project..."
./build_bindings.sh
echo ""

# Run Swift example
echo "🍎 Running Swift Example:"
echo "------------------------"
./examples/swift/run_swift_example.sh
echo ""

# Run Kotlin example
echo "🤖 Running Kotlin Example:"
echo "-------------------------"
./examples/kotlin/run_kotlin_example.sh
echo ""

echo "✅ All examples completed successfully!"
echo ""
echo "Summary:"
echo "- ✅ Swift example: Callback communication working"
echo "- ✅ Kotlin example: Callback communication working"
echo ""
echo "The examples demonstrate:"
echo "• Bidirectional communication between Rust and client languages"
echo "• Callback registration and management"
echo "• Data processing with callbacks"
echo "• Background work with event notifications"
echo "• Proper cleanup and memory management" 