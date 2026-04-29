import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/replies.api.g.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'replies_test.mocks.dart';

@GenerateMocks([
  RepliesHostApi,
  LCQBuildInfo,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockRepliesHostApi();
  final mBuildInfo = MockLCQBuildInfo();

  setUpAll(() {
    Replies.$setHostApi(mHost);
    LCQBuildInfo.setInstance(mBuildInfo);
  });

  test('[setEnabled] should call host method', () async {
    const enabled = true;

    await Replies.setEnabled(enabled);

    verify(
      mHost.setEnabled(enabled),
    ).called(1);
  });

  test('[show] should call host method', () async {
    await Replies.show();

    verify(
      mHost.show(),
    ).called(1);
  });

  test('[setInAppNotificationsEnabled] should call host method', () async {
    const enabled = true;

    await Replies.setInAppNotificationsEnabled(enabled);

    verify(
      mHost.setInAppNotificationsEnabled(enabled),
    ).called(1);
  });

  test('[setInAppNotificationSound] should call host method', () async {
    const enabled = true;
    when(mBuildInfo.isAndroid).thenReturn(true);

    await Replies.setInAppNotificationSound(enabled);

    verify(
      mHost.setInAppNotificationSound(enabled),
    ).called(1);
  });

  test('[getUnreadRepliesCount] should call host method', () async {
    const count = 10;
    when(mHost.getUnreadRepliesCount()).thenAnswer((_) async => count);

    final result = await Replies.getUnreadRepliesCount();

    expect(result, count);
    verify(
      mHost.getUnreadRepliesCount(),
    ).called(1);
  });

  test('[hasChats] should call host method', () async {
    const hasChats = true;
    when(mHost.hasChats()).thenAnswer((_) async => hasChats);

    final result = await Replies.hasChats();

    expect(result, hasChats);
    verify(
      mHost.hasChats(),
    ).called(1);
  });

  test('[setOnNewReplyReceivedCallback] should call host method', () async {
    await Replies.setOnNewReplyReceivedCallback(() {});

    verify(
      mHost.bindOnNewReplyCallback(),
    ).called(1);
  });

  test('[setPushNotificationsEnabled] should call host method', () async {
    const enabled = true;

    await Replies.setPushNotificationsEnabled(enabled);

    verify(
      mHost.setPushNotificationsEnabled(enabled),
    ).called(1);
  });

  test(
    '[setPushNotificationRegistrationTokenAndroid] should call host method on Android',
    () async {
      const token = 'fcm-token';
      when(mBuildInfo.isAndroid).thenReturn(true);

      await Replies.setPushNotificationRegistrationTokenAndroid(token);

      verify(
        mHost.setPushNotificationRegistrationTokenAndroid(token),
      ).called(1);
    },
  );

  test(
    '[setPushNotificationRegistrationTokenAndroid] should not call host method on iOS',
    () async {
      const token = 'fcm-token';
      when(mBuildInfo.isAndroid).thenReturn(false);

      await Replies.setPushNotificationRegistrationTokenAndroid(token);

      verifyNever(mHost.setPushNotificationRegistrationTokenAndroid(token));
    },
  );

  test(
    '[showNotificationAndroid] should call host method on Android',
    () async {
      const data = {'body': 'hello'};
      when(mBuildInfo.isAndroid).thenReturn(true);

      await Replies.showNotificationAndroid(data);

      verify(mHost.showNotificationAndroid(data)).called(1);
    },
  );

  test(
    '[showNotificationAndroid] should not call host method on iOS',
    () async {
      const data = {'body': 'hello'};
      when(mBuildInfo.isAndroid).thenReturn(false);

      await Replies.showNotificationAndroid(data);

      verifyNever(mHost.showNotificationAndroid(data));
    },
  );

  test(
    '[setNotificationIconAndroid] should call host method on Android',
    () async {
      const resourceId = 42;
      when(mBuildInfo.isAndroid).thenReturn(true);

      await Replies.setNotificationIconAndroid(resourceId);

      verify(mHost.setNotificationIconAndroid(resourceId)).called(1);
    },
  );

  test(
    '[setNotificationIconAndroid] should not call host method on iOS',
    () async {
      const resourceId = 42;
      when(mBuildInfo.isAndroid).thenReturn(false);

      await Replies.setNotificationIconAndroid(resourceId);

      verifyNever(mHost.setNotificationIconAndroid(resourceId));
    },
  );

  test(
    '[setPushNotificationChannelIdAndroid] should call host method on Android',
    () async {
      const id = 'channel-id';
      when(mBuildInfo.isAndroid).thenReturn(true);

      await Replies.setPushNotificationChannelIdAndroid(id);

      verify(mHost.setPushNotificationChannelIdAndroid(id)).called(1);
    },
  );

  test(
    '[setPushNotificationChannelIdAndroid] should not call host method on iOS',
    () async {
      const id = 'channel-id';
      when(mBuildInfo.isAndroid).thenReturn(false);

      await Replies.setPushNotificationChannelIdAndroid(id);

      verifyNever(mHost.setPushNotificationChannelIdAndroid(id));
    },
  );

  test(
    '[setSystemReplyNotificationSoundEnabledAndroid] should call host method on Android',
    () async {
      const enabled = true;
      when(mBuildInfo.isAndroid).thenReturn(true);

      await Replies.setSystemReplyNotificationSoundEnabledAndroid(enabled);

      verify(
        mHost.setSystemReplyNotificationSoundEnabledAndroid(enabled),
      ).called(1);
    },
  );

  test(
    '[setSystemReplyNotificationSoundEnabledAndroid] should not call host method on iOS',
    () async {
      const enabled = true;
      when(mBuildInfo.isAndroid).thenReturn(false);

      await Replies.setSystemReplyNotificationSoundEnabledAndroid(enabled);

      verifyNever(
        mHost.setSystemReplyNotificationSoundEnabledAndroid(enabled),
      );
    },
  );
}
