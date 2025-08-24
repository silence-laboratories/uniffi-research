import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_uniffi_demo/flutter_uniffi_demo.dart';
import 'package:flutter_uniffi_demo/flutter_uniffi_demo_platform_interface.dart';
import 'package:flutter_uniffi_demo/flutter_uniffi_demo_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterUniffiDemoPlatform
    with MockPlatformInterfaceMixin
    implements FlutterUniffiDemoPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterUniffiDemoPlatform initialPlatform = FlutterUniffiDemoPlatform.instance;

  test('$MethodChannelFlutterUniffiDemo is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterUniffiDemo>());
  });

  test('getPlatformVersion', () async {
    FlutterUniffiDemo flutterUniffiDemoPlugin = FlutterUniffiDemo();
    MockFlutterUniffiDemoPlatform fakePlatform = MockFlutterUniffiDemoPlatform();
    FlutterUniffiDemoPlatform.instance = fakePlatform;

    expect(await flutterUniffiDemoPlugin.getPlatformVersion(), '42');
  });
}
