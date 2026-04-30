#import "LuciqSDK/LuciqSDK.h"
#import "ApmApi.h"
#import "ArgsRegistry.h"
#import "LCQAPM+PrivateAPIs.h"
#import "LCQTimeIntervalUnits.h"
#import "../Util/LCQRunCatching.h"

void InitApmApi(id<FlutterBinaryMessenger> messenger) {
    ApmApi *api = [[ApmApi alloc] init];
    ApmHostApiSetup(messenger, api);
}

@implementation ApmApi

NSMutableDictionary *traces;

- (instancetype)init {
    self = [super init];
    traces = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"ApmApi.setEnabled", ^{
        LCQAPM.enabled = [isEnabled boolValue];
    });
}

- (void)isEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.isEnabled", ^{
        BOOL isEnabled = LCQAPM.enabled;
        NSNumber *isEnabledNumber = @(isEnabled);
        completion(isEnabledNumber, nil);
    });
}

- (void)setScreenLoadingEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.setScreenLoadingEnabled", ^{
        [LCQAPM setScreenLoadingEnabled:[isEnabled boolValue]];
    });
}

- (void)isScreenLoadingEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.isScreenLoadingEnabled", ^{
        BOOL isScreenLoadingEnabled = LCQAPM.screenLoadingEnabled;
        completion(@(isScreenLoadingEnabled), nil);
    });
}

- (void)setColdAppLaunchEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"ApmApi.setColdAppLaunchEnabled", ^{
        LCQAPM.coldAppLaunchEnabled = [isEnabled boolValue];
    });
}

- (void)setAutoUITraceEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"ApmApi.setAutoUITraceEnabled", ^{
        LCQAPM.autoUITraceEnabled = [isEnabled boolValue];
    });
}

- (void)startFlowName:(nonnull NSString *)name error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.startFlow", ^{
        [LCQAPM startFlowWithName:name];
    });
}

- (void)setFlowAttributeName:(nonnull NSString *)name key:(nonnull NSString *)key value:(nullable NSString *)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.setFlowAttribute", ^{
        [LCQAPM setAttributeForFlowWithName:name key:key value:value];
    });
}

- (void)endFlowName:(nonnull NSString *)name error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.endFlow", ^{
        [LCQAPM endFlowWithName:name];
    });
}

- (void)startUITraceName:(NSString *)name error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"ApmApi.startUITrace", ^{
        [LCQAPM startUITraceWithName:name];
    });
}

- (void)endUITraceWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"ApmApi.endUITrace", ^{
        [LCQAPM endUITrace];
    });
}

- (void)endAppLaunchWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"ApmApi.endAppLaunch", ^{
        [LCQAPM endAppLaunch];
    });
}

- (void)networkLogAndroidData:(NSDictionary<NSString *, id> *)data error:(FlutterError *_Nullable *_Nonnull)error {
    // Android Only
}

- (void)startCpUiTraceScreenName:(nonnull NSString *)screenName microTimeStamp:(nonnull NSNumber *)microTimeStamp traceId:(nonnull NSNumber *)traceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.startCpUiTrace", ^{
        NSTimeInterval startTimeStampMUS = [microTimeStamp doubleValue];
        [LCQAPM startUITraceCPWithName:screenName startTimestampMUS:startTimeStampMUS];
    });
}

- (void)reportScreenLoadingCPStartTimeStampMicro:(nonnull NSNumber *)startTimeStampMicro durationMicro:(nonnull NSNumber *)durationMicro uiTraceId:(nonnull NSNumber *)uiTraceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.reportScreenLoadingCP", ^{
        NSTimeInterval startTimeStampMicroMUS = [startTimeStampMicro doubleValue];
        NSTimeInterval durationMUS = [durationMicro doubleValue];
        [LCQAPM reportScreenLoadingCPWithStartTimestampMUS:startTimeStampMicroMUS durationMUS:durationMUS];
    });
}

- (void)endScreenLoadingCPTimeStampMicro:(nonnull NSNumber *)timeStampMicro uiTraceId:(nonnull NSNumber *)uiTraceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.endScreenLoadingCP", ^{
        NSTimeInterval endScreenLoadingCPWithEndTimestampMUS = [timeStampMicro doubleValue];
        [LCQAPM endScreenLoadingCPWithEndTimestampMUS:endScreenLoadingCPWithEndTimestampMUS];
    });
}

- (void)isEndScreenLoadingEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.isEndScreenLoadingEnabled", ^{
        BOOL isEndScreenLoadingEnabled = LCQAPM.endScreenLoadingEnabled;
        completion(@(isEndScreenLoadingEnabled), nil);
    });
}

- (void)isScreenRenderEnabledWithCompletion:(void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.isScreenRenderEnabled", ^{
        BOOL isScreenRenderEnabled = LCQAPM.isScreenRenderingOperational;
        completion(@(isScreenRenderEnabled), nil);
    });
}

- (void)isCustomSpanEnabledWithCompletion:(void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.isCustomSpanEnabled", ^{
        BOOL isCustomSpanEnabled = LCQAPM.customSpansEnabled;
        completion(@(isCustomSpanEnabled), nil);
    });
}

- (void)setScreenRenderEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.setScreenRenderEnabled", ^{
        [LCQAPM setScreenRenderingEnabled:[isEnabled boolValue]];
    });
}

- (void)endScreenRenderForAutoUiTraceData:(nonnull NSDictionary<NSString *,id> *)data error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.endScreenRenderForAutoUiTrace", ^{
        NSArray<NSArray<NSNumber *> *> *rawFrames = data[@"frameData"];
        NSMutableArray<LCQFrameInfo *> *frameInfos = [[NSMutableArray alloc] init];
        if (rawFrames && [rawFrames isKindOfClass:[NSArray class]]) {
            for (NSArray<NSNumber *> *frameValues in rawFrames) {
                if ([frameValues count] == 2) {
                    LCQFrameInfo *frameInfo = [[LCQFrameInfo alloc] init];
                    frameInfo.startTimestampInMicroseconds = [frameValues[0] doubleValue];
                    frameInfo.durationInMicroseconds = [frameValues[1] doubleValue];
                    [frameInfos addObject:frameInfo];
                }
            }
        }
        [LCQAPM endAutoUITraceCPWithFrames:frameInfos];
    });
}

- (void)endScreenRenderForCustomUiTraceData:(nonnull NSDictionary<NSString *,id> *)data error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"ApmApi.endScreenRenderForCustomUiTrace", ^{
        NSArray<NSArray<NSNumber *> *> *rawFrames = data[@"frameData"];
        NSMutableArray<LCQFrameInfo *> *frameInfos = [[NSMutableArray alloc] init];
        if (rawFrames && [rawFrames isKindOfClass:[NSArray class]]) {
            for (NSArray<NSNumber *> *frameValues in rawFrames) {
                if ([frameValues count] == 2) {
                    LCQFrameInfo *frameInfo = [[LCQFrameInfo alloc] init];
                    frameInfo.startTimestampInMicroseconds = [frameValues[0] doubleValue];
                    frameInfo.durationInMicroseconds = [frameValues[1] doubleValue];
                    [frameInfos addObject:frameInfo];
                }
            }
        }
        [LCQAPM endCustomUITraceCPWithFrames:frameInfos];
    });
}

- (void)getDeviceRefreshRateAndToleranceWithCompletion:(nonnull void (^)(NSArray<NSNumber *> * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.getDeviceRefreshRateAndTolerance", ^{
        double tolerance = LCQAPM.screenRenderingThreshold;
        if (@available(iOS 10.3, *)) {
            double refreshRate = [UIScreen mainScreen].maximumFramesPerSecond;
            completion(@[@(refreshRate), @(tolerance)], nil);
        } else {
            completion(@[@(60.0), @(tolerance)], nil);
        }
    });
}

- (void)isAutoUiTraceEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    LCQRunCatching(@"ApmApi.isAutoUiTraceEnabled", ^{
        BOOL isAutoUiTraceIsEnabled = LCQAPM.autoUITraceEnabled && LCQAPM.enabled;
        completion(@(isAutoUiTraceIsEnabled), nil);
    });
}

- (void)syncCustomSpanName:(NSString *)name
           startTimestamp:(NSNumber *)startTimestamp
             endTimestamp:(NSNumber *)endTimestamp
                    error:(FlutterError *_Nullable *_Nonnull)error
{
    LCQRunCatching(@"ApmApi.syncCustomSpan", ^{
        // Convert NSNumber (μs) → NSTimeInterval (seconds)
        NSTimeInterval startSeconds = startTimestamp.doubleValue / 1e6;
        NSTimeInterval endSeconds   = endTimestamp.doubleValue / 1e6;

        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startSeconds];
        NSDate *endDate   = [NSDate dateWithTimeIntervalSince1970:endSeconds];

        // Send span to native APM SDK
        [LCQAPM addCompletedCustomSpanWithName:name
                                     startDate:startDate
                                       endDate:endDate];
    });
}

@end
