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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.setEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    BOOL boolValue = [isEnabled boolValue];
    LCQReplies.enabled = boolValue;
}

- (void)showWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.show]"];
    [LCQReplies show];
}

- (void)setInAppNotificationsEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.setInAppNotificationsEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    BOOL boolValue = [isEnabled boolValue];
    LCQReplies.inAppNotificationsEnabled = boolValue;
}

- (void)setInAppNotificationSoundIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.setInAppNotificationSound] iOS noop"];
    // Android Only
}

- (void)getUnreadRepliesCountWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.getUnreadRepliesCount]"];
    completion([NSNumber numberWithLong:LCQReplies.unreadRepliesCount], nil);
}

- (void)hasChatsWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.hasChats]"];
    completion([NSNumber numberWithBool:LCQReplies.hasChats], nil);
}

- (void)bindOnNewReplyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags replies] format:@"[Replies.bindOnNewReplyCallback]"];
    LCQReplies.didReceiveReplyHandler = ^{
      [self->_flutterApi onNewReplyWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

@end
