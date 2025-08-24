# UniFFI Callback Demo

This project demonstrates how to create a Rust library with callback functionality that can be used from Kotlin and Swift using Mozilla's UniFFI.

## Features

- **Rust Core Library**: Implements callback traits and core business logic
- **Kotlin Bindings**: Generated bindings for Android/JVM usage
- **Swift Bindings**: Generated bindings for iOS/macOS usage
- **Callback Support**: Full bidirectional communication between Rust and client languages
- **Thread Safety**: Uses proper synchronization for cross-language callback invocation

## Architecture

The library consists of:

1. **EventCallback Trait**: A trait that can be implemented in Kotlin/Swift
2. **CallbackService**: A Rust service that accepts and uses callbacks
3. **Registry System**: Global callback registration and management
4. **Utility Functions**: Helper functions for data creation and formatting

## Building the Library

### Prerequisites

- Rust (latest stable)
- Cargo

### Build Steps

```bash
# Clone or navigate to the project directory
cd uniffi_callback_demo

# Build the Rust library
cargo build

# Run tests
cargo test

# Generate bindings for Kotlin
cargo run --bin uniffi-bindgen generate \
    --library target/debug/libuniffi_callback_demo.dylib \
    --language kotlin \
    --out-dir bindings/kotlin

# Generate bindings for Swift
cargo run --bin uniffi-bindgen generate \
    --library target/debug/libuniffi_callback_demo.dylib \
    --language swift \
    --out-dir bindings/swift
```

## Rust API

### Core Components

```rust
// Trait to implement in client languages
pub trait EventCallback: Send + Sync {
    fn on_event(&self, event_type: String, message: String);
    fn on_data_received(&self, data: Vec<u8>) -> String;
}

// Main service class
pub struct CallbackService {
    // Internal implementation
}

impl CallbackService {
    pub fn new() -> Arc<Self>;
    pub fn get_status(&self) -> String;
    pub fn trigger_event(&self, event_type: String, message: String);
    pub fn process_data(&self, data: Vec<u8>) -> Option<String>;
    pub fn simulate_background_work(&self, duration_seconds: u32);
}

// Registration functions
pub fn register_callback(callback: Box<dyn EventCallback>) -> u32;
pub fn set_service_callback(service: Arc<CallbackService>, callback_id: u32);
pub fn unregister_callback(callback_id: u32);

// Utility functions
pub fn create_test_data(size: u32) -> Vec<u8>;
pub fn format_message(prefix: String, content: String) -> String;
```

## Kotlin Usage

### Setup

1. Include the generated Kotlin bindings in your project
2. Add the native library to your application

### Example Implementation

```kotlin
import uniffi.uniffi_callback_demo.*

class MyEventCallback : EventCallback {
    override fun onEvent(eventType: String, message: String) {
        println("Received: $eventType - $message")
    }
    
    override fun onDataReceived(data: List<UByte>): String {
        return "Processed ${data.size} bytes"
    }
}

fun main() {
    // Create callback and register it
    val callback = MyEventCallback()
    val callbackId = registerCallback(callback)
    
    // Create service and set callback
    val service = CallbackService()
    setServiceCallback(service, callbackId)
    
    // Use the service
    service.triggerEvent("test", "Hello from Kotlin!")
    val result = service.processData(createTestData(10u))
    
    // Cleanup
    unregisterCallback(callbackId)
}
```

## Swift Usage

### Setup

1. Include the generated Swift files in your Xcode project
2. Add the compiled library to your project

### Example Implementation

```swift
import Foundation

class MyEventCallback: EventCallback {
    func onEvent(eventType: String, message: String) {
        print("Received: \(eventType) - \(message)")
    }
    
    func onDataReceived(data: [UInt8]) -> String {
        return "Processed \(data.count) bytes"
    }
}

func example() throws {
    // Create callback and register it
    let callback = MyEventCallback()
    let callbackId = try registerCallback(callback: callback)
    
    // Create service and set callback
    let service = try CallbackService()
    try setServiceCallback(service: service, callbackId: callbackId)
    
    // Use the service
    try service.triggerEvent(eventType: "test", message: "Hello from Swift!")
    let result = try service.processData(data: createTestData(size: 10))
    
    // Cleanup
    try unregisterCallback(callbackId: callbackId)
}
```

## Running Examples

You have several options to run the examples:

### Run All Examples (Recommended)

```bash
# Run both Kotlin and Swift examples automatically
./run_all_examples.sh
```

### Run Individual Examples

#### Swift Example

```bash
# Run just the Swift example
./examples/swift/run_swift_example.sh
```

#### Kotlin Example

```bash
# Run just the Kotlin example (requires Kotlin compiler and JNA)
./examples/kotlin/run_kotlin_example.sh
```

### Prerequisites

- **Rust**: Latest stable version
- **Swift**: Available on macOS (built-in)
- **Kotlin**: Install using your package manager or download from kotlinlang.org
  - On macOS with Homebrew: `brew install kotlin`
- **JNA**: Automatically downloaded by the Kotlin example script

## Key Features Demonstrated

1. **Bidirectional Callbacks**: Rust can call functions implemented in Kotlin/Swift
2. **Data Passing**: Both simple types (strings, numbers) and complex types (byte arrays)
3. **Async Operations**: Background work with callback notifications
4. **Memory Management**: Proper registration/unregistration of callbacks
5. **Error Handling**: Graceful handling of missing callbacks
6. **Thread Safety**: Safe concurrent access to shared callback registry

## Architecture Notes

### Callback Registry

The library uses a global registry system to manage callbacks:
- Callbacks are registered and assigned unique IDs
- Services reference callbacks by ID rather than direct pointers
- This approach works well with UniFFI's Foreign Function Interface requirements

### Thread Safety

- All callback operations are protected by mutexes
- The `EventCallback` trait requires `Send + Sync` for thread safety
- Background operations can safely invoke callbacks from any thread

### Memory Management

- Rust manages the lifecycle of registered callbacks
- Clients must explicitly unregister callbacks to prevent memory leaks
- Services hold weak references to callbacks (by ID) to avoid circular references

## Troubleshooting

### Common Issues

1. **Library not found**: Ensure the dynamic library path is correctly set
2. **Callback not invoked**: Check that the callback is properly registered and the service has the correct callback ID
3. **Threading issues**: Ensure your callback implementation is thread-safe

### Building for Different Platforms

- **iOS**: Use `cargo build --target aarch64-apple-ios`
- **Android**: Use appropriate Android NDK targets
- **Linux**: Default target usually works
- **Windows**: May require additional setup for cross-compilation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is provided as an example and educational resource. Use it as a starting point for your own UniFFI-based projects. 