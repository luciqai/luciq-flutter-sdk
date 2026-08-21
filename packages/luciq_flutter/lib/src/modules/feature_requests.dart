// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/feature_requests.api.g.dart';
import 'package:luciq_flutter/src/utils/enum_converter.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:meta/meta.dart';

enum ActionType { requestNewFeature, addCommentToFeature }

class FeatureRequests {
  static var _host = FeatureRequestsHostApi();

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(FeatureRequestsHostApi host) {
    _host = host;
  }

  /// Shows the UI for feature requests list
  static Future<void> show() => hostCall(
        'FR.show',
        () => _host.show(),
        tag: DebugTags.featureRequests,
      );

  /// Sets whether users are required to enter an email address or not when sending reports.
  /// Defaults to YES.
  /// [isRequired] A boolean to indicate whether email
  /// field is required or not.
  /// [actionTypes] An enum that indicates which action types will have the isEmailFieldRequired
  static Future<void> setEmailFieldRequired(
    bool isRequired,
    List<ActionType>? actionTypes,
  ) =>
      hostCall(
        'FR.setEmailFieldRequired',
        () => _host.setEmailFieldRequired(
          isRequired,
          actionTypes.mapToString(),
        ),
        tag: DebugTags.featureRequests,
        args: {
          'isRequired': isRequired,
          'actionTypesCount': actionTypes?.length ?? 0,
        },
      );
}
