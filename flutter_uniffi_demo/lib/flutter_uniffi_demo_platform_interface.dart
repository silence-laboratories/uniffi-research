import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_uniffi_demo_method_channel.dart';

abstract class FlutterUniffiDemoPlatform extends PlatformInterface {
  /// Constructs a FlutterUniffiDemoPlatform.
  FlutterUniffiDemoPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterUniffiDemoPlatform _instance = MethodChannelFlutterUniffiDemo();

  /// The default instance of [FlutterUniffiDemoPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterUniffiDemo].
  static FlutterUniffiDemoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterUniffiDemoPlatform] when
  /// they register themselves.
  static set instance(FlutterUniffiDemoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
