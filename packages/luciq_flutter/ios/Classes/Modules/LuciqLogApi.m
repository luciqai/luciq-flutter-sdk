#import "LuciqSDK/LuciqSDK.h"
#import "LuciqLogApi.h"
#import "../Util/LCQRunCatching.h"

extern void InitLuciqLogApi(id<FlutterBinaryMessenger> messenger) {
    LuciqLogApi *api = [[LuciqLogApi alloc] init];
    LuciqLogHostApiSetup(messenger, api);
}

@implementation LuciqLogApi

- (void)logVerboseMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"LuciqLogApi.logVerbose", ^{ [LCQLog logVerbose:message]; });
}

- (void)logDebugMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"LuciqLogApi.logDebug", ^{ [LCQLog logDebug:message]; });
}

- (void)logInfoMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"LuciqLogApi.logInfo", ^{ [LCQLog logInfo:message]; });
}

- (void)logWarnMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"LuciqLogApi.logWarn", ^{ [LCQLog logWarn:message]; });
}

- (void)logErrorMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"LuciqLogApi.logError", ^{ [LCQLog logError:message]; });
}

- (void)clearAllLogsWithError:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
    LCQRunCatching(@"LuciqLogApi.clearAllLogs", ^{ [LCQLog clearAllLogs]; });
}

@end
