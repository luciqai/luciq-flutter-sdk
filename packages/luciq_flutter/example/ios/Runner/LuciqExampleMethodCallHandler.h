#import <Flutter/Flutter.h>

extern NSString * const kLuciqChannelName;

@interface LuciqExampleMethodCallHandler : NSObject 

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)sendNativeNonFatal:(NSString *)exceptionObject;
- (void)sendNativeFatalCrash;
- (void)sendFatalHang;
- (void)sendOOM;

@end
