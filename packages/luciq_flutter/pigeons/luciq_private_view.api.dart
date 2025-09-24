import 'package:pigeon/pigeon.dart';

@FlutterApi()
abstract class LuciqPrivateViewFlutterApi {
  List<double> getPrivateViews();
}

@HostApi()
abstract class LuciqPrivateViewHostApi {
  void init();
}
