import 'package:meta/meta.dart';

/// Mockable [DateTime] class.
class LCQDateTime {
  LCQDateTime._();

  static LCQDateTime _instance = LCQDateTime._();
  static LCQDateTime get instance => _instance;

  /// Shorthand for [instance]
  static LCQDateTime get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LCQDateTime instance) {
    _instance = instance;
  }

  DateTime now() => DateTime.now();
}
