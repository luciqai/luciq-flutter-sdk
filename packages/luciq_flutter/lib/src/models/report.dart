import 'dart:typed_data';

/// Severity of a log attached to the report.
enum ReportLogLevel { verbose, debug, info, warn, error }

/// One log entry captured on a report.
class ReportLog {
  const ReportLog({required this.log, required this.type});

  final String log;
  final ReportLogLevel type;
}

/// One file attachment declared on a report.
class ReportFileAttachment {
  const ReportFileAttachment({required this.file, required this.isData});

  /// The file URL/path (when `isData == false`) or a string identifier
  /// (when `isData == true`).
  final String file;

  /// Whether the attachment was added via raw data rather than a URL.
  final bool isData;
}

/// A report handed to the callback registered with
/// [Luciq.onReportSubmitHandler].
///
/// Use the mutator methods to enrich the report that the SDK is about to send.
/// Mutations are accumulated locally in Dart and applied to the native report
/// in a single batch when the callback returns.
class Report {
  /// @nodoc
  Report({
    List<String> tags = const [],
    List<String> consoleLogs = const [],
    List<ReportLog> luciqLogs = const [],
    Map<String, String> userAttributes = const {},
    List<ReportFileAttachment> fileAttachments = const [],
  })  : tags = List<String>.from(tags),
        consoleLogs = List<String>.from(consoleLogs),
        luciqLogs = List<ReportLog>.from(luciqLogs),
        userAttributes = Map<String, String>.from(userAttributes),
        fileAttachments = List<ReportFileAttachment>.from(fileAttachments);

  /// Tags on the report (initial + appended in this callback).
  final List<String> tags;

  /// Console logs on the report (initial + appended in this callback).
  final List<String> consoleLogs;

  /// Luciq logs on the report (initial + appended in this callback).
  final List<ReportLog> luciqLogs;

  /// User attributes on the report (initial + set in this callback).
  final Map<String, String> userAttributes;

  /// File attachments on the report (initial + appended in this callback).
  final List<ReportFileAttachment> fileAttachments;

  /// Mutations recorded by mutator methods, drained by the disposal manager
  /// after the user callback returns.
  final List<String> _pendingTags = [];
  final List<String> _pendingConsoleLogs = [];
  final List<_PendingLog> _pendingLogs = [];
  final Map<String, String> _pendingUserAttributes = {};
  final List<_PendingDataAttachment> _pendingDataAttachments = [];

  /// Appends a tag to the report.
  void appendTag(String tag) {
    tags.add(tag);
    _pendingTags.add(tag);
  }

  /// Appends a console log entry to the report.
  void appendConsoleLog(String log) {
    consoleLogs.add(log);
    _pendingConsoleLogs.add(log);
  }

  /// Sets a user attribute on the report.
  void setUserAttribute(String key, String value) {
    userAttributes[key] = value;
    _pendingUserAttributes[key] = value;
  }

  /// Attaches a verbose log line to the report.
  void logVerbose(String log) => _addLog(log, ReportLogLevel.verbose);

  /// Attaches a debug log line to the report.
  void logDebug(String log) => _addLog(log, ReportLogLevel.debug);

  /// Attaches an info log line to the report.
  void logInfo(String log) => _addLog(log, ReportLogLevel.info);

  /// Attaches a warn log line to the report.
  void logWarn(String log) => _addLog(log, ReportLogLevel.warn);

  /// Attaches an error log line to the report.
  void logError(String log) => _addLog(log, ReportLogLevel.error);

  void _addLog(String log, ReportLogLevel level) {
    luciqLogs.add(ReportLog(log: log, type: level));
    _pendingLogs.add(_PendingLog(log: log, level: level));
  }

  /// Attaches raw binary data as a file to the report.
  void addFileAttachmentWithData(Uint8List data, String fileName) {
    fileAttachments.add(ReportFileAttachment(file: fileName, isData: true));
    _pendingDataAttachments
        .add(_PendingDataAttachment(data: data, fileName: fileName));
  }

  /// @nodoc
  Map<String, Object?> drainMutations() {
    return <String, Object?>{
      'tags': List<String>.from(_pendingTags),
      'consoleLogs': List<String>.from(_pendingConsoleLogs),
      'userAttributes': Map<String, String>.from(_pendingUserAttributes),
      'logs': _pendingLogs
          .map(
            (e) => <String, Object?>{
              'log': e.log,
              'type': _levelName(e.level),
            },
          )
          .toList(),
      'dataAttachments': _pendingDataAttachments
          .map(
            (e) => <String, Object?>{
              'data': e.data,
              'fileName': e.fileName,
            },
          )
          .toList(),
    };
  }

  static String _levelName(ReportLogLevel level) {
    switch (level) {
      case ReportLogLevel.verbose:
        return 'verbose';
      case ReportLogLevel.debug:
        return 'debug';
      case ReportLogLevel.info:
        return 'info';
      case ReportLogLevel.warn:
        return 'warn';
      case ReportLogLevel.error:
        return 'error';
    }
  }
}

class _PendingLog {
  _PendingLog({required this.log, required this.level});
  final String log;
  final ReportLogLevel level;
}

class _PendingDataAttachment {
  _PendingDataAttachment({required this.data, required this.fileName});
  final Uint8List data;
  final String fileName;
}
