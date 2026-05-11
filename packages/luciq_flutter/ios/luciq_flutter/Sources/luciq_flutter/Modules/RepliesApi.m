#import "LuciqSDK/LuciqSDK.h"
#import "RepliesApi.h"

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
    BOOL boolValue = [isEnabled boolValue];
    LCQReplies.enabled = boolValue;
}

- (void)showWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LCQReplies show];
}

- (void)setInAppNotificationsEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    BOOL boolValue = [isEnabled boolValue];
    LCQReplies.inAppNotificationsEnabled = boolValue;
}

- (void)setInAppNotificationSoundIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    // Android Only
}

- (void)getUnreadRepliesCountWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    completion([NSNumber numberWithLong:LCQReplies.unreadRepliesCount], nil);
}

- (void)hasChatsWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    completion([NSNumber numberWithBool:LCQReplies.hasChats], nil);
}

- (void)bindOnNewReplyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQReplies.didReceiveReplyHandler = ^{
      [self->_flutterApi onNewReplyWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

@end
