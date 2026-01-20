#import <LuciqSDK/LuciqSDK.h>
#import <LuciqSDK/LCQSessionReplay.h>
#import "SessionReplayApi.h"

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

- (void)setScreenshotCapturingModeMode:(ScreenshotCapturingMode)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // Map Pigeon enum to native SDK enum (same order: navigation=0, interaction=1, frequency=2)
    LCQScreenshotCapturingMode nativeMode;
    switch (mode) {
        case ScreenshotCapturingModeNavigation:
            nativeMode = LCQScreenshotCapturingModeNavigation;
            break;
        case ScreenshotCapturingModeInteraction:
            nativeMode = LCQScreenshotCapturingModeInteraction;
            break;
        case ScreenshotCapturingModeFrequency:
            nativeMode = LCQScreenshotCapturingModeFrequency;
            break;
    }
    LCQSessionReplay.screenshotCapturingMode = nativeMode;
}

- (void)setScreenshotCaptureIntervalIntervalMs:(nonnull NSNumber *)intervalMs error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQSessionReplay.screenshotCaptureInterval = [intervalMs integerValue];
}

- (void)setScreenshotQualityModeMode:(ScreenshotQualityMode)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // Map Pigeon enum to native SDK enum (same order: normal=0, high=1, greyScale=2)
    LCQScreenshotQualityMode nativeMode;
    switch (mode) {
        case ScreenshotQualityModeNormal:
            nativeMode = LCQScreenshotQualityModeNormal;
            break;
        case ScreenshotQualityModeHigh:
            nativeMode = LCQScreenshotQualityModeHigh;
            break;
        case ScreenshotQualityModeGreyScale:
            nativeMode = LCQScreenshotQualityModeGreyScale;
            break;
    }
    LCQSessionReplay.screenshotQualityMode = nativeMode;
}

@end
