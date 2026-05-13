#import "SessionReplayPigeon.h"

extern void InitSessionReplayApi(id<FlutterBinaryMessenger> messenger);

@interface SessionReplayApi : NSObject <SessionReplayHostApi>

@property(nonatomic, strong) SessionReplayFlutterApi *flutterApi;
@property(nonatomic, strong) NSMutableArray<void (^)(BOOL)> *pendingSessionEvaluationCompletions;

- (instancetype)initWithFlutterApi:(SessionReplayFlutterApi *)api;

@end
