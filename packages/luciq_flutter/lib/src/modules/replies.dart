// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/replies.api.g.dart';
import 'package:luciq_flutter/src/utils/call_id.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:meta/meta.dart';

typedef OnNewReplyReceivedCallback = void Function();

class Replies implements RepliesFlutterApi {
  static var _host = RepliesHostApi();
  static final _instance = Replies();

  static OnNewReplyReceivedCallback? _onNewReplyReceivedCallback;

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(RepliesHostApi host) {
    _host = host;
  }

  /// @nodoc
  @internal
  static void $setup() {
    RepliesFlutterApi.setup(_instance);
  }

  /// @nodoc
  @internal
  @override
  void onNewReply(String callId) {
    logCallbackFire(
      'REP.onNewReply',
      tag: DebugTags.replies,
      callId: callId,
      args: {'callbackPresent': _onNewReplyReceivedCallback != null},
    );
    _onNewReplyReceivedCallback?.call();
  }

  /// Enables and disables everything related to receiving replies.
  /// [boolean] isEnabled
  static Future<void> setEnabled(bool isEnabled) => hostCall(
        'REP.setEnabled',
        () => _host.setEnabled(isEnabled),
        tag: DebugTags.replies,
        args: {'isEnabled': isEnabled},
      );

  /// Manual invocation for replies.
  static Future<void> show() {
    final callId = CallId.next();
    return hostCall(
      'REP.show',
      () => _host.show(callId),
      tag: DebugTags.replies,
      callId: callId,
    );
  }

  /// Tells whether the user has chats already or not.
  /// [callback] - callback that is invoked if chats exist
  static Future<bool?> hasChats() {
    final callId = CallId.next();
    return hostCall(
      'REP.hasChats',
      () => _host.hasChats(callId),
      tag: DebugTags.replies,
      callId: callId,
    );
  }

  /// Sets a block of code that gets executed when a new message is received.
  /// [callback] - A callback that gets executed when a new message is received.
  static Future<void> setOnNewReplyReceivedCallback(
    OnNewReplyReceivedCallback callback,
  ) {
    _onNewReplyReceivedCallback = callback;
    return hostCall(
      'REP.setOnNewReplyReceivedCallback',
      () => _host.bindOnNewReplyCallback(),
      tag: DebugTags.replies,
    );
  }

  /// Returns the number of unread messages the user currently has.
  /// Use this method to get the number of unread messages the user
  /// has, then possibly notify them about it with your own UI.
  /// [function] callback with argument
  /// Notifications count, or -1 in case the SDK has not been initialized.
  static Future<int?> getUnreadRepliesCount() {
    final callId = CallId.next();
    return hostCall(
      'REP.getUnreadRepliesCount',
      () => _host.getUnreadRepliesCount(callId),
      tag: DebugTags.replies,
      callId: callId,
    );
  }

  /// Enables/disables showing in-app notifications when the user receives a new message.
  /// [isEnabled] A boolean to set whether notifications are enabled or disabled.
  static Future<void> setInAppNotificationsEnabled(bool isEnabled) => hostCall(
        'REP.setInAppNotificationsEnabled',
        () => _host.setInAppNotificationsEnabled(isEnabled),
        tag: DebugTags.replies,
        args: {'isEnabled': isEnabled},
      );

  /// Set whether new in app notification received will play a small sound notification or not (Default is {@code false})
  /// [isEnabled] A boolean to set whether notifications sound should be played.
  /// @android ONLY
  static Future<void> setInAppNotificationSound(bool isEnabled) => hostCall(
        'REP.setInAppNotificationSound',
        () async {
          if (LCQBuildInfo.instance.isAndroid) {
            return _host.setInAppNotificationSound(isEnabled);
          }
        },
        tag: DebugTags.replies,
        args: {
          'isEnabled': isEnabled,
          'isAndroid': LCQBuildInfo.instance.isAndroid,
        },
      );
}
