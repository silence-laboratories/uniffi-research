
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
  
  // Object callbacks registry
  final Map<String, DartCallbackObject> _dartObjects = {};
  final Map<String, String> _registeredObjects = {}; // objectType -> callbackId

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

      case 'dartObjectCallback':
        final args = call.arguments as Map<dynamic, dynamic>;
        final objectType = args['objectType'] as String;
        final methodName = args['method'] as String;
        final methodArgs = args['args'] as Map<dynamic, dynamic>;
        
        debugPrint('Native calling Dart object callback: $objectType.$methodName with args: $methodArgs');
        
        if (_dartObjects.containsKey(objectType)) {
          final object = _dartObjects[objectType];
          if (object != null) {
            // Call the appropriate method on the Dart object
            return _callObjectMethod(object, methodName, methodArgs);
          }
        }
        throw PlatformException(code: 'OBJECT_NOT_FOUND', message: 'Object not registered: $objectType');
        
      default:
        throw PlatformException(code: 'METHOD_NOT_IMPLEMENTED', message: 'Method ${call.method} not implemented');
    }
  }

  /// Call a method on a Dart callback object
  dynamic _callObjectMethod(DartCallbackObject object, String methodName, Map<dynamic, dynamic> args) {
    switch (object.objectType) {
      case 'DataProcessor':
        final processor = object as DartDataProcessor;
        switch (methodName) {
          case 'processItem':
            final item = args['item'] as String;
            return processor.processItem(item).toMap();
          case 'validateInput':
            final input = args['input'] as String;
            return processor.validateInput(input);
          case 'transformData':
            final data = List<String>.from(args['data'] as List);
            return processor.transformData(data);
          case 'getProcessorName':
            return processor.getProcessorName();
          default:
            throw PlatformException(code: 'UNKNOWN_METHOD', message: 'Unknown DataProcessor method: $methodName');
        }
        
      case 'UserProfileManager':
        final manager = object as DartUserProfileManager;
        switch (methodName) {
          case 'getUserInfo':
            final userId = args['userId'] as int;
            return manager.getUserInfo(userId).toMap();
          case 'updatePreferences':
            final userId = args['userId'] as int;
            final preferencesMap = args['preferences'] as Map<dynamic, dynamic>;
            final preferences = UserPreferences.fromMap(preferencesMap);
            return manager.updatePreferences(userId, preferences);
          case 'calculateScore':
            final userId = args['userId'] as int;
            final metrics = List<double>.from(args['metrics'] as List);
            return manager.calculateScore(userId, metrics);
          case 'notifyUser':
            final userId = args['userId'] as int;
            final message = args['message'] as String;
            manager.notifyUser(userId, message);
            return null; // void method
                  default:
          throw PlatformException(code: 'UNKNOWN_METHOD', message: 'Unknown UserProfileManager method: $methodName');
      }

    case 'StorageClient':
      final client = object as DartStorageClient;
      switch (methodName) {
        case 'read':
          final key = args['key'] as String;
          return client.read(key).toMap();
        case 'write':
          final key = args['key'] as String;
          final value = args['value'] as String;
          return client.write(key, value).toMap();
        default:
          throw PlatformException(code: 'UNKNOWN_METHOD', message: 'Unknown StorageClient method: $methodName');
      }

    case 'WebSocketClient':
      final client = object as DartWebSocketClient;
      switch (methodName) {
        case 'send':
          final message = args['message'] as String;
          return client.send(message).toMap();
        case 'read':
          return client.read().toMap();
        default:
          throw PlatformException(code: 'UNKNOWN_METHOD', message: 'Unknown WebSocketClient method: $methodName');
      }
      
    default:
      throw PlatformException(code: 'UNKNOWN_OBJECT_TYPE', message: 'Unknown object type: ${object.objectType}');
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

  /// Register a Dart callback object
  Future<void> registerDartObject(DartCallbackObject object) async {
    try {
      _dartObjects[object.objectType] = object;
      
      // Generate a unique callback ID for this object type
      final objectCallbackId = 'dart_object_${object.objectType}_${DateTime.now().millisecondsSinceEpoch}';
      _registeredObjects[object.objectType] = objectCallbackId;
      
      // Register the object with the native side
      await _channel.invokeMethod('registerDartObject', {
        'objectType': object.objectType,
        'callbackId': objectCallbackId,
      });
      
      debugPrint('Registered Dart object: ${object.objectType}');
    } catch (e) {
      debugPrint('Failed to register Dart object: $e');
      rethrow;
    }
  }

  /// Create and use a DataProcessingService with Dart callbacks
  Future<Map<String, dynamic>?> processDataItem(String item) async {
    try {
      final result = await _channel.invokeMethod('processDataItem', {
        'item': item,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('Failed to process data item: $e');
      rethrow;
    }
  }

  /// Validate and process data using Dart DataProcessor
  Future<Map<String, dynamic>?> validateAndProcess(String input) async {
    try {
      final result = await _channel.invokeMethod('validateAndProcess', {
        'input': input,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('Failed to validate and process: $e');
      rethrow;
    }
  }

  /// Transform data using Dart DataProcessor
  Future<List<String>> transformBatchData(List<String> data) async {
    try {
      final result = await _channel.invokeMethod('transformBatchData', {
        'data': data,
      });
      return List<String>.from(result as List);
    } catch (e) {
      debugPrint('Failed to transform batch data: $e');
      rethrow;
    }
  }

  /// Get user info using Dart UserProfileManager
  Future<Map<String, dynamic>?> getUserInfo(int userId) async {
    try {
      final result = await _channel.invokeMethod('getUserInfo', {
        'userId': userId,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('Failed to get user info: $e');
      rethrow;
    }
  }

  /// Update user preferences using Dart UserProfileManager
  Future<bool> updateUserPreferences(int userId, UserPreferences preferences) async {
    try {
      final result = await _channel.invokeMethod('updateUserPreferences', {
        'userId': userId,
        'preferences': preferences.toMap(),
      });
      return result as bool;
    } catch (e) {
      debugPrint('Failed to update user preferences: $e');
      rethrow;
    }
  }

  /// Calculate user score using Dart UserProfileManager
  Future<double> calculateUserScore(int userId, List<double> metrics) async {
    try {
      final result = await _channel.invokeMethod('calculateUserScore', {
        'userId': userId,
        'metrics': metrics,
      });
      return result as double;
    } catch (e) {
      debugPrint('Failed to calculate user score: $e');
      rethrow;
    }
  }

  /// Send notification using Dart UserProfileManager
  Future<void> sendUserNotification(int userId, String message) async {
    try {
      await _channel.invokeMethod('sendUserNotification', {
        'userId': userId,
        'message': message,
      });
    } catch (e) {
      debugPrint('Failed to send user notification: $e');
      rethrow;
    }
  }

  // Storage Client methods
  /// Write data to storage using Dart StorageClient
  Future<Map<String, dynamic>?> writeToStorage(String key, String value) async {
    try {
      final result = await _channel.invokeMethod('writeToStorage', {
        'key': key,
        'value': value,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to write to storage: $e');
      rethrow;
    }
  }

  /// Read data from storage using Dart StorageClient
  Future<Map<String, dynamic>?> readFromStorage(String key) async {
    try {
      final result = await _channel.invokeMethod('readFromStorage', {
        'key': key,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to read from storage: $e');
      rethrow;
    }
  }

  /// Copy data in storage using Dart StorageClient (read then write)
  Future<Map<String, dynamic>?> copyStorageData(String sourceKey, String targetKey) async {
    try {
      final result = await _channel.invokeMethod('copyStorageData', {
        'sourceKey': sourceKey,
        'targetKey': targetKey,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to copy storage data: $e');
      rethrow;
    }
  }

  /// Backup multiple keys using Dart StorageClient
  Future<Map<String, dynamic>?> backupMultipleStorageKeys(List<String> keys, String backupKey) async {
    try {
      final result = await _channel.invokeMethod('backupMultipleStorageKeys', {
        'keys': keys,
        'backupKey': backupKey,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to backup multiple storage keys: $e');
      rethrow;
    }
  }

  // WebSocket Client methods
  /// Send message using Dart WebSocketClient
  Future<Map<String, dynamic>?> sendWebSocketMessage(String message) async {
    try {
      final result = await _channel.invokeMethod('sendWebSocketMessage', {
        'message': message,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to send WebSocket message: $e');
      rethrow;
    }
  }

  /// Read message using Dart WebSocketClient
  Future<Map<String, dynamic>?> readWebSocketMessage() async {
    try {
      final result = await _channel.invokeMethod('readWebSocketMessage');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to read WebSocket message: $e');
      rethrow;
    }
  }

  /// Send and read using Dart WebSocketClient (combined operation)
  Future<Map<String, dynamic>?> sendAndReadWebSocket(String message) async {
    try {
      final result = await _channel.invokeMethod('sendAndReadWebSocket', {
        'message': message,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to send and read WebSocket: $e');
      rethrow;
    }
  }

  /// WebSocket ping-pong using Dart WebSocketClient
  Future<Map<String, dynamic>?> webSocketPingPong() async {
    try {
      final result = await _channel.invokeMethod('webSocketPingPong');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Failed to WebSocket ping-pong: $e');
      rethrow;
    }
  }

  /// Send batch messages using Dart WebSocketClient
  Future<List<Map<String, dynamic>>> sendBatchWebSocketMessages(List<String> messages) async {
    try {
      final result = await _channel.invokeMethod('sendBatchWebSocketMessages', {
        'messages': messages,
      });
      if (result is List) {
        return result.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to send batch WebSocket messages: $e');
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

/// Base class for Dart callback objects
abstract class DartCallbackObject {
  String get objectType;
}

/// Dart implementation of DataProcessor
class DartDataProcessor extends DartCallbackObject {
  @override
  String get objectType => 'DataProcessor';

  ProcessResult processItem(String item) {
    // Default implementation - can be overridden
    return ProcessResult(
      success: true,
      result: 'Processed: $item',
      metadata: 'DartDataProcessor',
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  bool validateInput(String input) {
    // Default validation - can be overridden
    return input.isNotEmpty && input.length < 1000;
  }

  List<String> transformData(List<String> data) {
    // Default transformation - can be overridden
    return data.map((item) => 'DART_PROCESSED_$item').toList();
  }

  String getProcessorName() {
    return 'DartDataProcessor';
  }
}

/// Dart implementation of UserProfileManager
class DartUserProfileManager extends DartCallbackObject {
  @override
  String get objectType => 'UserProfileManager';

  UserInfo getUserInfo(int userId) {
    // Default implementation - can be overridden
    return UserInfo(
      id: userId,
      name: 'Dart User $userId',
      email: 'dartuser$userId@example.com',
      level: userId % 10,
    );
  }

  bool updatePreferences(int userId, UserPreferences preferences) {
    // Default implementation - can be overridden
    debugPrint('Dart: Updating preferences for user $userId: theme=${preferences.theme}');
    return true;
  }

  double calculateScore(int userId, List<double> metrics) {
    // Default implementation - can be overridden
    if (metrics.isEmpty) return 0.0;
    
    double sum = metrics.reduce((a, b) => a + b);
    double average = sum / metrics.length;
    
    // Add some Dart-specific logic
    double bonus = userId % 2 == 0 ? 5.0 : 0.0;
    return average + bonus;
  }

  void notifyUser(int userId, String message) {
    // Default implementation - can be overridden
    debugPrint('🔔 Dart Notification for user $userId: $message');
  }
}

/// Data structures matching Rust definitions
class ProcessResult {
  final bool success;
  final String result;
  final String metadata;
  final int timestamp;

  ProcessResult({
    required this.success,
    required this.result,
    required this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'result': result,
      'metadata': metadata,
      'timestamp': timestamp,
    };
  }

  factory ProcessResult.fromMap(Map<dynamic, dynamic> map) {
    return ProcessResult(
      success: map['success'] as bool,
      result: map['result'] as String,
      metadata: map['metadata'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}

class UserInfo {
  final int id;
  final String name;
  final String email;
  final int level;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'level': level,
    };
  }

  factory UserInfo.fromMap(Map<dynamic, dynamic> map) {
    return UserInfo(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      level: map['level'] as int,
    );
  }
}

class UserPreferences {
  final String theme;
  final bool notificationsEnabled;
  final String language;
  final bool autoSave;

  UserPreferences({
    required this.theme,
    required this.notificationsEnabled,
    required this.language,
    required this.autoSave,
  });

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'autoSave': autoSave,
    };
  }

  factory UserPreferences.fromMap(Map<dynamic, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] as String,
      notificationsEnabled: map['notificationsEnabled'] as bool,
      language: map['language'] as String,
      autoSave: map['autoSave'] as bool,
    );
  }
}

/// Dart implementation of StorageClient
class DartStorageClient extends DartCallbackObject {
  @override
  String get objectType => 'StorageClient';

  // In-memory storage for demo purposes
  final Map<String, String> _storage = {};

  StorageResult read(String key) {
    debugPrint('🗄️ DartStorageClient.read called with key: $key');
    
    if (_storage.containsKey(key)) {
      final value = _storage[key]!;
      debugPrint('🗄️ Found value: $value');
      return StorageResult(
        success: true,
        data: value,
        errorMessage: '',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } else {
      debugPrint('🗄️ Key not found: $key');
      return StorageResult(
        success: false,
        data: '',
        errorMessage: 'Key "$key" not found in storage',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  StorageResult write(String key, String value) {
    debugPrint('🗄️ DartStorageClient.write called: $key = $value');
    
    try {
      _storage[key] = value;
      debugPrint('🗄️ Successfully stored: $key = $value');
      return StorageResult(
        success: true,
        data: value,
        errorMessage: '',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } catch (e) {
      debugPrint('🗄️ Failed to store: $e');
      return StorageResult(
        success: false,
        data: '',
        errorMessage: 'Failed to write: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }
}

/// Dart implementation of WebSocketClient
class DartWebSocketClient extends DartCallbackObject {
  @override
  String get objectType => 'WebSocketClient';

  // Simulate WebSocket connection state
  bool _isConnected = true;
  final List<String> _messageQueue = [];
  int _messageCounter = 0;

  WebSocketResult send(String message) {
    debugPrint('🔌 DartWebSocketClient.send called with: $message');
    
    if (!_isConnected) {
      return WebSocketResult(
        success: false,
        message: '',
        errorMessage: 'WebSocket not connected',
        connectionStatus: 'disconnected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    try {
      // Simulate processing the message
      _messageCounter++;
      debugPrint('🔌 Sending message #$_messageCounter: $message');
      
      // Add simulated response to queue
      if (message.toUpperCase() == 'PING') {
        _messageQueue.add('PONG');
      } else {
        _messageQueue.add('Echo: $message (response #$_messageCounter)');
      }

      return WebSocketResult(
        success: true,
        message: 'Message sent successfully: $message',
        errorMessage: '',
        connectionStatus: 'connected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } catch (e) {
      debugPrint('🔌 Failed to send message: $e');
      return WebSocketResult(
        success: false,
        message: '',
        errorMessage: 'Failed to send: $e',
        connectionStatus: _isConnected ? 'connected' : 'disconnected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  WebSocketResult read() {
    debugPrint('🔌 DartWebSocketClient.read called');
    
    if (!_isConnected) {
      return WebSocketResult(
        success: false,
        message: '',
        errorMessage: 'WebSocket not connected',
        connectionStatus: 'disconnected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    if (_messageQueue.isNotEmpty) {
      final message = _messageQueue.removeAt(0);
      debugPrint('🔌 Read message from queue: $message');
      return WebSocketResult(
        success: true,
        message: message,
        errorMessage: '',
        connectionStatus: 'connected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } else {
      debugPrint('🔌 No messages in queue');
      return WebSocketResult(
        success: true,
        message: 'No new messages',
        errorMessage: '',
        connectionStatus: 'connected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }
}

/// Storage result data structure
class StorageResult {
  final bool success;
  final String data;
  final String errorMessage;
  final int timestamp;

  StorageResult({
    required this.success,
    required this.data,
    required this.errorMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'data': data,
      'errorMessage': errorMessage,
      'timestamp': timestamp,
    };
  }

  factory StorageResult.fromMap(Map<dynamic, dynamic> map) {
    return StorageResult(
      success: map['success'] as bool,
      data: map['data'] as String,
      errorMessage: map['errorMessage'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}

/// WebSocket result data structure
class WebSocketResult {
  final bool success;
  final String message;
  final String errorMessage;
  final String connectionStatus;
  final int timestamp;

  WebSocketResult({
    required this.success,
    required this.message,
    required this.errorMessage,
    required this.connectionStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'errorMessage': errorMessage,
      'connectionStatus': connectionStatus,
      'timestamp': timestamp,
    };
  }

  factory WebSocketResult.fromMap(Map<dynamic, dynamic> map) {
    return WebSocketResult(
      success: map['success'] as bool,
      message: map['message'] as String,
      errorMessage: map['errorMessage'] as String,
      connectionStatus: map['connectionStatus'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}
