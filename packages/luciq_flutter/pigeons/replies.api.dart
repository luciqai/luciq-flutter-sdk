import 'package:pigeon/pigeon.dart';

@FlutterApi()
abstract class RepliesFlutterApi {
  void onNewReply(String callId);
}

@HostApi()
abstract class RepliesHostApi {
  void setEnabled(bool isEnabled);
  void show(String callId);
  void setInAppNotificationsEnabled(bool isEnabled);
  void setInAppNotificationSound(bool isEnabled);

  @async
  int getUnreadRepliesCount(String callId);

  @async
  bool hasChats(String callId);

  void bindOnNewReplyCallback();
}
