#import "ArgsRegistry.h"

@implementation ArgsRegistry

+ (ArgsDictionary *)sdkLogLevels {
    return @{
        @"LogLevel.none" : @(LCQSDKDebugLogsLevelNone),
        @"LogLevel.error" : @(LCQSDKDebugLogsLevelError),
        @"LogLevel.debug" : @(LCQSDKDebugLogsLevelDebug),
        @"LogLevel.verbose" : @(LCQSDKDebugLogsLevelVerbose),
    };
}

+ (ArgsDictionary *)invocationEvents {
    return @{
        @"InvocationEvent.none" : @(LCQInvocationEventNone),
        @"InvocationEvent.shake" : @(LCQInvocationEventShake),
        @"InvocationEvent.screenshot" : @(LCQInvocationEventScreenshot),
        @"InvocationEvent.twoFingersSwipeLeft" : @(LCQInvocationEventTwoFingersSwipeLeft),
        @"InvocationEvent.floatingButton" : @(LCQInvocationEventFloatingButton),
    };
}

+ (ArgsDictionary *)invocationOptions {
    return @{
        @"InvocationOption.emailFieldHidden" : @(LCQBugReportingOptionEmailFieldHidden),
        @"InvocationOption.emailFieldOptional" : @(LCQBugReportingOptionEmailFieldOptional),
        @"InvocationOption.commentFieldRequired" : @(LCQBugReportingOptionCommentFieldRequired),
        @"InvocationOption.disablePostSendingDialog" : @(LCQBugReportingOptionDisablePostSendingDialog),
    };
}

+ (ArgsDictionary *)colorThemes {
    return @{
        @"ColorTheme.light" : @(LCQColorThemeLight),
        @"ColorTheme.dark" : @(LCQColorThemeDark),
    };
}

+ (ArgsDictionary *)floatingButtonEdges {
    return @{
        @"FloatingButtonEdge.left" : @(CGRectMinXEdge),
        @"FloatingButtonEdge.right" : @(CGRectMaxXEdge),
    };
}

+ (ArgsDictionary *)autoMasking {
    return @{
        @"AutoMasking.labels" : @(LCQAutoMaskScreenshotOptionLabels),
        @"AutoMasking.textInputs" : @(LCQAutoMaskScreenshotOptionTextInputs),
        @"AutoMasking.media" : @(LCQAutoMaskScreenshotOptionMedia),
        @"AutoMasking.none" : @(LCQAutoMaskScreenshotOptionMaskNothing
),

    };
}


+ (ArgsDictionary *)recordButtonPositions {
    return @{
        @"Position.topLeft" : @(LCQPositionTopLeft),
        @"Position.topRight" : @(LCQPositionTopRight),
        @"Position.bottomLeft" : @(LCQPositionBottomLeft),
        @"Position.bottomRight" : @(LCQPositionBottomRight),
    };
}

+ (ArgsDictionary *)welcomeMessageStates {
    return @{
        @"WelcomeMessageMode.live" : @(LCQWelcomeMessageModeLive),
        @"WelcomeMessageMode.beta" : @(LCQWelcomeMessageModeBeta),
        @"WelcomeMessageMode.disabled" : @(LCQWelcomeMessageModeDisabled),
    };
}

+ (ArgsDictionary *)reportTypes {
    return @{
        @"ReportType.bug" : @(LCQBugReportingReportTypeBug),
        @"ReportType.feedback" : @(LCQBugReportingReportTypeFeedback),
        @"ReportType.question" : @(LCQBugReportingReportTypeQuestion),
    };
}

+ (ArgsDictionary *)dismissTypes {
    return @{
        @"DismissType.submit" : @(LCQDismissTypeSubmit),
        @"DismissType.cancel" : @(LCQDismissTypeCancel),
        @"DismissType.addAttachment" : @(LCQDismissTypeAddAttachment),
    };
}

+ (ArgsDictionary *)actionTypes {
    return @{
        @"ActionType.allActions" : @(LCQActionAllActions),
        @"ActionType.reportBug" : @(LCQActionReportBug),
        @"ActionType.requestNewFeature" : @(LCQActionRequestNewFeature),
        @"ActionType.addCommentToFeature" : @(LCQActionAddCommentToFeature),
    };
}

+ (ArgsDictionary *)extendedBugReportStates {
    return @{
        @"ExtendedBugReportMode.enabledWithRequiredFields" : @(LCQExtendedBugReportModeEnabledWithRequiredFields),
        @"ExtendedBugReportMode.enabledWithOptionalFields" : @(LCQExtendedBugReportModeEnabledWithOptionalFields),
        @"ExtendedBugReportMode.disabled" : @(LCQExtendedBugReportModeDisabled),
    };
}
+ (ArgsDictionary *)nonFatalExceptionLevel {
    return @{
        @"NonFatalExceptionLevel.info" : @(LCQNonFatalLevelInfo),
        @"NonFatalExceptionLevel.error" : @(LCQNonFatalLevelError),
        @"NonFatalExceptionLevel.warning" : @(LCQNonFatalLevelWarning),
        @"NonFatalExceptionLevel.critical" : @(LCQNonFatalLevelCritical)


    };
}

+ (ArgsDictionary *)reproModes {
    return @{
        @"ReproStepsMode.enabled" : @(LCQUserStepsModeEnable),
        @"ReproStepsMode.disabled" : @(LCQUserStepsModeDisable),
        @"ReproStepsMode.enabledWithNoScreenshots" : @(LCQUserStepsModeEnabledWithNoScreenshots),
    };
}


+ (ArgsDictionary *)locales {
    return @{
            @"LCQLocale.arabic" : @(LCQLocaleArabic),
            @"LCQLocale.azerbaijani" : @(LCQLocaleAzerbaijani),
            @"LCQLocale.bulgarian" : @(LCQLocaleBulgarian),
            @"LCQLocale.chineseSimplified" : @(LCQLocaleChineseSimplified),
            @"LCQLocale.chineseTraditional" : @(LCQLocaleChineseTraditional),
            @"LCQLocale.croatian" : @(LCQLocaleCroatian),
            @"LCQLocale.czech" : @(LCQLocaleCzech),
            @"LCQLocale.danish" : @(LCQLocaleDanish),
            @"LCQLocale.dutch" : @(LCQLocaleDutch),
            @"LCQLocale.english" : @(LCQLocaleEnglish),
            @"LCQLocale.estonian" : @(LCQLocaleEstonian),
            @"LCQLocale.finnish" : @(LCQLocaleFinnish),
            @"LCQLocale.french" : @(LCQLocaleFrench),
            @"LCQLocale.german" : @(LCQLocaleGerman),
            @"LCQLocale.greek" : @(LCQLocaleGreek),
            @"LCQLocale.hungarian" : @(LCQLocaleHungarian),
            @"LCQLocale.italian" : @(LCQLocaleItalian),
            @"LCQLocale.japanese" : @(LCQLocaleJapanese),
            @"LCQLocale.korean" : @(LCQLocaleKorean),
            @"LCQLocale.latvian" : @(LCQLocaleLatvian),
            @"LCQLocale.lithuanian" : @(LCQLocaleLithuanian),
            @"LCQLocale.norwegian" : @(LCQLocaleNorwegian),
            @"LCQLocale.polish" : @(LCQLocalePolish),
            @"LCQLocale.portugueseBrazil" : @(LCQLocalePortugueseBrazil),
            @"LCQLocale.portuguesePortugal" : @(LCQLocalePortuguese),
            @"LCQLocale.romanian" : @(LCQLocaleRomanian),
            @"LCQLocale.russian" : @(LCQLocaleRussian),
            @"LCQLocale.serbian" : @(LCQLocaleSerbian),
            @"LCQLocale.slovak" : @(LCQLocaleSlovak),
            @"LCQLocale.slovenian" : @(LCQLocaleSlovenian),
            @"LCQLocale.spanish" : @(LCQLocaleSpanish),
            @"LCQLocale.swedish" : @(LCQLocaleSwedish),
            @"LCQLocale.turkish" : @(LCQLocaleTurkish),
            @"LCQLocale.ukrainian" : @(LCQLocaleUkrainian),
    };
}

+ (NSDictionary<NSString *, NSString *> *)placeholders {
    return @{
        @"CustomTextPlaceHolderKey.shakeHint" : kLCQShakeStartAlertTextStringName,
        @"CustomTextPlaceHolderKey.swipeHint" : kLCQEdgeSwipeStartAlertTextStringName,
        @"CustomTextPlaceHolderKey.invalidEmailMessage" : kLCQInvalidEmailMessageStringName,
        @"CustomTextPlaceHolderKey.invocationHeader" : kLCQInvocationTitleStringName,
        @"CustomTextPlaceHolderKey.reportQuestion" : kLCQAskAQuestionStringName,
        @"CustomTextPlaceHolderKey.reportBug" : kLCQReportBugStringName,
        @"CustomTextPlaceHolderKey.reportFeedback" : kLCQReportFeedbackStringName,
        @"CustomTextPlaceHolderKey.emailFieldHint" : kLCQEmailFieldPlaceholderStringName,
        @"CustomTextPlaceHolderKey.commentFieldHintForBugReport" : kLCQCommentFieldPlaceholderForBugReportStringName,
        @"CustomTextPlaceHolderKey.commentFieldHintForFeedback" : kLCQCommentFieldPlaceholderForFeedbackStringName,
        @"CustomTextPlaceHolderKey.commentFieldHintForQuestion" : kLCQCommentFieldPlaceholderForQuestionStringName,
        @"CustomTextPlaceHolderKey.addVoiceMessage" : kLCQAddVoiceMessageStringName,
        @"CustomTextPlaceHolderKey.addImageFromGallery" : kLCQAddImageFromGalleryStringName,
        @"CustomTextPlaceHolderKey.addExtraScreenshot" : kLCQAddExtraScreenshotStringName,
        @"CustomTextPlaceHolderKey.conversationsListTitle" : kLCQChatsTitleStringName,
        @"CustomTextPlaceHolderKey.audioRecordingPermissionDenied" : kLCQAudioRecordingPermissionDeniedTitleStringName,
        @"CustomTextPlaceHolderKey.conversationTextFieldHint" : kLCQChatReplyFieldPlaceholderStringName,
        @"CustomTextPlaceHolderKey.voiceMessagePressAndHoldToRecord" : kLCQRecordingMessageToHoldTextStringName,
        @"CustomTextPlaceHolderKey.voiceMessageReleaseToAttach" : kLCQRecordingMessageToReleaseTextStringName,
        @"CustomTextPlaceHolderKey.reportSuccessfullySent" : kLCQThankYouAlertMessageStringName,
        @"CustomTextPlaceHolderKey.successDialogHeader" : kLCQThankYouAlertTitleStringName,
        @"CustomTextPlaceHolderKey.addVideo" : kLCQAddScreenRecordingMessageStringName,
        @"CustomTextPlaceHolderKey.videoPressRecord" : kLCQVideoPressRecordTitle,
        @"CustomTextPlaceHolderKey.betaWelcomeMessageWelcomeStepTitle" : kLCQBetaWelcomeMessageWelcomeStepTitle,
        @"CustomTextPlaceHolderKey.betaWelcomeMessageWelcomeStepContent" : kLCQBetaWelcomeMessageWelcomeStepContent,
        @"CustomTextPlaceHolderKey.betaWelcomeMessageHowToReportStepTitle" : kLCQBetaWelcomeMessageHowToReportStepTitle,
        @"CustomTextPlaceHolderKey.betaWelcomeMessageHowToReportStepContent" : kLCQBetaWelcomeMessageHowToReportStepContent,
        @"CustomTextPlaceHolderKey.betaWelcomeMessageFinishStepTitle" : kLCQBetaWelcomeMessageFinishStepTitle,
        @"CustomTextPlaceHolderKey.betaWelcomeMessageFinishStepContent" : kLCQBetaWelcomeMessageFinishStepContent,
        @"CustomTextPlaceHolderKey.liveWelcomeMessageTitle" : kLCQLiveWelcomeMessageTitle,
        @"CustomTextPlaceHolderKey.liveWelcomeMessageContent" : kLCQLiveWelcomeMessageContent,

        @"CustomTextPlaceHolderKey.repliesNotificationTeamName" : kLCQTeamStringName,
        @"CustomTextPlaceHolderKey.repliesNotificationReplyButton" : kLCQReplyButtonTitleStringName,
        @"CustomTextPlaceHolderKey.repliesNotificationDismissButton" : kLCQDismissButtonTitleStringName,

        @"CustomTextPlaceHolderKey.surveysStoreRatingThanksTitle" : kLCQStoreRatingThankYouTitleText,
        @"CustomTextPlaceHolderKey.surveysStoreRatingThanksSubtitle" : kLCQStoreRatingThankYouDescriptionText,

        @"CustomTextPlaceHolderKey.reportBugDescription" : kLCQReportBugDescriptionStringName,
        @"CustomTextPlaceHolderKey.reportFeedbackDescription" : kLCQReportFeedbackDescriptionStringName,
        @"CustomTextPlaceHolderKey.reportQuestionDescription" : kLCQReportQuestionDescriptionStringName,
        @"CustomTextPlaceHolderKey.requestFeatureDescription" : kLCQRequestFeatureDescriptionStringName,

        @"CustomTextPlaceHolderKey.discardAlertTitle" : kLCQDiscardAlertTitle,
        @"CustomTextPlaceHolderKey.discardAlertMessage" : kLCQDiscardAlertMessage,
        @"CustomTextPlaceHolderKey.discardAlertCancel" : kLCQDiscardAlertCancel,
        @"CustomTextPlaceHolderKey.discardAlertAction" : kLCQDiscardAlertAction,
        @"CustomTextPlaceHolderKey.addAttachmentButtonTitleStringName" : kLCQAddAttachmentButtonTitleStringName,

        @"CustomTextPlaceHolderKey.reportReproStepsDisclaimerBody" : kLCQReproStepsDisclaimerBody,
        @"CustomTextPlaceHolderKey.reportReproStepsDisclaimerLink" : kLCQReproStepsDisclaimerLink,
        @"CustomTextPlaceHolderKey.reproStepsProgressDialogBody" : kLCQProgressViewTitle,
        @"CustomTextPlaceHolderKey.reproStepsListHeader" : kLCQReproStepsListTitle,
        @"CustomTextPlaceHolderKey.reproStepsListDescription" : kLCQReproStepsListHeader,
        @"CustomTextPlaceHolderKey.reproStepsListEmptyStateDescription" : kLCQReproStepsListEmptyStateLabel,
        @"CustomTextPlaceHolderKey.reproStepsListItemTitle" : kLCQReproStepsListItemName,

        @"CustomTextPlaceHolderKey.okButtonText" : kLCQOkButtonTitleStringName,
        @"CustomTextPlaceHolderKey.audio" : kLCQAudioStringName,
        @"CustomTextPlaceHolderKey.image" : kLCQImageStringName,
        @"CustomTextPlaceHolderKey.screenRecording" : kLCQScreenRecordingStringName,
        @"CustomTextPlaceHolderKey.messagesNotificationAndOthers" : kLCQMessagesNotificationTitleMultipleMessagesStringName,
        @"CustomTextPlaceHolderKey.insufficientContentTitle" : kLCQInsufficientContentTitleStringName,
        @"CustomTextPlaceHolderKey.insufficientContentMessage" : kLCQInsufficientContentMessageStringName,
    };
}
+ (ArgsDictionary *) userConsentActionTypes {
    return @{
        @"UserConsentActionType.dropAutoCapturedMedia": @(LCQConsentActionDropAutoCapturedMedia),
        @"UserConsentActionType.dropLogs": @(LCQConsentActionDropLogs),
        @"UserConsentActionType.noChat": @(LCQConsentActionNoChat)
    };
}

+ (ArgsDictionary *) userStepsGesture {
    return @{
        @"GestureType.swipe" : @(LCQUIEventTypeSwipe),
        @"GestureType.scroll" : @(LCQUIEventTypeScroll),
        @"GestureType.tap" : @(LCQUIEventTypeTap),
        @"GestureType.pinch" : @(LCQUIEventTypePinch),
        @"GestureType.longPress" : @(LCQUIEventTypeLongPress),
        @"GestureType.doubleTap" : @(LCQUIEventTypeDoubleTap),
    };
}
@end
