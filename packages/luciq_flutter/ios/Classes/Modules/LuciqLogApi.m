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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logVerbose] phase=enter length=%lu",
        (unsigned long)message.length];
    [LCQLog logVerbose:message];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logVerbose] phase=exit"];
}

- (void)logDebugMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logDebug] phase=enter length=%lu",
        (unsigned long)message.length];
    [LCQLog logDebug:message];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logDebug] phase=exit"];
}

- (void)logInfoMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logInfo] phase=enter length=%lu",
        (unsigned long)message.length];
    [LCQLog logInfo:message];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logInfo] phase=exit"];
}

- (void)logWarnMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logWarn] phase=enter length=%lu",
        (unsigned long)message.length];
    [LCQLog logWarn:message];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logWarn] phase=exit"];
}

- (void)logErrorMessage:(NSString *)message error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logError] phase=enter length=%lu",
        (unsigned long)message.length];
    [LCQLog logError:message];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.logError] phase=exit"];
}

- (void)clearAllLogsWithError:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.clearAllLogs] phase=enter"];
    [LCQLog clearAllLogs];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags luciqLog]
                   format:@"[LOG.clearAllLogs] phase=exit"];
}

@end
