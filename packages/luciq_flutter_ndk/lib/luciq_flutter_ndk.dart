import 'package:luciq_flutter_ndk/luciq_flutter_ndk_platform_interface.dart';

class LuciqFlutterNdk {
  Future<String?> getPlatformVersion() {
    return LuciqFlutterNdkPlatform.instance.getPlatformVersion();
  }
}
