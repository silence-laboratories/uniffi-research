import uniffi.uniffi_callback_demo.*

// Example implementation of the EventCallback trait in Kotlin
class MyEventCallback : EventCallback {
    override fun onEvent(eventType: String, message: String) {
        println("Kotlin received event: $eventType - $message")
    }
    
    override fun onDataReceived(data: ByteArray): String {
        return "Kotlin processed ${data.size} bytes of data: ${data.take(10).toList()}"
    }
    
    override fun addTwoNumbers(a: Int, b: Int): Int {
        val result = a + b
        println("Kotlin callback: $a + $b = $result")
        return result
    }
}

// Example implementation of the StorageClient trait in Kotlin
class MyStorageClient : StorageClient {
    private val storage = mutableMapOf<String, String>()
    
    override fun read(key: String): StorageResult {
        println("🗄️ Kotlin StorageClient.read called with key: $key")
        
        return if (storage.containsKey(key)) {
            val value = storage[key]!!
            println("🗄️ Found value: $value")
            StorageResult(
                success = true,
                data = value,
                errorMessage = "",
                timestamp = System.currentTimeMillis() / 1000
            )
        } else {
            println("🗄️ Key not found: $key")
            StorageResult(
                success = false,
                data = "",
                errorMessage = "Key \"$key\" not found in storage",
                timestamp = System.currentTimeMillis() / 1000
            )
        }
    }
    
    override fun write(key: String, value: String): StorageResult {
        println("🗄️ Kotlin StorageClient.write called: $key = $value")
        
        return try {
            storage[key] = value
            println("🗄️ Successfully stored: $key = $value")
            StorageResult(
                success = true,
                data = value,
                errorMessage = "",
                timestamp = System.currentTimeMillis() / 1000
            )
        } catch (e: Exception) {
            println("🗄️ Failed to store: ${e.message}")
            StorageResult(
                success = false,
                data = "",
                errorMessage = "Failed to write: ${e.message}",
                timestamp = System.currentTimeMillis() / 1000
            )
        }
    }
}

// Example implementation of the WebSocketClient trait in Kotlin
class MyWebSocketClient : WebSocketClient {
    private var isConnected = true
    private val messageQueue = mutableListOf<String>()
    private var messageCounter = 0
    
    override fun send(message: String): WebSocketResult {
        println("🔌 Kotlin WebSocketClient.send called with: $message")
        
        if (!isConnected) {
            return WebSocketResult(
                success = false,
                message = "",
                errorMessage = "WebSocket not connected",
                connectionStatus = "disconnected",
                timestamp = System.currentTimeMillis() / 1000
            )
        }
        
        return try {
            messageCounter++
            println("🔌 Sending message #$messageCounter: $message")
            
            // Add simulated response to queue
            if (message.uppercase() == "PING") {
                messageQueue.add("PONG")
            } else {
                messageQueue.add("Echo: $message (response #$messageCounter)")
            }
            
            WebSocketResult(
                success = true,
                message = "Message sent successfully: $message",
                errorMessage = "",
                connectionStatus = "connected",
                timestamp = System.currentTimeMillis() / 1000
            )
        } catch (e: Exception) {
            println("🔌 Failed to send message: ${e.message}")
            WebSocketResult(
                success = false,
                message = "",
                errorMessage = "Failed to send: ${e.message}",
                connectionStatus = if (isConnected) "connected" else "disconnected",
                timestamp = System.currentTimeMillis() / 1000
            )
        }
    }
    
    override fun read(): WebSocketResult {
        println("🔌 Kotlin WebSocketClient.read called")
        
        if (!isConnected) {
            return WebSocketResult(
                success = false,
                message = "",
                errorMessage = "WebSocket not connected",
                connectionStatus = "disconnected",
                timestamp = System.currentTimeMillis() / 1000
            )
        }
        
        return if (messageQueue.isNotEmpty()) {
            val message = messageQueue.removeAt(0)
            println("🔌 Read message from queue: $message")
            WebSocketResult(
                success = true,
                message = message,
                errorMessage = "",
                connectionStatus = "connected",
                timestamp = System.currentTimeMillis() / 1000
            )
        } else {
            println("🔌 No messages in queue")
            WebSocketResult(
                success = true,
                message = "No new messages",
                errorMessage = "",
                connectionStatus = "connected",
                timestamp = System.currentTimeMillis() / 1000
            )
        }
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
        
        // Test callback function calls
        println("\n--- Testing Callback Function Calls ---")
        val addResult = service.callAddTwoNumbers(15, 27)
        if (addResult != null) {
            println("Addition result from callback: $addResult")
        } else {
            println("No addition result returned (no callback set)")
        }
        
        // Test background work (this will block for a few seconds)
        println("\n--- Testing Background Work ---")
        println("Starting background work (2 seconds)...")
        service.simulateBackgroundWork(2u)
        println("Background work completed!")
        
        // Test StorageClient functionality
        println("\n--- Testing StorageClient ---")
        val storageClient = MyStorageClient()
        val storageClientId = registerStorageClient(storageClient)
        println("Registered StorageClient with ID: $storageClientId")
        
        val storageService = StorageService()
        storageService.setClient(storageClientId)
        
        // Test basic storage operations
        val writeResult = storageService.writeData("user_name", "John Doe")
        if (writeResult != null) {
            println("Write result: success=${writeResult.success}, data='${writeResult.data}'")
        }
        
        val readResult = storageService.readData("user_name")
        if (readResult != null) {
            println("Read result: success=${readResult.success}, data='${readResult.data}'")
        }
        
        // Test copy operation (read then write)
        storageService.writeData("source_key", "important_data")
        val copyResult = storageService.copyData("source_key", "backup_key")
        if (copyResult != null) {
            println("Copy operation: success=${copyResult.success}, copied data='${copyResult.data}'")
        }
        
        // Test backup multiple keys
        storageService.writeData("config1", "value1")
        storageService.writeData("config2", "value2")
        val backupResult = storageService.backupMultipleKeys(
            listOf("config1", "config2", "nonexistent"), 
            "full_backup"
        )
        if (backupResult != null) {
            println("Backup operation: success=${backupResult.success}")
            val backupData = storageService.readData("full_backup")
            if (backupData != null) {
                println("Backup data: '${backupData.data}'")
            }
        }
        
        // Test WebSocketClient functionality
        println("\n--- Testing WebSocketClient ---")
        val webSocketClient = MyWebSocketClient()
        val webSocketClientId = registerWebsocketClient(webSocketClient)
        println("Registered WebSocketClient with ID: $webSocketClientId")
        
        val webSocketService = WebSocketService()
        webSocketService.setClient(webSocketClientId)
        
        // Test basic WebSocket operations
        val sendResult = webSocketService.sendMessage("Hello WebSocket from Kotlin!")
        if (sendResult != null) {
            println("Send result: success=${sendResult.success}, message='${sendResult.message}'")
        }
        
        val readWSResult = webSocketService.readMessage()
        if (readWSResult != null) {
            println("Read result: success=${readWSResult.success}, message='${readWSResult.message}'")
        }
        
        // Test send and read operation
        val sendReadResult = webSocketService.sendAndRead("Testing combined operation")
        if (sendReadResult != null) {
            println("Send&Read result: success=${sendReadResult.success}, message='${sendReadResult.message}'")
        }
        
        // Test ping-pong
        val pingPongResult = webSocketService.pingPong()
        if (pingPongResult != null) {
            println("Ping-Pong result: success=${pingPongResult.success}, message='${pingPongResult.message}'")
        }
        
        // Test batch messages
        val batchResults = webSocketService.sendBatchMessages(listOf("msg1", "msg2", "msg3"))
        println("Batch operation returned ${batchResults.size} results")
        batchResults.forEachIndexed { index, result ->
            println("  Result $index: success=${result.success}, message='${result.message}'")
        }
        
        // Clean up
        unregisterCallback(callbackId)
        unregisterStorageClient(storageClientId)
        unregisterWebsocketClient(webSocketClientId)
        println("\nAll callbacks unregistered. Demo complete!")
        
    } catch (e: Exception) {
        println("Error: ${e.message}")
        e.printStackTrace()
    }
} 