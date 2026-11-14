#import "LuciqPigeon.h"

extern void InitLuciqApi(id<FlutterBinaryMessenger> messenger, NSObject<FlutterPluginRegistrar> *registrar);

@interface LuciqApi : NSObject <LuciqHostApi>

// The registrar of the engine this plugin instance belongs to. Its engine is sent with each route, so
// a hybrid app running several engines names only the hosts of that engine with it.
@property (nonatomic, strong, nullable) NSObject<FlutterPluginRegistrar> *flutterEngineRegistrar;

- (UIImage *)getImageForAsset:(NSString *)assetName;
- (UIFont *)getFontForAsset:(NSString *)assetName  error:(FlutterError *_Nullable *_Nonnull)error;
+ (void)registerFlutterHosts;
+ (void)registerFlutterSourceResolver;
+ (void)setScreenshotMaskingHandler:(nullable void (^)(UIImage *_Nonnull, void (^_Nonnull)(UIImage *_Nonnull)))maskingHandler;

@end
