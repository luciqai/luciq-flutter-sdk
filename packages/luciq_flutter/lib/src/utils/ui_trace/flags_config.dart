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
        return APM.isEnabled();
      case FlagsConfig.uiTrace:
        return APM.isAutoUiTraceEnabled();
      case FlagsConfig.screenLoading:
        return APM.isScreenLoadingEnabled();
      case FlagsConfig.endScreenLoading:
        return APM.isEndScreenLoadingEnabled();
      case FlagsConfig.screenRendering:
        return APM.isScreenRenderEnabled();
      case FlagsConfig.customSpan:
        return APM.isCustomSpanEnabled();
      default:
        return false;
    }
  }
}
