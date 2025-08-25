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
    
    func addTwoNumbers(a: Int32, b: Int32) -> Int32 {
        let result = a + b
        print("Swift callback: \(a) + \(b) = \(result)")
        return result
    }
}

// Example implementation of the StorageClient protocol in Swift
class MyStorageClient: StorageClient {
    private var storage: [String: String] = [:]
    
    func read(key: String) -> StorageResult {
        print("🗄️ Swift StorageClient.read called with key: \(key)")
        
        if let value = storage[key] {
            print("🗄️ Found value: \(value)")
            return StorageResult(
                success: true,
                data: value,
                errorMessage: "",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        } else {
            print("🗄️ Key not found: \(key)")
            return StorageResult(
                success: false,
                data: "",
                errorMessage: "Key \"\(key)\" not found in storage",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        }
    }
    
    func write(key: String, value: String) -> StorageResult {
        print("🗄️ Swift StorageClient.write called: \(key) = \(value)")
        
        do {
            storage[key] = value
            print("🗄️ Successfully stored: \(key) = \(value)")
            return StorageResult(
                success: true,
                data: value,
                errorMessage: "",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        } catch {
            print("🗄️ Failed to store: \(error.localizedDescription)")
            return StorageResult(
                success: false,
                data: "",
                errorMessage: "Failed to write: \(error.localizedDescription)",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        }
    }
}

// Example implementation of the WebSocketClient protocol in Swift
class MyWebSocketClient: WebSocketClient {
    private var isConnected = true
    private var messageQueue: [String] = []
    private var messageCounter = 0
    
    func send(message: String) -> WebSocketResult {
        print("🔌 Swift WebSocketClient.send called with: \(message)")
        
        if !isConnected {
            return WebSocketResult(
                success: false,
                message: "",
                errorMessage: "WebSocket not connected",
                connectionStatus: "disconnected",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        }
        
        do {
            messageCounter += 1
            print("🔌 Sending message #\(messageCounter): \(message)")
            
            // Add simulated response to queue
            if message.uppercased() == "PING" {
                messageQueue.append("PONG")
            } else {
                messageQueue.append("Echo: \(message) (response #\(messageCounter))")
            }
            
            return WebSocketResult(
                success: true,
                message: "Message sent successfully: \(message)",
                errorMessage: "",
                connectionStatus: "connected",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        } catch {
            print("🔌 Failed to send message: \(error.localizedDescription)")
            return WebSocketResult(
                success: false,
                message: "",
                errorMessage: "Failed to send: \(error.localizedDescription)",
                connectionStatus: isConnected ? "connected" : "disconnected",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        }
    }
    
    func read() -> WebSocketResult {
        print("🔌 Swift WebSocketClient.read called")
        
        if !isConnected {
            return WebSocketResult(
                success: false,
                message: "",
                errorMessage: "WebSocket not connected",
                connectionStatus: "disconnected",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        }
        
        if !messageQueue.isEmpty {
            let message = messageQueue.removeFirst()
            print("🔌 Read message from queue: \(message)")
            return WebSocketResult(
                success: true,
                message: message,
                errorMessage: "",
                connectionStatus: "connected",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        } else {
            print("🔌 No messages in queue")
            return WebSocketResult(
                success: true,
                message: "No new messages",
                errorMessage: "",
                connectionStatus: "connected",
                timestamp: UInt64(Date().timeIntervalSince1970)
            )
        }
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
    
    // Test callback function calls
    print("\n--- Testing Callback Function Calls ---")
    if let addResult = service.callAddTwoNumbers(a: 15, b: 27) {
        print("Addition result from callback: \(addResult)")
    } else {
        print("No addition result returned (no callback set)")
    }
    
    // Test background work (this will block for a few seconds)
    print("\n--- Testing Background Work ---")
    print("Starting background work (2 seconds)...")
    service.simulateBackgroundWork(durationSeconds: 2)
    print("Background work completed!")
    
    // Test StorageClient functionality
    print("\n--- Testing StorageClient ---")
    let storageClient = MyStorageClient()
    let storageClientId = registerStorageClient(client: storageClient)
    print("Registered StorageClient with ID: \(storageClientId)")
    
    let storageService = StorageService()
    storageService.setClient(clientId: storageClientId)
    
    // Test basic storage operations
    if let writeResult = storageService.writeData(key: "user_name", value: "Jane Smith") {
        print("Write result: success=\(writeResult.success), data='\(writeResult.data)'")
    }
    
    if let readResult = storageService.readData(key: "user_name") {
        print("Read result: success=\(readResult.success), data='\(readResult.data)'")
    }
    
    // Test copy operation (read then write)
    storageService.writeData(key: "source_key", value: "important_data")
    if let copyResult = storageService.copyData(sourceKey: "source_key", targetKey: "backup_key") {
        print("Copy operation: success=\(copyResult.success), copied data='\(copyResult.data)'")
    }
    
    // Test backup multiple keys
    storageService.writeData(key: "config1", value: "value1")
    storageService.writeData(key: "config2", value: "value2")
    if let backupResult = storageService.backupMultipleKeys(
        keys: ["config1", "config2", "nonexistent"], 
        backupKey: "full_backup"
    ) {
        print("Backup operation: success=\(backupResult.success)")
        if let backupData = storageService.readData(key: "full_backup") {
            print("Backup data: '\(backupData.data)'")
        }
    }
    
    // Test WebSocketClient functionality
    print("\n--- Testing WebSocketClient ---")
    let webSocketClient = MyWebSocketClient()
    let webSocketClientId = registerWebsocketClient(client: webSocketClient)
    print("Registered WebSocketClient with ID: \(webSocketClientId)")
    
    let webSocketService = WebSocketService()
    webSocketService.setClient(clientId: webSocketClientId)
    
    // Test basic WebSocket operations
    if let sendResult = webSocketService.sendMessage(message: "Hello WebSocket from Swift!") {
        print("Send result: success=\(sendResult.success), message='\(sendResult.message)'")
    }
    
    if let readWSResult = webSocketService.readMessage() {
        print("Read result: success=\(readWSResult.success), message='\(readWSResult.message)'")
    }
    
    // Test send and read operation
    if let sendReadResult = webSocketService.sendAndRead(message: "Testing combined operation") {
        print("Send&Read result: success=\(sendReadResult.success), message='\(sendReadResult.message)'")
    }
    
    // Test ping-pong
    if let pingPongResult = webSocketService.pingPong() {
        print("Ping-Pong result: success=\(pingPongResult.success), message='\(pingPongResult.message)'")
    }
    
    // Test batch messages
    let batchResults = webSocketService.sendBatchMessages(messages: ["msg1", "msg2", "msg3"])
    print("Batch operation returned \(batchResults.count) results")
    for (index, result) in batchResults.enumerated() {
        print("  Result \(index): success=\(result.success), message='\(result.message)'")
    }
    
    // Clean up
    unregisterCallback(callbackId: callbackId)
    unregisterStorageClient(clientId: storageClientId)
    unregisterWebsocketClient(clientId: webSocketClientId)
    print("\nAll callbacks unregistered. Demo complete!")
}

@main
struct SwiftExample {
    static func main() {
        runDemo()
    }
} 