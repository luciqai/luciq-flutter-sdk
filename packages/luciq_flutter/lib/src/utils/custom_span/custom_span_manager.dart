import 'package:luciq_flutter/src/constants/strings.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/models/custom_span.dart';
import 'package:luciq_flutter/src/modules/luciq.dart' show Luciq;
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';
import 'package:meta/meta.dart';

/// Manager class responsible for handling custom spans functionality.
///
/// This class encapsulates all logic related to custom spans including:
/// - Tracking active spans
/// - Enforcing concurrent span limits
/// - Validating span creation parameters
/// - Syncing span data to native SDK
class CustomSpanManager {
  CustomSpanManager._();

  static CustomSpanManager? _instance;

  /// Returns the singleton instance of CustomSpanManager.
  //ignore:prefer_constructors_over_static_methods
  static CustomSpanManager get I => _instance ??= CustomSpanManager._();

  /// Sets a custom instance (for testing).
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(CustomSpanManager instance) {
    _instance = instance;
  }

  /// Resets the instance to null (for testing).
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Host API for native communication.
  ApmHostApi _host = ApmHostApi();

  /// Log tag for custom span operations.
  static const String tag = 'Luciq - CustomSpan';

  /// Maximum number of concurrent custom spans allowed.
  static const int maxConcurrentSpans = 100;

  /// Maximum character length for span names.
  static const int maxNameLength = 150;

  /// List of active custom spans for tracking.
  final List<CustomSpan> _activeSpans = [];

  /// Sets the host API for native communication.
  /// Called from APM.$setHostApi and tests.
  /// @nodoc
  @internal
  // ignore: use_setters_to_change_properties
  void $setHostApi(ApmHostApi host) {
    _host = host;
  }

  /// Returns the current number of active spans.
  /// Exposed for APM and tests.
  @internal
  int get activeSpanCount => _activeSpans.length;

  /// Clears all active spans (for testing purposes only).
  @internal
  void $clearActiveSpans() {
    _activeSpans.clear();
  }

  /// Registers a span as active.
  /// Returns true if successful, false if limit reached.
  @internal
  bool registerSpan(CustomSpan span) {
    if (_activeSpans.length >= maxConcurrentSpans) {
      return false;
    }
    _activeSpans.add(span);
    return true;
  }

  /// Unregisters a span when it ends.
  @internal
  void unregisterSpan(CustomSpan span) {
    _activeSpans.remove(span);
  }

  /// Starts a custom span with the given [name] for performance tracking.
  ///
  /// The [name] must not be empty and will be trimmed to 150 characters if longer.
  /// Multiple spans can be active concurrently with the same or different names.
  ///
  /// Returns a [CustomSpan] object that must be ended by calling its `end()` method,
  /// or null if the feature is disabled or the name is invalid.
  ///
  /// Example:
  /// ```dart
  /// final span = await CustomSpanManager.I.startCustomSpan('Database Query');
  /// // ... perform operation ...
  /// await span?.end();
  /// ```
  Future<CustomSpan?> startCustomSpan(String name) async {
    // Validate name
    if (name.trim().isEmpty) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanNameEmpty,
        tag: tag,
      );
      return null;
    }

    // Check if SDK is initialized
    final isSDKInitialized = await Luciq.isBuilt();
    if (!isSDKInitialized) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanSDKNotInitializedMessage,
        tag: tag,
      );
      return null;
    }

    // Check if APM is enabled
    final isAPMEnabled = await FlagsConfig.apm.isEnabled();
    if (!isAPMEnabled) {
      LuciqLogger.I.d(
        LuciqStrings.customSpanAPMDisabledMessage,
        tag: tag,
      );
      return null;
    }

    // Check if custom span feature is enabled
    final isCustomSpanEnabled = await FlagsConfig.customSpan.isEnabled();
    if (!isCustomSpanEnabled) {
      LuciqLogger.I.d(
        LuciqStrings.customSpanDisabled,
        tag: tag,
      );
      return null;
    }

    // Check span limit
    if (_activeSpans.length >= maxConcurrentSpans) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanLimitReached,
        tag: tag,
      );
      return null;
    }

    // Trim name to limit
    final spanName = _trimSpanName(name);

    // Create span object and register it
    final span = CustomSpan(spanName);
    _activeSpans.add(span);
    return span;
  }

  /// Records a custom span that has already completed with specific start and end times.
  ///
  /// Use this API when you need to record a span retrospectively or when tracking
  /// operations that occurred before SDK initialization.
  ///
  /// The [name] must not be empty and will be trimmed to 150 characters if longer.
  /// The [startDate] must be before [endDate].
  ///
  /// Example:
  /// ```dart
  /// final start = DateTime.now();
  /// // ... perform operation ...
  /// final end = DateTime.now();
  /// await CustomSpanManager.I.addCompletedCustomSpan('Cache Lookup', start, end);
  /// ```
  Future<void> addCompletedCustomSpan(
    String name,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Validate name
    if (name.trim().isEmpty) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanNameEmpty,
        tag: tag,
      );
      return;
    }

    // Validate timestamps
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanEndTimeBeforeStartTime,
        tag: tag,
      );
      return;
    }

    // Check if SDK is initialized
    final isSDKInitialized = await Luciq.isBuilt();
    if (!isSDKInitialized) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanSDKNotInitializedMessage,
        tag: tag,
      );
      return;
    }

    // Check if APM is enabled
    final isAPMEnabled = await FlagsConfig.apm.isEnabled();
    if (!isAPMEnabled) {
      LuciqLogger.I.d(
        LuciqStrings.customSpanAPMDisabledMessage,
        tag: tag,
      );
      return;
    }

    // Check if custom span feature is enabled
    final isCustomSpanEnabled = await FlagsConfig.customSpan.isEnabled();
    if (!isCustomSpanEnabled) {
      LuciqLogger.I.d(
        LuciqStrings.customSpanDisabled,
        tag: tag,
      );
      return;
    }

    // Convert to microseconds
    final startTimestamp = startDate.microsecondsSinceEpoch;
    final endTimestamp = endDate.microsecondsSinceEpoch;

    // Send to native
    return syncCustomSpan(name, startTimestamp, endTimestamp);
  }

  /// Internal method to sync custom span data to native SDK.
  /// Used by CustomSpan.end() and addCompletedCustomSpan().
  @internal
  Future<void> syncCustomSpan(
    String name,
    int startTimestamp,
    int endTimestamp,
  ) async {
    // Validate name
    if (name.isEmpty) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanNameEmpty,
        tag: tag,
      );
      return;
    }

    // Validate timestamps
    if (endTimestamp <= startTimestamp) {
      LuciqLogger.I.e(
        LuciqStrings.customSpanEndTimeBeforeStartTime,
        tag: tag,
      );
      return;
    }

    // Trim name to limit
    final spanName = _trimSpanName(name);

    // Send to native
    return _host.syncCustomSpan(
      spanName,
      startTimestamp,
      endTimestamp,
    );
  }

  /// Trims and validates span name, logging if truncation occurs.
  String _trimSpanName(String name) {
    var spanName = name.trim();
    if (spanName.length > maxNameLength) {
      spanName = spanName.substring(0, maxNameLength);
      LuciqLogger.I.d(
        LuciqStrings.customSpanNameTruncated,
        tag: tag,
      );
    }
    return spanName;
  }
}
