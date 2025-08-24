import Flutter
import UIKit

public class FlutterUniffiDemoPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var callbackService: CallbackService?
    private var callbackId: UInt32?
    
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
            do {
                callbackService = try CallbackService()
                result("Service initialized")
            } catch {
                result(FlutterError(code: "INIT_ERROR", message: "Failed to initialize service: \(error)", details: nil))
            }
            
        case "registerCallback":
            do {
                let callback = FlutterEventCallback(eventSink: self.eventSink)
                let id = try registerCallback(callback: callback)
                callbackId = id
                if let service = callbackService {
                    try setServiceCallback(service: service, callbackId: id)
                }
                result(Int(id))
            } catch {
                result(FlutterError(code: "CALLBACK_ERROR", message: "Failed to register callback: \(error)", details: nil))
            }
            
        case "getStatus":
            do {
                let status = try callbackService?.getStatus() ?? "Service not initialized"
                result(status)
            } catch {
                result(FlutterError(code: "STATUS_ERROR", message: "Failed to get status: \(error)", details: nil))
            }
            
        case "triggerEvent":
            do {
                guard let args = call.arguments as? [String: Any],
                      let eventType = args["eventType"] as? String,
                      let message = args["message"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                try callbackService?.triggerEvent(eventType: eventType, message: message)
                result("Event triggered")
            } catch {
                result(FlutterError(code: "EVENT_ERROR", message: "Failed to trigger event: \(error)", details: nil))
            }
            
        case "processData":
            do {
                guard let args = call.arguments as? [String: Any],
                      let size = args["size"] as? Int else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                let testData = try createTestData(size: UInt32(size))
                let processResult = try callbackService?.processData(data: testData)
                result(processResult)
            } catch {
                result(FlutterError(code: "PROCESS_ERROR", message: "Failed to process data: \(error)", details: nil))
            }
            
        case "simulateWork":
            do {
                guard let args = call.arguments as? [String: Any],
                      let duration = args["duration"] as? Int else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                // Run on background thread to avoid blocking
                DispatchQueue.global(qos: .background).async { [weak self] in
                    do {
                        try self?.callbackService?.simulateBackgroundWork(durationSeconds: UInt32(duration))
                        DispatchQueue.main.async {
                            result("Work completed")
                        }
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "WORK_ERROR", message: "Failed to simulate work: \(error)", details: nil))
                        }
                    }
                }
            } catch {
                result(FlutterError(code: "WORK_ERROR", message: "Failed to simulate work: \(error)", details: nil))
            }
            
        case "formatMessage":
            do {
                guard let args = call.arguments as? [String: Any],
                      let prefix = args["prefix"] as? String,
                      let content = args["content"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                let formatted = try formatMessage(prefix: prefix, content: content)
                result(formatted)
            } catch {
                result(FlutterError(code: "FORMAT_ERROR", message: "Failed to format message: \(error)", details: nil))
            }
            
        case "cleanup":
            do {
                if let id = callbackId {
                    try unregisterCallback(callbackId: id)
                }
                callbackService = nil
                callbackId = nil
                result("Cleanup completed")
            } catch {
                result(FlutterError(code: "CLEANUP_ERROR", message: "Failed to cleanup: \(error)", details: nil))
            }
            
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

// MARK: - FlutterEventCallback

class FlutterEventCallback: EventCallback {
    private var eventSink: FlutterEventSink?
    
    init(eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
    }
    
    func onEvent(eventType: String, message: String) {
        DispatchQueue.main.async { [self] in
            self.eventSink?([
                "type": "event",
                "eventType": eventType,
                "message": message
            ])
        }
    }
    
    func onDataReceived(data: Data) -> String {
        let bytes = Array(data)
        let preview = Array(bytes.prefix(10))
        let result = "iOS processed \(data.count) bytes: \(preview)"
        
        DispatchQueue.main.async { [self] in
            self.eventSink?([
                "type": "dataProcessed",
                "result": result,
                "dataSize": data.count
            ])
        }
        
        return result
    }
}
