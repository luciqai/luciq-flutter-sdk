package ai.luciq.flutter;

import static org.junit.Assert.assertTrue;

import ai.luciq.library.LogLevel;
import ai.luciq.bug.BugReporting;
import ai.luciq.bug.invocation.Option;
import ai.luciq.featuresrequest.ActionType;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.library.LuciqColorTheme;
import ai.luciq.library.LuciqCustomTextPlaceHolder.Key;
import ai.luciq.library.OnSdkDismissCallback.DismissType;
import ai.luciq.library.ReproMode;
import ai.luciq.library.extendedbugreport.ExtendedBugReport;
import ai.luciq.library.internal.module.LuciqLocale;
import ai.luciq.library.invocation.LuciqInvocationEvent;
import ai.luciq.library.invocation.util.LuciqFloatingButtonEdge;
import ai.luciq.library.invocation.util.LuciqVideoRecordingButtonPosition;
import ai.luciq.library.ui.onboarding.WelcomeMessage;

import org.junit.Test;

public class ArgsRegistryTest {
    @Test
    public void testSdkLogLevels() {
        Integer[] values = {
                LogLevel.NONE,
                LogLevel.ERROR,
                LogLevel.DEBUG,
                LogLevel.VERBOSE,
        };

        for (Integer value : values) {
            assertTrue(ArgsRegistry.sdkLogLevels.containsValue(value));
        }
    }

    @Test
    public void testInvocationEvents() {
        LuciqInvocationEvent[] values = {
                LuciqInvocationEvent.NONE,
                LuciqInvocationEvent.SHAKE,
                LuciqInvocationEvent.FLOATING_BUTTON,
                LuciqInvocationEvent.SCREENSHOT,
                LuciqInvocationEvent.TWO_FINGER_SWIPE_LEFT,
        };

        for (LuciqInvocationEvent value : values) {
            assertTrue(ArgsRegistry.invocationEvents.containsValue(value));
        }
    }

    @Test
    public void testInvocationOptions() {
        Integer[] values = {
                Option.EMAIL_FIELD_HIDDEN,
                Option.EMAIL_FIELD_OPTIONAL,
                Option.COMMENT_FIELD_REQUIRED,
                Option.DISABLE_POST_SENDING_DIALOG,
        };

        for (Integer value : values) {
            assertTrue(ArgsRegistry.invocationOptions.containsValue(value));
        }
    }

    @Test
    public void testColorThemes() {
        LuciqColorTheme[] values = {
                LuciqColorTheme.LuciqColorThemeLight,
                LuciqColorTheme.LuciqColorThemeDark,
        };

        for (LuciqColorTheme value : values) {
            assertTrue(ArgsRegistry.colorThemes.containsValue(value));
        }
    }

    @Test
    public void testFloatingButtonEdges() {
        LuciqFloatingButtonEdge[] values = {
                LuciqFloatingButtonEdge.LEFT,
                LuciqFloatingButtonEdge.RIGHT,
        };

        for (LuciqFloatingButtonEdge value : values) {
            assertTrue(ArgsRegistry.floatingButtonEdges.containsValue(value));
        }
    }

    @Test
    public void testRecordButtonPositions() {
        LuciqVideoRecordingButtonPosition[] values = {
                LuciqVideoRecordingButtonPosition.TOP_LEFT,
                LuciqVideoRecordingButtonPosition.TOP_RIGHT,
                LuciqVideoRecordingButtonPosition.BOTTOM_LEFT,
                LuciqVideoRecordingButtonPosition.BOTTOM_RIGHT,
        };

        for (LuciqVideoRecordingButtonPosition value : values) {
            assertTrue(ArgsRegistry.recordButtonPositions.containsValue(value));
        }
    }

    @Test
    public void testwelcomeMessageStates() {
        WelcomeMessage.State[] values = {
                WelcomeMessage.State.LIVE,
                WelcomeMessage.State.BETA,
                WelcomeMessage.State.DISABLED,
        };

        for (WelcomeMessage.State value : values) {
            assertTrue(ArgsRegistry.welcomeMessageStates.containsValue(value));
        }
    }

    @Test
    public void testReportTypes() {
        Integer[] values = {
                BugReporting.ReportType.BUG,
                BugReporting.ReportType.FEEDBACK,
                BugReporting.ReportType.QUESTION,
        };

        for (Integer value : values) {
            assertTrue(ArgsRegistry.reportTypes.containsValue(value));
        }
    }

    @Test
    public void testDismissTypes() {
        DismissType[] values = {
                DismissType.SUBMIT,
                DismissType.CANCEL,
                DismissType.ADD_ATTACHMENT,
        };

        for (DismissType value : values) {
            assertTrue(ArgsRegistry.dismissTypes.containsValue(value));
        }
    }

    @Test
    public void testActionTypes() {
        Integer[] values = {
                ActionType.REQUEST_NEW_FEATURE,
                ActionType.ADD_COMMENT_TO_FEATURE,
        };

        for (Integer value : values) {
            assertTrue(ArgsRegistry.actionTypes.containsValue(value));
        }
    }

    @Test
    public void testExtendedBugReportStates() {
        ExtendedBugReport.State[] values = {
                ExtendedBugReport.State.ENABLED_WITH_REQUIRED_FIELDS,
                ExtendedBugReport.State.ENABLED_WITH_OPTIONAL_FIELDS,
                ExtendedBugReport.State.DISABLED,
        };

        for (ExtendedBugReport.State value : values) {
            assertTrue(ArgsRegistry.extendedBugReportStates.containsValue(value));
        }
    }

    @Test
    public void testReproModes() {
        Integer[] values = {
                ReproMode.Disable,
                ReproMode.EnableWithScreenshots,
                ReproMode.EnableWithNoScreenshots,
        };

        for (Integer value : values) {
            assertTrue(ArgsRegistry.reproModes.containsValue(value));
        }
    }


    @Test
    public void testLocales() {
        LuciqLocale[] values = {
                LuciqLocale.ARABIC,
                LuciqLocale.AZERBAIJANI,
                LuciqLocale.SIMPLIFIED_CHINESE,
                LuciqLocale.TRADITIONAL_CHINESE,
                LuciqLocale.CZECH,
                LuciqLocale.DANISH,
                LuciqLocale.NETHERLANDS,
                LuciqLocale.ENGLISH,
                LuciqLocale.FINNISH,
                LuciqLocale.FRENCH,
                LuciqLocale.GERMAN,
                LuciqLocale.HUNGARIAN,
                LuciqLocale.INDONESIAN,
                LuciqLocale.ITALIAN,
                LuciqLocale.JAPANESE,
                LuciqLocale.KOREAN,
                LuciqLocale.NORWEGIAN,
                LuciqLocale.POLISH,
                LuciqLocale.PORTUGUESE_BRAZIL,
                LuciqLocale.PORTUGUESE_PORTUGAL,
                LuciqLocale.ROMANIAN,
                LuciqLocale.RUSSIAN,
                LuciqLocale.SLOVAK,
                LuciqLocale.SPANISH,
                LuciqLocale.SWEDISH,
                LuciqLocale.TURKISH,
        };

        for (LuciqLocale value : values) {
            assertTrue(ArgsRegistry.locales.containsValue(value));
        }
    }


    @Test
    public void testPlaceholder() {
        Key[] values = {
                Key.SHAKE_HINT,
                Key.SWIPE_HINT,
                Key.INVALID_EMAIL_MESSAGE,
                Key.EMAIL_FIELD_HINT,
                Key.COMMENT_FIELD_HINT_FOR_BUG_REPORT,
                Key.COMMENT_FIELD_HINT_FOR_FEEDBACK,
                Key.COMMENT_FIELD_HINT_FOR_QUESTION,
                Key.INVOCATION_HEADER,
                Key.REPORT_QUESTION,
                Key.REPORT_BUG,
                Key.REPORT_FEEDBACK,
                Key.CONVERSATIONS_LIST_TITLE,
                Key.ADD_VOICE_MESSAGE,
                Key.ADD_IMAGE_FROM_GALLERY,
                Key.ADD_EXTRA_SCREENSHOT,
                Key.ADD_VIDEO,
                Key.AUDIO_RECORDING_PERMISSION_DENIED,
                Key.VOICE_MESSAGE_PRESS_AND_HOLD_TO_RECORD,
                Key.VOICE_MESSAGE_RELEASE_TO_ATTACH,
                Key.SUCCESS_DIALOG_HEADER,
                Key.VIDEO_RECORDING_FAB_BUBBLE_HINT,
                Key.CONVERSATION_TEXT_FIELD_HINT,
                Key.REPORT_SUCCESSFULLY_SENT,

                Key.BETA_WELCOME_MESSAGE_WELCOME_STEP_TITLE,
                Key.BETA_WELCOME_MESSAGE_WELCOME_STEP_CONTENT,
                Key.BETA_WELCOME_MESSAGE_HOW_TO_REPORT_STEP_TITLE,
                Key.BETA_WELCOME_MESSAGE_HOW_TO_REPORT_STEP_CONTENT,
                Key.BETA_WELCOME_MESSAGE_FINISH_STEP_TITLE,
                Key.BETA_WELCOME_MESSAGE_FINISH_STEP_CONTENT,
                Key.LIVE_WELCOME_MESSAGE_TITLE,
                Key.LIVE_WELCOME_MESSAGE_CONTENT,

                Key.SURVEYS_STORE_RATING_THANKS_TITLE,
                Key.SURVEYS_STORE_RATING_THANKS_SUBTITLE,

                Key.REPORT_BUG_DESCRIPTION,
                Key.REPORT_FEEDBACK_DESCRIPTION,
                Key.REPORT_QUESTION_DESCRIPTION,
                Key.REQUEST_FEATURE_DESCRIPTION,

                Key.REPORT_DISCARD_DIALOG_TITLE,
                Key.REPORT_DISCARD_DIALOG_BODY,
                Key.REPORT_DISCARD_DIALOG_NEGATIVE_ACTION,
                Key.REPORT_DISCARD_DIALOG_POSITIVE_ACTION,
                Key.REPORT_ADD_ATTACHMENT_HEADER,

                Key.REPORT_REPRO_STEPS_DISCLAIMER_BODY,
                Key.REPORT_REPRO_STEPS_DISCLAIMER_LINK,
                Key.REPRO_STEPS_PROGRESS_DIALOG_BODY,
                Key.REPRO_STEPS_LIST_HEADER,
                Key.REPRO_STEPS_LIST_DESCRIPTION,
                Key.REPRO_STEPS_LIST_EMPTY_STATE_DESCRIPTION,
                Key.REPRO_STEPS_LIST_ITEM_NUMBERING_TITLE,

                Key.CHATS_TEAM_STRING_NAME,
                Key.REPLIES_NOTIFICATION_REPLY_BUTTON,
                Key.REPLIES_NOTIFICATION_DISMISS_BUTTON,

                Key.BUG_ATTACHMENT_DIALOG_OK_BUTTON,
                Key.CHATS_TYPE_AUDIO,
                Key.CHATS_TYPE_IMAGE,
                Key.CHATS_TYPE_VIDEO,
                Key.CHATS_MULTIPLE_MESSAGE_NOTIFICATION,
                Key.COMMENT_FIELD_INSUFFICIENT_CONTENT,
        };

        for (Key value : values) {
            assertTrue(ArgsRegistry.placeholders.containsValue(value));
        }
    }

}
