#import "LuciqLogPigeon.h"

extern void InitLuciqLogApi(id<FlutterBinaryMessenger> messenger);

@interface LuciqLogApi : NSObject <LuciqLogHostApi>
@end
