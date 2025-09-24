#import <XCTest/XCTest.h>
#import <ArgsRegistry.h>

@interface ArgsRegistryTests : XCTestCase
@end

@implementation ArgsRegistryTests

- (void)testSdkLogLevels {
    NSArray *values = @[
        @(LCQSDKDebugLogsLevelVerbose),
        @(LCQSDKDebugLogsLevelDebug),
        @(LCQSDKDebugLogsLevelError),
        @(LCQSDKDebugLogsLevelNone)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.sdkLogLevels allValues] containsObject:value]);
    }
}

- (void)testInvocationEvents {
    NSArray *values = @[
        @(LCQInvocationEventNone),
        @(LCQInvocationEventShake),
        @(LCQInvocationEventScreenshot),
        @(LCQInvocationEventTwoFingersSwipeLeft),
        @(LCQInvocationEventFloatingButton),
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.invocationEvents allValues] containsObject:value]);
    }
}

- (void)testInvocationOptions {
    NSArray *values = @[
        @(LCQBugReportingOptionEmailFieldHidden),
        @(LCQBugReportingOptionEmailFieldOptional),
        @(LCQBugReportingOptionCommentFieldRequired),
        @(LCQBugReportingOptionDisablePostSendingDialog)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.invocationOptions allValues] containsObject:value]);
    }
}

- (void)testColorThemes {
    NSArray *values = @[
        @(LCQColorThemeLight),
        @(LCQColorThemeDark)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.colorThemes allValues] containsObject:value]);
    }
}

- (void)testFloatingButtonEdges {
    NSArray *values = @[
        @(CGRectMinXEdge),
        @(CGRectMaxXEdge)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.floatingButtonEdges allValues] containsObject:value]);
    }
}

- (void)testRecordButtonPositions {
    NSArray *values = @[
        @(LCQPositionTopLeft),
        @(LCQPositionTopRight),
        @(LCQPositionBottomLeft),
        @(LCQPositionBottomRight)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.recordButtonPositions allValues] containsObject:value]);
    }
}

- (void)testWelcomeMessageStates {
    NSArray *values = @[
        @(LCQWelcomeMessageModeLive),
        @(LCQWelcomeMessageModeBeta),
        @(LCQWelcomeMessageModeDisabled)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.welcomeMessageStates allValues] containsObject:value]);
    }
}

- (void)testReportTypes {
    NSArray *values = @[
        @(LCQBugReportingReportTypeBug),
        @(LCQBugReportingReportTypeFeedback),
        @(LCQBugReportingReportTypeQuestion)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.reportTypes allValues] containsObject:value]);
    }
}

- (void)testDismissTypes {
    NSArray *values = @[
        @(LCQDismissTypeSubmit),
        @(LCQDismissTypeCancel),
        @(LCQDismissTypeAddAttachment)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.dismissTypes allValues] containsObject:value]);
    }
}

- (void)testActionTypes {
    NSArray *values = @[
        @(LCQActionAllActions),
        @(LCQActionReportBug),
        @(LCQActionRequestNewFeature),
        @(LCQActionAddCommentToFeature),
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.actionTypes allValues] containsObject:value]);
    }
}

- (void)testExtendedBugReportStates {
    NSArray *values = @[
        @(LCQExtendedBugReportModeEnabledWithRequiredFields),
        @(LCQExtendedBugReportModeEnabledWithOptionalFields),
        @(LCQExtendedBugReportModeDisabled)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.extendedBugReportStates allValues] containsObject:value]);
    }
}

- (void)testReproModes {
    NSArray *values = @[
        @(LCQUserStepsModeEnable),
        @(LCQUserStepsModeDisable),
        @(LCQUserStepsModeEnabledWithNoScreenshots)
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.reproModes allValues] containsObject:value]);
    }
}

- (void)testLocales {
    NSArray *values = @[
        @(LCQLocaleArabic),
        @(LCQLocaleAzerbaijani),
        @(LCQLocaleChineseSimplified),
        @(LCQLocaleChineseTraditional),
        @(LCQLocaleCzech),
        @(LCQLocaleDanish),
        @(LCQLocaleDutch),
        @(LCQLocaleEnglish),
        @(LCQLocaleFinnish),
        @(LCQLocaleFrench),
        @(LCQLocaleGerman),
        @(LCQLocaleHungarian),
        @(LCQLocaleItalian),
        @(LCQLocaleJapanese),
        @(LCQLocaleKorean),
        @(LCQLocaleNorwegian),
        @(LCQLocalePolish),
        @(LCQLocalePortugueseBrazil),
        @(LCQLocalePortuguese),
        @(LCQLocaleRomanian),
        @(LCQLocaleRussian),
        @(LCQLocaleSlovak),
        @(LCQLocaleSpanish),
        @(LCQLocaleSwedish),
        @(LCQLocaleTurkish),
    ];

    for (NSNumber *value in values) {
        XCTAssertTrue([[ArgsRegistry.locales allValues] containsObject:value]);
    }
}

- (void)testPlaceholders {
    NSArray *values = @[
        kLCQShakeStartAlertTextStringName,
        kLCQEdgeSwipeStartAlertTextStringName,
        kLCQInvalidEmailMessageStringName,
        kLCQInvocationTitleStringName,
        kLCQAskAQuestionStringName,
        kLCQReportBugStringName,
        kLCQReportFeedbackStringName,
        kLCQEmailFieldPlaceholderStringName,
        kLCQCommentFieldPlaceholderForBugReportStringName,
        kLCQCommentFieldPlaceholderForFeedbackStringName,
        kLCQCommentFieldPlaceholderForQuestionStringName,
        kLCQAddVoiceMessageStringName,
        kLCQAddImageFromGalleryStringName,
        kLCQAddExtraScreenshotStringName,
        kLCQChatsTitleStringName,
        kLCQAudioRecordingPermissionDeniedTitleStringName,
        kLCQChatReplyFieldPlaceholderStringName,
        kLCQRecordingMessageToHoldTextStringName,
        kLCQRecordingMessageToReleaseTextStringName,
        kLCQThankYouAlertMessageStringName,
        kLCQThankYouAlertTitleStringName,
        kLCQAddScreenRecordingMessageStringName,
        kLCQVideoPressRecordTitle,
        kLCQBetaWelcomeMessageWelcomeStepTitle,
        kLCQBetaWelcomeMessageWelcomeStepContent,
        kLCQBetaWelcomeMessageHowToReportStepTitle,
        kLCQBetaWelcomeMessageHowToReportStepContent,
        kLCQBetaWelcomeMessageFinishStepTitle,
        kLCQBetaWelcomeMessageFinishStepContent,
        kLCQLiveWelcomeMessageTitle,
        kLCQLiveWelcomeMessageContent,

        kLCQTeamStringName,
        kLCQReplyButtonTitleStringName,
        kLCQDismissButtonTitleStringName,

        kLCQStoreRatingThankYouTitleText,
        kLCQStoreRatingThankYouDescriptionText,

        kLCQReportBugDescriptionStringName,
        kLCQReportFeedbackDescriptionStringName,
        kLCQReportQuestionDescriptionStringName,
        kLCQRequestFeatureDescriptionStringName,

        kLCQDiscardAlertTitle,
        kLCQDiscardAlertMessage,
        kLCQDiscardAlertCancel,
        kLCQDiscardAlertAction,
        kLCQAddAttachmentButtonTitleStringName,

        kLCQReproStepsDisclaimerBody,
        kLCQReproStepsDisclaimerLink,
        kLCQProgressViewTitle,
        kLCQReproStepsListTitle,
        kLCQReproStepsListHeader,
        kLCQReproStepsListEmptyStateLabel,
        kLCQReproStepsListItemName,
    ];

    for (NSString *value in values) {
        XCTAssertTrue([[ArgsRegistry.placeholders allValues] containsObject:value]);
    }
}

@end
