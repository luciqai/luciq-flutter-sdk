#import "LuciqSDK/LuciqSDK.h"
#import "LuciqLogApi.h"

extern void InitLuciqLogApi(id<FlutterBinaryMessenger> messenger) {
    LuciqLogApi *api = [[LuciqLogApi alloc] init];
    LuciqLogHostApiSetup(messenger, api);
}

@implementation LuciqLogApi

- (void)logVerboseMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQLog logVerbose:message];
}

- (void)logDebugMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQLog logDebug:message];
}

- (void)logInfoMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQLog logInfo:message];
}

- (void)logWarnMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQLog logWarn:message];
}

- (void)logErrorMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQLog logError:message];
}

- (void)clearAllLogsWithError:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
    [LCQLog clearAllLogs];
}

@end
