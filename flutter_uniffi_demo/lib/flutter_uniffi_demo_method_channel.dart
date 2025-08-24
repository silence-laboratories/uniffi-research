import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_uniffi_demo_platform_interface.dart';

/// An implementation of [FlutterUniffiDemoPlatform] that uses method channels.
class MethodChannelFlutterUniffiDemo extends FlutterUniffiDemoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_uniffi_demo');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
