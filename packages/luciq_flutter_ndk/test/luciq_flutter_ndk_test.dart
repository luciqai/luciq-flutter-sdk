import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter_ndk/luciq_flutter_ndk.dart';
import 'package:luciq_flutter_ndk/luciq_flutter_ndk_method_channel.dart';
import 'package:luciq_flutter_ndk/luciq_flutter_ndk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLuciqFlutterNdkPlatform
    with MockPlatformInterfaceMixin
    implements LuciqFlutterNdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = LuciqFlutterNdkPlatform.instance;

  test('$MethodChannelLuciqFlutterNdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLuciqFlutterNdk>());
  });

  test('getPlatformVersion', () async {
    final luciqFlutterNdkPlugin = LuciqFlutterNdk();
    final fakePlatform = MockLuciqFlutterNdkPlatform();
    LuciqFlutterNdkPlatform.instance = fakePlatform;

    expect(await luciqFlutterNdkPlugin.getPlatformVersion(), '42');
  });
}
