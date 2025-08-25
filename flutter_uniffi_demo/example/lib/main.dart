import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_uniffi_demo/flutter_uniffi_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFFI Callback Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'UniFFI Callback Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _uniffiDemo = FlutterUniffiDemo.instance;
  StreamSubscription<CallbackEvent>? _eventSubscription;
  
  List<CallbackEvent> _events = [];
  String _status = 'Not initialized';
  bool _isLoading = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _uniffiDemo.dispose();
    super.dispose();
  }

  Future<void> _initializePlugin() async {
    setState(() => _isLoading = true);
    
    try {
      await _uniffiDemo.initialize();
      
      // Register Dart callback functions
      await _uniffiDemo.registerDartCallback('addTwoNumbers', _dartAddTwoNumbers);
      
      // Register Dart callback objects
      await _uniffiDemo.registerDartObject(MyCustomDataProcessor());
      await _uniffiDemo.registerDartObject(MyCustomUserManager());
      await _uniffiDemo.registerDartObject(MyCustomStorageClient());
      await _uniffiDemo.registerDartObject(MyCustomWebSocketClient());
      
      // Listen to callback events
      _eventSubscription = _uniffiDemo.eventStream.listen((event) {
        setState(() {
          _events.insert(0, event);
          // Keep only the last 20 events
          if (_events.length > 20) {
            _events = _events.take(20).toList();
          }
        });
      });
      
      await _updateStatus();
    } catch (e) {
      _showError('Failed to initialize: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Dart implementation of the add two numbers callback
  int _dartAddTwoNumbers(int a, int b) {
    final result = a + b;
    debugPrint('🎯 Dart callback executed: $a + $b = $result');
    
    // You can add any custom Dart logic here!
    // For example, logging, validation, complex calculations, etc.
    if (result > 50) {
      debugPrint('💡 Large result detected: $result');
    }
    
    return result;
  }

  Future<void> _processDataItem() async {
    try {
      final result = await _uniffiDemo.processDataItem('Flutter test data');
      setState(() => _lastResult = 'Data Processing: ${result?['result']}');
      _showSuccess('Data processed via Dart object!');
    } catch (e) {
      _showError('Failed to process data: $e');
    }
  }

  Future<void> _validateAndProcess() async {
    try {
      final result = await _uniffiDemo.validateAndProcess('dart validation test');
      setState(() => _lastResult = 'Validation & Processing: ${result?['result']}');
      _showSuccess('Validation and processing completed!');
    } catch (e) {
      _showError('Failed to validate and process: $e');
    }
  }

  Future<void> _transformBatchData() async {
    try {
      final result = await _uniffiDemo.transformBatchData(['item1', 'flutter', 'dart']);
      setState(() => _lastResult = 'Batch Transform: ${result.join(', ')}');
      _showSuccess('Batch transformation completed!');
    } catch (e) {
      _showError('Failed to transform batch data: $e');
    }
  }

  Future<void> _getUserInfo() async {
    try {
      final result = await _uniffiDemo.getUserInfo(123);
      setState(() => _lastResult = 'User Info: ${result?['name']} (${result?['email']})');
      _showSuccess('User info retrieved!');
    } catch (e) {
      _showError('Failed to get user info: $e');
    }
  }

  Future<void> _calculateUserScore() async {
    try {
      final result = await _uniffiDemo.calculateUserScore(123, [85.5, 92.0, 78.3]);
      setState(() => _lastResult = 'User Score: ${result.toStringAsFixed(2)}');
      _showSuccess('User score calculated!');
    } catch (e) {
      _showError('Failed to calculate user score: $e');
    }
  }

  Future<void> _sendNotification() async {
    try {
      await _uniffiDemo.sendUserNotification(123, 'Hello from Flutter!');
      setState(() => _lastResult = 'Notification sent to user 123');
      _showSuccess('Notification sent via Dart object!');
    } catch (e) {
      _showError('Failed to send notification: $e');
    }
  }

  // Storage Client methods
  Future<void> _writeToStorage() async {
    try {
      final result = await _uniffiDemo.writeToStorage('flutter_key', 'Hello from Flutter Storage!');
      setState(() => _lastResult = 'Storage Write: ${result?['success'] ? 'Success' : 'Failed'}');
      _showSuccess('Data written to storage!');
    } catch (e) {
      _showError('Failed to write to storage: $e');
    }
  }

  Future<void> _readFromStorage() async {
    try {
      final result = await _uniffiDemo.readFromStorage('flutter_key');
      setState(() => _lastResult = 'Storage Read: ${result?['data'] ?? 'No data'}');
      _showSuccess('Data read from storage!');
    } catch (e) {
      _showError('Failed to read from storage: $e');
    }
  }

  Future<void> _copyStorageData() async {
    try {
      final result = await _uniffiDemo.copyStorageData('flutter_key', 'backup_key');
      setState(() => _lastResult = 'Storage Copy: ${result?['success'] ? 'Success' : 'Failed'}');
      _showSuccess('Data copied in storage!');
    } catch (e) {
      _showError('Failed to copy storage data: $e');
    }
  }

  Future<void> _backupMultipleKeys() async {
    try {
      final result = await _uniffiDemo.backupMultipleStorageKeys(['flutter_key', 'backup_key', 'nonexistent'], 'full_backup');
      setState(() => _lastResult = 'Storage Backup: ${result?['success'] ? 'Success' : 'Failed'}');
      _showSuccess('Multiple keys backed up!');
    } catch (e) {
      _showError('Failed to backup multiple keys: $e');
    }
  }

  // WebSocket Client methods
  Future<void> _sendWebSocketMessage() async {
    try {
      final result = await _uniffiDemo.sendWebSocketMessage('Hello WebSocket from Flutter!');
      setState(() => _lastResult = 'WebSocket Send: ${result?['message'] ?? 'No response'}');
      _showSuccess('Message sent via WebSocket!');
    } catch (e) {
      _showError('Failed to send WebSocket message: $e');
    }
  }

  Future<void> _readWebSocketMessage() async {
    try {
      final result = await _uniffiDemo.readWebSocketMessage();
      setState(() => _lastResult = 'WebSocket Read: ${result?['message'] ?? 'No messages'}');
      _showSuccess('Message read from WebSocket!');
    } catch (e) {
      _showError('Failed to read WebSocket message: $e');
    }
  }

  Future<void> _sendAndReadWebSocket() async {
    try {
      final result = await _uniffiDemo.sendAndReadWebSocket('Ping from Flutter');
      setState(() => _lastResult = 'WebSocket Send&Read: ${result?['message'] ?? 'No response'}');
      _showSuccess('Send and read completed!');
    } catch (e) {
      _showError('Failed to send and read: $e');
    }
  }

  Future<void> _webSocketPingPong() async {
    try {
      final result = await _uniffiDemo.webSocketPingPong();
      setState(() => _lastResult = 'WebSocket Ping-Pong: ${result?['message'] ?? 'No response'}');
      _showSuccess('Ping-pong completed!');
    } catch (e) {
      _showError('Failed to ping-pong: $e');
    }
  }

  Future<void> _sendBatchWebSocketMessages() async {
    try {
      final result = await _uniffiDemo.sendBatchWebSocketMessages(['msg1', 'msg2', 'flutter']);
      setState(() => _lastResult = 'WebSocket Batch: ${result.length} operations completed');
      _showSuccess('Batch messages sent!');
    } catch (e) {
      _showError('Failed to send batch messages: $e');
    }
  }

  Future<void> _updateStatus() async {
    try {
      final status = await _uniffiDemo.getStatus();
      setState(() => _status = status);
    } catch (e) {
      _showError('Failed to get status: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _triggerEvent() async {
    try {
      await _uniffiDemo.triggerEvent(
        'flutter_event',
        'Hello from Flutter at ${DateTime.now()}!',
      );
      _showSuccess('Event triggered successfully');
    } catch (e) {
      _showError('Failed to trigger event: $e');
    }
  }

  Future<void> _processData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _uniffiDemo.processData(15);
      setState(() => _lastResult = result);
      _showSuccess('Data processed successfully');
    } catch (e) {
      _showError('Failed to process data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateWork() async {
    setState(() => _isLoading = true);
    try {
      await _uniffiDemo.simulateWork(3);
      _showSuccess('Background work completed');
    } catch (e) {
      _showError('Failed to simulate work: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _formatMessage() async {
    try {
      final result = await _uniffiDemo.formatMessage(
        'FLUTTER',
        'Message formatted at ${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() => _lastResult = result);
      _showSuccess('Message formatted successfully');
    } catch (e) {
      _showError('Failed to format message: $e');
    }
  }

  Future<void> _addTwoNumbers() async {
    try {
      final a = 15;
      final b = 27;
      final result = await _uniffiDemo.addTwoNumbers(a, b);
      setState(() => _lastResult = 'Addition result: $a + $b = $result');
      _showSuccess('Numbers added successfully via callback');
    } catch (e) {
      _showError('Failed to add numbers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(_status),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateStatus,
                            child: const Text('Refresh Status'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Callbacks',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _triggerEvent,
                                icon: const Icon(Icons.send),
                                label: const Text('Trigger Event'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _processData,
                                icon: const Icon(Icons.data_usage),
                                label: const Text('Process Data'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _simulateWork,
                                icon: const Icon(Icons.work),
                                label: const Text('Simulate Work (3s)'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _formatMessage,
                                icon: const Icon(Icons.format_quote),
                                label: const Text('Format Message'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addTwoNumbers,
                                icon: const Icon(Icons.calculate),
                                label: const Text('Add Numbers'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Object Callbacks - DataProcessor',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _processDataItem,
                                icon: const Icon(Icons.memory),
                                label: const Text('Process Data Item'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _validateAndProcess,
                                icon: const Icon(Icons.verified),
                                label: const Text('Validate & Process'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _transformBatchData,
                                icon: const Icon(Icons.transform),
                                label: const Text('Transform Batch'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Object Callbacks - UserManager',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _getUserInfo,
                                icon: const Icon(Icons.person),
                                label: const Text('Get User Info'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _calculateUserScore,
                                icon: const Icon(Icons.score),
                                label: const Text('Calculate Score'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _sendNotification,
                                icon: const Icon(Icons.notifications),
                                label: const Text('Send Notification'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Object Callbacks - StorageClient',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _writeToStorage,
                                icon: const Icon(Icons.save),
                                label: const Text('Write to Storage'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _readFromStorage,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Read from Storage'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _copyStorageData,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Data'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _backupMultipleKeys,
                                icon: const Icon(Icons.backup),
                                label: const Text('Backup Keys'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Object Callbacks - WebSocketClient',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _sendWebSocketMessage,
                                icon: const Icon(Icons.send),
                                label: const Text('Send Message'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _readWebSocketMessage,
                                icon: const Icon(Icons.message),
                                label: const Text('Read Message'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _sendAndReadWebSocket,
                                icon: const Icon(Icons.sync),
                                label: const Text('Send & Read'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _webSocketPingPong,
                                icon: const Icon(Icons.sync_alt),
                                label: const Text('Ping-Pong'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _sendBatchWebSocketMessages,
                                icon: const Icon(Icons.burst_mode),
                                label: const Text('Batch Messages'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_lastResult != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Result',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(_lastResult!),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Callback Events (${_events.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_events.isEmpty)
                            const Text('No events yet. Try triggering some actions!')
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _events.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final event = _events[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    event.type == CallbackEventType.event
                                        ? Icons.event
                                        : event.type == CallbackEventType.calculationResult
                                            ? Icons.calculate
                                            : Icons.data_object,
                                    color: event.type == CallbackEventType.event
                                        ? Colors.blue
                                        : event.type == CallbackEventType.calculationResult
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                  title: Text(
                                    event.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

/// Custom DataProcessor implementation for the Flutter example
class MyCustomDataProcessor extends DartDataProcessor {
  @override
  ProcessResult processItem(String item) {
    debugPrint('🔧 MyCustomDataProcessor.processItem called with: $item');
    
    // Custom processing logic
    String processedResult;
    if (item.toLowerCase().contains('flutter')) {
      processedResult = '🎯 Flutter-specific processing: $item -> OPTIMIZED';
    } else if (item.toLowerCase().contains('dart')) {
      processedResult = '🎯 Dart-specific processing: $item -> ENHANCED';
    } else {
      processedResult = '🔧 Standard processing: $item -> PROCESSED';
    }
    
    return ProcessResult(
      success: true,
      result: processedResult,
      metadata: 'MyCustomDataProcessor v1.0',
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  @override
  bool validateInput(String input) {
    debugPrint('✅ MyCustomDataProcessor.validateInput called with: $input');
    
    // Custom validation logic
    final isValid = input.isNotEmpty && 
                   input.length >= 3 && 
                   input.length <= 100 &&
                   !input.contains(RegExp(r'[<>]')); // No HTML-like brackets
    
    debugPrint('✅ Validation result: $isValid');
    return isValid;
  }

  @override
  List<String> transformData(List<String> data) {
    debugPrint('🔄 MyCustomDataProcessor.transformData called with: $data');
    
    // Custom transformation logic
    return data.map((item) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'FLUTTER_TRANSFORMED_${item.toUpperCase()}_$timestamp';
    }).toList();
  }

  @override
  String getProcessorName() {
    return 'MyCustomDataProcessor (Flutter Edition)';
  }
}

/// Custom UserProfileManager implementation for the Flutter example
class MyCustomUserManager extends DartUserProfileManager {
  @override
  UserInfo getUserInfo(int userId) {
    debugPrint('👤 MyCustomUserManager.getUserInfo called for user: $userId');
    
    // Custom user info logic
    final userTypes = ['Admin', 'Developer', 'Designer', 'Tester', 'Manager'];
    final userType = userTypes[userId % userTypes.length];
    
    return UserInfo(
      id: userId,
      name: 'Flutter User $userId ($userType)',
      email: 'flutter.user$userId@dartlang.org',
      level: (userId % 10) + 1, // Level 1-10
    );
  }

  @override
  bool updatePreferences(int userId, UserPreferences preferences) {
    debugPrint('⚙️ MyCustomUserManager.updatePreferences called for user $userId');
    debugPrint('   Theme: ${preferences.theme}');
    debugPrint('   Notifications: ${preferences.notificationsEnabled}');
    debugPrint('   Language: ${preferences.language}');
    debugPrint('   Auto-save: ${preferences.autoSave}');
    
    // Custom preferences logic (e.g., save to local storage, validate, etc.)
    // For demo, always successful
    return true;
  }

  @override
  double calculateScore(int userId, List<double> metrics) {
    debugPrint('📊 MyCustomUserManager.calculateScore called for user $userId with metrics: $metrics');
    
    if (metrics.isEmpty) return 0.0;
    
    // Custom scoring algorithm
    double baseScore = metrics.reduce((a, b) => a + b) / metrics.length;
    
    // Flutter-specific bonuses
    double experienceBonus = userId > 100 ? 10.0 : 5.0;
    double consistencyBonus = metrics.every((m) => m > 70) ? 15.0 : 0.0;
    double flutterBonus = userId % 3 == 0 ? 8.0 : 0.0; // Every 3rd user gets Flutter bonus
    
    double finalScore = baseScore + experienceBonus + consistencyBonus + flutterBonus;
    
    debugPrint('📊 Score calculation: base=$baseScore, exp=$experienceBonus, consistency=$consistencyBonus, flutter=$flutterBonus => final=$finalScore');
    
    return finalScore;
  }

  @override
  void notifyUser(int userId, String message) {
    debugPrint('🔔 MyCustomUserManager.notifyUser called for user $userId');
    debugPrint('🔔 Message: $message');
    
    // Custom notification logic
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 Flutter notification sent at $timestamp to user $userId: $message');
  }
}

/// Custom StorageClient implementation for the Flutter example
class MyCustomStorageClient extends DartStorageClient {
  // Enhanced in-memory storage with metadata
  final Map<String, Map<String, dynamic>> _enhancedStorage = {};

  @override
  StorageResult read(String key) {
    debugPrint('🗄️ MyCustomStorageClient.read called with key: $key');
    
    if (_enhancedStorage.containsKey(key)) {
      final data = _enhancedStorage[key]!;
      final value = data['value'] as String;
      final writeTime = data['timestamp'] as int;
      
      debugPrint('🗄️ Found value: $value (written at $writeTime)');
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
        errorMessage: 'Key "$key" not found in Flutter storage',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  @override
  StorageResult write(String key, String value) {
    debugPrint('🗄️ MyCustomStorageClient.write called: $key = $value');
    
    try {
      // Enhanced storage with metadata
      _enhancedStorage[key] = {
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'writeCount': (_enhancedStorage[key]?['writeCount'] ?? 0) + 1,
        'source': 'Flutter App',
      };
      
      final writeCount = _enhancedStorage[key]!['writeCount'];
      debugPrint('🗄️ Successfully stored: $key = $value (write #$writeCount)');
      
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
        errorMessage: 'Flutter storage error: $e',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  // Additional Flutter-specific methods
  void printStorageStats() {
    debugPrint('📊 Storage Stats: ${_enhancedStorage.length} keys stored');
    for (final entry in _enhancedStorage.entries) {
      final metadata = entry.value;
      debugPrint('  ${entry.key}: ${metadata['writeCount']} writes, last: ${metadata['timestamp']}');
    }
  }
}

/// Custom WebSocketClient implementation for the Flutter example
class MyCustomWebSocketClient extends DartWebSocketClient {
  // Enhanced WebSocket simulation with Flutter-specific features
  bool _isFlutterConnected = true;
  final List<Map<String, dynamic>> _messageHistory = [];
  int _flutterMessageCounter = 0;
  final List<String> _flutterMessageQueue = [];

  @override
  WebSocketResult send(String message) {
    debugPrint('🔌 MyCustomWebSocketClient.send called with: $message');
    
    if (!_isFlutterConnected) {
      return WebSocketResult(
        success: false,
        message: '',
        errorMessage: 'Flutter WebSocket not connected',
        connectionStatus: 'disconnected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    try {
      _flutterMessageCounter++;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Log message history
      _messageHistory.add({
        'id': _flutterMessageCounter,
        'message': message,
        'timestamp': timestamp,
        'direction': 'outbound',
        'source': 'Flutter App',
      });
      
      debugPrint('🔌 Sending Flutter message #$_flutterMessageCounter: $message');
      
      // Flutter-specific response logic
      String response;
      if (message.toUpperCase() == 'PING') {
        response = 'PONG (from Flutter WebSocket)';
      } else if (message.toLowerCase().contains('flutter')) {
        response = '🎯 Flutter-optimized response: ${message.toUpperCase()}';
      } else if (message.toLowerCase().contains('dart')) {
        response = '🎯 Dart-enhanced response: ${message.toUpperCase()}';
      } else {
        response = 'Echo from Flutter: $message (response #$_flutterMessageCounter)';
      }
      
      // Add response to queue
      _flutterMessageQueue.add(response);
      
      // Log response in history
      _messageHistory.add({
        'id': _flutterMessageCounter,
        'message': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'direction': 'inbound',
        'source': 'Flutter WebSocket Server',
      });

      return WebSocketResult(
        success: true,
        message: 'Message sent via Flutter WebSocket: $message',
        errorMessage: '',
        connectionStatus: 'connected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } catch (e) {
      debugPrint('🔌 Failed to send Flutter message: $e');
      return WebSocketResult(
        success: false,
        message: '',
        errorMessage: 'Flutter WebSocket send error: $e',
        connectionStatus: _isFlutterConnected ? 'connected' : 'disconnected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  @override
  WebSocketResult read() {
    debugPrint('🔌 MyCustomWebSocketClient.read called');
    
    if (!_isFlutterConnected) {
      return WebSocketResult(
        success: false,
        message: '',
        errorMessage: 'Flutter WebSocket not connected',
        connectionStatus: 'disconnected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    if (_flutterMessageQueue.isNotEmpty) {
      final message = _flutterMessageQueue.removeAt(0);
      debugPrint('🔌 Read Flutter message from queue: $message');
      return WebSocketResult(
        success: true,
        message: message,
        errorMessage: '',
        connectionStatus: 'connected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } else {
      debugPrint('🔌 No Flutter messages in queue');
      return WebSocketResult(
        success: true,
        message: 'No new messages in Flutter WebSocket',
        errorMessage: '',
        connectionStatus: 'connected',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  // Additional Flutter-specific methods
  void printConnectionStats() {
    debugPrint('📊 WebSocket Stats: ${_messageHistory.length} messages, counter: $_flutterMessageCounter');
    debugPrint('   Queue: ${_flutterMessageQueue.length} pending messages');
    debugPrint('   Status: ${_isFlutterConnected ? 'Connected' : 'Disconnected'}');
  }

  void toggleConnection() {
    _isFlutterConnected = !_isFlutterConnected;
    debugPrint('🔌 Flutter WebSocket ${_isFlutterConnected ? 'connected' : 'disconnected'}');
  }
}
