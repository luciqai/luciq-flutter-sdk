#import <Flutter/Flutter.h>
#import <LuciqSDK/LuciqSDK.h>
#import <LuciqSDK/LCQSessionReplay.h>
#import "SessionReplayApi.h"
#import "ArgsRegistry.h"
#import "../Util/LCQRunCatching.h"

extern void InitSessionReplayApi(id<FlutterBinaryMessenger> messenger) {
    SessionReplayApi *api = [[SessionReplayApi alloc] init];
    SessionReplayHostApiSetup(messenger, api);
}

@implementation SessionReplayApi

- (void)setEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setEnabled", ^{
        LCQSessionReplay.enabled = [isEnabled boolValue];
    });
}

- (void)setLuciqLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setLuciqLogsEnabled", ^{
        LCQSessionReplay.LCQLogsEnabled = [isEnabled boolValue];
    });
}

- (void)setNetworkLogsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setNetworkLogsEnabled", ^{
        LCQSessionReplay.networkLogsEnabled = [isEnabled boolValue];
    });
}

- (void)setUserStepsEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setUserStepsEnabled", ^{
        LCQSessionReplay.userStepsEnabled = [isEnabled boolValue];
    });
}

- (void)getSessionReplayLinkWithCompletion:(void (^)(NSString *, FlutterError *))completion {
    LCQRunCatching(@"SessionReplayApi.getSessionReplayLink", ^{
        NSString *link = LCQSessionReplay.sessionReplayLink;
        completion(link, nil);
    });
}

- (void)setScreenshotCapturingModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setScreenshotCapturingMode", ^{
        LCQScreenshotCapturingMode nativeMode = (ArgsRegistry.screenshotCapturingModes[mode]).integerValue;
        LCQSessionReplay.screenshotCapturingMode = nativeMode;
    });
}

- (void)setScreenshotCaptureIntervalIntervalMs:(nonnull NSNumber *)intervalMs error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setScreenshotCaptureInterval", ^{
        if ([intervalMs integerValue] < 500) {
            NSLog(@"[Luciq] SessionReplayApi.setScreenshotCaptureInterval: intervalMs must be >= 500 on iOS");
            return;
        }
        LCQSessionReplay.screenshotCaptureInterval = [intervalMs integerValue];
    });
}

- (void)setScreenshotQualityModeMode:(NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"SessionReplayApi.setScreenshotQualityMode", ^{
        LCQScreenshotQualityMode nativeMode = (ArgsRegistry.screenshotQualityModes[mode]).integerValue;
        LCQSessionReplay.screenshotQualityMode = nativeMode;
    });
}

@end
