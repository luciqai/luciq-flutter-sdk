#import "LuciqSDK/LuciqSDK.h"
#import "ApmApi.h"
#import "ArgsRegistry.h"
#import "LCQAPM+PrivateAPIs.h"
#import "LCQTimeIntervalUnits.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

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

// This method is setting the enabled state of the APM feature. It
// takes a boolean value wrapped in an NSNumber object as a parameter and sets the APM enabled state
// based on that value. The `LCQAPM.enabled` property is being set to the boolean value extracted from
// the NSNumber parameter using the `boolValue` method.
- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.setEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    LCQAPM.enabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.setEnabled] phase=exit"];
}

// This method is used to check if the APM feature is enabled.
// `completion` handler is a way for implementing callback functionality.
- (void)isEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.isEnabled] phase=enter"];
    BOOL isEnabled = LCQAPM.enabled;

    NSNumber *isEnabledNumber = @(isEnabled);

    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow]
                   format:@"[APM.isEnabled] phase=exit resultPresent=%@",
        (isEnabledNumber != nil ? @"true" : @"false")];
    completion(isEnabledNumber, nil);
}

// This method is setting the enabled state of the screen loading feature in the APM module.
// It takes a boolean value wrapped in an NSNumber object as a parameter.
//The method then extracts the boolean value from the NSNumber parameter using the
// `boolValue` method and sets the screen loading enabled state in the APM module based on that value.
- (void)setScreenLoadingEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.setScreenLoadingEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    [LCQAPM setScreenLoadingEnabled:[isEnabled boolValue]];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.setScreenLoadingEnabled] phase=exit"];
}


// checks whether the screen loading feature is enabled.
//`completion` handler is a way for implementing callback functionality.
- (void)isScreenLoadingEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.isScreenLoadingEnabled] phase=enter"];
    BOOL isScreenLoadingEnabled = LCQAPM.screenLoadingEnabled;
    NSNumber *isEnabledNumber = @(isScreenLoadingEnabled);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading]
                   format:@"[APM.isScreenLoadingEnabled] phase=exit resultPresent=%@",
        (isEnabledNumber != nil ? @"true" : @"false")];
    completion(isEnabledNumber, nil);
}

// This method is setting the enabled state of the cold app launch feature in the APM module. It takes
// a boolean value wrapped in an NSNumber object as a parameter. The method then extracts the boolean
// value from the NSNumber parameter using the `boolValue` method and sets the cold app launch enabled
// state in the APM module based on that value.
- (void)setColdAppLaunchEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmAppLaunch] format:@"[APM.setColdAppLaunchEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    LCQAPM.coldAppLaunchEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmAppLaunch] format:@"[APM.setColdAppLaunchEnabled] phase=exit"];
}

// This method is setting the enabled state of the auto UI trace feature in the APM module. It takes a
// boolean value wrapped in an NSNumber object as a parameter. The method then extracts the boolean
// value from the NSNumber parameter using the `boolValue` method and sets the auto UI trace enabled
// state in the APM module based on that value.
- (void)setAutoUITraceEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.setAutoUITraceEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    LCQAPM.autoUITraceEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.setAutoUITraceEnabled] phase=exit"];
}


// This method is responsible for starting a flow with the given `name`. This functionality is used to
// track and monitor the performance of specific flows within the application.
- (void)startFlowName:(nonnull NSString *)name error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.startFlow] phase=enter nameLength=%lu", (unsigned long)name.length];
    [LCQAPM startFlowWithName:name];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.startFlow] phase=exit"];
}

// This method sets an attribute for a specific flow identified by the
// provided `name`. It takes three parameters:
// 1. `name`: The name of the flow for which the attribute needs to be set.
// 2. `key`: The key of the attribute being set.
// 3. `value`: The value of the attribute being set.
- (void)setFlowAttributeName:(nonnull NSString *)name key:(nonnull NSString *)key value:(nullable NSString *)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.setFlowAttribute] phase=enter nameLength=%lu keyLength=%lu valuePresent=%@", (unsigned long)name.length, (unsigned long)key.length, (value != nil ? @"true" : @"false")];
    [LCQAPM setAttributeForFlowWithName:name key:key value:value];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.setFlowAttribute] phase=exit"];
}

// This method is responsible for ending a flow with the given `name`.
// This functionality helps in monitoring and tracking the performance of different flows within the application.
- (void)endFlowName:(nonnull NSString *)name error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.endFlow] phase=enter nameLength=%lu", (unsigned long)name.length];
    [LCQAPM endFlowWithName:name];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmFlow] format:@"[APM.endFlow] phase=exit"];
}

// This method is responsible for starting a UI trace with the given `name`.
// Which initiates the tracking of user interface interactions for monitoring the performance of the application.
- (void)startUITraceName:(NSString *)name error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.startUITrace] phase=enter nameLength=%lu", (unsigned long)name.length];
    [LCQAPM startUITraceWithName:name];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.startUITrace] phase=exit"];
}

// The method is responsible for ending the currently active UI trace.
// Which signifies the completion of tracking user interface interactions.
- (void)endUITraceWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.endUITrace] phase=enter"];
    [LCQAPM endUITrace];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.endUITrace] phase=exit"];
}

// The method is responsible for ending the app launch process in the APM module.
- (void)endAppLaunchWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmAppLaunch] format:@"[APM.endAppLaunch] phase=enter"];
    [LCQAPM endAppLaunch];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmAppLaunch] format:@"[APM.endAppLaunch] phase=exit"];
}

- (void)networkLogAndroidData:(NSDictionary<NSString *, id> *)data error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmNetwork] format:@"[APM.networkLogAndroid] phase=enter platform=iOS noop=true"];
    // Android Only
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmNetwork] format:@"[APM.networkLogAndroid] phase=exit"];
}


// This method is responsible for initiating a custom performance UI trace
// in the APM module. It takes three parameters:
// 1. `screenName`: A string representing the name of the screen or UI element being traced.
// 2. `microTimeStamp`: A number representing the timestamp in microseconds when the trace is started.
// 3. `traceId`: A number representing the unique identifier for the trace.
- (void)startCpUiTraceScreenName:(nonnull NSString *)screenName microTimeStamp:(nonnull NSNumber *)microTimeStamp traceId:(nonnull NSNumber *)traceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.startCpUiTrace] phase=enter screenNameLength=%lu traceId=%@", (unsigned long)screenName.length, traceId];
    NSTimeInterval startTimeStampMUS = [microTimeStamp doubleValue];
    [LCQAPM startUITraceCPWithName:screenName startTimestampMUS:startTimeStampMUS];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.startCpUiTrace] phase=exit"];
}



// This method is responsible for reporting the screen
// loading data from Dart side to iOS side. It takes three parameters:
// 1. `startTimeStampMicro`: A number representing the start timestamp in microseconds of the screen
// loading custom performance data.
// 2. `durationMicro`: A number representing the duration in microseconds of the screen loading custom
// performance data.
// 3. `uiTraceId`: A number representing the unique identifier for the UI trace associated with the
// screen loading.
- (void)reportScreenLoadingCPStartTimeStampMicro:(nonnull NSNumber *)startTimeStampMicro durationMicro:(nonnull NSNumber *)durationMicro uiTraceId:(nonnull NSNumber *)uiTraceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.reportScreenLoadingCP] phase=enter durationMicro=%@ uiTraceId=%@", durationMicro, uiTraceId];
    NSTimeInterval startTimeStampMicroMUS = [startTimeStampMicro doubleValue];
    NSTimeInterval durationMUS = [durationMicro doubleValue];
    [LCQAPM reportScreenLoadingCPWithStartTimestampMUS:startTimeStampMicroMUS durationMUS:durationMUS];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.reportScreenLoadingCP] phase=exit"];
}

- (void)reportManualScreenLoadingCPScreenName:(nonnull NSString *)screenName startTimeStampMicro:(nonnull NSNumber *)startTimeStampMicro durationMicro:(nonnull NSNumber *)durationMicro error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.reportManualScreenLoadingCP] phase=enter screenNameLength=%lu durationMicro=%@", (unsigned long)screenName.length, durationMicro];
    NSTimeInterval startTimeStampMicroMUS = [startTimeStampMicro doubleValue];
    NSTimeInterval durationMUS = [durationMicro doubleValue];
    [LCQAPM reportScreenLoadingCPUITraceWithName:screenName screenLoadingStartMUS:startTimeStampMicroMUS screenLoadingDurationMUS:durationMUS stages:nil];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.reportManualScreenLoadingCP] phase=exit"];
}

// This method is responsible for extend the end time if the screen loading custom
// trace. It takes two parameters:
// 1. `timeStampMicro`: A number representing the timestamp in microseconds when the screen loading
// custom trace is ending.
// 2. `uiTraceId`: A number representing the unique identifier for the UI trace associated with the
// screen loading.
- (void)endScreenLoadingCPTimeStampMicro:(nonnull NSNumber *)timeStampMicro uiTraceId:(nonnull NSNumber *)uiTraceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.endScreenLoadingCP] phase=enter uiTraceId=%@", uiTraceId];
    NSTimeInterval endScreenLoadingCPWithEndTimestampMUS = [timeStampMicro doubleValue];
    [LCQAPM endScreenLoadingCPWithEndTimestampMUS:endScreenLoadingCPWithEndTimestampMUS];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.endScreenLoadingCP] phase=exit"];
}

// This method is used to check whether the end screen loading feature is enabled or not.
//`completion` handler is a way for implementing callback functionality.
- (void)isEndScreenLoadingEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading] format:@"[APM.isEndScreenLoadingEnabled] phase=enter"];
    BOOL isEndScreenLoadingEnabled = LCQAPM.endScreenLoadingEnabled;
    NSNumber *isEnabledNumber = @(isEndScreenLoadingEnabled);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenLoading]
                   format:@"[APM.isEndScreenLoadingEnabled] phase=exit resultPresent=%@",
        (isEnabledNumber != nil ? @"true" : @"false")];
    completion(isEnabledNumber, nil);
}

- (void)isScreenRenderEnabledWithCompletion:(void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion{
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.isScreenRenderEnabled] phase=enter"];
    BOOL isScreenRenderEnabled = LCQAPM.isScreenRenderingOperational;
    NSNumber *isEnabledNumber = @(isScreenRenderEnabled);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering]
                   format:@"[APM.isScreenRenderEnabled] phase=exit resultPresent=%@",
        (isEnabledNumber != nil ? @"true" : @"false")];
    completion(isEnabledNumber, nil);
}


- (void)isCustomSpanEnabledWithCompletion:(void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion{
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmCustomSpan] format:@"[APM.isCustomSpanEnabled] phase=enter"];
    BOOL isCustomSpanEnabled = LCQAPM.customSpansEnabled;
    NSNumber *isEnabledNumber = @(isCustomSpanEnabled);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmCustomSpan]
                   format:@"[APM.isCustomSpanEnabled] phase=exit resultPresent=%@",
        (isEnabledNumber != nil ? @"true" : @"false")];
    completion(isEnabledNumber, nil);
}

- (void)setScreenRenderEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.setScreenRenderEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    [LCQAPM setScreenRenderingEnabled:[isEnabled boolValue]];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.setScreenRenderEnabled] phase=exit"];
}


- (void)endScreenRenderForAutoUiTraceData:(nonnull NSDictionary<NSString *,id> *)data error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.endScreenRenderForAutoUiTrace] phase=enter frameDataCount=%lu", (unsigned long)((NSArray *)data[@"frameData"]).count];
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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.endScreenRenderForAutoUiTrace] phase=exit"];
}


- (void)endScreenRenderForCustomUiTraceData:(nonnull NSDictionary<NSString *,id> *)data error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.endScreenRenderForCustomUiTrace] phase=enter frameDataCount=%lu", (unsigned long)((NSArray *)data[@"frameData"]).count];
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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.endScreenRenderForCustomUiTrace] phase=exit"];
}

- (void)getDeviceRefreshRateAndToleranceWithCompletion:(nonnull void (^)(NSArray<NSNumber *> * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering] format:@"[APM.getDeviceRefreshRateAndTolerance] phase=enter"];
    double tolerance = LCQAPM.screenRenderingThreshold;
    if (@available(iOS 10.3, *)) {
        double refreshRate = [UIScreen mainScreen].maximumFramesPerSecond;
        NSArray<NSNumber *> *result = @[@(refreshRate), @(tolerance)];
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering]
                       format:@"[APM.getDeviceRefreshRateAndTolerance] phase=exit resultPresent=%@ resultCount=%lu",
            (result != nil ? @"true" : @"false"),
            (unsigned long)result.count];
        completion(result ,nil);
    } else {
        // Fallback for very old iOS versions.
        NSArray<NSNumber *> *result = @[@(60.0), @(tolerance)];
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmScreenRendering]
                       format:@"[APM.getDeviceRefreshRateAndTolerance] phase=exit resultPresent=%@ resultCount=%lu",
            (result != nil ? @"true" : @"false"),
            (unsigned long)result.count];
        completion(result , nil);
    }
}

- (void)isAutoUiTraceEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace] format:@"[APM.isAutoUiTraceEnabled] phase=enter"];
    BOOL isAutoUiTraceIsEnabled = LCQAPM.autoUITraceEnabled && LCQAPM.enabled;
    NSNumber *isEnabledNumber = @(isAutoUiTraceIsEnabled);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmUITrace]
                   format:@"[APM.isAutoUiTraceEnabled] phase=exit resultPresent=%@",
        (isEnabledNumber != nil ? @"true" : @"false")];
    completion(isEnabledNumber, nil);
}

- (void)syncCustomSpanName:(NSString *)name
           startTimestamp:(NSNumber *)startTimestamp
             endTimestamp:(NSNumber *)endTimestamp
                    error:(FlutterError *_Nullable *_Nonnull)error
{
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmCustomSpan] format:@"[APM.syncCustomSpan] phase=enter nameLength=%lu", (unsigned long)name.length];
    @try {


        // Convert NSNumber (μs) → NSTimeInterval (seconds)
        NSTimeInterval startSeconds = startTimestamp.doubleValue / 1e6;
        NSTimeInterval endSeconds   = endTimestamp.doubleValue / 1e6;


        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startSeconds];
        NSDate *endDate   = [NSDate dateWithTimeIntervalSince1970:endSeconds];

        // Send span to native APM SDK
        [LCQAPM addCompletedCustomSpanWithName:name
                                     startDate:startDate
                                       endDate:endDate];
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags apmCustomSpan] format:@"[APM.syncCustomSpan] phase=exit"];
    }
    @catch (NSException *exception) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags apmCustomSpan]
                       format:@"[APM.syncCustomSpan] phase=error errorType=%@ errorMessage=%@",
            NSStringFromClass([exception class]),
            (exception.reason ?: @"")];
    }
}





@end
