#import <Flutter/Flutter.h>
#import <LuciqSDK/LuciqSDK.h>
#import <LuciqSDK/LCQSessionReplay.h>
#import <LuciqSDK/LCQSessionMetadata.h>
#import "SessionReplayApi.h"
#import "ArgsRegistry.h"

extern void InitSessionReplayApi(id<FlutterBinaryMessenger> messenger) {
    SessionReplayFlutterApi *flutterApi = [[SessionReplayFlutterApi alloc] initWithBinaryMessenger:messenger];
    SessionReplayApi *api = [[SessionReplayApi alloc] initWithFlutterApi:flutterApi];
    SessionReplayHostApiSetup(messenger, api);
}

@implementation SessionReplayApi

- (instancetype)initWithFlutterApi:(SessionReplayFlutterApi *)api {
    self = [super init];
    self.flutterApi = api;
    self.pendingSessionEvaluationCompletions = [NSMutableArray array];
    return self;
}

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

- (NSArray<NSDictionary *> *)serializeNetworkLogs:(NSArray<LCQSessionMetadataNetworkLogs *> *)logs {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    for (LCQSessionMetadataNetworkLogs *log in logs) {
        [result addObject:@{
            @"url": log.url ?: [NSNull null],
            @"duration": @(log.duration),
            @"statusCode": @(log.statusCode),
        }];
    }
    return result;
}

- (NSDictionary *)serializeSessionMetadata:(LCQSessionMetadata *)metadata {
    NSString *launchTypeString;
    switch (metadata.launchType) {
        case LaunchTypeCold:
            launchTypeString = @"Cold";
            break;
        case LaunchTypeHot:
            launchTypeString = @"Hot";
            break;
        default:
            launchTypeString = @"Unknown";
            break;
    }
    return @{
        @"appVersion": metadata.appVersion ?: [NSNull null],
        @"os": metadata.os ?: [NSNull null],
        @"device": metadata.device ?: [NSNull null],
        @"sessionDurationInSeconds": @(metadata.sessionDuration),
        @"hasLinkToAppReview": @(metadata.hasLinkToAppReview),
        @"launchType": launchTypeString,
        @"launchDuration": @(metadata.launchDuration),
        @"bugsCount": @(metadata.bugsCount),
        @"fatalCrashCount": @(metadata.fatalCrashCount),
        @"oomCrashCount": @(metadata.oomCrashCount),
        @"networkLogs": [self serializeNetworkLogs:metadata.networkLogs],
    };
}

- (void)bindOnSyncCallbackWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    __weak __typeof(self) weakSelf = self;
    LCQSessionReplay.syncCallbackWithHandler = ^(LCQSessionMetadata *metadataObject, SessionEvaluationCompletion completion) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            completion(YES);
            return;
        }
        @synchronized (strongSelf.pendingSessionEvaluationCompletions) {
            [strongSelf.pendingSessionEvaluationCompletions addObject:[completion copy]];
        }
        NSDictionary *payload = [strongSelf serializeSessionMetadata:metadataObject];
        [strongSelf.flutterApi onShouldSyncSessionMetadata:payload
                                               completion:^(FlutterError * _Nullable _) {
                                               }];
    };
}

- (void)evaluateSyncResult:(NSNumber *)result error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    void (^completion)(BOOL) = nil;
    @synchronized (self.pendingSessionEvaluationCompletions) {
        if (self.pendingSessionEvaluationCompletions.count > 0) {
            completion = self.pendingSessionEvaluationCompletions.firstObject;
            [self.pendingSessionEvaluationCompletions removeObjectAtIndex:0];
        }
    }
    if (completion) {
        completion([result boolValue]);
    }
}

@end
