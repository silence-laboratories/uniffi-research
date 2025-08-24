import uniffi.uniffi_callback_demo.*

// Example implementation of the EventCallback trait in Kotlin
class MyEventCallback : EventCallback {
    override fun onEvent(eventType: String, message: String) {
        println("Kotlin received event: $eventType - $message")
    }
    
    override fun onDataReceived(data: ByteArray): String {
        return "Kotlin processed ${data.size} bytes of data: ${data.take(10).toList()}"
    }
}

fun main() {
    try {
        println("=== UniFFI Kotlin Callback Demo ===")
        
        // Create a callback implementation
        val callback = MyEventCallback()
        
        // Register the callback and get an ID
        val callbackId = registerCallback(callback)
        println("Registered callback with ID: $callbackId")
        
        // Create a service
        val service = CallbackService()
        println("Service status: ${service.getStatus()}")
        
        // Set the callback for the service
        setServiceCallback(service, callbackId)
        println("Service status after setting callback: ${service.getStatus()}")
        
        // Test triggering events
        println("\n--- Testing Events ---")
        service.triggerEvent("startup", "Application started successfully")
        service.triggerEvent("user_action", "User clicked button")
        
        // Test data processing
        println("\n--- Testing Data Processing ---")
        val testData = createTestData(20u)
        println("Created test data with ${testData.size} bytes")
        
        val result = service.processData(testData)
        if (result != null) {
            println("Processing result: $result")
        } else {
            println("No result returned (no callback set)")
        }
        
        // Test utility functions
        println("\n--- Testing Utility Functions ---")
        val formattedMessage = formatMessage("INFO", "This is a test message")
        println("Formatted message: $formattedMessage")
        
        // Test background work (this will block for a few seconds)
        println("\n--- Testing Background Work ---")
        println("Starting background work (2 seconds)...")
        service.simulateBackgroundWork(2u)
        println("Background work completed!")
        
        // Clean up
        unregisterCallback(callbackId)
        println("\nCallback unregistered. Demo complete!")
        
    } catch (e: Exception) {
        println("Error: ${e.message}")
        e.printStackTrace()
    }
} 