package com.example.flutter_uniffi_demo

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector

/** FlutterUniffiDemoPlugin */
class FlutterUniffiDemoPlugin: FlutterPlugin, MethodCallHandler, StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel : EventChannel
  private var eventSink: EventSink? = null
  private val mainHandler = Handler(Looper.getMainLooper())
  
  // For demonstration purposes, we'll simulate the Rust callbacks
  private var isInitialized = false
  private var callbackRegistered = false
  
  // Store Dart callback function ID and use MethodChannel to call back to Dart
  private var dartCallbackChannelId: String? = null
  
  // Store Dart object callback IDs
  private val dartObjectCallbacks = mutableMapOf<String, String>() // objectType -> callbackId

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_uniffi_demo")
    channel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_uniffi_demo_events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initializeService" -> {
        try {
          isInitialized = true
          Log.d("FlutterUniffiDemo", "Service initialized (Android demo mode)")
          result.success("Service initialized (Android demo mode)")
        } catch (e: Exception) {
          result.error("INIT_ERROR", "Failed to initialize service: ${e.message}", null)
        }
      }
      
      "registerCallback" -> {
        try {
          if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Service not initialized", null)
            return
          }
          
          val callbackId = call.argument<String>("callbackId")
          if (callbackId != null) {
            dartCallbackChannelId = callbackId
            callbackRegistered = true
            Log.d("FlutterUniffiDemo", "Dart callback registered with ID: $callbackId (Android demo mode)")
            result.success(1) // Return demo callback ID
          } else {
            result.error("INVALID_CALLBACK", "No callback ID provided", null)
          }
        } catch (e: Exception) {
          result.error("CALLBACK_ERROR", "Failed to register callback: ${e.message}", null)
        }
      }
      
      "getStatus" -> {
        try {
          val status = when {
            !isInitialized -> "Service not initialized"
            !callbackRegistered -> "No callback registered"
            else -> "Callback registered (Android demo mode)"
          }
          result.success(status)
        } catch (e: Exception) {
          result.error("STATUS_ERROR", "Failed to get status: ${e.message}", null)
        }
      }
      
      "triggerEvent" -> {
        try {
          val eventType = call.argument<String>("eventType") ?: ""
          val message = call.argument<String>("message") ?: ""
          
          // Simulate callback event
          mainHandler.post {
            eventSink?.success(mapOf(
              "type" to "event",
              "eventType" to eventType,
              "message" to "Android demo received: $message"
            ))
          }
          
          result.success("Event triggered (Android demo mode)")
        } catch (e: Exception) {
          result.error("EVENT_ERROR", "Failed to trigger event: ${e.message}", null)
        }
      }
      
      "processData" -> {
        try {
          val size = call.argument<Int>("size") ?: 10
          
          // Simulate data processing and callback
          val simulatedResult = "Android demo processed $size bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]"
          
          mainHandler.post {
            eventSink?.success(mapOf(
              "type" to "dataProcessed",
              "result" to simulatedResult,
              "dataSize" to size
            ))
          }
          
          result.success(simulatedResult)
        } catch (e: Exception) {
          result.error("PROCESS_ERROR", "Failed to process data: ${e.message}", null)
        }
      }
      
      "simulateWork" -> {
        try {
          val duration = call.argument<Int>("duration") ?: 2
          
          // Simulate background work
          Thread {
            Thread.sleep((duration * 1000).toLong())
            
            mainHandler.post {
              eventSink?.success(mapOf(
                "type" to "event",
                "eventType" to "work_completed",
                "message" to "Android demo: Background work completed after $duration seconds"
              ))
              result.success("Work completed (Android demo mode)")
            }
          }.start()
        } catch (e: Exception) {
          result.error("WORK_ERROR", "Failed to simulate work: ${e.message}", null)
        }
      }
      
      "formatMessage" -> {
        try {
          val prefix = call.argument<String>("prefix") ?: ""
          val content = call.argument<String>("content") ?: ""
          val formatted = "$prefix: $content (Android demo mode)"
          result.success(formatted)
        } catch (e: Exception) {
          result.error("FORMAT_ERROR", "Failed to format message: ${e.message}", null)
        }
      }
      
                  "addTwoNumbers" -> {
                try {
                    val a = call.argument<Int>("a") ?: 0
                    val b = call.argument<Int>("b") ?: 0
                    
                    if (dartCallbackChannelId != null && callbackRegistered) {
                        // Call back to Dart to perform the addition
                        channel.invokeMethod("dartCallback", mapOf(
                            "callbackId" to dartCallbackChannelId,
                            "function" to "addTwoNumbers",
                            "args" to mapOf("a" to a, "b" to b)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                val sum = dartResult as? Int ?: 0
                                
                                // Send callback event to Flutter
                                mainHandler.post {
                                    eventSink?.success(mapOf(
                                        "type" to "calculationResult",
                                        "operation" to "addition",
                                        "a" to a,
                                        "b" to b,
                                        "result" to sum,
                                        "message" to "Android demo (Dart callback): $a + $b = $sum"
                                    ))
                                }
                                
                                result.success(sum)
                            }
                            
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_CALLBACK_ERROR", "Dart callback failed: $errorMessage", errorDetails)
                            }
                            
                            override fun notImplemented() {
                                result.error("DART_CALLBACK_NOT_IMPLEMENTED", "Dart callback not implemented", null)
                            }
                        })
                    } else {
                        // Fallback to local calculation if no Dart callback registered
                        val sum = a + b
                        
                        mainHandler.post {
                            eventSink?.success(mapOf(
                                "type" to "calculationResult",
                                "operation" to "addition",
                                "a" to a,
                                "b" to b,
                                "result" to sum,
                                "message" to "Android demo (fallback): $a + $b = $sum"
                            ))
                        }
                        
                        result.success(sum)
                    }
                } catch (e: Exception) {
                    result.error("CALCULATION_ERROR", "Failed to add numbers: ${e.message}", null)
                }
            }
            
            "registerDartObject" -> {
                try {
                    val objectType = call.argument<String>("objectType") ?: ""
                    val callbackId = call.argument<String>("callbackId") ?: ""
                    
                    dartObjectCallbacks[objectType] = callbackId
                    Log.d("FlutterUniffiDemo", "Registered Dart object: $objectType with callback ID: $callbackId")
                    result.success("Object registered successfully")
                } catch (e: Exception) {
                    result.error("OBJECT_REGISTRATION_ERROR", "Failed to register object: ${e.message}", null)
                }
            }
            
            "processDataItem" -> {
                try {
                    val item = call.argument<String>("item") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("DataProcessor")) {
                        // Call Dart DataProcessor object
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "DataProcessor",
                            "method" to "processItem",
                            "args" to mapOf("item" to item)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_OBJECT_ERROR", "Dart object call failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_OBJECT_NOT_IMPLEMENTED", "Dart object call not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_PROCESSOR", "No DataProcessor object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("PROCESS_ERROR", "Failed to process data item: ${e.message}", null)
                }
            }
            
            "validateAndProcess" -> {
                try {
                    val input = call.argument<String>("input") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("DataProcessor")) {
                        // First validate
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "DataProcessor",
                            "method" to "validateInput",
                            "args" to mapOf("input" to input)
                        ), object : MethodChannel.Result {
                            override fun success(validationResult: Any?) {
                                val isValid = validationResult as? Boolean ?: false
                                if (isValid) {
                                    // Then process
                                    channel.invokeMethod("dartObjectCallback", mapOf(
                                        "objectType" to "DataProcessor",
                                        "method" to "processItem",
                                        "args" to mapOf("item" to input)
                                    ), object : MethodChannel.Result {
                                        override fun success(processResult: Any?) {
                                            result.success(processResult)
                                        }
                                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                            result.error("DART_PROCESS_ERROR", "Dart process failed: $errorMessage", errorDetails)
                                        }
                                        override fun notImplemented() {
                                            result.error("DART_PROCESS_NOT_IMPLEMENTED", "Dart process not implemented", null)
                                        }
                                    })
                                } else {
                                    result.success(mapOf(
                                        "success" to false,
                                        "result" to "Validation failed",
                                        "metadata" to "Android validation",
                                        "timestamp" to System.currentTimeMillis() / 1000
                                    ))
                                }
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_VALIDATION_ERROR", "Dart validation failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_VALIDATION_NOT_IMPLEMENTED", "Dart validation not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_PROCESSOR", "No DataProcessor object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("VALIDATE_PROCESS_ERROR", "Failed to validate and process: ${e.message}", null)
                }
            }
            
            "transformBatchData" -> {
                try {
                    val data = call.argument<List<String>>("data") ?: emptyList()
                    
                    if (dartObjectCallbacks.containsKey("DataProcessor")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "DataProcessor",
                            "method" to "transformData",
                            "args" to mapOf("data" to data)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_TRANSFORM_ERROR", "Dart transform failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_TRANSFORM_NOT_IMPLEMENTED", "Dart transform not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_PROCESSOR", "No DataProcessor object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("TRANSFORM_ERROR", "Failed to transform batch data: ${e.message}", null)
                }
            }
            
            "getUserInfo" -> {
                try {
                    val userId = call.argument<Int>("userId") ?: 0
                    
                    if (dartObjectCallbacks.containsKey("UserProfileManager")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "UserProfileManager",
                            "method" to "getUserInfo",
                            "args" to mapOf("userId" to userId)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_USER_INFO_ERROR", "Dart get user info failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_USER_INFO_NOT_IMPLEMENTED", "Dart get user info not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_USER_MANAGER", "No UserProfileManager object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("GET_USER_INFO_ERROR", "Failed to get user info: ${e.message}", null)
                }
            }
            
            "updateUserPreferences" -> {
                try {
                    val userId = call.argument<Int>("userId") ?: 0
                    val preferences = call.argument<Map<String, Any>>("preferences") ?: emptyMap()
                    
                    if (dartObjectCallbacks.containsKey("UserProfileManager")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "UserProfileManager",
                            "method" to "updatePreferences",
                            "args" to mapOf("userId" to userId, "preferences" to preferences)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_UPDATE_PREFS_ERROR", "Dart update preferences failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_UPDATE_PREFS_NOT_IMPLEMENTED", "Dart update preferences not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_USER_MANAGER", "No UserProfileManager object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("UPDATE_PREFS_ERROR", "Failed to update user preferences: ${e.message}", null)
                }
            }
            
            "calculateUserScore" -> {
                try {
                    val userId = call.argument<Int>("userId") ?: 0
                    val metrics = call.argument<List<Double>>("metrics") ?: emptyList()
                    
                    if (dartObjectCallbacks.containsKey("UserProfileManager")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "UserProfileManager",
                            "method" to "calculateScore",
                            "args" to mapOf("userId" to userId, "metrics" to metrics)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_CALC_SCORE_ERROR", "Dart calculate score failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_CALC_SCORE_NOT_IMPLEMENTED", "Dart calculate score not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_USER_MANAGER", "No UserProfileManager object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("CALC_SCORE_ERROR", "Failed to calculate user score: ${e.message}", null)
                }
            }
            
            "sendUserNotification" -> {
                try {
                    val userId = call.argument<Int>("userId") ?: 0
                    val message = call.argument<String>("message") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("UserProfileManager")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "UserProfileManager",
                            "method" to "notifyUser",
                            "args" to mapOf("userId" to userId, "message" to message)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success("Notification sent successfully")
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_NOTIFY_ERROR", "Dart notify user failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_NOTIFY_NOT_IMPLEMENTED", "Dart notify user not implemented", null)
                            }
                        })
    } else {
                        result.error("NO_USER_MANAGER", "No UserProfileManager object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("NOTIFY_ERROR", "Failed to send user notification: ${e.message}", null)
                }
            }
            
            // Storage Client methods
            "writeToStorage" -> {
                try {
                    val key = call.argument<String>("key") ?: ""
                    val value = call.argument<String>("value") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("StorageClient")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "StorageClient",
                            "method" to "write",
                            "args" to mapOf("key" to key, "value" to value)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_STORAGE_WRITE_ERROR", "Dart storage write failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_STORAGE_WRITE_NOT_IMPLEMENTED", "Dart storage write not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_STORAGE_CLIENT", "No StorageClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_WRITE_ERROR", "Failed to write to storage: ${e.message}", null)
                }
            }
            
            "readFromStorage" -> {
                try {
                    val key = call.argument<String>("key") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("StorageClient")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "StorageClient",
                            "method" to "read",
                            "args" to mapOf("key" to key)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_STORAGE_READ_ERROR", "Dart storage read failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_STORAGE_READ_NOT_IMPLEMENTED", "Dart storage read not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_STORAGE_CLIENT", "No StorageClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_READ_ERROR", "Failed to read from storage: ${e.message}", null)
                }
            }
            
            "copyStorageData" -> {
                try {
                    val sourceKey = call.argument<String>("sourceKey") ?: ""
                    val targetKey = call.argument<String>("targetKey") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("StorageClient")) {
                        // First read from source
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "StorageClient",
                            "method" to "read",
                            "args" to mapOf("key" to sourceKey)
                        ), object : MethodChannel.Result {
                            override fun success(readResult: Any?) {
                                val readData = readResult as? Map<String, Any>
                                if (readData?.get("success") == true) {
                                    val data = readData["data"] as? String ?: ""
                                    // Then write to target
                                    channel.invokeMethod("dartObjectCallback", mapOf(
                                        "objectType" to "StorageClient",
                                        "method" to "write",
                                        "args" to mapOf("key" to targetKey, "value" to data)
                                    ), object : MethodChannel.Result {
                                        override fun success(writeResult: Any?) {
                                            result.success(writeResult)
                                        }
                                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                            result.error("DART_STORAGE_COPY_WRITE_ERROR", "Copy write failed: $errorMessage", errorDetails)
                                        }
                                        override fun notImplemented() {
                                            result.error("DART_STORAGE_COPY_WRITE_NOT_IMPLEMENTED", "Copy write not implemented", null)
                                        }
                                    })
                                } else {
                                    result.error("STORAGE_COPY_READ_FAILED", "Failed to read source data for copy", readData)
                                }
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_STORAGE_COPY_READ_ERROR", "Copy read failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_STORAGE_COPY_READ_NOT_IMPLEMENTED", "Copy read not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_STORAGE_CLIENT", "No StorageClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_COPY_ERROR", "Failed to copy storage data: ${e.message}", null)
                }
            }
            
            "backupMultipleStorageKeys" -> {
                try {
                    val keys = call.argument<List<String>>("keys") ?: emptyList()
                    val backupKey = call.argument<String>("backupKey") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("StorageClient")) {
                        // Simulate backup by combining multiple reads
                        val backupData = "BACKUP_${keys.joinToString("_")}_${System.currentTimeMillis()}"
                        
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "StorageClient",
                            "method" to "write",
                            "args" to mapOf("key" to backupKey, "value" to backupData)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_STORAGE_BACKUP_ERROR", "Dart storage backup failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_STORAGE_BACKUP_NOT_IMPLEMENTED", "Dart storage backup not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_STORAGE_CLIENT", "No StorageClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_BACKUP_ERROR", "Failed to backup storage keys: ${e.message}", null)
                }
            }
            
            // WebSocket Client methods
            "sendWebSocketMessage" -> {
                try {
                    val message = call.argument<String>("message") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("WebSocketClient")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "WebSocketClient",
                            "method" to "send",
                            "args" to mapOf("message" to message)
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_WEBSOCKET_SEND_ERROR", "Dart WebSocket send failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_WEBSOCKET_SEND_NOT_IMPLEMENTED", "Dart WebSocket send not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_WEBSOCKET_CLIENT", "No WebSocketClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("WEBSOCKET_SEND_ERROR", "Failed to send WebSocket message: ${e.message}", null)
                }
            }
            
            "readWebSocketMessage" -> {
                try {
                    if (dartObjectCallbacks.containsKey("WebSocketClient")) {
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "WebSocketClient",
                            "method" to "read",
                            "args" to emptyMap<String, Any>()
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                result.success(dartResult)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_WEBSOCKET_READ_ERROR", "Dart WebSocket read failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_WEBSOCKET_READ_NOT_IMPLEMENTED", "Dart WebSocket read not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_WEBSOCKET_CLIENT", "No WebSocketClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("WEBSOCKET_READ_ERROR", "Failed to read WebSocket message: ${e.message}", null)
                }
            }
            
            "sendAndReadWebSocket" -> {
                try {
                    val message = call.argument<String>("message") ?: ""
                    
                    if (dartObjectCallbacks.containsKey("WebSocketClient")) {
                        // First send the message
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "WebSocketClient",
                            "method" to "send",
                            "args" to mapOf("message" to message)
                        ), object : MethodChannel.Result {
                            override fun success(sendResult: Any?) {
                                val sendData = sendResult as? Map<String, Any>
                                if (sendData?.get("success") == true) {
                                    // Then read the response
                                    channel.invokeMethod("dartObjectCallback", mapOf(
                                        "objectType" to "WebSocketClient",
                                        "method" to "read",
                                        "args" to emptyMap<String, Any>()
                                    ), object : MethodChannel.Result {
                                        override fun success(readResult: Any?) {
                                            result.success(readResult)
                                        }
                                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                            result.error("DART_WEBSOCKET_SEND_READ_READ_ERROR", "Send&Read read failed: $errorMessage", errorDetails)
                                        }
                                        override fun notImplemented() {
                                            result.error("DART_WEBSOCKET_SEND_READ_READ_NOT_IMPLEMENTED", "Send&Read read not implemented", null)
                                        }
                                    })
                                } else {
                                    result.error("WEBSOCKET_SEND_READ_SEND_FAILED", "Failed to send message for send&read", sendData)
                                }
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_WEBSOCKET_SEND_READ_SEND_ERROR", "Send&Read send failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_WEBSOCKET_SEND_READ_SEND_NOT_IMPLEMENTED", "Send&Read send not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_WEBSOCKET_CLIENT", "No WebSocketClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("WEBSOCKET_SEND_READ_ERROR", "Failed to send and read WebSocket: ${e.message}", null)
                }
            }
            
            "webSocketPingPong" -> {
                try {
                    if (dartObjectCallbacks.containsKey("WebSocketClient")) {
                        // Send PING and then read PONG
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "WebSocketClient",
                            "method" to "send",
                            "args" to mapOf("message" to "PING")
                        ), object : MethodChannel.Result {
                            override fun success(sendResult: Any?) {
                                val sendData = sendResult as? Map<String, Any>
                                if (sendData?.get("success") == true) {
                                    // Then read the response
                                    channel.invokeMethod("dartObjectCallback", mapOf(
                                        "objectType" to "WebSocketClient",
                                        "method" to "read",
                                        "args" to emptyMap<String, Any>()
                                    ), object : MethodChannel.Result {
                                        override fun success(readResult: Any?) {
                                            result.success(readResult)
                                        }
                                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                            result.error("DART_WEBSOCKET_PING_PONG_READ_ERROR", "Ping-pong read failed: $errorMessage", errorDetails)
                                        }
                                        override fun notImplemented() {
                                            result.error("DART_WEBSOCKET_PING_PONG_READ_NOT_IMPLEMENTED", "Ping-pong read not implemented", null)
                                        }
                                    })
                                } else {
                                    result.error("WEBSOCKET_PING_PONG_PING_FAILED", "Failed to send PING", sendData)
                                }
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_WEBSOCKET_PING_PONG_PING_ERROR", "Ping-pong ping failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_WEBSOCKET_PING_PONG_PING_NOT_IMPLEMENTED", "Ping-pong ping not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_WEBSOCKET_CLIENT", "No WebSocketClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("WEBSOCKET_PING_PONG_ERROR", "Failed to ping-pong WebSocket: ${e.message}", null)
                }
            }
            
            "sendBatchWebSocketMessages" -> {
                try {
                    val messages = call.argument<List<String>>("messages") ?: emptyList()
                    
                    if (dartObjectCallbacks.containsKey("WebSocketClient")) {
                        // Simulate batch operation by sending the first message
                        val firstMessage = messages.firstOrNull() ?: "batch_demo"
                        
                        channel.invokeMethod("dartObjectCallback", mapOf(
                            "objectType" to "WebSocketClient",
                            "method" to "send",
                            "args" to mapOf("message" to "BATCH: ${messages.joinToString(", ")}")
                        ), object : MethodChannel.Result {
                            override fun success(dartResult: Any?) {
                                // Return a list of results (simulated)
                                val batchResults = messages.map { msg ->
                                    mapOf(
                                        "success" to true,
                                        "message" to "Batch processed: $msg",
                                        "errorMessage" to "",
                                        "connectionStatus" to "connected",
                                        "timestamp" to (System.currentTimeMillis() / 1000)
                                    )
                                }
                                result.success(batchResults)
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                result.error("DART_WEBSOCKET_BATCH_ERROR", "Dart WebSocket batch failed: $errorMessage", errorDetails)
                            }
                            override fun notImplemented() {
                                result.error("DART_WEBSOCKET_BATCH_NOT_IMPLEMENTED", "Dart WebSocket batch not implemented", null)
                            }
                        })
                    } else {
                        result.error("NO_WEBSOCKET_CLIENT", "No WebSocketClient object registered", null)
                    }
                } catch (e: Exception) {
                    result.error("WEBSOCKET_BATCH_ERROR", "Failed to send batch WebSocket messages: ${e.message}", null)
                }
            }
            
            "cleanup" -> {
                try {
                    callbackRegistered = false
                    isInitialized = false
                    dartObjectCallbacks.clear()
                    Log.d("FlutterUniffiDemo", "Cleanup completed (Android demo mode)")
                    result.success("Cleanup completed (Android demo mode)")
                } catch (e: Exception) {
                    result.error("CLEANUP_ERROR", "Failed to cleanup: ${e.message}", null)
                }
            }
      
      else -> {
      result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  // StreamHandler implementation for event callbacks
  override fun onListen(arguments: Any?, events: EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
