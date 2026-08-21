import 'package:pigeon/pigeon.dart';

@FlutterApi()
abstract class LuciqPrivateViewFlutterApi {
  /// Native -> Dart capture callback. `callId` is minted on the native side via
  /// `LuciqFlutterLogger.nextCallId` so the resulting `phase=fire` line on Dart
  /// can be correlated with the originating `[PRIV.mask]` trace.
  List<double> getPrivateViews(String callId);
}

@HostApi()
abstract class LuciqPrivateViewHostApi {
  void init();
}
