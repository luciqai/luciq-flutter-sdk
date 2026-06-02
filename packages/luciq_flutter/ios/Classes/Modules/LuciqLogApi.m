#import "LuciqSDK/LuciqSDK.h"
#import "LuciqLogApi.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitLuciqLogApi(id<FlutterBinaryMessenger> messenger) {
    LuciqLogApi *api = [[LuciqLogApi alloc] init];
    LuciqLogHostApiSetup(messenger, api);
}

@implementation LuciqLogApi

- (void)logVerboseMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog] format:@"[LCQLog.logVerbose] length=%lu", (unsigned long)message.length];
    [LCQLog logVerbose:message];
}

- (void)logDebugMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog] format:@"[LCQLog.logDebug] length=%lu", (unsigned long)message.length];
    [LCQLog logDebug:message];
}

- (void)logInfoMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog] format:@"[LCQLog.logInfo] length=%lu", (unsigned long)message.length];
    [LCQLog logInfo:message];
}

- (void)logWarnMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog] format:@"[LCQLog.logWarn] length=%lu", (unsigned long)message.length];
    [LCQLog logWarn:message];
}

- (void)logErrorMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog] format:@"[LCQLog.logError] length=%lu", (unsigned long)message.length];
    [LCQLog logError:message];
}

- (void)clearAllLogsWithError:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog] format:@"[LCQLog.clearAllLogs]"];
    [LCQLog clearAllLogs];
}

@end
