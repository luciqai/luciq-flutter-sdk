#import "PrivateViewApi.h"
#import "LuciqPrivateViewPigeon.h"
extern void InitPrivateViewHostApi(id<FlutterBinaryMessenger> _Nonnull messenger, PrivateViewApi * _Nonnull api);

@interface PrivateViewHostApi : NSObject <LuciqPrivateViewHostApi>
@property (nonatomic, strong) PrivateViewApi* _Nonnull privateViewApi;
@end
