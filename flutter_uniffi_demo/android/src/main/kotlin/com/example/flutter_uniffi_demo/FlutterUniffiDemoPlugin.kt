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
          callbackRegistered = true
          Log.d("FlutterUniffiDemo", "Callback registered (Android demo mode)")
          result.success(1) // Return demo callback ID
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
