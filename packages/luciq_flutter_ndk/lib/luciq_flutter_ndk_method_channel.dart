import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:luciq_flutter_ndk/luciq_flutter_ndk_platform_interface.dart';

/// An implementation of [LuciqFlutterNdkPlatform] that uses method channels.
class MethodChannelLuciqFlutterNdk extends LuciqFlutterNdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('luciq_flutter_ndk');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
