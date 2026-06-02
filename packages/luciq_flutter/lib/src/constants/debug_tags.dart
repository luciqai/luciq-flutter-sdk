/// Debug log tags used to identify SDK functional areas in console output.
///
/// Each tag is passed as the `tag:` argument to [LuciqLogger] calls so log
/// streams can be grep-filtered by area (e.g. `LCQ-Flutter-APM-SPAN:`).
///
/// Conventions:
///  - All tags are prefixed `LCQ-Flutter-` and suffixed `:`.
///  - One tag per public functional area. Sub-areas (`APM_SCREEN_LOADING`)
///    get their own tag rather than sharing a parent so filtering is precise.
class DebugTags {
  DebugTags._();

  static const String core               = 'LCQ-Flutter-CORE:';
  static const String screenTracking     = 'LCQ-Flutter-SCREEN:';
  static const String apmScreenLoading   = 'LCQ-Flutter-APM-SL:';
  static const String apmScreenRendering = 'LCQ-Flutter-APM-SR:';
  static const String apmUITrace         = 'LCQ-Flutter-APM-UI:';
  static const String apmAppLaunch       = 'LCQ-Flutter-APM-LAUNCH:';
  static const String apmCustomSpan      = 'LCQ-Flutter-APM-SPAN:';
  static const String apmFlow            = 'LCQ-Flutter-APM-FLOW:';
  static const String apmNetwork         = 'LCQ-Flutter-APM-NET:';
  static const String bugReporting       = 'LCQ-Flutter-BR:';
  static const String crashReporting     = 'LCQ-Flutter-CRASH:';
  static const String sessionReplay      = 'LCQ-Flutter-SR:';
  static const String privateView        = 'LCQ-Flutter-PRIV:';
  static const String featureFlags       = 'LCQ-Flutter-FF:';
  static const String network            = 'LCQ-Flutter-NET:';
  static const String surveys            = 'LCQ-Flutter-SUR:';
  static const String replies            = 'LCQ-Flutter-REP:';
  static const String featureRequests    = 'LCQ-Flutter-FR:';
  static const String appState           = 'LCQ-Flutter-STATE:';
  static const String luciqLog           = 'LCQ-Flutter-LOG:';
}
