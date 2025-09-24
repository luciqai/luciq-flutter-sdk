import 'dart:io';

import 'package:flutter/foundation.dart';

/// Mockable class that contains info about the
/// [Platform], the OS and build modes.
class LCQBuildInfo {
  LCQBuildInfo._();

  static LCQBuildInfo _instance = LCQBuildInfo._();
  static LCQBuildInfo get instance => _instance;

  /// Shorthand for [instance]
  static LCQBuildInfo get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LCQBuildInfo instance) {
    _instance = instance;
  }

  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;

  String get operatingSystem => Platform.operatingSystem;

  bool get isReleaseMode => kReleaseMode;
  bool get isDebugMode => kDebugMode;
}
