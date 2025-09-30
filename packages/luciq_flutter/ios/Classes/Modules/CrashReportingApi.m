#import "LuciqSDK/LuciqSDK.h"
#import "CrashReportingApi.h"
#import "../Util/LCQCrashReporting+CP.h"
#import "ArgsRegistry.h"

extern void InitCrashReportingApi(id<FlutterBinaryMessenger> messenger) {
    CrashReportingApi *api = [[CrashReportingApi alloc] init];
    CrashReportingHostApiSetup(messenger, api);
}

@implementation CrashReportingApi

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    BOOL boolValue = [isEnabled boolValue];
    LCQCrashReporting.enabled = boolValue;
}

- (void)sendJsonCrash:(NSString *)jsonCrash isHandled:(NSNumber *)isHandled error:(FlutterError *_Nullable *_Nonnull)error {
    NSError *jsonError;
    NSData *objectData = [jsonCrash dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *stackTrace = [NSJSONSerialization JSONObjectWithData:objectData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&jsonError];
    BOOL isNonFatal = [isHandled boolValue];

    if (isNonFatal) {
        [LCQCrashReporting cp_reportNonFatalCrashWithStackTrace:stackTrace
                                                          level:LCQNonFatalLevelError groupingString:nil userAttributes:nil
        ];
    } else {
        [LCQCrashReporting cp_reportFatalCrashWithStackTrace:stackTrace  ];

    }
}

- (void)sendNonFatalErrorJsonCrash:(nonnull NSString *)jsonCrash userAttributes:(nullable NSDictionary<NSString *,NSString *> *)userAttributes fingerprint:(nullable NSString *)fingerprint nonFatalExceptionLevel:(nonnull NSString *)nonFatalExceptionLevel error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSError *jsonError;
    NSData *objectData = [jsonCrash dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *stackTrace = [NSJSONSerialization JSONObjectWithData:objectData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&jsonError];
    LCQNonFatalLevel level = (ArgsRegistry.nonFatalExceptionLevel[nonFatalExceptionLevel]).integerValue;
    [LCQCrashReporting cp_reportNonFatalCrashWithStackTrace:stackTrace
                                                      level: level
                                             groupingString:fingerprint
                                             userAttributes:userAttributes];

}

- (void)setNDKEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
//    This is auto-generated with pigeon, there is no NDK crashes for iOS.
}
@end
