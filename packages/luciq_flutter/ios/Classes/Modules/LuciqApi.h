#import <Foundation/Foundation.h>
#import "LuciqPigeon.h"

extern void InitLuciqApi(id<FlutterBinaryMessenger> messenger);

@interface LuciqApi : NSObject <LuciqHostApi>

@property(nonatomic, strong, nullable) LuciqFlutterApi *flutterApi;

- (instancetype _Nonnull)initWithFlutterApi:(LuciqFlutterApi *_Nullable)api;
- (UIImage *_Nullable)getImageForAsset:(NSString *_Nonnull)assetName;
- (UIFont *_Nullable)getFontForAsset:(NSString *_Nonnull)assetName  error:(FlutterError *_Nullable *_Nonnull)error;
+ (void)setScreenshotMaskingHandler:(nullable void (^)(UIImage *_Nonnull, void (^_Nonnull)(UIImage *_Nonnull)))maskingHandler;

@end
