#import "LuciqPigeon.h"

extern void InitLuciqApi(id<FlutterBinaryMessenger> messenger);

@interface LuciqApi : NSObject <LuciqHostApi>

- (UIImage *)getImageForAsset:(NSString *)assetName;
- (UIFont *)getFontForAsset:(NSString *)assetName  error:(FlutterError *_Nullable *_Nonnull)error;
+ (void)setScreenshotMaskingHandler:(nullable void (^)(UIImage *_Nonnull, void (^_Nonnull)(UIImage *_Nonnull)))maskingHandler;

@end
