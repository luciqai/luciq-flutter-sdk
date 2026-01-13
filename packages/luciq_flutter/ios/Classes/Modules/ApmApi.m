#import "LuciqSDK/LuciqSDK.h"
#import "ApmApi.h"
#import "ArgsRegistry.h"
#import "LCQAPM+PrivateAPIs.h"
#import "LCQTimeIntervalUnits.h"

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
    LCQAPM.enabled = [isEnabled boolValue];
}

// This method is used to check if the APM feature is enabled.
// `completion` handler is a way for implementing callback functionality.
- (void)isEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    BOOL isEnabled = LCQAPM.enabled;
    
    NSNumber *isEnabledNumber = @(isEnabled);
    
    completion(isEnabledNumber, nil);
}

// This method is setting the enabled state of the screen loading feature in the APM module.
// It takes a boolean value wrapped in an NSNumber object as a parameter.
//The method then extracts the boolean value from the NSNumber parameter using the
// `boolValue` method and sets the screen loading enabled state in the APM module based on that value.
- (void)setScreenLoadingEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LCQAPM setScreenLoadingEnabled:[isEnabled boolValue]];
}


// checks whether the screen loading feature is enabled.
//`completion` handler is a way for implementing callback functionality.
- (void)isScreenLoadingEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    BOOL isScreenLoadingEnabled = LCQAPM.screenLoadingEnabled;
    NSNumber *isEnabledNumber = @(isScreenLoadingEnabled);
    completion(isEnabledNumber, nil);
}

// This method is setting the enabled state of the cold app launch feature in the APM module. It takes
// a boolean value wrapped in an NSNumber object as a parameter. The method then extracts the boolean
// value from the NSNumber parameter using the `boolValue` method and sets the cold app launch enabled
// state in the APM module based on that value.
- (void)setColdAppLaunchEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    LCQAPM.coldAppLaunchEnabled = [isEnabled boolValue];
}

// This method is setting the enabled state of the auto UI trace feature in the APM module. It takes a
// boolean value wrapped in an NSNumber object as a parameter. The method then extracts the boolean
// value from the NSNumber parameter using the `boolValue` method and sets the auto UI trace enabled
// state in the APM module based on that value.
- (void)setAutoUITraceEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    LCQAPM.autoUITraceEnabled = [isEnabled boolValue];
}


// This method is responsible for starting a flow with the given `name`. This functionality is used to
// track and monitor the performance of specific flows within the application.
- (void)startFlowName:(nonnull NSString *)name error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LCQAPM startFlowWithName:name];
}

// This method sets an attribute for a specific flow identified by the
// provided `name`. It takes three parameters:
// 1. `name`: The name of the flow for which the attribute needs to be set.
// 2. `key`: The key of the attribute being set.
// 3. `value`: The value of the attribute being set.
- (void)setFlowAttributeName:(nonnull NSString *)name key:(nonnull NSString *)key value:(nullable NSString *)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LCQAPM setAttributeForFlowWithName:name key:key value:value];
}

// This method is responsible for ending a flow with the given `name`.
// This functionality helps in monitoring and tracking the performance of different flows within the application.
- (void)endFlowName:(nonnull NSString *)name error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LCQAPM endFlowWithName:name];
}

// This method is responsible for starting a UI trace with the given `name`.
// Which initiates the tracking of user interface interactions for monitoring the performance of the application.
- (void)startUITraceName:(NSString *)name error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQAPM startUITraceWithName:name];
}

// The method is responsible for ending the currently active UI trace.
// Which signifies the completion of tracking user interface interactions.
- (void)endUITraceWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LCQAPM endUITrace];
}

// The method is responsible for ending the app launch process in the APM module.
- (void)endAppLaunchWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LCQAPM endAppLaunch];
}

- (void)networkLogAndroidData:(NSDictionary<NSString *, id> *)data error:(FlutterError *_Nullable *_Nonnull)error {
    // Android Only
}


// This method is responsible for initiating a custom performance UI trace
// in the APM module. It takes three parameters:
// 1. `screenName`: A string representing the name of the screen or UI element being traced.
// 2. `microTimeStamp`: A number representing the timestamp in microseconds when the trace is started.
// 3. `traceId`: A number representing the unique identifier for the trace.
- (void)startCpUiTraceScreenName:(nonnull NSString *)screenName microTimeStamp:(nonnull NSNumber *)microTimeStamp traceId:(nonnull NSNumber *)traceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSTimeInterval startTimeStampMUS = [microTimeStamp doubleValue];
    [LCQAPM startUITraceCPWithName:screenName startTimestampMUS:startTimeStampMUS];
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
    NSTimeInterval startTimeStampMicroMUS = [startTimeStampMicro doubleValue];
    NSTimeInterval durationMUS = [durationMicro doubleValue];
    [LCQAPM reportScreenLoadingCPWithStartTimestampMUS:startTimeStampMicroMUS durationMUS:durationMUS];
}

// This method i/Users/ahmedalaa-Luciq/projects/Luciq-Flutter/packages/luciq_flutter/ios/Classes/Modules/ApmApi.ms responsible for extend the end time if the screen loading custom
// trace. It takes two parameters:
// 1. `timeStampMicro`: A number representing the timestamp in microseconds when the screen loading
// custom trace is ending.
// 2. `uiTraceId`: A number representing the unique identifier for the UI trace associated with the
// screen loading.
- (void)endScreenLoadingCPTimeStampMicro:(nonnull NSNumber *)timeStampMicro uiTraceId:(nonnull NSNumber *)uiTraceId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSTimeInterval endScreenLoadingCPWithEndTimestampMUS = [timeStampMicro doubleValue];
    [LCQAPM endScreenLoadingCPWithEndTimestampMUS:endScreenLoadingCPWithEndTimestampMUS];
}

// This method is used to check whether the end screen loading feature is enabled or not.
//`completion` handler is a way for implementing callback functionality.
- (void)isEndScreenLoadingEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    BOOL isEndScreenLoadingEnabled = LCQAPM.endScreenLoadingEnabled;
    NSNumber *isEnabledNumber = @(isEndScreenLoadingEnabled);
    completion(isEnabledNumber, nil);
}

- (void)isScreenRenderEnabledWithCompletion:(void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion{
    BOOL isScreenRenderEnabled = LCQAPM.isScreenRenderingOperational;
    NSNumber *isEnabledNumber = @(isScreenRenderEnabled);
    completion(isEnabledNumber, nil);
}


- (void)isCustomSpanEnabledWithCompletion:(void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion{
    BOOL isCustomSpanEnabled = LCQAPM.customSpansEnabled;
    NSNumber *isEnabledNumber = @(isCustomSpanEnabled);
    completion(isEnabledNumber, nil);
}

- (void)setScreenRenderEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LCQAPM setScreenRenderingEnabled:[isEnabled boolValue]];

}


- (void)endScreenRenderForAutoUiTraceData:(nonnull NSDictionary<NSString *,id> *)data error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
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
}


- (void)endScreenRenderForCustomUiTraceData:(nonnull NSDictionary<NSString *,id> *)data error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
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
}

- (void)getDeviceRefreshRateAndToleranceWithCompletion:(nonnull void (^)(NSArray<NSNumber *> * _Nullable, FlutterError * _Nullable))completion {
    double tolerance = LCQAPM.screenRenderingThreshold;
    if (@available(iOS 10.3, *)) {
        double refreshRate = [UIScreen mainScreen].maximumFramesPerSecond;
        completion(@[@(refreshRate), @(tolerance)] ,nil);
    } else {
        // Fallback for very old iOS versions.
        completion(@[@(60.0), @(tolerance)] , nil);
    }
}

- (void)isAutoUiTraceEnabledWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    BOOL isAutoUiTraceIsEnabled = LCQAPM.autoUITraceEnabled && LCQAPM.enabled;
    NSNumber *isEnabledNumber = @(isAutoUiTraceIsEnabled);
    completion(isEnabledNumber, nil);
}

- (void)syncCustomSpanName:(NSString *)name
           startTimestamp:(NSNumber *)startTimestamp
             endTimestamp:(NSNumber *)endTimestamp
                    error:(FlutterError *_Nullable *_Nonnull)error
{
    @try {
      

        // Convert NSNumber (μs) → NSTimeInterval (seconds)
        NSTimeInterval startSeconds = startTimestamp.doubleValue / 1e6;
        NSTimeInterval endSeconds   = endTimestamp.doubleValue / 1e6;


        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startSeconds];
        NSDate *endDate   = [NSDate dateWithTimeIntervalSince1970:endSeconds];

        // Log for verification
        NSLog(@"[CustomSpan] Syncing span - name: %@, start: %.0f μs, end: %.0f μs, duration: %.0f μs",
              name,
              startTimestamp.doubleValue,
              endTimestamp.doubleValue,
              endTimestamp.doubleValue - startTimestamp.doubleValue);

        // Send span to native APM SDK
        [LCQAPM addCompletedCustomSpanWithName:name
                                     startDate:startDate
                                       endDate:endDate];
    }
    @catch (NSException *exception) {
        NSLog(@"[CustomSpan] Error checking APM enabled: %@", exception);
    }
}





@end
