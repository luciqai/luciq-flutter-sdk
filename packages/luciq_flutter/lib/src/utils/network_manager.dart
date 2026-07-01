import 'dart:async';

import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/feature_flags_manager.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/luciq_constants.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

typedef ObfuscateLogCallback = FutureOr<NetworkData> Function(NetworkData data);
typedef OmitLogCallback = FutureOr<bool> Function(NetworkData data);

/// Mockable [NetworkManager] responsible for processing network logs
/// before they are sent to the native SDKs.
class NetworkManager {
  ObfuscateLogCallback? _obfuscateLogCallback;
  OmitLogCallback? _omitLogCallback;
  int? _cachedNetworkBodyMaxSize;
  final int _defaultNetworkBodyMaxSize = 10240; // in bytes
  final _host = LuciqHostApi();

  NetworkManager() {
    // Register for network body max size changes
    FeatureFlagsManager().onNetworkBodyMaxSizeChangeCallback = () {
      clearNetworkBodyMaxSizeCache();
    };
  }

  // ignore: use_setters_to_change_properties
  void setObfuscateLogCallback(ObfuscateLogCallback callback) {
    _obfuscateLogCallback = callback;
  }

  // ignore: use_setters_to_change_properties
  void setOmitLogCallback(OmitLogCallback callback) {
    _omitLogCallback = callback;
  }

  FutureOr<NetworkData> obfuscateLog(NetworkData data) {
    if (_obfuscateLogCallback == null) {
      return data;
    }

    return _obfuscateLogCallback!(data);
  }

  FutureOr<bool> omitLog(NetworkData data) {
    if (_omitLogCallback == null) {
      return false;
    }

    return _omitLogCallback!(data);
  }

  /// Checks if network request body exceeds backend size limits
  ///
  /// Returns true if request body size exceeds the limit
  Future<bool> didRequestBodyExceedSizeLimit(NetworkData data) async {
    try {
      final limit = await _getNetworkBodyMaxSize();
      if (limit == null) {
        return false; // If we can't get the limit, don't block logging
      }

      final requestExceeds = data.requestBodySize > limit;
      if (requestExceeds) {
        LuciqLogger.I.w(
          '[NET.didRequestBodyExceedSizeLimit] phase=warn type=request bodySize=${data.requestBodySize} limit=$limit',
          tag: DebugTags.network,
        );
      }

      return requestExceeds;
    } catch (error) {
      LuciqLogger.I.e(
        '[NET.didRequestBodyExceedSizeLimit] phase=error errorType=${error.runtimeType}',
        tag: DebugTags.network,
      );
      return false; // Don't block logging on error
    }
  }

  /// Checks if network response body exceeds backend size limits
  ///
  /// Returns true if response body size exceeds the limit
  Future<bool> didResponseBodyExceedSizeLimit(NetworkData data) async {
    try {
      final limit = await _getNetworkBodyMaxSize();
      if (limit == null) {
        return false; // If we can't get the limit, don't block logging
      }

      final responseExceeds = data.responseBodySize > limit;
      if (responseExceeds) {
        LuciqLogger.I.w(
          '[NET.didResponseBodyExceedSizeLimit] phase=warn type=response bodySize=${data.responseBodySize} limit=$limit',
          tag: DebugTags.network,
        );
      }

      return responseExceeds;
    } catch (error) {
      LuciqLogger.I.e(
        '[NET.didResponseBodyExceedSizeLimit] phase=error errorType=${error.runtimeType}',
        tag: DebugTags.network,
      );
      return false; // Don't block logging on error
    }
  }

  /// Gets the network body max size from native SDK, with caching
  Future<int?> _getNetworkBodyMaxSize() async {
    if (_cachedNetworkBodyMaxSize != null) {
      return _cachedNetworkBodyMaxSize;
    }

    final ffmNetworkBodyLimit = FeatureFlagsManager().networkBodyMaxSize;

    if (ffmNetworkBodyLimit > 0) {
      _cachedNetworkBodyMaxSize = ffmNetworkBodyLimit;
      return ffmNetworkBodyLimit;
    }

    try {
      final limit = await _host.getNetworkBodyMaxSize();
      _cachedNetworkBodyMaxSize = limit?.toInt();
      return limit?.toInt();
    } catch (error) {
      LuciqLogger.I.e(
        '[NET._getNetworkBodyMaxSize] phase=error errorType=${error.runtimeType} fallbackBytes=$_defaultNetworkBodyMaxSize',
        tag: DebugTags.network,
      );
      _cachedNetworkBodyMaxSize = _defaultNetworkBodyMaxSize;
      return _defaultNetworkBodyMaxSize;
    }
  }

  /// Clears the cached network body max size
  void clearNetworkBodyMaxSizeCache() {
    _cachedNetworkBodyMaxSize = null;
  }
}
