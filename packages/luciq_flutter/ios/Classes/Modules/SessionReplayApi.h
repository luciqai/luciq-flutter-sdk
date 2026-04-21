#import "SessionReplayPigeon.h"

extern void InitSessionReplayApi(id<FlutterBinaryMessenger> messenger);

@interface SessionReplayApi : NSObject <SessionReplayHostApi>

@property(nonatomic, strong) SessionReplayFlutterApi *flutterApi;
@property(nonatomic, copy, nullable) void (^pendingSessionEvaluationCompletion)(BOOL);

- (instancetype)initWithFlutterApi:(SessionReplayFlutterApi *)api;

@end
