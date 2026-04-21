import 'dart:typed_data';

import 'package:luciq_flutter/src/generated/luciq.api.g.dart';

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
/// Each method forwards to the native SDK so mutations are applied to the
/// outgoing report.
class Report {
  /// @nodoc
  Report({
    required LuciqHostApi host,
    List<String> tags = const [],
    List<String> consoleLogs = const [],
    List<ReportLog> luciqLogs = const [],
    Map<String, String> userAttributes = const {},
    List<ReportFileAttachment> fileAttachments = const [],
  })  : _host = host,
        tags = List<String>.from(tags),
        consoleLogs = List<String>.from(consoleLogs),
        luciqLogs = List<ReportLog>.from(luciqLogs),
        userAttributes = Map<String, String>.from(userAttributes),
        fileAttachments = List<ReportFileAttachment>.from(fileAttachments);

  final LuciqHostApi _host;

  /// Tags already attached to the report when the handler was invoked.
  final List<String> tags;

  /// Console logs already attached to the report.
  final List<String> consoleLogs;

  /// Luciq logs already attached to the report.
  final List<ReportLog> luciqLogs;

  /// User attributes already attached to the report.
  final Map<String, String> userAttributes;

  /// File attachments already attached to the report.
  final List<ReportFileAttachment> fileAttachments;

  /// Appends a tag to the report.
  Future<void> appendTag(String tag) {
    tags.add(tag);
    return _host.appendTagToReport(tag);
  }

  /// Appends a console log entry to the report.
  Future<void> appendConsoleLog(String log) {
    consoleLogs.add(log);
    return _host.appendConsoleLogToReport(log);
  }

  /// Sets a user attribute on the report.
  Future<void> setUserAttribute(String key, String value) {
    userAttributes[key] = value;
    return _host.setUserAttributeToReport(key, value);
  }

  /// Attaches a verbose log line to the report.
  Future<void> logVerbose(String log) {
    luciqLogs.add(ReportLog(log: log, type: ReportLogLevel.verbose));
    return _host.logVerboseToReport(log);
  }

  /// Attaches a debug log line to the report.
  Future<void> logDebug(String log) {
    luciqLogs.add(ReportLog(log: log, type: ReportLogLevel.debug));
    return _host.logDebugToReport(log);
  }

  /// Attaches an info log line to the report.
  Future<void> logInfo(String log) {
    luciqLogs.add(ReportLog(log: log, type: ReportLogLevel.info));
    return _host.logInfoToReport(log);
  }

  /// Attaches a warn log line to the report.
  Future<void> logWarn(String log) {
    luciqLogs.add(ReportLog(log: log, type: ReportLogLevel.warn));
    return _host.logWarnToReport(log);
  }

  /// Attaches an error log line to the report.
  Future<void> logError(String log) {
    luciqLogs.add(ReportLog(log: log, type: ReportLogLevel.error));
    return _host.logErrorToReport(log);
  }

  /// Attaches a file (by file system path/URL) to the report.
  Future<void> addFileAttachmentWithURL(String filePath, String fileName) {
    fileAttachments.add(ReportFileAttachment(file: filePath, isData: false));
    return _host.addFileAttachmentWithURLToReport(filePath, fileName);
  }

  /// Attaches raw binary data as a file to the report.
  Future<void> addFileAttachmentWithData(Uint8List data, String fileName) {
    fileAttachments.add(ReportFileAttachment(file: fileName, isData: true));
    return _host.addFileAttachmentWithDataToReport(data, fileName);
  }
}
