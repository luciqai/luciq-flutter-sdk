import 'package:luciq_flutter/luciq_flutter.dart';

enum FlagsConfig {
  apm,
  uiTrace,
  screenLoading,
  endScreenLoading,
  screenRendering,
  customSpan,
}

extension FeatureExtensions on FlagsConfig {
  Future<bool> isEnabled() async {
    switch (this) {
      case FlagsConfig.apm:
        return (await APM.isEnabled()) ?? false;
      case FlagsConfig.uiTrace:
        return (await APM.isAutoUiTraceEnabled()) ?? false;
      case FlagsConfig.screenLoading:
        return (await APM.isScreenLoadingEnabled()) ?? false;
      case FlagsConfig.endScreenLoading:
        return (await APM.isEndScreenLoadingEnabled()) ?? false;
      case FlagsConfig.screenRendering:
        return (await APM.isScreenRenderEnabled()) ?? false;
      case FlagsConfig.customSpan:
        return (await APM.isCustomSpanEnabled()) ?? false;
      default:
        return false;
    }
  }
}
