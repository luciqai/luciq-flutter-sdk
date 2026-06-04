#import "LuciqSDK/LuciqSDK.h"
#import "CrashReportingApi.h"
#import "../Util/LCQCrashReporting+CP.h"
#import "ArgsRegistry.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitCrashReportingApi(id<FlutterBinaryMessenger> messenger) {
    CrashReportingApi *api = [[CrashReportingApi alloc] init];
    CrashReportingHostApiSetup(messenger, api);
}

@implementation CrashReportingApi

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.setEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    BOOL boolValue = [isEnabled boolValue];
    LCQCrashReporting.enabled = boolValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.setEnabled] phase=exit"];
}

- (void)sendJsonCrash:(NSString *)jsonCrash isHandled:(NSNumber *)isHandled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.sendJsonCrash] phase=enter jsonCrashLength=%lu isHandled=%@", (unsigned long)jsonCrash.length, ([isHandled boolValue] ? @"true" : @"false")];
    NSError *jsonError;
    NSData *objectData = [jsonCrash dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *stackTrace = [NSJSONSerialization JSONObjectWithData:objectData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&jsonError];
    if (jsonError != nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags crashReporting] format:@"[CR.sendJsonCrash] phase=error errorType=JSONDecodeError errorMessage=%@", (jsonError.localizedDescription ?: @"")];
    }
    BOOL isNonFatal = [isHandled boolValue];

    if (isNonFatal) {
        [LCQCrashReporting cp_reportNonFatalCrashWithStackTrace:stackTrace
                                                          level:LCQNonFatalLevelError groupingString:nil userAttributes:nil
        ];
    } else {
        [LCQCrashReporting cp_reportFatalCrashWithStackTrace:stackTrace  ];

    }
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.sendJsonCrash] phase=exit"];
}

- (void)sendNonFatalErrorJsonCrash:(nonnull NSString *)jsonCrash userAttributes:(nullable NSDictionary<NSString *,NSString *> *)userAttributes fingerprint:(nullable NSString *)fingerprint nonFatalExceptionLevel:(nonnull NSString *)nonFatalExceptionLevel error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.sendNonFatalError] phase=enter jsonCrashLength=%lu userAttributesCount=%lu fingerprintPresent=%@ level=%@", (unsigned long)jsonCrash.length, (unsigned long)userAttributes.count, (fingerprint != nil ? @"true" : @"false"), nonFatalExceptionLevel];
    NSError *jsonError;
    NSData *objectData = [jsonCrash dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *stackTrace = [NSJSONSerialization JSONObjectWithData:objectData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&jsonError];
    if (jsonError != nil) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags crashReporting] format:@"[CR.sendNonFatalError] phase=error errorType=JSONDecodeError errorMessage=%@", (jsonError.localizedDescription ?: @"")];
    }
    LCQNonFatalLevel level = (ArgsRegistry.nonFatalExceptionLevel[nonFatalExceptionLevel]).integerValue;
    [LCQCrashReporting cp_reportNonFatalCrashWithStackTrace:stackTrace
                                                      level: level
                                             groupingString:fingerprint
                                             userAttributes:userAttributes];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.sendNonFatalError] phase=exit"];
}

- (void)setNDKEnabledIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.setNDKEnabled] phase=enter iOS=noop=true isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
//    This is auto-generated with pigeon, there is no NDK crashes for iOS.
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags crashReporting] format:@"[CR.setNDKEnabled] phase=exit iOS=noop=true"];
}
@end
