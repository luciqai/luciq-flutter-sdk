#import <Foundation/Foundation.h>
#import "LuciqPrivateViewPigeon.h"
#import <Flutter/Flutter.h>


@interface PrivateViewApi : NSObject

@property (nonatomic, strong) LuciqPrivateViewFlutterApi *flutterApi;
@property (nonatomic, strong) NSObject<FlutterPluginRegistrar> * flutterEngineRegistrar;

- (instancetype)initWithFlutterApi:(LuciqPrivateViewFlutterApi *)api
                         registrar:(NSObject<FlutterPluginRegistrar> *)registrar;

- (void)mask:(UIImage *)screenshot
 completion:(void (^)(UIImage *maskedImage))completion;
- (void)handlePrivateViewsResult:(NSArray<NSNumber *> *)rectangles
                             error:(FlutterError *)error
                        screenshot:(UIImage *)screenshot
                      completion:(void (^)(UIImage *))completion;
- (NSArray<NSValue *> *)convertToRectangles:(NSArray<NSNumber *> *)rectangles;

- (UIImage *)drawMaskedImage:(UIImage *)screenshot withPrivateViews:(NSArray<NSValue *> *)privateViews;
- (CGPoint)getFlutterViewOrigin;

- (void)logError:(FlutterError *)error;

@end

// Extern function to initialize PrivateViewApi
extern PrivateViewApi* InitPrivateViewApi(
    id<FlutterBinaryMessenger> messenger,
    NSObject<FlutterPluginRegistrar> *flutterEngineRegistrar
);

