#!/bin/bash

set -e

echo "=== Running Kotlin Example ==="

# Navigate to the uniffi root directory
cd /Users/dakshgarg/Desktop/uniffi

# Ensure we have the release build
echo "Building release library..."
cargo build --release

# Copy the Kotlin binding files to a temporary directory for compilation
echo "Preparing Kotlin files..."
mkdir -p temp_kotlin
cp -r bindings/kotlin/uniffi temp_kotlin/
cp examples/kotlin/KotlinExample.kt temp_kotlin/
cp target/release/libuniffi_callback_demo.dylib temp_kotlin/

# Download JNA if not present
echo "Downloading JNA library..."
cd temp_kotlin
if [ ! -f "jna-5.13.0.jar" ]; then
    curl -L -o jna-5.13.0.jar https://repo1.maven.org/maven2/net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar
fi

# Compile the Kotlin example
echo "Compiling Kotlin example..."

# Create a classpath with JNA and the generated Kotlin files
kotlinc -cp jna-5.13.0.jar:. -include-runtime -d KotlinExample.jar uniffi/uniffi_callback_demo/uniffi_callback_demo.kt KotlinExample.kt

# Run the example
echo "Running Kotlin example..."
echo ""
# Set the JNA library path to the current directory and run
java -cp jna-5.13.0.jar:KotlinExample.jar -Djna.library.path=. KotlinExampleKt

# Cleanup
cd ..
rm -rf temp_kotlin

echo ""
echo "Kotlin example completed!" 