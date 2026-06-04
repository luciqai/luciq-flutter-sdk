#import <Flutter/Flutter.h>
#import "LuciqSDK/LuciqSDK.h"
#import "BugReportingApi.h"
#import "ArgsRegistry.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitBugReportingApi(id<FlutterBinaryMessenger> messenger) {
    BugReportingFlutterApi *flutterApi = [[BugReportingFlutterApi alloc] initWithBinaryMessenger:messenger];
    BugReportingApi *api = [[BugReportingApi alloc] initWithFlutterApi:flutterApi];
    BugReportingHostApiSetup(messenger, api);
}

@implementation BugReportingApi

- (instancetype)initWithFlutterApi:(BugReportingFlutterApi *)api {
    self = [super init];
    self.flutterApi = api;
    return self;
}

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    LCQBugReporting.enabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setEnabled] phase=exit"];
}

- (void)showReportType:(NSString *)reportType invocationOptions:(NSArray<NSString *> *)invocationOptions error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.show] phase=enter reportType=%@ optionsCount=%lu", reportType, (unsigned long)invocationOptions.count];
    NSNumber *mappedType = ArgsRegistry.reportTypes[reportType];
    if (mappedType == nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.show] phase=error errorType=UnknownEnum reportType=%@", reportType];
    }
    LCQBugReportingReportType resolvedType = mappedType.integerValue;
    LCQBugReportingOption resolvedOptions = 0;

    for (NSString *option in invocationOptions) {
        NSNumber *mappedOption = ArgsRegistry.invocationOptions[option];
        if (mappedOption == nil) {
            [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.show] phase=error errorType=UnknownEnum invocationOption=%@", option];
            continue;
        }
        resolvedOptions |= mappedOption.integerValue;
    }

    [LCQBugReporting showWithReportType:resolvedType options:resolvedOptions];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.show] phase=exit"];
}

- (void)setInvocationEventsEvents:(NSArray<NSString *> *)events error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationEvents] phase=enter count=%lu", (unsigned long)events.count];
    LCQInvocationEvent resolvedEvents = 0;

    for (NSString *event in events) {
        NSNumber *mapped = ArgsRegistry.invocationEvents[event];
        if (mapped == nil) {
            [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationEvents] phase=error errorType=UnknownEnum invocationEvent=%@", event];
            continue;
        }
        resolvedEvents |= mapped.integerValue;
    }

    LCQBugReporting.invocationEvents = resolvedEvents;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationEvents] phase=exit"];
}

- (void)setReportTypesTypes:(NSArray<NSString *> *)types error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setReportTypes] phase=enter count=%lu", (unsigned long)types.count];
    LCQBugReportingReportType resolvedTypes = 0;

    for (NSString *type in types) {
        NSNumber *mapped = ArgsRegistry.reportTypes[type];
        if (mapped == nil) {
            [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setReportTypes] phase=error errorType=UnknownEnum reportType=%@", type];
            continue;
        }
        resolvedTypes |= mapped.integerValue;
    }

    [LCQBugReporting setPromptOptionsEnabledReportTypes:resolvedTypes];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setReportTypes] phase=exit"];
}

- (void)setExtendedBugReportModeMode:(NSString *)mode error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setExtendedBugReportMode] phase=enter mode=%@", mode];
    NSNumber *mapped = ArgsRegistry.extendedBugReportStates[mode];
    if (mapped == nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setExtendedBugReportMode] phase=error errorType=UnknownEnum mode=%@", mode];
    }
    LCQExtendedBugReportMode resolvedMode = mapped.integerValue;
    LCQBugReporting.extendedBugReportMode = resolvedMode;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setExtendedBugReportMode] phase=exit resolvedMode=%ld", (long)resolvedMode];
}

- (void)setInvocationOptionsOptions:(NSArray<NSString *> *)options error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationOptions] phase=enter count=%lu", (unsigned long)options.count];
    LCQBugReportingOption resolvedOptions = 0;

    for (NSString *option in options) {
        NSNumber *mapped = ArgsRegistry.invocationOptions[option];
        if (mapped == nil) {
            [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationOptions] phase=error errorType=UnknownEnum invocationOption=%@", option];
            continue;
        }
        resolvedOptions |= mapped.integerValue;
    }

    LCQBugReporting.bugReportingOptions = resolvedOptions;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationOptions] phase=exit"];
}

- (void)setFloatingButtonEdgeEdge:(NSString *)edge offset:(NSNumber *)offset error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setFloatingButtonEdge] phase=enter edge=%@ offset=%@", edge, offset];
    NSNumber *mapped = ArgsRegistry.floatingButtonEdges[edge];
    if (mapped == nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setFloatingButtonEdge] phase=error errorType=UnknownEnum edge=%@", edge];
    }
    CGRectEdge resolvedEdge = mapped.doubleValue;
    LCQBugReporting.floatingButtonEdge = resolvedEdge;
    LCQBugReporting.floatingButtonTopOffset = [offset doubleValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setFloatingButtonEdge] phase=exit"];
}

- (void)setVideoRecordingFloatingButtonPositionPosition:(NSString *)position error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setVideoRecordingFloatingButtonPosition] phase=enter position=%@", position];
    NSNumber *mapped = ArgsRegistry.recordButtonPositions[position];
    if (mapped == nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setVideoRecordingFloatingButtonPosition] phase=error errorType=UnknownEnum position=%@", position];
    }
    LCQPosition resolvedPosition = mapped.integerValue;
    LCQBugReporting.videoRecordingFloatingButtonPosition = resolvedPosition;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setVideoRecordingFloatingButtonPosition] phase=exit"];
}

- (void)setShakingThresholdForiPhoneThreshold:(NSNumber *)threshold error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForiPhone] phase=enter threshold=%@", threshold];
    LCQBugReporting.shakingThresholdForiPhone = [threshold doubleValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForiPhone] phase=exit"];
}

- (void)setShakingThresholdForiPadThreshold:(NSNumber *)threshold error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForiPad] phase=enter threshold=%@", threshold];
    LCQBugReporting.shakingThresholdForiPad = [threshold doubleValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForiPad] phase=exit"];
}

- (void)setShakingThresholdForAndroidThreshold:(NSNumber *)threshold error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForAndroid] phase=enter iOS=noop=true threshold=%@", threshold];
    // Android Only
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForAndroid] phase=exit iOS=noop=true"];
}

- (void)setEnabledAttachmentTypesScreenshot:(NSNumber *)screenshot extraScreenshot:(NSNumber *)extraScreenshot galleryImage:(NSNumber *)galleryImage screenRecording:(NSNumber *)screenRecording error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setEnabledAttachmentTypes] phase=enter screenshot=%@ extraScreenshot=%@ galleryImage=%@ screenRecording=%@", ([screenshot boolValue] ? @"true" : @"false"), ([extraScreenshot boolValue] ? @"true" : @"false"), ([galleryImage boolValue] ? @"true" : @"false"), ([screenRecording boolValue] ? @"true" : @"false")];

    LCQAttachmentType resolvedTypes = 0;

    if ([screenshot boolValue]) {
        resolvedTypes |= LCQAttachmentTypeScreenShot;
    }
    if ([extraScreenshot boolValue]) {
        resolvedTypes |= LCQAttachmentTypeExtraScreenShot;
    }
    if ([galleryImage boolValue]) {
        resolvedTypes |= LCQAttachmentTypeGalleryImage;
    }
    if ([screenRecording boolValue]) {
        resolvedTypes |= LCQAttachmentTypeScreenRecording;
    }

    LCQBugReporting.enabledAttachmentTypes = resolvedTypes;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setEnabledAttachmentTypes] phase=exit"];
}

- (void)bindOnInvokeCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.bindOnInvokeCallback] phase=enter"];
    LCQBugReporting.willInvokeHandler = ^{
      NSString *callId = [LuciqFlutterLogger nextCallId];
      [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting]
                     format:@"[BR.onSdkInvoke] #%@ phase=fire", callId];
      [self->_flutterApi onSdkInvokeCallId:callId completion:^(FlutterError *_Nullable _){
      }];
    };
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.bindOnInvokeCallback] phase=exit"];
}

- (void)bindOnDismissCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.bindOnDismissCallback] phase=enter"];
    LCQBugReporting.didDismissHandler = ^(LCQDismissType dismissType, LCQReportCategory reportType) {
      // Parse dismiss type enum
      NSString *dismissTypeString;
      if (dismissType == LCQDismissTypeCancel) {
          dismissTypeString = @"CANCEL";
      } else if (dismissType == LCQDismissTypeSubmit) {
          dismissTypeString = @"SUBMIT";
      } else if (dismissType == LCQDismissTypeAddAttachment) {
          dismissTypeString = @"ADD_ATTACHMENT";
      }

      // Parse report type enum
      NSString *reportTypeString;
        if (reportType == LCQReportCategoryBug) {
          reportTypeString = @"BUG";
      } else if (reportType == LCQReportCategoryFeedback) {
          reportTypeString = @"FEEDBACK";
      } else {
          reportTypeString = @"OTHER";
      }

      NSString *callId = [LuciqFlutterLogger nextCallId];
      [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting]
                     format:@"[BR.onSdkDismiss] #%@ phase=fire dismissType=%@ reportType=%@",
                     callId, dismissTypeString, reportTypeString];
      [self->_flutterApi onSdkDismissCallId:callId
                                dismissType:dismissTypeString
                                 reportType:reportTypeString
                                 completion:^(FlutterError *_Nullable _){
                                 }];
    };
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.bindOnDismissCallback] phase=exit"];
}

- (void)setDisclaimerTextText:(NSString *)text error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setDisclaimerText] phase=enter length=%lu", (unsigned long)text.length];
    [LCQBugReporting setDisclaimerText:text];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setDisclaimerText] phase=exit"];
}

- (void)setCommentMinimumCharacterCountLimit:(NSNumber *)limit reportTypes:(nullable NSArray<NSString *> *)reportTypes error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setCommentMinimumCharacterCount] phase=enter limit=%@ reportTypesCount=%lu", limit, (unsigned long)reportTypes.count];
    LCQBugReportingType resolvedTypes = 0;
    if (![reportTypes count]) {
        resolvedTypes = (ArgsRegistry.reportTypes[@"ReportType.bug"]).integerValue | (ArgsRegistry.reportTypes[@"ReportType.feedback"]).integerValue | (ArgsRegistry.reportTypes[@"ReportType.question"]).integerValue;
    }
    else {
        for (NSString *reportType in reportTypes) {
            NSNumber *mapped = ArgsRegistry.reportTypes[reportType];
            if (mapped == nil) {
                [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setCommentMinimumCharacterCount] phase=error errorType=UnknownEnum reportType=%@", reportType];
                continue;
            }
            resolvedTypes |= mapped.integerValue;
        }
    }

    [LCQBugReporting setCommentMinimumCharacterCount:[limit integerValue] forBugReportType:resolvedTypes];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setCommentMinimumCharacterCount] phase=exit"];
}

- (void)addUserConsentsKey:(NSString *)key
                 description:(NSString *)description
                   mandatory:(NSNumber *)mandatory
                     checked:(NSNumber *)checked
                  actionType:(nullable NSString *)actionType
                       error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.addUserConsents] phase=enter keyLength=%lu descLength=%lu mandatory=%@ checked=%@ actionTypePresent=%@", (unsigned long)key.length, (unsigned long)description.length, ([mandatory boolValue] ? @"true" : @"false"), ([checked boolValue] ? @"true" : @"false"), (actionType != nil ? @"true" : @"false")];

    NSNumber *mappedActionNumber = ArgsRegistry.userConsentActionTypes[actionType];
    if (actionType != nil && mappedActionNumber == nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags bugReporting] format:@"[BR.addUserConsents] phase=error errorType=UnknownEnum actionType=%@", actionType];
    }
    LCQConsentAction mappedActionType = mappedActionNumber.integerValue;

    [LCQBugReporting addUserConsentWithKey:key
                               description:description
                                 mandatory:[mandatory boolValue]
                                   checked:[checked boolValue]
                                actionType:mappedActionType];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.addUserConsents] phase=exit"];
}

- (void)setProactiveReportingConfigurationsEnabled:(nonnull NSNumber *)enabled gapBetweenModals:(nonnull NSNumber *)gapBetweenModals modalDelayAfterDetection:(nonnull NSNumber *)modalDelayAfterDetection error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setProactiveReportingConfigurations] phase=enter enabled=%@ gapBetweenModals=%@ modalDelayAfterDetection=%@", ([enabled boolValue] ? @"true" : @"false"), gapBetweenModals, modalDelayAfterDetection];
    LCQProactiveReportingConfigurations *configurations = [[LCQProactiveReportingConfigurations alloc] init];
    configurations.enabled = [enabled boolValue]; //Enable/disable
    configurations.gapBetweenModals = gapBetweenModals; // Time in seconds
    configurations.modalDelayAfterDetection = modalDelayAfterDetection; // Time in seconds
    [LCQBugReporting setProactiveReportingConfigurations:configurations];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setProactiveReportingConfigurations] phase=exit"];
}

@end
