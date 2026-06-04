#import <Flutter/Flutter.h>
#import <LuciqSDK/LuciqSDK.h>
#import <LuciqSDK/LCQSessionReplay.h>
#import "SessionReplayApi.h"
#import "ArgsRegistry.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitSessionReplayApi(id<FlutterBinaryMessenger> messenger) {
    SessionReplayApi *api = [[SessionReplayApi alloc] init];
    SessionReplayHostApiSetup(messenger, api);
}

@implementation SessionReplayApi

- (void)setEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    LCQSessionReplay.enabled = [isEnabled boolValue];
}

- (void)setLuciqLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setLuciqLogsEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    LCQSessionReplay.LCQLogsEnabled = [isEnabled boolValue];
}

- (void)setNetworkLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setNetworkLogsEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    LCQSessionReplay.networkLogsEnabled = [isEnabled boolValue];
}

- (void)setUserStepsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setUserStepsEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    LCQSessionReplay.userStepsEnabled = [isEnabled boolValue];
}

- (void)getSessionReplayLinkCallId:(NSString *)callId completion:(void (^)(NSString *, FlutterError *))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.getSessionReplayLink] #%@ phase=enter", callId];
    NSString *link = LCQSessionReplay.sessionReplayLink;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.getSessionReplayLink] #%@ phase=exit resultLength=%lu resultPresent=%@",
        callId,
        (unsigned long)link.length,
        (link.length > 0 ? @"true" : @"false")];
    completion(link, nil);
}

- (void)setScreenshotCapturingModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setScreenshotCapturingMode] phase=enter mode=%@", mode];
    LCQScreenshotCapturingMode nativeMode = (ArgsRegistry.screenshotCapturingModes[mode]).integerValue;
    LCQSessionReplay.screenshotCapturingMode = nativeMode;
}

- (void)setScreenshotCaptureIntervalIntervalMs:(nonnull NSNumber *)intervalMs error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setScreenshotCaptureInterval] phase=enter intervalMs=%@", intervalMs];
    if ([intervalMs integerValue] < 500) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags sessionReplay]
                       format:@"[SR.setScreenshotCaptureInterval] phase=error errorType=InvalidArgument errorMessage=intervalMs<500 intervalMs=%@", intervalMs];
        *error = [FlutterError errorWithCode:@"INVALID_CAPTURE_INTERVAL"
                                     message:@"intervalMs must be >= 500 on iOS"
                                     details:intervalMs];
        return;
    }
    LCQSessionReplay.screenshotCaptureInterval = [intervalMs integerValue];
}

- (void)setScreenshotQualityModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay]
                   format:@"[SR.setScreenshotQualityMode] phase=enter mode=%@", mode];
    LCQScreenshotQualityMode nativeMode = (ArgsRegistry.screenshotQualityModes[mode]).integerValue;
    LCQSessionReplay.screenshotQualityMode = nativeMode;
}

@end
