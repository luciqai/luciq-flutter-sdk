import 'dart:developer';

import 'package:meta/meta.dart';

/// Mockable, monotonic, high-resolution clock.
class LuciqMonotonicClock {
  LuciqMonotonicClock._();

  static LuciqMonotonicClock _instance = LuciqMonotonicClock._();
  static LuciqMonotonicClock get instance => _instance;

  /// Shorthand for [instance]
  static LuciqMonotonicClock get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LuciqMonotonicClock instance) {
    _instance = instance;
  }

  int get now => Timeline.now;
}
