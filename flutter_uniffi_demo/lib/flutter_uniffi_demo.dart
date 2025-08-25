
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_uniffi_demo_platform_interface.dart';

/// The main class for interacting with the UniFFI callback demo
class FlutterUniffiDemo {
  FlutterUniffiDemo._();

  static FlutterUniffiDemo? _instance;
  static FlutterUniffiDemo get instance => _instance ??= FlutterUniffiDemo._();

  static const MethodChannel _channel = MethodChannel('flutter_uniffi_demo');
  static const EventChannel _eventChannel = EventChannel('flutter_uniffi_demo_events');

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<CallbackEvent> _eventController = StreamController<CallbackEvent>.broadcast();
  
  // Callback functions registry
  final Map<String, Function> _dartCallbacks = {};
  String? _registeredCallbackId;

  /// Stream of callback events from the Rust library
  Stream<CallbackEvent> get eventStream => _eventController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the service and start listening for events
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the native service
      await _channel.invokeMethod('initializeService');
      
      // Set up method call handler for callback invocations from native
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Start listening to events
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          final callbackEvent = CallbackEvent.fromMap(event);
          _eventController.add(callbackEvent);
        },
        onError: (error) {
          debugPrint('Event stream error: $error');
        },
      );
      
      _isInitialized = true;
      debugPrint('FlutterUniffiDemo initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize FlutterUniffiDemo: $e');
      rethrow;
    }
  }

  /// Handle method calls from native platforms (for callbacks)
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'dartCallback':
        final args = call.arguments as Map<dynamic, dynamic>;
        final callbackId = args['callbackId'] as String;
        final functionName = args['function'] as String;
        final functionArgs = args['args'] as Map<dynamic, dynamic>;
        
        debugPrint('Native calling Dart callback: $functionName with args: $functionArgs');
        
        if (_dartCallbacks.containsKey(functionName)) {
          final callback = _dartCallbacks[functionName];
          if (callback != null) {
            // Call the registered Dart function
            switch (functionName) {
              case 'addTwoNumbers':
                final a = functionArgs['a'] as int;
                final b = functionArgs['b'] as int;
                return (callback as int Function(int, int))(a, b);
              default:
                throw PlatformException(code: 'UNKNOWN_CALLBACK', message: 'Unknown callback function: $functionName');
            }
          }
        }
        throw PlatformException(code: 'CALLBACK_NOT_FOUND', message: 'Callback function not registered: $functionName');
        
      default:
        throw PlatformException(code: 'METHOD_NOT_IMPLEMENTED', message: 'Method ${call.method} not implemented');
    }
  }

  /// Register a Dart callback function
  Future<void> registerDartCallback(String functionName, Function callback) async {
    try {
      _dartCallbacks[functionName] = callback;
      
      // Generate a unique callback ID if not already set
      _registeredCallbackId ??= 'dart_callback_${DateTime.now().millisecondsSinceEpoch}';
      
      // Register the callback with the native side
      await _channel.invokeMethod('registerCallback', {
        'callbackId': _registeredCallbackId,
      });
      
      debugPrint('Registered Dart callback: $functionName');
    } catch (e) {
      debugPrint('Failed to register Dart callback: $e');
      rethrow;
    }
  }

  /// Get the current service status
  Future<String> getStatus() async {
    try {
      final status = await _channel.invokeMethod<String>('getStatus');
      return status ?? 'Unknown status';
    } catch (e) {
      debugPrint('Failed to get status: $e');
      rethrow;
    }
  }

  /// Trigger an event in the Rust library
  Future<void> triggerEvent(String eventType, String message) async {
    try {
      await _channel.invokeMethod('triggerEvent', {
        'eventType': eventType,
        'message': message,
      });
    } catch (e) {
      debugPrint('Failed to trigger event: $e');
      rethrow;
    }
  }

  /// Process data through the Rust library and callbacks
  Future<String?> processData(int size) async {
    try {
      final result = await _channel.invokeMethod<String>('processData', {
        'size': size,
      });
      return result;
    } catch (e) {
      debugPrint('Failed to process data: $e');
      rethrow;
    }
  }

  /// Simulate background work in Rust (will trigger callback events)
  Future<void> simulateWork(int durationSeconds) async {
    try {
      await _channel.invokeMethod('simulateWork', {
        'duration': durationSeconds,
      });
    } catch (e) {
      debugPrint('Failed to simulate work: $e');
      rethrow;
    }
  }

  /// Format a message using the Rust utility function
  Future<String> formatMessage(String prefix, String content) async {
    try {
      final result = await _channel.invokeMethod<String>('formatMessage', {
        'prefix': prefix,
        'content': content,
      });
      return result ?? '';
    } catch (e) {
      debugPrint('Failed to format message: $e');
      rethrow;
    }
  }

  /// Add two numbers using the callback interface
  Future<int> addTwoNumbers(int a, int b) async {
    try {
      final result = await _channel.invokeMethod<int>('addTwoNumbers', {
        'a': a,
        'b': b,
      });
      return result ?? 0;
    } catch (e) {
      debugPrint('Failed to add numbers: $e');
      rethrow;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      await _eventSubscription?.cancel();
      await _channel.invokeMethod('cleanup');
      await _eventController.close();
      _isInitialized = false;
      _instance = null;
    } catch (e) {
      debugPrint('Failed to dispose FlutterUniffiDemo: $e');
    }
  }
}

/// Represents a callback event from the Rust library
class CallbackEvent {
  final CallbackEventType type;
  final String? eventType;
  final String? message;
  final String? result;
  final int? dataSize;

  CallbackEvent({
    required this.type,
    this.eventType,
    this.message,
    this.result,
    this.dataSize,
  });

  factory CallbackEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeString = map['type'] as String;
    final type = CallbackEventType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => CallbackEventType.unknown,
    );

    return CallbackEvent(
      type: type,
      eventType: map['eventType'] as String?,
      message: map['message'] as String?,
      result: map['result']?.toString(), // Convert any type to string
      dataSize: map['dataSize'] as int?,
    );
  }

  @override
  String toString() {
    switch (type) {
      case CallbackEventType.event:
        return 'Event($eventType): $message';
      case CallbackEventType.dataProcessed:
        return 'DataProcessed: $result (${dataSize} bytes)';
      case CallbackEventType.calculationResult:
        return 'Calculation: $message';
      case CallbackEventType.unknown:
        return 'Unknown event';
    }
  }
}

/// Types of callback events
enum CallbackEventType {
  event,
  dataProcessed,
  calculationResult,
  unknown,
}
