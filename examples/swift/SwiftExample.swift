import Foundation

// Example implementation of the EventCallback protocol in Swift
class MyEventCallback: EventCallback {
    func onEvent(eventType: String, message: String) {
        print("Swift received event: \(eventType) - \(message)")
    }
    
    func onDataReceived(data: Data) -> String {
        let bytes = Array(data)
        let preview = Array(bytes.prefix(10))
        return "Swift processed \(data.count) bytes of data: \(preview)"
    }
}

func runDemo() {
    print("=== UniFFI Swift Callback Demo ===")
    
    // Create a callback implementation
    let callback = MyEventCallback()
    
    // Register the callback and get an ID
    let callbackId = registerCallback(callback: callback)
    print("Registered callback with ID: \(callbackId)")
    
    // Create a service
    let service = CallbackService()
    print("Service status: \(service.getStatus())")
    
    // Set the callback for the service
    setServiceCallback(service: service, callbackId: callbackId)
    print("Service status after setting callback: \(service.getStatus())")
    
    // Test triggering events
    print("\n--- Testing Events ---")
    service.triggerEvent(eventType: "startup", message: "Application started successfully")
    service.triggerEvent(eventType: "user_action", message: "User tapped button")
    
    // Test data processing
    print("\n--- Testing Data Processing ---")
    let testData = createTestData(size: 20)
    print("Created test data with \(testData.count) bytes")
    
    let result = service.processData(data: testData)
    if let result = result {
        print("Processing result: \(result)")
    } else {
        print("No result returned (no callback set)")
    }
    
    // Test utility functions
    print("\n--- Testing Utility Functions ---")
    let formattedMessage = formatMessage(prefix: "INFO", content: "This is a test message")
    print("Formatted message: \(formattedMessage)")
    
    // Test background work (this will block for a few seconds)
    print("\n--- Testing Background Work ---")
    print("Starting background work (2 seconds)...")
    service.simulateBackgroundWork(durationSeconds: 2)
    print("Background work completed!")
    
    // Clean up
    unregisterCallback(callbackId: callbackId)
    print("\nCallback unregistered. Demo complete!")
}

@main
struct SwiftExample {
    static func main() {
        runDemo()
    }
} 