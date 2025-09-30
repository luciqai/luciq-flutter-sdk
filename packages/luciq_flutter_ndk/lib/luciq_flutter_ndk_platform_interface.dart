import 'package:luciq_flutter_ndk/luciq_flutter_ndk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class LuciqFlutterNdkPlatform extends PlatformInterface {
  /// Constructs a LuciqFlutterNdkPlatform.
  LuciqFlutterNdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static LuciqFlutterNdkPlatform _instance = MethodChannelLuciqFlutterNdk();

  /// The default instance of [LuciqFlutterNdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelLuciqFlutterNdk].
  static LuciqFlutterNdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LuciqFlutterNdkPlatform] when
  /// they register themselves.
  static set instance(LuciqFlutterNdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
