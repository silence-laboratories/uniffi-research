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
            
            "cleanup" -> {
                try {
                    callbackRegistered = false
                    isInitialized = false
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
