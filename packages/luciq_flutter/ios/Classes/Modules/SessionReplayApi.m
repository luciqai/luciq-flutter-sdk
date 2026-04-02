#import <Flutter/Flutter.h>
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
        default:
            *error = [FlutterError errorWithCode:@"INVALID_CAPTURING_MODE"
                                         message:[NSString stringWithFormat:@"Unknown ScreenshotCapturingMode: %lu", (unsigned long)mode]
                                         details:nil];
            return;
    }
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

- (void)setScreenshotQualityModeMode:(ScreenshotQualityMode)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
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
        default:
            *error = [FlutterError errorWithCode:@"INVALID_QUALITY_MODE"
                                         message:[NSString stringWithFormat:@"Unknown ScreenshotQualityMode: %lu", (unsigned long)mode]
                                         details:nil];
            return;
    }
    LCQSessionReplay.screenshotQualityMode = nativeMode;
}

@end
