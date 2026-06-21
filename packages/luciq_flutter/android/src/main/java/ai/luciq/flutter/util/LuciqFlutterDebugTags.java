package ai.luciq.flutter.util;

/**
 * Native Android debug-log tag inventory mirroring
 * lib/src/constants/debug_tags.dart.
 *
 * Each tag uses the same suffix as the Dart-side tag with an `Android-` segment
 * injected after the `LCQ-Flutter-` prefix, so a mixed Dart+native log stream
 * can be filtered per platform while remaining grep-compatible across both.
 *
 *   Dart:    LCQ-Flutter-APM-FLOW:
 *   iOS:     LCQ-Flutter-iOS-APM-FLOW:
 *   Android: LCQ-Flutter-Android-APM-FLOW:
 */
public final class LuciqFlutterDebugTags {
    public static final String CORE                 = "LCQ-Flutter-Android-CORE:";
    public static final String SCREEN_TRACKING      = "LCQ-Flutter-Android-SCREEN:";
    public static final String APM_SCREEN_LOADING   = "LCQ-Flutter-Android-APM-SL:";
    public static final String APM_SCREEN_RENDERING = "LCQ-Flutter-Android-APM-SR:";
    public static final String APM_UI_TRACE         = "LCQ-Flutter-Android-APM-UI:";
    public static final String APM_APP_LAUNCH       = "LCQ-Flutter-Android-APM-LAUNCH:";
    public static final String APM_CUSTOM_SPAN      = "LCQ-Flutter-Android-APM-SPAN:";
    public static final String APM_FLOW             = "LCQ-Flutter-Android-APM-FLOW:";
    public static final String APM_NETWORK          = "LCQ-Flutter-Android-APM-NET:";
    public static final String BUG_REPORTING        = "LCQ-Flutter-Android-BR:";
    public static final String CRASH_REPORTING      = "LCQ-Flutter-Android-CRASH:";
    public static final String SESSION_REPLAY       = "LCQ-Flutter-Android-SR:";
    public static final String PRIVATE_VIEW         = "LCQ-Flutter-Android-PRIV:";
    public static final String FEATURE_FLAGS        = "LCQ-Flutter-Android-FF:";
    public static final String NETWORK              = "LCQ-Flutter-Android-NET:";
    public static final String SURVEYS              = "LCQ-Flutter-Android-SUR:";
    public static final String REPLIES              = "LCQ-Flutter-Android-REP:";
    public static final String FEATURE_REQUESTS     = "LCQ-Flutter-Android-FR:";
    public static final String APP_STATE            = "LCQ-Flutter-Android-STATE:";
    public static final String LUCIQ_LOG            = "LCQ-Flutter-Android-LOG:";

    private LuciqFlutterDebugTags() {}
}
