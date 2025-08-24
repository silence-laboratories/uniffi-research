import Flutter
import UIKit

public class FlutterUniffiDemoPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    // For demonstration purposes, we'll simulate the Rust callbacks
    private var isInitialized = false
    private var callbackRegistered = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_uniffi_demo", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_uniffi_demo_events", binaryMessenger: registrar.messenger())
        
        let instance = FlutterUniffiDemoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeService":
            isInitialized = true
            print("Service initialized (iOS demo mode)")
            result("Service initialized (iOS demo mode)")
            
        case "registerCallback":
            if !isInitialized {
                result(FlutterError(code: "NOT_INITIALIZED", message: "Service not initialized", details: nil))
                return
            }
            callbackRegistered = true
            print("Callback registered (iOS demo mode)")
            result(1) // Return demo callback ID
            
        case "getStatus":
            let status: String
            if !isInitialized {
                status = "Service not initialized"
            } else if !callbackRegistered {
                status = "No callback registered"
            } else {
                status = "Callback registered (iOS demo mode)"
            }
            result(status)
            
        case "triggerEvent":
            guard let args = call.arguments as? [String: Any],
                  let eventType = args["eventType"] as? String,
                  let message = args["message"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            
            // Simulate callback event
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?([
                    "type": "event",
                    "eventType": eventType,
                    "message": "iOS demo received: \(message)"
                ])
            }
            
            result("Event triggered (iOS demo mode)")
            
        case "processData":
            guard let args = call.arguments as? [String: Any],
                  let size = args["size"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            
            // Simulate data processing and callback
            let simulatedResult = "iOS demo processed \(size) bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]"
            
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?([
                    "type": "dataProcessed",
                    "result": simulatedResult,
                    "dataSize": size
                ])
            }
            
            result(simulatedResult)
            
        case "simulateWork":
            guard let args = call.arguments as? [String: Any],
                  let duration = args["duration"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            
            // Simulate background work
            DispatchQueue.global(qos: .background).async { [weak self] in
                Thread.sleep(forTimeInterval: TimeInterval(duration))
                
                DispatchQueue.main.async {
                    self?.eventSink?([
                        "type": "event",
                        "eventType": "work_completed",
                        "message": "iOS demo: Background work completed after \(duration) seconds"
                    ])
                    result("Work completed (iOS demo mode)")
                }
            }
            
        case "formatMessage":
            guard let args = call.arguments as? [String: Any],
                  let prefix = args["prefix"] as? String,
                  let content = args["content"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            let formatted = "\(prefix): \(content) (iOS demo mode)"
            result(formatted)
            
        case "cleanup":
            callbackRegistered = false
            isInitialized = false
            print("Cleanup completed (iOS demo mode)")
            result("Cleanup completed (iOS demo mode)")
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
