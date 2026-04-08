#import <Flutter/Flutter.h>
#import <LuciqSDK/LuciqSDK.h>
#import <LuciqSDK/LCQSessionReplay.h>
#import "SessionReplayApi.h"
#import "ArgsRegistry.h"

extern void InitSessionReplayApi(id<FlutterBinaryMessenger> messenger) {
    SessionReplayApi *api = [[SessionReplayApi alloc] init];
    SessionReplayHostApiSetup(messenger, api);
}

@implementation SessionReplayApi

- (void)setEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQSessionReplay.enabled = [isEnabled boolValue];
}

- (void)setLuciqLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQSessionReplay.LCQLogsEnabled = [isEnabled boolValue];
}

- (void)setNetworkLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQSessionReplay.networkLogsEnabled = [isEnabled boolValue];
}

- (void)setUserStepsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQSessionReplay.userStepsEnabled = [isEnabled boolValue];
}

- (void)getSessionReplayLinkWithCompletion:(void (^)(NSString *, FlutterError *))completion {
    NSString *link = LCQSessionReplay.sessionReplayLink;
    completion(link, nil);
}

- (void)setScreenshotCapturingModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQScreenshotCapturingMode nativeMode = (ArgsRegistry.screenshotCapturingModes[mode]).integerValue;
    LCQSessionReplay.screenshotCapturingMode = nativeMode;
}

- (void)setScreenshotCaptureIntervalIntervalMs:(nonnull NSNumber *)intervalMs error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if ([intervalMs integerValue] < 500) {
        *error = [FlutterError errorWithCode:@"INVALID_CAPTURE_INTERVAL"
                                     message:@"intervalMs must be >= 500 on iOS"
                                     details:intervalMs];
        return;
    }
    LCQSessionReplay.screenshotCaptureInterval = [intervalMs integerValue];
}

- (void)setScreenshotQualityModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQScreenshotQualityMode nativeMode = (ArgsRegistry.screenshotQualityModes[mode]).integerValue;
    LCQSessionReplay.screenshotQualityMode = nativeMode;
}

@end
