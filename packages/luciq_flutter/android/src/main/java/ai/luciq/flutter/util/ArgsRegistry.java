package ai.luciq.flutter.util;

import androidx.annotation.NonNull;

import ai.luciq.crash.models.LuciqNonFatalException;
import ai.luciq.library.LogLevel;
import ai.luciq.bug.BugReporting;
import ai.luciq.bug.invocation.Option;
import ai.luciq.featuresrequest.ActionType;
import ai.luciq.library.LuciqColorTheme;
import ai.luciq.library.LuciqCustomTextPlaceHolder.Key;
import ai.luciq.library.MaskingType;
import ai.luciq.library.OnSdkDismissCallback.DismissType;
import ai.luciq.library.ReproMode;
import ai.luciq.library.extendedbugreport.ExtendedBugReport;
import ai.luciq.library.internal.module.LuciqLocale;
import ai.luciq.library.invocation.LuciqInvocationEvent;
import ai.luciq.library.invocation.util.LuciqFloatingButtonEdge;
import ai.luciq.library.invocation.util.LuciqVideoRecordingButtonPosition;
import ai.luciq.library.model.StepType;
import ai.luciq.library.ui.onboarding.WelcomeMessage;

import java.util.HashMap;
import java.util.Objects;

public final class ArgsRegistry {

    public static class ArgsMap<T> extends HashMap<String, T> {
        @NonNull
        @Override
        public T get(Object key) {
            return Objects.requireNonNull(super.get(key));
        }
    }

    public static final ArgsMap<Integer> sdkLogLevels = new ArgsMap<Integer>() {{
        put("LogLevel.none", LogLevel.NONE);
        put("LogLevel.error", LogLevel.ERROR);
        put("LogLevel.debug", LogLevel.DEBUG);
        put("LogLevel.verbose", LogLevel.VERBOSE);
    }};

    public static ArgsMap<LuciqInvocationEvent> invocationEvents = new ArgsMap<LuciqInvocationEvent>() {{
        put("InvocationEvent.none", LuciqInvocationEvent.NONE);
        put("InvocationEvent.shake", LuciqInvocationEvent.SHAKE);
        put("InvocationEvent.floatingButton", LuciqInvocationEvent.FLOATING_BUTTON);
        put("InvocationEvent.screenshot", LuciqInvocationEvent.SCREENSHOT);
        put("InvocationEvent.twoFingersSwipeLeft", LuciqInvocationEvent.TWO_FINGER_SWIPE_LEFT);
    }};

    public static final ArgsMap<Integer> invocationOptions = new ArgsMap<Integer>() {{
        put("InvocationOption.emailFieldHidden", Option.EMAIL_FIELD_HIDDEN);
        put("InvocationOption.emailFieldOptional", Option.EMAIL_FIELD_OPTIONAL);
        put("InvocationOption.commentFieldRequired", Option.COMMENT_FIELD_REQUIRED);
        put("InvocationOption.disablePostSendingDialog", Option.DISABLE_POST_SENDING_DIALOG);
    }};

    public static final ArgsMap<LuciqColorTheme> colorThemes = new ArgsMap<LuciqColorTheme>() {{
        put("ColorTheme.light", LuciqColorTheme.LuciqColorThemeLight);
        put("ColorTheme.dark", LuciqColorTheme.LuciqColorThemeDark);
    }};

    public static final ArgsMap<Integer> autoMasking = new ArgsMap<Integer>() {{
        put("AutoMasking.labels", MaskingType.LABELS);
        put("AutoMasking.textInputs", MaskingType.TEXT_INPUTS);
        put("AutoMasking.media", MaskingType.MEDIA);
        put("AutoMasking.none", MaskingType.MASK_NOTHING);
    }};

   public static ArgsMap<LuciqNonFatalException.Level> nonFatalExceptionLevel = new ArgsMap<LuciqNonFatalException.Level>() {{
        put("NonFatalExceptionLevel.critical", LuciqNonFatalException.Level.CRITICAL);
        put("NonFatalExceptionLevel.error", LuciqNonFatalException.Level.ERROR);
        put("NonFatalExceptionLevel.warning", LuciqNonFatalException.Level.WARNING);
        put("NonFatalExceptionLevel.info", LuciqNonFatalException.Level.INFO);
    }};
    public static final ArgsMap<LuciqFloatingButtonEdge> floatingButtonEdges = new ArgsMap<LuciqFloatingButtonEdge>() {{
        put("FloatingButtonEdge.left", LuciqFloatingButtonEdge.LEFT);
        put("FloatingButtonEdge.right", LuciqFloatingButtonEdge.RIGHT);
    }};

    public static ArgsMap<LuciqVideoRecordingButtonPosition> recordButtonPositions = new ArgsMap<LuciqVideoRecordingButtonPosition>() {{
        put("Position.topLeft", LuciqVideoRecordingButtonPosition.TOP_LEFT);
        put("Position.topRight", LuciqVideoRecordingButtonPosition.TOP_RIGHT);
        put("Position.bottomLeft", LuciqVideoRecordingButtonPosition.BOTTOM_LEFT);
        put("Position.bottomRight", LuciqVideoRecordingButtonPosition.BOTTOM_RIGHT);
    }};

    public static final ArgsMap<String> userConsentActionType = new ArgsMap<String>() {{
        put("UserConsentActionType.dropAutoCapturedMedia",  ai.luciq.bug.userConsent.ActionType.DROP_AUTO_CAPTURED_MEDIA);
        put("UserConsentActionType.dropLogs",  ai.luciq.bug.userConsent.ActionType.DROP_LOGS);
        put("UserConsentActionType.noChat",  ai.luciq.bug.userConsent.ActionType.NO_CHAT);
    }};

    public static ArgsMap<WelcomeMessage.State> welcomeMessageStates = new ArgsMap<WelcomeMessage.State>() {{
        put("WelcomeMessageMode.live", WelcomeMessage.State.LIVE);
        put("WelcomeMessageMode.beta", WelcomeMessage.State.BETA);
        put("WelcomeMessageMode.disabled", WelcomeMessage.State.DISABLED);
    }};

    public static final ArgsMap<Integer> reportTypes = new ArgsMap<Integer>() {{
        put("ReportType.bug", BugReporting.ReportType.BUG);
        put("ReportType.feedback", BugReporting.ReportType.FEEDBACK);
        put("ReportType.question", BugReporting.ReportType.QUESTION);
    }};

    public static final ArgsMap<DismissType> dismissTypes = new ArgsMap<DismissType>() {{
        put("dismissTypeSubmit", DismissType.SUBMIT);
        put("dismissTypeCancel", DismissType.CANCEL);
        put("dismissTypeAddAttachment", DismissType.ADD_ATTACHMENT);
    }};

    public static final ArgsMap<Integer> actionTypes = new ArgsMap<Integer>() {{
        put("ActionType.requestNewFeature", ActionType.REQUEST_NEW_FEATURE);
        put("ActionType.addCommentToFeature", ActionType.ADD_COMMENT_TO_FEATURE);
    }};

    public static ArgsMap<ExtendedBugReport.State> extendedBugReportStates = new ArgsMap<ExtendedBugReport.State>() {{
        put("ExtendedBugReportMode.enabledWithRequiredFields", ExtendedBugReport.State.ENABLED_WITH_REQUIRED_FIELDS);
        put("ExtendedBugReportMode.enabledWithOptionalFields", ExtendedBugReport.State.ENABLED_WITH_OPTIONAL_FIELDS);
        put("ExtendedBugReportMode.disabled", ExtendedBugReport.State.DISABLED);
    }};

    public static final ArgsMap<Integer> reproModes = new ArgsMap<Integer>() {{
        put("ReproStepsMode.enabledWithNoScreenshots", ReproMode.EnableWithNoScreenshots);
        put("ReproStepsMode.enabled", ReproMode.EnableWithScreenshots);
        put("ReproStepsMode.disabled", ReproMode.Disable);
    }};

    public static final ArgsMap<LuciqLocale> locales = new ArgsMap<LuciqLocale>() {{
        put("LCQLocale.arabic", LuciqLocale.ARABIC);
        put("LCQLocale.azerbaijani", LuciqLocale.AZERBAIJANI);
        put("LCQLocale.bulgarian", LuciqLocale.BULGARIAN);
        put("LCQLocale.chineseSimplified", LuciqLocale.SIMPLIFIED_CHINESE);
        put("LCQLocale.chineseTraditional", LuciqLocale.TRADITIONAL_CHINESE);
        put("LCQLocale.croatian", LuciqLocale.CROATIAN);
        put("LCQLocale.czech", LuciqLocale.CZECH);
        put("LCQLocale.danish", LuciqLocale.DANISH);
        put("LCQLocale.dutch", LuciqLocale.NETHERLANDS);
        put("LCQLocale.english", LuciqLocale.ENGLISH);
        put("LCQLocale.estonian", LuciqLocale.ESTONIAN);
        put("LCQLocale.finnish", LuciqLocale.FINNISH);
        put("LCQLocale.french", LuciqLocale.FRENCH);
        put("LCQLocale.german", LuciqLocale.GERMAN);
        put("LCQLocale.greek", LuciqLocale.GREEK);
        put("LCQLocale.hungarian", LuciqLocale.HUNGARIAN);
        put("LCQLocale.indonesian", LuciqLocale.INDONESIAN);
        put("LCQLocale.italian", LuciqLocale.ITALIAN);
        put("LCQLocale.japanese", LuciqLocale.JAPANESE);
        put("LCQLocale.korean", LuciqLocale.KOREAN);
        put("LCQLocale.norwegian", LuciqLocale.NORWEGIAN);
        put("LCQLocale.polish", LuciqLocale.POLISH);
        put("LCQLocale.portugueseBrazil", LuciqLocale.PORTUGUESE_BRAZIL);
        put("LCQLocale.portuguesePortugal", LuciqLocale.PORTUGUESE_PORTUGAL);
        put("LCQLocale.romanian", LuciqLocale.ROMANIAN);
        put("LCQLocale.russian", LuciqLocale.RUSSIAN);
        put("LCQLocale.serbian", LuciqLocale.SERBIAN);
        put("LCQLocale.slovak", LuciqLocale.SLOVAK);
        put("LCQLocale.slovenian", LuciqLocale.SLOVENIAN);
        put("LCQLocale.spanish", LuciqLocale.SPANISH);
        put("LCQLocale.swedish", LuciqLocale.SWEDISH);
        put("LCQLocale.turkish", LuciqLocale.TURKISH);
        put("LCQLocale.ukrainian", LuciqLocale.UKRAINIAN);
    }};

    public static final ArgsMap<Key> placeholders = new ArgsMap<Key>() {{
        put("CustomTextPlaceHolderKey.shakeHint", Key.SHAKE_HINT);
        put("CustomTextPlaceHolderKey.swipeHint", Key.SWIPE_HINT);
        put("CustomTextPlaceHolderKey.invalidEmailMessage", Key.INVALID_EMAIL_MESSAGE);
        put("CustomTextPlaceHolderKey.emailFieldHint", Key.EMAIL_FIELD_HINT);
        put("CustomTextPlaceHolderKey.commentFieldHintForBugReport", Key.COMMENT_FIELD_HINT_FOR_BUG_REPORT);
        put("CustomTextPlaceHolderKey.commentFieldHintForFeedback", Key.COMMENT_FIELD_HINT_FOR_FEEDBACK);
        put("CustomTextPlaceHolderKey.commentFieldHintForQuestion", Key.COMMENT_FIELD_HINT_FOR_QUESTION);
        put("CustomTextPlaceHolderKey.invocationHeader", Key.INVOCATION_HEADER);
        put("CustomTextPlaceHolderKey.reportQuestion", Key.REPORT_QUESTION);
        put("CustomTextPlaceHolderKey.reportBug", Key.REPORT_BUG);
        put("CustomTextPlaceHolderKey.reportFeedback", Key.REPORT_FEEDBACK);
        put("CustomTextPlaceHolderKey.conversationsListTitle", Key.CONVERSATIONS_LIST_TITLE);
        put("CustomTextPlaceHolderKey.addVoiceMessage", Key.ADD_VOICE_MESSAGE);
        put("CustomTextPlaceHolderKey.addImageFromGallery", Key.ADD_IMAGE_FROM_GALLERY);
        put("CustomTextPlaceHolderKey.addExtraScreenshot", Key.ADD_EXTRA_SCREENSHOT);
        put("CustomTextPlaceHolderKey.addVideo", Key.ADD_VIDEO);
        put("CustomTextPlaceHolderKey.audioRecordingPermissionDenied", Key.AUDIO_RECORDING_PERMISSION_DENIED);
        put("CustomTextPlaceHolderKey.voiceMessagePressAndHoldToRecord", Key.VOICE_MESSAGE_PRESS_AND_HOLD_TO_RECORD);
        put("CustomTextPlaceHolderKey.voiceMessageReleaseToAttach", Key.VOICE_MESSAGE_RELEASE_TO_ATTACH);
        put("CustomTextPlaceHolderKey.successDialogHeader", Key.SUCCESS_DIALOG_HEADER);
        put("CustomTextPlaceHolderKey.videoPressRecord", Key.VIDEO_RECORDING_FAB_BUBBLE_HINT);
        put("CustomTextPlaceHolderKey.conversationTextFieldHint", Key.CONVERSATION_TEXT_FIELD_HINT);
        put("CustomTextPlaceHolderKey.reportSuccessfullySent", Key.REPORT_SUCCESSFULLY_SENT);

        put("CustomTextPlaceHolderKey.betaWelcomeMessageWelcomeStepTitle", Key.BETA_WELCOME_MESSAGE_WELCOME_STEP_TITLE);
        put("CustomTextPlaceHolderKey.betaWelcomeMessageWelcomeStepContent", Key.BETA_WELCOME_MESSAGE_WELCOME_STEP_CONTENT);
        put("CustomTextPlaceHolderKey.betaWelcomeMessageHowToReportStepTitle", Key.BETA_WELCOME_MESSAGE_HOW_TO_REPORT_STEP_TITLE);
        put("CustomTextPlaceHolderKey.betaWelcomeMessageHowToReportStepContent", Key.BETA_WELCOME_MESSAGE_HOW_TO_REPORT_STEP_CONTENT);
        put("CustomTextPlaceHolderKey.betaWelcomeMessageFinishStepTitle", Key.BETA_WELCOME_MESSAGE_FINISH_STEP_TITLE);
        put("CustomTextPlaceHolderKey.betaWelcomeMessageFinishStepContent", Key.BETA_WELCOME_MESSAGE_FINISH_STEP_CONTENT);
        put("CustomTextPlaceHolderKey.liveWelcomeMessageTitle", Key.LIVE_WELCOME_MESSAGE_TITLE);
        put("CustomTextPlaceHolderKey.liveWelcomeMessageContent", Key.LIVE_WELCOME_MESSAGE_CONTENT);

        put("CustomTextPlaceHolderKey.surveysStoreRatingThanksTitle", Key.SURVEYS_STORE_RATING_THANKS_TITLE);
        put("CustomTextPlaceHolderKey.surveysStoreRatingThanksSubtitle", Key.SURVEYS_STORE_RATING_THANKS_SUBTITLE);

        put("CustomTextPlaceHolderKey.reportBugDescription", Key.REPORT_BUG_DESCRIPTION);
        put("CustomTextPlaceHolderKey.reportFeedbackDescription", Key.REPORT_FEEDBACK_DESCRIPTION);
        put("CustomTextPlaceHolderKey.reportQuestionDescription", Key.REPORT_QUESTION_DESCRIPTION);
        put("CustomTextPlaceHolderKey.requestFeatureDescription", Key.REQUEST_FEATURE_DESCRIPTION);

        put("CustomTextPlaceHolderKey.discardAlertTitle", Key.REPORT_DISCARD_DIALOG_TITLE);
        put("CustomTextPlaceHolderKey.discardAlertMessage", Key.REPORT_DISCARD_DIALOG_BODY);
        put("CustomTextPlaceHolderKey.discardAlertCancel", Key.REPORT_DISCARD_DIALOG_NEGATIVE_ACTION);
        put("CustomTextPlaceHolderKey.discardAlertAction", Key.REPORT_DISCARD_DIALOG_POSITIVE_ACTION);
        put("CustomTextPlaceHolderKey.addAttachmentButtonTitleStringName", Key.REPORT_ADD_ATTACHMENT_HEADER);

        put("CustomTextPlaceHolderKey.reportReproStepsDisclaimerBody", Key.REPORT_REPRO_STEPS_DISCLAIMER_BODY);
        put("CustomTextPlaceHolderKey.reportReproStepsDisclaimerLink", Key.REPORT_REPRO_STEPS_DISCLAIMER_LINK);
        put("CustomTextPlaceHolderKey.reproStepsProgressDialogBody", Key.REPRO_STEPS_PROGRESS_DIALOG_BODY);
        put("CustomTextPlaceHolderKey.reproStepsListHeader", Key.REPRO_STEPS_LIST_HEADER);
        put("CustomTextPlaceHolderKey.reproStepsListDescription", Key.REPRO_STEPS_LIST_DESCRIPTION);
        put("CustomTextPlaceHolderKey.reproStepsListEmptyStateDescription", Key.REPRO_STEPS_LIST_EMPTY_STATE_DESCRIPTION);
        put("CustomTextPlaceHolderKey.reproStepsListItemTitle", Key.REPRO_STEPS_LIST_ITEM_NUMBERING_TITLE);

        put("CustomTextPlaceHolderKey.repliesNotificationTeamName", Key.CHATS_TEAM_STRING_NAME);
        put("CustomTextPlaceHolderKey.repliesNotificationReplyButton", Key.REPLIES_NOTIFICATION_REPLY_BUTTON);
        put("CustomTextPlaceHolderKey.repliesNotificationDismissButton", Key.REPLIES_NOTIFICATION_DISMISS_BUTTON);

        put("CustomTextPlaceHolderKey.okButtonText", Key.BUG_ATTACHMENT_DIALOG_OK_BUTTON);
        put("CustomTextPlaceHolderKey.audio", Key.CHATS_TYPE_AUDIO);
        put("CustomTextPlaceHolderKey.image", Key.CHATS_TYPE_IMAGE);
        put("CustomTextPlaceHolderKey.screenRecording", Key.CHATS_TYPE_VIDEO);
        put("CustomTextPlaceHolderKey.messagesNotificationAndOthers", Key.CHATS_MULTIPLE_MESSAGE_NOTIFICATION);
        put("CustomTextPlaceHolderKey.insufficientContentMessage", Key.COMMENT_FIELD_INSUFFICIENT_CONTENT);
    }};

    public static final ArgsMap<String> gestureStepType = new ArgsMap<String>() {{
        put("GestureType.swipe", StepType.SWIPE);
        put("GestureType.scroll", StepType.SCROLL);
        put("GestureType.tap", StepType.TAP);
        put("GestureType.pinch", StepType.PINCH);
        put("GestureType.longPress", StepType.LONG_PRESS);
        put("GestureType.doubleTap", StepType.DOUBLE_TAP);
    }};
}
