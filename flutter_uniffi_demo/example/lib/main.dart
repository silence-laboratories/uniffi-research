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
                            'Actions',
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
