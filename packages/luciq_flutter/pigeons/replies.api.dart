import 'package:pigeon/pigeon.dart';

@FlutterApi()
abstract class RepliesFlutterApi {
  void onNewReply();
}

@HostApi()
abstract class RepliesHostApi {
  void setEnabled(bool isEnabled);
  void show();
  void setInAppNotificationsEnabled(bool isEnabled);
  void setInAppNotificationSound(bool isEnabled);

  @async
  int getUnreadRepliesCount();

  @async
  bool hasChats();

  void bindOnNewReplyCallback();

  void setPushNotificationsEnabled(bool isEnabled);
  void setPushNotificationRegistrationTokenAndroid(String token);
  void showNotificationAndroid(Map<String, String> data);
  void setNotificationIconAndroid(int resourceId);
  void setPushNotificationChannelIdAndroid(String id);
  void setSystemReplyNotificationSoundEnabledAndroid(bool isEnabled);
}
