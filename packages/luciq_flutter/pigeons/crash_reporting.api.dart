import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class CrashReportingHostApi {
  void setEnabled(bool isEnabled);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void send(String jsonCrash, bool isHandled);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void sendNonFatalError(
    String jsonCrash,
    Map<String, String>? userAttributes,
    String? fingerprint,
    String nonFatalExceptionLevel,
  );
  void setNDKEnabled(bool isEnabled);
}
