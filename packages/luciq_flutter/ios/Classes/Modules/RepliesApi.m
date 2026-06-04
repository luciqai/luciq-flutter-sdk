#import "LuciqSDK/LuciqSDK.h"
#import "RepliesApi.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitRepliesApi(id<FlutterBinaryMessenger> messenger) {
    RepliesFlutterApi *flutterApi = [[RepliesFlutterApi alloc] initWithBinaryMessenger:messenger];
    RepliesApi *api = [[RepliesApi alloc] initWithFlutterApi:flutterApi];
    RepliesHostApiSetup(messenger, api);
}

@implementation RepliesApi

- (instancetype)initWithFlutterApi:(RepliesFlutterApi *)api {
    self = [super init];
    self.flutterApi = api;
    return self;
}

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.setEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    BOOL boolValue = [isEnabled boolValue];
    LCQReplies.enabled = boolValue;
}

- (void)showCallId:(NSString *)callId error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.show] #%@ phase=enter", callId];
    [LCQReplies show];
}

- (void)setInAppNotificationsEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.setInAppNotificationsEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    BOOL boolValue = [isEnabled boolValue];
    LCQReplies.inAppNotificationsEnabled = boolValue;
}

- (void)setInAppNotificationSoundIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.setInAppNotificationSound] phase=enter platform=iOS noop=true"];
    // Android Only
}

- (void)getUnreadRepliesCountCallId:(NSString *)callId completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.getUnreadRepliesCount] #%@ phase=enter", callId];
    NSInteger count = LCQReplies.unreadRepliesCount;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.getUnreadRepliesCount] #%@ phase=exit result=%ld",
        callId, (long)count];
    completion([NSNumber numberWithLong:count], nil);
}

- (void)hasChatsCallId:(NSString *)callId completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.hasChats] #%@ phase=enter", callId];
    BOOL hasChats = LCQReplies.hasChats;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.hasChats] #%@ phase=exit result=%@",
        callId,
        (hasChats ? @"true" : @"false")];
    completion([NSNumber numberWithBool:hasChats], nil);
}

- (void)bindOnNewReplyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                   format:@"[REP.bindOnNewReplyCallback] phase=enter"];
    LCQReplies.didReceiveReplyHandler = ^{
      NSString *callId = [LuciqFlutterLogger nextCallId];
      [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies]
                     format:@"[REP.onNewReply] #%@ phase=fire", callId];
      [self->_flutterApi onNewReplyCallId:callId completion:^(FlutterError *_Nullable _){
      }];
    };
}

@end
