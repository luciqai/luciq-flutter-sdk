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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQSessionReplay.enabled = [isEnabled boolValue];
}

- (void)setLuciqLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setLuciqLogsEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQSessionReplay.LCQLogsEnabled = [isEnabled boolValue];
}

- (void)setNetworkLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setNetworkLogsEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQSessionReplay.networkLogsEnabled = [isEnabled boolValue];
}

- (void)setUserStepsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setUserStepsEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQSessionReplay.userStepsEnabled = [isEnabled boolValue];
}

- (void)getSessionReplayLinkWithCompletion:(void (^)(NSString *, FlutterError *))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.getSessionReplayLink]"];
    NSString *link = LCQSessionReplay.sessionReplayLink;
    completion(link, nil);
}

- (void)setScreenshotCapturingModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setScreenshotCapturingMode] mode=%@", mode];
    LCQScreenshotCapturingMode nativeMode = (ArgsRegistry.screenshotCapturingModes[mode]).integerValue;
    LCQSessionReplay.screenshotCapturingMode = nativeMode;
}

- (void)setScreenshotCaptureIntervalIntervalMs:(nonnull NSNumber *)intervalMs error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setScreenshotCaptureInterval] intervalMs=%@", intervalMs];
    if ([intervalMs integerValue] < 500) {
        *error = [FlutterError errorWithCode:@"INVALID_CAPTURE_INTERVAL"
                                     message:@"intervalMs must be >= 500 on iOS"
                                     details:intervalMs];
        return;
    }
    LCQSessionReplay.screenshotCaptureInterval = [intervalMs integerValue];
}

- (void)setScreenshotQualityModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags sessionReplay] format:@"[SR.setScreenshotQualityMode] mode=%@", mode];
    LCQScreenshotQualityMode nativeMode = (ArgsRegistry.screenshotQualityModes[mode]).integerValue;
    LCQSessionReplay.screenshotQualityMode = nativeMode;
}

@end
