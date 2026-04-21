/// Type of app launch associated with a session.
///
/// Values are platform-specific:
///  * `cold`, `hot`, `unknown` — iOS + Android
///  * `warm` — Android only
enum LaunchType { cold, warm, hot, unknown }

/// A single network log captured during a session.
class NetworkLog {
  const NetworkLog({
    required this.url,
    required this.duration,
    required this.statusCode,
  });

  /// The request URL.
  final String? url;

  /// The request duration in milliseconds.
  final int duration;

  /// The response status code.
  final int statusCode;

  /// @nodoc
  factory NetworkLog.fromMap(Map<Object?, Object?> map) => NetworkLog(
        url: map['url'] as String?,
        duration: (map['duration'] as num?)?.toInt() ?? 0,
        statusCode: (map['statusCode'] as num?)?.toInt() ?? 0,
      );
}

/// Metadata about the previous session, passed to [SessionReplay.setSyncCallback].
class SessionMetadata {
  const SessionMetadata({
    this.appVersion,
    this.os,
    this.device,
    this.sessionDurationInSeconds = 0,
    this.hasLinkToAppReview = false,
    this.launchType = LaunchType.unknown,
    this.launchDuration,
    this.bugsCount = 0,
    this.fatalCrashCount = 0,
    this.oomCrashCount = 0,
    this.networkLogs = const [],
  });

  /// The app's version string.
  final String? appVersion;

  /// The OS name/version.
  final String? os;

  /// The device make and model.
  final String? device;

  /// The previous session's duration, in seconds.
  final int sessionDurationInSeconds;

  /// True if an in-app review occurred during the previous session.
  final bool hasLinkToAppReview;

  /// Launch type of the previous session.
  final LaunchType launchType;

  /// Launch duration in milliseconds, if measured.
  final int? launchDuration;

  /// Number of bug reports captured during the previous session (iOS only; 0 on Android).
  final int bugsCount;

  /// Number of fatal crashes during the previous session (iOS only; 0 on Android).
  final int fatalCrashCount;

  /// Number of OOM crashes during the previous session (iOS only; 0 on Android).
  final int oomCrashCount;

  /// Network logs captured during the previous session.
  final List<NetworkLog> networkLogs;

  /// @nodoc
  factory SessionMetadata.fromMap(Map<Object?, Object?> map) {
    final rawLogs = map['networkLogs'];
    final logs = <NetworkLog>[];
    if (rawLogs is List) {
      for (final entry in rawLogs) {
        if (entry is Map) {
          logs.add(NetworkLog.fromMap(entry.cast<Object?, Object?>()));
        }
      }
    }
    return SessionMetadata(
      appVersion: map['appVersion'] as String?,
      os: (map['os'] ?? map['OS']) as String?,
      device: map['device'] as String?,
      sessionDurationInSeconds:
          (map['sessionDurationInSeconds'] as num?)?.toInt() ?? 0,
      hasLinkToAppReview: (map['hasLinkToAppReview'] as bool?) ?? false,
      launchType: _parseLaunchType(map['launchType']),
      launchDuration: (map['launchDuration'] as num?)?.toInt(),
      bugsCount: (map['bugsCount'] as num?)?.toInt() ?? 0,
      fatalCrashCount: (map['fatalCrashCount'] as num?)?.toInt() ?? 0,
      oomCrashCount: (map['oomCrashCount'] as num?)?.toInt() ?? 0,
      networkLogs: logs,
    );
  }

  static LaunchType _parseLaunchType(Object? raw) {
    if (raw is String) {
      switch (raw) {
        case 'Cold':
          return LaunchType.cold;
        case 'Warm':
          return LaunchType.warm;
        case 'Hot':
          return LaunchType.hot;
        default:
          return LaunchType.unknown;
      }
    }
    if (raw is num) {
      // iOS LCQSessionMetadata.launchType: Cold=0, Hot=1, Unknown=-1
      switch (raw.toInt()) {
        case 0:
          return LaunchType.cold;
        case 1:
          return LaunchType.hot;
        default:
          return LaunchType.unknown;
      }
    }
    return LaunchType.unknown;
  }
}
