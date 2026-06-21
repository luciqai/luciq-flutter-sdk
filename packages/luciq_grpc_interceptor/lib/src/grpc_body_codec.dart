import 'dart:convert';

// ignore: invalid_use_of_internal_member
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

const String _logTag = 'LCQ-Flutter-GRPC:';

String parseGrpcBody(dynamic data) {
  if (data == null) return '';
  try {
    final json = _toProto3JsonIfPossible(data);
    if (json != null) return jsonEncode(json);
  } catch (e) {
    LuciqLogger.I.v(
      '[parseGrpcBody] phase=warn op=proto3Json errorType=${e.runtimeType}',
      tag: _logTag,
    );
  }
  try {
    return jsonEncode(data);
  } catch (e) {
    LuciqLogger.I.v(
      '[parseGrpcBody] phase=warn op=jsonEncode errorType=${e.runtimeType}',
      tag: _logTag,
    );
  }
  try {
    return data.toString();
  } catch (e) {
    LuciqLogger.I.v(
      '[parseGrpcBody] phase=warn op=toString errorType=${e.runtimeType}',
      tag: _logTag,
    );
    return '';
  }
}

int calculateGrpcBodySize(dynamic data) {
  if (data == null) return 0;
  try {
    final bytes = _writeToBufferIfPossible(data);
    if (bytes != null) return bytes.length;
  } catch (e) {
    LuciqLogger.I.v(
      '[calculateGrpcBodySize] phase=warn op=writeToBuffer '
      'errorType=${e.runtimeType}',
      tag: _logTag,
    );
  }
  try {
    if (data is String) return utf8.encode(data).length;
    if (data is List<int>) return data.length;
    final json = _toProto3JsonIfPossible(data);
    if (json != null) return utf8.encode(jsonEncode(json)).length;
    return utf8.encode(jsonEncode(data)).length;
  } catch (e) {
    LuciqLogger.I.v(
      '[calculateGrpcBodySize] phase=warn op=jsonEncode '
      'errorType=${e.runtimeType}',
      tag: _logTag,
    );
  }
  try {
    return utf8.encode(data.toString()).length;
  } catch (e) {
    LuciqLogger.I.v(
      '[calculateGrpcBodySize] phase=warn op=toString '
      'errorType=${e.runtimeType}',
      tag: _logTag,
    );
    return 0;
  }
}

dynamic _toProto3JsonIfPossible(dynamic data) {
  try {
    final dyn = data as dynamic;
    final maybeFn = dyn.toProto3Json;
    if (maybeFn is Function) return Function.apply(maybeFn, []);
  } catch (_) {}
  return null;
}

List<int>? _writeToBufferIfPossible(dynamic data) {
  try {
    final dyn = data as dynamic;
    final maybeFn = dyn.writeToBuffer;
    if (maybeFn is Function) {
      final result = Function.apply(maybeFn, []);
      if (result is List<int>) return result;
    }
  } catch (_) {}
  return null;
}
