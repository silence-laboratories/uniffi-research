# Project Structure

```
uniffi_callback_demo/
├── Cargo.toml                    # Rust project configuration
├── README.md                     # Main documentation
├── STRUCTURE.md                  # This file
├── build_bindings.sh            # Build script for generating bindings
├── uniffi-bindgen.rs            # UniFFI bindgen binary
│
├── src/
│   └── lib.rs                   # Main Rust library code
│                                #   - EventCallback trait
│                                #   - CallbackService struct
│                                #   - Registration functions
│                                #   - Utility functions
│
├── target/                      # Build output (generated)
│   ├── debug/
│   │   └── libuniffi_callback_demo.dylib
│   └── release/
│       └── libuniffi_callback_demo.dylib
│
├── bindings/                    # Generated language bindings
│   ├── kotlin/
│   │   └── uniffi/
│   │       └── uniffi_callback_demo/
│   │           └── uniffi_callback_demo.kt
│   └── swift/
│       ├── uniffi_callback_demo.swift
│       ├── uniffi_callback_demoFFI.h
│       └── uniffi_callback_demoFFI.modulemap
│
└── examples/                    # Usage examples
    ├── kotlin/
    │   └── KotlinExample.kt     # Kotlin usage example
    └── swift/
        └── SwiftExample.swift   # Swift usage example
```

## Key Components

### Rust Core (`src/lib.rs`)

- **EventCallback Trait**: Defines the interface for callbacks that can be implemented in Kotlin/Swift
- **CallbackService**: Main service class that manages callbacks and provides functionality
- **Global Registry**: Thread-safe callback registration system using OnceLock and Mutex
- **Utility Functions**: Helper functions for data creation and message formatting

### Generated Bindings

#### Kotlin (`bindings/kotlin/`)
- **uniffi_callback_demo.kt**: Complete Kotlin API with classes and interfaces
- Provides type-safe wrappers around the native library
- Includes automatic memory management for callback objects

#### Swift (`bindings/swift/`)
- **uniffi_callback_demo.swift**: Swift API definitions
- **uniffi_callback_demoFFI.h**: C header for the native interface
- **uniffi_callback_demoFFI.modulemap**: Module map for Swift import

### Examples (`examples/`)

- **KotlinExample.kt**: Demonstrates complete callback usage in Kotlin
- **SwiftExample.swift**: Shows callback implementation and usage in Swift
- Both examples cover:
  - Callback implementation
  - Service creation and registration
  - Event triggering and data processing
  - Background work simulation
  - Proper cleanup

## Build Process

1. **Rust Compilation**: `cargo build` creates the dynamic library
2. **Binding Generation**: `uniffi-bindgen` processes the library and generates language-specific bindings
3. **Example Compilation**: Language-specific compilers build the examples against the bindings

## Integration Points

### Kotlin Integration
- Copy `bindings/kotlin/` contents to your Kotlin/Android project
- Include the native library (.dylib/.so/.dll) in your application bundle
- Implement the `EventCallback` interface in your Kotlin code

### Swift Integration
- Add Swift binding files to your Xcode project
- Link against the compiled Rust library
- Implement the `EventCallback` protocol in your Swift code

## Threading Model

- **Rust Side**: All callback operations are thread-safe using Mutex protection
- **Client Side**: Callback implementations must be thread-safe (Send + Sync)
- **Cross-language**: Callbacks can be invoked from any Rust thread safely

## Memory Management

- **Registration**: Callbacks are stored in a global registry with unique IDs
- **References**: Services hold callback IDs, not direct references
- **Cleanup**: Explicit unregistration prevents memory leaks
- **Safety**: UniFFI handles the complex FFI memory management automatically 