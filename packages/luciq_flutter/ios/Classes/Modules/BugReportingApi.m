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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQBugReporting.enabled = [isEnabled boolValue];
}

- (void)showReportType:(NSString *)reportType invocationOptions:(NSArray<NSString *> *)invocationOptions error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.show] reportType=%@ optionsCount=%lu", reportType, (unsigned long)invocationOptions.count];
    LCQBugReportingReportType resolvedType = (ArgsRegistry.reportTypes[reportType]).integerValue;
    LCQBugReportingOption resolvedOptions = 0;

    for (NSString *option in invocationOptions) {
        resolvedOptions |= (ArgsRegistry.invocationOptions[option]).integerValue;
    }

    [LCQBugReporting showWithReportType:resolvedType options:resolvedOptions];
}

- (void)setInvocationEventsEvents:(NSArray<NSString *> *)events error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationEvents] count=%lu", (unsigned long)events.count];
    LCQInvocationEvent resolvedEvents = 0;

    for (NSString *event in events) {
        resolvedEvents |= (ArgsRegistry.invocationEvents[event]).integerValue;
    }

    LCQBugReporting.invocationEvents = resolvedEvents;
}

- (void)setReportTypesTypes:(NSArray<NSString *> *)types error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setReportTypes] count=%lu", (unsigned long)types.count];
    LCQBugReportingReportType resolvedTypes = 0;

    for (NSString *type in types) {
        resolvedTypes |= (ArgsRegistry.reportTypes[type]).integerValue;
    }

    [LCQBugReporting setPromptOptionsEnabledReportTypes:resolvedTypes];
}

- (void)setExtendedBugReportModeMode:(NSString *)mode error:(FlutterError *_Nullable *_Nonnull)error {
    LCQExtendedBugReportMode resolvedMode = (ArgsRegistry.extendedBugReportStates[mode]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setExtendedBugReportMode] mode=%ld", (long)resolvedMode];
    LCQBugReporting.extendedBugReportMode = resolvedMode;
}

- (void)setInvocationOptionsOptions:(NSArray<NSString *> *)options error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setInvocationOptions] count=%lu", (unsigned long)options.count];
    LCQBugReportingOption resolvedOptions = 0;

    for (NSString *option in options) {
        resolvedOptions |= (ArgsRegistry.invocationOptions[option]).integerValue;
    }

    LCQBugReporting.bugReportingOptions = resolvedOptions;
}

- (void)setFloatingButtonEdgeEdge:(NSString *)edge offset:(NSNumber *)offset error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setFloatingButtonEdge] edge=%@ offset=%@", edge, offset];
    CGRectEdge resolvedEdge = (ArgsRegistry.floatingButtonEdges[edge]).doubleValue;
    LCQBugReporting.floatingButtonEdge = resolvedEdge;
    LCQBugReporting.floatingButtonTopOffset = [offset doubleValue];
}

- (void)setVideoRecordingFloatingButtonPositionPosition:(NSString *)position error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setVideoRecordingFloatingButtonPosition] position=%@", position];
    LCQPosition resolvedPosition = (ArgsRegistry.recordButtonPositions[position]).integerValue;
    LCQBugReporting.videoRecordingFloatingButtonPosition = resolvedPosition;
}

- (void)setShakingThresholdForiPhoneThreshold:(NSNumber *)threshold error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForiPhone] threshold=%@", threshold];
    LCQBugReporting.shakingThresholdForiPhone = [threshold doubleValue];
}

- (void)setShakingThresholdForiPadThreshold:(NSNumber *)threshold error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForiPad] threshold=%@", threshold];
    LCQBugReporting.shakingThresholdForiPad = [threshold doubleValue];
}

- (void)setShakingThresholdForAndroidThreshold:(NSNumber *)threshold error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setShakingThresholdForAndroid] iOS noop"];
    // Android Only
}

- (void)setEnabledAttachmentTypesScreenshot:(NSNumber *)screenshot extraScreenshot:(NSNumber *)extraScreenshot galleryImage:(NSNumber *)galleryImage screenRecording:(NSNumber *)screenRecording error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setEnabledAttachmentTypes] screenshot=%@ extraScreenshot=%@ galleryImage=%@ screenRecording=%@", ([screenshot boolValue] ? @"YES" : @"NO"), ([extraScreenshot boolValue] ? @"YES" : @"NO"), ([galleryImage boolValue] ? @"YES" : @"NO"), ([screenRecording boolValue] ? @"YES" : @"NO")];

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
}

- (void)bindOnInvokeCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.bindOnInvokeCallback]"];
    LCQBugReporting.willInvokeHandler = ^{
      [self->_flutterApi onSdkInvokeWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

- (void)bindOnDismissCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.bindOnDismissCallback]"];
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

      [self->_flutterApi onSdkDismissDismissType:dismissTypeString
                                      reportType:reportTypeString
                                      completion:^(FlutterError *_Nullable _){
                                      }];
    };
}

- (void)setDisclaimerTextText:(NSString *)text error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setDisclaimerText] length=%lu", (unsigned long)text.length];
    [LCQBugReporting setDisclaimerText:text];
}

- (void)setCommentMinimumCharacterCountLimit:(NSNumber *)limit reportTypes:(nullable NSArray<NSString *> *)reportTypes error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setCommentMinimumCharacterCount] limit=%@ reportTypesCount=%lu", limit, (unsigned long)reportTypes.count];
    LCQBugReportingType resolvedTypes = 0;
    if (![reportTypes count]) {
        resolvedTypes = (ArgsRegistry.reportTypes[@"ReportType.bug"]).integerValue | (ArgsRegistry.reportTypes[@"ReportType.feedback"]).integerValue | (ArgsRegistry.reportTypes[@"ReportType.question"]).integerValue;
    }
    else {
        for (NSString *reportType in reportTypes) {
            resolvedTypes |= (ArgsRegistry.reportTypes[reportType]).integerValue;
        }
    }
    
    [LCQBugReporting setCommentMinimumCharacterCount:[limit integerValue] forBugReportType:resolvedTypes];
}

- (void)addUserConsentsKey:(NSString *)key
                 description:(NSString *)description
                   mandatory:(NSNumber *)mandatory
                     checked:(NSNumber *)checked
                  actionType:(nullable NSString *)actionType
                       error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.addUserConsents] keyLength=%lu descLength=%lu mandatory=%@ checked=%@ actionTypePresent=%@", (unsigned long)key.length, (unsigned long)description.length, ([mandatory boolValue] ? @"YES" : @"NO"), ([checked boolValue] ? @"YES" : @"NO"), (actionType != nil ? @"YES" : @"NO")];

    LCQConsentAction mappedActionType =  (ArgsRegistry.userConsentActionTypes[actionType]).integerValue;

    [LCQBugReporting addUserConsentWithKey:key
                               description:description
                                 mandatory:[mandatory boolValue]
                                   checked:[checked boolValue]
                                actionType:mappedActionType];
}

- (void)setProactiveReportingConfigurationsEnabled:(nonnull NSNumber *)enabled gapBetweenModals:(nonnull NSNumber *)gapBetweenModals modalDelayAfterDetection:(nonnull NSNumber *)modalDelayAfterDetection error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags bugReporting] format:@"[BR.setProactiveReportingConfigurations] enabled=%@ gapBetweenModals=%@ modalDelayAfterDetection=%@", ([enabled boolValue] ? @"YES" : @"NO"), gapBetweenModals, modalDelayAfterDetection];
    LCQProactiveReportingConfigurations *configurations = [[LCQProactiveReportingConfigurations alloc] init];
    configurations.enabled = [enabled boolValue]; //Enable/disable
    configurations.gapBetweenModals = gapBetweenModals; // Time in seconds
    configurations.modalDelayAfterDetection = modalDelayAfterDetection; // Time in seconds
    [LCQBugReporting setProactiveReportingConfigurations:configurations];
}

@end
